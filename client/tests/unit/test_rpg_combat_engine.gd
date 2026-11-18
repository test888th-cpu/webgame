extends TestCase
## The reference combat engine of the trial (RpgEncounter, RpgUnit, RpgCast,
## RpgEffects, RpgCombat, RpgTalents): every class's basic attack, the resources,
## 20 Hz timing, specs and talents changing the runtime, every implemented ability
## doing what its effect says, blocked abilities refused, death, revive, corpses.

const CLASSES: Array[String] = [
	"warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"
]

var _content: ContentDB


func _db() -> ContentDB:
	if _content == null:
		_content = ContentDB.load_all()
	return _content


func _pack() -> Dictionary:
	return RpgPack.of(_db())


func _char(cls: String, level := 1) -> Dictionary:
	var s := RpgCharacter.create(_db(), _pack(), cls)
	s["level"] = level
	return s


func _fight(state: Dictionary, mob := "shore_scuttler", seed := 11, dist := -1.0) -> RpgEncounter:
	return RpgEncounter.start(_db(), _pack(), state, mob, RpgRng.seeded(seed), dist)


func _attack_labels(f: RpgEncounter) -> Dictionary:
	var out := {}
	for e: Dictionary in f.events:
		if e["type"] == "damage" and int(e.get("source", -1)) == int(f.player["id"]):
			out[str(e.get("ability", ""))] = true
	return out


# -- foundations ---------------------------------------------------------------------


func test_the_world_steps_at_the_reference_rate() -> void:
	var f := _fight(_char("warrior"))
	assert_near(f.dt, 0.05, "DT = 1 / TICK_RATE (20)")
	f.command({"op": "auto", "on": false})
	f.command({"op": "attack"})
	f.run(200)
	var swings: Array = []
	for e: Dictionary in f.events:
		if e["type"] == "damage" and int(e["source"]) == 1:
			swings.append(int(e["tick"]))
	assert_true(swings.size() >= 3, "several swings")
	# A 2.0 s sword: the timer resets to 2.0 and runs down by DT each tick.
	assert_eq(swings[1] - swings[0], 40, "40 ticks apart at 20 Hz")


func test_new_characters_start_with_the_reference_resources() -> void:
	for cls: String in CLASSES:
		var f := _fight(_char(cls))
		var p := f.player
		assert_eq(int(p["hp"]), int(p["max_hp"]), cls + ": full health (fraction 1 of 1)")
		if p["resource_type"] == "mana":
			assert_eq(float(p["resource"]), float(p["max_resource"]), cls + ": full mana")
		else:
			assert_eq(float(p["resource"]), 0.0, cls + ": rage, energy, focus start at 0")


func test_every_class_fights_with_its_own_basic_attack() -> void:
	for cls: String in CLASSES:
		var state := _char(cls)
		var f := _fight(state)
		var outcome := f.run(20 * 600)
		assert_eq(outcome, "victory", cls + ": wins a level-1 fight on auto")
		var labels := _attack_labels(f)
		var ranged: Variant = _pack()["classes"][cls]["ranged"]
		if ranged == null:
			assert_true(labels.has(""), cls + ": melee white swings")
		elif ranged.get("wand", false):
			assert_true(labels.has("Wand"), cls + ": wand shots (no melee)")
		else:
			assert_true(labels.has("Auto Shot"), cls + ": auto shot")
		assert_true(int(state["kills"]) == 1 and int(state["xp"]) > 0, cls + ": kill credit")


func test_a_wand_shot_flies_and_lands_later() -> void:
	var f := _fight(_char("mage"), "shore_scuttler", 3, 20.0)
	f.command({"op": "auto", "on": false})
	f.command({"op": "attack"})
	f.step()
	assert_eq(f.projectiles.size(), 1, "a bolt in flight")
	_assert_not(f.mob["engaged"], "a ranged start does not pull until it lands")
	for _i in 30:
		f.step()
	assert_true(f.mob["engaged"], "the landed shot pulled the monster")


func _assert_not(v: bool, msg: String) -> void:
	assert_true(not v, msg)


func test_the_monster_pursues_to_its_reach() -> void:
	var f := _fight(_char("mage"), "shore_scuttler", 3, 20.0)
	f.command({"op": "auto", "on": false})
	f.command({"op": "attack"})
	var start: float = f.mob["x"]
	for _i in 60:
		f.step()
	assert_true(float(f.mob["x"]) < start, "the engaged monster closed in")
	assert_true(f.distance() >= float(f.mob["profile"]["desiredRange"]) - 0.0001, "not past reach")


