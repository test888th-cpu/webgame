class_name ItemText
extends RefCounted
## How items read everywhere (bag, character screen, shop, pickups): rarity
## colours, slot names, and stat lines in player terms ("+15 Attack"), not
## data terms ("power: 0.15").

const RARITY_COLORS := {
	"common": Color("d9d6cc"),
	"uncommon": Color("7bd389"),
	"rare": Color("5fa8f0"),
	"epic": Color("c08af5"),
	"legendary": Color("f2a54a"),
}
const SLOT_NAMES := {
	"head": "Head",
	"body": "Body",
	"hands": "Hands",
	"weapon": "Weapon",
	"feet": "Feet",
	"charm": "Charm"
}
## Stat key -> name shown to players, in display order.
const STAT_NAMES := {
	"max_hp": "Max HP",
	"power": "Attack",
	"defense": "Defense",
	"speed": "Speed",
	"crit": "Crit",
	"attack_speed": "Atk Speed",
}
## One line explaining each stat, for the status screen.
const STAT_HELP := {
	"max_hp": "Damage you can take before going down.",
	"power": "Damage of every blow and skill.",
	"defense": "Taken off every hit you receive.",
	"speed": "How fast you move along the street.",
	"crit": "Chance that a blow lands for 1.5x damage.",
	"attack_speed": "How quickly you recover after each attack.",
}


static func rarity_color(item: Dictionary) -> Color:
	return RARITY_COLORS.get(str(item.get("rarity", "common")), UiTheme.TEXT)


## e.g. "Uncommon Weapon", "Common Consumable".
static func kind(item: Dictionary) -> String:
	var rarity := str(item.get("rarity", "common")).capitalize()
	if item.get("type") == "equipment":
		return "%s %s" % [rarity, SLOT_NAMES.get(str(item.get("slot")), "Gear")]
	if item.get("type") == "key":
		return "Evidence"
	if item.get("type") == "material":
		return "%s Material" % rarity
	return "%s Consumable" % rarity


## A stat's total as players see it: Attack 115, Speed 95%.
static func stat_value(key: String, value: float) -> String:
	match key:
		"power":
			return str(roundi(value * 100.0))
		"speed", "crit", "attack_speed":
			return "%d%%" % roundi(value * 100.0)
	return str(roundi(value))


## A bonus with its sign: "+15", "-5%".
static func bonus_value(key: String, value: float) -> String:
	var shown := stat_value(key, absf(value))
	return ("-" if value < 0.0 else "+") + shown


## What an item does, as [text, colour] lines: stat bonuses for gear (red for
## penalties), effects for consumables.
static func effect_lines(item: Dictionary) -> Array[Array]:
	var lines: Array[Array] = []
	if item.get("type") == "equipment":
		var stats: Dictionary = item.get("stats", {})
		for key: String in STAT_NAMES:
			if stats.has(key) and float(stats[key]) != 0.0:
				var value := float(stats[key])
				lines.append(
					[
						"%s %s" % [bonus_value(key, value), STAT_NAMES[key]],
						UiTheme.GOOD if value > 0.0 else UiTheme.DANGER
					]
				)
	else:
		if int(item.get("heal", 0)):
			lines.append(["Restores %d HP" % int(item["heal"]), UiTheme.GOOD])
		if int(item.get("energy", 0)):
			lines.append(["Restores %d energy" % int(item["energy"]), UiTheme.TEAL])
	return lines


## The change from wearing `item` instead of `current` (either may be {}), as
## [text, colour] lines; empty when nothing changes.
static func compare_lines(item: Dictionary, current: Dictionary) -> Array[Array]:
	var lines: Array[Array] = []
	var new_stats: Dictionary = item.get("stats", {})
	var old_stats: Dictionary = current.get("stats", {})
	for key: String in STAT_NAMES:
		var delta := float(new_stats.get(key, 0.0)) - float(old_stats.get(key, 0.0))
		if absf(delta) > 0.0001:
			lines.append(
				[
					"%s %s" % [bonus_value(key, delta), STAT_NAMES[key]],
					UiTheme.GOOD if delta > 0.0 else UiTheme.DANGER
				]
			)
	return lines
