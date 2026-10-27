extends TestCase
## The world boss (WorldBossRules, WorldBossRun): the Tunnel Mother opens on
## a clock once K-7 is beaten, at the hero's level, with one health pool per
## round worn down attempt by attempt, reward tiers paid once each, and a
## results screen (no knock-out penalty) instead of the game-over.

const TEST_SAVE := "user://test_world_boss_save.json"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _period() -> int:
	return int(_content().world_boss["period_minutes"]) * 60


func _hero(level := 30) -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	profile.level = level
	profile.defeated[str(_content().world_boss["unlock"])] = 1
	return profile


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func _game() -> Node2D:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.now_override = _period() * 1000 + 60  # a minute into an open round
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func test_rounds_open_on_the_clock() -> void:
	var start := _period() * 1000
	var open := WorldBossRules.window(_content(), start + 10)
	assert_true(open["open"], "open at the start of a round")
	assert_eq(int(open["round"]), 1000, "rounds count from the epoch")
	var length := int(_content().world_boss["open_minutes"]) * 60
	var shut := WorldBossRules.window(_content(), start + length + 10)
	assert_true(not shut["open"], "closed after its hour")
	assert_eq(int(shut["opens_at"]), start + _period(), "and opens again next period")


func test_it_waits_for_the_drains_to_be_reached() -> void:
	var profile := PlayerProfile.new_game(_content())
	var now := _period() * 1000 + 10
	assert_true(WorldBossRules.problem(profile, _content(), now) != "", "locked before K-7")
	profile.defeated[str(_content().world_boss["unlock"])] = 1
	assert_eq(WorldBossRules.problem(profile, _content(), now), "", "open once K-7 is down")
	var shut := now + int(_content().world_boss["open_minutes"]) * 60
	assert_true(WorldBossRules.problem(profile, _content(), shut).contains("opens"), "says when")


func test_the_boss_keeps_pace_with_the_hero() -> void:
	var low := WorldBossRules.level_for(_hero(20), _content())
	assert_eq(low, int(_content().world_boss["min_level"]), "never below its minimum")
	assert_eq(WorldBossRules.level_for(_hero(40), _content()), 42, "two above the hero")
	assert_true(
		WorldBossRules.pool(_content(), 42) > WorldBossRules.pool(_content(), 30), "bigger pool"
	)


func test_tiers_pay_once_per_round_and_reset_next_round() -> void:
	var profile := _hero()
	var total := 10000
	var tiers: Array = _content().world_boss["tiers"]
	var first := ceili(total * float(tiers[0]["share"]))
	var money := profile.money
	var paid := WorldBossRules.award(profile, _content(), 7, first - 1, total, 30, _rng())
	assert_true(paid["tiers"].is_empty(), "short of the first tier: nothing")
	paid = WorldBossRules.award(profile, _content(), 7, 1, total, 30, _rng())
	assert_eq(paid["tiers"], [0], "the first tier, once reached")
	assert_true(profile.money > money, "paid")
	paid = WorldBossRules.award(profile, _content(), 7, 0, total, 30, _rng())
	assert_true(paid["tiers"].is_empty(), "never twice in a round")
	paid = WorldBossRules.award(profile, _content(), 8, total, total, 30, _rng())
	assert_eq(paid["tiers"].size(), tiers.size(), "a new round, the whole pool: every tier")
	assert_eq(int(profile.world_boss["dealt"]), total, "never more than the pool")


func test_an_attempt_fights_the_rounds_pool() -> void:
	var profile := _hero()
	var zone := ZoneSim.new(_content(), profile, "great_drain", "west", 3)
	WorldBossRules.progress(profile, 5)["dealt"] = 1000
	var run := WorldBossRun.new(zone, profile, _content(), 5)
	assert_eq(zone.level + LevelRules.BOSS_BONUS, run.level, "the arena at the boss's level")
	for tick in 120:
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()))
	var mother := zone.fighter(zone.boss_id)
	assert_eq(mother.kind, "tunnel_mother", "the Tunnel Mother rises")
	assert_eq(mother.max_hp, run.total, "with the whole round's pool")
	assert_eq(mother.hp, run.total - 1000, "less what was dealt before")


func test_the_attempt_ends_on_the_clock() -> void:
	var profile := _hero()
	var zone := ZoneSim.new(_content(), profile, "great_drain", "west", 3)
	var run := WorldBossRun.new(zone, profile, _content(), 5)
	zone.hero.max_hp = 1000000
	zone.hero.hp = 1000000
	var limit := int(_content().world_boss["attempt_seconds"]) * CombatRules.TICK_RATE
	for tick in limit + 300:
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()))
		if run.ended:
			break
	assert_eq(run.ended, "time", "time's up")


func test_win_rides_there_only_while_it_is_open() -> void:
	var game := _game()
	game.profile.defeated[str(_content().world_boss["unlock"])] = 1
	game.profile.money = 100
	var npc := {"name": "Win", "role": "travel", "fare": 10, "sprite": "npc_win"}
	game._show("travel", GameMenus.travel(game, npc))
	var ride := game.menu.find_child("Ride_world_boss", true, false) as Button
	assert_true(ride != null and not ride.disabled, "offered while open")
	game.close_menu()
	game.now_override += int(_content().world_boss["open_minutes"]) * 60
	game._show("travel", GameMenus.travel(game, npc))
	ride = game.menu.find_child("Ride_world_boss", true, false) as Button
	assert_true(ride != null and ride.disabled, "shown, but shut, between rounds")
	_done(game)


func test_an_attempt_from_the_taxi_to_the_results() -> void:
	var game := _game()
	game.profile.defeated[str(_content().world_boss["unlock"])] = 1
	game.profile.level = 30
	game.profile.money = 100
	game._ride_world_boss({"fare": 10})
	assert_eq(game.zone.area_id, "great_drain", "in the Great Drain")
	assert_true(game.world_run != null, "an attempt under way")
	assert_eq(AutoRules.problem(game.profile, _content(), "great_drain") != "", true, "no auto")
	var money: int = game.profile.money
	for tick in 120:
		game.zone.hero.position.x = 200
		game.step(FighterInput.new())
	var mother: Node = game.view.view_of(game.zone.boss_id)
	assert_true(not (mother.get_node("Name") as Label).visible, "named on the boss bar only")
	game.zone.hero.hp = 0
	game.zone.hero.enter(Fighter.State.KO)
	var events: Array[ZoneEvent] = [ZoneEvent.make("hero_down")]
	game.world_run.tick(game.zone, events)
	game.step(FighterInput.new())
	assert_eq(game.menu_name, "world_boss", "the results, not the game-over")
	assert_eq(game.profile.money, money, "no coins lost")
	game._leave_world_boss()
	assert_eq(game.zone.area_id, _content().start_area, "home again")
	assert_eq(game.profile.hp, game.profile.stats(_content())["max_hp"], "rested")
	_done(game)


func test_the_arena_cannot_be_walked_or_loaded_into() -> void:
	var game := _game()
	game.enter_area("great_drain", "west")
	assert_eq(game.zone.area_id, _content().start_area, "only through an attempt")
	_done(game)


func test_the_round_is_saved() -> void:
	var profile := _hero()
	profile.world_boss = {"round": 9, "dealt": 1234, "tiers": 2}
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	assert_eq(loaded.world_boss, {"round": 9, "dealt": 1234, "tiers": 2}, "round kept")
	var old := profile.to_dict()
	old["version"] = 6
	old.erase("world_boss")
	assert_eq(PlayerProfile.from_dict(old, _content()).world_boss, {}, "a v6 save starts fresh")
