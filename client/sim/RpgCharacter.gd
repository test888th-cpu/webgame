class_name RpgCharacter
extends RefCounted
## A reference-rules character (the playable reference slice, docs/PLAYABLE_SLICE.md).
## Class from the class registry, spec committed from the reference's spec unlock
## level, level and XP from RpgProgression, gear from the runtime pack. The derived
## sheet is recomputed from base stats plus worn items as src/sim/entity.ts
## recalcPlayerStats sums them (item stats, spell power and ratings; an item above
## the character's level does not count). Only `state` is stored.
##
## Not applied (listed per spec in the pack, shown in the game): the spec's mastery
## and baseline modifiers (computeTalentModifiers), talents, set bonuses and auras.
##
## state = {schema, class_id, spec_id ("" before the spec is chosen), level, xp,
##          copper, equipment {slot: item_id}, equipment_quality {slot: quality},
##          inventory [{item_id, count, quality}], kills, talents, hotbar, ...}
## A copy keeps its own loot quality (loot_quality/core.ts) in the bags and while
## worn (equipment_quality), so equipping and taking off never changes the copy.

const SCHEMA := 2
## A mainhand that is missing or above level swings as this (entity.ts recalcPlayerStats).
const UNARMED := {"min": 1.0, "max": 2.0, "speed": 2.0}
const STAT_KEYS: Array[String] = ["str", "agi", "sta", "int", "spi", "armor"]


## A new level-1 character wearing its class's starting kit (sim.ts:2795: mainhand
## startWeapon, chest startChest, offhand startOffhand). {} for an unknown class.
static func create(content: ContentDB, pack: Dictionary, class_id: String) -> Dictionary:
	if RpgClassRegistry.class_def(content, class_id).is_empty():
		return {}
	var state := {
		"schema": SCHEMA,
		"class_id": class_id,
		"spec_id": "",
		"level": 1,
		"xp": 0,
		"copper": 0,
		"equipment": {},
		"equipment_quality": {},
		"hotbar": [],
		"inventory": [],
		"kills": 0,
		"talents": {},
		"id": "",
		"name": "",
		"saved_at": 0,
		"area": "",
	}
	var kit := RpgPack.kit(pack, class_id)
	var places := [
		["mainhand", "start_weapon"], ["chest", "start_chest"], ["offhand", "start_offhand"]
	]
	for pair: Array in places:
		if kit.get(pair[1]) != null:
			state["equipment"][pair[0]] = str(kit[pair[1]])
	return state


## Choose the option for a talent row (one per row, from the row's level; the same
## rules as repairAllocation). "" on success. Changing a choice is allowed out of
## combat; the trial applies it at the next fight.
static func choose_talent(
	pack: Dictionary, state: Dictionary, row_level: int, option_id: String
) -> String:
	var rows: Dictionary = state.get("talents", {}).duplicate()
	rows[str(row_level)] = option_id
	var alloc := {"spec": str(state.get("spec_id", "")), "rows": rows}
	var fixed := RpgTalents.repair(pack, str(state["class_id"]), alloc, int(state["level"]))
	if not fixed["rows"].has(str(row_level)):
		return "That talent is not available."
	state["talents"] = fixed["rows"]
	return ""


## Commit a spec (talents.ts: available from SPEC_UNLOCK_LEVEL). "" on success.
static func choose_spec(
	content: ContentDB, pack: Dictionary, state: Dictionary, spec_id: String
) -> String:
	if int(state["level"]) < int(RpgPack.constant(pack, "spec_unlock_level")):
		return "You cannot choose a specialization yet."
	if RpgClassRegistry.spec(content, str(state["class_id"]), spec_id).is_empty():
		return "Unknown specialization."
	state["spec_id"] = spec_id
	return ""


## The derived sheet (never stored): the combat unit's own numbers (RpgUnit.recalc,
## with the spec and talent modifiers), so the screen and the fight read one pipeline.
static func sheet(content: ContentDB, pack: Dictionary, state: Dictionary) -> Dictionary:
	return sheet_of(RpgUnit.player(content, pack, state))


