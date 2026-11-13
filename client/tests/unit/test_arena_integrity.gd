extends TestCase
## Arena results and fairness (ArenaRules, ArenaMatch, ArenaBrain): a result
## applied once per match id, draws and wins over lower ranks moving nobody,
## the clock judged by shares of health with a 2-point draw margin, a match
## left under way settled once as a forfeit (but not one left in the
## countdown), a damaged ladder repaired without losing the player's rank,
## the five rivals spread and stable, the player's own state restored after
## a match, and the AI held to human timing, real cooldowns and real reach.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _profile(level := 10) -> PlayerProfile:
	var p := PlayerProfile.new_game(_content(), "riku")
	p.level = level
	return p


## `p` placed at `rank` on its ladder.
func _place(p: PlayerProfile, rank: int) -> PlayerProfile:
	var order: Array = ArenaRules.state(p, _content())["order"]
	order.erase(ArenaRules.YOU)
	order.insert(rank - 1, ArenaRules.YOU)
	return p


func _match(p: PlayerProfile, id: String, seed_value := 5) -> ArenaMatch:
	var zone := ZoneSim.new(_content(), p, "pvp_arena", "", seed_value)
	return ArenaMatch.new(zone, p, _content(), id)


func test_a_result_is_applied_once_per_match() -> void:
	var db := _content()
	var p := _profile()
	var earlier := ArenaRules.begin(p, db)
	var id := ArenaRules.begin(p, db)
	var first := ArenaRules.record(p, db, "r47", ArenaRules.WIN, id)
	var money := p.money
	var again := ArenaRules.record(p, db, "r47", ArenaRules.WIN, id)
	assert_true(again["duplicate"], "the second is a duplicate")
	assert_eq(ArenaRules.rank_of(p, db), first["new_rank"], "no second move")
	assert_eq(p.money, money, "no second reward")
	var arena := ArenaRules.state(p, db)
	assert_eq(int(arena["wins"]), 1, "one win counted")
	assert_eq((arena["history"] as Array).size(), 1, "one history entry")
	var older := ArenaRules.record(p, db, "r40", ArenaRules.WIN, earlier)
	assert_true(older["duplicate"], "an older match id is refused too")
	assert_eq(ArenaRules.record(p, db, "r40", "maybe")["result"], "maybe", "unknown result...")
	assert_eq(ArenaRules.rank_of(p, db), first["new_rank"], "...changes nothing")


func test_draws_losses_and_wins_below_move_nobody() -> void:
	var db := _content()
	var p := _place(_profile(70), 20)
	var order: Array = ArenaRules.state(p, db)["order"].duplicate()
	ArenaRules.record(p, db, str(order[10]), ArenaRules.DRAW)
	ArenaRules.record(p, db, str(order[10]), ArenaRules.LOSS)
	ArenaRules.record(p, db, str(order[30]), ArenaRules.WIN)
	assert_eq(ArenaRules.state(p, db)["order"], order, "nobody moved")
	var arena := ArenaRules.state(p, db)
	assert_eq([int(arena["wins"]), int(arena["losses"]), int(arena["draws"])], [1, 1, 1], "counted")
	assert_near(ArenaRules.win_rate(arena), 1.0 / 3.0, "win rate over all three")
	var won := ArenaRules.record(p, db, str(order[14]), ArenaRules.WIN)
	assert_eq([won["old_rank"], won["new_rank"]], [20, 15], "a win above swaps")
	var after: Array = ArenaRules.state(p, db)["order"]
	assert_eq(after[19], order[14], "the rival takes rank 20")
	for i in after.size():
		if i != 14 and i != 19:
			assert_eq(after[i], order[i], "nobody else moves (%d)" % (i + 1))


