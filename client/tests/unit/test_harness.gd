extends TestCase
## The measurement harness (tests/harness): its story XP model matches the
## data, its simulated runs repeat exactly with the same seed, it picks gear
## only from the data's sources, and it changes no content.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_story_alone_ends_a_little_short_of_the_cap() -> void:
	var model := ProgressionHarness.story_model(_content())
	var quests := 0
	for quest: Dictionary in _content().quests.values():
		quests += int(quest["rewards"].get("xp", 0))
	assert_eq(model["quest_xp"], quests, "every quest's XP counted once")
	var level := int(model["level"])
	# The curve slows from level 38 (the C1 ramp into 50), so the story alone
	# ends a few levels short and the farming grounds carry the hero to 50.
	assert_true(level >= 44 and level <= 47, "one story pass ends at level 44-47 (%d)" % level)
	assert_true(int(model["to_cap"]) > 0, "the cap still needs XP after the story")
	assert_eq(model["areas"].size(), StreetMemory.street(_content()).size(), "every story area")


func test_more_play_never_lowers_the_level() -> void:
	var base := int(ProgressionHarness.story_model(_content())["level"])
	var twice := ProgressionHarness.story_model(_content(), {"passes": 2})
	assert_true(int(twice["level"]) >= base, "clearing every area twice")
	assert_true(int(twice["combat_xp"]) > 0, "combat XP counted")


func test_a_run_repeats_exactly_with_the_same_seed() -> void:
	var setup := {
		"area": "saltmarket",
		"hero": "mika",
		"gear": "shop",
		"seed": 3,
		"food": {"steamed_bun": 3},
	}
	var first := ProgressionHarness.run_area(_content(), setup)
	var second := ProgressionHarness.run_area(_content(), setup)
	assert_true(first["clear"], "auto battle clears the Saltmarket")
	assert_true(not first["ko"], "and stays standing")
	for key: String in ["ticks", "xp", "coins", "scrap", "alloy", "damage_taken"]:
		assert_eq(second[key], first[key], "same seed, same %s" % key)
	assert_true(int(first["xp"]) > 0 and int(first["coins"]) > 0, "it earns XP and coins")


func test_shop_gear_comes_only_from_shops_and_quests() -> void:
	var sold := {}
	for shop: Dictionary in _content().shops.values():
		for item_id: String in ShopRules.all_items(shop):
			sold[item_id] = true
	for quest: Dictionary in _content().quests.values():
		for item_id: String in quest["rewards"].get("items", {}):
			sold[item_id] = true
	for level in [1, 10, 30, 50]:
		for item_id in ProgressionHarness.gear(_content(), level, "shop"):
			assert_true(sold.has(item_id), "%s is bought or a quest reward" % item_id)
			assert_true(
				int(_content().item(item_id).get("level", 1)) <= level, "%s fits level" % item_id
			)


func test_measuring_changes_no_content() -> void:
	var before := JSON.stringify([_content().items, _content().enemies, _content().areas])
	ProgressionHarness.story_model(_content(), {"boss_repeats": 1})
	ProgressionHarness.run_area(_content(), {"area": "canal_works", "hero": "oren", "seed": 7})
	var value := ProgressionHarness.boss_value(_content(), "sludge_foreman", 3)
	assert_true(value["unique"] != "" and value["chance"] > 0.0, "the boss's unique item")
	var after := JSON.stringify([_content().items, _content().enemies, _content().areas])
	assert_eq(after, before, "content untouched")
