class_name ArenaSim
extends RefCounted
## Arena balance measurement (docs/ARENA_BALANCE.md): two configured arena
## fighters, each built by the game's own rules (ArenaLoadout.resolve with
## the harness's settings as one more layer, PlayerProfile.stats, the PvP
## kit and the arena's health scale, exactly as ArenaMatch builds a rival),
## each played by ArenaBrain, fought with CombatRules.tick for at most the
## arena's match length and judged as the arena judges (knock-out, else
## health shares with the draw margin). Both sides are AI: the numbers
## compare configurations, not real people. Measures only.
##
## A side is a dictionary of ArenaLoadout layer settings, for example
## {"job": "boxer", "level": 70, "grades": ["godforged"], "plus": 7,
## "preset": "balanced", "personality": "balanced", "ai": 0.7}.
##
## `cap` (0 = off) is an EXPERIMENT, not a game rule: before the fight each
## side's power, defense and health are held to at most 1 + cap times the
## other side's, to see how a PvP gear cap would change the results.

const BOUNDS := Rect2(0, 200, 600, 200)
const START_GAP := 160.0
## The rival id whose tier is neutral (level 70, +0) under the settings.
const BASE_ID := "r21"


## Builds a side's fighter (id 1 or 2) and its brain, or {"errors"}.
static func make(
	content: ContentDB, side_spec: Dictionary, side: int, rng: RandomNumberGenerator
) -> Dictionary:
	var data := ArenaLoadout.resolve(content, BASE_ID, side_spec)
	if not (data["errors"] as PackedStringArray).is_empty():
		return {"errors": data["errors"]}
	var made := ArenaLoadout.profile(content, data)
	var stats := made.stats(content)
	var at := BOUNDS.get_center() + Vector2((side - 0.5) * START_GAP, 0)
	var f := Fighter.new(side + 1, side + 1, at, 100)
	f.kind = ArenaRules.KIND
	f.max_hp = roundi(float(stats["max_hp"]) * float(content.arena["hp_scale"]))
	f.hp = f.max_hp
	f.power = stats["power"]
	f.defense = stats["defense"]
	f.speed = stats["speed"]
	f.crit_chance = stats["crit"]
	f.attack_speed = stats["attack_speed"]
	f.facing = 1 if side == 0 else -1
	f.stun_limit = CombatRules.HERO_STUN_LIMIT
	f.can_parry = true
	var hero := content.hero(str(data["hero"]))
	f.parry_window = int(hero.get("parry_window", CombatRules.PERFECT_GUARD_TICKS))
	f.skill_armor = bool(hero.get("skill_armor", false))
	JobRules.equip(f, content, str(data["hero"]))
	f.energy = CombatRules.MAX_ENERGY
	f.gauge = 0.0
	f.skills = SkillRules.unlocked(content, made.hero, made.level, BalanceProfile.PVP)
	f.passives = SkillRules.passives(content, made.hero, made.level)
	f.combos = ComboRules.unlocked(content, made.hero, made.level, BalanceProfile.PVP)
	var brain := ArenaBrain.new(content, rng, float(data["ai"]))
	brain.configure(data["brain"])
	return {"fighter": f, "brain": brain, "power": ArenaRules.power_of(content, data), "data": data}


