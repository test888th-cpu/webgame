extends TestCase
## The zone simulation: encounters, AI, rewards, exits, boss phases.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _zone(area: String, seed := 7) -> ZoneSim:
	var profile := PlayerProfile.new_game(_content())
	profile.money = 0
	profile.inventory.clear()
	return ZoneSim.new(_content(), profile, area, "", seed)


func _idle() -> FighterInput:
	return FighterInput.new()


func _walk(dir: Vector2) -> FighterInput:
	var input := FighterInput.new()
	input.move = dir
	return input


func _run(zone: ZoneSim, ticks: int, input: FighterInput = null) -> Array[ZoneEvent]:
	var events: Array[ZoneEvent] = []
	for i in ticks:
		events.append_array(zone.tick(input if input else _idle()))
	return events


## Walks the hero east for `ticks`, stepping down the lane to get round
## anything in the way, as a player would.
func _stroll(zone: ZoneSim, ticks: int) -> Array[ZoneEvent]:
	var events: Array[ZoneEvent] = []
	var detour := 0
	for i in ticks:
		var x := zone.hero.position.x
		var stepping := detour > 0
		events.append_array(zone.tick(_walk(Vector2(0, 1) if stepping else Vector2.RIGHT)))
		detour = maxi(0, detour - 1)
		if not stepping and is_equal_approx(zone.hero.position.x, x):
			detour = 12
	return events


func _types(events: Array[ZoneEvent]) -> Array[String]:
	var types: Array[String] = []
	for event in events:
		types.append(event.type)
	return types


## Puts the hero next to the nearest living enemy and swings until it falls.
func _beat_nearest(zone: ZoneSim, limit := 3000) -> Array[ZoneEvent]:
	var events: Array[ZoneEvent] = []
	for i in limit:
		var target: Fighter = null
		for enemy in zone.enemies():
			if not enemy.is_ko() and (target == null or enemy.id < target.id):
				target = enemy
		if target == null:
			if not zone.in_encounter():
				break
			events.append_array(zone.tick(FighterInput.new()))  # wait for the next wave
			continue
		zone.hero.hp = zone.hero.max_hp  # this test is about the enemy, not survival
		zone.hero.position = LaneMovement.clamp_to(target.position - Vector2(22, 0), zone.arena)
		zone.hero.facing = 1
		var input := FighterInput.new()
		input.light = i % 7 == 0
		events.append_array(zone.tick(input))
	return events


func test_same_seed_and_inputs_replay_identically() -> void:
	var a := _zone("saltmarket", 99)
	var b := _zone("saltmarket", 99)
	for i in 900:
		var input := _walk(Vector2.RIGHT) if i < 200 else FighterInput.new()
		input.light = i % 13 == 0
		a.tick(input)
		b.tick(input)
	assert_eq(a.hero.hp, b.hero.hp, "hero HP")
	assert_eq(a.fighters.size(), b.fighters.size(), "fighter count")
	for i in a.fighters.size():
		assert_eq(a.fighters[i].position, b.fighters[i].position, "fighter %d position" % i)


func test_walking_in_starts_an_encounter_and_locks_the_arena() -> void:
	var zone := _zone("saltmarket")
	var events := _stroll(zone, 400)
	assert_true("encounter_start" in _types(events), "encounter started")
	assert_true("spawn" in _types(events), "enemies spawned")
	assert_true(zone.in_encounter(), "fight in progress")
	assert_true(zone.hero.position.x <= zone.arena.end.x, "hero kept inside the arena")
	assert_true(zone.arena.end.x < zone.bounds.end.x, "arena narrower than the street")


func test_enemies_approach_and_attack_the_hero() -> void:
	var zone := _zone("saltmarket")
	_stroll(zone, 200)
	var start_hp := zone.hero.hp
	var events := _run(zone, 900)
	var hits_on_hero := 0
	for event in events:
		if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
			hits_on_hero += 1
	assert_true(hits_on_hero > 0, "enemies landed hits on an idle hero")
	assert_true(zone.hero.hp < start_hp, "hero took damage")


func test_attack_tokens_limit_simultaneous_attackers() -> void:
	var zone := _zone("saltmarket")
	for i in 5:
		zone.spawn_enemy("smogling", zone.hero.position + Vector2(40 + i * 4, 0))
	var worst := 0
	for i in 600:
		zone.hero.hp = zone.hero.max_hp
		zone.tick(_idle())
		var attacking := 0
		for enemy in zone.enemies():
			if enemy.state == Fighter.State.ATTACK:
				attacking += 1
		worst = maxi(worst, attacking)
	assert_true(
		worst <= ZoneSim.MAX_ATTACKERS, "never more than %d attack at once" % ZoneSim.MAX_ATTACKERS
	)
	assert_true(worst >= 1, "but they do attack")


func test_clearing_waves_rewards_and_unlocks() -> void:
	var zone := _zone("saltmarket")
	QuestRules.accept(zone.profile, "clear_saltmarket", _content())
	_stroll(zone, 200)
	var events := _beat_nearest(zone)
	var types := _types(events)
	assert_true("defeat" in types, "enemies defeated")
	assert_true("wave" in types, "second wave arrived")
	assert_true("encounter_clear" in types, "encounter cleared")
	assert_true(not zone.in_encounter(), "arena unlocked")
	assert_eq(zone.arena, zone.bounds, "full street walkable again")
	assert_true(zone.profile.xp > 0 or zone.profile.level > 1, "XP earned")
	assert_eq(zone.profile.defeated.get("smogling", 0), 4, "four smoglings counted")
	assert_eq(zone.profile.quests["clear_saltmarket"]["progress"], 5, "quest counted all five")
	assert_true(zone.pickups.size() > 0, "loot dropped")


