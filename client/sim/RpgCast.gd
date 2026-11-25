class_name RpgCast
extends RefCounted
## Casting (src/sim/combat/casting_lifecycle.ts castAbility, updateCasting,
## applyAbility, applyChannelTick, cancelCast, pushbackCast). Every refusal is the
## reference's message; the ones it makes silently return SILENT + a reason. Only an
## ability the runtime pack marks executable may be cast (the rest say why).
##
## Street adaptations (docs/SKILLS_PORT.md): the player turns to face the target it
## casts at (the street has no separate turn control), and an aimed ability without a
## cursor takes the reference's no-aim fallback (the selected hostile for the four
## SELECTED_HOSTILE_AIM_FALLBACK spells, else the caster's own position).

const SILENT := "silent:"
const CAST_QUEUE_WINDOW_SEC := 0.4
const CAST_PUSHBACK_SEC := 0.5
const CHANNEL_PUSHBACK_FRACTION := 0.25
const CAST_COMPLETE_EPS := 1e-9
const SELECTED_HOSTILE_AIM_FALLBACK: Array[String] = [
	"earthquake", "earthbind", "frostjaw_trap", "bear_trap"
]


static func _cost_error(resource: String) -> String:
	match resource:
		"rage":
			return "Not enough rage!"
		"energy":
			return "Not enough energy!"
		"focus":
			return "Not enough Focus!"
	return "Not enough mana!"


## paladinManaCostMultiplier.
static func paladin_mana_mult(p: Dictionary) -> float:
	var reduction := 0.0
	for a: Dictionary in p["auras"]:
		if a["kind"] == "buff_mana_grace":
			reduction += float(a.get("value2", 0.03))
	return maxf(0.2, 1.0 - reduction)


## The GCD (castAbility: max(MIN_GCD, playerGcdFor(cls) / spellHasteMult)).
static func gcd_for(w: RpgEncounter, p: Dictionary) -> float:
	var base := 1.0 if p["class_id"] == "rogue" else float(w.pack["constants"]["gcd"])
	return maxf(float(w.pack["constants"]["min_gcd"]), base / spell_haste_mult(p))


static func spell_haste_mult(p: Dictionary) -> float:
	var haste := float(p["spell_haste"])
	for a: Dictionary in p["auras"]:
		if a["kind"] == "buff_spellhaste":
			haste += float(a["value"])
	return 1.0 + maxf(0.0, haste)


static func is_silenced(p: Dictionary) -> bool:
	return RpgAbilityRules.has_kind(p, "silence")


static func is_locked_out(p: Dictionary, school: String) -> bool:
	for a: Dictionary in p["auras"]:
		if a["kind"] == "lockout" and str(a["school"]) == school:
			return true
	return false


static func _effects_have(res: Dictionary, kind: String) -> bool:
	for e: Dictionary in res["effects"]:
		if e["type"] == kind:
			return true
	return false