## One match, side 0 against side 1: {"winner": 0, 1 or -1 (draw),
## "seconds", "ko", "dealt": [..], "skills": [..], "defends": [..],
## "hp": [share left ..], "power": [..]}.
static func fight(
	content: ContentDB, a: Dictionary, b: Dictionary, seed_value: int, cap := 0.0
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sides := [make(content, a, 0, rng), make(content, b, 1, rng)]
	for s: Dictionary in sides:
		if s.has("errors"):
			return {"errors": s["errors"]}
	var fighters: Array[Fighter] = [sides[0]["fighter"], sides[1]["fighter"]]
	if cap > 0.0:
		_cap(fighters, cap)
	var max_ticks := int(content.arena["match_seconds"]) * CombatRules.TICK_RATE
	var out := {
		"winner": -1, "ko": false, "dealt": [0, 0], "power": [sides[0]["power"], sides[1]["power"]]
	}
	var ticks := 0
	while ticks < max_ticks and not fighters[0].is_ko() and not fighters[1].is_ko():
		ticks += 1
		var inputs := {}
		for side in 2:
			var brain: ArenaBrain = sides[side]["brain"]
			inputs[fighters[side].id] = brain.think(
				fighters[side], fighters[1 - side], true, content.moves, rng, Vector2.INF, ticks
			)
		for hit in CombatRules.tick(fighters, inputs, content.moves, BOUNDS, Callable(), rng):
			out["dealt"][0 if hit.attacker_id == fighters[0].id else 1] += hit.damage
	var shares := [ArenaMatch.share(fighters[0]), ArenaMatch.share(fighters[1])]
	out["hp"] = shares
	out["seconds"] = float(ticks) / CombatRules.TICK_RATE
	if fighters[0].is_ko() != fighters[1].is_ko():
		out["ko"] = true
		out["winner"] = 1 if fighters[0].is_ko() else 0
	elif not fighters[0].is_ko():
		var margin := float(content.arena.get("draw_margin", 0.02))
		var verdict := ArenaMatch.timeout_result(shares[0], shares[1], margin)
		if verdict != ArenaMatch.Phase.DRAW:
			out["winner"] = 0 if verdict == ArenaMatch.Phase.VICTORY else 1
	out["skills"] = [sides[0]["brain"].stats["skills"], sides[1]["brain"].stats["skills"]]
	out["defends"] = [sides[0]["brain"].stats["defends"], sides[1]["brain"].stats["defends"]]
	return out


## `seeds` matches of a against b, sides swapped every other match so neither
## start position favours one: totals from a's point of view.
static func series(
	content: ContentDB, a: Dictionary, b: Dictionary, seeds: int, cap := 0.0
) -> Dictionary:
	var out := {"matches": 0, "a_wins": 0, "b_wins": 0, "draws": 0, "kos": 0}
	out.merge({"seconds": 0.0, "a_dealt": 0.0, "b_dealt": 0.0, "a_skills": 0.0, "b_skills": 0.0})
	out.merge({"a_defends": 0.0, "b_defends": 0.0, "a_survived": 0, "b_survived": 0, "power": []})
	for n in seeds:
		var flip := n % 2 == 1
		var run := fight(content, b if flip else a, a if flip else b, 1000 + n * 7919, cap)
		if run.has("errors"):
			return {"errors": run["errors"]}
		var ai := 1 if flip else 0
		var bi := 1 - ai
		out["power"] = [run["power"][ai], run["power"][bi]]
		out["matches"] += 1
		if run["winner"] == -1:
			out["draws"] += 1
		elif run["winner"] == ai:
			out["a_wins"] += 1
		else:
			out["b_wins"] += 1
		out["kos"] += 1 if run["ko"] else 0
		out["seconds"] += run["seconds"]
		out["a_dealt"] += run["dealt"][ai]
		out["b_dealt"] += run["dealt"][bi]
		out["a_skills"] += run["skills"][ai]
		out["b_skills"] += run["skills"][bi]
		out["a_defends"] += run["defends"][ai]
		out["b_defends"] += run["defends"][bi]
		out["a_survived"] += 1 if float(run["hp"][ai]) > 0.0 else 0
		out["b_survived"] += 1 if float(run["hp"][bi]) > 0.0 else 0
	var m := float(maxi(1, out["matches"]))
	return {
		"matches": out["matches"],
		"a_win_rate": snappedf(out["a_wins"] / m, 0.001),
		"b_win_rate": snappedf(out["b_wins"] / m, 0.001),
		"draw_rate": snappedf(out["draws"] / m, 0.001),
		"ko_rate": snappedf(out["kos"] / m, 0.001),
		"mean_seconds": snappedf(out["seconds"] / m, 0.1),
		"a_damage": roundi(out["a_dealt"] / m),
		"b_damage": roundi(out["b_dealt"] / m),
		"a_skills": snappedf(out["a_skills"] / m, 0.1),
		"b_skills": snappedf(out["b_skills"] / m, 0.1),
		"a_defends": snappedf(out["a_defends"] / m, 0.1),
		"b_defends": snappedf(out["b_defends"] / m, 0.1),
		"a_survival": snappedf(out["a_survived"] / m, 0.001),
		"b_survival": snappedf(out["b_survived"] / m, 0.001),
		"power": out["power"],
	}


## The cap experiment: each side's power, defense and health held to at
## most 1 + cap times the other's.
static func _cap(fighters: Array[Fighter], cap: float) -> void:
	var base := [
		[fighters[0].power, fighters[0].defense, fighters[0].max_hp],
		[fighters[1].power, fighters[1].defense, fighters[1].max_hp],
	]
	for side in 2:
		var f := fighters[side]
		var other: Array = base[1 - side]
		f.power = minf(f.power, float(other[0]) * (1.0 + cap))
		f.defense = mini(f.defense, roundi(float(other[1]) * (1.0 + cap)))
		f.max_hp = mini(f.max_hp, roundi(float(other[2]) * (1.0 + cap)))
		f.hp = f.max_hp
