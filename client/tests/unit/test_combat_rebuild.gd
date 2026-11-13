extends TestCase
## The five classes' own combat (2026-11-13 rebuild): no move shared or
## copied between classes (SkillRegistry), a heavy attack and animations of
## each class's own, an area attack per class that really hits several foes,
## a signature ultimate each, the combo engine's transitions (skill to basic,
## basic to skill, no cancel on a whiff), heavy armour on committed moves
## only, and the PvP-only limits: combo scaling and a shorter fall after a
## throw. PvE is untouched by the PvP rules.

const BOUNDS := Rect2(0, 200, 800, 200)
const HEROES := {
	"boxer": "riku", "brawler": "kan", "grappler": "oren", "counter": "dao", "striker": "mika"
}
const AREA_SKILLS := {
	"boxer": "knockout_combo",
	"brawler": "ground_pound",
	"grappler": "ground_slam",
	"counter": "reversal_strike",
	"striker": "dash_strike",
}
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


func test_no_class_move_is_shared_or_copied() -> void:
	assert_eq(SkillRegistry.problems(_content()), PackedStringArray(), "the shipped classes")
	var db := ContentDB.load_all()
	db.jobs["counter"]["moveset"]["heavy"] = "boxer_overhand"
	var found := ", ".join(SkillRegistry.problems(db))
	assert_true("boxer_overhand is used by" in found, "a borrowed move is caught: %s" % found)
	var copy := db.moves.get_move("striker_jab")
	var twin := db.moves.get_move("counter_quick")
	for field: String in SkillRegistry.SIGNATURE:
		twin.set(field, copy.get(field))
	assert_true(
		"plays the same as" in ", ".join(SkillRegistry.problems(db)), "a renamed copy is caught"
	)


func test_every_class_has_its_own_heavy_and_animations() -> void:
	var heavies := {}
	for job: String in HEROES:
		var heavy := str(_content().jobs[job]["moveset"]["heavy"])
		assert_true(heavy != "haymaker", "%s: its own heavy" % job)
		heavies[heavy] = true
		var hero: Dictionary = _content().hero(str(HEROES[job]))
		for art: String in hero["sprites"].values():
			var frames: SpriteFrames = load("res://assets/characters/%s/%s.tres" % [art, art])
			for anim: String in _class_anims(job):
				assert_true(frames.has_animation(anim), "%s draws %s" % [art, anim])
	assert_eq(heavies.size(), 5, "five different heavies")


func _class_anims(job: String) -> Array[String]:
	var out: Array[String] = []
	for anim: String in MoveLibrary.ANIMS:
		if anim.begins_with(job + "_"):
			out.append(anim)
	return out


func test_every_class_area_attack_hits_several_foes() -> void:
	for job: String in AREA_SKILLS:
		var hero := _hero(job)
		var front := _dummy(10, hero.position + Vector2(30, 0))
		var other := _dummy(11, hero.position + Vector2(-30, 0))
		if job == "striker":
			other.position = hero.position + Vector2(70, 0)  # in the dash's path
		if job == "grappler":
			# Behind, where the wave reaches once the lift's step carries the
			# Grappler 25 px forward.
			other.position = hero.position + Vector2(-15, 0)
		var fighters: Array[Fighter] = [hero, front, other]
		var skill := str(AREA_SKILLS[job])
		var attacker: Fighter = null
		if job == "counter":
			# The reply needs a blow to catch: a hero attacking from the front.
			attacker = _hero("boxer", 50, 1)
			attacker.position = hero.position + Vector2(36, 0)
			attacker.facing = -1
			attacker.team = 2
			fighters.append(attacker)
		var hit := {}
		var inputs := func(t: int) -> Dictionary:
			var press := FighterInput.new()
			press.skill = skill if t == 0 else ""
			press.light = hero.state == Fighter.State.GRAB
			var out := {hero.id: press}
			if attacker != null:
				var jab := FighterInput.new()
				jab.light = t == 2
				out[attacker.id] = jab
			return out
		for event in _run(fighters, inputs, 240):
			if event.attacker_id == hero.id and event.damage > 0:
				hit[event.defender_id] = true
		var targets := [front.id, other.id] if attacker == null else [attacker.id, other.id]
		for target: int in targets:
			assert_true(hit.has(target), "%s's %s hits foe %d (%s)" % [job, skill, target, hit])


func test_every_ultimate_has_its_own_signature_animation() -> void:
	var seen := {}
	for job: String in HEROES:
		var ultimate := ""
		for skill_id: String in _content().jobs[job]["skills"]:
			if _content().skills[skill_id]["type"] == "ultimate":
				ultimate = skill_id
		var anims: Array[String] = []
		for move_id in SkillRegistry.skill_moves(_content(), ultimate):
			anims.append(_content().moves.get_move(move_id).anim)
		assert_true((job + "_ultimate") in anims, "%s's %s: %s" % [job, ultimate, anims])
		seen[ultimate] = true
	assert_eq(seen.size(), 5, "five ultimates")


