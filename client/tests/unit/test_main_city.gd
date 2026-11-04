extends TestCase
## Iron City Central (`main_city`), the city hub: a separate, safe area off
## the story street, reached by Win's taxi from every stand or the pause menu,
## whose one way out on foot is a gate east into Depot Yard. Arriving rests
## the hero exactly as Depot Yard does. Its services are the existing systems
## (a shop, the workbench's upgrades, Win's rides) and a notice board that
## only informs. Depot Yard, the story street, Recall, auto battle's home and
## the world bosses' way home are all unchanged; a save made in the city (or
## any other place off the street) unlocks nothing.

const TEST_SAVE := "user://test_main_city_save"
const CITY := "main_city"
const SCREEN := Rect2(0, 0, 640, 360)
## The middle of the road, clear of what is parked at the kerb (_walk_to).
const ROAD_Y := 300.0
## The city's services: npc id -> [role, the menu E opens].
const SERVICES := {
	"taxi_win_city": ["travel", "travel"],
	"thong_truck_city": ["travel", "travel"],
	"city_notice_board": ["board", "board"],
	"vendor_ama": ["shop", "shop"],
	"city_workbench": ["workbench", "bag"],
}
## Depot Yard as it is on main (SHA-256 of its areas.json entry, its kit and
## generated scenery entries, sorted-key JSON, and of its four scenery images).
## The city must never change Story Area 1.
## Depot Yard without its NPCs: the owner moved Ama's stall and Win's rank to
## the city (2026-11-03); the yard keeps Chief Odo, a story rest point.
const DEPOT_AREA_SHA := "392475033404b717094a20cff283941f6e5213793a0129f0dbb47f6aef9274b6"
const DEPOT_KIT_SHA := "d73d184ceaa63434c1309f90032f4c49fd6983276aa44d2fb52b23595e272e22"
const DEPOT_ENV_SHA := "cfa32a60f4d172a6d40a25cfdc28c6ef727f3c335bed0f0add4080095d51fd2f"
const DEPOT_PNG_SHA := {
	"sky": "f3f92e83c0c723822db33d149cbff9426a4db3ea559e44e8c1401460536ca40a",
	"far": "c6299d6f2b8cd9ca5d225d45883ba9709b9480d2718bd10bf1e57c693e34d63f",
	"buildings": "db07d9b2daaf7e5d735c02839bed6b2b0d0ec37e87add2359b3fdba25ea34150",
	"ground": "1d3404cc8ed536979ec66c52770e114d62b6e149e1b4b58af0c03829460fc143",
}

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _city() -> Dictionary:
	return _content().area(CITY)


func _npc(npc_id: String) -> Dictionary:
	for npc: Dictionary in _city()["npcs"]:
		if npc["id"] == npc_id:
			return npc
	return {}


func _spot(npc_id: String) -> Vector2:
	var npc := _npc(npc_id)
	return Vector2(float(npc["x"]) - 20.0, float(npc["y"]))


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


func _settle(size := Vector2i(1280, 720)) -> void:
	tree.root.size = size
	await tree.process_frame
	await tree.process_frame


## Walks the hero to `target` as a player would: along the middle of the
## road, clear of what is parked at the kerb, then up to the NPC once level
## with them; anything in the way is stepped round. True once there.
func _walk_to(game: Game, target: Vector2, ticks := 1500) -> bool:
	var detour := 0
	var last := game.zone.hero.position
	for i in ticks:
		var hero := game.zone.hero.position
		var offset := target - hero
		if absf(offset.x) <= 12.0 and absf(offset.y) <= 8.0:
			return true
		var lane := target.y if absf(offset.x) < 40.0 else ROAD_Y
		var input := FighterInput.new()
		input.move = Vector2(
			signf(offset.x) if absf(offset.x) > 4.0 else 0.0,
			signf(lane - hero.y) if absf(lane - hero.y) > 4.0 else 0.0
		)
		if detour > 0:
			input.move = Vector2(signf(offset.x), 1.0)
			detour -= 1
		game.step(input)
		if detour == 0 and game.zone.hero.position.distance_to(last) < 0.2:
			detour = 30
		last = game.zone.hero.position
	return false


