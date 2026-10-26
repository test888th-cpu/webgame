extends TestCase
## Poise: elites and bosses cannot be pinned by mashing. Enough hitstun
## turns into a spell of armor (blows still hurt, but do not interrupt), and
## a telegraphed wind-up cannot be jabbed out of. A parry still staggers.

const BOUNDS := Rect2(0, 200, 2000, 200)

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


## Hero (id 1) facing an elite (id 2, poise 60) 26 px away.
func _pair(poise := 60) -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.can_parry = true
	var elite := Fighter.new(2, 2, Vector2(526, 300), 100000)
	elite.facing = -1
	elite.poise_limit = poise
	elite.moveset = {"light": "warden_rake", "heavy": "warden_crush"}
	var fighters: Array[Fighter] = [hero, elite]
	return fighters


func _input(button := "") -> FighterInput:
	var input := FighterInput.new()
	if button:
		input.set(button, true)
	return input


## The hero jabs whenever free for `ticks`; returns the hits on the elite.
func _mash(fighters: Array[Fighter], ticks: int, elite_input := {}) -> Array[CombatEvent]:
	var hits: Array[CombatEvent] = []
	for t in ticks:
		var inputs := elite_input.duplicate() if t == 0 else {}
		if fighters[0].state == Fighter.State.IDLE:
			inputs[1] = _input("light")
		hits.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
		fighters[0].position.x = 500.0
		fighters[1].position.x = 526.0
	return hits.filter(func(h: CombatEvent) -> bool: return h.defender_id == 2)


func test_mashing_breaks_into_armor_not_a_lock() -> void:
	var fighters := _pair()
	var hits := _mash(fighters, 240)
	assert_true(hits.any(func(h: CombatEvent) -> bool: return h.armored), "poise broke into armor")
	var armored := hits.filter(func(h: CombatEvent) -> bool: return h.armored)
	assert_true(armored.all(func(h: CombatEvent) -> bool: return h.damage > 0), "armor still hurts")


func test_armor_wears_off() -> void:
	var fighters := _pair()
	fighters[1].armor = CombatRules.ARMOR_TICKS
	for i in CombatRules.ARMOR_TICKS:
		CombatRules.tick(fighters, {}, _lib(), BOUNDS)
	assert_eq(fighters[1].armor, 0, "gone after its time")


func test_a_telegraphed_wind_up_cannot_be_jabbed_out_of() -> void:
	var fighters := _pair()
	var crush := _lib().get_move("warden_crush")
	var hits := _mash(fighters, crush.startup, {2: _input("heavy")})
	assert_true(not hits.is_empty(), "the hero landed jabs during the wind-up")
	assert_eq(fighters[1].state, Fighter.State.ATTACK, "still winding up")
	assert_eq(fighters[1].move.id, "warden_crush", "the crush is coming")


func test_without_poise_a_wind_up_is_interrupted() -> void:
	var fighters := _pair(0)
	var crush := _lib().get_move("warden_crush")
	_mash(fighters, crush.startup, {2: _input("heavy")})
	assert_true(
		fighters[1].state != Fighter.State.ATTACK or fighters[1].move.id != "warden_crush",
		"an ordinary enemy is knocked out of it"
	)


func test_a_parry_still_staggers_an_armored_attacker() -> void:
	var fighters := _pair()
	fighters[1].armor = CombatRules.ARMOR_TICKS
	var rake := _lib().get_move("warden_rake")
	var events: Array[CombatEvent] = []
	for t in rake.startup + 4:
		var inputs := {}
		if t == 0:
			inputs[2] = _input("light")
		if t >= rake.startup - 3:
			inputs[1] = _input("guard")
		events.append_array(CombatRules.tick(fighters, inputs, _lib(), BOUNDS))
	assert_true(events.any(func(e: CombatEvent) -> bool: return e.parried), "parried")
	assert_eq(fighters[1].state, Fighter.State.HITSTUN, "staggered despite the armor")


func test_elites_and_bosses_have_poise_and_heroes_do_not() -> void:
	var content := ContentDB.load_all()
	for enemy_id: String in content.enemies:
		var enemy: Dictionary = content.enemies[enemy_id]
		if enemy.get("elite", false) or enemy.get("boss", false):
			assert_true(int(enemy.get("poise", 0)) > 0, "%s has poise" % enemy_id)
	var zone := ZoneSim.new(content, PlayerProfile.new_game(content), "depot_yard", "", 1)
	assert_eq(zone.hero.poise_limit, 0, "the hero flinches; stun protection covers them")
