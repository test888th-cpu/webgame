class_name ProgressionHarness
extends RefCounted
## Measures progression and the economy from the game's own rules, for
## balance decisions. It only reads content and runs the shared simulation:
## it changes no game data, saves nothing and writes no file (HarnessRun
## does the writing, outside the repository).
##
## Two kinds of numbers:
## * the story XP model: exact arithmetic over the data and LevelRules (every
##   story fight once, every quest), no simulation;
## * simulated runs: ZoneSim played by the game's own AutoPilot (the auto
##   battle brain), so times and drops are what auto battle achieves, not
##   what a person would. Seeds are fixed, so a run repeats exactly.

const SLOTS := ["head", "body", "hands", "feet", "weapon", "charm"]
const ARMOUR := ["head", "body", "hands", "feet"]
const SCRAP := "scrap_metal"
const ALLOY := "refined_alloy"


## The story XP model. `scenario` keys (all optional): "flat_threat" (ignore
## the level-gap XP multipliers), "passes" (clear every area this many
## times; quests count once), "boss_repeats" (extra kills of each boss).
## Returns {"areas": [per area], "quest_xp", "combat_xp", "level", "xp",
## "to_cap"}, levelling a real PlayerProfile with PlayerProfile.add_xp.
static func story_model(content: ContentDB, scenario := {}) -> Dictionary:
	var hero := PlayerProfile.new_game(content)
	var flat := bool(scenario.get("flat_threat", false))
	var passes := maxi(1, int(scenario.get("passes", 1)))
	var repeats := maxi(0, int(scenario.get("boss_repeats", 0)))
	var quest_xp := {}
	for quest: Dictionary in content.quests.values():
		var where := str(quest.get("objective", {}).get("area", ""))
		quest_xp[where] = int(quest_xp.get(where, 0)) + int(quest["rewards"].get("xp", 0))
	var rows: Array = []
	var total_quest := 0
	var total_combat := 0
	for area_id in StreetMemory.street(content):
		var area := content.area(area_id)
		var row := {
			"area": area_id, "area_level": int(area.get("level", 1)), "level_in": hero.level
		}
		var combat := 0
		for kind: String in _area_kinds(content, area_id):
			var data := content.enemy(kind)
			var kills := passes + (repeats if data.get("boss", false) else 0)
			for i in kills:
				var gained := _kill_xp(content, kind, row["area_level"], hero.level, flat)
				combat += gained
				hero.add_xp(gained, content)
		var quests := int(quest_xp.get(area_id, 0))
		hero.add_xp(quests, content)
		row["combat_xp"] = combat
		row["quest_xp"] = quests
		row["level_out"] = hero.level
		total_quest += quests
		total_combat += combat
		rows.append(row)
	return {
		"areas": rows,
		"quest_xp": total_quest,
		"combat_xp": total_combat,
		"level": hero.level,
		"xp": hero.xp,
		"to_cap": xp_to_cap(content, hero.level, hero.xp),
	}


## XP still needed from `level` (with `xp` into it) to the level cap.
static func xp_to_cap(content: ContentDB, level: int, xp: int) -> int:
	var step := PlayerProfile.new()
	var top := step.max_level(content)
	var left := 0
	for l in range(level, top):
		step.level = l
		left += step.xp_to_next(content)
	return maxi(0, left - xp) if level < top else 0


## Every enemy kind in `area_id`'s encounters, one entry per spawn.
static func _area_kinds(content: ContentDB, area_id: String) -> Array[String]:
	var kinds: Array[String] = []
	for encounter: Dictionary in content.area(area_id).get("encounters", []):
		for wave: Array in encounter["waves"]:
			for kind: String in wave:
				kinds.append(kind)
	return kinds


static func _kill_xp(
	content: ContentDB, kind: String, area_level: int, hero_level: int, flat: bool
) -> int:
	var data := content.enemy(kind)
	var level := LevelRules.enemy_level(data, area_level)
	var xp := int(LevelRules.enemy_stats(data, level)["xp"])
	return xp if flat else roundi(xp * LevelRules.xp_scale(level, hero_level))


## The boss fighting in `area_id`, or "" when there is none.
static func boss_of(content: ContentDB, area_id: String) -> String:
	for kind in _area_kinds(content, area_id):
		if content.enemy(kind).get("boss", false):
			return kind
	return ""


