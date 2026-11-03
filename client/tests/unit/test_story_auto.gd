extends TestCase
## Auto battle through the story (StoryAuto, AutoBattle): from a new game it
## takes the first quest, fights through to the stage's boss with no area
## cleared by hand, rides back to hand the quest in and takes the next one.

const TEST_SAVE := "user://test_story_auto_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _game() -> Node2D:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("oren")
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_the_steps_of_the_first_stage() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	StreetMemory.visit(profile, c.start_area)
	var step := StoryAuto.step(profile, c, "depot_yard", true)
	assert_eq(step, {"do": StoryAuto.QUEST, "quest": "foreman", "turn_in": false}, "take it")
	assert_eq(StoryAuto.step(profile, c, "main_city", true)["to"], "depot_yard", "ride to Odo")
	QuestRules.accept(profile, "foreman", c)
	assert_eq(StoryAuto.step(profile, c, "depot_yard", true)["do"], StoryAuto.EAST, "walk on")
	StreetMemory.visit(profile, "saltmarket")
	assert_eq(StoryAuto.step(profile, c, "saltmarket", false)["do"], StoryAuto.EAST, "and on")
	var far := StoryAuto.step(profile, c, "depot_yard", true)
	assert_eq(far, {"do": StoryAuto.RIDE, "to": "saltmarket"}, "to the furthest reached")
	StreetMemory.visit(profile, "canal_works")
	assert_eq(StoryAuto.step(profile, c, "canal_works", false)["do"], StoryAuto.STAY, "the boss")
	var again := StoryAuto.step(profile, c, "canal_works", true)
	assert_eq(again, {"do": StoryAuto.RIDE, "to": "canal_works"}, "nothing left: rest, back")
	QuestRules.on_defeat(profile, "sludge_foreman", c)
	assert_eq(StoryAuto.step(profile, c, "canal_works", true)["to"], "depot_yard", "report")
	var hand := StoryAuto.step(profile, c, "depot_yard", true)
	assert_eq(hand, {"do": StoryAuto.QUEST, "quest": "foreman", "turn_in": true}, "hand in")
	QuestRules.turn_in(profile, "foreman", c)
	assert_eq(StoryAuto.step(profile, c, "depot_yard", true)["quest"], "the_pit", "the next")
	for quest_id: String in c.quests:
		profile.quests[quest_id] = {"state": "turned_in", "progress": 1}
	assert_eq(StoryAuto.step(profile, c, "depot_yard", true)["do"], StoryAuto.DONE, "the end")


func test_auto_plays_the_first_stage_from_a_new_game() -> void:
	# Game seeds each area's fights from the global generator: fixed here, so
	# the run repeats exactly.
	seed(11)
	var game := _game()
	var profile: PlayerProfile = game.profile
	game.enter_area("depot_yard", "west")
	game.auto.toggle()
	assert_true(game.auto.on, "auto starts where the first quest is given")
	var seen: Array[String] = []
	var ticks := 0
	while ticks < 40000 and game.auto.on:
		ticks += 1
		game.step(game.auto.input(FighterInput.new(), false))
		if game.zone.area_id not in seen:
			seen.append(game.zone.area_id)
		if QuestRules.status(profile, "the_pit", _content()) == "active":
			break
	assert_eq(QuestRules.status(profile, "foreman", _content()), "turned_in", "stage one done")
	assert_eq(QuestRules.status(profile, "the_pit", _content()), "active", "the next taken")
	assert_true(int(profile.defeated.get("sludge_foreman", 0)) > 0, "its boss beaten by auto")
	assert_true("canal_works" in seen and "saltmarket" in seen, "walked the stage")
	assert_true(game.auto.on, "and still going (%d ticks)" % ticks)
	_done(game)


func test_auto_wears_the_best_gear_it_carries_for_each_slot() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = 20
	var weapons: Array[String] = []
	for item_id: String in c.items:
		var item := c.item(item_id)
		if item.get("type") == "equipment" and item.get("slot") == "weapon":
			if int(item.get("level", 1)) <= 20 and ItemRules.is_upgrade(profile, item_id, c):
				weapons.append(item_id)
	assert_true(weapons.size() >= 2, "weapons to choose from")
	var best := weapons[0]
	for item_id in weapons:
		profile.add_item(item_id)
		if ItemRules.copy_score(profile, item_id, c) > ItemRules.copy_score(profile, best, c):
			best = item_id
	var too_high := ""
	for item_id: String in c.items:
		if c.item(item_id).get("type") == "equipment" and int(c.item(item_id).get("level", 1)) > 20:
			too_high = item_id
	profile.add_item(too_high)
	var worn := AutoRules.wear_upgrades(profile, c)
	assert_true(best in worn, "the best weapon carried is put on")
	assert_eq(profile.equipment["weapon"], best, "and worn")
	assert_true(too_high not in worn, "nothing above the hero's level")
	assert_eq(AutoRules.wear_upgrades(profile, c), [], "nothing more to change")


func test_in_a_world_boss_arena_auto_fights_to_the_end() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	for boss: String in c.world_bosses:
		var arena := str(WorldBossRules.spec(c, boss)["area"])
		assert_eq(AutoRules.problem(profile, c, arena), "", arena + ": auto may fight it")
		var zone := ZoneSim.new(c, profile, arena, "west", 3)
		var pilot := AutoPilot.new(c)
		pilot.status = AutoPilot.STATUS_CLEAR
		profile.inventory.clear()
		zone.hero.hp = 1
		assert_true(not AutoRules.wants_rest(zone, pilot), arena + ": never home halfway")


func test_a_quest_left_far_behind_does_not_drag_the_hero_back() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	for area_id in StreetMemory.street(c):
		StreetMemory.visit(profile, area_id)
	var step := StoryAuto.step(profile, c, "reactor_walkway", false)
	assert_eq(step["do"], StoryAuto.HERE, "the first quest is far back: fight on here")
	assert_eq(step["to"], "depot_yard", "and it says where the quest is")
	var near := StoryAuto.step(profile, c, "saltmarket", false)
	assert_eq(near["do"], StoryAuto.RIDE, "close by, auto still goes for it")
