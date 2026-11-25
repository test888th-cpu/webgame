class_name RpgClassHooks
extends RefCounted
## The class branches inside runEffects' single-target arms, gathered by arm so the
## arm reads like the reference and each class keeps its rules in its own module.


## weaponStrike's class tails after a landed strike (hunter strikes, paladin
## edicts, Solar Reprisal).
static func after_weapon_strike(
	w: RpgEncounter, p: Dictionary, _target: Dictionary, res: Dictionary, _amount: int
) -> void:
	RpgPaladinProcs.after_weapon_strike(w, p, str(res["def"]["id"]))


## directDamage's early skips (Marrowbreak's guard).
static func skip_direct_damage(_w: RpgEncounter, p: Dictionary, res: Dictionary) -> bool:
	return RpgDruidKit.skips_direct_damage(p, res)


## The guaranteed crits (fireGuaranteedCrit, magmaBurstGuaranteedCrit).
static func guaranteed_crit(
	w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary
) -> bool:
	return (
		RpgMage.fire_guaranteed_crit(p, def, target)
		or RpgShaman.magma_burst_crit(w, p, def, target)
	)


## directDamage's class multipliers (Aether Surge, Thundercall, the druid apex).
static func direct_damage_mult(_w: RpgEncounter, _p: Dictionary, _def: Dictionary) -> float:
	return 1.0


## directDamage's class tails after the hit.
static func after_direct_damage(
	_w: RpgEncounter,
	_p: Dictionary,
	_target: Dictionary,
	_res: Dictionary,
	_final: int,
	_resolved: int,
	_crit: bool
) -> void:
	pass


## heal's class tails.
static func after_heal(
	_w: RpgEncounter,
	_p: Dictionary,
	_target: Dictionary,
	_res: Dictionary,
	_amount: float,
	_healed: int
) -> void:
	pass


## dot's application (Vampiric Touch's own apply, the Dirge refresh).
static func apply_dot(
	w: RpgEncounter, p: Dictionary, target: Dictionary, dot: Dictionary, def: Dictionary
) -> void:
	if not RpgPriest.apply_dot(w, p, target, dot, def):
		RpgCombat.apply_aura(w, target, dot)


## onCastCompleted's class engines, in its order (priest, convergence, shaman,
## combustion, rogue, druid, Nature's Boon, Leaden Hex).
static func on_cast_completed(
	w: RpgEncounter, p: Dictionary, ability_id: String, target: Dictionary
) -> void:
	RpgPriest.on_cast_completed(w, p)
	RpgMage.convergence_on_cast(w, p, ability_id)
	RpgShaman.on_cast_completed(w, p, ability_id)
	RpgMage.combustion_restokes(w, p, ability_id)
	RpgRogue.engine_on_cast(w, p, ability_id, target)
	RpgDruid.engine_on_cast(w, p, ability_id, target)
	RpgDruid.natures_boon_on_cast(w, p, ability_id)
	RpgWarlock.leaden_hex(w, p, ability_id, target)


## isPersistentEngineAura and the Gloomtithe hold: auras whose timer does not run.
static func persistent_aura(w: RpgEncounter, e: Dictionary, a: Dictionary) -> bool:
	return a["kind"] == "gloomtithe" and RpgPriest.preserves_gloomtithe(w, e)


## updateAuras' per-aura class tickers (shaman talent auras, affliction, thorns,
## the paladin's oath chain).
static func tick_aura(w: RpgEncounter, e: Dictionary, a: Dictionary) -> void:
	RpgThorns.tick(w, a)
	RpgShamanWar.tick_aura(w, a)
	RpgPaladinKit.tick_pull(w, e, a)


## updateAuras' special periodic auras handled before the generic kinds (Pyre
## Guardian, Temporal Hourglass, Sacrilegious March, affliction's eye and violence,
## a dot whose harm no longer stands). True when handled.
static func tick_special(_w: RpgEncounter, _e: Dictionary, _a: Dictionary) -> bool:
	return false


## A dot tick's class tails (Vampiric Touch's heal, Second Verse, Vespers,
## Thundercall, the druid's bleed engine).
static func on_dot_tick(
	w: RpgEncounter, e: Dictionary, a: Dictionary, src: Dictionary, landed: int
) -> void:
	RpgPriest.on_dot_tick(w, e, a, src, landed)
	RpgDruidEngine.on_bleed_tick(w, src, a)
	RpgShaman.on_dot_tick(w, src, a, landed)


## An aura's end (priestOnAuraEnded, the Greater Invisibility aftereffect).
static func on_aura_ended(w: RpgEncounter, e: Dictionary, a: Dictionary) -> void:
	RpgPriest.on_aura_ended(w, e, a)


## resolveAbilityChain's class resolvers (the hunter's Coldsight and shared-talent
## swaps, Vespers, Thundercall, the paladin's Ascension).
static func resolve_ability(_w: RpgEncounter, p: Dictionary, k: Dictionary) -> Dictionary:
	return RpgPaladin.resolve(p, RpgShaman.resolve(p, RpgPriest.resolve(p, k)))


## The chain's cast-time shapers (Radiant Resonance, Verdance, Nature's Boon).
static func resolve_cast_time(
	_w: RpgEncounter, p: Dictionary, known: Dictionary, k: Dictionary
) -> Dictionary:
	var id := str(known["id"])
	var resonance := RpgPaladinProcs.resonance_cast_time(p, id, float(k["castTime"]))
	var cast_time := RpgDruidEngine.wildmend_cast_time(p, id, resonance)
	if cast_time > 0.0 and id in RpgDruid.GROVEHEART_BOON_ABILITIES:
		cast_time = 0.0 if RpgDruid.natures_boon_armed_for(p, id) else cast_time
	if cast_time == float(k["castTime"]):
		return k
	var out := k.duplicate()
	out["castTime"] = cast_time
	if cast_time != resonance:
		# coefficientCastTime: the heal still scales off the cast before the speed-up.
		out["scalingCastTime"] = resonance
	return out


## haste_burst.ts: the Sated aura after an exhausting group haste.
static func apply_sated(w: RpgEncounter, p: Dictionary, school := "physical") -> void:
	var dur := float(w.pack["constants"]["sated_duration"])
	(
		RpgCombat
		. apply_aura(
			w,
			p,
			{
				"id": "sated",
				"kind": "sated",
				"remaining": dur,
				"duration": dur,
				"value": 0.0,
				"source_id": p["id"],
				"school": school,
			}
		)
	)


## runEffects' epilogue hooks (frostMageAfterCast, Benison, Doctrine, Vespers, the
## priest's after-ability, the paladin's devotion and ascension).
static func after_effects(
	w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary, ctx: Dictionary
) -> void:
	RpgMage.after_cast(w, p, def, target)
	RpgPriest.after_ability(w, p, def, target)
	RpgPaladin.after_ability(w, p, def, ctx)


## The special ground areas' own ticks (Ring of Frost, hunter traps, Temporal
## Hourglass, Spore Burst, Spirit Bomb residue). True when the area ends.
static func tick_special_ground(w: RpgEncounter, area: Dictionary) -> bool:
	if area["special"] == "spore_burst":
		return RpgDruidKit.tick_spore_burst(w, area)
	return float(area["remaining"]) <= 1e-9 and w != null