## The same sheet read from a live unit (an RpgEncounter's player, auras included).
static func sheet_of(u: Dictionary) -> Dictionary:
	return {
		"stats": u["stats"],
		"level": u["level"],
		"max_hp": u["max_hp"],
		"max_resource": u["max_resource"],
		"resource": u["resource_type"],
		"armor": u["armor"],
		"attack_power": u["attack_power"],
		"ranged_power": u["ranged_power"],
		"spell_power": u["spell_power"],
		"crit": u["crit"],
		"spell_crit": RpgCombat.spell_crit(u),
		"dodge": u["dodge"],
		"hit_bonus": u["hit_bonus"],
		"haste": u["melee_haste"],
		"weapon": u["weapon"],
		"offhand_weapon": u["offhand_weapon"],
		"dual_wielding": u["dual_wielding"],
		"block_chance": u["block_chance"],
		"block_value": u["block_value"],
		"spec_id": u["spec_id"],
	}


## The weapon worn in `slot` as {min, max, speed}, or {} (none, or above the
## character's level: entity.ts recalcPlayerStats treats it as inert).
static func _weapon(pack: Dictionary, state: Dictionary, slot: String, level: int) -> Dictionary:
	var item := RpgPack.item(pack, str(state["equipment"].get(slot, "")))
	var w: Variant = item.get("weapon")
	if str(item.get("kind")) != "weapon" or not (w is Dictionary) or not meets_level(item, level):
		return {}
	return {"min": float(w["min"]), "max": float(w["max"]), "speed": float(w["speed"])}


## The active shield's block value (entity.ts: a warrior or paladin with a
## level-legal shield in the off hand), else 0.
static func _shield(pack: Dictionary, state: Dictionary, level: int) -> int:
	var cls := str(state["class_id"])
	if cls != "warrior" and cls != "paladin":
		return 0
	var item := RpgPack.item(pack, str(state["equipment"].get("offhand", "")))
	if not item.get("shield", false) or str(item.get("kind")) != "armor":
		return 0
	if not meets_level(item, level):
		return 0
	return int(item.get("block_value", 0))


## meetsLevelRequirement: the pack stores requiredLevelFor(item), evaluated from the
## pinned item_level_req.ts.
static func meets_level(item: Dictionary, level: int) -> bool:
	return level >= int(item.get("required_level", 1))


## Equip an item from the bags (equipment_rules.ts canEquipItemInSlot and
## displacedSlotForEquip). "" on success, else the refusal, with nothing changed.
## `index` names the bag copy (its quality goes with it); -1 takes the first copy.
## The item worn there and a displaced other hand return to the bags as they were.
static func equip(
	content: ContentDB,
	pack: Dictionary,
	state: Dictionary,
	item_id: String,
	slot := "",
	index := -1
) -> String:
	var item := RpgPack.item(pack, item_id)
	if item.is_empty():
		return "Unknown item."
	if index < 0:
		index = _bag_index(state, item_id)
	if (
		index < 0
		or index >= state["inventory"].size()
		or state["inventory"][index]["item_id"] != item_id
	):
		return "You do not have that item."
	var cls := str(state["class_id"])
	var spec := str(state.get("spec_id", ""))
	if slot == "":
		slot = RpgGear.resolve_slot(item, state["equipment"])
	if slot == "" or not RpgGear.can_equip_in(content, cls, spec, item, slot):
		return "You cannot equip that item."
	if not meets_level(item, int(state["level"])):
		return "You are not high enough level."
	var displaced := RpgGear.displaced(content, pack, cls, spec, item, slot, state["equipment"])
	var quality: Variant = state["inventory"][index].get("quality")
	_take_from_bags(state, index)
	for s: String in [slot, displaced]:
		if s != "" and state["equipment"].has(s):
			unequip(state, s)
	state["equipment"][slot] = item_id
	if not state.get("equipment_quality") is Dictionary:
		state["equipment_quality"] = {}
	if quality != null:
		state["equipment_quality"][slot] = quality
	return ""


