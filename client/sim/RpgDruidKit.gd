class_name RpgDruidKit
extends RefCounted
## The druid's effect arms and kit rules: Faerie Fire, Feral Charge, Spore Burst
## (combat/druid_spore_burst.ts), Swiftmend's consumeAura, Overbloom, Marrowbreak's
## guard, Typhoon's knockback, the form-entry presses (druid_form_entry.ts), Lunge
## (druid_lunge.ts) and the Bruin Rush window refresh (druid_rush_window.ts).
## ADAPTED for the street: a knockback moves the monster `distance` along the axis
## away from the druid at once (the reference flies it on an arc).

const FORM_ENTRY := {"prowl": "cat", "lunge": "cat", "dash": "cat", "bear_charge": "bear"}
const FORM_ABILITY := {"bear": "bear_form", "cat": "cat_form"}
const SPORE_BURST_FULL_BANK_POWER := 1.25
const LUNGE_PENDING_ID := "lunge_pending"
const LUNGE_WEAPON_MULT := 0.6
const LUNGE_PENDING_SECONDS := 3.0


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _aura(
	p: Dictionary, id: String, kind: String, dur: float, value: float, school: String
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": dur,
		"duration": dur,
		"value": value,
		"source_id": p["id"],
		"school": school,
	}


## The arms runEffects routes here. False when `eff` is not a druid arm.
static func run_arm(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> bool:
	var def: Dictionary = res["def"]
	match str(eff["type"]):
		"faerieFire":
			if not target.is_empty() and not target["dead"]:
				var ff := _aura(
					p, str(def["id"]), "faerie_fire", float(eff["duration"]), 0.0, def["school"]
				)
				RpgCombat.apply_aura(w, target, ff)
				w.enter_combat(p, target)
		"feralCharge":
			if RpgAbilityRules.has_kind(p, "form_cat"):
				var fi := _aura(
					p, "feral_instinct_energy", "buff_energyregen", 10.0, 1.0, def["school"]
				)
				RpgCombat.apply_aura(w, p, fi)
			elif RpgAbilityRules.has_kind(p, "form_bear") and p["resource_type"] == "rage":
				p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + 50.0)
		"sporeBurst":
			_plant_spore_burst(w, p, res, eff, ctx)
		"consumeAura":
			_consume_aura(w, p, target, res, eff, ctx)
		"druidOverbloom":
			RpgDruidEngine.overbloom(
				w, p, target if not target.is_empty() else p, float(eff["harvestPct"])
			)
		"druidMarrowbreakGuard":
			if marrowbreak_guarded(p, float(eff["belowFrac"])):
				var mult := RpgDruidEngine.apex_payoff_mult(p, str(def["id"]))
				var heal := _jr(int(p["max_hp"]) * float(eff["healPctMaxHp"]) * mult)
				RpgCombat.apply_heal(w, p, p, heal, false)
				if p["resource_type"] == "rage":
					p["resource"] = minf(
						float(p["max_resource"]), float(p["resource"]) + float(eff["rage"])
					)
		"aoeKnockback":
			for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
				w, p, float(p["x"]), float(eff["radius"])
			):
				var away := signf(float(m["x"]) - float(p["x"]))
				if away == 0.0:
					away = float(p.get("facing", 1.0))
				m["x"] = clampf(
					float(m["x"]) + away * float(eff["distance"]), w.bounds.x, w.bounds.y
				)
				var daze := _aura(
					p,
					str(def["id"]) + "_daze",
					"slow",
					float(eff["dazeDuration"]),
					float(eff["dazeMult"]),
					def["school"]
				)
				RpgCombat.apply_aura(w, m, daze)
				w.enter_combat(p, m)
		_:
			return false
	return true


## druidMarrowbreakUsesGuard: below the fraction the guard replaces the strike.
static func marrowbreak_guarded(p: Dictionary, below: float) -> bool:
	return int(p["hp"]) < int(p["max_hp"]) * below


