extends TestCase
## The classes' own mechanics (round two of the 2026-11-13 rebuild), each
## changing how a class fights rather than how hard it hits: the Brawler's
## heavy armour (a guard breaker always, and in PvP a second blow per swing,
## break it; no grab while it lands), the Counter Fighter's catch-all Perfect
## Parry, blows that hit a foe on the ground ("otg"), the Boxer's energy-
## draining Body Blow and cooldown refresh, the Street Striker's dodge
## cancel, the Brawler's momentum, every class move drawn by its hero, unique
## ultimates, and a guard that no class pairing in the arena is hopeless.

const BOUNDS := Rect2(0, 200, 800, 200)
const HEROES := {
	"boxer": "riku", "brawler": "kan", "grappler": "oren", "counter": "dao", "striker": "mika"
}
## The arena guard below: matches per pairing, and the least share of them
## the weaker side must win (a 20-match sample is noisy, so the floor is low;
## the measured 200-match spread is 42% to 58%).
const MATCHUP_SEEDS := 20
const MATCHUP_FLOOR := 0.25

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hero(job: String, level := 50, side := 0) -> Fighter:
	var f := DuelSim.make_hero(_content(), str(HEROES[job]), level, side)
	f.skills = SkillRules.unlocked(_content(), str(HEROES[job]), level)
	f.energy = CombatRules.MAX_ENERGY
	f.position = Vector2(400, 300)
	f.facing = 1
	return f


## A plain target: no team-mate of anyone, plenty of health, never acts.
func _dummy(id: int, at: Vector2) -> Fighter:
	var f := Fighter.new(id, 2, at, 100000)
	f.facing = -1
	return f


func _run(fighters: Array[Fighter], inputs_at: Callable, ticks: int) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	for t in ticks:
		events.append_array(CombatRules.tick(fighters, inputs_at.call(t), _content().moves, BOUNDS))
	return events


## Kan mid-way through his armoured Hammer Fist, `tick` ticks in.
func _swinging_kan(tick: int) -> Fighter:
	var kan := _hero("brawler")
	CombatRules.start_move(kan, _content().moves.get_move("brawler_hammer"))
	kan.state_tick = tick
	return kan


func test_armour_gives_way_to_a_skill_or_a_guard_break_but_not_a_jab() -> void:
	var kan := _swinging_kan(4)
	var riku := _hero("boxer", 50, 1)
	var jab := _content().moves.get_move("boxer_jab")
	assert_true(not CombatRules.breaks_armor(kan, riku, jab), "a light punch does not")
	assert_true(
		CombatRules.breaks_armor(kan, riku, _content().moves.get_move("boxer_overhand")),
		"the Boxer's guard-breaking Overhand does"
	)
	riku.skill_id = "power_jab"
	assert_true(
		CombatRules.breaks_armor(kan, riku, _content().moves.get_move("power_jab")),
		"so does any skill's blow"
	)


func test_an_armoured_swing_cannot_be_grabbed_until_it_is_through() -> void:
	var hammer := _content().moves.get_move("brawler_hammer")
	assert_true(not GrabRules.can_hold(_swinging_kan(2)), "planted in the wind-up: no grip")
	assert_true(not GrabRules.can_hold(_swinging_kan(hammer.startup)), "nor while it lands")
	assert_true(GrabRules.can_hold(_swinging_kan(hammer.startup + hammer.active)), "recovery: yes")
	var left := _hero("brawler")
	CombatRules.start_move(left, _content().moves.get_move("brawler_left"))
	assert_true(GrabRules.can_hold(left), "an unarmoured jab can be grabbed")


func test_perfect_parry_catches_even_a_guard_breaker() -> void:
	var breaker := _content().moves.get_move("brawler_hammer")
	var plain := _content().moves.get_move("brawler_left")
	for pair: Array in [["perfect_parry_stance", true], ["quick_counter_stance", false]]:
		var dao := _hero("counter")
		CombatRules.start_move(dao, _content().moves.get_move(str(pair[0])))
		dao.state_tick = dao.move.startup
		assert_true(CounterRules.catches(dao, plain, true), "%s catches a jab" % pair[0])
		assert_eq(CounterRules.catches(dao, breaker, true), pair[1], "%s: a hammer" % pair[0])
		assert_true(not CounterRules.catches(dao, plain, false), "never from behind")


