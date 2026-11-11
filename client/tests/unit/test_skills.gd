extends TestCase
## Hero skills and consumable cooldowns. These are simulation rules (the zone
## server will enforce them), so a client can never fire a locked skill or
## skip a cooldown.

const BOUNDS := Rect2(0, 200, 2000, 200)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A hero with the skills of `level`, and a foe `gap` px in front (negative:
## behind).
func _pair(level := 70, gap := 24.0) -> Array[Fighter]:
	var hero := Fighter.new(1, 1, Vector2(500, 300), 100)
	hero.skills = SkillRules.unlocked(_content(), "mika", level)
	var foe := Fighter.new(2, 2, Vector2(500 + gap, 300), 200)
	foe.facing = -1 if gap > 0 else 1
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


func _skill(id: String) -> FighterInput:
	var input := FighterInput.new()
	input.skill = id
	return input


func _run(fighters: Array[Fighter], first: FighterInput, ticks: int) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	for i in ticks:
		var input := first if i == 0 else FighterInput.new()
		events.append_array(CombatRules.tick(fighters, {1: input}, _content().moves, BOUNDS))
	return events


func test_skills_unlock_by_level() -> void:
	var level_1 := SkillRules.unlocked(_content(), "mika", 1)
	assert_eq(level_1.keys(), ["quick_jab"], "one skill at Lv 1")
	assert_eq(
		SkillRules.unlocked_at(_content(), "mika", 2), ["triple_punch"] as Array[String], "Lv 2"
	)
	assert_eq(SkillRules.unlocked(_content(), "mika", 5).size(), 4, "four skills by Lv 5")
	assert_eq(SkillRules.unlocked(_content(), "mika", 30).size(), 6, "all six actives by Lv 30")
	assert_true(not SkillRules.unlocked(_content(), "mika", 49).has("million_fist_onslaught"), "49")
	assert_true(SkillRules.unlocked(_content(), "mika", 50).has("million_fist_onslaught"), "50")
	assert_eq(SkillRules.passives(_content(), "mika", 9).size(), 0, "no passive before Lv 10")
	assert_eq(SkillRules.passives(_content(), "mika", 25).size(), 2, "both passives by Lv 25")
	for hero_id: String in _content().hero_order:
		assert_eq(SkillRules.actives(_content(), hero_id).size(), 6, hero_id + ": six actives")
		assert_true(SkillRules.ultimate(_content(), hero_id) != "", hero_id + ": an ultimate")


func test_a_skill_costs_energy_hits_and_starts_its_cooldown() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	var events := _run(fighters, _skill("rising_fist"), 30)
	assert_eq(events.size(), 1, "the rising fist lands")
	assert_true(events[0].knocked_down, "and knocks down")
	assert_eq(events[0].move_id, "rising_fist", "with the skill's move")
	var cooldown := int(_content().skills["rising_fist"]["cooldown"])
	assert_eq(hero.cooldown_left("rising_fist"), cooldown - 29, "cooldown running")
	assert_true(hero.energy < CombatRules.MAX_ENERGY, "energy spent")


func test_a_skill_on_cooldown_does_nothing_until_it_is_ready() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	_run(fighters, _skill("rising_fist"), 40)
	_run(fighters, _skill("rising_fist"), 1)
	assert_eq(hero.state, Fighter.State.IDLE, "refused while cooling down")
	_run(fighters, FighterInput.new(), hero.cooldown_left("rising_fist"))
	assert_eq(hero.cooldown_left("rising_fist"), 0, "ready again")
	_run(fighters, _skill("rising_fist"), 1)
	assert_eq(hero.state, Fighter.State.ATTACK, "and usable")


func test_a_locked_skill_cannot_be_used_whatever_the_input_says() -> void:
	var fighters := _pair(1)
	_run(fighters, _skill("chain_breaker"), 1)
	assert_eq(fighters[0].state, Fighter.State.IDLE, "not unlocked at Lv 1")
	_run(fighters, _skill("no_such_skill"), 1)
	assert_eq(fighters[0].state, Fighter.State.IDLE, "unknown skills are ignored")


func test_not_enough_energy_refuses_the_skill_without_a_cooldown() -> void:
	var fighters := _pair()
	fighters[0].energy = 10.0
	_run(fighters, _skill("chain_breaker"), 1)
	assert_eq(fighters[0].state, Fighter.State.IDLE, "refused")
	assert_eq(fighters[0].cooldown_left("chain_breaker"), 0, "no cooldown spent")


func test_a_backhand_hits_behind_and_pushes_away() -> void:
	var fighters := _pair(70, -24.0)
	fighters[0].skills = SkillRules.unlocked(_content(), "kan", 70)
	var foe := fighters[1]
	var events := _run(fighters, _skill("backhand_smash"), 40)
	assert_eq(events.size(), 1, "the foe behind is hit")
	assert_true(foe.position.x < 476.0, "and pushed further away, not through the hero")


func test_a_dash_strike_carries_the_hero_forward() -> void:
	var fighters := _pair(70, 300.0)
	var hero := fighters[0]
	_run(fighters, _skill("dash_strike"), 40)
	var advance := _content().moves.get_move("dash_strike").advance
	assert_near(hero.position.x, 500.0 + advance, "moved by the lunge distance", 0.5)


func test_a_skill_cancels_a_landed_jab() -> void:
	var fighters := _pair()
	var hero := fighters[0]
	var jab := FighterInput.new()
	jab.light = true
	_run(fighters, jab, 2)
	_run(fighters, _skill("rising_fist"), 1)
	_run(fighters, FighterInput.new(), 6)
	assert_eq(hero.move.id if hero.move else "", "rising_fist", "cancelled into the skill")


func test_items_share_a_cooldown_in_the_zone() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.add_item("steamed_bun", 2)
	var zone := ZoneSim.new(_content(), profile, "depot_yard", "", 1)
	zone.hero.hp = 20
	assert_true(zone.use_item("steamed_bun"), "first bun")
	assert_true(not zone.use_item("steamed_bun"), "second refused during the cooldown")
	for i in _content().item_cooldown:
		zone.tick(FighterInput.new())
	assert_true(zone.use_item("steamed_bun"), "allowed again")


func test_zone_reports_skill_swings_and_unlocks_on_level_up() -> void:
	var profile := PlayerProfile.new_game(_content())
	var zone := ZoneSim.new(_content(), profile, "depot_yard", "", 1)
	var events := zone.tick(_skill("quick_jab"))
	var swing: Array[ZoneEvent] = []
	for event in events:
		if event.type == "swing":
			swing.append(event)
	assert_eq(swing.size(), 1, "one swing")
	assert_eq(swing[0].data["skill"], "quick_jab", "names the skill")
	for i in 60:
		zone.tick(FighterInput.new())
	profile.level = 1
	profile.xp = profile.xp_to_next(_content()) - 1
	var foe := zone.spawn_enemy("smogling", zone.hero.position + Vector2(20, 0))
	foe.hp = 1
	var jab := FighterInput.new()
	jab.light = true
	var level_events: Array[ZoneEvent] = []
	for i in 30:
		for event in zone.tick(jab if i == 0 else FighterInput.new()):
			if event.type == "level_up":
				level_events.append(event)
	assert_eq(level_events.size(), 1, "levelled up")
	assert_eq(level_events[0].data["skills"], ["triple_punch"] as Array[String], "Lv 2's skill")
	assert_true(zone.hero.skills.has("triple_punch"), "and usable right away")


func test_hotbar_content_is_validated() -> void:
	var db := ContentDB.load_all()
	assert_true(db.is_valid(), "shipped content is valid")
	db.hotbar[1] = {"type": "skill", "hero_skill": 9}
	db.skills["quick_jab"]["move"] = "nope"
	db.errors.clear()
	db.validate()
	assert_true(" ".join(db.errors).contains("hero_skill must be"), "bad hotbar slot reported")
	assert_true(" ".join(db.errors).contains("unknown move"), "unknown skill move reported")
