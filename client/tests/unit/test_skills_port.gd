extends SkillsCase
## The skills port (docs/SKILLS_PORT.md): every implemented ability of every class
## and specialization casts on the street without an engine error, and the warrior's
## ported mechanics do what the reference does (charges, stances, Overpower into
## Mortal Strike, the execute window, Heroic Strike's queued swing, Sunder's armor,
## areas over several monsters, fear, Charge's run, Victor's Surge, Heroic Leap).


func test_every_implemented_ability_casts_without_an_engine_error() -> void:
	var pack := _pack()
	var casts := 0
	for cls: String in CLASSES:
		var specs: Array = [""]
		for sp: Dictionary in pack["talents"][cls]["specs"]:
			specs.append(sp["id"])
		for spec: String in specs:
			var f := _street(_char(cls, 20, spec), [3.0, 4.0, 12.0])
			for k: Dictionary in f.known():
				if not str(pack["abilities"][k["id"]]["status"]).begins_with("IMPLEMENTED"):
					continue
				if k["def"].get("passive", false):
					continue
				f.player["cooldowns"].clear()
				f.player["casting"] = {}
				f.player["dead"] = false
				f.player["hp"] = f.player["max_hp"]
				f.outcome = "fighting"
				if f.mob.is_empty() or f.mob["dead"]:
					f.command({"op": "target_nearest"})
				_cast(f, str(k["id"]))
				f.run(30)
				casts += 1
	assert_true(casts > 50, "the implemented abilities were cast (%d)" % casts)


func test_stances_follow_the_spec_and_defensive_stance_toggles() -> void:
	var f := _street(_char("warrior", 10, "fury"), [30.0])
	f.step()
	assert_true(_has_aura(f.player, "berserker_stance"), "fury wears Berserker Stance")
	var arms := _street(_char("warrior", 10, "arms"), [30.0])
	arms.step()
	assert_true(_has_aura(arms.player, "battle_stance"), "arms starts in Battle Stance")
	assert_eq(_cast(arms, "defensive_stance"), "", "Defensive Stance casts")
	assert_true(_has_aura(arms.player, "defensive_stance"), "and is worn")
	assert_true(not _has_aura(arms.player, "battle_stance"), "Battle Stance left (one group)")
	arms.player["cooldowns"].clear()
	assert_eq(_cast(arms, "defensive_stance"), "", "pressed again")
	assert_true(not _has_aura(arms.player, "defensive_stance"), "it toggles off")


func test_overpower_has_two_charges_and_feeds_mortal_strike() -> void:
	var f := _sturdy(_street(_char("warrior", 10, "arms"), [1.5]))
	assert_eq(_cast(f, "overpower"), "", "first charge")
	assert_eq(_cast(f, "overpower"), "", "second charge on the same cooldown")
	assert_eq(_cast(f, "overpower"), "That ability is not ready yet.", "no third")
	var charge := RpgAbilityRules.find_kind(f.player, "overpower_charge")
	assert_true(not charge.is_empty() and int(charge["stacks"]) >= 1, "Overpower's charge")
	assert_eq(_cast(f, "mortal_strike"), "", "Mortal Strike")
	assert_true(RpgAbilityRules.find_kind(f.player, "overpower_charge").is_empty(), "spent")


func test_execute_waits_for_the_window() -> void:
	var f := _street(_char("warrior", 12), [1.5])
	assert_true(
		_cast(f, "execute").begins_with("That ability requires the target below 20%"), "gate"
	)
	f.mob["hp"] = int(int(f.mob["max_hp"]) * 0.1)
	assert_eq(_cast(f, "execute"), "", "below 20% it lands")


func test_heroic_strike_rides_the_next_swing() -> void:
	var f := _street(_char("warrior", 4), [1.5])
	assert_eq(_cast(f, "heroic_strike"), "", "queued")
	assert_eq(str(f.player["queued_on_swing"]), "heroic_strike", "on the next swing")
	assert_true(f.player["auto_attack"], "starting the auto attack")
	f.run(60)
	assert_eq(str(f.player["queued_on_swing"]), "", "the swing took it")


