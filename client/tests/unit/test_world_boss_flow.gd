extends TestCase
## A world boss attempt from start to finish, as players reported it going
## wrong: a slain boss is gone for the rest of its round (no fight against an
## empty health bar), the round runs on the world's clock (a tab asleep in
## the background stops nothing), at the end of the hour the boss escapes off
## the arena instead of staying to be beaten, and the result screen is built
## once and can be pressed (the street goes on behind it).

const TEST_SAVE := "user://test_world_boss_flow_save"
const MOTHER := "tunnel_mother"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _spec() -> Dictionary:
	return _content().world_bosses[MOTHER]


func _period() -> int:
	return int(_spec()["period_minutes"]) * 60


## A minute into round `round`.
func _during(round: int) -> int:
	return round * _period() + int(_spec().get("offset_minutes", 0)) * 60 + 60


func _hero() -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	profile.level = 40
	return profile


## The game, a minute into round 1000 of the Tunnel Mother.
func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.now_override = _during(1000)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return rng


## The boss up in its arena, the hero unable to fall.
func _arena(profile: PlayerProfile, round: int, now: int) -> Array:
	var zone := ZoneSim.new(_content(), profile, str(_spec()["area"]), "west", 5)
	var run := WorldBossRun.new(zone, profile, _content(), MOTHER, round, now)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	for tick in 240:
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()), now)
		if zone.boss_id != 0:
			break
	return [zone, run]


func test_a_slain_boss_is_gone_until_its_next_round() -> void:
	var c := _content()
	var profile := _hero()
	var now := _during(7)
	assert_eq(WorldBossRules.problem(profile, c, MOTHER, now), "", "open: in you go")
	var total := WorldBossRules.pool(c, MOTHER)
	var paid := WorldBossRules.award(profile, c, MOTHER, 7, total, total, 32, _rng(), true)
	assert_true(paid["kill"], "the kill pays")
	var said := WorldBossRules.problem(profile, c, MOTHER, now + 60)
	assert_true(said.begins_with("Already defeated this round"), "no empty-bar rematch: " + said)
	assert_true(WorldBossRules.fallen(profile, MOTHER, 7), "fallen this round")
	assert_eq(WorldBossRules.problem(profile, c, MOTHER, _during(8)), "", "back next round")
	for attempt in 5:
		assert_eq(WorldBossRules.problem(profile, c, MOTHER, _during(8)), "", "any number of tries")


func test_an_emptied_pool_keeps_the_boss_down_even_when_banked_after_a_quit() -> void:
	# The tab closed on the last blow: settle() banks the attempt. Only a kill
	# seen to the end pays (test_item_safety), but the boss stays down: never
	# 0 HP and standing for a one-hit rematch.
	var c := _content()
	var profile := _hero()
	var total := WorldBossRules.pool(c, MOTHER)
	WorldBossRules.note_attempt(profile, MOTHER, 9, total, total, 32)
	var settled := WorldBossRules.settle(profile, c, _rng())
	assert_true(not settled[MOTHER]["kill"], "a cut-short attempt pays nothing")
	assert_true(WorldBossRules.fallen(profile, MOTHER, 9), "but the boss stays down")
	assert_true(
		WorldBossRules.problem(profile, c, MOTHER, _during(9)).begins_with("Already defeated"),
		"no rematch at 0 HP"
	)


func test_at_the_end_of_the_hour_the_boss_escapes_off_the_arena() -> void:
	var profile := _hero()
	var closes := int(WorldBossRules.window(_content(), MOTHER, _during(5))["closes_at"])
	var setup := _arena(profile, 5, closes - 3)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var mother := zone.fighter(zone.boss_id)
	assert_true(mother != null, "the boss is up")
	var id := mother.id
	var dealt_at_bell := -1
	for tick in 600:
		var input := FighterInput.new()
		input.light = tick % 12 == 0
		if zone.fighter(id):
			zone.hero.position = zone.fighter(id).position - Vector2(40, 0)
			zone.hero.facing = 1
		run.tick(zone, zone.tick(input), closes - 3 + tick / CombatRules.TICK_RATE)
		if run.escaping and dealt_at_bell < 0:
			dealt_at_bell = run.dealt
			assert_eq(zone.boss_id, 0, "its hazards and summons stop")
		if run.ended:
			break
	assert_eq(run.ended, "time", "it got away")
	assert_eq(run.dealt, dealt_at_bell, "not one more hit lands once it runs")
	assert_true(zone.fighter(id) == null, "gone from the arena")
	assert_true(not zone.hero.is_ko(), "the hero is left standing, alone")


