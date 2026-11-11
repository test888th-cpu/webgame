extends TestCase
## Hard but fair (docs/BOSS_SKILL_QUALITY_AUDIT.md, D-2 and R-1): every regular
## boss skill that hurts can be avoided by a hero who reacts a quarter of a
## second (REACTION ticks) after its warning, in at least one way a player has:
## a roll away ("back"), a roll timed into the blow ("through"), a step out of
## its lane ("side"), or, from a hazard, a walk to clear ground. Ultimates have
## their own, wave-by-wave escape test (test_boss_ultimates).

const ARENA := "saltmarket"
const HERO_X := 160.0
const ROAD_Y := 300.0
const REACTION := 15

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _level(kind: String) -> int:
	for boss: String in _content().world_bosses:
		if str(_content().world_bosses[boss]["enemy"]) == kind:
			return WorldBossRules.level(_content(), boss)
	return int(_content().boss_skills["bosses"][kind]["level"]) + LevelRules.BOSS_BONUS


func _zone(kind: String, gap: float) -> ZoneSim:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = _level(kind)
	var zone := ZoneSim.new(c, profile, ARENA, "west", 3)
	zone.level = _level(kind) - LevelRules.BOSS_BONUS
	zone.hero.position = Vector2(HERO_X, ROAD_Y)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	var boss := zone.spawn_enemy(kind, Vector2(HERO_X + gap, ROAD_Y))
	boss.facing = -1
	zone.tick(FighterInput.new())
	return zone


## The nearest spot no waiting hazard covers, along the street or a step up
## or down the lane.
static func _clear_spot(zone: ZoneSim) -> Vector2:
	var hero := zone.hero.position
	var best := hero
	var best_gap := INF
	for dy in [0.0, -24.0, 24.0, -44.0, 44.0]:
		for step in 61:
			for side in [-1.0, 1.0]:
				var at := Vector2(hero.x + side * step * 6.0, hero.y + dy)
				if not zone.bounds.grow(-6.0).has_point(at):
					continue
				var clear := true
				for drop: Dictionary in zone.hazards:
					var gap: Vector2 = (at - drop["at"]).abs()
					var half: Vector2 = drop["half"]
					clear = clear and (gap.x > half.x + 10.0 or gap.y > half.y + 10.0)
				if clear and hero.distance_to(at) < best_gap:
					best = at
					best_gap = hero.distance_to(at)
	return best


## A roll now meets `move`'s blow inside the roll's invulnerability: a lunge
## about to reach the hero, or a blow in place a few ticks before its hitbox.
static func _about_to_hit(zone: ZoneSim, boss: Fighter, move: MoveData, since: int) -> bool:
	if boss.state != Fighter.State.ATTACK or boss.move != move:
		return false
	# A blow can land only once its hitbox opens (the end of its wind-up), so
	# the roll is timed for the later of that beat and the lunge's arrival.
	if since < move.startup - CombatRules.DODGE_IFRAME_START:
		return false
	if move.advance <= 0.0:
		return true
	var per_tick := move.advance / (move.startup + move.active)
	var gap := absf(zone.hero.position.x - boss.position.x)
	var far := move.reach_offset + move.reach + CombatRules.HURT_HALF_WIDTH
	return gap - per_tick * 3.0 <= far


