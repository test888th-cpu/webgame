extends TestCase
## The Guide (N): items, monsters, bosses and maps, every one findable by
## search, every page built from LootIndex (the rules that pay the drops), its
## names linking to their own pages, Back returning; exact rates or rarity
## words by progression.json "show_drop_rates"; nothing made up where the data
## has nothing to say.

const TEST_SAVE := "user://test_guide"
const GAME_SCENE := preload("res://scenes/game/Game.tscn")


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("riku")
	tree.root.size = Vector2i(1280, 720)
	var game: Game = GAME_SCENE.instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _links(guide: GuideScreen, tab: String) -> Array[LinkButton]:
	var out: Array[LinkButton] = []
	for node in (guide._tabs[tab]["detail"] as Node).find_children("*", "LinkButton", true, false):
		out.append(node as LinkButton)
	return out


func test_n_opens_the_guide_and_every_entry_can_be_found() -> void:
	var game := _game()
	Input.action_press("guide")
	game._physics_process(0.0)
	Input.action_release("guide")
	assert_eq(game.menu_name, "guide", "N opens the Guide")
	var c := game.content
	var total := {"items": 0, "monsters": 0, "bosses": 0, "maps": 0}
	for id: String in c.items:
		var found := GuidePages.entries(c, "items", str(c.item(id)["name"]), "", "name")
		assert_true(id in found, id + ": found by name")
		total["items"] += 1
	for id: String in c.enemies:
		var kind := LootIndex.kind_of(c, id)
		if kind == LootIndex.TRAINING:
			continue
		var tab := "bosses" if kind in LootIndex.BOSSES else "monsters"
		assert_true(id in GuidePages.entries(c, tab, str(c.enemy(id)["name"]), "", "name"), id)
		total[tab] += 1
	for id: String in c.areas:
		if GuidePages.place_kind(c, id) != "arena":
			assert_true(
				id in GuidePages.entries(c, "maps", str(c.area(id)["name"]), "", "name"), id
			)
			total["maps"] += 1
	assert_eq(GuidePages.entries(c, "items", "", "", "name").size(), total["items"], "no doubles")
	assert_true(total["monsters"] > 30 and total["bosses"] == 24, "indexed: %s" % str(total))
	_done(game)


func test_an_item_lists_every_source_and_links_to_it_and_back() -> void:
	var game := _game()
	game.open_screen("guide")
	var guide := GuideScreen.of(game.menu)
	var c := game.content
	guide.open("items", "chiefs_baton")
	var enemies := {}
	for source: Dictionary in LootIndex.sources(c, "chiefs_baton"):
		if source["kind"] == "enemy":
			enemies[str(c.enemy(str(source["id"]))["name"])] = true
	var names := _links(guide, "items").map(func(l: LinkButton) -> String: return l.text)
	for name: String in enemies:
		assert_true(name in names, name + ": a source, linked")
	var first := _links(guide, "items")[0]
	first.pressed.emit()
	assert_eq(guide.current(), "bosses", "the link opens the boss")
	assert_eq(guide.shown("bosses"), "security_chief", "its page")
	guide.back()
	assert_eq(guide.current(), "items", "Back")
	assert_eq(guide.shown("items"), "chiefs_baton", "to the item")
	_done(game)


func test_enemy_and_map_pages_show_the_rules_own_lists() -> void:
	var game := _game()
	game.open_screen("guide")
	var guide := GuideScreen.of(game.menu)
	var c := game.content
	for tab_id: Array in [
		["monsters", "smogling"], ["bosses", "director_wiroj"], ["bosses", "iron_colossus"]
	]:
		guide.open(tab_id[0], tab_id[1])
		var item_links := _links(guide, tab_id[0]).filter(
			func(l: LinkButton) -> bool:
				return c.areas.values().all(
					func(a: Dictionary) -> bool: return a.get("name") != l.text
				)
		)
		assert_eq(
			item_links.size(),
			LootIndex.drops(c, tab_id[1]).size(),
			tab_id[1] + ": every drop listed"
		)
	guide.open("maps", "farm_saltmarket_backlots")
	var info := LootIndex.area_info(c, "farm_saltmarket_backlots")
	var names := _links(guide, "maps").map(func(l: LinkButton) -> String: return l.text)
	for entry: Dictionary in info["enemies"]:
		assert_true(str(c.enemy(str(entry["id"]))["name"]) in names, str(entry["id"]) + " is here")
	assert_eq(
		names.size(), info["enemies"].size() + info["items"].size(), "and every item farmed here"
	)
	_done(game)


