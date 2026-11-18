class_name RpgMobs
extends RefCounted
## Reference enemy stats (World of ClaudeCraft at d2b91e08, REFERENCE-EXACT):
## src/sim/entity.ts createMob. Kill XP lives in RpgProgression (one home for
## every XP rule).

## Elite multipliers (createMob).
const ELITE_HP_MULT := 2.3
const ELITE_DMG_MULT := 1.5
## A mob's weapon spread around its damage (createMob).
const DMG_MIN_MULT := 0.8
const DMG_MAX_MULT := 1.25


## A mob template at `level`: {max_hp, weapon {min, max, speed}, armor}.
## `template` has hp_base, hp_per_level, dmg_base, dmg_per_level, attack_speed,
## armor_per_level and optional elite.
static func stats(template: Dictionary, level: int) -> Dictionary:
	var elite := bool(template.get("elite", false))
	var hp := (
		(float(template["hp_base"]) + float(template["hp_per_level"]) * (level - 1))
		* (ELITE_HP_MULT if elite else 1.0)
	)
	var dmg := (
		(float(template["dmg_base"]) + float(template["dmg_per_level"]) * (level - 1))
		* (ELITE_DMG_MULT if elite else 1.0)
	)
	return {
		"max_hp": roundi(hp),
		"weapon":
		{
			"min": roundi(dmg * DMG_MIN_MULT),
			"max": roundi(dmg * DMG_MAX_MULT),
			"speed": float(template["attack_speed"]),
		},
		"armor": roundi(float(template["armor_per_level"]) * (level - 1)),
	}