func test_the_clock_compares_health_shares_with_a_draw_margin() -> void:
	var m := 0.02
	assert_eq(ArenaMatch.timeout_result(0.52, 0.31, m), ArenaMatch.Phase.VICTORY, "52 vs 31")
	assert_eq(ArenaMatch.timeout_result(0.46, 0.448, m), ArenaMatch.Phase.DRAW, "46 vs 44.8")
	assert_eq(ArenaMatch.timeout_result(0.30, 0.50, m), ArenaMatch.Phase.DEFEAT, "30 vs 50")
	assert_eq(ArenaMatch.timeout_result(0.50, 0.48, m), ArenaMatch.Phase.VICTORY, "2 points wins")
	var db := _content()
	var p := _profile(40)
	var bout := _match(p, "r45")
	bout.countdown = 1
	bout.ticks_left = 2
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	# Different maximums: 600 of 1000 against 300 of 500 is 60% each, a draw.
	bout.zone.hero.max_hp = 1000
	bout.zone.hero.hp = 600
	bout.rival.max_hp = 500
	bout.rival.hp = 300
	bout.tick(events)
	bout.tick(events)
	assert_eq(events[-1].type, "arena_end", "the clock ends it")
	assert_eq(events[-1].data["result"], ArenaRules.DRAW, "equal shares draw")
	assert_eq(ArenaRules.rank_of(p, db), 51, "a draw moves nobody")
	assert_eq(int(events[-1].data["money"]), 0, "and pays nothing")
	assert_eq(ArenaRules.state(p, db)["history"][0]["result"], ArenaRules.DRAW, "in the history")


func test_phases_run_forward_only_and_the_end_is_processed_once() -> void:
	var p := _profile(70)
	var bout := _match(p, "r50")
	assert_eq(bout.phase, ArenaMatch.Phase.COUNTDOWN, "counting down")
	assert_true(not bout._go(ArenaMatch.Phase.VICTORY), "no skipping the fight")
	bout.countdown = 1
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	assert_eq(bout.phase, ArenaMatch.Phase.ACTIVE, "fighting")
	bout.rival.state = Fighter.State.KO
	bout.tick(events)
	bout.tick(events)
	bout.tick(events)
	var ends := events.filter(func(e: ZoneEvent) -> bool: return e.type == "arena_end")
	assert_eq(ends.size(), 1, "one result")
	assert_eq(bout.phase, ArenaMatch.Phase.RESULT_PROCESSING, "processed")
	assert_true(not bout._go(ArenaMatch.Phase.ACTIVE), "never back to the fight")
	bout.shown()
	bout.returned()
	assert_eq(bout.phase, ArenaMatch.Phase.RETURN, "and out")
	assert_eq(int(ArenaRules.state(p, _content())["wins"]), 1, "one win")


func test_leaving_during_the_fight_is_one_forfeit_but_the_countdown_is_free() -> void:
	var db := _content()
	var p := _profile(30)
	var early := _match(p, "r46")
	var events: Array[ZoneEvent] = []
	early.tick(events)
	assert_true(ArenaRules.state(p, db)["pending"].is_empty(), "nothing pending in the countdown")
	assert_eq(ArenaRules.settle_pending(p, db), {}, "leaving now costs nothing")
	var bout := _match(p, "r46")
	bout.countdown = 1
	bout.tick(events)
	var pending: Dictionary = ArenaRules.state(p, db)["pending"]
	assert_eq([pending["match"], pending["rival"]], [bout.match_id, "r46"], "the fight is pending")
	# The game closes: the saved profile is loaded again.
	var saved := PlayerProfile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), db)
	var settled := ArenaRules.settle_pending(saved, db)
	assert_eq(settled["result"], ArenaRules.LOSS, "a forfeit loss")
	assert_eq(ArenaRules.state(saved, db)["history"][0]["reason"], "forfeit", "recorded so")
	assert_eq(ArenaRules.rank_of(saved, db), 51, "no rank change")
	assert_eq(int(ArenaRules.state(saved, db)["losses"]), 1, "one loss")
	assert_eq(ArenaRules.settle_pending(saved, db), {}, "settled once")
	var twice := ArenaRules.record(saved, db, "r46", ArenaRules.WIN, bout.match_id)
	assert_true(twice["duplicate"], "the forfeited match cannot be won afterwards")


