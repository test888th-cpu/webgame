extends SceneTree
## Boss playtest scenarios (docs/BOSS_PLAYTEST_PLAN.md): reproducible, SCRIPTED
## SIMULATION of every boss's Ultimate. A scripted hero is not a person: these
## runs show what the rules allow, never how a player will feel. Read-only.
##
##   godot --headless --path client --script res://tests/harness/BossPlaytestScenarios.gd
##   (BOSSES=a,b to run only some bosses; PARTS=power,move,life to run some parts;
##   HERO=riku to play one hero, and so one job, instead of the default hero;
##   VARIANTS=base,roll to run only some movement variants)
##
## Prints one JSON line per result:
## * "POWER": the Ultimate's damage at the boss's level against five kits, with
##   its base power, the strongest phase's power and that phase under enrage
##   (a stage boss's fight enrage, a world boss's round enrage).
## * "MOVE": one movement scenario: start (gap, lane), hero speed, frame rate,
##   input delay and answer (walk, or walk and a timed roll); the damage taken
##   from the Ultimate and the fewest ticks spare before a wave landed.
## * "LIFE": the encounter's edges: repeated Ultimates in a long fight, the
##   hero falling, the boss falling, a world boss escaping, all mid-Ultimate,
##   and hazards overlapping before and during it.

const ARENA := "saltmarket"
const HERO_X := 300.0
const ROAD_Y := 300.0
## A quarter of a second after each wave is marked.
const REACTION := 15
const EDGE := 6.0
## Steps across the street (px) the planner tries: every 12 px, then every 4.
const STYLES := [
	[-60.0, -48.0, -36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0, 48.0, 60.0],
	[-60.0, -52.0, -44.0, -36.0, -28.0, -20.0, -12.0, -4.0, 4.0, 12.0, 20.0, 28.0, 36.0, 44.0],
	[-56.0, -48.0, -40.0, -32.0, -24.0, -16.0, -8.0, 0.0, 8.0, 16.0, 24.0, 32.0, 40.0, 48.0, 56.0],
]
const KITS := {
	"S0": ["starter", 0],
	"AP": ["boss", 0],
	"B0": ["shop", 0],
	"B5": ["shop", 5],
	"D10": ["boss", 10],
}
## One factor at a time from the baseline, then the combined worst case.
## speed: the hero's walk against the default hero's (0.8: the slowest hero;
## 0.64: the slowest hero with the slowest weapon); fps: frames a second, the
## sim at a fixed 60 ticks (at 30 the same input is held for two ticks);
## delay: ticks of input latency on top of the reaction; roll: also roll
## through a wave the hero cannot leave in time.
const VARIANTS := {
	"base": {"speed": 1.0, "fps": 60, "delay": 0, "roll": false},
	"slow_hero": {"speed": 0.8, "fps": 60, "delay": 0, "roll": false},
	"slowest_kit": {"speed": 0.64, "fps": 60, "delay": 0, "roll": false},
	"fps30": {"speed": 1.0, "fps": 30, "delay": 0, "roll": false},
	"fps120": {"speed": 1.0, "fps": 120, "delay": 0, "roll": false},
	"lag100ms": {"speed": 1.0, "fps": 60, "delay": 6, "roll": false},
	"lag200ms": {"speed": 1.0, "fps": 60, "delay": 12, "roll": false},
	"roll": {"speed": 1.0, "fps": 60, "delay": 0, "roll": true},
	"slow_lag_roll": {"speed": 0.8, "fps": 30, "delay": 6, "roll": true},
	"slow_hero_roll": {"speed": 0.8, "fps": 60, "delay": 0, "roll": true},
	"slowest_kit_roll": {"speed": 0.64, "fps": 60, "delay": 0, "roll": true},
	"lag200ms_roll": {"speed": 1.0, "fps": 60, "delay": 12, "roll": true},
}
const STARTS := [[50.0, -30.0], [50.0, 30.0], [150.0, 0.0], [250.0, -30.0], [250.0, 30.0]]
const FIGHT_TICKS := 6000

