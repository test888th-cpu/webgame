class_name RpgPriest
extends RefCounted
## The priest's mechanics (src/sim/combat/priest/*.ts): the talents (talents.ts),
## Stilled Mind, the shadow periodic crit, Vampiric Touch, Doctrine (discipline),
## the Seraphic Vigil (holy), and Vespers (shadow: Dirge, Effigy, Gloomtithe, the
## echo). Benison's prayers are item-set bonuses (no set items in this game). The
## Tithefiend guardian and Spirit Bomb join with the guardian system. On the street the
## priest's group is the priest alone (partyOf finds no party).

const TALENT_SHELTERING_STEP := "pri_r5_improved_renew"
const TALENT_VEIL_UNBOUND := "pri_r5_searing_light"
const TALENT_PROCESSIONAL_GRACE := "pri_r5_twisted_faith"
const TALENT_LINGERING_DREAD := "pri_r8_psychic_scream"
const TALENT_BINDING_PSALM := "pri_r11_vampiric_embrace"
const TALENT_STILLED_MIND := "pri_r11_inner_focus"
const TALENT_LIVING_COVENANT := "pri_r14_pain_and_suffering"
const TALENT_TWIN_COVENANT := "pri_r20_twin_covenant"
const TALENT_SECOND_VERSE := "pri_r20_second_verse"
const TALENT_INCARNATE_SPIRIT := "pri_r20_incarnate_spirit"
const TALENT_CHOIR := "pri_r17_choir_of_deliverance"
const STILLED_MIND_CRIT_AURA_ID := "priest_stilled_mind_crit"
const DOCTRINE_AURA_ID := "priest_doctrine"
const SERAPHIC_VIGIL_ID := "seraphic_vigil"
const EFFIGY_AURA_ID := "priest_effigy"
const GLOOMTITHE_AURA_ID := "priest_gloomtithe"
const GLOOMTITHE_MAX_STACKS := 5
const GLOOMTITHE_GRACE := 15.0
const EFFIGY_ECHO_RATE := 0.3
const VESPERS_DOT_DAMAGE_MULT := 1.1
const MINDFRACTURE_SPELL_POWER_COEFF := 0.5
const DOCTRINE_DURATION := 30.0
const DOCTRINE_CONVERSION := 0.3
const DOCTRINE_FALLBACK_CONVERSION := 0.15
const DOCTRINE_RANGE := 30.0
const DOCTRINE_DAMAGE_ABILITIES: Array[String] = ["smite", "scouring_mercy"]
const SERAPHIC_VIGIL_THRESHOLD := 0.35
const VAMPIRIC_TOUCH_CHARGES := 2
const VAMPIRIC_TOUCH_DAMAGE_MULT := 1.3
const VAMPIRIC_TOUCH_HEAL_RATE := 0.2
const VAMPIRIC_TOUCH_HEAL_RANGE := 30.0
const LIVING_COVENANT_MAX_EXTENSION := 6.0
const SHADOW_LIVING_COVENANT_EXTENSION := 1.0
const SHADOW_LIVING_COVENANT_MAX_EXTENSION := 3.0
const SHADOW_SECOND_VERSE_TICKS := 5
const SHADOW_CHOIR_DURATION := 15.0
const SHADOW_CHOIR_HEAL_FRACTION := 0.2
const DIRGE_BASE_DURATION := 18.0
const DIRGE_DEFAULT_RANGE := 30.0


static func _priest(p: Dictionary, spec := "") -> bool:
	if p.is_empty() or p.get("kind") != "player" or p.get("class_id") != "priest":
		return false
	return spec == "" or p.get("spec_id") == spec


static func has_talent(p: Dictionary, id: String) -> bool:
	return _priest(p) and bool(p["mods"]["selected"].get(id, false))


static func _shadow_talent(p: Dictionary, id: String) -> bool:
	return not p.is_empty() and not p["dead"] and _priest(p, "shadow") and has_talent(p, id)


static func _aura(
	id: String, kind: String, duration: float, value: float, p: Dictionary, school: String
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": duration,
		"duration": duration,
		"value": value,
		"source_id": p["id"],
		"school": school,
	}


static func _own(u: Dictionary, id: String, src_id: int) -> Dictionary:
	for a: Dictionary in u["auras"]:
		if a["id"] == id and int(a["source_id"]) == src_id:
			return a
	return {}


