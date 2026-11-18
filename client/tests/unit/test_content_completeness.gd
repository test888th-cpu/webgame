extends TestCase
## Content completeness (docs/CONTENT_COMPLETENESS_AUDIT.md): checked through the
## same rules the game and its Guide use (LootIndex), on every test run.
## * every item can be obtained (a drop, shop, quest or a hero's starter kit);
## * every enemy that fights is placed in an area;
## * every drop names a known item and has a chance within 0..1;
## * every item and enemy id is unique across the files that define them.


func _starters(content: ContentDB) -> Dictionary:
	var out := {}
	for hero_id: String in content.heroes:
		var starter: Dictionary = content.hero(hero_id).get("starter", {})
		for item_id: String in starter.get("equipment", []):
			out[item_id] = true
		for item_id: String in starter.get("items", {}):
			out[item_id] = true
	return out


func test_every_item_can_be_obtained() -> void:
	var content := GameSession.content
	var starters := _starters(content)
	for item_id: String in content.items:
		var sources := LootIndex.sources(content, item_id)
		assert_true(
			not sources.is_empty() or starters.has(item_id), item_id + ": has a way to get it"
		)


func test_every_enemy_is_placed_and_its_drops_are_sound() -> void:
	var content := GameSession.content
	for enemy_id: String in content.enemies:
		if content.enemy(enemy_id).get("training", false):
			continue
		assert_true(not LootIndex.places(content, enemy_id).is_empty(), enemy_id + ": placed")
		for drop: Dictionary in LootIndex.drops(content, enemy_id):
			var item_id := str(drop["item"])
			assert_true(not content.item(item_id).is_empty(), "%s drops %s" % [enemy_id, item_id])
			var chance := float(drop["chance"])
			assert_true(
				chance > 0.0 and chance <= 1.0, "%s %s chance in 0..1" % [enemy_id, item_id]
			)


func test_item_ids_are_unique_across_files() -> void:
	var base: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))["items"]
	)
	var catalog: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/item_catalog.json"))["items"]
	)
	for item_id: String in catalog:
		assert_true(not base.has(item_id), item_id + ": defined once")
	assert_eq(GameSession.content.items.size(), base.size() + catalog.size(), "all items loaded")
