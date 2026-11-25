class_name RpgAutoAttack
extends RefCounted
## The player's auto attack and weapon swings (src/sim/combat/auto_attack.ts
## updatePlayerAutoAttack, tryPlayerSwing, meleeSwing, rangedSwing). A queued
## on-next-swing ability (Heroic Strike) rides the next main-hand swing.


## updatePlayerAutoAttack.
static func update(w: RpgEncounter) -> void:
	var p := w.player
	p["swing_timer"] = maxf(0.0, float(p["swing_timer"]) - w.dt)
	p["offhand_timer"] = maxf(0.0, float(p["offhand_timer"]) - w.dt)
	try_swing(w)


## tryPlayerSwing.
static func try_swing(w: RpgEncounter) -> void:
	var p := w.player
	if RpgPaladinKit.valkyr_airborne(p):
		return
	for a: Dictionary in p["auras"]:
		if RpgForms.is_travel_kind(str(a["kind"])):
			p["auto_attack"] = false
			return
	if not p["auto_attack"] or not p["casting"].is_empty():
		return
	var t := w.mob
	if t.is_empty() or t["dead"]:
		p["auto_attack"] = false
		return
	var dual: bool = p["dual_wielding"]
	if float(p["swing_timer"]) > 0.0 and (not dual or float(p["offhand_timer"]) > 0.0):
		return
	if RpgCombat.is_stunned(p) or RpgAbilityRules.has_kind(p, "disarm"):
		return
	if not RpgAbilityRules.in_front(p, t):
		return
	var d := w.distance()
	var ranged := RpgWorld.ranged_profile(w)
	if (
		not ranged.is_empty()
		and d <= float(ranged["maxRange"])
		and d >= (0.0 if ranged.get("wand", false) else float(ranged.get("minRange", 0)))
	):
		RpgShaman.break_ghost_wolf(w, p)
		var shot := ranged.duplicate()
		if not ranged.get("wand", false):
			shot["min"] = p["weapon"]["min"]
			shot["max"] = p["weapon"]["max"]
			shot["speed"] = p["weapon"]["speed"]
		ranged_swing(w, shot)
		p["swing_timer"] = float(shot["speed"]) * swing_interval_mult(p, "ranged")
		return
	if d > w.player_attack_range(0.0):
		return
	RpgShaman.break_ghost_wolf(w, p)
	var penalty: bool = dual and not (p["class_id"] == "shaman" and p["spec_id"] == "enhancement")
	var haste := RpgWarrior.stance_mastery_haste(w, p)
	if float(p["swing_timer"]) <= 0.0:
		var opts := {"hand": "mainhand", "auto_attack": true}
		var label := _queued_swing(w, p, opts)
		opts["white_dw_penalty"] = penalty and label == ""
		var connected := melee(w, t, opts, label)
		var extra := float(p["mods"]["global"]["extraAttackPct"])
		if connected and label == "" and extra > 0.0 and w.rng.chance(extra):
			melee(w, t, {"hand": "mainhand", "white_dw_penalty": penalty, "auto_attack": true}, "")
		RpgWarrior.swing_procs(w, p, connected)
		p["swing_timer"] = (
			RpgDruid.base_swing_speed(p) * swing_interval_mult(p, "melee") / (1.0 + haste)
		)
	if dual and float(p["offhand_timer"]) <= 0.0 and not t["dead"]:
		var off: Dictionary = p["offhand_weapon"]
		var connected := melee(
			w,
			t,
			{
				"hand": "offhand",
				"weapon": off,
				"white_dw_penalty": penalty,
				"auto_attack": true,
				"ap_speed": float(off["speed"]),
			},
			""
		)
		RpgWarrior.swing_procs(w, p, connected)
		p["offhand_timer"] = float(off["speed"]) * swing_interval_mult(p, "melee") / (1.0 + haste)


