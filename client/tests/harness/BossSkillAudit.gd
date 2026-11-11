extends SceneTree
## Boss skill audit (docs/BOSS_SKILL_QUALITY_AUDIT.md): measures every boss
## skill (BossSkillRules) and every boss's AI in a fight. Read-only.
##
##   godot --headless --path client --script res://tests/harness/BossSkillAudit.gd
##
## Prints one "SKILL " JSON line per skill:
## * the data: type, moves, telegraph and cooldown (ticks), range, hitbox
##   [reach_offset, reach, depth], base damage;
## * "lands": it hurts a hero standing in range;
## * "dodged": a hero who reacts REACTION ticks into the wind-up (a dodge
##   roll away from a blow, a walk to the nearest clear ground from a hazard)
##   takes none of it;
## * "escape": for a combo, the fewest ticks a hero hit by one blow has before
##   the next can land (a dodge's invulnerability starts DODGE_IFRAME_START
##   ticks in);
## * "fx": the drawn width of its effect against the hitbox's (GameFeedback);
## * "share": the most of a hero's health it takes at the boss's level, per
##   gear profile in KITS.
## and one "BOSS " JSON line per boss from a long fight with the hero moving:
## the skills used, back-to-back repeats, the longest time in one attack, and
## the most of the street around the hero covered by waiting hazards.

## A human-like reaction: a quarter of a second after the wind-up begins.
const REACTION := 15
const ARENA := "saltmarket"
const HERO_X := 160.0
const ROAD_Y := 300.0
const KITS := {
	"S0": {"gear": "starter", "plus": 0},
	"B0": {"gear": "shop", "plus": 0},
	"B5": {"gear": "shop", "plus": 5},
	"D10": {"gear": "boss", "plus": 10},
}
const FIGHT_TICKS := 5400


func _init() -> void:
	var c := ContentDB.load_all()
	var kits := {}
	for kind: String in c.boss_skills["bosses"]:
		var level := _level(c, kind)
		kits[kind] = {}
		for kit: String in KITS:
			kits[kind][kit] = _hero_stats(c, level, kit)
	for kind: String in c.boss_skills["bosses"]:
		for id in BossSkillRules.of(c, kind):
			print("SKILL " + JSON.stringify(_audit(c, kind, id, kits[kind])))
		print("BOSS " + JSON.stringify(_fight_audit(c, kind)))
	quit(0)


static func _level(c: ContentDB, kind: String) -> int:
	for boss: String in c.world_bosses:
		if str(c.world_bosses[boss]["enemy"]) == kind:
			return WorldBossRules.level(c, boss)
	return int(c.boss_skills["bosses"][kind]["level"]) + LevelRules.BOSS_BONUS


static func _hero_stats(c: ContentDB, level: int, kit: String) -> Dictionary:
	var profile := PlayerProfile.new_game(c)
	profile.level = level
	for item_id in ProgressionHarness.gear(c, level, str(KITS[kit]["gear"])):
		profile.add_item(item_id)
		profile.equip(item_id, c)
		var key := profile.own_copy(str(c.item(item_id)["slot"]))
		profile.enhance[key] = int(KITS[kit]["plus"])
	var zone := ZoneSim.new(c, profile, ARENA, "west", 1)
	return {"hp": zone.hero.max_hp, "defense": zone.hero.defense}


static func _zone(c: ContentDB, kind: String, gap: float, seed_value: int) -> ZoneSim:
	var profile := PlayerProfile.new_game(c)
	profile.level = _level(c, kind)
	var zone := ZoneSim.new(c, profile, ARENA, "west", seed_value)
	zone.level = _level(c, kind) - LevelRules.BOSS_BONUS
	zone.hero.position = Vector2(HERO_X, ROAD_Y)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	var boss := zone.spawn_enemy(kind, Vector2(HERO_X + gap, ROAD_Y))
	boss.facing = -1
	zone.tick(FighterInput.new())
	return zone