## vespersDirgeSpMultiplier, for shadow_word_pain's dot only.
static func dirge_sp_mult(p: Dictionary, ability_id: String) -> float:
	if ability_id != "shadow_word_pain":
		return 1.0
	return VESPERS_DOT_DAMAGE_MULT if _priest(p, "shadow") else 1.0


## resolveVespersAbility (and resolveShadowChoir): a shadow priest's Dirge totals
## 10% more, its Mind Blast scales 0.5 with spell power, its Choir is a 15 s buff.
static func resolve(p: Dictionary, k: Dictionary) -> Dictionary:
	if not _priest(p, "shadow"):
		return k
	var id := str(k["def"]["id"])
	if id == "choir_of_deliverance":
		var out := k.duplicate()
		var fx: Array = [
			{
				"type": "selfBuff",
				"kind": "buff_dmg_done",
				"duration": SHADOW_CHOIR_DURATION,
				"value": 0
			}
		]
		var def: Dictionary = k["def"].duplicate()
		def["school"] = "shadow"
		def.erase("channel")
		def["effects"] = fx
		out["def"] = def
		out["castTime"] = 0.0
		out["effects"] = fx
		return out
	if id != "shadow_word_pain" and id != "mind_blast":
		return k
	var shaped := k.duplicate()
	var effects: Array = []
	for e: Dictionary in k["effects"]:
		var c := e.duplicate(true)
		if id == "shadow_word_pain" and c["type"] == "dot":
			c["total"] = RpgTalents.js_round(float(c["total"]) * VESPERS_DOT_DAMAGE_MULT)
		if id == "mind_blast" and c["type"] == "directDamage":
			c["spellPowerCoeff"] = MINDFRACTURE_SPELL_POWER_COEFF
		effects.append(c)
	shaped["effects"] = effects
	return shaped


## shadowPeriodicHit: a shadow priest's Dirge, Litany and Vampiric Touch ticks can
## crit (one spell-crit draw each).
static func shadow_periodic_hit(
	w: RpgEncounter, src: Dictionary, a: Dictionary, amount: int
) -> Dictionary:
	var id := str(a["id"])
	if (
		str(a["school"]) != "shadow"
		or a.get("final_damage", false)
		or not id in ["shadow_word_pain", "mind_flay", "vampiric_touch"]
		or not _priest(src, "shadow")
		or amount <= 0
	):
		return {"amount": amount, "crit": false}
	var crit := w.rng.chance(RpgCombat.spell_crit(src))
	if crit:
		amount = int(RpgTalents.js_round(amount * (1.5 + float(src["crit_dmg_spell"]))))
	return {"amount": amount, "crit": crit}


# -- casts --------------------------------------------------------------------------------


## priestOnCastCompleted: a cast that spent an empowered aura ends Inner Focus's shield.
static func on_cast_completed(w: RpgEncounter, p: Dictionary) -> void:
	if not p.get("cast_consumed_empower", false):
		return
	for a: Dictionary in p["auras"]:
		if a["id"] == "inner_focus" and a["kind"] == "cast_shield":
			RpgAbilityRules.remove_aura(w, p, a)
			return


## reserveShadowStilledMind: Mind Blast or Void Rupture spends Stilled Mind for a
## guaranteed crit.
static func reserve_stilled_mind(w: RpgEncounter, p: Dictionary, res: Dictionary) -> Dictionary:
	var id := str(res["def"]["id"])
	if (id != "mind_blast" and id != "void_rupture") or not _shadow_talent(p, TALENT_STILLED_MIND):
		return res
	var a := _own(p, STILLED_MIND_CRIT_AURA_ID, int(p["id"]))
	if a.is_empty() or float(a["remaining"]) <= 0.0:
		return res
	RpgAbilityRules.remove_aura(w, p, a)
	var out := res.duplicate()
	var fx: Array = []
	for e: Dictionary in res["effects"]:
		var c := e.duplicate(true)
		if c["type"] == "directDamage":
			c["guaranteedCrit"] = true
		fx.append(c)
	out["effects"] = fx
	return out