## The queued on-next-swing ability: paid for when affordable, its bonus and talent
## multiplier ride this swing. Returns its name ("" for a white swing).
static func _queued_swing(w: RpgEncounter, p: Dictionary, opts: Dictionary) -> String:
	var queued := str(p.get("queued_on_swing", ""))
	if queued == "":
		return ""
	var label := ""
	var res := w.known_entry(queued)
	if not res.is_empty():
		var eff := {}
		for e: Dictionary in res["effects"]:
			if e["type"] == "weaponDamage":
				eff = e
		var cost := 0.0 if p.get("queued_on_swing_free", false) else float(res["cost"])
		if not eff.is_empty() and float(p["resource"]) >= cost:
			RpgCast.spend(p, cost)
			RpgAbilityRules.rage_spend_refund(w, p, cost if p["resource_type"] == "rage" else 0.0)
			if float(res["def"]["cooldown"]) > 0.0:
				p["cooldowns"][queued] = float(res["def"]["cooldown"])
			opts["bonus"] = float(eff["bonus"])
			opts["ability_id"] = queued
			opts["threat_flat"] = float(res.get("threatFlat", 0.0))
			opts["threat_mult"] = float(res.get("threatMult", 1.0))
			opts["weapon_mult"] = float(RpgTalents.hit_mult(w.pack, res["def"], p["mods"])["dmg"])
			label = str(res["def"]["name"])
	p["queued_on_swing"] = ""
	p.erase("queued_on_swing_free")
	return label


## resetSwingTimer.
static func reset_swing_timer(w: RpgEncounter) -> void:
	var p := w.player
	var haste := RpgWarrior.stance_mastery_haste(w, p)
	p["swing_timer"] = (
		RpgDruid.base_swing_speed(p) * swing_interval_mult(p, "melee") / (1.0 + haste)
	)
	if p["dual_wielding"]:
		p["offhand_timer"] = (
			float(p["offhand_weapon"]["speed"]) * swing_interval_mult(p, "melee") / (1.0 + haste)
		)


## swingIntervalMult.
static func swing_interval_mult(u: Dictionary, channel: String) -> float:
	var slow := 1.0
	var haste := float(u.get("ranged_haste" if channel == "ranged" else "melee_haste", 0.0))
	for a: Dictionary in u["auras"]:
		if a["kind"] in ["attackspeed", "sanguine"]:
			slow *= float(a["value"])
		if a["kind"] == "buff_haste":
			haste += float(a["value"]) - 1.0
	return slow / (1.0 + maxf(0.0, haste))


## blindMissBonus.
static func blind_miss_bonus(u: Dictionary) -> float:
	var bonus := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "blind" and float(a["value"]) > bonus:
			bonus = float(a["value"])
	return bonus


