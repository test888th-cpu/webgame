extends TestCase
## The shop screen and the bag on the real screens: the deal bar stays on
## screen, stacks are bought and sold back, rare gear asks before it goes,
## and gear drags between the bag and the doll (docs/UI.md).

const TEST_SAVE := "user://test_save.json"
const SCREEN := Rect2(0, 0, 640, 360)


func _game() -> Game:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	GameSession.profile.money = 0
	GameSession.profile.inventory.clear()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(node: Node) -> void:
	node.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _settle() -> void:
	tree.root.size = Vector2i(1280, 720)
	await tree.process_frame
	await tree.process_frame


func _check_layout(root: Node, what: String) -> void:
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if control.is_visible_in_tree() and (control is Button or control is Label):
			var rect := control.get_global_rect()
			assert_true(
				SCREEN.grow(1).encloses(rect), "%s: %s fits (%s)" % [what, control.name, rect]
			)


func test_the_deal_bar_is_on_screen_for_every_ware() -> void:
	var game := _game()
	game.profile.money = 100000
	game.profile.level = 30
	game.zone.hero.position = Vector2(410, 262)
	assert_true(game.try_interact(), "vendor in reach")
	await _settle()
	var list := game.menu.find_child("List", true, false) as ItemList
	for i in list.item_count:
		list.select(i)
		list.item_selected.emit(i)
		await _settle()
		var trade := game.menu.find_child("Trade", true, false) as Button
		assert_true(trade != null and trade.is_visible_in_tree(), "ware %d has a Buy button" % i)
		assert_true(SCREEN.encloses(trade.get_global_rect()), "ware %d: Buy is on screen" % i)
	_check_layout(game.menu, "shop with the longest card")
	_done(game)


func test_buying_a_stack_and_selling_it_back() -> void:
	var game := _game()
	game.profile.money = 100
	game.zone.hero.position = Vector2(410, 262)
	assert_true(game.try_interact(), "vendor in reach")
	await _settle()
	var step := game.menu.find_child("Step+", true, false) as Button
	step.pressed.emit()
	step.pressed.emit()
	assert_eq((game.menu.find_child("Total", true, false) as Label).text, "30", "3 buns: 30")
	(game.menu.find_child("Trade", true, false) as Button).pressed.emit()
	assert_eq(game.profile.count("steamed_bun"), 3, "bought three")
	assert_eq(game.profile.money, 70, "for 30")
	GameMenus.cycle_tab(game.menu, 1)
	await _settle()
	var tabs := game.menu.find_child("Tabs", true, false) as TabContainer
	assert_eq(tabs.current_tab, 1, "Q/E reach the Sell tab")
	var sell := tabs.get_child(1)
	var trade := sell.find_child("Trade", true, false) as Button
	(sell.find_child("StepMax", true, false) as Button).pressed.emit()
	trade.pressed.emit()
	assert_eq(game.profile.count("steamed_bun"), 0, "sold all three")
	assert_eq(
		game.profile.money, 70 + 3 * ShopRules.sell_price(game.content, "steamed_bun"), "paid"
	)
	await _settle()
	tabs = game.menu.find_child("Tabs", true, false) as TabContainer
	assert_eq(tabs.current_tab, 1, "the shop stays on Sell")
	_check_layout(game.menu, "empty sell tab")
	_done(game)


func test_rare_gear_asks_before_it_is_sold() -> void:
	var game := _game()
	game.profile.add_item("brass_knuckles")
	game.menu_focus = "sell:brass_knuckles"
	game.open_shop({"name": "Kenji", "shop": "night_stall", "role": "shop"})
	await _settle()
	var tabs := game.menu.find_child("Tabs", true, false) as TabContainer
	assert_eq(tabs.current_tab, 1, "opens on Sell")
	var trade := tabs.get_child(1).find_child("Trade", true, false) as Button
	trade.pressed.emit()
	assert_eq(game.profile.count("brass_knuckles"), 1, "not on the first press")
	assert_eq(trade.text, "Sure?", "it asks")
	trade.pressed.emit()
	assert_eq(game.profile.count("brass_knuckles"), 0, "sold on the second")
	_done(game)


func test_gear_drags_between_the_bag_and_the_doll() -> void:
	var game := _game()
	game.profile.add_item("taped_knuckles")
	game.profile.add_item("steamed_bun")
	game.open_inventory()
	await _settle()
	var bag := game.menu.find_child("Bag_taped_knuckles", true, false) as ItemSlot
	var data: Variant = bag._get_drag_data(Vector2.ZERO)
	assert_true(data is Dictionary and data["from"] == "bag", "gear can be picked up")
	var head := game.menu.find_child("Worn_head", true, false) as ItemSlot
	var weapon := game.menu.find_child("Worn_weapon", true, false) as ItemSlot
	assert_true(not head._can_drop_data(Vector2.ZERO, data), "a weapon does not fit the head")
	assert_true(weapon._can_drop_data(Vector2.ZERO, data), "it fits the weapon slot")
	weapon._drop_data(Vector2.ZERO, data)
	assert_eq(game.profile.equipment["weapon"], "taped_knuckles", "dropped on: worn")
	await _settle()
	weapon = game.menu.find_child("Worn_weapon", true, false) as ItemSlot
	data = weapon._get_drag_data(Vector2.ZERO)
	var cell := game.menu.find_child("BagGrid", true, false).get_child(3) as ItemSlot
	assert_true(cell._can_drop_data(Vector2.ZERO, data), "worn gear can go back to the bag")
	cell._drop_data(Vector2.ZERO, data)
	assert_eq(game.profile.equipment["weapon"], "", "taken off")
	assert_eq(game.profile.count("taped_knuckles"), 1, "back in the bag")
	await _settle()
	var bun := game.menu.find_child("Bag_steamed_bun", true, false) as ItemSlot
	assert_eq(bun._get_drag_data(Vector2.ZERO), null, "food is not dragged")
	bag = game.menu.find_child("Bag_taped_knuckles", true, false) as ItemSlot
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	bag._gui_input(click)
	assert_eq(game.profile.equipment["weapon"], "taped_knuckles", "a right click wears it")
	_done(game)


func test_an_upgraded_copy_has_its_own_cell_in_the_bag() -> void:
	var game := _game()
	game.profile.level = 10
	game.profile.add_item("foreman_wrench", 3)
	game.profile.equip("foreman_wrench", game.content)
	var copy := game.profile.own_copy("weapon")
	game.profile.enhance[copy] = 10
	game.profile.unequip("weapon", game.content)
	game.open_inventory()
	await _settle()
	var stack := game.menu.find_child("Bag_foreman_wrench", true, false) as ItemSlot
	var own := game.menu.find_child("Bag_" + copy.validate_node_name(), true, false) as ItemSlot
	assert_eq([stack.count, stack.upgrade], [2, 0], "the two plain wrenches: one +0 stack")
	assert_eq([own.count, own.upgrade], [1, 10], "the +10 one on its own")
	_check_layout(game.menu, "bag with copies")
	_done(game)