## runEffects' priest epilogue: benison (Seraphic Vigil's threshold), doctrine (Power
## Word: Shield links Doctrine), vespers (Tithefiend: the guardian system), then
## priestAfterAbility (Stilled Mind, Sheltering Step, Veil Unbound, Processional Grace).
static func after_ability(
	w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary
) -> void:
	if not _priest(p):
		return
	var id := str(def["id"])
	if (
		_priest(p, "holy")
		and id == SERAPHIC_VIGIL_ID
		and not target.is_empty()
		and not target["dead"]
	):
		var vigil := _own(target, SERAPHIC_VIGIL_ID, int(p["id"]))
		if not vigil.is_empty():
			vigil["value2"] = SERAPHIC_VIGIL_THRESHOLD
	if _priest(p, "discipline") and id == "power_word_shield" and not target.is_empty():
		var shield := _own(target, "power_word_shield", int(p["id"]))
		if not shield.is_empty() and shield.get("value2") == null:
			shield["value2"] = shield["value"]
		var rate := 0.7 if has_talent(p, TALENT_TWIN_COVENANT) else DOCTRINE_CONVERSION
		RpgCombat.apply_aura(
			w, target, _aura(DOCTRINE_AURA_ID, "doctrine", DOCTRINE_DURATION, rate, p, "holy")
		)
	if id == "inner_focus" and _shadow_talent(p, TALENT_STILLED_MIND):
		RpgCombat.apply_aura(
			w, p, _aura(STILLED_MIND_CRIT_AURA_ID, "buff_dmg_done", 60.0, 0.0, p, "shadow")
		)
	if (
		id == "power_word_shield"
		and not target.is_empty()
		and has_talent(p, TALENT_SHELTERING_STEP)
	):
		RpgCombat.apply_aura(
			w, target, _aura("priest_sheltering_step", "buff_speed", 3.0, 1.4, p, "holy")
		)
	if id != "veilstep":
		return
	if has_talent(p, TALENT_VEIL_UNBOUND):
		for a: Dictionary in (p["auras"] as Array).duplicate():
			if (
				(a["kind"] == "slow" or a["kind"] == "root")
				and not a.get("unbreakable_control", false)
			):
				RpgAbilityRules.remove_aura(w, p, a)
		RpgCombat.apply_aura(w, p, _aura("priest_veil_unbound", "buff_speed", 3.0, 1.5, p, "holy"))
	if has_talent(p, TALENT_PROCESSIONAL_GRACE):
		RpgCombat.apply_aura(
			w, p, _aura("priest_processional_grace", "processional_grace", 4.0, 1.0, p, "holy")
		)
	w.recalc_player()


## priestOnAuraEnded: a priest's Terror Canticle ending leaves Lingering Dread.
static func on_aura_ended(w: RpgEncounter, target: Dictionary, a: Dictionary) -> void:
	if a["id"] != "fear_incap" or a.get("name") != "Terror Canticle":
		return
	var priest := w.unit(int(a["source_id"]))
	if priest.is_empty() or priest["dead"] or not has_talent(priest, TALENT_LINGERING_DREAD):
		return
	RpgCombat.apply_aura(
		w, target, _aura("priest_lingering_dread", "slow", 4.0, 0.5, priest, "shadow")
	)


## priestOnShieldConsumed: Binding Psalm roots the attacker (12 s per attacker);
## Incarnate Spirit heals 40% of the shield.
static func on_shield_consumed(
	w: RpgEncounter, priest: Dictionary, shield: Dictionary, owner: Dictionary, attacker: Dictionary
) -> void:
	if shield["id"] != "power_word_shield" or not _priest(priest):
		return
	if not attacker.is_empty() and not attacker["dead"] and attacker["kind"] == "mob":
		if has_talent(priest, TALENT_BINDING_PSALM):
			var icds: Dictionary = RpgTalentProcs._state(attacker)["icds"]
			var key := "binding_psalm_%d" % int(priest["id"])
			if not icds.has(key):
				icds[key] = 12.0
				RpgCombat.apply_aura(w, attacker, _aura(key, "root", 2.0, 0.0, priest, "holy"))
	if has_talent(priest, TALENT_INCARNATE_SPIRIT):
		var original := float(shield.get("value2", 0.0))
		if original > 0.0:
			RpgCombat.apply_heal(w, priest, owner, RpgTalents.js_round(original * 0.4), false)


