extends SkillsCase
## The shaman's port (docs/SKILLS_PORT.md): Thunder Charges and their vent, the shared
## shock cooldown, Warspirit's cadence into Stormcast, the Mending Current and the
## charge-limited Thunder Ward.


func test_arc_bolts_bank_thunder_that_earthen_jolt_vents() -> void:
	var f := _sturdy(_street(_char("shaman", 20, "elemental"), [10.0]))
	RpgShaman.add_thunder_charges(f, f.player, 4)
	assert_eq(RpgShaman.thunder_charges(f.player), 4, "four charges banked")
	assert_near(RpgShaman.thundercall_damage_mult(f, f.player, "earth_shock"), 2.0, "+25% each")
	assert_eq(_cast(f, "earth_shock"), "", "Earthen Jolt")
	f.run(40)
	assert_eq(RpgShaman.thunder_charges(f.player), 0, "the vent spends the bank")


func test_the_shocks_share_one_cooldown() -> void:
	var f := _sturdy(_street(_char("shaman", 20), [10.0]))
	assert_eq(_cast(f, "earth_shock"), "", "Earthen Jolt")
	assert_eq(_cast(f, "frost_shock"), "That ability is not ready yet.", "the other shocks wait")
	assert_eq(_cast(f, "flame_shock"), "That ability is not ready yet.", "all of them")


func test_warspirit_cadence_arms_stormcast_on_the_third_swing() -> void:
	var f := _sturdy(_street(_char("shaman", 20, "enhancement"), [1.5]))
	assert_eq(_cast(f, "galeheart_weapon"), "", "Galeheart posture")
	assert_eq(RpgShamanWar.posture(f.player), "galeheart", "worn")
	for i in 3:
		RpgShamanWar.advance_cadence(f, f.player, f.mob, 40)
	assert_true(_has_aura(f.player, RpgShamanWar.STORMCAST_ID), "Stormcast armed")
	assert_true(_has_aura(f.player, RpgShamanWar.STORMCAST_CHEAP_ID), "and half price")
	assert_eq(RpgShamanWar.cadence(f.player), 0, "the cadence restarts")


func test_mending_waters_banks_a_current_that_pays_out() -> void:
	var f := _street(_char("shaman", 20, "restoration"), [40.0])
	f.player["hp"] = 60
	assert_eq(_cast(f, "healing_wave"), "", "Mending Waters")
	f.run(int(2.6 / f.dt))
	var cur := RpgShamanKit.current(f.player, int(f.player["id"]))
	assert_true(not cur.is_empty() and float(cur["value"]) > 0.0, "a Mending Current banked")
	var hp := int(f.player["hp"])
	f.run(int(4.0 / f.dt))
	assert_true(int(f.player["hp"]) > hp, "it pays out over time")


func test_thunder_ward_spends_a_charge_per_reflect() -> void:
	var f := _sturdy(_street(_char("shaman", 20), [1.5]))
	assert_eq(_cast(f, "lightning_shield"), "", "Thunder Ward")
	var ward := RpgAbilityRules.find_kind(f.player, "thorns")
	var hp := int(f.mob["hp"])
	RpgThorns.react(f, f.player, f.mob)
	assert_true(int(f.mob["hp"]) < hp, "the attacker is struck")
	assert_eq(int(ward["charges"]), 2, "a charge spent")
	hp = int(f.mob["hp"])
	RpgThorns.react(f, f.player, f.mob)
	assert_eq(int(f.mob["hp"]), hp, "inside its internal cooldown nothing more")
