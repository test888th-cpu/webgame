class_name ContentDB
extends RefCounted
## All game content, loaded from res://data/*.json and validated as a whole:
## field types and ranges, and every cross-reference (an enemy's moves, a loot
## table's items, a quest's target, an area's exits and encounters). Content is
## data so that new enemies, items, areas and quests need no code changes; the
## validation is what makes that safe.

const DATA_DIR := "res://data"
const ART_MANIFEST := "res://assets/manifest.json"
## "key": story items (evidence). Kept for good: never sold, used or dropped.
## "material": spent on upgrades.
const ITEM_TYPES := ["consumable", "equipment", "material", "key"]
## What a quest giver says when offering, while it is under way, and on
## hand-in (quests.json "dialogue").
const DIALOGUE_LINES := ["offer", "active", "done"]
## From most common to rarest; the UI colours names by rarity.
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const EXIT_SIDES := ["west", "east"]
const NPC_ROLES := ["shop", "quests", "travel"]
const HOTBAR_TYPES := ["attack", "skill", "item"]
const HOTBAR_SLOTS := 7
## Skills each hero brings to the hotbar.
const HERO_SKILLS := 4
const HERO_STATS := ["max_hp", "power", "defense", "speed"]

var moves: MoveLibrary
var enemies: Dictionary = {}
var items: Dictionary = {}
var areas: Dictionary = {}
## Street furniture that blocks walking (kind -> {"piece", "half", "box"}), from
## obstacles.json; areas place them in "obstacles".
var obstacles: Dictionary = {}
var start_area := ""
var quests: Dictionary = {}
var shops: Dictionary = {}
var progression: Dictionary = {}
## Playable heroes (id -> definition) and the order the selection screen shows.
var heroes: Dictionary = {}
var hero_order: Array = []
## Street weapons (id -> definition), from weapons.json.
var weapons: Dictionary = {}
## Hero skills (skill id -> definition) and the hotbar layout, from skills.json.
var skills: Dictionary = {}
var hotbar: Array = []
## Ticks between uses of consumables (shared by all of them).
var item_cooldown := 0
## Imported art, from the asset manifest (asset id -> entry).
var art: Dictionary = {}
## Generated scenery: {"props": {...}, "areas": {area id -> layers and props}}.
var environment: Dictionary = {}
## The HD-2D street kit: {"pieces": {id: texture and size}, "scroll": {layer:
## speed}, "areas": {area id -> placed pieces}}, from tools/assets/kit_import.py.
var kit: Dictionary = {}
## Generated interface art: {"icons": {"sheet": ..., "regions": {id: [x, y, w, h]}}}.
var ui: Dictionary = {}
## Generated effects ({"sheet", "effects": {id: frames}}) and sounds
## ({"sounds": {id: path}}). Presentation only.
var fx: Dictionary = {}
var audio: Dictionary = {}
## Bundled fonts: {"thai": {"file", "license", ...}}.
var fonts: Dictionary = {}
## The first-time tutorial's steps, in order (tutorial.json).
var tutorial: Array = []
## The world boss: who, where, when it opens and its reward tiers
## (world_boss.json, see WorldBossRules).
var world_boss: Dictionary = {}
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
	db.weapons = db._section(dir, "weapons.json", "weapons")
	db.obstacles = db._section(dir, "obstacles.json", "obstacles")
	db.heroes = db._section(dir, "heroes.json", "heroes")
	db.hero_order = db._read(dir.path_join("heroes.json")).get("order", [])
	var skill_file := db._read(dir.path_join("skills.json"))
	db.skills = skill_file.get("skills", {})
	db.hotbar = skill_file.get("hotbar", [])
	db.tutorial = db._read(dir.path_join("tutorial.json")).get("steps", [])
	db.world_boss = db._read(dir.path_join("world_boss.json")).get("world_boss", {})
	db.item_cooldown = int(skill_file.get("item_cooldown", 0))
	var manifest := db._read(ART_MANIFEST)
	db.art = manifest.get("assets", {})
	db.environment = manifest.get("environment", {})
	db.kit = manifest.get("kit", {})
	db.ui = manifest.get("ui", {})
	db.fx = manifest.get("fx", {})
	db.audio = manifest.get("audio", {})
	db.fonts = manifest.get("fonts", {})
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


