extends TestCase
## Bosses that fight with their hands come armed (enemies.json "weapon"): they
## step in already holding their own weapon, with its moves. A boss's grip is
## harder to break: its weapon lasts progression.json "boss_weapon_durability"
## times a hero's (2.5; the owner asked for two to three times, and for the
## world bosses to fight armed too). Unit K-7 and Subject 12 keep their own
## attacks.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_every_armed_boss_steps_in_holding_its_weapon() -> void:
	var c := _content()
	var armed := 0
	for kind: String in c.enemies:
		var data: Dictionary = c.enemies[kind]
		if not data.has("weapon"):
			continue
		armed += 1
		var weapon := str(data["weapon"])
		assert_true(c.weapons.has(weapon), "%s: %s is a weapon" % [kind, weapon])
		for seed in 5:
			var profile := PlayerProfile.new_game(c)
			var zone := ZoneSim.new(c, profile, "saltmarket", "west", seed)
			zone.level = 40
			var boss := zone.spawn_enemy(kind, Vector2(600, 300))
			assert_eq(
				boss.weapon, weapon, "%s comes holding its %s (seed %d)" % [kind, weapon, seed]
			)
			var uses := int(c.weapons[weapon]["durability"])
			var factor := float(c.progression["boss_weapon_durability"])
			if c.enemies[kind].get("boss", false):
				assert_eq(boss.weapon_uses, roundi(uses * factor), kind + ": a tougher grip")
			else:
				assert_eq(boss.weapon_uses, uses, kind + ": with its full wear, like the hero's")
	assert_true(armed >= 9, "every boss that fights with its hands (%d)" % armed)
	for kind in ["unit_k7", "subject_twelve"]:
		assert_true(not c.enemies[kind].has("weapon"), kind + ": keeps its own attacks")
	for boss: String in c.world_bosses:
		var enemy_id := str(c.world_bosses[boss]["enemy"])
		assert_true(c.enemies[enemy_id].has("weapon"), enemy_id + ": a world boss fights armed")
