extends TestCase
## Counter stances (CounterRules): a blow caught from the front starts the
## skill's reply; a stance nobody hits does nothing; guard breakers, blows
## from behind and grabs beat it.

const BOUNDS := Rect2(0, 200, 2000, 200)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _lib() -> MoveLibrary:
	return _content().moves


## A hero who knows a counter (stance, then a cross and a hook) and a foe in
## front whose light attack is `foe_move`.
func _pair(foe_move := "thug_jab") -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.skills = {
		"riposte": {"move": "counter_stance", "cooldown": 600, "then": ["cross", "body_hook"]}
	}
	var foe := Fighter.new(2, 2, Vector2(526, 300), 500)
	foe.facing = -1
	foe.moveset = {"light": foe_move}
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


func _input(field: String, value: Variant = true) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, value)
	return input


## The hero takes the stance on tick 0 and the foe attacks on `foe_tick`
## (never if negative). Returns every hit over `ticks` ticks.
func _run(fighters: Array[Fighter], ticks: int, foe_tick := 0) -> Array[CombatEvent]:
	var hits: Array[CombatEvent] = []
	for t in ticks:
		var inputs := {}
		if t == 0:
			inputs[1] = _input("skill", "riposte")
		if t == foe_tick:
			inputs[2] = _input("light")
		hits.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	return hits


func test_a_caught_blow_starts_the_reply() -> void:
	var fighters := _pair()
	var hp := fighters[0].hp
	var hits := _run(fighters, 70)
	assert_true(hits[0].countered and hits[0].parried, "the jab is caught")
	assert_eq(hits[0].damage, 0, "and does nothing")
	assert_eq(fighters[0].hp, hp, "the hero is unhurt")
	var reply := []
	for hit in hits.slice(1):
		if hit.attacker_id == 1:
			reply.append(hit.move_id)
	assert_eq(reply, ["cross", "body_hook"], "the whole reply lands")
	assert_true(hits[1].counter, "its first blow is a counter hit on the reeling foe")
	var plain := CombatRules.damage_for(_lib().get_move("cross"), fighters[0], fighters[1])
	assert_eq(hits[1].damage, roundi(plain * CombatRules.COUNTER_DAMAGE), "for counter damage")


func test_a_stance_nobody_hits_deals_nothing_and_leaves_an_opening() -> void:
	var fighters := _pair()
	var stance := _lib().get_move("counter_stance")
	var hits := _run(fighters, stance.total_ticks() + 30, -1)
	assert_eq(hits.size(), 0, "no blow comes out unprovoked")
	assert_eq(fighters[0].state, Fighter.State.IDLE, "the skill is over")
	assert_true(fighters[0].cooldown_left("riposte") > 0, "and its cooldown is spent")
	var late := _pair()
	_run(late, stance.startup + stance.active + 2, -1)
	assert_true(not CounterRules.open(late[0]), "after the window the stance is shut")
	assert_eq(late[0].state, Fighter.State.ATTACK, "but the hero is still recovering")
	assert_true(CombatRules.is_vulnerable(late[0]), "and can be hit")


func test_a_blow_before_or_after_the_window_lands() -> void:
	var stance := _lib().get_move("counter_stance")
	var jab := _lib().get_move("thug_jab")
	var late := _pair()
	var hits := _run(late, 80, stance.startup + stance.active - jab.startup + 1)
	assert_true(not hits[0].countered, "a blow just after the window is not caught")
	assert_true(hits[0].damage > 0, "it hurts")
	assert_eq(hits.size(), 1, "and no reply follows")


func test_a_guard_breaker_goes_through_the_stance() -> void:
	var fighters := _pair("brute_slam")
	assert_true(_lib().get_move("brute_slam").guard_break, "the slam breaks guard")
	var hp := fighters[0].hp
	var hits := _run(fighters, 80)
	assert_true(not hits[0].countered, "the stance does not catch it")
	assert_true(fighters[0].hp < hp, "the hero is hurt")
	for hit in hits:
		assert_true(hit.attacker_id != 1, "and never replies")


func test_a_blow_from_behind_goes_through() -> void:
	var fighters := _pair()
	fighters[1].position.x = 474
	fighters[1].facing = 1
	var hits := _run(fighters, 60)
	assert_true(not hits[0].countered, "the stance faces one way only")
	assert_true(hits[0].damage > 0, "the back is open")


func test_a_grab_beats_the_stance() -> void:
	var fighters := _pair()
	fighters[1].grab = _content().jobs["brawler"]["grab"]
	fighters[1].position.x = 520
	for t in 14:
		var inputs := {}
		if t == 0:
			inputs[1] = _input("skill", "riposte")
			inputs[2] = _input("grab")
		CombatRules.tick(fighters, inputs, _lib(), BOUNDS)
	assert_eq(fighters[0].state, Fighter.State.HELD, "the hero is seized out of the stance")
	assert_eq(fighters[0].skill_id, "", "and the counter is over")


func test_a_boss_is_caught_but_does_not_reel() -> void:
	var fighters := _pair()
	fighters[1].unshaken = true
	var hits := _run(fighters, 70)
	assert_true(hits[0].countered, "the boss's blow is caught")
	assert_true(fighters[1].state != Fighter.State.HITSTUN, "the boss does not stagger")
	var replied := false
	for hit in hits:
		replied = replied or (hit.attacker_id == 1 and hit.counter)
	assert_true(replied, "the reply still lands as a counter hit")


func test_catching_a_blow_counts_as_a_parry_for_passives() -> void:
	var fighters := _pair()
	fighters[0].passives = {"retaliation": {"gain": "parry", "max": 3, "effects": {"damage": 0.1}}}
	_run(fighters, 12)
	assert_eq(PassiveRules.stacks_of(fighters[0], "retaliation"), 1, "a caught blow is a parry")


func test_only_a_first_move_may_be_a_stance() -> void:
	var lib := _lib()
	var good := {"move": "counter_stance", "then": ["cross"]}
	assert_eq(SkillSequence.problems(good, lib, "s"), PackedStringArray(), "stance, then a reply")
	var bare := ", ".join(SkillSequence.problems({"move": "counter_stance"}, lib, "s"))
	assert_true("needs a reply" in bare, "a stance alone is refused: " + bare)
	var late := {"move": "jab", "then": ["counter_stance"]}
	var found := ", ".join(SkillSequence.problems(late, lib, "s"))
	assert_true("only the first move may be" in found, "a stance in the middle is refused")
	assert_true(_content().is_valid(), "the game's own data passes")
