class_name LevelRules
extends RefCounted
## How levels make enemies tougher and smarter, how an enemy compares with
## the hero, and which weapons turn up. Level 1 is the enemy as written in
## enemies.json. Per level, an enemy's health grows a little faster than the
## hero's damage and its damage about as fast as the hero's health
## (progression.json), so an enemy at the hero's level stays a fair fight from
## level 1 to 50 (gear and enhancing keep the hero ahead), and the gap between
## them, not the number, decides how hard it is. Brains sharpen slowly: guarding from level 4,
## picking up weapons from 6, dodging from 9, reactions at their quickest
## only near the level cap. Pure functions of data and level, so the zone
## server computes the same enemy as the client.

const HP_PER_LEVEL := 0.06
const POWER_PER_LEVEL := 0.08
const LEVELS_PER_DEFENSE := 8
const SPEED_PER_LEVEL := 0.008
const MAX_SPEED_SCALE := 1.25
const XP_PER_LEVEL := 0.15
const MONEY_PER_LEVEL := 0.12

## Elites fight a level above their area, bosses two (unless "level_bonus" says).
const ELITE_BONUS := 1
const BOSS_BONUS := 2

## How an enemy compares with the hero, from the level gap (enemy - hero):
## its name colour, and how much of its XP it pays. Far weaker foes pay
## almost nothing, so levelling means moving on rather than farming old streets.
const THREATS: Array[Dictionary] = [
	{"id": "deadly", "gap": 6, "xp": 1.4},
	{"id": "tough", "gap": 3, "xp": 1.2},
	{"id": "even", "gap": -2, "xp": 1.0},
	{"id": "easy", "gap": -5, "xp": 0.6},
	{"id": "trivial", "gap": -1000, "xp": 0.1},
]


## The level enemy `data` fights at in an area of `area_level`.
static func enemy_level(data: Dictionary, area_level: int) -> int:
	var bonus := 0
	if data.get("boss", false):
		bonus = BOSS_BONUS
	elif data.get("elite", false):
		bonus = ELITE_BONUS
	return maxi(1, area_level + int(data.get("level_bonus", bonus)))


## Stats for enemy `data` at `level`.
static func enemy_stats(data: Dictionary, level: int) -> Dictionary:
	var steps := maxi(0, level - 1)
	return {
		"max_hp": roundi(float(data["max_hp"]) * (1.0 + HP_PER_LEVEL * steps)),
		"power": float(data.get("power", 1.0)) * (1.0 + POWER_PER_LEVEL * steps),
		"defense": int(data.get("defense", 0)) + steps / LEVELS_PER_DEFENSE,
		"speed":
		float(data.get("speed", 1.0)) * minf(MAX_SPEED_SCALE, 1.0 + SPEED_PER_LEVEL * steps),
		"xp": roundi(float(data.get("xp", 0)) * (1.0 + XP_PER_LEVEL * steps)),
		"money_scale": 1.0 + MONEY_PER_LEVEL * steps,
	}


## The "ai" block for `level`: quicker, pushier, and new tricks, a little at a time.
static func enemy_ai(ai: Dictionary, level: int, has_heavy: bool) -> Dictionary:
	var steps := maxi(0, level - 1)
	var scaled := ai.duplicate()
	var quicker := maxf(0.5, 1.0 - 0.012 * steps)
	scaled["reaction"] = maxi(4, roundi(float(ai.get("reaction", 12)) * quicker))
	scaled["cooldown"] = maxi(20, roundi(float(ai.get("cooldown", 50)) * quicker))
	if has_heavy:
		scaled["heavy_chance"] = minf(0.6, float(ai.get("heavy_chance", 0.0)) + 0.005 * steps)
	scaled["guard_chance"] = clampf(0.015 * (level - 3), 0.0, 0.45)
	scaled["dodge_chance"] = clampf(0.012 * (level - 8), 0.0, 0.3)
	scaled["scavenge"] = level >= 6
	return scaled


## "deadly", "tough", "even", "easy" or "trivial": an enemy at `enemy_level`
## against a hero at `hero_level`.
static func threat(enemy_level: int, hero_level: int) -> String:
	return _threat(enemy_level, hero_level)["id"]


## The share of its XP an enemy pays a hero at `hero_level`.
static func xp_scale(enemy_level: int, hero_level: int) -> float:
	return float(_threat(enemy_level, hero_level)["xp"])


static func _threat(enemy_level: int, hero_level: int) -> Dictionary:
	var gap := enemy_level - hero_level
	for entry in THREATS:
		if gap >= int(entry["gap"]):
			return entry
	return THREATS.back()


## Chance that a wielding enemy spawns already holding a weapon.
static func armed_chance(data: Dictionary, level: int) -> float:
	if not data.get("wields", false):
		return 0.0
	return clampf(float(data.get("weapon_chance", 0.0)) + 0.015 * (level - 1), 0.0, 0.7)


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
