extends TestCase
## Every boss's and mini-boss's own skills (BossSkillRules, BossSkills,
## EnemyBrain): the catalogue covers the whole roster with unique ids, each
## skill runs in a fight (its blow lands, its hazard or helpers arrive), the AI
## uses them, cooldowns hold, a fallen or departed boss leaves nothing behind,
## and the damage is a boss's, yet fair: telegraphed, dodgeable, never most
## of a hero's health at the boss's level.

const ARENA := "saltmarket"
const HERO_X := 160.0
const ROAD_Y := 300.0
## A skill's hit may take this long after it is pressed (wind-up, a combo's
## later blows, a hazard's warning, a volley's stagger).
const RUN_TICKS := 360
## At most this share of a hero's health in one skill, at the boss's level with
## the shop's gear: a boss hurts, but nothing short of a mistake ends a fight.
const MAX_SHARE := 0.45
const ADVANCED := ["combo3", "volley", "summon", "quake", "chain"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _bosses() -> Array[String]:
	var out: Array[String] = []
	for kind: String in _content().enemies:
		if _content().enemy(kind).get("boss", false):
			out.append(kind)
	return out


## The level boss `kind` fights at: its world boss round's, else its area's
## plus the boss bonus.
func _level(kind: String) -> int:
	for boss: String in _content().world_bosses:
		if str(_content().world_bosses[boss]["enemy"]) == kind:
			return WorldBossRules.level(_content(), boss)
	return int(_content().boss_skills["bosses"][kind]["level"]) + LevelRules.BOSS_BONUS


## A street with the hero standing still and `kind` spawned ahead of them,
## its skills armed (one tick run).
func _fight(kind: String, gap: float, seed_value := 3) -> ZoneSim:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.level = _level(kind)
	var zone := ZoneSim.new(c, profile, ARENA, "west", seed_value)
	zone.level = _level(kind) - LevelRules.BOSS_BONUS
	zone.hero.position = Vector2(HERO_X, ROAD_Y)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	var boss := zone.spawn_enemy(kind, Vector2(HERO_X + gap, ROAD_Y))
	boss.facing = -1
	zone.tick(FighterInput.new())
	return zone


func _hold(zone: ZoneSim) -> void:
	zone.hero.hp = zone.hero.max_hp
	zone.hero.position = Vector2(HERO_X, ROAD_Y)


## Presses skill `id` for `zone`'s boss and runs it: {"started", "moves" (the
## boss's moves, in order), "damage" to the hero from the skill, "spawned",
## "warned"}.
func _use(zone: ZoneSim, id: String) -> Dictionary:
	var c := _content()
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	var data := BossSkillRules.skill(c, id)
	# Pressed now, whatever wait it opens a fight with (an Ultimate's).
	boss.cooldowns.erase(id)
	brain.planned_skill = id
	brain.cooldown = 0
	brain.skill_wait = 0
	var out := {
		"started": false, "cooling": false, "moves": [], "damage": 0, "spawned": 0, "warned": 0
	}
	var kinds: Array = [str(data.get("hazard", {}).get("kind", ""))]
	for wave: Dictionary in data.get("waves", []):
		kinds.append(str(wave["kind"]))
	for tick in RUN_TICKS:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			match event.type:
				"swing":
					if int(event.data["id"]) == boss.id and str(event.data["skill"]) == id:
						out["started"] = true
						out["cooling"] = boss.cooldown_left(id) > 0
						if BossSkillRules.is_ultimate(data):
							# Its waves land long after: no other blow knocks the
							# standing hero down (and out of reach) meanwhile.
							brain.cooldown = 600
				"hit":
					var hit := event.hit
					var ours: bool = (
						hit.move_id in data["moves"] or (hit.move_id and hit.move_id in kinds)
					)
					if hit.defender_id == ZoneSim.HERO_ID and hit.attacker_id == boss.id and ours:
						out["damage"] += hit.damage
				"hazard_warn":
					out["warned"] += 1
				"boss_summon":
					out["spawned"] += (event.data["ids"] as Array).size()
		var running: bool = zone._boss_mechanics.skills.active() == id
		if running and boss.state == Fighter.State.ATTACK and boss.move.id not in out["moves"]:
			(out["moves"] as Array).append(boss.move.id)
	return out


func test_every_boss_and_mini_boss_has_its_own_skill_set() -> void:
	var c := _content()
	# Every move a hero's skill uses: its blows and its grab's (a passive: none).
	var hero_moves := {}
	for hero_skill: String in c.skills:
		var skill: Dictionary = c.skills[hero_skill]
		for move_id in SkillSequence.moves(skill):
			hero_moves[move_id] = true
		var grab: Variant = skill.get("grab")
		if grab is Dictionary:
			for value: Variant in (grab as Dictionary).values():
				hero_moves[str(value)] = true
	assert_eq(c.errors, PackedStringArray(), "the data validates")
	assert_eq(BossSkillRules.problems(c), PackedStringArray(), "the catalogue validates")
	var tiers := {"mini": 0, "stage": 0, "world": 0}
	var seen := {}
	for kind in _bosses():
		var ids := BossSkillRules.of(c, kind)
		var tier := BossSkillRules.tier(c, kind)
		tiers[tier] += 1
		var band: Array = BossSkillRules.TIERS[tier]
		var plain := ids.filter(
			func(id: String) -> bool:
				return not BossSkillRules.is_ultimate(BossSkillRules.skill(c, id))
		)
		assert_true(plain.size() >= int(band[0]) and plain.size() <= int(band[1]), kind + ": count")
		assert_true(BossSkillRules.ultimate_of(c, kind) != "", kind + ": an Ultimate")
		for id in ids:
			assert_true(not seen.has(id), id + ": one owner")
			seen[id] = kind
			assert_eq(BossSkillRules.skill(c, id)["owner"], kind, id + ": its owner")
			assert_true(not c.skills.has(id), id + ": not a hero's skill id")
			for move_id: String in BossSkillRules.skill(c, id)["moves"]:
				assert_true(not hero_moves.has(move_id), move_id + ": not a hero's")
	assert_eq(seen.size(), (c.boss_skills["skills"] as Dictionary).size(), "no orphan skills")
	for id: String in seen:
		# A boss never stands far off calling skills: it closes in first.
		var span: Array = BossSkillRules.skill(c, id)["range"]
		assert_true(float(span[1]) <= 300.0, id + ": used from near, not from afar")
	# The tier follows the map's own marks: a world boss, a district's last
	# boss, or a boss on the way (a mini-boss, as every lair's rematch).
	for kind in _bosses():
		var want := "stage"
		var area := ""
		for area_id: String in c.areas:
			if MapRules.boss_of(c, area_id) == kind:
				area = area_id
		if MapRules.kind_of(c, area) == MapRules.MINI_BOSS:
			want = "mini"
		if c.area(area).get("world_boss", false):
			want = "world"
		assert_eq(BossSkillRules.tier(c, kind), want, kind + ": tier")
	assert_eq(tiers, {"mini": 10, "stage": 6, "world": 8}, "the whole roster")


func test_the_validator_catches_a_broken_catalogue() -> void:
	for want: String in [
		"has no skills",
		"a hero's skill id",
		"is also",
		"belongs to",
		"winds up at least",
		"a cast is one wind-up",
		"no such effect",
		"no boss lists it",
		"should start",
	]:
		var broken := ContentDB.load_all()
		_break(broken, want)
		var said := "\n".join(BossSkillRules.problems(broken))
		assert_true(want in said, want + ": " + said.left(200))


## Breaks `c`'s boss skills the way the validator should report as `want`.
func _break(c: ContentDB, want: String) -> void:
	var skills: Dictionary = c.boss_skills["skills"]
	var ring: Dictionary = c.boss_skills["bosses"]["ringmaster"]
	match want:
		"has no skills":
			c.boss_skills["bosses"].erase("ringmaster")
		"a hero's skill id":
			skills[c.skills.keys()[0]] = skills["MB_RINGMASTER_001"]
		"is also":
			skills["MB_RINGMASTER_001"]["moves"] = ["bs_sb_big_sak_001"]
		"belongs to":
			skills["MB_RINGMASTER_001"]["owner"] = "big_sak"
		"winds up at least":
			c.moves.get_move("bs_mb_ringmaster_001").startup = 4
		"a cast is one wind-up":
			c.moves.get_move("bs_mb_ringmaster_003").damage = 9
		"no such effect":
			skills["MB_RINGMASTER_001"]["fx"] = "nope"
		"no boss lists it":
			(ring["skills"] as Array).erase("MB_RINGMASTER_003")
		"should start":
			ring["tier"] = "world"


func test_every_skill_runs_and_hurts_in_a_fight() -> void:
	var c := _content()
	for kind in _bosses():
		for id in BossSkillRules.of(c, kind):
			var data := BossSkillRules.skill(c, id)
			var span: Array = data["range"]
			var gap := clampf((float(span[0]) + float(span[1])) / 2.0, 30.0, 160.0)
			if BossSkillRules.is_ultimate(data):
				gap = 40.0  # Close by: an Ultimate's waves start around the boss.
			var zone := _fight(kind, gap)
			var boss := zone.fighter(zone.boss_id)
			assert_true(boss.skills.has(id), id + ": armed")
			var run := _use(zone, id)
			assert_true(run["started"], id + ": pressed and started")
			assert_true(run["cooling"], id + ": cooling down once used")
			if data.has("summon"):
				assert_true(int(run["spawned"]) > 0, id + ": helpers came")
				continue
			if data.has("hazard") or data.has("waves"):
				assert_true(int(run["warned"]) > 0, id + ": warned on the ground first")
			else:
				for move_id: String in data["moves"]:
					assert_true(move_id in run["moves"], "%s: %s played" % [id, move_id])
			assert_true(int(run["damage"]) > 0, id + ": it hurts")


func test_cooldowns_hold_and_one_skill_runs_at_a_time() -> void:
	var c := _content()
	var id := "SB_BIG_SAK_001"
	var zone := _fight("big_sak", 40.0)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	brain.planned_skill = id
	brain.cooldown = 0
	var started := 0
	var cooldown := int(BossSkillRules.skill(c, id)["cooldown"])
	for tick in cooldown - 10:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "swing" and str(event.data["skill"]) == id:
				started += 1
		# It keeps wanting it: only the cooldown stops it.
		if brain.planned_skill == "" and started > 0:
			brain.planned_skill = id
	assert_eq(started, 1, "once, then not again while it cools down")
	# A combo's blows come one after the other, never two at once.
	zone = _fight("big_sak", 40.0)
	var run := _use(zone, "SB_BIG_SAK_003")
	assert_eq(run["moves"], BossSkillRules.skill(c, "SB_BIG_SAK_003")["moves"], "each blow in turn")


func test_a_fallen_boss_leaves_no_hazard_behind() -> void:
	var zone := _fight("founders_engine", 120.0)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	brain.planned_skill = "WB_FOUNDERS_ENGINE_004"
	brain.cooldown = 0
	var warned := false
	var marked := {}
	for tick in 120:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "hazard_warn":
				warned = true
				marked[int(event.data["id"])] = true
		if warned:
			break
	assert_true(warned and not zone.hazards.is_empty(), "the quake is warned")
	var waiting := {}
	for drop: Dictionary in zone.hazards:
		waiting[int(drop["id"])] = true
	boss.hp = 0
	boss.enter(Fighter.State.KO)
	var landed := false
	var called_off := {}
	for tick in 120:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			landed = landed or event.type == "hazard_hit"
			if event.type == "hazard_cancel":
				called_off[int(event.data["id"])] = true
	assert_true(zone.hazards.is_empty(), "its hazards go with it")
	assert_true(not landed, "nothing lands after it falls")
	# Every warning still on the street is called off by its own id, so the
	# view clears it instead of leaving the mark painted on the ground.
	assert_eq(called_off.keys(), waiting.keys(), "each waiting hazard is called off")
	for id: int in called_off:
		assert_true(marked.has(id), "a cancelled hazard is one that was warned")
	assert_true(boss.skills.is_empty() and brain.boss_skills.is_empty(), "no skill left to use")


## The owner's report, checked on every boss: each hazard warned on the street
## ends exactly once, landing (hazard_hit) or called off when the boss falls
## (hazard_cancel), by its own id, so no mark is ever left on the ground.
func test_every_bosss_hazards_each_land_or_are_called_off_once() -> void:
	for kind in _bosses():
		var zone := _fight(kind, 60.0)
		var warned := {}
		var ended := {}
		var twice := 0
		var stray := 0
		var felled := false
		for tick in 1500:
			_hold(zone)
			var boss := zone.fighter(zone.boss_id) if zone.boss_id != 0 else null
			# Fell it once hazards are waiting, so some are called off too.
			if not felled and tick > 600 and boss and not zone.hazards.is_empty():
				boss.hp = 0
				boss.enter(Fighter.State.KO)
				felled = true
			for event in zone.tick(FighterInput.new()):
				var id := int(event.data.get("id", 0))
				if event.type == "hazard_warn":
					warned[id] = true
				elif event.type in ["hazard_hit", "hazard_cancel"]:
					twice += int(ended.has(id))
					stray += int(not warned.has(id))
					ended[id] = true
		var open := 0
		for id: int in warned:
			open += int(not ended.has(id) and not _waiting(zone, id))
		assert_eq(twice, 0, kind + ": no hazard ends twice")
		assert_eq(stray, 0, kind + ": every hazard that ends was warned")
		assert_eq(open, 0, kind + ": every warned hazard lands, is called off or still waits")


func _waiting(zone: ZoneSim, id: int) -> bool:
	return zone.hazards.any(func(drop: Dictionary) -> bool: return int(drop["id"]) == id)


func test_a_world_boss_that_escapes_stops_its_skills() -> void:
	var c := _content()
	var boss_id := "crucible_king"
	var spec: Dictionary = c.world_bosses[boss_id]
	var profile := PlayerProfile.new_game(c)
	profile.level = int(spec["level"])
	var period := int(spec["period_minutes"]) * 60
	var now := 3 * period + int(spec.get("offset_minutes", 0)) * 60 + 30
	var zone := ZoneSim.new(c, profile, str(spec["area"]), "west", 4)
	var run := WorldBossRun.new(zone, profile, c, boss_id, 3, now)
	zone.hero.max_hp = 100000000
	var boss: Fighter = null
	for tick in 600:
		zone.hero.hp = zone.hero.max_hp
		zone.hero.position.x = 220
		run.tick(zone, zone.tick(FighterInput.new()), now)
		boss = zone.fighter(zone.boss_id) if zone.boss_id else boss
		if boss and not zone.hazards.is_empty():
			break
	assert_true(boss != null and not zone.hazards.is_empty(), "hazards on the ground")
	run.ticks_left = 1
	var after := 0
	for tick in 240:
		zone.hero.hp = zone.hero.max_hp
		for event in zone.tick(FighterInput.new()):
			if event.type in ["hazard_hit", "swing"] and run.escaping:
				after += 1
		run.tick(zone, [], now)
	assert_true(run.escaping or run.ended == "time", "the bell rang")
	assert_eq(after, 0, "no hazard and no skill after the bell")
	assert_true(zone.hazards.is_empty(), "nothing left to land")
	assert_true(boss.skills.is_empty(), "its skills are gone with it")


func test_the_ai_uses_its_skills_in_a_real_fight() -> void:
	var c := _content()
	for kind in _bosses():
		var zone := _fight(kind, 90.0, 7)
		var boss := zone.fighter(zone.boss_id)
		var used := {}
		var overlap := false
		for tick in 3600:
			# The hero drifts back and forth so every range comes up.
			zone.hero.hp = zone.hero.max_hp
			zone.hero.position = Vector2(HERO_X + 120.0 * sin(tick / 90.0), ROAD_Y)
			for event in zone.tick(FighterInput.new()):
				if event.type == "swing" and int(event.data["id"]) == boss.id:
					var skill := str(event.data["skill"])
					if skill:
						overlap = overlap or zone._boss_mechanics.skills.active() not in ["", skill]
						used[skill] = int(used.get(skill, 0)) + 1
			if boss.is_ko():
				break
		var phase_free := BossSkillRules.of(c, kind).filter(
			func(id: String) -> bool: return int(BossSkillRules.skill(c, id)["phase"]) == 0
		)
		assert_true(used.size() >= 2, "%s: used %d of its skills (%s)" % [kind, used.size(), used])
		for id: String in used:
			assert_true(id in BossSkillRules.of(c, kind), id + ": its own")
			assert_true(int(BossSkillRules.skill(c, id)["phase"]) <= zone.phase_of(boss.id), id)
		assert_true(used.size() <= BossSkillRules.of(c, kind).size(), kind + ": nothing else")
		assert_true(not phase_free.is_empty(), kind + ": something from the start")
		assert_true(not overlap, kind + ": one skill at a time")


func test_a_phase_skill_waits_for_its_phase() -> void:
	var zone := _fight("founders_engine", 60.0)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	var rng := RandomNumberGenerator.new()
	for i in 200:
		brain.last_skill = ""
		var pick := brain._pick_skill(boss, 60.0, rng)
		if pick:
			var phase := int(BossSkillRules.skill(_content(), pick)["phase"])
			assert_true(phase <= brain.boss_phase, pick + ": not before its phase")


## What a hero's active skill deals on a hit, as the boss generator measures
## it (tools/content/boss_skills.py, hero_damage): its blows, and a grab
## skill's throw, or its squeezes over the hold and its drop. Passives and the
## jobs' gauge-gated ultimates are not measured (0).
static func _hero_damage(c: ContentDB, skill: Dictionary) -> int:
	if str(skill.get("type", "active")) != "active":
		return 0
	var total := 0
	for move_id in SkillSequence.moves(skill):
		total += c.moves.get_move(move_id).damage
	var grab: Variant = skill.get("grab")
	if grab is Dictionary:
		var hold: Dictionary = grab
		if hold.has("squeeze"):
			var squeezes := floori(float(hold["hold"]) / float(hold["every"]))
			total += c.moves.get_move(str(hold["squeeze"])).damage * squeezes
		if hold.has("throw"):
			total += c.moves.get_move(str(hold["throw"])).damage
	return total


func test_a_skill_is_a_bosss_blow_yet_fair() -> void:
	var c := _content()
	var hero_damage: Array = []
	for id: String in c.skills:
		var dealt := _hero_damage(c, c.skills[id])
		if dealt > 0:
			hero_damage.append(dealt)
	hero_damage.sort()
	var median := float(hero_damage[hero_damage.size() / 2])
	for kind in _bosses():
		var level := _level(kind)
		var stats := LevelRules.enemy_stats(c.enemy(kind), level)
		var profile := PlayerProfile.new_game(c)
		profile.level = level
		for item_id in ProgressionHarness.gear(c, level, "shop"):
			profile.add_item(item_id)
			profile.equip(item_id, c)
		var zone := ZoneSim.new(c, profile, ARENA, "west", 1)
		var base_power := float(c.enemy(kind).get("power", 1.0))
		for id in BossSkillRules.of(c, kind):
			var raw := BossSkillRules.damage(c, id)
			if raw == 0:
				continue
			var ultimate := BossSkillRules.is_ultimate(BossSkillRules.skill(c, id))
			# An Ultimate is sized to the boss's basic blow instead (2-3 times it),
			# and hits a whole area (test_boss_ultimates).
			if not ultimate:
				assert_true(raw * base_power >= median, "%s: above a hero's skill (%d)" % [id, raw])
			var dealt := raw * float(stats["power"]) - zone.hero.defense
			var share := dealt / float(zone.hero.max_hp)
			assert_true(share <= MAX_SHARE, "%s: %d%% of a hero's health" % [id, share * 100])
			var data := BossSkillRules.skill(c, id)
			var first := c.moves.get_move(str(data["moves"][0]))
			var floor_ticks := BossSkillRules.MIN_HEAVY_WINDUP
			if not first.knockdown:
				floor_ticks = BossSkillRules.MIN_LIGHT_WINDUP
			if data.has("hazard"):
				floor_ticks += BossSkillRules.MIN_WARN
			assert_true(BossSkillRules.telegraph(c, id) >= floor_ticks, id + ": telegraphed")


func test_effects_and_telegraphs_match_where_a_skill_hits() -> void:
	var c := _content()
	for id: String in c.boss_skills["skills"]:
		var data := BossSkillRules.skill(c, id)
		if data.has("hazard"):
			var half: Array = data["hazard"]["half"]
			var view := HazardView.new()
			view.setup(0.5, str(data["hazard"]["kind"]), Vector2(half[0], half[1]))
			assert_eq(view.half, Vector2(half[0], half[1]), id + ": warned at its true size")
			view.free()
			continue
		if data.has("summon") or data.has("waves"):
			continue
		var move := c.moves.get_move(str(data["moves"][0]))
		var effect := str(data["fx"])
		var size := GameFeedback.fit(c, effect, GameFeedback.hit_width(move))
		var drawn := float(c.fx["effects"][effect]["size"][0]) * size
		var reach := GameFeedback.hit_width(move)
		var clamped := size in [GameFeedback.MIN_FIT, GameFeedback.MAX_FIT]
		assert_true(clamped or absf(drawn - reach) < 1.0, "%s: %d px for %d" % [id, drawn, reach])
		assert_true(move.anim in MoveLibrary.ANIMS, id + ": a real animation")


func test_higher_bands_bring_new_mechanics_not_just_numbers() -> void:
	var c := _content()
	var by_band := {}
	for kind in _bosses():
		var band := mini(6, (int(c.boss_skills["bosses"][kind]["level"]) - 1) / 10)
		var types := {}
		var windups: Array = []
		for id in BossSkillRules.of(c, kind):
			var data := BossSkillRules.skill(c, id)
			types[str(data["type"])] = true
			windups.append(c.moves.get_move(str(data["moves"][0])).startup)
		if not by_band.has(band):
			by_band[band] = {"advanced": 0, "bosses": 0, "kinds": {}, "windup": 999}
		var row: Dictionary = by_band[band]
		row["bosses"] += 1
		row["kinds"].merge(types)
		row["windup"] = mini(int(row["windup"]), windups.min())
		for type: String in types:
			if type in ADVANCED:
				row["advanced"] += 1
	assert_eq(by_band.keys().size(), 7, "every band of ten levels has bosses")
	for band in [0, 1, 2]:
		assert_eq(by_band[band]["advanced"], 0, "band %d: readable patterns only" % band)
	for band in [4, 5, 6]:
		var row: Dictionary = by_band[band]
		assert_true(row["advanced"] >= row["bosses"], "band %d: demanding mechanics" % band)
	var kinds_low: int = (by_band[0]["kinds"] as Dictionary).size()
	var kinds_high: int = (by_band[6]["kinds"] as Dictionary).size()
	assert_true(kinds_high > kinds_low, "more kinds of skill late (%d)" % kinds_high)
	for band in by_band:
		assert_true(int(by_band[band]["windup"]) >= BossSkillRules.MIN_LIGHT_WINDUP, "fair")


func test_a_shield_drops_the_rest_of_a_combo() -> void:
	# Behind its shield a boss is untouchable and stands back: a combo it had
	# started must not keep swinging (the audit's finding).
	var zone := _fight("subject_zero", 30.0)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	brain.planned_skill = "WB_SUBJECT_ZERO_001"
	brain.cooldown = 0
	var follow: Array = BossSkillRules.skill(_content(), "WB_SUBJECT_ZERO_001")["moves"].slice(1)
	var shielded := 0
	var started := false
	for tick in 200:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "swing" and str(event.data["skill"]) == "WB_SUBJECT_ZERO_001":
				started = true
				boss.hp = int(boss.max_hp * 0.3)
			if event.type == "hit" and event.hit.move_id in follow:
				shielded += int(zone._boss_mechanics.shield_up())
	assert_true(started and zone._boss_mechanics.shield_up(), "the shield went up mid-combo")
	assert_eq(shielded, 0, "no follow-up blow from behind the shield")
	assert_eq(zone._boss_mechanics.skills.active(), "", "the combo is over")


func test_a_fallen_hero_ends_the_bosss_skills() -> void:
	var zone := _fight("founders_engine", 120.0)
	var boss := zone.fighter(zone.boss_id)
	var brain: EnemyBrain = zone.brains[boss.id]
	brain.planned_skill = "WB_FOUNDERS_ENGINE_004"
	brain.cooldown = 0
	for tick in 120:
		_hold(zone)
		zone.tick(FighterInput.new())
		if not zone.hazards.is_empty():
			break
	assert_true(not zone.hazards.is_empty(), "a quake is warned")
	zone.hero.hp = 0
	zone.hero.enter(Fighter.State.KO)
	zone.tick(FighterInput.new())
	assert_true(zone.hazards.is_empty(), "nothing left to land")
	assert_true(boss.skills.is_empty() and brain.boss_skills.is_empty(), "no skill left to use")


func test_a_solid_prop_stops_a_charge_and_a_leap() -> void:
	for id in ["SB_BIG_SAK_002", "SB_BIG_SAK_005"]:
		var zone := _fight("big_sak", 150.0)
		var boss := zone.fighter(zone.boss_id)
		var wall := HERO_X + 70.0
		zone.solids.append(
			{"position": Vector2(wall, ROAD_Y), "half": Vector2(6, 60), "kind": "test"}
		)
		var brain: EnemyBrain = zone.brains[boss.id]
		var start := boss.position.x
		var run := _use(zone, id)
		assert_true(run["started"], id + ": used")
		assert_true(boss.position.x > wall, "%s: stopped at the prop (%d)" % [id, boss.position.x])
		assert_true(boss.position.x < start, id + ": it did set off")
		assert_eq(int(run["damage"]), 0, id + ": the hero behind the prop is safe")
		assert_true(brain != null, "armed")