static func _audit(c: ContentDB, kind: String, id: String, kits: Dictionary) -> Dictionary:
	var data := BossSkillRules.skill(c, id)
	var first := c.moves.get_move(str(data["moves"][0]))
	var span: Array = data["range"]
	var gap := clampf((float(span[0]) + float(span[1])) / 2.0, 30.0, 160.0)
	var out := {
		"id": id,
		"owner": kind,
		"tier": BossSkillRules.tier(c, kind),
		"level": int(c.boss_skills["bosses"][kind]["level"]),
		"name": data["name"],
		"type": data["type"],
		"moves": (data["moves"] as Array).size(),
		"telegraph": BossSkillRules.telegraph(c, id),
		"windup": first.startup,
		"cooldown": int(data["cooldown"]),
		"phase": int(data["phase"]),
		"range": span,
		"damage": BossSkillRules.damage(c, id),
	}
	if not BossSkillRules.is_cast(data):
		out["hitbox"] = [first.reach_offset, first.reach, first.depth_tolerance]
		out["advance"] = first.advance
		# GameFeedback.hit_width and fit (a scene class this script cannot load).
		var width := first.reach + 2.0 * CombatRules.HURT_HALF_WIDTH
		var art := float(c.fx["effects"][str(data["fx"])]["size"][0])
		var size := clampf(width / art, 0.3, 1.5)
		out["fx"] = [roundi(float(c.fx["effects"][str(data["fx"])]["size"][0]) * size), width]
	elif data.has("hazard"):
		out["hazard"] = data["hazard"]
	if data.has("waves"):
		# An Ultimate: its escape is planned wave by wave (test_boss_ultimates).
		out["waves"] = (data["waves"] as Array).size()
		out["lands"] = _run(c, kind, id, 40.0, "stand") > 0
		out["dodged"] = "planned"
	elif data.has("summon"):
		out["lands"] = _summons(c, kind, id)
		out["dodged"] = "n/a"
	else:
		out["lands"] = _run(c, kind, id, gap, "stand") > 0
		var ways: Array[String] = []
		for how in ["back", "through", "side"]:
			if _run(c, kind, id, gap, how) == 0:
				ways.append(how)
		out["dodged"] = ways
	out["escape"] = _escape(c, data)
	out["share"] = _shares(c, kind, id, kits)
	return out


## Damage the hero takes from skill `id`. Strategy "stand": still, in
## range. Else the hero answers REACTION ticks after the warning (a blow's
## wind-up, a hazard's mark on the ground): "back" rolls away, "through" rolls
## timed for the blow's active ticks (a learnt rhythm), "side" steps out of its
## lane; from a hazard every strategy walks to the nearest clear ground.
static func _run(c: ContentDB, kind: String, id: String, gap: float, how: String) -> int:
	var zone := _zone(c, kind, gap, 3)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	var data := BossSkillRules.skill(c, id)
	boss.cooldowns.erase(id)
	brain.planned_skill = id
	brain.cooldown = 0
	brain.skill_wait = 0
	var kinds: Array = [str(data.get("hazard", {}).get("kind", ""))]
	for wave: Dictionary in data.get("waves", []):
		kinds.append(str(wave["kind"]))
	var taken := 0
	var since := -1
	var target := Vector2.INF
	var first := c.moves.get_move(str(data["moves"][0]))
	var rolled := false
	for tick in 420:
		var input := FighterInput.new()
		if since >= 0:
			since += 1
		if how != "stand" and since >= REACTION:
			if data.has("hazard"):
				target = _clear_spot(zone) if since == REACTION else target
			elif how == "back" and since == REACTION:
				input.dodge = true
				input.move = Vector2(signf(zone.hero.position.x - boss.position.x), 0)
			elif how == "through" and not rolled and _about_to_hit(zone, boss, first, since):
				# Rolled into the blow as it arrives: a lunge when it is about to
				# reach the hero, a blow in place on the rhythm of its wind-up.
				rolled = true
				input.dodge = true
				input.move = Vector2(signf(boss.position.x - zone.hero.position.x), 0)
			elif how == "side" and since < REACTION + 40:
				input.move = Vector2(0, -1)
		if target != Vector2.INF:
			input.move = (target - zone.hero.position).limit_length(1.0)
			if zone.hero.position.distance_to(target) < 2.0:
				input.move = Vector2.ZERO
		zone.hero.hp = zone.hero.max_hp
		if how == "stand":
			zone.hero.position = Vector2(HERO_X, ROAD_Y)
		for event in zone.tick(input):
			var ground := data.has("hazard") or data.has("waves")
			var warned := event.type == "hazard_warn" and ground
			var swung := event.type == "swing" and str(event.data.get("skill", "")) == id
			if swung and data.has("waves"):
				# No plain blow knocks the hero down before the waves land.
				brain.cooldown = 600
			if since < 0 and (warned or (swung and not ground)):
				since = 0
			if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				var hit := event.hit
				var ours: bool = (
					hit.move_id in data["moves"] or (hit.move_id and hit.move_id in kinds)
				)
				if hit.attacker_id == boss.id and ours:
					taken += hit.damage
		# One use only: done once the skill has ended and nothing waits to land.
		var running: bool = zone._boss_mechanics.skills.active() == id
		if since > 20 and not running and zone.hazards.is_empty():
			break
	return taken


