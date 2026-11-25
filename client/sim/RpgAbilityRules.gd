class_name RpgAbilityRules
extends RefCounted
## Shared ability mechanics of World of ClaudeCraft (d2b91e08), each a port of the
## reference function named on it. `w` is the RpgEncounter; units are its
## dictionaries. Geometry is the street's one axis (docs/SKILLS_PORT.md, ADAPTED):
## a circle of radius r around x is [x - r, x + r]; "in front" is on the side the
## unit faces (`facing`, +1 or -1); a point closer than FACING_HOLD_DIST counts as
## in front.

const FACING_HOLD_DIST := 0.1
## empower_next.ts EMPOWER_CAST_KINDS, BATTLE_TRANCE_ABILITIES, REVENGE_FREE_ABILITIES.
const EMPOWER_CAST_KINDS: Array[String] = [
	"next_cast_free", "next_execute_free", "next_cast_instant", "next_cast_cheap"
]
const BATTLE_TRANCE_ABILITIES: Array[String] = ["heroic_strike", "mortal_strike"]
const REVENGE_FREE_ABILITIES: Array[String] = ["revenge"]
const SHAMAN_SHOCKS: Array[String] = ["earth_shock", "flame_shock", "frost_shock"]
## sim.ts isControlAura.
const CONTROL_KINDS: Array[String] = ["stun", "root", "incapacitate", "polymorph"]

# -- geometry (ctx.hostilesInRadius, normAngle/angleTo against MELEE_ARC) ------------


## Living hostiles of `source` within `radius` of `center` (the street's mobs for the
## player; the player for a mob), nearest first as the spatial query returns them.
static func hostiles_in_radius(
	w: RpgEncounter, source: Dictionary, center: float, radius: float
) -> Array:
	var out: Array = []
	var pool: Array = w.mobs if source["kind"] == "player" else [w.player]
	for u: Dictionary in pool:
		if u["dead"]:
			continue
		if absf(float(u["x"]) - center) <= radius:
			out.append(u)
	out.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return absf(float(a["x"]) - center) < absf(float(b["x"]) - center)
	)
	return out


## Whether `other` stands in `u`'s frontal arc (on the faced side, or overlapping).
static func in_front(u: Dictionary, other: Dictionary) -> bool:
	var dx := float(other["x"]) - float(u["x"])
	if absf(dx) < FACING_HOLD_DIST:
		return true
	return signf(dx) == float(u.get("facing", 1.0))


# -- aura helpers (empower_next.ts, sure_crit.ts, area_echo.ts, required_aura.ts) ----


static func has_id(u: Dictionary, id: String) -> bool:
	for a: Dictionary in u["auras"]:
		if a["id"] == id:
			return true
	return false


static func has_kind(u: Dictionary, kind: String) -> bool:
	for a: Dictionary in u["auras"]:
		if a["kind"] == kind:
			return true
	return false


static func find_kind(u: Dictionary, kind: String) -> Dictionary:
	for a: Dictionary in u["auras"]:
		if a["kind"] == kind:
			return a
	return {}


static func _matches(aura: Dictionary, ability_id: String) -> bool:
	if aura.get("empower_abilities") == null:
		return true
	return ability_id != "" and ability_id in aura["empower_abilities"]


static func remove_aura(w: RpgEncounter, u: Dictionary, aura: Dictionary) -> void:
	var i := (u["auras"] as Array).find(aura)
	if i < 0:
		return
	u["auras"].remove_at(i)
	w.log_event({"type": "aura", "target": u["id"], "name": aura["id"], "gained": false})


## consumeAuraKind: a charged aura loses one charge; otherwise it goes.
static func consume_aura_kind(
	w: RpgEncounter, u: Dictionary, kind: String, ability_id := ""
) -> Dictionary:
	for a: Dictionary in u["auras"]:
		if a["kind"] != kind or not _matches(a, ability_id):
			continue
		if kind in EMPOWER_CAST_KINDS:
			u["cast_consumed_empower"] = true
		if int(a.get("charges", 1)) > 1:
			a["charges"] = int(a.get("charges", 1)) - 1
			return a
		remove_aura(w, u, a)
		return a
	return {}