func _texts(root: Node) -> String:
	var out := ""
	for label: Label in root.find_children("*", "Label", true, false):
		out += label.text + "\n"
	return out


## Every visible panel, button and label of `root` lies inside `visible`. A
## list that scrolls clips its rows, so the scroll box itself must fit.
func _check_layout(root: Node, what: String, visible := SCREEN) -> void:
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if not control.is_visible_in_tree() or _in_scroll(control):
			continue
		if (
			control is PanelContainer
			or control is Button
			or control is Label
			or control is ScrollContainer
		):
			assert_true(
				visible.grow(1).encloses(control.get_global_rect()),
				"%s: %s %s fits on screen" % [what, control.get_class(), control.name]
			)


static func _in_scroll(control: Control) -> bool:
	var up := control.get_parent()
	while up != null:
		if up is ScrollContainer:
			return true
		up = up.get_parent()
	return false


func _rides(menu: Control) -> Array[String]:
	var out: Array[String] = []
	for button: Button in menu.find_children("Ride_*", "Button", true, false):
		out.append(button.name.trim_prefix("Ride_"))
	out.sort()
	return out


# --- Depot Yard is untouched ---------------------------------------------


func test_depot_yard_is_exactly_as_on_main() -> void:
	var depot := _content().area("depot_yard").duplicate(true)
	# The owner's changes since: the merchants and Win moved to the city, so
	# only Chief Odo stays. Everything else is byte for byte as on main.
	var npcs: Array = depot["npcs"]
	assert_eq(npcs.map(func(n: Dictionary) -> String: return n["id"]), ["chief_odo"], "Odo stays")
	depot.erase("npcs")
	assert_eq(JSON.stringify(depot, "", true).sha256_text(), DEPOT_AREA_SHA, "Depot Yard's data")
	assert_eq(
		JSON.stringify(_content().kit["areas"]["depot_yard"], "", true).sha256_text(),
		DEPOT_KIT_SHA,
		"Depot Yard's street-kit layout"
	)
	assert_eq(
		JSON.stringify(_content().environment["areas"]["depot_yard"], "", true).sha256_text(),
		DEPOT_ENV_SHA,
		"Depot Yard's generated scenery"
	)
	for layer: String in DEPOT_PNG_SHA:
		var path := "res://assets/environment/depot_yard/%s.png" % layer
		assert_eq(FileAccess.get_sha256(path), DEPOT_PNG_SHA[layer], "Depot Yard's %s" % layer)
	assert_eq(_content().start_area, "depot_yard", "new characters still start there")
	assert_true(not depot["exits"].has("west"), "Depot Yard gains no west exit")


# --- A separate area off the street ---------------------------------------


func test_the_city_is_its_own_area_off_the_street() -> void:
	assert_eq(_content().city_area, CITY, "the city's own area id")
	assert_true(CITY != _content().start_area, "not Depot Yard")
	assert_eq(_city()["name"], "Iron City Central", "the approved name")
	assert_true(_city().get("safe", false), "a safe zone")
	assert_true(_city().get("heal_on_enter", false), "a place to rest")
	assert_true(_city().get("encounters", []).is_empty(), "not a story stage: no fights")
	assert_true(not _city().get("world_boss", false), "not a world boss arena")
	var street := StreetMemory.street(_content())
	assert_true(CITY not in street, "off the story street")
	assert_eq(street.size(), 31, "the street is Depot Yard and the 30 story areas, as before")
	assert_eq(MapRules.districts(_content())[0]["areas"][0], "depot_yard", "districts unchanged")
	assert_eq(MapRules.locate(_content(), CITY), {}, "in no district")
	for area_id: String in _content().areas:
		var hub_only := (
			AreaRules.kind(_content(), area_id) in [AreaRules.FARM, AreaRules.WORLD_BOSS]
		)
		for side: String in _content().area(area_id).get("exits", {}):
			var to := str(_content().area(area_id)["exits"][side]["to"])
			if hub_only:
				assert_eq(to, CITY, "%s: walked out of, it leads back to the city" % area_id)
			else:
				assert_true(to != CITY, "no story area walks into the city (%s)" % area_id)
	var fresh := PlayerProfile.new_game(_content())
	assert_true(AutoRules.problem(fresh, _content(), CITY, false) != "", "no fight in the city")
	assert_eq(AutoRules.problem(fresh, _content(), CITY), "", "but auto rides out for the story")


