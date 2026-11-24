extends TestCase
## Phase B2.1 and B2.2 registries (docs/PHASE_B2_PLAN.md) against the values read
## in World of ClaudeCraft source at the commit the registry records:
## * the nine classes and their 27 specialisations (talents_classic.ts,
##   talents_warrior.ts, spec_primary_stat.ts), the spec level and talent rows
##   (talents.ts, talent_rows.ts);
## * the 13 equipment slots and the class equipment rules (types.ts,
##   equipment_rules.ts), and the isolated legacy Charm slot (ADAPTED);
## * gameplay still runs on the legacy six slots (nothing switched over).

const COMMIT := "d2b91e0884cb269422c28d0b42d2a30a01de130a"
## [spec id, role, primary stat, signature ability], from the source.
const SPECS := {
	"warrior":
	[
		["arms", "dps", "str", "mortal_strike"],
		["fury", "dps", "str", "bloodthirst"],
		["prot", "tank", "str", "shield_slam"]
	],
	"paladin":
	[
		["holy", "healer", "int", "mercy_lance"],
		["protection", "tank", "str", "sunward_disc"],
		["retribution", "dps", "str", "final_edict"]
	],
	"hunter":
	[
		["beast_mastery", "dps", "agi", "bestial_wrath"],
		["marksmanship", "dps", "agi", "cold_focus"],
		["survival", "dps", "agi", "bloodhook"]
	],
	"rogue":
	[
		["assassination", "dps", "agi", "cold_blood"],
		["combat", "dps", "agi", "blade_flurry"],
		["subtlety", "dps", "agi", "hemorrhage"]
	],
	"priest":
	[
		["discipline", "healer", "int", "scouring_mercy"],
		["holy", "healer", "int", "seraphic_vigil"],
		["shadow", "dps", "int", "summon_tithefiend"]
	],
	"shaman":
	[
		["elemental", "dps", "int", "elemental_mastery"],
		["enhancement", "dps", "str", "stormstrike"],
		["restoration", "healer", "int", "chain_heal"]
	],
	"mage":
	[
		["arcane", "healer", "int", "temporal_mend"],
		["fire", "dps", "int", "pyroblast"],
		["frost", "dps", "int", "ice_lance"]
	],
	"warlock":
	[
		["affliction", "dps", "int", "evil_eye"],
		["demonology", "dps", "int", "metamorphosis"],
		["destruction", "dps", "int", "conflagrate"]
	],
	"druid":
	[
		["balance", "dps", "int", "moonkin_form"],
		["feral", "tank", "str", "feral_charge"],
		["restoration", "healer", "int", "swiftmend"]
	],
}
const ARMOR := {
	"warrior": "mail",
	"paladin": "mail",
	"shaman": "mail",
	"druid": "leather",
	"rogue": "leather",
	"hunter": "leather",
	"priest": "cloth",
	"mage": "cloth",
	"warlock": "cloth",
}
const SLOTS: Array[String] = [
	"mainhand",
	"offhand",
	"helmet",
	"neck",
	"shoulder",
	"chest",
	"waist",
	"legs",
	"gloves",
	"feet",
	"ring1",
	"ring2",
	"trinket",
]


func _reference_abilities() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(
		"../data/reference/woc_abilities_index.json"
	)
	return JSON.parse_string(FileAccess.get_file_as_string(path))["abilities"]


func test_registries_load_without_problems() -> void:
	var content := GameSession.content
	assert_eq(RpgClassRegistry.problems(content).size(), 0, "class registry valid")
	assert_eq(RpgEquipmentRules.problems(content).size(), 0, "equipment registry valid")
	assert_eq(content.errors.size(), 0, "content still validates")


