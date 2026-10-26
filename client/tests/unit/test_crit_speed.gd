extends TestCase
## Critical hits and attack speed: crits come only from the seeded generator
## (same seed, same crits), multiply damage, and stay within their caps;
## attack speed shortens recovery but never the wind-up.

const BOUNDS := Rect2(0, 200, 2000, 200)

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


func _pair() -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	var foe := Fighter.new(2, 2, Vector2(525, 300), 100000)
	foe.facing = -1
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


## Jabs `times` times with `rng`; returns the hit events.
func _jabs(fighters: Array[Fighter], times: int, rng: RandomNumberGenerator) -> Array:
	var hits: Array = []
	for i in times:
		var input := FighterInput.new()
		input.light = true
		for t in 30:
			hits.append_array(
				CombatRules.tick(
					fighters, {1: input} if t == 0 else {}, _lib(), BOUNDS, Callable(), rng
				)
			)
		fighters[1].hp = fighters[1].max_hp
		fighters[1].enter(Fighter.State.IDLE)
		fighters[1].position.x = 525.0
	return hits


func test_crits_multiply_damage_and_replay_from_the_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var a := _pair()
	a[0].crit_chance = 0.5
	var first := _jabs(a, 40, rng)
	var crits := first.filter(func(e: CombatEvent) -> bool: return e.critical)
	var plain := CombatRules.damage_for(_lib().get_move("jab"), a[0], a[1])
	assert_true(crits.size() > 5 and crits.size() < 35, "about half crit (%d)" % crits.size())
	assert_eq(crits[0].damage, roundi(plain * CombatRules.CRIT_DAMAGE), "1.5x damage")
	var again := RandomNumberGenerator.new()
	again.seed = 9
	var b := _pair()
	b[0].crit_chance = 0.5
	var second := _jabs(b, 40, again)
	assert_eq(
		first.map(func(e: CombatEvent) -> bool: return e.critical),
		second.map(func(e: CombatEvent) -> bool: return e.critical),
		"same seed, same crits"
	)


func test_no_generator_or_no_chance_means_no_crits() -> void:
	var fighters := _pair()
	fighters[0].crit_chance = 1.0
	assert_true(
		_jabs(fighters, 5, null).all(func(e: CombatEvent) -> bool: return not e.critical),
		"no generator, no crits"
	)
	var rng := RandomNumberGenerator.new()
	var plain := _pair()
	assert_true(
		_jabs(plain, 5, rng).all(func(e: CombatEvent) -> bool: return not e.critical),
		"0% crit never crits"
	)


func test_attack_speed_cuts_recovery_not_startup() -> void:
	var jab := _lib().get_move("jab")
	var f := Fighter.new()
	f.attack_speed = 1.25
	assert_true(CombatRules.recovery_cut(f, jab) > 0, "faster recovery")
	assert_true(CombatRules.recovery_cut(f, jab) < jab.recovery, "never zero recovery")
	f.attack_speed = 1.0
	assert_eq(CombatRules.recovery_cut(f, jab), 0, "normal speed changes nothing")
	var fast := _pair()
	fast[0].attack_speed = 1.3
	var input := FighterInput.new()
	input.light = true
	CombatRules.tick(fast, {1: input}, _lib(), BOUNDS)
	var ticks := 1
	while fast[0].state == Fighter.State.ATTACK and ticks < 100:
		CombatRules.tick(fast, {}, _lib(), BOUNDS)
		ticks += 1
	assert_true(ticks < jab.total_ticks(), "a fast jab ends sooner (%d ticks)" % ticks)


func test_gear_moves_crit_and_speed_within_caps() -> void:
	var content := ContentDB.load_all()
	var profile := PlayerProfile.new_game(content, "mika")
	var base := profile.stats(content)
	assert_eq(float(base["crit"]), PlayerProfile.BASE_CRIT, "base crit")
	profile.add_item("brass_knuckles")
	profile.level = 10
	profile.equip("brass_knuckles", content)
	assert_true(profile.stats(content)["crit"] > base["crit"], "knuckles add crit")
	var tuned := profile.stats(content)
	assert_true(tuned["crit"] <= PlayerProfile.MAX_CRIT, "capped")
	assert_true(tuned["attack_speed"] <= PlayerProfile.ATTACK_SPEED_RANGE.y, "attack speed capped")
