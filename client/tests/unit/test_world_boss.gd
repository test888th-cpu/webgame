extends TestCase
## World bosses (WorldBossRules, WorldBossRun): each on its own clock, with
## one health pool per round worn down attempt by attempt, personal reward
## tiers paid once each, a kill paid once, and a results screen (no knock-out
## penalty) instead of the game-over. Each fights at a fixed level with a
## fixed pool, for anyone who unlocked it; all three are built for groups,
## their rarest drops coming with the kill.

const TEST_SAVE := "user://test_world_boss_save"
const MOTHER := "tunnel_mother"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _spec(boss := MOTHER) -> Dictionary:
	return _content().world_bosses[boss]


func _period(boss := MOTHER) -> int:
	return int(_spec(boss)["period_minutes"]) * 60


## A Unix time a minute into `boss`'s round `round`, while it is up.
func _during(round: int, boss := MOTHER) -> int:
	return round * _period(boss) + int(_spec(boss).get("offset_minutes", 0)) * 60 + 60


func _hero(level := 30) -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	profile.level = level
	for boss: String in _content().world_bosses:
		profile.defeated[str(_spec(boss)["unlock"])] = 1
	return profile


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func _game() -> Node2D:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.now_override = _period() * 1000 + 60  # a minute into an open round
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_rounds_open_on_the_clock() -> void:
	var start := _period() * 1000
	var open := WorldBossRules.window(_content(), MOTHER, start + 10)
	assert_true(open["open"], "open at the start of a round")
	assert_eq(int(open["round"]), 1000, "rounds count from the epoch")
	var length := int(_spec()["open_minutes"]) * 60
	var shut := WorldBossRules.window(_content(), MOTHER, start + length + 10)
	assert_true(not shut["open"], "closed after its hour")
	assert_eq(int(shut["opens_at"]), start + _period(), "and opens again next period")


func test_it_waits_for_the_drains_to_be_reached() -> void:
	var profile := PlayerProfile.new_game(_content())
	var now := _period() * 1000 + 10
	assert_true(WorldBossRules.problem(profile, _content(), MOTHER, now) != "", "locked before K-7")
	profile.defeated[str(_spec()["unlock"])] = 1
	assert_eq(WorldBossRules.problem(profile, _content(), MOTHER, now), "", "open once K-7 is down")
	var shut := now + int(_spec()["open_minutes"]) * 60
	assert_true(
		WorldBossRules.problem(profile, _content(), MOTHER, shut).contains("Back in"), "says when"
	)


func test_a_world_boss_is_the_same_for_everyone() -> void:
	# Fixed like a field boss: its level and pool never follow the hero.
	for boss: String in _content().world_bosses:
		var level := WorldBossRules.level(_content(), boss)
		assert_eq(level, int(_spec(boss)["level"]), "%s at its own level" % boss)
		var zone_low := ZoneSim.new(_content(), _hero(10), "depot_yard", "", 1)
		var zone_high := ZoneSim.new(_content(), _hero(50), "depot_yard", "", 1)
		var low := WorldBossRun.new(zone_low, _hero(10), _content(), boss, 1, _during(1, boss))
		var high := WorldBossRun.new(zone_high, _hero(50), _content(), boss, 1, _during(1, boss))
		assert_eq(low.level, high.level, "%s: the same level for a rookie and a veteran" % boss)
		assert_eq(low.total, high.total, "%s: and the same pool" % boss)
	assert_eq(WorldBossRules.level(_content(), MOTHER), 32, "the Mother is level 32")


func test_only_the_kill_pays_and_an_escape_pays_nothing() -> void:
	var profile := _hero()
	var total := 10000
	var tiers: Array = _spec()["tiers"]
	var money := profile.money
	var paid := WorldBossRules.award(profile, _content(), MOTHER, 7, total / 2, total, 30, _rng())
	assert_true(paid["tiers"].is_empty() and not paid["kill"], "half the pool down: nothing yet")
	assert_eq(profile.money, money, "no coins while it stands")
	assert_eq(int(profile.world_boss[MOTHER]["dealt"]), total / 2, "but the damage counts")
	paid = WorldBossRules.award(profile, _content(), MOTHER, 7, total / 2, total, 30, _rng(), true)
	assert_eq(paid["tiers"].size(), tiers.size(), "it falls: every tier the round's damage reached")
	assert_true(paid["kill"] and profile.money > money, "and the kill")
	paid = WorldBossRules.award(profile, _content(), MOTHER, 7, 0, total, 30, _rng(), true)
	assert_true(paid["tiers"].is_empty() and not paid["kill"], "never twice in a round")
	paid = WorldBossRules.award(profile, _content(), MOTHER, 8, total - 1, total, 30, _rng())
	assert_true(paid["tiers"].is_empty(), "next round, all but the last blow: nothing")
	var fresh := WorldBossRules.progress(profile, MOTHER, 9)
	assert_eq(int(fresh["dealt"]), 0, "it got away: the round after starts at full health")


