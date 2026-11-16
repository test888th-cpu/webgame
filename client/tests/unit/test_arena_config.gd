extends TestCase
## The arena's rival configuration (ArenaLoadout, data/arena.json): every
## slot's item, grade and upgrade set by data alone, presets, the nine tiers,
## rank and opponent overrides and which wins, validation that names what is
## wrong and never substitutes, and a running match keeping its rival.

var content: ContentDB
var _saved := {}


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
		_saved = content.arena.duplicate(true)
	return content


## The content with `change` applied to a copy of the arena configuration.
func _with(change: Callable) -> ContentDB:
	var db := _content()
	db.arena = _saved.duplicate(true)
	change.call(db.arena)
	return db


func _restore() -> void:
	content.arena = _saved.duplicate(true)


func test_the_shipped_configuration_is_valid_and_versioned() -> void:
	var db := _content()
	assert_eq(ArenaLoadout.problems(db), PackedStringArray(), "no problems")
	assert_eq(int(db.arena["config_version"]), 2, "version 2")
	var data := ArenaRules.rival(db, "r30")
	assert_eq(int(data["version"]), 2, "a rival knows its configuration's version")
	assert_true("defaults" in data["sources"][0], "built from the defaults up")
	assert_true(data["sources"].has("tier:t5"), "and its tier: %s" % str(data["sources"]))


func test_every_slot_takes_its_own_item_grade_and_upgrade() -> void:
	var db := _with(
		func(arena: Dictionary) -> void:
			arena["opponents"]["r12"] = {
				"slots":
				{
					"head": {"item": "founders_halo", "plus": 6},
					"body": {"item": "sovereign_mantle", "plus": 5},
					"hands": {"item": "sovereign_grips", "plus": 7},
					"weapon": {"item": "sovereign_fists", "plus": 10},
					"feet": {"item": "sovereign_treads", "plus": 0},
					"charm": {"item": "titan_core", "plus": 4},
				}
			}
	)
	var data := ArenaRules.rival(db, "r12")
	assert_eq(data["errors"], PackedStringArray(), "valid")
	var want := {
		"head": ["founders_halo", 6],
		"body": ["sovereign_mantle", 5],
		"hands": ["sovereign_grips", 7],
		"weapon": ["sovereign_fists", 10],
		"feet": ["sovereign_treads", 0],
		"charm": ["titan_core", 4],
	}
	for slot: String in want:
		assert_eq(data["slots"][slot]["item"], want[slot][0], slot)
		assert_eq(int(data["slots"][slot]["plus"]), want[slot][1], slot + " upgrade")
	var made := ArenaLoadout.profile(db, data)
	for slot: String in want:
		assert_eq(EnhanceRules.level(made, slot), want[slot][1], "worn at that upgrade: " + slot)
	assert_eq(EnhanceRules.max_level(db), 10, "the game's top upgrade is +10")
	_restore()


func test_grades_mix_by_slot_and_a_missing_grade_is_an_error_not_a_swap() -> void:
	var db := _with(
		func(arena: Dictionary) -> void:
			arena["opponents"]["r25"] = {
				"slots":
				{
					"weapon": {"grade": "epic"},
					"head": {"grade": "rare"},
					"charm": {"grade": "legendary"}
				}
			}
			arena["opponents"]["r24"] = {"grades": ["legendary"]}
	)
	var data := ArenaRules.rival(db, "r25")
	assert_eq(data["errors"], PackedStringArray(), "valid")
	assert_eq(data["slots"]["weapon"]["grade"], "epic", "an epic weapon")
	assert_eq(data["slots"]["head"]["grade"], "rare", "a rare head")
	assert_eq(data["slots"]["charm"]["grade"], "legendary", "a legendary charm")
	assert_eq(data["slots"]["body"]["grade"], "godforged", "the rest from the tier")
	# The real items hold no legendary body or feet: an error, never a swap.
	var broken := ArenaRules.rival(db, "r24")
	var text := ", ".join(broken["errors"])
	assert_true("r24.body: no legendary item" in text, text)
	assert_true("r24.feet: no legendary item" in text, text)
	assert_true(not broken["slots"].has("body"), "no body item put in its place")
	assert_true(not ArenaRules.fit(db, "r24"), "never offered")
	_restore()


