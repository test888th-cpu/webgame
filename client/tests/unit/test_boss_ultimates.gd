extends TestCase
## Every boss's Ultimate (BossSkillRules.ULTIMATES; the owner's rule): one
## each, its own id, cast and look, waves of hazards over a wide area that hit
## every target in them once a wave, sized to the boss's basic blow, more
## elaborate later in the game, dangerous to a hero who stands in it, and
## always escapable by one who reacts.

const ARENA := "saltmarket"
const HERO_X := 300.0
const ROAD_Y := 300.0
const REACTION := 15
## A hero's walk, in px per tick, along the street and across it.
const WALK := Vector2(2.0, 1.16)
## How far clear of a tile's edge a hero keeps.
const EDGE := 6.0
## Ticks a reacting hero is clear of a wave before it lands, at the least.
const MIN_SPARE := 12
## Ways players move: mostly along the street (a few lanes), or using the
## whole depth in steps of 12 or 4 px. An escape counts if any works.
const STYLES := [
	[-40.0, -20.0, 0.0, 20.0, 40.0],
	[-60.0, -48.0, -36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0, 48.0, 60.0],
	[
		-60.0,
		-56.0,
		-52.0,
		-48.0,
		-44.0,
		-40.0,
		-36.0,
		-32.0,
		-28.0,
		-24.0,
		-20.0,
		-16.0,
		-12.0,
		-8.0,
		-4.0,
		0.0,
		4.0,
		8.0,
		12.0,
		16.0,
		20.0,
		24.0,
		28.0,
		32.0,
		36.0,
		40.0,
		44.0,
		48.0,
		52.0,
		56.0,
		60.0
	],
]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _bosses() -> Array[String]:
	var out: Array[String] = []
	for kind: String in _content().boss_skills["bosses"]:
		out.append(kind)
	return out


func _level(kind: String) -> int:
	for boss: String in _content().world_bosses:
		if str(_content().world_bosses[boss]["enemy"]) == kind:
			return WorldBossRules.level(_content(), boss)
	return int(_content().boss_skills["bosses"][kind]["level"]) + LevelRules.BOSS_BONUS


func _band(kind: String) -> int:
	return mini(6, (int(_content().boss_skills["bosses"][kind]["level"]) - 1) / 10)


## A street, the hero `gap` px from boss `kind`, its Ultimate pressed.
func _fight(kind: String, gap: float) -> ZoneSim:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = _level(kind)
	var zone := ZoneSim.new(c, profile, ARENA, "west", 5)
	zone.level = _level(kind) - LevelRules.BOSS_BONUS
	zone.hero.position = Vector2(HERO_X, ROAD_Y)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	var boss := zone.spawn_enemy(kind, Vector2(HERO_X + gap, ROAD_Y))
	boss.facing = -1
	zone.tick(FighterInput.new())
	var brain: EnemyBrain = zone.brains[boss.id]
	var id := BossSkillRules.ultimate_of(c, kind)
	boss.cooldowns.erase(id)
	brain.planned_skill = id
	brain.cooldown = 0
	brain.skill_wait = 0
	return zone


## Runs `zone` until the boss's Ultimate marks its first wave; returns its id
## ("" if it never did).
func _cast(zone: ZoneSim) -> String:
	var id := BossSkillRules.ultimate_of(_content(), zone.fighter(zone.boss_id).kind)
	for tick in 120:
		zone.hero.hp = zone.hero.max_hp
		zone.tick(FighterInput.new())
		for drop: Dictionary in zone.hazards:
			if drop["from"] == id:
				return id
	return ""


## Leaves only the Ultimate's own drops waiting (the boss's other hazards and
## skills are other tests' business).
func _keep(zone: ZoneSim, id: String) -> void:
	for i in range(zone.hazards.size() - 1, -1, -1):
		if zone.hazards[i]["from"] != id:
			zone.hazards.remove_at(i)


func _covers(at: Vector2, drops: Array, margin := 0.0) -> bool:
	for drop: Dictionary in drops:
		var gap: Vector2 = (at - drop["at"]).abs()
		var half: Vector2 = drop["half"]
		if gap.x <= half.x + margin and gap.y <= half.y + margin:
			return true
	return false


