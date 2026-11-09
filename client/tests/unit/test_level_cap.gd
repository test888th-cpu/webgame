extends TestCase
## The level 1-70 foundation: the cap comes from progression.json, XP keeps
## counting past the old cap of 50, a level 70 save loads, and the curve has
## no cliff (each level costs no more than a few times the one before).

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_cap_is_seventy() -> void:
	var profile := PlayerProfile.new_game(_content())
	assert_eq(profile.max_level(_content()), 70, "progression.json max_level")


func test_xp_counts_past_fifty() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.level = 50
	var need := profile.xp_to_next(_content())
	assert_true(need > 0, "level 50 has a next level")
	assert_eq(profile.add_xp(need, _content()), 1, "one level gained")
	assert_eq(profile.level, 51, "past the old cap")
	assert_eq(profile.xp, 0, "the exact amount, nothing left over")


func test_level_seventy_is_the_end() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.level = 69
	var gained := profile.add_xp(profile.xp_to_next(_content()) + 5000, _content())
	assert_eq(gained, 1, "reaches 70")
	assert_eq(profile.level, 70, "the cap")
	assert_eq(profile.xp, 0, "no XP banked at the cap")
	assert_eq(profile.add_xp(100000, _content()), 0, "nothing more to gain")


func test_a_high_level_save_loads() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.level = 65
	profile.xp = 1234
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	assert_eq(loaded.level, 65, "level 65 survives a save")
	assert_eq(loaded.xp, 1234, "with its XP")


func test_the_curve_rises_without_a_cliff() -> void:
	var curve: Dictionary = _content().progression["xp"]
	var previous := 0
	for level in range(1, 70):
		var cost := LevelRules.xp_to_next(curve, level)
		assert_true(cost >= previous, "level %d costs no less than %d" % [level, level - 1])
		if previous > 0:
			assert_true(cost <= previous * 5, "level %d is no cliff over %d" % [level, level - 1])
		previous = cost


func test_overrides_and_the_formula_agree_where_unset() -> void:
	var curve := {"base": 100, "growth": 100, "square": 5, "levels": {"10": 7}}
	assert_eq(LevelRules.xp_to_next(curve, 9), 100 + 800 + 5 * 64, "the formula")
	assert_eq(LevelRules.xp_to_next(curve, 10), 7, "the override")


func test_kills_pay_xp_above_fifty() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.level = 55
	var zone := ZoneSim.new(_content(), profile, "saltmarket", "", 1)
	zone.level = 55
	var foe := zone.spawn_enemy("smogling", Vector2(500, 300))
	foe.hp = 1
	var paid := 0
	for tick in 240:
		var input := FighterInput.new()
		input.light = tick % 20 == 0
		zone.hero.position = foe.position - Vector2(30, 0)
		zone.hero.facing = 1
		for event in zone.tick(input):
			if event.type == "defeat":
				paid += int(event.data["xp"])
		if foe.is_ko():
			break
	assert_true(foe.is_ko(), "the foe falls")
	assert_true(paid > 0, "and pays XP to a level 55 hero")
