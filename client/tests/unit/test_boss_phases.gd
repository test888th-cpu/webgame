extends TestCase
## Boss phases are written on the enemy's base (level 1) scale and scaled to
## the boss's level like its own stats, so a phase always hardens the fight:
## once a level-32 boss with power x3.48 dropped to the phase's raw x1.05.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## What `data` fights with before any phase, at `level`.
func _base(data: Dictionary, level: int) -> Dictionary:
	var stats := LevelRules.enemy_stats(data, level)
	var ai := LevelRules.enemy_ai(data["ai"], level, data["moveset"].has("heavy"))
	return {
		"power": stats["power"],
		"speed": stats["speed"],
		"cooldown": int(ai["cooldown"]),
		"heavy_chance": float(ai.get("heavy_chance", 0.0)),
		"heavy_cooldown": int(ai.get("heavy_cooldown", EnemyBrain.DEFAULT_HEAVY_COOLDOWN)),
	}


func test_every_phase_hardens_the_fight_at_every_level() -> void:
	var checked := 0
	for enemy_id: String in _content().enemies:
		var data := _content().enemy(enemy_id)
		if data.get("phases", []).is_empty():
			continue
		for level in [1, 20, 32, 52, 55]:
			var before := _base(data, level)
			for i in data.get("phases", []).size():
				var now := LevelRules.phase_stats(data, data["phases"][i], level)
				var where := "%s Lv %d phase %d" % [enemy_id, level, i + 1]
				assert_true(now["power"] >= before["power"], where + ": hits no softer")
				assert_true(now["speed"] >= before["speed"], where + ": moves no slower")
				assert_true(now["cooldown"] <= before["cooldown"], where + ": rests no longer")
				assert_true(now["heavy_chance"] >= before["heavy_chance"], where + ": no meeker")
				before = now
				checked += 1
	assert_true(checked > 50, "every phase of every boss (%d)" % checked)


func test_at_level_one_a_phase_is_what_the_data_says() -> void:
	var data := _content().enemy("sludge_foreman")
	var phase: Dictionary = data["phases"][0]
	var stats := LevelRules.phase_stats(data, phase, 1)
	assert_near(stats["power"], float(phase["power"]), "power as written")
	assert_near(stats["speed"], float(phase["speed"]), "speed as written")
	assert_eq(stats["cooldown"], int(phase["cooldown"]), "cooldown as written")


func test_a_phase_keeps_the_bosss_level() -> void:
	var data := _content().enemy("tunnel_mother")
	var phase: Dictionary = data["phases"][0]
	var stats := LevelRules.phase_stats(data, phase, 32)
	var base := LevelRules.enemy_stats(data, 32)
	var ratio := float(phase["power"]) / float(data.get("power", 1.0))
	assert_near(stats["power"], base["power"] * ratio, "level power times the phase's step", 0.01)


func test_a_boss_in_a_zone_grows_stronger_in_its_next_phase() -> void:
	var profile := PlayerProfile.new_game(_content())
	var zone := ZoneSim.new(_content(), profile, "great_drain", "west", 3)
	zone.level = 32 - LevelRules.BOSS_BONUS
	var mother := zone.spawn_enemy("tunnel_mother", Vector2(600, 300))
	assert_eq(zone.enemy_level(mother.id), 32, "a level 32 Mother")
	var power := mother.power
	var speed := mother.speed
	var cooldown: int = zone.brains[mother.id].cooldown_ticks
	mother.hp = int(mother.max_hp * 0.6)
	zone.tick(FighterInput.new())
	assert_eq(zone.phase_of(mother.id), 1, "into its second phase")
	assert_true(mother.power > power, "hits harder (%.2f > %.2f)" % [mother.power, power])
	assert_true(mother.speed > speed, "moves faster")
	assert_true(zone.brains[mother.id].cooldown_ticks < cooldown, "rests less")


func test_the_validator_rejects_a_phase_that_softens_the_boss() -> void:
	var broken := ContentDB.load_all()
	broken.errors.clear()
	var phase: Dictionary = broken.enemies["furnace_baron"]["phases"][0]
	phase["power"] = 0.5
	phase["cooldown"] = 999
	broken.validate()
	var all := "\n".join(broken.errors)
	assert_true("furnace_baron.phases.power: below the base" in all, "weaker blows")
	assert_true("furnace_baron.phases.cooldown: above the base" in all, "longer rests")
