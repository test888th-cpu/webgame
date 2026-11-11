extends TestCase
## Grab and throw (GrabRules): every job can seize a foe and throw them, a
## thrown body knocks into others, and nobody is held without a way out.

const BOUNDS := Rect2(0, 200, 2000, 200)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _lib() -> MoveLibrary:
	return _content().moves


## A hero of `job` and a foe within arm's reach, plus `extra` foes behind it.
func _scene(job := "brawler", extra := 0) -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.grab = _content().jobs[job]["grab"]
	var fighters: Array[Fighter] = [hero]
	for i in 1 + extra:
		var foe := Fighter.new(2 + i, 2, Vector2(520 + 40 * i, 300), 200)
		foe.facing = -1
		fighters.append(foe)
	return fighters


func _press(button: String) -> FighterInput:
	var input := FighterInput.new()
	input.set(button, true)
	return input


## Runs `ticks` ticks with `first` as the inputs of the first one.
func _run(fighters: Array[Fighter], ticks: int, first := {}) -> Array[CombatEvent]:
	var hits: Array[CombatEvent] = []
	for t in ticks:
		hits.append_array(CombatRules.tick(fighters, first if t == 0 else {}, _lib(), BOUNDS))
	return hits


## The hero grabs the first foe; returns once the hold has begun.
func _seize(fighters: Array[Fighter]) -> void:
	_run(fighters, 12, {1: _press("grab")})


func test_a_grab_holds_the_foe_in_front() -> void:
	var fighters := _scene()
	_seize(fighters)
	assert_eq(fighters[0].state, Fighter.State.GRAB, "the hero holds")
	assert_eq(fighters[1].state, Fighter.State.HELD, "the foe is held")
	assert_eq([fighters[0].holding, fighters[1].held_by], [2, 1], "each knows the other")
	assert_true(not CombatRules.is_vulnerable(fighters[1]), "a held foe cannot be hit")
	assert_near(fighters[1].position.x, 500 + GrabRules.HOLD_GAP, "carried in front")


func test_a_grab_that_reaches_nobody_is_an_opening() -> void:
	var fighters := _scene()
	fighters[1].position.x = 700
	var energy := fighters[0].energy
	_run(fighters, 3, {1: _press("grab")})
	assert_eq(fighters[0].state, Fighter.State.ATTACK, "the hero is committed to the reach")
	assert_true(fighters[0].energy < energy, "and paid for it")
	_run(fighters, 30)
	assert_eq(fighters[0].state, Fighter.State.IDLE, "then recovers, holding nobody")
	assert_eq(fighters[1].state, Fighter.State.IDLE, "the foe untouched")


func test_the_pick_button_grabs_only_with_empty_hands() -> void:
	var fighters := _scene()
	assert_true(GrabRules.wants(fighters[0], _press("pick")), "empty hands: pick grabs")
	fighters[0].weapon = "pipe"
	assert_true(not GrabRules.wants(fighters[0], _press("pick")), "armed: pick is for the weapon")
	assert_true(GrabRules.wants(fighters[0], _press("grab")), "the grab button always grabs")
	assert_true(not GrabRules.wants(fighters[1], _press("grab")), "enemies have no grab")


func test_an_attack_button_throws_the_held_foe() -> void:
	var fighters := _scene()
	_seize(fighters)
	var hp := fighters[1].hp
	var hits := _run(fighters, 1, {1: _press("light")})
	assert_eq(hits.size(), 1, "the throw lands as one blow")
	assert_eq(hits[0].move_id, "brawler_throw", "the job's throw")
	assert_true(fighters[1].hp < hp, "it hurts")
	assert_eq(fighters[1].state, Fighter.State.DOWN, "and floors the foe")
	assert_eq([fighters[0].holding, fighters[1].held_by], [0, 0], "nobody is held any more")
	_run(fighters, 30)
	assert_true(fighters[1].position.x > 580, "thrown well clear, the way the hero faces")