func test_defeat_then_revive_at_the_corpse() -> void:
	var state := _char("priest")
	var f := _fight(state, "barrow_wight", 5)
	assert_eq(f.run(20 * 600), "defeat", "a level-1 priest loses to a level-20 monster")
	assert_true(state["vitals"]["dead"], "dead is saved")
	assert_eq(RpgEncounter.revive_at_corpse(_db(), _pack(), state), "", "revive")
	var u := RpgUnit.player(_db(), _pack(), state)
	RpgEncounter.restore_vitals(u, state)
	assert_eq(int(u["hp"]), int(RpgTalents.js_round(float(u["max_hp"]) * 0.5)), "50% health")
	assert_eq(float(u["resource"]), RpgTalents.js_round(float(u["max_resource"]) * 0.5), "50% mana")
	assert_true(RpgEncounter.revive_at_corpse(_db(), _pack(), state) != "", "only the dead revive")


func test_corpse_loot_waits_on_the_corpse_and_survives_a_save() -> void:
	var state := _char("warrior")
	var found := false
	for seed in range(1, 40):
		state.erase("corpses")
		state.erase("vitals")
		var f := _fight(state, "shore_scuttler", seed)
		f.run(20 * 600)
		var corpse: Dictionary = state["corpses"][-1]
		if int(corpse["loot"]["copper"]) > 0 or not corpse["loot"]["items"].is_empty():
			found = true
			break
	assert_true(found, "some kill dropped loot")
	var back := RpgSave.from_dict(
		JSON.parse_string(JSON.stringify(RpgSave.to_dict(state))), _db(), _pack()
	)
	assert_eq(back["problems"].size(), 0, "loads")
	var copper_before := int(state["copper"])
	var loot_copper := int(state["corpses"][-1]["loot"]["copper"])
	assert_eq(RpgEncounter.take_loot(back["state"]), "", "taken after a reload")
	assert_eq(int(back["state"]["copper"]), copper_before + loot_copper, "copper once")
	assert_eq(RpgEncounter.take_loot(back["state"]), "Nothing to loot.", "only once")
	RpgEncounter.wait(_db(), _pack(), state, 61.0)
	assert_true(state["corpses"].is_empty(), "the corpse decays after CORPSE_DURATION")


# -- specs and talents -------------------------------------------------------------


func test_every_spec_applies_its_modifiers_to_the_runtime() -> void:
	var checked := 0
	for cls: String in CLASSES:
		for spec: Dictionary in RpgTalents.class_talents(_pack(), cls)["specs"]:
			var base := _char(cls, 20)
			var with_spec := _char(cls, 20)
			assert_eq(
				RpgCharacter.choose_spec(_db(), _pack(), with_spec, spec["id"]), "", spec["id"]
			)
			var u0 := RpgUnit.player(_db(), _pack(), base)
			var u1 := RpgUnit.player(_db(), _pack(), with_spec)
			var mods: Dictionary = u1["mods"]
			assert_eq(mods["spec"], spec["id"], spec["id"] + ": the unit carries the spec")
			var changed: bool = (
				u0["max_hp"] != u1["max_hp"]
				or u0["armor"] != u1["armor"]
				or u0["attack_power"] != u1["attack_power"]
				or u0["crit"] != u1["crit"]
				or u0["dodge"] != u1["dodge"]
				or u0["max_resource"] != u1["max_resource"]
				or u0["melee_haste"] != u1["melee_haste"]
				or u0["spell_haste"] != u1["spell_haste"]
			)
			var stat_mods := false
			for k: String in mods["stats"]:
				stat_mods = stat_mods or float(mods["stats"][k]) != 0.0
			for k: String in ["meleeHastePct", "spellHastePct", "manaPct"]:
				stat_mods = stat_mods or float(mods["global"][k]) != 0.0
			if stat_mods:
				assert_true(changed, spec["id"] + ": its stat modifiers change the unit")
			var f := _fight(with_spec)
			var known_ids: Array = f.known().map(func(k: Dictionary) -> String: return k["id"])
			for sig: String in spec["signature_ids"]:
				assert_true(sig in known_ids, spec["id"] + ": signature known: " + sig)
			checked += 1
	assert_eq(checked, 27, "27 specializations")


