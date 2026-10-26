extends TestCase
## Perfect guard and counters: a guard raised just before a hit parries it,
## the attacker reels, and the next hit on them deals extra damage.

const BOUNDS := Rect2(0, 200, 2000, 200)

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


## Hero (id 1, can parry) at x 500 facing the foe (id 2) at x 528.
func _pair() -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.can_parry = true
	var foe := Fighter.new(2, 2, Vector2(528, 300), 100)
	foe.facing = -1
	foe.moveset = {"light": "thug_jab", "heavy": "brute_slam"}
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


func _input(button := "") -> FighterInput:
	var input := FighterInput.new()
	if button:
		input.set(button, true)
	return input


## The foe presses `button` on tick 0; the hero holds guard from tick
## `guard_at` (-1: never). Returns the events until the swing is over.
func _swing(fighters: Array[Fighter], button: String, guard_at: int) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	for i in 70:
		var inputs := {}
		if i == 0:
			inputs[2] = _input(button)
		if guard_at >= 0 and i >= guard_at:
			inputs[1] = _input("guard")
		events.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	return events


## Tick on which `move_id` first hits (startup + 1, as tick 0 starts it).
func _hit_tick(move_id: String) -> int:
	return _lib().get_move(move_id).startup


func test_guard_raised_just_in_time_parries() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	var foe := fighters[1]
	hero.energy = 50.0
	var events := _swing(fighters, "light", _hit_tick("thug_jab") - 3)
	assert_eq(events.size(), 1, "one hit")
	assert_true(events[0].parried, "parried")
	assert_eq(events[0].damage, 0, "no damage")
	assert_eq(hero.hp, 100, "hero unharmed")
	assert_true(hero.energy > 50.0, "parry refunds energy")
	assert_true(foe.exposed > 0 or foe.state != Fighter.State.ATTACK, "foe reels")


func test_parry_beats_a_guard_breaker() -> void:
	var fighters := _pair()
	var events := _swing(fighters, "heavy", _hit_tick("brute_slam") - 2)
	assert_true(events[0].parried, "even a guard-breaking slam is parried")
	assert_eq(fighters[0].state, Fighter.State.GUARD, "hero still guarding")


func test_early_guard_only_blocks() -> void:
	var fighters := _pair()
	for i in CombatRules.PERFECT_GUARD_TICKS + 1:
		CombatRules.tick(fighters, {1: _input("guard")}, _lib(), BOUNDS)
	var events := _swing(fighters, "light", 0)
	assert_true(events[0].blocked, "blocked")
	assert_true(not events[0].parried, "too early to parry")
	assert_true(events[0].damage > 0, "chip damage")


func test_tapping_guard_does_not_keep_the_window_open() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	CombatRules.tick(fighters, {1: _input("guard")}, _lib(), BOUNDS)
	CombatRules.tick(fighters, {}, _lib(), BOUNDS)  # let go
	assert_true(hero.parry_lockout > 0, "letting go starts the lockout")
	CombatRules.tick(fighters, {1: _input("guard")}, _lib(), BOUNDS)
	assert_true(not hero.parry_open, "a re-raised guard cannot parry during lockout")


func test_enemies_never_parry() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	var foe := fighters[1]
	foe.enter(Fighter.State.GUARD)
	hero.facing = 1
	var events: Array[CombatEvent] = []
	for i in 30:
		var inputs := {1: _input("light")} if i == 0 else {}
		inputs[2] = _input("guard")
		events.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	assert_true(events[0].blocked and not events[0].parried, "enemy guard only blocks")


func test_counter_hit_deals_extra_damage() -> void:
	var fighters := _pair()
	var foe := fighters[1]
	var events := _swing(fighters, "light", _hit_tick("thug_jab") - 3)
	assert_true(events[0].parried, "parried first")
	# The swing helper ran past the reel; set up a fresh one to counter into.
	foe.enter(Fighter.State.HITSTUN, CombatRules.PARRY_STUN)
	foe.exposed = CombatRules.PARRY_STUN
	foe.position.x = 520.0
	var plain := CombatRules.damage_for(_lib().get_move("jab"), fighters[0], foe)
	var hits: Array[CombatEvent] = []
	for i in 12:
		var inputs := {1: _input("light")} if i == 0 else {}
		hits.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	assert_eq(hits.size(), 1, "the jab lands")
	assert_true(hits[0].counter, "counter hit")
	assert_eq(hits[0].damage, roundi(plain * CombatRules.COUNTER_DAMAGE), "counter damage")
	assert_eq(foe.exposed, 0, "only the first hit counts")