var content: ContentDB
## The default hero's walk, px a tick, along and across the street.
var walk := Vector2.ZERO


func _init() -> void:
	content = ContentDB.load_all()
	var only := OS.get_environment("BOSSES")
	var parts := OS.get_environment("PARTS")
	if parts == "":
		parts = "power,move,life"
	walk = _measure_walk()
	print("WALK %s" % walk)
	for kind: String in content.boss_skills["bosses"]:
		if only != "" and kind not in only.split(","):
			continue
		if "power" in parts:
			_power(kind)
		if "move" in parts:
			for name: String in VARIANTS:
				var wanted := OS.get_environment("VARIANTS")
				if wanted != "" and name not in wanted.split(","):
					continue
				_movement(kind, name)
		if "life" in parts:
			_life(kind)
	quit()


func _level(kind: String) -> int:
	for boss: String in content.world_bosses:
		if str(content.world_bosses[boss]["enemy"]) == kind:
			return WorldBossRules.level(content, boss)
	return int(content.boss_skills["bosses"][kind]["level"]) + LevelRules.BOSS_BONUS


func _world_boss(kind: String) -> String:
	for boss: String in content.world_bosses:
		if str(content.world_bosses[boss]["enemy"]) == kind:
			return boss
	return ""


## The default hero's walk, measured: ten ticks right, then ten down.
func _measure_walk() -> Vector2:
	var zone := _street("sludge_foreman", 400.0)
	zone.fighters.erase(zone.fighter(zone.boss_id))
	var start := zone.hero.position
	var right := FighterInput.new()
	right.move = Vector2(1, 0)
	for i in 10:
		zone.tick(right)
	var along := (zone.hero.position.x - start.x) / 10.0
	start = zone.hero.position
	var down := FighterInput.new()
	down.move = Vector2(0, 1)
	for i in 10:
		zone.tick(down)
	return Vector2(along, (zone.hero.position.y - start.y) / 10.0)


## A street, the hero `gap` px from boss `kind` (never hurt: damage is read
## from the hit events).
func _street(kind: String, gap: float, profile: PlayerProfile = null) -> ZoneSim:
	if profile == null:
		profile = PlayerProfile.new_game(content, OS.get_environment("HERO"))
		profile.level = _level(kind)
	var zone := ZoneSim.new(content, profile, ARENA, "west", 5)
	zone.level = _level(kind) - LevelRules.BOSS_BONUS
	zone.hero.position = Vector2(HERO_X, ROAD_Y)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	var boss := zone.spawn_enemy(kind, Vector2(HERO_X + gap, ROAD_Y))
	boss.facing = -1
	zone.tick(FighterInput.new())
	return zone


## Presses `kind`'s Ultimate now.
func _press(zone: ZoneSim) -> String:
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	var id := BossSkillRules.ultimate_of(content, boss.kind)
	boss.cooldowns.erase(id)
	brain.planned_skill = id
	brain.cooldown = 0
	brain.skill_wait = 0
	return id


func _mine(zone: ZoneSim, id: String) -> bool:
	return zone.hazards.any(func(d: Dictionary) -> bool: return d["from"] == id)


# --- POWER ------------------------------------------------------------------


