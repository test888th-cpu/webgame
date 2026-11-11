extends TestCase
## The weight of a throw and empty hands (GrabRules): only an empty-handed
## fighter grabs (a weapon is dropped first), a body is thrown only a couple
## of spaces and slams into the street once.

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


func test_a_thrown_body_flies_evenly_then_slams_down_once() -> void:
	var fighters := _scene("grappler")
	_seize(fighters)
	var body := fighters[1]
	_run(fighters, 1, {1: _press("light")})
	for t in GrabRules.READY_TICKS + 1:
		if body.airborne > 0:
			break
		_run(fighters, 1)
	assert_eq(body.airborne, GrabRules.AIR_TICKS - 1, "in the air")
	var steps: Array[float] = []
	var landings := 0
	var last := body.position.x
	for t in GrabRules.AIR_TICKS + 10:
		_run(fighters, 1)
		if body.airborne > 0 or body.landed:
			steps.append(body.position.x - last)
		last = body.position.x
		landings += 1 if body.landed else 0
	assert_eq(landings, 1, "it hits the street once")
	assert_near(steps[0], steps[steps.size() - 1], "at an even pace, no skid")
	var away := (body.position.x - fighters[0].position.x) / GrabRules.BODY
	assert_true(away <= GrabRules.MAX_THROW_BODIES + 0.01, "no farther than 4 bodies (%.1f)" % away)
	assert_eq(body.knockback_remaining, 0.0, "and stays where it fell")
	assert_eq(body.state, Fighter.State.DOWN, "on the ground")
	assert_eq(body.state_tick, 11, "down since it landed, not since it was thrown")
	_run(fighters, GrabRules.SLAM_DOWN_TICKS - 13)
	assert_eq(body.state, Fighter.State.DOWN, "still down after more than a second")
	_run(fighters, 3)
	assert_eq(body.state, Fighter.State.IDLE, "and up after 1.5 s on the street")


func test_no_throw_sends_a_body_flying_far() -> void:
	var db := _content()
	for job: String in db.job_order:
		var profile: Dictionary = db.jobs[job]["grab"]
		var throw := db.moves.get_move(str(profile["throw"]))
		assert_true(throw.knockdown, job + ": the throw floors the foe")
		var lands := (GrabRules.HOLD_GAP + throw.knockback) / GrabRules.BODY
		assert_true(lands >= 3.0 and lands <= 4.0, "%s lands %.1f bodies away" % [job, lands])
	var bad: Dictionary = db.jobs["brawler"]["grab"].duplicate()
	bad["throw"] = "jab"
	var found := ", ".join(GrabRules.problems(bad, db.moves, "g"))
	assert_true("g.throw: a thrown body hits the ground" in found, found)
	bad["throw"] = "baron_furnace"
	found = ", ".join(GrabRules.problems(bad, db.moves, "g"))
	assert_true("g.throw: knockback 120 lands past 4 bodies" in found, found)
	# Even a skill that scales knockback up cannot fling a body past the limit.
	var fighters := _scene("grappler")
	_seize(fighters)
	fighters[0].grab = fighters[0].grab.duplicate()
	fighters[0].grab["throw"] = "crowd_toss_hit"
	_run(fighters, 40, {1: _press("light")})
	var away := (fighters[1].position.x - fighters[0].position.x) / GrabRules.BODY
	assert_true(away <= GrabRules.MAX_THROW_BODIES + 0.01, "capped (%.1f bodies)" % away)


func test_grabbing_with_a_weapon_drops_it_first_in_a_zone() -> void:
	var db := _content()
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 5)
	var foe := zone.spawn_enemy("dock_thug", zone.hero.position + Vector2(18, 0))
	zone.equip_weapon(zone.hero, "pipe", 5)
	var on_ground := zone.ground_weapons.size()
	var events := zone.tick(_press("grab"))
	var dropped := events.filter(func(e: ZoneEvent) -> bool: return e.type == "weapon_drop")
	assert_eq(zone.hero.weapon, "", "the weapon falls from the hand")
	assert_eq(dropped.size(), 1, "reported once")
	assert_eq(zone.ground_weapons.size(), on_ground + 1, "and lies on the street")
	assert_eq(zone.hero.state, Fighter.State.IDLE, "that press grabs nobody")
	for t in 12:
		zone.tick(_press("grab") if t == 0 else FighterInput.new())
	assert_eq(foe.state, Fighter.State.HELD, "the next press, empty-handed, takes hold")
	var slams := 0
	for t in 40:
		for event in zone.tick(_press("light") if t == 0 else FighterInput.new()):
			slams += 1 if event.type == "slam" and event.data["id"] == foe.id else 0
	assert_eq(slams, 1, "the thrown thug slams into the street once")


