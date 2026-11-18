class_name RpgEquipmentRules
extends RefCounted
## The reference equipment slots and class equipment rules (Phase B2.2,
## docs/PHASE_B2_PLAN.md), read from client/data/rpg/equipment_slots.json, which
## tools/content/build_reference_registries.py generates from World of
## ClaudeCraft src/sim/types.ts ALL_EQUIP_SLOTS and src/sim/equipment_rules.ts.
## Its "legacy" section (the interim Charm slot and the old slot names) is
## hand-written ADAPTED compatibility data, never reference data. Not used by
## gameplay yet.


static func reference_rules(content: ContentDB) -> Dictionary:
	return content.rpg.get("equipment", {}).get("reference", {})


static func legacy(content: ContentDB) -> Dictionary:
	return content.rpg.get("equipment", {}).get("legacy", {})


## The 13 reference slot ids, in reference order.
static func slots(content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for slot: Dictionary in reference_rules(content).get("slots", []):
		out.append(str(slot["id"]))
	return out


## Whether `slot` takes items declaring `item_slot` (rings declare "ring" and
## fit ring1 or ring2), as the reference's slotAcceptsItem does for non-weapons.
static func slot_accepts(content: ContentDB, slot: String, item_slot: String) -> bool:
	for entry: Dictionary in reference_rules(content).get("slots", []):
		if entry["id"] == slot:
			return entry["accepts"] == item_slot
	return false


## Whether `class_id` may wear armour of `armor_type` (the reference ranks
## cloth < leather < mail, and a class wears up to its own type).
static func can_wear_armor(content: ContentDB, class_id: String, armor_type: String) -> bool:
	var rank: Dictionary = reference_rules(content).get("armor_rank", {})
	var own := str(RpgClassRegistry.class_def(content, class_id).get("armor", ""))
	if not rank.has(armor_type) or not rank.has(own):
		return false
	return int(rank[armor_type]) <= int(rank[own])


## Whether `class_id` (with `spec_id`, "" for none) may dual wield.
static func can_dual_wield(content: ContentDB, class_id: String, spec_id: String) -> bool:
	for rule: Dictionary in reference_rules(content).get("dual_wield", []):
		if rule["class"] == class_id and (rule["spec"] == null or rule["spec"] == spec_id):
			return true
	return false


## Where a legacy save slot's item goes in the reference layout ("charm" stays
## in the interim Charm slot).
static func legacy_slot_target(content: ContentDB, old_slot: String) -> String:
	return str(legacy(content).get("slot_map", {}).get(old_slot, ""))


static func problems(content: ContentDB) -> PackedStringArray:
	var out := PackedStringArray()
	var ids := slots(content)
	if ids.size() != 13:
		out.append("rpg equipment: expected 13 reference slots, found %d" % ids.size())
	var seen := {}
	for slot in ids:
		if seen.has(slot):
			out.append("rpg equipment: duplicate slot " + slot)
		seen[slot] = true
	for slot: String in legacy(content).get("slots", {}):
		if seen.has(slot):
			out.append("rpg equipment: legacy slot %s collides with a reference slot" % slot)
	if str(legacy(content).get("status", "")) != "ADAPTED":
		out.append("rpg equipment: the legacy section must be marked ADAPTED")
	for old_slot: String in legacy(content).get("slot_map", {}):
		var target := legacy_slot_target(content, old_slot)
		if not seen.has(target) and not legacy(content).get("slots", {}).has(target):
			out.append("rpg equipment: legacy %s maps to unknown slot %s" % [old_slot, target])
	for group: String in reference_rules(content).get("weapon_groups", {}):
		for class_id: String in reference_rules(content)["weapon_groups"][group]:
			if class_id not in RpgClassRegistry.ROSTER:
				out.append("rpg equipment: weapon group %s names %s" % [group, class_id])
	return out