## castAbility. Returns "" when the cast started or resolved.
static func cast(w: RpgEncounter, ability_id: String) -> String:
	var p := w.player
	var res := w.known_entry(ability_id)
	if res.is_empty():
		return "You do not know that ability."
	var def: Dictionary = res["def"]
	if p["dead"]:
		return SILENT + "dead"
	if def.get("passive", false):
		return SILENT + "passive"
	var paladin_gate := RpgPaladin.cast_gate(p, ability_id)
	if paladin_gate != "":
		return paladin_gate
	if _cancel_stasis_toggle(w, p, def):
		return ""
	for id: String in [ability_id, str(res["id"])]:
		var status := str(w.pack["abilities"][id]["status"])
		if (
			not status.begins_with("IMPLEMENTED")
			and not (id != ability_id and status == "CONDITION_LOCKED")
		):
			return "Not available in this build: " + str(w.pack["abilities"][id]["reason"])
	if not def.get("usableWhileControlled", false):
		if RpgAbilityRules.has_kind(p, "stasis"):
			return SILENT + "stasis"
		if RpgCombat.is_stunned(p):
			return "You are stunned!"
		if def["school"] != "physical" and (is_silenced(p) or is_locked_out(p, def["school"])):
			return "You are silenced!"
	# Blink While Casting: an instant marked usableWhileCasting (or Blink with the
	# blinkCast talent) slips through the busy guard and the GCD.
	var blink_through: bool = (
		not p["casting"].is_empty()
		and float(res["castTime"]) == 0.0
		and (
			def.get("usableWhileCasting", false)
			or (ability_id == "blink" and float(p["mods"]["global"]["blinkCast"]) > 0.0)
		)
	)
	if not p["casting"].is_empty() and not blink_through:
		if float(p["casting"]["remaining"]) <= CAST_QUEUE_WINDOW_SEC:
			p["queued_cast"] = ability_id
			return SILENT + "queued"
		return "You are busy."
	if not def.get("offGcd", false) and float(p["gcd"]) > 0.0 and not blink_through:
		if float(p["gcd"]) <= CAST_QUEUE_WINDOW_SEC:
			p["queued_cast"] = ability_id
		return SILENT + "gcd"
	var toggling_off := false
	if RpgAbilityRules.is_toggle_buff(w, def):
		for a: Dictionary in p["auras"]:
			toggling_off = toggling_off or a["id"] == ability_id
	var bonus := int(res.get("bonusCharges", 0))
	if (
		p["cooldowns"].has(ability_id)
		and not toggling_off
		and not RpgAbilityRules.has_charge(p, ability_id, bonus, float(res["cooldown"]))
		and not RpgMage.brain_freeze_bypasses(p, ability_id)
		and not RpgPaladinProcs.bypasses_cooldown(p, ability_id)
	):
		return "That ability is not ready yet."
	var free := (
		float(res["cost"]) > 0.0
		and (
			RpgAbilityRules.has_free_cost(p, ability_id)
			or RpgPaladinProcs.makes_free(p, ability_id)
		)
	)
	var cheap := RpgRogue.combine(
		RpgRogue.combine(
			RpgAbilityRules.next_cast_cheap_mult(p, ability_id), RpgRogue.dusk_cost_mult(p)
		),
		RpgRogue.detonator_free_mult(p, ability_id)
	)
	var cost := float(res["cost"]) if cheap < 0.0 else ceilf(float(res["cost"]) * cheap)
	cost = RpgShamanWar.mana_cost(p, cost)
	var payable := ceilf(cost * paladin_mana_mult(p)) if p["resource_type"] == "mana" else cost
	var shift := RpgForms.shift_kind(w, p, def)
	var pool := RpgForms.casting_pool(w, p, def)
	var entry_pool := RpgDruidKit.form_entry_pool(p, ability_id)
	if entry_pool >= 0.0:
		pool = entry_pool
	if pool < payable and not free and not toggling_off and shift == "":
		return _cost_error(str(p["resource_type"]))
	if def.get("requiresShield", false) and not RpgWorld.player_has_shield(w):
		return "You must have a shield equipped."
	if _effects_have(res, "charge") and RpgCombat.is_rooted(p):
		return "Can't move!"
	if def.get("requiresDodgeProc", false) and w.time > float(p.get("overpower_until", -1.0)):
		return "Your target must dodge first."
	if not RpgAbilityRules.has_required_aura(p, def):
		return "That ability is not ready yet."
	if def.get("spendsCombo", false) and not def.get("comboOptional", false):
		if int(p.get("combo_points", 0)) <= 0:
			return "That ability requires combo points."
	var form_error := RpgForms.cast_gate(w, p, def)
	if form_error != "":
		return form_error
	if (
		def.get("requiresStealth", false)
		and not res.get("ignoreStealthRequirement", false)
		and not RpgRogue.veil_allows_stealth_abilities(p)
		and not RpgRogue.gloam_bank_armed(p)
		and not RpgStealth.is_stealthed(p)
	):
		return "You must be stealthed."
	if def.get("requiresOutOfCombat", false) and p["in_combat"]:
		return "You can't do that while in combat."
	var target := {}
	var targeted := _resolve_target(w, def, res)
	if targeted.has("error"):
		return targeted["error"]
	target = targeted.get("target", {})
	var aim: Variant = _aim_point(w, def, p)
	if aim is String:
		return aim
	return _commit(w, res, target, aim, toggling_off, shift)


