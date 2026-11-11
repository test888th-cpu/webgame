extends SceneTree
## Five jobs against the 24 bosses (docs/BOSS_SKILL_QUALITY_AUDIT.md): each
## hero (one job each, heroes.json) fights each boss under auto battle
## (AutoPilot presses the same inputs a player does), at the boss's level with
## a kit of gear, no food, on a cleared street. SCRIPTED SIMULATION: it
## compares the jobs under one pilot; it says nothing about how people play.
## Read-only.
##
##   godot --headless --path client --script res://tests/harness/BossJobMatrix.gd
##   (BOSSES=a,b  HEROES=riku,oren  SEEDS=3  KIT=shop|starter|boss  PLUS=0..10)
##
## Prints one "FIGHT " JSON line per boss, hero and seed:
## * won / ko / seconds, and the hero's damage taken (% of health a minute);
## * where it came from: boss "basic" blows, boss "skill" blows, "ultimate"
##   waves, other "hazard" drops, and "helper" monsters;
## * "downs": times knocked down; "stun": the longest stretch the hero could
##   not act (hitstun, down, held) in ticks; "skills": boss skills used a
##   minute;
## * the job's answers: hero skills used, "countered" boss blows caught by a
##   counter stance, and "held_boss" ticks a boss spent in a hold (bosses
##   cannot be held: always 0).

const ARENA := "saltmarket"
const HERO_X := 260.0
const ROAD_Y := 300.0
const LIMIT := 10800

var content: ContentDB


func _init() -> void:
	content = ContentDB.load_all()
	var only := _list("BOSSES")
	var heroes := _list("HEROES")
	if heroes.is_empty():
		for hero_id: String in content.heroes:
			heroes.append(hero_id)
	var seeds := int(OS.get_environment("SEEDS")) if OS.get_environment("SEEDS") else 3
	var kit := OS.get_environment("KIT") if OS.get_environment("KIT") else "shop"
	var plus := int(OS.get_environment("PLUS")) if OS.get_environment("PLUS") else 0
	for kind: String in content.boss_skills["bosses"]:
		if not only.is_empty() and kind not in only:
			continue
		for hero_id in heroes:
			for seed in range(1, seeds + 1):
				print("FIGHT " + JSON.stringify(_fight(kind, hero_id, seed, kit, plus)))
	quit()


func _list(key: String) -> Array[String]:
	var out: Array[String] = []
	for part in OS.get_environment(key).split(",", false):
		out.append(part)
	return out


func _level(kind: String) -> int:
	for boss: String in content.world_bosses:
		if str(content.world_bosses[boss]["enemy"]) == kind:
			return WorldBossRules.level(content, boss)
	return int(content.boss_skills["bosses"][kind]["level"]) + LevelRules.BOSS_BONUS


