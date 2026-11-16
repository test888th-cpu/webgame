extends TestCase
## The arena (ArenaRules, ArenaMatch, ArenaBrain, ArenaFlow, ArenaScreen):
## a ladder of fifty AI-played heroes rising in level, gear, upgrades and
## skill; five rivals offered above the player; a win swaps ranks; matches
## at PvP strength with doubled health and no food; the city's arena master
## opens it and a match leads straight back to the ladder. Configuration:
## test_arena_config.gd; results, forfeits and the AI: test_arena_integrity.gd.

const TEST_SAVE := "user://test_arena"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _profile(level := 10, hero_id := "riku") -> PlayerProfile:
	var p := PlayerProfile.new_game(_content(), hero_id)
	p.level = level
	return p


## The arena zone with a match against `id` for `profile`.
func _match(profile: PlayerProfile, id: String) -> ArenaMatch:
	var zone := ZoneSim.new(_content(), profile, "pvp_arena", "", 5)
	return ArenaMatch.new(zone, profile, _content(), id)


## Plays `bout` with the hero driven by an ArenaBrain of `skill` (a stand-in
## player) until it ends or `ticks` pass. Returns the arena_end data or {}.
func _play(bout: ArenaMatch, skill: float, ticks := 7000) -> Dictionary:
	var zone := bout.zone
	var player := ArenaBrain.new(_content(), zone.rng, skill)
	for t in ticks:
		var input := player.think(
			zone.hero, bout.rival, true, _content().moves, zone.rng, Vector2.INF, zone.tick_count
		)
		var events := zone.tick(bout.filter(input))
		bout.tick(events)
		for event in events:
			if event.type == "arena_end":
				return event.data
	return {}


func test_the_ladder_rises_from_plain_gear_to_top_gear_plus_seven() -> void:
	var db := _content()
	assert_true(db.is_valid(), "content loads: %s" % ", ".join(db.errors))
	assert_eq(ArenaRules.size(db), 50, "fifty rivals")
	var bottom := ArenaRules.rival(db, "r50")
	assert_eq(bottom["gear"].size(), 5, "five slots: no common charm exists before level 53")
	assert_true(not bottom["slots"].has("charm"), "so the bottom tier wears none, as configured")
	for item_id: String in bottom["gear"]:
		assert_eq(db.item(item_id)["rarity"], "common", "the bottom wears plain gear")
		assert_eq(int(bottom["plus"][item_id]), 0, "not upgraded")
	var top_plain := ArenaRules.rival(db, "r21")
	assert_eq(int(top_plain["level"]), 70, "rank 21 is level 70")
	for slot: String in top_plain["slots"]:
		assert_eq(top_plain["slots"][slot]["grade"], "godforged", "top grade: %s" % slot)
		assert_eq(int(top_plain["slots"][slot]["plus"]), 0, "still +0")
	# Each tier's upgrades, mixed across the slots within its range.
	for pair: Array in [["r20", 1, 2], ["r15", 3, 4], ["r10", 5, 6], ["r5", 7, 7], ["r1", 7, 7]]:
		var data := ArenaRules.rival(db, str(pair[0]))
		for slot: String in data["slots"]:
			var plus := int(data["slots"][slot]["plus"])
			assert_true(plus >= pair[1] and plus <= pair[2], "%s %s +%d" % [pair[0], slot, plus])
	var mixed := {}
	for slot: String in ArenaRules.rival(db, "r8")["slots"]:
		mixed[int(ArenaRules.rival(db, "r8")["slots"][slot]["plus"])] = true
	assert_eq(mixed.size(), 2, "rank 8 mixes +5 and +6")
	assert_eq(ArenaRules.rival(db, "r1")["slots"]["weapon"]["item"], "sovereign_fists", "r1 own")