## priestOnGroupHeal: Living Covenant banks Prayer of Healing's overheal as a shield
## (capped at 10% of max health); Second Verse echoes 40% as a 2 s hot.
static func on_group_heal(
	w: RpgEncounter,
	priest: Dictionary,
	target: Dictionary,
	def: Dictionary,
	attempted: int,
	missing_before: int,
	effective: int
) -> void:
	var id := str(def["id"])
	if id != "prayer_of_healing" and id != "holy_nova":
		return
	if id == "prayer_of_healing" and has_talent(priest, TALENT_LIVING_COVENANT):
		var overheal := maxi(0, attempted - missing_before)
		var cap := maxi(1, int(RpgTalents.js_round(int(target["max_hp"]) * 0.1)))
		if overheal > 0:
			var existing := _own(target, "priest_living_covenant", int(priest["id"]))
			if not existing.is_empty():
				existing["value"] = minf(cap, float(existing["value"]) + overheal)
				existing["remaining"] = 10.0
			else:
				var a := _aura(
					"priest_living_covenant",
					"absorb",
					10.0,
					float(mini(cap, overheal)),
					priest,
					"holy"
				)
				a["value2"] = float(cap)
				RpgCombat.apply_aura(w, target, a)
	if has_talent(priest, TALENT_SECOND_VERSE) and effective > 0:
		var hot := _aura(
			"priest_second_verse_%s_%d" % [id, w.tick_count],
			"hot",
			2.0,
			float(maxi(1, int(RpgTalents.js_round(effective * 0.4)))),
			priest,
			"holy"
		)
		hot["tick_interval"] = 2.0
		hot["tick_timer"] = 2.0
		RpgCombat.apply_aura(w, target, hot)


# -- shadow: Vampiric Touch, Dirge, Effigy, Gloomtithe ---------------------------------


## applyVampiricTouch: two Gloomtithe stacks empower it (x1.3) and are spent.
static func apply_vampiric_touch(
	w: RpgEncounter, priest: Dictionary, target: Dictionary, dot: Dictionary
) -> void:
	if not _priest(priest, "shadow") or priest["dead"]:
		RpgCombat.apply_aura(w, target, dot)
		return
	var bank := _own(priest, GLOOMTITHE_AURA_ID, int(priest["id"]))
	var empowered := int(bank.get("stacks", 0)) >= VAMPIRIC_TOUCH_CHARGES
	if empowered:
		dot["value"] = float(RpgTalents.js_round(float(dot["value"]) * VAMPIRIC_TOUCH_DAMAGE_MULT))
	var previous := _own(target, "vampiric_touch", int(priest["id"]))
	dot["shadow_verse_ticks"] = int(previous.get("shadow_verse_ticks", 0))
	RpgCombat.apply_aura(w, target, dot)
	if empowered:
		bank["stacks"] = int(bank["stacks"]) - VAMPIRIC_TOUCH_CHARGES
		if int(bank["stacks"]) == 0:
			RpgAbilityRules.remove_aura(w, priest, bank)


## healVampiricTouch: 20% of what the tick took heals the group (the priest).
static func heal_vampiric_touch(w: RpgEncounter, priest: Dictionary, landed: int) -> void:
	if not _priest(priest, "shadow") or priest["dead"]:
		return
	heal_group_budget(w, priest, int(RpgTalents.js_round(landed * VAMPIRIC_TOUCH_HEAL_RATE)))


## healShadowGroupBudget: the budget split over injured group members (the priest).
static func heal_group_budget(w: RpgEncounter, priest: Dictionary, budget: int) -> void:
	if budget > 0 and int(priest["hp"]) < int(priest["max_hp"]):
		RpgCombat.apply_heal(w, priest, priest, float(budget), false)


## The dot arm's priest applications: Vampiric Touch's own, and the Dirge's refresh
## carrying its timing (dirge_refresh.ts).
static func apply_dot(
	w: RpgEncounter, p: Dictionary, target: Dictionary, dot: Dictionary, def: Dictionary
) -> bool:
	if str(dot["id"]) == "vampiric_touch":
		apply_vampiric_touch(w, p, target, dot)
		return true
	if str(def["id"]) != "shadow_word_pain" or not _priest(p, "shadow") or target["kind"] != "mob":
		return false
	var prior := _own(target, "shadow_word_pain", int(p["id"]))
	if prior.is_empty() or float(prior["remaining"]) <= 0.0:
		return false
	RpgCombat.apply_aura(w, target, dot)
	_carry_dirge(dot, prior)
	_resync_effigy(p, target, float(dot["remaining"]))
	for h: Dictionary in RpgAbilityRules.hostiles_in_radius(
		w,
		p,
		float(p["x"]),
		float(def["range"]) if float(def["range"]) > 0.0 else DIRGE_DEFAULT_RANGE
	):
		if h["id"] == target["id"] or h["kind"] != "mob":
			continue
		var existing := _own(h, "shadow_word_pain", int(p["id"]))
		if existing.is_empty() or float(existing["remaining"]) <= 0.0:
			continue
		var fresh := existing.duplicate()
		fresh["value"] = dot["value"]
		fresh["school"] = dot["school"]
		if dot.get("leech_pct") != null:
			fresh["leech_pct"] = dot["leech_pct"]
		_carry_dirge(fresh, existing)
		RpgCombat.apply_aura(w, h, fresh)
		_resync_effigy(p, h, float(fresh["remaining"]))
	return true