func test_the_round_runs_on_the_worlds_clock() -> void:
	# A tab asleep in the background runs no ticks; when it wakes, the clock
	# has moved on, and a round that closed meanwhile is over.
	var profile := _hero()
	var start := _during(4)
	var closes := int(WorldBossRules.window(_content(), MOTHER, start)["closes_at"])
	var setup := _arena(profile, 4, start)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var before := run.seconds_left()
	run.tick(zone, zone.tick(FighterInput.new()), start + 600)
	assert_true(
		run.seconds_left() <= before - 590, "ten minutes away count: %d" % run.seconds_left()
	)
	run.tick(zone, zone.tick(FighterInput.new()), closes + 5)
	assert_true(run.escaping, "woke after the bell: the boss is leaving")


func test_the_result_is_built_once_and_can_be_pressed() -> void:
	var game := _game()
	game.profile.level = maxi(game.profile.level, 10)
	game.profile.level = 30
	game.profile.money = 100
	game._ride_world_boss({"fare": 10}, MOTHER)
	assert_true(game.world_run != null, "an attempt under way")
	for tick in 120:
		game.zone.hero.position.x = 200
		game.step(FighterInput.new())
	game.world_run.ended = "down"
	game.step(FighterInput.new())
	var shown := game.menu
	assert_eq(game.menu_name, "world_boss", "the result is up")
	var banked := int(WorldBossRules.progress(game.profile, MOTHER, game.world_run.round)["dealt"])
	for tick in 30:
		game.step(FighterInput.new())  # the street goes on behind the screen
	assert_true(game.menu == shown, "the same screen, not rebuilt every tick")
	var dealt := int(WorldBossRules.progress(game.profile, MOTHER, game.world_run.round)["dealt"])
	assert_eq(dealt, banked, "the damage is banked once")
	var leave := game.menu.find_child("Leave", true, false) as Button
	assert_true(leave != null and not leave.disabled, "the button is there to press")
	leave.pressed.emit()
	assert_eq(game.zone.area_id, AreaRules.hub(_content()), "pressing it takes the hero home")
	assert_true(game.world_run == null, "the attempt is over")
	_done(game)


func test_every_world_boss_fights_armed_with_a_tougher_weapon() -> void:
	var c := _content()
	var factor := float(c.progression["boss_weapon_durability"])
	assert_true(factor >= 2.0 and factor <= 3.0, "two to three times as hard to break")
	for boss: String in c.world_bosses:
		var spec: Dictionary = c.world_bosses[boss]
		var enemy_id := str(spec["enemy"])
		var weapon := str(c.enemy(enemy_id).get("weapon", ""))
		assert_true(c.weapons.has(weapon), boss + ": holds a weapon")
		var profile := _hero()
		var zone := ZoneSim.new(c, profile, str(spec["area"]), "west", 2)
		var giant := zone.spawn_enemy(enemy_id, Vector2(600, 300))
		assert_eq(giant.weapon, weapon, boss + ": spawns with it")
		var base := int(c.weapons[weapon]["durability"])
		assert_eq(giant.weapon_uses, roundi(base * factor), boss + ": for %d hits" % base)
	var zone := ZoneSim.new(c, _hero(), "saltmarket", "west", 2)
	var thug := zone.spawn_enemy("dock_thug", Vector2(500, 300))
	zone.equip_weapon(thug, "pipe", 9)
	assert_eq(thug.weapon_uses, 9, "anyone else's weapon lasts as before")


func test_the_truck_lists_every_world_boss_in_order_of_level() -> void:
	var game := _game()
	game.profile.money = 100
	game.profile.level = 9
	game.enter_area(_content().city_area, "west")
	var truck := {"name": "Uncle Thong", "role": "travel", "routes": "field", "fare": 10}
	game._show("travel", GameMenus.travel(game, truck))
	for boss: String in _content().world_bosses:
		var locked := game.menu.find_child("Locked_" + boss, true, false) as Button
		assert_true(locked != null and locked.disabled, boss + ": shut below level 10")
		assert_true("From Lv 10" in locked.text, boss + ": says what opens it")
	game.profile.level = 10
	game._show("travel", GameMenus.travel(game, truck))
	var levels: Array[int] = []
	for boss: String in _content().world_bosses:
		var ride := game.menu.find_child("Ride_" + boss, true, false) as Button
		assert_true(ride != null, boss + ": every one rides from level 10")
	for row: Button in game.menu.find_children("*", "Button", true, false):
		var id := row.name.trim_prefix("Ride_").trim_prefix("Locked_")
		if _content().world_bosses.has(id):
			levels.append(WorldBossRules.level(_content(), id))
	var sorted := levels.duplicate()
	sorted.sort()
	assert_eq(levels, sorted, "in order of level")
	game.close_menu()
	var round := int(WorldBossRules.window(_content(), MOTHER, game._now())["round"])
	var total := WorldBossRules.pool(_content(), MOTHER)
	WorldBossRules.award(game.profile, _content(), MOTHER, round, total, total, 32, _rng(), true)
	game._show("travel", GameMenus.travel(game, truck))
	var mother := game.menu.find_child("Ride_" + MOTHER, true, false) as Button
	assert_true(mother.disabled and "defeated, rises in" in mother.text, "down: " + mother.text)
	_done(game)