## freeCostAuraActive / hasFreeCostFor.
static func has_free_cost(u: Dictionary, ability_id: String) -> bool:
	for a: Dictionary in u["auras"]:
		var k := str(a["kind"])
		if k in ["next_cast_free", "next_execute_free"] and _matches(a, ability_id):
			return true
		if k == "battle_trance" and ability_id in BATTLE_TRANCE_ABILITIES:
			return true
		if k == "revenge_free" and ability_id in REVENGE_FREE_ABILITIES:
			return true
		if k == "sudden_death" and ability_id == "execute":
			return true
	return false


## consumeFreeCostFor.
static func consume_free_cost(w: RpgEncounter, u: Dictionary, ability_id: String) -> bool:
	if not consume_aura_kind(w, u, "next_cast_free", ability_id).is_empty():
		return true
	if not consume_aura_kind(w, u, "next_execute_free", ability_id).is_empty():
		return true
	if ability_id in BATTLE_TRANCE_ABILITIES:
		if not consume_aura_kind(w, u, "battle_trance").is_empty():
			return true
	if ability_id == "execute" and not consume_aura_kind(w, u, "sudden_death").is_empty():
		return true
	return (
		ability_id in REVENGE_FREE_ABILITIES
		and not consume_aura_kind(w, u, "revenge_free").is_empty()
	)


## nextCastCheapMultiplier: the next_cast_cheap aura's value, or -1 (none).
static func next_cast_cheap_mult(u: Dictionary, ability_id: String) -> float:
	if (
		ability_id == "dawns_embrace"
		and (
			u.get("cast_radiant_resonance", false)
			or has_kind(u, RpgPaladinProcs.RADIANT_RESONANCE_KIND)
		)
	):
		return RpgPaladinProcs.RADIANT_RESONANCE_DAWN_COST_MULT
	for a: Dictionary in u["auras"]:
		if a["kind"] == "next_cast_cheap" and _matches(a, ability_id):
			return float(a["value"])
	return -1.0


static func consume_next_cast_cheap(w: RpgEncounter, u: Dictionary, ability_id: String) -> float:
	var resonance := RpgPaladinProcs.resonance_cheap(w, u, ability_id, true)
	if resonance >= 0.0:
		return resonance
	var a := consume_aura_kind(w, u, "next_cast_cheap", ability_id)
	return -1.0 if a.is_empty() else float(a["value"])


static func consume_next_cast_instant(
	w: RpgEncounter, u: Dictionary, ability_id: String
) -> Dictionary:
	var instant := consume_aura_kind(w, u, "next_cast_instant", ability_id)
	if instant.is_empty():
		return RpgPaladinProcs.consume_resonance_instant(w, u, ability_id)
	return instant


## consumeNextAttackCrit.
static func consume_next_attack_crit(w: RpgEncounter, u: Dictionary) -> bool:
	return not consume_aura_kind(w, u, "next_attack_crit").is_empty()


## consumeSureCritCharge / consumeAreaEchoCharge.
static func consume_charge_of_kind(w: RpgEncounter, u: Dictionary, kind: String) -> void:
	var a := find_kind(u, kind)
	if a.is_empty():
		return
	var left := int(a.get("charges", 1)) - 1
	if left <= 0:
		remove_aura(w, u, a)
	else:
		a["charges"] = left


## abilityQualifiesForAreaEcho.
static func qualifies_for_area_echo(effects: Array) -> bool:
	var single := false
	for e: Dictionary in effects:
		if e["type"] in ["weaponStrike", "directDamage"]:
			single = true
		if e["type"] in ["aoeDamage", "aoeRoot", "groundAoE"]:
			return false
	return single


