extends TestCase
## Where to get an item (ItemSources, the item card's "Where to get"): drops
## with the place they fight (street, farming field or lair), the field
## elites' prizes, the world bosses' reward rolls, shops and quests. Every
## piece of gear has at least one, so the farming loop always has a target.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _texts(item_id: String) -> Array:
	return _content().sources(item_id).map(func(s: Dictionary) -> String: return str(s["text"]))


func test_every_item_a_player_can_hold_has_a_source() -> void:
	for item_id: String in _content().items:
		var kind := str(_content().items[item_id]["type"])
		if kind in ["equipment", "material", "consumable"]:
			assert_true(not _content().sources(item_id).is_empty(), item_id + ": a source")


func test_world_boss_prizes_name_their_boss() -> void:
	for boss: String in _content().world_bosses:
		var spec: Dictionary = _content().world_bosses[boss]
		var name := str(_content().enemy(str(spec["enemy"]))["name"])
		for item_id: String in spec.get("kill", {}).get("rolls", {}):
			var kinds := _content().sources(item_id).map(
				func(s: Dictionary) -> String: return str(s["kind"])
			)
			assert_true(ItemSources.WORLD_BOSS in kinds, item_id + ": a world boss prize")
			assert_true(
				_texts(item_id).any(func(t: String) -> bool: return t.contains(name)),
				item_id + ": names " + name
			)


func test_field_elite_prizes_name_their_ground() -> void:
	for area_id in AreaRules.farms(_content()):
		var ground := str(_content().area(area_id)["name"])
		for prize: Dictionary in _content().area(area_id)["spawning"].get("elite_drops", []):
			assert_true(
				_texts(str(prize["item"])).has(
					"Field elites, %s (%d%%)" % [ground, roundi(float(prize["chance"]) * 100)]
				),
				"%s: %s from the field elites" % [area_id, prize["item"]]
			)


func test_drops_say_where_their_monster_fights() -> void:
	# A farming field's monsters and a lair's boss fight nowhere on the street.
	assert_true(_texts("coolant_rare_body").has("Vault Trooper (2%)  -  Coolant Vaults"), "field")
	assert_true(
		_texts("spillway_epic_head").has("Spillway Chief (20%)  -  Spillway Gatehouse"), "lair"
	)


func test_random_sources_come_first_most_likely_first() -> void:
	var sources := _content().sources("coolant_epic_body")
	var chances: Array = []
	for source: Dictionary in sources:
		if source.has("chance"):
			chances.append(float(source["chance"]))
	var sorted := chances.duplicate()
	sorted.sort()
	sorted.reverse()
	assert_eq(chances, sorted, "most likely first")
	assert_true(chances.size() >= 3, "the lair boss, the field elites and the champion")