func test_power_level_and_skill_rise_up_the_ladder() -> void:
	var db := _content()
	var last_power := 0
	var last_level := 0
	var last_ai := -1.0
	for rank in range(50, 0, -1):
		var id := ArenaRules.rival_id(rank)
		var data := ArenaRules.rival(db, id)
		var power := ArenaRules.rival_power(db, id)
		assert_true(int(data["level"]) >= last_level, "rank %d: level never falls" % rank)
		assert_true(float(data["ai"]) >= last_ai, "rank %d: AI skill never falls" % rank)
		assert_true(
			power >= last_power * 0.9, "rank %d: power %d (was %d)" % [rank, power, last_power]
		)
		last_power = maxi(last_power, power)
		last_level = int(data["level"])
		last_ai = float(data["ai"])
	assert_true(ArenaRules.rival_power(db, "r1") > ArenaRules.rival_power(db, "r21") * 1.5, "+7")
	var player := ArenaRules.player_power(_profile(10), db)
	var bottom := ArenaRules.rival_power(db, "r50")
	assert_true(
		bottom < player and bottom >= player * 0.3,
		"the bottom: a gentle start (%d, %d)" % [bottom, player]
	)


func test_every_five_ranks_hold_all_five_jobs() -> void:
	var db := _content()
	for start in range(1, 47):
		var jobs := {}
		for rank in range(start, start + 5):
			jobs[JobRules.job_of(db, str(ArenaRules.rival(db, ArenaRules.rival_id(rank))["hero"]))] = 1
		assert_eq(jobs.size(), 5, "ranks %d to %d: every job" % [start, start + 4])


func test_a_new_challenger_is_offered_five_spread_above() -> void:
	var p := _profile()
	assert_eq(ArenaRules.rank_of(p, _content()), 51, "unranked, below all fifty")
	assert_eq(
		ArenaRules.choices(p, _content()),
		["r50", "r48", "r46", "r45", "r44"] as Array[String],
		"five, from the nearest to the much stronger"
	)
	var labels: Array[String] = []
	for id in ArenaRules.choices(p, _content()):
		labels.append(
			str(
				(
					ArenaRules
					. difficulty(_content(), id, ArenaRules.player_power(p, _content()))["label"]
				)
			)
		)
	assert_eq(labels, ["Easy", "Easy", "Even", "Hard", "Very Hard"] as Array[String], "a spread")
	assert_eq(ArenaRules.closed(_profile(9), _content()) != "", true, "closed below level 10")
	assert_eq(ArenaRules.closed(p, _content()), "", "open from level 10")


func test_a_win_swaps_ranks_and_a_loss_changes_nothing() -> void:
	var db := _content()
	var p := _profile()
	var lost := ArenaRules.record(p, db, "r47", ArenaRules.LOSS)
	assert_eq([lost["old_rank"], lost["new_rank"]], [51, 51], "a loss keeps the rank")
	var won := ArenaRules.record(p, db, "r47", ArenaRules.WIN)
	assert_eq([won["old_rank"], won["new_rank"]], [51, 47], "a win takes the rival's rank")
	assert_eq(ArenaRules.rank_of(p, db, "r47"), 51, "the rival drops to the player's")
	assert_true(won["new_best"], "a new best")
	assert_eq(ArenaRules.choices(p, db)[0], "r46", "and the next five are above")
	var arena := ArenaRules.state(p, db)
	assert_eq([int(arena["wins"]), int(arena["losses"]), int(arena["best"])], [1, 1, 47], "kept")


func test_climbing_pays_each_best_rank_reward_once() -> void:
	var db := _content()
	var p := _profile()
	var money := p.money
	var paid := 0
	var steps := 0
	while ArenaRules.rank_of(p, db) > 1 and steps < 60:
		steps += 1
		var above := _highest(p, ArenaRules.choices(p, db))
		paid += int(ArenaRules.record(p, db, above, ArenaRules.WIN)["money"])
	var expected := 0
	for reward: Dictionary in db.arena["rewards"]:
		expected += int(reward["money"])
	assert_eq(ArenaRules.rank_of(p, db), 1, "the top in %d wins" % steps)
	assert_eq(paid, expected, "every reward once on the way up")
	assert_eq(p.money, money + expected, "paid in coins")
	assert_eq(ArenaRules.choices(p, db)[0], ArenaRules.state(p, db)["order"][1], "defend below")
	var defended := ArenaRules.record(p, db, ArenaRules.choices(p, db)[0], ArenaRules.WIN)
	assert_eq([defended["new_rank"], defended["money"]], [1, 0], "the champion stays, unpaid")
	var arena := ArenaRules.state(p, db)
	assert_eq([int(arena["defenses"]), int(arena["streak"])], [1, 1], "a title defense")


