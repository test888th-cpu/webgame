class_name StreetMemory
extends RefCounted
## What the street remembers between visits, kept in PlayerProfile:
## * fights already won in each area ("cleared": area id -> encounter
##   indices) stay won, so a knocked-out hero does not have to fight the
##   whole way back; resting where the area heals (Depot Yard) brings every
##   fight back, for anyone who wants to farm coins and drops;
## * areas reached ("visited"), which the motorbike taxi can ride to.
## Pure rules, shared with the server.


## True when encounter `index` of `area_id` was won since the last rest.
static func is_cleared(profile: PlayerProfile, area_id: String, index: int) -> bool:
	return index in profile.cleared.get(area_id, [])


static func mark_cleared(profile: PlayerProfile, area_id: String, index: int) -> void:
	var done: Array = profile.cleared.get(area_id, [])
	if index not in done:
		done.append(index)
		done.sort()
	profile.cleared[area_id] = done


## Resting: every street fills up again.
static func rest(profile: PlayerProfile) -> void:
	profile.cleared.clear()


static func visit(profile: PlayerProfile, area_id: String) -> void:
	if area_id not in profile.visited:
		profile.visited.append(area_id)


## Fights `area_id` should still hold for this visit. Normally the ones not
## won yet; but if they are all won while the area's guarded exit is still
## shut (the hero has not knocked down enough of its guard), they all come
## back, so a gate can always be opened where it stands.
static func pending(profile: PlayerProfile, content: ContentDB, area_id: String) -> Array[int]:
	var encounters: Array = content.area(area_id).get("encounters", [])
	var out: Array[int] = []
	for i in encounters.size():
		if not is_cleared(profile, area_id, i):
			out.append(i)
	if out.is_empty() and not gate(profile, content, area_id, "east").is_empty():
		profile.cleared.erase(area_id)
		for i in encounters.size():
			out.append(i)
	return out


## Where a farming ground (AreaRules.FARM) refills: the west edge of its first
## fight's ground, where the taxi sets the hero down. -INF anywhere else.
static func refill_x(content: ContentDB, area_id: String) -> float:
	if AreaRules.kind(content, area_id) != AreaRules.FARM:
		return -INF
	var west := INF
	for encounter: Dictionary in content.area(area_id).get("encounters", []):
		west = minf(west, float(encounter["arena"][0]))
	return west if west != INF else -INF


## A farming ground's fights repeat: once every one there is won, they all
## come back as soon as the hero stands west of refill_x (arriving by taxi,
## loading a save there, or walking back for another round). A rest brings
## them back too, as everywhere. Returns true when it has just refilled.
## Nothing new is saved: the won fights are forgotten, as a rest does.
static func refill(
	profile: PlayerProfile, content: ContentDB, area_id: String, hero_x: float
) -> bool:
	if hero_x >= refill_x(content, area_id) or not pending(profile, content, area_id).is_empty():
		return false
	profile.cleared.erase(area_id)
	return true


## What still keeps `area_id`'s exit on `side` shut: {"defeat", "count",
## "hint", "done", "side"} (done: how many are down so far), or {} when it is
## open. Exits open once the hero has defeated enough of the enemy that
## guards them, so the street opens as the story moves on, whichever quest
## is active.
static func gate(
	profile: PlayerProfile, content: ContentDB, area_id: String, side: String
) -> Dictionary:
	var requires: Dictionary = content.area(area_id).get("exits", {}).get(side, {}).get(
		"requires", {}
	)
	if requires.is_empty():
		return {}
	var done := int(profile.defeated.get(str(requires["defeat"]), 0))
	if done >= int(requires["count"]):
		return {}
	var out := requires.duplicate()
	out["done"] = done
	out["side"] = side
	return out


## True for a street area the hero has already passed (AutoRules.is_beaten:
## the area east of it reached, or its boss beaten at the end of the line).
## Its fights still come back after a rest, for farming, but they hold no one
## in (ZoneSim.fight_locked): the hero may fight, walk on east or back west,
## or leave by the pause menu, and a fight walked away from comes back on the
## next visit. Farming grounds and world boss arenas are never "passed".
static func passed(profile: PlayerProfile, content: ContentDB, area_id: String) -> bool:
	return (
		AreaRules.kind(content, area_id) == AreaRules.STREET
		and AutoRules.is_beaten(profile, content, area_id)
	)


## Areas the taxi can take the hero to from `here`: every area reached
## before, in street order.
static func destinations(profile: PlayerProfile, content: ContentDB, here: String) -> Array[String]:
	var out: Array[String] = []
	for area_id in street(content):
		if area_id != here and area_id in profile.visited:
			out.append(area_id)
	return out


## Area ids from the start eastwards.
static func street(content: ContentDB) -> Array[String]:
	var out: Array[String] = [content.start_area]
	var here := content.start_area
	while content.area(here).get("exits", {}).has("east"):
		here = str(content.area(here)["exits"]["east"]["to"])
		if here in out:
			break
		out.append(here)
	return out


## Fills `profile` from saved data (already migrated), dropping unknown areas
## and encounters. Every area west of the saved one counts as reached: the
## hero walked through it to get there.
static func load_into(profile: PlayerProfile, saved: Dictionary, content: ContentDB) -> void:
	var cleared: Variant = saved.get("cleared", {})
	if cleared is Dictionary:
		for area_id: String in cleared:
			var count: int = content.area(area_id).get("encounters", []).size()
			if cleared[area_id] is Array:
				for index: Variant in cleared[area_id]:
					if int(index) >= 0 and int(index) < count:
						mark_cleared(profile, area_id, int(index))
	var visited: Variant = saved.get("visited", [])
	if visited is Array:
		for area_id: Variant in visited:
			if content.areas.has(str(area_id)):
				visit(profile, str(area_id))
	# Only a hero standing on the street walked through the areas west of it.
	# Off the street (the city, a world boss arena) nothing more is implied:
	# without this check the walk never met the saved area and marked the
	# whole street, up to the final chapter, as reached.
	var road := street(content)
	if profile.area not in road:
		# Every hero starts at the start area, so that much is always reached.
		visit(profile, content.start_area)
		return
	for area_id in road:
		visit(profile, area_id)
		if area_id == profile.area:
			break
