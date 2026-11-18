class_name ItemCatalog
extends RefCounted
## The item ecosystem added on top of items.json, kept in its own data files
## so each concern can change on its own:
## * item_catalog.json   new item definitions (stable ids; "category",
##                       "appearance", "counts_as", "boss_only", "enabled");
##                       merged into ContentDB.items, never over an existing id
## * drop_tables.json    which enemies drop them, how (DropTables)
## * appearances.json    appearance id -> {"slot", "asset"}: what equipping
##                       shows (EquipmentLooks); the asset is replaceable art
## * placeholder_art.json  temporary icons and appearance assets, drawn by the
##                       game until final art with the same asset id exists
## * test_vendor.json    the single Item Testing Merchant (TEST_VENDOR_ENABLED)
## An item id, its icon id, its appearance id and that appearance's asset id
## are four different names: art is swapped by asset id, never by touching
## item ids, saves, drop tables or upgrades. Pure rules, shared with the server.

const FILES := {
	"items": "item_catalog.json",
	"drops": "drop_tables.json",
	"appearances": "appearances.json",
	"placeholders": "placeholder_art.json",
	"vendor": "test_vendor.json",
}
## Item categories (the merchant's sections and the drop tables' categories).
## Items without one are classed by type and slot (category()).
const CATEGORIES: Array[String] = [
	"enhancement_material",
	"ore",
	"consumable",
	"headgear",
	"outfit",
	"weapon",
	"boss_material",
	"special",
]
const SLOT_CATEGORY := {"head": "headgear", "body": "outfit", "weapon": "weapon"}
## What an art entry may be: a temporary placeholder or final production art.
const ART_STATUS: Array[String] = ["placeholder", "final"]

## Ids of the items item_catalog.json added, in file order.
var added: Array[String] = []
var drops: Dictionary = {}
var appearances: Dictionary = {}
var placeholders: Dictionary = {}
var vendor: Dictionary = {}
## True once the test merchant has been put in the world (enable_vendor).
var vendor_enabled := false


## Reads the catalog files from `dir` into `db` (before db.validate()).
static func load_into(db: ContentDB, dir: String) -> void:
	var catalog := ItemCatalog.new()
	db.catalog = catalog
	var file: Dictionary = db._read(dir.path_join(FILES["items"]))
	var items: Dictionary = file.get("items", {})
	for id: String in items:
		if db.items.has(id):
			db.errors.append("item_catalog.%s: the id is taken by items.json" % id)
			continue
		db.items[id] = items[id]
		catalog.added.append(id)
	catalog.drops = db._read(dir.path_join(FILES["drops"]))
	catalog.appearances = db._read(dir.path_join(FILES["appearances"])).get("appearances", {})
	catalog.placeholders = db._read(dir.path_join(FILES["placeholders"]))
	catalog.vendor = db._read(dir.path_join(FILES["vendor"]))


## The category of `item`: its own, or one from its type and slot.
static func category(item: Dictionary) -> String:
	if item.has("category"):
		return str(item["category"])
	match str(item.get("type", "")):
		"consumable":
			return "consumable"
		"material":
			return "enhancement_material"
		"equipment":
			return str(SLOT_CATEGORY.get(str(item.get("slot", "")), "special"))
	return "special"


## True when `item` may appear anywhere (drops, the merchant).
static func enabled(item: Dictionary) -> bool:
	return bool(item.get("enabled", true))


## True when `icon` is a temporary placeholder icon.
func has_placeholder_icon(icon: String) -> bool:
	return placeholders.get("icons", {}).has(icon)


## The appearance `item_id` shows when worn, or "".
func appearance_of(content: ContentDB, item_id: String) -> String:
	return str(content.item(item_id).get("appearance", ""))


## Puts the Item Testing Merchant in its area and opens its shop: every
## enabled catalog item, at the merchant's token price. Called by the game
## only while TEST_VENDOR_ENABLED is on; content loaded without it (the
## server, the tests) never has the merchant.
func enable_vendor(content: ContentDB) -> void:
	if vendor_enabled or vendor.is_empty():
		return
	var stock: Array[String] = []
	for id in added:
		if enabled(content.item(id)):
			stock.append(id)
	content.shops[str(vendor["shop"])] = {
		"name": str(vendor["name"]),
		"items": stock,
		"price_each": int(vendor.get("price_each", 1)),
		"categories": vendor.get("categories", []),
		"test": true,
	}
	var area: Dictionary = content.areas.get(str(vendor["area"]), {})
	if area.is_empty():
		return
	var npcs: Array = area.get("npcs", [])
	npcs.append((vendor["npc"] as Dictionary).duplicate(true))
	area["npcs"] = npcs
	vendor_enabled = true


## Problems with the catalog files, one message each (ContentDB.validate).
func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for id in added:
		var item := content.item(id)
		var where := "item_catalog.%s" % id
		if str(item.get("category", "")) not in CATEGORIES:
			out.append("%s.category: expected one of %s" % [where, CATEGORIES])
		var look := str(item.get("appearance", ""))
		if look != "":
			var spec: Dictionary = appearances.get(look, {})
			if spec.is_empty():
				out.append("%s.appearance: unknown appearance %s" % [where, look])
			elif spec.get("slot") != item.get("slot"):
				out.append("%s.appearance: %s is for %s" % [where, look, spec.get("slot")])
		for material: String in item.get("counts_as", {}):
			if content.item(material).get("type") != "material":
				out.append("%s.counts_as: %s is not a material" % [where, material])
			if int(item["counts_as"][material]) < 1:
				out.append("%s.counts_as.%s: expected 1 or more" % [where, material])
		for source: String in item.get("sources", []):
			if not content.enemy(source).get("boss", false):
				out.append("%s.sources: %s is not a boss" % [where, source])
		if item.get("rarity") == "godforged":
			out.append("%s: Godforged comes from world bosses only" % where)
	for look: String in appearances:
		var asset := str(appearances[look].get("asset", ""))
		if not placeholders.get("appearance_assets", {}).has(asset):
			out.append("appearances.%s.asset: no asset %s" % [look, asset])
	# Every piece of art says whether it is a temporary placeholder or final,
	# so a placeholder can never pass for production art.
	for kind: String in ["appearance_assets", "icons"]:
		var entries: Dictionary = placeholders.get(kind, {})
		for id: String in entries:
			if str(entries[id].get("status", "")) not in ART_STATUS:
				out.append("placeholder_art.%s.%s.status: one of %s" % [kind, id, ART_STATUS])
	out.append_array(DropTables.problems(content))
	for kind: String in content.enemies:
		out.append_array(
			loot_grade_problems(content, content.enemy(kind), "enemies.%s.loot" % kind)
		)
	return out


## The grade rules for loot tables (owner's standard): an ordinary monster
## never drops Legendary or Godforged; Legendary is for bosses; Godforged comes
## only from a world boss's rewards (world_boss.json), never a loot table.
static func loot_grade_problems(
	content: ContentDB, enemy: Dictionary, where: String
) -> PackedStringArray:
	var out: PackedStringArray = []
	var loot: Variant = enemy.get("loot", {})
	if not loot is Dictionary:
		return out
	for drop: Variant in loot.get("drops", []):
		if not drop is Dictionary:
			continue
		var grade := str(content.item(str(drop.get("item", ""))).get("rarity", ""))
		if grade == "godforged":
			out.append("%s: %s is Godforged, a world boss reward only" % [where, drop.get("item")])
		if grade == "legendary" and not enemy.get("boss", false):
			out.append("%s: %s is Legendary, for bosses only" % [where, drop.get("item")])
	return out
