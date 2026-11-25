class_name RpgGround
extends RefCounted
## Ground areas (effect_dispatch.ts groundAoE arm, sim.ts pulseGroundAoE,
## hunter_ground_zone.ts pulseArmoredGroundAoE, entity_roster.ts tickGroundAoEs). An
## area pulses every interval for its duration at its centre on the street's axis; a
## delayed one waits one interval before its first pulse. The special areas (Ring of
## Frost, hunter traps, Temporal Hourglass, Spore Burst, Spirit Bomb's residue) tick
## through their class modules. Areas live on the encounter (`w.ground`).


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


## The groundAoE arm.
static func cast(
	w: RpgEncounter, p: Dictionary, res: Dictionary, eff: Dictionary, ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var center := float(p["cast_aim"]) if p.get("cast_aim") != null else float(p["x"])
	var thunder := RpgShaman.thundercall_damage_mult(w, p, str(def["id"]))
	var area := {
		"source_id": p["id"],
		"x": center,
		"radius": float(eff["radius"]),
		"min": float(_jr(float(eff["min"]) * thunder)),
		"max": float(_jr(float(eff["max"]) * thunder)),
		"remaining": float(eff["duration"]) + (w.dt if eff.get("delayed", false) else 0.0),
		"interval": float(eff["interval"]),
		"tick_timer": float(eff["interval"]),
		"school": str(def["school"]),
		"ability": str(def["name"]),
		"ability_id": str(def["id"]),
		"sp_bonus":
		(
			RpgEffects.direct_hit_bonus(
				w,
				RpgEffects.scaling_power(p, def),
				def,
				float(res["castTime"]),
				true,
				float(ctx["dmg_mult"])
			)
			* thunder
		),
		"ally_buff_pct": eff.get("allyBuffPct"),
		"ignite_frac": eff.get("igniteFrac"),
		"slow_mult": eff.get("slowMult"),
		"slow_duration": eff.get("slowDuration"),
		"orb_cdr": eff.get("orbCdr"),
		"devotion_on_first_hit": eff.get("devotionOnFirstHit"),
		"armor_mitigated": def["school"] == "physical",
		"threat": {"flat": ctx["threat_flat"], "mult": ctx["threat_mult"]},
	}
	RpgPaladin.shape_consecration(w, p, def, eff, area)
	if eff.get("orbCdr") != null:
		p["blizzard_orb_cdr"] = 0.0
	if not eff.get("delayed", false):
		pulse(w, area, true)
	w.ground.append(area)
	RpgShaman.after_ground_aoe(w, p, def, eff, area)


## tickGroundAoEs.
static func tick(w: RpgEncounter) -> void:
	for i in range(w.ground.size() - 1, -1, -1):
		var area: Dictionary = w.ground[i]
		var src := w.unit(int(area["source_id"]))
		if area.get("special") != null:
			if src.is_empty() or src["dead"]:
				w.ground.remove_at(i)
				continue
			area["remaining"] = float(area["remaining"]) - w.dt
			if RpgClassHooks.tick_special_ground(w, area):
				w.ground.erase(area)
			continue
		area["remaining"] = float(area["remaining"]) - w.dt
		area["tick_timer"] = float(area["tick_timer"]) - w.dt
		while float(area["tick_timer"]) <= 1e-9 and float(area["remaining"]) > 1e-9:
			area["tick_timer"] = float(area["tick_timer"]) + float(area["interval"])
			pulse(w, area, false)
		if float(area["remaining"]) <= 1e-9:
			w.ground.erase(area)


## pulseGroundAoE / pulseArmoredGroundAoE.
static func pulse(w: RpgEncounter, area: Dictionary, direct: bool) -> void:
	var src := w.unit(int(area["source_id"]))
	if src.is_empty() or src["dead"]:
		return
	if area.get("ally_buff_pct") != null:
		# friendliesInRadius: the caster alone on the street, while inside the rune.
		if absf(float(src["x"]) - float(area["x"])) <= float(area["radius"]):
			var dur := float(area["interval"]) + 1.0
			(
				RpgCombat
				. apply_aura(
					w,
					src,
					{
						"id": "rune_of_power",
						"kind": "buff_dmg_done",
						"value": float(area["ally_buff_pct"]),
						"remaining": dur,
						"duration": dur,
						"source_id": src["id"],
						"school": area["school"],
					}
				)
			)
		return
	var struck := 0
	var effective := 0
	var school := str(area["school"])
	for t: Dictionary in RpgAbilityRules.hostiles_in_radius(
		w, src, float(area["x"]), float(area["radius"])
	):
		struck += 1
		var raw := w.rng.range_f(float(area["min"]), float(area["max"])) + float(area["sp_bonus"])
		var dmg := 0
		if area["armor_mitigated"]:
			dmg = _jr(
				(
					raw
					* (
						1.0
						- RpgHitTable.armor_reduction(
							RpgCombat.effective_armor(w, t), int(src["level"])
						)
					)
				)
			)
		else:
			dmg = _jr(raw * RpgEffects.spell_damage_mult(src) if school != "physical" else raw)
			if (
				area.get("slow_mult") != null
				and area.get("slow_duration") != null
				and not t["dead"]
			):
				(
					RpgCombat
					. apply_aura(
						w,
						t,
						{
							"id": "blizzard_slow",
							"kind": "slow",
							"value": float(area["slow_mult"]),
							"remaining": float(area["slow_duration"]),
							"duration": float(area["slow_duration"]),
							"source_id": src["id"],
							"school": school,
						}
					)
				)
			if area.get("ignite_frac") != null and dmg > 0 and not t["dead"]:
				RpgMage.apply_ignite(w, src, t, _jr(dmg * float(area["ignite_frac"])))
		var before := int(t["hp"])
		RpgCombat.deal_damage(
			w, src, t, dmg, false, school, str(area["ability"]), "hit", not direct, area["threat"]
		)
		if int(t["hp"]) < before:
			effective += 1
	if area.get("orb_cdr") != null and struck > 0 and src["kind"] == "player":
		RpgMage.frost_channel_pulse(w, src, "blizzard", struck)
	RpgPaladin.ground_devotion_on_first_hit(w, src, area, effective)
