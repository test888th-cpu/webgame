extends TestCase
## Upgrade materials and "where to get": every material has a source, the
## item card's sources come from the real loot tables, shops and quests.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_every_material_can_be_found() -> void:
	for item_id: String in _content().items:
		if _content().items[item_id]["type"] == "material":
			assert_true(not _content().sources(item_id).is_empty(), "%s has a source" % item_id)


func test_sources_list_drops_by_chance_then_shops() -> void:
	var sources := _content().sources("scrap_metal")
	assert_eq(sources[0]["kind"], "drop", "drops first")
	assert_true(str(sources[0]["text"]).contains("100%"), "most likely first")
	var texts := sources.map(func(s: Dictionary) -> String: return str(s["text"]))
	assert_true(
		texts.any(func(t: String) -> bool: return t.contains("Smogling (15%)")), "a street drop"
	)
	assert_true(
		texts.any(func(t: String) -> bool: return t.contains("Ama's Stall, 30 coins")), "and a shop"
	)


func test_quest_rewards_are_sources() -> void:
	var texts := _content().sources("brass_whistle").map(
		func(s: Dictionary) -> String: return str(s["text"])
	)
	assert_true(texts.has('Quest "The Sludge Foreman"'), "the Foreman's quest gives it")


func test_every_boss_guarantees_upgrade_material() -> void:
	for enemy_id: String in _content().enemies:
		var enemy: Dictionary = _content().enemies[enemy_id]
		if not enemy.get("boss", false):
			continue
		var sure: Array = enemy["loot"]["drops"].filter(
			func(d: Dictionary) -> bool:
				return (
					float(d["chance"]) >= 1.0
					and _content().item(str(d["item"]))["type"] == "material"
				)
		)
		assert_true(not sure.is_empty(), "%s always drops material" % enemy_id)


func test_materials_can_be_discarded() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.add_item("scrap_metal", 2)
	assert_true(profile.discard("scrap_metal", _content()), "spare scrap can go")
	assert_eq(profile.count("scrap_metal"), 1, "one left")
