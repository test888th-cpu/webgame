class_name RpgItemText
extends RefCounted
## How a reference item reads on the street's screens (Equipment, Bag): its name,
## grade colour, placeholder icon, kind, stats and where it drops. Everything is
## read from the runtime pack (RpgPack.item and the monsters' loot rows); nothing
## here is a rule. Grades use the owner's colour standard (ItemText.RARITY_COLORS)
## for the reference qualities that share its ids; the reference's "poor" has no
## owner colour and shows in the faint text colour (ADAPTED, presentation only).
## Ranks come from the reference's quality order (data/rpg/quality.json "tiers").

## Temporary icons (existing UI icons) until the owner's own item art.
const SLOT_ICONS := {
	"mainhand": "slot_weapon",
	"offhand": "slot_weapon",
	"helmet": "slot_head",
	"chest": "slot_body",
	"shoulder": "slot_body",
	"waist": "slot_body",
	"legs": "slot_body",
	"gloves": "slot_hands",
	"feet": "slot_feet",
	"neck": "slot_charm",
	"ring1": "slot_charm",
	"ring2": "slot_charm",
	"trinket": "slot_charm",
}
const KIND_ICONS := {"quest": "quest", "junk": "scrap_metal"}
const SLOT_NAMES := {
	"mainhand": "Main hand",
	"offhand": "Off hand",
	"helmet": "Head",
	"neck": "Neck",
	"shoulder": "Shoulders",
	"chest": "Chest",
	"waist": "Waist",
	"legs": "Legs",
	"gloves": "Hands",
	"feet": "Feet",
	"ring1": "Ring",
	"ring2": "Ring",
	"trinket": "Trinket",
}
const STAT_NAMES := {
	"str": "Strength",
	"agi": "Agility",
	"sta": "Stamina",
	"int": "Intellect",
	"spi": "Spirit",
	"armor": "Armor",
}


static func name_of(pack: Dictionary, item_id: String) -> String:
	return str(RpgPack.item(pack, item_id).get("display_name", item_id))


static func icon_id(pack: Dictionary, item_id: String) -> String:
	var item := RpgPack.item(pack, item_id)
	if KIND_ICONS.has(str(item.get("kind"))):
		return KIND_ICONS[str(item["kind"])]
	return str(SLOT_ICONS.get(str(item.get("slot")), "slot_charm"))


static func color(pack: Dictionary, item_id: String) -> Color:
	var quality := str(RpgPack.item(pack, item_id).get("quality"))
	return ItemText.RARITY_COLORS.get(quality, UiTheme.TEXT_FAINT)


## The item's grade by its place in the reference's quality order (-1 without one).
static func grade_rank(content: ContentDB, pack: Dictionary, item_id: String) -> int:
	var tiers: Array = content.rpg.get("quality", {}).get("tiers", [])
	return tiers.find(str(RpgPack.item(pack, item_id).get("quality")))


## e.g. "Common Main hand weapon", "Quest item".
static func kind(pack: Dictionary, item_id: String) -> String:
	var item := RpgPack.item(pack, item_id)
	var quality := str(item.get("quality", "")).capitalize()
	match str(item.get("kind")):
		"weapon":
			return "%s %s weapon" % [quality, SLOT_NAMES.get(str(item.get("slot")), "")]
		"armor":
			var shield := " (shield)" if item.get("shield", false) else ""
			return "%s %s%s" % [quality, SLOT_NAMES.get(str(item.get("slot")), "armor"), shield]
		"quest":
			return "Quest item"
		"junk":
			return "%s junk" % quality
	return str(item.get("kind", "")).capitalize()


## The item's own numbers, as the reference data has them.
static func stat_lines(pack: Dictionary, item_id: String) -> Array[String]:
	var item := RpgPack.item(pack, item_id)
	var out: Array[String] = []
	var w: Variant = item.get("weapon")
	if w is Dictionary:
		out.append("Damage %d-%d, speed %.1f" % [w["min"], w["max"], w["speed"]])
	var stats: Variant = item.get("stats")
	if stats is Dictionary:
		for key: String in STAT_NAMES:
			if float(stats.get(key, 0)) != 0.0:
				out.append("+%d %s" % [int(stats[key]), STAT_NAMES[key]])
	if int(item.get("block_value", 0)) > 0:
		out.append("Block value %d" % int(item["block_value"]))
	for key: String in ["spell_power", "crit_rating", "haste_rating", "hit_rating"]:
		if float(item.get(key, 0)) != 0.0:
			out.append("+%d %s" % [int(item[key]), key.replace("_", " ").capitalize()])
	if int(item.get("required_level", 1)) > 1:
		out.append("Requires level %d" % int(item["required_level"]))
	if item.get("required_class") != null:
		out.append("Class: %s" % str(item["required_class"]).capitalize())
	return out


## A copy's own loot quality (loot_quality/core.ts), when it rolled one.
static func copy_quality(quality: Variant) -> String:
	if not (quality is Dictionary) or int(quality.get("tier", 0)) <= 0:
		return ""
	return "Copy quality: tier %d" % int(quality["tier"])


## Which placed monsters can drop it, and how often (their loot rows).
static func sources(pack: Dictionary, item_id: String) -> Array[String]:
	var out: Array[String] = []
	for mid: String in pack.get("trial_monsters", {}):
		var m: Dictionary = pack["trial_monsters"][mid]
		for row: Dictionary in m.get("loot", []):
			if str(row.get("item")) != item_id:
				continue
			var gate := " (quest only)" if row.get("quest_id") != null else ""
			out.append(
				"%s: %s%%%s" % [m["display_name"], _percent(float(row.get("chance", 0))), gate]
			)
	return out


static func _percent(chance: float) -> String:
	var pct := chance * 100.0
	return str(int(pct)) if is_equal_approx(pct, roundf(pct)) else "%.1f" % pct
