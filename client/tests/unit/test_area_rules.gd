extends TestCase
## Area kinds, regions and farming-ground unlocks (AreaRules, F0). The tests
## add a made-up ground ("test_ground") to a copy of the content, or for the
## game scenes to the session's content, and take it out again; the seven
## shipped grounds are tested in test_farming_grounds.gd.

const TEST_SAVE := "user://test_area_rules_save"
const GROUND := "test_ground"
const ROAD_Y := 300.0

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A farming ground built from a world boss arena's layout (so it has a
## background to draw), with its own kind, region, purpose and unlock rule.
static func _ground(from: ContentDB, unlock: Dictionary) -> Dictionary:
	var ground: Dictionary = from.area("great_drain").duplicate(true)
	ground.erase("world_boss")
	ground["name"] = "Test Ground"
	ground["level"] = 4
	ground["encounters"] = []
	ground["kind"] = "farm"
	ground["region"] = "South Street"
	ground["purpose"] = "A test of the rules"
	ground["unlock"] = unlock
	return ground


## A fresh content copy with the test ground added and validated.
func _with_ground(unlock := {"reached": "rusted_corner"}) -> ContentDB:
	var copy := ContentDB.load_all()
	copy.areas[GROUND] = _ground(copy, unlock)
	copy.errors.clear()
	copy.validate()
	return copy


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.content.areas[GROUND] = _ground(game.content, {"reached": "rusted_corner"})
	return game


func _done(game: Game) -> void:
	game.content.areas.erase(GROUND)
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _rides(menu: Control) -> Array[String]:
	var out: Array[String] = []
	for button: Button in menu.find_children("Ride_*", "Button", true, false):
		out.append(button.name.trim_prefix("Ride_"))
	return out


func test_kinds_and_regions_come_from_the_existing_data() -> void:
	var c := _content()
	assert_eq(c.errors, PackedStringArray(), "the shipped data validates")
	for area_id in StreetMemory.street(c):
		assert_eq(AreaRules.kind(c, area_id), AreaRules.STREET, area_id + " is street")
		assert_true(AreaRules.region(c, area_id) != "", area_id + " has a region")
	assert_eq(AreaRules.kind(c, c.city_area), AreaRules.CITY, "the city")
	assert_eq(AreaRules.region(c, c.city_area), "", "the city is in no district")
	for boss: String in c.world_bosses:
		var arena := str(WorldBossRules.spec(c, boss)["area"])
		assert_eq(AreaRules.kind(c, arena), AreaRules.WORLD_BOSS, arena + " is a world boss arena")
	assert_eq(AreaRules.region(c, "saltmarket"), "South Street", "Saltmarket's district")
	assert_eq(AreaRules.region(c, "port_road"), "Port District", "Port Road's district")


func test_only_farming_grounds_carry_the_new_fields() -> void:
	var c := _content()
	for area_id: String in c.areas:
		if AreaRules.kind(c, area_id) == AreaRules.FARM:
			continue
		var area := c.area(area_id)
		for field in ["kind", "region", "unlock", "purpose"]:
			assert_true(not area.has(field), "%s has no %s (derived)" % [area_id, field])
	var profile := PlayerProfile.new_game(c)
	assert_eq(AreaRules.open_farms(profile, c), [] as Array[String], "a new hero has none open")


func test_a_ground_opens_once_its_story_area_is_reached() -> void:
	var c := _with_ground()
	assert_eq(c.errors, PackedStringArray(), "a well-formed ground validates")
	assert_eq(AreaRules.kind(c, GROUND), AreaRules.FARM, "a farming ground")
	assert_eq(AreaRules.region(c, GROUND), "South Street", "its region")
	assert_true(GROUND in AreaRules.farms(c), "listed")
	assert_true(GROUND not in StreetMemory.street(c), "off the street")
	assert_eq(StreetMemory.street(c), StreetMemory.street(_content()), "the street is unchanged")
	var profile := PlayerProfile.new_game(c)
	assert_true(not AreaRules.unlocked(profile, c, GROUND), "closed at first")
	assert_eq(MapRules.state(profile, c, GROUND, "depot_yard"), MapRules.UNKNOWN, "unknown")
	assert_eq(AreaRules.unlock_text(c, GROUND), "Reach Rusted Corner", "what opens it")
	StreetMemory.visit(profile, "canal_works")
	assert_true(not AreaRules.unlocked(profile, c, GROUND), "not by another area")
	StreetMemory.visit(profile, "rusted_corner")
	assert_true(AreaRules.unlocked(profile, c, GROUND), "open once Rusted Corner is reached")
	assert_true(GROUND in AreaRules.open_farms(profile, c), "open")
	assert_eq(MapRules.state(profile, c, GROUND, "depot_yard"), MapRules.KNOWN, "on the map")


