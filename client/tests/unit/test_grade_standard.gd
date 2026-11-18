extends TestCase
## The six item grades (owner's standard): their ids and order, their colours
## (white, green, blue, gold, red, light blue), grade comparisons by order
## not colour, and where the top grades may come from: never an ordinary
## monster for Legendary or Godforged, Godforged from world boss rewards only.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_six_grades_keep_their_ids_and_order() -> void:
	assert_eq(
		ContentDB.RARITIES,
		["common", "uncommon", "rare", "epic", "legendary", "godforged"],
		"six grades, lowest first"
	)
	for id: String in _content().items:
		var grade := str(_content().items[id].get("rarity", ""))
		assert_true(grade in ContentDB.RARITIES, "%s: a known grade (%s)" % [id, grade])


func test_each_grade_has_its_own_colour() -> void:
	var colours := ItemText.RARITY_COLORS
	assert_eq(colours.keys().size(), ContentDB.RARITIES.size(), "a colour per grade")
	var epic: Color = colours["epic"]
	assert_true(epic.r > 0.9 and epic.g > 0.7 and epic.b < 0.4, "Epic is gold: %s" % epic)
	var legendary: Color = colours["legendary"]
	assert_true(
		legendary.r > 0.9 and legendary.g < 0.4 and legendary.b < 0.4,
		"Legendary is red: %s" % legendary
	)
	var godforged: Color = colours["godforged"]
	var rare: Color = colours["rare"]
	assert_true(godforged.b > 0.9 and godforged.g > 0.85, "Godforged is light blue")
	assert_true(_distance(godforged, rare) > 0.35, "and clearly apart from Rare's blue")
	for a: String in colours:
		for b: String in colours:
			if a < b:
				assert_true(_distance(colours[a], colours[b]) > 0.25, "%s and %s differ" % [a, b])


func _distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func test_grades_compare_by_their_order() -> void:
	var last := -1
	for grade: String in ContentDB.RARITIES:
		var rank := ItemText.grade_rank({"rarity": grade})
		assert_true(rank > last, grade + " ranks above the one before")
		last = rank
	assert_eq(ItemText.grade_rank({}), -1, "no grade: below every grade")


func test_top_grades_come_only_from_their_sources() -> void:
	var c := _content()
	for kind: String in c.enemies:
		var enemy := c.enemy(kind)
		for drop: Dictionary in enemy.get("loot", {}).get("drops", []):
			var grade := str(c.item(str(drop["item"])).get("rarity"))
			assert_true(grade != "godforged", "%s drops no Godforged" % kind)
			if not enemy.get("boss", false):
				assert_true(grade != "legendary", "%s, an ordinary monster: no Legendary" % kind)
	for shop: String in c.shops:
		for item_id in ShopRules.all_items(c.shops[shop]):
			var grade := ItemText.grade_rank(c.item(item_id))
			assert_true(
				grade < ContentDB.RARITIES.find("legendary"), "%s sells no top grade" % shop
			)
	var godforged := 0
	for id: String in c.items:
		if c.items[id]["rarity"] == "godforged":
			godforged += 1
			assert_true(_world_boss_reward(c, id), "%s is a world boss reward" % id)
	assert_eq(godforged, 25, "the 25 Godforged items kept")


func _world_boss_reward(c: ContentDB, item_id: String) -> bool:
	return JSON.stringify(c.world_bosses).contains('"%s"' % item_id)


func test_the_rules_are_checked_when_content_loads() -> void:
	var c := ContentDB.load_all()
	var gear := ""
	for id: String in c.items:
		if c.items[id]["rarity"] == "godforged":
			gear = id
			break
	c.enemies["smogling"]["loot"]["drops"].append({"item": gear, "chance": 0.1})
	var said := ", ".join(c.catalog.problems(c))
	assert_true(said.contains("world boss reward only"), "Godforged refused")
	c.items[gear]["rarity"] = "legendary"
	said = ", ".join(c.catalog.problems(c))
	assert_true(said.contains("for bosses only"), "Legendary refused")
