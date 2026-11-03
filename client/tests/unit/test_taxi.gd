extends TestCase
## Win's taxi (GameMenus.travel): a group on the left, its places on the
## right. Late in the story it holds forty-odd rides; the picker keeps every
## one a few presses away and the whole dialog on the 640x360 canvas.

const TEST_SAVE := "user://test_taxi_save"
const SCREEN := Rect2(0, 0, 640, 360)


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _settle(size := Vector2i(1280, 720)) -> void:
	tree.root.size = size
	await tree.process_frame
	await tree.process_frame


## Every area reached and every boss beaten: every ride Win has.
func _late(game: Game) -> void:
	for area_id in StreetMemory.street(game.content):
		StreetMemory.visit(game.profile, area_id)
	for enemy_id: String in game.content.enemies:
		if game.content.enemy(enemy_id).get("boss", false):
			game.profile.defeated[enemy_id] = 1
	game.profile.money = 1000


## Win's rank in the city, the only taxi (the story's areas have none); the
## hero is taken there first.
func _win(game: Game) -> Dictionary:
	if game.zone.area_id != game.content.city_area:
		game.enter_area(game.content.city_area, "west")
	for npc: Dictionary in game.content.area(game.content.city_area)["npcs"]:
		if npc.get("role") == "travel":
			return npc
	return {}


func _tabs(menu: Control) -> Array[String]:
	var out: Array[String] = []
	var groups: Node = menu.find_child("Groups", true, false)
	for tab: Button in groups.get_children():
		out.append(tab.name.trim_prefix("Heading_"))
	return out


func _shown(menu: Control) -> Array[String]:
	var out: Array[String] = []
	for ride: Button in menu.find_children("Ride_*", "Button", true, false):
		if ride.is_visible_in_tree():
			out.append(ride.name.trim_prefix("Ride_"))
	return out


func test_late_in_the_story_the_rides_come_in_groups() -> void:
	var game := _game()
	_late(game)
	game._show("travel", GameMenus.travel(game, _win(game)))
	await _settle()
	var expected: Array[String] = []
	for district in MapRules.districts(game.content):
		expected.append(str(district["name"]).validate_node_name())
	expected.append_array(["Farming", "World Bosses"])
	assert_eq(_tabs(game.menu), expected, "the six districts, farming, world bosses")
	var all := game.menu.find_children("Ride_*", "Button", true, false).size()
	assert_eq(all, 31 + 7 + 3, "the whole street, every ground and every world boss")
	var south: Button = game.menu.find_child("Heading_South Street", true, false)
	assert_true("South Street  11" in south.text, "each group says how many: " + south.text)
	assert_eq(_shown(game.menu).size(), 4, "only one group's rides show at once")
	assert_true("core_chamber" in _shown(game.menu), "it opens where the story is furthest")
	var focused := game.get_viewport().gui_get_focus_owner()
	assert_true(focused != null and focused.name == "Ride_core_approach", "its first ride focused")
	_done(game)


func test_any_ride_is_a_few_presses_away() -> void:
	var game := _game()
	_late(game)
	game._show("travel", GameMenus.travel(game, _win(game)))
	await _settle()
	var last: Button = game.menu.find_child("Heading_Main Control Centre", true, false)
	last.grab_focus()
	await tree.process_frame
	assert_true("core_chamber" in _shown(game.menu), "focusing a group shows its places")
	assert_true("saltmarket" not in _shown(game.menu), "and hides the others'")
	last.pressed.emit()
	await tree.process_frame
	var focused := game.get_viewport().gui_get_focus_owner()
	assert_true(focused != null and focused.name.begins_with("Ride_"), "pressing it goes in")
	var chamber: Button = game.menu.find_child("Ride_core_chamber", true, false)
	chamber.pressed.emit()
	assert_eq(game.zone.area_id, "core_chamber", "and a ride takes the hero there")
	assert_eq(game.profile.money, 990, "for the fare")
	_done(game)