func test_the_game_settles_a_forfeit_on_start() -> void:
	SaveStore.root = "user://test_arena_forfeit"
	SaveStore.delete_all()
	GameSession.start_new_game("riku")
	var p: PlayerProfile = GameSession.profile
	p.level = 20
	ArenaRules.mark_active(p, _content(), ArenaRules.begin(p, _content()), "r50")
	p.area = "pvp_arena"
	tree.root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	await tree.process_frame
	assert_eq(game.zone.area_id, game.content.city_area, "back in the city, not the arena")
	assert_eq(int(ArenaRules.state(game.profile, game.content)["losses"]), 1, "a forfeit")
	assert_true(ArenaRules.state(game.profile, game.content)["pending"].is_empty(), "settled")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_a_damaged_ladder_is_repaired_keeping_the_players_rank() -> void:
	var db := _content()
	var p := _place(_profile(70), 12)
	var data := p.to_dict()
	var order: Array = data["arena"]["order"]
	order[3] = order[4]  # a duplicate
	order.insert(7, "r999")  # an unknown id
	order.remove_at(30)  # a missing rival
	var loaded := PlayerProfile.from_dict(data, db)
	var fixed: Array = ArenaRules.state(loaded, db)["order"]
	assert_eq(fixed.size(), 51, "fifty rivals and you")
	var seen := {}
	for id: Variant in fixed:
		assert_true(not seen.has(id), "no duplicate: %s" % id)
		seen[id] = true
	assert_true(not seen.has("r999"), "no unknown id")
	assert_eq(ArenaRules.rank_of(loaded, db), 12, "the player's rank is kept")
	assert_true(ArenaRules.state(loaded, db)["best"] <= 12, "and best")


func test_five_rivals_spread_stay_stable_and_refresh() -> void:
	var db := _content()
	var p := _place(_profile(70), 41)
	var first := ArenaRules.choices(p, db)
	assert_eq(first, ArenaRules.choices(p, db), "the same state, the same five")
	assert_eq(first.size(), 5, "five")
	assert_true(ArenaRules.YOU not in first, "never yourself")
	var ranks: Array[int] = []
	for id in first:
		ranks.append(ArenaRules.rank_of(p, db, id))
	assert_eq(ranks[0], 40, "the nearest first")
	assert_true(ranks[-1] <= 34, "the farthest well above: %s" % str(ranks))
	var unique := {}
	for r in ranks:
		unique[r] = true
	assert_eq(unique.size(), 5, "no duplicates")
	var shifted := false
	for n in 4:
		ArenaRules.refresh(p, db)
		var again := ArenaRules.choices(p, db)
		assert_eq(again[0], first[0], "the nearest stays")
		shifted = shifted or again != first
	assert_true(shifted, "New rivals offers others")
	var top := _place(_profile(70), 3)
	var near := ArenaRules.choices(top, db)
	assert_eq(near.slice(0, 2), [ArenaRules.state(top, db)["order"][1], "r1"], "both above")
	assert_eq(near.size(), 5, "and three below to defend")
	var champ := _place(_profile(70), 1)
	assert_eq(ArenaRules.rank_of(champ, db, ArenaRules.choices(champ, db)[0]), 2, "defend #2..")
	assert_eq(ArenaRules.champion(champ, db), ArenaRules.YOU, "the champion is you")


func test_difficulty_comes_from_real_power_and_ai() -> void:
	var db := _content()
	var p := _profile(10)
	var mine := ArenaRules.player_power(p, db)
	var easy := ArenaRules.difficulty(db, "r50", mine)
	var data := ArenaRules.rival(db, "r50")
	var made := ArenaLoadout.profile(db, data)
	assert_eq(easy["power"], ArenaRules.power(made.stats(db), made.level), "its real power")
	var ratio := float(easy["power"]) / mine * (0.85 + 0.3 * float(data["ai"]))
	assert_near(float(easy["ratio"]), ratio, "power ratio times AI")
	assert_eq(easy["label"], "Easy", "the bottom is easy for a level 10")
	assert_eq(ArenaRules.difficulty(db, "r1", mine)["label"], "Very Hard", "the champion is not")
	assert_eq(ArenaRules.ai_label(db, 0.0), "Beginner", "AI levels")
	assert_eq(ArenaRules.ai_label(db, 1.0), "Master", "named")


