class_name RpgUnit
extends RefCounted
## Combat units, as World of ClaudeCraft's entities carry them (d2b91e08). A unit is a
## Dictionary (the one authoritative combat state; scenes only read it):
## {id, kind "player"|"mob", class_id, spec_id, level, stats, weapon, offhand_weapon,
##  dual_wielding, attack_power, ranged_power, spell_power, heal_power, crit,
##  shared_crit_bonus, dodge, hit_bonus, melee_haste, ranged_haste, spell_haste,
##  crit_dmg_phys, crit_dmg_spell, crit_dmg_heal, block_chance, block_value, hp, max_hp,
##  resource_type, resource, max_resource, armor, auras [], cooldowns {}, gcd,
##  swing_timer, offhand_timer, five_second_rule, combat_timer, x, dead, mods}.
##
## recalc() is src/sim/entity.ts recalcPlayerStats for what the trial can hold: gear
## stats, ratings, spell power, the aura stat kinds, the spec and talent modifiers,
## dual wield, the shield, health kept as a fraction of max health and mana as a
## fraction of max mana (rage, energy and focus capped at 100). Not held by the trial,
## so not computed: set bonuses, item-instance rolls, shapeshift forms, PvP ratings,
## membership and referral gear.

const UNARMED := {"min": 1.0, "max": 2.0, "speed": 2.0}
const SPELL_POWER_PER_INT := 0.5


## A new player unit from a character state (createPlayer + recalcPlayerStats): health
## starts at 1 of max 1, so the first recalc fills it; resource starts at 0, so mana
## fills (its fraction defaults to 1) and rage, energy and focus stay at 0.
static func player(content: ContentDB, pack: Dictionary, state: Dictionary) -> Dictionary:
	var u := {
		"id": 1,
		"kind": "player",
		"class_id": str(state["class_id"]),
		"level": int(state["level"]),
		"hp": 1,
		"max_hp": 1,
		"resource": 0.0,
		"max_resource": 0,
		"resource_type": "",
		"auras": [],
		"cooldowns": {},
		"gcd": 0.0,
		"swing_timer": 0.0,
		"offhand_timer": 0.0,
		"five_second_rule": 0.0,
		"combat_timer": 99.0,
		"in_combat": false,
		"x": 0.0,
		"dead": false,
		"casting": {},
		"auto_attack": false,
		"facing": 1.0,
		"combo_points": 0,
		"combo_until": 0.0,
		"overpower_until": -1.0,
		"queued_on_swing": "",
		"charge_target": -1,
		"charge_time": 0.0,
		"cast_aim": null,
		"ability_charges": {},
		"saved_mana": 0.0,
	}
	set_talents(content, pack, u, state)
	recalc(content, pack, u, state)
	return u


## The spec and talent modifiers (computeTalentModifiers) for the stored allocation.
static func set_talents(
	_content: ContentDB, pack: Dictionary, u: Dictionary, state: Dictionary
) -> void:
	var alloc := {"spec": str(state.get("spec_id", "")), "rows": state.get("talents", {})}
	u["mods"] = RpgTalents.mods_for(pack, str(state["class_id"]), alloc, int(state["level"]))
	u["spec_id"] = "" if u["mods"]["spec"] == null else str(u["mods"]["spec"])