func test_the_hero_can_turn_and_throw_the_other_way() -> void:
	var fighters := _scene()
	_seize(fighters)
	var turn := FighterInput.new()
	turn.move = Vector2(-1, 0)
	_run(fighters, 1, {1: turn})
	assert_near(fighters[1].position.x, 500 - GrabRules.HOLD_GAP, "carried round behind")
	_run(fighters, 30, {1: _press("heavy")})
	assert_true(fighters[1].position.x < 440, "and thrown that way")


func test_a_thrown_body_knocks_into_the_others_once() -> void:
	var fighters := _scene("grappler", 2)
	_seize(fighters)
	var hits := _run(fighters, 40, {1: _press("light")})
	var crashed := {}
	for hit in hits:
		if hit.move_id == "grappler_crash":
			assert_true(not crashed.has(hit.defender_id), "each foe is hit once")
			crashed[hit.defender_id] = true
	assert_eq(crashed.size(), 2, "both foes in the way are knocked down")
	assert_true(not crashed.has(2), "the thrown body does not hit itself")
	assert_eq(fighters[1].thrown_by, 0, "and is harmless once it lands")


func test_a_hold_ends_by_itself() -> void:
	var fighters := _scene("striker")
	_seize(fighters)
	var hp := fighters[1].hp
	_run(fighters, int(_content().jobs["striker"]["grab"]["hold"]) + 2)
	assert_eq(fighters[0].state, Fighter.State.IDLE, "the hero lets go")
	assert_eq(fighters[1].state, Fighter.State.IDLE, "the foe is free")
	assert_eq(fighters[1].hp, hp, "unhurt")


func test_nobody_is_grabbed_twice_in_a_row() -> void:
	var fighters := _scene("striker")
	_seize(fighters)
	_run(fighters, int(_content().jobs["striker"]["grab"]["hold"]) + 2)
	assert_true(fighters[1].grab_guard > 0, "freshly freed")
	fighters[1].position = Vector2(520, 300)
	var hits := _run(fighters, 12, {1: _press("grab")})
	assert_eq(fighters[1].held_by, 0, "the second grab does not hold")
	assert_eq(hits.size(), 1, "it only shoves")
	assert_eq(hits[0].move_id, "grab_shove", "with the shove")
	_run(fighters, GrabRules.REGRAB_TICKS)
	assert_true(GrabRules.can_hold(fighters[1]), "later they can be held again")


func test_a_boss_cannot_be_held() -> void:
	var fighters := _scene("grappler")
	fighters[1].unshaken = true
	var hp := fighters[1].hp
	var hits := _run(fighters, 12, {1: _press("grab")})
	assert_eq(fighters[0].state != Fighter.State.GRAB, true, "no hold on a boss")
	assert_eq(fighters[1].held_by, 0, "the boss is free")
	assert_eq(hits[0].move_id, "grab_shove", "the grab lands as a shove")
	assert_true(fighters[1].hp < hp, "that still hurts")


func test_a_tough_monster_is_held_half_as_long() -> void:
	var fighters := _scene()
	assert_eq(GrabRules.hold_ticks(fighters[0], fighters[1]), 45, "a common foe: the full hold")
	fighters[1].poise_limit = 60
	assert_eq(GrabRules.hold_ticks(fighters[0], fighters[1]), 22, "a foe with poise: half")
	assert_true(GrabRules.can_hold(fighters[1]), "but still held: it is an ordinary monster")