## Damage the hero takes from one use of skill `id`, answering `how`.
func _run(kind: String, id: String, gap: float, how: String) -> int:
	var c := _content()
	var zone := _zone(kind, gap)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	var data := BossSkillRules.skill(c, id)
	boss.cooldowns.erase(id)
	brain.planned_skill = id
	brain.cooldown = 0
	brain.skill_wait = 0
	var kind_of_hazard := str(data.get("hazard", {}).get("kind", ""))
	var first := c.moves.get_move(str(data["moves"][0]))
	var taken := 0
	var since := -1
	var target := Vector2.INF
	var rolled := false
	for tick in 420:
		var input := FighterInput.new()
		if since >= 0:
			since += 1
		if since >= REACTION:
			if data.has("hazard"):
				target = _clear_spot(zone) if since == REACTION else target
			elif how == "back" and since == REACTION:
				input.dodge = true
				input.move = Vector2(signf(zone.hero.position.x - boss.position.x), 0)
			elif how == "through" and not rolled and _about_to_hit(zone, boss, first, since):
				rolled = true
				input.dodge = true
				input.move = Vector2(signf(boss.position.x - zone.hero.position.x), 0)
			elif how == "side" and since < REACTION + 40:
				input.move = Vector2(0, -1)
		if target != Vector2.INF and zone.hero.position.distance_to(target) > 2.0:
			input.move = (target - zone.hero.position).limit_length(1.0)
		zone.hero.hp = zone.hero.max_hp
		for event in zone.tick(input):
			var warned := event.type == "hazard_warn" and data.has("hazard")
			var swung := event.type == "swing" and str(event.data.get("skill", "")) == id
			if since < 0 and (warned or (swung and not data.has("hazard"))):
				since = 0
			if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				var hit := event.hit
				var ours: bool = (
					hit.move_id in data["moves"]
					or (kind_of_hazard and hit.move_id == kind_of_hazard)
				)
				if hit.attacker_id == boss.id and ours:
					taken += hit.damage
		var running: bool = zone._boss_mechanics.skills.active() == id
		if since > 20 and not running and zone.hazards.is_empty():
			break
	return taken


func test_every_regular_skill_can_be_avoided_on_reaction() -> void:
	var c := _content()
	var checked := 0
	for kind: String in c.boss_skills["bosses"]:
		for id in BossSkillRules.of(c, kind):
			var data := BossSkillRules.skill(c, id)
			if BossSkillRules.is_ultimate(data) or data.has("summon"):
				continue
			var span: Array = data["range"]
			var gap := clampf((float(span[0]) + float(span[1])) / 2.0, 30.0, 160.0)
			var ways: Array[String] = []
			for how in ["back", "through", "side"]:
				if _run(kind, id, gap, how) == 0:
					ways.append(how)
					break
			assert_true(not ways.is_empty(), "%s (%s): avoidable on reaction" % [id, data["type"]])
			checked += 1
	assert_eq(checked, 107, "every damaging regular skill")


func test_the_timings_that_make_it_fair_are_kept() -> void:
	var c := _content()
	for id: String in c.boss_skills["skills"]:
		var data := BossSkillRules.skill(c, id)
		if BossSkillRules.is_cast(data):
			continue
		var moves: Array = data["moves"]
		var first := c.moves.get_move(str(moves[0]))
		assert_true(first.startup >= BossSkillRules.MIN_OPENER_WINDUP, id + ": its opener is seen")
		if first.advance >= EnemyBrain.CHARGE_ADVANCE:
			assert_true(
				first.startup >= BossSkillRules.MIN_CHARGE_WINDUP, id + ": a charge's wind-up"
			)
		for i in moves.size() - 1:
			var hit := c.moves.get_move(str(moves[i]))
			var next := c.moves.get_move(str(moves[i + 1]))
			assert_true(
				BossSkillRules.escape_window(hit, next) >= BossSkillRules.MIN_ESCAPE,
				id + ": time to roll out between blows"
			)
	var broken := ContentDB.load_all()
	broken.moves.get_move("bs_wb_founders_engine_002").startup = 18
	broken.moves.get_move("bs_wb_founders_engine_001").startup = 12
	broken.moves.get_move("bs_wb_founders_engine_001").hitstun = 30
	var said := "\n".join(BossSkillRules.problems(broken))
	assert_true(
		"bs_wb_founders_engine_002 winds up at least 24" in said, "a quick charge is caught"
	)
	assert_true("bs_wb_founders_engine_001 winds up at least 18" in said, "a quick opener too")
	assert_true("ticks to escape" in said, "and a combo with no way out")