## recalcPlayerStats.
static func recalc(content: ContentDB, pack: Dictionary, u: Dictionary, state: Dictionary) -> void:
	var cls := str(u["class_id"])
	var def := RpgClassRegistry.class_def(content, cls)
	var lvl := int(u["level"])
	var mods: Dictionary = u["mods"]
	var s := RpgStats.base_stats(def, lvl)
	var bonus_sp := 0.0
	var crit_rating := 0.0
	var haste_rating := 0.0
	var hit_rating := 0.0
	var equipment: Dictionary = state["equipment"]
	for slot: String in RpgEquipmentRules.slots(content) + ["charm"]:
		if not equipment.has(slot):
			continue
		var item := RpgPack.item(pack, str(equipment[slot]))
		if item.is_empty() or not RpgCharacter.meets_level(item, lvl):
			continue
		bonus_sp += float(item.get("spell_power", 0))
		crit_rating += float(item.get("crit_rating", 0))
		haste_rating += float(item.get("haste_rating", 0))
		hit_rating += float(item.get("hit_rating", 0))
		if item.get("stats") is Dictionary:
			for k: String in RpgCharacter.STAT_KEYS:
				s[k] = int(s[k]) + int(item["stats"].get(k, 0))
	var a := _aura_stats(pack, u, s)
	bonus_sp += a["sp"]
	var m: Dictionary = mods["stats"]
	for k: String in RpgCharacter.STAT_KEYS:
		s[k] = int(s[k]) + int(m[k])
	a["ap"] += float(m["ap"])
	a["dodge"] += float(m["dodge"])
	for pair: Array in [
		["sta", "staPct"],
		["str", "strPct"],
		["agi", "agiPct"],
		["int", "intPct"],
		["spi", "spiPct"]
	]:
		if float(m[pair[1]]) != 0.0:
			s[pair[0]] = int(RpgTalents.js_round(float(s[pair[0]]) * (1.0 + float(m[pair[1]]))))
	if a["all_pct"] != 0.0 or a["int_pct"] != 0.0 or a["sta_pct"] != 0.0:
		var all: float = a["all_pct"]
		for k: String in ["str", "agi", "spi"]:
			s[k] = int(RpgTalents.js_round(float(s[k]) * (1.0 + all)))
		s["sta"] = int(RpgTalents.js_round(float(s["sta"]) * (1.0 + all + a["sta_pct"])))
		s["int"] = int(RpgTalents.js_round(float(s["int"]) * (1.0 + all + a["int_pct"])))
	s["agi"] = maxi(0, int(s["agi"]))
	s["armor"] = int(s["armor"]) + int(s["agi"]) * 2
	_form_stats(u, s, a, lvl)
	if float(m["armorFromStrPct"]) != 0.0:
		s["armor"] += int(RpgTalents.js_round(float(s["str"]) * float(m["armorFromStrPct"])))
	if float(m["armorPct"]) != 0.0:
		s["armor"] = int(RpgTalents.js_round(float(s["armor"]) * (1.0 + float(m["armorPct"]))))
	if a["armor_flat"] != 0.0:
		s["armor"] += int(a["armor_flat"])
	if a["armor_pct"] != 0.0:
		s["armor"] = int(RpgTalents.js_round(float(s["armor"]) * (1.0 + a["armor_pct"])))
	s["spi"] = maxi(0, int(s["spi"]))
	u["stats"] = s
	u["armor"] = int(s["armor"])
	_weapons(content, pack, u, state, lvl)
	var ap_from_stats := float(s["str"])
	if cls in ["warrior", "paladin", "shaman", "druid"]:
		ap_from_stats = float(s["str"]) * 2.0
	elif cls in ["rogue", "hunter"]:
		ap_from_stats = float(s["str"]) + float(s["agi"])
	var ap_pct: float = 1.0 + float(m["apPct"]) + float(a["ap_pct"])
	u["attack_power"] = maxi(0, int(RpgTalents.js_round((ap_from_stats + a["ap"]) * ap_pct)))
	u["ranged_power"] = (
		maxi(0, int(RpgTalents.js_round((float(s["agi"]) * 2.0 + a["ap"]) * ap_pct)))
		if cls == "hunter"
		else 0
	)
	u["spell_power"] = maxi(
		0, int(RpgTalents.js_round(float(s["int"]) * SPELL_POWER_PER_INT + bonus_sp))
	)
	u["heal_power"] = maxi(0, int(u["spell_power"]))
	u["hit_bonus"] = RpgStats.hit_from_rating(hit_rating)
	var haste_frac := RpgStats.haste_from_rating(haste_rating)
	u["melee_haste"] = haste_frac + a["haste"] + float(mods["global"]["meleeHastePct"])
	u["ranged_haste"] = haste_frac + a["haste"]
	u["spell_haste"] = haste_frac + a["haste"] + float(mods["global"]["spellHastePct"])
	u["shared_crit_bonus"] = a["crit"] + float(m["crit"]) + RpgStats.crit_from_rating(crit_rating)
	u["crit"] = 0.05 + float(s["agi"]) * 0.0005 + float(u["shared_crit_bonus"])
	if RpgAbilityRules.has_kind(u, "berserker_stance"):
		u["crit"] = float(u["crit"]) + float(pack["constants"]["berserker_crit_chance"])
	u["crit_dmg_spell"] = float(mods["global"]["critDmgSpellPct"])
	u["crit_dmg_phys"] = float(mods["global"]["critDmgPhysPct"])
	u["crit_dmg_heal"] = float(mods["global"]["critDmgHealPct"])
	u["dodge"] = maxf(0.0, 0.05 + float(s["agi"]) * 0.0005 + a["dodge"])
	_pools(def, u, s, lvl, mods, a)


