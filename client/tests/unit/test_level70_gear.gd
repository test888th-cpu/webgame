extends TestCase
## Gear for levels 50-70: every tier has every slot in three grades with a
## source, upgrades stay +0 to +10 but cost more for high-level items, the
## workbench previews the next level, the mythic grade is priced by the
## same budget, and the market's 50-70 stock opens with the lair bosses.

const TIERS := ["coolant", "underworks", "foundry", "heart"]
const GRADES := ["uncommon", "rare", "epic"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## The item ids that drop from `enemy_id`.
func _drops(enemy_id: String) -> Array:
	return _content().enemy(enemy_id)["loot"]["drops"].map(
		func(d: Dictionary) -> String: return str(d["item"])
	)


func test_each_tier_has_every_slot_in_three_grades() -> void:
	var c := _content()
	for tier: String in TIERS:
		var level := -1
		for grade: String in GRADES:
			for slot: String in ItemRules.SLOT_WEIGHTS:
				var item_id := "%s_%s_%s" % [tier, grade, slot]
				var item := c.item(item_id)
				assert_true(not item.is_empty(), item_id + ": exists")
				assert_eq(item.get("slot"), slot, item_id + ": slot")
				assert_eq(item.get("rarity"), grade, item_id + ": grade")
				if level < 0:
					level = int(item["level"])
				assert_eq(int(item["level"]), level, item_id + ": one level per tier")
				assert_true(level > 50 and level <= 70, item_id + ": a 50-70 piece")
	assert_eq(ItemRules.problems(c), PackedStringArray(), "every piece within its budget")


func test_every_new_piece_has_a_source() -> void:
	# Uncommon from the market, rare from the ground's monsters, epic from the
	# lair's boss: the farming loop always has a target.
	var c := _content()
	var market: Array = ShopRules.all_items(c.shops["city_market"])
	var lair_drops := []
	var field_drops := []
	for lair_id in AreaRules.lairs(c):
		for wave: Array in c.area(lair_id)["encounters"][0]["waves"]:
			for kind: String in wave:
				lair_drops.append_array(_drops(kind))
	for gid in AreaRules.farms(c):
		for kind: String in c.area(gid)["spawning"]["pool"]:
			field_drops.append_array(_drops(kind))
	for tier: String in TIERS:
		for slot: String in ItemRules.SLOT_WEIGHTS:
			assert_true("%s_uncommon_%s" % [tier, slot] in market, tier + " uncommon: sold")
			assert_true("%s_rare_%s" % [tier, slot] in field_drops, tier + " rare: dropped")
			assert_true("%s_epic_%s" % [tier, slot] in lair_drops, tier + " epic: a boss's")
	for slot: String in ItemRules.SLOT_WEIGHTS:
		var prizes := []
		for boss: String in c.world_bosses:
			var spec: Dictionary = c.world_bosses[boss]
			prizes.append_array(spec.get("kill", {}).get("rolls", {}).keys())
		var mythic := ""
		for item_id: String in c.items:
			if c.item(item_id).get("rarity") == "mythic" and c.item(item_id)["slot"] == slot:
				mythic = item_id
		assert_true(mythic in prizes, slot + ": a mythic piece from a world boss")


func test_mythic_is_priced_by_the_budget() -> void:
	var item := {"slot": "body", "rarity": "mythic", "level": 70, "stats": {}}
	var legendary := item.duplicate()
	legendary["rarity"] = "legendary"
	assert_near(
		ItemRules.budget(item) / ItemRules.budget(legendary),
		ItemRules.GRADES["mythic"] / ItemRules.GRADES["legendary"],
		"a mythic is worth its grade over a legendary",
		0.0001
	)
	assert_true(ItemRules.GRADES["mythic"] > ItemRules.GRADES["legendary"], "the top grade")


func test_upgrades_stay_at_ten_and_cost_more_for_high_level_items() -> void:
	var c := _content()
	assert_eq(EnhanceRules.max_level(c), 10, "+10 is still the top")
	var enhance: Dictionary = c.progression["enhance"]
	var bands: Array = enhance["item_level_costs"]
	for step: Dictionary in enhance["levels"]:
		var low := EnhanceRules.scaled_cost(step, bands, 50)
		var mid := EnhanceRules.scaled_cost(step, bands, 53)
		var high := EnhanceRules.scaled_cost(step, bands, 68)
		assert_eq(int(low["coins"]), int(step["coins"]), "level 50 gear: the base cost")
		assert_eq(int(mid["coins"]), roundi(int(step["coins"]) * 2.0), "from 51: x2 coins")
		assert_eq(int(high["coins"]), roundi(int(step["coins"]) * 3.0), "from 61: x3 coins")
		for item_id: String in step["items"]:
			var base := int(step["items"][item_id])
			assert_eq(int(low["items"][item_id]), base, "base materials")
			assert_eq(int(mid["items"][item_id]), roundi(base * 1.5), "x1.5 materials")
			assert_eq(int(high["items"][item_id]), roundi(base * 2.0), "x2 materials")
		assert_eq(float(high["rate"]), float(step["rate"]), "the odds never change")
	# The worn item's level picks the band, and +10 has no next step.
	var profile := PlayerProfile.new_game(c)
	profile.level = 70
	profile.add_item("heart_epic_weapon")
	profile.equip("heart_epic_weapon", c)
	var first: Dictionary = enhance["levels"][0]
	assert_eq(
		int(EnhanceRules.next_cost(profile, "weapon", c)["coins"]),
		roundi(int(first["coins"]) * 3.0),
		"a level 68 weapon pays the top band"
	)
	profile.enhance[str(profile.equipment["weapon"])] = 10
	assert_eq(EnhanceRules.next_cost(profile, "weapon", c), {}, "nothing past +10")


func test_a_failed_upgrade_keeps_the_item_and_its_level() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = 70
	profile.add_item("heart_epic_body")
	profile.equip("heart_epic_body", c)
	var key := profile.own_copy("body")
	profile.enhance[key] = 9
	profile.money = 1000000
	profile.add_item("scrap_metal", 100)
	profile.add_item("refined_alloy", 100)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var failed := false
	for i in 30:
		var coins := profile.money
		var result := EnhanceRules.attempt(profile, "body", c, rng)
		assert_true(profile.money < coins, "each try is paid")
		if result["result"] == "fail":
			failed = true
			assert_eq(str(profile.equipment["body"]), key, "the item is kept")
			assert_eq(EnhanceRules.level(profile, "body"), 9, "and its level")
			assert_true(int(profile.enhance_pity[key]) > 0, "and the next try is likelier")
			break
		profile.enhance[key] = 9
	assert_true(failed, "a 20% try fails within 30 rolls")


func test_the_preview_adds_one_level_of_bonus() -> void:
	var c := _content()
	var item := c.item("foundry_epic_hands")
	var per := float(c.progression["enhance"]["bonus_per_level"])
	for steps in [1, 5, 10]:
		var bonus := EnhanceRules.bonus_at(item, steps, c)
		for key: String in item["stats"]:
			assert_near(
				float(bonus.get(key, 0.0)),
				float(item["stats"][key]) * per * steps,
				"%s at +%d" % [key, steps],
				0.51
			)


func test_the_markets_high_level_stock_opens_with_the_lair_bosses() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	for area_id in StreetMemory.street(c):
		StreetMemory.visit(profile, area_id)
	var gated := 0
	for stock: Dictionary in c.shops["city_market"]["stock"]:
		if not stock.has("defeated"):
			continue
		gated += 1
		var boss := str(stock["defeated"])
		profile.defeated.erase(boss)
		assert_true(not ShopRules.stock_open(profile, stock), boss + ": shut before")
		for item_id: String in stock["items"]:
			if c.item(item_id).get("type") == "equipment":
				assert_true(
					item_id not in ShopRules.wares(profile, c, "city_market"), item_id + ": not yet"
				)
		profile.defeated[boss] = 1
		assert_true(ShopRules.stock_open(profile, stock), boss + ": open after")
		for item_id: String in stock["items"]:
			assert_true(item_id in ShopRules.wares(profile, c, "city_market"), item_id + ": sold")
	assert_eq(gated, 4, "one stock per tier")
	var copy := ContentDB.load_all()
	copy.shops["city_market"]["stock"].append({"defeated": "smogling", "items": ["rice_box"]})
	var said := "\n".join(ShopRules.problems(copy))
	assert_true("stock waits on a boss" in said, "only a boss opens stock")


func test_cost_bands_switch_exactly_at_their_levels() -> void:
	var enhance: Dictionary = _content().progression["enhance"]
	var step: Dictionary = enhance["levels"][9]
	var bands: Array = enhance["item_level_costs"]
	var expected := {1: 1.0, 30: 1.0, 50: 1.0, 51: 2.0, 60: 2.0, 61: 3.0, 70: 3.0}
	for item_level: int in expected:
		var cost := EnhanceRules.scaled_cost(step, bands, item_level)
		assert_eq(
			int(cost["coins"]),
			roundi(int(step["coins"]) * float(expected[item_level])),
			"item level %d: x%s coins" % [item_level, expected[item_level]]
		)
		assert_eq(float(cost["rate"]), float(step["rate"]), "the rate never moves")


func test_the_preview_is_what_the_upgrade_gives() -> void:
	# The workbench preview and the upgraded item come from the same rule
	# (EnhanceRules.bonus_at): what +N+1 shows is what the item has at +N+1.
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = 70
	profile.add_item("foundry_epic_hands")
	profile.equip("foundry_epic_hands", c)
	var key := profile.own_copy("hands")
	var item := c.item(key)
	for steps in range(0, 10):
		profile.enhance[key] = steps
		var preview := EnhanceRules.bonus_at(item, steps + 1, c)
		profile.enhance[key] = steps + 1
		var upgraded := ItemCard.upgraded(c, profile, key)
		for stat: String in item["stats"]:
			assert_near(
				float(upgraded["stats"][stat]),
				float(item["stats"][stat]) + float(preview.get(stat, 0.0)),
				"+%d %s as previewed" % [steps + 1, stat],
				0.0001
			)


func test_a_plus_ten_high_level_item_survives_a_save() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = 70
	profile.add_item("sovereign_mantle")
	profile.equip("sovereign_mantle", c)
	var key := profile.own_copy("body")
	profile.enhance[key] = 10
	var loaded := PlayerProfile.from_dict(profile.to_dict(), c)
	assert_eq(str(loaded.equipment["body"]), key, "the copy is still worn")
	assert_eq(EnhanceRules.level(loaded, "body"), 10, "at +10")
	assert_eq(EnhanceRules.next_cost(loaded, "body", c), {}, "with nothing past it")