## The best-ranked of `ids`.
func _highest(p: PlayerProfile, ids: Array[String]) -> String:
	var best := ids[0]
	for id in ids:
		if ArenaRules.rank_of(p, _content(), id) < ArenaRules.rank_of(p, _content(), best):
			best = id
	return best


func test_the_ladder_is_saved_and_a_broken_one_starts_fresh() -> void:
	var db := _content()
	var p := _profile()
	ArenaRules.record(p, db, "r48", ArenaRules.WIN)
	var loaded := PlayerProfile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), db)
	assert_eq(ArenaRules.rank_of(loaded, db), 48, "rank kept")
	var data := p.to_dict()
	data["arena"]["order"] = ["you", "you"]
	var broken := PlayerProfile.from_dict(data, db)
	assert_eq(ArenaRules.rank_of(broken, db), 51, "a broken ladder starts fresh")


func test_a_match_is_pvp_strength_double_health_no_food_and_a_countdown() -> void:
	var db := _content()
	var p := _profile(50)
	p.add_item("steamed_bun", 3)
	var bout := _match(p, "r50")
	var hero := bout.zone.hero
	var normal := int(p.stats(db)["max_hp"])
	assert_eq(hero.max_hp, roundi(normal * float(db.arena["hp_scale"])), "double health")
	assert_eq(hero.hp, hero.max_hp, "full")
	assert_near(float(hero.skills["heavy_cross"]["scale"]["damage"]), 0.6, "PvP strength")
	assert_eq(bout.rival.max_hp % 2, 0, "the rival too")
	assert_true(bout.rival.can_parry and bout.rival.stun_limit > 0, "a player's protections")
	hero.hp -= 50
	assert_true(not bout.zone.use_item("steamed_bun"), "no food in the arena")
	var press := FighterInput.new()
	press.light = true
	assert_eq(bout.filter(press).light, false, "no input during the countdown")
	var events: Array[ZoneEvent] = []
	for t in int(db.arena["countdown_ticks"]):
		bout.zone.tick(bout.filter(FighterInput.new()))
		bout.tick(events)
	assert_eq(bout.rival.state_tick > 0 and bout.rival.state == Fighter.State.IDLE, true, "waited")
	assert_eq(events.size(), 1, "the countdown ends")
	assert_eq(events[0].type, "arena_start", "with the start")
	assert_eq(bout.filter(press).light, true, "then the hero acts")


func test_the_match_ends_on_a_knock_out_or_the_clock() -> void:
	var db := _content()
	var p := _profile(70)
	var ko := _match(p, "r50")
	ko.countdown = 1
	ko.rival.hp = 1
	ko.rival.position = ko.zone.hero.position + Vector2(24, 0)
	var result := _play(ko, 1.0, 600)
	assert_true(result.get("won", false), "a knock-out wins")
	assert_eq(result.get("reason"), "ko", "by knock-out")
	assert_eq(ArenaRules.rank_of(p, db), 50, "and takes rank 50")
	var timed := _match(p, "r49")
	timed.countdown = 1
	timed.ticks_left = 3
	timed.rival.hp = timed.rival.max_hp / 2
	var events: Array[ZoneEvent] = []
	for t in 5:
		timed.zone.tick(FighterInput.new())
		timed.tick(events)
	assert_eq(events[-1].type, "arena_end", "the clock ends it")
	assert_true(events[-1].data["won"], "the side with more health left wins")
	assert_eq(events[-1].data["reason"], "time", "on time")


