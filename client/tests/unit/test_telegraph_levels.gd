extends TestCase
## boss_fx.json "telegraph", how loudly a hazard warns, is validated
## (BossFxRules.telegraph_problems).


func _content() -> ContentDB:
	return ContentDB.load_all()


func test_the_shipped_levels_are_valid() -> void:
	var c := _content()
	assert_eq(BossFxRules.telegraph_problems(c), PackedStringArray(), "valid as shipped")
	var rules: Dictionary = c.boss_fx["telegraph"]
	assert_eq(rules["ultimate"], "full", "Ultimates warn in full")
	assert_eq(rules["skill"], "minimal", "other skills' hazards warn minimally")


func test_a_level_outside_none_minimal_full_is_named() -> void:
	var c := _content()
	c.boss_fx["telegraph"]["skill"] = "loud"
	var said := "\n".join(BossFxRules.telegraph_problems(c))
	assert_true('boss_fx.telegraph.skill: "loud" is not one of none, minimal, full' in said, said)
	c.boss_fx["telegraph"]["typo"] = "full"
	said = "\n".join(BossFxRules.telegraph_problems(c))
	assert_true("boss_fx.telegraph.typo: unknown key" in said, said)


func test_a_per_skill_level_names_the_skill_and_its_boss() -> void:
	var c := _content()
	c.boss_fx["telegraph"]["skills"] = {
		"MB_SLUDGE_FOREMAN_002": "bright",
		"WB_FOUNDERS_ENGINE_ULT_001": "none",
		"NO_SUCH_SKILL": "full",
		"MB_SLUDGE_FOREMAN_001": "none",
	}
	var said := "\n".join(BossFxRules.telegraph_problems(c))
	assert_true(
		(
			'boss_fx.telegraph.skills.MB_SLUDGE_FOREMAN_002 (sludge_foreman): "bright" is not one of'
			in said
		),
		said
	)
	var ultimate := "boss_fx.telegraph.skills.WB_FOUNDERS_ENGINE_ULT_001 (founders_engine)"
	assert_true(ultimate + ": a hazard's warning cannot be none" in said, said)
	assert_true("boss_fx.telegraph.skills.NO_SUCH_SKILL: no such boss skill" in said, said)
	# A blow has no hazard: "none" is allowed for it.
	assert_true("MB_SLUDGE_FOREMAN_001" not in said, said)
