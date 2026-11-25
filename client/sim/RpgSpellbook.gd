class_name RpgSpellbook
extends RefCounted
## The class's whole spellbook as players see it (the Skills screen), and the
## hotbar layout. What a character knows comes only from RpgTalents.known (the
## abilitiesKnownAt port); this file classifies the rest by the same conditions
## known() applies, so the screen never disagrees with the engine, and it keeps
## the saved hotbar to abilities the engine can run.
##
## Each entry: {id, state, reason, status}. state is one of:
##   "usable"        known and its effects run in this engine (IMPLEMENTED_*)
##   "passive"       a known passive whose behaviour runs in this engine: always on
##   "known_blocked" known, but its source execution path is not ported (BLOCKED,
##                   UNKNOWN, CONDITION_LOCKED): shown, never castable
##   "level"         learnLevel above the character's level
##   "spec"          needs a specialization the character has not chosen
##   "talent"        granted by a talent option not chosen
##   "quest"         needs a reference quest (none exist in this build)
##   "hidden"        hiddenFromPlayer, or not for players

const USABLE := "usable"
const PASSIVE := "passive"


## Every ability of the class (its kit, and every talent grant), in spellbook order.
static func book(pack: Dictionary, cls: String, level: int, mods: Dictionary) -> Array:
	var known := {}
	for k: Dictionary in RpgTalents.known(pack, cls, level, mods):
		known[str(k["id"])] = k
	var granted := {}
	for g: Dictionary in mods["grants"]:
		granted[str(g["ability"])] = true
	var ids: Array = pack["classes"][cls]["kit_abilities"].duplicate()
	for row: Dictionary in pack["talents"].get(cls, {}).get("rows", []):
		for o: Dictionary in row["options"]:
			var grant: Variant = o.get("effect", {}).get("grant")
			if grant is Dictionary and not grant["ability"] in ids:
				ids.append(str(grant["ability"]))
	var out: Array = []
	for id: String in ids:
		var doc: Dictionary = pack["abilities"].get(id, {})
		if doc.is_empty():
			continue
		var in_kit: bool = id in pack["classes"][cls]["kit_abilities"]
		out.append(_entry(id, doc, known, granted, in_kit, level, mods))
	return out


static func _entry(
	id: String,
	doc: Dictionary,
	known: Dictionary,
	granted: Dictionary,
	in_kit: bool,
	level: int,
	mods: Dictionary
) -> Dictionary:
	var def: Dictionary = doc["def"]
	var status := str(doc["status"])
	var e := {"id": id, "status": status, "state": "", "reason": ""}
	if known.has(id):
		e["state"] = USABLE if status.begins_with("IMPLEMENTED") else "known_blocked"
		if e["state"] == USABLE and def.get("passive", false):
			e["state"] = PASSIVE
		e["reason"] = "" if e["state"] in [USABLE, PASSIVE] else str(doc.get("reason", status))
		e["known"] = known[id]
		return e
	if def.get("hiddenFromPlayer", false) or status == "NOT_APPLICABLE_TO_PLAYER":
		e["state"] = "hidden"
		e["reason"] = "Not used by players."
	elif not in_kit and not granted.has(id):
		e["state"] = "talent"
		e["reason"] = "Granted by a talent option."
	elif int(def.get("learnLevel", 1)) > level:
		e["state"] = "level"
		e["reason"] = "Learned at level %d." % int(def["learnLevel"])
	elif def.get("requiresQuest") != null:
		e["state"] = "quest"
		e["reason"] = "Learned from a quest (no quests in this build yet)."
	elif def.get("specs") != null and (mods["spec"] == null or not mods["spec"] in def["specs"]):
		e["state"] = "spec"
		e["reason"] = "Needs the %s specialization." % " or ".join(def["specs"])
	else:
		e["state"] = "spec"
		e["reason"] = "Not available to this specialization."
	return e


## The abilities the hotbar may hold: known and run by this engine.
static func usable_ids(pack: Dictionary, cls: String, level: int, mods: Dictionary) -> Array:
	var out: Array = []
	for k: Dictionary in RpgTalents.known(pack, cls, level, mods):
		if k["def"].get("passive", false):
			continue
		if str(pack["abilities"][k["id"]]["status"]).begins_with("IMPLEMENTED"):
			out.append(str(k["id"]))
	return out


## The bar's ability slots (after the attack in slot 1): the saved layout, keeping
## only abilities still usable, else every usable ability in spellbook order.
static func hotbar(pack: Dictionary, state: Dictionary, mods: Dictionary, slots: int) -> Array:
	var usable := usable_ids(pack, str(state["class_id"]), int(state["level"]), mods)
	var saved: Variant = state.get("hotbar")
	var out: Array = []
	if saved is Array and not saved.is_empty():
		for id: Variant in saved:
			out.append(str(id) if str(id) in usable else "")
	else:
		out = usable.duplicate()
	out.resize(slots)
	for i in out.size():
		if out[i] == null:
			out[i] = ""
	return out


## Put `ability_id` ("" empties it) in ability slot `index` (0-based, after the
## attack). "" on success; a known ability the engine cannot run is refused.
static func assign(
	pack: Dictionary,
	state: Dictionary,
	mods: Dictionary,
	index: int,
	ability_id: String,
	slots: int
) -> String:
	if index < 0 or index >= slots:
		return "No such slot."
	var usable := usable_ids(pack, str(state["class_id"]), int(state["level"]), mods)
	if ability_id != "" and not ability_id in usable:
		return "That ability cannot be used yet."
	var bar := hotbar(pack, state, mods, slots)
	var was := bar.find(ability_id) if ability_id != "" else -1
	if was >= 0:
		bar[was] = bar[index]
	bar[index] = ability_id
	state["hotbar"] = bar
	return ""