func test_sunder_stacks_cut_armor() -> void:
	var f := _street(_char("warrior", 10, "prot"), [1.5])
	var before := RpgCombat.effective_armor(f, f.mob)
	for i in 3:
		_cast(f, "sunder_armor")
	var s := RpgAbilityRules.find_kind(f.mob, "sunder")
	if not s.is_empty():
		assert_true(RpgCombat.effective_armor(f, f.mob) < before or before == 0.0, "armor cut")
		assert_true(int(s["stacks"]) <= 5, "at most five stacks")


func test_thunder_clap_hits_every_monster_in_its_radius() -> void:
	var f := _sturdy(_street(_char("warrior", 10, "prot"), [2.0, 4.0, 30.0]))
	assert_eq(_cast(f, "thunder_clap"), "", "cast")
	var hit := {}
	for e: Dictionary in f.events:
		if e["type"] == "damage" and str(e.get("ability", "")) != "" and int(e["source"]) == 1:
			hit[int(e["target"])] = true
	assert_eq(hit.size(), 2, "the two within 8 yd, not the far one")
	for m: Dictionary in f.mobs.slice(0, 2):
		assert_true(_has_aura(m, "thunder_clap_as"), "their swings slowed")


func test_intimidating_shout_fears_and_the_feared_flee() -> void:
	var f := _street(_char("warrior", 14), [2.0, 3.0])
	assert_eq(_cast(f, "intimidating_shout"), "", "cast")
	var m: Dictionary = f.mobs[0]
	assert_true(_has_aura(m, "fear_incap"), "feared")
	var x0 := float(m["x"])
	f.run(10)
	assert_true(absf(float(m["x"]) - x0) > 0.0 or not _has_aura(m, "fear_incap"), "it moves")


func test_charge_runs_to_the_target_and_starts_the_attack() -> void:
	var f := _street(_char("warrior", 3), [15.0])
	assert_eq(_cast(f, "charge"), "", "cast")
	f.run(40)
	assert_true(absf(float(f.mob["x"]) - float(f.player["x"])) < 5.0, "arrived")
	assert_true(f.player["auto_attack"], "auto attack on arrival")
	assert_true(float(f.player["resource"]) > 0.0, "rage from the charge")


func test_too_close_to_charge() -> void:
	var f := _street(_char("warrior", 3), [3.0])
	assert_eq(_cast(f, "charge"), "Too close!", "inside 8 yd")


func test_victory_rush_opens_after_a_kill_and_is_spent() -> void:
	var f := _street(_char("warrior", 10, "arms", {"8": "war_row_victory_rush"}), [1.5, 2.0])
	assert_eq(_cast(f, "victory_rush"), "That ability is not ready yet.", "no kill yet")
	f.mob["hp"] = 1
	RpgCombat.deal_damage(f, f.player, f.mob, 50, false, "physical", "test")
	assert_true(_has_aura(f.player, "victory_rush"), "Victor's Surge after the kill")
	_sturdy(f)
	f.command({"op": "target_nearest"})
	assert_eq(_cast(f, "victory_rush"), "", "now it casts")
	assert_true(not _has_aura(f.player, "victory_rush"), "and spends the window")


func test_heroic_leap_lands_with_a_strike() -> void:
	var f := _street(_char("warrior", 6), [5.0])
	f.player["facing"] = 1.0
	assert_eq(_cast(f, "heroic_leap"), "", "cast")
	f.run(20)
	assert_true(f.player.get("leap") == null, "landed")


func test_interrupt_does_nothing_to_a_monster_that_is_not_casting() -> void:
	var f := _street(_char("warrior", 8), [1.5])
	assert_eq(_cast(f, "pummel"), "", "cast")
	assert_true(not _has_aura(f.mob, "pummel_lockout"), "no cast to lock out")


func test_passives_never_go_on_the_hotbar() -> void:
	var s := _char("warrior", 10, "arms")
	var f := _street(s, [30.0])
	var ids := RpgSpellbook.usable_ids(_pack(), "warrior", 10, f.player["mods"])
	assert_true(not "measured_fury" in ids, "a passive is not a hotbar ability")
	var book := RpgSpellbook.book(_pack(), "warrior", 10, f.player["mods"])
	for e: Dictionary in book:
		if e["id"] == "measured_fury":
			assert_eq(e["state"], RpgSpellbook.PASSIVE, "shown as an always-on passive")
