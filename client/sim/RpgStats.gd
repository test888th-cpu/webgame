class_name RpgStats
extends RefCounted
## Reference character stats (World of ClaudeCraft at d2b91e08, REFERENCE-EXACT):
## src/sim/entity.ts recalcPlayerStats, hpFromStamina, manaFromIntellect and the
## rating conversions in src/sim/types.ts. Pure: a class definition (data, see
## client/data/rpg_reference.json) and a level in, numbers out. Not connected
## to gameplay yet (docs/RPG_CORE_PHASE1_SPEC.md, Phase 2).

## Rating per 1% (types.ts HASTE/CRIT/HIT_RATING_PER_PCT).
const HASTE_RATING_PER_PCT := 20.0
const CRIT_RATING_PER_PCT := 20.0
const HIT_RATING_PER_PCT := 10.0
## Base melee/ranged crit and dodge, and their Agility slopes (entity.ts).
const BASE_CRIT := 0.05
const CRIT_PER_AGI := 0.0005
const BASE_DODGE := 0.05
const DODGE_PER_AGI := 0.0005
## Spell crit (combat/spell_combat.ts SPELL_CRIT_BASE, SPELL_CRIT_PER_INT).
const SPELL_CRIT_BASE := 0.05
const SPELL_CRIT_PER_INT := 0.0008
## Spell Power per Intellect (types.ts SPELL_POWER_PER_INT).
const SPELL_POWER_PER_INT := 0.5
## Armor from each point of Agility (entity.ts `s.armor += s.agi * 2`).
const ARMOR_PER_AGI := 2
## Primary stats, in the reference's order.
const PRIMARY := ["str", "agi", "sta", "int", "spi", "armor"]


static func haste_from_rating(rating: float) -> float:
	return rating / (HASTE_RATING_PER_PCT * 100.0)


static func crit_from_rating(rating: float) -> float:
	return rating / (CRIT_RATING_PER_PCT * 100.0)


static func hit_from_rating(rating: float) -> float:
	return rating / (HIT_RATING_PER_PCT * 100.0)


## Base + per-level primary stats at `level` (before gear): {str, agi, sta,
## int, spi, armor}. `class_def` has "base_stats" and "stats_per_level".
static func base_stats(class_def: Dictionary, level: int) -> Dictionary:
	var out := {}
	for key: String in PRIMARY:
		out[key] = (
			int(class_def["base_stats"][key]) + int(class_def["stats_per_level"][key]) * (level - 1)
		)
	return out


## The first 20 Stamina give 1 HP each, every point after gives 10.
static func hp_from_stamina(sta: int) -> int:
	var s := maxi(0, sta)
	return mini(s, 20) + maxi(0, s - 20) * 10


## The first 20 Intellect give 1 mana each, every point after gives 15.
static func mana_from_intellect(intellect: int) -> int:
	var i := maxi(0, intellect)
	return mini(i, 20) + maxi(0, i - 20) * 15


## Melee Attack Power from stats by class archetype (entity.ts apFromStats):
## "str2" = 2 x Str (warrior, paladin, shaman, druid), "str_agi" = Str + Agi
## (rogue, hunter), otherwise Str.
static func attack_power(stats: Dictionary, ap_rule: String, bonus := 0.0, pct := 0.0) -> int:
	var from_stats := float(stats["str"])
	if ap_rule == "str2":
		from_stats = 2.0 * float(stats["str"])
	elif ap_rule == "str_agi":
		from_stats = float(stats["str"]) + float(stats["agi"])
	return maxi(0, roundi((from_stats + bonus) * (1.0 + pct)))


## Hunter Ranged Attack Power: 2 x Agility (entity.ts rangedPower).
static func ranged_attack_power(stats: Dictionary, bonus := 0.0, pct := 0.0) -> int:
	return maxi(0, roundi((float(stats["agi"]) * 2.0 + bonus) * (1.0 + pct)))


static func spell_power(stats: Dictionary, bonus := 0.0) -> int:
	return maxi(0, roundi(float(stats["int"]) * SPELL_POWER_PER_INT + bonus))


## Melee and ranged crit chance: 5% + Agi x 0.05% + the shared bonus (crit
## rating, talents, sets, auras).
static func crit_chance(stats: Dictionary, shared_bonus := 0.0) -> float:
	return BASE_CRIT + float(stats["agi"]) * CRIT_PER_AGI + shared_bonus


static func spell_crit_chance(stats: Dictionary, shared_bonus := 0.0) -> float:
	return SPELL_CRIT_BASE + float(stats["int"]) * SPELL_CRIT_PER_INT + shared_bonus


static func dodge_chance(stats: Dictionary, bonus := 0.0) -> float:
	return maxf(0.0, BASE_DODGE + float(stats["agi"]) * DODGE_PER_AGI + bonus)


## Armor: stat armor plus 2 per Agility.
static func armor(stats: Dictionary) -> int:
	return int(stats["armor"]) + int(stats["agi"]) * ARMOR_PER_AGI


## Max HP: class base + per level + Stamina.
static func max_hp(class_def: Dictionary, stats: Dictionary, level: int) -> int:
	return (
		int(class_def["base_hp"])
		+ int(class_def["hp_per_level"]) * (level - 1)
		+ hp_from_stamina(int(stats["sta"]))
	)


## Resource pool: mana classes from base + per level + Intellect; rage,
## energy and focus are capped at 100.
static func max_resource(class_def: Dictionary, stats: Dictionary, level: int) -> int:
	if class_def["resource"] != "mana":
		return 100
	return (
		int(class_def["base_mana"])
		+ int(class_def["mana_per_level"]) * (level - 1)
		+ mana_from_intellect(int(stats["int"]))
	)


## Everything above for a class at a level with no gear (gear and auras add to
## `stats` before these are read; that wiring is Phase 3).
static func sheet(class_def: Dictionary, level: int) -> Dictionary:
	var s := base_stats(class_def, level)
	return {
		"stats": s,
		"max_hp": max_hp(class_def, s, level),
		"max_resource": max_resource(class_def, s, level),
		"armor": armor(s),
		"attack_power": attack_power(s, str(class_def["ap_rule"])),
		"ranged_attack_power": ranged_attack_power(s) if class_def.get("ranged_ap") else 0,
		"spell_power": spell_power(s),
		"crit": crit_chance(s),
		"spell_crit": spell_crit_chance(s),
		"dodge": dodge_chance(s),
	}
