extends TestCase
## Skills of several blows (SkillSequence): each stage starts by itself, hits
## a defender once, and the skill stops when its user is interrupted. Balance
## scales (BalanceProfile) reach the blows of a running skill only.

const BOUNDS := Rect2(0, 200, 2000, 200)
const STAGES: Array[String] = ["jab", "cross", "body_hook"]

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


## A hero who knows a three-blow skill, and a sturdy foe in front.
func _pair(scale := {}) -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.skills = {"flurry": {"move": "jab", "cooldown": 300, "then": ["cross", "body_hook"]}}
	hero.skills["flurry"]["scale"] = scale
	var foe := Fighter.new(2, 2, Vector2(524, 300), 1000)
	foe.facing = -1
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


func _press(skill_id: String) -> FighterInput:
	var input := FighterInput.new()
	input.skill = skill_id
	return input


## Runs `ticks` ticks (the skill pressed on the first) and returns the hits.
func _run(fighters: Array[Fighter], ticks: int, mash := false) -> Array[CombatEvent]:
	var hits: Array[CombatEvent] = []
	for t in ticks:
		var inputs := {}
		if t == 0:
			inputs[1] = _press("flurry")
		elif mash:
			var jab := FighterInput.new()
			jab.light = true
			inputs[1] = jab
		hits.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	return hits


func _length() -> int:
	var ticks := 0
	for id in STAGES:
		ticks += _lib().get_move(id).total_ticks()
	return ticks


func test_every_stage_lands_once_in_order() -> void:
	var fighters := _pair()
	var hits := _run(fighters, _length() + 10)
	var moves := []
	for hit in hits:
		moves.append(hit.move_id)
	assert_eq(moves, STAGES, "three blows, one hit each, in order")
	assert_eq(fighters[0].state, Fighter.State.IDLE, "and the skill is over")
	assert_eq(fighters[0].skill_id, "", "no skill running")
	assert_eq(fighters[0].cooldown_left("flurry") > 0, true, "one cooldown for the whole skill")


func test_only_the_first_move_costs_energy() -> void:
	var fighters := _pair()
	fighters[0].skills["flurry"]["move"] = "haymaker"
	var before := fighters[0].energy
	CombatRules.tick(fighters, {1: _press("flurry")}, _lib(), BOUNDS)
	var cost := _lib().get_move("haymaker").energy_cost
	assert_near(before - fighters[0].energy, cost - CombatRules.ENERGY_REGEN, "paid once", cost)
	var problems := SkillSequence.problems({"move": "jab", "then": ["haymaker"]}, _lib(), "s")
	assert_true("must cost no energy" in ", ".join(problems), "a later stage may not cost")
	problems = SkillSequence.problems({"move": "nothing", "then": ["nothing"]}, _lib(), "s")
	assert_eq(problems.size(), 2, "unknown moves are refused")


func test_mashing_does_not_cut_the_sequence_short() -> void:
	var fighters := _pair()
	var hits := _run(fighters, _length() - 2, true)
	var moves := []
	for hit in hits:
		moves.append(hit.move_id)
	assert_eq(moves, STAGES, "the stages play out whatever is pressed")


func test_an_interrupted_skill_stops() -> void:
	var fighters := _pair()
	CombatRules.tick(fighters, {1: _press("flurry")}, _lib(), BOUNDS)
	assert_eq(fighters[0].skill_id, "flurry", "the skill is running")
	assert_true(SkillSequence.pending(fighters[0]), "with stages to come")
	fighters[0].enter(Fighter.State.HITSTUN, 20)
	assert_eq(fighters[0].skill_id, "", "a blow ends it")
	var hits := _run(fighters, 1)
	for t in _length():
		hits.append_array(CombatRules.tick(fighters, {}, _lib(), BOUNDS))
	assert_eq(hits.size(), 0, "and no later stage comes out")


func test_a_miss_still_plays_every_stage_but_hits_nothing() -> void:
	var fighters := _pair()
	fighters[1].position.x = 900
	var hits := _run(fighters, _length() + 10)
	assert_eq(hits.size(), 0, "nothing in reach")
	assert_eq(fighters[0].state, Fighter.State.IDLE, "the skill ran its length")


func test_a_plain_attack_after_a_skill_is_not_a_skill() -> void:
	var fighters := _pair()
	_run(fighters, _length() + 10)
	var jab := FighterInput.new()
	jab.light = true
	CombatRules.tick(fighters, {1: jab}, _lib(), BOUNDS)
	assert_eq(fighters[0].state, Fighter.State.ATTACK, "jabbing")
	assert_eq(fighters[0].skill_id, "", "not a skill")
	assert_near(SkillSequence.scale(fighters[0], "damage"), 1.0, "so no skill scale")


func test_the_profile_scales_a_skill_s_blows_only() -> void:
	var plain := _run(_pair(), _length() + 10)
	var scaled := _run(_pair({"damage": 2.0, "hitstun": 1.0, "knockback": 1.0}), _length() + 10)
	for i in STAGES.size():
		assert_eq(scaled[i].damage, plain[i].damage * 2, STAGES[i] + ": damage doubled")
	var fighters := _pair({"damage": 2.0})
	var jab := FighterInput.new()
	jab.light = true
	var hits: Array[CombatEvent] = []
	for t in 12:
		hits.append_array(CombatRules.tick(fighters, {1: jab} if t == 0 else {}, _lib(), BOUNDS))
	assert_eq(hits[0].damage, plain[0].damage, "a basic jab is not scaled")


func test_the_zone_reports_each_stage_of_a_real_skill() -> void:
	var db := ContentDB.load_all()
	var skills := SkillRules.unlocked(db, "riku", 70)
	assert_eq(skills["power_jab"]["then"], [], "a one-move skill has no later stages")
	assert_eq(skills["knockout_combo"]["then"].size(), 3, "the Knockout Combo has three")
	var profile := PlayerProfile.new_game(db, "riku")
	profile.level = 40
	var zone := ZoneSim.new(db, profile, "depot_yard", "", 1)
	var steps := []
	var input := _press("knockout_combo")
	for t in 120:
		for event in zone.tick(input):
			if event.type == "swing" and event.data["id"] == zone.hero.id:
				steps.append([event.data["skill"], event.data["step"]])
		input = FighterInput.new()
	var expected := []
	for step in 4:
		expected.append(["knockout_combo", step])
	assert_eq(steps, expected, "all four stages reported")