func test_a_ground_can_open_on_a_boss_defeat() -> void:
	var c := _with_ground({"defeated": "director_wiroj"})
	assert_eq(c.errors, PackedStringArray(), "validates")
	assert_eq(AreaRules.unlock_text(c, GROUND), "Defeat Director Wiroj", "what opens it")
	var profile := PlayerProfile.new_game(c)
	for area_id in StreetMemory.street(c):
		StreetMemory.visit(profile, area_id)
	assert_true(not AreaRules.unlocked(profile, c, GROUND), "reaching every area is not enough")
	profile.defeated["director_wiroj"] = 1
	assert_true(AreaRules.unlocked(profile, c, GROUND), "open once Director Wiroj is down")


func test_the_unlock_survives_a_save_and_load() -> void:
	var c := _with_ground()
	var profile := PlayerProfile.new_game(c)
	StreetMemory.visit(profile, "rusted_corner")
	var data := profile.to_dict()
	assert_eq(int(data["version"]), PlayerProfile.SAVE_VERSION, "no new save version")
	var loaded := PlayerProfile.from_dict(data, c)
	assert_true(AreaRules.unlocked(loaded, c, GROUND), "still open after loading")
	profile.area = GROUND
	var inside := PlayerProfile.from_dict(profile.to_dict(), c)
	assert_eq(inside.area, GROUND, "a save made in a ground loads there")
	assert_true(AreaRules.unlocked(inside, c, GROUND), "and it stays open")


func test_the_validator_keeps_grounds_off_the_street_and_one_way() -> void:
	var cases := {
		"its one way out is west to main_city": func(g: Dictionary) -> void: g["exits"] = {},
		"not a safe area": func(g: Dictionary) -> void: g["safe"] = true,
		"no rest in a farming ground": func(g: Dictionary) -> void: g["heal_on_enter"] = true,
		".region: required": func(g: Dictionary) -> void: g.erase("region"),
		".region: a district name": func(g: Dictionary) -> void: g["region"] = "Nowhere",
		".purpose: say what it is for": func(g: Dictionary) -> void: g["purpose"] = "",
		".unlock: one of": func(g: Dictionary) -> void: g["unlock"] = {"quest": "x"},
		".unlock.reached: a story area":
		func(g: Dictionary) -> void: g["unlock"] = {"reached": "main_city"},
		".unlock.defeated: a boss":
		func(g: Dictionary) -> void: g["unlock"] = {"defeated": "smogling"},
		".kind: one of": func(g: Dictionary) -> void: g["kind"] = "dungeon",
	}
	for expected: String in cases:
		var copy := ContentDB.load_all()
		var ground := _ground(copy, {"reached": "rusted_corner"})
		(cases[expected] as Callable).call(ground)
		copy.areas[GROUND] = ground
		copy.errors.clear()
		copy.validate()
		var all := "\n".join(copy.errors)
		assert_true(expected in all, "rejects: %s" % expected)
	var into := ContentDB.load_all()
	into.areas[GROUND] = _ground(into, {"reached": "rusted_corner"})
	into.areas["great_drain"]["exits"]["west"]["to"] = GROUND
	into.errors.clear()
	into.validate()
	assert_true("leads into it" in "\n".join(into.errors), "nothing leads into a ground")
	var to_story := ContentDB.load_all()
	to_story.areas[GROUND] = _ground(to_story, {"reached": "rusted_corner"})
	to_story.areas[GROUND]["exits"]["west"]["to"] = "depot_yard"
	to_story.areas["great_drain"]["exits"]["west"]["to"] = "depot_yard"
	to_story.errors.clear()
	to_story.validate()
	var out := "\n".join(to_story.errors)
	assert_true(GROUND + ": its one way out is west to main_city" in out, "no way out to the story")
	assert_true("great_drain: its one way out is west to main_city" in out, "nor from an arena")
	var walk_in := ContentDB.load_all()
	walk_in.areas["saltmarket"]["exits"]["west"]["to"] = "main_city"
	walk_in.errors.clear()
	walk_in.validate()
	assert_true("saltmarket leads into the city" in "\n".join(walk_in.errors), "story: taxi only")
	var mislabelled := ContentDB.load_all()
	mislabelled.areas["saltmarket"]["kind"] = "city"
	mislabelled.areas["depot_yard"]["unlock"] = {"reached": "saltmarket"}
	mislabelled.errors.clear()
	mislabelled.validate()
	var said := "\n".join(mislabelled.errors)
	assert_true("city is city_area" in said, "only the city is a city")
	assert_true("only a farming ground has one" in said, "only grounds have unlock rules")


