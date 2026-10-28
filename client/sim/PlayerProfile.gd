class_name PlayerProfile
extends RefCounted
## Durable progression of one hero: level, XP, money, inventory, equipment,
## quests. Serialises to a versioned dictionary for the local save today and
## for the backend in Milestone 4, when the server becomes the only writer.
## Temporary combat state (position, energy, cooldowns) never lives here.

const SAVE_VERSION := 10
## Equipment slots, in the order the character screen shows them.
const SLOTS := ["head", "body", "hands", "weapon", "feet", "charm"]
## Stats an item can add, as stored in items.json "stats".
const STAT_KEYS := ["max_hp", "power", "defense", "speed", "crit", "attack_speed"]
## Every hero starts with this crit chance and attack speed unless heroes.json
## says otherwise; gear moves them within these caps, so no build ever crits
## every blow or swings faster than the animations can show.
const BASE_CRIT := 0.05
const MAX_CRIT := 0.5
const ATTACK_SPEED_RANGE := Vector2(0.7, 1.3)
## Player names: letters of any script (with their marks, e.g. Thai vowels),
## digits, spaces, apostrophes, hyphens and dots.
const NAME_MIN := 2
const NAME_MAX := 16
const NAME_PATTERN := "^[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} '.\\-]*$"

## The character's id (RosterRules.is_id: 16 hex digits, "" until the store
## gives one). An account plays several characters; everything below is this
## one's alone, item copy keys included.
var id := ""
## When it was last saved (Unix seconds), for "last played".
var saved_at := 0
## Which playable hero (heroes.json id) and the name the player gave them.
var hero := ""
var name := ""

var level := 1
var xp := 0
var money := 0
## Current HP carried between areas; clamped to max HP on load and on use.
var hp := 0
## Item key -> count. A key is an item id (a stack of identical, never
## upgraded copies) or "<item id>#<n>": one copy of its own, made when it
## first goes to the workbench, so its upgrades are its alone (count 1).
## ContentDB.item() takes either.
var inventory := {}
## Slot -> item key ("" when empty).
var equipment := {"head": "", "body": "", "hands": "", "weapon": "", "feet": "", "charm": ""}
## Quest id -> {"state": "active" | "complete" | "turned_in", "progress": int}.
var quests := {}
## Enemy id -> total defeated.
var defeated := {}
var area := ""
## Index of the next tutorial step (see TutorialRules); past the last step
## when finished or skipped.
var tutorial := 0
## How many times the current step's action was done. Not saved: a step is
## short enough to redo after a reload.
var tutorial_progress := 0
## Upgrade level per copy ("<item id>#<n>" key; EnhanceRules; it stays with
## the copy when taken off), and failed attempts since that copy's last
## success (each raises the next chance).
var enhance := {}
var enhance_pity := {}
## What a save held that this build does not know (see _load_gear), kept
## and saved unchanged: {"inventory", "enhance", "enhance_pity"}.
var unknown := {"inventory": {}, "enhance": {}, "enhance_pity": {}}
## Fights won per area since the last rest, and areas reached (StreetMemory).
var cleared := {}
var visited: Array[String] = []
## Each world boss's round progress, by boss id: {"round": int, "dealt":
## damage so far, "tiers": personal tiers paid, "killed": the kill paid}
## (WorldBossRules).
var world_boss := {}


## A fresh profile for `hero_id` (the first hero if empty or unknown), named
## `player_name` if it is a valid name, else the hero's default name.
static func new_game(content: ContentDB, hero_id := "", player_name := "") -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.hero = hero_id if content.heroes.has(hero_id) else str(content.hero_order[0])
	profile.name = clean_name(player_name)
	if profile.name == "":
		profile.name = str(content.hero(profile.hero)["default_name"])
	profile.area = content.start_area
	# The hero's starter kit: worn gear, a few items and some coins.
	var starter: Dictionary = content.hero(profile.hero).get("starter", {})
	profile.money = int(starter.get("money", 0))
	for item_id: String in starter.get("equipment", []):
		profile.add_item(item_id)
		profile.equip(item_id, content)
	var items: Dictionary = starter.get("items", {})
	for item_id: String in items:
		profile.add_item(item_id, int(items[item_id]))
	profile.hp = profile.stats(content)["max_hp"]
	return profile


## Normalises a player name: trims and collapses spaces. Returns "" when it
## is too short, too long or has characters outside NAME_PATTERN.
static func clean_name(text: String) -> String:
	var cleaned := " ".join(text.strip_edges().split(" ", false))
	if cleaned.length() < NAME_MIN or cleaned.length() > NAME_MAX:
		return ""
	var pattern := RegEx.create_from_string(NAME_PATTERN)
	return cleaned if pattern.search(cleaned) else ""


