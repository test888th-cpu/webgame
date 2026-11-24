extends TestCase
## The reference RPG formulas (Rpg* modules) reproduce World of ClaudeCraft at
## d2b91e08. Expected values are the reference's own test values where it has
## them (tests/mana_regen.test.ts, tests/item_level.test.ts,
## tests/combat_rating.test.ts), otherwise its formulas worked by hand
## (docs/RPG_CORE_PHASE1_SPEC.md §D). These modules are not wired into
## gameplay yet; this pins them before they are.

const DATA := "res://data/rpg_reference.json"

var _classes: Dictionary


func _class(id: String) -> Dictionary:
	if _classes.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_classes = parsed["classes"]
	return _classes[id]


func test_rating_conversions_match_the_reference_tests() -> void:
	assert_near(RpgStats.haste_from_rating(150), 0.075, "150 haste rating")
	assert_near(RpgStats.crit_from_rating(20), 0.01, "20 crit rating")
	assert_near(RpgStats.hit_from_rating(50), 0.05, "50 hit rating")


func test_stamina_and_intellect_pools() -> void:
	assert_eq(RpgStats.hp_from_stamina(20), 20, "first 20 Stamina: 1 HP each")
	assert_eq(RpgStats.hp_from_stamina(60), 420, "then 10 HP each")
	assert_eq(RpgStats.hp_from_stamina(-5), 0, "never negative")
	assert_eq(RpgStats.mana_from_intellect(81), 935, "20 + 61 x 15")


func test_level_20_sheets_match_the_worked_reference_values() -> void:
	var w := RpgStats.sheet(_class("warrior"), 20)
	assert_eq(w["max_hp"], 812, "warrior HP 50 + 18x19 + 420")
	assert_eq(w["armor"], 356, "warrior armor 278 + 2 x 39 Agi")
	assert_eq(w["attack_power"], 122, "warrior AP 2 x 61 Str")
	assert_near(w["crit"], 0.0695, "warrior crit 5% + 39 x 0.05%")
	assert_near(w["dodge"], 0.0695, "warrior dodge 5% + 39 x 0.05%")
	assert_eq(w["max_resource"], 100, "rage caps at 100")
	var r := RpgStats.sheet(_class("rogue"), 20)
	assert_eq(r["max_hp"], 700, "rogue HP")
	assert_eq(r["attack_power"], 118, "rogue AP Str + Agi")
	var h := RpgStats.sheet(_class("hunter"), 20)
	assert_eq(h["ranged_attack_power"], 164, "hunter RAP 2 x 82 Agi")
	var m := RpgStats.sheet(_class("mage"), 20)
	assert_eq(m["max_resource"], 1491, "mage mana 100 + 24x19 + 935")
	assert_eq(m["spell_power"], 41, "mage SP round(81 x 0.5)")
	assert_near(m["spell_crit"], 0.1148, "mage spell crit 5% + 81 x 0.08%")


func test_hit_table_matches_the_reference() -> void:
	assert_near(RpgHitTable.melee_miss_chance(20, 23), 0.19, "reference test: +3 levels")
	assert_near(RpgHitTable.melee_miss_chance(20, 20), 0.05, "equal level")
	assert_near(RpgHitTable.melee_miss_chance(20, 21), 0.075, "+1")
	assert_near(RpgHitTable.melee_miss_chance(20, 30), 0.19, "saturates past +3")
	assert_near(RpgHitTable.melee_miss_chance(20, 15), 0.04, "-0.2% per level below")
	assert_near(RpgHitTable.spell_hit_chance(20, 20), 0.96, "spell hit equal level")
	assert_near(RpgHitTable.spell_hit_chance(20, 22), 0.88, "spell hit +2")
	assert_near(
		RpgHitTable.swing_miss_chance(10, 30, true), 0.19, "mob vs player: min(19%, the 20% cap)"
	)
	assert_near(RpgHitTable.swing_miss_chance(20, 20, false, 0.08), 0.0, "hit rating floors at 0")
	assert_eq(RpgHitTable.resolve(0.01, 0.05, 0.05), "miss", "roll under miss")
	assert_eq(RpgHitTable.resolve(0.07, 0.05, 0.05), "dodge", "then dodge")
	assert_eq(RpgHitTable.resolve(0.11, 0.05, 0.05, 0.05), "parry", "then parry")
	assert_eq(RpgHitTable.resolve(0.5, 0.05, 0.05, 0.05, 0.05), "hit", "else hit")


