extends TestCase
## Losing a fight costs coins, not the whole road back: a knocked-out hero gets
## up in the same area (just short of a boss fight they lost), fights already
## won stay won until a rest at the Depot brings them all back for farming, and
## the motorbike taxi rides to any area reached before.

const TEST_SAVE := "user://test_checkpoint_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _profile() -> PlayerProfile:
	return PlayerProfile.new_game(_content())


func _game() -> Node2D:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _win_first_fight(zone: ZoneSim) -> void:
	var events: Array[ZoneEvent] = []
	zone._start_encounter(0, events)
	zone._spawn_queue.clear()
	zone._waves_left.clear()
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone.tick(FighterInput.new())


func test_a_won_fight_stays_won() -> void:
	var profile := _profile()
	var zone := ZoneSim.new(_content(), profile, "saltmarket", "west", 3)
	_win_first_fight(zone)
	assert_true(StreetMemory.is_cleared(profile, "saltmarket", 0), "remembered")
	var again := ZoneSim.new(_content(), profile, "saltmarket", "west", 4)
	assert_eq(again._encounters[0]["state"], "cleared", "not fought again")
	assert_eq(again._encounters[1]["state"], "pending", "the next fight still waits")


func test_resting_at_the_depot_brings_every_fight_back() -> void:
	var profile := _profile()
	StreetMemory.mark_cleared(profile, "saltmarket", 0)
	StreetMemory.mark_cleared(profile, "rail_yards", 2)
	ZoneSim.new(_content(), profile, "depot_yard", "", 3)
	assert_true(profile.cleared.is_empty(), "every street fills up again to farm")


func test_a_shut_gate_always_has_fights_left() -> void:
	var profile := _profile()
	for i in _content().area("rat_nest")["encounters"].size():
		StreetMemory.mark_cleared(profile, "rat_nest", i)
	var zone := ZoneSim.new(_content(), profile, "rat_nest", "west", 3)
	for entry: Dictionary in zone._encounters:
		assert_eq(entry["state"], "pending", "the Tar Rats come back while the gate is shut")
	profile.defeated["tar_hound"] = 12
	for i in _content().area("rat_nest")["encounters"].size():
		StreetMemory.mark_cleared(profile, "rat_nest", i)
	zone = ZoneSim.new(_content(), profile, "rat_nest", "west", 3)
	assert_eq(zone._encounters[0]["state"], "cleared", "with the gate open, won fights stay won")


func test_every_gate_opens_in_one_pass() -> void:
	for area_id: String in _content().areas:
		var area: Dictionary = _content().area(area_id)
		var requires: Dictionary = area["exits"].get("east", {}).get("requires", {})
		if requires.is_empty():
			continue
		var guards := 0
		for encounter: Dictionary in area["encounters"]:
			for wave: Array in encounter["waves"]:
				guards += wave.count(requires["defeat"])
		assert_true(
			guards >= int(requires["count"]),
			"%s holds %d of the %d guards its gate needs" % [area_id, guards, requires["count"]]
		)


func test_a_knock_out_wakes_you_in_the_city() -> void:
	var content := _content()
	assert_eq(AreaRules.wake_area(content, "canal_works"), "main_city", "from the street")
	assert_eq(AreaRules.wake_area(content, "farm_rail_sidings"), "main_city", "from a farm")
	assert_eq(AreaRules.wake_area(content, "main_city"), "main_city", "in the city itself")
	assert_eq(AreaRules.wake_area(content, "depot_yard"), "depot_yard", "the tutorial yard")


func test_getting_up_in_the_city_keeps_the_story() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	_win_first_fight(game.zone)
	game.zone.hero.hp = 0
	game.open_game_over()
	game._recover()
	assert_eq(game.zone.area_id, "main_city", "back on your feet in the city")
	assert_true("saltmarket" in game.profile.visited, "the street stays reached (taxi)")
	assert_true(StreetMemory.is_cleared(game.profile, "saltmarket", 0), "the won fight is kept")
	var saved := SaveStore.load_character(game.profile.id, _content())
	assert_true(StreetMemory.is_cleared(saved, "saltmarket", 0), "and saved")
	game.enter_area("saltmarket", "west")
	assert_eq(game.zone._encounters[0]["state"], "cleared", "riding back, it is still won")
	_done(game)


func test_the_taxi_rides_only_where_you_have_been() -> void:
	var profile := _profile()
	StreetMemory.visit(profile, "depot_yard")
	StreetMemory.visit(profile, "night_market")
	StreetMemory.visit(profile, "saltmarket")
	assert_eq(
		StreetMemory.destinations(profile, _content(), "depot_yard"),
		["saltmarket", "night_market"] as Array[String],
		"reached areas in street order, not here"
	)


func test_a_ride_costs_the_fare() -> void:
	var game := _game()
	StreetMemory.visit(game.profile, "saltmarket")
	game.enter_area("main_city", "west")
	var taxi: Dictionary = {}
	for npc: Dictionary in game.zone.area["npcs"]:
		if npc["role"] == "travel":
			taxi = npc
	assert_true(not taxi.is_empty(), "a taxi waits in the city")
	game.profile.money = 5
	game._ride(taxi, "saltmarket")
	assert_eq(game.zone.area_id, "main_city", "too poor to ride")
	game.profile.money = 50
	game._ride(taxi, "saltmarket")
	assert_eq(game.zone.area_id, "saltmarket", "rode there")
	assert_eq(game.profile.money, 50 - int(taxi["fare"]), "paid the fare")
	_done(game)


func test_old_saves_know_the_road_they_walked() -> void:
	var old := _profile().to_dict()
	old["version"] = 5
	old.erase("cleared")
	old.erase("visited")
	old["area"] = "rail_yards"
	var loaded := PlayerProfile.from_dict(old, _content())
	assert_true(loaded != null, "a version 5 save loads")
	for area_id in ["depot_yard", "saltmarket", "canal_works", "rusted_corner", "parking_lot"]:
		assert_true(area_id in loaded.visited, "%s was walked through" % area_id)
	assert_true("night_market" not in loaded.visited, "nothing past the saved area")
	assert_true(loaded.cleared.is_empty(), "every fight ready")
