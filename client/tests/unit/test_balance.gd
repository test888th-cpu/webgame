extends TestCase
## Balance rules between the five jobs, so tuning numbers later cannot
## quietly break them. A skill's "total" is the damage of all its blows on one
## target (its moves, and its throw if it grabs), before power and defense.

## A skill waits on a cooldown, so one that strikes must at least match the
## heavy attack, which has none; and each job's strongest must clearly beat it.
const STRONGEST_OVER_HEAVY := 2.0
## An ultimate against the job's strongest active skill, on one target.
const ULTIMATE_MIN := 2.0
const ULTIMATE_MAX := 3.0

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Every blow of `skill_id` on one target: its moves, a grab's throw and
## what a crushing hold squeezes out.
func _total(skill_id: String) -> float:
	var skill: Dictionary = _content().skills[skill_id]
	var sum := 0.0
	for move_id: String in SkillSequence.moves(skill):
		sum += _content().moves.get_move(move_id).damage
	var plan: Dictionary = skill.get("grab", {})
	if plan.has("throw"):
		sum += _content().moves.get_move(str(plan["throw"])).damage
	if plan.has("squeeze"):
		var squeezes := (int(plan["hold"]) - 1) / int(plan["every"])
		sum += squeezes * _content().moves.get_move(str(plan["squeeze"])).damage
	return sum


func _strongest_active(hero_id: String) -> float:
	var best := 0.0
	for skill_id in SkillRules.actives(_content(), hero_id):
		best = maxf(best, _total(skill_id))
	return best


func _ultimate(hero_id: String) -> float:
	return _total(SkillRules.ultimate(_content(), hero_id))


func test_skills_that_strike_are_worth_their_cooldown() -> void:
	var heavy: int = _content().moves.get_move("haymaker").damage
	for hero_id: String in _content().hero_order:
		for skill_id in SkillRules.actives(_content(), hero_id):
			var total := _total(skill_id)
			assert_true(
				total == 0.0 or total >= heavy, "%s hits at least as hard as the heavy" % skill_id
			)
		assert_true(
			_strongest_active(hero_id) >= heavy * STRONGEST_OVER_HEAVY,
			"%s's strongest skill clearly beats the heavy attack" % hero_id
		)


func test_an_ultimate_is_two_to_three_times_the_strongest_skill() -> void:
	for hero_id: String in _content().hero_order:
		var ratio := _ultimate(hero_id) / _strongest_active(hero_id)
		assert_true(
			ratio >= ULTIMATE_MIN and ratio <= ULTIMATE_MAX,
			"%s's ultimate is %.2f times its strongest skill" % [hero_id, ratio]
		)


func test_the_boxer_hits_one_target_hardest() -> void:
	for hero_id: String in _content().hero_order:
		if hero_id == "riku":
			continue
		assert_true(_ultimate("riku") >= _ultimate(hero_id), "no ultimate out-hits the Boxer's")
	assert_true(_ultimate("kan") < _ultimate("riku"), "least of all the Brawler's, on one target")


func test_the_brawler_reaches_the_most_street() -> void:
	var widest := ""
	var most := 0
	for hero_id: String in _content().hero_order:
		var wide := 0
		for skill_id: String in SkillRules.kit(_content(), hero_id):
			for move_id in SkillSequence.moves(_content().skills[skill_id]):
				var move := _content().moves.get_move(move_id)
				wide += 1 if move.reach_offset < 0.0 and move.damage > 0 else 0
		if wide > most:
			most = wide
			widest = hero_id
	assert_eq(widest, "kan", "the Brawler has the most blows that hit all around")


func test_the_striker_is_quickest_and_hits_lightest() -> void:
	var first := {}
	for hero_id: String in _content().hero_order:
		var skill: Dictionary = _content().skills[SkillRules.actives(_content(), hero_id)[0]]
		first[hero_id] = int(skill["cooldown"])
	for hero_id: String in first:
		assert_true(first["mika"] <= first[hero_id], "the Striker's opener comes back soonest")
	var hits := 0
	for move_id in SkillSequence.moves(_content().skills["million_fist_onslaught"]):
		hits += 1 if _content().moves.get_move(move_id).damage > 0 else 0
	for hero_id: String in _content().hero_order:
		var other := 0
		var ultimate: Dictionary = _content().skills[SkillRules.ultimate(_content(), hero_id)]
		for move_id in SkillSequence.moves(ultimate):
			other += 1 if _content().moves.get_move(move_id).damage > 0 else 0
		assert_true(hits >= other, "no ultimate lands more blows than the Striker's")


func test_counters_never_strike_unprovoked() -> void:
	var stances := 0
	for skill_id: String in SkillRules.kit(_content(), "dao"):
		var skill: Dictionary = _content().skills[skill_id]
		var move := _content().moves.get_move(str(skill.get("move", "")))
		stances += 1 if move != null and move.counter else 0
	assert_true(stances >= 4, "the Counter Fighter's kit is built on stances (%d)" % stances)
	var ultimate := _content().moves.get_move(
		str(_content().skills["absolute_retribution"]["move"])
	)
	assert_true(ultimate.counter and ultimate.damage == 0, "its ultimate is one too")


func test_the_grappler_s_skills_are_grabs() -> void:
	var grabs := 0
	for skill_id in SkillRules.actives(_content(), "oren"):
		var move := _content().moves.get_move(str(_content().skills[skill_id]["move"]))
		grabs += 1 if move.grab else 0
	assert_eq(grabs, 6, "every active skill of the Grappler opens with a grab")
	for hero_id: String in ["riku", "kan", "dao", "mika"]:
		for skill_id in SkillRules.actives(_content(), hero_id):
			var move := _content().moves.get_move(str(_content().skills[skill_id]["move"]))
			assert_true(not move.grab, "%s is not a grab" % skill_id)


func test_each_hero_trades_one_strength_for_another() -> void:
	var mika: Dictionary = _content().hero("mika")["stats"]
	var oren: Dictionary = _content().hero("oren")["stats"]
	assert_true(
		mika["power"] > oren["power"] and mika["speed"] > oren["speed"], "Mika: damage, speed"
	)
	assert_true(
		oren["max_hp"] > mika["max_hp"] and oren["defense"] > mika["defense"],
		"Oren: health, defense"
	)