## Hero stats from the hero's base values, level and equipment.
func stats(content: ContentDB) -> Dictionary:
	var base: Dictionary = content.hero(hero).get("stats", {})
	var per_level: Dictionary = content.progression.get("per_level", {})
	var result := {
		"max_hp": int(base.get("max_hp", 100)) + int(per_level.get("max_hp", 0)) * (level - 1),
		"power": float(base.get("power", 1.0)) + float(per_level.get("power", 0.0)) * (level - 1),
		"defense": int(base.get("defense", 0)),
		"speed": float(base.get("speed", 1.0)),
		"crit": float(base.get("crit", BASE_CRIT)),
		"attack_speed": float(base.get("attack_speed", 1.0)),
	}
	var gear := gear_stats(content)
	result["max_hp"] += int(gear["max_hp"])
	result["power"] += float(gear["power"])
	result["defense"] += int(gear["defense"])
	result["speed"] = maxf(0.3, result["speed"] + float(gear["speed"]))
	result["crit"] = clampf(result["crit"] + float(gear["crit"]), 0.0, MAX_CRIT)
	result["attack_speed"] = clampf(
		result["attack_speed"] + float(gear["attack_speed"]),
		ATTACK_SPEED_RANGE.x,
		ATTACK_SPEED_RANGE.y
	)
	return result


## What equipped items add, stat by stat (all STAT_KEYS present).
func gear_stats(content: ContentDB) -> Dictionary:
	var total := {
		"max_hp": 0, "power": 0.0, "defense": 0, "speed": 0.0, "crit": 0.0, "attack_speed": 0.0
	}
	for slot: String in SLOTS:
		var item := content.item(equipment[slot])
		var bonus: Dictionary = item.get("stats", {})
		for key: String in bonus:
			total[key] += bonus[key]
		var upgrades := EnhanceRules.bonus(self, slot, item, content)
		for key: String in upgrades:
			total[key] += upgrades[key]
	return total


## Why `item_id` cannot be equipped right now ("" if it can): not owned, not
## equipment, or the hero's level is too low.
func equip_problem(item_id: String, content: ContentDB) -> String:
	var item := content.item(item_id)
	if item.get("type") != "equipment":
		return "not_equipment"
	if count(item_id) == 0:
		return "not_owned"
	if level < int(item.get("level", 1)):
		return "level"
	return ""


func xp_to_next(content: ContentDB) -> int:
	var curve: Dictionary = content.progression.get("xp", {})
	var steps := level - 1
	return (
		int(curve.get("base", 40))
		+ int(curve.get("growth", 0)) * steps
		+ int(curve.get("square", 0)) * steps * steps
	)


func max_level(content: ContentDB) -> int:
	return int(content.progression.get("max_level", 1))


## Adds XP and returns how many levels were gained. Levelling up refills HP.
func add_xp(amount: int, content: ContentDB) -> int:
	var gained := 0
	if level >= max_level(content):
		return 0
	xp += maxi(0, amount)
	while level < max_level(content) and xp >= xp_to_next(content):
		xp -= xp_to_next(content)
		level += 1
		gained += 1
	if level >= max_level(content):
		xp = 0
	if gained > 0:
		hp = stats(content)["max_hp"]
	return gained


func count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


## Every copy of item `item_id` the hero has, worn or carried, upgraded or not.
func owned(item_id: String) -> int:
	var total := 0
	for key: String in inventory:
		total += count(key) if ContentDB.base_id(key) == item_id else 0
	for slot: String in SLOTS:
		total += 1 if ContentDB.base_id(equipment[slot]) == item_id else 0
	return total


## Makes what is worn in `slot` a copy of its own (see `inventory`) and
## returns its key; a copy already its own keeps its key.
func own_copy(slot: String) -> String:
	var key := str(equipment[slot])
	if key == "" or key.contains("#"):
		return key
	var taken := {}
	for other: String in inventory.keys() + equipment.values() + enhance.keys():
		taken[other] = true
	for other: String in enhance_pity:
		taken[other] = true
	var n := 1
	while taken.has("%s#%d" % [key, n]):
		n += 1
	equipment[slot] = "%s#%d" % [key, n]
	return equipment[slot]


func add_item(item_id: String, amount := 1) -> void:
	inventory[item_id] = count(item_id) + amount