func hero(id: String) -> Dictionary:
	return heroes.get(id, {})


## The art a profile's hero shows: the look of the worn body item if the hero
## has art for it (e.g. "armoured"), else the hero's default.
## Where `item_id` comes from, for players: who drops it (and how often, and
## where they fight), who sells it, which quest gives it. Worked out from
## the loot tables, shops and quests, so it can never disagree with them.
## Each entry is {"kind": "drop" | "shop" | "quest", "text"}; drops come
## first, most likely first.
func sources(item_id: String) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	for enemy_id: String in enemies:
		for drop: Dictionary in enemies[enemy_id].get("loot", {}).get("drops", []):
			if drop["item"] != item_id:
				continue
			var where := _first_area_of(enemy_id)
			(
				drops
				. append(
					{
						"kind": "drop",
						"chance": float(drop["chance"]),
						"text":
						(
							"%s (%d%%)%s"
							% [
								enemies[enemy_id]["name"],
								roundi(float(drop["chance"]) * 100.0),
								"  -  " + where if where else ""
							]
						),
					}
				)
			)
	drops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["chance"] > b["chance"])
	var found: Array[Dictionary] = []
	found.append_array(drops)
	for shop_id: String in shops:
		if item_id in shops[shop_id].get("items", []):
			found.append(
				{
					"kind": "shop",
					"text": "%s, %d coins" % [shops[shop_id]["name"], int(item(item_id)["price"])]
				}
			)
	for quest_id: String in quests:
		if quests[quest_id].get("rewards", {}).get("items", {}).has(item_id):
			found.append({"kind": "quest", "text": 'Quest "%s"' % quests[quest_id]["name"]})
	return found


## The first area (in street order from the start) where `enemy_id` fights.
func _first_area_of(enemy_id: String) -> String:
	for area_id: String in areas:
		var area_data: Dictionary = areas[area_id]
		var found := false
		for placed: Dictionary in area_data.get("placed", []):
			found = found or placed["enemy"] == enemy_id
		for encounter: Dictionary in area_data.get("encounters", []):
			for wave: Variant in encounter.get("waves", []):
				found = found or enemy_id in JSON.stringify(wave)
		if found:
			return str(area_data["name"])
	return ""


func hero_art(profile: PlayerProfile) -> String:
	var sprites: Dictionary = hero(profile.hero).get("sprites", {})
	var look := str(item(profile.equipment["body"]).get("look", ""))
	return str(sprites.get(look, sprites.get("default", "")))


## The hotbar for one hero: the template with its skill slots filled in.
func hotbar_for(hero_id: String) -> Array[Dictionary]:
	var hero_skills: Array = hero(hero_id).get("skills", [])
	var result: Array[Dictionary] = []
	for slot: Dictionary in hotbar:
		var entry := slot.duplicate()
		if entry["type"] == "skill":
			entry["id"] = str(hero_skills[int(entry["hero_skill"])])
		result.append(entry)
	return result


func validate() -> void:
	var enhance: Dictionary = progression.get("enhance", {})
	var last_rate := 1.0
	for i in enhance.get("levels", []).size():
		var row: Dictionary = enhance["levels"][i]
		var where := "progression.enhance.levels[%d]" % i
		_number(row, "coins", where, 0)
		var rate := float(row.get("rate", -1))
		_check(rate > 0.0 and rate <= last_rate, where + ".rate: in (0, 1] and never rising")
		last_rate = rate
		for item_id: String in row.get("items", {}):
			_check(
				items.get(item_id, {}).get("type") == "material",
				"%s.items: %s is not a material" % [where, item_id]
			)
	for i in tutorial.size():
		var step: Variant = tutorial[i]
		var where := "tutorial.steps[%d]" % i
		if not step is Dictionary:
			errors.append(where + ": expected an object")
			continue
		_check(step.get("signal") in TutorialRules.SIGNALS, "%s.signal: unknown" % where)
		_number(step, "count", where, 1)
		_check(str(step.get("text", "")) != "", where + ".text: required")
	for id: String in enemies:
		_validate_enemy(id, enemies[id])
	_validate_world_boss()
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
	_validate_weapons()
	_validate_heroes()
	_validate_skills()
	_validate_art()


