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
	assert_eq(here["services"], ["Shop", "Quests", "Taxi"], "the yard is a town")
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
	var spec := WorldBossRules.spec(_content(), "tunnel_mother")
	profile.defeated[str(spec["unlock"])] = 1
	assert_eq(MapRules.arenas(profile, _content()), ["great_drain"] as Array[String], "unlocked")
	assert_eq(
		MapRules.state(profile, _content(), "great_drain", "depot_yard"), MapRules.KNOWN, "known"
	)


func test_the_goal_follows_the_quest_chain_to_the_end() -> void:
	var profile := PlayerProfile.new_game(_content())
	var goal := MapRules.goal(profile, _content())
	assert_eq(goal["area"], "depot_yard", "the first quest's giver")
	assert_eq(goal["text"], "New quest from Chief Odo", "who to see")
	QuestRules.accept(profile, "clear_saltmarket", _content())
	assert_eq(MapRules.goal(profile, _content())["area"], "saltmarket", "the quest's area")
	profile.quests["clear_saltmarket"]["state"] = "complete"
	goal = MapRules.goal(profile, _content())
	assert_eq([goal["area"], goal["text"]], ["depot_yard", "Report to Chief Odo"], "hand in")
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
	broken.quests["warden"]["objective"]["area"] = "port_road"
	broken.validate()
	var all := "\n".join(broken.errors)
	assert_true(all.contains("districts[6].name: required"), "unnamed district")
	assert_true(all.contains("districts[6].from: an area further east"), "out of order")
	assert_true(all.contains("quests.warden.objective.area: port_road"), "wrong quest area")


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
	assert_eq(rows.size(), StreetMemory.street(game.content).size(), "every street area")
	_done(game)


func test_hud_strip_opens_the_map() -> void:
	var game := _game()
	await _settle()
	var strip: MiniMap = game.find_child("MiniMap", true, false)
	assert_true(strip != null and strip.is_visible_in_tree(), "the strip is on the HUD")
	assert_true(strip.tooltip_text.begins_with("South Street  1 / 11"), "says where")
	var first := strip._get_tooltip(strip.node_at(0))
	assert_true(first.begins_with("Depot Yard  Lv 1"), "a node names its area (%s)" % first)
	var district := MapRules.districts(game.content)[0]["areas"] as Array
	var last := strip._get_tooltip(strip.node_at(district.size() - 1))
	assert_true(MapRules.boss_of(game.content, district[-1]) != "", "the district ends on a boss")
	assert_true(last.contains("boss"), "and its node says so before it is reached (%s)" % last)
	assert_true(not last.contains("Lv"), "without giving away more")
	assert_true(SCREEN.encloses(strip.get_global_rect()), "the card is on screen")
	strip.pressed.emit()
	assert_eq(game.menu_name, "map", "a tap opens the map")
	_done(game)