func test_only_monsters_and_players_are_ever_held() -> void:
	var db := _content()
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 5)
	var at := zone.hero.position + Vector2(18, 0)
	var held := {}
	var counts := {"boss": 0, "mini": 0, "monster": 0}
	for kind: String in db.enemies:
		var data: Dictionary = db.enemies[kind]
		if data.get("training", false):
			continue
		var foe := zone.spawn_enemy(kind, at)
		var rank := "boss" if data.get("boss", false) else "monster"
		rank = "mini" if data.get("elite", false) else rank
		counts[rank] += 1
		held[rank] = held.get(rank, 0) + (1 if GrabRules.can_hold(foe) else 0)
		assert_eq(
			GrabRules.can_hold(foe),
			rank == "monster",
			"%s (%s) can be held: %s" % [kind, rank, rank == "monster"]
		)
		zone.fighters.erase(foe)
		zone.brains.erase(foe.id)
	assert_true(
		counts["boss"] > 0 and counts["mini"] > 0 and counts["monster"] > 0, "all three kinds"
	)
	assert_eq([held["boss"], held["mini"]], [0, 0], "no boss or mini-boss is ever held")
	assert_eq(held["monster"], counts["monster"], "every ordinary monster can be")
	assert_true(GrabRules.can_hold(zone.hero), "and so can a player")


func test_a_grab_on_a_mini_boss_only_shoves_in_a_real_zone() -> void:
	var db := _content()
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 5)
	var foe := zone.spawn_enemy("smog_warden", zone.hero.position + Vector2(18, 0))
	(zone.brains[foe.id] as EnemyBrain).cooldown = 100000
	var hp := foe.hp
	var was_held := false
	var shoved := false
	for t in 40:
		for event in zone.tick(_press("grab") if t == 0 else FighterInput.new()):
			shoved = shoved or (event.type == "hit" and event.hit.move_id == "grab_shove")
		was_held = was_held or foe.state == Fighter.State.HELD
	assert_true(not was_held, "the mini-boss is never held")
	assert_true(shoved and foe.hp < hp, "the grab lands as a shove")
	assert_eq(zone.hero.holding, 0, "and the hero holds nobody")


func test_hitting_the_holder_frees_the_held() -> void:
	var fighters := _scene("brawler", 1)
	_seize(fighters)
	fighters[2].position = Vector2(476, 300)
	fighters[2].facing = 1
	fighters[2].moveset = {"light": "thug_jab"}
	_run(fighters, _lib().get_move("thug_jab").startup + 3, {3: _press("light")})
	assert_true(fighters[0].state != Fighter.State.GRAB, "the hero is knocked out of the hold")
	assert_eq(fighters[1].state, Fighter.State.IDLE, "and the foe walks free")
	assert_eq(fighters[1].held_by, 0, "held by nobody")


func test_a_held_player_struggles_free_sooner() -> void:
	var calm := _scene("grappler")
	var busy := _scene("grappler")
	for fighters: Array[Fighter] in [calm, busy]:
		fighters[1].stun_limit = CombatRules.HERO_STUN_LIMIT
		_seize(fighters)
	var calm_ticks := 0
	var busy_ticks := 0
	while calm[1].state == Fighter.State.HELD and calm_ticks < 200:
		CombatRules.tick(calm, {}, _lib(), BOUNDS)
		calm_ticks += 1
	while busy[1].state == Fighter.State.HELD and busy_ticks < 200:
		var inputs := {2: _press("light")} if busy_ticks % 4 == 0 else {}
		CombatRules.tick(busy, inputs, _lib(), BOUNDS)
		busy_ticks += 1
	assert_true(busy_ticks < calm_ticks / 2, "mashing: %d ticks, not %d" % [busy_ticks, calm_ticks])
	var foe := _scene("grappler")
	_seize(foe)
	var held := 0
	while foe[1].state == Fighter.State.HELD and held < 200:
		CombatRules.tick(foe, {2: _press("light")}, _lib(), BOUNDS)
		held += 1
	assert_true(held >= calm_ticks - 2, "a common enemy cannot struggle out")


func test_every_job_grabs_and_the_grappler_does_it_best() -> void:
	var db := _content()
	var best := {"hold": "", "damage": "", "distance": "", "reach": ""}
	var top := {"hold": 0.0, "damage": 0.0, "distance": 0.0, "reach": 0.0}
	for job: String in db.job_order:
		var profile: Dictionary = db.jobs[job]["grab"]
		assert_eq(GrabRules.problems(profile, db.moves, job), PackedStringArray(), job + ": valid")
		var throw := db.moves.get_move(str(profile["throw"]))
		var values := {
			"hold": float(profile["hold"]),
			"damage": float(throw.damage),
			"distance": throw.knockback,
			"reach": db.moves.get_move(str(profile["move"])).reach,
		}
		for key: String in values:
			if values[key] > top[key]:
				top[key] = values[key]
				best[key] = job
	for key: String in best:
		assert_eq(best[key], "grappler", "the Grappler has the best " + key)
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 1)
	assert_eq(zone.hero.grab["throw"], "grappler_throw", "the zone gives the hero their job's grab")


