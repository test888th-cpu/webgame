extends TestCase
## RpgRegistryLoader: registry loading outside ContentDB, and the reference and
## Iron Legacy id namespaces (docs/REFERENCE_MONSTER_REGISTRY.md "Namespaces").


func _regs() -> Dictionary:
	return RpgRegistryLoader.load_registries(ContentDB.read_registry)


func test_loader_reads_every_registry_and_the_shipped_rules() -> void:
	var regs := _regs()
	for name: String in RpgRegistryLoader.REGISTRY_FILES:
		assert_true(not (regs[name].is_empty()), name + ": loaded from data/registry")
	var content := GameSession.content
	for key: String in RpgRegistryLoader.RPG_FILES:
		assert_true(not (content.rpg[key].is_empty()), key + ": shipped rule registry loaded")
	assert_eq(RpgRegistryLoader.problems(content).size(), 0, "shipped rule registries valid")
	var missing := RpgRegistryLoader.load_registries(ContentDB.read_registry, "/nonexistent")
	for name: String in missing:
		assert_eq(missing[name], {}, name + ": an absent registry reads as empty")


func test_namespaced_ids_never_cross() -> void:
	var regs := _regs()
	var content := GameSession.content
	var ref := RpgRegistryLoader.reference_record(regs, "monsters", "reference:training_dummy")
	assert_eq(ref["selection"].split(":")[0], "NOT_AN_ENEMY", "the reference dummy")
	var own := RpgRegistryLoader.game_record(content, "monsters", "iron_legacy:training_dummy")
	assert_eq(int(own["max_hp"]), 120, "the game's own dummy")
	assert_eq(
		RpgRegistryLoader.reference_record(regs, "monsters", "iron_legacy:training_dummy"),
		{},
		"a game id never reaches the reference"
	)
	assert_eq(
		RpgRegistryLoader.game_record(content, "monsters", "reference:training_dummy"),
		{},
		"a reference id never reaches the game"
	)
	assert_eq(
		RpgRegistryLoader.reference_record(regs, "monsters", "training_dummy"),
		{},
		"a bare id is refused"
	)
	assert_eq(RpgRegistryLoader.split_id("other:x"), PackedStringArray(), "unknown namespace")


func test_collision_audit_matches_the_live_data() -> void:
	var regs := _regs()
	var content := GameSession.content
	var audit: Dictionary = regs["collisions"]
	for domain: String in ["monsters", "items"]:
		var recorded := []
		for row: Dictionary in audit[domain]["shared_bare_ids"]:
			recorded.append(row["id"])
			assert_eq(row["reference"], "reference:" + row["id"], "reference form")
			assert_eq(row["iron_legacy"], "iron_legacy:" + row["id"], "game form")
		assert_eq(
			recorded,
			RpgRegistryLoader.shared_bare_ids(content, regs, domain),
			domain + ": the audit lists exactly the shared ids"
		)
	assert_eq(audit["monsters"]["shared_bare_ids"].size(), 1, "training_dummy only")
	assert_eq(audit["items"]["shared_bare_ids"], [], "no item id collides")
	assert_eq(audit["reference_monsters_vs_reference_items"], [], "no monster id is an item id")
	assert_true(audit["loot_table_ids_unique"], "loot table ids are unique")
	for item_id: String in regs["items"]["items"]:
		assert_eq(
			regs["items"]["items"][item_id]["namespaced_id"],
			"reference:" + item_id,
			item_id + ": namespaced"
		)