## directDamage's early skip: Marrowbreak below half health guards instead of striking.
static func skips_direct_damage(p: Dictionary, res: Dictionary) -> bool:
	if res["def"]["id"] != "marrowbreak":
		return false
	for e: Dictionary in res["effects"]:
		if e["type"] == "druidMarrowbreakGuard":
			return marrowbreak_guarded(p, float(e["belowFrac"]))
	return false


## consumeAura: the target's matching hot or dot (an enemy's dot only the caster's
## own) is consumed for the rolled heal or hit.
static func _consume_aura(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var t: Dictionary = target if not target.is_empty() else p
	if t["dead"]:
		w.log_event({"type": "error", "text": "Nothing to consume."})
		return
	var found := {}
	for a: Dictionary in t["auras"]:
		if a["kind"] != "dot" and a["kind"] != "hot":
			continue
		var by_id: bool = eff.get("auraIds") != null and a["id"] in eff["auraIds"]
		var by_kind: bool = eff.get("auraKind") != null and a["kind"] == eff["auraKind"]
		if not by_id and not by_kind:
			continue
		if t["kind"] == "mob" and a["kind"] == "dot" and a["source_id"] != p["id"]:
			continue
		found = a
		break
	if found.is_empty():
		w.log_event({"type": "error", "text": "Nothing to consume."})
		return
	t["auras"].erase(found)
	w.log_event({"type": "aura", "target": t["id"], "name": found["id"], "gained": false})
	if eff.get("deal") != null and t["kind"] == "mob":
		var deal: Dictionary = eff["deal"]
		var dmg := (
			w.rng.range_f(float(deal["min"]), float(deal["max"]))
			+ RpgEffects.direct_hit_bonus(
				w,
				RpgEffects.scaling_power(p, def),
				def,
				float(res["castTime"]),
				false,
				ctx["dmg_mult"]
			)
		)
		var is_spell: bool = ctx["is_spell"]
		if is_spell:
			dmg *= RpgEffects.spell_damage_mult(p)
		var forced := RpgAbilityRules.consume_next_attack_crit(w, p)
		var crit := (
			w.rng.chance(1.0 if forced else RpgCombat.spell_crit(p)) or bool(ctx["sure_crit"])
		)
		if ctx["sure_crit"]:
			ctx["sure_crit_rolled"] = true
		if crit:
			dmg *= (
				(1.5 + float(p["crit_dmg_spell"]))
				if is_spell
				else (2.0 + float(p["crit_dmg_phys"]))
			)
		if not is_spell:
			dmg *= (
				1.0 - RpgHitTable.armor_reduction(RpgCombat.effective_armor(w, t), int(p["level"]))
			)
		RpgCombat.deal_damage(w, p, t, _jr(dmg), crit, str(def["school"]), str(def["name"]))
	if eff.get("heal") != null:
		var heal: Dictionary = eff["heal"]
		var amount := RpgEffects.scale_primary(
			(
				w.rng.range_f(float(heal["min"]), float(heal["max"]))
				+ RpgEffects.direct_heal_bonus(
					w, float(p["heal_power"]), float(res["castTime"]), ctx["heal_mult"]
				)
			),
			RpgEffects.primary_heal_mult(p)
		)
		RpgCombat.apply_heal(w, p, t, amount)


# -- Spore Burst -------------------------------------------------------------------


## The sporeBurst arm (plantSporeBurst): a fused patch at the aim; a full engine bank
## makes it 25% stronger, a Nature's Boon cast stronger still.
static func _plant_spore_burst(
	w: RpgEncounter, p: Dictionary, res: Dictionary, eff: Dictionary, ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var full := (
		RpgDruidEngine.stacks(p, RpgDruidEngine.VERDANCE_ID) >= RpgDruidEngine.STAGES
		or RpgDruidEngine.stacks(p, RpgDruidEngine.MOONTIDE_ID) >= RpgDruidEngine.STAGES
	)
	var bank := SPORE_BURST_FULL_BANK_POWER if full else 1.0
	var boon := float(res.get("natures_boon_power", 1.0)) * bank
	var fuse := float(eff["fuse"])
	var area := {
		"special": "spore_burst",
		"source_id": p["id"],
		"x": float(p["cast_aim"]) if p.get("cast_aim") != null else float(p["x"]),
		"radius": float(eff["radius"]),
		"min": float(eff["min"]),
		"max": float(eff["max"]),
		"remaining": fuse,
		"interval": fuse,
		"tick_timer": fuse,
		"school": "nature",
		"ability": str(def["name"]),
		"ability_id": "spore_burst",
		"sp_bonus":
		RpgEffects.direct_hit_bonus(
			w, RpgEffects.scaling_power(p, def), def, float(res["castTime"]), true, ctx["dmg_mult"]
		),
		"heal_min": float(eff["healMin"]),
		"heal_max": float(eff["healMax"]),
		"heal_bonus":
		RpgEffects.direct_heal_bonus(
			w, float(p["heal_power"]), float(res["castTime"]), ctx["heal_mult"], true
		),
		"heal_mult": float(ctx.get("cast_heal_mult", 1.0)) * bank,
		"primary_heal_mult": RpgEffects.primary_heal_mult(p),
		"damage_mult": boon * float(ctx["primary_dmg_mult"]),
		"plants": p["class_id"] == "druid" and p["spec_id"] == "restoration",
	}
	w.ground.append(area)


## The patch's own tick: it bursts when its fuse runs out. True when it is done.
static func tick_spore_burst(w: RpgEncounter, area: Dictionary) -> bool:
	if float(area["remaining"]) > RpgCast.CAST_COMPLETE_EPS:
		return false
	var src := w.unit(int(area["source_id"]))
	if src.is_empty() or src["dead"]:
		return true
	if absf(float(src["x"]) - float(area["x"])) <= float(area["radius"]):
		var rolled := w.rng.range_f(float(area["heal_min"]), float(area["heal_max"]))
		rolled += float(area["heal_bonus"])
		var whole := (
			rolled
			if float(area["heal_mult"]) == 1.0
			else float(_jr(rolled * float(area["heal_mult"])))
		)
		RpgCombat.apply_heal(
			w, src, src, RpgEffects.scale_primary(whole, float(area["primary_heal_mult"]))
		)
		if area["plants"] and not src["dead"]:
			var fresh := true
			for a: Dictionary in src["auras"]:
				if a["kind"] == "hot" and a["id"] == "rejuvenation" and a["source_id"] == src["id"]:
					fresh = false
			RpgDruidEngine.replant_sporemending(w, src, src, float(area["heal_mult"]))
			if fresh:
				RpgDruidEngine.on_hot_planted(w, src, "rejuvenation")
	var struck := RpgAbilityRules.hostiles_in_radius(
		w, src, float(area["x"]), float(area["radius"])
	)
	if struck.is_empty():
		return true
	var crit := w.rng.chance(RpgCombat.spell_crit(src))
	var crit_mult := 1.5 + float(src["crit_dmg_spell"]) if crit else 1.0
	for m: Dictionary in struck:
		var rolled := (
			w.rng.range_f(float(area["min"]), float(area["max"])) + float(area["sp_bonus"])
		)
		var amount := (
			rolled * RpgEffects.spell_damage_mult(src) * crit_mult * float(area["damage_mult"])
		)
		RpgCombat.deal_damage(w, src, m, _jr(amount), crit, "nature", str(area["ability"]))
	return true


# -- form entry, Lunge, Bruin Rush --------------------------------------------------


## druidFormEntryOwed: the press would shift the druid into its form first.
static func form_entry_owed(p: Dictionary, ability_id: String) -> bool:
	if p.get("class_id") != "druid" or not FORM_ENTRY.has(ability_id):
		return false
	return not RpgAbilityRules.has_kind(p, RpgForms.FORM_AURA_KIND[FORM_ENTRY[ability_id]])


## druidFormEntryPool: a Cat entry is billed from the energy the shift hands over.
static func form_entry_pool(p: Dictionary, ability_id: String) -> float:
	if not form_entry_owed(p, ability_id):
		return -1.0
	if FORM_ENTRY[ability_id] != "cat":
		return 0.0
	if not p.get("in_combat", false):
		return 100.0
	return 100.0 - float(p.get("parked_energy_deficit", 0.0))


## applyDruidFormEntry: the other forms drop and the press's form goes on.
static func apply_form_entry(w: RpgEncounter, p: Dictionary, ability_id: String) -> void:
	if not form_entry_owed(p, ability_id):
		return
	var form: String = FORM_ENTRY[ability_id]
	var form_id: String = FORM_ABILITY[form]
	var kind: String = RpgForms.FORM_AURA_KIND[form]
	var def: Dictionary = w.pack["abilities"].get(form_id, {}).get("def", {})
	var buff := {}
	for e: Dictionary in def.get("effects", []):
		if e["type"] == "selfBuff" and e["kind"] == kind:
			buff = e
	if buff.is_empty():
		return
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if RpgForms.is_form_kind(w, str(a["kind"])) and a["kind"] != kind:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
	var aura := _aura(
		p, form_id, kind, float(buff["duration"]), float(buff["value"]), def["school"]
	)
	RpgCombat.apply_aura(w, p, aura)
	w.recalc_player()


## startLunge: the charge toward the target pends the strike for 3 s.
static func start_lunge(w: RpgEncounter, p: Dictionary, target: Dictionary) -> void:
	if target.is_empty() or target["dead"] or int(p.get("charge_target", -1)) != int(target["id"]):
		return
	_remove(w, p, LUNGE_PENDING_ID)
	var pending := _aura(p, LUNGE_PENDING_ID, "internal_cd", LUNGE_PENDING_SECONDS, 0.0, "physical")
	pending["value"] = float(target["id"])
	RpgCombat.apply_aura(w, p, pending)


static func _remove(w: RpgEncounter, p: Dictionary, id: String) -> Dictionary:
	for a: Dictionary in p["auras"]:
		if a["id"] == id:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
			return a
	return {}


## finishLunge and finishBruinRush, when a charge run ends: an arrived Lunge strikes
## (x0.6 weapon, a combo point), a short one refunds its cooldown; an arrived Bruin
## Rush restarts the Pin window.
static func finish_charge(
	w: RpgEncounter, p: Dictionary, target: Dictionary, arrived: bool
) -> void:
	var pending := {}
	for a: Dictionary in p["auras"]:
		if a["id"] == LUNGE_PENDING_ID and a["kind"] == "internal_cd":
			pending = a
	if not pending.is_empty():
		_remove(w, p, LUNGE_PENDING_ID)
		if (
			not arrived
			or target.is_empty()
			or target["dead"]
			or int(target["id"]) != int(pending["value"])
		):
			p["cooldowns"].erase("lunge")
		elif w.player_melee(
			target, {"weapon_mult": LUNGE_WEAPON_MULT, "bonus": 0.0, "ability_id": "lunge"}, "Lunge"
		):
			RpgRogue.award_combo(w, p, target, 1)
	if target.is_empty() or target["dead"]:
		return
	for a: Dictionary in p["auras"]:
		if a["id"] == RpgDruidEngine.BRUIN_RUSH_WINDOW_ID and int(a["value"]) == int(target["id"]):
			a["remaining"] = RpgDruidEngine.BRUIN_RUSH_WINDOW_SECONDS
			a["duration"] = RpgDruidEngine.BRUIN_RUSH_WINDOW_SECONDS
