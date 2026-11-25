class_name RpgCombat
extends RefCounted
## Damage, healing and auras for the trial world (RpgEncounter), each a port of the
## World of ClaudeCraft function named on it (d2b91e08). `w` is the RpgEncounter.
##
## dealDamage keeps, in the source's order, every step a trial unit can reach: the
## two-hand mastery, stances, Shield Wall, expose, spell and general vulnerability,
## damage-done buffs, damage reduction, physical reduction, Shadowform, absorbs,
## health loss, breaking breakable control, combat entry and death. Steps that need
## something the trial cannot hold (parties, duels, arenas, PvP, set and trinket
## procs, boss wards, pets, crafted collections) are absent because nothing reaches
## them.

const CAST_COMPLETE_EPS := 1e-9


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


# -- auras (sim.ts applyAura, combat/auras.ts updateAuras) ------------------------


## applyAura: same id and same source replace (a refresh); a mob never takes control
## while ccImmune or a slow while slowImmune (the trial's mobs are neither).
static func apply_aura(w: RpgEncounter, target: Dictionary, aura: Dictionary) -> void:
	if aura["kind"] == "slow" and _has_kind(target, "slow_immunity"):
		return
	if RpgPaladinKit.blocks_aura(target, aura):
		return
	if (
		target["kind"] == "mob"
		and target.get("cc_immune", false)
		and aura["kind"] in RpgAbilityRules.CONTROL_KINDS
		and aura["source_id"] != target["id"]
	):
		return
	if (
		aura["source_id"] != target["id"]
		and not aura.get("unbreakable_control", false)
		and RpgMage.ice_blocked(target)
		and (
			aura["kind"] in RpgAbilityRules.CONTROL_KINDS
			or aura["kind"] in ["silence", "blind", "disarm", "slow", "lockout", "tongues"]
		)
	):
		return
	var auras: Array = target["auras"]
	var any_source: bool = aura["id"] in w.pack["constants"]["source_independent_group_buffs"]
	for i in range(auras.size() - 1, -1, -1):
		var e: Dictionary = auras[i]
		if e["id"] != aura["id"]:
			continue
		if any_source or e["source_id"] == aura["source_id"] or int(e["source_id"]) == 0:
			auras.remove_at(i)
	auras.append(aura)
	w.log_event({"type": "aura", "target": target["id"], "name": aura["id"], "gained": true})
	if target["kind"] == "player":
		w.recalc_player()


## updateAuras for one unit: proc cooldowns tick; each aura runs down; a periodic
## aura ticks (dot, hot, mana grace, polymorph's regrowth, and the class tickers);
## an expired aura goes (an expiring hot fires its caster's hotExpired procs; a stat
## aura's removal recalculates the player).
static func update_auras(w: RpgEncounter, e: Dictionary) -> void:
	if e["dead"]:
		return
	var stats_dirty := false
	RpgTalentProcs.tick(e, w.dt)
	RpgPaladin.tick(e, w.dt)
	if e["kind"] == "player":
		RpgDruidEngine.combat_state(w, e)
	var snapshot: Array = (e["auras"] as Array).duplicate()
	for i in range(snapshot.size() - 1, -1, -1):
		var a: Dictionary = snapshot[i]
		if not (e["auras"] as Array).has(a):
			continue
		if not a.get("permanent", false) and not RpgClassHooks.persistent_aura(w, e, a):
			a["remaining"] = float(a["remaining"]) - w.dt
		RpgClassHooks.tick_aura(w, e, a)
		if a.get("tick_interval") != null:
			a["tick_timer"] = float(a.get("tick_timer", a["tick_interval"])) - w.dt
			if float(a["tick_timer"]) <= CAST_COMPLETE_EPS:
				a["tick_timer"] = float(a["tick_timer"]) + float(a["tick_interval"])
				_tick_periodic(w, e, a)
				if e["dead"]:
					return
		if not a.get("permanent", false) and float(a["remaining"]) <= CAST_COMPLETE_EPS:
			var idx := (e["auras"] as Array).find(a)
			if idx < 0:
				continue
			e["auras"].remove_at(idx)
			w.log_event({"type": "aura", "target": e["id"], "name": a["id"], "gained": false})
			RpgClassHooks.on_aura_ended(w, e, a)
			if a["kind"] == "hot":
				var src := w.unit(int(a["source_id"]))
				if not src.is_empty() and not src["dead"] and src["kind"] == "player":
					RpgTalentProcs.on_hot_expired(w, src, str(a["id"]), e)
					RpgDruid.second_bloom_on_hot_expired(w, src, e, a)
			var kind := str(a["kind"])
			if (
				kind.begins_with("buff")
				or kind.begins_with("form")
				or kind in ["debuff_ap", "die_by_sword", "enrage", "bloodbath", "berserker_stance"]
			):
				stats_dirty = true
	if stats_dirty and e["kind"] == "player":
		w.recalc_player()


