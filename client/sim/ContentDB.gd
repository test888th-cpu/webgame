class_name ContentDB
extends RefCounted
## All game content, loaded from res://data/*.json and validated as a whole:
## field types and ranges, and every cross-reference (an enemy's moves, a loot
## table's items, a quest's target, an area's exits and encounters). Content is
## data so that new enemies, items, areas and quests need no code changes; the
## validation is what makes that safe.

const DATA_DIR := "res://data"
const ART_MANIFEST := "res://assets/manifest.json"
const ITEM_TYPES := ["consumable", "weapon", "armor", "accessory"]
const EXIT_SIDES := ["west", "east"]
const NPC_ROLES := ["shop", "quests"]

var moves: MoveLibrary
var enemies: Dictionary = {}
var items: Dictionary = {}
var areas: Dictionary = {}
var start_area := ""
var quests: Dictionary = {}
var shops: Dictionary = {}
var progression: Dictionary = {}
## Imported art, from the asset manifest (asset id -> entry).
var art: Dictionary = {}
var errors: PackedStringArray = []


static func load_all(dir := DATA_DIR) -> ContentDB:
	var db := ContentDB.new()
	db.moves = MoveLibrary.load_file(dir.path_join("moves.json"))
	for error in db.moves.errors:
		db.errors.append("moves.json: " + error)
	db.enemies = db._section(dir, "enemies.json", "enemies")
	db.items = db._section(dir, "items.json", "items")
	db.quests = db._section(dir, "quests.json", "quests")
	db.shops = db._section(dir, "shops.json", "shops")
	var area_file := db._read(dir.path_join("areas.json"))
	db.areas = area_file.get("areas", {})
	db.start_area = str(area_file.get("start_area", ""))
	db.progression = db._read(dir.path_join("progression.json"))
	db.art = db._read(ART_MANIFEST).get("assets", {})
	db.validate()
	return db


func is_valid() -> bool:
	return errors.is_empty()


func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


func item(id: String) -> Dictionary:
	return items.get(id, {})


func area(id: String) -> Dictionary:
	return areas.get(id, {})


func validate() -> void:
	for id: String in enemies:
		_validate_enemy(id, enemies[id])
	for id: String in items:
		_validate_item(id, items[id])
	for id: String in shops:
		for item_id in shops[id].get("items", []):
			_check(items.has(item_id), "shops.%s: unknown item %s" % [id, item_id])
	for id: String in quests:
		_validate_quest(id, quests[id])
	_check(areas.has(start_area), "areas.start_area: unknown area %s" % start_area)
	for id: String in areas:
		_validate_area(id, areas[id])
	_validate_progression()
	_validate_art()


func _validate_enemy(id: String, e: Dictionary) -> void:
	var where := "enemies.%s" % id
	_number(e, "max_hp", where, 1)
	_number(e, "speed", where, 0)
	_number(e, "xp", where, 0)
	_validate_moveset(e.get("moveset", {}), where)
	var ai: Variant = e.get("ai")
	if ai != null:
		_check(ai is Dictionary, "%s.ai: expected an object or null" % where)
		if ai is Dictionary:
			for field in ["spacing", "reaction", "cooldown", "cooldown_jitter", "heavy_chance"]:
				_number(ai, field, where + ".ai", 0)
	for phase: Variant in e.get("phases", []):
		_check(phase is Dictionary, "%s.phases: expected objects" % where)
		if phase is Dictionary:
			var below: Variant = phase.get("below")
			_check(
				(below is float or below is int) and below > 0 and below < 1,
				"%s.phases.below: expected 0 < below < 1" % where
			)
			_validate_moveset(phase.get("moveset", {}), where + ".phases")
	_validate_loot(e.get("loot", {}), where + ".loot")


func _validate_moveset(moveset: Variant, where: String) -> void:
	if not moveset is Dictionary:
		errors.append("%s.moveset: expected an object" % where)
		return
	for input: String in moveset:
		_check(input in MoveLibrary.CHAIN_INPUTS, "%s.moveset: unknown input %s" % [where, input])
		var move_id := str(moveset[input])
		_check(moves.moves.has(move_id), "%s.moveset: unknown move %s" % [where, move_id])


func _validate_loot(loot: Variant, where: String) -> void:
	if not loot is Dictionary:
		errors.append("%s: expected an object" % where)
		return
	var money: Variant = loot.get("money", [0, 0])
	_check(
		money is Array and money.size() == 2 and money[0] >= 0 and money[1] >= money[0],
		"%s.money: expected [min, max] with 0 <= min <= max" % where
	)
	for drop: Variant in loot.get("drops", []):
		if not drop is Dictionary:
			errors.append("%s.drops: expected objects" % where)
			continue
		_check(
			items.has(str(drop.get("item"))),
			"%s.drops: unknown item %s" % [where, drop.get("item")]
		)
		var chance: Variant = drop.get("chance")
		_check(
			(chance is float or chance is int) and chance > 0 and chance <= 1,
			"%s.drops.chance: expected 0 < chance <= 1" % where
		)


func _validate_item(id: String, it: Dictionary) -> void:
	var where := "items.%s" % id
	_check(it.get("type") in ITEM_TYPES, "%s.type: expected one of %s" % [where, ITEM_TYPES])
	_number(it, "price", where, 0)
	for field in ["heal", "energy", "power", "defense", "max_hp"]:
		if it.has(field):
			_number(it, field, where, 0)
	if it.get("type") == "consumable":
		_check(
			it.has("heal") or it.has("energy"),
			"%s: a consumable must heal or restore energy" % where
		)


