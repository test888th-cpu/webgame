extends TestCase
## Levels 1-50: enemies grow tougher and smarter at the hero's own pace, areas
## climb level bands by chapter, names are coloured by the level gap, and
## weapons are rolled by level.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _rng(seed := 3) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


func test_level_one_is_the_enemy_as_written() -> void:
	var data := _content().enemy("smogling")
	var stats := LevelRules.enemy_stats(data, 1)
	assert_eq(stats["max_hp"], int(data["max_hp"]), "hp unchanged")
	assert_near(stats["power"], float(data.get("power", 1.0)), "power unchanged")
	assert_eq(stats["xp"], int(data["xp"]), "xp unchanged")


func test_higher_levels_are_tougher_and_pay_more() -> void:
	var data := _content().enemy("dock_thug")
	var low := LevelRules.enemy_stats(data, 1)
	var high := LevelRules.enemy_stats(data, 20)
	assert_true(high["max_hp"] > low["max_hp"], "more hp")
	assert_true(high["power"] > low["power"], "hits harder")
	assert_true(high["defense"] > low["defense"], "more defense")
	assert_true(high["xp"] > low["xp"], "more xp")
	assert_true(high["money_scale"] > 1.0, "more money")
	assert_true(
		LevelRules.enemy_stats(data, 99)["speed"] <= float(data["speed"]) * 1.25 + 0.001,
		"speed capped"
	)


func test_higher_levels_think_faster_and_learn_tricks() -> void:
	var ai: Dictionary = _content().enemy("dock_thug")["ai"]
	var rookie := LevelRules.enemy_ai(ai, 1, true)
	var veteran := LevelRules.enemy_ai(ai, 20, true)
	assert_true(veteran["reaction"] < rookie["reaction"], "reacts sooner")
	assert_true(veteran["cooldown"] < rookie["cooldown"], "attacks more often")
	assert_eq(rookie["guard_chance"], 0.0, "rookies never guard")
	assert_eq(rookie["dodge_chance"], 0.0, "rookies never dodge")
	assert_true(not rookie["scavenge"], "rookies ignore weapons")
	assert_true(veteran["guard_chance"] > 0.0, "veterans guard")
	assert_true(veteran["dodge_chance"] > 0.0, "veterans dodge")
	assert_true(veteran["scavenge"], "veterans grab weapons")


func test_areas_chain_east_with_rising_levels() -> void:
	var area_id := "depot_yard"
	var last := 0
	var seen: Array[String] = []
	while area_id != "" and area_id not in seen:
		seen.append(area_id)
		var area := _content().area(area_id)
		assert_true(int(area["level"]) >= last, "%s is no easier than before" % area_id)
		last = int(area["level"])
		area_id = str(area.get("exits", {}).get("east", {}).get("to", ""))
	assert_true("refinery" in seen, "the chain reaches the refinery")
	assert_true(last >= 20, "the last area is level 20 or more")


func test_weapon_rolls_respect_level_and_replay() -> void:
	var weapons := _content().weapons
	for i in 200:
		var id := LevelRules.roll_weapon(weapons, 1, _rng(i))
		assert_true(int(weapons[id].get("min_level", 1)) <= 1, "%s allowed at level 1" % id)
	var first: Array[String] = []
	var second: Array[String] = []
	var a := _rng(9)
	var b := _rng(9)
	for i in 20:
		first.append(LevelRules.roll_weapon(weapons, 8, a))
		second.append(LevelRules.roll_weapon(weapons, 8, b))
	assert_eq(first, second, "same seed, same weapons")
	var pooled := LevelRules.roll_weapon(weapons, 8, _rng(), {"pipe": 1})
	assert_eq(pooled, "pipe", "the pool limits the choice")


func test_enemies_spawn_at_the_area_level() -> void:
	var profile := PlayerProfile.new_game(_content())
	var zone := ZoneSim.new(_content(), profile, "refinery", "", 5)
	var enemy := zone.spawn_enemy("dock_thug", Vector2(400, 300))
	assert_eq(zone.enemy_level(enemy.id), 9, "fights at the Refinery's level 9")
	assert_true(enemy.max_hp > int(_content().enemy("dock_thug")["max_hp"]), "scaled hp")