## Where a hero heads: clear of the next wave to land and reachable before
## it, clear of the wave after if it can be, nearest first; trying the steps
## across the street in `lanes` (px).
func _plan(zone: ZoneSim, lanes: Array) -> Vector2:
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
			# Nobody stands inside the boss.
			var body := (at - boss.position).abs()
			if body.x < Bodies.PERSON.x * 2.0 + 2.0 and body.y < Bodies.PERSON.y * 2.0 + 2.0:
				continue
			var ticks := maxf(absf(dx) / WALK.x, absf(dy) / WALK.y)
			# A step clear of a tile's edge, as a player keeps.
			if ticks > first - 1 or _covers(at, now, EDGE):
				continue
			var score := ticks + (1000.0 if _covers(at, later, EDGE) else 0.0)
			if score < best_score:
				best = at
				best_score = score
	return best


func test_every_boss_has_one_ultimate_of_its_own() -> void:
	var c := _content()
	var looks := {}
	for kind in _bosses():
		var id := BossSkillRules.ultimate_of(c, kind)
		assert_true(id != "", kind + ": an Ultimate")
		var ults := BossSkillRules.of(c, kind).filter(
			func(other: String) -> bool:
				return BossSkillRules.is_ultimate(BossSkillRules.skill(c, other))
		)
		assert_eq(ults.size(), 1, kind + ": exactly one")
		var data := BossSkillRules.skill(c, id)
		assert_eq(data["owner"], kind, id + ": its owner's alone")
		assert_true(id.contains("_ULT_"), id + ": named an Ultimate")
		var cast := c.moves.get_move(str(data["moves"][0]))
		assert_true(cast.anim not in ["light", "heavy"], id + ": its own animation")
		assert_true(int(data["cooldown"]) >= BossSkillRules.ULT_MIN_COOLDOWN, id + ": rare")
		assert_true(int(data.get("opening", 0)) > 0, id + ": not at the very start")
		for other in BossSkillRules.of(c, kind):
			if other != id:
				var mine := BossSkillRules.skill(c, other)
				assert_true(mine["sound"] != data["sound"], id + ": its own sound")
				assert_true(mine["fx"] != data["fx"], id + ": its own effect")
				assert_true(
					int(mine["cooldown"]) < int(data["cooldown"]), id + ": the longest wait"
				)
		var light := float(c.moves.get_move(str(c.enemy(kind)["moveset"]["light"])).damage)
		for wave: Dictionary in data["waves"]:
			var share := float(wave["damage"]) / light
			assert_true(
				share >= 2.0 and share <= 3.0, "%s: %.1f times its basic blow" % [id, share]
			)
		var look := JSON.stringify((data["waves"] as Array).map(_wave_look))
		assert_true(not looks.has(look), "%s: unlike %s's" % [id, looks.get(look, "")])
		looks[look] = kind


## What a wave looks like: its tiles' layout, size and kind.
static func _wave_look(w: Dictionary) -> Array:
	return [w.get("offsets", []), w.get("count", 0), w["half"], w["kind"]]


func test_later_ultimates_are_more_elaborate() -> void:
	var c := _content()
	var waves_by_band := {}
	for kind in _bosses():
		var waves: Array = BossSkillRules.skill(c, BossSkillRules.ultimate_of(c, kind))["waves"]
		var band := _band(kind)
		waves_by_band[band] = waves_by_band.get(band, []) + [waves.size()]
		var gaps := waves.filter(
			func(w: Dictionary) -> bool: return (w.get("offsets", []) as Array).size() >= 8
		)
		if band <= 1:
			assert_true(waves.size() <= 2, kind + ": one or two simple waves early")
			assert_eq(gaps.size(), 0, kind + ": no safe-gap lines early")
		if band >= 4:
			assert_true(waves.size() >= 3, kind + ": three or more waves late")
	var last := 0.0
	for band in range(7):
		var sizes: Array = waves_by_band[band]
		var mean := float(sizes.reduce(func(a: int, b: int) -> int: return a + b, 0)) / sizes.size()
		assert_true(
			mean >= last, "band %d: no fewer waves than the band before (%.1f)" % [band, mean]
		)
		last = mean


