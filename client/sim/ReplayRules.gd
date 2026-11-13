class_name ReplayRules
extends RefCounted
## Story boss and story mini-boss replays (docs/BLUEPRINT.md D18, the owner's
## rule: the story is completed once, its boss fights stay open for good).
## Separate from the lairs' shared mini-boss (LairRules) and the world bosses.
##
## A story boss fight is a street encounter holding a boss ("boss": true). As
## on the map (MapRules.kind_of), it is a STAGE boss where its district ends
## and a story MINI-BOSS before that. Elites are neither: an elite is a
## stronger enemy, not a boss fight.
##
## Once the hero has reached its area a boss fight may be fought again any
## number of times: no daily or total cap, no cooldown after a win or a loss.
## A replay is a fresh fight (ZoneSim builds the boss, its phases, skills,
## cooldowns, hazards and timers anew, at full health) in the hero's own story
## instance (SessionRules.STORY).
##
## A replay only changes which fights the area holds for this visit
## (PlayerProfile.cleared, which a rest clears anyway): the chosen fight comes
## back and the area's other fights stand down, so the hero goes straight to
## it, with no quest or chapter to play again. Quests, evidence, areas reached
## and story gates are never touched. Each win counts in PlayerProfile.defeated
## and rolls the boss's drop table as any kill does; a once-only drop already
## owned (evidence, a unique item) is left out alone (LootRules.eligible), and
## first-clear rewards are quest rewards, paid once by QuestRules.turn_in.
## Pure rules, shared with the server.

const STAGE_BOSS := "stage_boss"
const MINI_BOSS := "mini_boss"


## True when encounter `index` of `area_id` is a story boss fight.
static func is_boss_fight(content: ContentDB, area_id: String, index: int) -> bool:
	return foe(content, area_id, index) != ""


## The boss of story fight `index` of `area_id`, or "" (no boss in it, or not
## a story area).
static func foe(content: ContentDB, area_id: String, index: int) -> String:
	if SessionRules.session_type(content, area_id) != SessionRules.STORY:
		return ""
	var encounters: Array = content.area(area_id).get("encounters", [])
	if index < 0 or index >= encounters.size():
		return ""
	for wave: Array in encounters[index]["waves"]:
		for kind: String in wave:
			if content.enemy(kind).get("boss", false):
				return kind
	return ""


## STAGE_BOSS or MINI_BOSS for a story boss fight in `area_id` (MapRules).
static func rank(content: ContentDB, area_id: String) -> String:
	return MINI_BOSS if MapRules.kind_of(content, area_id) == MapRules.MINI_BOSS else STAGE_BOSS


## True when the hero may fight boss fight `index` of `area_id` again: its
## area has been reached. Nothing else is asked, and nothing runs out.
static func unlocked(
	profile: PlayerProfile, content: ContentDB, area_id: String, index: int
) -> bool:
	return is_boss_fight(content, area_id, index) and area_id in profile.visited


## Every story boss fight open to the hero, in street order: [{"area",
## "index", "foe", "rank"}].
static func rematches(profile: PlayerProfile, content: ContentDB) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for area_id in StreetMemory.street(content):
		for i in content.area(area_id).get("encounters", []).size():
			if unlocked(profile, content, area_id, i):
				(
					out
					. append(
						{
							"area": area_id,
							"index": i,
							"foe": foe(content, area_id, i),
							"rank": rank(content, area_id),
						}
					)
				)
	return out


## The boss fight of `area_id` nearest to `x` (the one the hero stands in or
## just fought), or -1 when the area has none.
static func nearest(content: ContentDB, area_id: String, x: float) -> int:
	var best := -1
	var best_gap := INF
	var encounters: Array = content.area(area_id).get("encounters", [])
	for i in encounters.size():
		if not is_boss_fight(content, area_id, i):
			continue
		var arena: Array = encounters[i]["arena"]
		var gap := maxf(0.0, maxf(float(arena[0]) - x, x - float(arena[1])))
		if gap < best_gap:
			best = i
			best_gap = gap
	return best


## The boss fight of `area_id` whose ground `x` is on, or -1.
static func at(content: ContentDB, area_id: String, x: float) -> int:
	var index := nearest(content, area_id, x)
	if index < 0:
		return -1
	var arena: Array = content.area(area_id)["encounters"][index]["arena"]
	return index if x >= float(arena[0]) and x <= float(arena[1]) else -1


## Sets `area_id` up for a replay of boss fight `index`: that fight is
## pending again and the area's other fights stand down for this visit.
## Returns where the hero starts (the west edge of the fight's ground), or
## -1.0 when the fight is not open to the hero (nothing is changed then).
static func rematch(
	profile: PlayerProfile, content: ContentDB, area_id: String, index: int
) -> float:
	if not unlocked(profile, content, area_id, index):
		return -1.0
	var others: Array = []
	var encounters: Array = content.area(area_id).get("encounters", [])
	for i in encounters.size():
		if i != index:
			others.append(i)
	profile.cleared[area_id] = others
	return float(encounters[index]["arena"][0])
