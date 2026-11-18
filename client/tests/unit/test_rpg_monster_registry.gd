extends TestCase
## Phase B2 monster registry and boss/elite metadata (docs/PHASE_B2_PLAN.md R6),
## against World of ClaudeCraft's MOBS table and Studio overlay at the pinned
## commit, and the PROPOSED area candidates (tools/content/render_monster_matrix.py).
## Data only: the live enemies and areas must be unchanged.

const COMMIT := "d2b91e0884cb269422c28d0b42d2a30a01de130a"
## Counts read from the evaluated source tables (reference_registry_manifest.json).
const MOBS_COUNT := 364
const STUDIO_COUNT := 15
## Records the earlier text scan missed (factory-built or added at module load);
## a sample per mechanism.
const FOUND_BY_EVALUATION := [
	"mere_hydra_head_center",
	"tideglass_reflection_mage",
	"muster_footman",
	"varkhul_forgefather_of_the_last_flame",
]


func _registries() -> Dictionary:
	return RpgRegistryLoader.load_registries(ContentDB.read_registry)


func _monsters() -> Dictionary:
	return _registries()["monsters"]


func test_count_tables_fields_and_source() -> void:
	var regs := _registries()
	var doc: Dictionary = regs["monsters"]
	var mobs := RpgMonsterRegistry.monsters(doc)
	assert_eq(doc["source"]["commit"], COMMIT, "pinned commit")
	assert_eq(
		doc["tables"],
		{"MOBS": float(MOBS_COUNT), "STUDIO_CONTENT.mobs": float(STUDIO_COUNT)},
		"tables"
	)
	assert_eq(mobs.size(), MOBS_COUNT + STUDIO_COUNT, "every MOBS and Studio record")
	assert_eq(int(doc["count"]), mobs.size(), "count matches")
	assert_eq(int(regs["manifest"]["counts"]["monsters"]), mobs.size(), "manifest count matches")
	var items: Dictionary = regs["items"]["items"]
	var problems := RpgMonsterRegistry.problems(doc, items)
	assert_eq(problems.size(), 0, "registry valid: %s" % [problems.slice(0, 3)])
	for monster_id: String in FOUND_BY_EVALUATION:
		assert_true(mobs.has(monster_id), monster_id + ": found by evaluating the source tables")
	for monster_id: String in mobs:
		var m: Dictionary = mobs[monster_id]
		assert_true(doc["source"]["inputs"].has(m["ref"]["file"]), monster_id + ": file hashed")
		assert_true(m["stats"].has("hpBase"), monster_id + ": has base HP")


func test_every_source_field_is_kept_and_nothing_is_unknown() -> void:
	var doc := _monsters()
	assert_eq(int(doc["unknown_value_count"]), 0, "no UNKNOWN value left in any monster")
	assert_eq(doc["fields_not_in_mob_template"], {}, "every field is a MobTemplate field")
	var mobs := RpgMonsterRegistry.monsters(doc)
	# The 68 nested mechanics the text parse left UNKNOWN, a sample by shape.
	var bone: Dictionary = mobs["crypt_bone_minion"]["mechanics"]
	assert_eq(bone["trashKit"]["grow"]["into"], "crypt_bone_brute", "nested object resolved")
	assert_near(float(bone["deathThroes"]["shrapnel"]["maxHpPct"]), 0.1, "two levels deep")
	assert_eq(
		mobs["rift_boss_brute"]["mechanics"]["rankMechanics"],
		["stomp", "terrify", "deathZoneCast", "deathZoneStrike"],
		"array of mechanic ids"
	)
	assert_true(mobs["emberkin"]["mechanics"].has("petRanged"), "pet kit resolved")
	for monster_id: String in mobs:
		var m: Dictionary = mobs[monster_id]
		var fields: Dictionary = m["source_fields"]
		assert_true(not (fields.has("loot")), monster_id + ": loot lives in the loot registry")
		assert_eq(fields.get("id"), monster_id, monster_id + ": source id kept")
		assert_eq(fields.get("minLevel"), m["level"]["min"], monster_id + ": level as written")