## castAbility's target resolution (friendly, then hostile), in its order.
static func _resolve_target(w: RpgEncounter, def: Dictionary, res: Dictionary) -> Dictionary:
	var p := w.player
	if not def.get("requiresTarget", false):
		return {}
	if def.get("targetsDead", false):
		# A combat resurrection: the street has no group, so no dead ally.
		return {"error": "You must target a dead ally in your group."}
	if def.get("targetType") == "friendly":
		# resolveFriendlyTarget: no friendly target held, so the caster.
		if _effects_have(res, "charge"):
			return {"error": "You must target an ally."}
		return {"target": p}
	var target := w.mob
	if w.mob.is_empty():
		target = RpgRogue.low_blow_fallback(w, p, def)
		if target.is_empty():
			var attacker := RpgWorld.nearest_attacking_mob(w)
			if not attacker.is_empty():
				RpgWorld.set_target(w, attacker)
			target = w.mob
	if target.is_empty() or target["dead"]:
		return {"error": "You have no target."}
	RpgWorld.face(w, target)
	var d := absf(float(target["x"]) - float(p["x"]))
	if d > w.player_attack_range(float(def["range"])):
		return {"error": "Out of range."}
	if def.get("targetType") != "any" and def.get("minRange") != null:
		if d < float(def["minRange"]):
			return {"error": "Too close!"}
	if def.get("targetType") != "any":
		var t := RpgAbilityRules.execute_threshold(def)
		if t >= 0.0 and RpgAbilityRules.execute_window_blocks(def, p, target):
			return {
				"error":
				(
					"That ability requires the target below %d%% health."
					% int(RpgTalents.js_round(t * 100.0))
				)
			}
		var gate := RpgClassGates.target_gate(w, p, def, res, target)
		if gate != "":
			return {"error": gate}
	return {"target": target}


## The aim point of a targetMode "position" ability with no cursor (castAbility's
## no-aim arm), clamped to range; null for any other ability; a String refusal.
static func _aim_point(w: RpgEncounter, def: Dictionary, p: Dictionary) -> Variant:
	if def.get("targetMode") != "position":
		return null
	var fallback := float(p["x"])
	if def["id"] in SELECTED_HOSTILE_AIM_FALLBACK and not w.mob.is_empty() and not w.mob["dead"]:
		fallback = float(w.mob["x"])
	var max_range := (
		float(def["range"])
		if float(def["range"]) > 0.0
		else float(w.pack["constants"]["melee_range"])
	)
	var dx := fallback - float(p["x"])
	var aim := fallback if absf(dx) <= max_range else float(p["x"]) + signf(dx) * max_range
	if def.get("minRange") != null and absf(aim - float(p["x"])) < float(def["minRange"]):
		aim = float(p["x"]) + float(p.get("facing", 1.0)) * float(def["minRange"])
	return aim


