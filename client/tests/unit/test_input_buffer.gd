extends TestCase
## The input buffer: a button pressed shortly before an attack ends starts
## right after it, instead of being lost (missed swings felt unresponsive).

const BOUNDS := Rect2(0, 200, 2000, 200)

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


## A hero with nothing in reach, so every swing misses.
func _alone() -> Array[Fighter]:
	var fighters: Array[Fighter] = [Fighter.new(1, 1, Vector2(500, 300), 100)]
	return fighters


func _tick(fighters: Array[Fighter], button := "") -> void:
	var input := FighterInput.new()
	if button:
		input.set(button, true)
	CombatRules.tick(fighters, {1: input}, _lib(), BOUNDS)


func test_a_late_press_starts_right_after_a_missed_swing() -> void:
	var fighters := _alone()
	var jab := _lib().get_move("jab")
	_tick(fighters, "light")
	for i in jab.total_ticks() - 5:
		_tick(fighters)
	_tick(fighters, "heavy")
	for i in 4:
		_tick(fighters)
	assert_eq(fighters[0].move.id if fighters[0].move else "", "haymaker", "the heavy came out")


func test_an_early_press_is_not_kept() -> void:
	var fighters := _alone()
	var jab := _lib().get_move("jab")
	_tick(fighters, "light")
	_tick(fighters, "light")
	for i in jab.total_ticks():
		_tick(fighters)
	assert_eq(fighters[0].state, Fighter.State.IDLE, "a press long before the end is dropped")


func test_a_buffered_skill_comes_out_after_a_miss() -> void:
	var content := ContentDB.load_all()
	var fighters := _alone()
	fighters[0].skills = SkillRules.unlocked(content, "mika", 1)
	var jab := _lib().get_move("jab")
	_tick(fighters, "light")
	for i in jab.total_ticks() - 3:
		_tick(fighters)
	var input := FighterInput.new()
	input.skill = "whirlwind_kick"
	CombatRules.tick(fighters, {1: input}, content.moves, BOUNDS)
	for i in 3:
		_tick(fighters)
	assert_eq(fighters[0].move.id if fighters[0].move else "", "whirlwind_kick", "skill buffered")