## recalcPlayerStats' druid forms: Bruin x2.1 armor and 15 + 1.5 Agi attack power;
## Cat 8 + 2/level attack power and max(2, level/2) Agility; Moonwing x1.5 armor (its
## Spell Power rides the aura); Sporemender x1.4 armor.
static func _form_stats(u: Dictionary, s: Dictionary, a: Dictionary, lvl: int) -> void:
	if RpgAbilityRules.has_kind(u, "form_bear"):
		s["armor"] = int(RpgTalents.js_round(float(s["armor"]) * 2.1))
		a["ap"] += 15.0 + RpgTalents.js_round(float(s["agi"]) * 1.5)
	if RpgAbilityRules.has_kind(u, "form_cat"):
		a["ap"] += 8.0 + lvl * 2
		s["agi"] = int(s["agi"]) + maxi(2, int(floorf(lvl / 2.0)))
	if RpgAbilityRules.has_kind(u, "form_moonkin"):
		s["armor"] = int(RpgTalents.js_round(float(s["armor"]) * 1.5))
	if RpgAbilityRules.has_kind(u, "form_sporemender"):
		s["armor"] = int(RpgTalents.js_round(float(s["armor"]) * RpgDruid.SPOREMENDER_ARMOR_MULT))


## The aura stat kinds recalcPlayerStats reads, in its order; `s` is updated in place.
static func _aura_stats(pack: Dictionary, u: Dictionary, s: Dictionary) -> Dictionary:
	var out := {
		"ap": 0.0,
		"sp": 0.0,
		"crit": 0.0,
		"dodge": 0.0,
		"haste": 0.0,
		"armor_flat": 0.0,
		"all_pct": 0.0,
		"int_pct": 0.0,
		"sta_pct": 0.0,
		"armor_pct": 0.0,
		"ap_pct": 0.0,
		"maxhp_pct": 0.0,
	}
	for aura: Dictionary in u["auras"]:
		var v := float(aura["value"])
		match str(aura["kind"]):
			"buff_ap":
				out["ap"] += v
			"debuff_ap":
				out["ap"] -= v
			"buff_armor":
				out["armor_flat"] += v
			"buff_int", "buff_str", "buff_agi", "buff_spi", "buff_sta":
				var k := str(aura["kind"]).trim_prefix("buff_")
				s[k] = int(s[k]) + int(v)
			"buff_allstats":
				for k: String in ["str", "agi", "sta", "int", "spi"]:
					s[k] = int(s[k]) + int(v)
			"buff_spellpower", "form_moonkin":
				out["sp"] += v
			"buff_crit", "buff_reckless", "bloodbath":
				out["crit"] += v
			"die_by_sword", "buff_dodge":
				out["dodge"] += v
			"enrage":
				out["haste"] += float(pack["constants"]["enrage_haste_pct"])
			"buff_maxhp_pct":
				out["maxhp_pct"] += v
			"buff_allstats_pct":
				for k: String in ["str", "agi", "sta", "int", "spi"]:
					s[k] = int(RpgTalents.js_round(float(s[k]) * (1.0 + v)))
			"buff_stats_pct":
				out["all_pct"] += v / 100.0
			"buff_int_pct":
				out["int_pct"] += v / 100.0
			"buff_sta_pct":
				out["sta_pct"] += v / 100.0
			"buff_armor_pct":
				out["armor_pct"] += v / 100.0
			"buff_ap_pct":
				out["ap_pct"] += v / 100.0
	return out


static func _weapons(
	content: ContentDB, pack: Dictionary, u: Dictionary, state: Dictionary, lvl: int
) -> void:
	var w := RpgCharacter._weapon(pack, state, "mainhand", lvl)
	u["weapon"] = w if not w.is_empty() else UNARMED.duplicate()
	var off := {}
	if RpgGear.can_dual_wield(content, str(u["class_id"]), str(u["spec_id"])):
		off = RpgCharacter._weapon(pack, state, "offhand", lvl)
	u["offhand_weapon"] = off
	u["dual_wielding"] = not off.is_empty()
	var block := RpgCharacter._shield(pack, state, lvl)
	u["block_value"] = block
	u["block_chance"] = float(RpgPack.swing(pack)["shield_block_base"]) if block > 0 else 0.0
	u["str"] = int(u["stats"]["str"])


