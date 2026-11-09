extends TestCase
## The city map (MapRules, MapTab, MiniMap): districts cover the street,
## the hero knows only what they have reached plus the way on, the goal
## follows the quest chain, and the Map tab and HUD strip show it all.

const TEST_SAVE := "user://test_map_save"
const SCREEN := Rect2(0, 0, 640, 360)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(node: Node) -> void:
	node.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _settle() -> void:
	tree.root.size = Vector2i(1280, 720)
	await tree.process_frame
	await tree.process_frame


func test_districts_cover_the_street_once_in_order() -> void:
	var covered: Array[String] = []
	var names: Array[String] = []
	for district in MapRules.districts(_content()):
		names.append(str(district["name"]))
		for area_id: String in district["areas"]:
			covered.append(area_id)
	assert_eq(covered, StreetMemory.street(_content()), "every street area, once, west to east")
	assert_eq(names.size(), _content().districts.size(), "one row per district")
	assert_eq(names[0], "South Street", "the street starts in South Street")
	var spot := MapRules.locate(_content(), "saltmarket")
	assert_eq([spot["name"], spot["index"]], ["South Street", 1], "Saltmarket is second")
	assert_eq(MapRules.locate(_content(), "port_road")["index"], 0, "Port Road starts its own")
	assert_eq(MapRules.locate(_content(), "great_drain"), {}, "arenas are off the street")


func test_the_hero_knows_what_they_reached_and_the_way_on() -> void:
	var profile := PlayerProfile.new_game(_content())
	var here := MapRules.about(profile, _content(), "depot_yard", "depot_yard")
	assert_eq(here["state"], MapRules.HERE, "standing in the yard")
	assert_eq(here["services"], ["Quests"], "the yard is a rest point: quests only")
	var next := MapRules.about(profile, _content(), "saltmarket", "depot_yard")
	assert_eq(next["state"], MapRules.IN_SIGHT, "the next area is in sight")
	assert_eq([next["name"], next["level"]], ["Saltmarket Street", 2], "named, with its level")
	assert_eq(next["gate"], "", "but nothing more")
	var far := MapRules.about(profile, _content(), "canal_works", "depot_yard")
	assert_eq([far["state"], far["name"], far["level"]], [MapRules.UNKNOWN, "???", 0], "unknown")
	StreetMemory.visit(profile, "saltmarket")
	var street := MapRules.about(profile, _content(), "saltmarket", "depot_yard")
	assert_eq(street["state"], MapRules.KNOWN, "reached")
	assert_true(str(street["gate"]).contains("Smog Warden"), "its shut gate says why")
	profile.defeated["smog_warden"] = 1
	assert_eq(MapRules.about(profile, _content(), "saltmarket", "")["gate"], "", "gate open")
	var canal := MapRules.about(profile, _content(), "canal_works", "depot_yard")
	assert_eq(canal["state"], MapRules.IN_SIGHT, "the way on moves east")
	StreetMemory.visit(profile, "canal_works")
	canal = MapRules.about(profile, _content(), "canal_works", "depot_yard")
	assert_eq([canal["boss"], canal["beaten"]], ["The Sludge Foreman", false], "its boss")


func test_world_boss_arenas_appear_once_unlocked() -> void:
	var profile := PlayerProfile.new_game(_content())
	assert_eq(MapRules.arenas(profile, _content()), [] as Array[String], "none at first")
	assert_eq(
		MapRules.state(profile, _content(), "great_drain", "depot_yard"),
		MapRules.UNKNOWN,
		"the arena next to the yard stays hidden"
	)
	profile.level = 10
	var all: Array[String] = []
	for boss: String in _content().world_bosses:
		all.append(str(WorldBossRules.spec(_content(), boss)["area"]))
	assert_eq(MapRules.arenas(profile, _content()), all, "every arena from level 10")
	assert_eq(
		MapRules.state(profile, _content(), "great_drain", "depot_yard"), MapRules.KNOWN, "known"
	)


func test_the_goal_follows_the_quest_chain_to_the_end() -> void:
	var profile := PlayerProfile.new_game(_content())
	var goal := MapRules.goal(profile, _content())
	# Taken and claimed from the quest card, wherever the hero is (QuestFlow).
	assert_eq(goal["area"], "", "no walk to a giver")
	assert_eq(goal["text"], "New quest: The Sludge Foreman (F)", "accept it from the card")
	QuestRules.accept(profile, "foreman", _content())
	assert_eq(MapRules.goal(profile, _content())["area"], "canal_works", "the quest's area")
	profile.quests["foreman"]["state"] = "complete"
	goal = MapRules.goal(profile, _content())
	assert_eq([goal["area"], goal["text"]], ["", "Claim your reward (F)"], "claim it there")
	for quest_id: String in _content().quests:
		profile.quests[quest_id] = {"state": "turned_in", "progress": 0}
	assert_eq(MapRules.goal(profile, _content()), {}, "nothing left")


