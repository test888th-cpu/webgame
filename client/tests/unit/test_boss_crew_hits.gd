extends TestCase
## A boss's hazards (its skills' blasts, drops and sweeps) on its own side:
## the crew in the footprint is knocked down and pushed out, never hurt and
## never killed (CombatRules.crew_hit); the hero in the same footprint takes
## the full blow. Fighters who do not flinch only stand it.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Saltmarket with a hazard boss far off and the hero at `at`.
func _zone(at: Vector2) -> ZoneSim:
	var profile := PlayerProfile.new_game(_content(), "mika")
	profile.level = 20
	var zone := ZoneSim.new(_content(), profile, "saltmarket", "west", 5)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.position = at
	_foe(zone, "harbourmaster_chen", at + Vector2(400, 0))
	return zone


func _foe(zone: ZoneSim, kind: String, at: Vector2) -> Fighter:
	var foe := zone.spawn_enemy(kind, at)
	(zone.brains[foe.id] as EnemyBrain).cooldown = 100000
	return foe


## A hazard of `damage` landing next tick at `at`.
func _drop(zone: ZoneSim, at: Vector2, damage := 400) -> void:
	zone.hazards.append(
		{"at": at, "ticks": 1, "half": Vector2(40, 30), "damage": damage, "kind": "shock"}
	)


func _hits(events: Array[ZoneEvent], id: int) -> Array[CombatEvent]:
	var out: Array[CombatEvent] = []
	for event in events:
		if event.type == "hit" and event.hit.defender_id == id:
			out.append(event.hit)
	return out


func test_the_blast_floors_the_crew_but_never_hurts_it() -> void:
	var at := Vector2(400, 300)
	var zone := _zone(at)
	var minion := _foe(zone, "smogling", at + Vector2(10, 0))
	var weak := _foe(zone, "tar_hound", at + Vector2(-10, 4))
	weak.hp = 1
	var hero_before := zone.hero.hp
	_drop(zone, at)
	var events := zone.tick(FighterInput.new())
	assert_true(zone.hero.hp < hero_before, "the hero in the footprint is hurt")
	for crew: Fighter in [minion, weak]:
		var hits := _hits(events, crew.id)
		assert_eq(hits.size(), 1, crew.kind + ": the blast reaches them")
		assert_true(hits[0].friendly, crew.kind + ": as the boss's own side")
		assert_eq(hits[0].damage, 0, crew.kind + ": no damage")
		assert_true(hits[0].knocked_down and not hits[0].ko, crew.kind + ": floored, not out")
		assert_eq(crew.state, Fighter.State.DOWN, crew.kind + ": on the ground")
	assert_eq(minion.hp, minion.max_hp, "full health kept")
	assert_eq(weak.hp, 1, "even on its last point of health it lives")
	assert_true(minion.knockback_remaining > 0.0, "thrown away from the blast's centre")
	for event in events:
		assert_true(event.type != "defeat", "no one defeated by their own boss")


func test_a_crew_that_does_not_flinch_stands_it() -> void:
	var at := Vector2(400, 300)
	var zone := _zone(at)
	var guard := _foe(zone, "port_guard", at)
	guard.unshaken = true
	_drop(zone, at)
	var hits := _hits(zone.tick(FighterInput.new()), guard.id)
	assert_eq(hits.size(), 1, "reached")
	assert_true(hits[0].armored and not hits[0].knocked_down, "it stands")
	assert_eq(guard.hp, guard.max_hp, "unhurt")


func test_the_boss_itself_and_a_floored_crew_are_left_alone() -> void:
	var at := Vector2(400, 300)
	var zone := _zone(at)
	var boss := zone.fighter(zone.boss_id)
	boss.position = at
	var down := _foe(zone, "smogling", at)
	down.enter(Fighter.State.DOWN)
	_drop(zone, at)
	var events := zone.tick(FighterInput.new())
	assert_eq(_hits(events, boss.id).size(), 0, "the boss is never caught by its own")
	assert_eq(_hits(events, down.id).size(), 0, "one already down is not hit again")
	assert_eq(boss.hp, boss.max_hp, "boss unhurt")


func test_a_whole_fight_of_hazards_kills_none_of_the_crew() -> void:
	# The boss's own cycle, many times over, with its crew standing in it.
	var at := Vector2(400, 300)
	var zone := _zone(at)
	var crew: Array[Fighter] = []
	for i in 4:
		crew.append(_foe(zone, "smogling", at + Vector2(i * 6 - 9, i * 3)))
	for wave in 12:
		_drop(zone, at + Vector2(wave % 3 * 5, 0))
		for t in 3:
			zone.hero.hp = zone.hero.max_hp
			zone.tick(FighterInput.new())
	for f in crew:
		assert_eq(f.hp, f.max_hp, "crew %d kept its health" % f.id)
		assert_true(not f.is_ko(), "crew %d still fighting" % f.id)