func test_an_attempt_fights_the_rounds_pool() -> void:
	var profile := _hero()
	var zone := ZoneSim.new(_content(), profile, "great_drain", "west", 3)
	WorldBossRules.progress(profile, MOTHER, 5)["dealt"] = 1000
	var run := WorldBossRun.new(zone, profile, _content(), MOTHER, 5, _during(5))
	assert_eq(zone.level + LevelRules.BOSS_BONUS, run.level, "the arena at the boss's level")
	for tick in 120:
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()))
	var mother := zone.fighter(zone.boss_id)
	assert_eq(mother.kind, "tunnel_mother", "the Tunnel Mother rises")
	assert_eq(mother.max_hp, run.total, "with the whole round's pool")
	assert_eq(mother.hp, run.total - 1000, "less what was dealt before")


func test_the_fight_lasts_until_the_hour_is_up() -> void:
	var profile := _hero()
	var zone := ZoneSim.new(_content(), profile, "great_drain", "west", 3)
	var closes := int(WorldBossRules.window(_content(), MOTHER, _during(5))["closes_at"])
	var early := WorldBossRun.new(zone, profile, _content(), MOTHER, 5, _during(5))
	var hour := int(_spec()["open_minutes"]) * 60
	assert_eq(early.seconds_left(), hour - 60, "a minute in: the rest of the hour to fight")
	var run := WorldBossRun.new(zone, profile, _content(), MOTHER, 5, closes - 5)
	zone.hero.max_hp = 1000000
	zone.hero.hp = 1000000
	var limit := 5 * CombatRules.TICK_RATE
	for tick in limit + 300:
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()))
		if run.ended:
			break
	assert_eq(run.ended, "time", "the hour is up: it gets away")


func test_win_rides_there_only_while_it_is_open() -> void:
	var game := _game()
	game.profile.defeated[str(_spec()["unlock"])] = 1
	game.profile.money = 100
	var npc := {"name": "Uncle Thong", "role": "travel", "routes": "field", "fare": 10}
	game._show("travel", GameMenus.travel(game, npc))
	var ride := game.menu.find_child("Ride_" + MOTHER, true, false) as Button
	assert_true(ride == null, "never out of the story")
	game.close_menu()
	var win := {"name": "Win", "role": "travel", "routes": "story", "fare": 10}
	game.enter_area(_content().city_area, "west")
	game._show("travel", GameMenus.travel(game, win))
	ride = game.menu.find_child("Ride_" + MOTHER, true, false) as Button
	assert_true(ride == null, "nor from Win's story rank")
	game.close_menu()
	game.enter_area(_content().city_area, "west")
	game._show("travel", GameMenus.travel(game, npc))
	ride = game.menu.find_child("Ride_" + MOTHER, true, false) as Button
	assert_true(ride != null and not ride.disabled, "offered in the city while open")
	game.close_menu()
	game.now_override += int(_spec()["open_minutes"]) * 60
	game._show("travel", GameMenus.travel(game, npc))
	ride = game.menu.find_child("Ride_" + MOTHER, true, false) as Button
	assert_true(ride != null and ride.disabled, "shown, but shut, between rounds")
	_done(game)


func test_an_attempt_from_the_taxi_to_the_results() -> void:
	var game := _game()
	game.profile.defeated[str(_spec()["unlock"])] = 1
	game.profile.level = 30
	game.profile.money = 100
	game._ride_world_boss({"fare": 10}, MOTHER)
	assert_eq(game.zone.area_id, "great_drain", "in the Great Drain")
	assert_true(game.world_run != null, "an attempt under way")
	assert_eq(AutoRules.problem(game.profile, _content(), "great_drain"), "", "auto may fight it")
	var money: int = game.profile.money
	for tick in 120:
		game.zone.hero.position.x = 200
		game.step(FighterInput.new())
	var mother: Node = game.view.view_of(game.zone.boss_id)
	var overhead := mother.get_node("Name") as Label
	assert_true(overhead.visible and overhead.text == "The Tunnel Mother", "named overhead")
	assert_true(mother.get_node("Rank") != null, "with the boss skull")
	game.get_node("Hud")._process(0.016)
	var boss_bar := game.get_node("Hud").find_child("Boss", true, false) as Control
	assert_true(boss_bar.visible, "and on the boss bar")
	assert_true(boss_bar.find_child("BossIcon", true, false) != null, "skull there too")
	game.zone.hero.hp = 0
	game.zone.hero.enter(Fighter.State.KO)
	var events: Array[ZoneEvent] = [ZoneEvent.make("hero_down")]
	game.world_run.tick(game.zone, events)
	game.step(FighterInput.new())
	assert_eq(game.menu_name, "world_boss", "the results, not the game-over")
	assert_eq(game.profile.money, money, "no coins lost")
	game._leave_world_boss()
	assert_eq(game.zone.area_id, _content().city_area, "back in the city")
	assert_eq(game.profile.hp, game.profile.stats(_content())["max_hp"], "rested")
	_done(game)


