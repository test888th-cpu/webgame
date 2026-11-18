extends TestCase
## The eight reference reward-source execution models (docs/REFERENCE_LOOT_REGISTRY.md
## §2.1), the monster count reconciliation and the loot relationship graph. The
## models are data in reference_loot_tables.json; their agreement with the pinned
## source functions is evidence in reward_model_verification.json (written by
## tools/content/verify_reward_models.py, which runs the real source and the model on
## the same scripted draws). Data only: nothing here rolls loot in the game.

const SOURCES: Array[String] = [
	"buddy_boss_drops",
	"world_quest_class_loot",
	"hoard_boss_loot",
	"treasure_vault_payouts",
	"rift_clear_pools",
	"rift_first_clear",
	"drowned_litany_chest",
	"weekly_boss_tables",
]


func _regs() -> Dictionary:
	return RpgRegistryLoader.load_registries(ContentDB.read_registry)


func _verification() -> Dictionary:
	return ContentDB.read_registry(
		RpgRegistryLoader.registry_dir().path_join("reward_model_verification.json")
	)


func _cites_source(entry: Dictionary) -> bool:
	return (
		str(entry.get("source", "")).begins_with("src/sim/")
		and str(entry["source"]).contains(".ts:")
	)


func test_every_reward_source_has_a_cited_execution_model() -> void:
	var sources: Dictionary = _regs()["loot_tables"]["reward_sources"]
	assert_eq(sources.keys().size(), SOURCES.size(), "eight reward sources")
	for id: String in SOURCES:
		var src: Dictionary = sources[id]
		var model: Dictionary = src["execution_model"]
		assert_true(str(src["procedure_status"]).begins_with("MODELLED"), id + ": modelled")
		assert_true(_cites_source(model["entry_point"]), id + ": entry point cited")
		assert_true(model["triggers"].size() > 0, id + ": triggers")
		assert_true(model["eligibility"].size() > 0, id + ": eligibility")
		for rule: Dictionary in model["triggers"] + model["eligibility"]:
			assert_true(_cites_source(rule), id + ": every rule cites a source line")
		assert_true(_cites_source(model["ownership"]), id + ": ownership cited")
		assert_true(model["steps"].size() > 0, id + ": ordered steps")
		for key: String in ["reset", "quantity", "currency"]:
			assert_true(str(model.get(key, "")) != "", id + ": %s inspected" % key)
		assert_true(src["model_data"].size() > 0, id + ": source data stored with the model")
		assert_eq(
			_regs()["loot_selection"]["reward_sources"][id]["adoption"],
			"DEFERRED",
			id + ": not adopted"
		)


func test_models_agree_with_the_source_functions() -> void:
	var regs := _regs()
	var evidence := _verification()
	assert_eq(evidence["result"], "PASS", "verification passed")
	assert_eq(evidence["commit"], "d2b91e0884cb269422c28d0b42d2a30a01de130a", "pinned commit")
	for id: String in SOURCES:
		var run: Dictionary = evidence["sources"][id]
		var stored: Dictionary = regs["loot_tables"]["reward_sources"][id]["execution_model"]
		assert_eq(run["model_sha256"], stored["model_sha256"], id + ": evidence for this model")
		assert_eq(run["result"], "PASS", id + ": agrees with the source")
		assert_eq(int(run["mismatches"]), 0, id + ": no mismatch")
		assert_true(int(run["scenarios"]) >= 150, id + ": many scenarios")
		assert_true(int(run["scenarios_with_rewards"]) > 0, id + ": rewards were compared")
		# Every draw step of the model ran in some scenario.
		for draw_id: String in run["draw_steps_declared"]:
			assert_true(draw_id in run["draw_steps_exercised"], "%s: %s exercised" % [id, draw_id])
		# The comparison can see a change: a mutated model disagrees.
		assert_eq(run["negative_control"]["result"], "PASS", id + ": negative control caught")
	for golden: Dictionary in evidence["sources"]["world_quest_class_loot"]["reference_goldens"]:
		assert_true(golden["pass"] and golden["cited_line_present"], str(golden["test"]))
	for golden: Dictionary in evidence["sources"]["treasure_vault_payouts"]["reference_goldens"]:
		assert_true(golden["source_pass"] and golden["model_pass"], str(golden["test"]))
	assert_true(evidence["sources"]["treasure_vault_payouts"]["allocation"]["pass"], "allocation")