func test_protection_armor_modifiers_are_exact() -> void:
	var state := _char("warrior", 20)
	RpgCharacter.choose_spec(_db(), _pack(), state, "prot")
	var u := RpgUnit.player(_db(), _pack(), state)
	var m: Dictionary = u["mods"]["stats"]
	assert_true(float(m["armorPct"]) > 0.0, "prot raises armor by a percentage")
	var bare := RpgUnit.player(_db(), _pack(), _char("warrior", 20))
	var stats_armor := int(bare["stats"]["armor"])
	var sta := int(u["stats"]["sta"])
	assert_true(sta >= int(bare["stats"]["sta"]), "Stamina from staPct")
	var with_str := (
		stats_armor
		+ int(RpgTalents.js_round(float(u["stats"]["str"]) * float(m["armorFromStrPct"])))
	)
	var expected := int(RpgTalents.js_round(float(with_str) * (1.0 + float(m["armorPct"]))))
	assert_eq(int(u["armor"]), expected, "recalcPlayerStats order: +Str share, then x armorPct")


func test_a_talent_choice_changes_the_runtime() -> void:
	var done := 0
	for cls: String in CLASSES:
		for row: Dictionary in RpgTalents.class_talents(_pack(), cls)["rows"]:
			for o: Dictionary in row["options"]:
				var eff: Variant = o.get("effect")
				if not (eff is Dictionary):
					continue
				var state := _char(cls, 20)
				var before := RpgUnit.player(_db(), _pack(), state)
				assert_eq(
					RpgCharacter.choose_talent(_pack(), state, int(row["level"]), o["id"]),
					"",
					o["id"] + ": chosen"
				)
				var after := RpgUnit.player(_db(), _pack(), state)
				assert_true(after["mods"]["selected"].has(o["id"]), o["id"] + ": in the modifiers")
				if eff.get("stats") is Dictionary and float(eff["stats"].get("sta", 0)) > 0.0:
					assert_true(
						after["max_hp"] > before["max_hp"], o["id"] + ": Stamina raises health"
					)
					done += 1
				if eff.get("grant") is Dictionary:
					var f := _fight(state)
					var ids: Array = f.known().map(func(k: Dictionary) -> String: return k["id"])
					assert_true(eff["grant"]["ability"] in ids, o["id"] + ": grant known")
					done += 1
	assert_true(done > 5, "talent effects checked: %d" % done)
	var low := _char("warrior", 4)
	var first: Dictionary = RpgTalents.class_talents(_pack(), "warrior")["rows"][0]
	assert_eq(
		RpgCharacter.choose_talent(_pack(), low, 5, first["options"][0]["id"]),
		"That talent is not available.",
		"a row before its level"
	)


# -- abilities -----------------------------------------------------------------------


## A level-20 character of the ability's class that knows it (kit, spec or talent).
func _knower(ability_id: String) -> Dictionary:
	var doc: Dictionary = _pack()["abilities"][ability_id]
	var def: Dictionary = doc["def"]
	var state := _char(str(def["class"]), 20)
	var specs: Variant = def.get("specs")
	if specs is Array and not specs.is_empty():
		RpgCharacter.choose_spec(_db(), _pack(), state, str(specs[0]))
	for how: String in doc["acquired_by"]:
		var parts := how.split(" ")
		if parts.size() >= 3 and parts[1] != "talent" and parts[2] == "signature":
			RpgCharacter.choose_spec(_db(), _pack(), state, parts[1])
		if parts.size() >= 3 and parts[1] == "talent":
			for row: Dictionary in RpgTalents.class_talents(_pack(), parts[0])["rows"]:
				for o: Dictionary in row["options"]:
					if o["id"] == parts[2]:
						RpgCharacter.choose_talent(_pack(), state, int(row["level"]), o["id"])
	return state


func test_every_implemented_ability_does_what_its_effects_say() -> void:
	var tested := 0
	for id: String in _pack()["abilities"]:
		var doc: Dictionary = _pack()["abilities"][id]
		if not str(doc["status"]).begins_with("IMPLEMENTED"):
			continue
		var state := _knower(id)
		var f := _fight(state, "thicket_boar", 7, 4.0)
		f.command({"op": "auto", "on": false})
		var entry := f.known_entry(id)
		assert_true(not entry.is_empty(), id + ": known by its character")
		if entry.is_empty():
			continue
		f.player["resource"] = float(f.player["max_resource"])
		f.player["hp"] = int(f.player["max_hp"]) / 2
		var res_before := float(f.player["resource"])
		var mob_hp := int(f.mob["hp"])
		assert_eq(f.command({"op": "cast", "ability": id}), "", id + ": cast accepted")
		for _i in 80:
			if not f.player["casting"].is_empty() or not f.projectiles.is_empty() or _i < 2:
				f.step()
		var gained := false
		for e: Dictionary in entry["effects"]:
			gained = gained or e["type"] == "gainResource"
		if float(entry["cost"]) > 0.0 and not gained:
			assert_true(float(f.player["resource"]) < res_before, id + ": cost paid")
		if float(entry["cooldown"]) > 0.0:
			assert_true(f.player["cooldowns"].has(id), id + ": on cooldown")
		_assert_effects(f, id, entry, mob_hp)
		tested += 1
	assert_eq(tested, _implemented_count(), "every implemented ability exercised")


