class_name ReplayRules
extends RefCounted
## Story boss and mini-boss rematches (docs/BLUEPRINT.md D18, the owner's
## rule: the story is completed once, its boss fights stay open for good).
##
## A boss fight is a street encounter holding a boss or an elite (a story
## mini-boss). Once the hero has reached its area it may be fought again any
## number of times: no daily or total cap, no cooldown after a win or a loss.
## A rematch is a fresh fight (ZoneSim builds the boss and its mechanics anew,
## with full health) in the hero's own story instance (SessionRules.STORY).
##
## A rematch only changes which fights the area holds for this visit
## (PlayerProfile.cleared, which a rest clears anyway): the chosen fight comes
## back and the area's other fights stand down, so the hero goes straight to
## it, with no quest or chapter to play again. Quests, evidence, areas reached
## and story gates are never touched. Each win counts in PlayerProfile.defeated
## and rolls the foe's drop table (LootRules) as any kill does; the first-clear
## rewards are quest rewards, paid once by QuestRules.turn_in, and no enemy
## drops evidence or a one-of-a-kind item (problems), so replays never repeat
## them. Pure rules, shared with the server.


## True when encounter `index` of `area_id` is a story boss fight: a street
## encounter with a boss or an elite in it.
static func is_boss_fight(content: ContentDB, area_id: String, index: int) -> bool:
	return foe(content, area_id, index) != ""


## The foe a boss fight is named after: its boss, else its first elite, else
## "" (not a boss fight, or not a story area).
static func foe(content: ContentDB, area_id: String, index: int) -> String:
	if SessionRules.session_type(content, area_id) != SessionRules.STORY:
		return ""
	var encounters: Array = content.area(area_id).get("encounters", [])
	if index < 0 or index >= encounters.size():
		return ""
	var elite := ""
	for wave: Array in encounters[index]["waves"]:
		for kind: String in wave:
			if content.enemy(kind).get("boss", false):
				return kind
			if elite == "" and content.enemy(kind).get("elite", false):
				elite = kind
	return elite


## True when the hero may fight boss fight `index` of `area_id` again: its
## area has been reached. Nothing else is asked, and nothing runs out.
static func unlocked(
	profile: PlayerProfile, content: ContentDB, area_id: String, index: int
) -> bool:
	return is_boss_fight(content, area_id, index) and area_id in profile.visited


## Every boss fight open to the hero, in street order: [{"area", "index",
## "foe"}]. `bosses_only`: just the fights with a boss (not a mini-boss).
static func rematches(
	profile: PlayerProfile, content: ContentDB, bosses_only := false
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for area_id in StreetMemory.street(content):
		for i in content.area(area_id).get("encounters", []).size():
			if not unlocked(profile, content, area_id, i):
				continue
			var kind := foe(content, area_id, i)
			if bosses_only and not content.enemy(kind).get("boss", false):
				continue
			out.append({"area": area_id, "index": i, "foe": kind})
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


## Sets `area_id` up for a rematch of boss fight `index`: that fight is
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


## What would let a replay pay a first-clear reward twice, one message each
## (empty when nothing): an enemy whose drop table holds evidence or a
## one-of-a-kind item. Those come once, from quests. ContentDB.validate adds
## these to its errors.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for kind: String in content.enemies:
		for drop: Variant in content.enemy(kind).get("loot", {}).get("drops", []):
			if not drop is Dictionary:
				continue
			var item := content.item(str(drop.get("item", "")))
			if item.get("type") == "key" or item.get("unique", false):
				out.append(
					"enemies.%s.loot: %s comes once, from a quest" % [kind, drop.get("item")]
				)
	return out