## Why bag copy `index` cannot be equipped ("" when it can): equip() itself, run on a
## copy of the state, so a screen never disagrees with the engine.
static func equip_problem(
	content: ContentDB, pack: Dictionary, state: Dictionary, index: int
) -> String:
	if index < 0 or index >= state["inventory"].size():
		return "You do not have that item."
	var item_id := str(state["inventory"][index]["item_id"])
	var kind := str(RpgPack.item(pack, item_id).get("kind"))
	if kind != "weapon" and kind != "armor":
		return "This item is not equipment."
	return equip(content, pack, state.duplicate(true), item_id, "", index)


## Take off what is worn in `slot`: the copy, with its quality, goes to the bags.
static func unequip(state: Dictionary, slot: String) -> String:
	if not state["equipment"].has(slot):
		return "Nothing is equipped there."
	var item_id := str(state["equipment"][slot])
	var qualities: Variant = state.get("equipment_quality", {})
	var quality: Variant = qualities.get(slot) if qualities is Dictionary else null
	state["equipment"].erase(slot)
	if qualities is Dictionary:
		qualities.erase(slot)
	add_item(state, item_id, 1, quality)
	return ""


## Bags hold one row per copy (a copy may carry its own quality).
static func add_item(state: Dictionary, item_id: String, count: int, quality: Variant) -> void:
	for _i in count:
		state["inventory"].append({"item_id": item_id, "count": 1, "quality": quality})


static func _bag_index(state: Dictionary, item_id: String) -> int:
	for i in state["inventory"].size():
		if state["inventory"][i]["item_id"] == item_id:
			return i
	return -1


static func _take_from_bags(state: Dictionary, index: int) -> void:
	state["inventory"].remove_at(index)


## Sell a bagged copy for the item's sellValue (copper). "" on success.
static func sell(pack: Dictionary, state: Dictionary, index: int) -> String:
	if index < 0 or index >= state["inventory"].size():
		return "Nothing to sell."
	var item := RpgPack.item(pack, str(state["inventory"][index]["item_id"]))
	state["copper"] = int(state["copper"]) + int(item.get("sell_value", 0))
	state["inventory"].remove_at(index)
	return ""


## XP from a kill (damage.ts:1969, solo): round(mobXpValue x eliteMult x xpMult x
## groupBonus[0]); levels gained up to the cap. Returns the levels gained. XP past
## the cap (lifetime XP and prestige) is not kept in this slice.
static func gain_xp(state: Dictionary, amount: int) -> int:
	var gained := 0
	if amount <= 0 or int(state["level"]) >= RpgProgression.MAX_LEVEL:
		return 0
	state["xp"] = int(state["xp"]) + amount
	while int(state["level"]) < RpgProgression.MAX_LEVEL:
		var need := RpgProgression.xp_for_level(int(state["level"]))
		if int(state["xp"]) < need:
			break
		state["xp"] = int(state["xp"]) - need
		state["level"] = int(state["level"]) + 1
		gained += 1
	if int(state["level"]) >= RpgProgression.MAX_LEVEL:
		state["xp"] = 0
	return gained


## Problems with a stored state (save loading); empty means it can be played.
static func problems(content: ContentDB, pack: Dictionary, state: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var cls := str(state.get("class_id", ""))
	if RpgClassRegistry.class_def(content, cls).is_empty():
		out.append("unknown class")
		return out
	var spec := str(state.get("spec_id", ""))
	if spec != "" and RpgClassRegistry.spec(content, cls, spec).is_empty():
		out.append("unknown spec")
	var level := int(state.get("level", 0))
	if level < 1 or level > RpgProgression.MAX_LEVEL:
		out.append("level out of range")
	if int(state.get("xp", -1)) < 0 or int(state.get("copper", -1)) < 0:
		out.append("negative xp or copper")
	for slot: String in state.get("equipment", {}):
		if RpgPack.item(pack, str(state["equipment"][slot])).is_empty():
			out.append("unknown equipped item " + str(state["equipment"][slot]))
	for row: Variant in state.get("inventory", []):
		if not (row is Dictionary) or RpgPack.item(pack, str(row.get("item_id", ""))).is_empty():
			out.append("unknown item in bags")
	return out