## The commit half of castAbility: queued swing, channel, cast bar or instant.
static func _commit(
	w: RpgEncounter,
	res: Dictionary,
	target: Dictionary,
	aim: Variant,
	toggling_off: bool,
	shift: String
) -> String:
	var p := w.player
	res = RpgMage.brain_freeze_override(w, p, res)
	res = RpgPaladinProcs.cast_overrides(w, p, res)
	res = _scale_natures_boon(p, res)
	var def: Dictionary = res["def"]
	var ability_id := str(def["id"])
	var cast_time := float(res["castTime"])
	var instant_aura := {}
	if not def.has("channel") and cast_time > 0.0 and def["school"] != "physical":
		instant_aura = RpgAbilityRules.consume_next_cast_instant(w, p, ability_id)
	if not instant_aura.is_empty():
		cast_time = 0.0
	else:
		cast_time *= RpgShamanWar.cast_time_mult(p, ability_id)
	if ability_id != "ghost_wolf":
		RpgShaman.break_ghost_wolf(w, p)
	var moving: bool = w.move_dir != 0 and not RpgCombat.is_rooted(p)
	if (
		(def.get("channel") != null or (cast_time > 0.0 and not toggling_off))
		and moving
		and not def.get("castWhileMoving", false)
		and not res.get("castWhileMoving", false)
		and RpgMage.ice_floes_for(p, ability_id).is_empty()
		and not RpgAbilityRules.has_kind(p, "processional_grace")
	):
		return "You can't cast while moving."
	RpgForms.before_commit(w, p, def, shift)
	var gcd := gcd_for(w, p)
	p["cast_aim"] = aim
	if def.get("onNextSwing", false):
		var off: bool = p.get("queued_on_swing", "") == ability_id
		p["queued_on_swing"] = "" if off else ability_id
		p["queued_on_swing_free"] = (
			not off
			and float(res["cost"]) > 0.0
			and RpgAbilityRules.has_free_cost(p, ability_id)
			and RpgAbilityRules.consume_free_cost(w, p, ability_id)
		)
		if not p["auto_attack"] and not target.is_empty():
			w.command({"op": "attack"})
		return ""
	var resolved := res.duplicate()
	if instant_aura.get("id", "") == RpgShamanWar.STORMCAST_ID:
		# The Stormcast reservation: given back if the cast is refused or resisted.
		resolved["stormcast"] = [instant_aura.duplicate()]
		var cheap_aura := RpgAbilityRules.find_kind(p, "next_cast_cheap")
		if cheap_aura.get("id", "") == RpgShamanWar.STORMCAST_CHEAP_ID:
			resolved["stormcast"].append(cheap_aura.duplicate())
	if (cast_time == 0.0 or def.get("channel") != null) and not toggling_off:
		if float(res["cost"]) > 0.0 and RpgAbilityRules.has_free_cost(p, ability_id):
			if RpgAbilityRules.consume_free_cost(w, p, ability_id):
				resolved["cost"] = 0.0
				resolved["free_cast"] = true
		elif float(res["cost"]) > 0.0:
			var cheap := RpgAbilityRules.consume_next_cast_cheap(w, p, ability_id)
			if cheap >= 0.0:
				resolved["cost"] = ceilf(float(res["cost"]) * cheap)
			var dusk := RpgRogue.combine(
				RpgRogue.dusk_cost_mult(p), RpgRogue.detonator_free_mult(p, ability_id)
			)
			if dusk >= 0.0:
				resolved["cost"] = ceilf(float(resolved["cost"]) * dusk)
	if def.get("channel") != null:
		if float(resolved["cost"]) > 0.0 and p["resource_type"] == "mana":
			resolved["cost"] = ceilf(float(resolved["cost"]) * paladin_mana_mult(p))
		_spend_cost(w, p, resolved)
		_arm_cooldown(p, resolved, toggling_off)
		var ch: Dictionary = def["channel"]
		var duration := float(ch["duration"]) / spell_haste_mult(p)
		var every := duration / float(ch["ticks"])
		p["casting"] = {
			"ability": ability_id,
			"remaining": duration,
			"total": duration,
			"target": target,
			"channel": true,
			"tick_every": every,
			"tick_timer": every,
			"ticks_left": int(ch["ticks"]),
		}
		p["gcd"] = maxf(float(p["gcd"]), gcd)
		w.log_event({"type": "cast_start", "ability": ability_id, "time": duration})
		RpgPaladinKit.aegis_sync(w, p, resolved)
		RpgTalentProcs.on_cast_completed(w, p, ability_id, target)
		return ""
	if cast_time > 0.0 and not toggling_off:
		RpgPaladinProcs.reserve_resonance(p, ability_id, true)
		var stretched := cast_time / spell_haste_mult(p)
		p["casting"] = {
			"ability": ability_id, "remaining": stretched, "total": stretched, "target": target
		}
		p["gcd"] = maxf(float(p["gcd"]), gcd)
		w.log_event({"type": "cast_start", "ability": ability_id, "time": stretched})
		return ""
	if not def.get("offGcd", false):
		p["gcd"] = maxf(float(p["gcd"]), gcd)
	var out := apply_ability(w, resolved, target, toggling_off)
	p["cast_aim"] = null
	return out


