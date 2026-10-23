extends TestCase
## Balance rules between the heroes, so tuning numbers later cannot quietly
## break them. "Effective" damage is a move's damage times the hero's base
## power (what it does to a target with no defense).

## Same-slot skills of different heroes may differ by at most this share.
const SLOT_TOLERANCE := 0.15
## A skill waits on a cooldown, so it must clearly beat the heavy attack,
## which has none.
const SKILL_OVER_HEAVY := 1.5

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _effective(hero_id: String, move_id: String) -> float:
	var power := float(_content().hero(hero_id)["stats"]["power"])
	return _content().moves.get_move(move_id).damage * power


func _skill_move(skill_id: String) -> String:
	return str(_content().skills[skill_id]["move"])


func test_every_skill_out_damages_the_free_heavy_attack() -> void:
	for hero_id: String in _content().hero_order:
		var heavy := _effective(hero_id, "haymaker")
		for skill_id: String in _content().hero(hero_id)["skills"]:
			assert_true(
				_effective(hero_id, _skill_move(skill_id)) >= heavy * SKILL_OVER_HEAVY,
				"%s's %s hits 1.5x the heavy attack" % [hero_id, skill_id]
			)


func test_same_slot_skills_are_close_across_heroes() -> void:
	var heroes: Array = _content().hero_order
	for slot in ContentDB.HERO_SKILLS:
		var values: Array[float] = []
		for hero_id: String in heroes:
			var skill_id: String = _content().hero(hero_id)["skills"][slot]
			values.append(_effective(hero_id, _skill_move(skill_id)))
		var low: float = values.min()
		var high: float = values.max()
		assert_true(
			high <= low * (1.0 + SLOT_TOLERANCE),
			(
				"skill slot %d within %d%% across heroes (%s)"
				% [slot + 2, SLOT_TOLERANCE * 100, values]
			)
		)


func test_later_skills_hit_harder_and_cool_down_longer() -> void:
	for hero_id: String in _content().hero_order:
		var skills: Array = _content().hero(hero_id)["skills"]
		var ultimate: String = skills[skills.size() - 1]
		for skill_id: String in skills.slice(0, skills.size() - 1):
			assert_true(
				(
					_effective(hero_id, _skill_move(ultimate))
					> _effective(hero_id, _skill_move(skill_id))
				),
				"%s's ultimate is the strongest" % hero_id
			)
			assert_true(
				(
					int(_content().skills[ultimate]["cooldown"])
					> int(_content().skills[skill_id]["cooldown"])
				),
				"%s's ultimate has the longest cooldown" % hero_id
			)


func test_each_hero_trades_one_strength_for_another() -> void:
	var mika: Dictionary = _content().hero("mika")["stats"]
	var oren: Dictionary = _content().hero("oren")["stats"]
	assert_true(
		mika["power"] > oren["power"] and mika["speed"] > oren["speed"], "Mika: damage, speed"
	)
	assert_true(
		oren["max_hp"] > mika["max_hp"] and oren["defense"] > mika["defense"],
		"Oren: health, defense"
	)