func test_its_one_way_out_is_the_gate_east_into_depot_yard() -> void:
	assert_eq(_city()["exits"].keys(), ["east"], "one exit")
	assert_eq(_city()["exits"]["east"], {"to": "depot_yard", "entry": "west"}, "to Depot Yard")
	var game := _game()
	game._go_to_city()
	game.zone.hero.position = Vector2(game.zone.bounds.end.x - 2.0, ROAD_Y)
	var input := FighterInput.new()
	input.move = Vector2.RIGHT
	for i in 30:
		game.step(input)
		if game.zone.area_id != CITY:
			break
	assert_eq(game.zone.area_id, "depot_yard", "walked out through the gate")
	assert_true(game.zone.hero.position.x < 100.0, "into Depot Yard's west end")
	_done(game)


func test_arriving_rests_exactly_like_depot_yard() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.hp = 5
	profile.money = 321
	profile.xp = 40
	profile.add_item("scrap_metal", 2)
	profile.defeated["smogling"] = 7
	profile.quests["foreman"] = {"state": "active", "progress": 0}
	profile.world_boss["tunnel_mother"] = {"round": 9, "dealt": 50, "tiers": 1, "killed": false}
	StreetMemory.mark_cleared(profile, "saltmarket", 0)
	var before := profile.to_dict()
	ZoneSim.new(_content(), profile, CITY, "west", 1)
	assert_eq(profile.hp, int(profile.stats(_content())["max_hp"]), "healed")
	assert_eq(profile.cleared, {}, "the streets fill up again, as at Depot Yard")
	var after := profile.to_dict()
	for key: String in [
		"quests", "defeated", "world_boss", "inventory", "money", "equipment", "xp", "level"
	]:
		assert_eq(after[key], before[key], "%s kept" % key)


# --- Getting there and back -----------------------------------------------


func test_only_the_city_has_merchants_and_a_taxi() -> void:
	# The owner's rule: services live in the city; the story has quest givers.
	for area_id in StreetMemory.street(_content()):
		for npc: Dictionary in _content().area(area_id).get("npcs", []):
			assert_eq(
				str(npc["role"]), "quests", "%s: only a quest giver (%s)" % [area_id, npc["id"]]
			)
	var roles := {}
	for npc: Dictionary in _city()["npcs"]:
		roles[npc["role"]] = int(roles.get(npc["role"], 0)) + 1
	assert_eq(int(roles.get("travel", 0)), 2, "Win's story rank and Uncle Thong's truck")
	assert_eq(int(roles.get("shop", 0)), 1, "one merchant: Ama's Market")
	assert_eq(_content().shops.keys(), ["city_market"], "selling every trader's wares")
	var game := _game()
	game.profile.money = 1000
	for area_id in StreetMemory.street(game.content):
		StreetMemory.visit(game.profile, area_id)
	game._go_to_city()
	game._ride(_npc("taxi_win_city"), "port_road")
	assert_eq(game.zone.area_id, "port_road", "rode out to the story")
	assert_eq(game.profile.money, 990, "for the usual fare")
	_done(game)


