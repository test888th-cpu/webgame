extends TestCase
## Phase B2 R7 reference loot registry (docs/REFERENCE_LOOT_REGISTRY.md), against
## World of ClaudeCraft at the pinned commit: every monster's loot, the heroic
## appends and the non-LootEntry reward sources, with the source's exact chances.
## Data only: nothing here drops in the game, and the game's own loot is unchanged.

const COMMIT := "d2b91e0884cb269422c28d0b42d2a30a01de130a"


func _regs() -> Dictionary:
	return RpgRegistryLoader.load_registries(ContentDB.read_registry)


func _entries(regs: Dictionary, table_id: String) -> Array:
	return RpgLootRegistry.entries_of(regs["loot_tables"], regs["loot_entries"], table_id)


func test_source_completeness() -> void:
	var regs := _regs()
	var tables: Dictionary = RpgLootRegistry.tables(regs["loot_tables"])
	var mobs := RpgMonsterRegistry.monsters(regs["monsters"])
	assert_eq(regs["loot_tables"]["source"]["commit"], COMMIT, "pinned commit")
	for monster_id: String in mobs:
		assert_true(tables.has("mob:" + monster_id), monster_id + ": its loot table is recorded")
	var heroic := 0
	for table_id: String in tables:
		if tables[table_id]["kind"] == "heroic_append":
			heroic += 1
	assert_eq(tables.size(), mobs.size() + heroic, "one table per monster plus the appends")
	assert_eq(heroic, 21, "21 heroic appends (HEROIC_BOSS_LOOT)")
	var counts: Dictionary = regs["manifest"]["counts"]
	assert_eq(int(counts["loot_tables"]), tables.size(), "manifest tables")
	assert_eq(int(counts["loot_entries"]), regs["loot_entries"]["entries"].size(), "manifest rows")
	assert_eq(int(regs["loot_entries"]["unknown_value_count"]), 0, "no UNKNOWN loot value")
	# Tables the text parse read as empty: built by a helper or a shared constant.
	assert_eq(_entries(regs, "mob:rift_boss_brute").size(), 4, "bossLoot(...) helper")
	assert_true(_entries(regs, "mob:mere_hydra_head_center").size() > 1, "HYDRA_BLUE constant")
	var sources: Dictionary = regs["loot_tables"]["reward_sources"]
	assert_eq(sources.size(), 8, "eight reward sources outside LootEntry")
	for source_id: String in sources:
		assert_eq(sources[source_id]["unknown_values"], [], source_id + ": data fully evaluated")
		assert_true(sources[source_id]["procedure"].size() > 0, source_id + ": procedure cited")


func test_relationships_monster_table_entry_item() -> void:
	var regs := _regs()
	var items: Dictionary = regs["items"]["items"]
	var mobs := RpgMonsterRegistry.monsters(regs["monsters"])
	var problems := RpgLootRegistry.problems(regs["loot_tables"], regs["loot_entries"], items, mobs)
	assert_eq(problems.size(), 0, "loot registry valid: %s" % [problems.slice(0, 3)])
	var all := RpgRegistryLoader.registry_problems(regs)
	assert_eq(all.size(), 0, "registries and links valid: %s" % [all.slice(0, 3)])
	for monster_id: String in mobs:
		var t := RpgLootRegistry.table(regs["loot_tables"], "mob:" + monster_id)
		assert_eq(t["owner"], monster_id, monster_id + ": table owner")
		var want := (
			"world_boss_personal" if mobs[monster_id]["flags"].get("worldBoss") else "corpse"
		)
		assert_eq(t["roller"], want, monster_id + ": rolled by the source's roller")
	for source_id: String in regs["loot_tables"]["reward_sources"]:
		for item_id: String in regs["loot_tables"]["reward_sources"][source_id]["item_ids"]:
			assert_true(items.has(item_id), "%s: %s is a reference item" % [source_id, item_id])


