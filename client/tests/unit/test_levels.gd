extends TestCase
## Area levels: enemies grow tougher and smarter, areas chain onwards, and
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
	var high := LevelRules.enemy_stats(data, 8)
	assert_true(high["max_hp"] > low["max_hp"], "more hp")
	assert_true(high["power"] > low["power"], "hits harder")
	assert_true(high["defense"] > low["defense"], "more defense")
	assert_true(high["xp"] > low["xp"], "more xp")
	assert_true(high["money_scale"] > 1.0, "more money")
	assert_true(
		LevelRules.enemy_stats(data, 99)["speed"] <= float(data["speed"]) * 1.3 + 0.001,
		"speed capped"
	)


func test_higher_levels_think_faster_and_learn_tricks() -> void:
	var ai: Dictionary = _content().enemy("dock_thug")["ai"]
	var rookie := LevelRules.enemy_ai(ai, 1, true)
	var veteran := LevelRules.enemy_ai(ai, 8, true)
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
	assert_true(last >= 8, "the last area is level 8 or more")


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
	assert_eq(zone.enemy_level(enemy.id), 8, "fights at level 8")
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