func test_the_two_taxis_keep_to_their_own_routes_and_fit_small_screens() -> void:
	var game := _game()
	game._go_to_city()
	for area_id in StreetMemory.street(game.content):
		StreetMemory.visit(game.profile, area_id)
	for boss: String in game.content.world_bosses:
		game.profile.defeated[str(WorldBossRules.spec(game.content, boss)["unlock"])] = 1
	game.profile.money = 100
	game._show("travel", GameMenus.travel(game, _npc("taxi_win_city")))
	var story: Array[String] = StreetMemory.street(game.content)
	story.sort()
	assert_eq(_rides(game.menu), story, "Win: every story area reached, nothing else")
	for district in MapRules.districts(game.content):
		var heading := "Heading_" + str(district["name"]).validate_node_name()
		assert_true(game.menu.find_child(heading, true, false) != null, heading)
	assert_true(game.menu.find_child("Heading_Farming", true, false) == null, "no farming")
	await _settle()
	_check_layout(game.menu, "story taxi at 640x360")
	game.close_menu()
	game._show("travel", GameMenus.travel(game, _npc("thong_truck_city")))
	# Every boss is down too, so every farming ground is open.
	var field: Array[String] = AreaRules.farms(game.content)
	field.append_array(game.content.world_bosses.keys())
	field.sort()
	assert_eq(_rides(game.menu), field, "Uncle Thong: the grounds and the world bosses only")
	for heading in ["Heading_Farming", "Heading_World Bosses"]:
		assert_true(game.menu.find_child(heading, true, false) != null, heading)
	await _settle()
	_check_layout(game.menu, "taxi at 640x360")
	# A phone held upright (360 px wide): the game scales to fit the width.
	await _settle(Vector2i(360, 640))
	_check_layout(game.menu, "taxi at 360x640", game.get_viewport().get_visible_rect())
	await _settle()
	_done(game)


func test_the_pause_menu_goes_to_the_city_with_recalls_checks() -> void:
	var game := _game()
	game.open_pause()
	var go: Button = game.menu.find_child("Recall", true, false)
	assert_true(go != null and not go.disabled, "offered from Depot Yard")
	assert_eq(go.text.strip_edges(), "Return to Iron City Central", "one return: to the city")
	assert_true(game.menu.find_child("GoToCity", true, false) == null, "no second city item")
	await _settle()
	_check_layout(game.menu, "pause menu")
	game.close_menu()
	# In a fight: neither Recall nor the city.
	game.enter_area("saltmarket", "west")
	game.zone.hero.position.x = float(game.content.area("saltmarket")["encounters"][0]["trigger_x"])
	game.step(FighterInput.new())
	assert_true(game.zone.in_encounter(), "a fight started")
	assert_eq(game.city_problem(), game.zone.recall_problem(), "the same check as Recall")
	assert_true(game.city_problem() != "", "no escape from a fight")
	game._go_to_city()
	assert_eq(game.zone.area_id, "saltmarket", "stayed to fight")
	# Knocked down: no.
	game.enter_area("saltmarket", "west")
	game.zone.hero.enter(Fighter.State.DOWN, 600)
	assert_true(game.city_problem() != "", "not while down")
	# During a world boss attempt: no.
	var boss := "tunnel_mother"
	game.profile.defeated[str(WorldBossRules.spec(game.content, boss)["unlock"])] = 1
	game.now_override = int(WorldBossRules.spec(game.content, boss)["period_minutes"]) * 60000 + 60
	game._start_world_boss(boss)
	assert_true(game.world_run != null, "an attempt under way")
	assert_true(game.city_problem() != "", "not during a world boss attempt")
	game._leave_world_boss()
	assert_eq(game.zone.area_id, CITY, "the world boss way home is the city")
	game.enter_area("depot_yard", "west")
	game._go_to_city()
	assert_eq(game.zone.area_id, CITY, "to the city")
	assert_eq(game.city_problem(), "You are already there.", "already there")
	_done(game)