## pctValue: a value above 1 is a percent.
static func _pct(v: float) -> float:
	return v / 100.0 if v > 1.0 else v


static func _tick_periodic(w: RpgEncounter, e: Dictionary, a: Dictionary) -> void:
	if RpgClassHooks.tick_special(w, e, a):
		return
	match str(a["kind"]):
		"dot":
			var src := w.unit(int(a["source_id"]))
			var amount := float(a["value"])
			if str(a["school"]) == "physical":
				var amp := 0.0
				for t: Dictionary in e["auras"]:
					if t["kind"] == "bleed_vuln":
						amp += _pct(float(t["value"]))
				if amp > 0.0:
					amount = _jr(amount * (1.0 + amp))
			var hit := RpgPriest.shadow_periodic_hit(w, src, a, int(amount))
			var landed := deal_damage(
				w,
				src,
				e,
				int(hit["amount"]),
				hit["crit"],
				str(a["school"]),
				str(a["id"]),
				"hit",
				true
			)
			RpgClassHooks.on_dot_tick(w, e, a, src, landed)
			if a.get("leech_pct") != null and not src.is_empty() and not src["dead"]:
				var intended := _jr(amount * float(a["leech_pct"]) * healing_taken_mult(src))
				var healed := mini(intended, maxi(0, int(src["max_hp"]) - int(src["hp"])))
				if healed > 0:
					src["hp"] = int(src["hp"]) + healed
					w.log_event(
						{"type": "heal", "target": src["id"], "amount": healed, "hot": true}
					)
			if e["dead"]:
				return
			if a.get("max_tick_stacks") != null:
				var old := maxi(1, int(a.get("stacks", 1)))
				var nxt := mini(int(a["max_tick_stacks"]), old + 1)
				if nxt != old:
					var per := float(a["value"]) / old
					a["stacks"] = nxt
					a["value"] = float(maxi(1, _jr(per * nxt)))
		"hot":
			if RpgShaman.tick_mending_current(w, e, a):
				return
			var healer := w.unit(int(a["source_id"]))
			var intended := _jr(
				(
					float(a["value"])
					* RpgDruid.sporemender_healing_mult(healer)
					* healing_taken_mult(e)
				)
			)
			var healed := mini(intended, maxi(0, int(e["max_hp"]) - int(e["hp"])))
			if healed > 0:
				e["hp"] = int(e["hp"]) + healed
			w.log_event({"type": "heal", "target": e["id"], "amount": healed, "hot": true})
			RpgDruid.natures_boon_on_hot_tick(w, healer, a)
		"buff_mana_grace":
			if e["resource_type"] == "mana":
				e["resource"] = minf(
					float(e["max_resource"]), float(e["resource"]) + _jr(float(a["value"]))
				)
		"polymorph":
			e["hp"] = mini(int(e["max_hp"]), int(e["hp"]) + _jr(int(e["max_hp"]) * 0.1))


# -- healing (combat/heal.ts) ------------------------------------------------------


static func healing_taken_mult(target: Dictionary) -> float:
	var mult := 1.0
	for a: Dictionary in target["auras"]:
		if a["kind"] == "mortal_wound":
			mult *= 1.0 - float(a["value"])
	return maxf(0.0, mult)