## updateCasting: the bar runs down (a channel ticks); at the end the ability
## applies, then a queued cast fires. Stun, silence or a lost target cancel it.
static func update_casting(w: RpgEncounter) -> void:
	var p := w.player
	if p["casting"].is_empty():
		if str(p.get("queued_cast", "")) != "":
			_fire_queued(w)
		return
	var c: Dictionary = p["casting"]
	if RpgCombat.is_stunned(p):
		cancel_cast(w)
		return
	var res := w.known_entry(str(c["ability"]))
	if not res.is_empty() and res["def"]["school"] != "physical":
		if is_silenced(p) or is_locked_out(p, str(res["def"]["school"])):
			cancel_cast(w)
			return
	if (
		not c.get("channel", false)
		and not res.is_empty()
		and res["def"].get("requiresTarget", false)
		and res["def"].get("targetType") != "friendly"
	):
		var live: Dictionary = c["target"]
		if live.is_empty() or live["dead"]:
			cancel_cast(w)
			w.log_event({"type": "error", "text": "You have no target."})
			return
	c["remaining"] = float(c["remaining"]) - w.dt
	if c.get("channel", false):
		_update_channel(w, c, res)
		return
	if float(c["remaining"]) > CAST_COMPLETE_EPS:
		return
	p["casting"] = {}
	w.log_event({"type": "cast_stop", "ability": c["ability"], "success": true})
	var floes := RpgMage.ice_floes_for(p, str(c["ability"]))
	if not floes.is_empty():
		floes["value"] = float(floes["value"]) - 1.0
		if float(floes["value"]) <= 0.0:
			RpgAbilityRules.remove_aura(w, p, floes)
	if not res.is_empty():
		var refusal := apply_ability(w, res, c["target"])
		if refusal != "":
			w.log_event({"type": "error", "text": refusal})
	p["cast_aim"] = null
	_fire_queued(w)


static func _update_channel(w: RpgEncounter, c: Dictionary, res: Dictionary) -> void:
	var p := w.player
	RpgPaladinKit.aegis_sync(w, p, res)
	c["tick_timer"] = float(c["tick_timer"]) - w.dt
	if float(c["tick_timer"]) <= 0.0:
		c["tick_timer"] = float(c["tick_timer"]) + float(c["tick_every"])
		if int(c["ticks_left"]) > 0:
			c["ticks_left"] = int(c["ticks_left"]) - 1
		if not res.is_empty():
			RpgChannel.tick(w, p, res, c)
	if p["casting"] != c:
		return
	if float(c["remaining"]) <= CAST_COMPLETE_EPS:
		while int(c["ticks_left"]) > 0 and float(c["tick_timer"]) <= CAST_COMPLETE_EPS:
			c["ticks_left"] = int(c["ticks_left"]) - 1
			c["tick_timer"] = float(c["tick_timer"]) + float(c["tick_every"])
			if not res.is_empty():
				RpgChannel.tick(w, p, res, c)
		RpgPaladinKit.aegis_complete(w, p, res)
		p["casting"] = {}
		p["cast_aim"] = null
		w.log_event({"type": "cast_stop", "ability": c["ability"], "success": true})
		_fire_queued(w)