func test_otg_blows_hit_a_foe_on_the_ground_for_damage_only() -> void:
	var pound := _content().moves.get_move("ground_pound")
	var left := _content().moves.get_move("brawler_left")
	var down := _hero("boxer", 50, 1)
	down.enter(Fighter.State.DOWN)
	down.airborne = 0
	assert_true(CombatRules.hits_down(pound, down), "Ground Pound reaches the floor")
	assert_true(not CombatRules.hits_down(left, down), "a jab does not")
	for move_id: String in ["ground_pound", "ground_slam_wave", "chain_breaker"]:
		assert_true(_content().moves.get_move(move_id).otg, move_id + " hits low")
	# For real: Kan pounds a hero lying in front of him.
	var kan := _hero("brawler")
	var foe := _hero("boxer", 50, 1)
	foe.team = 2
	foe.position = kan.position + Vector2(30, 0)
	foe.enter(Fighter.State.DOWN)
	foe.airborne = 0
	var hp := foe.hp
	var fighters: Array[Fighter] = [kan, foe]
	var inputs := func(t: int) -> Dictionary:
		var press := FighterInput.new()
		press.skill = "ground_pound" if t == 0 else ""
		return {kan.id: press}
	var hits := _run(fighters, inputs, pound.startup + pound.active + 1)
	assert_true(foe.hp < hp, "the downed hero is hurt (%d hits)" % hits.size())
	assert_eq(foe.state, Fighter.State.DOWN, "and stays down: no relaunch, no new fall")


func test_the_body_blow_drains_energy() -> void:
	var riku := _hero("boxer")
	var foe := _hero("brawler", 50, 1)
	foe.team = 2
	foe.position = riku.position + Vector2(24, 0)
	foe.facing = -1
	var fighters: Array[Fighter] = [riku, foe]
	var inputs := func(t: int) -> Dictionary:
		var press := FighterInput.new()
		press.skill = "body_blow" if t == 0 else ""
		return {riku.id: press}
	var hit := false
	for event in _run(fighters, inputs, 12):
		hit = hit or (event.attacker_id == riku.id and event.damage > 0)
	assert_true(hit, "the Body Blow lands")
	assert_true(foe.energy <= CombatRules.MAX_ENERGY - 30.0, "energy taken: %.1f" % foe.energy)


func test_each_class_passive_changes_how_it_fights() -> void:
	var kan := _hero("brawler")
	kan.passives = SkillRules.passives(_content(), "kan", 50)
	assert_near(PassiveRules.bonus(kan, "guard_drain"), 0.0, "Crushing Momentum starts at rest")
	for n in 7:
		PassiveRules.on_event(kan, "hit")
	assert_near(PassiveRules.bonus(kan, "guard_drain"), 0.75, "five blows: guards drain 75% more")
	assert_near(PassiveRules.bonus(kan, "damage"), 0.2, "and they hit 20% harder")
	var mika := _hero("striker")
	mika.passives = SkillRules.passives(_content(), "mika", 50)
	assert_true(CombatRules.dodge_cost(mika) < CombatRules.DODGE_COST, "Slipstream: cheaper slip")
	var riku := _hero("boxer")
	riku.passives = SkillRules.passives(_content(), "riku", 50)
	assert_eq(CombatRules.dodge_cost(riku), CombatRules.DODGE_COST, "others pay in full")
	assert_near(PassiveRules.bonus(riku, "refresh"), 45.0, "Combination Puncher: refresh")
	var young := _hero("striker", 20)
	young.passives = SkillRules.passives(_content(), "mika", 20)
	assert_eq(CombatRules.dodge_cost(young), CombatRules.DODGE_COST, "not before level 25")