## applyHeal: one crit draw (when it can crit), heal-done buffs, x1.5 on a crit plus
## the heal-crit bonus, healing taken, clamped to missing health.
static func apply_heal(
	w: RpgEncounter,
	source: Dictionary,
	target: Dictionary,
	amount: float,
	can_crit := true,
	out := {}
) -> int:
	if target["dead"]:
		return 0
	var crit := w.rng.chance(spell_crit(source)) if can_crit else false
	var heal_done := 0.0
	for a: Dictionary in source["auras"]:
		if a["kind"] == "buff_heal_done":
			heal_done += float(a["value"])
	var healed := _jr(
		(
			amount
			* (1.0 + heal_done)
			* (1.5 + float(source.get("crit_dmg_heal", 0.0)) if crit else 1.0)
			* RpgPaladin.healing_done_mult(source)
			* RpgDruid.sporemender_healing_mult(source)
			* healing_taken_mult(target)
		)
	)
	out["resolved"] = healed
	healed = mini(healed, int(target["max_hp"]) - int(target["hp"]))
	target["hp"] = int(target["hp"]) + healed
	w.log_event({"type": "heal", "target": target["id"], "amount": healed, "crit": crit})
	if crit and source["kind"] == "player":
		RpgTalentProcs.on_spell_crit(w, source, "", target)
	return healed


## spellCritChance: base + Int x 0.08% + the shared crit bonus (+ aura bonuses).
static func spell_crit(u: Dictionary) -> float:
	var bonus := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "buff_spellcrit":
			bonus += float(a["value"])
		elif a["kind"] == "sacred_form":
			bonus += float(a.get("value2", 0.05))
	if u["kind"] != "player":
		return RpgStats.SPELL_CRIT_BASE
	return (
		RpgStats.SPELL_CRIT_BASE
		+ float(u["stats"]["int"]) * RpgStats.SPELL_CRIT_PER_INT
		+ float(u.get("shared_crit_bonus", 0.0))
		+ bonus
	)


## spell_resist.ts isSpellResisted: one chance(effectiveSpellHit) draw; resisted when
## it fails.
static func spell_resisted(w: RpgEncounter, src: Dictionary, tgt: Dictionary) -> bool:
	var hit := minf(
		1.0,
		(
			RpgHitTable.spell_hit_chance(int(src["level"]), int(tgt["level"]))
			+ float(src.get("hit_bonus", 0.0))
		)
	)
	return not w.rng.chance(hit)


# -- damage (combat/damage.ts dealDamage) -----------------------------------------


static func _has_kind(u: Dictionary, kind: String) -> bool:
	for a: Dictionary in u["auras"]:
		if a["kind"] == kind:
			return true
	return false


static func _sum_kind(u: Dictionary, kinds: Array) -> float:
	var total := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] in kinds:
			total += float(a["value"])
	return total