func test_presets_pick_different_real_gear() -> void:
	var db := _content()
	var heavy := ArenaLoadout.best_item(
		db, "body", 40, ["epic"], db.arena["presets"]["heavy"]["weights"]
	)
	var guard := ArenaLoadout.best_item(
		db, "body", 40, ["epic"], db.arena["presets"]["defensive"]["weights"]
	)
	var fast := ArenaLoadout.best_item(
		db, "feet", 40, ["epic"], db.arena["presets"]["fast"]["weights"]
	)
	for id in [heavy, guard, fast]:
		assert_true(db.items.has(id), "a real item: %s" % id)
	var tiers := {}
	for rank in range(35, 30, -1):
		tiers[ArenaRules.rival(db, ArenaRules.rival_id(rank))["preset"]] = true
	assert_eq(tiers.size(), 5, "a tier of five ranks shows five builds")
	var builds := {}
	for rank in range(35, 30, -1):
		builds[str(ArenaRules.rival(db, ArenaRules.rival_id(rank))["gear"])] = true
	assert_true(builds.size() >= 3, "and they wear different gear (%d sets)" % builds.size())
	# A preset can name every item: r1 uses sovereign_full.
	var champion := ArenaRules.rival(db, "r1")
	assert_eq(champion["preset"], "sovereign_full", "r1's own preset")
	assert_eq(champion["slots"]["head"]["item"], "sovereign_crown", "its items")


func test_the_nine_tiers_follow_the_real_grades() -> void:
	var db := _content()
	var expect := {
		"r48": [["common"], 0, 0],
		"r43": [["common", "uncommon"], 0, 0],
		"r38": [["uncommon", "rare"], 0, 0],
		"r33": [["epic"], 0, 0],
		"r21": [["godforged"], 0, 0],
		"r18": [["godforged"], 1, 2],
		"r13": [["godforged"], 3, 4],
		"r8": [["godforged"], 5, 6],
		"r3": [["godforged"], 7, 7],
	}
	var tiers := {}
	for id: String in expect:
		var data := ArenaRules.rival(db, id)
		tiers[data["tier"]] = true
		for slot: String in data["slots"]:
			var worn: Dictionary = data["slots"][slot]
			assert_true(worn["grade"] in expect[id][0], "%s %s %s" % [id, slot, worn["grade"]])
			var plus := int(worn["plus"])
			assert_true(
				plus >= expect[id][1] and plus <= expect[id][2], "%s %s +%d" % [id, slot, plus]
			)
	assert_eq(tiers.size(), 9, "nine tiers")


func test_precedence_opponent_then_rank_then_tier_then_defaults() -> void:
	var db := _with(
		func(arena: Dictionary) -> void:
			arena["rank_overrides"] = [
				{"ranks": [15, 11], "ai": 0.5, "plus": 4},
				{"ranks": [12, 12], "personality": "defensive"},
			]
			arena["opponents"]["r12"] = {"ai": 0.9, "slots": {"weapon": {"plus": 9}}}
	)
	var tier_only := ArenaRules.rival(db, "r16")
	assert_near(float(tier_only["ai"]), 0.76, "r16: the tier's ai", 0.001)
	var ranked := ArenaRules.rival(db, "r13")
	assert_near(float(ranked["ai"]), 0.5, "r13: the rank override's ai")
	assert_eq(int(ranked["slots"]["head"]["plus"]), 4, "and its +4 for every slot")
	var own := ArenaRules.rival(db, "r12")
	assert_near(float(own["ai"]), 0.9, "r12: its own ai beats the rank override")
	assert_eq(own["personality"], "defensive", "the narrower rank override applies too")
	assert_eq(int(own["slots"]["weapon"]["plus"]), 9, "a per-slot +9 beats the ladder-wide +4")
	assert_eq(int(own["slots"]["head"]["plus"]), 4, "the other slots keep +4")
	assert_eq(
		own["sources"].slice(-3),
		["rank:[15, 11]", "rank:[12, 12]", "opponent:r12"],
		"the layers, weakest first"
	)
	_restore()


