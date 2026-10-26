extends TestCase
## Stun-lock protection: a hero hit again and again is knocked down instead
## of being held helpless, then gets up with a short grace.

const BOUNDS := Rect2(0, 200, 2000, 200)

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


func _pair(gap := 30.0) -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	var foe := Fighter.new(2, 2, Vector2(500 + gap, 300), 100)
	foe.facing = -1
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


func _press(button: String) -> FighterInput:
	var input := FighterInput.new()
	input.set(button, true)
	return input


func _run(fighters: Array[Fighter], ticks: int, hero_input: FighterInput = null) -> void:
	for i in ticks:
		var inputs := {}
		if hero_input and i == 0:
			inputs[1] = hero_input
		CombatRules.tick(fighters, inputs, _lib(), BOUNDS)


## Longest run of ticks the hero spends in hitstun or down while the foe
## jabs whenever it can, and whether a jab (never a knockdown) floored them.
func _jabbed(stun_limit: int) -> Array:
	var fighters := _pair(28.0)
	var hero := fighters[0]
	var foe := fighters[1]
	hero.stun_limit = stun_limit
	hero.max_hp = 100000
	hero.hp = 100000
	foe.moveset = {"light": "thug_jab"}
	var worst := 0
	var run := 0
	var floored := false
	for i in 600:
		var inputs := {}
		if foe.state == Fighter.State.IDLE:
			inputs[2] = _press("light")
		CombatRules.tick(fighters, inputs, _lib(), BOUNDS)
		hero.position.x = 500.0  # stay in reach despite knockback
		foe.position.x = 528.0
		floored = floored or hero.state == Fighter.State.DOWN
		var helpless := hero.state in [Fighter.State.HITSTUN, Fighter.State.DOWN]
		run = run + 1 if helpless else 0
		worst = maxi(worst, run)
	return [worst, floored]


func test_stun_lock_protection_knocks_down_instead_of_holding() -> void:
	var unprotected := _jabbed(0)
	assert_true(not unprotected[1], "jabs alone never floor an unprotected fighter")
	var protected := _jabbed(CombatRules.HERO_STUN_LIMIT)
	assert_true(protected[1], "past the stun limit the next jab knocks down")
	var cap := CombatRules.HERO_STUN_LIMIT + CombatRules.KNOCKDOWN_TICKS + 1
	assert_true(protected[0] <= cap, "helpless for %d ticks (cap %d)" % [protected[0], cap])


func test_getting_up_grants_grace_until_attacking() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	hero.stun_limit = CombatRules.HERO_STUN_LIMIT
	hero.enter(Fighter.State.DOWN)
	_run(fighters, CombatRules.KNOCKDOWN_TICKS)
	assert_eq(hero.state, Fighter.State.IDLE, "back up")
	assert_eq(hero.grace, CombatRules.WAKE_GRACE_TICKS, "grace after getting up")
	assert_true(not CombatRules.is_vulnerable(hero), "untouchable during grace")
	_run(fighters, 1, _press("light"))
	assert_eq(hero.grace, 0, "attacking ends the grace")
	assert_true(CombatRules.is_vulnerable(hero), "hittable again")


func test_enemies_have_no_stun_protection() -> void:
	var fighters := _pair()
	var foe := fighters[1]
	foe.enter(Fighter.State.DOWN)
	_run(fighters, CombatRules.KNOCKDOWN_TICKS)
	assert_eq(foe.grace, 0, "no grace for fighters without a stun limit")