func test_every_quest_points_on_from_its_giver() -> void:
	var street := StreetMemory.street(_content())
	for quest_id: String in _content().quests:
		var quest: Dictionary = _content().quests[quest_id]
		var at := street.find(str(quest["objective"]["area"]))
		var giver := street.find(MapRules.giver_area(_content(), str(quest["giver"])))
		assert_true(at >= 0, "%s: its area is on the street" % quest_id)
		assert_true(giver >= 0 and giver <= at, "%s: never back west of its giver" % quest_id)


func test_validator_checks_districts_and_quest_areas() -> void:
	var broken := ContentDB.load_all()
	broken.errors.clear()
	broken.districts.append({"name": "", "from": "depot_yard"})
	broken.quests["foreman"]["objective"]["area"] = "port_road"
	broken.validate()
	var all := "\n".join(broken.errors)
	assert_true(all.contains("districts[6].name: required"), "unnamed district")
	assert_true(all.contains("districts[6].from: an area further east"), "out of order")
	assert_true(all.contains("quests.foreman.objective.area: port_road"), "wrong quest area")


func test_map_tab_opens_on_the_hero_and_fits() -> void:
	var game := _game()
	game.open_screen("map")
	await _settle()
	assert_eq(game.menu_name, "map", "reported as the map")
	for node in game.menu.find_children("*", "Control", true, false):
		var control: Control = node
		if control.is_visible_in_tree() and (control is Button or control is Label):
			assert_true(
				SCREEN.grow(1).encloses(control.get_global_rect()),
				"%s %s fits on screen" % [control.get_class(), control.name]
			)
	var owner := tree.root.gui_get_focus_owner()
	assert_true(owner != null and owner.name == "Area_depot_yard", "starts on the hero")
	var heading: Label = game.menu.find_child("Heading", true, false)
	assert_true(heading.text.begins_with("Depot Yard"), "shows where the hero is")
	var rows := game.menu.find_children("Area_*", "MapNode", true, false)
	# On the street, the story only (the owner's rule).
	assert_eq(rows.size(), StreetMemory.street(game.content).size(), "every street area")
	assert_true(
		game.menu.find_child("Area_" + game.content.city_area, true, false) == null,
		"the city waits for the city"
	)
	_done(game)


func test_the_city_map_shows_every_section_apart_and_fits_late_in_the_game() -> void:
	var game := _late_game()
	game._go_to_city()
	game.open_screen("map")
	await _settle()
	var map: Node = game.menu.find_child("Map", true, false)
	var story: Label = map.find_child("Section_story", false, false)
	var hub: Label = map.find_child("Section_hub", false, false)
	assert_true(story != null and hub != null, "the story, then everything off the street")
	assert_true("IRON CITY CENTRAL" in hub.text, "the hub is named: " + hub.text)
	assert_true(map.find_child("OnlyHere", false, false) == null, "everything in the city")
	for row in ["Row_City", "Row_Farming", "Row_World_Bosses"]:
		var title := map.find_child(row, true, false) as Label
		assert_true(title != null, row + ": a category of its own")
		var colour := title.get_theme_color("font_color")
		assert_true(colour != UiTheme.TEXT_DIM, row + ": in its own colour")
	var order: Array[String] = []
	for child in map.get_children():
		var areas := child.find_children("Area_*", "MapNode", true, false)
		if child == story or child == hub:
			order.append(child.name)
		elif not areas.is_empty():
			order.append(areas[0].name)
	var split := order.find("Section_hub")
	assert_eq(order[0], "Section_story", "the story comes first")
	assert_true(order.find("Area_depot_yard") < split, "the street is in the story")
	for area_id: String in [game.content.city_area, "farm_saltmarket_backlots", "great_drain"]:
		assert_true(order.find("Area_" + area_id) > split, area_id + ": off the street")
	for node in game.menu.find_children("*", "Control", true, false):
		var control: Control = node
		if control.is_visible_in_tree() and (control is Button or control is Label):
			assert_true(
				SCREEN.grow(1).encloses(control.get_global_rect()),
				"%s %s fits on screen" % [control.get_class(), control.name]
			)
	var ground: Control = game.menu.find_child("Area_farm_facility_annex", true, false)
	ground.grab_focus()
	var heading: Label = game.menu.find_child("Heading", true, false)
	assert_true("Uncle Thong's truck in Iron City Central" in heading.text, "how to get there")
	_done(game)


