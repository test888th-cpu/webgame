extends TestCase
## Bosses stand up to knockdown blows: each one only staggers them, until
## enough land close together; after a fall they cannot be floored again for
## a while. Ordinary enemies still go down to a single knockdown blow.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _sturdy() -> Fighter:
	var boss := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(300, 300), 9999)
	boss.down_limit = 3
	return boss


## A knockdown blow on `defender` (thrown_hit is the public way in).
func _blow(defender: Fighter) -> CombatEvent:
	return CombatRules.thrown_hit(defender, 1, 260.0, 5, true, "test")


## Lets `f` recover from a stagger or a fall.
func _recover(f: Fighter, ticks: int) -> void:
	var bounds := Rect2(0, 200, 1000, 200)
	for i in ticks:
		CombatRules.tick([f], {}, _content().moves, bounds)


func test_an_ordinary_enemy_falls_to_one_blow() -> void:
	var thug := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(300, 300), 9999)
	var hit := _blow(thug)
	assert_true(hit.knocked_down, "down at once")
	assert_eq(thug.state, Fighter.State.DOWN, "on the floor")


func test_a_boss_falls_only_to_the_third_blow_in_a_row() -> void:
	var boss := _sturdy()
	for i in 2:
		var hit := _blow(boss)
		assert_true(not hit.knocked_down, "blow %d: still standing" % (i + 1))
		assert_true(hit.staggered, "blow %d: staggered" % (i + 1))
		assert_eq(boss.state, Fighter.State.HITSTUN, "rocked")
		_recover(boss, CombatRules.STAGGER_TICKS + 1)
		assert_eq(boss.state, Fighter.State.IDLE, "and soon back in it")
	var third := _blow(boss)
	assert_true(third.knocked_down, "the third blow floors it")
	assert_true(not third.staggered, "a fall, not a stagger")


func test_the_blows_must_come_close_together() -> void:
	var boss := _sturdy()
	_blow(boss)
	_blow(boss)
	_recover(boss, CombatRules.DOWN_WINDOW + 1)
	assert_eq(boss.down_meter, 0, "a lull lets it shake them off")
	assert_true(not _blow(boss).knocked_down, "so the next blow starts over")


func test_a_boss_that_fell_cannot_be_floored_again_for_a_while() -> void:
	var boss := _sturdy()
	for i in 3:
		_blow(boss)
	assert_eq(boss.state, Fighter.State.DOWN, "down")
	_recover(boss, CombatRules.KNOCKDOWN_TICKS + 1)
	assert_eq(boss.state, Fighter.State.IDLE, "up again")
	for i in 6:
		assert_true(_blow(boss).staggered, "rest: blow %d only staggers" % (i + 1))
	assert_eq(boss.down_meter, 0, "blows during the rest do not count")
	_recover(boss, CombatRules.DOWN_REST)
	for i in 2:
		_blow(boss)
	assert_true(_blow(boss).knocked_down, "after the rest it can fall again")


func test_every_boss_is_sturdy_and_nothing_else() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 7)
	for enemy_id: String in _content().enemies:
		var data := _content().enemy(enemy_id)
		var enemy := zone.spawn_enemy(enemy_id, Vector2(500, 300))
		var expected := 0
		if data.get("boss", false):
			expected = int(data.get("down_blows", CombatRules.BOSS_DOWN_BLOWS))
		assert_eq(enemy.down_limit, expected, "%s down_limit" % enemy_id)
	assert_eq(zone.hero.down_limit, 0, "the hero falls as before")


func test_the_validator_checks_down_blows() -> void:
	var broken := ContentDB.load_all()
	broken.errors.clear()
	broken.enemies["dock_thug"]["down_blows"] = 2
	broken.enemies["furnace_baron"]["down_blows"] = 0
	broken.validate()
	var all := "\n".join(broken.errors)
	assert_true("dock_thug.down_blows: only bosses" in all, "only bosses")
	assert_true("furnace_baron.down_blows" in all, "at least one blow")
