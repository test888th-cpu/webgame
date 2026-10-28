extends TestCase
## Bosses never flinch, stagger, reel or fall to a blow. Only an overwhelming
## beating (more damage than their break meter drains, as from a crowd)
## breaks them, and then not again for a long while. Ordinary enemies are
## unchanged.

const BOUNDS := Rect2(0, 200, 1000, 200)

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _boss() -> Fighter:
	var boss := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(300, 300), 1000)
	boss.unshaken = true
	return boss


## A thrown blow on `defender` (thrown_hit is the public way in).
func _blow(defender: Fighter, damage: int, knockdown := true) -> CombatEvent:
	return CombatRules.thrown_hit(defender, 1, 260.0, damage, knockdown, "test")


func _wait(f: Fighter, ticks: int) -> void:
	for i in ticks:
		CombatRules.tick([f], {}, _content().moves, BOUNDS)


## `per_second` damage a second for `seconds`, in blows of 10 ticks apart.
## Returns how many blows broke `boss`.
func _beat(boss: Fighter, per_second: float, seconds: int) -> int:
	var breaks := 0
	for i in seconds * 6:
		var hit := _blow(boss, roundi(per_second / 6.0), false)
		breaks += 1 if hit.broken else 0
		boss.hp = boss.max_hp
		_wait(boss, 10)
	return breaks


func test_an_ordinary_enemy_still_falls() -> void:
	var thug := Fighter.new(2, ZoneSim.ENEMY_TEAM, Vector2(300, 300), 1000)
	assert_true(_blow(thug, 5).knocked_down, "down to a knockdown blow")
	var other := Fighter.new(3, ZoneSim.ENEMY_TEAM, Vector2(300, 300), 1000)
	_blow(other, 5, false)
	assert_eq(other.state, Fighter.State.HITSTUN, "and flinches at a plain one")


func test_a_boss_does_not_flinch_stagger_or_fall() -> void:
	var boss := _boss()
	var hit := _blow(boss, 20)
	assert_true(not hit.knocked_down, "a knockdown blow leaves it standing")
	assert_eq(boss.state, Fighter.State.IDLE, "not even a stagger")
	assert_eq(boss.knockback_remaining, 0.0, "nor pushed back")
	assert_eq(boss.hp, 980, "but it takes the damage")
	boss.enter(Fighter.State.ATTACK)
	boss.move = _content().moves.get_move("jab")
	_blow(boss, 20, false)
	assert_eq(boss.state, Fighter.State.ATTACK, "its attack goes on")


func test_one_hero_at_its_level_never_breaks_it() -> void:
	# A hero at the boss's level deals a few percent of its HP a second,
	# under what the meter drains.
	var boss := _boss()
	var drain := boss.max_hp * CombatRules.BREAK_DRAIN
	assert_eq(_beat(boss, drain * 0.9, 120), 0, "two minutes of steady blows")
	assert_true(CombatRules.is_unflinching(boss), "and never a flinch")


func test_a_crowd_breaks_it_then_not_again_for_a_while() -> void:
	var boss := _boss()
	var drain := boss.max_hp * CombatRules.BREAK_DRAIN
	var hit: CombatEvent = null
	for i in 600:
		boss.hp = boss.max_hp
		hit = _blow(boss, roundi(drain), false)
		if hit.broken:
			break
		_wait(boss, 2)
	assert_true(hit.broken, "many heroes at once break it")
	assert_true(hit.knocked_down, "a break knocks it down")
	assert_eq(boss.state, Fighter.State.DOWN, "on the floor")
	_wait(boss, CombatRules.KNOCKDOWN_TICKS + 1)
	for i in 50:
		boss.hp = boss.max_hp
		assert_true(not _blow(boss, roundi(drain), false).broken, "rest %d" % i)
	assert_eq(boss.state, Fighter.State.IDLE, "and up again, unshaken")
	_wait(boss, CombatRules.BREAK_REST)
	assert_true(_beat(boss, drain * 6.0, 10) > 0, "after the rest a crowd can break it again")


func test_every_boss_is_unshaken_and_nothing_else() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 7)
	for enemy_id: String in _content().enemies:
		var enemy := zone.spawn_enemy(enemy_id, Vector2(500, 300))
		var boss := bool(_content().enemy(enemy_id).get("boss", false))
		assert_eq(enemy.unshaken, boss, "%s unshaken" % enemy_id)
	assert_true(not zone.hero.unshaken, "the hero falls as before")