func test_an_ultimate_hits_every_target_in_its_area_once_a_wave() -> void:
	# Stand-ins for a crowd (a world boss is for groups): fighters on the
	# hero's side, held in place. Each is hit once by every wave that covers it,
	# never twice by one wave, never by a wave that misses it.
	for kind in _bosses():
		var zone := _fight(kind, 100.0)
		var boss := zone.fighter(zone.boss_id)
		var brain: EnemyBrain = zone.brains[boss.id]
		var crowd: Array[Fighter] = []
		var spots := {}
		for i in 9:
			var at := Vector2(boss.position.x - 260.0 + i * 60.0, ROAD_Y + (i % 3 - 1) * 24.0)
			var stand_in := Fighter.new(9000 + i, ZoneSim.HERO_TEAM, at, 100000000)
			zone.fighters.append(stand_in)
			crowd.append(stand_in)
			spots[stand_in.id] = at
		var start := boss.position
		var id := _cast(zone)
		assert_true(id != "", kind + ": the Ultimate is cast")
		# Each wave as it is marked: who it covers.
		var seen := {}
		var expected := {}
		var hits := {}
		for tick in 500:
			zone.hero.hp = zone.hero.max_hp
			_keep(zone, id)
			for drop: Dictionary in zone.hazards:
				var wave := int(drop["wave"])
				for target in crowd:
					if _covers(spots[target.id], [drop]) and not seen.has([wave, target.id]):
						seen[[wave, target.id]] = true
						expected[target.id] = int(expected.get(target.id, 0)) + 1
			# Back on its feet each tick: this counts hits per wave; being knocked
			# down (and so missed by the next wave) is the combat rules' business.
			for target in crowd:
				target.position = spots[target.id]
				target.hp = target.max_hp
				target.knockback_remaining = 0.0
				target.grace = 0
				if target.state != Fighter.State.IDLE:
					target.enter(Fighter.State.IDLE)
			brain.cooldown = 60
			boss.position = start
			for event in zone.tick(FighterInput.new()):
				var hazard: bool = event.hit != null and event.hit.move_id in BossMechanics.KINDS
				if event.type == "hit" and event.hit.defender_id >= 9000 and hazard:
					hits[event.hit.defender_id] = int(hits.get(event.hit.defender_id, 0)) + 1
			if zone.hazards.is_empty() and tick > 200:
				break
		var caught := 0
		for target in crowd:
			assert_eq(
				int(hits.get(target.id, 0)),
				int(expected.get(target.id, 0)),
				"%s: stand-in %d, once per wave over it" % [kind, target.id]
			)
			caught += int(int(expected.get(target.id, 0)) > 0)
		assert_true(caught >= 2, "%s: many targets at once (%d)" % [kind, caught])


func test_a_hero_who_reacts_can_always_escape_an_ultimate() -> void:
	# From near, middle and far, in the near, middle and far lane: a hero who
	# reacts a quarter of a second after each wave is marked, and plans the
	# next step, is never hit. The spare ticks (between leaving a wave's tiles
	# and its landing) are printed for the audit.
	for kind in _bosses():
		var spare := 9999
		for gap in [50.0, 150.0, 250.0]:
			for lane in [-30.0, 0.0, 30.0]:
				var best := [9999, -1]
				for style: Array in STYLES:
					var run := _escape(kind, gap, lane, style)
					if run[0] < best[0] or (run[0] == best[0] and run[1] > best[1]):
						best = run
				assert_eq(
					best[0], 0, "%s from %d px, lane %+d: escaped every wave" % [kind, gap, lane]
				)
				spare = mini(spare, best[1])
		print("ULT_SPARE %s %d" % [kind, spare])
		# Out of every wave with time to spare: a fifth of a second on top of the
		# quarter-second reaction already allowed.
		assert_true(spare >= MIN_SPARE, "%s: %d ticks to spare" % [kind, spare])