## fireQueuedCast: a GCD-held press waits for the GCD.
static func _fire_queued(w: RpgEncounter) -> void:
	var queued := str(w.player.get("queued_cast", ""))
	if queued == "":
		return
	var res := w.known_entry(queued)
	if not res.is_empty() and not res["def"].get("offGcd", false) and float(w.player["gcd"]) > 0.0:
		return
	w.player.erase("queued_cast")
	w.command({"op": "cast", "ability": queued})


## cancelCast.
static func cancel_cast(w: RpgEncounter) -> void:
	var p := w.player
	if p["casting"].is_empty():
		return
	var id := str(p["casting"]["ability"])
	if p["casting"].get("channel", false):
		RpgPaladinKit.aegis_cleanup(w, p)
	p["casting"] = {}
	RpgPaladinProcs.reserve_resonance(p, id, false)
	p["cast_aim"] = null
	p.erase("queued_cast")
	w.log_event({"type": "cast_stop", "ability": id, "success": false})


## pushbackCast: a cast bar loses CAST_PUSHBACK_SEC; a channel loses a quarter of
## its length and the ticks that no longer fit.
static func pushback(p: Dictionary) -> void:
	if p["casting"].is_empty():
		return
	if RpgAbilityRules.has_kind(p, "cast_shield"):
		return
	if str(p["casting"].get("ability", "")) == "ghost_wolf":
		return
	var c: Dictionary = p["casting"]
	var factor := 1.0 - float(p.get("cast_pushback_reduction", 0.0))
	if factor <= 0.0:
		return
	if c.get("channel", false):
		c["remaining"] = maxf(
			0.0, float(c["remaining"]) - float(c["total"]) * CHANNEL_PUSHBACK_FRACTION * factor
		)
		if int(c["ticks_left"]) > 0 and float(c["tick_every"]) > 0.0:
			var room := float(c["remaining"]) - float(c["tick_timer"]) + CAST_COMPLETE_EPS
			var fit := 0 if room < 0.0 else int(floorf(room / float(c["tick_every"]))) + 1
			c["ticks_left"] = mini(int(c["ticks_left"]), fit)
		return
	c["remaining"] = float(c["remaining"]) + CAST_PUSHBACK_SEC * factor
	c["total"] = float(c["total"]) + CAST_PUSHBACK_SEC * factor


