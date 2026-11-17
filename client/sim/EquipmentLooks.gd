class_name EquipmentLooks
extends RefCounted
## What a hero's worn gear looks like: for each slot with gear that has an
## "appearance" (item_catalog.json), that appearance id. It is worked out
## from PlayerProfile.equipment whenever the hero is refreshed (equipping,
## taking off, loading a save), so it never drifts from what is actually
## worn and nothing new is saved. The art an appearance id names
## (appearances.json "asset") is the presentation's business. Pure rules.

## The slots whose gear shows on the body (headgear, outfit, weapon).
const SHOWN: Array[String] = ["head", "body", "weapon"]


## {slot: appearance id} for `profile`'s worn gear.
static func of(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	var out := {}
	for slot in SHOWN:
		var key := str(profile.equipment.get(slot, ""))
		var look := str(content.item(key).get("appearance", "")) if key != "" else ""
		if look != "":
			out[slot] = look
	return out


static func apply(f: Fighter, profile: PlayerProfile, content: ContentDB) -> void:
	f.appearance = of(profile, content)