## The bug fixed: the pause menu's return went to the story's start (Depot
## Yard). It must reach Iron City Central from Story Area 1, from later story
## areas, from Depot Yard and from a farming ground, and arrive at the taxi
## rank, rested, for free, with the hero's progress untouched.
func test_return_to_the_city_from_anywhere_lands_at_the_rank() -> void:
	var game := _game()
	var rank := float(_npc("taxi_win_city")["x"])
	var from: Array[String] = ["saltmarket", "port_road", "core_chamber", "depot_yard"]
	from.append("farm_facility_annex")
	game.profile.money = 250
	game.profile.add_item("steamed_bun", 4)
	game.profile.level = 7
	var buns := game.profile.count("steamed_bun")
	for area_id in from:
		game.enter_area(area_id, "west")
		game.zone.hero.hp = 3
		game.open_pause()
		var back: Button = game.menu.find_child("Recall", true, false)
		assert_true(back != null and not back.disabled, "%s: offered" % area_id)
		back.pressed.emit()
		assert_eq(game.zone.area_id, CITY, "%s: back in Iron City Central" % area_id)
		assert_true(game.zone.area_id != game.content.start_area, "%s: not Depot Yard" % area_id)
		var at := game.zone.hero.position
		assert_true(game.zone.bounds.has_point(at), "%s: arrives inside the city" % area_id)
		assert_true(at.x < rank, "%s: arrives at the taxi rank (%s)" % [area_id, at])
		assert_eq(game.profile.area, CITY, "%s: the save remembers the city" % area_id)
		assert_eq(game.zone.hero.hp, game.zone.hero.max_hp, "%s: rested" % area_id)
		assert_eq(game.profile.money, 250, "%s: free" % area_id)
	assert_eq(game.profile.count("steamed_bun"), buns, "the bag is untouched")
	assert_eq(game.profile.level, 7, "and the level")
	assert_eq(game.content.start_area, "depot_yard", "Depot Yard is still the start area")
	_done(game)


func test_the_story_goes_home_to_depot_yard_and_the_hub_content_to_the_city() -> void:
	var c := _content()
	assert_eq(c.start_area, "depot_yard", "the story's home")
	assert_eq(AreaRules.hub(c), CITY, "the farming grounds' and world bosses' home")
	assert_eq(AreaRules.rest_home(c, "port_road"), CITY, "auto rests in the city, story or not")
	assert_eq(AreaRules.rest_home(c, "farm_facility_annex"), CITY, "and in the city from a ground")
	assert_eq(AutoRules.fare(c, CITY), 10, "auto battle's ride back from the city")
	for boss: String in c.world_bosses:
		var arena := str(WorldBossRules.spec(c, boss)["area"])
		assert_eq(str(c.area(arena)["exits"]["west"]["to"]), CITY, "%s exit" % arena)


func test_the_map_shows_the_city_from_the_first_night() -> void:
	var profile := PlayerProfile.new_game(_content())
	assert_eq(MapRules.state(profile, _content(), CITY, "depot_yard"), MapRules.KNOWN, "known")
	var about := MapRules.about(profile, _content(), CITY, "depot_yard")
	assert_eq(about["kind"], MapRules.TOWN, "a town")
	assert_eq(about["services"], ["Taxi", "Notices", "Shop", "Upgrades"], "what it offers")
	var game := _game()
	game._go_to_city()
	game.open_screen("map")
	assert_true(game.menu.find_child("Area_" + CITY, true, false) != null, "its own map row")
	_done(game)


# --- Moving around and the services ----------------------------------------


func test_the_hero_can_walk_to_every_service() -> void:
	var game := _game()
	game._go_to_city()
	var start := game.zone.hero.position
	assert_true(start.x < 100.0, "arrives at the taxi rank (%s)" % start)
	assert_true(Bodies.is_clear(start, game.zone.solids, game.zone.bounds), "on a clear spot")
	for npc_id: String in SERVICES:
		assert_true(_walk_to(game, _spot(npc_id)), "walked to %s" % npc_id)
		assert_eq(game.view.npc_near(game.zone.hero).get("id"), npc_id, "in reach of %s" % npc_id)
	_done(game)


