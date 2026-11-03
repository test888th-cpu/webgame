extends TestCase
## A farming ground's living field (FarmSpawner): its camps stand full and
## wait, a camp comes as one when the hero walks in or strikes one, a chase
## too far ends back home healed, a cleared camp refills away from the hero,
## the way out stays safe, the same seed brings the same field, the odd elite
## is worth more, and it stays out of every other kind of area.

const GROUND := "farm_facility_annex"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hero(level := 37) -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content(), "oren")
	profile.level = level
	return profile


## How many enemies stand in `zone` (not knocked out).
static func _standing(zone: ZoneSim) -> int:
	var count := 0
	for enemy in zone.enemies():
		if not enemy.is_ko():
			count += 1
	return count


## Knocks `enemy` out as a blow would, paying its rewards (ZoneSim._defeat).
static func _fell(zone: ZoneSim, enemy: Fighter) -> Array[ZoneEvent]:
	var events: Array[ZoneEvent] = []
	enemy.hp = 0
	enemy.enter(Fighter.State.KO)
	zone._defeat(enemy, events)
	return events


## A copy of the content whose ground draws only `kind`, elite as often as
## `chance`.
func _single(kind: String, chance: float) -> ContentDB:
	var copy := ContentDB.load_all()
	copy.areas[GROUND]["spawning"]["pool"] = {kind: 1}
	copy.areas[GROUND]["spawning"]["elite_chance"] = chance
	return copy


## Camp `camp`'s members standing in `zone`.
static func _camp(zone: ZoneSim, camp: int) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for id: int in zone._farm._members:
		var enemy := zone.fighter(id)
		if zone._farm._members[id] == camp and enemy and not enemy.is_ko():
			out.append(enemy)
	return out


static func _brain(zone: ZoneSim, enemy: Fighter) -> EnemyBrain:
	return zone.brains[enemy.id]


func test_the_camps_stand_full_and_wait_for_the_hero() -> void:
	var c := _content()
	var data := FarmSpawner.spec(c, GROUND)
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 7)
	zone.tick(FighterInput.new())
	assert_eq(_standing(zone), FarmSpawner.capacity(data), "every camp full on arrival")
	assert_true(FarmSpawner.capacity(data) >= 9, "a field worth the walk")
	var homes := {}
	for enemy in zone.enemies():
		homes[enemy.id] = enemy.position
	for tick in 600:
		zone.tick(FighterInput.new())
	for enemy in zone.enemies():
		assert_true(not _brain(zone, enemy).engaged, "nobody comes while the hero is away")
		var moved := enemy.position.distance_to(homes[enemy.id])
		assert_true(moved < 12.0, "each stands at its spot (%s px)" % moved)


func test_walking_into_a_camp_wakes_that_camp_only() -> void:
	var c := _content()
	var data := FarmSpawner.spec(c, GROUND)
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 7)
	zone.tick(FighterInput.new())
	var first := _camp(zone, 0)
	zone.hero.position = first[0].position + Vector2(-float(data["aggro"]) + 20.0, 0)
	for tick in 3:
		zone.tick(FighterInput.new())
	for enemy in _camp(zone, 0):
		assert_true(_brain(zone, enemy).engaged, "the whole first camp comes")
	for camp in range(1, (data["camps"] as Array).size()):
		for enemy in _camp(zone, camp):
			assert_true(not _brain(zone, enemy).engaged, "camp %d stays put" % camp)


func test_a_blow_from_afar_wakes_the_camp_it_lands_on() -> void:
	var c := _content()
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 7)
	zone.tick(FighterInput.new())
	var last := _camp(zone, 2)
	last[0].hp -= 1
	for tick in 2:
		zone.tick(FighterInput.new())
	for enemy in _camp(zone, 2):
		assert_true(_brain(zone, enemy).engaged, "struck: its camp comes")