func test_data_integrity_exact_values_and_no_forced_sums() -> void:
	var regs := _regs()
	var hydra := _entries(regs, "mob:mere_hydra_head_center")
	var totals := RpgLootRegistry.group_totals(hydra)
	# HYDRA_BLUE: four rows of 0.0875, a 35 percent group, never scaled to 100.
	assert_near(float(totals["hydra_blue"]), 0.35, "hydra group total as authored", 1e-15)
	for e: Dictionary in hydra:
		if e.get("roll_group") == "hydra_blue":
			assert_eq(e["chance"], 0.0875, "authored chance kept")
			assert_eq(e["normal_only"], true, "normalOnly kept")
	var thorn := RpgLootRegistry.table(regs["loot_tables"], "mob:nythraxis_scourge_of_thornpeak")
	# The exact double the roller accumulates, not a rounded 0.4.
	assert_eq(
		thorn["roll_group_totals"]["nythraxis_patterns"],
		0.39999999999999997,
		"double sum kept as computed"
	)
	var rows := _entries(regs, "mob:nythraxis_scourge_of_thornpeak")
	# weightedLootGroup: reserved 0.03 + 0.03, then (1 - 0.06) x 54 / 349.
	assert_eq(rows[3]["chance"], 0.14544412607449855, "derived partition share, exact")
	var copper: Dictionary = rows[0]
	assert_eq(int(copper["copper"]), 150000, "authored copper")
	assert_eq(copper["copper_roll"], {"min": 90000.0, "max": 210000.0}, "0.6x to 1.4x, inclusive")
	var range := RpgLootRegistry.copper_range(150000.0)
	assert_eq(range, Vector2i(90000, 210000), "accessor follows loot_roll.ts")
	var marrow := _entries(regs, "heroic_append:sexton_marrow")
	assert_eq(marrow[1]["preserve_source_tier"], true, "preserveSourceTier kept")


func test_rollers_cite_the_source() -> void:
	var rollers: Dictionary = _regs()["loot_tables"]["rollers"]
	assert_eq(rollers.keys().size(), RpgLootRegistry.ROLLERS.size(), "every roller described")
	for roller: String in RpgLootRegistry.ROLLERS:
		for rule: Dictionary in rollers[roller]:
			assert_true(str(rule["source"]).begins_with("src/sim/"), roller + ": cites source")
			assert_true(str(rule["source"]).contains(".ts:"), roller + ": cites a line")


func test_gameplay_separation_and_selection() -> void:
	var regs := _regs()
	var selection: Dictionary = regs["loot_selection"]
	# The game's own drop data is byte-for-byte what the registry recorded.
	var legacy: Dictionary = selection["legacy_loot"]["sha256"]
	for path: String in legacy:
		var abs := ProjectSettings.globalize_path("res://").path_join("../" + path)
		assert_eq(FileAccess.get_sha256(abs), legacy[path], path + ": legacy loot unchanged")
	for table_id: String in selection["tables"]:
		var status := RpgLootRegistry.adoption(selection, table_id)
		assert_true(status in RpgLootRegistry.ADOPTION, table_id + ": known adoption status")
		assert_true(status != "ADOPTED", table_id + ": nothing adopted")
	var item_counts: Dictionary = selection["items"]["selection_counts"]
	assert_eq(int(item_counts["PENDING_SELECTION"]), 2197, "every item decision pending")
	# The game's live tables still read only their own items and enemies.
	var content := GameSession.content
	assert_eq(content.enemies.size(), 64, "live enemies unchanged")
	assert_true(not (content.items.has("crownforged_dreadhelm")), "no reference item in play")