func test_nine_classes_and_their_specialisations_match_the_source() -> void:
	var content := GameSession.content
	assert_eq(RpgClassRegistry.classes(content).keys().size(), 9, "nine classes")
	var abilities := _reference_abilities()
	var total := 0
	for class_id: String in SPECS:
		var got := RpgClassRegistry.specs(content, class_id)
		var want: Array = SPECS[class_id]
		assert_eq(got.size(), want.size(), class_id + ": spec count")
		for i in want.size():
			var spec: Dictionary = got[i]
			var row: Array = want[i]
			var where := "%s.%s" % [class_id, row[0]]
			assert_eq(
				[spec["id"], spec["role"], spec["primary_stat"], spec["signature"]], row, where
			)
			assert_eq(spec["ref"]["commit"], COMMIT, where + ": source commit")
			assert_true(
				abilities.has(spec["signature"]), where + ": signature is a reference ability"
			)
			assert_true(
				str(spec["display_name_status"]).begins_with("INTERIM"),
				where + ": display name is marked interim"
			)
			total += 1
		assert_eq(RpgClassRegistry.class_def(content, class_id)["armor"], ARMOR[class_id], class_id)
	assert_eq(total, 27, "27 specialisations")
	assert_eq(RpgClassRegistry.spec_level(content), 5, "spec chosen at level 5")
	assert_eq(RpgClassRegistry.row_levels(content), [5, 8, 11, 14, 17, 20], "talent rows")


func test_thirteen_slots_and_the_equipment_rules() -> void:
	var content := GameSession.content
	assert_eq(RpgEquipmentRules.slots(content), SLOTS, "the 13 reference slots, in order")
	assert_true(RpgEquipmentRules.slot_accepts(content, "ring1", "ring"), "ring1 takes rings")
	assert_true(RpgEquipmentRules.slot_accepts(content, "ring2", "ring"), "ring2 takes rings")
	assert_true(not RpgEquipmentRules.slot_accepts(content, "neck", "ring"), "neck takes no ring")
	assert_true(RpgEquipmentRules.can_wear_armor(content, "warrior", "mail"), "warrior: mail")
	assert_true(RpgEquipmentRules.can_wear_armor(content, "warrior", "cloth"), "warrior: cloth")
	assert_true(
		not RpgEquipmentRules.can_wear_armor(content, "mage", "leather"), "mage: no leather"
	)
	assert_true(not RpgEquipmentRules.can_wear_armor(content, "rogue", "mail"), "rogue: no mail")
	assert_true(RpgEquipmentRules.can_dual_wield(content, "rogue", ""), "rogue dual wields")
	assert_true(RpgEquipmentRules.can_dual_wield(content, "warrior", "fury"), "fury dual wields")
	assert_true(not RpgEquipmentRules.can_dual_wield(content, "warrior", "arms"), "arms does not")
	assert_true(RpgEquipmentRules.can_dual_wield(content, "shaman", "enhancement"), "enhancement")
	assert_true(not RpgEquipmentRules.can_dual_wield(content, "mage", ""), "mage does not")


func test_the_legacy_charm_slot_is_isolated() -> void:
	var content := GameSession.content
	assert_eq(RpgEquipmentRules.legacy(content)["status"], "ADAPTED", "legacy is ADAPTED")
	assert_true(not "charm" in RpgEquipmentRules.slots(content), "charm is no reference slot")
	assert_eq(RpgEquipmentRules.legacy_slot_target(content, "charm"), "charm", "charms stay put")
	assert_eq(RpgEquipmentRules.legacy_slot_target(content, "weapon"), "mainhand", "weapon")
	assert_eq(RpgEquipmentRules.legacy_slot_target(content, "head"), "helmet", "head")
	assert_eq(RpgEquipmentRules.legacy_slot_target(content, "body"), "chest", "body")
	assert_eq(RpgEquipmentRules.legacy_slot_target(content, "hands"), "gloves", "hands")
	assert_eq(RpgEquipmentRules.legacy_slot_target(content, "feet"), "feet", "feet")


func test_gameplay_still_uses_the_legacy_slots() -> void:
	# B2 builds data only: the game's equipment is unchanged until C1 is approved.
	assert_eq(
		PlayerProfile.SLOTS,
		["head", "body", "hands", "weapon", "feet", "charm"],
		"the six legacy slots are still the live ones"
	)
