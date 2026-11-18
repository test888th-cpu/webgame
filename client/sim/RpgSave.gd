class_name RpgSave
extends RefCounted
## The playable reference slice's save (docs/PLAYABLE_SLICE.md). It is a file of its
## own (SaveStore.save_reference, user://reference_slice.json), so the hero saves
## (PlayerProfile, SAVE_VERSION 13) are never read or changed by it.
##
## {format: "iron_legacy_reference_slice", version, character: RpgCharacter state}.
## Loading validates everything: a save naming an unknown class, spec, talent or item,
## an impossible level or a negative balance is refused, never repaired by guessing.
## Owner order 2026-11-18 (player data reset): earlier versions (the trial's v1 and v2,
## and every PlayerProfile hero save) are test data and are refused, never migrated.

const FORMAT := "iron_legacy_reference_slice"
const VERSION := 3


static func to_dict(state: Dictionary) -> Dictionary:
	return {"format": FORMAT, "version": VERSION, "character": state.duplicate(true)}


## {"state": the character, or {} when refused; "problems": why}. JSON numbers are
## floats; the state comes back with integer fields as integers.
static func from_dict(data: Variant, content: ContentDB, pack: Dictionary) -> Dictionary:
	var problems := PackedStringArray()
	if not (data is Dictionary) or data.get("format") != FORMAT:
		problems.append("not a reference slice save")
		return {"state": {}, "problems": problems}
	var version := int(data.get("version", 0))
	if version != VERSION:
		problems.append("save version %d is not supported" % version)
		return {"state": {}, "problems": problems}
	var raw: Variant = data.get("character")
	if not (raw is Dictionary):
		problems.append("no character")
		return {"state": {}, "problems": problems}
	var state := _normalise(raw)
	state["schema"] = RpgCharacter.SCHEMA
	problems.append_array(RpgCharacter.problems(content, pack, state))
	problems.append_array(_v2_problems(pack, state))
	return {"state": state if problems.is_empty() else {}, "problems": problems}


static func _normalise(raw: Dictionary) -> Dictionary:
	var state := {
		"schema": int(raw.get("schema", RpgCharacter.SCHEMA)),
		"class_id": str(raw.get("class_id", "")),
		"spec_id": str(raw.get("spec_id", "")),
		"level": int(raw.get("level", 0)),
		"xp": int(raw.get("xp", -1)),
		"copper": int(raw.get("copper", -1)),
		"kills": maxi(0, int(raw.get("kills", 0))),
		"id": str(raw.get("id", "")),
		"name": PlayerProfile.clean_name(str(raw.get("name", ""))),
		"saved_at": maxi(0, int(raw.get("saved_at", 0))),
		"area": str(raw.get("area", "")),
		"equipment": {},
		"inventory": [],
	}
	var equipment: Variant = raw.get("equipment", {})
	if equipment is Dictionary:
		for slot: Variant in equipment:
			state["equipment"][str(slot)] = str(equipment[slot])
	var bags: Variant = raw.get("inventory", [])
	if bags is Array:
		for row: Variant in bags:
			if row is Dictionary:
				var copy := {
					"item_id": str(row.get("item_id", "")),
					"count": maxi(1, int(row.get("count", 1))),
					"quality": _quality(row.get("quality")),
				}
				state["inventory"].append(copy)
	var vitals: Variant = raw.get("vitals")
	if vitals is Dictionary:
		state["vitals"] = {
			"hp": int(vitals.get("hp", 0)),
			"resource": float(vitals.get("resource", 0.0)),
			"dead": bool(vitals.get("dead", false)),
		}
	var talents: Variant = raw.get("talents", {})
	state["talents"] = {}
	if talents is Dictionary:
		for row: Variant in talents:
			state["talents"][str(row)] = str(talents[row])
	state["corpses"] = []
	var corpses: Variant = raw.get("corpses", [])
	if corpses is Array:
		for corpse: Variant in corpses:
			if not (corpse is Dictionary and corpse.get("loot") is Dictionary):
				continue
			var items: Array = []
			for slot: Variant in corpse["loot"].get("items", []):
				if slot is Dictionary:
					(
						items
						. append(
							{
								"item_id": str(slot.get("item_id", "")),
								"count": maxi(1, int(slot.get("count", 1))),
								"quality": _quality(slot.get("quality")),
								"quest": bool(slot.get("quest", false)),
							}
						)
					)
			var copper := maxi(0, int(corpse["loot"].get("copper", 0)))
			(
				state["corpses"]
				. append(
					{
						"monster": str(corpse.get("monster", "")),
						"loot": {"copper": copper, "items": items},
						"remaining": float(corpse.get("remaining", 0.0)),
					}
				)
			)
	return state


## Talents the reference's own rules accept, and a corpse of a real monster.
static func _v2_problems(pack: Dictionary, state: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if state.get("class_id", "") == "" or not pack.get("classes", {}).has(state["class_id"]):
		return out
	var alloc := {"spec": state["spec_id"], "rows": state["talents"]}
	var fixed := RpgTalents.repair(pack, state["class_id"], alloc, int(state["level"]))
	if fixed["rows"] != state["talents"] or fixed["spec"] != state["spec_id"]:
		out.append("talents or spec not allowed at this level")
	for corpse: Dictionary in state["corpses"]:
		if (
			RpgPack.monster(pack, corpse["monster"]).is_empty()
			and not _placed(pack, corpse["monster"])
		):
			out.append("corpse of an unknown monster")
		for slot: Dictionary in corpse["loot"]["items"]:
			if RpgPack.item(pack, slot["item_id"]).is_empty():
				out.append("unknown item on the corpse")
	return out


static func _quality(q: Variant) -> Variant:
	if not (q is Dictionary):
		return null
	var weights: Array = []
	for w: Variant in q.get("weights", []):
		weights.append(int(w))
	return {"tier": int(q.get("tier", 0)), "weights": weights}


static func _placed(pack: Dictionary, monster_id: String) -> bool:
	return pack.get("monsters", {}).has(monster_id)