func test_armor_reduction_matches_the_reference() -> void:
	assert_near(RpgHitTable.armor_reduction(356, 20), 0.14495, "356 armor vs Lv 20", 0.0001)
	assert_near(RpgHitTable.armor_reduction(356, 1), 0.42332, "356 armor vs Lv 1", 0.0001)
	assert_near(RpgHitTable.armor_reduction(1e9, 1), 0.75, "capped at 75%")
	var full := RpgHitTable.armor_reduction(356, 10)
	assert_near(
		RpgHitTable.mob_armor_reduction(356, 10, 13, true), 0.2, "3+ levels down: the 20% cap"
	)
	assert_near(RpgHitTable.mob_armor_reduction(356, 10, 10, true), full, "same level: full DR")


func test_melee_and_ranged_damage() -> void:
	# Lv 20 warrior (AP 122) with worn_sword (2-5, 2.0 s): average roll 3.5.
	assert_near(RpgDamage.melee_hit(3.5, 122, 2.0, false), 20.92857, "white swing", 0.0001)
	assert_near(RpgDamage.melee_hit(3.5, 122, 2.0, true), 41.85714, "x2 on a crit", 0.0001)
	assert_eq(RpgDamage.after_armor(20.92857, 0.14495), 18, "after 356 armor")
	assert_eq(RpgDamage.after_armor(0.2, 0.5), 1, "at least 1")
	assert_near(RpgDamage.ranged_hit(7.0, 164, 2.3, false), 33.94286, "hunter shot", 0.0001)
	assert_near(RpgDamage.weapon_roll({"min": 2, "max": 5}, 0.5), 3.5, "roll midpoint")
	assert_near(RpgDamage.normalized_speed({"dagger": true}), 1.7, "dagger normalized")
	assert_near(RpgDamage.direct_coefficient(1.5), 0.42857, "1.5 s cast", 0.0001)
	assert_near(RpgDamage.direct_coefficient(6.0), 1.0, "capped at 1")
	assert_near(RpgDamage.dot_coefficient(15.0), 1.0, "15 s DoT")
	assert_near(RpgDamage.spell_crit(100.0, true), 150.0, "spell crit x1.5")


func test_resources_match_the_reference_tests() -> void:
	assert_near(RpgResources.spirit_regen_per_tick(60, 20), 28.0, "mana_regen.test: 28")
	assert_near(RpgResources.spirit_regen_per_tick(60, 20, 0.5), 42.0, "with +50%")
	assert_near(RpgResources.spirit_regen_per_tick(0, 1), 4.0, "floor 4")
	assert_eq(RpgResources.mana_regen_per_tick(60, 20, 99.0), 28, "out of combat: full")
	assert_eq(RpgResources.mana_regen_per_tick(60, 20, 0.0), 8, "in combat: 30%")
	assert_eq(RpgResources.mana_regen_per_tick(60, 20, 0.0, 0.5), 13, "in combat with +50%")
	assert_near(RpgResources.rage_conversion(20), 72.51, "c(20)", 0.001)
	assert_near(RpgResources.gcd(), 1.5, "GCD")
	assert_near(RpgResources.gcd(10.0), 0.75, "floored at 0.75 s")
	assert_near(RpgResources.swing_interval(2.0, 0.25), 1.6, "2.0 s weapon, +25% haste")
	assert_eq(RpgResources.hp_regen_per_tick(60), 20, "60 Sta x 0.3 + 2")


func test_item_budget_matches_the_reference_tests() -> void:
	assert_eq(RpgItemBudget.primary_stat_budget(10, "common", "chest"), 0, "whites: none")
	assert_eq(RpgItemBudget.primary_stat_budget(10, "rare", "chest"), 6, "item_level.test")
	assert_eq(RpgItemBudget.primary_stat_budget(13, "rare", "mainhand"), 7, "item_level.test")
	assert_true(
		(
			RpgItemBudget.primary_stat_budget(13, "rare", "feet")
			< RpgItemBudget.primary_stat_budget(13, "rare", "chest")
		),
		"smaller slots below chest"
	)
	assert_near(RpgItemBudget.weapon_dps_budget(20), 12.7, "6.7 + 0.3 x 20")
	assert_near(RpgItemBudget.weapon_dps_budget(20, true), 14.605, "two-hand x1.15", 0.0001)
	assert_eq(RpgItemBudget.item_level(22, "epic"), 28, "heroic epic: 22 + 6")
	var scaled := RpgItemBudget.scale_weapon_damage({"min": 2, "max": 5, "speed": 2.0}, 12.7)
	assert_eq([scaled["min"], scaled["max"]], [15, 36], "spread kept at 12.7 DPS")


