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
	var requires: Dictionary = content.area(area_id).get("exits", {}).get("east", {}).get(
		"requires", {}
	)
	var open := (
		requires.is_empty()
		or int(profile.defeated.get(str(requires["defeat"]), 0)) >= int(requires["count"])
	)
	if out.is_empty() and not open:
		profile.cleared.erase(area_id)
		for i in encounters.size():
			out.append(i)
	return out


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
	for area_id in street(content):
		visit(profile, area_id)
		if area_id == profile.area:
			break
