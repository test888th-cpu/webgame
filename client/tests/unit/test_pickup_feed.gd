extends TestCase
## Items picked up are listed small at the left of the screen (PickupFeed):
## the item's icon and its name in its grade's colour, "x2" when more come,
## at most MAX_ROWS rows, each fading after a few seconds; coins are left out.

const TEST_SAVE := "user://test_pickup_feed_save"


func test_picking_up_items_lists_them_with_their_grade_colour() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var feed: PickupFeed = game._hud.pickups
	assert_true(feed.is_inside_tree(), "on the HUD")
	var events := [
		{"kind": "item", "item": "scrap_metal", "amount": 1},
		{"kind": "money", "amount": 30},
		{"kind": "item", "item": "harbour_hook", "amount": 1},
		{"kind": "item", "item": "scrap_metal", "amount": 2},
	]
	for data: Dictionary in events:
		game._feedback.on_event(ZoneEvent.make("pickup", data))
	assert_eq(
		feed.shown(), ["scrap_metal", "harbour_hook"] as Array[String], "items only, once each"
	)
	var names := feed.find_children("Name", "Label", true, false)
	assert_eq((names[0] as Label).text, "Scrap Metal x3", "more of the same: counted")
	var hook := game.content.item("harbour_hook")
	assert_eq(
		(names[1] as Label).get_theme_color("font_color"),
		ItemText.rarity_color(hook),
		"its name in its grade's colour"
	)
	for item_id in ["rice_box", "herbal_tonic", "steamed_bun", "brass_knuckles", "work_jacket"]:
		feed.add(game.content, item_id)
	assert_eq(feed.shown().size(), PickupFeed.MAX_ROWS, "a short list")
	feed._process(PickupFeed.ROW_SECONDS + 0.1)
	assert_eq(feed.shown().size(), 0, "and it fades away")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