func _power(kind: String) -> void:
	var data := content.enemy(kind)
	var level := _level(kind)
	var id := BossSkillRules.ultimate_of(content, kind)
	var ult := BossSkillRules.skill(content, id)
	var from := int(ult.get("phase", 0))
	var base := float(LevelRules.enemy_stats(data, level)["power"])
	var phases: Array = data.get("phases", [])
	var strongest := base if from == 0 else 0.0
	var at_phase := 0
	for i in phases.size():
		if i + 1 < from:
			continue
		var p := float(LevelRules.phase_stats(data, phases[i], level)["power"])
		if p > strongest:
			strongest = p
			at_phase = i + 1
	var rage := float(data.get("enrage", {}).get("damage", 1.0))
	var rage_kind := "fight" if data.has("enrage") else ""
	var world := _world_boss(kind)
	if world != "":
		var spec: Dictionary = WorldBossRules.spec(content, world).get("enrage", {})
		if not spec.is_empty():
			rage = maxf(rage, float(spec.get("damage", 1.0)))
			rage_kind = "round"
	var light := float(content.moves.get_move(str(data["moveset"]["light"])).damage)
	var waves: Array = ult["waves"]
	var kits := {}
	for kit: String in KITS:
		var profile := PlayerProfile.new_game(content, OS.get_environment("HERO"))
		profile.level = level
		for item_id in ProgressionHarness.gear(content, level, str(KITS[kit][0])):
			profile.add_item(item_id)
			profile.equip(item_id, content)
			profile.enhance[profile.own_copy(str(content.item(item_id)["slot"]))] = int(
				KITS[kit][1]
			)
		var zone := ZoneSim.new(content, profile, ARENA, "west", 1)
		var row := {"hp": zone.hero.max_hp, "def": zone.hero.defense}
		for case: String in ["base", "phase", "enraged"]:
			var power := base
			if case == "phase":
				power = strongest
			elif case == "enraged":
				power = strongest * rage
			var worst := 0.0
			var total := 0.0
			for wave: Dictionary in waves:
				# BossMechanics.call_hazard, then CombatRules.thrown_hit.
				var hit := maxf(1.0, roundf(float(wave["damage"]) * power) - zone.hero.defense)
				worst = maxf(worst, hit)
				total += hit
			row[case] = [
				snappedf(worst / zone.hero.max_hp * 100.0, 0.1),
				snappedf(total / zone.hero.max_hp * 100.0, 0.1)
			]
		kits[kit] = row
	var out := {
		"boss": kind,
		"ult": id,
		"level": level,
		"waves": waves.size(),
		"wave_damage": waves.map(func(w: Dictionary) -> int: return int(w["damage"])),
		"warn": waves.map(func(w: Dictionary) -> int: return int(w["warn"])),
		"times_light": snappedf(float(waves[0]["damage"]) / light, 0.01),
		"power":
		{
			"base": snappedf(base, 0.001),
			"strongest_phase": at_phase,
			"phase": snappedf(strongest, 0.001),
			"enrage": rage,
			"enrage_kind": rage_kind
		},
		"kits": kits,
	}
	print("POWER " + JSON.stringify(out))


# --- MOVE -------------------------------------------------------------------


func _movement(kind: String, name: String) -> void:
	var v: Dictionary = VARIANTS[name]
	var worst_taken := 0
	var worst_spare := 9999
	var hit_starts: Array = []
	var rolls := 0
	for start: Array in STARTS:
		var best := [9999, -1, 0]
		for style: Array in STYLES:
			var run := _escape(kind, float(start[0]), float(start[1]), style, v)
			if run[0] < best[0] or (run[0] == best[0] and run[1] > best[1]):
				best = run
			if best[0] == 0 and best[1] >= 12:
				break
		worst_taken = maxi(worst_taken, best[0])
		worst_spare = mini(worst_spare, best[1])
		rolls += best[2]
		if best[0] > 0:
			hit_starts.append(start)
	var out := {
		"boss": kind,
		"variant": name,
		"setup": v,
		"taken": worst_taken,
		"spare": worst_spare,
		"rolls": rolls,
		"hit_from": hit_starts,
	}
	print("MOVE " + JSON.stringify(out))


