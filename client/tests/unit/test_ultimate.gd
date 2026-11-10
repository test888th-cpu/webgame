extends TestCase
## Ultimates and their gauge (UltimateRules), skill grabs and slipping moves:
## an ultimate needs a full gauge, the gauge fills by fighting on either side
## of a blow, and each job's ultimate keeps to its own rule.

const BOUNDS := Rect2(0, 200, 4000, 200)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## `hero_id` at level 70 with a full gauge, and a sturdy foe in front.
func _pair(hero_id: String, gap := 24.0) -> Array[Fighter]:
	var db := _content()
	var hero := Fighter.new(1, 1, Vector2(500, 300), 300)
	JobRules.equip(hero, db, hero_id)
	hero.skills = SkillRules.unlocked(db, hero_id, 70)
	hero.gauge = UltimateRules.FULL
	var foe := Fighter.new(2, 2, Vector2(500 + gap, 300), 5000)
	foe.facing = -1
	foe.moveset = {"light": "thug_jab"}
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


func _press(field: String, value: Variant = true) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, value)
	return input


## Runs `ticks` ticks with `first` as the first tick's inputs.
func _run(fighters: Array[Fighter], ticks: int, first := {}) -> Array[CombatEvent]:
	var hits: Array[CombatEvent] = []
	for t in ticks:
		var inputs: Dictionary = first if t == 0 else {}
		hits.append_array(CombatRules.tick(fighters, inputs, _content().moves, BOUNDS))
	return hits


## `hero_id` at level 70 in the yard with a full gauge, and a tireless thug
## `gap` px in front who never attacks.
func _zone(hero_id: String, gap := 24.0) -> ZoneSim:
	var db := _content()
	var profile := PlayerProfile.new_game(db, hero_id)
	profile.level = 70
	var zone := ZoneSim.new(db, profile, "depot_yard", "", 7)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
		zone.brains.erase(enemy.id)
	zone.hero.position = Vector2(300, 300)
	zone.hero.facing = 1
	zone.hero.gauge = UltimateRules.FULL
	var foe := zone.spawn_enemy("dock_thug", zone.hero.position + Vector2(gap, 0))
	foe.max_hp = 100000
	foe.hp = 100000
	(zone.brains[foe.id] as EnemyBrain).cooldown = 100000
	return zone


## The moves of the hero's blows over `ticks` ticks after pressing `skill_id`.
func _play(zone: ZoneSim, skill_id: String, ticks: int) -> Array:
	var landed := []
	for t in ticks:
		var input := _press("skill", skill_id) if t == 0 else FighterInput.new()
		for event in zone.tick(input):
			if event.type == "hit" and event.hit.attacker_id == zone.hero.id:
				landed.append(event.hit.move_id)
	return landed


func _dealt(hits: Array[CombatEvent], defender := 2) -> int:
	var sum := 0
	for hit in hits:
		if hit.attacker_id == 1 and hit.defender_id == defender:
			sum += hit.damage
	return sum


func test_an_ultimate_needs_a_full_gauge_and_spends_it() -> void:
	var fighters := _pair("riku")
	fighters[0].gauge = UltimateRules.FULL - 1.0
	_run(fighters, 1, {1: _press("skill", "knockout_devastation")})
	assert_eq(fighters[0].state, Fighter.State.IDLE, "refused short of a full gauge")
	fighters[0].gauge = UltimateRules.FULL
	_run(fighters, 1, {1: _press("skill", "knockout_devastation")})
	assert_eq(fighters[0].state, Fighter.State.ATTACK, "a full gauge lets it go")
	assert_near(fighters[0].gauge, 0.0, "and is spent")
	assert_true(fighters[0].move.telegraph, "it warns before it strikes")


func test_the_gauge_fills_by_hitting_and_by_being_hit() -> void:
	var fighters := _pair("mika")
	var hero := fighters[0]
	hero.gauge = 0.0
	_run(fighters, 12, {1: _press("light")})
	var per_hit := float(_content().job_gauge["per_hit"])
	assert_near(hero.gauge, per_hit, "one blow landed")
	_run(fighters, 40)
	var before := hero.gauge
	var hp := hero.hp
	_run(fighters, 20, {2: _press("light")})
	assert_true(hero.hp < hp, "the hero is hit")
	var share := float(hp - hero.hp) / hero.max_hp
	var expected := before + share * float(_content().job_gauge["per_hurt"])
	assert_near(hero.gauge, expected, "and gains for the health lost", 0.01)
	assert_near(fighters[1].gauge, 0.0, "an enemy has no gauge")
	_run(fighters, 40)
	hero.gauge = UltimateRules.FULL - 0.1
	_run(fighters, 12, {1: _press("light")})
	assert_near(hero.gauge, UltimateRules.FULL, "it never overflows")


func test_an_ultimate_s_own_blows_fill_nothing() -> void:
	var zone := _zone("riku")
	var landed := _play(zone, "knockout_devastation", 200)
	assert_true(landed.size() >= 6, "the ultimate lands (%d blows)" % landed.size())
	assert_near(zone.hero.gauge, 0.0, "and the gauge stays empty")


func test_every_striking_ultimate_lands_all_its_blows_once() -> void:
	var cases := {
		"riku": "knockout_devastation", "kan": "street_carnage", "mika": "million_fist_onslaught"
	}
	for hero_id: String in cases:
		var moves := SkillSequence.moves(_content().skills[cases[hero_id]])
		for gap: float in [24.0, 40.0]:
			var zone := _zone(hero_id, gap)
			var landed := _play(zone, cases[hero_id], 400)
			assert_eq(landed, moves, "%s from %d px: every stage hits once" % [cases[hero_id], gap])
			assert_eq(zone.hero.state, Fighter.State.IDLE, hero_id + " is free again")