func test_the_players_health_and_gauge_come_back_unchanged_after_a_match() -> void:
	var db := _content()
	var p := _profile(40)
	p.hp = 123
	p.gauge = 37.0
	p.add_item("steamed_bun", 2)
	var bag := p.inventory.duplicate(true)
	var worn := p.equipment.duplicate()
	var money := p.money
	var bout := _match(p, "r45")
	assert_true(bout.zone.hero.max_hp > int(p.stats(db)["max_hp"]), "doubled in the arena")
	assert_eq(bout.zone.hero.gauge, 0.0, "an empty gauge in the arena")
	bout.countdown = 1
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	bout.zone.hero.gauge = 90.0
	bout.zone.tick(FighterInput.new())
	bout.zone.hero.state = Fighter.State.KO
	bout.tick(events)
	bout.restore()
	assert_eq(p.hp, 123, "health as before")
	assert_near(p.gauge, 37.0, "gauge as before")
	assert_near(bout.zone.hero.gauge, 37.0, "on the hero that carries it out")
	assert_eq(p.inventory, bag, "no item used or added")
	assert_eq(p.equipment, worn, "gear untouched")
	assert_eq(p.money, money, "a loss pays nothing")


## The rival against a hero that throws one jab at `tick` from up close.
func _jab_at(brain_skill: float, state_tick: int, seed_value: int) -> FighterInput:
	var p := _profile(70)
	var bout := _match(p, "r1", seed_value)
	var brain := ArenaBrain.new(_content(), bout.zone.rng, brain_skill)
	var hero := bout.zone.hero
	var rival := bout.rival
	hero.position = rival.position - Vector2(30, 0)
	hero.facing = 1
	hero.state = Fighter.State.ATTACK
	hero.move = _content().moves.get_move(CombatRules.starter(hero, _content().moves, "light"))
	hero.state_tick = state_tick
	return brain.think(rival, hero, true, _content().moves, bout.zone.rng, Vector2.INF, 999)


func test_the_ai_never_reacts_before_a_human_could() -> void:
	var early := 0
	for seed_value in range(1, 41):
		if _defends(_jab_at(1.0, 2, seed_value)):
			early += 1
	assert_eq(early, 0, "nothing answers a blow 2 ticks old")
	var brain := ArenaBrain.new(_content(), RandomNumberGenerator.new(), 1.0)
	assert_eq(brain.react_after, 12, "the best sees a blow at 200 ms")
	assert_eq(
		ArenaBrain.new(_content(), RandomNumberGenerator.new(), 0.0).react_after, 24, "400 ms"
	)
	brain.configure({"reaction_ticks": 1})
	assert_eq(brain.react_after, 12, "configure cannot go under 200 ms")
	assert_true(brain.cadence() >= 3, "decides at most every 50 ms")
	assert_true(brain.mash_every() >= 5, "mashes at most 12 times a second")


## A guard, a dodge or a counter stance: an answer to a blow.
func _defends(input: FighterInput) -> bool:
	if input.guard or input.dodge:
		return true
	if input.skill == "":
		return false
	var move := _content().moves.get_move(str(_content().skills[input.skill]["move"]))
	return move != null and move.counter


## Plays a ranked match with the hero standing still, recording every skill
## the rival presses with its cooldown, energy and distance at that moment.
func _watch_rival(id: String, ticks: int, seed_value := 3) -> Dictionary:
	var p := _profile(70)
	var bout := _match(p, id, seed_value)
	bout.countdown = 1
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	var rival := bout.rival
	var hero := bout.zone.hero
	var start_gap := absf(rival.position.x - hero.position.x)
	var presses: Array[Dictionary] = []
	var damage := 0
	for t in ticks:
		var input := bout.brain.think(
			rival, hero, true, _content().moves, bout.zone.rng, Vector2.INF, bout.zone.tick_count
		)
		if input.skill != "":
			var move := _content().moves.get_move(str(rival.skills[input.skill]["move"]))
			(
				presses
				. append(
					{
						"cooldown": rival.cooldown_left(input.skill),
						"energy_ok": rival.energy >= move.energy_cost,
						"gap": absf(hero.position.x - rival.position.x),
						"far":
						(
							move.reach_offset
							+ move.reach
							+ move.advance
							+ 2 * CombatRules.HURT_HALF_WIDTH
						),
					}
				)
			)
		var hp := hero.hp
		bout.zone.tick(FighterInput.new())
		damage += maxi(0, hp - hero.hp)
		if hero.is_ko():
			break
	return {
		"presses": presses,
		"damage": damage,
		"closed": start_gap - absf(rival.position.x - hero.position.x),
		"brain": bout.brain,
	}


