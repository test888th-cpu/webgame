extends TestCase
## Each farming ground's "toughness" (multipliers on its enemies, set with
## FarmCheck so grounds rise in step with their level) and its own "drops"
## (the Uncommon and Rare gear of its band, which no shop sells), the owner's
## requests of November 2026.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _zone(c: ContentDB, gid: String) -> ZoneSim:
	var profile := PlayerProfile.new_game(c)
	profile.level = int(c.area(gid)["level"])
	var zone := ZoneSim.new(c, profile, gid, "west", 5)
	for tick in 3:
		zone.tick(FighterInput.new())
	return zone


func test_a_grounds_enemies_are_as_tough_as_it_asks() -> void:
	var c := _content()
	for gid in AreaRules.farms(c):
		var toughness: Dictionary = FarmSpawner.spec(c, gid).get("toughness", {})
		var zone := _zone(c, gid)
		assert_true(not zone.enemies().is_empty(), gid + ": camps stand")
		for enemy in zone.enemies():
			if enemy.elite:
				continue
			var base := LevelRules.enemy_stats(c.enemy(enemy.kind), zone.enemy_level(enemy.id))
			var want := roundi(int(base["max_hp"]) * float(toughness.get("hp", 1.0)))
			assert_eq(enemy.max_hp, want, "%s: %s's HP" % [gid, enemy.kind])


func test_every_enemy_on_a_ground_may_drop_its_prizes() -> void:
	var c := _content()
	for gid in AreaRules.farms(c):
		var drops: Array = FarmSpawner.spec(c, gid).get("drops", [])
		assert_true(not drops.is_empty(), gid + ": prizes of its own")
		var level := int(c.area(gid)["level"])
		for prize: Dictionary in drops:
			var item := c.item(str(prize["item"]))
			assert_true(item["rarity"] in ["uncommon", "rare"], prize["item"] + ": a field grade")
			assert_true(absi(int(item["level"]) - level) <= 7, prize["item"] + ": of its band")
			var texts := ItemSources.of(c, str(prize["item"])).map(
				func(source: Dictionary) -> String: return str(source["text"])
			)
			var here := "Any enemy, " + str(c.area(gid)["name"])
			assert_true(texts.any(func(t: String) -> bool: return t.begins_with(here)), str(texts))
		var zone := _zone(c, gid)
		var enemy: Fighter = zone.enemies()[0]
		var loot: Array = zone._enemy_level[enemy.id]["stats"]["loot"]["drops"]
		for prize: Dictionary in drops:
			assert_true(prize in loot, "%s: %s on %s" % [gid, prize["item"], enemy.kind])


func test_no_uncommon_piece_is_out_of_reach() -> void:
	# The gear stall sells Common only, so every Uncommon piece must drop.
	var c := _content()
	for item_id: String in c.items:
		var item := c.item(item_id)
		if item.get("type") == "equipment" and item.get("rarity") == "uncommon":
			assert_true(not ItemSources.of(c, item_id).is_empty(), item_id + ": somewhere to get")


func test_the_validator_keeps_toughness_in_range() -> void:
	var broken := ContentDB.load_all()
	broken.areas["farm_iron_heart"]["spawning"]["toughness"] = {"hp": 0.5, "power": 9.0}
	var said := "\n".join(FarmSpawner.problems(broken))
	assert_true(".toughness.hp: 1 to" in said, said)
	assert_true(".toughness.power: 1 to" in said, said)