func test_loot_roll_semantics_are_kept_as_in_source() -> void:
	var regs := _regs()
	var entries: Dictionary = regs["loot_entries"]["entries"]
	# heroicCopper rides its own copper row; both money bands are recorded.
	var korzul: Dictionary = entries["mob:korzul_the_gravewyrm#0"]
	assert_eq(int(korzul["copper"]), 15000, "normal copper base")
	assert_eq(int(korzul["heroic_copper"]), 100000, "heroic copper base")
	assert_eq(korzul["heroic_copper_roll"], {"min": 60000.0, "max": 140000.0}, "heroic band")
	# World-boss personal loot: its roller, and the per-contributor gates.
	var balgath: Dictionary = entries["mob:balgath_cyclops#2"]
	assert_eq(int(balgath["max_player_level"]), 13, "maxPlayerLevel kept")
	assert_eq(
		RpgLootRegistry.table(regs["loot_tables"], "mob:balgath_cyclops")["roller"],
		"world_boss_personal",
		"rolled per contributor"
	)
	assert_eq(entries["mob:gourdlight_thatchgrin#2"]["unless_owned"], true, "unlessOwned kept")
	assert_eq(
		entries["mob:gourdlight_thatchgrin#3"]["unless_owned_item"],
		"reins_emberbristle_broom",
		"unlessOwnedItem kept"
	)
	# Quest gates and guaranteed rows.
	var quest: Dictionary = entries["mob:ashbone_raider#2"]
	assert_eq(quest["quest_id"], "q_dk_marrow_and_ash", "quest gate kept")
	assert_eq(quest["chance"], 0.6, "quest row chance as authored")
	var rules: Dictionary = regs["loot_tables"]["rollers"]
	var corpse := JSON.stringify(rules["corpse"])
	assert_true(corpse.contains("falls forward"), "repeated group winner falls forward")
	assert_true(corpse.contains("exactly one rng.next()"), "one draw per roll group")
	assert_true(corpse.contains("independent rng.chance"), "independent rows")
	var personal := JSON.stringify(rules["world_boss_personal"])
	assert_true(personal.contains("pay nothing"), "world-boss copper rows pay nothing")
	# Heroic appends are rolled only on a heroic claim, by their own roller.
	var append := RpgLootRegistry.table(regs["loot_tables"], "heroic_append:sexton_marrow")
	assert_eq(append["roller"], "corpse_heroic_append", "heroic append roller")
	# Procedural reward sources are documented rules, never executable loot here.
	for source_id: String in regs["loot_tables"]["reward_sources"]:
		var src: Dictionary = regs["loot_tables"]["reward_sources"][source_id]
		# Modelled and verified (test_rpg_reward_models.gd), and still labelled as
		# documented source rules, never Iron Legacy loot logic.
		var status := str(src["procedure_status"])
		assert_true(status.begins_with("MODELLED"), source_id + ": execution model present")
		assert_true(status.contains("not Iron Legacy loot logic"), source_id + ": rule only")
		assert_eq(
			regs["loot_selection"]["reward_sources"][source_id]["adoption"],
			"DEFERRED",
			source_id + ": not adopted"
		)
	# Group sums: 49 exactly 1, 46 below, none above; none was normalised.
	var at_one := 0
	var below := 0
	for table_id: String in regs["loot_tables"]["tables"]:
		var totals: Dictionary = regs["loot_tables"]["tables"][table_id]["roll_group_totals"]
		for group: String in totals:
			var total := float(totals[group])
			assert_true(total <= 1.0, "%s %s: never above 1" % [table_id, group])
			if total == 1.0:
				at_one += 1
			else:
				below += 1
	assert_eq([at_one, below], [49, 46], "group sums as the source computes them")


func test_approximated_math_never_reaches_a_registry() -> void:
	var regs := _regs()
	var audit: Dictionary = regs["manifest"]["math_audit"]
	assert_eq(int(audit["approximated_calls"]), 226, "every approximated call found")
	assert_eq(
		int(audit["calls_examined"]),
		int(audit["exact_calls"]) + int(audit["approximated_calls"]),
		"calls examined = exact + approximated"
	)
	var calls := 0
	for site: Dictionary in audit["sites"]:
		calls += int(site["calls"])
		assert_eq(site["result"], "NON_GAMEPLAY_LAYOUT_ONLY", str(site["site"]) + ": isolated")
		assert_eq(int(site["evidence"]["registry_values_reached"]), 0, str(site["site"]))
		assert_true(int(site["line"]) > 0 and str(site["file"]).begins_with("src/sim/"), "located")
		assert_true(site["functions"].size() > 0, str(site["site"]) + ": its function recorded")
	assert_eq(calls, 226, "the per-site calls add up")
	assert_eq(
		audit["approximated_calls_by_result"], {"NON_GAMEPLAY_LAYOUT_ONLY": 226.0}, "by result"
	)
	# An approximated value in a registry would be an UNKNOWN marker with sites.
	for name: String in ["monsters", "items", "loot_tables", "loot_entries"]:
		assert_true(not JSON.stringify(regs[name]).contains("implementation-approximated"), name)
	# Empirical evidence: one ulp up or down at any site changes no registry byte.
	var path := RpgRegistryLoader.registry_dir().path_join("math_perturbation_audit.json")
	var perturbation := ContentDB.read_registry(path)
	assert_eq(perturbation["sites"].size(), audit["sites"].size(), "every site perturbed")
	for site: String in perturbation["sites"]:
		for mode: String in ["up", "down"]:
			assert_eq(perturbation["sites"][site][mode], "identical", "%s %s" % [site, mode])
	for mode: String in ["up", "down"]:
		assert_eq(perturbation["all_sites_together"][mode], "identical", "all sites " + mode)
