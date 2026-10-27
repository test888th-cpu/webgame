extends TestCase
## Drives the real Game scene tick by tick: NPCs, menus, area changes, defeat
## and saving. Uses its own save path so it never touches a player's save.

const TEST_SAVE := "user://test_save.json"


func _game() -> Node2D:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	# Tests count coins and items from zero, without the starter kit.
	GameSession.profile.money = 0
	GameSession.profile.inventory.clear()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)  # tests drive ticks explicitly
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _walk(dir: Vector2) -> FighterInput:
	var input := FighterInput.new()
	input.move = dir
	return input


func test_new_game_starts_in_the_depot_with_npcs_and_dummy() -> void:
	var game := _game()
	assert_eq(game.zone.area_id, GameSession.content.start_area, "start area")
	assert_eq(game.zone.enemies().size(), 1, "training dummy placed")
	assert_eq(game.zone.area["npcs"].size(), 3, "vendor, quest giver and taxi")
	assert_true(SaveStore.has_save(), "entering an area autosaves")
	_done(game)


func test_shopping_at_the_vendor() -> void:
	var game := _game()
	game.profile.money = 50
	game.zone.hero.position = Vector2(430, 262) + Vector2(-20, 0)
	assert_true(game.try_interact(), "talking to the vendor")
	assert_eq(game.menu_name, "shop", "shop open")
	game._buy(game.view.npc_near(game.zone.hero), "steamed_bun")
	assert_eq(game.profile.money, 40, "paid 10")
	assert_eq(game.profile.count("steamed_bun"), 1, "bun bought")
	var ticks_before: int = game.zone.tick_count
	game._physics_process(0.0)
	assert_eq(game.zone.tick_count, ticks_before, "the world is paused while shopping")
	game.close_menu()
	assert_eq(game.menu, null, "shop closed")
	_done(game)


func test_quest_giver_offers_and_accepts_the_first_quest() -> void:
	var game := _game()
	game.zone.hero.position = Vector2(640, 262) + Vector2(-20, 0)
	assert_true(game.try_interact(), "talking to the chief")
	assert_eq(game.menu_name, "quests_npc", "quest dialog open")
	game._accept(game.view.npc_near(game.zone.hero), "clear_saltmarket")
	assert_eq(
		QuestRules.status(game.profile, "clear_saltmarket", game.content), "active", "accepted"
	)
	_done(game)


func test_nothing_to_talk_to_far_from_npcs() -> void:
	var game := _game()
	game.zone.hero.position = Vector2(140, 300)
	assert_true(not game.try_interact(), "no NPC in reach")
	assert_eq(game.menu, null, "no menu")
	_done(game)


func test_walking_off_the_east_edge_changes_area_and_saves() -> void:
	var game := _game()
	game.zone.hero.position.x = game.zone.bounds.end.x
	game.step(_walk(Vector2.RIGHT))
	assert_eq(game.zone.area_id, "saltmarket", "now in Saltmarket")
	assert_true(game.zone.hero.position.x < 100, "arrived at the west end")
	var saved := SaveStore.load_profile(game.content)
	assert_eq(saved.area, "saltmarket", "save records the new area")
	_done(game)


func test_a_weapon_left_in_an_area_is_there_on_return() -> void:
	var game := _game()
	var depot: String = game.zone.area_id
	game.zone.equip_weapon(game.zone.hero, "plank", 5)
	game.zone.hero.position.x = game.zone.bounds.end.x
	game.step(_walk(Vector2.RIGHT))
	assert_eq(game.zone.hero.weapon, "", "arrived empty-handed")
	game.enter_area(depot, "east")
	var planks: Array = game.zone.ground_weapons.filter(
		func(entry: Dictionary) -> bool: return entry["uses"] == 5
	)
	assert_eq(planks.size(), 1, "the dropped plank is still in the yard")
	_done(game)


func test_defeat_wakes_you_where_you_fell_and_costs_coins() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	game.profile.money = 100
	game.zone.hero.hp = 1
	game.profile.hp = 1
	var foe: Fighter = game.zone.spawn_enemy("smogling", game.zone.hero.position + Vector2(20, 0))
	foe.facing = -1
	for i in 600:
		game.step(FighterInput.new())
		if game.zone.hero.is_ko():
			break
	game.open_game_over()
	assert_eq(game.menu_name, "game_over", "game over shown")
	game._recover(10)
	assert_eq(game.profile.money, 90, "lost 10%")
	assert_eq(game.zone.area_id, "saltmarket", "back on your feet in the same street")
	assert_true(game.zone.hero.position.x < 120.0, "at its west end")
	assert_eq(game.zone.hero.hp, game.zone.hero.max_hp, "healed")
	_done(game)


func test_pause_menu_and_inventory_equip() -> void:
	var game := _game()
	game.profile.add_item("taped_knuckles")
	game.open_pause()
	assert_eq(game.menu_name, "pause", "paused")
	game.open_inventory()
	assert_eq(game.menu_name, "inventory", "inventory open")
	var power: float = game.zone.hero.power
	game._equip("taped_knuckles")
	assert_true(game.zone.hero.power > power, "equipping raises the hero's power right away")
	game.close_menu()
	_done(game)


func test_quick_heal_uses_a_bun() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun")
	game.zone.hero.hp = 50
	assert_true(game.quick_heal(), "ate")
	assert_eq(game.zone.hero.hp, 75, "healed 25")
	assert_true(not game.quick_heal(), "nothing left")
	_done(game)


func test_save_store_round_trip() -> void:
	SaveStore.path = TEST_SAVE
	var content := GameSession.content
	var profile := PlayerProfile.new_game(content)
	profile.money = 77
	assert_true(SaveStore.save(profile), "saved")
	assert_eq(SaveStore.load_profile(content).money, 77, "loaded")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_eq(SaveStore.load_profile(content), null, "a corrupt save is rejected, not crashed on")
	SaveStore.delete()
	assert_true(not SaveStore.has_save(), "deleted")
	SaveStore.path = SaveStore.DEFAULT_PATH