func _validate_quest(id: String, q: Dictionary) -> void:
	var where := "quests.%s" % id
	var objective: Variant = q.get("objective")
	if not objective is Dictionary or objective.get("type") != "defeat":
		errors.append('%s.objective: expected {"type": "defeat", ...}' % where)
	else:
		var target := str(objective.get("enemy"))
		_check(
			target == "any" or enemies.has(target),
			"%s.objective: unknown enemy %s" % [where, target]
		)
		_number(objective, "count", where + ".objective", 1)
	if q.has("requires"):
		_check(
			quests.has(str(q["requires"])), "%s.requires: unknown quest %s" % [where, q["requires"]]
		)
	var rewards: Variant = q.get("rewards", {})
	if rewards is Dictionary:
		for item_id: String in rewards.get("items", {}):
			_check(items.has(item_id), "%s.rewards: unknown item %s" % [where, item_id])


func _validate_area(id: String, a: Dictionary) -> void:
	var where := "areas.%s" % id
	_number(a, "width", where, 320)
	var exits: Variant = a.get("exits", {})
	if exits is Dictionary:
		for side: String in exits:
			_check(side in EXIT_SIDES, "%s.exits: unknown side %s" % [where, side])
			var target := str(exits[side].get("to"))
			_check(areas.has(target), "%s.exits.%s: unknown area %s" % [where, side, target])
			_check(
				exits[side].get("entry") in EXIT_SIDES,
				"%s.exits.%s.entry: expected west or east" % [where, side]
			)
	for npc: Variant in a.get("npcs", []):
		_check(npc.get("role") in NPC_ROLES, "%s.npcs: unknown role %s" % [where, npc.get("role")])
		if npc.get("role") == "shop":
			_check(
				shops.has(str(npc.get("shop"))),
				"%s.npcs: unknown shop %s" % [where, npc.get("shop")]
			)
	for placed: Variant in a.get("placed", []):
		_check(
			enemies.has(str(placed.get("enemy"))),
			"%s.placed: unknown enemy %s" % [where, placed.get("enemy")]
		)
	var width := float(a.get("width", 0))
	for encounter: Variant in a.get("encounters", []):
		var arena: Variant = encounter.get("arena")
		_check(
			(
				arena is Array
				and arena.size() == 2
				and arena[0] >= 0
				and arena[1] <= width
				and arena[1] - arena[0] >= 320
			),
			(
				"%s.encounters.arena: expected [left, right] inside the area, at least 320 px wide"
				% where
			)
		)
		_number(encounter, "max_alive", where + ".encounters", 1)
		var trigger: Variant = encounter.get("trigger_x")
		_check(
			(
				(trigger is float or trigger is int)
				and arena is Array
				and arena.size() == 2
				and trigger > arena[0]
				and trigger < arena[1]
			),
			"%s.encounters.trigger_x: must lie inside the arena" % where
		)
		for wave: Variant in encounter.get("waves", []):
			for enemy_id: Variant in wave:
				_check(
					enemies.has(str(enemy_id)),
					"%s.encounters: unknown enemy %s" % [where, enemy_id]
				)


func _validate_progression() -> void:
	var hero: Variant = progression.get("hero")
	_check(hero is Dictionary, "progression.hero: expected an object")
	if hero is Dictionary:
		_number(hero, "max_hp", "progression.hero", 1)
	_number(progression, "max_level", "progression", 1)
	var xp: Variant = progression.get("xp")
	_check(xp is Dictionary, "progression.xp: expected an object")
	if xp is Dictionary:
		_number(xp, "base", "progression.xp", 1)
		_number(xp, "growth", "progression.xp", 0)


## Every sprite named by content must be an imported asset.
func _validate_art() -> void:
	var wanted := {}
	for id: String in enemies:
		if enemies[id].has("sprite"):
			wanted[enemies[id]["sprite"]] = "enemies.%s.sprite" % id
	for id: String in items:
		if items[id].has("hero_sprite"):
			wanted[items[id]["hero_sprite"]] = "items.%s.hero_sprite" % id
	for id: String in areas:
		for npc: Dictionary in areas[id].get("npcs", []):
			if npc.has("sprite"):
				wanted[npc["sprite"]] = "areas.%s.npcs.%s.sprite" % [id, npc.get("id")]
	var hero: Variant = progression.get("hero")
	if hero is Dictionary and hero.has("sprite"):
		wanted[hero["sprite"]] = "progression.hero.sprite"
	for sprite: String in wanted:
		var entry: Dictionary = art.get(sprite, {})
		_check(
			entry.get("status") == "imported",
			"%s: art %s is not an imported asset in assets/manifest.json" % [wanted[sprite], sprite]
		)


func _number(container: Dictionary, field: String, where: String, minimum: float) -> void:
	var value: Variant = container.get(field)
	_check(
		(value is float or value is int) and value >= minimum,
		"%s.%s: expected a number >= %s" % [where, field, minimum]
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func _section(dir: String, file: String, key: String) -> Dictionary:
	var data := _read(dir.path_join(file))
	var section: Variant = data.get(key)
	if not section is Dictionary:
		errors.append('%s: expected {"%s": {...}}' % [file, key])
		return {}
	return section


func _read(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text) if text else null
	if not data is Dictionary:
		errors.append("%s: missing or not a JSON object" % path.get_file())
		return {}
	return data
