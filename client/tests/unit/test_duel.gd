extends TestCase
## PvP 1 against 1 (tests/harness/DuelSim.gd, DuelBot.gd): the safety rails
## every pairing of jobs must keep in the arena, whatever the balance numbers:
## nobody stays helpless for long, no single blow comes near a one-shot, a
## held player gets free, and the PvP balance profile reaches every blow of a
## skill, its throw included. Win rates are measured with DuelCheck, not
## asserted: a bot is not a player.

## The longest a fighter may be unable to act in a duel (3 s): a grab, a
## throw and the time on the ground included.
const MAX_LOCK_TICKS := 180
## No single blow may take this share of a full health bar.
const MAX_BLOW_SHARE := 0.7
## A duel lasts at least this long on average (no burst kills).
const MIN_MEAN_SECONDS := 8.0

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_every_pairing_keeps_the_pvp_safety_rails() -> void:
	for level in [30, 70]:
		var result := DuelSim.table(_content(), _content().hero_order, level, 2)
		assert_true(
			int(result["lock"]) <= MAX_LOCK_TICKS,
			"Lv %d: the longest lock is %d ticks" % [level, result["lock"]]
		)
		assert_true(
			float(result["biggest"]) < MAX_BLOW_SHARE,
			(
				"Lv %d: the biggest blow (%s) takes %d%% of a health bar"
				% [level, result["biggest_move"], roundi(result["biggest"] * 100.0)]
			)
		)
		var seconds := float(result["ticks"]) / CombatRules.TICK_RATE
		assert_true(seconds >= MIN_MEAN_SECONDS, "Lv %d: duels last %.1f s" % [level, seconds])


func test_a_held_player_mashing_gets_free_before_the_hold_ends() -> void:
	var db := _content()
	var oren := DuelSim.make_hero(db, "oren", 70, 0)
	var foe := DuelSim.make_hero(db, "riku", 70, 1)
	foe.position = oren.position + Vector2(20, 0)
	var fighters: Array[Fighter] = [oren, foe]
	var grab := FighterInput.new()
	grab.skill = "crushing_hold"
	var held := 0
	for t in 200:
		var inputs := {oren.id: grab if t == 0 else FighterInput.new()}
		var mash := FighterInput.new()
		mash.light = foe.state == Fighter.State.HELD and t % DuelBot.MASH_EVERY == 0
		inputs[foe.id] = mash
		CombatRules.tick(fighters, inputs, db.moves, DuelSim.BOUNDS)
		held += 1 if foe.state == Fighter.State.HELD else 0
	var hold := int(db.skills["crushing_hold"]["grab"]["hold"])
	assert_true(held > 0, "the Grappler gets hold of the Boxer")
	assert_true(held < hold, "who struggles free in %d of the hold's %d ticks" % [held, hold])


func test_the_pvp_profile_reaches_a_grab_skill_s_throw() -> void:
	var db := _content()
	var dealt := {}
	for mode: String in [BalanceProfile.PVE, BalanceProfile.PVP]:
		var hero := DuelSim.make_hero(db, "oren", 50, 0)
		hero.skills = SkillRules.unlocked(db, "oren", 50, mode)
		hero.combos = []
		hero.passives = {}
		hero.crit_chance = 0.0
		var foe := Fighter.new(9, 2, hero.position + Vector2(20, 0), 100000)
		foe.facing = -1
		var fighters: Array[Fighter] = [hero, foe]
		for t in 200:
			var input := FighterInput.new()
			input.skill = "backbreaker" if t == 0 else ""
			for hit in CombatRules.tick(fighters, {hero.id: input}, db.moves, DuelSim.BOUNDS):
				if hit.move_id == "backbreaker_hit":
					dealt[mode] = hit.damage
	var scale := float(db.skills["backbreaker"]["profiles"]["pvp"]["damage"])
	assert_true(dealt.has(BalanceProfile.PVE) and dealt.has(BalanceProfile.PVP), "both throws land")
	assert_eq(
		dealt[BalanceProfile.PVP],
		roundi(dealt[BalanceProfile.PVE] * scale),
		"the throw lands after the skill, yet with its PvP scale"
	)
