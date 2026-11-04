extends TestCase
## The seven farming grounds (areas.json "kind": "farm", AreaRules): each is
## off the story street, opens on its approved unlock rule, is reached by
## Win's taxi for the usual fare, is left on foot west to Depot Yard (or by
## the pause menu's return to Iron City Central), fights only its own
## district's enemies (one elite, no boss, no Hybrid), draws its own scenery,
## and can be cleared. Fights come back on a rest, like the street's, and
## once all are won when the hero is back at the west end (test_farming_loop).
## Its level is a suggestion shown as such, never a requirement to enter.

const TEST_SAVE := "user://test_farming_grounds_save"
const ROAD_Y := 300.0
## Each ground: [region, unlock rule, the enemies it may use, its elite].
const GROUNDS := {
	"farm_saltmarket_backlots":
	[
		"South Street",
		{"reached": "rusted_corner"},
		["tar_hound", "pipe_brute", "street_thrower", "smogling", "smog_warden"],
		"smog_warden",
	],
	"farm_rail_sidings":
	[
		"South Street",
		{"reached": "refinery"},
		["rail_bruiser", "dock_thug", "market_punk", "refinery_enforcer"],
		"refinery_enforcer",
	],
	"farm_harbour_stacks":
	[
		"Port District",
		{"reached": "container_yard"},
		["stevedore", "dock_slinger", "dock_thug", "port_guard"],
		"port_guard",
	],
	"farm_plant_outskirts":
	[
		"Industrial District",
		{"reached": "waste_pools"},
		["patrol_unit", "hazmat_sprayer", "plant_guard"],
		"plant_guard",
	],
	"farm_network_backrooms":
	[
		"The Black Network",
		{"reached": "counting_house"},
		["network_runner", "network_enforcer", "ring_fighter"],
		"ring_fighter",
	],
	"farm_facility_annex":
	[
		"The Core Facility",
		{"reached": "machine_hall"},
		["facility_trooper", "hazmat_sprayer", "patrol_unit", "riot_trooper"],
		"riot_trooper",
	],
	"farm_core_overflow":
	[
		"Main Control Centre",
		{"defeated": "director_wiroj"},
		["facility_trooper", "patrol_unit", "core_sentinel"],
		"core_sentinel",
	],
}

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


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## A hero who has reached every story area and beaten every boss.
func _everything(profile: PlayerProfile) -> void:
	for area_id in StreetMemory.street(_content()):
		StreetMemory.visit(profile, area_id)
	for enemy_id: String in _content().enemies:
		if _content().enemy(enemy_id).get("boss", false):
			profile.defeated[enemy_id] = 1