## Where a hero heads: clear of the next wave to land and reachable before it
## at `pace` once `delay` ticks of lag have passed, clear of the wave after if
## it can be, nearest first.
func _plan(zone: ZoneSim, lanes: Array, pace: Vector2, delay: int) -> Vector2:
	var hero := zone.hero.position
	var boss := zone.fighter(zone.boss_id)
	var first := 9999
	for drop: Dictionary in zone.hazards:
		first = mini(first, int(drop["ticks"]))
	var now := zone.hazards.filter(func(d: Dictionary) -> bool: return int(d["ticks"]) <= first + 2)
	var later := zone.hazards.filter(
		func(d: Dictionary) -> bool: return int(d["ticks"]) > first + 2
	)
	var best := hero
	var best_score := INF
	for dx in range(-320, 321, 4):
		for dy: float in lanes:
			var at := hero + Vector2(dx, dy)
			if not zone.bounds.grow(-4.0).has_point(at):
				continue
			if boss:
				var body := (at - boss.position).abs()
				if body.x < Bodies.PERSON.x * 2.0 + 2.0 and body.y < Bodies.PERSON.y * 2.0 + 2.0:
					continue
			var ticks := maxf(absf(dx) / pace.x, absf(dy) / pace.y)
			if ticks + delay > first - 1 or _covers(at, now, EDGE):
				continue
			var score := ticks + (1000.0 if _covers(at, later, EDGE) else 0.0)
			if score < best_score:
				best = at
				best_score = score
	return best


static func _covers(at: Vector2, drops: Array, margin := 0.0) -> bool:
	for drop: Dictionary in drops:
		var gap: Vector2 = (at - drop["at"]).abs()
		var half: Vector2 = drop["half"]
		if gap.x <= half.x + margin and gap.y <= half.y + margin:
			return true
	return false


## One run: [damage taken, fewest spare ticks before a wave landed, rolls].
func _escape(kind: String, gap: float, lane: float, style: Array, v: Dictionary) -> Array:
	var zone := _street(kind, gap)
	zone.hero.speed *= float(v["speed"])
	zone.hero.position.y = ROAD_Y + lane
	var pace: Vector2 = walk * float(v["speed"])
	var id := _press(zone)
	var cast := false
	for tick in 120:
		zone.tick(FighterInput.new())
		if _mine(zone, id):
			cast = true
			break
	if not cast:
		return [9999, -1, 0]
	var hold := 2 if int(v["fps"]) == 30 else 1
	var queue: Array[FighterInput] = []
	var since := 0
	var taken := 0
	var rolls := 0
	var spare := 9999
	var last_in := {}
	var held := FighterInput.new()
	for tick in 600:
		zone.hero.hp = zone.hero.max_hp
		for i in range(zone.hazards.size() - 1, -1, -1):
			if zone.hazards[i]["from"] != id:
				zone.hazards.remove_at(i)
		for enemy in zone.enemies():
			if enemy.id != zone.boss_id:
				zone.fighters.erase(enemy)
		if zone.hazards.is_empty() and tick > 260:
			break
		since += 1
		# What the player's hands do this tick (read once a frame).
		var hands := FighterInput.new()
		if tick % hold == 0:
			if since >= REACTION:
				var to := _plan(zone, style, pace, int(v["delay"])) - zone.hero.position
				hands.move = Vector2(
					signf(to.x) if absf(to.x) > 1.0 else 0.0,
					signf(to.y) if absf(to.y) > 1.0 else 0.0
				)
				if bool(v["roll"]) and _must_roll(zone, int(v["delay"])):
					hands.dodge = true
					hands.move.x = hands.move.x if hands.move.x != 0.0 else -zone.hero.facing
			held = hands
		else:
			# The second physics step of a 30 FPS frame: the same keys, no new press.
			hands = FighterInput.new()
			hands.move = held.move
		queue.append(hands)
		var input: FighterInput = (
			queue.pop_front() if queue.size() > int(v["delay"]) else FighterInput.new()
		)
		rolls += int(input.dodge)
		var waiting := {}
		for drop: Dictionary in zone.hazards:
			var wave := int(drop["wave"])
			waiting[wave] = true
			last_in[wave] = last_in.get(wave, tick)
			if _covers(zone.hero.position, [drop]):
				last_in[wave] = tick
		for event in zone.tick(input):
			if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				if event.hit.move_id in BossMechanics.KINDS:
					taken += event.hit.damage
		for wave: int in waiting:
			if not zone.hazards.any(func(d: Dictionary) -> bool: return int(d["wave"]) == wave):
				spare = mini(spare, tick - int(last_in[wave]))
	return [taken, spare, rolls]