func test_classifications_come_from_source_flags_and_rare_is_never_a_mini_boss() -> void:
	var mobs := RpgMonsterRegistry.monsters(_monsters())
	var flagged := {"boss": 0, "elite": 0, "rare": 0, "worldBoss": 0}
	var by_class := {}
	for monster_id: String in mobs:
		var m: Dictionary = mobs[monster_id]
		var c := RpgMonsterRegistry.classification(m)
		assert_eq(m["classification"], c, monster_id + ": stored classification")
		assert_true(c in RpgMonsterRegistry.CLASSIFICATIONS, monster_id + ": a source class")
		by_class[c] = int(by_class.get(c, 0)) + 1
		for flag: String in flagged:
			if m["flags"].get(flag, false):
				flagged[flag] += 1
		# Owner decision 2026-11-17: a rare spawn stays "rare"; no role beyond the source.
		assert_true(not m.has("proposed_role"), monster_id + ": no derived role")
		if m["flags"].get("rare", false) and not m["flags"].get("boss", false):
			assert_eq(c, "rare", monster_id + ": a rare spawn keeps its source class")
		if m["context"] == "dungeon":
			assert_eq(int(m["heroic_level"]), 22, monster_id + ": heroic dungeon enemies at 22")
		else:
			assert_eq(m["heroic_level"], null, monster_id + ": no heroic level outside dungeons")
	# The source's own flag counts in MOBS and the Studio overlay.
	assert_eq(flagged, {"boss": 34, "elite": 182, "rare": 26, "worldBoss": 3}, "flag counts")
	assert_true(not ("mini_boss" in RpgMonsterRegistry.CLASSIFICATIONS), "no invented class")
	assert_eq(int(by_class.get("world_boss", 0)), 3, "three world bosses")
	assert_eq(int(by_class.get("rare", 0)), 26, "26 rare spawns, all kept as rare")
	var text := FileAccess.get_file_as_string(
		RpgRegistryLoader.registry_dir().path_join("reference_monsters.json")
	)
	assert_true(not text.contains("mini_boss"), "no mini-boss anywhere in the registry")


func test_excluded_deferred_and_non_enemy_rules() -> void:
	var mobs := RpgMonsterRegistry.monsters(_monsters())
	var scorching := 0
	for monster_id: String in mobs:
		var m: Dictionary = mobs[monster_id]
		var file := str(m["ref"]["file"])
		if file == "src/sim/content/scorching_wastes.ts":
			scorching += 1
			assert_eq(RpgMonsterRegistry.selection(m), "EXCLUDED", monster_id + ": excluded")
			assert_eq(m["registry_table"], "STUDIO_CONTENT.mobs", monster_id + ": Studio overlay")
		if m["context"] == "rift":
			assert_eq(RpgMonsterRegistry.selection(m), "DEFERRED", monster_id + ": Rift deferred")
			assert_true(int(m["level"]["max"]) <= 23, monster_id + ": Rift tops out at 23")
		if m["context"] in ["player_pet", "companion", "escort_objective", "minigame_objective"]:
			assert_eq(
				RpgMonsterRegistry.selection(m), "NOT_AN_ENEMY", monster_id + ": not an enemy"
			)
		if m["flags"].get("dummy", false) or m["flags"].get("ambient", false):
			assert_eq(RpgMonsterRegistry.selection(m), "NOT_AN_ENEMY", monster_id + ": no enemy")
	assert_eq(scorching, 14, "14 Scorching Wastes monsters, all excluded")