func test_away_from_the_city_the_map_shows_only_where_the_hero_is() -> void:
	# The owner's rule: the story on the street, the grounds in a ground, the
	# arenas in an arena.
	var game := _late_game()
	var cases := {
		"saltmarket": "Section_story",
		"farm_core_overflow": "Section_farming",
	}
	for area_id: String in cases:
		game.enter_area(area_id, "west")
		assert_eq(game.zone.area_id, area_id, "in " + area_id)
		game.open_screen("map")
		await _settle()
		var map: Node = game.menu.find_child("Map", true, false)
		var sections: Array[String] = []
		for child in map.get_children():
			if str(child.name).begins_with("Section_"):
				sections.append(str(child.name))
		assert_eq(sections, [cases[area_id]] as Array[String], area_id + ": its section only")
		assert_true(map.find_child("OnlyHere", false, false) != null, area_id + ": says why")
		var own := map.find_child("Area_" + area_id, true, false)
		assert_true(own != null, area_id + ": the hero's own box is there")
		game.close_menu()
	assert_eq(MapTab.sections(game.content, "great_drain"), [MapTab.BOSSES], "an arena")
	assert_eq(MapTab.sections(game.content, "foundry_crucible"), [MapTab.FARMING], "a lair")
	_done(game)


func _late_game() -> Game:
	var game := _game()
	for area_id in StreetMemory.street(game.content):
		StreetMemory.visit(game.profile, area_id)
	for enemy_id: String in game.content.enemies:
		if game.content.enemy(enemy_id).get("boss", false):
			game.profile.defeated[enemy_id] = 1
	game.profile.level = 70
	return game


func test_the_route_marks_the_town_the_mini_bosses_and_the_boss() -> void:
	var content := GameSession.content
	var profile := PlayerProfile.new_game(content)
	var route := MapRules.route(profile, content, "depot_yard")
	assert_eq(route["name"], "South Street", "the district")
	assert_eq(route["here"], 0, "the hero at its first area")
	var kinds := {}
	for node: Dictionary in route["nodes"]:
		kinds[node["number"]] = node["kind"]
	assert_eq(kinds[1], MapRules.TOWN, "1: the town")
	assert_eq(kinds[3], MapRules.MINI_BOSS, "3: Canal Works' mini-boss")
	assert_eq(kinds[8], MapRules.MINI_BOSS, "8: the Fight Club's mini-boss")
	assert_eq(kinds[11], MapRules.BOSS, "11: the district's boss")
	assert_eq(kinds[2], MapRules.AREA, "2: a plain area")
	for district in MapRules.districts(content):
		var last: String = district["areas"][-1]
		assert_eq(MapRules.kind_of(content, last), MapRules.BOSS, "%s ends on its boss" % last)
	var unknown := MapRules.about(profile, content, "fight_club", "depot_yard")
	assert_eq(unknown["kind"], MapRules.MINI_BOSS, "known to hold a mini-boss before it is reached")
	assert_eq(unknown["boss"], "", "its name is not")
	profile.defeated["sludge_foreman"] = 1
	route = MapRules.route(profile, content, "depot_yard")
	assert_true(route["nodes"][2]["beaten"], "a beaten mini-boss is marked")
	assert_eq(MapRules.route(profile, content, "great_drain"), {}, "an arena has no route")


func test_hud_strip_opens_the_map() -> void:
	var game := _game()
	await _settle()
	var strip: MiniMap = game.find_child("MiniMap", true, false)
	assert_true(strip != null and strip.is_visible_in_tree(), "the strip is on the HUD")
	assert_true(strip.tooltip_text.begins_with("South Street  1 / 11"), "says where")
	var first := strip._get_tooltip(strip.node_at(0))
	assert_true(first.begins_with("1. Depot Yard  Lv 1"), "a node names its area (%s)" % first)
	var district := MapRules.districts(game.content)[0]["areas"] as Array
	var last := strip._get_tooltip(strip.node_at(district.size() - 1))
	assert_true(MapRules.boss_of(game.content, district[-1]) != "", "the district ends on a boss")
	assert_true(last.contains("boss"), "and its node says so before it is reached (%s)" % last)
	assert_true(not last.contains("Lv"), "without giving away more")
	var third := strip._get_tooltip(strip.node_at(2))
	assert_true(third.contains("A mini-boss waits here"), "a mini-boss shows early (%s)" % third)
	assert_true(not third.contains("Sludge"), "but not who it is")
	# The longest names stay on the card.
	for area_id: String in StreetMemory.street(game.content):
		game.enter_area(area_id, "west")
		await tree.process_frame
		var line := strip.header(strip.get_theme_default_font())
		assert_true(line["right"] <= strip.size.x - MiniMap.PAD + 0.5, "%s fits" % line["area"])
		assert_true(str(line["area"]).contains("Lv"), "%s: the level always shows" % area_id)
	assert_true(SCREEN.encloses(strip.get_global_rect()), "the card is on screen")
	strip.pressed.emit()
	assert_eq(game.menu_name, "map", "a tap opens the map")
	_done(game)