func test_a_landed_striker_blow_cancels_into_a_dodge() -> void:
	for job: String in ["striker", "boxer"]:
		var hero := _hero(job)
		hero.passives = SkillRules.passives(_content(), str(HEROES[job]), 50)
		var foe := _dummy(11, hero.position + Vector2(30, 0))
		var pair: Array[Fighter] = [hero, foe]
		var at := -1
		var jab := _content().moves.get_move(str(_content().jobs[job]["moveset"]["light"]))
		for t in 30:
			var press := FighterInput.new()
			press.light = t == 0
			press.dodge = t >= jab.startup + jab.active
			CombatRules.tick(pair, {hero.id: press}, _content().moves, BOUNDS)
			if at < 0 and hero.state == Fighter.State.DODGE:
				at = t
		if job == "striker":
			assert_true(at > 0 and at < jab.total_ticks(), "Mika slips out at %d" % at)
		else:
			assert_true(at >= jab.total_ticks() - 1, "Riku recovers first (%d)" % at)


func test_a_landed_route_link_refreshes_the_boxers_cooldowns() -> void:
	var riku := _hero("boxer")
	riku.passives = SkillRules.passives(_content(), "riku", 50)
	riku.combos = ComboRules.unlocked(_content(), "riku", 50)
	riku.cooldowns["uppercut"] = 600
	var foe := _dummy(11, riku.position + Vector2(24, 0))
	var pair: Array[Fighter] = [riku, foe]
	var ticks := 0
	var sent := false
	while ticks < 120 and riku.combo_done == "":
		var press := FighterInput.new()
		if ticks == 0:
			press.skill = "power_jab"
		elif not sent and "heavy_cross" in ComboRules.next_links(riku):
			press.skill = "heavy_cross"
			sent = true
		foe.position = riku.position + Vector2(24, 0)
		CombatRules.tick(pair, {riku.id: press}, _content().moves, BOUNDS)
		ticks += 1
	assert_eq(riku.combo_done, "one_two", "the One-Two lands")
	assert_true(
		int(riku.cooldowns.get("uppercut", 0)) <= 600 - ticks - 40,
		(
			"Uppercut came back 45 ticks sooner (%d after %d ticks)"
			% [riku.cooldowns["uppercut"], ticks]
		)
	)


func test_every_class_move_plays_an_animation_its_hero_draws() -> void:
	var owned := SkillRegistry.class_moves(_content())
	for job: String in HEROES:
		var hero: Dictionary = _content().hero(str(HEROES[job]))
		for art: String in hero["sprites"].values():
			var frames: SpriteFrames = load("res://assets/characters/%s/%s.tres" % [art, art])
			for move_id: String in owned[job]:
				var anim := _content().moves.get_move(move_id).anim
				if anim != "":
					assert_true(
						frames.has_animation(anim), "%s: %s plays %s" % [art, move_id, anim]
					)
			for button: String in ["light", "heavy"]:
				assert_true(frames.has_animation(button), "%s draws its %s" % [art, button])


func test_two_ultimates_sharing_an_animation_are_refused() -> void:
	var db := ContentDB.load_all()
	var ultimates: Array[String] = []
	for job: String in HEROES:
		ultimates.append(SkillRules.ultimate(db, str(HEROES[job])))
	var moves := {}
	for ultimate in ultimates:
		for move_id in SkillRegistry.skill_moves(db, ultimate):
			assert_true(not moves.has(move_id), "%s is in one ultimate only" % move_id)
			moves[move_id] = true
	for move_id in SkillRegistry.skill_moves(db, "titan_destruction"):
		if db.moves.get_move(move_id).anim == "grappler_ultimate":
			db.moves.get_move(move_id).anim = "brawler_ultimate"
	var found := ", ".join(SkillRegistry.problems(db))
	assert_true("share their animation" in found, "a borrowed ultimate clip is caught: %s" % found)
	for move_id in SkillRegistry.skill_moves(db, "street_carnage"):
		db.moves.get_move(move_id).anim = "heavy"
	found = ", ".join(SkillRegistry.problems(db))
	assert_true("street_carnage has no animation of its own" in found, "a plain one: %s" % found)


