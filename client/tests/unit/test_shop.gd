extends TestCase
## Shops (ShopRules): buying several at once, selling back at the sell rate,
## what a shop will not take, and upgrades leaving with the last copy.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _profile(money := 0) -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	profile.money = money
	profile.inventory.clear()
	return profile


func test_food_and_materials_are_bought_by_the_stack_gear_one_at_a_time() -> void:
	var profile := _profile(100)
	assert_eq(ShopRules.buy(profile, "depot_stall", "steamed_bun", _content(), 5), "", "5 buns")
	assert_eq(profile.count("steamed_bun"), 5, "all five in the bag")
	assert_eq(profile.money, 50, "paid 5 x 10")
	assert_eq(
		ShopRules.buy(profile, "depot_stall", "dock_beanie", _content(), 2),
		"bad_amount",
		"gear: one"
	)
	assert_eq(
		ShopRules.buy(profile, "depot_stall", "steamed_bun", _content(), 0), "bad_amount", "0"
	)
	assert_eq(
		ShopRules.buy(profile, "depot_stall", "steamed_bun", _content(), 6),
		"not_enough_money",
		"60 coins of buns with 50"
	)
	assert_eq(profile.money, 50, "nothing taken for a failed deal")
	assert_eq(ShopRules.affordable(profile, _content(), "steamed_bun"), 5, "5 more buns at most")
	assert_eq(ShopRules.affordable(profile, _content(), "dock_beanie"), 1, "gear: one")


func test_selling_pays_the_sell_rate_and_never_a_profit() -> void:
	var rate := float(_content().progression["sell_rate"])
	assert_true(rate > 0.0 and rate < 1.0, "a shop pays less than it asks")
	for item_id: String in _content().items:
		var price := int(_content().item(item_id).get("price", 0))
		assert_true(ShopRules.sell_price(_content(), item_id) <= price, "%s no profit" % item_id)
	var profile := _profile()
	profile.add_item("refined_alloy", 3)
	assert_eq(ShopRules.sell(profile, "refined_alloy", _content(), 2), "", "sold two")
	assert_eq(profile.money, ShopRules.sell_price(_content(), "refined_alloy") * 2, "paid for two")
	assert_eq(profile.count("refined_alloy"), 1, "one left")
	assert_eq(ShopRules.sell(profile, "refined_alloy", _content(), 2), "not_owned", "only one left")
	assert_eq(profile.count("refined_alloy"), 1, "still there")


func test_evidence_and_worn_gear_are_not_for_sale() -> void:
	var profile := _profile()
	profile.add_item("torn_label")
	assert_eq(ShopRules.sell_price(_content(), "torn_label"), 0, "evidence has no price")
	assert_eq(ShopRules.sell(profile, "torn_label", _content()), "not_for_sale", "and stays")
	var worn: String = profile.equipment["head"]
	assert_true(worn != "", "the hero wears a hat")
	assert_eq(ShopRules.sell(profile, worn, _content()), "not_owned", "take it off first")
	assert_eq(profile.equipment["head"], worn, "still worn")


func test_upgrades_leave_with_the_last_copy() -> void:
	var profile := _profile()
	profile.add_item("brass_knuckles", 2)
	profile.enhance["brass_knuckles"] = 4
	profile.enhance_pity["brass_knuckles"] = 2
	ShopRules.sell(profile, "brass_knuckles", _content())
	assert_eq(EnhanceRules.item_level(profile, "brass_knuckles"), 4, "the other copy keeps +4")
	ShopRules.sell(profile, "brass_knuckles", _content())
	assert_eq(EnhanceRules.item_level(profile, "brass_knuckles"), 0, "gone with the last one")
	assert_true(not profile.enhance_pity.has("brass_knuckles"), "and its pity too")
	profile.add_item("brass_knuckles")
	assert_eq(EnhanceRules.item_level(profile, "brass_knuckles"), 0, "one bought back is +0")
