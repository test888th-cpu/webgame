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
	_run(fighters, 1, {1: _press("light")})
	var body := fighters[1]
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
	assert_true(away <= GrabRules.MAX_THROW_BODIES + 0.01, "no farther than 3 bodies (%.1f)" % away)
	assert_eq(body.knockback_remaining, 0.0, "and stays where it fell")
	assert_eq(body.state, Fighter.State.DOWN, "on the ground")


func test_no_throw_sends_a_body_flying_far() -> void:
	var db := _content()
	for job: String in db.job_order:
		var profile: Dictionary = db.jobs[job]["grab"]
		var throw := db.moves.get_move(str(profile["throw"]))
		assert_true(throw.knockdown, job + ": the throw floors the foe")
		var lands := (GrabRules.HOLD_GAP + throw.knockback) / GrabRules.BODY
		assert_true(lands >= 2.0 and lands <= 3.0, "%s lands %.1f bodies away" % [job, lands])
	var bad: Dictionary = db.jobs["brawler"]["grab"].duplicate()
	bad["throw"] = "jab"
	var found := ", ".join(GrabRules.problems(bad, db.moves, "g"))
	assert_true("g.throw: a thrown body hits the ground" in found, found)
	bad["throw"] = "grappler_crash"
	found = ", ".join(GrabRules.problems(bad, db.moves, "g"))
	assert_true("g.throw: knockback 50 lands past 3 bodies" in found, found)
	# Even a skill that scales knockback up cannot fling a body past the limit.
	var fighters := _scene("grappler")
	_seize(fighters)
	fighters[0].grab = fighters[0].grab.duplicate()
	fighters[0].grab["throw"] = "crowd_toss_hit"
	_run(fighters, 40, {1: _press("light")})
	var away := (fighters[1].position.x - 500) / GrabRules.BODY
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