## True when a hero rolling now meets `move`'s blow inside the roll's
## invulnerability: a lunge about to reach them, or a blow in place a few
## ticks before its hitbox opens.
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


## True when summon skill `id` brings helpers in.
static func _summons(c: ContentDB, kind: String, id: String) -> bool:
	var zone := _zone(c, kind, 60.0, 3)
	var brain: EnemyBrain = zone.brains[zone.boss_id]
	brain.planned_skill = id
	brain.cooldown = 0
	brain.skill_wait = 0
	for tick in 240:
		zone.hero.hp = zone.hero.max_hp
		for event in zone.tick(FighterInput.new()):
			if event.type == "boss_summon":
				return not (event.data["ids"] as Array).is_empty()
	return false


## The nearest spot no waiting hazard covers: along the street or a step up
## or down the lane (a player does both).
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


## A combo's tightest window between being hit and the next blow landing
## (ticks), or -1 for a single blow.
static func _escape(c: ContentDB, data: Dictionary) -> int:
	var moves: Array = data["moves"]
	if moves.size() < 2 or BossSkillRules.is_cast(data):
		return -1
	var least := 9999
	for i in moves.size() - 1:
		var hit := c.moves.get_move(str(moves[i]))
		var next := c.moves.get_move(str(moves[i + 1]))
		# Hit on its first active tick: the rest of it, then the next wind-up.
		var until_next := hit.active + hit.recovery + next.startup
		least = mini(least, until_next - hit.hitstun)
	return least


static func _shares(c: ContentDB, kind: String, id: String, kits: Dictionary) -> Dictionary:
	var power := float(LevelRules.enemy_stats(c.enemy(kind), _level(c, kind))["power"])
	var data := BossSkillRules.skill(c, id)
	var out := {}
	for kit: String in kits:
		var hero: Dictionary = kits[kit]
		var total := 0
		if data.has("hazard"):
			total = maxi(1, roundi(float(data["hazard"]["damage"]) * power) - int(hero["defense"]))
		elif data.has("waves"):
			# An Ultimate: one wave's hit (its strongest), the share reported.
			for wave: Dictionary in data["waves"]:
				var hit := maxi(1, roundi(float(wave["damage"]) * power) - int(hero["defense"]))
				total = maxi(total, hit)
		elif not data.has("summon"):
			for move_id: Variant in data["moves"]:
				var move := c.moves.get_move(str(move_id))
				total += maxi(1, roundi(move.damage * power) - int(hero["defense"]))
		out[kit] = snappedf(float(total) / float(hero["hp"]), 0.01)
	return out