func test_skill_to_basic_and_basic_to_skill_transitions() -> void:
	# Power Jab lands, light pressed: the Boxer's straight follows at once.
	var boxer := _hero("boxer")
	var foe := _dummy(10, boxer.position + Vector2(36, 0))
	var fighters: Array[Fighter] = [boxer, foe]
	var started := []
	for t in 60:
		var press := FighterInput.new()
		press.skill = "power_jab" if t == 0 else ""
		press.light = t >= 6
		CombatRules.tick(fighters, {boxer.id: press}, _content().moves, BOUNDS)
		if boxer.move != null and (started.is_empty() or started[-1] != boxer.move.id):
			started.append(boxer.move.id)
	assert_eq(started.slice(0, 2), ["power_jab", "boxer_straight"], "skill into basic")
	# A jab lands, a skill pressed: it cancels the jab's recovery.
	var mika := _hero("striker")
	var target := _dummy(11, mika.position + Vector2(30, 0))
	var pair: Array[Fighter] = [mika, target]
	var at := -1
	for t in 40:
		var press := FighterInput.new()
		press.light = t == 0
		press.skill = "triple_punch" if t >= 4 else ""
		CombatRules.tick(pair, {mika.id: press}, _content().moves, BOUNDS)
		if at < 0 and mika.skill_id == "triple_punch":
			at = t
	var jab := _content().moves.get_move("striker_jab")
	assert_true(
		at > 0 and at < jab.total_ticks(), "cancelled at %d of %d" % [at, jab.total_ticks()]
	)


func test_a_whiffed_basic_cannot_be_cancelled() -> void:
	var mika := _hero("striker")
	var far := _dummy(11, mika.position + Vector2(200, 0))
	var pair: Array[Fighter] = [mika, far]
	var at := -1
	for t in 40:
		var press := FighterInput.new()
		press.light = t == 0
		press.skill = "triple_punch" if t >= 4 else ""
		CombatRules.tick(pair, {mika.id: press}, _content().moves, BOUNDS)
		if at < 0 and mika.skill_id == "triple_punch":
			at = t
	var jab := _content().moves.get_move("striker_jab")
	assert_true(at >= jab.total_ticks(), "a miss recovers in full first (%d)" % at)


func test_heavy_armour_only_on_committed_moves() -> void:
	for pair: Array in [["brawler_hammer", true], ["brawler_left", false]]:
		var kan := _hero("brawler")
		var foe := _hero("striker", 50, 1)
		foe.team = 2
		foe.position = kan.position + Vector2(30, 0)
		foe.facing = -1
		CombatRules.start_move(kan, _content().moves.get_move(str(pair[0])))
		var fighters: Array[Fighter] = [kan, foe]
		var kept := true
		for t in 8:
			var jab := FighterInput.new()
			jab.light = t == 0
			CombatRules.tick(fighters, {foe.id: jab}, _content().moves, BOUNDS)
			kept = kept and kan.state == Fighter.State.ATTACK
		assert_eq(kept, pair[1], "%s keeps swinging through a jab: %s" % [pair[0], pair[1]])
	# Armour is the Brawler's alone (its committed heavies and its ultimate).
	var brawler: Dictionary = SkillRegistry.class_moves(_content())["brawler"]
	for move_id: String in _content().moves.moves:
		if _content().moves.get_move(move_id).armor:
			assert_true(brawler.has(move_id), "%s: armour is the Brawler's" % move_id)


func test_pvp_combos_scale_down_but_monsters_are_never_scaled() -> void:
	var a := _hero("striker")
	var b := _hero("boxer", 50, 1)
	b.state = Fighter.State.HITSTUN
	var scales: Array[float] = []
	for n in 9:
		scales.append(CombatRules.combo_scale(a, b))
	assert_eq(scales.slice(0, 3), [1.0, 1.0, 1.0] as Array[float], "the first three in full")
	assert_true(scales[4] < scales[3] and scales[3] < 1.0, "then less: %s" % str(scales))
	assert_near(scales[-1], CombatRules.PVP_COMBO_FLOOR, "never under the floor")
	b.state = Fighter.State.IDLE
	assert_eq(CombatRules.combo_scale(a, b), 1.0, "a hero back on their feet starts afresh")
	var monster := _dummy(20, Vector2.ZERO)
	monster.state = Fighter.State.HITSTUN
	for n in 9:
		assert_eq(CombatRules.combo_scale(a, monster), 1.0, "PvE is never scaled")


func test_a_throw_keeps_a_hero_down_less_long_in_pvp_only() -> void:
	var oren := _hero("grappler")
	var hero := _hero("boxer", 50, 1)
	var monster := _dummy(20, Vector2.ZERO)
	assert_eq(GrabRules.slam_down(oren, hero), GrabRules.SLAM_DOWN_PVP_TICKS, "PvP: shorter")
	assert_eq(GrabRules.slam_down(oren, monster), GrabRules.SLAM_DOWN_TICKS, "PvE: as before")
	assert_true(GrabRules.SLAM_DOWN_PVP_TICKS > CombatRules.KNOCKDOWN_TICKS, "still a real fall")
	# Thrown for real: once up, the hero cannot be seized again at once.
	var boxer := _hero("boxer", 50, 1)
	boxer.team = 2
	boxer.position = oren.position + Vector2(18, 0)
	boxer.facing = -1
	var fighters: Array[Fighter] = [oren, boxer]
	var guard_after := -1
	for t in 200:
		var press := FighterInput.new()
		press.skill = "power_throw" if t == 0 else ""
		press.light = oren.state == Fighter.State.GRAB
		CombatRules.tick(fighters, {oren.id: press}, _content().moves, BOUNDS)
		if boxer.state == Fighter.State.IDLE and guard_after < 0 and t > 30:
			guard_after = boxer.grab_guard
	assert_true(guard_after >= 60, "still guarded from a grab when up (%d)" % guard_after)


func test_the_check_hook_steps_back() -> void:
	var dao := _hero("counter")
	var start := dao.position.x
	CombatRules.start_move(dao, _content().moves.get_move("counter_check_hook"))
	var fighters: Array[Fighter] = [dao]
	for t in 12:
		CombatRules.tick(fighters, {}, _content().moves, BOUNDS)
	assert_true(dao.position.x < start - 8.0, "it retreats while it hooks (%.1f)" % dao.position.x)