func test_the_late_game_taxi_fits_every_screen_without_scrolling_a_group() -> void:
	var game := _game()
	_late(game)
	game._show("travel", GameMenus.travel(game, _win(game)))
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(360, 640)]:
		await _settle(size)
		var visible := game.get_viewport().get_visible_rect()
		var dialog: Control = game.menu.find_child("Dialog", true, false)
		assert_true(visible.grow(1).encloses(dialog.get_global_rect()), "dialog fits %s" % size)
		for name in ["GroupScroll", "Scroll"]:
			var box: Control = game.menu.find_child(name, true, false)
			assert_true(
				visible.grow(1).encloses(box.get_global_rect()), "%s fits %s" % [name, size]
			)
		var tabs := game.menu.find_child("GroupScroll", true, false) as ScrollContainer
		for tab: Button in game.menu.find_child("Groups", true, false).get_children():
			var rect := tab.get_global_rect()
			assert_true(tabs.get_global_rect().grow(1).encloses(rect), "%s shows whole" % tab.name)
		var places := game.menu.find_child("Scroll", true, false) as ScrollContainer
		for group: Node in game.menu.find_child("Places", true, false).get_children():
			var tab := game.menu.find_child(
				"Heading_" + group.name.trim_prefix("Group_"), true, false
			)
			(tab as Button).grab_focus()
			await tree.process_frame
			for ride: Button in group.get_children():
				var rect := ride.get_global_rect()
				assert_true(places.get_global_rect().grow(1).encloses(rect), "%s whole" % ride.name)
				# Its whole name shows: the button is as wide as its text needs.
				var needs := ride.get_theme_font("font").get_string_size(
					ride.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ride.get_theme_font_size("font_size")
				)
				assert_true(
					ride.size.x >= needs.x, "%s reads in full (%s)" % [ride.name, ride.text]
				)
	await _settle()
	_done(game)


func test_in_the_city_it_opens_on_the_furthest_district() -> void:
	var game := _game()
	_late(game)
	game._go_to_city()
	var win: Dictionary = {}
	for npc: Dictionary in game.content.area(game.content.city_area)["npcs"]:
		if npc.get("role") == "travel":
			win = npc
	game._show("travel", GameMenus.travel(game, win))
	await _settle()
	assert_true("core_chamber" in _shown(game.menu), "the way back to where the story is")
	assert_true(game.menu.find_child("Heading_City", true, false) == null, "no ride to here")
	_done(game)


func test_without_the_fare_nothing_rides_and_the_group_keeps_the_focus() -> void:
	var game := _game()
	_late(game)
	game.profile.money = 0
	game._show("travel", GameMenus.travel(game, _win(game)))
	await _settle()
	for ride: Button in game.menu.find_children("Ride_*", "Button", true, false):
		if not game.content.world_bosses.has(ride.name.trim_prefix("Ride_")):
			assert_true(ride.disabled, ride.name + " needs the fare")
	var focused := game.get_viewport().gui_get_focus_owner()
	assert_true(focused != null and focused.name == "Heading_Main Control Centre", "on its group")
	_done(game)


func test_a_new_hero_sees_only_the_yard() -> void:
	var game := _game()
	game._show("travel", GameMenus.travel(game, _win(game)))
	await _settle()
	assert_eq(_tabs(game.menu), ["South Street"] as Array[String], "one group")
	assert_eq(_shown(game.menu), ["depot_yard"] as Array[String], "one ride: back to the story")
	_done(game)


func test_win_says_where_he_goes_and_every_ride_gets_there() -> void:
	var game := _game()
	_late(game)
	var win := _win(game)
	var line := str(win["line"])
	game._show("travel", GameMenus.travel(game, win))
	var said := false
	for label: Label in game.menu.find_children("*", "Label", true, false):
		said = said or label.text == '"%s"' % line
	assert_true(said, "Win's line, shown as said")
	var targets: Array[String] = []
	for ride: Button in game.menu.find_children("Ride_*", "Button", true, false):
		var target := ride.name.trim_prefix("Ride_")
		if not game.content.world_bosses.has(target):
			targets.append(target)
	game.close_menu()
	var expected: Array[String] = StreetMemory.destinations(
		game.profile, game.content, game.content.city_area
	)
	expected.append_array(AreaRules.open_farms(game.profile, game.content))
	targets.sort()
	expected.sort()
	assert_eq(targets, expected, "every story area reached and every open ground")
	for target in targets:
		game.enter_area(game.content.city_area, "west")
		game.profile.money = 100
		game._show("travel", GameMenus.travel(game, win))
		(game.menu.find_child("Ride_" + target, true, false) as Button).pressed.emit()
		assert_eq(game.zone.area_id, target, "the ride to %s gets there" % target)
		assert_eq(game.profile.money, 90, "%s: for the usual fare" % target)
	_done(game)
