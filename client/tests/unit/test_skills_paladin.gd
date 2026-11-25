extends SkillsCase
## The paladin's port (docs/SKILLS_PORT.md): Devotion and Divine Ascension
## (paladin_devotion.ts), Debt of Light, thorns and Requital, Oath Chain, Sun God's
## Verdict, Valkyr's Calling, Veilbound March, Aegis of the First Dawn, Consecration
## and the Devotion family choice.


func _devotion(f: RpgEncounter) -> int:
	return int(f.player.get("paladin_devotion", {}).get("value", 0))


func test_a_landed_hammer_of_grace_grants_devotion() -> void:
	var f := _sturdy(_street(_char("paladin", 10), [3.0]))
	assert_eq(_cast(f, "hammer_of_grace"), "", "Hammer of Grace")
	f.run(40)
	assert_eq(_devotion(f), 1, "one Devotion for the effective hit")


func test_divine_ascension_needs_full_devotion_and_empowers_five_abilities() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "retribution"), [1.5]))
	assert_eq(_cast(f, "divine_ascension"), "That ability is not ready yet.", "below 20")
	f.player["paladin_devotion"]["value"] = 20
	assert_eq(_cast(f, "divine_ascension"), "", "at 20 it ascends")
	assert_true(RpgPaladin.ascension_active(f.player), "ascended")
	assert_eq(_devotion(f), 0, "the bank is spent")
	assert_eq(int(f.player["paladin_devotion"]["ascension_charges"]), 5, "five charges")
	assert_true(_has_aura(f.player, "divine_ascension"), "its aura")
	# Hammer of Wrath ignores its execute window while ascended, and spends a charge.
	assert_eq(_cast(f, "hammer_of_wrath"), "", "Hammer of Wrath on a healthy target")
	f.run(40)
	assert_eq(int(f.player["paladin_devotion"]["ascension_charges"]), 4, "a charge spent")
	assert_eq(_devotion(f), 0, "no Devotion while ascended")


func test_ascension_makes_dawns_embrace_instant_and_stronger() -> void:
	var f := _street(_char("paladin", 20, "holy"), [20.0])
	var plain := f.known_entry("dawns_embrace")
	f.player["paladin_devotion"] = {
		"value": 0,
		"ascension_charges": 5,
		"ascension_remaining": 45.0,
		"out_of_combat_time": 0.0,
		"block_icd": 0.0,
	}
	var asc := f.known_entry("dawns_embrace")
	assert_near(float(asc["castTime"]), 0.0, "instant while ascended")
	assert_near(
		float(asc["effects"][0]["min"]), roundf(float(plain["effects"][0]["min"]) * 1.35), "x1.35"
	)


func test_debt_of_light_soaks_a_blow_and_answers_it() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "retribution"), [1.5]))
	assert_eq(_cast(f, "faithforged_guard"), "", "Faithforged Guard")
	assert_true(
		not RpgAbilityRules.find_kind(f.player, "paladin_debt_of_light").is_empty(), "armed"
	)
	var mob_hp := int(f.mob["hp"])
	var hp := int(f.player["hp"])
	RpgCombat.deal_damage(f, f.mob, f.player, 100, false, "physical", "")
	assert_eq(int(f.player["hp"]), hp, "the 100 soaked (cap 140)")
	assert_eq(mob_hp - int(f.mob["hp"]), 100, "and answered as holy damage")
	assert_eq(_devotion(f), 1, "a Devotion")
	assert_true(RpgAbilityRules.find_kind(f.player, "paladin_debt_of_light").is_empty(), "spent")


func test_requital_reflects_and_rides_the_swing() -> void:
	var f := _sturdy(_street(_char("paladin", 20), [1.5]))
	assert_eq(_cast(f, "retribution_aura"), "", "Requital Aura")
	var hp := int(f.mob["hp"])
	RpgThorns.react(f, f.player, f.mob)
	assert_true(int(f.mob["hp"]) < hp, "a melee attacker takes the thorns")
	assert_eq(_cast(f, "devotion_ward"), "", "the other aura choice")
	assert_true(not _has_aura(f.player, "retribution_aura"), "replaces Requital (one family)")
	assert_eq(_cast(f, "dawn_devotion"), "", "a long devotion")
	assert_true(_has_aura(f.player, "devotion_ward"), "is another family")