## Who comes to a ground's living field (its "spawning" pool).
static func _kinds(area: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for kind: String in area["spawning"]["pool"]:
		out.append(kind)
	return out


## Uncle Thong's truck in the city: the farming grounds' and world bosses' rides.
func _truck(game: Game) -> Dictionary:
	for npc: Dictionary in game.content.area("main_city")["npcs"]:
		if npc.get("routes") == "field":
			return npc
	return {}


func test_the_seven_grounds_exist_with_their_approved_unlocks() -> void:
	var c := _content()
	assert_eq(c.errors, PackedStringArray(), "the data validates")
	var ids: Array = GROUNDS.keys()
	ids.sort()
	var farms: Array = AreaRules.farms(c)
	farms.sort()
	assert_eq(farms, ids, "exactly the seven grounds")
	for gid: String in GROUNDS:
		var area := c.area(gid)
		assert_eq(AreaRules.region(c, gid), GROUNDS[gid][0], gid + ": region")
		assert_eq(area["unlock"], GROUNDS[gid][1], gid + ": the approved unlock rule")
		assert_true(str(area.get("purpose", "")) != "", gid + ": a purpose")
		assert_true(gid not in StreetMemory.street(c), gid + ": off the street")
		assert_eq(
			area["exits"], {"west": {"to": c.city_area, "entry": "west"}}, gid + ": out to the city"
		)
	assert_eq(StreetMemory.street(c).size(), 31, "the story street is unchanged")


func test_each_ground_fights_only_its_districts_enemies() -> void:
	var c := _content()
	for gid: String in GROUNDS:
		var allowed: Array = GROUNDS[gid][2]
		var kinds := _kinds(c.area(gid))
		assert_true(kinds.size() > 0, gid + ": has fights")
		var elites := {}
		for kind in kinds:
			assert_true(kind in allowed, "%s: %s belongs here" % [gid, kind])
			assert_true(not c.enemy(kind).get("boss", false), "%s: no boss (%s)" % [gid, kind])
			assert_true(not kind.begins_with("hybrid"), "%s: no Hybrid (%s)" % [gid, kind])
			if c.enemy(kind).get("elite", false):
				elites[kind] = true
		assert_eq(elites.keys(), [GROUNDS[gid][3]], gid + ": its one elite")
		var camp := FarmSpawner.size_range(c.area(gid)["spawning"]).y
		assert_true(camp <= 4, gid + ": at most 4 come at once from one camp")


func test_each_ground_draws_its_own_scenery() -> void:
	var c := _content()
	for gid: String in GROUNDS:
		var holder := Node2D.new()
		assert_true(Scenery.build(holder, c, gid), gid + ": scenery builds")
		assert_true(c.kit["areas"].has(gid), gid + ": a kit layout")
		assert_true(c.environment["areas"].has(gid), gid + ": a generated sky")
		holder.free()


func test_each_ground_opens_only_on_its_rule() -> void:
	var c := _content()
	for gid: String in GROUNDS:
		var profile := PlayerProfile.new_game(c)
		assert_true(not AreaRules.unlocked(profile, c, gid), gid + ": closed at first")
		assert_eq(MapRules.state(profile, c, gid, "depot_yard"), MapRules.UNKNOWN, gid + ": unseen")
		var rule: Dictionary = GROUNDS[gid][1]
		if rule.has("reached"):
			StreetMemory.visit(profile, str(rule["reached"]))
		else:
			for area_id in StreetMemory.street(c):
				StreetMemory.visit(profile, area_id)
			assert_true(not AreaRules.unlocked(profile, c, gid), gid + ": not by walking")
			profile.defeated[str(rule["defeated"])] = 1
		assert_true(AreaRules.unlocked(profile, c, gid), gid + ": open on its rule")
		assert_eq(MapRules.state(profile, c, gid, "depot_yard"), MapRules.KNOWN, gid + ": on map")


func test_wins_taxi_rides_to_each_open_ground_for_the_usual_fare() -> void:
	var game := _game()
	var win := _truck(game)
	assert_eq(str(win["role"]), "travel", "Uncle Thong's truck in the city")
	game.enter_area("main_city", "west")
	game._show("travel", GameMenus.travel(game, win))
	assert_true(game.menu.find_child("Heading_Farming", true, false) == null, "none open yet")
	game.close_menu()
	_everything(game.profile)
	for gid: String in GROUNDS:
		game.enter_area("main_city", "west")
		game.profile.money = 100
		game._show("travel", GameMenus.travel(game, win))
		assert_true(game.menu.find_child("Heading_Farming", true, false) != null, "Farming")
		var ride: Button = game.menu.find_child("Ride_" + gid, true, false)
		assert_true(ride != null, gid + ": a ride")
		var level := int(game.content.area(gid)["level"])
		assert_true("suggested Lv %d" % level in ride.text, gid + ": its level is a suggestion")
		game.close_menu()
		game._ride(win, gid)
		assert_eq(game.zone.area_id, gid, gid + ": rode there")
		assert_eq(game.profile.money, 90, gid + ": for 10 coins")
		assert_true(game.zone.hero.position.x < 200.0, gid + ": arrives at its west end")
	game.open_screen("map")
	for gid: String in GROUNDS:
		assert_true(game.menu.find_child("Area_" + gid, true, false) != null, gid + ": map row")
	game.close_menu()
	_done(game)


func test_each_ground_is_left_west_or_by_the_pause_menu_to_the_city() -> void:
	var game := _game()
	_everything(game.profile)
	for gid: String in GROUNDS:
		game.enter_area(gid, "west")
		game.zone.hero.position = Vector2(game.zone.bounds.position.x + 2.0, ROAD_Y)
		var input := FighterInput.new()
		input.move = Vector2.LEFT
		for i in 30:
			game.step(input)
			if game.zone.area_id != gid:
				break
		assert_eq(game.zone.area_id, "main_city", gid + ": walked out west into the city")
		assert_true(game.zone.hero.position.x < 200.0, gid + ": at the taxi rank")
		game.enter_area(gid, "west")
		game.open_pause()
		var back: Button = game.menu.find_child("Recall", true, false)
		assert_true(back != null and not back.disabled, gid + ": the return is on offer")
		back.pressed.emit()
		assert_eq(game.zone.area_id, game.content.city_area, gid + ": back in the city")
	assert_true(
		not game.content.area("depot_yard").get("exits", {}).has("west"),
		"Depot Yard still has no way west"
	)
	_done(game)


func test_the_map_shows_a_grounds_level_as_a_suggestion_and_what_it_is_for() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	_everything(profile)
	for gid: String in GROUNDS:
		var info := MapRules.about(profile, c, gid, "depot_yard")
		assert_eq(info["purpose"], c.area(gid)["purpose"], gid + ": what it is for")
		var panel := MapTab._detail()
		MapTab._show(panel, info, false)
		var heading: Label = panel.find_child("Heading", true, false)
		var lines: Label = panel.find_child("Lines", true, false)
		assert_true("Suggested Lv %d" % int(c.area(gid)["level"]) in heading.text, heading.text)
		assert_true("No level needed to enter" in lines.text, gid + ": not a requirement")
		panel.free()
	assert_eq(MapRules.about(profile, c, "saltmarket", "depot_yard")["purpose"], "", "streets")
	assert_true("no XP" in str(c.area("farm_core_overflow")["purpose"]), "the cap is said")


func test_auto_battle_farms_each_ground_at_its_level() -> void:
	var c := _content()
	for gid: String in GROUNDS:
		var run := ProgressionHarness.run_loop(
			c, {"area": gid, "hero": "oren", "seed": 3, "ticks": 7200}
		)
		assert_eq(int(run["ticks"]), 7200, "%s: two minutes played" % gid)
		assert_true(not run["ko"], gid + ": the hero stays standing")
		assert_true(int(run["coins"]) > 0, gid + ": coins")
		# A hero at the level cap earns no XP (PlayerProfile), so a ground at
		# the cap pays in coins and materials only.
		var capped := int(run["level"]) >= int(c.progression["max_level"])
		assert_eq(int(run["xp"]) > 0, not capped, gid + ": XP unless at the level cap")


func test_each_ground_is_a_living_field_with_nothing_to_win_or_save() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	_everything(profile)
	for gid: String in GROUNDS:
		assert_true(FarmSpawner.active(c, gid), gid + ": a living field")
		assert_true(c.area(gid).get("encounters", []).is_empty(), gid + ": no fixed fights")
		assert_true(StreetMemory.pending(profile, c, gid).is_empty(), gid + ": nothing to win")
		var zone := ZoneSim.new(c, profile, gid, "west", 1)
		for tick in 600:
			zone.tick(FighterInput.new())
		var data := FarmSpawner.spec(c, gid)
		var fewest := (data["camps"] as Array).size() * FarmSpawner.size_range(data).x
		var standing := zone.enemies().size()
		assert_true(standing >= fewest, gid + ": every camp standing")
		assert_true(standing <= FarmSpawner.capacity(data), gid + ": none past its size")
		assert_true(not zone.fight_locked(), gid + ": nothing walls the hero in")
		assert_true(not profile.cleared.has(gid), gid + ": nothing saved about it")


func test_a_save_made_in_a_ground_loads_there() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	_everything(profile)
	for gid: String in GROUNDS:
		profile.area = gid
		var loaded := PlayerProfile.from_dict(profile.to_dict(), c)
		assert_eq(loaded.area, gid, gid + ": loads in the ground")
		assert_true(AreaRules.unlocked(loaded, c, gid), gid + ": still open")
		assert_eq(loaded.visited.size(), profile.visited.size(), gid + ": progress kept")