## replayDamage (echoAreaDamage / sweepStrikeDamage): `amount` x mult on up to
## `max_targets` other hostiles within AOE_ECHO_RADIUS of the primary target.
static func replay_damage(
	w: RpgEncounter,
	source: Dictionary,
	primary: Dictionary,
	amount: int,
	mult: float,
	max_targets: int,
	school: String,
	ability_name: String
) -> void:
	var c: Dictionary = w.pack["constants"]
	var replayed := maxi(1, int(RpgTalents.js_round(amount * mult)))
	var hits := 0
	var near := hostiles_in_radius(w, source, float(primary["x"]), float(c["aoe_echo_radius"]))
	for h: Dictionary in near:
		if h["id"] == primary["id"]:
			continue
		RpgCombat.deal_damage(w, source, h, replayed, false, school, ability_name, "hit")
		hits += 1
		if hits >= max_targets:
			return


## hasRequiredAura / consumeRequiredAura.
static func _required_aura(u: Dictionary, def: Dictionary) -> Dictionary:
	for a: Dictionary in u["auras"]:
		if a["kind"] != def.get("requiresAuraKind"):
			continue
		if def.get("requiresOwnAura", false) and a["source_id"] != u["id"]:
			continue
		if int(a.get("stacks", 1)) >= int(def.get("requiresAuraStacks", 1)):
			return a
	return {}


static func has_required_aura(u: Dictionary, def: Dictionary) -> bool:
	return def.get("requiresAuraKind") == null or not _required_aura(u, def).is_empty()


static func consume_required_aura(w: RpgEncounter, u: Dictionary, def: Dictionary) -> bool:
	if def.get("requiresAuraKind") == null:
		return true
	var cost: Variant = def.get("consumesRequiredAuraStacks")
	if cost == null:
		consume_aura_kind(w, u, str(def["requiresAuraKind"]))
		return true
	var a := _required_aura(u, def)
	if a.is_empty() or int(a.get("stacks", 1)) < int(cost):
		return false
	a["stacks"] = int(a.get("stacks", 1)) - int(cost)
	if int(a["stacks"]) == 0:
		u["auras"].erase(a)
	w.log_event({"type": "aura", "target": u["id"], "name": a["id"], "gained": a["stacks"] > 0})
	return true


## execute_threshold.ts executeWindowThreshold / executeWindowBlocksCast (the paladin
## windows join with that class's port).
static func execute_threshold(def: Dictionary) -> float:
	if def.get("executeThreshold") != null:
		return float(def["executeThreshold"])
	if def.get("requiresTargetHpBelow") != null:
		return float(def["requiresTargetHpBelow"])
	return -1.0


static func execute_window_blocks(def: Dictionary, caster: Dictionary, target: Dictionary) -> bool:
	var t := execute_threshold(def)
	if t < 0.0:
		return false
	var hp := float(target["hp"])
	var max_hp := float(target["max_hp"])
	var outside := hp >= max_hp * t if def.get("executeThreshold") != null else hp > max_hp * t
	if not outside:
		return false
	if RpgPaladin.execute_bypassed(caster, str(def["id"])):
		return false
	return not (def["id"] == "execute" and has_kind(caster, "sudden_death"))


## toggle_buff.ts isToggleBuff.
static func is_toggle_buff(w: RpgEncounter, def: Dictionary) -> bool:
	if def["id"] == "ghost_wolf":
		return true
	var forms: Array = w.pack["constants"]["form_aura_kinds"]
	for e: Dictionary in def.get("effects", []):
		if e["type"] != "selfBuff":
			continue
		var k := str(e["kind"])
		if k in forms or k in ["defensive_stance", "stealth", "stasis"]:
			return true
		if e.get("healthDrainPctMax") != null:
			return true
	return false


# -- charges and cooldowns (casting_lifecycle.ts chargeState, armAbilityCooldown,
#    auras.ts updateTimers) ------------------------------------------------------------


static func charge_state(u: Dictionary, id: String, bonus: int, cooldown: float) -> Dictionary:
	if bonus <= 0 or cooldown <= 0.0:
		return {}
	if not u.has("ability_charges"):
		u["ability_charges"] = {}
	var max_charges := 1 + maxi(0, bonus)
	var existing: Dictionary = u["ability_charges"].get(id, {})
	if (
		not existing.is_empty()
		and int(existing["max"]) == max_charges
		and float(existing["length"]) == cooldown
	):
		return existing
	var s: Dictionary = (
		existing
		if not existing.is_empty()
		else {"charges": max_charges, "max": max_charges, "recharges": [], "length": cooldown}
	)
	s["max"] = max_charges
	s["length"] = cooldown
	s["charges"] = mini(maxi(int(s["charges"]), 0), max_charges)
	var rech: Array = s["recharges"]
	rech.sort()
	var missing := max_charges - int(s["charges"])
	while rech.size() > missing:
		rech.pop_back()
	while rech.size() < missing:
		rech.append(cooldown)
	if int(s["charges"]) <= 0 and not rech.is_empty():
		u["cooldowns"][id] = rech[0]
	u["ability_charges"][id] = s
	return s