func test_bad_grab_data_is_refused() -> void:
	var db := _content()
	var profile: Dictionary = db.jobs["boxer"]["grab"].duplicate()
	profile["move"] = "jab"
	profile["hold"] = 600
	profile["throw"] = "nothing"
	var found := ", ".join(GrabRules.problems(profile, db.moves, "g"))
	for part: String in ["g.move: must be a grab", "g.hold: expected", "g.throw: unknown move"]:
		assert_true(part in found, "%s: %s" % [part, found])


func test_the_view_shows_the_reach_the_lift_and_the_carried_foe() -> void:
	var db := _content()
	var scene: PackedScene = load("res://scenes/fighter/FighterView.tscn")
	var fighters := _scene("grappler")
	var views: Array[FighterView] = []
	for i in 2:
		var view: FighterView = scene.instantiate()
		tree.root.add_child(view)
		view.fighter = fighters[i]
		view.set_art(["hero_oren", "hero_riku"][i], db.art)
		views.append(view)
	var holder: AnimatedSprite2D = views[0].get_node("Sprite")
	var carried: AnimatedSprite2D = views[1].get_node("Sprite")
	_run(fighters, 3, {1: _press("grab")})
	views[0].sync()
	assert_eq(holder.animation, &"grab", "reaching out plays the grab")
	_run(fighters, 9 + FighterView.LIFT_TICKS)
	for view in views:
		view.sync()
	assert_eq(holder.animation, &"lift", "holding plays the lift")
	assert_true(carried.position.y < -30.0, "the held foe is drawn overhead")
	assert_true(absf(carried.rotation) > 1.5, "lying on their side")
	_run(fighters, 2, {1: _press("light")})
	for view in views:
		view.sync()
	assert_eq(holder.animation, &"throw", "the throw plays")
	assert_eq(carried.position, Vector2.ZERO, "and the foe is back on their own feet's spot")
	assert_near(carried.rotation, 0.0, "upright in the sheet's own pose")
	for view in views:
		view.queue_free()


func test_every_lpc_character_has_the_grab_art_and_others_fall_back() -> void:
	var db := _content()
	for id: String in db.art:
		var entry: Dictionary = db.art[id]
		if entry.get("source") != "lpc":
			continue
		for anim: String in ["grab", "lift", "throw"]:
			assert_true(entry["animations"].has(anim), "%s has %s" % [id, anim])
	for anim: String in ["grab", "throw", "lift"]:
		assert_true(FighterView.FALLBACK.has(anim), anim + " has a stand-in for painted art")
	assert_true("grab" in MoveLibrary.ANIMS and "throw" in MoveLibrary.ANIMS, "moves may use them")


func test_in_a_zone_the_pick_button_grabs_and_a_throw_can_win_the_fight() -> void:
	var db := _content()
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 5)
	var foe := zone.spawn_enemy("dock_thug", zone.hero.position + Vector2(18, 0))
	foe.hp = 1
	var held := false
	var defeated := false
	var thrown := false
	for t in 120:
		var input := FighterInput.new()
		input.pick = t == 0
		input.light = held and not thrown
		thrown = thrown or input.light
		for event in zone.tick(input):
			if event.type == "defeat":
				defeated = true
		held = held or foe.state == Fighter.State.HELD
	assert_true(held, "E with empty hands grabs the thug")
	assert_true(defeated, "and the throw that finishes them counts as a defeat")
	assert_eq(zone.hero.state, Fighter.State.IDLE, "the hero is back on guard")