## What one kill of boss `kind` in an area of `area_level` is worth, from the
## data: expected coins (loot midpoint, scaled like LevelRules), XP at an
## even level, its unique item and chance, and its guaranteed drops.
static func boss_value(content: ContentDB, kind: String, area_level: int) -> Dictionary:
	var data := content.enemy(kind)
	var level := LevelRules.enemy_level(data, area_level)
	var stats := LevelRules.enemy_stats(data, level)
	var money: Array = data["loot"]["money"]
	var unique := ""
	var chance := 0.0
	var sure: Array = []
	for drop: Dictionary in data["loot"].get("drops", []):
		var item := str(drop["item"])
		if float(drop["chance"]) >= 1.0:
			sure.append(item)
		elif content.item(item).get("type") == "equipment" and float(drop["chance"]) > chance:
			unique = item
			chance = float(drop["chance"])
	return {
		"boss": kind,
		"level": level,
		"coins": (float(money[0]) + float(money[1])) / 2.0 * float(stats["money_scale"]),
		"xp": int(stats["xp"]),
		"unique": unique,
		"chance": chance,
		"guaranteed": sure,
	}


## Equipment for a hero of `level`, chosen from the data, never hard-coded.
## "shop": per slot the highest-level item any shop sells (ties: higher
## price); the charm is the best quest-reward charm. "boss": the same armour,
## with the best boss-drop weapon and charm when one is not above `level`.
static func gear(content: ContentDB, level: int, kind := "shop") -> Array[String]:
	var sold := {}
	for shop: Dictionary in content.shops.values():
		for item_id: String in shop.get("items", []):
			sold[item_id] = true
	var rewarded := {}
	for quest: Dictionary in content.quests.values():
		for item_id: String in quest["rewards"].get("items", {}):
			rewarded[item_id] = true
	var dropped := {}
	for data: Dictionary in content.enemies.values():
		if data.get("boss", false):
			for drop: Dictionary in data["loot"].get("drops", []):
				dropped[str(drop["item"])] = true
	var picked: Array[String] = []
	for slot: String in SLOTS:
		var pool := sold
		if slot == "charm":
			pool = rewarded
		if kind == "boss" and slot in ["weapon", "charm"]:
			var from_boss := _best(content, dropped, slot, level)
			if from_boss != "":
				picked.append(from_boss)
				continue
		var best := _best(content, pool, slot, level)
		if best != "":
			picked.append(best)
	return picked


static func _best(content: ContentDB, pool: Dictionary, slot: String, level: int) -> String:
	var best := ""
	for item_id: String in pool:
		var item := content.item(item_id)
		if item.get("slot") != slot or int(item.get("level", 1)) > level:
			continue
		if best == "" or _better(item, content.item(best)):
			best = item_id
	return best


static func _better(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("level", 1)) != int(b.get("level", 1)):
		return int(a.get("level", 1)) > int(b.get("level", 1))
	return int(a.get("price", 0)) > int(b.get("price", 0))


## One simulated run of `area_id` by `hero_id` at `level` with gear `kind`,
## played by AutoPilot from the west edge until the area is clear, the hero
## is down, or `max_ticks` pass. `boss_only` pre-clears every encounter
## without a boss (a stand-in for a boss rematch). `food` is carried.
## Returns times in ticks and seconds and what was gained and spent.
static func run_area(content: ContentDB, setup: Dictionary) -> Dictionary:
	var area_id := str(setup["area"])
	var level := int(setup.get("level", content.area(area_id).get("level", 1)))
	var profile := PlayerProfile.new_game(content, str(setup.get("hero", "")))
	profile.level = level
	for item_id in gear(content, level, str(setup.get("gear", "shop"))):
		profile.add_item(item_id)
		profile.equip(item_id, content)
	var food: Dictionary = setup.get("food", {})
	for item_id: String in food:
		profile.add_item(item_id, int(food[item_id]))
	if bool(setup.get("boss_only", false)):
		_clear_all_but_boss(content, profile, area_id)
	var zone := ZoneSim.new(content, profile, area_id, "west", int(setup.get("seed", 1)))
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	var pilot := AutoPilot.new(content)
	var before := _wealth(content, profile, food)
	var last_hp := zone.hero.hp
	var taken := 0
	var ticks := 0
	var limit := int(setup.get("max_ticks", 36000))
	while ticks < limit:
		ticks += 1
		var input := pilot.think(zone)
		if pilot.item:
			zone.use_item(pilot.item)
		zone.tick(input)
		taken += maxi(0, last_hp - zone.hero.hp)
		last_hp = zone.hero.hp
		if pilot.status == AutoPilot.STATUS_CLEAR or zone.hero.is_ko():
			break
	var after := _wealth(content, profile, food)
	return {
		"area": area_id,
		"hero": profile.hero,
		"level": level,
		"gear": str(setup.get("gear", "shop")),
		"seed": int(setup.get("seed", 1)),
		"boss_only": bool(setup.get("boss_only", false)),
		"ticks": ticks,
		"seconds": float(ticks) / CombatRules.TICK_RATE,
		"clear": pilot.status == AutoPilot.STATUS_CLEAR,
		"ko": zone.hero.is_ko(),
		"xp": int(after["xp"]) - int(before["xp"]),
		"coins": int(after["coins"]) - int(before["coins"]),
		"scrap": int(after["scrap"]) - int(before["scrap"]),
		"alloy": int(after["alloy"]) - int(before["alloy"]),
		"food_used": int(before["food"]) - int(after["food"]),
		"damage_taken": taken,
		"max_hp": zone.hero.max_hp,
	}