func _validate_enemy(id: String, e: Dictionary) -> void:
	var where := "enemies.%s" % id
	_number(e, "max_hp", where, 1)
	_number(e, "speed", where, 0)
	_number(e, "xp", where, 0)
	if e.has("poise"):
		_number(e, "poise", where, 1)
	var ranged: Variant = e.get("ranged", {})
	if ranged is Dictionary and not ranged.is_empty():
		_check(
			moves.get_move(str(ranged.get("move"))) != null, where + ".ranged.move: unknown move"
		)
		_check(
			weapons.has(str(ranged.get("projectile"))), where + ".ranged.projectile: no such weapon"
		)
		_number(ranged, "damage", where + ".ranged", 1)
		var band: Dictionary = e.get("ai", {}).get("ranged", {})
		_check(
			float(band.get("min", 0)) > 0 and float(band.get("max", 0)) > float(band.get("min", 0)),
			where + ".ai.ranged: needs 0 < min < max"
		)
	var hazard: Variant = e.get("hazard", {})
	if hazard is Dictionary and not hazard.is_empty():
		_check(bool(e.get("boss", false)), where + ".hazard: only bosses call hazards")
		_validate_hazard(hazard, where + ".hazard")
	var summon: Variant = e.get("summon", {})
	if summon is Dictionary and not summon.is_empty():
		_check(bool(e.get("boss", false)), where + ".summon: only bosses call reinforcements")
		_check(enemies.has(str(summon.get("enemy"))), where + ".summon.enemy: unknown enemy")
		for field in ["every", "count", "max"]:
			_number(summon, field, where + ".summon", 1)
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
			var own: Variant = phase.get("hazard", {})
			if own is Dictionary and not own.is_empty():
				_validate_hazard(own, where + ".phases.hazard")
			var shield: Variant = phase.get("shield", {})
			if shield is Dictionary and not shield.is_empty():
				for field in ["up", "down"]:
					_number(shield, field, where + ".phases.shield", 1)
	_validate_loot(e.get("loot", {}), where + ".loot")


func _validate_world_boss() -> void:
	var wb := world_boss
	var where := "world_boss"
	_check(enemy(str(wb.get("enemy"))).get("boss", false), where + ".enemy: must be a boss")
	_check(area(str(wb.get("area"))).get("world_boss", false), where + ".area: needs world_boss")
	_check(enemies.has(str(wb.get("unlock"))), where + ".unlock: unknown enemy")
	for field in ["period_minutes", "open_minutes", "attempt_seconds", "min_level", "pool"]:
		_number(wb, field, where, 1)
	_check(
		int(wb.get("open_minutes", 0)) < int(wb.get("period_minutes", 0)),
		where + ".open_minutes: shorter than the period"
	)
	var last := 0.0
	for tier: Variant in wb.get("tiers", []):
		if not tier is Dictionary:
			errors.append(where + ".tiers: expected objects")
			continue
		var share := float(tier.get("share", 0))
		_check(share > last and share <= 1.0, where + ".tiers.share: rising, at most 1")
		last = share
		_number(tier, "money", where + ".tiers", 0)
		for item_id: String in tier.get("items", {}):
			_check(items.has(item_id), where + ".tiers.items: unknown " + item_id)
		for item_id: String in tier.get("rolls", {}):
			_check(items.has(item_id), where + ".tiers.rolls: unknown " + item_id)
			var chance := float(tier["rolls"][item_id])
			_check(chance > 0.0 and chance <= 1.0, where + ".tiers.rolls: chance in (0, 1]")
	_check(last == 1.0, where + ".tiers: the last tier is the whole pool")


