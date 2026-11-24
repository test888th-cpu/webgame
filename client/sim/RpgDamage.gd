class_name RpgDamage
extends RefCounted
## Reference damage formulas (World of ClaudeCraft at d2b91e08,
## REFERENCE-EXACT): src/sim/combat/auto_attack.ts meleeSwing and
## rangedSwing, src/sim/combat/effect_dispatch.ts crit multipliers,
## src/sim/combat/form_swing.ts normalized speeds and the spell coefficients of
## src/sim/types.ts. Pure: the weapon roll is passed in.

## Attack Power to damage: AP / 14 per second of swing.
const AP_PER_DPS := 14.0
## Crit multipliers: physical x2, spell and heal x1.5 (plus spec bonuses).
const PHYSICAL_CRIT_MULT := 2.0
const SPELL_CRIT_MULT := 1.5
## Normalized speeds for instant weapon specials (form_swing.ts).
const DAGGER_NORMALIZED_SPEED := 1.7
const ONE_HAND_NORMALIZED_SPEED := 2.4
## Dual wield (auto_attack.ts): off-hand white damage x0.5, +10% white miss.
const OFFHAND_AUTO_ATTACK_DMG_MULT := 0.5
const DUAL_WIELD_WHITE_MISS_PENALTY := 0.1
## Spell coefficients (types.ts SPELL_COEFF_*).
const SPELL_COEFF_DIVISOR := 3.5
const SPELL_COEFF_MIN_CAST := 1.5
const SPELL_COEFF_MAX_CAST := 3.5
const SPELL_DOT_COEFF_DURATION := 15.0
const SPELL_AOE_COEFF_MULT := 0.333
## Physical "attack spell" flat parts scale off AP x this (ranged and melee).
const ATTACK_SPELL_AP_SCALE := 0.15


## A weapon's roll in [min, max] from a uniform `t` in [0, 1).
static func weapon_roll(weapon: Dictionary, t: float) -> float:
	return float(weapon["min"]) + (float(weapon["max"]) - float(weapon["min"])) * t


## Melee swing before armor: (roll x rollMult + AP / 14 x swingSpeed) x mult +
## bonus; x (2 + crit bonus) on a crit. `swing_speed` is the weapon speed for
## an auto attack, or the normalized speed for an instant special.
static func melee_hit(
	roll: float,
	attack_power: float,
	swing_speed: float,
	crit: bool,
	mult := 1.0,
	bonus := 0.0,
	roll_mult := 1.0,
	crit_bonus := 0.0
) -> float:
	var dmg := (roll * roll_mult + attack_power / AP_PER_DPS * swing_speed) * mult + bonus
	if crit:
		dmg *= PHYSICAL_CRIT_MULT + crit_bonus
	return dmg


## Ranged shot before armor: roll + RAP / 14 x weapon speed; x2 on a crit.
static func ranged_hit(roll: float, ranged_ap: float, speed: float, crit: bool) -> float:
	var dmg := roll + ranged_ap / AP_PER_DPS * speed
	return dmg * PHYSICAL_CRIT_MULT if crit else dmg


## After armor: x (1 - DR), at least 1, rounded (meleeSwing dealtAmount).
static func after_armor(dmg: float, armor_dr: float) -> int:
	return maxi(1, roundi(dmg * (1.0 - armor_dr)))


static func normalized_speed(weapon: Dictionary) -> float:
	return DAGGER_NORMALIZED_SPEED if weapon.get("dagger", false) else ONE_HAND_NORMALIZED_SPEED


## Direct spell coefficient: clamp(castTime, 1.5, 3.5) / 3.5.
static func direct_coefficient(cast_time: float) -> float:
	return clampf(cast_time, SPELL_COEFF_MIN_CAST, SPELL_COEFF_MAX_CAST) / SPELL_COEFF_DIVISOR


## Total DoT coefficient: duration / 15.
static func dot_coefficient(duration: float) -> float:
	return duration / SPELL_DOT_COEFF_DURATION


static func spell_crit(dmg: float, crit: bool, crit_bonus := 0.0) -> float:
	return dmg * (SPELL_CRIT_MULT + crit_bonus) if crit else dmg