static func has_charge(u: Dictionary, id: String, bonus: int, cooldown: float) -> bool:
	var s := charge_state(u, id, bonus, cooldown)
	return not s.is_empty() and int(s["charges"]) > 0


## armAbilityCooldown.
static func arm_cooldown(
	u: Dictionary, id: String, cooldown: float, toggling_off := false, bonus := 0
) -> void:
	if cooldown <= 0.0 or toggling_off:
		return
	var s := charge_state(u, id, bonus, cooldown)
	if not s.is_empty():
		s["charges"] = maxi(0, int(s["charges"]) - 1)
		s["recharges"].append(cooldown)
		s["recharges"].sort()
		if int(s["charges"]) <= 0:
			u["cooldowns"][id] = s["recharges"][0]
		else:
			u["cooldowns"].erase(id)
		return
	# ability_cooldown_groups.ts: the shaman's three shocks share one cooldown.
	if id in SHAMAN_SHOCKS:
		for shock: String in SHAMAN_SHOCKS:
			u["cooldowns"][shock] = cooldown
		return
	u["cooldowns"][id] = cooldown


## updateTimers' charge lap: every running recharge ticks at once.
static func tick_charges(u: Dictionary, dt: float) -> void:
	if not u.has("ability_charges"):
		return
	for id: String in u["ability_charges"]:
		var s: Dictionary = u["ability_charges"][id]
		if int(s["charges"]) >= int(s["max"]):
			continue
		var rech: Array = s["recharges"]
		var rate := 2.0 if id == "tidecall" and has_id(u, "shaman_primal_exaltation") else 1.0
		for i in rech.size():
			rech[i] = float(rech[i]) - dt * rate
		while not rech.is_empty() and float(rech[0]) <= 0.0:
			rech.pop_front()
			s["charges"] = mini(int(s["max"]), int(s["charges"]) + 1)
		if int(s["charges"]) >= int(s["max"]) or rech.is_empty():
			s["recharges"] = []
			if int(s["charges"]) > 0:
				u["cooldowns"].erase(id)
			continue
		if int(s["charges"]) <= 0:
			u["cooldowns"][id] = rech[0]


## applyRageSpendCooldownRefund (Colossal Might).
static func rage_spend_refund(w: RpgEncounter, p: Dictionary, spent: float) -> void:
	var rate := float(p["mods"]["global"]["cdrPerRage"])
	if spent <= 0.0 or rate <= 0.0:
		return
	var c: Dictionary = w.pack["constants"]
	var cap := {}
	for a: Dictionary in p["auras"]:
		if a["id"] == "colossal_might_cap":
			cap = a
	var used := 0.0 if cap.is_empty() else float(cap["value"])
	var refund := minf(spent * rate, float(c["colossal_might_cap_seconds"]) - used)
	if refund <= 0.0:
		return
	if not cap.is_empty():
		cap["value"] = float(cap["value"]) + refund
	else:
		var window := float(c["colossal_might_cap_window"])
		(
			RpgCombat
			. apply_aura(
				w,
				p,
				{
					"id": "colossal_might_cap",
					"kind": "internal_cd",
					"value": refund,
					"remaining": window,
					"duration": window,
					"source_id": p["id"],
					"school": "physical",
				}
			)
		)
	for id: String in c["colossal_might_cooldowns"]:
		if not p["cooldowns"].has(id):
			continue
		var cur := float(p["cooldowns"][id])
		if cur <= refund:
			p["cooldowns"].erase(id)
		else:
			p["cooldowns"][id] = cur - refund