static func _carry_dirge(fresh: Dictionary, prior: Dictionary) -> void:
	fresh["tick_timer"] = prior.get("tick_timer", fresh.get("tick_timer"))
	var duration := minf(
		DIRGE_BASE_DURATION + LIVING_COVENANT_MAX_EXTENSION,
		maxf(DIRGE_BASE_DURATION, float(prior["remaining"]))
	)
	fresh["duration"] = duration
	fresh["remaining"] = duration
	var extended := maxf(0.0, duration - DIRGE_BASE_DURATION)
	if extended > 0.0:
		fresh["extended_by"] = extended
	else:
		fresh.erase("extended_by")


static func _resync_effigy(p: Dictionary, target: Dictionary, remaining: float) -> void:
	var effigy := _own(target, EFFIGY_AURA_ID, int(p["id"]))
	if not effigy.is_empty():
		effigy["remaining"] = maxf(0.05, remaining)
		effigy["duration"] = maxf(0.05, remaining)


static func add_gloomtithe(w: RpgEncounter, priest: Dictionary, amount := 1) -> void:
	if amount <= 0 or priest["dead"]:
		return
	var existing := RpgAbilityRules.find_kind(priest, "gloomtithe")
	if not existing.is_empty():
		existing["stacks"] = mini(GLOOMTITHE_MAX_STACKS, int(existing.get("stacks", 1)) + amount)
		existing["remaining"] = GLOOMTITHE_GRACE
		return
	var a := _aura(GLOOMTITHE_AURA_ID, "gloomtithe", GLOOMTITHE_GRACE, 0.0, priest, "shadow")
	a["stacks"] = mini(GLOOMTITHE_MAX_STACKS, amount)
	RpgCombat.apply_aura(w, priest, a)


## preservesGloomtithe: the bank holds while an Effigy stands on a Dirge.
static func preserves_gloomtithe(w: RpgEncounter, priest: Dictionary) -> bool:
	for m: Dictionary in w.mobs:
		if not m["dead"]:
			if not _own(m, EFFIGY_AURA_ID, int(priest["id"])).is_empty():
				if not _own(m, "shadow_word_pain", int(priest["id"])).is_empty():
					return true
	return false


static func _bind_effigy(w: RpgEncounter, priest: Dictionary, target: Dictionary) -> bool:
	var dirge := _own(target, "shadow_word_pain", int(priest["id"]))
	if dirge.is_empty() or target["dead"]:
		return false
	var links: Array = []
	for m: Dictionary in w.mobs:
		if not _own(m, EFFIGY_AURA_ID, int(priest["id"])).is_empty():
			links.append(m)
	if not has_talent(priest, TALENT_TWIN_COVENANT):
		for m: Dictionary in links:
			RpgAbilityRules.remove_aura(w, m, _own(m, EFFIGY_AURA_ID, int(priest["id"])))
	elif not links.has(target) and links.size() >= 2:
		var first: Dictionary = links[0]
		RpgAbilityRules.remove_aura(w, first, _own(first, EFFIGY_AURA_ID, int(priest["id"])))
	var dur := maxf(0.05, float(dirge["remaining"]))
	RpgCombat.apply_aura(
		w, target, _aura(EFFIGY_AURA_ID, "hex", dur, EFFIGY_ECHO_RATE, priest, "shadow")
	)
	return true