## A long fight with the hero drifting about: what the AI does.
static func _fight_audit(c: ContentDB, kind: String) -> Dictionary:
	var zone := _zone(c, kind, 90.0, 7)
	var boss := zone.fighter(zone.boss_id)
	var used := {}
	var repeats := 0
	var last := ""
	var attack_run := 0
	var longest_attack := 0
	var crowded := 0.0
	var far_casts := 0
	for tick in FIGHT_TICKS:
		zone.hero.hp = zone.hero.max_hp
		var x := HERO_X + 140.0 + 160.0 * sin(tick / 110.0)
		zone.hero.position = Vector2(x, ROAD_Y + 20.0 * sin(tick / 37.0))
		# Half way through, the boss is hurt into its later phases.
		if tick == FIGHT_TICKS / 2:
			boss.hp = maxi(1, boss.max_hp / 4)
		for event in zone.tick(FighterInput.new()):
			if event.type == "swing" and int(event.data["id"]) == boss.id:
				var skill := str(event.data["skill"])
				if skill:
					used[skill] = int(used.get(skill, 0)) + 1
					repeats += int(skill == last)
					last = skill
					var gap := absf(zone.hero.position.x - boss.position.x)
					var span: Array = BossSkillRules.skill(c, skill)["range"]
					far_casts += int(gap > float(span[1]) + 20.0)
		attack_run = attack_run + 1 if boss.state == Fighter.State.ATTACK else 0
		longest_attack = maxi(longest_attack, attack_run)
		crowded = maxf(crowded, _covered(zone))
		if boss.is_ko():
			break
	var evade := _evade_fight(c, kind)
	return {
		"evade_hits": evade[0],
		"evade_landed": evade[1],
		"boss": kind,
		"tier": BossSkillRules.tier(c, kind),
		"skills": BossSkillRules.of(c, kind).size(),
		"used": used,
		"repeats": repeats,
		"far_casts": far_casts,
		"longest_attack": longest_attack,
		"phase_reached": zone.phase_of(boss.id),
		"covered": snappedf(crowded, 0.01),
	}


## A fight where the hero only dodges hazards, walking to the nearest clear
## ground whenever any wait: [hazard hits taken, hazards landed].
static func _evade_fight(c: ContentDB, kind: String) -> Array:
	var zone := _zone(c, kind, 90.0, 11)
	var boss := zone.fighter(zone.boss_id)
	var hits := 0
	var landed := 0
	var target := Vector2.INF
	var wait := 0
	for tick in FIGHT_TICKS:
		zone.hero.hp = zone.hero.max_hp
		if tick == FIGHT_TICKS / 2:
			boss.hp = maxi(1, boss.max_hp / 4)
		var input := FighterInput.new()
		if zone.hazards.is_empty():
			target = Vector2.INF
			wait = 0
		else:
			wait += 1
			if wait == REACTION or (wait > REACTION and wait % 10 == 0):
				target = _clear_spot(zone)
		if target != Vector2.INF and zone.hero.position.distance_to(target) > 2.0:
			input.move = (target - zone.hero.position).limit_length(1.0)
		for event in zone.tick(input):
			if event.type == "hazard_hit":
				landed += 1
			if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				if event.hit.move_id in BossMechanics.KINDS:
					hits += 1
		if boss.is_ko():
			break
	return [hits, landed]


## The share of the street within 120 px either side of the hero, in their
## lane, under a waiting hazard.
static func _covered(zone: ZoneSim) -> float:
	if zone.hazards.is_empty():
		return 0.0
	var hero := zone.hero.position
	var under := 0
	for step in 49:
		var at := Vector2(hero.x - 120.0 + step * 5.0, hero.y)
		for drop: Dictionary in zone.hazards:
			var gap: Vector2 = (at - drop["at"]).abs()
			var half: Vector2 = drop["half"]
			if gap.x <= half.x and gap.y <= half.y:
				under += 1
				break
	return under / 49.0