## One escape: [damage taken, fewest spare ticks before a wave landed].
func _escape(kind: String, gap: float, lane: float, style: Array) -> Array:
	var zone := _fight(kind, gap)
	zone.hero.position.y = ROAD_Y + lane
	var id := _cast(zone)
	assert_true(id != "", "%s: cast, its waves on the ground" % kind)
	var since := 0
	var taken := 0
	var spare := 9999
	# Per wave id: the last tick the hero stood in one of its tiles.
	var last_in := {}
	for tick in 600:
		zone.hero.hp = zone.hero.max_hp
		_keep(zone, id)
		# The Ultimate alone: helpers on the boss's own timer could pin the
		# hero (the audit's risk R-2), which is not this test's question.
		for enemy in zone.enemies():
			if enemy.id != zone.boss_id:
				zone.fighters.erase(enemy)
		if zone.hazards.is_empty() and tick > 260:
			break
		since += 1
		var input := FighterInput.new()
		if since >= REACTION:
			var to := _plan(zone, style) - zone.hero.position
			input.move = Vector2(
				signf(to.x) if absf(to.x) > 1.0 else 0.0, signf(to.y) if absf(to.y) > 1.0 else 0.0
			)
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
			var still := zone.hazards.any(
				func(d: Dictionary) -> bool: return int(d["wave"]) == wave
			)
			if not still:
				spare = mini(spare, tick - int(last_in[wave]))
	return [taken, spare]


func test_an_ultimate_is_dangerous_but_never_a_one_shot() -> void:
	var c := _content()
	for kind in _bosses():
		var id := BossSkillRules.ultimate_of(c, kind)
		var data := BossSkillRules.skill(c, id)
		var power := float(LevelRules.enemy_stats(c.enemy(kind), _level(kind))["power"])
		for kit in ["starter", "shop"]:
			var profile := PlayerProfile.new_game(c)
			profile.level = _level(kind)
			for item_id in ProgressionHarness.gear(c, _level(kind), kit):
				profile.add_item(item_id)
				profile.equip(item_id, c)
			var zone := ZoneSim.new(c, profile, ARENA, "west", 1)
			var hp := float(zone.hero.max_hp)
			var total := 0.0
			var worst := 0.0
			for wave: Dictionary in data["waves"]:
				var hit := maxf(1.0, roundf(float(wave["damage"]) * power) - zone.hero.defense)
				total += hit
				worst = maxf(worst, hit)
			# No single wave takes most of a hero: one mistake is survivable (a
			# starter kit at the boss's level is a poor kit, so a little more).
			var most := 0.5 if kit == "shop" else 0.6
			assert_true(worst / hp < most, "%s, %s: one wave %d%%" % [id, kit, worst / hp * 100])
			if kit == "starter" and data["waves"].size() >= 2:
				# Standing in all of it, badly geared, a hero is in real trouble.
				assert_true(total / hp >= 0.4, "%s: all waves %d%%" % [id, total / hp * 100])


func test_the_ai_uses_its_ultimate_after_its_opening() -> void:
	var c := _content()
	for kind in _bosses():
		var id := BossSkillRules.ultimate_of(c, kind)
		var opening := int(BossSkillRules.skill(c, id)["opening"])
		var profile := PlayerProfile.new_game(c)
		profile.level = _level(kind)
		var zone := ZoneSim.new(c, profile, ARENA, "west", 9)
		zone.level = _level(kind) - LevelRules.BOSS_BONUS
		zone.hero.max_hp = 100000000
		var boss := zone.spawn_enemy(kind, Vector2(HERO_X + 120.0, ROAD_Y))
		var first := -1
		for tick in 2400:
			zone.hero.hp = zone.hero.max_hp
			zone.hero.position = Vector2(HERO_X + 60.0 * sin(tick / 80.0), ROAD_Y)
			for event in zone.tick(FighterInput.new()):
				if event.type == "swing" and str(event.data["skill"]) == id and first < 0:
					first = tick
			if first >= 0 or boss.is_ko():
				break
		assert_true(first >= opening, "%s: not before its opening (%d)" % [kind, first])


