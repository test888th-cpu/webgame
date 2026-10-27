extends TestCase
## Auto battle: allowed only in areas the hero has beaten by hand; the pilot
## clears a street alone with every hero, eats, dodges, guards and uses its
## skills by their move data; the farm loop rests, restocks and rides back;
## and the player's own input always takes over.

const TEST_SAVE := "user://test_auto_save.json"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A zone with the hero alone (no fights started), the brains kept but idle.
func _zone(area_id := "saltmarket", hero_id := "mika", level := 3) -> ZoneSim:
	var profile := PlayerProfile.new_game(_content(), hero_id)
	profile.level = level
	var zone := ZoneSim.new(_content(), profile, area_id, "west", 5)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.position = Vector2(600, 300)
	return zone


func _foe(zone: ZoneSim, kind: String, at: Vector2) -> Fighter:
	var foe := zone.spawn_enemy(kind, at)
	(zone.brains[foe.id] as EnemyBrain).cooldown = 100000
	return foe


func _game() -> Node2D:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func test_auto_is_only_for_areas_already_beaten() -> void:
	var profile := PlayerProfile.new_game(_content())
	assert_true(AutoRules.problem(profile, _content(), "depot_yard") != "", "nothing to fight")
	assert_true(AutoRules.problem(profile, _content(), "saltmarket") != "", "not beaten yet")
	StreetMemory.visit(profile, "canal_works")
	assert_eq(AutoRules.problem(profile, _content(), "saltmarket"), "", "beaten: walked on east")
	var last := StreetMemory.street(_content()).back() as String
	assert_true(AutoRules.problem(profile, _content(), last) != "", "the last area's boss is up")
	for encounter: Dictionary in _content().area(last)["encounters"]:
		for wave: Array in encounter["waves"]:
			for kind: String in wave:
				if _content().enemy(kind).get("boss", false):
					profile.defeated[kind] = 1
	assert_eq(AutoRules.problem(profile, _content(), last), "", "its bosses beaten")


func test_every_hero_clears_a_street_alone() -> void:
	for hero_id: String in _content().hero_order:
		var profile := PlayerProfile.new_game(_content(), hero_id)
		profile.level = 3
		profile.add_item("steamed_bun", 5)
		var zone := ZoneSim.new(_content(), profile, "saltmarket", "west", 11)
		zone.refresh_hero()
		zone.hero.hp = zone.hero.max_hp
		var pilot := AutoPilot.new(_content())
		var left := false
		var skills := 0
		for tick in 60 * 60 * 3:
			var input := pilot.think(zone)
			if pilot.item:
				zone.use_item(pilot.item)
			for event in zone.tick(input):
				left = left or event.type == "exit"
				if event.type == "swing" and event.data["id"] == ZoneSim.HERO_ID:
					skills += 1 if event.data["skill"] else 0
			if pilot.status == AutoPilot.STATUS_CLEAR or zone.hero.is_ko():
				break
		assert_eq(pilot.status, AutoPilot.STATUS_CLEAR, "%s clears the Saltmarket" % hero_id)
		assert_true(not zone.hero.is_ko(), "%s is still standing" % hero_id)
		assert_true(not left, "%s never walks out of the area" % hero_id)
		assert_true(skills > 0, "%s fights with its skills" % hero_id)
		assert_true(
			profile.money > 0 and zone.pickups.is_empty(), "%s picks up the drops" % hero_id
		)


func test_it_eats_when_hurt_and_not_when_well() -> void:
	var zone := _zone()
	zone.profile.add_item("steamed_bun", 2)
	zone.profile.add_item("ginger_tea", 1)
	var pilot := AutoPilot.new(_content())
	pilot.heal_below = 0.8
	pilot.think(zone)
	assert_eq(pilot.item, "", "full health: nothing")
	zone.hero.hp = int(zone.hero.max_hp * 0.75)
	pilot.think(zone)
	assert_eq(pilot.item, "steamed_bun", "a little hurt: the small heal")
	zone.hero.hp = int(zone.hero.max_hp * 0.1)
	pilot.think(zone)
	assert_eq(pilot.item, "ginger_tea", "badly hurt: the big one")
	zone.item_cooldown = 10
	pilot.think(zone)
	assert_eq(pilot.item, "", "not while food is on cooldown")


func test_it_turns_area_skills_on_a_crowd() -> void:
	var zone := _zone()
	_foe(zone, "smogling", Vector2(620, 300))
	_foe(zone, "smogling", Vector2(580, 300))
	var input := AutoPilot.new(_content()).think(zone)
	assert_eq(input.skill, "whirlwind_kick", "the kick that hits both sides")


func test_it_saves_the_big_skill_for_crowds_and_bosses() -> void:
	var zone := _zone()
	for skill_id: String in ["rising_uppercut", "whirlwind_kick", "shoulder_rush"]:
		zone.hero.cooldowns[skill_id] = 1000
	var foe := _foe(zone, "smogling", Vector2(625, 300))
	var pilot := AutoPilot.new(_content())
	assert_true(pilot.think(zone).skill != "furnace_slam", "not on one street thug")
	zone.fighters.erase(foe)
	zone.brains.erase(foe.id)
	_foe(zone, "sludge_foreman", Vector2(625, 300))
	assert_eq(pilot.think(zone).skill, "furnace_slam", "but on a boss")


