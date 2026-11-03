extends TestCase
## Gear grades (ItemRules) and boss loot: every item is worth what its grade
## says, shops sell only Common and Uncommon, every story boss drops gear a
## clear step above the shop's, each slot has boss gear along the whole road,
## and a boss's rarest piece gets more likely the longer it does not drop
## (LootRules pity), without saving anything new.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _gear() -> Dictionary:
	var out := {}
	for id: String in _content().items:
		if _content().item(id).get("type") == "equipment":
			out[id] = _content().item(id)
	return out


## The best the shops sell for `slot` at or below `level` (score), or 0.
func _best_in_shops(slot: String, level: int) -> float:
	var best := 0.0
	for shop_id: String in _content().shops:
		for item_id: Variant in ShopRules.all_items(_content().shops[shop_id]):
			var item := _content().item(str(item_id))
			if item.get("slot") == slot and int(item.get("level", 1)) <= level:
				best = maxf(best, ItemRules.score(item))
	return best


## Every gear drop of every boss: [{"boss", "item", "chance", "pity"}].
func _boss_gear() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for enemy_id: String in _content().enemies:
		var enemy := _content().enemy(enemy_id)
		if not enemy.get("boss", false):
			continue
		for drop: Dictionary in enemy.get("loot", {}).get("drops", []):
			if _content().item(str(drop["item"])).get("type") == "equipment":
				out.append(
					{
						"boss": enemy_id,
						"item": str(drop["item"]),
						"chance": float(drop["chance"]),
						"pity": drop.get("pity", false)
					}
				)
	return out


func test_every_item_is_worth_its_grade() -> void:
	assert_eq(ItemRules.problems(_content()), PackedStringArray(), "the shipped gear is clean")
	for id: String in _gear():
		var item: Dictionary = _gear()[id]
		assert_true(item.get("rarity") in ItemRules.GRADES, id + ": a known grade")


func test_grades_step_up_in_order() -> void:
	var order := ["common", "uncommon", "rare", "epic", "legendary"]
	for i in order.size() - 1:
		assert_true(
			ItemRules.GRADES[order[i]] < ItemRules.GRADES[order[i + 1]],
			"%s is below %s" % [order[i], order[i + 1]]
		)


func test_shops_sell_only_common_and_uncommon() -> void:
	for shop_id: String in _content().shops:
		for item_id: Variant in ShopRules.all_items(_content().shops[shop_id]):
			var item := _content().item(str(item_id))
			if item.get("type") == "equipment":
				assert_true(
					item.get("rarity") in ItemRules.SHOP_GRADES, "%s sells %s" % [shop_id, item_id]
				)
	var copy := ContentDB.load_all()
	copy.shops["city_market"]["items"].append("harbour_hook")
	copy.errors.clear()
	copy.validate()
	assert_true("sells harbour_hook" in "\n".join(copy.errors), "a shop selling a boss prize")
	var weak := ContentDB.load_all()
	weak.items["harbour_hook"]["stats"] = {"power": 0.01}
	weak.errors.clear()
	weak.validate()
	assert_true("items.harbour_hook.stats: worth" in "\n".join(weak.errors), "a weak legendary")


func test_every_story_boss_drops_gear_well_above_the_shops() -> void:
	var bosses := {}
	for drop in _boss_gear():
		var item := _content().item(drop["item"])
		assert_true(item.get("rarity") in ["epic", "legendary"], drop["item"] + ": Epic or better")
		var shop := _best_in_shops(str(item["slot"]), int(item["level"]))
		var mine := ItemRules.score(item)
		assert_true(
			shop == 0.0 or mine >= shop * 1.2,
			(
				"%s (%.0f) beats the shops' %s (%.0f) by 20%%"
				% [drop["item"], mine, item["slot"], shop]
			)
		)
		bosses[drop["boss"]] = true
	for area_id in StreetMemory.street(_content()):
		for encounter: Dictionary in _content().area(area_id).get("encounters", []):
			for wave: Array in encounter["waves"]:
				for kind: String in wave:
					if _content().enemy(kind).get("boss", false):
						assert_true(bosses.has(kind), kind + ": a story boss drops gear")


func test_each_slot_has_boss_gear_along_the_whole_road() -> void:
	var levels := {}
	for drop in _boss_gear():
		var item := _content().item(drop["item"])
		if not levels.has(item["slot"]):
			levels[item["slot"]] = [1]
		levels[item["slot"]].append(int(item["level"]))
	for slot: String in ItemRules.SLOT_WEIGHTS:
		assert_true(levels.has(slot), slot + ": a boss drops one")
		var steps: Array = levels.get(slot, [1])
		steps.append(int(_content().progression["max_level"]) - 10)
		steps.sort()
		for i in steps.size() - 1:
			assert_true(
				steps[i + 1] - steps[i] <= 20,
				"%s: boss gear every 20 levels (%d to %d)" % [slot, steps[i], steps[i + 1]]
			)


func test_a_bosss_rarest_piece_is_rare_but_comes_in_the_end() -> void:
	var c := _content()
	var drop := {"item": "harbour_hook", "chance": 0.06, "pity": true}
	var profile := PlayerProfile.new_game(c)
	profile.defeated["harbourmaster_chen"] = 1
	assert_near(LootRules.chance(drop, profile, "harbourmaster_chen"), 0.06, "the first try: base")
	profile.defeated["harbourmaster_chen"] = 9
	assert_near(LootRules.chance(drop, profile, "harbourmaster_chen"), 0.06 * 3.0, "8 misses: x3")
	profile.defeated["harbourmaster_chen"] = 500
	assert_near(LootRules.chance(drop, profile, "harbourmaster_chen"), LootRules.PITY_CAP, "capped")
	profile.add_item("harbour_hook")
	assert_near(LootRules.chance(drop, profile, "harbourmaster_chen"), 0.06, "owned: base again")
	var plain := {"item": "jade_charm", "chance": 0.2}
	assert_near(LootRules.chance(plain, profile, "furnace_baron"), 0.2, "no pity on others")
	var legendary := 0
	for drop_info in _boss_gear():
		if _content().item(drop_info["item"]).get("rarity") == "legendary":
			legendary += 1
			assert_true(drop_info["pity"], drop_info["item"] + ": a legendary has pity")
			assert_true(drop_info["chance"] <= 0.1, drop_info["item"] + ": and is rare")
	assert_true(legendary >= 8, "story bosses hold legendaries (%d)" % legendary)


func test_the_pity_is_paid_by_the_zone_where_every_drop_is() -> void:
	var c := ContentDB.load_all()
	c.enemies["furnace_baron"]["loot"] = {
		"money": [0, 0], "drops": [{"item": "baron_knuckledusters", "chance": 0.1, "pity": true}]
	}
	var profile := PlayerProfile.new_game(c)
	profile.level = 12
	profile.defeated["furnace_baron"] = 500
	var zone := ZoneSim.new(c, profile, "gang_hq", "west", 1)
	var baron := zone.spawn_enemy("furnace_baron", Vector2(600, 300))
	var events: Array[ZoneEvent] = []
	var dropped := 0
	for i in 40:
		zone.pickups.clear()
		zone._defeat(baron, events)
		for pickup: Dictionary in zone.pickups:
			dropped += 1 if pickup.get("item") == "baron_knuckledusters" else 0
	assert_true(dropped >= 10, "at the cap, about half the kills drop it (%d of 40)" % dropped)


func test_field_elites_carry_their_districts_epic_prizes() -> void:
	for gid in AreaRules.farms(_content()):
		var prizes: Array = FarmSpawner.spec(_content(), gid).get("elite_drops", [])
		assert_true(not prizes.is_empty(), gid + ": its elites carry prizes")
		for prize: Dictionary in prizes:
			var item := _content().item(str(prize["item"]))
			assert_eq(item.get("rarity"), "epic", gid + ": an Epic prize")
			assert_true(float(prize["chance"]) <= 0.05, gid + ": a rare one")
			var level := int(_content().area(gid)["level"])
			assert_true(int(item["level"]) <= level, gid + ": wearable at the ground's level")


func test_spare_boss_gear_sells_by_its_grade() -> void:
	var c := _content()
	var hook := ShopRules.sell_price(c, "harbour_hook")
	var shop_weapon := ShopRules.sell_price(c, "dock_hook")
	assert_true(hook > 0, "a boss prize sells (%d)" % hook)
	assert_true(hook > shop_weapon, "for more than shop gear of its level (%d)" % shop_weapon)
	assert_eq(
		ShopRules.sell_price(c, "brass_knuckles"),
		floori(int(c.item("brass_knuckles")["price"]) * float(c.progression["sell_rate"])),
		"shop gear still sells at a share of its price"
	)
	var profile := PlayerProfile.new_game(c)
	profile.add_item("harbour_hook")
	assert_eq(ShopRules.sell(profile, "harbour_hook", c), "", "and the shop takes it")
	assert_eq(profile.money, 30 + hook, "paid")


func test_the_bag_marks_what_beats_the_worn_gear() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c, "oren")
	profile.level = 15
	profile.add_item("dock_hook")
	profile.add_item("brass_knuckles")
	profile.add_item("harbour_hook")
	profile.add_item("iron_legacy")
	assert_true(ItemRules.is_upgrade(profile, "dock_hook", c), "anything beats an empty hand")
	assert_true(profile.equip("dock_hook", c), "worn")
	assert_true(not ItemRules.is_upgrade(profile, "brass_knuckles", c), "a weaker one: no")
	assert_true(ItemRules.is_upgrade(profile, "harbour_hook", c), "the boss's: yes")
	assert_true(not ItemRules.is_upgrade(profile, "iron_legacy", c), "not before its level")
	assert_true(not ItemRules.is_upgrade(profile, "steamed_bun", c), "not food")
	var dock_hook := ItemRules.copy_score(profile, "dock_hook", c)
	profile.enhance["dock_hook"] = 5
	assert_true(ItemRules.copy_score(profile, "dock_hook", c) > dock_hook, "upgrades count")


func test_the_map_names_the_prizes_to_be_won() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	for area_id in StreetMemory.street(c):
		StreetMemory.visit(profile, area_id)
	var crane := MapRules.about(profile, c, "crane_yard", "depot_yard")
	assert_true("Legendary: Harbourmaster's Hook" in crane["prize_text"], crane["prize_text"])
	assert_true("Epic: Harbourmaster's Cap" in crane["prize_text"], "and the Epics")
	var ground := MapRules.about(profile, c, "farm_harbour_stacks", "depot_yard")
	assert_true("Epic:" in ground["prize_text"], "a ground's elite prizes")
	profile.defeated[str(WorldBossRules.spec(c, "tunnel_mother")["unlock"])] = 1
	StreetMemory.visit(profile, "great_drain")
	var drain := MapRules.about(profile, c, "great_drain", "depot_yard")
	assert_true("Legendary:" in drain["prize_text"], "a world boss's prizes")
	assert_eq(MapRules.about(profile, c, "saltmarket", "depot_yard")["prize_text"], "", "none")