func test_absolute_retribution_does_nothing_unless_attacked() -> void:
	var idle := _pair("dao")
	var hits := _run(idle, 200, {1: _press("skill", "absolute_retribution")})
	assert_eq(_dealt(hits), 0, "nobody attacked: no damage at all")
	assert_near(idle[0].gauge, 0.0, "and the gauge is gone")
	var struck := _pair("dao")
	var first := {1: _press("skill", "absolute_retribution")}
	hits = _run(struck, 20, first)
	hits.append_array(_run(struck, 200, {2: _press("light")}))
	assert_true(hits.any(func(hit: CombatEvent) -> bool: return hit.countered), "the jab is caught")
	assert_true(_dealt(hits) > 100, "and answered in full (%d)" % _dealt(hits))


func test_titan_destruction_throws_a_foe_and_only_strikes_a_boss() -> void:
	var fighters := _pair("oren", 60.0)
	var bystander := Fighter.new(3, 2, Vector2(520, 300), 5000)
	fighters.append(bystander)
	var hits := _run(fighters, 200, {1: _press("skill", "titan_destruction")})
	var moves := []
	for hit in hits:
		moves.append(hit.move_id)
	assert_true("titan_slam" in moves, "the foe is lifted and slammed")
	assert_true("titan_wave" in moves, "and the shockwave follows")
	assert_true(_dealt(hits, 3) > 0, "the bystander is caught in it")
	var boss := _pair("oren", 60.0)
	boss[1].unshaken = true
	hits = _run(boss, 200, {1: _press("skill", "titan_destruction")})
	moves = []
	for hit in hits:
		moves.append(hit.move_id)
	assert_true("titan_slam" not in moves, "a boss is never lifted")
	assert_true("titan_shove" in moves and "titan_wave" in moves, "it takes the blow and the wave")
	assert_eq(boss[1].held_by, 0, "and is held by nobody")
	var missed := _pair("oren", 600.0)
	hits = _run(missed, 200, {1: _press("skill", "titan_destruction")})
	assert_eq(hits.size(), 0, "a grab that closes on nobody: no shockwave either")


func test_a_skill_grab_throws_by_itself_and_the_skill_goes_on() -> void:
	var fighters := _pair("oren")
	fighters.append(Fighter.new(3, 2, Vector2(470, 300), 5000))
	var hits := _run(fighters, 120, {1: _press("skill", "ground_slam")})
	var moves := []
	for hit in hits:
		moves.append(hit.move_id)
	assert_eq(moves, ["ground_slam_hit", "ground_slam_wave"], "the slam, then its wave")
	assert_eq(hits[1].defender_id, 3, "the wave floors the foe standing behind")
	assert_eq(fighters[0].state, Fighter.State.IDLE, "the Grappler is free again")
	assert_eq(fighters[1].held_by, 0, "and the foe let go")


func test_a_crushing_hold_hurts_all_the_while_then_drops() -> void:
	var fighters := _pair("oren")
	var hits := _run(fighters, 140, {1: _press("skill", "crushing_hold")})
	var squeezes := 0
	for hit in hits:
		squeezes += 1 if hit.move_id == "crushing_hold_squeeze" else 0
	assert_true(squeezes >= 4, "squeezed again and again (%d)" % squeezes)
	assert_eq(hits[hits.size() - 1].move_id, "crushing_hold_drop", "then dropped")
	var held := _pair("oren")
	_run(held, 30, {1: _press("skill", "crushing_hold")})
	assert_eq(held[1].state, Fighter.State.HELD, "held while it lasts")
	_run(held, 1, {1: _press("light")})
	assert_eq(held[1].state, Fighter.State.HELD, "the hold is not cut short by a button")


func test_a_slip_punch_cannot_be_hit_on_the_way_in() -> void:
	var slip := _content().moves.get_move("slip_punch")
	var jab := _content().moves.get_move("thug_jab")
	assert_true(jab.startup < slip.startup + slip.active, "the jab lands during the slip")
	var fighters := _pair("dao")
	var hero := fighters[0]
	var hp := hero.hp
	var hits := _run(fighters, 40, {1: _press("skill", "slip_punch"), 2: _press("light")})
	assert_eq(hero.hp, hp, "the jab passes through the slip")
	assert_true(_dealt(hits) > 0, "and the punch lands")
	var late := _pair("dao")
	_run(late, slip.startup + slip.active + 1, {1: _press("skill", "slip_punch")})
	assert_true(CombatRules.is_vulnerable(late[0]), "the recovery is open")


func test_the_ultimate_sits_on_the_hotbar_or_its_own_key() -> void:
	var db := _content()
	for hero_id: String in db.hero_order:
		var profile := PlayerProfile.new_game(db, hero_id)
		var ultimate := SkillRules.ultimate(db, hero_id)
		assert_true(HotbarRules.place(profile, db, 6, "skill:" + ultimate), ultimate + " on a slot")
		assert_true(not SkillRules.unlocked(db, hero_id, 49).has(ultimate), "locked at 49")
		assert_near(float(SkillRules.unlocked(db, hero_id, 50)[ultimate]["gauge"]), 100.0, "50")
	assert_true(InputMap.has_action("ultimate"), "and a key of its own")
