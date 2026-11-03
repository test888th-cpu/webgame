extends TestCase
## A farming ground's living field (FarmSpawner): it fills up to its cap,
## sends one more in after each loss, keeps entrances away from the hero and
## the way out, is the same for the same seed, makes the odd elite worth
## more, and stays out of every other kind of area.

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


func test_the_field_fills_to_its_cap_then_replaces_each_loss() -> void:
	var c := _content()
	var data := FarmSpawner.spec(c, GROUND)
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 7)
	var cap := int(data["cap"])
	var idle := FighterInput.new()
	for tick in FarmSpawner.FILL_TICKS * cap + 1:
		zone.tick(idle)
	assert_eq(_standing(zone), cap, "full after one entrance every half second")
	for tick in 600:
		zone.tick(idle)
	assert_true(_standing(zone) <= cap, "never more than the cap")
	var ticks := 0
	_fell(zone, zone.enemies()[0])
	while _standing(zone) < cap and ticks < 1000:
		zone.tick(idle)
		ticks += 1
	assert_eq(ticks, int(data["respawn_ticks"]), "one more comes after the respawn time")


func test_entrances_keep_away_from_the_hero_and_the_way_out() -> void:
	var c := _content()
	var from_x := float(FarmSpawner.spec(c, GROUND)["from_x"])
	for hero_x: float in [60.0, 400.0, 700.0, 1100.0, 1340.0]:
		var zone := ZoneSim.new(c, _hero(), GROUND, "west", 11)
		zone.hero.position.x = hero_x
		for i in 40:
			var x := FarmSpawner.entry_x(zone, from_x)
			assert_true(x >= from_x, "never west of from_x (%s)" % x)
			assert_true(x <= zone.bounds.end.x, "inside the field")
			assert_true(
				absf(x - hero_x) >= FarmSpawner.MIN_GAP, "not on top of the hero at %s" % hero_x
			)


func test_the_west_end_is_a_safe_spot() -> void:
	var c := _content()
	var west := float(FarmSpawner.spec(c, GROUND)["from_x"]) - FarmSpawner.SAFE_MARGIN
	var zone := ZoneSim.new(c, _hero(), GROUND, "west", 9)
	var furthest := INF
	for tick in 3600:
		zone.tick(FighterInput.new())
		for enemy in zone.enemies():
			if not enemy.is_ko():
				furthest = minf(furthest, enemy.position.x)
	assert_true(furthest < INF, "enemies came for the hero")
	assert_true(furthest >= west - 8.0, "none walked into the safe spot (%s)" % furthest)
	assert_true(zone.hero.position.x < west, "where the hero arrived is inside it")


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
		".cap: 1 to": func(s: Dictionary) -> void: s["cap"] = 0,
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
