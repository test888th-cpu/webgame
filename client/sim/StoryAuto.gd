class_name StoryAuto
extends RefCounted
## Auto battle through the story, as the auto-quest of the field games it
## follows: it plays the next step of the quest the map points to
## (MapRules.goal), so a hero can go from Chief Odo's first quest to the
## Director with no area cleared by hand first.
##
## One step at a time, from where the hero stands:
## * QUEST: a quest to hand in, or one on offer: take it wherever the hero
##   is, as the quest card lets a player (QuestFlow), handing in first so the
##   next one is offered;
## * EAST: the goal lies east of the furthest area reached and this is that
##   area: clear its fights, then walk on through its east exit. The same
##   when that area is next door east (from the city into Depot Yard): the
##   hero walks there, never paying a taxi for one street;
## * STAY: this is the goal area: fight on to its boss;
## * RIDE: the goal (or the furthest area reached on the way to it) is
##   elsewhere: home to the hub, then Win's taxi there. Also the goal area
##   itself when nothing is left to fight in it (its boss beaten before the
##   quest was taken): the rest at the hub brings its fights back;
## * HERE: the quest would send the hero back to an area more than
##   BACKTRACK_LEVELS easier than this one, with a fight here (a quest left
##   behind while playing on by hand): auto keeps fighting here instead of
##   dragging the hero back, and says where that quest is;
## * DONE: the story has nothing left to do.
## The steps only read the profile; AutoBattle carries them out through the
## same actions a player has (QuestRules, the taxi fare, walking), so nothing
## new is saved and a server sees only ordinary actions. Pure rules, shared
## with the server.

const QUEST := "quest"
const EAST := "east"
const STAY := "stay"
const RIDE := "ride"
const DONE := "done"
const HERE := "here"
## How many levels easier an area may be before auto will not ride back to it.
const BACKTRACK_LEVELS := 8


## The next step from `here`: {"do": one of the constants above, "quest"
## and "turn_in" for QUEST, "to" for RIDE}. `cleared` is true when nothing
## is left to fight in `here` this visit.
static func step(
	profile: PlayerProfile, content: ContentDB, here: String, cleared: bool
) -> Dictionary:
	for state in ["complete", "available"]:
		var quest_id := quest_here(profile, content, here, state)
		if quest_id != "":
			return {"do": QUEST, "quest": quest_id, "turn_in": state == "complete"}
	var goal := MapRules.goal(profile, content)
	if goal.is_empty():
		return {"do": DONE}
	var goal_area := str(goal["area"])
	var to := target(profile, content, goal_area)
	if to != here and _backtrack(content, here, to):
		return {"do": HERE, "to": to, "quest": str(goal.get("text", ""))}
	if to != here:
		# Next door (the city's east exit is Depot Yard): walk there, no taxi.
		if AreaRules.next_door(content, here, to):
			return {"do": EAST if _east_of(content, here) == to else RIDE, "to": to}
		return {"do": RIDE, "to": to}
	if goal_area != here:
		return {"do": EAST}
	return {"do": RIDE, "to": here} if cleared else {"do": STAY}


## The first quest in state `state` ("complete" or "available"), or "".
## Taken and handed in from anywhere (the quest card); `area_id` is kept for
## the callers and no longer limits it.
static func quest_here(
	profile: PlayerProfile, content: ContentDB, _area_id: String, state: String
) -> String:
	for quest_id: String in content.quests:
		if QuestRules.status(profile, quest_id, content) == state:
			return quest_id
	return ""


## Where to go for `goal_area`: the area itself once reached, else the
## furthest street area reached west of it (to walk on east from).
static func target(profile: PlayerProfile, content: ContentDB, goal_area: String) -> String:
	if goal_area in profile.visited:
		return goal_area
	var street := StreetMemory.street(content)
	var at := street.find(goal_area)
	if at < 0:
		return goal_area
	for i in range(at, -1, -1):
		if street[i] in profile.visited:
			return street[i]
	return content.start_area


## The area through `area_id`'s east exit, or "".
static func _east_of(content: ContentDB, area_id: String) -> String:
	return str(content.area(area_id).get("exits", {}).get("east", {}).get("to", ""))


## True when going to `to` would take the hero from a fight in `here` back to
## an area more than BACKTRACK_LEVELS easier.
static func _backtrack(content: ContentDB, here: String, to: String) -> bool:
	var area := content.area(here)
	if area.get("encounters", []).is_empty() and not FarmSpawner.active(content, here):
		return false
	var easier := int(area.get("level", 0)) - int(content.area(to).get("level", 0))
	return easier > BACKTRACK_LEVELS
