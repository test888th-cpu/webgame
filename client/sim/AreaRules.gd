class_name AreaRules
extends RefCounted
## What kind of place an area is, which region it belongs to, and whether a
## farming ground is open to the hero. Reads the optional areas.json fields
## "kind", "region", "unlock" and "purpose" (ADR-06).
##
## Most areas carry none of them: the kind is derived from what the data
## already says (the city is areas.json "city_area", a world boss arena has
## "world_boss", everything else is the street), and a street area's region
## is its district. A farming ground ("kind": "farm") always states its
## region, its purpose and its unlock rule: {"reached": a story area} or
## {"defeated": a boss}. Unlocks read what the profile already keeps (areas
## reached, enemies defeated), so nothing new is saved. Pure rules, shared
## with the server.

const STREET := "street"
const CITY := "city"
const WORLD_BOSS := "world_boss"
const FARM := "farm"
const KINDS := [STREET, CITY, WORLD_BOSS, FARM]
## The two unlock rules a farming ground may use.
const REACHED := "reached"
const DEFEATED := "defeated"


## STREET, CITY, WORLD_BOSS or FARM for `area_id`.
static func kind(content: ContentDB, area_id: String) -> String:
	var area := content.area(area_id)
	if area.has("kind"):
		return str(area["kind"])
	if area_id == content.city_area:
		return CITY
	if area.get("world_boss", false):
		return WORLD_BOSS
	return STREET


## The region `area_id` belongs to: its "region", else its street district,
## else "" (the city and the world boss arenas belong to none).
static func region(content: ContentDB, area_id: String) -> String:
	var area := content.area(area_id)
	if area.has("region"):
		return str(area["region"])
	return str(MapRules.locate(content, area_id).get("name", ""))