## applyAbility: the target re-checked (range + 2), the cost re-checked, then billing,
## the cooldown, and the effects: at once for a friendly or physical ability, on a
## projectile for a spell (with the hostile spell resist roll on arrival).
static func apply_ability(
	w: RpgEncounter, res: Dictionary, target: Dictionary, toggling_off := false
) -> String:
	var p := w.player
	var def: Dictionary = res["def"]
	var friendly: bool = def.get("targetType") == "friendly"
	if def.get("requiresTarget", false) and not friendly:
		if target.is_empty() or target["dead"]:
			return "You have no target."
		if (
			absf(float(target["x"]) - float(p["x"]))
			> w.player_attack_range(float(def["range"])) + 2.0
		):
			return "Out of range."
	var resolved := _cost_tail(w, p, RpgMage.consume_overload(w, p, res.duplicate()), toggling_off)
	var cost := float(resolved["cost"])
	if float(p["resource"]) < cost and not toggling_off and RpgForms.shift_kind(w, p, def) == "":
		if not resolved.get("free_cast", false):
			return "Not enough %s!" % p["resource_type"]
	if def.get("spendsAllResource", false) and not toggling_off:
		var cap: Variant = def.get("spendResourceCap")
		var spend := float(p["resource"]) if cap == null else minf(float(p["resource"]), float(cap))
		resolved["cost"] = spend
	if def.get("requiresAuraKind") != null and def.get("consumesRequiredAura", true) != false:
		if not RpgAbilityRules.consume_required_aura(w, p, def):
			_restore_stormcast(w, p, resolved)
			return "That ability is not ready yet."
	if def["id"] == "unleash_weapon":
		var unleash := RpgShamanKit.unleash_error(w, p, target)
		if unleash != "":
			_restore_stormcast(w, p, resolved)
			return unleash
	var mana_before := float(p["resource"]) if p["resource_type"] == "mana" else 0.0
	_spend_cost(w, p, resolved)
	if p["resource_type"] == "mana":
		RpgShamanWar.on_mana_spent(
			w, p, maxf(0.0, mana_before - float(p["resource"])), float(res["cost"]) > 0.0
		)
	_arm_cooldown(p, resolved, toggling_off)
	if friendly:
		RpgEffects.run(w, p, target, resolved)
		if resolved.has("stormcast"):
			RpgShamanWar.on_stormcast_consumed(w, p)
		RpgTalentProcs.on_cast_completed(w, p, str(def["id"]), target)
		return ""
	var fires_projectile: bool = (
		def["projectile"] if def.get("projectile") != null else def["school"] != "physical"
	)
	resolved = RpgPriest.reserve_stilled_mind(w, p, resolved)
	var is_taunt := _effects_have(resolved, "taunt")
	if not target.is_empty() and fires_projectile:
		var is_spell: bool = def["school"] != "physical"
		w.schedule_projectile(
			func(src: Dictionary, tgt: Dictionary) -> void:
				if is_spell and not is_taunt and RpgCombat.spell_resisted(w, src, tgt):
					_log_resist(w, src, tgt, def)
					_restore_stormcast(w, src, resolved)
					return
				RpgEffects.run(w, src, tgt, resolved, not is_spell)
				if resolved.has("stormcast"):
					RpgShamanWar.on_stormcast_consumed(w, src)
		)
		RpgTalentProcs.on_cast_completed(w, p, str(def["id"]), target)
		return ""
	var resisted: bool = (
		not target.is_empty()
		and target["kind"] == "mob"
		and def["school"] != "physical"
		and not is_taunt
		and RpgCombat.spell_resisted(w, p, target)
	)
	if resisted:
		_log_resist(w, p, target, def)
		_restore_stormcast(w, p, resolved)
	else:
		RpgEffects.run(w, p, target, resolved)
		if resolved.has("stormcast"):
			RpgShamanWar.on_stormcast_consumed(w, p)
	if not toggling_off:
		RpgTalentProcs.on_cast_completed(w, p, str(def["id"]), target)
	return ""


## scaleNaturesBoonPower: an armed boon scales its spell's numbers (a heal, hot or
## Spore Burst takes the whole multiplier in runEffects through natures_boon_power).
static func _scale_natures_boon(p: Dictionary, res: Dictionary) -> Dictionary:
	var amp := RpgDruidEngine.boon_power(p, str(res["def"]["id"]))
	if amp == 1.0:
		return res
	var out := res.duplicate()
	var effects: Array = []
	for e: Dictionary in res["effects"]:
		if e["type"] in ["heal", "hot", "sporeBurst"]:
			effects.append(e)
			continue
		var scaled := e.duplicate(true)
		for key: String in ["min", "max", "amount", "total", "value"]:
			if scaled.get(key) is float or scaled.get(key) is int:
				if float(scaled[key]) > 0.0:
					scaled[key] = float(RpgTalents.js_round(float(scaled[key]) * amp))
		effects.append(scaled)
	out["effects"] = effects
	out["natures_boon_power"] = amp
	return out