func test_every_service_opens_what_it_says() -> void:
	var game := _game()
	game._go_to_city()
	for npc_id: String in SERVICES:
		game.close_menu()
		game.zone.hero.position = _spot(npc_id)
		assert_eq(game.view.npc_near(game.zone.hero).get("role"), SERVICES[npc_id][0], npc_id)
		assert_true(game.try_interact(), "%s answers E" % npc_id)
		assert_eq(game.menu_name, SERVICES[npc_id][1], "%s opens its screen" % npc_id)
		await _settle()
		_check_layout(game.menu, npc_id)
	_done(game)


func test_the_market_gets_each_traders_stock_with_their_chapter() -> void:
	var game := _game()
	game._go_to_city()
	game.profile.money = 50
	var price := int(game.content.item("steamed_bun")["price"])
	game._buy(_npc("vendor_ama"), "steamed_bun")
	assert_eq(game.profile.money, 50 - price, "Ama's Market is open from the start")
	assert_eq(game.profile.count("steamed_bun"), 4, "bought one (3 in the starter kit)")
	var market: Dictionary = game.content.shops["city_market"]
	var before := ShopRules.wares(game.profile, game.content, "city_market")
	for stock: Dictionary in market["stock"]:
		var fresh := ""
		for item_id: String in stock["items"]:
			if item_id not in ShopRules.wares(game.profile, game.content, "city_market"):
				fresh = item_id
		if fresh == "":
			continue
		game.profile.money = 100000
		var text := ShopRules.next_stock(game.profile, game.content, "city_market")
		assert_true(text.begins_with(str(stock["from"])), "the next stock is named: " + text)
		var refused := ShopRules.buy(game.profile, "city_market", fresh, game.content)
		assert_eq(refused, "not_sold", fresh + ": not before its chapter")
		StreetMemory.visit(game.profile, str(stock["reached"]))
		assert_eq(ShopRules.buy(game.profile, "city_market", fresh, game.content), "", fresh)
	var after := ShopRules.wares(game.profile, game.content, "city_market")
	assert_true(after.size() > before.size(), "the whole street's wares by the end")
	assert_eq(ShopRules.next_stock(game.profile, game.content, "city_market"), "", "all in")
	_done(game)


func test_the_workbench_upgrades_and_the_upgrade_is_saved() -> void:
	var game := _game()
	game._go_to_city()
	var slot := ""
	for name: String in PlayerProfile.SLOTS:
		if slot == "" and str(game.profile.equipment[name]) != "":
			slot = name
	game.zone.hero.position = _spot("city_workbench")
	assert_true(game.try_interact(), "the workbench answers E")
	assert_eq(game.menu_focus, "worn:" + slot, "on worn gear")
	game.profile.money = 1000
	game.profile.add_item("scrap_metal", 5)
	game._upgrade(slot)
	assert_eq(EnhanceRules.level(game.profile, slot), 1, "upgraded in the city (it is safe)")
	var saved := SaveStore.load_character(game.profile.id, game.content)
	assert_eq(EnhanceRules.level(saved, slot), 1, "and saved")
	_done(game)


func test_the_board_reveals_no_more_than_the_story_has() -> void:
	var game := _game()
	var board := _npc("city_notice_board")
	game._show("board", GameMenus.notice_board(game, board))
	var text := _texts(game.menu)
	for boss: String in game.content.world_bosses:
		var data := WorldBossRules.spec(game.content, boss)
		assert_true(game.menu.find_child("Boss_" + boss, true, false) != null, boss)
		assert_true(str(game.content.enemy(str(data["enemy"]))["name"]) not in text, "unnamed")
		assert_true(str(game.content.enemy(str(data["unlock"]))["name"]) not in text, "no hint")
	var goal := str(MapRules.goal(game.profile, game.content)["text"])
	assert_true(goal in text, "the current job: " + goal)
	var unlock := str(WorldBossRules.spec(game.content, "tunnel_mother")["unlock"])
	game.profile.defeated[unlock] = 1
	var period := int(WorldBossRules.spec(game.content, "tunnel_mother")["period_minutes"]) * 60
	game.now_override = period * 1000 + 60
	game._show("board", GameMenus.notice_board(game, board))
	var mother := _texts(game.menu.find_child("Boss_tunnel_mother", true, false))
	assert_true("The Tunnel Mother" in mother and "OUT NOW" in mother, "named and timed")
	_done(game)


