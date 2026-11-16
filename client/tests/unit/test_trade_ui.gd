extends TestCase
## The shop screen and the bag on the real screens: the cart and its
## checkout stay on screen, clicks fill the cart and one checkout settles it,
## rare gear asks before it goes, and gear drags between the bag and the doll
## (docs/UI.md). The cart's rules: test_trade_cart.gd.

const TEST_SAVE := "user://test_save"
const SCREEN := Rect2(0, 0, 640, 360)
const NPC := {"name": "Ama", "shop": "city_market", "role": "shop"}


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	GameSession.profile.money = 0
	GameSession.profile.inventory.clear()
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


func _check_layout(root: Node, what: String) -> void:
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if _scrolls(control):
			# Inside a scroll box: a long card scrolls rather than fits.
			continue
		if control.is_visible_in_tree() and (control is Button or control is Label):
			var rect := control.get_global_rect()
			assert_true(
				SCREEN.grow(1).encloses(rect), "%s: %s fits (%s)" % [what, control.name, rect]
			)


## True when `control` sits inside a ScrollContainer.
func _scrolls(control: Control) -> bool:
	var up := control.get_parent()
	while up:
		if up is ScrollContainer:
			return true
		up = up.get_parent()
	return false


## A left click on row `index` of the `mode` tab's list (Shift held: `many`).
func _click(game: Game, mode: String, index: int, button := MOUSE_BUTTON_LEFT) -> void:
	var tabs := game.menu.find_child("Tabs", true, false) as TabContainer
	var list := tabs.get_child(ShopScreen.TABS.find(mode)).find_child("List", true, false)
	(list as ItemList).item_clicked.emit(index, Vector2.ZERO, button)


func _row(game: Game, mode: String, item_id: String) -> int:
	return ShopScreen.of(game.menu)._pages[mode]["ids"].find(item_id)


func test_the_cart_and_checkout_are_on_screen_for_every_ware() -> void:
	var game := _game()
	game.profile.money = 100000
	game.profile.level = 30
	game.enter_area("main_city", "west")
	game.zone.hero.position = Vector2(500, 262)
	assert_true(game.try_interact(), "vendor in reach")
	await _settle()
	var list := game.menu.find_child("List", true, false) as ItemList
	var shop := ShopScreen.of(game.menu)
	for i in shop._pages[TradeCart.BUY]["ids"].size():
		list.select(i)
		list.item_selected.emit(i)
		_click(game, TradeCart.BUY, i)
		await _settle()
		var checkout := game.menu.find_child("Checkout", true, false) as Button
		assert_true(checkout.is_visible_in_tree(), "ware %d: a Buy button" % i)
		assert_true(SCREEN.encloses(checkout.get_global_rect()), "ware %d: Buy is on screen" % i)
	_check_layout(game.menu, "shop with the longest card and a full cart")
	_done(game)


func test_clicks_fill_the_cart_and_one_checkout_buys_it_all() -> void:
	var game := _game()
	game.profile.money = 100
	game.open_shop(NPC)
	await _settle()
	var bun := _row(game, TradeCart.BUY, "steamed_bun")
	var tea := _row(game, TradeCart.BUY, "ginger_tea")
	for i in 3:
		_click(game, TradeCart.BUY, bun)
	_click(game, TradeCart.BUY, tea)
	assert_eq(game.profile.count("steamed_bun"), 0, "nothing bought before the checkout")
	var line := game.menu.find_child("Line_steamed_bun", true, false)
	assert_true(line != null, "a click puts the item in the cart")
	assert_eq((line.find_child("Count", true, false) as Label).text, "3", "three clicks: three")
	var price := 3 * 10 + int(game.content.item("ginger_tea")["price"])
	assert_eq((game.menu.find_child("Total", true, false) as Label).text, str(price), "total")
	(line.find_child("Step-", true, false) as Button).pressed.emit()
	assert_eq(ShopScreen.of(game.menu).cart(TradeCart.BUY).amount("steamed_bun"), 2, "- takes one")
	(game.menu.find_child("Checkout", true, false) as Button).pressed.emit()
	assert_eq(game.profile.count("steamed_bun"), 2, "both lines bought in one go")
	assert_eq(game.profile.count("ginger_tea"), 1, "tea too")
	assert_eq(game.profile.money, 100 - price + 10, "paid once for all")
	assert_true(ShopScreen.of(game.menu).cart(TradeCart.BUY).is_empty(), "the cart is emptied")
	_done(game)