func test_oath_chain_reels_the_target_in_then_slows_it() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "protection"), [20.0]))
	assert_eq(_cast(f, "oath_chain"), "", "Oath Chain")
	assert_true(_has_aura(f.mob, "oath_chain_pull"), "reeling")
	f.run(60)
	assert_true(absf(float(f.mob["x"]) - float(f.player["x"])) <= 3.5, "drawn to the stop")
	assert_true(_has_aura(f.mob, "oath_chain_slow"), "then slowed")


func test_sun_gods_verdict_detonates_on_the_third_final_edict() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "retribution"), [1.5]))
	assert_eq(_cast(f, "sun_gods_verdict"), "", "the mark")
	var mark := RpgPaladinKit.verdict_mark(f.player, f.mob, "final_edict")
	assert_true(not mark.is_empty(), "marked")
	RpgPaladinKit.advance_verdict(f, f.player, f.mob, "final_edict", mark)
	RpgPaladinKit.advance_verdict(f, f.player, f.mob, "final_edict", mark)
	assert_eq(int(mark["stacks"]), 2, "two charges")
	var hp := int(f.mob["hp"])
	RpgPaladinKit.advance_verdict(f, f.player, f.mob, "final_edict", mark)
	assert_true(hp - int(f.mob["hp"]) >= 360, "the third detonates (360-420 x1.5)")


func test_valkyrs_calling_flies_lands_and_strikes() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "retribution"), [15.0]))
	assert_eq(_cast(f, "valkyrs_calling"), "", "Valkyr's Calling")
	assert_true(RpgPaladinKit.valkyr_airborne(f.player), "airborne")
	var hp := int(f.player["hp"])
	RpgCombat.deal_damage(f, f.mob, f.player, 50, false, "physical", "")
	assert_eq(int(f.player["hp"]), hp, "untouchable in the air")
	assert_eq(_cast(f, "hammer_of_justice"), "You are busy.", "no casts")
	var mob_hp := int(f.mob["hp"])
	f.run(50)
	assert_true(not RpgPaladinKit.valkyr_airborne(f.player), "landed")
	assert_near(float(f.player["x"]), 15.0, "on the target's spot")
	assert_true(int(f.mob["hp"]) < mob_hp, "the landing strikes")


func test_veilbound_march_marks_what_it_passes_and_bursts() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "protection"), [4.0]))
	assert_eq(_cast(f, "veilbound_march"), "", "Veilbound March")
	f.move_dir = 1
	f.run(10)
	assert_true(_has_aura(f.mob, "veilbound_mark"), "the monster passed is marked")
	assert_eq(_devotion(f), 1, "the first mark grants Devotion")
	f.move_dir = 0
	var hp := int(f.mob["hp"])
	f.run(80)
	assert_true(hp - int(f.mob["hp"]) >= 36, "the march's end bursts the marked")


func test_aegis_of_the_first_dawn_guards_and_heals_through_its_channel() -> void:
	var f := _street(_char("paladin", 20, "holy"), [40.0])
	f.player["hp"] = 50
	assert_eq(_cast(f, "aegis_first_dawn"), "", "Aegis")
	f.run(2)
	assert_true(not RpgAbilityRules.find_kind(f.player, "shield_wall").is_empty(), "the cut")
	f.run(120)
	assert_true(int(f.player["hp"]) > 50, "healed")
	assert_true(_has_aura(f.player, "aegis_first_dawn_speed"), "and the closing speed")
	assert_true(RpgAbilityRules.find_kind(f.player, "shield_wall").is_empty(), "cut ends")


func test_consecration_grants_devotion_once_and_guards_protection() -> void:
	var f := _sturdy(_street(_char("paladin", 20, "protection"), [1.5, 2.5]))
	assert_eq(_cast(f, "consecration"), "", "Consecration")
	f.run(60)
	assert_eq(_devotion(f), 1, "one Devotion for the zone's first effective pulse")
	assert_near(RpgPaladinProcs.consecration_dr(f, f.player), 0.1, "10% cut while inside")
	f.player["x"] = 30.0
	assert_near(RpgPaladinProcs.consecration_dr(f, f.player), 0.0, "none outside")
