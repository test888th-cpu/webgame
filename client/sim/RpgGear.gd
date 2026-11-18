class_name RpgGear
extends RefCounted
## Who may wear what, and where (World of ClaudeCraft src/sim/equipment_rules.ts):
## canEquipItem, canEquipItemInSlot, resolveEquipSlot and displacedSlotForEquip, with
## the class groups from client/data/rpg/equipment_slots.json. Not modelled (no item
## in the runtime pack needs them; the pack lists such fields as not_modelled):
## membership weapon shapes, unique-equipped legendaries, masterwrought caps, quest
## tools.

const ARMOR_RANK := {"cloth": 0, "leather": 1, "mail": 2}


static func _rules(content: ContentDB) -> Dictionary:
	return RpgEquipmentRules.reference_rules(content)


static func max_armor(content: ContentDB, cls: String) -> String:
	return str(RpgClassRegistry.class_def(content, cls).get("armor", "cloth"))


static func hand(item: Dictionary) -> String:
	return str(item["hand"]) if item.get("hand") != null else "onehand"


static func _same_set(classes: Array, allowed: Array) -> bool:
	if classes.size() != allowed.size():
		return false
	for c: Variant in classes:
		if not c in allowed:
			return false
	return true


## weaponArchetypeForItem: a weapon whose requiredClass is exactly one class group.
static func archetype(content: ContentDB, item: Dictionary) -> String:
	var req: Variant = item.get("required_class")
	if str(item.get("kind")) != "weapon" or not (req is Array):
		return ""
	var groups: Dictionary = _rules(content).get("weapon_groups", {})
	for name: String in ["warrior", "caster", "rogue"]:
		if _same_set(req, groups.get(name, [])):
			return name
	return ""


## canEquipItem.
static func can_equip(content: ContentDB, cls: String, item: Dictionary) -> bool:
	var req: Variant = item.get("required_class")
	var req_list: Array = req if req is Array else []
	if item.get("class_locked", false) and not cls in req_list:
		return false
	var kind := str(item.get("kind"))
	if kind == "armor" and str(item.get("slot")) == "offhand" and item.get("shield", false):
		return req == null or cls in req_list
	if kind == "held_offhand":
		return req == null or cls in req_list
	if kind == "armor" and item.get("armor_type") != null:
		return int(ARMOR_RANK[str(item["armor_type"])]) <= int(ARMOR_RANK[max_armor(content, cls)])
	if cls == "rogue" and kind == "weapon" and hand(item) == "twohand":
		return false
	var arch := archetype(content, item)
	if arch != "":
		return cls in _rules(content)["weapon_groups"][arch]
	if req is Array:
		return cls in req_list
	return true


static func can_dual_wield(content: ContentDB, cls: String, spec: String) -> bool:
	return RpgEquipmentRules.can_dual_wield(content, cls, spec)


static func can_dual_wield_two_hand(content: ContentDB, cls: String, spec: String) -> bool:
	for rule: Dictionary in _rules(content).get("dual_wield_two_hand", []):
		if rule["class"] == cls and (rule["spec"] == null or rule["spec"] == spec):
			return true
	return false


## canEquipItemInSlot.
static func can_equip_in(
	content: ContentDB, cls: String, spec: String, item: Dictionary, slot: String
) -> bool:
	if not can_equip(content, cls, item):
		return false
	var kind := str(item.get("kind"))
	if kind == "armor":
		if str(item.get("slot")) == "ring":
			return slot == "ring1" or slot == "ring2"
		return str(item.get("slot")) == slot
	if kind != "weapon":
		return str(item.get("slot")) == slot
	if slot == "mainhand":
		return true
	if slot != "offhand" or not can_dual_wield(content, cls, spec):
		return false
	var h := hand(item)
	return h == "onehand" or (h == "twohand" and can_dual_wield_two_hand(content, cls, spec))


## resolveEquipSlot.
static func resolve_slot(item: Dictionary, equipment: Dictionary) -> String:
	if item.get("slot") == null:
		return ""
	if str(item["slot"]) != "ring":
		return str(item["slot"])
	if not equipment.has("ring1"):
		return "ring1"
	if not equipment.has("ring2"):
		return "ring2"
	return "ring1"


static func occupies_hand(item: Dictionary) -> bool:
	return str(item.get("kind")) != "held_offhand" or item.get("occupies_hand", true) != false


## displacedSlotForEquip: the other hand an equip empties (a two-hander and an
## off hand), or "".
static func displaced(
	content: ContentDB,
	pack: Dictionary,
	cls: String,
	spec: String,
	item: Dictionary,
	slot: String,
	equipment: Dictionary
) -> String:
	if slot == "offhand":
		if not occupies_hand(item):
			return ""
		var main := RpgPack.item(pack, str(equipment.get("mainhand", "")))
		var titan := (
			str(item.get("kind")) == "weapon" and can_dual_wield_two_hand(content, cls, spec)
		)
		if str(main.get("kind")) == "weapon" and hand(main) == "twohand" and not titan:
			return "mainhand"
		return ""
	if slot == "mainhand" and str(item.get("kind")) == "weapon" and hand(item) == "twohand":
		var off := RpgPack.item(pack, str(equipment.get("offhand", "")))
		if not off.is_empty() and not occupies_hand(off):
			return ""
		var titan_pair := (
			str(off.get("kind")) == "weapon" and can_dual_wield_two_hand(content, cls, spec)
		)
		if equipment.has("offhand") and not titan_pair:
			return "offhand"
	return ""