func test_it_dodges_what_guard_cannot_stop_and_parries_the_rest() -> void:
	var zone := _zone()
	var brute := _foe(zone, "patrol_unit", Vector2(630, 300))
	brute.facing = -1
	brute.move = _content().moves.get_move("brute_slam")
	brute.state = Fighter.State.ATTACK
	brute.state_tick = brute.move.startup - 6
	var input := AutoPilot.new(_content()).think(zone)
	assert_true(input.dodge, "a guard breaker is dodged")
	assert_eq(input.face, -1, "away from it")
	brute.move = _content().moves.get_move("k7_piston")
	brute.state_tick = brute.move.startup - 3
	input = AutoPilot.new(_content()).think(zone)
	assert_true(input.guard, "a plain blow is guarded just before it lands")
	assert_eq(input.face, 1, "facing it, for a parry")


func test_it_steps_out_of_a_hazard_shadow() -> void:
	var zone := _zone()
	var drop := {"at": zone.hero.position, "ticks": 40, "half": Vector2(24, 10), "kind": "crane"}
	zone.hazards.append(drop)
	var pilot := AutoPilot.new(_content())
	var input := pilot.think(zone)
	assert_true(input.move != Vector2.ZERO and not input.dodge, "walks out with time to spare")
	drop["ticks"] = 8
	assert_true(pilot.think(zone).dodge, "dodges out when it is about to land")


func test_the_farm_loop_rules() -> void:
	var zone := _zone()
	var pilot := AutoPilot.new(_content())
	pilot.status = AutoPilot.STATUS_CLEAR
	assert_true(AutoRules.wants_rest(zone, pilot), "an area cleared: go and rest")
	pilot.status = AutoPilot.STATUS_ADVANCE
	zone.profile.inventory.clear()
	zone.hero.hp = 10
	assert_true(AutoRules.wants_rest(zone, pilot), "hurt with nothing to eat: rest")
	zone.profile.add_item("steamed_bun")
	assert_true(not AutoRules.wants_rest(zone, pilot), "not while there is food")
	assert_eq(AutoRules.fare(_content(), "depot_yard"), 10, "Win's fare home")
	var profile := PlayerProfile.new_game(_content())
	profile.money = 45
	var bought := AutoRules.restock(profile, _content(), "depot_yard", 10, 10)
	assert_eq(bought, 3, "buns bought while the fare back stays in the purse")
	assert_true(profile.money >= 10, "the fare is kept")


func test_auto_starts_only_where_allowed_and_the_player_takes_over() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	game.auto.toggle()
	assert_true(not game.auto.on, "refused in an area not beaten yet")
	StreetMemory.visit(game.profile, "canal_works")
	game.auto.toggle()
	assert_true(game.auto.on, "on in a beaten area")
	var manual := FighterInput.new()
	manual.move = Vector2.LEFT
	assert_eq(game.auto.input(manual, true), manual, "the player's own input wins")
	assert_true(game.auto.input(FighterInput.new(), false) != null, "otherwise the pilot plays")
	game.enter_area("canal_works", "west")
	assert_true(not game.auto.on, "walking on to another area turns it off")
	_done(game)


func test_the_farm_loop_rests_restocks_and_rides_back() -> void:
	var game := _game()
	var profile: PlayerProfile = game.profile
	StreetMemory.visit(profile, "canal_works")
	profile.defeated["smog_warden"] = 1
	for i in _content().area("saltmarket")["encounters"].size():
		StreetMemory.mark_cleared(profile, "saltmarket", i)
	game.enter_area("saltmarket", "west")
	profile.money = 100
	profile.hp = 20
	game.zone.hero.hp = 20
	game.auto.toggle()
	for tick in 600:
		var input: FighterInput = game.auto.input(FighterInput.new(), false)
		game.step(input)
		if game.auto.runs > 1:
			break
	assert_eq(game.auto.runs, 2, "a second run started")
	assert_eq(game.zone.area_id, "saltmarket", "back in the farmed area")
	assert_eq(game.zone.hero.hp, game.zone.hero.max_hp, "rested at home")
	assert_true(profile.cleared.is_empty(), "the street's fights are back")
	assert_true(profile.count("steamed_bun") > 0, "food bought for the next run")
	assert_true(profile.money >= 0 and profile.money < 100, "paid for food and the taxi")
	assert_true(game.auto.on, "and still farming")
	_done(game)


func test_the_hud_switch_shows_its_state() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	StreetMemory.visit(game.profile, "canal_works")
	var button := game.find_child("AutoButton", true, false) as Button
	assert_true(button != null, "an AUTO switch on the HUD")
	button.pressed.emit()
	assert_true(game.auto.on, "pressing it turns auto on")
	game._process(0.016)
	assert_eq(button.text, "AUTO ON", "and it says so")
	var status := game.find_child("AutoStatus", true, false) as Label
	assert_true(status.visible and status.text.begins_with("AUTO"), "with what it is doing")
	_done(game)
