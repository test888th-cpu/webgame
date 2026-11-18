class_name RpgResources
extends RefCounted
## Reference resources and timing (World of ClaudeCraft at d2b91e08,
## REFERENCE-EXACT): rage math in src/sim/types.ts, src/sim/mana_regen.ts,
## the 2-second regen tick of src/sim/combat/auras.ts updateRegen, the GCD and
## the swing timer of src/sim/combat/auto_attack.ts. Times are in seconds;
## callers convert to the game's ticks (x 60).

## Global cooldown and its haste floor (types.ts GCD, MIN_GCD).
const GCD := 1.5
const MIN_GCD := 0.75
## Resources regenerate on a 2-second tick.
const REGEN_TICK_SECONDS := 2.0
## Per 2-second tick: energy +20, focus +10, rage -2 out of combat.
const ENERGY_PER_TICK := 20
const FOCUS_PER_TICK := 10
const RAGE_DECAY_PER_TICK := 2
## Out-of-combat health regen per tick: Sta x 0.3 + 2.
const HP_REGEN_PER_STA := 0.3
const HP_REGEN_FLAT := 2.0
## Spirit mana regen (mana_regen.ts): full out of combat, 30% while the
## five-second rule holds.
const FIVE_SECOND_RULE_SECONDS := 5.0
const COMBAT_SPIRIT_REGEN_FRACTION := 0.3


## Rage conversion c(L) = 0.0091 L^2 + 3.23 L + 4.27.
static func rage_conversion(level: int) -> float:
	return 0.0091 * level * level + 3.23 * level + 4.27


static func rage_from_dealing(damage: float, level: int) -> float:
	return 7.5 * damage / rage_conversion(level)


static func rage_from_taking(damage: float, attacker_level: int) -> float:
	return damage / (maxi(1, attacker_level) * 1.5)


## Spirit regen per 2 s: (Spi / 3 + 4 + floor(L / 5)) x (1 + regen%).
static func spirit_regen_per_tick(spi: float, level: int, regen_pct := 0.0) -> float:
	return (spi / 3.0 + 4.0 + floori(level / 5.0)) * (1.0 + regen_pct)


static func mana_regen_per_tick(
	spi: float, level: int, since_spend_seconds: float, regen_pct := 0.0
) -> int:
	var full := spirit_regen_per_tick(spi, level, regen_pct)
	if since_spend_seconds < FIVE_SECOND_RULE_SECONDS:
		return roundi(full * COMBAT_SPIRIT_REGEN_FRACTION)
	return roundi(full)


static func hp_regen_per_tick(sta: float) -> int:
	return roundi(sta * HP_REGEN_PER_STA + HP_REGEN_FLAT)


## The GCD after spell haste, never below MIN_GCD.
static func gcd(spell_haste := 0.0) -> float:
	return maxf(MIN_GCD, GCD / (1.0 + spell_haste))


## Seconds between swings: weapon speed / (1 + haste).
static func swing_interval(weapon_speed: float, haste := 0.0) -> float:
	return weapon_speed / (1.0 + haste)
