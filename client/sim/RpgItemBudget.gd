class_name RpgItemBudget
extends RefCounted
## Reference item budgets (World of ClaudeCraft at d2b91e08, REFERENCE-EXACT):
## src/sim/item_budget.ts and src/sim/item_level_req.ts. Quality ids are the
## reference's own; how the six Iron Legacy grades map onto them is an open
## decision (docs/RPG_CORE_PHASE1_SPEC.md), so nothing here reads our grades.

## Share of a level's stat budget per quality (QUALITY_STAT_MULT).
const QUALITY_STAT_MULT := {
	"poor": 0.0,
	"common": 0.0,
	"uncommon": 0.55,
	"rare": 0.8,
	"epic": 1.0,
	"legendary": 1.9,
}
## Item-level bump per quality (QUALITY_ILVL_BONUS).
const QUALITY_ILVL_BONUS := {
	"poor": 0, "common": 0, "uncommon": 1, "rare": 3, "epic": 6, "legendary": 10
}
## Slot weights (SLOT_STAT_MULT).
const SLOT_STAT_MULT := {
	"mainhand": 1.0,
	"offhand": 0.75,
	"chest": 1.0,
	"legs": 0.9,
	"helmet": 0.85,
	"shoulder": 0.75,
	"waist": 0.7,
	"gloves": 0.7,
	"feet": 0.65,
	"neck": 0.65,
	"ring": 0.6,
	"trinket": 0.6,
}
## Primary stat points per item level at full multipliers (STAT_PER_ILVL).
const STAT_PER_ILVL := 0.7
## Two-handers: x1.3 stats, x1.15 weapon DPS.
const TWOHAND_STAT_MULT := 1.3
const TWOHAND_DPS_MULT := 1.15
## A worn off-hand (a quiver) is priced lower.
const WORN_OFFHAND_STAT_MULT := 0.45
## Weapon DPS by item level: 6.7 + 0.3 x level.
const WEAPON_DPS_BASE := 6.7
const WEAPON_DPS_PER_LEVEL := 0.3
## Default required level per quality when no source level is known
## (item_level_req.ts; legendary uses the level cap).
const QUALITY_REQUIRED_LEVEL := {"poor": 1, "common": 1, "uncommon": 1, "rare": 12, "epic": 18}


## Primary stat points: round(level x quality x slot x 0.7), at least 0.
static func primary_stat_budget(level: int, quality: String, slot: String) -> int:
	var q := float(QUALITY_STAT_MULT.get(quality, 0.0))
	var s := float(SLOT_STAT_MULT.get(slot, 0.7))
	return maxi(0, roundi(level * q * s * STAT_PER_ILVL))


static func weapon_dps_budget(level: int, two_hand := false) -> float:
	var dps := WEAPON_DPS_BASE + WEAPON_DPS_PER_LEVEL * level
	return dps * TWOHAND_DPS_MULT if two_hand else dps


## Item level: the source level plus the quality bump.
static func item_level(source_level: int, quality: String) -> int:
	return source_level + int(QUALITY_ILVL_BONUS.get(quality, 0))


## Weapon min/max rescaled to `dps` at its speed, spread kept
## (item_budget.ts scaleWeaponDamage). Rounded, at least 1.
static func scale_weapon_damage(weapon: Dictionary, dps: float) -> Dictionary:
	var avg := (float(weapon["min"]) + float(weapon["max"])) / 2.0
	if avg <= 0.0:
		return {"min": weapon["min"], "max": weapon["max"]}
	var k := dps * float(weapon["speed"]) / avg
	return {
		"min": maxi(1, roundi(float(weapon["min"]) * k)),
		"max": maxi(1, roundi(float(weapon["max"]) * k)),
	}