## A roll pressed now (arriving `delay` ticks later) covers the landing of a
## wave the hero still stands in.
func _must_roll(zone: ZoneSim, delay: int) -> bool:
	if zone.hero.state != Fighter.State.IDLE:
		return false
	for drop: Dictionary in zone.hazards:
		var lands := int(drop["ticks"]) - delay
		if (
			_covers(zone.hero.position, [drop])
			and lands > CombatRules.DODGE_IFRAME_START
			and lands < CombatRules.DODGE_IFRAME_END - 1
		):
			return true
	return false


# --- LIFE -------------------------------------------------------------------


func _life(kind: String) -> void:
	var out := {"boss": kind}
	out["repeat"] = _repeated(kind)
	out["hero_falls"] = _hero_falls(kind)
	out["boss_falls"] = _boss_falls(kind)
	out["overlap_before"] = _overlap_before(kind)
	if _world_boss(kind) != "":
		out["escape"] = _escape_mid_ultimate(kind)
	print("LIFE " + JSON.stringify(out))


## A long fight at a third of its health (every phase reached), the hero
## pacing: every Ultimate's tick, the shortest gap between two, and any other
## hazard waiting while one is channelled.
func _repeated(kind: String) -> Dictionary:
	var zone := _street(kind, 140.0)
	var boss := zone.fighter(zone.boss_id)
	boss.hp = maxi(1, roundi(boss.max_hp * 0.14))
	var id := BossSkillRules.ultimate_of(content, kind)
	var casts: Array[int] = []
	# Hazards called while the Ultimate is channelled (none should be), and
	# hazards from before the cast still waiting when a wave is marked (none).
	var called := 0
	var carried := 0
	var carried_in := 0
	var phases := 0
	var seen: Array[Dictionary] = []
	for tick in FIGHT_TICKS:
		zone.hero.hp = zone.hero.max_hp
		zone.hero.position = Vector2(HERO_X + 90.0 * sin(tick / 70.0), ROAD_Y)
		boss.hp = maxi(boss.hp, 1)
		var was := zone._boss_mechanics.skills.channeling()
		for event in zone.tick(FighterInput.new()):
			if event.type == "swing" and str(event.data.get("skill", "")) == id:
				casts.append(tick)
				carried_in += (
					zone.hazards.filter(func(d: Dictionary) -> bool: return d["from"] != id).size()
				)
			phases = maxi(phases, int(event.data.get("phase", 0)) * int(event.type == "boss_phase"))
		var mine := _mine(zone, id)
		for drop: Dictionary in zone.hazards:
			var fresh := not seen.any(func(d: Dictionary) -> bool: return is_same(d, drop))
			if drop["from"] != id:
				called += int(fresh and was)
				carried += int(fresh == false and mine)
		seen.assign(zone.hazards.duplicate())
	var gap := 99999
	for i in range(1, casts.size()):
		gap = mini(gap, casts[i] - casts[i - 1])
	return {
		"casts": casts.size(),
		"first": casts[0] if casts.size() > 0 else -1,
		"min_gap": gap,
		"cooldown": int(BossSkillRules.skill(content, id)["cooldown"]),
		"phase": phases,
		"hazards_waiting_at_casts": carried_in,
		"called_while_channelled": called,
		"earlier_waiting_beside_a_wave": carried,
	}


## The hero, at one health point, stands in the first wave: the run ends with
## the fall, and nothing of the Ultimate is left to land.
func _hero_falls(kind: String) -> Dictionary:
	var zone := _street(kind, 150.0)
	var id := _press(zone)
	var down := -1
	var after := 0
	var wave_hits := 0
	for tick in 400:
		if down < 0:
			# The hero lives until the Ultimate is on the ground, then is at its mercy.
			zone.hero.hp = 1 if _mine(zone, id) else zone.hero.max_hp
			if _mine(zone, id):
				var ours := zone.hazards.filter(func(d: Dictionary) -> bool: return d["from"] == id)
				zone.hero.position = (ours[0] as Dictionary)["at"]
		for event in zone.tick(FighterInput.new()):
			if event.type == "hero_down" and down < 0:
				down = tick
			elif down >= 0 and tick > down and event.type in ["hazard_warn", "hazard_hit"]:
				after += 1
			if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				wave_hits += int(event.hit.move_id in BossMechanics.KINDS)
		if down >= 0 and tick > down + 200:
			break
	return {
		"down_at": down,
		"wave_hits": wave_hits,
		"events_after": after,
		"hazards_left": zone.hazards.size(),
		"channel": zone._boss_mechanics.skills.channeling(),
	}