## meleeSwing for the player: one table roll (RpgSwing), a dodge arms Overpower's
## window, then dealDamage. `opts` (RpgSwing's plus): ability_id, primary_dmg_mult,
## force_crit, threat_flat, threat_mult, auto_attack, on_dealt(amount, effective).
## Returns whether it connected; w.last_melee_dealt holds the damage dealt.
static func melee(w: RpgEncounter, target: Dictionary, opts: Dictionary, label: String) -> bool:
	var p := w.player
	w.last_melee_dealt = 0
	opts["miss_bonus"] = blind_miss_bonus(p)
	var imbue := 0.0
	for a: Dictionary in p["auras"]:
		if a["kind"] == "imbue":
			imbue += float(a["value"])
	opts["bonus"] = float(opts.get("bonus", 0.0)) + imbue
	var hand := str(opts.get("hand", ""))
	var ability := str(opts.get("ability_id", ""))
	var bear_strike: bool = (
		RpgAbilityRules.has_kind(p, "form_bear")
		and not (opts.get("auto_attack", false) and ability == "")
	)
	if hand == "mainhand" and not bear_strike:
		opts["roll_mult"] = RpgDruid.cat_auto_roll_mult(p)
	if not opts.has("ap_speed"):
		opts["ap_speed"] = (
			float(p["weapon"]["speed"]) if bear_strike else RpgDruid.base_swing_speed(p)
		)
	opts["form_mult"] = RpgDruid.cat_form_damage_mult(p)
	opts["crit_forced"] = RpgAbilityRules.consume_next_attack_crit(w, p)
	var hit := RpgSwing.player_swing(
		RpgWorld.swing_view(w, p), RpgWorld.swing_view(w, target), w.rng, opts
	)
	var connected: bool = hit["result"] == "hit" or hit["result"] == "block"
	if not connected:
		w.log_event(
			{
				"type": "damage",
				"source": p["id"],
				"target": target["id"],
				"amount": 0,
				"kind": hit["result"],
				"ability": label
			}
		)
		w.enter_combat(p, target)
		if hit["result"] == "dodge":
			p["overpower_until"] = w.time + 5.0
		return false
	var amount := maxi(
		1, int(RpgTalents.js_round(float(hit["amount"]) * float(opts.get("primary_dmg_mult", 1.0))))
	)
	var hp_before := int(target["hp"])
	var dealt := (
		RpgCombat
		. deal_damage(
			w,
			p,
			target,
			amount,
			hit["crit"],
			"physical",
			label,
			hit["result"],
			false,
			{
				"flat": float(opts.get("threat_flat", 0.0)),
				"mult": float(opts.get("threat_mult", 1.0)),
				"ability_id": ability,
			}
		)
	)
	w.last_melee_dealt = dealt
	if opts.has("on_dealt"):
		opts["on_dealt"].call(dealt, maxi(0, hp_before - int(target["hp"])))
	if ability == "":
		RpgShamanWar.advance_cadence(w, p, target, dealt, 1)
	elif ability == "stormstrike":
		RpgShamanWar.advance_cadence(w, p, target, dealt, 2)
		RpgShamanWar.trigger_ward_cycle(w, p)
	if opts.get("auto_attack", false):
		RpgDruidEngine.boon_on_auto_attack(w, p)
		RpgPaladinProcs.requital(w, p, target)
		RpgPaladinProcs.try_dawns_wrath(w, p)
	RpgDruid.on_landed_strike(w, p, ability)
	RpgTalentProcs.on_melee_swing(w, p)
	RpgPoisons.apply_coats(w, p, target)
	return true


## rangedSwing: a projectile; on arrival one miss draw (swingMissChance + blind),
## the weapon roll (x0.6 for a bow, as is for a wand) + RAP / 14 x speed, the
## discipline wand bonus, one crit draw, armor for a bow only.
static func ranged_swing(w: RpgEncounter, shot: Dictionary) -> void:
	var wand: bool = shot.get("wand", false)
	var school := str(shot.get("school", "arcane")) if wand else "physical"
	var label := "Wand" if wand else "Auto Shot"
	if not wand:
		RpgTalentProcs.on_cast_completed(w, w.player, "auto_shot", w.mob)
	w.schedule_projectile(
		func(atk: Dictionary, tgt: Dictionary) -> void:
			var miss := (
				RpgHitTable.swing_miss_chance(
					int(atk["level"]), int(tgt["level"]), false, float(atk["hit_bonus"])
				)
				+ blind_miss_bonus(atk)
			)
			if w.rng.chance(miss):
				w.log_event(
					{
						"type": "damage",
						"source": atk["id"],
						"target": tgt["id"],
						"amount": 0,
						"kind": "miss",
						"ability": label
					}
				)
				w.enter_combat(atk, tgt)
				return
			var roll := w.rng.range_f(float(shot["min"]), float(shot["max"]))
			var dmg := (
				(roll if wand else roll * float(w.pack["constants"]["ranged_weapon_coeff"]))
				+ float(atk["ranged_power"]) / 14.0 * float(shot["speed"])
			)
			if wand and atk["class_id"] == "priest" and atk["spec_id"] == "discipline":
				dmg *= float(w.pack["constants"]["discipline_wand_offense_mult"])
			var crit_chance := maxf(
				0.005, float(atk["crit"]) - maxi(0, int(tgt["level"]) - int(atk["level"])) * 0.002
			)
			var forced := RpgAbilityRules.consume_next_attack_crit(w, atk)
			var crit := w.rng.chance(1.0 if forced else crit_chance)
			if crit:
				dmg *= 2.0 + float(atk["crit_dmg_phys"])
			if not wand:
				dmg *= (
					1.0
					- RpgHitTable.armor_reduction(
						RpgCombat.effective_armor(w, tgt), int(atk["level"])
					)
				)
			RpgCombat.deal_damage(w, atk, tgt, maxi(1, int(floorf(dmg + 0.5))), crit, school, label)
	)