func test_mob_stats_and_xp() -> void:
	var template := {
		"hp_base": 50,
		"hp_per_level": 20,
		"dmg_base": 4,
		"dmg_per_level": 1.5,
		"attack_speed": 2.0,
		"armor_per_level": 10
	}
	var s := RpgMobs.stats(template, 10)
	assert_eq(s["max_hp"], 230, "50 + 20 x 9")
	assert_eq([s["weapon"]["min"], s["weapon"]["max"]], [14, 22], "17.5 x 0.8 / x 1.25")
	assert_eq(s["armor"], 90, "10 x 9")
	template["elite"] = true
	assert_eq(RpgMobs.stats(template, 10)["max_hp"], 529, "elite x2.3")
	assert_eq(RpgProgression.mob_xp_value(10, 10), 95, "45 + 5 x 10")
	assert_eq(RpgProgression.mob_xp_value(12, 10), 116, "+2 levels: +10%")
	assert_eq(RpgProgression.mob_xp_value(3, 10), 0, "grey at 7 below for Lv 10")
	assert_eq(RpgProgression.xp_for_level(1), 400, "XP table start")
	assert_eq(RpgProgression.xp_for_level(19), 21300, "19 to 20")
	assert_eq(RpgProgression.xp_for_level(20), 23200, "clamped at the cap entry")


func test_all_nine_class_sheets_at_levels_1_and_20() -> void:
	# [level 1 HP, resource, armor, AP, level 20 HP, resource, armor, AP], worked from
	# the reference CLASSES data and recalcPlayerStats (docs/RPG_CORE_PHASE1_SPEC.md).
	var expected := {
		"warrior": [90, 100, 90, 46, 812, 100, 356, 122],
		"paladin": [95, 93, 79, 44, 798, 660, 345, 120],
		"hunter": [69, 100, 95, 39, 725, 100, 361, 115],
		"rogue": [62, 100, 90, 42, 700, 100, 356, 118],
		"priest": [51, 160, 42, 10, 653, 1224, 118, 10],
		"shaman": [68, 108, 72, 36, 733, 1068, 300, 74],
		"mage": [54, 180, 49, 10, 665, 1491, 125, 10],
		"warlock": [57, 140, 46, 11, 677, 1470, 122, 11],
		"druid": [62, 114, 60, 30, 662, 1088, 212, 68],
	}
	assert_eq(_class("warrior").size() > 0, true, "data loads")
	assert_eq(_classes.size(), 9, "nine classes in the reference data")
	for id: String in expected:
		var want: Array = expected[id]
		for i in 2:
			var level := 1 if i == 0 else 20
			var s := RpgStats.sheet(_class(id), level)
			var got := [s["max_hp"], s["max_resource"], s["armor"], s["attack_power"]]
			assert_eq(got, want.slice(i * 4, i * 4 + 4), "%s level %d" % [id, level])


func test_progression_cap_post_cap_and_prestige() -> void:
	assert_eq(RpgProgression.xp_to_reach_level(1), 0, "level 1 needs nothing")
	assert_eq(RpgProgression.xp_to_reach_level(2), 400, "first table entry")
	assert_eq(RpgProgression.xp_to_reach_level(20), 167200, "sum of 19 table entries")
	assert_eq(RpgProgression.xp_to_reach_level(21), 190400, "first virtual level: +23200")
	assert_eq(RpgProgression.xp_to_reach_level(22), 215920, "then x1.1: +25520")
	assert_eq(RpgProgression.xp_to_reach_level(30), 536947, "rounded steps to 30")
	assert_eq(RpgProgression.virtual_level(0), 1, "start")
	assert_eq(RpgProgression.virtual_level(399), 1, "just short of 2")
	assert_eq(RpgProgression.virtual_level(400), 2, "exactly 2")
	assert_eq(RpgProgression.virtual_level(190399), 20, "just short of 21")
	assert_eq(RpgProgression.virtual_level(190400), 21, "exactly 21")
	assert_eq(RpgProgression.max_prestige_rank(167200), 0, "none at the cap")
	assert_eq(RpgProgression.max_prestige_rank(167200 + 3 * 23200), 3, "one per 23200")
