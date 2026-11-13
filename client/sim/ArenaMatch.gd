class_name ArenaMatch
extends RefCounted
## One arena match on a ZoneSim in the arena area (ArenaRules): the hero
## against a rival hero played by ArenaBrain. Both fight with the PvP balance
## profile and the arena's health scale, start with an empty gauge, and may
## not eat. A countdown, then MATCH: a knock-out ends it, or the clock, when
## the side with the larger share of its health left wins (a tie is the
## rival's). The ladder is updated here, in the rules, never by a screen.
##
## Events it adds to the zone's: "arena_start" (the countdown is over),
## "arena_end" {"won", "old_rank", "new_rank", "best", "new_best", "money",
## "rival", "name", "reason": "ko" | "time"}.

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
var rival_id := ""
var rival: Fighter
var brain: ArenaBrain
## Ticks of countdown left, then ticks of match left.
var countdown := 0
var ticks_left := 0
var over := false
var result := {}
## The hero's health as of the last tick (0 before the match): a refresh of
## the hero's stats mid-match (gear changed) keeps it.
var _hero_hp := 0


func _init(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB, id: String) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	rival_id = id
	var spec := ArenaRules.spec(content)
	countdown = int(spec["countdown_ticks"])
	ticks_left = int(spec["match_seconds"]) * CombatRules.TICK_RATE
	zone.duel = self
	_spawn_rival()
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.energy = CombatRules.MAX_ENERGY
	zone.hero.gauge = 0.0
	zone.hero.position = Vector2(zone.bounds.get_center().x - 80.0, zone.bounds.get_center().y)
	zone.hero.facing = 1
	profile.hp = zone.hero.hp


## The hero's arena kit (ZoneSim.refresh_hero calls it): PvP balance and the
## arena's health scale, health kept as a share across a refresh.
func apply_hero() -> void:
	var hero := zone.hero
	_arena_kit(hero, profile)
	hero.hp = clampi(_hero_hp, 1, hero.max_hp) if _hero_hp > 0 else hero.max_hp
	profile.hp = hero.hp


## Input for the hero this tick: nothing during the countdown or after the end.
func filter(input: FighterInput) -> FighterInput:
	return FighterInput.new() if countdown > 0 or over else input


## One tick, after the zone's: the countdown, the clock and the result.
func tick(events: Array[ZoneEvent]) -> void:
	if over:
		return
	_hero_hp = zone.hero.hp
	if countdown > 0:
		countdown -= 1
		if countdown == 0:
			events.append(ZoneEvent.make("arena_start", {"rival": rival_id}))
		return
	ticks_left -= 1
	if zone.hero.is_ko():
		_finish(false, "ko", events)
	elif rival.is_ko():
		_finish(true, "ko", events)
	elif ticks_left <= 0:
		var mine := float(zone.hero.hp) / maxf(1.0, zone.hero.max_hp)
		var theirs := float(rival.hp) / maxf(1.0, rival.max_hp)
		_finish(mine > theirs, "time", events)


func seconds_left() -> int:
	return ceili(float(maxi(0, ticks_left)) / CombatRules.TICK_RATE)


func _finish(won: bool, reason: String, events: Array[ZoneEvent]) -> void:
	over = true
	result = ArenaRules.record(profile, content, rival_id, won)
	result["rival"] = rival_id
	result["name"] = rival.title
	result["reason"] = reason
	events.append(ZoneEvent.make("arena_end", result.duplicate()))


func _spawn_rival() -> void:
	var data := ArenaRules.rival(content, rival_id)
	var made := ArenaRules.rival_profile(content, rival_id)
	var at := Vector2(zone.bounds.get_center().x + 80.0, zone.bounds.get_center().y)
	rival = Fighter.new(zone.next_id(), ZoneSim.ENEMY_TEAM, at, 100)
	rival.kind = ArenaRules.KIND
	rival.title = str(data["name"])
	rival.look = str(content.hero(str(data["hero"]))["sprites"]["default"])
	rival.facing = -1
	JobRules.equip(rival, content, str(data["hero"]))
	_arena_kit(rival, made)
	rival.hp = rival.max_hp
	rival.stun_limit = CombatRules.HERO_STUN_LIMIT
	rival.can_parry = true
	var hero_data := content.hero(str(data["hero"]))
	rival.parry_window = int(hero_data.get("parry_window", CombatRules.PERFECT_GUARD_TICKS))
	rival.skill_armor = bool(hero_data.get("skill_armor", false))
	zone.fighters.append(rival)
	brain = ArenaBrain.new(content, zone.rng, float(data["ai"]))
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