func test_a_rival_keeps_its_job_skills_in_the_arena() -> void:
	var p := _profile(70)
	var bout := _match(p, "r10")
	var skills := bout.rival.skills.keys()
	assert_true(skills.size() >= 5, "a level 70 hero's skills: %s" % str(skills))
	for t in 30:
		bout.zone.tick(FighterInput.new())
		bout.tick([] as Array[ZoneEvent])
	assert_eq(bout.rival.skills.keys(), skills, "the boss machinery leaves them alone")


func test_the_ai_closes_in_attacks_and_obeys_cooldowns_energy_and_reach() -> void:
	var seen := _watch_rival("r10", 900)
	assert_true(seen["closed"] > 20.0, "it walks in (%.0f)" % seen["closed"])
	assert_true(seen["damage"] > 0, "and lands blows (%d)" % seen["damage"])
	var presses: Array = seen["presses"]
	assert_true(presses.size() >= 3, "it uses its skills (%d)" % presses.size())
	for press: Dictionary in presses:
		assert_eq(press["cooldown"], 0, "never a skill on cooldown")
		assert_true(press["energy_ok"], "never without the energy")
		assert_true(press["gap"] <= press["far"], "never from out of reach: %s" % str(press))


func test_a_rival_knocked_down_gets_up_and_fights_on() -> void:
	var p := _profile(70)
	var bout := _match(p, "r30")
	bout.countdown = 1
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	bout.rival.position = bout.zone.hero.position + Vector2(40, 0)
	bout.rival.state = Fighter.State.DOWN
	bout.rival.state_tick = 0
	var acted := false
	for t in 600:
		bout.zone.tick(FighterInput.new())
		bout.tick(events)
		if bout.rival.state == Fighter.State.ATTACK:
			acted = true
			break
	assert_true(acted, "up again and attacking")


func test_personalities_play_differently() -> void:
	# Three bouts each (one bout is too small a sample: who attacks whom how
	# often swings with a single seed).
	var styles := {}
	for name: String in ["aggressive", "defensive", "counter"]:
		var totals := {"skills": 0.0, "defends": 0.0, "gap": 0.0, "ticks": 0}
		for seed_value in [7, 8, 9]:
			var bout := _personality_bout(name, seed_value)
			for key: String in totals:
				totals[key] += bout[key]
		var minutes: float = totals["ticks"] / 3600.0
		styles[name] = {
			"skills_per_minute": snappedf(totals["skills"] / minutes, 0.1),
			"guards_per_minute": snappedf(totals["defends"] / minutes, 0.1),
			"gap": snappedf(totals["gap"] / totals["ticks"], 0.1),
		}
	var a: Dictionary = styles["aggressive"]
	var d: Dictionary = styles["defensive"]
	assert_true(
		a["skills_per_minute"] > d["skills_per_minute"], "aggressive attacks more: %s" % str(styles)
	)
	assert_true(
		d["guards_per_minute"] > a["guards_per_minute"], "defensive guards more: %s" % str(styles)
	)
	assert_true(styles["counter"] != a, "counter is its own style")


## One 30 s bout of rival r20 played with personality `name` against an
## average arena brain on Riku: its skills, defends, mean gap and ticks.
func _personality_bout(name: String, seed_value: int) -> Dictionary:
	var db := _content()
	var bout := _match(_profile(70), "r20", seed_value)
	var settings: Dictionary = ArenaRules.rival(db, "r20")["brain"].duplicate()
	settings.merge(db.arena["personalities"][name], true)
	bout.brain.configure(settings)
	bout.countdown = 1
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	var gap := 0.0
	var ticks := 0
	var foe := ArenaBrain.new(db, bout.zone.rng, 0.5)
	for t in 1800:
		var input := foe.think(
			bout.zone.hero, bout.rival, true, db.moves, bout.zone.rng, Vector2.INF, 0
		)
		bout.zone.tick(bout.filter(input))
		bout.tick(events)
		if bout.over:
			break
		ticks += 1
		gap += absf(bout.rival.position.x - bout.zone.hero.position.x)
	return {
		"skills": float(bout.brain.stats["skills"]),
		"defends": float(bout.brain.stats["defends"]),
		"gap": gap,
		"ticks": ticks,
	}