func test_a_chase_too_far_from_home_gives_up_and_heals() -> void:
	var c := _content()
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 7)
	zone.tick(FighterInput.new())
	var enemy := _camp(zone, 1)[0]
	var brain := _brain(zone, enemy)
	brain.engaged = true
	enemy.hp = enemy.max_hp / 2
	enemy.position.x = brain.home.x + brain.leash + 20.0
	var back := false
	for tick in 900:
		zone.tick(FighterInput.new())
		if not brain.engaged and enemy.position.distance_to(brain.home) < 8.0:
			back = true
			zone.tick(FighterInput.new())
			break
	assert_true(back, "walked home")
	assert_eq(enemy.hp, enemy.max_hp, "and healed there")


func test_a_cleared_camp_refills_behind_the_hero_not_in_their_face() -> void:
	var c := _content()
	var data := FarmSpawner.spec(c, GROUND)
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 7)
	zone.tick(FighterInput.new())
	var centre := float(data["camps"][0])
	zone.hero.position.x = centre
	for enemy in _camp(zone, 0):
		_fell(zone, enemy)
	var respawn := int(data["respawn_ticks"])
	for tick in respawn + 60:
		zone.tick(FighterInput.new())
		zone.hero.position.x = centre
	assert_eq(_camp(zone, 0).size(), 0, "nothing comes back with the hero standing there")
	zone.hero.position.x = 60.0
	var size := int(data["camp_size"])
	for tick in respawn * size + 60:
		zone.tick(FighterInput.new())
		zone.hero.position.x = 60.0
	assert_eq(_camp(zone, 0).size(), size, "away from it, the camp fills again")


func test_the_west_end_is_a_safe_spot() -> void:
	var c := _content()
	var west := float(FarmSpawner.spec(c, GROUND)["from_x"]) - FarmSpawner.SAFE_MARGIN
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 9)
	zone.tick(FighterInput.new())
	var arrived := zone.hero.position
	assert_true(arrived.x < west, "where the hero arrived is inside it")
	zone.hero.position = _camp(zone, 0)[0].position
	zone.tick(FighterInput.new())
	var furthest := INF
	for tick in 1200:
		zone.hero.position = arrived
		zone.tick(FighterInput.new())
		for enemy in zone.enemies():
			if not enemy.is_ko():
				furthest = minf(furthest, enemy.position.x)
	assert_true(furthest < west + 40.0, "the woken camp chased the hero west")
	assert_true(furthest >= west - 8.0, "none walked into the safe spot (%s)" % furthest)


func test_the_same_seed_brings_the_same_field() -> void:
	var c := _content()
	var kinds: Array = []
	for run in 2:
		var zone := ZoneSim.new(c, _hero(), GROUND, "west", 21)
		var seen: Array[String] = []
		for tick in 400:
			for event in zone.tick(FighterInput.new()):
				if event.type == "spawn":
					seen.append(str(event.data["kind"]))
		kinds.append(seen)
	assert_true(kinds[0].size() > 0, "enemies came")
	assert_eq(kinds[0], kinds[1], "the same kinds in the same order")


func test_an_elite_is_tougher_and_worth_three_times_the_xp_and_coins() -> void:
	var always := _single("facility_trooper", FarmSpawner.MAX_ELITE_CHANCE)
	var never := _single("facility_trooper", 0.0)
	var plain_zone := ZoneSim.new(never, _hero(30), GROUND, "west", 5)
	var plain := plain_zone.spawn_enemy("facility_trooper", Vector2(900, 300))
	var plain_money := float(plain_zone._enemy_level[plain.id]["stats"]["money_scale"])
	var plain_xp := int(_fell(plain_zone, plain)[0].data["xp"])
	var zone := ZoneSim.new(always, _hero(30), GROUND, "west", 5)
	var elite: Fighter = null
	for tick in 20000:
		for event in zone.tick(FighterInput.new()):
			if event.type != "spawn":
				continue
			if event.data["elite"]:
				elite = zone.fighter(int(event.data["id"]))
			else:
				_fell(zone, zone.fighter(int(event.data["id"])))
		if elite:
			break
	assert_true(elite != null and elite.elite, "an elite came")
	assert_eq(elite.max_hp, roundi(plain.max_hp * FarmSpawner.ELITE_HP), "three times the HP")
	var events := _fell(zone, elite)
	var xp := float(events[0].data["xp"])
	assert_near(xp, plain_xp * FarmSpawner.ELITE_REWARD, "XP x3 (to rounding)", 2.0)
	var stats: Dictionary = zone._enemy_level[elite.id]["stats"]
	var money := float(stats["money_scale"])
	assert_near(money, plain_money * FarmSpawner.ELITE_REWARD, "coins x3", 0.0001)


