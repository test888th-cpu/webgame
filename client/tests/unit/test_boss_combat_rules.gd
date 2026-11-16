extends TestCase
## Two standing rules of boss fights, and the auto battle's respect for them:
## - every boss (enemies.json "boss": bosses, mini-bosses and world bosses
##   alike) is ungrabbable: a grab or throw never holds one;
## - no counter stance answers a boss's guard breaker, Perfect Parry included
##   (its catch-all is for heroes' and ordinary monsters' guard breakers);
## - the auto battle does not keep Oren's skills back for a grab route
##   against a boss (it can never be grabbed), but still does on an ordinary
##   foe it can grab.

const BOUNDS := Rect2(0, 200, 800, 200)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _bosses() -> Array[String]:
	var out: Array[String] = []
	for enemy_id: String in _content().enemies:
		if _content().enemy(enemy_id).get("boss", false):
			out.append(enemy_id)
	return out


## A zone with Oren (level 70) and nothing else in it.
func _zone(hero_id := "oren") -> ZoneSim:
	var profile := PlayerProfile.new_game(_content(), hero_id)
	profile.level = 70
	var zone := ZoneSim.new(_content(), profile, "depot_yard", "", 7)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
		zone.brains.erase(enemy.id)
	zone.hero.position = Vector2(300, 300)
	zone.hero.facing = 1
	return zone


func test_every_boss_is_ungrabbable() -> void:
	var bosses := _bosses()
	assert_eq(bosses.size(), 24, "every boss of the game is checked")
	for boss_id in bosses:
		var zone := _zone()
		var boss := zone.spawn_enemy(boss_id, Vector2(318, 300))
		boss.facing = -1
		assert_true(boss.ungrabbable and boss.unshaken, boss_id + " is a boss")
		assert_true(not GrabRules.can_hold(boss), boss_id + " cannot be held")
		# For real: Oren's Power Throw and his plain grab on it.
		var oren := zone.hero
		oren.energy = CombatRules.MAX_ENERGY
		var fighters: Array[Fighter] = [oren, boss]
		var held := false
		for skill_id: String in ["power_throw", ""]:
			oren.cooldowns.clear()
			for t in 90:
				var press := FighterInput.new()
				press.skill = skill_id if t == 0 else ""
				press.grab = skill_id == "" and t == 0
				press.light = oren.state == Fighter.State.GRAB
				CombatRules.tick(fighters, {oren.id: press}, _content().moves, BOUNDS)
				held = held or boss.state == Fighter.State.HELD
		assert_true(not held, boss_id + " was never held by a grab or a throw")


func test_perfect_parry_catches_guard_breakers_but_not_a_bosss() -> void:
	var zone := _zone("dao")
	var dao := zone.hero
	dao.skills = SkillRules.unlocked(_content(), "dao", 70)
	CombatRules.start_move(dao, _content().moves.get_move("perfect_parry_stance"))
	dao.state_tick = dao.move.startup
	var boss := zone.spawn_enemy("sludge_foreman", Vector2(330, 300))
	var boss_breaker := _content().moves.get_move("bs_mb_sludge_foreman_003")
	var boss_plain := _content().moves.get_move("foreman_jab")
	assert_true(boss_breaker.guard_break and not boss_plain.guard_break, "the moves tested")
	assert_true(
		not CounterRules.catches(dao, boss_breaker, true, boss), "a boss's guard breaker: no"
	)
	assert_true(CounterRules.catches(dao, boss_plain, true, boss), "a boss's plain blow: yes")
	var brute := zone.spawn_enemy("pipe_brute", Vector2(330, 300))
	var slam := _content().moves.get_move("brute_slam")
	assert_true(CounterRules.catches(dao, slam, true, brute), "a monster's guard breaker: yes")
	var kan := DuelSim.make_hero(_content(), "kan", 70, 1)
	var hammer := _content().moves.get_move("brawler_hammer")
	assert_true(CounterRules.catches(dao, hammer, true, kan), "a hero's guard breaker: yes (PvP)")
	# Quick Counter never took a guard breaker, from anyone.
	CombatRules.start_move(dao, _content().moves.get_move("quick_counter_stance"))
	dao.state_tick = dao.move.startup
	assert_true(not CounterRules.catches(dao, slam, true, brute), "Quick Counter: no")
	# For real: the boss's guard breaker lands on Dao's open Perfect Parry.
	var real := _zone("dao")
	var hero := real.hero
	hero.hp = 100000
	hero.max_hp = 100000
	hero.energy = CombatRules.MAX_ENERGY
	# The charge carries the boss 150 px over its wind-up and live ticks:
	# start it far enough away to land on Dao.
	var charge := (
		boss_breaker.advance * boss_breaker.startup / (boss_breaker.startup + boss_breaker.active)
	)
	var foreman := real.spawn_enemy("sludge_foreman", Vector2(300 + charge + 16, 300))
	foreman.facing = -1
	hero.facing = 1
	CombatRules.start_move(foreman, boss_breaker)
	var fighters: Array[Fighter] = [hero, foreman]
	var countered := false
	var hurt := false
	for t in boss_breaker.startup + boss_breaker.active + 2:
		# The stance opens just before the blow is due, as a player times it.
		if t == boss_breaker.startup - 2:
			CombatRules.start_move(hero, _content().moves.get_move("perfect_parry_stance"))
		for event in CombatRules.tick(fighters, {}, _content().moves, BOUNDS):
			if event.defender_id == hero.id:
				countered = countered or event.countered
				hurt = hurt or event.damage > 0
	assert_true(not countered, "the stance does not answer it")
	assert_true(hurt, "and it lands")


func test_auto_battle_holds_no_grab_route_against_a_boss() -> void:
	var zone := _zone()
	var oren := zone.hero
	var grabs: Array = []
	for skill_id: String in oren.skills:
		if _content().moves.get_move(str(oren.skills[skill_id]["move"])).grab:
			grabs.append(skill_id)
	assert_eq(grabs.size(), 7, "every skill of Oren's starts with a grab (six and his ultimate)")
	# Backbreaker is Lift and Drop's finisher: kept back while Iron Grip is
	# ready on a foe that can be grabbed, not on a boss.
	assert_eq(AutoSkills.combo_weight(oren, "backbreaker"), AutoSkills.HOLD_WEIGHT, "a thug")
	assert_eq(AutoSkills.combo_weight(oren, "backbreaker", false, grabs), 1.0, "a boss")
	# In the auto battle: against a boss in reach, a skill is used at once
	# (a grab skill shoves a boss: still a blow); against a thug the grab
	# route is kept.
	var pilot := AutoPilot.new(_content())
	var boss := zone.spawn_enemy("sludge_foreman", Vector2(320, 300))
	boss.facing = -1
	(zone.brains[boss.id] as EnemyBrain).cooldown = 1000000
	var used := {}
	for t in 600:
		var input := pilot.think(zone)
		if input.skill != "" and oren.cooldown_left(input.skill) == 0:
			used[input.skill] = true
		zone.tick(input)
	assert_true(used.has("backbreaker"), "Backbreaker is used on the boss: %s" % str(used.keys()))
	var thug_zone := _zone()
	var thug := thug_zone.spawn_enemy("dock_thug", Vector2(320, 300))
	thug.facing = -1
	(thug_zone.brains[thug.id] as EnemyBrain).cooldown = 1000000
	var thug_oren := thug_zone.hero
	assert_eq(
		AutoSkills.combo_weight(thug_oren, "backbreaker"), AutoSkills.HOLD_WEIGHT, "still held"
	)
