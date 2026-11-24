extends TestCase
## The Item Testing Merchant in the real game (TEST_VENDOR_ENABLED): it
## stands in the city, sorts its wares by category, sells through the cart
## for coins, and lets gear be tried on there; worn headgear, outfit and fist
## gear show on the hero (EquipmentLayers, temporary art) and go when taken
## off; it all survives saving and loading. The rules: test_item_catalog.gd.

const TEST_SAVE := "user://test_item_merchant"
const GAME_SCENE := preload("res://scenes/game/Game.tscn")
const GEAR: Array[String] = [
	"crimson_warlord_helm", "crimson_warlord_mantle", "crimson_warlord_fists"
]


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("riku")
	GameSession.profile.money = 100000
	GameSession.profile.level = 30
	GameSession.content.catalog.enable_vendor(GameSession.content)
	tree.root.size = Vector2i(1280, 720)
	var game: Game = GAME_SCENE.instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.enter_area(game.content.city_area, "")
	return game


func _done(game: Node) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _merchant(game: Game) -> Dictionary:
	for npc: Dictionary in game.content.area(game.content.city_area)["npcs"]:
		if npc["id"] == "item_test_merchant":
			return npc
	return {}


## A covering hat hides the head's own top rows (the old headwear) and is
## drawn over them.
func _assert_covers(game: Game, head: Sprite2D) -> void:
	var view := game.view.view_of(ZoneSim.HERO_ID)
	var sprite := view.get_node("Sprite") as AnimatedSprite2D
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var cover := EquipmentLayers.find_cover(frame.get_image())
	if sprite.flip_h:
		cover.position.x = frame.get_width() - cover.end.x
	var hidden := view.gear().hidden_rect()
	assert_eq(hidden, Rect2(sprite.offset + cover.position, cover.size), "the old headwear hidden")
	var drawn := Rect2(head.position, head.texture.get_size())
	assert_true(drawn.intersects(hidden), "and the hat drawn there: %s over %s" % [drawn, hidden])


func _gear_view(game: Game) -> EquipmentLayers:
	game.step(FighterInput.new())
	return game.view.view_of(ZoneSim.HERO_ID).gear()


func test_the_merchant_stands_in_the_city_and_sorts_its_wares() -> void:
	var game := _game()
	var npc := _merchant(game)
	assert_eq(npc.get("name"), "Item Testing Merchant", "one merchant, in the city")
	game.zone.hero.position = Vector2(float(npc["x"]) - 20.0, float(npc["y"]))
	assert_true(game.try_interact(), "E talks to it")
	await tree.process_frame
	assert_eq(game.menu_name, "shop", "its shop opens")
	var shop := ShopScreen.of(game.menu)
	var picker := game.menu.find_child("Category", true, false) as OptionButton
	assert_eq(picker.item_count, 1 + ItemCatalog.CATEGORIES.size(), "All and eight sections")
	for category in ItemCatalog.CATEGORIES:
		shop.show_category(category)
		var ids: Array = shop._pages[TradeCart.BUY]["ids"]
		assert_true(not ids.is_empty(), category + ": has wares")
		for id: String in ids:
			assert_eq(ItemCatalog.category(game.content.item(id)), category, id + " in " + category)
	_done(game)


func test_buying_wearing_and_taking_off_shows_on_the_hero() -> void:
	var game := _game()
	game.open_shop(_merchant(game))
	await tree.process_frame
	var shop := ShopScreen.of(game.menu)
	var money := game.profile.money
	for id in GEAR:
		shop.add(TradeCart.BUY, id)
	var cost := shop.cart(TradeCart.BUY).total(game.content)
	shop.checkout(TradeCart.BUY)
	assert_eq(game.profile.money, money - cost, "paid for")
	for id in GEAR:
		assert_eq(game.profile.count(id), 1, id + " in the bag")
	var layers := _gear_view(game)
	assert_true(layers == null or layers.shown().is_empty(), "nothing shows before it is worn")
	for id in GEAR:
		shop.try_on(id)
	assert_eq(game.zone.hero.appearance.size(), 3, "three looks worn")
	layers = _gear_view(game)
	await tree.process_frame
	var head := layers.get_node("Headgear") as Sprite2D
	assert_true(head.visible and head.texture != null, "the helm shows on the hero")
	assert_eq(layers.get_child_count(), 1, "only headgear is drawn: outfits keep the own look")
	_assert_covers(game, head)
	var hats := [str(game.content.item(GEAR[0])["appearance"])]
	shop.add(TradeCart.BUY, "patched_street_cap")
	shop.checkout(TradeCart.BUY)
	shop.try_on("patched_street_cap")
	layers = _gear_view(game)
	assert_eq(game.profile.equipment["head"], "patched_street_cap", "the new hat is worn")
	assert_eq(game.profile.count(GEAR[0]), 1, "the old one went back to the bag")
	assert_eq(layers.get_child_count(), 1, "still one hat drawn, not two")
	assert_true(game.zone.hero.appearance["head"] not in hats, "the new hat's look")
	shop.try_on(GEAR[0])
	for slot: String in ["head", "body", "weapon"]:
		shop.take_off(slot)
	layers = _gear_view(game)
	assert_true(not (layers.get_node("Headgear") as CanvasItem).visible, "taken off: the own look")
	for id in GEAR:
		assert_eq(game.profile.count(id), 1, id + " back in the bag")
	_done(game)


func test_worn_gear_and_its_look_survive_saving_and_loading() -> void:
	var game := _game()
	game.open_shop(_merchant(game))
	var shop := ShopScreen.of(game.menu)
	for id in GEAR:
		shop.add(TradeCart.BUY, id)
	shop.checkout(TradeCart.BUY)
	shop.try_on(GEAR[0])
	shop.try_on(GEAR[1])
	shop.add(TradeCart.BUY, "ore_iron", 5)
	shop.checkout(TradeCart.BUY)
	var id := game.profile.id
	var bag := game.profile.inventory.duplicate()
	var worn := game.profile.equipment.duplicate()
	var looks := game.zone.hero.appearance.duplicate()
	game.free()
	var loaded := SaveStore.load_character(id, GameSession.content)
	assert_eq(loaded.equipment, worn, "what was worn")
	assert_eq(loaded.inventory, bag, "what was carried")
	GameSession.profile = loaded
	var again: Game = GAME_SCENE.instantiate()
	tree.root.add_child(again)
	again.set_physics_process(false)
	again.enter_area(again.content.city_area, "")
	assert_eq(again.zone.hero.appearance, looks, "the same looks")
	var layers := _gear_view(again)
	assert_true((layers.get_node("Headgear") as CanvasItem).visible, "the helm shows again")
	_done(again)


func test_placeholder_icons_are_marked_temporary_and_told_apart() -> void:
	var c := GameSession.content
	var seen := {}
	for id in c.catalog.added:
		var icon := str(c.item(id)["icon"])
		var texture := UiKit.icon(c, icon)
		assert_true(texture != null, id + ": an icon")
		var image := texture.get_image()
		assert_eq(image.get_size(), Vector2i(16, 16), id + ": 16x16")
		if not c.catalog.placeholders["icons"][icon].has("image"):
			# Drawn placeholders carry the temporary mark; the owner's hats are art.
			assert_eq(image.get_pixel(13, 13), Color.WHITE, id + ": the temporary mark")
			assert_eq(image.get_pixel(14, 13), Color.BLACK, id + ": checked")
		seen[icon] = true
	assert_eq(seen.size(), c.catalog.added.size(), "an icon id each")