func _implemented_count() -> int:
	var n := 0
	for id: String in _pack()["abilities"]:
		n += int(str(_pack()["abilities"][id]["status"]).begins_with("IMPLEMENTED"))
	return n


func _resisted_or_avoided(f: RpgEncounter) -> bool:
	for e: Dictionary in f.events:
		if e["type"] == "damage" and str(e.get("kind")) in ["resist", "miss", "dodge", "parry"]:
			return true
	return false


func _has_aura(u: Dictionary, id_prefix: String) -> bool:
	for a: Dictionary in u["auras"]:
		if str(a["id"]).begins_with(id_prefix):
			return true
	return false


func _assert_effects(f: RpgEncounter, id: String, entry: Dictionary, mob_hp: int) -> void:
	var avoided := _resisted_or_avoided(f)
	for eff: Dictionary in entry["effects"]:
		match str(eff["type"]):
			"weaponStrike", "directDamage", "aoeDamage":
				assert_true(int(f.mob["hp"]) < mob_hp or avoided, id + ": damage landed or avoided")
			"dot", "stun", "incapacitate", "root", "slow":
				assert_true(
					_has_aura(f.mob, id) or avoided or f.mob["dead"], id + ": aura on the target"
				)
			"hot", "absorb", "selfBuff", "buffTarget":
				var own := (
					_has_aura(f.player, id) or _has_aura(f.player, str(eff.get("auraId", id)))
				)
				assert_true(own, id + ": aura on the caster")
			"heal":
				assert_true(int(f.player["hp"]) > int(f.player["max_hp"]) / 2, id + ": healed")
			"gainResource":
				assert_true(float(f.player["resource"]) > 0.0, id + ": resource gained")


func test_blocked_abilities_refuse_and_change_nothing() -> void:
	var refused := 0
	for id: String in _pack()["abilities"]:
		var doc: Dictionary = _pack()["abilities"][id]
		if doc["status"] != "BLOCKED" or doc["def"].get("passive", false):
			continue
		var state := _knower(id)
		var f := _fight(state)
		f.command({"op": "auto", "on": false})
		if f.known_entry(id).is_empty():
			continue
		var res := float(f.player["resource"])
		var why := f.command({"op": "cast", "ability": id})
		assert_true(
			why.begins_with("Not available in this build:"), id + ": refused with its reason"
		)
		assert_eq(float(f.player["resource"]), res, id + ": nothing spent")
		refused += 1
	assert_true(refused > 100, "blocked abilities checked: %d" % refused)


func test_cast_gates_use_the_reference_messages() -> void:
	var f := _fight(_knower("hamstring"), "thicket_boar", 9, 4.0)
	f.command({"op": "auto", "on": false})
	assert_eq(f.command({"op": "cast", "ability": "nope"}), "You do not know that ability.", "?")
	f.player["resource"] = 0.0
	assert_eq(f.command({"op": "cast", "ability": "hamstring"}), "Not enough rage!", "rage")
	f.player["resource"] = 100.0
	assert_eq(f.command({"op": "cast", "ability": "hamstring"}), "", "cast")
	assert_eq(
		f.command({"op": "cast", "ability": "hamstring"}),
		RpgEncounter.SILENT + "gcd",
		"the GCD refuses silently"
	)
	var far := _fight(_knower("hamstring"), "thicket_boar", 9, 15.0)
	far.command({"op": "auto", "on": false})
	far.player["resource"] = 100.0
	assert_eq(far.command({"op": "cast", "ability": "hamstring"}), "Out of range.", "range")
	var hoj := _fight(_knower("hammer_of_justice"), "thicket_boar", 9, 4.0)
	hoj.command({"op": "auto", "on": false})
	assert_eq(hoj.command({"op": "cast", "ability": "hammer_of_justice"}), "", "stun cast")
	hoj.player["gcd"] = 0.0
	assert_eq(
		hoj.command({"op": "cast", "ability": "hammer_of_justice"}),
		"That ability is not ready yet.",
		"cooldown"
	)


