extends TestCase
## Skills used normally and combos that flow (owner's request, 2026-11-13):
## auto battle uses a grab skill like any other skill, does not stand over a
## foe it has just thrown while another can be hit, a counter reply reaches
## the attacker it caught, auto battle goes on into the longer route when
## its skills are ready and keeps a route's later skill for the route, and
## every job's routes can be chained by a player.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _zone(hero_id: String, level: int) -> ZoneSim:
	var profile := PlayerProfile.new_game(_content(), hero_id)
	profile.level = level
	var zone := ZoneSim.new(_content(), profile, "saltmarket", "west", 5)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.position = Vector2(600, 300)
	return zone


func _foe(zone: ZoneSim, kind: String, at: Vector2) -> Fighter:
	var foe := zone.spawn_enemy(kind, at)
	(zone.brains[foe.id] as EnemyBrain).cooldown = 100000
	return foe


func test_auto_grabs_a_lone_ordinary_foe_like_any_skill() -> void:
	# Power Throw opens no route at level 20. Before, auto used a grab on a
	# lone ordinary foe only to open a route (or with a crowd behind it, or
	# on a tough foe); now a ready grab skill is used like any other.
	var zone := _zone("oren", 20)
	_foe(zone, "dock_thug", Vector2(618, 300))
	for skill_id: String in zone.hero.skills:
		if skill_id != "power_throw":
			zone.hero.cooldowns[skill_id] = 1000
	var pilot := AutoPilot.new(_content())
	var chosen := ""
	for t in 30:
		var input := pilot.think(zone)
		if input.skill != "":
			chosen = input.skill
			break
		zone.tick(input)
	assert_eq(chosen, "power_throw", "the grab skill, on a lone ordinary foe")


func test_auto_does_not_grab_when_badly_hurt_with_others_close() -> void:
	var zone := _zone("oren", 20)
	_foe(zone, "dock_thug", Vector2(618, 300))
	var other := _foe(zone, "dock_thug", Vector2(560, 300))
	for skill_id: String in zone.hero.skills:
		if skill_id != "power_throw":
			zone.hero.cooldowns[skill_id] = 1000
	zone.hero.hp = zone.hero.max_hp / 3
	var pilot := AutoPilot.new(_content())
	assert_true(pilot.think(zone).skill != "power_throw", "a hold would pin it near the other")
	other.position = Vector2(300, 300)
	assert_eq(pilot.think(zone).skill, "power_throw", "with nobody else close it grabs")


func test_auto_does_not_stand_over_a_foe_it_threw() -> void:
	var zone := _zone("oren", 20)
	var thrown := _foe(zone, "dock_thug", Vector2(640, 300))
	var other := _foe(zone, "dock_thug", Vector2(520, 300))
	var pilot := AutoPilot.new(_content())
	pilot._target_id = thrown.id
	pilot._thrown_id = thrown.id
	thrown.enter(Fighter.State.DOWN, 90)
	var foes: Array[Fighter] = [thrown, other]
	assert_eq(pilot._choose_target(zone, foes), other, "the one that can be hit")
	pilot._thrown_id = 0
	pilot._target_id = thrown.id
	assert_eq(pilot._choose_target(zone, foes), thrown, "a foe merely knocked down is kept")


func test_a_counter_reply_reaches_the_attacker_it_caught() -> void:
	# A caught attacker reels PARRY_PUSH away; the reply's first move steps in.
	for skill_id: String in _content().skills:
		var skill: Dictionary = _content().skills[skill_id]
		var stance := _content().moves.get_move(str(skill.get("move", "")))
		if stance == null or not stance.counter:
			continue
		var reply := _content().moves.get_move(str(skill["then"][0]))
		var far := reply.reach_offset + reply.reach + reply.advance
		assert_true(reply.advance > 0, "%s: the reply steps in" % skill_id)
		assert_true(far >= 46 + CombatRules.PARRY_PUSH, "%s reaches %d" % [skill_id, far])


func test_a_caught_blow_from_a_long_reach_is_answered() -> void:
	# Riku's Power Jab reaches 46 and does not step in; caught at the end of
	# its reach, Riku reels 14 further away. The reply must still land.
	var dao := DuelSim.make_hero(_content(), "dao", 30, 0)
	var riku := DuelSim.make_hero(_content(), "riku", 30, 1)
	dao.skills = SkillRules.unlocked(_content(), "dao", 30)
	riku.skills = SkillRules.unlocked(_content(), "riku", 30)
	riku.position = dao.position + Vector2(48, 0)
	var fighters: Array[Fighter] = [dao, riku]
	var rng := RandomNumberGenerator.new()
	var caught := false
	var landed := false
	for t in 120:
		var mine := FighterInput.new()
		var theirs := FighterInput.new()
		mine.face = 1
		theirs.face = -1
		if t == 0:
			mine.skill = "perfect_parry"
		if t == 2:
			theirs.skill = "power_jab"
		var inputs := {dao.id: mine, riku.id: theirs}
		var lib := _content().moves
		for hit in CombatRules.tick(fighters, inputs, lib, DuelSim.BOUNDS, Callable(), rng):
			if hit.attacker_id == dao.id and hit.damage > 0:
				landed = true
		caught = caught or (dao.move != null and dao.move.id == "perfect_parry_hit")
	assert_true(caught, "the parry catches the jab")
	assert_true(landed, "and its reply reaches Riku")


func test_auto_goes_on_into_the_longer_route_and_keeps_its_skills() -> void:
	var zone := _zone("mika", 30)
	var hero := zone.hero
	hero.combo_chain = ["quick_jab"]
	hero.combo_landed = true
	hero.combo_timer = 60
	var longer := AutoSkills.combo_weight(hero, "dash_strike")
	var shorter := AutoSkills.combo_weight(hero, "triple_punch")
	assert_true(
		longer > shorter, "Chain Reaction's next skill first (%.1f > %.1f)" % [longer, shorter]
	)
	hero.cooldowns["chain_breaker"] = 300
	assert_eq(
		AutoSkills.combo_weight(hero, "dash_strike"),
		AutoSkills.LINK_WEIGHT,
		"not when it cannot finish"
	)
	ComboRules.reset(hero)
	hero.cooldowns.clear()
	assert_near(
		AutoSkills.combo_weight(hero, "dash_strike"), AutoSkills.HOLD_WEIGHT, "kept for its route"
	)
	hero.cooldowns["quick_jab"] = 200
	assert_eq(
		AutoSkills.combo_weight(hero, "dash_strike"), 1.0, "used freely when the route is far off"
	)


func test_perfect_retort_can_be_completed() -> void:
	var dao := DuelSim.make_hero(_content(), "dao", 30, 0)
	dao.skills = SkillRules.unlocked(_content(), "dao", 30)
	dao.combos = ComboRules.unlocked(_content(), "dao", 30)
	var route := {}
	for r: Dictionary in dao.combos:
		if r["id"] == "perfect_retort":
			route = r
	assert_true(not route.is_empty(), "unlocked at 30")
	ComboRules.on_skill(dao, "perfect_parry")
	dao.skill_id = "perfect_parry"
	ComboRules.on_hit(dao, _content().moves.get_move("perfect_parry_hit"))
	assert_eq(
		ComboRules.next_links(dao), ["slip_punch"] as Array[String], "a landed reply leads on"
	)