## Throws `amount` away at the player's request (selling uses it too).
## Evidence (key items) is the story and is never thrown away. Once no copy
## is left, worn or carried, its upgrades go with it, so one bought back
## starts again at +0.
func discard(item_id: String, content: ContentDB, amount := 1) -> bool:
	if content.item(item_id).get("type") == "key" or not remove_item(item_id, amount):
		return false
	if count(item_id) == 0 and item_id not in equipment.values():
		enhance.erase(item_id)
		enhance_pity.erase(item_id)
	return true


func remove_item(item_id: String, amount := 1) -> bool:
	if count(item_id) < amount:
		return false
	inventory[item_id] = count(item_id) - amount
	if inventory[item_id] == 0:
		inventory.erase(item_id)
	return true


## Equips an owned item into its slot; whatever was there goes back to the
## inventory. HP is kept but clamped to the new max HP.
func equip(item_id: String, content: ContentDB) -> bool:
	if equip_problem(item_id, content) != "":
		return false
	var slot := str(content.item(item_id)["slot"])
	remove_item(item_id)
	if equipment[slot]:
		add_item(equipment[slot])
	equipment[slot] = item_id
	hp = mini(hp, stats(content)["max_hp"])
	return true


func unequip(slot: String, content: ContentDB) -> bool:
	if slot not in SLOTS or not equipment[slot]:
		return false
	add_item(equipment[slot])
	equipment[slot] = ""
	hp = mini(hp, stats(content)["max_hp"])
	return true


## Consumes one consumable on the given fighter (which is kept in sync with
## `hp`). Returns false if it is not owned, not consumable, or would do nothing.
func use_item(item_id: String, hero: Fighter, content: ContentDB) -> bool:
	var item := content.item(item_id)
	if item.get("type") != "consumable" or count(item_id) == 0:
		return false
	var heals := int(item.get("heal", 0)) > 0 and hero.hp < hero.max_hp
	var energises := float(item.get("energy", 0)) > 0 and hero.energy < CombatRules.MAX_ENERGY
	if hero.is_ko() or not (heals or energises):
		return false
	remove_item(item_id)
	hero.hp = mini(hero.max_hp, hero.hp + int(item.get("heal", 0)))
	hero.energy = minf(CombatRules.MAX_ENERGY, hero.energy + float(item.get("energy", 0)))
	hp = hero.hp
	return true


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"id": id,
		"saved_at": saved_at,
		"hero": hero,
		"name": name,
		"level": level,
		"xp": xp,
		"money": money,
		"hp": hp,
		"inventory": inventory.duplicate(),
		"equipment": equipment.duplicate(),
		"quests": quests.duplicate(true),
		"defeated": defeated.duplicate(),
		"area": area,
		"tutorial": tutorial,
		"enhance": enhance.duplicate(),
		"enhance_pity": enhance_pity.duplicate(),
		"unknown": unknown.duplicate(true),
		"cleared": cleared.duplicate(true),
		"visited": visited.duplicate(),
		"world_boss": world_boss.duplicate(),
	}