## dealDamage. Returns the health actually lost. `kind`: hit, block, ...
static func deal_damage(
	w: RpgEncounter,
	source: Dictionary,
	target: Dictionary,
	amount: int,
	crit: bool,
	school: String,
	ability: String,
	kind := "hit",
	periodic := false,
	_threat := {}
) -> int:
	if target["dead"] or RpgPaladinKit.valkyr_airborne(target) or _has_kind(target, "stasis"):
		return 0
	var other: bool = not source.is_empty() and source["id"] != target["id"]
	var amt := float(_jr(maxi(0, amount) * RpgPaladinKit.mark_damage_mult(source, target)))
	amt = _jr(amt * RpgMage.cauterize_fire_mult(source, target, school))
	if other and source["kind"] == "player" and amt > 0:
		var two_hand := float(source["mods"]["global"]["masteryTwoHandDmgPct"])
		if two_hand > 0.0 and w.player_mainhand_is_two_hand():
			amt = _jr(amt * (1.0 + two_hand))
	if other and _has_kind(source, "defensive_stance"):
		amt = _jr(amt * 0.9)
	if other and _has_kind(target, "defensive_stance"):
		amt = _jr(amt * 0.9)
	if amt > 0:
		var ward := 0.0
		for a: Dictionary in target["auras"]:
			if a["kind"] == "shield_wall":
				ward = maxf(ward, float(a["value"]))
		if ward > 0.0:
			amt = _jr(amt * (1.0 - ward))
	if school == "physical" and amt > 0:
		var expose := 1.0 + _sum_kind(target, ["expose"])
		if expose != 1.0:
			amt = _jr(amt * expose)
	if amt > 0 and school != "physical" and school != "holy":
		var amp := _sum_kind(target, ["spellvuln"])
		if amp > 0.0:
			amt = _jr(amt * (1.0 + amp))
	if amt > 0:
		var vuln := _sum_kind(target, ["vulnerability"])
		if vuln > 0.0:
			amt = _jr(amt * (1.0 + vuln))
	if not source.is_empty() and amt > 0:
		var own_vuln := 0.0
		for a: Dictionary in target["auras"]:
			if a["kind"] == "vuln_source" and a["source_id"] == source["id"]:
				own_vuln += float(a["value"])
		if own_vuln > 0.0:
			amt = _jr(amt * (1.0 + own_vuln))
	if other and amt > 0:
		var done := _sum_kind(source, ["buff_dmg_done", "bloodbath", "buff_avatar", "enrage"])
		for a: Dictionary in source["auras"]:
			if a["kind"] == "sanguine":
				done += float(a.get("value2", 0.0))
		if done != 0.0:
			amt = _jr(amt * maxf(0.0, 1.0 + done))
	if other and amt > 0:
		var red := RpgPaladinProcs.consecration_dr(w, target)
		for a: Dictionary in target["auras"]:
			if a["kind"] == "buff_dr":
				red += RpgPaladinProcs.mastered_value(target, str(a["id"]), float(a["value"]))
			elif a["kind"] == "die_by_sword":
				red += float(a["value"])
		if red > 0.0:
			amt = _jr(amt * maxf(0.0, 1.0 - red))
	if other and amt > 0 and school == "physical":
		var red_phys := _sum_kind(target, ["buff_dr_phys"])
		if red_phys > 0.0:
			amt = _jr(amt * maxf(0.0, 1.0 - red_phys))
	if not source.is_empty() and school == "shadow" and amt > 0:
		for a: Dictionary in source["auras"]:
			if a["kind"] == "form_shadow":
				amt = _jr(amt * (1.0 + float(a["value"]) / 100.0))
				break
	var c: Dictionary = w.pack["constants"]
	if crit and amt > 0 and other and _has_kind(source, "berserker_stance"):
		amt = _jr(amt * (1.0 + float(c["berserker_crit_damage"])))
	if crit and amt > 0 and ability != "" and other and _has_kind(source, "battle_stance"):
		if source["kind"] == "player" and float(source["mods"]["global"]["stanceMastery"]) > 0.0:
			amt = _jr(amt * (1.0 + float(c["stance_mastery_battle_crit_dmg"])))
	if (
		other
		and amt >= int(target["max_hp"]) * float(c["stance_mastery_guarded_hp_pct"])
		and _has_kind(target, "defensive_stance")
		and target["kind"] == "player"
		and float(target["mods"]["global"]["stanceMastery"]) > 0.0
	):
		amt = _jr(amt * (1.0 - float(c["stance_mastery_guarded_cut"])))
	RpgMage.ignite_on_crit(w, source, target, int(amt), crit, school, ability)
	var absorbed := RpgPaladinProcs.debt_of_light(w, target, source, int(amt))
	amt -= absorbed
	if amt > 0:
		var auras: Array = target["auras"]
		for i in range(auras.size() - 1, -1, -1):
			if amt <= 0:
				break
			var a: Dictionary = auras[i]
			if a["kind"] != "absorb":
				continue
			var soaked := minf(float(a["value"]), amt)
			a["value"] = float(a["value"]) - soaked
			amt -= soaked
			absorbed += int(soaked)
			if float(a["value"]) <= 0.0:
				auras.remove_at(i)
				w.log_event(
					{"type": "aura", "target": target["id"], "name": a["id"], "gained": false}
				)
				var shielder := w.unit(int(a["source_id"]))
				if (
					not shielder.is_empty()
					and not shielder["dead"]
					and shielder["kind"] == "player"
				):
					RpgTalentProcs.on_shield_consumed(w, shielder, str(a["id"]), target)
					RpgPriest.on_shield_consumed(w, shielder, a, target, source)
	var cauterized := RpgMage.cauterize(w, target, amt)
	if cauterized >= 0.0:
		amt = cauterized
	if target["kind"] == "player" and amt >= int(target["hp"]) and not target["dead"]:
		# cheatDeathIcd (Borrowed Breath): a killing blow leaves 1 health, once per icd.
		var icd := float(target["mods"]["global"]["cheatDeathIcd"])
		if icd > 0.0:
			var icds: Dictionary = RpgTalentProcs._state(target)["icds"]
			if not icds.has("cheat_death"):
				icds["cheat_death"] = icd
				amt = maxf(0.0, int(target["hp"]) - 1)
	var pre := int(target["hp"])
	target["hp"] = maxi(0, pre - int(amt))
	var lost := pre - int(target["hp"])
	RpgPriest.on_damage(w, source, target, lost, school, str(_threat.get("ability_id", ability)))
	if other and amt > 0:
		RpgShamanWar.trance_mana(source, int(amt))
	if target["kind"] == "player" and amt > 0:
		RpgShamanWar.on_damage_taken(w, target, int(amt))
	(
		w
		. log_event(
			{
				"type": "damage",
				"source": -1 if source.is_empty() else source["id"],
				"target": target["id"],
				"amount": int(amt),
				"crit": crit,
				"school": school,
				"ability": ability,
				"kind": kind,
				"absorbed": absorbed,
				"periodic": periodic,
			}
		)
	)
	if amt > 0:
		_break_on_damage(w, source, target, int(amt), not periodic)
		_heal_echo(w, target)
	if other:
		w.enter_combat(source, target)
	if other and source["kind"] == "player" and crit and school != "physical" and ability != "":
		RpgTalentProcs.on_spell_crit(w, source, str(_threat.get("ability_id", "")), target)
	if not source.is_empty() and source["kind"] == "player" and amt > 0 and not periodic:
		w.rage_from_dealing(source, int(amt), school, ability, crit)
	if target["kind"] == "player" and amt > 0 and int(target["hp"]) > 0:
		RpgTalentProcs.on_damage_taken(w, target, int(amt))
	if target["kind"] == "player" and other and amt > 0:
		w.rage_from_taking(source, target, int(amt))
	if (
		target["kind"] == "player"
		and other
		and not target["casting"].is_empty()
		and amt > 0
		and kind == "hit"
	):
		RpgCast.pushback(target)
	RpgPaladinProcs.pay_debt(w, target)
	if int(target["hp"]) <= 0 and not target["dead"]:
		w.kill(source, target)
	return lost


