extends TestCase
## The item ecosystem (ItemCatalog, DropTables, EquipmentLooks, the test
## merchant's rules): new items with stable ids kept apart from their icons,
## appearances and art; drops that never give an ordinary monster's kill a
## Legendary, Godforged or boss-only item; enhancement stones paying the
## workbench; the merchant priced so buying to sell back never pays; and
## worn gear's appearance surviving a save. The game screens: see
## test_item_testing_merchant.gd.

const MONSTER := "smogling"
const BOSS := "director_wiroj"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_catalog_adds_its_items_without_touching_the_old_ones() -> void:
	var c := _content()
	assert_true(c.is_valid(), "content loads: %s" % ", ".join(c.errors))
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	assert_eq(c.items.size(), file["items"].size() + c.catalog.added.size(), "added, none replaced")
	assert_eq(c.catalog.added.size(), 56, "56 new items (19 of them the owner's hats)")
	var categories := {}
	for id in c.catalog.added:
		assert_true(not file["items"].has(id), id + ": a new id")
		var item := c.item(id)
		categories[ItemCatalog.category(item)] = true
		assert_true(item["rarity"] in ContentDB.RARITIES, id + ": one of the six grades")
		assert_true(item["rarity"] != "godforged", id + ": Godforged stays with world bosses")
		var icon := str(item["icon"])
		assert_true(icon != id, id + ": its icon has its own id")
		assert_true(c.catalog.has_placeholder_icon(icon), id + ": a placeholder icon for now")
		if item.has("appearance"):
			var look := str(item["appearance"])
			var asset := str(c.catalog.appearances[look]["asset"])
			assert_true(look != id and asset != look, id + ": appearance and art are their own ids")
	for category in ItemCatalog.CATEGORIES:
		assert_true(categories.has(category), "%s has items" % category)


func test_every_new_piece_of_gear_has_a_look_for_its_slot_and_a_fair_budget() -> void:
	var c := _content()
	var slots := {}
	for id in c.catalog.added:
		var item := c.item(id)
		if item["type"] != "equipment":
			continue
		slots[item["slot"]] = int(slots.get(item["slot"], 0)) + 1
		var look := str(item.get("appearance", ""))
		assert_eq(c.catalog.appearances[look]["slot"], item["slot"], id + ": a look for its slot")
		var budget := ItemRules.budget(item)
		assert_true(
			absf(ItemRules.score(item) - budget) <= budget * ItemRules.TOLERANCE,
			id + ": worth what its grade says"
		)
	assert_eq(slots, {"head": 24, "body": 5, "weapon": 5}, "headgear, outfits, weapons")


func test_an_ordinary_monster_never_drops_a_top_grade_or_a_boss_prize() -> void:
	var c := _content()
	for category in ItemCatalog.CATEGORIES:
		var pool := DropTables.pool_for(c, category, "monster")
		for grade: String in pool:
			assert_true(grade not in ["legendary", "godforged"], "%s: no %s" % [category, grade])
			for id: String in pool[grade]:
				assert_true(not c.item(id).get("boss_only", false), id + ": not a boss prize")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen := {}
	for kill in 40000:
		for drop: Dictionary in DropTables.roll(c, MONSTER, rng):
			var item := c.item(drop["item"])
			seen[item["rarity"]] = int(seen.get(item["rarity"], 0)) + 1
			assert_true(item["rarity"] not in ["legendary", "godforged"], "kill %d" % kill)
			assert_true(not item.get("boss_only", false), "kill %d: no boss prize" % kill)
	assert_true(int(seen.get("common", 0)) > int(seen.get("uncommon", 0)), "common the most")
	assert_true(int(seen.get("rare", 0)) > 0, "a rare one now and then")


