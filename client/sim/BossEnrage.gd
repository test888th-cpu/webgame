class_name BossEnrage
extends RefCounted
## A boss's enrage, from data:
## * a fight timer (enemies.json "enrage": {"after_seconds", "warn_seconds",
##   "damage", "cooldown"}): once the boss has fought for "after_seconds",
##   warned "warn_seconds" before, it hits harder ("damage" multiplies its
##   power, hazards included) and its hazards and summons come quicker
##   ("cooldown" multiplies their intervals). BossMechanics runs it.
## * a world boss's round (world_boss.json "enrage": {"last_seconds",
##   "warn_seconds", "damage", "cooldown"}): the same, for the last
##   "last_seconds" of the round's hour. WorldBossRun runs it.
## Enrage only raises the pressure: it never ends a fight, takes an entry
## or limits food (the owner's rules stand). Pure rules, shared with the
## server.

const FIGHT_KEYS := ["after_seconds", "warn_seconds", "damage", "cooldown"]
const ROUND_KEYS := ["last_seconds", "warn_seconds", "damage", "cooldown"]


## Makes `boss` enraged by `spec`.
static func apply(boss: Fighter, spec: Dictionary) -> void:
	boss.power *= float(spec.get("damage", 1.0))
	boss.rage = float(spec.get("cooldown", 1.0))


## Ticks into the fight when the warning and the enrage come: {"warn", "at"}.
static func fight_ticks(spec: Dictionary) -> Dictionary:
	var at := roundi(float(spec["after_seconds"]) * CombatRules.TICK_RATE)
	var warn := at - roundi(float(spec.get("warn_seconds", 0)) * CombatRules.TICK_RATE)
	return {"warn": warn, "at": at}


## `every` ticks at `boss`'s pace (never below one tick).
static func paced(boss: Fighter, every: int) -> int:
	return maxi(1, roundi(every * boss.rage))


## What is wrong with the enrage data of the enemies and the world bosses.
static func content_problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in content.enemies:
		var enemy: Dictionary = content.enemies[id]
		if enemy.has("enrage"):
			var where := "enemies.%s.enrage" % id
			if not enemy.get("boss", false):
				out.append(where + ": a boss's")
			out.append_array(problems(enemy["enrage"], where, FIGHT_KEYS))
	for id: String in content.world_bosses:
		var wb: Variant = content.world_bosses[id]
		if not (wb is Dictionary and wb.has("enrage")):
			continue
		var where := "world_bosses.%s.enrage" % id
		var found := problems(wb["enrage"], where, ROUND_KEYS)
		out.append_array(found)
		var round_seconds := float(wb.get("open_minutes", 0)) * 60.0
		if found.is_empty() and float(wb["enrage"]["last_seconds"]) >= round_seconds:
			out.append(where + ".last_seconds: inside the round")
	return out


## What is wrong with an enrage spec (`keys`: FIGHT_KEYS or ROUND_KEYS).
static func problems(spec: Variant, where: String, keys: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	if not spec is Dictionary:
		return PackedStringArray([where + ": an object"])
	for key: String in keys:
		if not (spec.get(key) is float or spec.get(key) is int):
			out.append("%s.%s: a number" % [where, key])
	if not out.is_empty():
		return out
	var length := float(spec.get("after_seconds", spec.get("last_seconds", 0)))
	if length <= 0.0:
		out.append(where + ": its time is above 0")
	if float(spec["warn_seconds"]) < 0.0 or float(spec["warn_seconds"]) >= length:
		out.append(where + ".warn_seconds: 0 or more, shorter than its time")
	if float(spec["damage"]) < 1.0 or float(spec["damage"]) > 3.0:
		out.append(where + ".damage: from 1 to 3")
	if float(spec["cooldown"]) <= 0.0 or float(spec["cooldown"]) > 1.0:
		out.append(where + ".cooldown: above 0, at most 1")
	return out