## vespersOnDotTick: a Dirge tick on an Effigy banks a Gloomtithe stack (once a tick).
static func on_dot_tick(
	w: RpgEncounter, target: Dictionary, a: Dictionary, src: Dictionary, landed: int
) -> void:
	if str(a["id"]) == "vampiric_touch":
		heal_vampiric_touch(w, src, landed)
		_second_verse_tick(w, target, a, src)
	if str(a["id"]) != "shadow_word_pain" or src.is_empty():
		return
	if _own(target, EFFIGY_AURA_ID, int(a["source_id"])).is_empty():
		return
	if (
		int(a.get("gloomtithe_tick", -1)) == w.tick_count
		or not _priest(src, "shadow")
		or src["dead"]
	):
		return
	a["gloomtithe_tick"] = w.tick_count
	add_gloomtithe(w, src)


## shadowSecondVerseTick: every fifth Vampiric Touch tick under an Effigy repeats.
static func _second_verse_tick(
	w: RpgEncounter, target: Dictionary, dot: Dictionary, priest: Dictionary
) -> void:
	if target["dead"] or not _shadow_talent(priest, TALENT_SECOND_VERSE):
		return
	if _own(target, EFFIGY_AURA_ID, int(priest["id"])).is_empty():
		return
	dot["shadow_verse_ticks"] = int(dot.get("shadow_verse_ticks", 0)) + 1
	if int(dot["shadow_verse_ticks"]) % SHADOW_SECOND_VERSE_TICKS != 0:
		return
	var hit := shadow_periodic_hit(w, priest, dot, int(dot["value"]))
	var before := int(target["hp"])
	RpgCombat.deal_damage(
		w,
		priest,
		target,
		int(hit["amount"]),
		hit["crit"],
		str(dot["school"]),
		str(dot["id"]),
		"hit",
		true
	)
	heal_vampiric_touch(w, priest, maxi(0, before - int(target["hp"])))


## The damage hooks of dealDamage: the Doctrine conversion, the Effigy echo and the
## Choir's healing.
static func on_damage(
	w: RpgEncounter,
	source: Dictionary,
	target: Dictionary,
	lost: int,
	school: String,
	ability_id: String
) -> void:
	if source.is_empty() or lost <= 0 or not _priest(source):
		return
	_doctrine_convert(w, source, lost, school, ability_id)
	_vespers_echo(w, source, target, lost, ability_id)
	if (
		school == "shadow"
		and source["id"] != target["id"]
		and _shadow_talent(source, TALENT_CHOIR)
		and not _own(source, "choir_of_deliverance", int(source["id"])).is_empty()
	):
		heal_group_budget(w, source, int(RpgTalents.js_round(lost * SHADOW_CHOIR_HEAL_FRACTION)))


## doctrineConvertDamage: a discipline priest's holy Smite or Scouring Mercy heals the
## Doctrine-linked (the priest, when linked and hurt) by the link's rate; with no hurt
## link, the lowest hurt group member (the priest) by 15%.
static func _doctrine_convert(
	w: RpgEncounter, priest: Dictionary, dealt: int, school: String, ability_id: String
) -> void:
	if (
		school != "holy"
		or not ability_id in DOCTRINE_DAMAGE_ABILITIES
		or not _priest(priest, "discipline")
	):
		return
	var link := _own(priest, DOCTRINE_AURA_ID, int(priest["id"]))
	if not link.is_empty() and int(priest["hp"]) < int(priest["max_hp"]):
		var healed := RpgCombat.apply_heal(
			w, priest, priest, RpgTalents.js_round(dealt * float(link["value"])), false
		)
		if has_talent(priest, TALENT_LIVING_COVENANT) and healed > 0:
			var shield := _own(priest, "power_word_shield", int(priest["id"]))
			if not shield.is_empty() and shield.get("value2") != null:
				shield["value"] = minf(
					float(shield["value2"]),
					float(shield["value"]) + RpgTalents.js_round(healed * 0.2)
				)
		if (
			ability_id == "scouring_mercy"
			and healed > 0
			and has_talent(priest, TALENT_SECOND_VERSE)
		):
			var hot := _aura(
				"priest_second_verse_scouring_mercy_%d" % w.tick_count,
				"hot",
				2.0,
				float(maxi(1, int(RpgTalents.js_round(healed * 0.4)))),
				priest,
				"holy"
			)
			hot["tick_interval"] = 2.0
			hot["tick_timer"] = 2.0
			RpgCombat.apply_aura(w, priest, hot)
		return
	if int(priest["hp"]) < int(priest["max_hp"]):
		RpgCombat.apply_heal(
			w, priest, priest, RpgTalents.js_round(dealt * DOCTRINE_FALLBACK_CONVERSION), false
		)


