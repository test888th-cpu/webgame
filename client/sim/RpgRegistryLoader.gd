class_name RpgRegistryLoader
extends RefCounted
## Loads and validates the Phase B2 registries (docs/PHASE_B2_PLAN.md), so
## ContentDB stays a content loader:
## * the shipped rule registries in client/data (classes, talents, slots,
##   quality), stored in ContentDB.rpg;
## * the reference registries in data/registry (monsters, items, loot), which are
##   not shipped in the game build and are read on demand.
## File access stays in ContentDB (the one reviewed reader, test_sim_purity):
## callers pass its reader as a Callable. Accessors elsewhere are pure and do no
## I/O.
##
## Namespaces: a reference record is addressed as "reference:<id>" and one of
## The Iron Legacy's own records as "iron_legacy:<id>". A bare id can exist in
## both (training_dummy does); each side keeps its own record and nothing merges
## them (data/registry/id_collisions.json).

const REFERENCE := "reference"
const IRON_LEGACY := "iron_legacy"
## Shipped rule registries: key in ContentDB.rpg -> [file under client/data, section or ""].
const RPG_FILES := {
	"classes": ["rpg_reference.json", "classes"],
	"talents": ["rpg/talent_structure.json", ""],
	"equipment": ["rpg/equipment_slots.json", ""],
	"quality": ["rpg/quality.json", ""],
	"runtime": ["rpg/runtime_pack.json", ""],
	"placement": ["rpg/placement.json", ""],
	"ability_icons": ["rpg/ability_icons.json", ""],
}
## Reference registries in data/registry, by name.
const REGISTRY_FILES := {
	"monsters": "reference_monsters.json",
	"items": "reference_items.json",
	"loot_tables": "reference_loot_tables.json",
	"loot_entries": "reference_loot_entries.json",
	"loot_selection": "loot_selection.json",
	"collisions": "id_collisions.json",
	"manifest": "reference_registry_manifest.json",
	"legacy_items": "legacy_items.json",
}


## The shipped rule registries, read with `read` (ContentDB._read).
static func load_rpg(read: Callable, dir: String) -> Dictionary:
	var out := {}
	for key: String in RPG_FILES:
		var spec: Array = RPG_FILES[key]
		var doc: Dictionary = read.call(dir.path_join(spec[0]))
		out[key] = doc.get(spec[1], {}) if spec[1] != "" else doc
	return out


## Problems in the shipped rule registries (run by ContentDB.validate).
static func problems(content: ContentDB) -> PackedStringArray:
	var out := PackedStringArray()
	out.append_array(RpgClassRegistry.problems(content))
	out.append_array(RpgEquipmentRules.problems(content))
	out.append_array(RpgQuality.problems(content))
	return out


## data/registry beside the Godot project. Absent from exported builds, where
## every reference registry reads as {}.
static func registry_dir() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../data/registry")


## The reference registries, read with `read` (ContentDB.read_registry).
static func load_registries(read: Callable, dir := registry_dir()) -> Dictionary:
	var out := {}
	for name: String in REGISTRY_FILES:
		out[name] = read.call(dir.path_join(REGISTRY_FILES[name]))
	return out


## Problems across the reference registries and their links.
static func registry_problems(registries: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var items: Dictionary = registries.get("items", {}).get("items", {})
	var monsters := RpgMonsterRegistry.monsters(registries.get("monsters", {}))
	out.append_array(RpgMonsterRegistry.problems(registries.get("monsters", {}), items))
	out.append_array(
		RpgLootRegistry.problems(
			registries.get("loot_tables", {}), registries.get("loot_entries", {}), items, monsters
		)
	)
	for item_id: String in items:
		if items[item_id].get("namespaced_id") != namespaced(REFERENCE, item_id):
			out.append("item %s: not in the reference namespace" % item_id)
	return out


static func namespaced(space: String, id: String) -> String:
	return space + ":" + id


## ["reference" or "iron_legacy", bare id], or [] for an id without a known namespace.
static func split_id(namespaced_id: String) -> PackedStringArray:
	var at := namespaced_id.find(":")
	if at < 0:
		return PackedStringArray()
	var ns := namespaced_id.substr(0, at)
	if ns != REFERENCE and ns != IRON_LEGACY:
		return PackedStringArray()
	return PackedStringArray([ns, namespaced_id.substr(at + 1)])


## A reference record ("monsters" or "items") by "reference:<id>"; {} for any
## other namespace or a bare id, so an Iron Legacy id can never reach it.
static func reference_record(
	registries: Dictionary, domain: String, namespaced_id: String
) -> Dictionary:
	var parts := split_id(namespaced_id)
	if parts.is_empty() or parts[0] != REFERENCE:
		return {}
	return registries.get(domain, {}).get(domain, {}).get(parts[1], {})


## One of the game's own records ("monsters" or "items") by "iron_legacy:<id>";
## {} for any other namespace or a bare id.
static func game_record(content: ContentDB, domain: String, namespaced_id: String) -> Dictionary:
	var parts := split_id(namespaced_id)
	if parts.is_empty() or parts[0] != IRON_LEGACY:
		return {}
	var table: Dictionary = content.enemies if domain == "monsters" else content.items
	return table.get(parts[1], {})


## Bare ids present in both namespaces for a domain, sorted.
static func shared_bare_ids(content: ContentDB, registries: Dictionary, domain: String) -> Array:
	var reference: Dictionary = registries.get(domain, {}).get(domain, {})
	var game: Dictionary = content.enemies if domain == "monsters" else content.items
	var out := []
	for id: String in reference:
		if game.has(id):
			out.append(id)
	out.sort()
	return out