## Every farming ground, in data order.
static func farms(content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for area_id: String in content.areas:
		if kind(content, area_id) == FARM:
			out.append(area_id)
	return out


## True when the hero may go to `area_id`: a farming ground once its unlock
## rule is met; any other area is not gated here (the street has its own
## gates and the world boss arenas WorldBossRules).
static func unlocked(profile: PlayerProfile, content: ContentDB, area_id: String) -> bool:
	if kind(content, area_id) != FARM:
		return true
	var rule: Dictionary = content.area(area_id).get("unlock", {})
	if rule.has(REACHED):
		return str(rule[REACHED]) in profile.visited
	if rule.has(DEFEATED):
		return int(profile.defeated.get(str(rule[DEFEATED]), 0)) > 0
	return false


## The hub: where the farming grounds and the world boss arenas are reached
## from and left to. The city when the game has one (Win's taxi there is the
## only way in; walking out west, a finished world boss attempt, auto
## battle's rest and the pause menu's return all come back to it), else the
## start area. The story's taxis never ride to them.
static func hub(content: ContentDB) -> String:
	return content.city_area if content.city_area != "" else content.start_area


## The way home from `area_id` to rest: the hub for a farming ground, else
## the start area (AutoBattle's rest, ProgressionHarness).
static func rest_home(content: ContentDB, area_id: String) -> String:
	return hub(content) if kind(content, area_id) == FARM else content.start_area


## True when a taxi ride from `area_id` may go to the farming grounds and the
## world boss arenas: only from the hub.
static func rides_from_hub(content: ContentDB, area_id: String) -> bool:
	return area_id == hub(content)


## The farming grounds open to the hero, in data order.
static func open_farms(profile: PlayerProfile, content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for area_id in farms(content):
		if unlocked(profile, content, area_id):
			out.append(area_id)
	return out


## What opens farming ground `area_id`, for players: "Reach Rusted Corner",
## "Defeat Director Wiroj", or "" when it has no rule.
static func unlock_text(content: ContentDB, area_id: String) -> String:
	var rule: Dictionary = content.area(area_id).get("unlock", {})
	if rule.has(REACHED):
		var target := str(rule[REACHED])
		return "Reach %s" % content.area(target).get("name", target)
	if rule.has(DEFEATED):
		var boss := str(rule[DEFEATED])
		return "Defeat %s" % content.enemy(boss).get("name", boss)
	return ""


## What is wrong with the areas' kinds, regions and farming grounds, one
## message each (empty when nothing). ContentDB.validate adds these to its
## errors. An explicit "kind" must agree with what the data already says, and
## a "region" is a district. A farming ground is off the street and reached
## by taxi only: nothing leads into it, its one way out on foot is west to
## the hub, it is no place to rest, and it names its region,
## purpose and unlock rule.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var street := StreetMemory.street(content)
	var regions: Array = []
	for district: Dictionary in content.districts:
		regions.append(str(district.get("name", "")))
	for id: String in content.areas:
		var a: Dictionary = content.areas[id]
		var where := "areas.%s" % id
		if a.has("kind"):
			var said := str(a["kind"])
			if said not in KINDS:
				out.append("%s.kind: one of %s" % [where, KINDS])
			if said == CITY and id != content.city_area:
				out.append(where + ".kind: city is city_area")
			if (said == WORLD_BOSS) != bool(a.get("world_boss", false)):
				out.append(where + ".kind: world_boss goes with the world_boss flag")
			if said == STREET and id not in street:
				out.append(where + ".kind: street is the street")
		if a.has("region") and str(a["region"]) not in regions:
			out.append("%s.region: a district name" % where)
		if kind(content, id) == WORLD_BOSS and not _west_to_hub(content, a):
			out.append("%s: its one way out is west to %s" % [where, hub(content)])
		if kind(content, id) == FARM:
			out.append_array(_farm_problems(content, id, street))
		elif a.has("unlock"):
			out.append(where + ".unlock: only a farming ground has one")
	return out


## True when area data `a` has one way out, west to the hub, with no gate.
static func _west_to_hub(content: ContentDB, a: Dictionary) -> bool:
	var exits: Dictionary = a.get("exits", {})
	var west: Dictionary = exits.get("west", {})
	var to_hub := str(west.get("to")) == hub(content)
	return exits.keys() == ["west"] and to_hub and not west.has("requires")


static func _farm_problems(
	content: ContentDB, id: String, street: Array[String]
) -> PackedStringArray:
	var out: PackedStringArray = []
	var a := content.area(id)
	var where := "areas.%s" % id
	if id in street:
		out.append(where + ": a farming ground is off the street")
	if a.get("safe", false):
		out.append(where + ": a farming ground is not a safe area")
	if a.get("heal_on_enter", false):
		out.append(where + ": no rest in a farming ground")
	if not _west_to_hub(content, a):
		out.append("%s: its one way out is west to %s" % [where, hub(content)])
	for other: String in content.areas:
		for side: String in content.areas[other].get("exits", {}):
			if str(content.areas[other]["exits"][side].get("to")) == id:
				out.append("%s: %s leads into it; it is reached by taxi only" % [where, other])
	if str(a.get("region", "")) == "":
		out.append(where + ".region: required")
	if str(a.get("purpose", "")) == "":
		out.append(where + ".purpose: say what it is for")
	var rule: Variant = a.get("unlock")
	if not (rule is Dictionary and rule.size() == 1 and rule.keys()[0] in [REACHED, DEFEATED]):
		out.append('%s.unlock: one of {"reached": area} or {"defeated": boss}' % where)
		return out
	if rule.has(REACHED) and str(rule[REACHED]) not in street:
		out.append("%s.unlock.reached: a story area, not %s" % [where, rule[REACHED]])
	if rule.has(DEFEATED):
		var boss := str(rule[DEFEATED])
		if not content.enemies.get(boss, {}).get("boss", false):
			out.append("%s.unlock.defeated: a boss, not %s" % [where, boss])
	return out
