class_name RpgHitTable
extends RefCounted
## Reference attack resolution (World of ClaudeCraft at d2b91e08,
## REFERENCE-EXACT): src/sim/types.ts meleeMissChance, spellHitChance,
## swingMissChance, armorReduction, mobArmorReduction, and the single-roll
## table of src/sim/combat/auto_attack.ts meleeSwing (miss, dodge, parry,
## block, hit). Pure; the roll is passed in.

## Extra miss/resist % when the target is above the attacker's level, by gap
## (types.ts ABOVE_LEVEL_MISS_PCT; saturates at the last entry).
const ABOVE_LEVEL_MISS_PCT := [0.0, 2.5, 8.0, 14.0]
## A hostile mob hitting a player always connects at least 80% of the time,
## and its armor DR against a higher-level player ramps toward this cap.
const MOB_VS_PLAYER_MAX_MISS := 0.2
const MOB_VS_PLAYER_MAX_ARMOR_DR := 0.2
const ARMOR_DR_RAMP_LEVELS := 3
## armorReduction: armor / (armor + 85 x attackerLevel + 400), capped at 75%.
const ARMOR_K_PER_LEVEL := 85.0
const ARMOR_K_BASE := 400.0
const ARMOR_DR_CAP := 0.75
## Crit chance lost per level the target is above the attacker, and its floor
## (auto_attack.ts meleeSwing / rangedSwing).
const CRIT_LOSS_PER_LEVEL := 0.002
const CRIT_FLOOR := 0.005
## A mob's dodge against a player: 5% + 0.5% per level above.
const MOB_DODGE_BASE := 0.05
const MOB_DODGE_PER_LEVEL := 0.005


static func above_level_miss_pct(diff: int) -> float:
	if diff <= 0:
		return 0.0
	return ABOVE_LEVEL_MISS_PCT[mini(diff, ABOVE_LEVEL_MISS_PCT.size() - 1)]


## Melee miss by level: 5% base, -0.2% per level below, the capped penalty
## above; clamped to 0.5%..95%.
static func melee_miss_chance(attacker_level: int, target_level: int) -> float:
	var diff := target_level - attacker_level
	var miss := 5.0 + above_level_miss_pct(diff) if diff > 0 else 5.0 + diff * 0.2
	return clampf(miss / 100.0, 0.005, 0.95)


## Spell hit: 96% at equal level, +1% per level below, minus the penalty above;
## clamped to 5%..99%.
static func spell_hit_chance(caster_level: int, target_level: int) -> float:
	var diff := target_level - caster_level
	var hit := 96.0 + -diff * 1.0 if diff <= 0 else 96.0 - above_level_miss_pct(diff)
	return clampf(hit / 100.0, 0.05, 0.99)


## A swing's miss chance. A hostile mob hitting the player side is capped at
## MOB_VS_PLAYER_MAX_MISS; otherwise the attacker's hit bonus is subtracted.
static func swing_miss_chance(
	attacker_level: int, target_level: int, mob_hits_player: bool, hit_bonus := 0.0
) -> float:
	var miss := melee_miss_chance(attacker_level, target_level)
	if mob_hits_player:
		return minf(miss, MOB_VS_PLAYER_MAX_MISS)
	return maxf(0.0, miss - hit_bonus)


static func armor_reduction(armor: float, attacker_level: int) -> float:
	var a := maxf(0.0, armor)
	return minf(ARMOR_DR_CAP, a / (a + ARMOR_K_PER_LEVEL * attacker_level + ARMOR_K_BASE))


## Armor DR for a hostile mob below the player's level ramps toward the cap
## over ARMOR_DR_RAMP_LEVELS; every other case keeps the full DR.
static func mob_armor_reduction(
	armor: float, attacker_level: int, target_level: int, mob_hits_player: bool
) -> float:
	var dr := armor_reduction(armor, attacker_level)
	var diff := target_level - attacker_level
	if mob_hits_player and diff > 0:
		var t := minf(1.0, float(diff) / ARMOR_DR_RAMP_LEVELS)
		return minf(dr, dr - (dr - MOB_VS_PLAYER_MAX_ARMOR_DR) * t)
	return dr


static func mob_dodge_chance(attacker_level: int, target_level: int) -> float:
	return MOB_DODGE_BASE + maxi(0, target_level - attacker_level) * MOB_DODGE_PER_LEVEL


## Crit chance against a target: the attacker's crit minus 0.2% per level the
## target is above, floored at 0.5%.
static func crit_vs(crit: float, attacker_level: int, target_level: int, bonus := 0.0) -> float:
	return maxf(
		CRIT_FLOOR, crit + bonus - maxi(0, target_level - attacker_level) * CRIT_LOSS_PER_LEVEL
	)


## One roll in [0, 1) against the stacked table: "miss", "dodge", "parry",
## "block" or "hit" (meleeSwing order).
static func resolve(roll: float, miss: float, dodge: float, parry := 0.0, block := 0.0) -> String:
	if roll < miss:
		return "miss"
	if roll < miss + dodge:
		return "dodge"
	if roll < miss + dodge + parry:
		return "parry"
	if roll < miss + dodge + parry + block:
		return "block"
	return "hit"