## A boss hazard: how often ("every"), and either one hazard (its "kind",
## "warn", "damage" and "half") or a "cycle" of them called in turn.
func _validate_hazard(hazard: Dictionary, where: String) -> void:
	_number(hazard, "every", where, 1)
	var cycle: Variant = hazard.get("cycle", [hazard])
	_check(cycle is Array and not cycle.is_empty(), where + ".cycle: expected hazards")
	if not cycle is Array:
		return
	for entry: Variant in cycle:
		if not entry is Dictionary:
			errors.append(where + ".cycle: expected objects")
			continue
		_check(
			str(entry.get("kind", "crane")) in BossMechanics.KINDS,
			where + ".kind: one of " + ", ".join(BossMechanics.KINDS)
		)
		for field in ["warn", "damage"]:
			_number(entry, field, where, 1)
		var half: Variant = entry.get("half")
		_check(half is Array and half.size() == 2, where + ".half: [x, y]")


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
	_check(it.get("rarity") in RARITIES, "%s.rarity: expected one of %s" % [where, RARITIES])
	_check(str(it.get("name", "")) != "", where + ".name: required")
	_check(str(it.get("description", "")) != "", where + ".description: required")
	_number(it, "price", where, 0)
	for field in ["heal", "energy"]:
		if it.has(field):
			_number(it, field, where, 0)
	if it.get("type") == "equipment":
		_check(
			it.get("slot") in PlayerProfile.SLOTS,
			"%s.slot: expected one of %s" % [where, PlayerProfile.SLOTS]
		)
		_number(it, "level", where, 1)
		var stats: Variant = it.get("stats")
		_check(stats is Dictionary and not stats.is_empty(), where + ".stats: expected bonuses")
		if stats is Dictionary:
			for key: String in stats:
				_check(key in PlayerProfile.STAT_KEYS, "%s.stats: unknown stat %s" % [where, key])
				var value: Variant = stats[key]
				_check(
					value is float or value is int, "%s.stats.%s: expected a number" % [where, key]
				)
	if it.get("type") == "key":
		_check(int(it.get("price", 0)) == 0, "%s: story items are not for sale" % where)
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
	var dialogue: Variant = q.get("dialogue", {})
	_check(dialogue is Dictionary, where + ".dialogue: expected an object")
	if dialogue is Dictionary:
		for key: String in dialogue:
			_check(key in DIALOGUE_LINES, "%s.dialogue: unknown line %s" % [where, key])
			_check(str(dialogue[key]) != "", "%s.dialogue.%s: empty" % [where, key])
	var ends: Variant = q.get("ends_chapter", {})
	_check(
		ends is Dictionary and (ends.is_empty() or str(ends.get("title", "")) != ""),
		where + ".ends_chapter: needs a title"
	)
	if ends is Dictionary and ends.has("epilogue"):
		var lines: Variant = ends["epilogue"]
		_check(
			(
				lines is Array
				and not lines.is_empty()
				and lines.all(func(l: Variant) -> bool: return l is String)
			),
			where + ".ends_chapter.epilogue: expected lines of text"
		)


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
			var requires: Variant = exits[side].get("requires", {})
			if requires is Dictionary and not requires.is_empty():
				var gate := "%s.exits.%s.requires" % [where, side]
				_check(
					enemies.has(str(requires.get("defeat"))),
					"%s.defeat: unknown enemy %s" % [gate, requires.get("defeat")]
				)
				_number(requires, "count", gate, 1)
				_check(str(requires.get("hint", "")) != "", "%s.hint: say what opens it" % gate)
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
	for obstacle: Variant in a.get("obstacles", []):
		_check(
			obstacle is Dictionary and obstacles.has(str(obstacle.get("kind"))),
			"%s.obstacles: unknown kind %s" % [where, obstacle]
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


func _validate_weapons() -> void:
	for id: String in weapons:
		var where := "weapons.%s" % id
		var weapon: Variant = weapons[id]
		if not weapon is Dictionary:
			errors.append(where + ": expected an object")
			continue
		_check(str(weapon.get("name", "")) != "", where + ".name: required")
		_number(weapon, "durability", where, 1)
		_number(weapon, "weight", where, 0)
		_number(weapon, "min_level", where, 1)
		_number(weapon, "speed", where, 0.1)
		_check(weapon.get("grip") in ["hand", "overhead"], where + ".grip: hand or overhead")
		_check(
			weapon.get("material") in ["wood", "metal", "glass"],
			where + ".material: wood, metal or glass"
		)
		_validate_moveset(weapon.get("moveset", {}), where)
		_check(not weapon.get("moveset", {}).is_empty(), where + ".moveset: required")
	for id: String in areas:
		var spec: Variant = areas[id].get("weapons", {})
		if spec is Dictionary and not spec.is_empty():
			var count: Variant = spec.get("count")
			_check(
				count is Array and count.size() == 2 and count[0] <= count[1],
				"areas.%s.weapons.count: expected [min, max]" % id
			)
			for weapon_id: String in spec.get("pool", {}):
				_check(weapons.has(weapon_id), "areas.%s.weapons: unknown %s" % [id, weapon_id])
		_number(areas[id], "level", "areas.%s" % id, 1)


func _validate_heroes() -> void:
	_check(not hero_order.is_empty(), "heroes.order: at least one hero")
	for id: Variant in hero_order:
		_check(heroes.has(str(id)), "heroes.order: unknown hero %s" % id)
	for id: String in heroes:
		var where := "heroes.%s" % id
		var h: Variant = heroes[id]
		if not h is Dictionary:
			errors.append(where + ": expected an object")
			continue
		for field in ["name", "default_name", "title", "tagline", "bio"]:
			_check(str(h.get(field, "")) != "", "%s.%s: required" % [where, field])
		_check(
			PlayerProfile.clean_name(str(h.get("default_name", ""))) != "",
			"%s.default_name: not a valid player name" % where
		)
		var stats: Variant = h.get("stats")
		_check(stats is Dictionary, where + ".stats: expected an object")
		if stats is Dictionary:
			for stat: String in HERO_STATS:
				_number(stats, stat, where + ".stats", 0)
			_check(float(stats.get("max_hp", 0)) >= 1, where + ".stats.max_hp: at least 1")
			_check(float(stats.get("speed", 0)) > 0, where + ".stats.speed: above 0")
			_check(
				float(stats.get("crit", 0.0)) <= PlayerProfile.MAX_CRIT,
				where + ".stats.crit: at most the crit cap"
			)
		_number(h, "difficulty", where, 1)
		if h.has("parry_window"):
			var window := int(h["parry_window"])
			_check(window >= 1 and window <= 20, where + ".parry_window: 1 to 20 ticks")
		_check(h.get("skill_armor", false) is bool, where + ".skill_armor: true or false")
		var sprites: Variant = h.get("sprites")
		_check(
			sprites is Dictionary and sprites.has("default"), where + ".sprites.default: required"
		)
		var starter: Variant = h.get("starter", {})
		if starter is Dictionary:
			for item_id: Variant in starter.get("equipment", []):
				var gear := item(str(item_id))
				_check(
					gear.get("type") == "equipment" and int(gear.get("level", 1)) == 1,
					"%s.starter: %s is not level 1 equipment" % [where, item_id]
				)
			for item_id: Variant in starter.get("items", {}):
				_check(items.has(str(item_id)), "%s.starter: unknown item %s" % [where, item_id])
		var hero_skills: Variant = h.get("skills")
		_check(
			hero_skills is Array and hero_skills.size() == HERO_SKILLS,
			"%s.skills: expected %d skills" % [where, HERO_SKILLS]
		)
		if hero_skills is Array:
			for skill_id: Variant in hero_skills:
				_check(skills.has(str(skill_id)), "%s.skills: unknown skill %s" % [where, skill_id])
	# Every item look (e.g. "armoured") must exist for every hero.
	for item_id: String in items:
		var look := str(items[item_id].get("look", ""))
		if look == "":
			continue
		for id: String in heroes:
			_check(
				heroes[id] is Dictionary and heroes[id].get("sprites", {}).has(look),
				"items.%s.look: hero %s has no %s sprite" % [item_id, id, look]
			)


func _validate_progression() -> void:
	_number(progression, "max_level", "progression", 1)
	var xp: Variant = progression.get("xp")
	_check(xp is Dictionary, "progression.xp: expected an object")
	if xp is Dictionary:
		_number(xp, "base", "progression.xp", 1)
		_number(xp, "growth", "progression.xp", 0)
		if xp.has("square"):
			_number(xp, "square", "progression.xp", 0)


func _validate_skills() -> void:
	var icons: Dictionary = ui.get("icons", {}).get("regions", {})
	for id: String in skills:
		var where := "skills.%s" % id
		var skill: Variant = skills[id]
		if not skill is Dictionary:
			errors.append(where + ": expected an object")
			continue
		_check(moves.moves.has(str(skill.get("move"))), "%s.move: unknown move" % where)
		_number(skill, "cooldown", where, 1)
		_number(skill, "unlock_level", where, 1)
		for field in ["name", "description"]:
			_check(str(skill.get(field, "")) != "", "%s.%s: required" % [where, field])
		_check(icons.has(str(skill.get("icon"))), "%s.icon: no such icon" % where)
		_check(fx.get("effects", {}).has(str(skill.get("fx"))), "%s.fx: no such effect" % where)
		_check(
			audio.get("sounds", {}).has(str(skill.get("sound"))), "%s.sound: no such sound" % where
		)
	_check(hotbar.size() == HOTBAR_SLOTS, "skills.hotbar: expected %d slots" % HOTBAR_SLOTS)
	for i in hotbar.size():
		var slot: Variant = hotbar[i]
		var where := "skills.hotbar[%d]" % i
		if not slot is Dictionary or slot.get("type") not in HOTBAR_TYPES:
			errors.append(where + ': expected {"type": attack|skill|item}')
			continue
		match slot["type"]:
			"skill":
				var index: Variant = slot.get("hero_skill")
				_check(
					(index is int or index is float) and index >= 0 and index < HERO_SKILLS,
					where + ": hero_skill must be 0..%d" % (HERO_SKILLS - 1)
				)
			"item":
				var item_data := item(str(slot.get("id")))
				_check(item_data.get("type") == "consumable", where + ": not a consumable")
			"attack":
				_check(icons.has(str(slot.get("icon"))), where + ": no such icon")
	_check(item_cooldown >= 0, "skills.item_cooldown: expected >= 0")


## Every sprite named by content must be an imported asset.
func _validate_art() -> void:
	var wanted := {}
	for id: String in enemies:
		if enemies[id].has("sprite"):
			wanted[enemies[id]["sprite"]] = "enemies.%s.sprite" % id
	for id: String in areas:
		for npc: Dictionary in areas[id].get("npcs", []):
			if npc.has("sprite"):
				wanted[npc["sprite"]] = "areas.%s.npcs.%s.sprite" % [id, npc.get("id")]
	for id: String in heroes:
		if heroes[id] is Dictionary:
			var sprites: Dictionary = heroes[id].get("sprites", {})
			for look: String in sprites:
				wanted[sprites[look]] = "heroes.%s.sprites.%s" % [id, look]
	var icons: Dictionary = ui.get("icons", {}).get("regions", {})
	for id: String in items:
		var icon := str(items[id].get("icon", ""))
		_check(
			icon == "" or icons.has(icon), "items.%s.icon: no icon %s in the UI sheet" % [id, icon]
		)
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
