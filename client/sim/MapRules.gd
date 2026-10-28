class_name MapRules
extends RefCounted
## The city map. The street (StreetMemory.street) is split into districts
## (areas.json "districts": each starts at its "from" area and runs east to
## the next), and the hero knows only part of it:
## * areas reached are known (name, level, who works there, the boss);
## * the next area east of one reached is in sight (name and level only):
##   the way on is always shown;
## * everything past that is unknown, and a district with nothing known is
##   unnamed.
## World boss arenas are known once their boss is unlocked (WorldBossRules).
## The map also says where the hero's goal is: the tracked quest's area
## (quests.json objective "area"), its giver once it is done, or the giver
## of the next quest. Derived from the profile, so nothing new is saved.
## Pure rules, shared with the server.

const HERE := "here"
const KNOWN := "known"
const IN_SIGHT := "in_sight"
const UNKNOWN := "unknown"
const UNKNOWN_NAME := "???"
## What each NPC role offers, as the map lists it.
const SERVICES := {"shop": "Shop", "quests": "Quests", "travel": "Taxi"}


## The street's districts, west to east: [{"name", "areas": [area ids]}].
static func districts(content: ContentDB) -> Array[Dictionary]:
	var starts := {}
	for district: Dictionary in content.districts:
		starts[str(district["from"])] = str(district["name"])
	var out: Array[Dictionary] = []
	for area_id in StreetMemory.street(content):
		if starts.has(area_id) or out.is_empty():
			out.append({"name": str(starts.get(area_id, "")), "areas": []})
		out[-1]["areas"].append(area_id)
	return out


## Where `area_id` lies: {"name": its district, "index": its place in the
## district from 0, "count": the district's areas}; {} off the street.
static func locate(content: ContentDB, area_id: String) -> Dictionary:
	for district in districts(content):
		var index: int = district["areas"].find(area_id)
		if index >= 0:
			return {"name": district["name"], "index": index, "count": district["areas"].size()}
	return {}


## World boss arenas the hero knows of (their boss unlocked), in data order.
static func arenas(profile: PlayerProfile, content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for boss: String in content.world_bosses:
		if WorldBossRules.unlocked(profile, content, boss):
			out.append(str(WorldBossRules.spec(content, boss)["area"]))
	return out


## HERE, KNOWN, IN_SIGHT or UNKNOWN for `area_id`, with the hero in `here`.
static func state(
	profile: PlayerProfile, content: ContentDB, area_id: String, here: String
) -> String:
	if area_id == here:
		return HERE
	if content.area(area_id).get("world_boss", false):
		return KNOWN if area_id in arenas(profile, content) else UNKNOWN
	if area_id in profile.visited:
		return KNOWN
	var west := str(content.area(area_id).get("exits", {}).get("west", {}).get("to", ""))
	return IN_SIGHT if west in profile.visited or west == here else UNKNOWN


## What the map shows of `area_id`: {"state", "name", "level" (0 when
## unknown), "services": [names], "boss": the boss's name or "", "beaten":
## the boss is down, "gate": why the way east is still shut or ""}. Only a
## known area shows more than its name and level.
static func about(
	profile: PlayerProfile, content: ContentDB, area_id: String, here: String
) -> Dictionary:
	var area := content.area(area_id)
	var seen := state(profile, content, area_id, here)
	var info := {
		"state": seen,
		"name": UNKNOWN_NAME,
		"level": 0,
		"services": [],
		"boss": "",
		"beaten": false,
		"gate": "",
	}
	if seen == UNKNOWN:
		return info
	info["name"] = str(area.get("name", area_id))
	info["level"] = int(area.get("level", 1))
	if seen == IN_SIGHT:
		return info
	for npc: Dictionary in area.get("npcs", []):
		var service := str(SERVICES.get(str(npc.get("role")), ""))
		if service and service not in info["services"]:
			info["services"].append(service)
	var boss := boss_of(content, area_id)
	if boss:
		info["boss"] = str(content.enemy(boss).get("name", boss))
		info["beaten"] = int(profile.defeated.get(boss, 0)) > 0
	info["gate"] = _gate(profile, area)
	return info


## The hero's goal: {"area", "text"}, or {} with nothing left to do. The
## quest is the one the HUD tracks (the first active or done in the log);
## with none, the next quest on offer.
static func goal(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	for quest_id: String in profile.quests:
		var quest: Dictionary = content.quests[quest_id]
		var giver := str(quest["giver"])
		match str(profile.quests[quest_id]["state"]):
			"active":
				return {"area": str(quest["objective"]["area"]), "text": str(quest["name"])}
			"complete":
				var who := str(_npc(content, giver).get("name", giver))
				return {"area": giver_area(content, giver), "text": "Report to %s" % who}
	for quest_id: String in content.quests:
		if QuestRules.status(profile, quest_id, content) == "available":
			var giver := str(content.quests[quest_id]["giver"])
			var who := str(_npc(content, giver).get("name", giver))
			return {"area": giver_area(content, giver), "text": "New quest from %s" % who}
	return {}


## The area where NPC `npc_id` stands, or "".
static func giver_area(content: ContentDB, npc_id: String) -> String:
	for area_id: String in content.areas:
		for npc: Dictionary in content.area(area_id).get("npcs", []):
			if npc.get("id") == npc_id:
				return area_id
	return ""


static func _npc(content: ContentDB, npc_id: String) -> Dictionary:
	for npc: Dictionary in content.area(giver_area(content, npc_id)).get("npcs", []):
		if npc.get("id") == npc_id:
			return npc
	return {}


## The first boss fighting in `area_id`, or "". The route shows where the
## bosses wait even before an area is reached (not who they are).
static func boss_of(content: ContentDB, area_id: String) -> String:
	for encounter: Dictionary in content.area(area_id).get("encounters", []):
		for wave: Array in encounter["waves"]:
			for kind: String in wave:
				if content.enemy(kind).get("boss", false):
					return kind
	return ""


## Why `area`'s way east is still shut (its hint), or "" when it is open.
static func _gate(profile: PlayerProfile, area: Dictionary) -> String:
	var requires: Dictionary = area.get("exits", {}).get("east", {}).get("requires", {})
	if requires.is_empty():
		return ""
	if int(profile.defeated.get(str(requires["defeat"]), 0)) >= int(requires["count"]):
		return ""
	return str(requires.get("hint", "The way on is shut."))
