extends TestCase
## Auto battle: allowed wherever there is a fight (story areas not cleared
## yet included) or a story step to take; the pilot clears a street alone
## with every hero, eats, dodges, guards and uses its skills by their move
## data; the farm loop rests, restocks and rides back; and the player's own
## input always takes over.

const TEST_SAVE := "user://test_auto_save"

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
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node2D) -> void:
	GameSession.settings["auto_story"] = true
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_auto_runs_wherever_there_is_a_fight_or_a_story_step() -> void:
	var profile := PlayerProfile.new_game(_content())
	for area_id in StreetMemory.street(_content()):
		if not _content().area(area_id).get("encounters", []).is_empty():
			assert_eq(AutoRules.problem(profile, _content(), area_id), "", area_id + ": not beaten")
	assert_eq(AutoRules.problem(profile, _content(), "depot_yard"), "", "a quest to take there")
	var off := AutoRules.problem(profile, _content(), "depot_yard", false)
	assert_true(off != "", "nothing to fight there without the story")
	for quest_id: String in _content().quests:
		profile.quests[quest_id] = {"state": "turned_in", "progress": 1}
	assert_true(AutoRules.problem(profile, _content(), "depot_yard") != "", "the story is done")


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
	var zone := _zone("saltmarket", "kan", 40)
	_foe(zone, "smogling", Vector2(620, 300))
	_foe(zone, "smogling", Vector2(580, 300))
	var input := AutoPilot.new(_content()).think(zone)
	assert_true(input.skill != "", "a skill for the crowd")
	var move := _content().moves.get_move(str(_content().skills[input.skill]["move"]))
	assert_true(move.reach_offset < 0.0, "%s hits both sides" % input.skill)


func test_it_saves_the_big_skill_for_crowds_and_bosses() -> void:
	var zone := _zone("saltmarket", "kan", 50)
	for skill_id in SkillRules.actives(_content(), "kan"):
		zone.hero.cooldowns[skill_id] = 1000
	var foe := _foe(zone, "smogling", Vector2(625, 300))
	var pilot := AutoPilot.new(_content())
	assert_eq(pilot.think(zone).skill, "", "no ultimate while the gauge is empty")
	zone.hero.gauge = UltimateRules.FULL
	assert_true(pilot.think(zone).skill != "street_carnage", "not on one street thug")
	zone.fighters.erase(foe)
	zone.brains.erase(foe.id)
	_foe(zone, "sludge_foreman", Vector2(625, 300))
	assert_eq(pilot.think(zone).skill, "street_carnage", "but on a boss")


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
	assert_eq(AutoRules.fare(_content(), "main_city"), 10, "Win's fare from the city")
	var profile := PlayerProfile.new_game(_content())
	profile.money = 45
	var bought := AutoRules.restock(profile, _content(), "main_city", 10, 10)
	assert_eq(bought, 3, "buns bought while the fare back stays in the purse")
	assert_true(profile.money >= 10, "the fare is kept")


func test_auto_starts_only_where_allowed_and_the_player_takes_over() -> void:
	var game := _game()
	game.enter_area("main_city", "west")
	GameSession.settings["auto_story"] = false
	game.auto.toggle()
	assert_true(not game.auto.on, "refused with no one to fight and no story to follow")
	GameSession.settings["auto_story"] = true
	game.enter_area("saltmarket", "west")
	game.auto.toggle()
	assert_true(game.auto.on, "on in an area not beaten yet")
	var manual := FighterInput.new()
	manual.move = Vector2.LEFT
	assert_eq(game.auto.input(manual, true), manual, "the player's own input wins")
	assert_true(game.auto.input(FighterInput.new(), false) != null, "otherwise the pilot plays")
	game.enter_area("canal_works", "west")
	assert_true(not game.auto.on, "the player walking on to another area turns it off")
	_done(game)


