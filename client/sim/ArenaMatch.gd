class_name ArenaMatch
extends RefCounted
## One arena match on a ZoneSim in the arena area (ArenaRules): the hero
## against a rival hero played by ArenaBrain. Both fight with the PvP balance
## profile and the arena's health scale (the same for both), start with an
## empty gauge and full energy, and may not eat. The ladder is updated here,
## in the rules, never by a screen.
##
## Phases, in order (a phase never goes back):
##   PREPARING  rival built from its configuration, snapshotted (`loadout`)
##   COUNTDOWN  no input on either side; leaving now costs nothing
##   ACTIVE     the fight; from here leaving counts as a forfeit
##              (ArenaRules.mark_active / settle_pending)
##   VICTORY / DEFEAT / DRAW  decided: a knock-out, or at the clock the larger
##              share of health left, a draw within draw_margin of each other
##   RESULT_PROCESSING  the result applied to the ladder, once (match id)
##   RESULT_DISPLAY / RETURN  for the screen (ArenaFlow)
##
## Events it adds to the zone's: "arena_start" {"rival", "match"} (the fight
## begins), "arena_end" {ArenaRules.record()'s result, "rival", "name",
## "reason": "ko" | "time", "seconds", "hero_share", "rival_share"}.

enum Phase {
	PREPARING,
	COUNTDOWN,
	ACTIVE,
	VICTORY,
	DEFEAT,
	DRAW,
	RESULT_PROCESSING,
	RESULT_DISPLAY,
	RETURN,
}
const NEXT := {
	Phase.PREPARING: [Phase.COUNTDOWN],
	Phase.COUNTDOWN: [Phase.ACTIVE],
	Phase.ACTIVE: [Phase.VICTORY, Phase.DEFEAT, Phase.DRAW],
	Phase.VICTORY: [Phase.RESULT_PROCESSING],
	Phase.DEFEAT: [Phase.RESULT_PROCESSING],
	Phase.DRAW: [Phase.RESULT_PROCESSING],
	Phase.RESULT_PROCESSING: [Phase.RESULT_DISPLAY],
	Phase.RESULT_DISPLAY: [Phase.RETURN],
	Phase.RETURN: [],
}

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
var rival_id := ""
var rival: Fighter
var brain: ArenaBrain
var phase := Phase.PREPARING
## This match's id (ArenaRules.begin); results are applied once per id.
var match_id := 0
## The rival as configured when the match began: a configuration changed
## mid-match never touches it.
var loadout := {}
## False for a practice bout (the balance harness): no ladder, no history.
var ranked := true
## The player's own health and ultimate gauge before the match, given back
## by restore(): the arena's doubled health and its gauge stay in the arena.
## (Energy, statuses and stances live on the zone's fighter and end with it;
## food and gear are never touched by a match.)
var snapshot := {}
## Ticks of countdown left, then ticks of match left.
var countdown := 0
var ticks_left := 0
## Ticks fought since the countdown ended.
var fought := 0
var over := false
var result := {}
## The hero's health as of the last tick (0 before the match): a refresh of
## the hero's stats mid-match (gear changed) keeps it.
var _hero_hp := 0


## A match against rival `id`, or, for practice, against the resolved
## loadout `data` (ArenaLoadout.resolve; then nothing is recorded).
func _init(
	p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB, id: String, data := {}
) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	rival_id = id
	ranked = data.is_empty()
	loadout = (ArenaRules.rival(content, id) if ranked else data).duplicate(true)
	var spec := ArenaRules.spec(content)
	countdown = int(spec["countdown_ticks"])
	ticks_left = int(spec["match_seconds"]) * CombatRules.TICK_RATE
	if ranked:
		match_id = ArenaRules.begin(profile, content)
	snapshot = {"hp": profile.hp, "gauge": profile.gauge}
	zone.duel = self
	_spawn_rival()
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.energy = CombatRules.MAX_ENERGY
	zone.hero.gauge = 0.0
	zone.hero.position = Vector2(zone.bounds.get_center().x - 80.0, zone.bounds.get_center().y)
	zone.hero.facing = 1
	_go(Phase.COUNTDOWN)


## Moves to phase `to` if the order allows it; false (and no change) if not.
func _go(to: Phase) -> bool:
	if to not in NEXT[phase]:
		return false
	phase = to
	return true


## The screen shows the result, then the player leaves (ArenaFlow).
func shown() -> void:
	_go(Phase.RESULT_DISPLAY)


func returned() -> void:
	_go(Phase.RETURN)


## Gives the player back the health and gauge of before the match (on the
## zone's hero too, which carries its gauge out of the area).
func restore() -> void:
	var max_hp := int(profile.stats(content)["max_hp"])
	profile.hp = clampi(int(snapshot.get("hp", max_hp)), 1, max_hp)
	profile.gauge = clampf(float(snapshot.get("gauge", 0.0)), 0.0, UltimateRules.FULL)
	zone.hero.gauge = profile.gauge


## The hero's arena kit (ZoneSim.refresh_hero calls it): PvP balance and the
## arena's health scale, health kept as a share across a refresh.
func apply_hero() -> void:
	var hero := zone.hero
	_arena_kit(hero, profile)
	hero.hp = clampi(_hero_hp, 1, hero.max_hp) if _hero_hp > 0 else hero.max_hp