func test_the_arena_cannot_be_walked_or_loaded_into() -> void:
	var game := _game()
	game.enter_area("great_drain", "west")
	assert_eq(game.zone.area_id, _content().city_area, "only through an attempt")
	_done(game)


func test_the_round_is_saved() -> void:
	var profile := _hero()
	var state := {"round": 9, "dealt": 1234, "tiers": 2, "killed": false}
	profile.world_boss = {MOTHER: state.duplicate()}
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	assert_eq(loaded.world_boss, {MOTHER: state}, "round kept")
	var v7 := profile.to_dict()
	v7["version"] = 7
	v7["world_boss"] = {"round": 9, "dealt": 1234, "tiers": 2}
	var moved := PlayerProfile.from_dict(v7, _content())
	assert_eq(int(moved.world_boss[MOTHER]["dealt"]), 1234, "a v7 round was the Mother's")
	var old := profile.to_dict()
	old["version"] = 6
	old.erase("world_boss")
	assert_eq(PlayerProfile.from_dict(old, _content()).world_boss, {}, "a v6 save starts fresh")


func test_no_level_is_asked_at_the_door() -> void:
	# Anyone who has unlocked it may try; being ready is up to them.
	var now := _period("iron_colossus") * 100 + int(_spec("iron_colossus")["offset_minutes"]) * 60
	assert_eq(
		WorldBossRules.problem(_hero(5), _content(), "iron_colossus", now + 10),
		"",
		"a level 5 hero may walk in"
	)


func test_the_validator_rejects_a_scaling_world_boss() -> void:
	var broken := ContentDB.load_all()
	broken.errors.clear()
	broken.world_bosses[MOTHER]["level_above_hero"] = 2
	broken.world_bosses["iron_colossus"].erase("level")
	broken.validate()
	var all := "\n".join(broken.errors)
	assert_true("tunnel_mother.level_above_hero" in all, "no scaling")
	assert_true("iron_colossus.level" in all, "a fixed level is required")


func test_subject_zero_rises_once_a_day_in_the_evening() -> void:
	var data := _spec("subject_zero")
	assert_eq(int(data["period_minutes"]), 24 * 60, "daily")
	var day := 20000 * 86400
	var opens := day + int(data["offset_minutes"]) * 60
	var before := WorldBossRules.window(_content(), "subject_zero", opens - 60)
	assert_true(not before["open"], "shut a minute before")
	assert_eq(int(before["opens_at"]), opens, "opens at its hour")
	assert_true(WorldBossRules.window(_content(), "subject_zero", opens + 60)["open"], "open")


func test_a_group_boss_pays_by_ones_part_when_it_falls_once() -> void:
	var profile := _hero(50)
	var boss := "iron_colossus"
	var players := int(_spec(boss)["players"])
	var total := 50000
	var part := WorldBossRules.part(_content(), boss, total)
	assert_eq(part, total / players, "one player's part of the pool")
	var paid := WorldBossRules.award(profile, _content(), boss, 3, part, total, 52, _rng())
	assert_true(paid["tiers"].is_empty(), "a full part, the boss standing: nothing yet")
	paid = WorldBossRules.award(profile, _content(), boss, 3, 0, total, 52, _rng(), true)
	assert_eq(paid["tiers"].size(), _spec(boss)["tiers"].size(), "it falls: a full part's tiers")
	assert_true(paid["kill"], "and the kill")
	paid = WorldBossRules.award(profile, _content(), boss, 3, 0, total, 52, _rng(), true)
	assert_true(not paid["kill"], "once a round")


func test_rare_drops_are_rare() -> void:
	# Over many kills the exclusive legendaries turn up near their chance:
	# hard to get, never guaranteed.
	var boss := "subject_zero"
	var rng := _rng()
	var found := 0
	for round in 400:
		var profile := _hero(50)
		var paid := WorldBossRules.award(profile, _content(), boss, round, 0, 1000, 55, rng, true)
		found += int(paid["items"].get("iron_legacy", 0))
	var chance := float(_spec(boss)["kill"]["rolls"]["iron_legacy"])
	assert_true(found > 0 and found < 400 * chance * 3.0, "rare: %d in 400 kills" % found)
	for item_id: String in ["colossus_core", "piston_gauntlets", "zeros_mantle", "iron_legacy"]:
		assert_eq(str(_content().item(item_id)["rarity"]), "legendary", "%s is legendary" % item_id)
