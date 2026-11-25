class_name RpgChannel
extends RefCounted
## One channel tick (casting_lifecycle.ts applyChannelTick), by the channel's shape:
## an aimed or self-centred area; an area around the caster; a resource channel; an
## area heal; else a bolt at the channel's target. The paladin's Aegis, the frost
## mage's pulse and the warlock's drain hooks join with those classes' ports.


static func _bonus(w: RpgEncounter, power: float, def: Dictionary, mult: float) -> int:
	var ch: Dictionary = def["channel"]
	if int(ch["ticks"]) <= 0:
		return 0
	var divisor := float(w.pack["constants"]["spell_coeff_divisor"])
	var coeff := RpgEffects.clamp_cast(w, float(ch["duration"])) / divisor / float(ch["ticks"])
	return int(RpgTalents.js_round(power * coeff * RpgEffects.power_scale(w, def) * mult))


static func tick(w: RpgEncounter, p: Dictionary, res: Dictionary, c: Dictionary) -> void:
	if RpgPaladinKit.aegis_tick(w, p, res):
		return
	var def: Dictionary = res["def"]
	var hm := RpgTalents.hit_mult(w.pack, def, p["mods"])
	var is_spell: bool = def["school"] != "physical"
	if (
		def.get("targetMode") == "position"
		or (not def.get("requiresTarget", false) and _has(res, "aoeDamage"))
	):
		var center := float(p["x"])
		if def.get("targetMode") == "position" and not def.get("selfCentered", false):
			center = float(p.get("cast_aim", p["x"]) if p.get("cast_aim") != null else p["x"])
		var sp := _bonus(w, RpgEffects.scaling_power(p, def), def, float(hm["dmg"]))
		var struck := 0
		for eff: Dictionary in res["effects"]:
			if eff["type"] != "aoeDamage":
				continue
			for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
				w, p, center, float(eff["radius"])
			):
				var dmg := w.rng.range_f(float(eff["min"]), float(eff["max"])) + sp
				if not is_spell:
					dmg *= (
						1.0
						- RpgHitTable.armor_reduction(
							RpgCombat.effective_armor(w, m), int(p["level"])
						)
					)
				RpgCombat.deal_damage(
					w, p, m, int(RpgTalents.js_round(dmg)), false, def["school"], def["name"]
				)
				struck += 1
		if def.get("targetMode") == "position":
			for eff: Dictionary in res["effects"]:
				if eff["type"] != "aoeSlow":
					continue
				for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
					w, p, center, float(eff["radius"])
				):
					RpgEffects.apply_simple(
						w,
						m,
						def["id"] + "_slow",
						"slow",
						float(eff["duration"]),
						float(eff["mult"]),
						p,
						def
					)
			RpgMage.frost_channel_pulse(w, p, str(def["id"]), struck)
		return
	if not def.get("requiresTarget", false) and _has(res, "gainResource"):
		_resource_tick(w, p, res)
		return
	if not def.get("requiresTarget", false) and _has(res, "aoeHeal"):
		var heal_sp := _bonus(w, float(p["heal_power"]), def, float(hm["heal"]))
		for eff: Dictionary in res["effects"]:
			if eff["type"] != "aoeHeal":
				continue
			var amount := w.rng.range_f(float(eff["min"]), float(eff["max"])) + heal_sp
			amount = RpgEffects.scale_primary(amount, RpgEffects.primary_heal_mult(p))
			RpgCombat.apply_heal(w, p, p, amount)
		return
	var target: Dictionary = c.get("target", {})
	if target.is_empty() or target["dead"]:
		RpgCast.cancel_cast(w)
		return
	if absf(float(target["x"]) - float(p["x"])) > w.player_attack_range(float(def["range"])):
		w.log_event({"type": "error", "text": "Out of range."})
		RpgCast.cancel_cast(w)
		return
	w.schedule_projectile(
		func(src: Dictionary, tgt: Dictionary) -> void: _bolt(w, src, tgt, res, float(hm["dmg"]))
	)


static func _bolt(
	w: RpgEncounter, src: Dictionary, tgt: Dictionary, res: Dictionary, mult: float
) -> void:
	var def: Dictionary = res["def"]
	var sp := _bonus(w, RpgEffects.scaling_power(src, def), def, mult)
	var surge := RpgMage.aether_darts_bonus(w, src, def)
	for eff: Dictionary in res["effects"]:
		match str(eff["type"]):
			"directDamage":
				var forced := RpgAbilityRules.consume_next_attack_crit(w, src)
				var crit := w.rng.chance(1.0 if forced else RpgCombat.spell_crit(src))
				var dmg := w.rng.range_f(float(eff["min"]), float(eff["max"])) + sp + surge
				dmg *= RpgEffects.spell_damage_mult(src)
				dmg *= RpgMage.darts_damage_mult(src, def)
				if crit:
					dmg *= 1.5 + float(src["crit_dmg_spell"])
				RpgCombat.deal_damage(
					w, src, tgt, int(RpgTalents.js_round(dmg)), crit, def["school"], def["name"]
				)
				RpgMage.note_spell_hit(w, src, crit, str(def["id"]))
			"drainTick":
				RpgWarlock.drain_tick(w, src, tgt, res, eff, sp)
			"extendDot":
				RpgEffects.extend_owned_dot(tgt, src["id"], eff)


static func _resource_tick(w: RpgEncounter, p: Dictionary, res: Dictionary) -> void:
	var def: Dictionary = res["def"]
	for eff: Dictionary in res["effects"]:
		if eff["type"] == "gainResource":
			p["resource"] = minf(
				float(p["max_resource"]), float(p["resource"]) + float(eff["amount"])
			)
		elif eff["type"] == "selfBuff" and eff["kind"] == "buff_spellpower":
			var existing := {}
			for a: Dictionary in p["auras"]:
				if a["id"] == def["id"] and a["kind"] == "buff_spellpower":
					existing = a
			if not existing.is_empty():
				existing["value"] = float(existing["value"]) + float(eff["value"])
				existing["stacks"] = int(existing.get("stacks", 1)) + 1
				existing["remaining"] = float(eff["duration"])
				existing["duration"] = float(eff["duration"])
			else:
				(
					RpgCombat
					. apply_aura(
						w,
						p,
						{
							"id": def["id"],
							"kind": "buff_spellpower",
							"value": float(eff["value"]),
							"remaining": float(eff["duration"]),
							"duration": float(eff["duration"]),
							"source_id": p["id"],
							"school": def["school"],
							"stacks": 1,
						}
					)
				)
			w.recalc_player()


static func _has(res: Dictionary, kind: String) -> bool:
	for e: Dictionary in res["effects"]:
		if e["type"] == kind:
			return true
	return false