func test_a_cart_beyond_the_purse_cannot_be_bought() -> void:
	var game := _game()
	game.profile.money = 25
	game.open_shop(NPC)
	await _settle()
	_click(game, TradeCart.BUY, _row(game, TradeCart.BUY, "steamed_bun"), MOUSE_BUTTON_RIGHT)
	var cart := ShopScreen.of(game.menu).cart(TradeCart.BUY)
	assert_eq(cart.amount("steamed_bun"), ShopRules.MAX_AMOUNT, "a right click adds a stack")
	var checkout := game.menu.find_child("Checkout", true, false) as Button
	assert_true(checkout.disabled, "Buy is off while the cart costs more than the purse")
	var after := game.menu.find_child("After", true, false) as Label
	assert_true(after.text.ends_with("coins short"), after.text)
	checkout.pressed.emit()
	assert_eq(game.profile.money, 25, "nothing paid")
	_done(game)


func test_selling_many_items_at_once() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun", 3)
	game.profile.add_item("scrap_metal", 120)
	game.profile.add_item("brass_knuckles")
	game.content.items["brass_knuckles"]["rarity"] = "rare"
	game.menu_focus = "sell:"
	game.open_shop(NPC)
	await _settle()
	var tabs := game.menu.find_child("Tabs", true, false) as TabContainer
	assert_eq(tabs.current_tab, 1, "opens on Sell")
	(game.menu.find_child("AddAll", true, false) as Button).pressed.emit()
	var cart := ShopScreen.of(game.menu).cart(TradeCart.SELL)
	assert_eq(cart.amount("steamed_bun"), 3, "Add all: every bun")
	assert_eq(cart.amount("scrap_metal"), 120, "and all 120 scrap, past one deal's 99")
	assert_eq(cart.amount("brass_knuckles"), 0, "but not rare gear")
	_click(game, TradeCart.SELL, _row(game, TradeCart.SELL, "brass_knuckles"))
	assert_eq(cart.amount("brass_knuckles"), 1, "which goes in by hand")
	var money := game.profile.money
	var paid := cart.total(game.content)
	var sell := tabs.get_child(1).find_child("Checkout", true, false) as Button
	sell.pressed.emit()
	assert_eq(sell.text, "Sure?", "rare gear in the cart: it asks first")
	assert_eq(game.profile.count("scrap_metal"), 120, "nothing sold yet")
	sell.pressed.emit()
	assert_eq(game.profile.count("steamed_bun"), 0, "every bun sold")
	assert_eq(game.profile.count("scrap_metal"), 0, "all the scrap")
	assert_eq(game.profile.count("brass_knuckles"), 0, "the knuckles")
	assert_eq(game.profile.money, money + paid, "paid the total")
	game.content.items["brass_knuckles"]["rarity"] = "uncommon"
	await _settle()
	_check_layout(game.menu, "empty sell tab")
	_done(game)


func test_keys_add_change_and_settle_the_cart() -> void:
	var game := _game()
	game.profile.money = 100
	game.open_shop(NPC)
	await _settle()
	var shop := ShopScreen.of(game.menu)
	var list := game.menu.find_child("List", true, false) as ItemList
	var chosen := shop._chosen(TradeCart.BUY)
	for action: String in ["ui_accept", "ui_right", "ui_right", "ui_left"]:
		var key := InputEventAction.new()
		key.action = action
		key.pressed = true
		list.gui_input.emit(key)
	assert_eq(shop.cart(TradeCart.BUY).amount(chosen), 2, "Enter, Right, Right, Left: two")
	var settle := InputEventAction.new()
	settle.action = "attack_heavy"
	settle.pressed = true
	list.gui_input.emit(settle)
	assert_eq(game.profile.count(chosen), 2, "X settles the cart")
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
	var food: Variant = bun._get_drag_data(Vector2.ZERO)
	assert_true(food is Dictionary and food["from"] == "bag", "food drags (to the hotbar)")
	var head2 := game.menu.find_child("Worn_head", true, false) as ItemSlot
	assert_true(not head2._can_drop_data(Vector2.ZERO, food), "but never onto gear slots")
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