func test_a_veteran_guards_or_dodges_a_wind_up() -> void:
	var ai: Dictionary = _content().enemy("dock_thug")["ai"].duplicate()
	ai["guard_chance"] = 1.0
	var brain := EnemyBrain.new(ai, _rng())
	var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(130, 300))
	var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(100, 300))
	hero.facing = 1
	hero.state = Fighter.State.ATTACK
	hero.move = _content().moves.get_move("jab")
	hero.state_tick = 1
	var input := brain.think(me, hero, false, _content().moves, _rng(), Vector2.INF, 10)
	assert_true(input.guard, "guards the incoming jab")
	me.state = Fighter.State.GUARD
	assert_true(
		brain.think(me, hero, false, _content().moves, _rng(), Vector2.INF, 11).guard,
		"keeps guarding through the swing"
	)


func test_a_scavenger_walks_to_a_weapon_and_picks_it_up() -> void:
	var ai: Dictionary = _content().enemy("dock_thug")["ai"].duplicate()
	ai["scavenge"] = true
	var brain := EnemyBrain.new(ai, _rng())
	var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(200, 300))
	var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(400, 300))
	var input := brain.think(me, hero, false, _content().moves, _rng(), Vector2(260, 300))
	assert_true(input.move.x > 0.0, "heads for the weapon")
	input = brain.think(me, hero, false, _content().moves, _rng(), Vector2(204, 302))
	assert_true(input.pick, "picks it up when standing on it")


func test_elites_and_bosses_fight_above_their_area() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "refinery", "", 5)
	var elite := zone.spawn_enemy("refinery_enforcer", Vector2(400, 300))
	var boss := zone.spawn_enemy("furnace_baron", Vector2(500, 300))
	assert_eq(zone.enemy_level(elite.id), 10, "an elite is one level up")
	assert_eq(zone.enemy_level(boss.id), 11, "a boss two")
	var data := {"boss": true, "level_bonus": 0}
	assert_eq(LevelRules.enemy_level(data, 9), 9, "unless level_bonus says otherwise")


func test_chapters_climb_their_level_bands() -> void:
	# Chapter 1's streets run levels 1-10, Chapter 2's 11-16, Chapter 3's 19-24
	# Chapter 4's 26-31 and Chapter 5's 33-39; their elites and bosses stand at
	# most two higher.
	var bands := {
		"gang_hq": [1, 10],
		"crane_yard": [11, 16],
		"factory_drains": [19, 24],
		"sak_tower": [26, 31],
		"control_room": [33, 39],
	}
	var street := StreetMemory.street(_content())
	var low := 1
	for area_id in street:
		var area := _content().area(area_id)
		var level := int(area["level"])
		var band: Array = []
		for end: String in bands:
			if street.find(area_id) <= street.find(end):
				band = bands[end]
				break
		var top := 0
		for enemy_id: String in _encounter_enemies(area):
			top = maxi(top, LevelRules.enemy_level(_content().enemy(enemy_id), level))
		assert_true(level >= int(band[0]) and level <= int(band[1]), "%s in its band" % area_id)
		assert_true(top <= int(band[1]) + 2, "%s's toughest foe stays near the band" % area_id)
		assert_true(level >= low, "%s never drops a level" % area_id)
		low = level
	assert_eq(_content().progression["max_level"], 50, "the hero can reach level 50")


func test_early_enemies_are_simple_minded() -> void:
	# Chapter 1 foes (levels 1-10) barely guard, almost never dodge and react
	# little faster than as written: no level 20-30 brains on South Street.
	var ai: Dictionary = _content().enemy("dock_thug")["ai"]
	for level in range(1, 4):
		assert_eq(
			LevelRules.enemy_ai(ai, level, true)["guard_chance"], 0.0, "no guard at %d" % level
		)
	var ten := LevelRules.enemy_ai(ai, 10, true)
	assert_true(ten["guard_chance"] <= 0.15, "rare guarding at 10")
	assert_true(ten["dodge_chance"] <= 0.05, "rare dodging at 10")
	assert_true(ten["reaction"] >= int(ai.get("reaction", 12)) * 0.85, "reactions near as written")
	var thirty := LevelRules.enemy_ai(ai, 30, true)
	assert_true(thirty["guard_chance"] > ten["guard_chance"] * 2.0, "much sharper by 30")
	assert_true(thirty["reaction"] < ten["reaction"], "and quicker")


