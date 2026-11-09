extends TestCase
## The levelling-time model (LevelingSim): curve arithmetic matches the game,
## farm rates repeat exactly from a seed and count XP past the level cap, and
## synthetic re-levels never leak into the content.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_game_curve_matches_the_profile() -> void:
	var curve: Dictionary = _content().progression["xp"]
	var profile := PlayerProfile.new_game(_content())
	for level in range(1, 50):
		profile.level = level
		assert_eq(
			LevelingSim.xp_to_next(curve, level), profile.xp_to_next(_content()), "level %d" % level
		)
	assert_eq(LevelingSim.xp_between(curve, 1, 3), 100 + 205, "levels 1 and 2")


func test_a_proposed_curve_overrides_single_levels() -> void:
	var curve := {"base": 100, "growth": 0, "square": 0, "levels": {"5": 999}}
	assert_eq(LevelingSim.xp_to_next(curve, 4), 100, "formula")
	assert_eq(LevelingSim.xp_to_next(curve, 5), 999, "override")
	assert_eq(LevelingSim.xp_between(curve, 4, 6), 1099, "summed")


func test_plan_turns_rates_into_hours() -> void:
	var curve := {"base": 1000, "growth": 0, "square": 0}
	var steady := LevelingSim.plan(curve, 1, 4, func(_l: int) -> float: return 500.0)
	assert_eq(steady["hours"], 6.0, "three levels at two hours each")
	var stuck := LevelingSim.plan(curve, 1, 2, func(_l: int) -> float: return 0.0)
	assert_eq(stuck["hours"], INF, "no rate, no progress")


func test_best_rate_uses_grounds_at_or_below_the_level() -> void:
	var rates := {"low": {4: 1000.0, 10: 400.0}, "high": {12: 3000.0}}
	assert_eq(LevelingSim.best_rate(rates, 10), 400.0, "the ground measured at 10")
	assert_eq(LevelingSim.best_rate(rates, 12), 3000.0, "a better ground at 12")
	assert_eq(LevelingSim.best_rate(rates, 3), 0.0, "nothing measured that low")
	assert_eq(LevelingSim.best_rate(rates, 20), 0.0, "too far past every measurement")


func test_a_farm_rate_repeats_exactly_from_a_seed() -> void:
	var setup := {"area": "farm_saltmarket_backlots", "level": 4, "seed": 3, "ticks": 3000}
	var first := LevelingSim.farm_rate(_content(), setup)
	var second := LevelingSim.farm_rate(_content(), setup)
	assert_true(int(first["kills"]) > 0, "auto battle farms the ground")
	assert_eq(first, second, "same seed, same session")


func test_xp_is_counted_past_the_level_cap() -> void:
	var setup := {"area": "farm_core_overflow", "level": 55, "seed": 1, "ticks": 3000}
	var run := LevelingSim.farm_rate(_content(), setup)
	assert_true(int(run["xp"]) > 0, "kills are worth XP at level 55 (trivial threat)")
	assert_eq(int(run["level"]), 55, "the hero stays at the measured level")


func test_synthetic_relevels_do_not_leak() -> void:
	var area := "farm_core_overflow"
	var before := int(_content().area(area)["level"])
	var setup := {
		"area": area, "level": 60, "area_level": 60, "syn_gear": true, "seed": 1, "ticks": 600
	}
	LevelingSim.farm_rate(_content(), setup)
	assert_eq(int(_content().area(area)["level"]), before, "the ground's level is restored")
	var fresh := ContentDB.load_all()
	assert_true(not fresh.items.has("syn_alloy_knuckles_60"), "nothing synthetic reaches the data")