## Input for the hero this tick: nothing outside the fight.
func filter(input: FighterInput) -> FighterInput:
	return input if phase == Phase.ACTIVE else FighterInput.new()


## One tick, after the zone's: the countdown, the clock and the result.
func tick(events: Array[ZoneEvent]) -> void:
	if phase == Phase.COUNTDOWN:
		_hero_hp = zone.hero.hp
		countdown -= 1
		if countdown <= 0 and _go(Phase.ACTIVE):
			if ranked:
				ArenaRules.mark_active(profile, content, match_id, rival_id)
			events.append(ZoneEvent.make("arena_start", {"rival": rival_id, "match": match_id}))
		return
	if phase != Phase.ACTIVE:
		return
	_hero_hp = zone.hero.hp
	ticks_left -= 1
	fought += 1
	var mine := share(zone.hero)
	var theirs := share(rival)
	if zone.hero.is_ko() and rival.is_ko():
		_finish(Phase.DRAW, "ko", events)
	elif zone.hero.is_ko():
		_finish(Phase.DEFEAT, "ko", events)
	elif rival.is_ko():
		_finish(Phase.VICTORY, "ko", events)
	elif ticks_left <= 0:
		_finish(timeout_result(mine, theirs, draw_margin()), "time", events)


## The share of its health `f` has left, 0..1.
static func share(f: Fighter) -> float:
	return clampf(float(f.hp) / maxf(1.0, float(f.max_hp)), 0.0, 1.0)


## At the clock: within `margin` of each other is a draw, else the larger
## share of health left wins. Shares, never raw health, so different
## maximums compare fairly.
static func timeout_result(mine: float, theirs: float, margin: float) -> Phase:
	if absf(mine - theirs) < margin:
		return Phase.DRAW
	return Phase.VICTORY if mine > theirs else Phase.DEFEAT


func draw_margin() -> float:
	return float(ArenaRules.spec(content).get("draw_margin", 0.02))


func seconds_left() -> int:
	return ceili(float(maxi(0, ticks_left)) / CombatRules.TICK_RATE)


func seconds_fought() -> int:
	return roundi(float(fought) / CombatRules.TICK_RATE)


func _finish(outcome: Phase, reason: String, events: Array[ZoneEvent]) -> void:
	if not _go(outcome):
		return
	over = true
	var name := ArenaRules.WIN
	if outcome == Phase.DEFEAT:
		name = ArenaRules.LOSS
	elif outcome == Phase.DRAW:
		name = ArenaRules.DRAW
	_go(Phase.RESULT_PROCESSING)
	if ranked:
		var details := {
			"reason": reason,
			"seconds": seconds_fought(),
			"version": int(loadout.get("version", 0)),
		}
		result = ArenaRules.record(profile, content, rival_id, name, match_id, details)
	else:
		result = {"result": name, "won": name == ArenaRules.WIN, "match": 0, "money": 0}
	result["rival"] = rival_id
	result["name"] = rival.title
	result["reason"] = reason
	result["seconds"] = seconds_fought()
	result["hero_share"] = share(zone.hero)
	result["rival_share"] = share(rival)
	events.append(ZoneEvent.make("arena_end", result.duplicate()))


func _spawn_rival() -> void:
	var data := loadout
	var made := ArenaLoadout.profile(content, data)
	var at := Vector2(zone.bounds.get_center().x + 80.0, zone.bounds.get_center().y)
	rival = Fighter.new(zone.next_id(), ZoneSim.ENEMY_TEAM, at, 100)
	rival.kind = ArenaRules.KIND
	rival.title = str(data["name"])
	rival.look = str(content.hero(str(data["hero"]))["sprites"]["default"])
	rival.facing = -1
	JobRules.equip(rival, content, str(data["hero"]))
	_arena_kit(rival, made)
	rival.hp = rival.max_hp
	rival.energy = CombatRules.MAX_ENERGY
	rival.gauge = 0.0
	rival.stun_limit = CombatRules.HERO_STUN_LIMIT
	rival.can_parry = true
	var hero_data := content.hero(str(data["hero"]))
	rival.parry_window = int(hero_data.get("parry_window", CombatRules.PERFECT_GUARD_TICKS))
	rival.skill_armor = bool(hero_data.get("skill_armor", false))
	zone.fighters.append(rival)
	brain = ArenaBrain.new(content, zone.rng, float(data["ai"]))
	brain.configure(data.get("brain", {}))
	brain.start_at = zone.tick_count + countdown
	zone.brains[rival.id] = brain
	zone.boss_id = rival.id
	zone._enemy_level[rival.id] = {"level": int(data["level"]), "stats": {}}


## Stats of `who`'s character at the arena's health scale, and its job's kit
## at PvP strength.
func _arena_kit(f: Fighter, who: PlayerProfile) -> void:
	var stats := who.stats(content)
	f.max_hp = roundi(float(stats["max_hp"]) * float(ArenaRules.spec(content)["hp_scale"]))
	f.power = stats["power"]
	f.defense = stats["defense"]
	f.speed = stats["speed"]
	f.crit_chance = stats["crit"]
	f.attack_speed = stats["attack_speed"]
	f.skills = SkillRules.unlocked(content, who.hero, who.level, BalanceProfile.PVP)
	f.passives = SkillRules.passives(content, who.hero, who.level)
	f.combos = ComboRules.unlocked(content, who.hero, who.level, BalanceProfile.PVP)