## Rebuilds a profile from saved data. Returns null if the data is not a save
## this build understands. Values are clamped and unknown content ids dropped,
## so a hand-edited or stale save cannot produce an impossible hero.
static func from_dict(data: Variant, content: ContentDB) -> PlayerProfile:
	if not data is Dictionary:
		return null
	var migrated := migrate(data)
	if migrated.is_empty():
		return null
	var p := PlayerProfile.new()
	var saved_hero := str(migrated.get("hero", ""))
	if not content.heroes.has(saved_hero):
		return null
	p.hero = saved_hero
	var saved_id := str(migrated.get("id", ""))
	p.id = saved_id if RosterRules.is_id(saved_id) else ""
	p.saved_at = maxi(0, int(migrated.get("saved_at", 0)))
	p.name = clean_name(str(migrated.get("name", "")))
	if p.name == "":
		p.name = str(content.hero(p.hero)["default_name"])
	p.level = clampi(int(migrated.get("level", 1)), 1, p.max_level(content))
	p.xp = clampi(int(migrated.get("xp", 0)), 0, p.xp_to_next(content) - 1)
	p.money = maxi(0, int(migrated.get("money", 0)))
	_load_gear(p, migrated, content)
	var saved_quests: Variant = migrated.get("quests", {})
	if saved_quests is Dictionary:
		for quest_id: String in saved_quests:
			var entry: Variant = saved_quests[quest_id]
			if content.quests.has(quest_id) and entry is Dictionary:
				var state := str(entry.get("state"))
				if state in ["active", "complete", "turned_in"]:
					p.quests[quest_id] = {
						"state": state, "progress": maxi(0, int(entry.get("progress", 0)))
					}
	var saved_defeated: Variant = migrated.get("defeated", {})
	if saved_defeated is Dictionary:
		for enemy_id: String in saved_defeated:
			if content.enemies.has(enemy_id):
				p.defeated[enemy_id] = maxi(0, int(saved_defeated[enemy_id]))
	var saved_area := str(migrated.get("area", ""))
	p.area = saved_area if content.areas.has(saved_area) else content.start_area
	var max_hp: int = p.stats(content)["max_hp"]
	p.hp = clampi(int(migrated.get("hp", max_hp)), 1, max_hp)
	p.tutorial = clampi(int(migrated.get("tutorial", 0)), 0, content.tutorial.size())
	StreetMemory.load_into(p, migrated, content)
	var rounds: Variant = migrated.get("world_boss", {})
	if rounds is Dictionary:
		for boss: Variant in rounds:
			var state: Variant = rounds[boss]
			var boss_data := WorldBossRules.spec(content, str(boss))
			if boss_data.is_empty() or not state is Dictionary or not state.has("round"):
				continue
			p.world_boss[str(boss)] = {
				"round": int(state["round"]),
				"dealt": maxi(0, int(state.get("dealt", 0))),
				"tiers": clampi(int(state.get("tiers", 0)), 0, boss_data["tiers"].size()),
				"killed": bool(state.get("killed", false)),
			}
			var attempt: Variant = state.get("attempt")
			if attempt is Dictionary and attempt.has_all(["dealt", "total", "level"]):
				p.world_boss[str(boss)]["attempt"] = {
					"dealt": maxi(0, int(attempt["dealt"])),
					"total": maxi(1, int(attempt["total"])),
					"level": maxi(1, int(attempt["level"])),
				}
	return p


## Inventory, equipment and upgrades from saved data. Nothing the player
## owns is thrown away: an item this build does not know (renamed, removed,
## or from a newer build) goes to `unknown` with its upgrades, is saved as it
## was, and comes back the first time a build knows it again. Worn gear that
## no longer fits its slot goes to the bag.
static func _load_gear(p: PlayerProfile, migrated: Dictionary, content: ContentDB) -> void:
	var parked: Variant = migrated.get("unknown", {})
	parked = parked if parked is Dictionary else {}
	var bag := {}
	for source: Variant in [migrated.get("inventory", {}), parked.get("inventory", {})]:
		if source is Dictionary:
			for key: Variant in source:
				bag[str(key)] = int(bag.get(str(key), 0)) + maxi(0, int(source[key]))
	var worn: Variant = migrated.get("equipment", {})
	if worn is Dictionary:
		for slot: String in SLOTS:
			var key := str(worn.get(slot, ""))
			if key == "":
				continue
			if content.item(key).get("slot") == slot and key not in p.equipment.values():
				p.equipment[slot] = key
				# A copy of its own is in one place: worn wins over the bag.
				if key.contains("#"):
					bag.erase(key)
			else:
				bag[key] = int(bag.get(key, 0)) + 1
	for key: String in bag:
		if bag[key] <= 0 or key in p.equipment.values():
			continue
		# A copy of its own is one item, however the save got edited.
		var amount: int = mini(bag[key], 1) if key.contains("#") else bag[key]
		if content.item(key).is_empty():
			p.unknown["inventory"][key] = amount
		else:
			p.inventory[key] = amount
	var top := EnhanceRules.max_level(content)
	for field: String in ["enhance", "enhance_pity"]:
		var levels := {}
		for source: Variant in [migrated.get(field, {}), parked.get(field, {})]:
			if source is Dictionary:
				for key: Variant in source:
					levels[str(key)] = source[key]
		var limit := top if field == "enhance" else 1000
		for key: String in levels:
			var value := clampi(int(levels[key]), 0, limit)
			if value <= 0 or not key.contains("#"):
				continue  # a plain id would upgrade a whole stack at once
			if p.unknown["inventory"].has(key):
				p.unknown[field][key] = int(levels[key])  # kept unclamped, with its item
			elif p.count(key) > 0 or key in p.equipment.values():
				if content.item(key).get("type") == "equipment":
					p.get(field)[key] = value


