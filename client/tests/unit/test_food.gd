extends TestCase
## Food (FoodRules): eat what fits the wound, keep the big food for trouble,
## and buy food sized to the hero, from the quick-heal key to the farm loop.

const TEST_SAVE := "user://test_food_save.json"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _carrying(items: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	profile.inventory.clear()
	for item_id: String in items:
		profile.add_item(item_id, int(items[item_id]))
	return profile


func test_it_eats_the_smallest_food_that_fills_the_gap() -> void:
	var profile := _carrying({"steamed_bun": 2, "rice_box": 1, "herbal_tonic": 1})
	assert_eq(FoodRules.choose(profile, _content(), 30), "steamed_bun", "a scratch: a bun")
	assert_eq(FoodRules.choose(profile, _content(), 150), "rice_box", "a real wound: a meal")
	assert_eq(FoodRules.choose(profile, _content(), 30, true), "herbal_tonic", "in trouble")
	assert_eq(FoodRules.choose(_carrying({}), _content(), 30), "", "nothing to eat")


func test_it_shops_for_food_sized_to_the_hero() -> void:
	var sold: Array = _content().shops["depot_stall"]["items"]
	var rookie: String = FoodRules.shopping_list(_content(), sold, 110)[0]
	var veteran: String = FoodRules.shopping_list(_content(), sold, 420)[0]
	assert_eq(rookie, "steamed_bun", "a new hero buys buns")
	assert_eq(veteran, "rice_box", "a level 30 hero buys proper meals")
	for item_id in FoodRules.shopping_list(_content(), sold, 110):
		assert_true(int(_content().item(item_id).get("heal", 0)) > 0, "%s heals" % item_id)


func test_the_farm_loop_restocks_with_the_right_food() -> void:
	var profile := _carrying({})
	profile.level = 30
	profile.money = 1000
	var bought := AutoRules.restock(profile, _content(), "depot_yard", 5, 10)
	assert_eq(bought, 5, "five foods")
	assert_eq(profile.count("rice_box"), 5, "all of them meals")
	assert_eq(FoodRules.carried(profile, _content()), 5, "and no more than asked")


func test_the_quick_heal_key_picks_the_fitting_food() -> void:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.profile.inventory.clear()
	game.profile.add_item("steamed_bun", 1)
	game.profile.add_item("rice_box", 1)
	game.zone.hero.hp = game.zone.hero.max_hp - 20
	assert_true(game.quick_heal(), "it eats")
	assert_eq(game.profile.count("steamed_bun"), 0, "the bun, for a scratch")
	assert_eq(game.profile.count("rice_box"), 1, "the meal is kept")
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH
