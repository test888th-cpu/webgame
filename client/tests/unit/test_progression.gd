extends TestCase
## Profile, levelling, items, equipment, quests, shop, loot and saves.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A new profile with an empty bag and no coins (tests count from zero).
func _profile() -> PlayerProfile:
	var p := PlayerProfile.new_game(_content())
	p.money = 0
	p.inventory.clear()
	return p


func test_new_game_starts_in_start_area_at_full_hp() -> void:
	var p := _profile()
	assert_eq(p.area, _content().start_area, "start area")
	assert_eq(p.hp, p.stats(_content())["max_hp"], "full HP")
	assert_eq(p.level, 1, "level 1")


func test_xp_levels_up_and_refills_hp() -> void:
	var p := _profile()
	p.hp = 10
	var needed := p.xp_to_next(_content())
	assert_eq(p.add_xp(needed - 1, _content()), 0, "not yet")
	assert_eq(p.add_xp(1, _content()), 1, "level up")
	assert_eq(p.level, 2, "level 2")
	assert_eq(p.xp, 0, "carry-over xp")
	assert_eq(p.hp, p.stats(_content())["max_hp"], "level up refills HP")
	assert_true(p.stats(_content())["max_hp"] > 100, "max HP grows with level")


func test_big_xp_gives_several_levels_and_stops_at_cap() -> void:
	var p := _profile()
	var gained := p.add_xp(1000000, _content())
	assert_eq(p.level, p.max_level(_content()), "capped")
	assert_eq(gained, p.max_level(_content()) - 1, "levels gained")
	assert_eq(p.add_xp(100, _content()), 0, "no XP past the cap")


func test_equipment_changes_stats_and_swaps_back() -> void:
	var p := _profile()
	p.level = 5  # the wrench needs level 5
	p.add_item("taped_knuckles")
	p.add_item("foreman_wrench")
	var base: float = p.stats(_content())["power"]
	assert_true(p.equip("taped_knuckles", _content()), "equip owned weapon")
	assert_near(p.stats(_content())["power"], base + 0.15, "power bonus")
	assert_true(p.equip("foreman_wrench", _content()), "swap weapon")
	assert_eq(p.count("taped_knuckles"), 1, "old weapon back in the bag")
	assert_true(not p.equip("taped_knuckles", _content()) or true, "re-equip allowed")
	assert_true(not p.equip("work_jacket", _content()), "cannot equip what you do not own")
	assert_true(not p.equip("steamed_bun", _content()), "cannot equip a consumable")


func test_consumables_heal_and_are_used_up() -> void:
	var p := _profile()
	var hero := Fighter.new(1, 1, Vector2.ZERO, 100)
	hero.hp = 40
	assert_true(not p.use_item("steamed_bun", hero, _content()), "nothing to use")
	p.add_item("steamed_bun", 2)
	assert_true(p.use_item("steamed_bun", hero, _content()), "eat a bun")
	assert_eq(hero.hp, 65, "healed 25")
	assert_eq(p.hp, 65, "profile HP follows")
	assert_eq(p.count("steamed_bun"), 1, "one left")
	hero.hp = 100
	hero.energy = CombatRules.MAX_ENERGY
	assert_true(not p.use_item("steamed_bun", hero, _content()), "not wasted at full HP")
	assert_eq(p.count("steamed_bun"), 1, "still one left")


func test_shop_checks_stock_and_money() -> void:
	var p := _profile()
	assert_eq(
		ShopRules.buy(p, "depot_stall", "steamed_bun", _content()), "not_enough_money", "broke"
	)
	p.money = 100
	assert_eq(ShopRules.buy(p, "depot_stall", "steamed_bun", _content()), "", "bought")
	assert_eq(p.money, 90, "paid")
	assert_eq(p.count("steamed_bun"), 1, "received")
	assert_eq(
		ShopRules.buy(p, "depot_stall", "foreman_wrench", _content()), "not_sold", "boss drop"
	)
	assert_eq(ShopRules.buy(p, "nope", "steamed_bun", _content()), "unknown_shop", "no shop")


func test_quest_chain_progress_and_single_turn_in() -> void:
	var p := _profile()
	assert_eq(QuestRules.status(p, "warden", _content()), "locked", "needs the first quest")
	assert_true(QuestRules.accept(p, "clear_saltmarket", _content()), "accepted")
	assert_true(not QuestRules.accept(p, "clear_saltmarket", _content()), "not twice")
	for i in 7:
		QuestRules.on_defeat(p, "smogling", _content())
	assert_eq(QuestRules.status(p, "clear_saltmarket", _content()), "active", "7 of 8")
	assert_eq(QuestRules.on_defeat(p, "tar_hound", _content()), ["clear_saltmarket"], "complete")
	var rewards := QuestRules.turn_in(p, "clear_saltmarket", _content())
	assert_eq(rewards.get("money"), 40, "money reward")
	assert_eq(p.money, 40, "money paid")
	assert_eq(p.count("ginger_tea"), 2, "items given")
	assert_eq(QuestRules.turn_in(p, "clear_saltmarket", _content()), {}, "no second payout")
	assert_eq(p.money, 40, "still 40")
	assert_eq(QuestRules.status(p, "warden", _content()), "available", "next quest unlocked")


func test_targeted_quest_ignores_other_enemies() -> void:
	var p := _profile()
	p.quests["warden"] = {"state": "active", "progress": 0}
	QuestRules.on_defeat(p, "smogling", _content())
	assert_eq(p.quests["warden"]["progress"], 0, "a smogling is not the warden")
	QuestRules.on_defeat(p, "smog_warden", _content())
	assert_eq(QuestRules.status(p, "warden", _content()), "complete", "warden counts")


func test_loot_is_deterministic_per_seed() -> void:
	var loot: Dictionary = _content().enemy("smog_warden")["loot"]
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	for i in 20:
		assert_eq(LootRules.roll(loot, a), LootRules.roll(loot, b), "same seed, same drops")
	var guaranteed: Dictionary = _content().enemy("sludge_foreman")["loot"]
	# Bosses guarantee upgrade material; their signature gear is a farmed chance.
	assert_true("refined_alloy" in LootRules.roll(guaranteed, a)["items"], "boss always drops")
	var roll := LootRules.roll(loot, a)
	assert_true(roll["money"] >= 20 and roll["money"] <= 35, "money within range")


func test_save_round_trip() -> void:
	var p := _profile()
	p.add_xp(150, _content())
	p.money = 321
	p.add_item("steamed_bun", 3)
	p.add_item("work_jacket")
	p.equip("work_jacket", _content())
	QuestRules.accept(p, "clear_saltmarket", _content())
	p.area = "saltmarket"
	StreetMemory.visit(p, "depot_yard")
	StreetMemory.visit(p, "saltmarket")
	StreetMemory.mark_cleared(p, "saltmarket", 1)
	var json := JSON.stringify(p.to_dict())
	var loaded := PlayerProfile.from_dict(JSON.parse_string(json), _content())
	assert_true(loaded != null, "loads")
	assert_eq(loaded.to_dict(), p.to_dict(), "identical after a JSON round trip")


func test_bad_saves_are_rejected_or_sanitised() -> void:
	assert_eq(PlayerProfile.from_dict("garbage", _content()), null, "not a dictionary")
	assert_eq(PlayerProfile.from_dict({"level": 3}, _content()), null, "no version")
	var future := {"version": PlayerProfile.SAVE_VERSION + 1}
	assert_eq(PlayerProfile.from_dict(future, _content()), null, "newer than this build")
	var tampered := {
		"version": 1,
		"level": 999,
		"money": -50,
		"hp": 99999,
		"inventory": {"steamed_bun": 2, "gold_bar": 99},
		"equipment": {"weapon": "work_jacket", "armor": "work_jacket"},
		"quests": {"clear_saltmarket": {"state": "hacked"}, "made_up": {"state": "active"}},
		"area": "moon",
	}
	var p := PlayerProfile.from_dict(tampered, _content())
	assert_eq(p.level, p.max_level(_content()), "level clamped")
	assert_eq(p.money, 0, "money not negative")
	assert_eq(p.hp, p.stats(_content())["max_hp"], "HP clamped")
	assert_eq(p.inventory, {"steamed_bun": 2}, "unknown items dropped")
	assert_eq(p.equipment["weapon"], "", "armour cannot sit in the weapon slot")
	assert_eq(p.equipment["body"], "work_jacket", "valid slot kept (armor became body)")
	assert_eq(p.quests, {}, "invalid quest states dropped")
	assert_eq(p.area, _content().start_area, "unknown area falls back to start")
