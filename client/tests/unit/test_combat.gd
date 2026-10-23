extends TestCase
## Rules of the combat core. These pin down the behaviour the zone server will
## enforce, so changes here are gameplay changes.

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


## Runs `ticks` ticks; `hero_input` is used on the first tick only unless
## `hold` is set. Returns every event.
func _run(
	fighters: Array[Fighter], ticks: int, hero_input: FighterInput = null, hold := false
) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	for i in ticks:
		var inputs := {}
		if hero_input and (hold or i == 0):
			inputs[1] = hero_input
		events.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	return events


func test_shipped_moves_are_valid() -> void:
	assert_true(_lib().is_valid(), "moves.json is valid: %s" % ", ".join(_lib().errors))
	assert_eq(_lib().starters.get("light"), "jab", "light starts with jab")


func test_invalid_content_is_reported() -> void:
	var bad := MoveLibrary.new()
	(
		bad
		. parse(
			{
				"starters": {"light": "jab", "heavy": "missing"},
				"moves":
				{
					"jab": {"startup": -1, "active": 0, "recovery": 2, "damage": 1, "hitstun": 1},
					"poke":
					{
						"startup": 1,
						"active": 1,
						"recovery": 1,
						"damage": 1,
						"hitstun": 1,
						"chains": {"light": "nowhere", "kick": "jab"},
					},
				},
			}
		)
	)
	var all := "\n".join(bad.errors)
	assert_true(all.contains("jab.startup"), "negative startup rejected")
	assert_true(all.contains("jab.active"), "zero active frames rejected")
	assert_true(all.contains("starters.heavy"), "unknown starter rejected")
	assert_true(all.contains("unknown move nowhere"), "dangling chain rejected")
	assert_true(all.contains("unknown input kick"), "unknown chain input rejected")


func test_jab_hits_on_its_first_active_tick() -> void:
	var fighters := _pair()
	var jab := _lib().get_move("jab")
	var events := _run(fighters, jab.startup, _press("light"))
	assert_eq(events.size(), 0, "nothing during startup")
	events = _run(fighters, 1)
	assert_eq(events.size(), 1, "hit on first active tick")
	assert_eq(fighters[1].hp, 100 - jab.damage, "damage applied")
	assert_eq(fighters[1].state, Fighter.State.HITSTUN, "defender in hitstun")


func test_one_swing_hits_a_target_once() -> void:
	var fighters := _pair()
	var events := _run(fighters, 30, _press("light"))
	assert_eq(events.size(), 1, "three active ticks, one hit")


func test_out_of_reach_or_other_lane_misses() -> void:
	var far := _pair(80)
	assert_eq(_run(far, 30, _press("light")).size(), 0, "too far along the street")
	var other_lane := _pair()
	other_lane[1].position.y += 20
	assert_eq(_run(other_lane, 30, _press("light")).size(), 0, "different depth")
	var behind := _pair(-30)
	assert_eq(_run(behind, 30, _press("light")).size(), 0, "behind the attacker")


func test_same_team_is_never_hit() -> void:
	var fighters := _pair()
	fighters[1].team = 1
	assert_eq(_run(fighters, 30, _press("light")).size(), 0, "no friendly fire")


func test_light_chain_requires_a_landed_hit() -> void:
	var whiff := _pair(200)
	_run(whiff, 5, _press("light"))
	_run(whiff, 1, _press("light"))
	_run(whiff, 20)
	var move_id: String = whiff[0].move.id if whiff[0].move else ""
	assert_true(move_id != "cross", "whiffed jab does not chain")

	var fighters := _pair()
	_run(fighters, 5, _press("light"))  # jab lands on tick 5
	_run(fighters, 1, _press("light"))  # buffered during the jab
	_run(fighters, 3)
	assert_eq(fighters[0].move.id, "cross", "jab chains into cross after a hit")


func test_full_combo_ends_in_knockdown() -> void:
	var fighters := _pair()
	var landed: Array[String] = []
	for i in 120:
		var input := _press("light") if i % 6 == 0 else null
		for event in _run(fighters, 1, input):
			landed.append(event.move_id)
	assert_eq(landed, ["jab", "cross", "body_hook"], "jab, cross, body hook")
	assert_eq(fighters[1].hp, 100 - 6 - 8 - 12, "combo damage")
	assert_true(
		fighters[1].state in [Fighter.State.DOWN, Fighter.State.IDLE], "finisher knocks down"
	)


func test_knockdown_is_invulnerable_then_recovers() -> void:
	var foe := Fighter.new(2, 2, Vector2(500, 300))
	foe.enter(Fighter.State.DOWN)
	assert_true(not CombatRules.is_vulnerable(foe), "cannot be hit while down")
	var fighters: Array[Fighter] = [foe]
	_run(fighters, CombatRules.KNOCKDOWN_TICKS)
	assert_eq(foe.state, Fighter.State.IDLE, "gets up after KNOCKDOWN_TICKS")


func test_knockback_pushes_away_from_attacker() -> void:
	var fighters := _pair()
	var start := fighters[1].position.x
	_run(fighters, 40, _press("heavy"))
	assert_true(fighters[1].position.x > start + 60, "haymaker pushes the foe back")