func test_wins_taxi_shows_farming_only_once_a_ground_is_open() -> void:
	var game := _game()
	game.profile.money = 100
	var win: Dictionary = game.content.area("main_city")["npcs"][0]
	assert_eq(str(win["role"]), "travel", "Win in the city")
	game.enter_area("main_city", "west")
	game._show("travel", GameMenus.travel(game, win))
	assert_true(game.menu.find_child("Heading_Farming", true, false) == null, "no Farming yet")
	assert_true(GROUND not in _rides(game.menu), "no ride to a closed ground")
	game.close_menu()
	StreetMemory.visit(game.profile, "rusted_corner")
	game._show("travel", GameMenus.travel(game, win))
	assert_true(game.menu.find_child("Heading_Farming", true, false) != null, "Farming heading")
	assert_true(GROUND in _rides(game.menu), "a ride to the ground")
	game.close_menu()
	game._ride(win, GROUND)
	assert_eq(game.zone.area_id, GROUND, "rode to the ground")
	assert_eq(game.profile.money, 90, "for Win's usual 10 coins")
	assert_true(game.zone.hero.position.x < 200.0, "arrives at its west end")
	_done(game)


func test_the_storys_taxis_never_ride_to_a_ground_or_a_world_boss() -> void:
	var game := _game()
	game.profile.money = 100
	StreetMemory.visit(game.profile, "rusted_corner")
	game.profile.level = 60
	for area_id: String in game.content.areas:
		for npc: Dictionary in game.content.area(area_id).get("npcs", []):
			if npc.get("role") != "travel" or area_id == game.content.city_area:
				continue
			game.enter_area(area_id, "west")
			game._show("travel", GameMenus.travel(game, npc))
			var said := area_id + ": story taxi"
			assert_true(game.menu.find_child("Heading_Farming", true, false) == null, said)
			assert_true(game.menu.find_child("Heading_World Bosses", true, false) == null, said)
			assert_true(game.menu.find_child("Ride_main_city", true, false) != null, said)
			game.close_menu()
	_done(game)


func test_a_ground_is_left_west_to_the_city_or_by_recall_or_the_pause_menu() -> void:
	var game := _game()
	StreetMemory.visit(game.profile, "rusted_corner")
	game.enter_area(GROUND, "west")
	assert_eq(game.zone.recall_problem(), "", "Recall works in a ground")
	assert_eq(game.city_problem(), "", "so does the pause menu's ride to the city")
	game.zone.hero.position = Vector2(game.zone.bounds.position.x + 2.0, ROAD_Y)
	var input := FighterInput.new()
	input.move = Vector2.LEFT
	for i in 30:
		game.step(input)
		if game.zone.area_id != GROUND:
			break
	assert_eq(game.zone.area_id, "main_city", "walked out west into the city")
	assert_true(game.zone.hero.position.x < 200.0, "at the taxi rank")
	assert_eq(game.content.area("main_city")["exits"].keys(), ["east"], "one way: no way back")
	game.enter_area(GROUND, "west")
	game._recall()
	assert_eq(game.zone.area_id, "depot_yard", "Recall goes home")
	game.enter_area(GROUND, "west")
	game._go_to_city()
	assert_eq(game.zone.area_id, game.content.city_area, "the pause menu goes to the city")
	_done(game)


func test_the_map_lists_open_grounds_under_farming() -> void:
	var game := _game()
	game.open_screen("map")
	assert_true(game.menu.find_child("Area_" + GROUND, true, false) == null, "closed: no row")
	game.close_menu()
	StreetMemory.visit(game.profile, "rusted_corner")
	game.open_screen("map")
	assert_true(game.menu.find_child("Area_" + GROUND, true, false) != null, "open: on the map")
	game.close_menu()
	_done(game)