static func _clear_all_but_boss(
	content: ContentDB, profile: PlayerProfile, area_id: String
) -> void:
	var encounters: Array = content.area(area_id).get("encounters", [])
	for i in encounters.size():
		var has_boss := false
		for wave: Array in encounters[i]["waves"]:
			for kind: String in wave:
				has_boss = has_boss or content.enemy(kind).get("boss", false)
		if not has_boss:
			StreetMemory.mark_cleared(profile, area_id, i)


## Total XP earned so far, coins, materials and food carried.
static func _wealth(content: ContentDB, profile: PlayerProfile, food: Dictionary) -> Dictionary:
	var step := PlayerProfile.new()
	var total := profile.xp
	for l in range(1, profile.level):
		step.level = l
		total += step.xp_to_next(content)
	var meals := 0
	for item_id: String in food:
		meals += profile.count(item_id)
	return {
		"xp": total,
		"coins": profile.money,
		"scrap": profile.count(SCRAP),
		"alloy": profile.count(ALLOY),
		"food": meals,
	}


## Per-minute rates and means over `runs` (all of one area and setup).
static func summarize(runs: Array) -> Dictionary:
	var seconds := 0.0
	var sums := {"xp": 0, "coins": 0, "scrap": 0, "alloy": 0, "food_used": 0}
	var knockouts := 0
	var damage := 0.0
	for run: Dictionary in runs:
		seconds += float(run["seconds"])
		for key: String in sums:
			sums[key] += int(run[key])
		knockouts += 1 if run["ko"] else 0
		damage += float(run["damage_taken"]) / maxf(1.0, float(run["max_hp"]))
	var count := maxi(1, runs.size())
	var minutes := maxf(seconds / 60.0, 0.0001)
	return {
		"runs": runs.size(),
		"knockouts": knockouts,
		"seconds_mean": seconds / count,
		"xp_per_min": sums["xp"] / minutes,
		"coins_per_min": sums["coins"] / minutes,
		"scrap_per_min": sums["scrap"] / minutes,
		"alloy_per_min": sums["alloy"] / minutes,
		"food_per_run": float(sums["food_used"]) / count,
		"damage_share_per_run": damage / count,
	}


## Comparison scenarios for repeat boss rewards. They are NOT game values:
## `models` holds the parameters to compare (from the harness config), and
## nothing here changes what the game pays. `area` and `boss_only` are
## summaries of a boss area and of its boss-only runs; `value` is boss_value.
static func boss_models(
	area: Dictionary, boss_only: Dictionary, value: Dictionary, models: Dictionary
) -> Dictionary:
	var area_minutes := maxf(float(area["seconds_mean"]) / 60.0, 0.0001)
	var solo_minutes := maxf(float(boss_only["seconds_mean"]) / 60.0, 0.0001)
	var coin_cut := 1.0 - float(models.get("repeat_boss_coin_share", 1.0))
	var cut_coins := float(value["coins"]) * coin_cut
	var alloy_cut := 1.0 if ALLOY in value["guaranteed"] else 0.0
	var chance := maxf(float(value["chance"]), 0.0001)
	var wins := maxi(1, int(models.get("rematch_wins_per_item", 1)))
	var current := {
		"xp_per_min": area["xp_per_min"],
		"coins_per_min": area["coins_per_min"],
		"alloy_per_min": area["alloy_per_min"],
		"minutes_per_unique": area_minutes / chance,
	}
	var reduced := {
		"xp_per_min": area["xp_per_min"],
		"coins_per_min": area["coins_per_min"] - cut_coins / area_minutes,
		"alloy_per_min": maxf(0.0, area["alloy_per_min"] - alloy_cut / area_minutes),
		"minutes_per_unique": area_minutes / chance,
	}
	var story_repeat := reduced.duplicate()
	story_repeat["minutes_per_unique"] = -1.0
	var rematch := {
		"xp_per_min": boss_only["xp_per_min"],
		"coins_per_min": boss_only["coins_per_min"] - cut_coins / solo_minutes,
		"alloy_per_min": maxf(0.0, boss_only["alloy_per_min"] - alloy_cut / solo_minutes),
		"minutes_per_unique": solo_minutes * wins,
	}
	return {
		"model_1_current": current,
		"model_2_reduced_repeat": reduced,
		"model_3_story_repeat": story_repeat,
		"model_3_rematch": rematch,
	}