func test_auto_and_manual_combat_share_one_pipeline() -> void:
	var a := _char("rogue")
	var b := a.duplicate(true)
	var auto_fight := _fight(a, "shore_scuttler", 99)
	var manual := _fight(b, "shore_scuttler", 99)
	manual.command({"op": "auto", "on": false})
	assert_eq(manual.command({"op": "attack"}), "", "manual attack")
	auto_fight.run(20 * 600)
	manual.run(20 * 600)
	assert_eq(manual.outcome, auto_fight.outcome, "same outcome")
	assert_eq(manual.events, auto_fight.events, "the same swings, draw for draw")


func test_a_stunned_monster_does_not_swing() -> void:
	var f := _fight(_knower("hammer_of_justice"), "thicket_boar", 4, 4.0)
	f.command({"op": "auto", "on": false})
	f.command({"op": "cast", "ability": "hammer_of_justice"})
	for _i in 10:
		f.step()
	if _has_aura(f.mob, "hammer_of_justice"):
		var swings_before := 0
		for e: Dictionary in f.events:
			swings_before += int(e["type"] == "damage" and int(e.get("source", 0)) == 2)
		for _i in 20:
			f.step()
		var swings_after := 0
		for e: Dictionary in f.events:
			swings_after += int(e["type"] == "damage" and int(e.get("source", 0)) == 2)
		assert_eq(swings_after, swings_before, "no swing while stunned")
	else:
		assert_true(_resisted_or_avoided(f), "the stun was resisted")


func test_a_street_of_monsters_is_one_engine() -> void:
	var state := _char("warrior", 3)
	var spawns := [
		{"monster": "shore_scuttler", "x": 8.0}, {"monster": "shore_scuttler", "x": 40.0}
	]
	var z := RpgEncounter.start_zone(_db(), _pack(), state, spawns, RpgRng.seeded(21), 0.0)
	assert_eq(z.mobs.size(), 2, "two monsters on the street")
	assert_eq(z.distance(), INF, "no target yet")
	z.command({"op": "auto", "on": false})
	assert_eq(z.command({"op": "attack"}), "Invalid attack target.", "the reference's message")
	assert_eq(z.command({"op": "target_nearest"}), "", "target the nearest")
	assert_eq(int(z.mob["id"]), 2, "the near one")
	z.command({"op": "move", "dir": 1})
	for _i in 20:
		z.step()
	assert_near(
		float(z.player["x"]), float(_pack()["constants"]["run_speed"]), "1 s at RUN_SPEED", 0.01
	)
	z.command({"op": "move", "dir": 0})
	z.command({"op": "auto", "on": true})
	assert_eq(z.run(20 * 900), "victory", "both monsters beaten by the same engine")
	assert_eq(int(state["kills"]), 2, "two kills credited")
	assert_eq(state["corpses"].size(), 2, "two corpses")


func test_a_living_street_respawns_on_the_reference_schedule() -> void:
	var state := _char("warrior", 3)
	var spawns := [{"monster": "shore_scuttler", "x": 30.0}, {"monster": "void_stalker", "x": 60.0}]
	var z := RpgEncounter.start_zone(_db(), _pack(), state, spawns, RpgRng.seeded(5), 0.0)
	z.respawn = true
	z.command({"op": "auto", "on": false})
	for m: Dictionary in z.mobs.duplicate():
		z.kill(z.player, m)
	assert_eq(z.outcome, "fighting", "a living street never ends in victory")
	var own := float(_pack()["trial_monsters"]["shore_scuttler"]["respawn_seconds"])
	var world := float(_pack()["constants"]["trash_respawn_seconds"])
	assert_eq(world, 60.0, "TRASH_RESPAWN_SECONDS")
	for _i in int(own * 20.0) + 1:
		z.step()
	assert_true(not z.unit(2)["dead"], "its own respawnSeconds wins (respawn_policy.ts)")
	assert_true(z.unit(3)["dead"], "the other waits for the world's delay")
	assert_eq(float(z.unit(2)["x"]), 30.0, "back at its spawn point")
	for _i in int((world - own) * 20.0) + 1:
		z.step()
	assert_true(not z.unit(3)["dead"], "risen after TRASH_RESPAWN_SECONDS")
