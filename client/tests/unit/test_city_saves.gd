extends TestCase
## Iron City Central and saves: a save made off the story street (the city, a
## world boss arena) loads without unlocking anything it did not reach, saves
## on the street still know the road walked, and saves from versions 5 to 10
## load as before. Before the fix, loading a save made off the street marked
## the whole street reached: a level 1 hero could ride to the final chapter.
## Also the validator's rules that keep the city separate and safe.

const TEST_SAVE := "user://test_city_saves"
const CITY := "main_city"

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


func _done(game: Node) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_a_save_in_the_city_unlocks_nothing() -> void:
	var game := _game()
	game._go_to_city()
	var visited := game.profile.visited.duplicate()
	var saved := SaveStore.load_character(game.profile.id, game.content)
	assert_eq(saved.area, CITY, "loads in the city")
	assert_eq(saved.visited, visited, "with only the areas really reached")
	assert_true("core_chamber" not in saved.visited, "a level 1 hero rides nowhere late")
	assert_eq(
		StreetMemory.destinations(saved, game.content, CITY),
		["depot_yard"] as Array[String],
		"Win rides back to Depot Yard only"
	)
	_done(game)


func test_a_save_in_any_world_boss_arena_unlocks_nothing() -> void:
	for boss: String in _content().world_bosses:
		var profile := PlayerProfile.new_game(_content())
		for area_id in ["depot_yard", "saltmarket", "canal_works"]:
			StreetMemory.visit(profile, area_id)
		profile.area = str(WorldBossRules.spec(_content(), boss)["area"])
		var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
		assert_eq(loaded.area, profile.area, "%s: loads where it was saved" % boss)
		assert_eq(
			loaded.visited,
			["depot_yard", "saltmarket", "canal_works"] as Array[String],
			"%s: nothing new reached" % boss
		)


func test_a_save_on_the_street_still_knows_the_road_walked() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.area = "rail_yards"
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	for area_id in ["depot_yard", "saltmarket", "canal_works", "rusted_corner", "parking_lot"]:
		assert_true(area_id in loaded.visited, "%s was walked through" % area_id)
	assert_true("rail_yards" in loaded.visited, "the saved area")
	assert_true("night_market" not in loaded.visited, "nothing past it")


func test_saves_from_versions_5_to_10_load_as_before() -> void:
	for version in range(5, 11):
		var old := PlayerProfile.new_game(_content()).to_dict()
		old["version"] = version
		old["area"] = "night_market"
		if version < 6:
			# Version 6 added "cleared" and "visited".
			old.erase("cleared")
			old.erase("visited")
		else:
			old["visited"] = ["depot_yard", "saltmarket", "canal_works", "great_drain"]
		var loaded := PlayerProfile.from_dict(old, _content())
		assert_true(loaded != null, "a version %d save loads" % version)
		assert_eq(loaded.area, "night_market", "v%d: where it was saved" % version)
		var road := StreetMemory.street(_content())
		for area_id in road.slice(0, road.find("night_market") + 1):
			assert_true(area_id in loaded.visited, "v%d: %s reached" % [version, area_id])
		assert_true("fight_club" not in loaded.visited, "v%d: nothing past it" % version)
		assert_true(CITY not in loaded.visited, "v%d: the city is not invented" % version)
		if version >= 6:
			assert_true("great_drain" in loaded.visited, "v%d: saved places kept" % version)


func test_the_validator_keeps_the_city_separate_and_safe() -> void:
	var broken := ContentDB.load_all()
	broken.errors.clear()
	var city: Dictionary = broken.areas[CITY]
	city["safe"] = false
	city["encounters"] = [{"trigger_x": 300, "arena": [100, 700], "max_alive": 1, "waves": []}]
	city["exits"]["west"] = {"to": "saltmarket", "entry": "east"}
	broken.areas["saltmarket"]["exits"]["west"]["to"] = CITY
	city["landmarks"].append({"x": 99999, "text": ""})
	city["npcs"][1]["planned_services"] = [""]
	broken.validate()
	var all := "\n".join(broken.errors)
	for expected: String in [
		"the city must be safe",
		"no fights in the city",
		"its one way out is the gate east",
		"saltmarket leads into the city",
		"landmarks",
		"planned_services",
	]:
		assert_true(expected in all, expected)
	var start := ContentDB.load_all()
	start.errors.clear()
	start.city_area = start.start_area
	start.validate()
	assert_true("not the start area" in "\n".join(start.errors), "not Depot Yard")