## Upgrades saved data one version at a time to SAVE_VERSION. Returns {} for
## data from a newer build or without a version, which must not be guessed at.
static func migrate(data: Dictionary) -> Dictionary:
	var version: Variant = data.get("version")
	if not (version is int or version is float) or int(version) < 1:
		return {}
	if int(version) > SAVE_VERSION:
		return {}
	var migrated := data.duplicate(true)
	if int(migrated["version"]) == 1:
		# Version 1 saves predate hero selection: Mika was the only hero.
		migrated["hero"] = "mika"
		migrated["name"] = "Mika"
		migrated["version"] = 2
	if int(migrated["version"]) == 2:
		# Version 3 has six slots; "armor" became "body", "accessory" "charm".
		var old: Variant = migrated.get("equipment", {})
		if old is Dictionary:
			migrated["equipment"] = {
				"weapon": old.get("weapon", ""),
				"body": old.get("armor", ""),
				"charm": old.get("accessory", ""),
			}
		migrated["version"] = 3
	if int(migrated["version"]) == 3:
		# Version 4 adds the tutorial. Saves from before it belong to players
		# who already know the game, so it counts as finished.
		migrated["tutorial"] = 1 << 20
		migrated["version"] = 4
	if int(migrated["version"]) == 4:
		# Version 5 adds slot upgrades; everything starts at +0.
		migrated["enhance"] = {}
		migrated["enhance_pity"] = {}
		migrated["version"] = 5
	if int(migrated["version"]) == 5:
		# Version 6 remembers fights won and areas reached; older saves start
		# with every fight ready and their road so far reached.
		migrated["cleared"] = {}
		migrated["visited"] = []
		migrated["version"] = 6
	if int(migrated["version"]) == 6:
		# Version 7 keeps the world boss round's progress; none yet.
		migrated["world_boss"] = {}
		migrated["version"] = 7
	if int(migrated["version"]) == 7:
		# Version 8 keeps a round per world boss; version 7's was the Tunnel
		# Mother's.
		var round: Variant = migrated.get("world_boss", {})
		var by_boss := {}
		if round is Dictionary and round.has("round"):
			by_boss["tunnel_mother"] = round
		migrated["world_boss"] = by_boss
		migrated["version"] = 8
	if int(migrated["version"]) == 8:
		# Version 9 keeps upgrades on the item, not the slot: each slot's level
		# goes to what was worn there (an empty slot's is dropped).
		var worn: Variant = migrated.get("equipment", {})
		for field: String in ["enhance", "enhance_pity"]:
			var by_item := {}
			var by_slot: Variant = migrated.get(field, {})
			if by_slot is Dictionary and worn is Dictionary:
				for slot: Variant in by_slot:
					var item_id := str(worn.get(slot, ""))
					if item_id:
						by_item[item_id] = by_slot[slot]
			migrated[field] = by_item
		migrated["version"] = 9
	if int(migrated["version"]) == 9:
		_migrate_copies(migrated)
		migrated["version"] = 10
	return migrated


## Version 10 keeps upgrades per copy: version 9 kept them per item id, so
## every copy of an upgraded item showed (and gave) the upgrade. The upgrade
## stays with one copy, the worn one where there is one, else one from the
## bag; the others are +0 again.
static func _migrate_copies(migrated: Dictionary) -> void:
	var worn: Variant = migrated.get("equipment", {})
	var bag: Variant = migrated.get("inventory", {})
	if not worn is Dictionary or not bag is Dictionary:
		migrated["enhance"] = {}
		migrated["enhance_pity"] = {}
		return
	var levels: Variant = migrated.get("enhance", {})
	var pity: Variant = migrated.get("enhance_pity", {})
	levels = levels if levels is Dictionary else {}
	pity = pity if pity is Dictionary else {}
	var by_copy := {"enhance": {}, "enhance_pity": {}}
	for item_id: String in (levels as Dictionary).keys() + (pity as Dictionary).keys():
		var key := item_id + "#1"
		if by_copy["enhance"].has(key) or by_copy["enhance_pity"].has(key):
			continue
		var slot: Variant = worn.find_key(item_id)
		if slot != null:
			worn[slot] = key
		elif int(bag.get(item_id, 0)) > 0:
			bag[item_id] = int(bag[item_id]) - 1
			if bag[item_id] == 0:
				bag.erase(item_id)
			bag[key] = 1
		else:
			continue
		if levels.has(item_id):
			by_copy["enhance"][key] = levels[item_id]
		if pity.has(item_id):
			by_copy["enhance_pity"][key] = pity[item_id]
	migrated["enhance"] = by_copy["enhance"]
	migrated["enhance_pity"] = by_copy["enhance_pity"]