## The boss is beaten by the hero's blows just after its first wave is marked.
func _boss_falls(kind: String) -> Dictionary:
	var zone := _street(kind, 60.0)
	var boss := zone.fighter(zone.boss_id)
	var id := _press(zone)
	var fell := -1
	var after := 0
	var hero_hits := 0
	for tick in 400:
		zone.hero.hp = zone.hero.max_hp
		var input := FighterInput.new()
		if _mine(zone, id) and fell < 0:
			boss.hp = mini(boss.hp, 1)
			boss.grace = 0
			zone.hero.position = boss.position + Vector2(-30.0, 0)
			zone.hero.facing = 1
			input.light = tick % 2 == 0
		for event in zone.tick(input):
			if event.type == "defeat" and int(event.data["id"]) == boss.id:
				fell = tick
			elif fell >= 0 and tick > fell and event.type in ["hazard_warn", "hazard_hit"]:
				after += 1
			elif fell >= 0 and event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				hero_hits += 1
		if fell >= 0 and tick > fell + 200:
			break
	return {
		"fell_at": fell,
		"events_after": after,
		"hits_after": hero_hits,
		"hazards_left": zone.hazards.size(),
		"channel": zone._boss_mechanics.skills.channeling(),
	}


## A hazard called just before the Ultimate lands before its first wave.
func _overlap_before(kind: String) -> Dictionary:
	var zone := _street(kind, 150.0)
	var boss := zone.fighter(zone.boss_id)
	var earlier := {
		"kind": "steam", "warn": 70, "damage": 10, "half": [36, 14], "count": 3, "spread": [200, 40]
	}
	zone._boss_mechanics.call_hazard(zone, boss, earlier, [])
	var id := _press(zone)
	var last_earlier := -1
	var first_wave := -1
	for tick in 400:
		zone.hero.hp = zone.hero.max_hp
		zone.tick(FighterInput.new())
		var others := zone.hazards.filter(func(d: Dictionary) -> bool: return d["from"] != id)
		if not others.is_empty():
			last_earlier = tick
		if _mine(zone, id) and first_wave < 0:
			first_wave = tick
		if first_wave >= 0 and tick > first_wave + 5:
			break
	return {"earlier_last": last_earlier, "first_wave": first_wave}


## A world boss's hour runs out mid-Ultimate (WorldBossRun): it escapes, and
## nothing of the Ultimate lands after.
func _escape_mid_ultimate(kind: String) -> Dictionary:
	var world := _world_boss(kind)
	var profile := PlayerProfile.new_game(content, OS.get_environment("HERO"))
	profile.level = _level(kind)
	var zone := _street(kind, 150.0, profile)
	var run := WorldBossRun.new(zone, profile, content, world, 0, 0)
	var id := _press(zone)
	var escaped := -1
	var after := 0
	var hits_after := 0
	for tick in 900:
		zone.hero.hp = zone.hero.max_hp
		if _mine(zone, id) and escaped < 0 and not run.escaping:
			run.ticks_left = 1
		var events := zone.tick(FighterInput.new())
		run.tick(zone, events)
		if run.escaping and escaped < 0:
			escaped = tick
			continue
		for event in events:
			if escaped >= 0 and event.type in ["hazard_warn", "hazard_hit"]:
				after += 1
			if escaped >= 0 and event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				hits_after += 1
		if run.ended:
			break
	return {
		"escaped_at": escaped,
		"ended": run.ended,
		"events_after": after,
		"hits_after": hits_after,
		"hazards_left": zone.hazards.size(),
	}