func test_source_semantics_recorded_in_the_models() -> void:
	var sources: Dictionary = _regs()["loot_tables"]["reward_sources"]
	var vault := JSON.stringify(sources["treasure_vault_payouts"]["execution_model"])
	assert_true(vault.contains("guestCapped is passed in but never read"), "code over comment")
	var buddy := JSON.stringify(sources["buddy_boss_drops"]["execution_model"])
	assert_true(buddy.contains("heroicOnly"), "heroic-only rows")
	assert_true(buddy.contains("already owns"), "drawn even when owned")
	var litany := JSON.stringify(sources["drowned_litany_chest"]["execution_model"])
	assert_true(litany.contains("rng.chance(0); // draw 2 placeholder"), "the placeholder draw")
	var weekly: Dictionary = sources["weekly_boss_tables"]["execution_model"]
	assert_true(str(weekly["reset"]).begins_with("weekly"), "weekly reset recorded")
	var rift: Dictionary = sources["rift_clear_pools"]["execution_model"]
	assert_true(
		rift["related_paths"][0]["status"].begins_with("OUT OF SCOPE"), "related path recorded"
	)
	var semantics: Dictionary = _regs()["loot_tables"]["rng_semantics"]
	assert_eq(semantics["chance(p)"], "next() < p", "rng.ts chance")


func test_monster_count_reconciliation() -> void:
	var doc: Dictionary = _regs()["monsters"]
	var rec: Dictionary = doc["count_reconciliation"]
	var earlier: Dictionary = rec["earlier_text_scan"]
	assert_eq(int(earlier["count"]), 316, "the earlier text match, reproduced")
	assert_eq(int(earlier["in_MOBS"]) + int(earlier["in_STUDIO_CONTENT.mobs"]), 316, "split")
	assert_eq(int(earlier["in_STUDIO_CONTENT.mobs"]), 14, "Scorching Wastes in the overlay")
	assert_eq(earlier["registered_nowhere"], [], "nothing the scan saw is unregistered")
	assert_eq(int(rec["evaluated"]["MOBS"]), 364, "base world")
	assert_eq(int(rec["evaluated"]["STUDIO_CONTENT.mobs"]), 15, "overlay")
	var missed := 0
	var mobs := RpgMonsterRegistry.monsters(doc)
	for why: String in rec["missed_by_the_text_scan"]:
		for row: Dictionary in rec["missed_by_the_text_scan"][why]:
			missed += 1
			assert_true(mobs.has(row["id"]), str(row["id"]) + ": in the registry")
	assert_eq(missed, int(rec["missed_count"]), "every missed record classified")
	assert_eq(
		int(earlier["in_MOBS"]) + missed, 364 + 1, "302 scanned + 62 base + 1 overlay record missed"
	)
	var total := 0
	for sel: String in rec["by_selection"]:
		total += int(rec["by_selection"][sel])
	assert_eq(total, mobs.size(), "categories cover every record")
	assert_eq(rec["duplicate_ids_across_tables"], [], "no id in both tables")


func test_loot_relationship_graph() -> void:
	var graph: Dictionary = _regs()["manifest"]["loot_graph"]
	assert_eq(graph["result"], "PASS", "graph valid")
	assert_eq(graph["problems"], {}, "no orphan, duplicate or unresolved link")
	assert_eq(int(graph["counts"]["loot_tables"]), 400, "tables")
	assert_eq(int(graph["counts"]["loot_entries"]), 1190, "entries")
	assert_eq(int(graph["counts"]["quest_gated_entries"]), 67, "quest gates")
	assert_eq(int(graph["counts"]["quest_gates_resolved_in_studio_overlay"]), 9, "overlay quests")
	for id: String in SOURCES:
		assert_true(graph["reward_source_links"].has(id), id + ": linked")