func test_invalid_settings_are_reported_by_name_and_never_offered() -> void:
	var cases := {
		"r40": [{"slots": {"weapon": {"item": "no_such_item"}}}, "unknown item no_such_item"],
		"r39": [{"slots": {"weapon": {"item": "sovereign_crown"}}}, "goes in head"],
		"r38": [{"slots": {"head": {"item": "sovereign_crown"}}}, "needs level 70"],
		"r37": [{"slots": {"head": {"plus": 11}}}, "outside +0..+10"],
		"r36": [{"slots": {"head": {"plus": -1}}}, "outside +0..+10"],
		"r35": [{"grades": ["mythic"]}, "unknown grade mythic"],
		"r34": [{"preset": "nope"}, "unknown preset nope"],
		"r33": [{"personality": "sleepy"}, "unknown personality sleepy"],
		"r32": [{"slots": {"weapon": {"item": "sovereign_fists", "grade": "epic"}}}, "not epic"],
		"r31": [{"level": 99}, "outside 1..70"],
	}
	var db := _with(
		func(arena: Dictionary) -> void:
			for id: String in cases:
				arena["opponents"][id] = cases[id][0]
	)
	var listed := ", ".join(ArenaLoadout.problems(db))
	for id: String in cases:
		var errors := ", ".join(ArenaRules.rival(db, id)["errors"])
		assert_true(str(cases[id][1]) in errors, "%s: %s" % [id, errors])
		assert_true(id in listed, "%s reported on load" % id)
		assert_true(not ArenaRules.fit(db, id), "%s never offered" % id)
	var reach := _profile_at(db, 41)
	for id in ArenaRules.choices(reach, db):
		assert_true(not cases.has(id), "the offer skips broken rivals: %s" % id)
	assert_true(ArenaRules.choices(reach, db).size() == 5, "and still offers five")
	var unknown := _with(func(arena: Dictionary) -> void: arena["opponents"]["r9"] = {"wings": 2})
	assert_true("unknown setting wings" in ", ".join(ArenaLoadout.problems(unknown)), "typos")
	_restore()


## A level 70 player standing at `rank`.
func _profile_at(db: ContentDB, rank: int) -> PlayerProfile:
	var p := PlayerProfile.new_game(db, "riku")
	p.level = 70
	var order: Array = ArenaRules.state(p, db)["order"]
	order.erase(ArenaRules.YOU)
	order.insert(rank - 1, ArenaRules.YOU)
	return p


func test_a_human_reaction_floor_is_enforced() -> void:
	var db := _with(
		func(arena: Dictionary) -> void: arena["opponents"]["r2"] = {"reaction_ms": 100}
	)
	var data := ArenaRules.rival(db, "r2")
	assert_true("under the human floor" in ", ".join(data["errors"]), "100 ms refused")
	assert_true(int(data["brain"]["reaction_ticks"]) >= 12, "never under 200 ms")
	_restore()
	var top := ArenaRules.rival(_content(), "r1")
	assert_eq(int(top["brain"]["reaction_ticks"]), 12, "the best reacts in 200 ms")
	assert_eq(int(ArenaRules.rival(_content(), "r50")["brain"]["reaction_ticks"]), 24, "400 ms")


func test_a_running_match_keeps_its_rival_when_the_configuration_changes() -> void:
	var db := _content()
	var p := PlayerProfile.new_game(db, "riku")
	p.level = 30
	var zone := ZoneSim.new(db, p, "pvp_arena", "", 3)
	var bout := ArenaMatch.new(zone, p, db, "r45")
	var before: Array = bout.loadout["gear"].duplicate()
	var hp := bout.rival.max_hp
	db.arena["opponents"]["r45"] = {
		"level": 70, "grades": ["godforged"], "plus": 10, "personality": "aggressive"
	}
	assert_eq(ArenaRules.rival(db, "r45")["level"], 70, "the new configuration applies")
	assert_eq(bout.loadout["gear"], before, "the running match keeps its gear")
	assert_eq(bout.rival.max_hp, hp, "and its rival")
	bout.countdown = 1
	var events: Array[ZoneEvent] = []
	bout.tick(events)
	bout.rival.state = Fighter.State.KO
	bout.tick(events)
	var history: Array = ArenaRules.state(p, db)["history"]
	assert_eq(int(history[0]["version"]), 2, "the result records the version it was fought under")
	var next := ArenaMatch.new(ZoneSim.new(db, p, "pvp_arena", "", 4), p, db, "r45")
	assert_eq(int(next.loadout["level"]), 70, "a new match uses the new configuration")
	_restore()
	assert_eq(
		p.equipment, PlayerProfile.new_game(db, "riku").equipment, "the player's gear untouched"
	)