func _fight(kind: String, hero_id: String, seed: int, kit: String, plus: int) -> Dictionary:
	var level := _level(kind)
	var profile := PlayerProfile.new_game(content, hero_id)
	profile.level = level
	for item_id in ProgressionHarness.gear(content, level, kit):
		profile.add_item(item_id)
		profile.equip(item_id, content)
		profile.enhance[profile.own_copy(str(content.item(item_id)["slot"]))] = plus
	# FOOD=n: that many of each food (the owner's rule: food is unlimited in
	# play; none by default, to measure the boss's pressure itself).
	var food := int(OS.get_environment("FOOD")) if OS.get_environment("FOOD") else 0
	for item_id in ["steamed_bun", "ginger_tea", "rice_box", "herbal_tonic"]:
		if food > 0 and content.items.has(item_id):
			profile.add_item(item_id, food)
	var encounters: Array = content.area(ARENA).get("encounters", [])
	for i in encounters.size():
		StreetMemory.mark_cleared(profile, ARENA, i)
	var zone := ZoneSim.new(content, profile, ARENA, "west", seed)
	zone.level = level - LevelRules.BOSS_BONUS
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.position = Vector2(HERO_X, ROAD_Y)
	var boss := zone.spawn_enemy(kind, Vector2(HERO_X + 160.0, ROAD_Y))
	# NO_SKILLS=1: the control, the boss without its skill catalogue (as on
	# main before the boss skills): its moveset, phases, hazards and summons.
	var plain := OS.get_environment("NO_SKILLS") == "1"
	var pilot := AutoPilot.new(content)
	var ult := BossSkillRules.ultimate_of(content, kind)
	var out := {
		"boss": kind,
		"hero": hero_id,
		"job": str(content.hero(hero_id).get("job", "")),
		"seed": seed,
		"level": level,
		"max_hp": zone.hero.max_hp,
		"from": {"basic": 0, "skill": 0, "ultimate": 0, "hazard": 0, "helper": 0},
		"downs": 0,
		"stun": 0,
		"skills": 0,
		"hero_skills": 0,
		"countered": 0,
		"held_boss": 0,
		"plain": plain,
		"food": food,
	}
	var stun := 0
	var ticks := 0
	var ult_drops := {}
	while ticks < LIMIT:
		ticks += 1
		if plain:
			boss.skills = {}
			(zone.brains[boss.id] as EnemyBrain).boss_skills = []
			(zone.brains[boss.id] as EnemyBrain).planned_skill = ""
		var input := pilot.think(zone)
		if pilot.item:
			zone.use_item(pilot.item)
		# The drops of the Ultimate waiting to land (its hits are told apart
		# from the boss's other hazards by where they land).
		ult_drops.clear()
		for drop: Dictionary in zone.hazards:
			if drop.get("from", "") == ult and int(drop["ticks"]) <= 1:
				ult_drops[drop["at"]] = true
		var was_down := zone.hero.state == Fighter.State.DOWN
		for event in zone.tick(input):
			_count(event, out, boss, ult_drops)
		var stuck: bool = (
			zone.hero.state in [Fighter.State.HITSTUN, Fighter.State.DOWN, Fighter.State.HELD]
		)
		stun = stun + 1 if stuck else 0
		out["stun"] = maxi(int(out["stun"]), stun)
		out["downs"] += int(not was_down and zone.hero.state == Fighter.State.DOWN)
		out["held_boss"] += int(boss.state == Fighter.State.HELD)
		if boss.is_ko() or zone.hero.is_ko():
			break
	var minutes := float(ticks) / CombatRules.TICK_RATE / 60.0
	var taken := 0
	for source: String in out["from"]:
		taken += int(out["from"][source])
	out["won"] = boss.is_ko()
	out["ko"] = zone.hero.is_ko()
	out["seconds"] = snappedf(float(ticks) / CombatRules.TICK_RATE, 0.1)
	out["taken_pct_min"] = snappedf(taken * 100.0 / zone.hero.max_hp / maxf(minutes, 0.01), 0.1)
	out["skills"] = snappedf(int(out["skills"]) / maxf(minutes, 0.01), 0.1)
	return out


func _count(event: ZoneEvent, out: Dictionary, boss: Fighter, ult_drops: Dictionary) -> void:
	if event.type == "swing":
		var skill := str(event.data.get("skill", ""))
		if int(event.data["id"]) == boss.id and skill != "":
			out["skills"] += 1
		elif int(event.data["id"]) == ZoneSim.HERO_ID and skill != "":
			out["hero_skills"] += 1
		return
	if event.type != "hit" or event.hit == null:
		return
	var hit := event.hit
	if hit.defender_id != ZoneSim.HERO_ID:
		return
	if hit.countered:
		out["countered"] += 1
		return
	var source := "helper"
	if hit.move_id in BossMechanics.KINDS:
		# Nothing else is called while an Ultimate is channelled, so a hazard
		# hit on a tick its waves land is the Ultimate's.
		source = "ultimate" if not ult_drops.is_empty() else "hazard"
	elif hit.attacker_id == boss.id:
		source = "skill" if hit.move_id.begins_with("bs_") else "basic"
	out["from"][source] += hit.damage
