extends TestCase
## The hotbar the player lays out (HotbarRules, the Bag's editor, the HUD):
## any slot takes the attack, the hero's skills or food, in any order, each
## once; layouts are saved per character and cleaned on load; play uses
## them; food that runs out can be swapped for other food.

const ROOT := "user://test_hotbar"
const GAME_SCENE := preload("res://scenes/game/Game.tscn")
const SCREEN := Rect2(0, 0, 640, 360)


func _content() -> ContentDB:
	return GameSession.content


func _profile(hero := "mika") -> PlayerProfile:
	return PlayerProfile.new_game(_content(), hero)


func _game() -> Game:
	SaveStore.root = ROOT
	SaveStore.delete_all()
	GameSession.start_new_game("mika")
	GameSession.profile.inventory.clear()
	# Lay out at the 16:9 base size, as the UI tests do.
	tree.root.size = Vector2i(1280, 720)
	var game: Game = GAME_SCENE.instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_every_hero_starts_with_the_default_layout() -> void:
	for hero: String in _content().hero_order:
		var keys := HotbarRules.layout(_profile(hero), _content())
		assert_eq(keys.size(), HotbarRules.SLOTS, "%s: seven slots" % hero)
		assert_eq(keys[0], HotbarRules.ATTACK, "%s: attack first" % hero)
		var first_skill := str(_content().hero(hero)["skills"][0])
		assert_eq(keys[1], "skill:" + first_skill, "%s: their first skill on 2" % hero)
		assert_eq(keys[5], "item:steamed_bun", "%s: food on 6" % hero)


func test_any_slot_takes_anything_the_hero_can_use_once() -> void:
	var p := _profile()
	assert_true(HotbarRules.place(p, _content(), 2, "item:steamed_bun"), "a bun on 3")
	var keys := HotbarRules.layout(p, _content())
	assert_eq(keys[2], "item:steamed_bun", "there")
	assert_eq(keys[5], "skill:whirlwind_kick", "what was on 3 went to the bun's old slot")
	assert_eq(keys.count("item:steamed_bun"), 1, "never twice")
	assert_true(HotbarRules.place(p, _content(), 6, "item:rice_box"), "any food")
	assert_true(HotbarRules.place(p, _content(), 0, "skill:furnace_slam"), "a skill on 1")
	assert_true(not HotbarRules.place(p, _content(), 1, "skill:headbutt"), "not Oren's skill")
	assert_true(not HotbarRules.place(p, _content(), 1, "item:work_jacket"), "not gear")
	assert_true(not HotbarRules.place(p, _content(), 1, "item:torn_label"), "not evidence")
	assert_true(not HotbarRules.place(p, _content(), 7, "item:steamed_bun"), "only 1-7")
	var before := HotbarRules.layout(p, _content())
	HotbarRules.swap(p, _content(), 0, 6)
	assert_eq(HotbarRules.layout(p, _content())[0], before[6], "swapped")
	HotbarRules.clear(p, _content(), 3)
	assert_eq(HotbarRules.entry(p, _content(), 3)["type"], "empty", "emptied")


func test_layouts_are_saved_and_cleaned_on_load() -> void:
	var p := _profile()
	HotbarRules.place(p, _content(), 2, "item:steamed_bun")
	var loaded := PlayerProfile.from_dict(
		JSON.parse_string(JSON.stringify(p.to_dict())), _content()
	)
	assert_eq(loaded.hotbar, p.hotbar, "kept")
	var data := p.to_dict()
	data["hotbar"] = ["attack", "attack", "skill:headbutt", "item:work_jacket", "", "x", ""]
	var cleaned := PlayerProfile.from_dict(data, _content())
	assert_eq(cleaned.hotbar, ["attack", "", "", "", "", "", ""], "only what this hero can use")
	data["hotbar"] = ["attack"]
	var short := PlayerProfile.from_dict(data, _content())
	assert_eq(HotbarRules.layout(short, _content()).size(), 7, "a broken layout gives the default")


func test_play_follows_the_layout() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun", 2)
	game._hotbar_put(2, "item:steamed_bun")
	game.zone.hero.hp = 20
	assert_true(game.use_slot(2, FighterInput.new()), "3 eats a bun now")
	assert_true(game.zone.hero.hp > 20, "healed")
	game._hotbar_clear(4)
	assert_true(not game.use_slot(4, FighterInput.new()), "an empty slot does nothing")
	await tree.process_frame
	var hud := game.get_node("Hud").find_child("Hotbar", true, false) as Hotbar
	assert_eq(hud.entries[2]["id"], "steamed_bun", "the HUD shows the new layout")
	assert_eq(hud.entries[4]["type"], "empty", "and the empty slot")
	_done(game)