func test_a_boss_rolls_its_own_prizes_and_better_grades() -> void:
	var c := _content()
	var monster := DropTables.grade_weights(
		c, "monster", DropTables.pool_for(c, "headgear", "monster")
	)
	var boss := DropTables.grade_weights(c, "boss", DropTables.pool_for(c, "headgear", "boss"))
	assert_true(boss.has("legendary") and not monster.has("legendary"), "Legendary: bosses only")
	assert_true(boss["rare"] > monster["rare"] and boss["epic"] > monster["epic"], "better odds")
	var odds := DropTables.chances(c, BOSS)
	assert_true(float(odds.get("wiroj_protocol_chip", 0.0)) >= 0.25, "Wiroj's own chip")
	assert_eq(
		float(DropTables.chances(c, MONSTER).get("wiroj_protocol_chip", 0.0)), 0.0, "only his"
	)
	assert_eq(
		float(DropTables.chances(c, "furnace_baron").get("wiroj_protocol_chip", 0.0)), 0.0, ""
	)
	var legendary := float(odds.get("crimson_warlord_helm", 0.0))
	assert_true(
		legendary > 0.0 and legendary < 0.01, "Legendary: under 1%% a kill (%s)" % legendary
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var got := 0
	for kill in 400:
		for drop: Dictionary in DropTables.roll(c, BOSS, rng):
			got += 1 if drop["item"] == "wiroj_protocol_chip" else 0
	assert_true(got > 60 and got < 140, "about one kill in four (%d of 400)" % got)


func test_world_bosses_training_and_their_arenas_keep_their_own_rewards() -> void:
	var c := _content()
	var rng := RandomNumberGenerator.new()
	for boss: String in c.world_bosses:
		var kind := str(c.world_bosses[boss]["enemy"])
		assert_true(DropTables.table_for(c, kind).is_empty(), kind + ": world boss rewards only")
	assert_true(DropTables.table_for(c, "training_dummy").is_empty(), "nothing from a dummy")
	var arena := {"world_boss": true}
	for kill in 2000:
		assert_true(DropTables.roll(c, MONSTER, rng, arena).is_empty(), "nothing in a raid arena")


func test_the_new_drops_change_no_fight() -> void:
	# Drops roll their own generator: the fight's stays where it would be.
	var c := _content()
	var states: Array[int] = []
	for tables: bool in [true, false]:
		var copy := ContentDB.load_all()
		if not tables:
			copy.catalog.drops["defaults"] = {"monster": "none", "boss": "none"}
		var zone := ZoneSim.new(copy, PlayerProfile.new_game(copy), "saltmarket", "west", 3)
		for n in 30:
			var foe := zone.spawn_enemy(MONSTER, zone.hero.position + Vector2(40, 0))
			foe.hp = 0
			foe.enter(Fighter.State.KO)
			zone._defeat(foe, [])
		states.append(zone.rng.state)
	assert_eq(states[0], states[1], "the same fight either way")
	assert_true(c.is_valid(), "")


func test_a_kill_puts_the_new_items_on_the_street() -> void:
	var c := _content()
	var zone := ZoneSim.new(c, PlayerProfile.new_game(c), "saltmarket", "west", 5)
	var found := {}
	for n in 400:
		var foe := zone.spawn_enemy(MONSTER, zone.hero.position + Vector2(40, 0))
		foe.hp = 0
		foe.enter(Fighter.State.KO)
		zone._defeat(foe, [])
	for pickup: Dictionary in zone.pickups:
		if pickup["kind"] == "item" and str(pickup["item"]) in c.catalog.added:
			found[pickup["item"]] = int(pickup["amount"])
	assert_true(found.size() >= 3, "several new items dropped: %s" % str(found))


func test_enhancement_stones_pay_the_workbench() -> void:
	var c := _content()
	var p := PlayerProfile.new_game(c)
	p.inventory.clear()
	p.add_item("enhance_stone_basic", 2)
	p.add_item("enhance_stone_refined", 1)
	assert_eq(EnhanceRules.available(p, c, "scrap_metal"), 5, "2 x 1 + 1 x 3")
	p.add_item("scrap_metal", 1)
	EnhanceRules._pay(p, c, "scrap_metal", 3)
	assert_eq(p.count("scrap_metal"), 0, "the real material first")
	assert_eq(p.count("enhance_stone_basic"), 0, "then the smallest stand-in")
	assert_eq(p.count("enhance_stone_refined"), 1, "the bigger one kept")
	p.money = 100000
	p.add_item("taped_knuckles")
	p.equip("taped_knuckles", c)
	p.add_item("enhance_stone_refined", 9)
	p.add_item("enhance_stone_advanced", 9)
	var rng := RandomNumberGenerator.new()
	var result := EnhanceRules.attempt(p, "weapon", c, rng)
	assert_true(result["result"] in ["success", "fail"], "an upgrade paid with stones alone")
	assert_true(p.count("enhance_stone_refined") < 10, "stones were spent")


func test_the_test_merchant_stays_out_unless_enabled_and_never_pays_to_resell() -> void:
	var c := ContentDB.load_all()
	assert_true(not c.shops.has("item_test_merchant"), "off until TEST_VENDOR_ENABLED")
	var city: Array = c.area(c.city_area)["npcs"]
	var before := city.size()
	c.catalog.enable_vendor(c)
	c.catalog.enable_vendor(c)
	assert_eq(c.area(c.city_area)["npcs"].size(), before + 1, "one merchant, once")
	var shop: Dictionary = c.shops["item_test_merchant"]
	assert_eq(shop["items"].size(), c.catalog.added.size(), "every new item")
	for id in c.catalog.added:
		var price := ShopRules.buy_price(c, "item_test_merchant", id)
		assert_true(price >= 1, id + ": costs coins")
		assert_true(price > ShopRules.sell_price(c, id), id + ": never resold at a profit")


func test_buying_every_category_costs_coins_and_fills_the_bag() -> void:
	var c := ContentDB.load_all()
	c.catalog.enable_vendor(c)
	var p := PlayerProfile.new_game(c)
	p.inventory.clear()
	p.money = 1000000
	var bought := {}
	for id in c.catalog.added:
		var cart := TradeCart.new(TradeCart.BUY, "item_test_merchant")
		assert_eq(cart.add(p, c, id, 2), mini(2, ShopRules.max_amount(c, id)), id + ": in the cart")
		var money := p.money
		var total := cart.total(c)
		assert_eq(cart.checkout(p, c)["error"], "", id + ": bought")
		assert_eq(p.money, money - total, id + ": paid")
		assert_true(p.count(id) >= 1, id + ": in the bag")
		bought[ItemCatalog.category(c.item(id))] = true
	assert_eq(bought.size(), ItemCatalog.CATEGORIES.size(), "every category")
	p.money = 0
	var broke := TradeCart.new(TradeCart.BUY, "item_test_merchant")
	broke.add(p, c, "ore_iron")
	assert_eq(broke.checkout(p, c)["error"], "not_enough_money", "nothing for free")


func test_worn_looks_follow_the_gear_and_survive_a_save() -> void:
	var c := _content()
	var p := PlayerProfile.new_game(c)
	p.level = 30
	for id: String in ["crimson_warlord_helm", "crimson_warlord_mantle", "crimson_warlord_fists"]:
		p.add_item(id)
		p.equip(id, c)
	var looks := EquipmentLooks.of(p, c)
	assert_eq(
		looks,
		{
			"head": "look_head_horned_crown",
			"body": "look_body_mantle",
			"weapon": "look_weapon_fist"
		},
		"each slot shows its gear"
	)
	var loaded := PlayerProfile.from_dict(p.to_dict(), c)
	assert_eq(EquipmentLooks.of(loaded, c), looks, "the same after a save")
	var zone := ZoneSim.new(c, loaded, "saltmarket", "west", 1)
	assert_eq(zone.hero.appearance, looks, "and on the hero in the street")
	loaded.unequip("head", c)
	zone.refresh_hero()
	assert_true(not zone.hero.appearance.has("head"), "taken off: gone")
	assert_eq(loaded.count("crimson_warlord_helm"), 1, "back in the bag")
