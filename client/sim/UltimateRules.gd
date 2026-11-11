class_name UltimateRules
extends RefCounted
## The ultimate gauge. A job's ultimate (skills.json "type": "ultimate") is
## paid for with a full gauge, not energy or a long cooldown. The gauge
## fills by fighting: a little for every blow landed, and with every share of
## health lost, so the losing side builds it too. An ultimate's own blows
## fill nothing. The gauge is combat state (Fighter.gauge), kept by the zone.

const FULL := 100.0


## What a skill costs in gauge (0 for everything but an ultimate).
static func cost(skill: Dictionary) -> float:
	return float(skill.get("gauge", 0.0))


## Whether `f` has the gauge for `skill` (always, for ordinary skills).
static func ready(f: Fighter, skill: Dictionary) -> bool:
	return f.gauge >= cost(skill)


static func spend(f: Fighter, skill: Dictionary) -> void:
	f.gauge = maxf(0.0, f.gauge - cost(skill))


## A blow landed: the attacker and the defender each gain what their rates
## give ({"per_hit", "per_hurt"}; fighters without rates gain nothing).
static func on_hit(attacker: Fighter, defender: Fighter, event: CombatEvent) -> void:
	if event.blocked or event.damage <= 0:
		return
	var using: Dictionary = attacker.skills.get(attacker.skill_id, {})
	if not attacker.gauge_rates.is_empty() and cost(using) <= 0.0:
		_fill(attacker, float(attacker.gauge_rates.get("per_hit", 0.0)))
	if not defender.gauge_rates.is_empty():
		var share := float(event.damage) / maxf(1.0, defender.max_hp)
		_fill(defender, share * float(defender.gauge_rates.get("per_hurt", 0.0)))


## The hero leaves an area: the gauge goes with them to the next one. It is
## not part of a save, so loading a game starts it empty.
static func carry(profile: PlayerProfile, hero: Fighter) -> void:
	profile.gauge = clampf(hero.gauge, 0.0, FULL)


static func _fill(f: Fighter, amount: float) -> void:
	f.gauge = clampf(f.gauge + amount, 0.0, FULL)


## What is wrong with jobs.json "gauge".
static func problems(rates: Variant, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if not rates is Dictionary:
		out.append(where + ': expected {"per_hit", "per_hurt"}')
		return out
	for field: String in ["per_hit", "per_hurt"]:
		var value: Variant = rates.get(field)
		if not (value is float or value is int) or value <= 0 or value > FULL:
			out.append("%s.%s: expected a number above 0, at most %d" % [where, field, FULL])
	return out