func test_overlapping_tiles_of_one_wave_hit_once() -> void:
	# A wave whose tiles overlap (at an arena's edge, or a crowd's) never hits a
	# fighter twice: one wave, one hit (BossMechanics._land_hazards).
	var zone := _fight("founders_engine", 200.0)
	var boss := zone.fighter(zone.boss_id)
	var spot := zone.hero.position
	var wave := {
		"kind": "quake",
		"warn": 1,
		"damage": 10,
		"half": [30, 46],
		"origin": "hero",
		"offsets": [[0, 0], [12, 0], [-12, 0]],
	}
	zone._boss_mechanics.call_hazard(zone, boss, wave, [])
	var hits := 0
	# Guarding, the hero stays on their feet (a knock-down would hide a double
	# hit: a downed fighter cannot be hit again).
	var guard := FighterInput.new()
	guard.guard = true
	for tick in 3:
		zone.hero.position = spot
		for event in zone.tick(guard):
			if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
				hits += int(event.hit.move_id == "quake")
	assert_eq(hits, 1, "three overlapping tiles, one hit")


func test_nothing_else_lands_while_an_ultimate_is_channelled() -> void:
	# The boss stands still and strikes nothing; its own hazard cycle and its
	# helpers wait: the Ultimate's waves are the only danger, so their safe
	# ground stays safe (no overlap that could not be escaped).
	for kind in _bosses():
		var zone := _fight(kind, 150.0)
		var boss := zone.fighter(zone.boss_id)
		var id := _cast(zone)
		assert_true(id != "", kind + ": cast")
		var mechanics: BossMechanics = zone._boss_mechanics
		var start := boss.position
		var others := 0
		var swings := 0
		var summoned := 0
		while mechanics.skills.channeling():
			zone.hero.hp = zone.hero.max_hp
			for event in zone.tick(FighterInput.new()):
				swings += int(event.type == "swing" and int(event.data["id"]) == boss.id)
				summoned += int(event.type == "boss_summon")
			for drop: Dictionary in zone.hazards:
				others += int(drop["from"] != id)
		assert_eq(others, 0, kind + ": only the Ultimate's waves on the ground")
		assert_eq(swings, 0, kind + ": no blow while channelling")
		assert_eq(summoned, 0, kind + ": no helpers called meanwhile")
		assert_eq(boss.position, start, kind + ": it stands its ground")


func test_a_fallen_boss_marks_no_more_waves() -> void:
	var zone := _fight("founders_engine", 150.0)
	var boss := zone.fighter(zone.boss_id)
	var id := _cast(zone)
	assert_true(id != "" and zone._boss_mechanics.skills.channeling(), "the Ultimate is under way")
	boss.hp = 0
	boss.enter(Fighter.State.KO)
	var marked := 0
	var landed := 0
	for tick in 300:
		zone.hero.hp = zone.hero.max_hp
		for event in zone.tick(FighterInput.new()):
			marked += int(event.type == "hazard_warn")
			landed += int(event.type == "hazard_hit")
	assert_eq(marked, 0, "no wave marked after it falls")
	assert_eq(landed, 0, "and none lands")
	assert_true(not zone._boss_mechanics.skills.channeling(), "the channel ends with it")


func test_hazards_waiting_at_the_cast_land_before_the_first_wave() -> void:
	# A hazard the boss called before its Ultimate (a regular skill's, its own
	# cycle's) keeps its mechanics: it lands where and when it was warned. The
	# Ultimate's first wave is marked only after, so nothing of it can land in
	# the Ultimate's safe ground.
	for kind in _bosses():
		var zone := _fight(kind, 150.0)
		var boss := zone.fighter(zone.boss_id)
		var mechanics: BossMechanics = zone._boss_mechanics
		var earlier := {
			"kind": "steam",
			"warn": 70,
			"damage": 10,
			"half": [36, 14],
			"count": 3,
			"spread": [200, 40]
		}
		mechanics.call_hazard(zone, boss, earlier, [])
		var id := BossSkillRules.ultimate_of(_content(), kind)
		var last_earlier := -1
		var first_wave := -1
		for tick in 400:
			zone.hero.hp = zone.hero.max_hp
			zone.tick(FighterInput.new())
			var mine := 0
			var others := 0
			for drop: Dictionary in zone.hazards:
				if drop["from"] == id:
					mine += 1
				else:
					others += 1
			if others > 0:
				last_earlier = tick
			if mine > 0 and first_wave < 0:
				first_wave = tick
			if first_wave >= 0 and tick > first_wave + 5:
				break
		assert_true(first_wave >= 0, kind + ": the Ultimate came")
		assert_true(
			first_wave > last_earlier, "%s: its first wave after the earlier hazards landed" % kind
		)