func test_an_enemy_at_the_heroes_level_stays_a_fair_fight() -> void:
	# Enemy health against hero power, and enemy power against hero health,
	# change only a little between level 1 and level 50.
	var hero := PlayerProfile.new_game(_content())
	var data := _content().enemy("dock_thug")
	var ratios: Array[Vector2] = []
	for level: int in [1, 25, 50]:
		hero.level = level
		var mine := hero.stats(_content())
		var theirs := LevelRules.enemy_stats(data, level)
		ratios.append(
			Vector2(
				float(theirs["max_hp"]) / float(mine["power"]),
				float(theirs["power"]) / float(mine["max_hp"])
			)
		)
	for i in range(1, ratios.size()):
		assert_true(ratios[i].x / ratios[0].x < 1.35, "hits to kill barely change (%d)" % i)
		assert_true(ratios[i].y / ratios[0].y > 0.6, "their hits still count (%d)" % i)


func test_names_are_coloured_by_the_level_gap() -> void:
	assert_eq(LevelRules.threat(10, 10), "even", "same level")
	assert_eq(LevelRules.threat(12, 10), "even", "two above is still even")
	assert_eq(LevelRules.threat(13, 10), "tough", "three above")
	assert_eq(LevelRules.threat(16, 10), "deadly", "six above")
	assert_eq(LevelRules.threat(7, 10), "easy", "three below")
	assert_eq(LevelRules.threat(4, 10), "trivial", "six below")
	for threat: String in ["trivial", "easy", "even", "tough", "deadly"]:
		assert_true(UiTheme.THREAT.has(threat), "%s has a colour" % threat)


func test_far_weaker_enemies_pay_little_xp() -> void:
	var profile := PlayerProfile.new_game(_content())
	var zone := ZoneSim.new(_content(), profile, "saltmarket", "", 5)
	var xp := {}
	for level: int in [2, 12]:
		profile.level = level
		profile.xp = 0
		var enemy := zone.spawn_enemy("smogling", Vector2(400, 300))
		zone.brains.erase(enemy.id)
		enemy.hp = 0
		var events: Array[ZoneEvent] = []
		zone._defeat(enemy, events)
		for event in events:
			if event.type == "defeat":
				xp[level] = int(event.data["xp"])
	assert_true(int(xp[2]) > 0, "a fair foe pays")
	assert_true(int(xp[12]) * 5 <= int(xp[2]), "one ten levels down pays a tenth or so")


func test_a_straight_run_keeps_the_hero_near_each_area_level() -> void:
	# Clearing each area once and handing in each quest on the way leaves the
	# hero within two levels of every area on arrival (from the Canal Works on).
	var quests := _content().quests
	var hero := PlayerProfile.new_game(_content())
	var kills := {}
	var done := {}
	for area_id in StreetMemory.street(_content()):
		var area := _content().area(area_id)
		var level := int(area["level"])
		if level >= 3:
			assert_true(absi(hero.level - level) <= 2, "%s: hero %d" % [area_id, hero.level])
		for enemy_id: String in _encounter_enemies(area):
			var data := _content().enemy(enemy_id)
			var at := LevelRules.enemy_level(data, level)
			var xp: int = LevelRules.enemy_stats(data, at)["xp"]
			hero.add_xp(roundi(xp * LevelRules.xp_scale(at, hero.level)), _content())
			kills[enemy_id] = int(kills.get(enemy_id, 0)) + 1
			var handed := true
			while handed:
				handed = false
				for quest_id: String in quests:
					var quest: Dictionary = quests[quest_id]
					var needs := str(quest.get("requires", ""))
					if done.has(quest_id) or (needs != "" and not done.has(needs)):
						continue
					var target := str(quest["objective"]["enemy"])
					var have := 0
					for kind: String in kills:
						have += int(kills[kind]) if target in ["any", kind] else 0
					if have >= int(quest["objective"]["count"]):
						done[quest_id] = true
						hero.add_xp(int(quest["rewards"].get("xp", 0)), _content())
						handed = true


## Every enemy id in an area's encounters, once per appearance.
func _encounter_enemies(area: Dictionary) -> Array[String]:
	var found: Array[String] = []
	for encounter: Dictionary in area.get("encounters", []):
		for wave: Array in encounter["waves"]:
			for enemy_id: String in wave:
				found.append(enemy_id)
	return found