func test_a_grab_skill_waits_for_empty_hands() -> void:
	var fighters := _scene("grappler")
	var hero := fighters[0]
	hero.skills = {"power_throw": _content().skills["power_throw"]}
	hero.weapon = "pipe"
	assert_true(not CombatRules.start_skill(hero, "power_throw", _lib()), "armed: no grab skill")
	assert_eq(hero.cooldown_left("power_throw"), 0, "and nothing is spent")
	hero.weapon = ""
	assert_true(CombatRules.start_skill(hero, "power_throw", _lib()), "empty hands: it starts")


func test_every_grab_has_a_known_pose() -> void:
	var db := _content()
	var poses := {}
	for job: String in db.job_order:
		var pose := str(db.jobs[job]["grab"].get("pose", GrabRules.OVERHEAD))
		assert_true(pose in GrabRules.POSES, job + ": " + pose)
		poses[pose] = true
	for skill_id: String in db.skills:
		var plan: Variant = db.skills[skill_id].get("grab")
		if plan is Dictionary:
			poses[str(plan.get("pose", GrabRules.OVERHEAD))] = true
	assert_eq(poses.size(), GrabRules.POSES.size(), "all three poses are used")
	var bad: Dictionary = db.jobs["boxer"]["grab"].duplicate()
	bad["pose"] = "moonsault"
	var found := ", ".join(GrabRules.problems(bad, db.moves, "g"))
	assert_true("g.pose: expected one of" in found, found)


func test_a_piledriver_lands_where_it_stands_as_the_thrower_jumps() -> void:
	var fighters := _scene("grappler")
	var hero := fighters[0]
	var body := fighters[1]
	hero.skills = {"ground_slam": _content().skills["ground_slam"]}
	assert_true(CombatRules.start_skill(hero, "ground_slam", _lib()), "the skill starts")
	var hopped := false
	for t in 120:
		_run(fighters, 1)
		hopped = hopped or hero.hop > 0
	assert_eq(body.grab_pose, GrabRules.PILEDRIVER, "held for a piledriver")
	assert_true(hopped, "the thrower jumps with it")
	var moved := absf(body.position.x - hero.position.x) - GrabRules.HOLD_GAP
	assert_true(moved <= GrabRules.PILEDRIVER_TRAVEL + 0.5, "driven down in place (%.1f)" % moved)


func test_the_view_draws_each_pose() -> void:
	var scene: PackedScene = load("res://scenes/fighter/FighterView.tscn")
	var fighters := _scene("boxer")
	var view: FighterView = scene.instantiate()
	tree.root.add_child(view)
	view.fighter = fighters[1]
	view.set_art("hero_riku", _content().art)
	var sprite := view.get_node("Sprite") as AnimatedSprite2D
	_seize(fighters)
	_run(fighters, FighterView.LIFT_TICKS)  # fully lifted
	var lift := {}
	for pose: String in GrabRules.POSES:
		fighters[1].grab_pose = pose
		view.sync()
		lift[pose] = -sprite.position.y
	assert_true(lift["body_slam"] < lift["overhead"], "a body slam is lifted to the chest")
	assert_near(absf(sprite.rotation), PI, "a piledriver hangs upside down")
	view.queue_free()


func test_an_elite_on_the_street_is_grabbed_and_thrown() -> void:
	var db := _content()
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 5)
	var foe := zone.spawn_enemy("smog_warden", zone.hero.position + Vector2(18, 0))
	(zone.brains[foe.id] as EnemyBrain).cooldown = 100000
	assert_true(db.enemy("smog_warden").get("elite", false), "the Smog Warden is an elite")
	var held := false
	var thrown := false
	for t in 60:
		var press := _press("grab") if t == 0 else (_press("light") if t == 12 else null)
		for event in zone.tick(press if press else FighterInput.new()):
			thrown = thrown or event.type == "slam" and event.data["id"] == foe.id
		held = held or foe.state == Fighter.State.HELD
	assert_true(held, "held like any monster (an elite is no mini-boss)")
	assert_true(thrown, "and slammed")