func test_pickups_are_collected_by_walking_over_them() -> void:
	var zone := _zone("saltmarket")
	zone.pickups.append({"id": 1, "kind": "money", "amount": 7, "position": zone.hero.position})
	zone.pickups.append(
		{
			"id": 2,
			"kind": "item",
			"item": "steamed_bun",
			"amount": 1,
			"position": zone.hero.position + Vector2(60, 0)
		}
	)
	var events := _run(zone, 1)
	assert_eq(zone.profile.money, 7, "money collected underfoot")
	assert_eq(zone.pickups.size(), 1, "far pickup stays")
	assert_true("pickup" in _types(events), "pickup event")
	zone.hero.position.x += 60
	_run(zone, 1)
	assert_eq(zone.profile.count("steamed_bun"), 1, "item collected")


func test_training_dummy_gives_nothing_and_respawns() -> void:
	var zone := _zone("depot_yard")
	QuestRules.accept(zone.profile, "clear_saltmarket", _content())
	var events := _beat_nearest(zone, 400)
	assert_true("defeat" not in _types(events), "no defeat rewards from a dummy")
	assert_eq(zone.profile.xp, 0, "no XP")
	assert_eq(zone.profile.quests["clear_saltmarket"]["progress"], 0, "no quest progress")
	var dummy := zone.enemies()[0]
	_run(zone, int(_content().enemy("training_dummy")["respawn_ticks"]) + 5)
	assert_eq(dummy.hp, dummy.max_hp, "dummy back to full")


func test_exits_only_when_not_fighting() -> void:
	var zone := _zone("depot_yard")
	zone.hero.position.x = zone.bounds.end.x
	var events := _run(zone, 1, _walk(Vector2.RIGHT))
	assert_true("exit" in _types(events), "east exit from the depot")
	var exit := events[_types(events).find("exit")]
	assert_eq(exit.data["to"], "saltmarket", "leads to Saltmarket")
	var west := _zone("depot_yard")
	west.hero.position.x = west.bounds.position.x
	assert_true("exit" not in _types(_run(west, 1, _walk(Vector2.LEFT))), "no west exit there")
	var fight := _zone("saltmarket")
	_stroll(fight, 200)
	fight.hero.position.x = fight.arena.position.x
	assert_true("exit" not in _types(_run(fight, 1, _walk(Vector2.LEFT))), "locked during a fight")


func test_entry_side_places_the_hero() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "saltmarket", "east", 1)
	assert_true(zone.hero.position.x > zone.bounds.end.x - 40, "arrives at the east end")
	assert_eq(zone.hero.facing, -1, "facing into the street")


func test_boss_enters_second_phase_below_half_hp() -> void:
	var zone := _zone("canal_works")
	var boss := zone.spawn_enemy("sludge_foreman", Vector2(600, 300))
	var heavy_before := CombatRules.starter(boss, _content().moves, "heavy")
	boss.hp = int(boss.max_hp * 0.49)
	var events := _run(zone, 1)
	assert_true("boss_phase" in _types(events), "phase change reported")
	assert_true(
		CombatRules.starter(boss, _content().moves, "heavy") != heavy_before, "new heavy move"
	)
	assert_true(boss.speed > float(_content().enemy("sludge_foreman")["speed"]), "faster")
	assert_true("boss_phase" not in _types(_run(zone, 5)), "only once")


func test_hero_down_is_reported_once() -> void:
	var zone := _zone("saltmarket")
	zone.hero.hp = 1
	zone.profile.hp = 1
	var enemy := zone.spawn_enemy("smogling", zone.hero.position + Vector2(20, 0))
	enemy.facing = -1
	var events := _run(zone, 600)
	assert_eq(_types(events).count("hero_down"), 1, "one hero_down event")
	assert_true(zone.hero.is_ko(), "hero KO")


func test_a_crowd_cannot_stun_lock_the_hero() -> void:
	# Three fast Market Punks against a hero who never presses anything: the
	# hero must never stay helpless longer than the protection allows.
	var cap := CombatRules.HERO_STUN_LIMIT + CombatRules.KNOCKDOWN_TICKS + 1
	for seed in [1, 2, 3]:
		var zone := _zone("night_market", seed)
		zone.hero.max_hp = 1000000
		zone.hero.hp = 1000000
		zone.hero.position = Vector2(600, 300)
		for i in 3:
			zone.spawn_enemy("market_punk", Vector2(560 + i * 40, 280 + i * 10))
		var worst := 0
		var run := 0
		for t in 1800:
			zone.tick(_idle())
			var helpless := zone.hero.state in [Fighter.State.HITSTUN, Fighter.State.DOWN]
			run = run + 1 if helpless else 0
			worst = maxi(worst, run)
		assert_true(worst <= cap, "seed %d: helpless %d ticks (cap %d)" % [seed, worst, cap])