## Breakable control ends on damage: a damage budget (breakThreshold) wears down
## first; a fear breaks by chance, min(1, amount / (scale x max health)).
static func _break_on_damage(
	w: RpgEncounter, source: Dictionary, target: Dictionary, amount: int, direct: bool
) -> void:
	var auras: Array = target["auras"]
	for i in range(auras.size() - 1, -1, -1):
		var b: Dictionary = auras[i]
		if not b.get("breaks_on_damage", false) or b.get("unbreakable_control", false):
			continue
		if RpgRogue.foul_play_guards(source, b, direct):
			continue
		if b.get("break_threshold") != null and int(b["break_threshold"]) > amount:
			b["break_threshold"] = int(b["break_threshold"]) - amount
			continue
		if b.get("break_chance_scale") != null and int(target["max_hp"]) > 0:
			var chance := minf(
				1.0, float(amount) / (float(b["break_chance_scale"]) * int(target["max_hp"]))
			)
			if not w.rng.chance(chance):
				continue
		auras.remove_at(i)
		w.log_event({"type": "aura", "target": target["id"], "name": b["id"], "gained": false})


## effectiveArmorOf: a monster's own armor buffs, minus corrosion, then the largest
## percent cut (Sunder by its stacks, Faerie Fire, melting acid).
static func effective_armor(w: RpgEncounter, u: Dictionary) -> float:
	var armor := float(u.get("armor", 0))
	var base := armor
	var cut := 0.0
	var c: Dictionary = w.pack["constants"]
	for a: Dictionary in u["auras"]:
		var k := str(a["kind"])
		if u["kind"] != "player" and k == "buff_armor":
			armor += float(a["value"])
		elif u["kind"] != "player" and k == "buff_armor_pct":
			armor += base * float(a["value"]) / 100.0
		if k == "corrode":
			armor -= float(a["value"]) * int(a.get("stacks", 1))
		elif k == "sunder":
			cut = maxf(cut, float(c["sunder_armor_pct_per_stack"]) * int(a.get("stacks", 1)))
		elif k == "faerie_fire":
			cut = maxf(cut, float(c["faerie_fire_armor_pct"]))
		elif k == "melting_acid":
			cut = maxf(cut, float(a["value"]))
	return maxf(0.0, armor * (1.0 - cut))