func test_dodge_iframes_avoid_hits() -> void:
	var fighters := _pair()
	fighters[1].facing = 1  # dodge away from the hero, along the street
	var jab := _lib().get_move("jab")
	# Foe starts dodging so that the jab's active ticks fall inside its i-frames.
	CombatRules.tick(fighters, {1: _press("light"), 2: _press("dodge")}, _lib(), BOUNDS)
	assert_eq(fighters[1].state, Fighter.State.DODGE, "foe is dodging")
	var events := _run(fighters, jab.total_ticks())
	assert_eq(events.size(), 0, "jab passes through the dodge")
	assert_eq(fighters[1].hp, 100, "no damage")


func test_dodge_costs_energy_and_needs_enough() -> void:
	var fighters := _pair(300)
	_run(fighters, 1, _press("dodge"))
	assert_eq(fighters[0].state, Fighter.State.DODGE, "dodge starts")
	assert_near(
		fighters[0].energy, CombatRules.MAX_ENERGY - CombatRules.DODGE_COST, "energy spent", 0.01
	)
	var tired := _pair(300)
	tired[0].energy = CombatRules.DODGE_COST - 1
	_run(tired, 1, _press("dodge"))
	assert_true(tired[0].state != Fighter.State.DODGE, "no dodge without energy")


func test_guard_reduces_damage_from_the_front() -> void:
	var fighters := _pair()
	var guard := FighterInput.new()
	guard.guard = true
	CombatRules.tick(fighters, {1: _press("light"), 2: guard}, _lib(), BOUNDS)
	var events: Array[CombatEvent] = []
	for i in 10:
		events.append_array(CombatRules.tick(fighters, {2: guard}, _lib(), BOUNDS))
	assert_eq(events.size(), 1, "one hit")
	assert_true(events[0].blocked, "blocked")
	assert_eq(fighters[1].hp, 99, "chip damage is 20%, at least 1")
	assert_eq(fighters[1].state, Fighter.State.GUARD, "still guarding")


func test_guard_does_not_cover_the_back() -> void:
	var fighters := _pair()
	fighters[1].facing = 1  # turned away from the hero
	var guard := FighterInput.new()
	guard.guard = true
	CombatRules.tick(fighters, {1: _press("light"), 2: guard}, _lib(), BOUNDS)
	var events: Array[CombatEvent] = []
	for i in 10:
		events.append_array(CombatRules.tick(fighters, {2: guard}, _lib(), BOUNDS))
	assert_true(not events[0].blocked, "hit from behind is not blocked")


func test_guard_break_move_ignores_guard() -> void:
	var fighters := _pair()
	var guard := FighterInput.new()
	guard.guard = true
	CombatRules.tick(fighters, {1: _press("heavy"), 2: guard}, _lib(), BOUNDS)
	var events: Array[CombatEvent] = []
	for i in 20:
		events.append_array(CombatRules.tick(fighters, {2: guard}, _lib(), BOUNDS))
	assert_true(not events[0].blocked, "haymaker breaks through")
	assert_eq(fighters[1].hp, 100 - _lib().get_move("haymaker").damage, "full damage")


func test_empty_energy_breaks_guard() -> void:
	var fighters := _pair()
	fighters[1].energy = 1.0
	var guard := FighterInput.new()
	guard.guard = true
	CombatRules.tick(fighters, {1: _press("light"), 2: guard}, _lib(), BOUNDS)
	var events: Array[CombatEvent] = []
	for i in 10:
		events.append_array(CombatRules.tick(fighters, {2: guard}, _lib(), BOUNDS))
	assert_true(events[0].guard_broken, "guard broken")
	assert_eq(fighters[1].state, Fighter.State.HITSTUN, "stunned after the break")


func test_heavy_needs_energy() -> void:
	var fighters := _pair()
	fighters[0].energy = 5.0
	_run(fighters, 1, _press("heavy"))
	assert_true(fighters[0].state != Fighter.State.ATTACK, "no haymaker without energy")


func test_ko_at_zero_hp_and_no_further_hits() -> void:
	var fighters := _pair()
	fighters[1].hp = 3
	var events := _run(fighters, 30, _press("light"))
	assert_true(events[0].ko, "KO reported")
	assert_eq(fighters[1].state, Fighter.State.KO, "foe is KO")
	assert_eq(fighters[1].hp, 0, "hp floors at zero")
	assert_eq(_run(fighters, 30, _press("light")).size(), 0, "KO fighters cannot be hit")


func test_simultaneous_hits_trade() -> void:
	var fighters := _pair()
	CombatRules.tick(fighters, {1: _press("light"), 2: _press("light")}, _lib(), BOUNDS)
	var events := _run(fighters, 10)
	assert_eq(events.size(), 2, "both jabs land")
	assert_eq(fighters[0].hp, fighters[1].hp, "equal damage regardless of array order")


func test_same_inputs_give_same_result() -> void:
	var a := _pair()
	var b := _pair()
	var script := ["light", "", "light", "", "", "heavy", "dodge", "", "light"]
	for i in 90:
		var button: String = script[i % script.size()]
		var input := _press(button) if button else FighterInput.new()
		CombatRules.tick(a, {1: input}, _lib(), BOUNDS)
		CombatRules.tick(b, {1: input}, _lib(), BOUNDS)
	for i in 2:
		assert_eq(a[i].position, b[i].position, "position is deterministic")
		assert_eq(a[i].hp, b[i].hp, "hp is deterministic")
		assert_eq(a[i].state, b[i].state, "state is deterministic")