func test_planned_services_are_marked_and_offer_nothing_to_press() -> void:
	var game := _game()
	game._show("board", GameMenus.notice_board(game, _npc("city_notice_board")))
	var planned := game.menu.find_children("Planned_*", "Label", true, false)
	assert_eq(planned.size(), 0, "no unapproved farming grounds or level bands")
	var tip := game.menu.find_children("FarmingTip", "Label", true, false)
	assert_eq(tip.size(), 1, "the farming tip, under its own heading")
	assert_true("cleared" in (tip[0] as Label).text, "farm any cleared street")
	var services := game.menu.find_children("Service_*", "Label", true, false)
	assert_eq(services.size(), 2, "trading post and guild hall only")
	for label: Label in services:
		assert_true("not open yet" in label.text, label.text)
	assert_eq(game.menu.find_children("*", "Button", true, false).size(), 1, "only Close")
	game.close_menu()
	game._go_to_city()
	var signs := game.view.find_children("Landmark_*", "Label", true, false)
	assert_eq(signs.size(), _city()["landmarks"].size(), "the city's signs")
	for landmark: Dictionary in _city()["landmarks"]:
		var text := str(landmark["text"])
		if "Trading Post" in text or "Guild Hall" in text:
			assert_true("not open yet" in text, "%s says it is not open yet" % text)
	var prompts := game.view.find_children("Prompt", "CenterContainer", true, false)
	assert_eq(prompts.size(), _city()["npcs"].size(), "a prompt only where E does something")
	_done(game)


func test_practice_weapons_lie_in_the_training_yard() -> void:
	var span: Array = _city()["weapons"]["span"]
	for seed in 20:
		var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), CITY, "", seed)
		assert_eq(zone.ground_weapons.size(), 2, "two to practise with")
		for weapon: Dictionary in zone.ground_weapons:
			var x: float = weapon["position"].x
			assert_true(x >= float(span[0]) and x <= float(span[1]), "by the dummy (%d)" % x)


func test_riding_out_and_coming_back_keeps_the_character_intact() -> void:
	var game := _game()
	game._go_to_city()
	game.profile.money = 100
	StreetMemory.visit(game.profile, "saltmarket")
	var before := game.profile.to_dict()
	game._ride(_npc("taxi_win_city"), "saltmarket")
	assert_eq(game.zone.area_id, "saltmarket", "rode out")
	game.open_pause()
	game._go_to_city()
	assert_eq(game.zone.area_id, CITY, "came back")
	var after := game.profile.to_dict()
	for key: String in ["inventory", "equipment", "enhance", "quests", "level", "xp", "hotbar"]:
		assert_eq(after[key], before[key], "%s unchanged" % key)
	assert_eq(int(after["money"]), int(before["money"]) - 10, "only the fare paid")
	var saved := SaveStore.load_character(game.profile.id, game.content)
	assert_eq(saved.to_dict(), game.profile.to_dict(), "the save on arrival is the character")
	_done(game)


func test_a_short_ride_list_is_shown_whole() -> void:
	# A new hero in the city: Win's list is short, and shown whole.
	var game := _game()
	game._go_to_city()
	game._show("travel", GameMenus.travel(game, _npc("taxi_win_city")))
	await _settle()
	var scroll: ScrollContainer = game.menu.find_child("Scroll", true, false)
	var box := scroll.get_global_rect()
	for row: Button in game.menu.find_children("Ride_*", "Button", true, false):
		if row.is_visible_in_tree():
			assert_true(box.grow(1).encloses(row.get_global_rect()), "%s is not cut off" % row.name)
	_done(game)