## effectiveAttackPowerOf: a monster's attack power with its AP auras.
static func effective_attack_power(u: Dictionary) -> float:
	var ap := float(u.get("attack_power", 0))
	if u["kind"] != "player":
		var base := ap
		for a: Dictionary in u["auras"]:
			match str(a["kind"]):
				"buff_ap":
					ap += float(a["value"])
				"debuff_ap":
					ap -= float(a["value"])
				"buff_ap_pct":
					ap += base * float(a["value"]) / 100.0
	return maxf(0.0, ap)


## isStunned (combat/cc.ts).
static func is_stunned(u: Dictionary) -> bool:
	for a: Dictionary in u["auras"]:
		if a["kind"] in ["stun", "stasis", "incapacitate", "polymorph"]:
			return true
	return false


## isRooted (a stun roots too).
static func is_rooted(u: Dictionary) -> bool:
	return is_stunned(u) or _has_kind(u, "root")


static func is_rooted_or_chilled(u: Dictionary) -> bool:
	return is_rooted(u) or _has_kind(u, "slow")


## A monster's speed under slows (the smallest slow multiplier).
static func move_speed_mult(u: Dictionary) -> float:
	var slow := 1.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "slow":
			slow = minf(slow, float(a["value"]))
	return slow


## player_motion.ts moveSpeedMult: the smallest slow (stealth's own value is one),
## times the strongest speed buff (Enraged counts ENRAGE_MOVE_MULT), times the cat
## form's passive and the Sporemender pace.
static func player_speed_mult(w: RpgEncounter, u: Dictionary) -> float:
	var c: Dictionary = w.pack["constants"]
	var slow := 1.0
	var speed := 1.0
	var form := 1.0
	var pace := 1.0
	var immune := _has_kind(u, "slow_immunity")
	for a: Dictionary in u["auras"]:
		var k := str(a["kind"])
		if (not immune and k == "slow") or k == "stealth":
			slow = minf(slow, float(a["value"]))
		if k == "stealth" and float(a["value"]) > 1.0:
			speed = maxf(speed, float(a["value"]))
		if k in ["buff_speed", "form_travel", "form_fireball"]:
			speed = maxf(speed, float(a["value"]))
		if k == "enrage":
			speed = maxf(speed, float(c["enrage_move_mult"]))
		if k == "form_cat":
			form = float(c["cat_form_move_mult"])
		if k == "form_sporemender":
			pace = float(c["sporemender_move_speed_mult"])
	speed *= form * RpgHunter.hunting_momentum_mult(u)
	return slow * speed * pace


## The heal_echo auras (Seraphic Vigil, talent echoes): a hit that leaves the target
## under the aura's threshold (value2 of max health) fires its heal.
static func _heal_echo(w: RpgEncounter, target: Dictionary) -> void:
	if target["dead"] or int(target["max_hp"]) <= 0:
		return
	for a: Dictionary in (target["auras"] as Array).duplicate():
		if a["kind"] != "heal_echo":
			continue
		if float(target["hp"]) >= float(target["max_hp"]) * float(a.get("value2", 0.0)):
			continue
		RpgAbilityRules.remove_aura(w, target, a)
		var healer := w.unit(int(a["source_id"]))
		if not healer.is_empty() and not healer["dead"]:
			apply_heal(w, healer, target, float(a["value"]))
