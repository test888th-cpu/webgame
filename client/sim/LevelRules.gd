class_name LevelRules
extends RefCounted
## How an area's level makes enemies tougher and smarter, and which weapons
## turn up. Level 1 is the enemy as written in enemies.json; every level above
## adds health, damage, a little defense and speed, faster reactions, shorter
## pauses between attacks, and (from level 3) guarding, (from level 5)
## dodging and picking up weapons. Pure functions of data and level, so the
## zone server computes the same enemy as the client.

const HP_PER_LEVEL := 0.2
const POWER_PER_LEVEL := 0.08
const SPEED_PER_LEVEL := 0.02
const MAX_SPEED_SCALE := 1.3
const XP_PER_LEVEL := 0.25
const MONEY_PER_LEVEL := 0.2


## Stats for enemy `data` at `level`.
static func enemy_stats(data: Dictionary, level: int) -> Dictionary:
	var steps := maxi(0, level - 1)
	return {
		"max_hp": roundi(float(data["max_hp"]) * (1.0 + HP_PER_LEVEL * steps)),
		"power": float(data.get("power", 1.0)) * (1.0 + POWER_PER_LEVEL * steps),
		"defense": int(data.get("defense", 0)) + steps / 3,
		"speed":
		float(data.get("speed", 1.0)) * minf(MAX_SPEED_SCALE, 1.0 + SPEED_PER_LEVEL * steps),
		"xp": roundi(float(data.get("xp", 0)) * (1.0 + XP_PER_LEVEL * steps)),
		"money_scale": 1.0 + MONEY_PER_LEVEL * steps,
	}


## The "ai" block for `level`: quicker, pushier, and new tricks.
static func enemy_ai(ai: Dictionary, level: int, has_heavy: bool) -> Dictionary:
	var steps := maxi(0, level - 1)
	var scaled := ai.duplicate()
	var quicker := maxf(0.4, 1.0 - 0.05 * steps)
	scaled["reaction"] = maxi(4, roundi(float(ai.get("reaction", 12)) * quicker))
	scaled["cooldown"] = maxi(20, roundi(float(ai.get("cooldown", 50)) * quicker))
	if has_heavy:
		scaled["heavy_chance"] = minf(0.6, float(ai.get("heavy_chance", 0.0)) + 0.02 * steps)
	scaled["guard_chance"] = clampf(0.08 * (level - 2), 0.0, 0.5)
	scaled["dodge_chance"] = clampf(0.05 * (level - 4), 0.0, 0.3)
	scaled["scavenge"] = level >= 5
	return scaled


## Chance that a wielding enemy spawns already holding a weapon.
static func armed_chance(data: Dictionary, level: int) -> float:
	if not data.get("wields", false):
		return 0.0
	return clampf(float(data.get("weapon_chance", 0.0)) + 0.04 * (level - 1), 0.0, 0.7)


## A weapon id picked by weight among those allowed at `level` ("" if none).
static func roll_weapon(
	weapons: Dictionary, level: int, rng: RandomNumberGenerator, pool := {}
) -> String:
	var total := 0.0
	var options: Array[String] = []
	for id: String in weapons:
		var weapon: Dictionary = weapons[id]
		if int(weapon.get("min_level", 1)) > level:
			continue
		if not pool.is_empty() and not pool.has(id):
			continue
		options.append(id)
		total += float(pool.get(id, weapon.get("weight", 1)))
	options.sort()  # dictionary order must not change the outcome
	var roll := rng.randf() * total
	for id in options:
		roll -= float(pool.get(id, weapons[id].get("weight", 1)))
		if roll <= 0.0:
			return id
	return options.back() if options else ""
