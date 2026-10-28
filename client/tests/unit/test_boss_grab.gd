extends TestCase
## Bosses (ai.grab) now and then go for a weapon on the ground: not every
## time, never from under the hero's feet, with a "!" the player can see,
## and they keep their own heavy blow while they swing it.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _rng(seed := 3) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## The Furnace Baron's brain, set to grab the first weapon it looks at.
func _eager_brain() -> EnemyBrain:
	var ai: Dictionary = _content().enemy("furnace_baron")["ai"].duplicate(true)
	ai["grab"]["chance"] = 1.0
	var brain := EnemyBrain.new(ai, _rng())
	brain.grab_wait = 0
	return brain


func _think(brain: EnemyBrain, me: Fighter, hero: Fighter, loot: Vector2) -> FighterInput:
	return brain.think(me, hero, true, _content().moves, _rng(), loot, 10)


func test_only_bosses_grab_and_their_bodies_can_hold_weapons() -> void:
	var grabbers := 0
	for enemy_id: String in _content().enemies:
		var enemy := _content().enemy(enemy_id)
		var ai: Variant = enemy.get("ai")
		if not (ai is Dictionary and ai.has("grab")):
			continue
		grabbers += 1
		assert_true(enemy.get("boss", false), "%s is a boss" % enemy_id)
		var art: Dictionary = _content().art[str(enemy["sprite"])]
		for weapon_id: String in _content().weapons:
			var move_id: String = _content().weapons[weapon_id]["moveset"]["light"]
			var anim := _content().moves.get_move(move_id).anim
			if not art["animations"].has(anim):
				anim = str(FighterView.FALLBACK.get(anim, anim))
			assert_true(art.get("hands", {}).has(anim), "%s holds a %s" % [enemy_id, weapon_id])
	assert_true(grabbers >= 6, "most human bosses grab (%d)" % grabbers)


func test_a_boss_waits_before_its_first_look() -> void:
	var ai: Dictionary = _content().enemy("furnace_baron")["ai"].duplicate(true)
	ai["grab"]["chance"] = 1.0
	var brain := EnemyBrain.new(ai, _rng())
	var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(200, 300))
	var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(420, 300))
	var first := -1
	for tick in int(ai["grab"]["every"]) + 5:
		_think(brain, me, hero, Vector2(240, 300))
		if brain.eyed and first < 0:
			first = tick
	assert_eq(first, int(ai["grab"]["every"]) - 1, "not the moment the fight starts")


func test_a_boss_walks_to_a_weapon_and_picks_it_up() -> void:
	var brain := _eager_brain()
	var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(200, 300))
	var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(420, 300))
	var input := _think(brain, me, hero, Vector2(260, 300))
	assert_true(brain.eyed, "sets off for it")
	assert_true(input.move.x > 0.0, "heads for the weapon, not the hero")
	input = _think(brain, me, hero, Vector2(260, 300))
	assert_true(not brain.eyed, "the '!' shows once")
	me.position = Vector2(256, 302)
	input = _think(brain, me, hero, Vector2(260, 300))
	assert_true(input.pick, "picks it up when standing on it")
	assert_eq(brain.fetching, Vector2.INF, "done fetching")


func test_never_from_under_the_heros_feet() -> void:
	var brain := _eager_brain()
	var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(200, 300))
	var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(270, 300))
	_think(brain, me, hero, Vector2(262, 300))
	assert_true(not brain.eyed, "the hero is nearer the weapon")
	assert_eq(brain.fetching, Vector2.INF, "fights instead")
	brain.grab_wait = 0
	_think(brain, me, Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(600, 300)), Vector2(500, 300))
	assert_true(not brain.eyed, "out of its range")


func test_a_boss_gives_up_when_the_weapon_is_gone() -> void:
	var brain := _eager_brain()
	var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(200, 300))
	var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(420, 300))
	_think(brain, me, hero, Vector2(300, 300))
	assert_true(brain.fetching != Vector2.INF, "on its way")
	_think(brain, me, hero, Vector2.INF)
	assert_eq(brain.fetching, Vector2.INF, "the hero took it: back to the fight")
	assert_eq(brain.grab_wait, brain.grab_every, "and no new look for a while")
	brain.grab_wait = 0
	_think(brain, me, hero, Vector2(300, 300))
	for i in EnemyBrain.GRAB_PATIENCE:
		_think(brain, me, hero, Vector2(300, 300))
	assert_eq(brain.fetching, Vector2.INF, "and gives up on one it cannot reach")


func test_not_every_time() -> void:
	var ai: Dictionary = _content().enemy("furnace_baron")["ai"]
	var rng := _rng(11)
	var went := 0
	var looks := 300
	for i in looks:
		var brain := EnemyBrain.new(ai, rng)
		brain.grab_wait = 0
		var me := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(200, 300))
		var hero := Fighter.new(1, ZoneSim.HERO_TEAM, Vector2(420, 300))
		brain.think(me, hero, true, _content().moves, rng, Vector2(260, 300), 10)
		went += 1 if brain.eyed else 0
	var share := float(went) / looks
	var chance := float(ai["grab"]["chance"])
	assert_true(absf(share - chance) < 0.1, "goes about %.2f of the time (%.2f)" % [chance, share])


func test_an_armed_boss_keeps_its_own_heavy() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 7)
	zone.ground_weapons.clear()
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone.hero.position = Vector2(300, 300)
	var boss := zone.spawn_enemy("furnace_baron", Vector2(500, 300))
	zone.brains[boss.id].grab_chance = 1.0
	zone.brains[boss.id].grab_wait = 0
	zone.place_weapon("pipe", Vector2(540, 300), 6)
	var events: Array[ZoneEvent] = []
	for i in 90:
		events.append_array(zone.tick(FighterInput.new()))
		if boss.weapon:
			break
	var types := events.map(func(event: ZoneEvent) -> String: return event.type)
	assert_true("weapon_eyed" in types, "the '!' is reported")
	assert_true("weapon_pickup" in types, "the pickup is reported")
	assert_eq(boss.weapon, "pipe", "the Baron swings the pipe")
	assert_eq(
		CombatRules.starter(boss, _content().moves, "light"),
		str(_content().weapons["pipe"]["moveset"]["light"]),
		"its light blow is the pipe's"
	)
	assert_eq(
		CombatRules.starter(boss, _content().moves, "heavy"),
		str(boss.moveset["heavy"]),
		"its heavy is still its own"
	)


func test_the_validator_checks_grab() -> void:
	var broken := ContentDB.load_all()
	broken.errors.clear()
	var thug: Dictionary = broken.enemies["dock_thug"]
	thug["ai"]["grab"] = {"chance": 0.3, "every": 200, "range": 100}
	var baron: Dictionary = broken.enemies["furnace_baron"]
	baron["ai"]["grab"] = {"chance": 1.5, "every": 0, "range": 100}
	broken.validate()
	var all := "\n".join(broken.errors)
	for expected in [
		"dock_thug.ai.grab: only bosses",
		"furnace_baron.ai.grab.every",
		"furnace_baron.ai.grab.chance",
	]:
		assert_true(expected in all, "reports " + expected)
