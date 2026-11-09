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
	profile.defeated[str(_spec()["unlock"])] = 1
	return profile


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


func test_an_emptied_pool_is_a_kill_even_when_banked_after_a_quit() -> void:
	# The tab closed on the killing blow: settle() banks the attempt. The boss
	# is dead, so it pays and stays down, never 0 HP and standing.
	var c := _content()
	var profile := _hero()
	var total := WorldBossRules.pool(c, MOTHER)
	WorldBossRules.note_attempt(profile, MOTHER, 9, total, total, 32)
	var settled := WorldBossRules.settle(profile, c, _rng())
	assert_true(settled[MOTHER]["kill"], "the emptied pool pays the kill")
	assert_true(WorldBossRules.fallen(profile, MOTHER, 9), "and the boss stays down")


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
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.now_override = _during(1000)
	game.profile.defeated[str(_spec()["unlock"])] = 1
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
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
