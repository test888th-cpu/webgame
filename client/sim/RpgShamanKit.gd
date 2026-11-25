class_name RpgShamanKit
extends RefCounted
## The shaman's Spiritmend (src/sim/combat/shaman_spiritmend.ts): a Restoration
## shaman's Mending Waters (50%) and Tidecall (100%) bank their healing as a Mending
## Current (cap 30% of max health) that pays out over 12 s, and Chain Heal or Unleash
## Weapon cash it in at 125%. Unleash Weapon (shaman_unleash_weapon.ts) by the worn
## enchant, and the chainHeal arm. On the street the only ally is the shaman.

const MENDING_CURRENT_ID := "shaman_mending_current"
const LIFESPRING_WEAPON_ID := "lifespring_weapon"
const MENDING_CURRENT_DURATION := 12.0
const MENDING_CURRENT_INTERVAL := 3.0
const MENDING_CURRENT_MAX_HP_CAP := 0.3
const MENDING_WATERS_DEPOSIT := 0.5
const TIDECALL_DEPOSIT := 1.0
const LIFESPRING_DEPOSIT_BONUS := 0.2
const CURRENT_CONSUME_MULTIPLIER := 1.25
const UNLEASH_GUARD_FRACTION := 0.5
const UNLEASH_GUARD_DURATION := 8.0
const PYREBRAND_UNLEASH_MIN := 54.0
const PYREBRAND_UNLEASH_MAX := 64.0
const PYREBRAND_UNLEASH_SP := 0.3


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _resto(p: Dictionary) -> bool:
	return (
		p.get("kind") == "player"
		and p.get("class_id") == "shaman"
		and p.get("spec_id") == "restoration"
	)


static func current(target: Dictionary, source_id: int) -> Dictionary:
	for a: Dictionary in target["auras"]:
		if a["id"] == MENDING_CURRENT_ID and int(a["source_id"]) == source_id:
			return a
	return {}


static func _deposit_raw(w: RpgEncounter, src: Dictionary, t: Dictionary, requested: float) -> void:
	if not _resto(src) or t["dead"] or requested <= 0.0:
		return
	var cap := maxi(0, _jr(int(t["max_hp"]) * MENDING_CURRENT_MAX_HP_CAP))
	var existing := current(t, int(src["id"]))
	var next := mini(cap, int(existing.get("value", 0)) + _jr(requested))
	if not existing.is_empty():
		existing["value"] = float(next)
		existing["remaining"] = MENDING_CURRENT_DURATION
		existing["duration"] = MENDING_CURRENT_DURATION
		existing["tick_interval"] = MENDING_CURRENT_INTERVAL
		existing["tick_timer"] = MENDING_CURRENT_INTERVAL
	elif next > 0:
		(
			RpgCombat
			. apply_aura(
				w,
				t,
				{
					"id": MENDING_CURRENT_ID,
					"kind": "hot",
					"value": float(next),
					"remaining": MENDING_CURRENT_DURATION,
					"duration": MENDING_CURRENT_DURATION,
					"tick_interval": MENDING_CURRENT_INTERVAL,
					"tick_timer": MENDING_CURRENT_INTERVAL,
					"source_id": src["id"],
					"school": "nature",
				}
			)
		)


## depositMendingCurrent after Mending Waters or Tidecall.
static func deposit(
	w: RpgEncounter, src: Dictionary, t: Dictionary, healing: float, id: String
) -> void:
	if not id in ["healing_wave", "tidecall"] or not _resto(src) or healing <= 0.0:
		return
	var base := TIDECALL_DEPOSIT if id == "tidecall" else MENDING_WATERS_DEPOSIT
	var life := 1.0
	if RpgAbilityRules.has_id(src, LIFESPRING_WEAPON_ID):
		life = 1.0 + LIFESPRING_DEPOSIT_BONUS
		if RpgShamanWar.selected(src, RpgShamanWar.T_IMBUE_MASTERY):
			life += 0.2
	var talent := 1.5 if RpgShamanWar.exaltation_active(src) else 1.0
	_deposit_raw(w, src, t, float(maxi(0, _jr(healing * base * life * talent))))


## tickMendingCurrent: each tick pays the current out evenly over the ticks left.
static func tick_mending_current(w: RpgEncounter, t: Dictionary, a: Dictionary) -> bool:
	if a["id"] != MENDING_CURRENT_ID or a["kind"] != "hot":
		return false
	var src := w.unit(int(a["source_id"]))
	if src.is_empty() or src["dead"] or not _resto(src):
		a["value"] = 0.0
		a["remaining"] = 0.0
		return true
	var ticks := int(floorf(maxf(0.0, float(a["remaining"])) / MENDING_CURRENT_INTERVAL)) + 1
	var pay := mini(int(a["value"]), int(ceilf(float(a["value"]) / ticks)))
	a["value"] = float(maxi(0, int(a["value"]) - pay))
	if pay > 0:
		RpgCombat.apply_heal(w, src, t, pay, false)
	return true


## consumeMendingCurrent (Chain Heal's hops): the whole current at 125% at once.
static func consume(w: RpgEncounter, src: Dictionary, t: Dictionary) -> void:
	if not _resto(src):
		return
	var cur := current(t, int(src["id"]))
	if cur.is_empty():
		return
	t["auras"].erase(cur)
	var pay := maxi(0, _jr(float(cur["value"]) * CURRENT_CONSUME_MULTIPLIER))
	if pay <= 0 or t["dead"]:
		return
	RpgCombat.apply_heal(w, src, t, pay, false)
	if RpgShamanWar.selected(src, RpgShamanWar.T_ECHOING):
		var echo := {
			"id": "shaman_echoing_elements_heal",
			"kind": "hot",
			"value": float(maxi(1, _jr(pay * 0.4))),
			"remaining": 2.0,
			"duration": 2.0,
			"tick_interval": 2.0,
			"tick_timer": 2.0,
			"source_id": src["id"],
			"school": "nature",
		}
		RpgCombat.apply_aura(w, t, echo)
	if RpgShamanWar.selected(src, RpgShamanWar.T_DEEP_RESERVOIR):
		_deposit_raw(w, src, t, float(cur["value"]) * 0.25)


