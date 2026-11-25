extends SkillsCase
## The skills port's class engines beyond the warrior (docs/SKILLS_PORT.md): the rogue's
## stealth, combo points, finishers, spec engines and poisons; the mage's Hot Streak,
## Ignite, Cauterize, Icicles, Frost Nova's freeze, ground areas and Ice Block.

# -- rogue ------------------------------------------------------------------------------


func test_rogue_openers_need_stealth_and_monsters_see_less() -> void:
	var f := _sturdy(_street(_char("rogue", 10), [1.5]))
	assert_eq(_cast(f, "garrote"), "You must be stealthed.", "an opener outside stealth")
	assert_eq(_cast(f, "stealth"), "", "stealth")
	assert_true(RpgStealth.is_stealthed(f.player), "stealthed")
	assert_eq(_cast(f, "garrote"), "", "the opener from stealth")
	assert_true(not RpgStealth.is_stealthed(f.player), "the opener breaks stealth")
	assert_eq(int(f.player["combo_points"]), 1, "and awards its combo point")
	assert_true(RpgRogue.detection_mult(10, 10) < 1.0, "equal level sees a quarter as far")


func test_finishers_spend_combo_points_by_their_count() -> void:
	var f := _sturdy(_street(_char("rogue", 10), [1.5]))
	assert_eq(_cast(f, "eviscerate"), "That ability requires combo points.", "none yet")
	f.player["combo_points"] = 3
	f.player["combo_until"] = 99.0
	var hp := int(f.mob["hp"])
	assert_eq(_cast(f, "eviscerate"), "", "a finisher")
	assert_eq(int(f.player["combo_points"]), 0, "points spent")
	assert_true(int(f.mob["hp"]) < hp, "damage by the points")
	f.player["combo_points"] = 2
	f.player["combo_until"] = 99.0
	assert_eq(_cast(f, "slice_and_dice"), "", "Slice and Dice")
	var snd := RpgAbilityRules.find_kind(f.player, "buff_haste")
	assert_near(float(snd["duration"]), 12.0 + 4.0 * 2, "12 s + 4 s per point")


func test_combat_redline_turns_sinister_strike_into_body_blow() -> void:
	var f := _sturdy(_street(_char("rogue", 10, "combat"), [1.5]))
	f.player["combo_points"] = 4
	f.player["combo_until"] = 99.0
	_cast(f, "eviscerate")
	assert_true(not RpgAbilityRules.find_kind(f.player, "redline").is_empty(), "Redline opens")
	assert_eq(str(f.known_entry("sinister_strike")["id"]), "body_blow", "the button swaps")
	assert_eq(str(f.known_entry("eviscerate")["id"]), "knockout_blow", "and the finisher")


func test_assassination_venom_ritual_stages() -> void:
	var f := _sturdy(_street(_char("rogue", 14, "assassination"), [1.5]))
	_cast(f, "venom_dart")
	f.run(10)
	var ritual := RpgAbilityRules.find_kind(f.player, "venom_ritual")
	assert_true(not ritual.is_empty() and int(ritual["stacks"]) == 1, "a stage")


func test_a_poison_coat_rides_the_swings() -> void:
	var f := _sturdy(_street(_char("rogue", 14), [1.5]))
	assert_eq(_cast(f, "deadly_poison"), "", "coated")
	f.command({"op": "attack"})
	f.run(200)
	var coat := {}
	for a: Dictionary in f.mob["auras"]:
		if a["id"] == "deadly_poison":
			coat = a
	assert_true(not coat.is_empty(), "the poison landed")


func test_vanish_drops_every_monster() -> void:
	var f := _sturdy(_street(_char("rogue", 18), [1.5, 3.0]))
	for m: Dictionary in f.mobs:
		m["engaged"] = true
	assert_eq(_cast(f, "vanish"), "", "Vanish")
	for m: Dictionary in f.mobs:
		assert_true(not m["engaged"], "dropped")
	f.run(5)
	for m: Dictionary in f.mobs:
		assert_true(not m["engaged"], "and cannot find the player")


# -- mage -------------------------------------------------------------------------------


func test_two_fire_crits_light_hot_streak() -> void:
	var f := _sturdy(_street(_char("mage", 10, "fire"), [20.0]))
	RpgMage.note_spell_hit(f, f.player, true, "fireball")
	assert_true(_has_aura(f.player, "heating_up"), "the first crit heats up")
	RpgMage.note_spell_hit(f, f.player, true, "fireball")
	assert_true(_has_aura(f.player, "hot_streak"), "the second makes Hot Streak")
	assert_true(not RpgMage.ice_floes_for(f.player, "pyroblast").size() > 0, "no floes")
	assert_true(
		RpgMage.fire_guaranteed_crit(f.player, f.known_entry("fire_blast")["def"], f.mob),
		"Fire Blast always crits"
	)


