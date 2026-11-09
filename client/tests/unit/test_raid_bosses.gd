extends TestCase
## The three raid bosses past the story, one for each band (50-60, 60-65,
## 65-70): each stronger than the last and built for more players, armed,
## with moves and skills of its own (the "quake" column and the "rain"
## volley among them) and its own arena, paying Godforged gear. Like every
## world boss: unlimited entries and attempts.

const RAID := ["floodgate_marshal", "crucible_king", "founders_engine"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hazard_kinds(enemy: Dictionary) -> Dictionary:
	var kinds := {}
	var specs: Array = [enemy.get("hazard", {})]
	for phase: Dictionary in enemy.get("phases", []):
		specs.append(phase.get("hazard", {}))
	for spec: Dictionary in specs:
		for entry: Dictionary in spec.get("cycle", []):
			kinds[str(entry["kind"])] = true
	return kinds


func test_each_raid_boss_is_stronger_and_bigger_than_the_last() -> void:
	var c := _content()
	assert_eq(c.errors, PackedStringArray(), "the data validates")
	var last := {"level": 0, "players": 10, "pool": 0, "xp": 0}
	for boss in RAID:
		assert_true(c.world_bosses.has(boss), boss + ": a world boss")
		var spec: Dictionary = c.world_bosses[boss]
		var enemy := c.enemy(str(spec["enemy"]))
		var pool := WorldBossRules.pool(c, boss)
		assert_true(int(spec["level"]) > int(last["level"]), boss + ": a higher level")
		assert_true(int(spec["players"]) > int(last["players"]), boss + ": more players")
		assert_true(pool > int(last["pool"]), boss + ": a bigger pool (%d)" % pool)
		assert_true(int(enemy["xp"]) > int(last["xp"]), boss + ": worth more")
		last = {"level": spec["level"], "players": spec["players"], "pool": pool, "xp": enemy["xp"]}
	var sovereign := WorldBossRules.pool(c, "iron_sovereign")
	assert_true(int(last["pool"]) > sovereign, "the last one outlasts the Iron Sovereign")


func test_each_raid_boss_fights_its_own_way() -> void:
	var c := _content()
	for boss in RAID:
		var spec: Dictionary = c.world_bosses[boss]
		var enemy := c.enemy(str(spec["enemy"]))
		assert_true(c.weapons.has(str(enemy.get("weapon", ""))), boss + ": armed")
		for slot: String in enemy["moveset"]:
			var move_id := str(enemy["moveset"][slot])
			assert_true(c.moves.get_move(move_id) != null, move_id + ": a real move")
			for other: String in c.enemies:
				if other != str(spec["enemy"]):
					var theirs: Dictionary = c.enemy(other).get("moveset", {})
					assert_true(move_id not in theirs.values(), "%s: %s's own" % [move_id, boss])
		var kinds := _hazard_kinds(enemy)
		assert_true(kinds.has("quake") or kinds.has("rain"), boss + ": a new skill")
		assert_true(kinds.size() >= 3, boss + ": several skills across its phases")
		assert_true((enemy.get("phases", []) as Array).size() >= 2, boss + ": phases")
		assert_true(enemy.has("summon"), boss + ": calls in help")
		assert_true(enemy.has("tint"), boss + ": its own colour")
		var arena := str(spec["area"])
		assert_eq(AreaRules.kind(c, arena), AreaRules.WORLD_BOSS, boss + ": its own arena")
		assert_true(c.environment["areas"].has(arena), arena + ": scenery")


func test_each_raid_boss_pays_godforged_gear_with_unlimited_entries() -> void:
	var c := _content()
	for boss in RAID:
		var spec: Dictionary = c.world_bosses[boss]
		for limit in ["attempts", "daily_attempts", "cooldown_minutes", "entries"]:
			assert_true(not spec.has(limit), "%s: no %s" % [boss, limit])
		var rolls: Dictionary = spec["kill"]["rolls"]
		assert_true(rolls.size() >= 3, boss + ": several prizes")
		for item_id: String in rolls:
			var item := c.item(item_id)
			assert_eq(item["rarity"], "godforged", item_id + ": Godforged")
			assert_eq(int(item["level"]), int(spec["level"]), item_id + ": at the boss's level")


func test_a_quake_splits_the_whole_depth_and_a_step_along_avoids_it() -> void:
	var c := _content()
	for offset in [0.0, 60.0]:
		var profile := PlayerProfile.new_game(c)
		var zone := ZoneSim.new(c, profile, "saltmarket", "west", 1)
		zone.hero.position = Vector2(400, zone.bounds.end.y - 1.0)
		var top := zone.bounds.position.y + 1.0
		zone.hazards.append(
			{"at": Vector2(400 + offset, top), "ticks": 3, "half": Vector2(24, 90), "damage": 30}
		)
		zone.hazards[0]["kind"] = "quake"
		var before := zone.hero.hp
		for tick in 6:
			zone.tick(FighterInput.new())
		if offset == 0.0:
			assert_true(
				zone.hero.hp < before,
				"marked at the far kerb, it hits at the near one: the whole depth"
			)
		else:
			assert_eq(zone.hero.hp, before, "a step along the street avoids it")


func test_a_raid_boss_throws_its_new_skills_in_a_fight() -> void:
	var c := _content()
	for boss in RAID:
		var spec: Dictionary = c.world_bosses[boss]
		var profile := PlayerProfile.new_game(c)
		profile.level = int(spec["level"])
		profile.defeated[str(spec["unlock"])] = 1
		var period := int(spec["period_minutes"]) * 60
		var now := 3 * period + int(spec.get("offset_minutes", 0)) * 60 + 30
		var zone := ZoneSim.new(c, profile, str(spec["area"]), "west", 4)
		var run := WorldBossRun.new(zone, profile, c, boss, 3, now)
		zone.hero.max_hp = 100000000
		var seen := {}
		for tick in 1800:
			zone.hero.hp = zone.hero.max_hp
			zone.hero.position.x = 220
			for event in zone.tick(FighterInput.new()):
				if event.type == "hazard_warn":
					seen[str(event.data["kind"])] = true
			run.tick(zone, [], now)
		var own := _hazard_kinds(c.enemy(str(spec["enemy"])))
		var first: Array = c.enemy(str(spec["enemy"]))["hazard"]["cycle"]
		for entry: Dictionary in first:
			assert_true(seen.has(str(entry["kind"])), "%s: uses %s" % [boss, entry["kind"]])
		assert_true(own.size() >= seen.size(), boss + ": nothing it does not own")


func test_every_hazard_kind_draws() -> void:
	# Any script error while drawing fails the test (TestRunner).
	for kind: String in BossMechanics.KINDS:
		var view := HazardView.new()
		view.setup(0.3, kind, Vector2(24, 90) if kind == "quake" else Vector2(30, 12))
		tree.root.add_child(view)
		for frame in 3:
			await tree.process_frame
		view.land()
		for frame in 3:
			await tree.process_frame
		view.free()
	assert_true(true, "every kind drew, waiting and landing")
