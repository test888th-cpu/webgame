extends TestCase
## Throwing the held weapon: E with nothing underfoot winds up, lets go, and
## the weapon flies along the street, hits the first foe and lands (or
## breaks on its last use).

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## The yard with nothing lying around and the dummy cleared away.
func _zone() -> ZoneSim:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 7)
	zone.ground_weapons.clear()
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone.hero.position = Vector2(300, 300)
	zone.hero.facing = 1
	return zone


func _press(field: String) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, true)
	return input


func _run(zone: ZoneSim, ticks: int, first: FighterInput = null) -> Array[ZoneEvent]:
	var events: Array[ZoneEvent] = []
	for i in ticks:
		events.append_array(zone.tick(first if first and i == 0 else FighterInput.new()))
	return events


func _of_type(events: Array[ZoneEvent], type: String) -> Array[ZoneEvent]:
	var found: Array[ZoneEvent] = []
	for event in events:
		if event.type == type:
			found.append(event)
	return found


## A smogling standing still `gap` px ahead of the hero.
func _target(zone: ZoneSim, gap: float) -> Fighter:
	var enemy := zone.spawn_enemy("smogling", zone.hero.position + Vector2(gap, 0))
	enemy.facing = -1
	zone.brains.erase(enemy.id)
	return enemy


func test_the_hero_throws_instead_of_putting_down() -> void:
	var zone := _zone()
	zone.equip_weapon(zone.hero, "pipe", 6)
	var events := _run(zone, 1, _press("pick"))
	assert_eq(zone.hero.state, Fighter.State.ATTACK, "winding up the throw")
	assert_eq(zone.hero.weapon, "pipe", "still in hand during the wind-up")
	events = _run(zone, 10)
	assert_eq(_of_type(events, "weapon_throw").size(), 1, "let go once")
	assert_eq(zone.hero.weapon, "", "hands empty")
	assert_eq(zone.thrown.size(), 1, "in flight")


func test_a_thrown_weapon_hits_the_first_foe_and_lands() -> void:
	var zone := _zone()
	var near := _target(zone, 70)
	var far := _target(zone, 110)
	zone.equip_weapon(zone.hero, "pipe", 6)
	var events := _run(zone, 40, _press("pick"))
	var hits := _of_type(events, "hit")
	assert_eq(hits.size(), 1, "one hit")
	assert_eq(hits[0].hit.defender_id, near.id, "the nearer foe")
	assert_true(hits[0].hit.knocked_down, "knocked down")
	assert_eq(far.hp, far.max_hp, "the one behind is untouched")
	assert_eq(zone.thrown.size(), 0, "landed")
	assert_eq(zone.ground_weapons.size(), 1, "lying on the street")
	assert_eq(zone.ground_weapons[0]["uses"], 5, "the hit used it once")


func test_a_miss_lands_at_the_end_of_its_flight() -> void:
	var zone := _zone()
	zone.equip_weapon(zone.hero, "plank", 5)
	_run(zone, 60, _press("pick"))
	assert_eq(zone.ground_weapons.size(), 1, "landed")
	var travelled: float = zone.ground_weapons[0]["position"].x - 300.0
	assert_true(travelled > 100.0, "flew %d px" % travelled)
	assert_eq(zone.ground_weapons[0]["uses"], 5, "a miss costs no use")


func test_a_last_use_breaks_on_impact() -> void:
	var zone := _zone()
	_target(zone, 60)
	zone.equip_weapon(zone.hero, "bottle", 1)
	var events := _run(zone, 40, _press("pick"))
	assert_eq(_of_type(events, "weapon_break").size(), 1, "shattered")
	assert_eq(zone.ground_weapons.size(), 0, "nothing left to pick up")


func test_bosses_are_stunned_not_floored() -> void:
	var zone := _zone()
	var boss := zone.spawn_enemy("furnace_baron", zone.hero.position + Vector2(70, 0))
	boss.facing = -1
	zone.brains.erase(boss.id)
	zone.equip_weapon(zone.hero, "pipe", 6)
	var events := _run(zone, 30, _press("pick"))
	var hits := _of_type(events, "hit")
	assert_eq(hits.size(), 1, "the boss is hit")
	assert_true(not hits[0].hit.knocked_down, "but stays on their feet")


func test_a_guard_blocks_a_thrown_weapon_only_from_the_front() -> void:
	var foe := Fighter.new(2, 2, Vector2(400, 300), 100)
	foe.facing = -1  # facing a throw coming from the left
	foe.enter(Fighter.State.GUARD)
	var front := CombatRules.thrown_hit(foe, 1, 380.0, 20, true, "thrown_pipe")
	assert_true(front.blocked, "blocked from the front")
	assert_eq(foe.state, Fighter.State.GUARD, "still guarding")
	foe.enter(Fighter.State.GUARD)
	var back := CombatRules.thrown_hit(foe, 1, 420.0, 20, true, "thrown_pipe")
	assert_true(not back.blocked, "not from behind")
	assert_true(back.knocked_down, "floored from behind")