func test_matrix_areas_roles_and_every_monster_status() -> void:
	var content := GameSession.content
	var mobs := RpgMonsterRegistry.monsters(_monsters())
	var doc := ContentDB.read_registry(
		RpgRegistryLoader.registry_dir().path_join("monster_area_candidates.json")
	)
	assert_eq(doc["areas"].size(), content.areas.size(), "every area considered (58)")
	for area_id: String in doc["areas"]:
		assert_true(content.areas.has(area_id), area_id + ": an existing area")
		var info: Dictionary = doc["areas"][area_id]
		assert_true(int(info["placement_level"]) <= 22, area_id + ": no area above 22")
		for want: String in info["slots"]:
			var slot: Dictionary = info["slots"][want]
			assert_eq(slot["empty"], slot["candidates"].is_empty(), area_id + ": empty flag")
			for c: Dictionary in slot["candidates"]:
				var m: Dictionary = mobs[c["id"]]
				assert_eq(RpgMonsterRegistry.selection(m), "PENDING_REVIEW", c["id"])
				assert_eq(
					RpgMonsterRegistry.classification(m), want, "%s fills its own class" % c["id"]
				)
				assert_true(m["context"] != "rift", c["id"] + ": no Rift enemy proposed")
	var statuses: Dictionary = doc["monsters"]
	assert_eq(statuses.size(), mobs.size(), "every reference monster has one status")
	for monster_id: String in mobs:
		var status := str(statuses[monster_id]["status"])
		var pending := RpgMonsterRegistry.selection(mobs[monster_id]) == "PENDING_REVIEW"
		var matrix_states := ["PROPOSED", "DEFERRED_THEME", "RANKED_OUT", "NO_FITTING_AREA"]
		assert_eq(status in matrix_states, pending, monster_id + ": status follows selection")
	# Mutually exclusive statuses that add up to every record (owner audit 2026-11-17).
	var totals := {}
	for monster_id: String in statuses:
		var status := str(statuses[monster_id]["status"])
		totals[status] = int(totals.get(status, 0)) + 1
	var want := {
		"PROPOSED": 118,
		"RANKED_OUT": 126,
		"DEFERRED_THEME": 28,
		"NO_FITTING_AREA": 7,
		"DEFERRED": 49,
		"EXCLUDED": 14,
		"NOT_AN_ENEMY": 37,
	}
	assert_eq(totals, want, "status totals")
	var sum := 0
	for status: String in totals:
		sum += int(totals[status])
	assert_eq(sum, mobs.size(), "the statuses cover all 379 records")
	# The matrix stays PROPOSED: no slot is approved or active.
	assert_true(not JSON.stringify(doc).contains("APPROVED"), "no approved placement")
	var underworks: Dictionary = doc["areas"]["farm_reactor_underworks"]
	assert_eq(int(underworks["placement_level"]), 21, "the level-21 ground")
	for want_role: String in underworks["slots"]:
		assert_true(underworks["slots"][want_role]["empty"], "level 21 stays empty: " + want_role)


func test_matrix_levels_and_adaptations() -> void:
	var mobs := RpgMonsterRegistry.monsters(_monsters())
	var doc := ContentDB.read_registry(
		RpgRegistryLoader.registry_dir().path_join("monster_area_candidates.json")
	)
	var register: Array = doc["adaptation_register"]
	assert_eq(register.size(), 1, "one adaptation in use")
	for field: String in ["reference", "original", "adapted", "why", "behaviour", "impact"]:
		assert_true(str(register[0].get(field, "")) != "", "the adaptation records " + field)
	var adapted := 0
	for area_id: String in doc["areas"]:
		var info: Dictionary = doc["areas"][area_id]
		var level := int(info["placement_level"])
		for want: String in info["slots"]:
			for c: Dictionary in info["slots"][want]["candidates"]:
				var m: Dictionary = mobs[c["id"]]
				# Source and placement levels are separate; the source level is as written.
				assert_eq(c["source_level"]["min"], int(m["level"]["min"]), c["id"] + ": source")
				assert_eq(int(c["placement_level"]), level, c["id"] + ": placement")
				var within: bool = (
					level >= int(m["level"]["min"]) and level <= int(m["level"]["max"])
				)
				if c.get("adaptation") != null:
					adapted += 1
					assert_eq(level, 22, c["id"] + ": the heroic adaptation is used only at 22")
					assert_eq(int(m["heroic_level"]), 22, c["id"] + ": a heroic dungeon enemy")
					assert_true(not (within), c["id"] + ": adapted only when its own range misses")
				else:
					assert_true(within, c["id"] + ": within its own source range")
		if level == 21:
			for want: String in info["slots"]:
				assert_true(info["slots"][want]["empty"], area_id + ": nothing qualifies at 21")
	assert_eq(adapted, doc["adapted_placements"].size(), "every adapted placement is listed")


func test_live_enemies_and_areas_are_unchanged() -> void:
	var content := GameSession.content
	assert_eq(content.enemies.size(), 64, "the game's 64 enemies")
	var mobs := RpgMonsterRegistry.monsters(_monsters())
	assert_eq(
		RpgRegistryLoader.shared_bare_ids(content, _registries(), "monsters"),
		["training_dummy"],
		"only the known coincidental shared id"
	)
	# The game's dummy is its own: 120 HP, not the reference's 999,999 base HP.
	assert_eq(int(content.enemy("training_dummy")["max_hp"]), 120, "the game's own dummy")
	assert_eq(
		RpgMonsterRegistry.selection(mobs["training_dummy"]),
		"NOT_AN_ENEMY",
		"reference dummy unused"
	)
	assert_eq(int(content.area("depot_yard")["level"]), 1, "area levels as before")
	assert_eq(int(content.area("heart_core_chamber")["level"]), 70, "area levels as before")