func test_the_farm_loop_rests_restocks_and_rides_back() -> void:
	var game := _game()
	GameSession.settings["auto_story"] = false
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
	var spin := button.get_node("Spin") as TextureRect
	assert_true(spin.texture != null, "the switch is an icon")
	assert_eq(button.text, "", "with no words on it")
	var hud: Node = game.get_node("Hud")
	hud._process(0.1)
	assert_true(spin.rotation_degrees > 0.0, "its arrows turn while auto runs")
	assert_true(button.tooltip_text.contains("Run 1"), "the run's tally is in the tooltip")
	button.pressed.emit()
	game._process(0.016)
	assert_true(not game.auto.on, "pressing again turns it off")
	assert_eq(spin.rotation_degrees, 0.0, "and the arrows stop")
	_done(game)


func test_the_equipment_screen_says_when_auto_battle_changes_gear() -> void:
	# Auto battle wears better gear it finds (setting "auto_gear"): it can put
	# back what the player took off, so the switch sits where gear changes.
	var game: Game = _game()
	GameSession.set_setting("auto_gear", true)
	game.open_inventory()
	var toggle := game.menu.find_child("AutoGear", true, false) as CheckButton
	assert_true(toggle != null, "the switch is on the equipment screen")
	assert_true(toggle.button_pressed, "showing it is on")
	toggle.button_pressed = false
	assert_eq(GameSession.settings["auto_gear"], false, "turned off from here")
	game.profile.level = 30
	game.profile.add_item("riveted_jacket")
	var worn := str(game.profile.equipment["body"])
	game.auto._wear_upgrades()
	assert_eq(str(game.profile.equipment["body"]), worn, "off: auto leaves the gear alone")
	GameSession.set_setting("auto_gear", true)
	_done(game)


func test_it_answers_an_attack_with_a_counter_stance() -> void:
	var zone := _zone("saltmarket", "dao", 3)
	var thug := _foe(zone, "dock_thug", Vector2(626, 300))
	thug.facing = -1
	var jab := _content().moves.get_move(str(thug.moveset["light"]))
	thug.enter(Fighter.State.ATTACK)
	thug.move = jab
	thug.state_tick = maxi(0, jab.startup - 6)
	var input := AutoPilot.new(_content()).think(zone)
	assert_eq(input.skill, "quick_counter", "a blow on its way: the stance, not a jab")
	assert_eq(input.face, 1, "facing the attacker")
	zone.hero.cooldowns["quick_counter"] = 500
	input = AutoPilot.new(_content()).think(zone)
	assert_true(input.skill != "quick_counter", "not while it cools down")


func test_it_never_opens_with_a_stance() -> void:
	var zone := _zone("saltmarket", "dao", 70)
	_foe(zone, "smogling", Vector2(624, 300))
	var input := AutoPilot.new(_content()).think(zone)
	var skill: Dictionary = zone.hero.skills.get(input.skill, {})
	assert_true(
		input.skill == "" or not AutoSkills.is_stance(_content(), skill),
		"with nobody attacking it strikes or punches (%s)" % input.skill
	)


func test_it_throws_what_it_grabs() -> void:
	var zone := _zone("saltmarket", "oren", 3)
	var foe := _foe(zone, "dock_thug", Vector2(618, 300))
	var pilot := AutoPilot.new(_content())
	var held := false
	var thrown := false
	for t in 200:
		for event in zone.tick(pilot.think(zone)):
			if event.type == "hit" and event.hit.move_id == "grappler_throw":
				thrown = true
		held = held or foe.state == Fighter.State.HELD
		if thrown:
			break
	assert_true(held, "the Grappler's first skill seizes the thug")
	assert_true(thrown, "and auto throws them")


func test_it_braces_when_hurt_in_a_fight() -> void:
	var zone := _zone("saltmarket", "dao", 70)
	_foe(zone, "smogling", Vector2(640, 300))
	for skill_id in SkillRules.actives(_content(), "dao"):
		if skill_id != "defensive_stance":
			zone.hero.cooldowns[skill_id] = 1000
	var pilot := AutoPilot.new(_content())
	assert_true(pilot.think(zone).skill != "defensive_stance", "not at full health")
	zone.hero.hp = zone.hero.max_hp / 3
	assert_eq(pilot.think(zone).skill, "defensive_stance", "hurt and close: brace")