func test_an_elite_drops_three_rolls_of_its_loot() -> void:
	var c := _single("facility_trooper", FarmSpawner.MAX_ELITE_CHANCE)
	c.enemies["facility_trooper"]["loot"] = {
		"money": [0, 0], "drops": [{"item": "scrap_metal", "chance": 1.0}]
	}
	var zone := ZoneSim.new(c, _hero(30), GROUND, "west", 5)
	var elite: Fighter = null
	for tick in 20000:
		for event in zone.tick(FighterInput.new()):
			if event.type != "spawn":
				continue
			if event.data["elite"]:
				elite = zone.fighter(int(event.data["id"]))
			else:
				_fell(zone, zone.fighter(int(event.data["id"])))
		if elite:
			break
	zone.pickups.clear()
	_fell(zone, elite)
	assert_eq(zone.pickups.size(), 1, "the usual roll when it falls")
	zone.tick(FighterInput.new())
	var scrap := 0
	for pickup: Dictionary in zone.pickups:
		scrap += 1 if pickup.get("item") == "scrap_metal" else 0
	assert_eq(scrap, roundi(FarmSpawner.ELITE_REWARD), "and two more: three rolls in all")


func test_no_other_area_has_a_living_field() -> void:
	var c := _content()
	for area_id: String in c.areas:
		var farm := AreaRules.kind(c, area_id) == AreaRules.FARM
		assert_eq(FarmSpawner.active(c, area_id), farm, area_id + ": a field only in a ground")
	var zone := ZoneSim.new(c, _hero(5), "saltmarket", "west", 3)
	for tick in 300:
		for event in zone.tick(FighterInput.new()):
			assert_true(event.type != "spawn", "the story spawns only by its fights")
	assert_eq(zone.enemies().size(), 0, "no one comes to a story area unasked")


func test_the_validator_checks_every_spawning_block() -> void:
	var cases := {
		".camps: 1 to": func(s: Dictionary) -> void: s["camps"] = [],
		".camps: 5000": func(s: Dictionary) -> void: s["camps"] = [5000],
		".camp_size: 1 to": func(s: Dictionary) -> void: s["camp_size"] = 0,
		".aggro: ": func(s: Dictionary) -> void: s["aggro"] = 10,
		".respawn_ticks: at least": func(s: Dictionary) -> void: s["respawn_ticks"] = 5,
		".elite_chance: 0 to": func(s: Dictionary) -> void: s["elite_chance"] = 0.9,
		".from_x: inside the area": func(s: Dictionary) -> void: s["from_x"] = 5000,
		".pool: {enemy: weight}": func(s: Dictionary) -> void: s["pool"] = {},
		".pool.furnace_baron": func(s: Dictionary) -> void: s["pool"] = {"furnace_baron": 1},
		".pool.ghost": func(s: Dictionary) -> void: s["pool"] = {"ghost": 1},
	}
	for expected: String in cases:
		var copy := ContentDB.load_all()
		(cases[expected] as Callable).call(copy.areas[GROUND]["spawning"])
		copy.errors.clear()
		copy.validate()
		assert_true(expected in "\n".join(copy.errors), "rejects: %s" % expected)
	var story := ContentDB.load_all()
	story.areas["saltmarket"]["spawning"] = story.areas[GROUND]["spawning"].duplicate(true)
	story.errors.clear()
	story.validate()
	assert_true("only a farming ground has one" in "\n".join(story.errors), "not on the street")
	assert_eq(_content().errors, PackedStringArray(), "the shipped data is clean")