## vespersEchoDamage (Mind Blast): binds the Effigy, stretches the shadow dots (Living
## Covenant), banks Gloomtithe, and echoes 30% to up to three other Dirged foes.
static func _vespers_echo(
	w: RpgEncounter, priest: Dictionary, target: Dictionary, dealt: int, ability_id: String
) -> void:
	if ability_id != "mind_blast" or not _priest(priest, "shadow") or priest["dead"]:
		return
	if not _bind_effigy(w, priest, target):
		return
	_extend_primary_dots(priest, target)
	add_gloomtithe(w, priest)
	if _own(target, EFFIGY_AURA_ID, int(priest["id"])).is_empty():
		return
	var others: Array = []
	for m: Dictionary in w.mobs:
		if (
			m["id"] != target["id"]
			and not m["dead"]
			and not _own(m, "shadow_word_pain", int(priest["id"])).is_empty()
		):
			others.append(m)
	others.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var da := absf(float(a["x"]) - float(target["x"]))
			var db := absf(float(b["x"]) - float(target["x"]))
			return da < db if da != db else int(a["id"]) < int(b["id"])
	)
	var echo := maxi(1, int(RpgTalents.js_round(dealt * EFFIGY_ECHO_RATE)))
	var covenant := _shadow_talent(priest, TALENT_LIVING_COVENANT)
	for m: Dictionary in others.slice(0, 3):
		var dirge := _own(m, "shadow_word_pain", int(priest["id"]))
		if not dirge.is_empty() and covenant:
			var ext := minf(
				1.0, LIVING_COVENANT_MAX_EXTENSION - float(dirge.get("extended_by", 0.0))
			)
			if dirge.get("extended_by") == null:
				ext = 1.0
			if ext > 0.0:
				dirge["extended_by"] = float(dirge.get("extended_by", 0.0)) + ext
				dirge["remaining"] = float(dirge["remaining"]) + ext
				dirge["duration"] = float(dirge["duration"]) + ext
			var eff2 := _own(m, EFFIGY_AURA_ID, int(priest["id"]))
			if not eff2.is_empty():
				eff2["remaining"] = dirge["remaining"]
				eff2["duration"] = dirge["duration"]
		RpgCombat.deal_damage(w, priest, m, echo, false, "shadow", "Effigy Echo", "hit", true)


## extendShadowPrimaryDots (Living Covenant): +1 s to the Effigy target's Dirge and
## Vampiric Touch, up to 3 s each.
static func _extend_primary_dots(priest: Dictionary, target: Dictionary) -> void:
	if not _shadow_talent(priest, TALENT_LIVING_COVENANT):
		return
	var effigy := _own(target, EFFIGY_AURA_ID, int(priest["id"]))
	if effigy.is_empty():
		return
	for d: Dictionary in target["auras"]:
		if int(d["source_id"]) != int(priest["id"]) or d["kind"] != "dot":
			continue
		if d["id"] != "shadow_word_pain" and d["id"] != "vampiric_touch":
			continue
		var extra := minf(
			SHADOW_LIVING_COVENANT_EXTENSION,
			SHADOW_LIVING_COVENANT_MAX_EXTENSION - float(d.get("extended_by", 0.0))
		)
		if extra <= 0.0:
			continue
		d["extended_by"] = float(d.get("extended_by", 0.0)) + extra
		d["remaining"] = float(d["remaining"]) + extra
		d["duration"] = float(d["duration"]) + extra
		if d["id"] == "shadow_word_pain":
			effigy["remaining"] = d["remaining"]
			effigy["duration"] = d["duration"]


## vespersOnEntityDeath: an Effigy moves to the nearest other Dirged foe.
static func on_death(w: RpgEncounter, dead: Dictionary) -> void:
	for a: Dictionary in dead["auras"]:
		if a["id"] != EFFIGY_AURA_ID:
			continue
		var priest := w.unit(int(a["source_id"]))
		if priest.is_empty() or priest["dead"]:
			continue
		var best := {}
		for m: Dictionary in w.mobs:
			if (
				m["id"] == dead["id"]
				or m["dead"]
				or _own(m, "shadow_word_pain", int(priest["id"])).is_empty()
			):
				continue
			if (
				best.is_empty()
				or (
					absf(float(m["x"]) - float(dead["x"]))
					< absf(float(best["x"]) - float(dead["x"]))
				)
			):
				best = m
		if not best.is_empty():
			_bind_effigy(w, priest, best)