## A short, fixed sample of the arena balance run (ArenaSim, both sides AI,
## AI skill and personality drawn per match): no class pairing may be close
## to hopeless. The full 200-match run is docs/COMBAT_SYSTEM.md's matrix;
## this guards against a change that brings a hard counter back.
func test_no_class_pairing_is_hopeless_in_the_arena() -> void:
	var jobs: Array = _content().job_order
	var top := {"level": 70, "grades": ["godforged"], "plus": 0}
	for i in jobs.size():
		for j in range(i + 1, jobs.size()):
			var a := top.merged({"job": jobs[i]})
			var b := top.merged({"job": jobs[j]})
			var run := ArenaSim.series(_content(), a, b, MATCHUP_SEEDS, 0.0, true)
			var low := minf(float(run["a_win_rate"]), float(run["b_win_rate"]))
			assert_true(
				low >= MATCHUP_FLOOR,
				"%s vs %s: %s / %s" % [jobs[i], jobs[j], run["a_win_rate"], run["b_win_rate"]]
			)


func test_pvp_only_rules_leave_pve_alone() -> void:
	var riku := _hero("boxer")
	var hero := _hero("brawler", 50, 1)
	var monster := _dummy(20, Vector2.ZERO)
	monster.defense = hero.defense
	var jab := _content().moves.get_move("boxer_jab")
	var raw := roundi(jab.damage * riku.power)
	# PvE: flat defense, as it always was.
	assert_eq(CombatRules.damage_for(jab, riku, monster), maxi(1, raw - monster.defense), "PvE")
	# PvP: defense takes a share, so a jab is never wiped out.
	var share := hero.defense / (hero.defense + CombatRules.PVP_DEFENSE_K)
	assert_eq(CombatRules.damage_for(jab, riku, hero), roundi(raw * (1.0 - share)), "PvP share")
	# Heavy armour: a monster's blows never wear it down; a hero's second one does.
	var kan := _swinging_kan(4)
	var thug := _dummy(21, Vector2.ZERO)
	for n in 3:
		assert_true(not CombatRules.breaks_armor(kan, thug, jab), "monster blow %d held" % n)
	assert_true(not CombatRules.breaks_armor(kan, riku, jab), "the first hero blow is held")
	assert_true(CombatRules.breaks_armor(kan, riku, jab), "the second gets through")
	# The Boxer's stepping punches step less far in PvE (skill profile).
	var pve := SkillRules.unlocked(_content(), "riku", 50, BalanceProfile.PVE)
	var pvp := SkillRules.unlocked(_content(), "riku", 50, BalanceProfile.PVP)
	for skill_id: String in ["heavy_cross", "body_blow", "uppercut"]:
		assert_true(_content().moves.get_move(skill_id).advance > 0.0, skill_id + " steps in")
		assert_true(
			pve[skill_id]["scale"]["advance"] < pvp[skill_id]["scale"]["advance"],
			skill_id + ": a shorter step in PvE"
		)


## A class move that reaches well behind the fighter plays a clip that turns
## (or slams the ground, or dashes through): never a plain forward swing,
## so what is seen matches where the blow lands. Checked on screen too
## (docs/COMBAT_REBUILD_REPORT.md, final polish).
func test_blows_all_around_play_a_turning_or_ground_clip() -> void:
	var around := [
		"boxer_weave",
		"brawler_pound",
		"brawler_whirl",
		"brawler_ultimate",
		"grappler_slam",
		"grappler_ultimate",
		"counter_whirl",
		"striker_spin",
		"striker_dash",
		"striker_ultimate",
	]
	var owned := SkillRegistry.class_moves(_content())
	for job: String in owned:
		for move_id: String in owned[job]:
			var move := _content().moves.get_move(move_id)
			if move.damage > 0 and move.reach_offset <= -20.0:
				assert_true(
					move.anim in around, "%s reaches behind: plays %s" % [move_id, move.anim]
				)