func test_the_ladder_gets_harder_to_climb() -> void:
	var db := _content()
	var wins_low := 0
	var wins_top := 0
	for seed_value in range(1, 4):
		var low := _match(_profile(10), "r50")
		low.zone.rng.seed = seed_value
		wins_low += 1 if _play(low, 0.7).get("won", false) else 0
		var top := _match(_profile(10), "r1")
		top.zone.rng.seed = seed_value
		wins_top += 1 if _play(top, 0.7).get("won", false) else 0
	assert_true(wins_low >= 2, "a fair level 10 player beats the bottom rival (%d of 3)" % wins_low)
	assert_eq(wins_top, 0, "and never the champion")


func test_a_beginner_rival_is_slower_and_misreads_more() -> void:
	var rng := RandomNumberGenerator.new()
	var novice := ArenaBrain.new(_content(), rng, 0.0)
	var master := ArenaBrain.new(_content(), rng, 1.0)
	assert_true(novice.miss_share() > master.miss_share(), "misreads more")
	assert_true(novice.cadence() > master.cadence(), "decides less often")
	assert_true(novice.mash_every() > master.mash_every(), "mashes slower")


func test_the_arena_master_opens_the_ladder_and_a_match_returns_to_it() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("riku")
	tree.root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.profile.level = 12
	game.enter_area(game.content.city_area, "")
	var npc := {}
	for entry: Dictionary in game.content.area(game.content.city_area)["npcs"]:
		if entry["role"] == "arena":
			npc = entry
	assert_true(not npc.is_empty(), "the arena master is in the city")
	game.arena.open_ladder(npc)
	await tree.process_frame
	assert_eq(game.menu_name, "arena", "the ladder opens")
	var cards := game.menu.find_children("Rival_*", "PanelContainer", true, false)
	assert_eq(cards.size(), 5, "five rivals to choose from")
	var picked := str(cards[2].name).trim_prefix("Rival_")
	var target := ArenaRules.rank_of(game.profile, game.content, picked)
	var fight := cards[2].find_child("Fight", true, false) as Button
	fight.pressed.emit()
	await tree.process_frame
	assert_eq(game.menu_name, "arena_details", "Fight shows the rival first")
	assert_eq(game.zone.area_id, game.content.city_area, "nothing starts yet")
	var challenge := game.menu.find_child("Challenge", true, false) as Button
	challenge.pressed.emit()
	await tree.process_frame
	assert_eq(game.zone.area_id, "pvp_arena", "into the arena")
	assert_true(game.arena.active(), "a match runs")
	assert_eq(game.city_problem() != "", true, "no leaving mid-match")
	assert_true(game.arena.hud_text().begins_with("ARENA"), "the clock is on the HUD")
	var bout := game.arena.bout
	bout.countdown = 1
	bout.rival.hp = 1
	bout.rival.position = game.zone.hero.position + Vector2(24, 0)
	for t in 60:
		var jab := FighterInput.new()
		jab.light = t % 12 == 1
		jab.face = 1
		game.step(jab)
		if game.menu_name == "arena_result":
			break
	assert_eq(game.menu_name, "arena_result", "the result shows")
	var banner := game.find_child("LevelUp", true, false) as Control
	var title := (banner.get_child(0) as Label).text
	assert_eq(title, "FIGHT!", "the match's banner is its own, not a level-up")
	assert_eq(ArenaRules.rank_of(game.profile, game.content), target, "its rank taken")
	var again := game.menu.find_child("Again", true, false) as Button
	again.pressed.emit()
	await tree.process_frame
	assert_eq(game.zone.area_id, game.content.city_area, "back in the city")
	assert_eq(game.menu_name, "arena", "on the ladder again")
	var saved := SaveStore.load_character(game.profile.id, game.content)
	assert_eq(ArenaRules.rank_of(saved, game.content), target, "saved")
	assert_true(ArenaRules.state(saved, game.content)["pending"].is_empty(), "nothing pending")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