## The chainHeal arm: one rolled heal; the street's chain is the shaman alone (each
## hop goes to the most hurt unhealed ally in reach).
static func chain_heal(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var first: Dictionary = target if not target.is_empty() else p
	if first["kind"] == "mob":
		return
	var amount := RpgEffects.scale_primary(
		(
			w.rng.range_f(float(eff["min"]), float(eff["max"]))
			+ RpgEffects.direct_heal_bonus(
				w, float(p["heal_power"]), float(res["castTime"]), ctx["heal_mult"]
			)
		),
		RpgEffects.primary_heal_mult(p)
	)
	var chain: Array = [first]
	for i in chain.size():
		var hop := maxi(1, _jr(amount * pow(float(eff["falloff"]), i)))
		RpgCombat.apply_heal(w, p, chain[i], hop)
		consume(w, p, chain[i])


## unleashWeaponCastError.
static func unleash_error(w: RpgEncounter, p: Dictionary, target: Dictionary) -> String:
	var enchant := _enchant(p)
	if enchant == "":
		return "That ability is not ready yet."
	if enchant == "lifespring":
		if current(p, int(p["id"])).is_empty():
			return "That ability is not ready yet."
		return ""
	return (
		""
		if not target.is_empty() and target["kind"] == "mob" and w != null
		else "You have no target."
	)


static func _enchant(p: Dictionary) -> String:
	if RpgAbilityRules.has_id(p, "flametongue_weapon"):
		return "pyrebrand"
	if RpgAbilityRules.has_id(p, RpgShamanWar.GALEHEART_WEAPON_ID):
		return "galeheart"
	if RpgAbilityRules.has_id(p, RpgShamanWar.STONEBOUND_WEAPON_ID):
		return "stonebound"
	if RpgAbilityRules.has_id(p, LIFESPRING_WEAPON_ID):
		return "lifespring"
	return ""


## runUnleashWeapon: Pyrebrand's fire bolt (+2 charges), Galeheart's strike and haste,
## Stonebound's strike and guard, Lifespring's cashed current and its ward.
static func run_unleash(w: RpgEncounter, p: Dictionary, target: Dictionary) -> void:
	var enchant := _enchant(p)
	if enchant == "lifespring":
		_unleash_current(w, p, p)
		return
	if target.is_empty() or target["dead"] or target["kind"] != "mob":
		return
	match enchant:
		"pyrebrand":
			var dmg := w.rng.range_f(PYREBRAND_UNLEASH_MIN, PYREBRAND_UNLEASH_MAX)
			dmg += _jr(float(p["spell_power"]) * PYREBRAND_UNLEASH_SP)
			dmg *= RpgEffects.spell_damage_mult(p)
			var crit := w.rng.chance(RpgCombat.spell_crit(p))
			if crit:
				dmg *= 1.5 + float(p["crit_dmg_spell"])
			RpgCombat.deal_damage(w, p, target, maxi(1, _jr(dmg)), crit, "fire", "Unleash Weapon")
			RpgShaman.add_thunder_charges(w, p, 2)
		"galeheart":
			var on_dealt := func(amount: int, _effective: int) -> void:
				RpgShamanWar.advance_cadence(w, p, target, amount)
			var opts := {
				"weapon_mult": 1.0,
				"bonus": 0.0,
				"ability_id": "unleash_weapon",
				"on_dealt": on_dealt,
			}
			if w.player_melee(target, opts, "Unleash Weapon"):
				RpgCombat.apply_aura(
					w, p, _guard(p, "shaman_galeheart_unleash_haste", "buff_haste", 6.0, 1.2)
				)
		"stonebound":
			w.player_melee(
				target,
				{"weapon_mult": 0.75, "bonus": 0.0, "ability_id": "unleash_weapon"},
				"Unleash Weapon"
			)
			RpgCombat.apply_aura(
				w, p, _guard(p, "shaman_stonebound_unleash_guard", "buff_dr", 4.0, 0.2)
			)


static func _guard(p: Dictionary, id: String, kind: String, dur: float, value: float) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": dur,
		"duration": dur,
		"value": value,
		"source_id": p["id"],
		"school": "nature",
	}


## unleashMendingCurrent: the current at 125%, then half the healing as a ward.
static func _unleash_current(w: RpgEncounter, src: Dictionary, t: Dictionary) -> void:
	if not _resto(src) or t["dead"]:
		return
	var cur := current(t, int(src["id"]))
	if cur.is_empty():
		return
	t["auras"].erase(cur)
	var pay := maxi(0, _jr(float(cur["value"]) * CURRENT_CONSUME_MULTIPLIER))
	if pay <= 0:
		return
	var healed := RpgCombat.apply_heal(w, src, t, pay, false)
	var ward := maxi(0, _jr(healed * UNLEASH_GUARD_FRACTION))
	if ward > 0:
		RpgCombat.apply_aura(
			w, t, _guard(src, "unleash_weapon", "absorb", UNLEASH_GUARD_DURATION, ward)
		)
