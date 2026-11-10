extends TestCase
## Passive skills (PassiveRules): stacks earned by landing blows or parrying,
## lost by missing or by time, and what they add to damage, critical chance
## and attack speed.

const BOUNDS := Rect2(0, 200, 2000, 200)

var library: MoveLibrary


func _lib() -> MoveLibrary:
	if library == null:
		library = MoveLibrary.load_file()
	return library


func _pair(passives: Dictionary, gap := 24.0) -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.passives = passives
	var foe := Fighter.new(2, 2, Vector2(500 + gap, 300), 1000)
	foe.facing = -1
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


## One jab from the hero, played to its end. Returns its hit (or null).
func _jab(fighters: Array[Fighter]) -> CombatEvent:
	var press := FighterInput.new()
	press.light = true
	var found: CombatEvent = null
	for t in _lib().get_move("jab").total_ticks() + 1:
		for hit in CombatRules.tick(fighters, {1: press} if t == 0 else {}, _lib(), BOUNDS):
			found = hit
	return found


func test_stacks_build_on_hits_up_to_the_cap() -> void:
	var spec := {"gain": "hit", "reset": "miss", "max": 3, "effects": {"damage": 0.5}}
	var fighters := _pair({"focus": spec})
	var first := _jab(fighters)
	assert_eq(PassiveRules.stacks_of(fighters[0], "focus"), 1, "one stack after one hit")
	var second := _jab(fighters)
	assert_eq(second.damage, roundi(first.damage * 1.5), "the next blow hits half as hard again")
	_jab(fighters)
	_jab(fighters)
	assert_eq(PassiveRules.stacks_of(fighters[0], "focus"), 3, "capped at three")


func test_a_miss_drops_the_stacks() -> void:
	var spec := {"gain": "hit", "reset": "miss", "max": 5, "effects": {"crit": 0.1}}
	var fighters := _pair({"focus": spec})
	_jab(fighters)
	_jab(fighters)
	assert_near(PassiveRules.bonus(fighters[0], "crit"), 0.2, "two stacks of crit")
	fighters[1].position.x = 900
	assert_eq(_jab(fighters), null, "a jab at thin air")
	assert_eq(PassiveRules.stacks_of(fighters[0], "focus"), 0, "loses them all")


func test_timed_stacks_run_out() -> void:
	var spec := {"gain": "hit", "max": 3, "duration": 60, "effects": {"attack_speed": 0.2}}
	var fighters := _pair({"flow": spec})
	var jab := _lib().get_move("jab")
	assert_eq(CombatRules.recovery_cut(fighters[0], jab), 0, "no flow, no speed")
	_jab(fighters)
	assert_true(CombatRules.recovery_cut(fighters[0], jab) > 0, "flow shortens the recovery")
	for t in 70:
		CombatRules.tick(fighters, {}, _lib(), BOUNDS)
	assert_eq(PassiveRules.stacks_of(fighters[0], "flow"), 0, "gone after a second without a hit")


func test_a_finisher_passive_boosts_only_the_last_blow() -> void:
	var spec := {"always": true, "when": "finisher", "effects": {"damage": 1.0}}
	var plain := _pair({})
	var keen := _pair({"impact": spec})
	assert_eq(_jab(keen).damage, _jab(plain).damage, "a jab (more punches follow) is unchanged")
	var hook := _lib().get_move("body_hook")
	assert_eq(
		CombatRules.damage_for(hook, keen[0], keen[1]),
		2 * CombatRules.damage_for(hook, plain[0], plain[1]),
		"the combination's last blow is doubled"
	)


func test_parry_stacks_are_spent_by_the_counter() -> void:
	var spec := {
		"gain": "parry", "max": 2, "when": "counter", "consume": true, "effects": {"damage": 1.0}
	}
	var fighters := _pair({"retaliation": spec})
	var hero := fighters[0]
	var foe := fighters[1]
	PassiveRules.on_event(hero, "parry")
	assert_eq(PassiveRules.stacks_of(hero, "retaliation"), 1, "a parry banks a stack")
	var jab := _lib().get_move("jab")
	var plain := CombatRules.damage_for(jab, hero, foe)
	assert_eq(plain, CombatRules.damage_for(jab, _pair({})[0], foe), "no bonus on a ready foe")
	foe.exposed = 30
	var hit := _jab(fighters)
	assert_eq(hit.damage, roundi(plain * 2 * CombatRules.COUNTER_DAMAGE), "the counter is boosted")
	assert_eq(PassiveRules.stacks_of(hero, "retaliation"), 0, "and the stack is spent")


func test_a_real_parry_earns_the_stack() -> void:
	var spec := {"gain": "parry", "max": 2, "effects": {"damage": 0.5}}
	var fighters := _pair({"retaliation": spec})
	var hero := fighters[0]
	hero.can_parry = true
	hero.parry_open = true
	var foe := fighters[1]
	var press := FighterInput.new()
	press.light = true
	var guard := FighterInput.new()
	guard.guard = true
	var startup := _lib().get_move("jab").startup
	var parried := false
	for t in startup + 3:
		var inputs := {}
		if t == 0:
			inputs[2] = press
		if t >= startup - 3:
			inputs[1] = guard
		for hit in CombatRules.tick(fighters, inputs, _lib(), BOUNDS):
			parried = parried or hit.parried
	assert_true(parried, "the jab is parried")
	assert_eq(PassiveRules.stacks_of(hero, "retaliation"), 1, "and a stack is earned")
	assert_eq(PassiveRules.stacks_of(foe, "retaliation"), 0, "enemies have no passives")


func test_passives_unlock_by_level_and_never_reach_the_hotbar() -> void:
	var db := ContentDB.load_all()
	var skill: Dictionary = db.skills["liver_shot"].duplicate(true)
	skill.erase("move")
	skill["type"] = "passive"
	skill["unlock_level"] = 15
	skill["passive"] = {"gain": "hit", "reset": "miss", "max": 5, "effects": {"crit": 0.02}}
	db.skills["liver_shot"] = skill
	assert_eq(SkillRules.passives(db, "riku", 14), {}, "locked below level 15")
	assert_true(SkillRules.passives(db, "riku", 15).has("liver_shot"), "open at 15")
	assert_true(not SkillRules.unlocked(db, "riku", 70).has("liver_shot"), "never a usable skill")
	var profile := PlayerProfile.new_game(db, "riku")
	assert_true(not HotbarRules.allowed(profile, db, "skill:liver_shot"), "nor on the hotbar")
	profile.level = 15
	var zone := ZoneSim.new(db, profile, "depot_yard", "", 1)
	assert_true(zone.hero.passives.has("liver_shot"), "the zone gives the hero the passive")


func test_bad_passive_data_is_refused() -> void:
	var good := {"gain": "hit", "max": 3, "effects": {"damage": 0.1}}
	assert_eq(PassiveRules.problems(good, "p"), PackedStringArray(), "a plain passive")
	var always := {"always": true, "effects": {"crit": 0.05}}
	assert_eq(PassiveRules.problems(always, "p"), PackedStringArray(), "a standing one")
	var bad := {"gain": "dance", "max": 0, "when": "never", "effects": {"luck": 1}}
	var found := ", ".join(PassiveRules.problems(bad, "p"))
	for part: String in ["unknown effect luck", "p.when", "p.gain", "p.max"]:
		assert_true(part in found, "%s is reported: %s" % [part, found])
	assert_true(".effects" in ", ".join(PassiveRules.problems({"always": true}, "p")), "no effect")