func test_each_wave_is_announced_and_lands_on_its_tick() -> void:
	# Every wave is marked on the ground (hazard_warn, HazardView) and lands
	# exactly its warning later: the timing is in simulation ticks, the same
	# at any frame rate (the scene steps the sim at a fixed 60 ticks a second).
	for kind in _bosses():
		var zone := _fight(kind, 150.0)
		var id := BossSkillRules.ultimate_of(_content(), kind)
		var data := BossSkillRules.skill(_content(), id)
		var marked := {}
		var warns := 0
		var late := 0
		for tick in 600:
			zone.hero.hp = zone.hero.max_hp
			zone.hero.grace = 9999
			for event in zone.tick(FighterInput.new()):
				warns += int(event.type == "hazard_warn")
			for drop: Dictionary in zone.hazards:
				if drop["from"] != id or marked.has(int(drop["wave"])):
					continue
				marked[int(drop["wave"])] = tick + int(drop["ticks"])
			for wave: int in marked.keys():
				var waiting := zone.hazards.any(
					func(d: Dictionary) -> bool: return int(d["wave"]) == wave
				)
				if not waiting and int(marked[wave]) >= 0:
					# Landed this tick: on time (a staggered tile, a few ticks after).
					late = maxi(late, absi(tick - int(marked[wave])))
					marked[wave] = -1
			if (
				marked.size() == (data["waves"] as Array).size()
				and marked.values().all(func(t: int) -> bool: return t < 0)
			):
				break
		assert_eq(marked.size(), (data["waves"] as Array).size(), kind + ": every wave marked")
		assert_true(warns >= marked.size(), kind + ": every wave announced")
		assert_true(late <= 40, "%s: each wave lands on its warning (%d)" % [kind, late])


func test_gear_decides_how_much_a_late_ultimate_wave_hurts() -> void:
	# The two strongest Ultimates, against four kits at the boss's level: one
	# wave is never most of a geared hero; all of them, ignored, overwhelm a
	# poorly kitted one. Printed for the audit.
	var c := _content()
	var kits := {"S0": ["starter", 0], "B0": ["shop", 0], "B5": ["shop", 5], "D10": ["boss", 10]}
	for kind in ["crucible_king", "founders_engine"]:
		var data := BossSkillRules.skill(c, BossSkillRules.ultimate_of(c, kind))
		var power := float(LevelRules.enemy_stats(c.enemy(kind), _level(kind))["power"])
		for kit: String in kits:
			var profile := PlayerProfile.new_game(c)
			profile.level = _level(kind)
			for item_id in ProgressionHarness.gear(c, _level(kind), str(kits[kit][0])):
				profile.add_item(item_id)
				profile.equip(item_id, c)
				profile.enhance[profile.own_copy(str(c.item(item_id)["slot"]))] = int(kits[kit][1])
			var zone := ZoneSim.new(c, profile, ARENA, "west", 1)
			var hp := float(zone.hero.max_hp)
			var wave := float(data["waves"][0]["damage"])
			var hit := maxf(1.0, roundf(wave * power) - zone.hero.defense)
			var all := hit * (data["waves"] as Array).size()
			print(
				(
					"ULT_GEAR %s %s hp %d wave %d%% all %d%%"
					% [kind, kit, hp, hit / hp * 100, all / hp * 100]
				)
			)
			assert_true(hit / hp < (0.6 if kit == "S0" else 0.5), "%s, %s: one wave" % [kind, kit])
			if kit == "S0":
				assert_true(all / hp > 1.0, kind + ": all of it, ignored, overwhelms a starter kit")
