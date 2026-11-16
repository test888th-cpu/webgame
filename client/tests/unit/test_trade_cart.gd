extends TestCase
## TradeCart: a shop cart that gathers what to buy or sell and settles it in
## one checkout, all or nothing, within every limit ShopRules sets. The
## screen around it: test_trade_ui.gd.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _profile(money := 0) -> PlayerProfile:
	var p := PlayerProfile.new_game(_content())
	p.inventory.clear()
	p.money = money
	return p


func test_a_buy_cart_holds_only_wares_within_one_deal() -> void:
	var p := _profile(1000)
	var cart := TradeCart.new(TradeCart.BUY, "city_market")
	assert_eq(cart.add(p, _content(), "steamed_bun", 5), 5, "a ware goes in")
	assert_eq(cart.add(p, _content(), "steamed_bun", 500), ShopRules.MAX_AMOUNT - 5, "to 99")
	assert_eq(cart.add(p, _content(), "scrap_metal"), 0, "nothing the shop does not sell")
	var gear := TradeCart.new(TradeCart.BUY, "city_gear")
	var ware := ""
	for id in ShopRules.wares(p, _content(), "city_gear"):
		if ShopRules.max_amount(_content(), id) == 1:
			ware = id
			break
	assert_eq(gear.add(p, _content(), ware, 3), 1, "gear one at a time")
	assert_eq(cart.take("steamed_bun", 90), 90, "taken back out")
	assert_eq(cart.amount("steamed_bun"), ShopRules.MAX_AMOUNT - 90, "the rest stays")
	assert_eq(cart.take("steamed_bun", 50), ShopRules.MAX_AMOUNT - 90, "no more than is in")
	assert_true(cart.is_empty(), "and the line goes")


func test_a_cart_holds_a_limited_number_of_lines() -> void:
	var p := _profile()
	for i in TradeCart.MAX_LINES + 1:
		p.add_item("scrap_metal#%d" % i)
	var cart := TradeCart.new(TradeCart.SELL, "city_market")
	for i in TradeCart.MAX_LINES:
		assert_eq(cart.add(p, _content(), "scrap_metal#%d" % i), 1, "line %d" % i)
	assert_eq(cart.add(p, _content(), "scrap_metal#%d" % TradeCart.MAX_LINES), 0, "no more")


func test_buying_settles_every_line_at_once_or_nothing() -> void:
	var p := _profile(100)
	var cart := TradeCart.new(TradeCart.BUY, "city_market")
	cart.add(p, _content(), "steamed_bun", 3)
	cart.add(p, _content(), "ginger_tea", 2)
	var cost := 3 * 10 + 2 * int(_content().item("ginger_tea")["price"])
	assert_eq(cart.total(_content()), cost, "the total")
	var done := cart.checkout(p, _content())
	assert_eq(done, {"error": "", "items": 5, "coins": cost}, "settled")
	assert_eq([p.count("steamed_bun"), p.count("ginger_tea")], [3, 2], "both lines bought")
	assert_eq(p.money, 100 - cost, "paid once")
	assert_true(cart.is_empty(), "the cart is empty after")
	cart.add(p, _content(), "steamed_bun", 50)
	assert_eq(cart.problem(p, _content()), "not_enough_money", "beyond the purse")
	var refused := cart.checkout(p, _content())
	assert_eq(refused["error"], "not_enough_money", "refused")
	assert_eq([p.money, p.count("steamed_bun")], [100 - cost, 3], "nothing changed")
	assert_eq(cart.amount("steamed_bun"), 50, "and the cart is kept")
	assert_eq(TradeCart.new(TradeCart.BUY, "city_market").problem(p, _content()), "empty", "")


func test_selling_settles_stacks_past_one_deal_and_upgrades_ask_first() -> void:
	var p := _profile()
	p.add_item("scrap_metal", 150)
	p.add_item("brass_knuckles")
	var cart := TradeCart.new(TradeCart.SELL, "city_market")
	assert_eq(cart.add(p, _content(), "scrap_metal", 999), 150, "every one carried")
	assert_eq(cart.add(p, _content(), "scrap_metal"), 0, "and no more")
	assert_true(not cart.precious(p, _content()), "scrap needs no asking")
	cart.add(p, _content(), "brass_knuckles")
	p.enhance["brass_knuckles"] = 3
	assert_true(cart.precious(p, _content()), "an upgraded item asks first")
	var pays := cart.total(_content())
	assert_eq(
		pays,
		(
			150 * ShopRules.sell_price(_content(), "scrap_metal")
			+ ShopRules.sell_price(_content(), "brass_knuckles")
		),
		"the total"
	)
	assert_eq(cart.checkout(p, _content())["coins"], pays, "paid")
	assert_eq(p.money, pays, "into the purse")
	assert_eq(p.count("scrap_metal"), 0, "150 sold, past one deal's 99")
	assert_true(not p.enhance.has("brass_knuckles"), "its upgrades went with it")


func test_the_cart_follows_the_bag() -> void:
	var p := _profile()
	p.add_item("steamed_bun", 5)
	var cart := TradeCart.new(TradeCart.SELL, "city_market")
	cart.add(p, _content(), "steamed_bun", 5)
	p.remove_item("steamed_bun", 2)
	assert_eq(cart.problem(p, _content()), "not_owned", "eaten meanwhile")
	assert_true(cart.prune(p, _content()), "pruned")
	assert_eq(cart.amount("steamed_bun"), 3, "to what is left")
	p.remove_item("steamed_bun", 3)
	cart.prune(p, _content())
	assert_true(cart.is_empty(), "and gone when none are")
	assert_eq(cart.add(p, _content(), "steamed_bun"), 0, "nothing to add")


func test_evidence_and_worn_gear_never_go_in_a_sell_cart() -> void:
	var p := _profile()
	var key := ""
	for id: String in _content().items:
		if _content().items[id].get("type") == "key":
			key = id
			break
	p.add_item(key)
	var cart := TradeCart.new(TradeCart.SELL, "city_market")
	assert_eq(cart.add(p, _content(), key), 0, "evidence is never sold")
	p.add_item("taped_knuckles")
	p.equip("taped_knuckles", _content())
	assert_eq(cart.add(p, _content(), "taped_knuckles"), 0, "worn gear is not in the bag")