## applyAbility's cost tail for every billed cast: a free charge (a cast-time spell's
## is consumed here), else the cheap charge (Radiant Resonance's Dawn's Embrace),
## then the paladin's mana-grace discount.
static func _cost_tail(
	w: RpgEncounter, p: Dictionary, res: Dictionary, toggling_off: bool
) -> Dictionary:
	var id := str(res["def"]["id"])
	if not toggling_off and float(res["cost"]) > 0.0 and not res.has("stormcast"):
		if RpgAbilityRules.has_free_cost(p, id) and RpgAbilityRules.consume_free_cost(w, p, id):
			res["cost"] = 0.0
			res["free_cast"] = true
			RpgPaladinProcs.resonance_cheap(w, p, id, true)
		else:
			var cheap := RpgAbilityRules.consume_next_cast_cheap(w, p, id)
			if cheap >= 0.0:
				res["cost"] = ceilf(float(res["cost"]) * cheap)
	var mana: bool = p["resource_type"] == "mana"
	res["cost"] = RpgShamanWar.mana_cost(p, float(res["cost"]))
	if float(res["cost"]) > 0.0 and mana and not res["def"].get("spendsAllResource", false):
		res["cost"] = ceilf(float(res["cost"]) * paladin_mana_mult(p))
	RpgPaladinProcs.reserve_resonance(p, id, false)
	return res


## restoreStormcastReservation: a refused or resisted Stormcast cast gets it back.
static func _restore_stormcast(w: RpgEncounter, p: Dictionary, res: Dictionary) -> void:
	if not res.has("stormcast") or p["dead"]:
		return
	for a: Dictionary in res["stormcast"]:
		if not RpgAbilityRules.has_id(p, str(a["id"])):
			RpgCombat.apply_aura(w, p, a.duplicate())


static func _log_resist(w: RpgEncounter, src: Dictionary, tgt: Dictionary, def: Dictionary) -> void:
	w.log_event(
		{
			"type": "damage",
			"source": src["id"],
			"target": tgt["id"],
			"amount": 0,
			"kind": "resist",
			"ability": def["name"]
		}
	)
	w.enter_combat(src, tgt)


## armAbilityCooldownWithReflection (the warlock reflection joins with that class).
static func _arm_cooldown(p: Dictionary, res: Dictionary, toggling_off: bool) -> void:
	RpgAbilityRules.arm_cooldown(
		p,
		str(res.get("cooldownId", res["id"])),
		float(res["cooldown"]),
		toggling_off,
		int(res.get("bonusCharges", 0))
	)


## spendAbilityCost: a toggle going off is free; a form shift bills the parked mana;
## mana spending restarts the five-second rule; spent rage feeds Colossal Might.
static func _spend_cost(w: RpgEncounter, p: Dictionary, res: Dictionary) -> void:
	var def: Dictionary = res["def"]
	if RpgAbilityRules.is_toggle_buff(w, def):
		for a: Dictionary in p["auras"]:
			if a["id"] == def["id"]:
				return
	var cost := float(res["cost"])
	var shift := RpgForms.shift_kind(w, p, def)
	if shift == "off":
		return
	if shift == "cross":
		RpgForms.spend_cross(p, cost)
		return
	var spent_rage := cost if p["resource_type"] == "rage" else 0.0
	spend(p, cost)
	RpgMage.overflowing_power_cdr(w, p, cost)
	RpgAbilityRules.rage_spend_refund(w, p, spent_rage)


## spendResource (mana spending restarts the five-second rule).
static func spend(p: Dictionary, cost: float) -> void:
	p["resource"] = maxf(0.0, float(p["resource"]) - cost)
	if p["resource_type"] == "mana" and cost > 0.0:
		p["five_second_rule"] = 0.0


## cancelStasisToggle: pressing Ice Block again ends its stasis (and its absorb).
static func _cancel_stasis_toggle(w: RpgEncounter, p: Dictionary, def: Dictionary) -> bool:
	var toggle := false
	for e: Dictionary in def.get("effects", []):
		toggle = toggle or (e["type"] == "selfBuff" and e["kind"] == "stasis")
	if not toggle:
		return false
	var worn := false
	for a: Dictionary in p["auras"]:
		if (
			a["id"] == def["id"]
			and a["source_id"] == p["id"]
			and not a.get("unbreakable_control", false)
		):
			worn = true
	if not worn:
		return false
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if (a["id"] == def["id"] or a["id"] == def["id"] + "_absorb") and a["source_id"] == p["id"]:
			RpgAbilityRules.remove_aura(w, p, a)
	return true