func test_the_bag_puts_food_on_the_bar_and_only_food() -> void:
	var game := _game()
	game.profile.add_item("rice_box", 1)
	game.profile.add_item("taped_knuckles", 1)
	game.open_inventory()
	await tree.process_frame
	await tree.process_frame
	assert_true(game.menu.find_child("Drag_skill_whirlwind_kick", true, false) == null, "no skills")
	var bar3 := game.menu.find_child("Bar3", true, false) as ItemSlot
	var rice := game.menu.find_child("Bag_rice_box", true, false) as ItemSlot
	var data: Variant = rice._get_drag_data(Vector2.ZERO)
	assert_true(bar3._can_drop_data(Vector2.ZERO, data), "food can go on a slot")
	var gear := game.menu.find_child("Bag_taped_knuckles", true, false) as ItemSlot
	var gloves: Variant = gear._get_drag_data(Vector2.ZERO)
	assert_true(not bar3._can_drop_data(Vector2.ZERO, gloves), "gear cannot")
	var skill := {"from": "skills", "key": "skill:whirlwind_kick"}
	assert_true(not bar3._can_drop_data(Vector2.ZERO, skill), "nor a skill, in the Bag")
	bar3._drop_data(Vector2.ZERO, data)
	assert_eq(HotbarRules.layout(game.profile, game.content)[2], "item:rice_box", "it did")
	var bar1 := game.menu.find_child("Bar1", true, false) as ItemSlot
	var bar7 := game.menu.find_child("Bar7", true, false) as ItemSlot
	var keys := HotbarRules.layout(game.profile, game.content)
	bar7._drop_data(Vector2.ZERO, bar1._get_drag_data(Vector2.ZERO))
	var swapped := HotbarRules.layout(game.profile, game.content)
	assert_eq([swapped[0], swapped[6]], [keys[6], keys[0]], "slot onto slot swaps")
	var cell := game.menu.find_child("BagGrid", true, false).get_child(5) as ItemSlot
	bar7 = game.menu.find_child("Bar7", true, false) as ItemSlot
	cell._drop_data(Vector2.ZERO, bar7._get_drag_data(Vector2.ZERO))
	assert_eq(HotbarRules.layout(game.profile, game.content)[6], "", "dragged off: emptied")
	await tree.process_frame
	_fits(game, "bag")
	var saved := SaveStore.load_character(game.profile.id, game.content)
	assert_eq(saved.hotbar, game.profile.hotbar, "every change is saved")
	_done(game)


func test_the_skills_screen_lists_the_skills_and_puts_them_on_the_bar() -> void:
	var game := _game()
	game.open_screen("skills")
	await tree.process_frame
	await tree.process_frame
	assert_eq(game.menu_name, "skills", "its own screen")
	var cards := game.menu.find_children("Card_*", "PanelContainer", true, false)
	assert_eq(cards.size(), 5, "the attack and the hero's four skills")
	assert_true(game.menu.find_child("Bag_steamed_bun", true, false) == null, "no items here")
	var kick := game.menu.find_child("Drag_skill_whirlwind_kick", true, false) as ItemSlot
	var bar1 := game.menu.find_child("Bar1", true, false) as ItemSlot
	var food := {"from": "bag", "item_id": "steamed_bun"}
	assert_true(not bar1._can_drop_data(Vector2.ZERO, food), "food goes on from the Bag")
	bar1._drop_data(Vector2.ZERO, kick._get_drag_data(Vector2.ZERO))
	assert_eq(HotbarRules.layout(game.profile, game.content)[0], "skill:whirlwind_kick", "put")
	assert_eq(game.menu_name, "skills", "still on the Skills screen")
	var text := ""
	for label: Label in game.menu.find_children("*", "Label", true, false):
		text += label.text + "|"
	assert_true(text.contains("Key 1"), "a card says which key it is on")
	assert_true(text.contains("Unlocks at Lv"), "and when a locked one unlocks")
	_fits(game, "skills")
	_done(game)


func _fits(game: Game, what: String) -> void:
	for node in game.menu.find_children("*", "Control", true, false):
		var control: Control = node
		if control.is_visible_in_tree() and (control is Button or control is Label):
			var rect := control.get_global_rect()
			assert_true(
				SCREEN.grow(1).encloses(rect), "%s: %s fits (%s)" % [what, control.name, rect]
			)