## Max health (health kept as a fraction) and the resource pool.
static func _pools(
	def: Dictionary, u: Dictionary, s: Dictionary, lvl: int, mods: Dictionary, a: Dictionary
) -> void:
	var hp_frac := float(u["hp"]) / float(u["max_hp"]) if int(u["max_hp"]) > 0 else 1.0
	var max_hp := (
		int(def["base_hp"])
		+ int(def["hp_per_level"]) * (lvl - 1)
		+ RpgStats.hp_from_stamina(s["sta"])
	)
	var bear := RpgAbilityRules.has_kind(u, "form_bear")
	var cat := RpgAbilityRules.has_kind(u, "form_cat")
	if bear:
		max_hp = int(RpgTalents.js_round(max_hp * 1.3))
	if float(mods["stats"]["maxHpPct"]) != 0.0:
		max_hp = int(RpgTalents.js_round(float(max_hp) * (1.0 + float(mods["stats"]["maxHpPct"]))))
	if a["maxhp_pct"] != 0.0:
		max_hp = maxi(1, int(RpgTalents.js_round(float(max_hp) * (1.0 + a["maxhp_pct"]))))
	u["max_hp"] = max_hp
	u["hp"] = maxi(1, int(RpgTalents.js_round(float(max_hp) * hp_frac)))
	if u["dead"]:
		u["hp"] = 0
	var res_type := str(def["resource"])
	# Druid forms swap the bar: Bruin rage (starts empty), Cat energy (the parked
	# pool mid-fight, full out of combat); the mana waits in saved_mana.
	var form_res := "rage" if bear else ("energy" if cat else "")
	if u["resource_type"] == "energy" and form_res != "energy" and res_type == "mana":
		u["parked_energy_deficit"] = 100.0 - clampf(float(u["resource"]), 0.0, 100.0)
	if form_res != "":
		if u["resource_type"] == "mana":
			u["saved_mana"] = float(u["resource"])
		if u["resource_type"] != form_res:
			var energy := (
				100.0
				- (float(u.get("parked_energy_deficit", 0.0)) if u.get("in_combat", false) else 0.0)
			)
			u["parked_energy_deficit"] = 0.0
			u["resource"] = energy if form_res == "energy" else 0.0
		u["resource_type"] = form_res
		u["max_resource"] = 100
	elif res_type == "mana":
		var came_from_form: bool = u["resource_type"] != "mana" and u["resource_type"] != ""
		var mana_frac := (
			float(u["resource"]) / float(u["max_resource"]) if int(u["max_resource"]) > 0 else 1.0
		)
		u["resource_type"] = "mana"
		u["max_resource"] = int(
			RpgTalents.js_round(
				(
					(
						float(def["base_mana"])
						+ float(def["mana_per_level"]) * (lvl - 1)
						+ RpgStats.mana_from_intellect(s["int"])
					)
					* (1.0 + float(mods["global"]["manaPct"]))
				)
			)
		)
		u["resource"] = (
			minf(float(u.get("saved_mana", 0.0)), float(u["max_resource"]))
			if came_from_form
			else RpgTalents.js_round(float(u["max_resource"]) * mana_frac)
		)
	else:
		u["resource_type"] = res_type
		u["max_resource"] = 100
		u["resource"] = minf(float(u["resource"]), 100.0)


## A trial monster (entity.ts createMob) at `level`.
static func mob(pack: Dictionary, monster_id: String, level: int, x: float) -> Dictionary:
	var m := RpgPack.monster(pack, monster_id)
	var st := RpgMobs.stats(m["template"], level)
	return {
		"id": 2,
		"kind": "mob",
		"template_id": monster_id,
		"class_id": "",
		"spec_id": "",
		"level": level,
		"weapon": st["weapon"],
		"attack_power": 0,
		"armor": st["armor"],
		"hp": st["max_hp"],
		"max_hp": st["max_hp"],
		"elite": m["template"].get("elite", false),
		"xp_mult": float(m.get("xp_mult", 1)),
		"auras": [],
		"swing_timer": 0.0,
		"x": x,
		"prev_x": x,
		"dead": false,
		"engaged": false,
		"profile": m["combat_profile"],
		"move_speed": float(m["move_speed"]),
		"aggro_radius": float(m["aggro_radius"]),
		"body_edge": float(m.get("body_edge_melee_range", 0)),
		"resource_type": "",
		"resource": 0.0,
		"dodge": 0.05,
		"crit": 0.05,
		"hit_bonus": 0.0,
		"facing": -1.0,
		"casting": {},
	}