func test_a_fire_crit_ignites_and_cauterize_saves_once() -> void:
	var f := _sturdy(_street(_char("mage", 10, "fire"), [20.0]))
	RpgCombat.deal_damage(f, f.player, f.mob, 100, true, "fire", "Fireball")
	assert_true(_has_aura(f.mob, "ignite"), "the crit ignites")
	var p := f.player
	RpgCombat.deal_damage(f, f.mob, p, int(p["max_hp"]) * 3, false, "physical", "")
	assert_true(not p["dead"] and int(p["hp"]) > 0, "Cauterize saves")
	assert_true(_has_aura(p, "cauterizing"), "and burns")


func test_frostbolt_builds_icicles_for_glacial_spike() -> void:
	var f := _sturdy(_street(_char("mage", 16, "frost"), [20.0]))
	for i in 5:
		RpgMage.after_cast(f, f.player, f.known_entry("frostbolt")["def"], f.mob)
	var icicles := RpgAbilityRules.find_kind(f.player, "icicles")
	assert_eq(int(icicles["stacks"]), 5, "five Icicles")
	assert_true(
		RpgAbilityRules.has_required_aura(f.player, f.known_entry("glacial_spike")["def"]),
		"Glacial Spike opens"
	)


func test_frost_nova_roots_and_freezes_for_ice_lance() -> void:
	var f := _sturdy(_street(_char("mage", 10, "frost"), [3.0, 5.0]))
	assert_eq(_cast(f, "frost_nova"), "", "Frost Nova")
	for m: Dictionary in f.mobs:
		assert_true(_has_aura(m, "frost_nova_root"), "rooted")
	var frozen := RpgMage.frozen_cast(f, f.player, f.known_entry("ice_lance")["def"], f.mob)
	assert_near(float(frozen.get("damage_mult", 0.0)), 3.0, "Ice Lance x3 on a frozen target")


func test_blizzard_lays_a_ground_area_that_pulses() -> void:
	var f := _sturdy(_street(_char("mage", 10, "frost"), [3.0]))
	assert_eq(_cast(f, "blizzard"), "", "Blizzard")
	f.run(60)
	assert_true(_has_aura(f.mob, "blizzard_slow") or int(f.mob["hp"]) < 100000, "the area struck")


func test_ice_block_refuses_control_and_toggles_off() -> void:
	var f := _sturdy(_street(_char("mage", 12), [3.0]))
	assert_eq(_cast(f, "ice_block"), "", "Ice Block")
	assert_true(_has_aura(f.player, "ice_block"), "in stasis")
	RpgEffects.apply_simple(f, f.player, "x_stun", "stun", 3.0, 0.0, f.mob, {"school": "physical"})
	assert_true(not _has_aura(f.player, "x_stun"), "control refused")
	f.player["cooldowns"].clear()
	assert_eq(_cast(f, "ice_block"), "", "pressed again")
	assert_true(not _has_aura(f.player, "ice_block"), "it ends")


# -- priest -----------------------------------------------------------------------------


func test_discipline_doctrine_turns_smite_into_healing() -> void:
	var f := _sturdy(_street(_char("priest", 10, "discipline"), [20.0]))
	assert_eq(_cast(f, "power_word_shield"), "", "the shield links Doctrine")
	assert_true(_has_aura(f.player, "priest_doctrine"), "linked")
	f.player["hp"] = int(f.player["max_hp"]) / 2
	var hp := int(f.player["hp"])
	RpgCombat.deal_damage(
		f, f.player, f.mob, 100, false, "holy", "Smite", "hit", false, {"ability_id": "smite"}
	)
	assert_true(int(f.player["hp"]) > hp, "the smite healed the priest")


func test_shadow_mind_blast_binds_an_effigy_and_banks_gloomtithe() -> void:
	var f := _sturdy(_street(_char("priest", 16, "shadow"), [20.0]))
	assert_eq(_cast(f, "shadow_word_pain"), "", "Dirge")
	f.run(20)
	RpgCombat.deal_damage(
		f,
		f.player,
		f.mob,
		50,
		false,
		"shadow",
		"Mind Blast",
		"hit",
		false,
		{"ability_id": "mind_blast"}
	)
	assert_true(_has_aura(f.mob, "priest_effigy"), "the Effigy binds")
	assert_true(
		not RpgAbilityRules.find_kind(f.player, "gloomtithe").is_empty(), "Gloomtithe banks"
	)


func test_holy_nova_heals_the_caster() -> void:
	var f := _sturdy(_street(_char("priest", 10, "holy"), [3.0]))
	f.player["hp"] = int(f.player["max_hp"]) / 2
	var hp := int(f.player["hp"])
	assert_eq(_cast(f, "holy_nova"), "", "Holy Nova")
	assert_true(int(f.player["hp"]) > hp, "healed")