func test_rates_or_words_and_changes_show_at_once() -> void:
	var game := _game()
	var c := game.content
	var drop := {"chance": 0.003, "guaranteed": false}
	assert_eq(GuidePages.chance_text(c, drop), "0.3%", "exact by default")
	c.progression["show_drop_rates"] = false
	assert_eq(GuidePages.chance_text(c, drop), "very rare", "a word when rates are hidden")
	assert_eq(GuidePages.chance_text(c, {"chance": 1.0, "guaranteed": true}), "guaranteed", "")
	c.progression["show_drop_rates"] = true
	# The pages read the live data: a changed chance shows the next time.
	var table: Array = c.enemies["smogling"]["loot"]["drops"]
	var old := float(table[0]["chance"])
	table[0]["chance"] = 0.5
	LootIndex._index = {}
	var found := LootIndex.drops(c, "smogling").filter(
		func(d: Dictionary) -> bool:
			return d["item"] == table[0]["item"] and d["how"] == "loot" and d["area"] == ""
	)
	assert_eq(GuidePages.chance_text(c, found[0]), "50.0%", "the new chance")
	table[0]["chance"] = old
	LootIndex._index = {}
	_done(game)


func test_typing_in_the_search_is_text_not_hotkeys() -> void:
	var game := _game()
	game.open_screen("guide")
	await tree.process_frame
	var guide := GuideScreen.of(game.menu)
	var search: LineEdit = guide._tabs["items"]["search"]
	search.grab_focus()
	for action: String in ["menu_next", "guide", "pause", "map"]:
		Input.action_press(action)
		game._physics_process(0.0)
		Input.action_release(action)
		assert_eq(game.menu_name, "guide", action + ": still the Guide")
		assert_eq(guide.current(), "items", action + ": still on Items")
	_done(game)


func test_unknown_places_are_said_not_made_up() -> void:
	var c := ContentDB.load_all()
	for id: String in c.enemies:
		if LootIndex.places(c, id).is_empty() and LootIndex.kind_of(c, id) != LootIndex.TRAINING:
			var by := GuidePages._summoned_by(c, id)
			assert_true(by != "", id + ": no place, but a boss calls it in (%s)" % by)


func test_every_page_opens_quickly_and_lists_nothing_twice() -> void:
	var game := _game()
	game.open_screen("guide")
	var guide := GuideScreen.of(game.menu)
	var c := game.content
	var started := Time.get_ticks_msec()
	var pages := 0
	for tab: String in GuideScreen.TABS:
		var ids := GuidePages.entries(c, tab, "", "", "name")
		var unique := {}
		for id: String in ids:
			unique[id] = true
		assert_eq(unique.size(), ids.size(), tab + ": no entry twice")
		for id: String in ids:
			guide.open(tab, id)
			pages += 1
			for child in (guide._tabs[tab]["detail"] as Node).get_children():
				child.free()
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("guide: %d pages in %.1f s" % [pages, seconds])
	assert_true(pages >= 420, "%d pages opened" % pages)
	assert_true(seconds < 60.0, "every page opened in %.1f s" % seconds)
	var search_start := Time.get_ticks_msec()
	GuidePages.entries(c, "monsters", "street", "", "level")
	assert_true(Time.get_ticks_msec() - search_start < 500, "a search answers at once")
	_done(game)
