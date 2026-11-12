class_name DuelSim
extends RefCounted
## One against one, hero against hero, in a bare arena: the measurement for
## PvP balance (docs/HARNESS.md). Both sides use their job's kit with the
## PvP balance profile (SkillRules.unlocked, ComboRules.unlocked with
## BalanceProfile.PVP), the player's stun-lock protection, parry and grab
## escape, and the same gear at the same level. A simple bot plays each side
## (DuelBot); it is not a person, so the numbers compare jobs with each other,
## not with real play. Measures only: it changes no game data.

## The arena: a street 600 px long, the fighters 160 px apart to start.
const BOUNDS := Rect2(0, 200, 600, 200)
const START_GAP := 160.0
## A match ends at a knock-out or after this many ticks (90 s), when the side
## with more of its health left wins.
const MAX_TICKS := 5400


## One match: {"winner": 0 or 1 (-1 a draw), "ticks", "hp": [left, right]
## share of health left, "dealt": [..], "lock": [longest ticks each could
## not act], "biggest": [largest single blow each took, as a share of their
## health], "combos": [routes completed], "grabs": [holds started]}.
static func duel(content: ContentDB, heroes: Array, level: int, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var fighters: Array[Fighter] = []
	var bots: Array[DuelBot] = []
	for side in 2:
		var f := make_hero(content, str(heroes[side]), level, side)
		fighters.append(f)
		bots.append(DuelBot.new(content, rng))
	var out := {"winner": -1, "ticks": 0, "hp": [1.0, 1.0], "dealt": [0, 0]}
	out.merge({"lock": [0, 0], "biggest": [0.0, 0.0], "combos": [0, 0], "grabs": [0, 0]})
	out["biggest_move"] = ["", ""]
	var locked := [0, 0]
	while out["ticks"] < MAX_TICKS and not fighters[0].is_ko() and not fighters[1].is_ko():
		out["ticks"] += 1
		var inputs := {}
		for side in 2:
			inputs[fighters[side].id] = bots[side].think(fighters[side], fighters[1 - side])
		for hit in CombatRules.tick(fighters, inputs, content.moves, BOUNDS, Callable(), rng):
			var by := 0 if hit.attacker_id == fighters[0].id else 1
			out["dealt"][by] += hit.damage
			var share := float(hit.damage) / fighters[1 - by].max_hp
			if share > out["biggest"][1 - by]:
				out["biggest"][1 - by] = share
				out["biggest_move"][1 - by] = hit.move_id
		for side in 2:
			var f := fighters[side]
			if f.combo_done != "":
				out["combos"][side] += 1
				f.combo_done = ""
			if f.state == Fighter.State.GRAB and f.state_tick == 0:
				out["grabs"][side] += 1
			var helpless := (
				f.state in [Fighter.State.HITSTUN, Fighter.State.DOWN, Fighter.State.HELD]
			)
			locked[side] = locked[side] + 1 if helpless else 0
			out["lock"][side] = maxi(out["lock"][side], locked[side])
	for side in 2:
		out["hp"][side] = float(fighters[side].hp) / fighters[side].max_hp
	if out["hp"][0] != out["hp"][1]:
		out["winner"] = 0 if out["hp"][0] > out["hp"][1] else 1
	return out


## A player's hero for a duel: the stats of `level` in shop gear, the job's
## punches, grab, gauge and PvP kit, a player's protections.
static func make_hero(content: ContentDB, hero_id: String, level: int, side: int) -> Fighter:
	var setup := {"area": "", "level": level, "seed": 1, "hero": hero_id, "gear": "shop"}
	var profile := LevelingSim._profile(content, setup)
	var stats := profile.stats(content)
	var at := BOUNDS.get_center() + Vector2((side - 0.5) * START_GAP, 0)
	var f := Fighter.new(side + 1, side + 1, at, int(stats["max_hp"]))
	f.kind = "hero"
	f.power = stats["power"]
	f.defense = stats["defense"]
	f.speed = stats["speed"]
	f.crit_chance = stats["crit"]
	f.attack_speed = stats["attack_speed"]
	f.facing = 1 if side == 0 else -1
	f.stun_limit = CombatRules.HERO_STUN_LIMIT
	f.can_parry = true
	var data := content.hero(hero_id)
	f.parry_window = int(data.get("parry_window", CombatRules.PERFECT_GUARD_TICKS))
	f.skill_armor = bool(data.get("skill_armor", false))
	JobRules.equip(f, content, hero_id)
	f.skills = SkillRules.unlocked(content, hero_id, level, BalanceProfile.PVP)
	f.passives = SkillRules.passives(content, hero_id, level)
	f.combos = ComboRules.unlocked(content, hero_id, level, BalanceProfile.PVP)
	return f


## Every pairing of the heroes (both sides, mirrors included) over `seeds`
## seeds at `level`: {"wins": {hero: {foe: wins}}, "games": {hero: {foe:
## games}}, "lock": longest lock seen (ticks), "biggest": largest blow seen
## (share of health), "ticks": mean match length, "draws"}.
static func table(content: ContentDB, heroes: Array, level: int, seeds: int) -> Dictionary:
	var out := {"wins": {}, "games": {}, "lock": 0, "biggest": 0.0, "ticks": 0.0, "draws": 0}
	out.merge({"combos": {}, "matches": 0, "biggest_move": ""})
	for a: String in heroes:
		out["wins"][a] = {}
		out["games"][a] = {}
		out["combos"][a] = 0
		for b: String in heroes:
			out["wins"][a][b] = 0
			out["games"][a][b] = 0
	for a: String in heroes:
		for b: String in heroes:
			for seed_value in range(1, seeds + 1):
				var run := duel(content, [a, b], level, seed_value * 7919 + level)
				out["matches"] += 1
				out["ticks"] += float(run["ticks"])
				out["lock"] = maxi(out["lock"], maxi(run["lock"][0], run["lock"][1]))
				for side in 2:
					if run["biggest"][side] > out["biggest"]:
						out["biggest"] = run["biggest"][side]
						out["biggest_move"] = run["biggest_move"][side]
				out["combos"][a] += int(run["combos"][0])
				out["combos"][b] += int(run["combos"][1])
				out["games"][a][b] += 1
				out["games"][b][a] += 1
				if run["winner"] == 0:
					out["wins"][a][b] += 1
				elif run["winner"] == 1:
					out["wins"][b][a] += 1
				else:
					out["draws"] += 1
	out["ticks"] = out["ticks"] / maxi(1, out["matches"])
	return out


## Each hero's share of the games they won against every other job (mirror
## matches left out).
static func win_rates(result: Dictionary) -> Dictionary:
	var rates := {}
	for a: String in result["wins"]:
		var won := 0
		var played := 0
		for b: String in result["wins"][a]:
			if a == b:
				continue
			won += int(result["wins"][a][b])
			played += int(result["games"][a][b])
		rates[a] = float(won) / maxi(1, played)
	return rates
