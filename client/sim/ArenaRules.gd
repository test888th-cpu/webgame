class_name ArenaRules
extends RefCounted
## The arena ladder (data/arena.json). Fifty rivals, each a player's hero
## played by the computer (ArenaBrain), ranked 1 (the champion) to 50; a new
## challenger starts below them all. The arena offers the five rivals ranked
## just above the player; beating one swaps their ranks, so the player climbs
## and the rival drops to where the player stood. Losing changes nothing.
##
## A rival is defined by the rank it starts at: its band's level, gear grades,
## upgrades (from plain gear at the bottom, through the best gear in the game
## unupgraded, to the best gear at +1 to +7, mixed by slot) and AI skill all
## rise with it. A rival keeps its strength as it moves on the ladder.
##
## The ladder is kept per character (PlayerProfile.arena: "order" of rival
## ids and "you", top first; "best" rank; "wins"; "losses"; "paid": reward
## ranks already paid). Pure rules, shared with the server.

## What an arena rival's Fighter.kind is (it is no enemy of enemies.json).
const KIND := "arena_rival"
const YOU := "you"
const SLOT_SPREAD: Array[int] = [1, 0, -1, 1, 0, -1]
const MAX_PLUS := 7


static func spec(content: ContentDB) -> Dictionary:
	return content.arena


## How many rivals the ladder holds.
static func size(content: ContentDB) -> int:
	return (spec(content).get("names", []) as Array).size()


## The id of the rival who starts at `rank`.
static func rival_id(rank: int) -> String:
	return "r%d" % rank


static func start_rank(id: String) -> int:
	return int(id.substr(1)) if id.begins_with("r") and id.substr(1).is_valid_int() else 0


static func is_rival(content: ContentDB, id: String) -> bool:
	var rank := start_rank(id)
	return rank >= 1 and rank <= size(content)


## "" when `profile` may enter the arena, else why not.
static func closed(profile: PlayerProfile, content: ContentDB) -> String:
	var level := int(spec(content).get("entry_level", 1))
	if profile.level < level:
		return "The arena takes fighters from level %d." % level
	return ""


## The ladder of `profile`, made whole: every rival once and the player once,
## top first (a missing or broken one starts fresh, the player at the bottom).
static func state(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	var arena: Dictionary = profile.arena
	var order: Variant = arena.get("order", [])
	if not _valid_order(content, order):
		order = []
		for rank in range(1, size(content) + 1):
			order.append(rival_id(rank))
		order.append(YOU)
		arena["order"] = order
	for field: String in ["best", "wins", "losses"]:
		arena[field] = maxi(0, int(arena.get(field, 0)))
	if int(arena["best"]) == 0:
		arena["best"] = size(content) + 1
	if not arena.get("paid") is Array:
		arena["paid"] = []
	profile.arena = arena
	return arena


static func _valid_order(content: ContentDB, order: Variant) -> bool:
	if not order is Array or (order as Array).size() != size(content) + 1:
		return false
	var seen := {}
	for id: Variant in order:
		var key := str(id)
		if seen.has(key) or not (key == YOU or is_rival(content, key)):
			return false
		seen[key] = true
	return true


## The rank (1 = champion) of `who` ("you" or a rival id).
static func rank_of(profile: PlayerProfile, content: ContentDB, who := YOU) -> int:
	return (state(profile, content)["order"] as Array).find(who) + 1


## The rivals the arena offers now: the CHOICES ranked just above the player,
## nearest first; the champion is offered the ones just below, to defend.
static func choices(profile: PlayerProfile, content: ContentDB) -> Array[String]:
	var order: Array = state(profile, content)["order"]
	var mine := order.find(YOU)
	var count := int(spec(content).get("choices", 5))
	var out: Array[String] = []
	var step := -1 if mine > 0 else 1
	var at := mine + step
	while out.size() < count and at >= 0 and at < order.size():
		out.append(str(order[at]))
		at += step
	return out


## Records a finished match against `id`: a win over a rival ranked above
## swaps their places. Returns {"won", "old_rank", "new_rank", "best", "new_best",
## "money"} (money: a reward for a best rank first reached).
static func record(profile: PlayerProfile, content: ContentDB, id: String, won: bool) -> Dictionary:
	var arena := state(profile, content)
	var order: Array = arena["order"]
	var mine := order.find(YOU)
	var theirs := order.find(id)
	var out := {"won": won, "old_rank": mine + 1, "new_rank": mine + 1, "money": 0}
	if won:
		arena["wins"] = int(arena["wins"]) + 1
		if theirs >= 0 and theirs < mine:
			order[mine] = id
			order[theirs] = YOU
			out["new_rank"] = theirs + 1
	else:
		arena["losses"] = int(arena["losses"]) + 1
	out["new_best"] = int(out["new_rank"]) < int(arena["best"])
	arena["best"] = mini(int(arena["best"]), int(out["new_rank"]))
	out["best"] = arena["best"]
	for reward: Dictionary in spec(content).get("rewards", []):
		var at := int(reward["best"])
		if int(arena["best"]) <= at and at not in arena["paid"]:
			arena["paid"].append(at)
			out["money"] = int(out["money"]) + int(reward.get("money", 0))
	profile.money += int(out["money"])
	return out


## Everything that makes rival `id`: {"id", "name", "hero", "level",
## "gear": [item ids by slot], "plus": {item id: upgrade}, "ai": skill 0..1}.
static func rival(content: ContentDB, id: String) -> Dictionary:
	var rank := start_rank(id)
	var band := _band(content, rank)
	var t := _along(band, rank)
	var level := roundi(lerpf(float(band["level"][0]), float(band["level"][1]), t))
	var jobs: Array = content.job_order
	var job := str(jobs[rank % jobs.size()])
	var gear := best_gear(content, level, band["grades"])
	var average := lerpf(float(band["plus"][0]), float(band["plus"][1]), t)
	var plus := {}
	for i in gear.size():
		var spread := SLOT_SPREAD[(i + rank) % SLOT_SPREAD.size()] if average >= 1.0 else 0
		plus[gear[i]] = clampi(roundi(average) + spread, 0, MAX_PLUS)
	return {
		"id": id,
		"name": str(spec(content)["names"][rank - 1]),
		"hero": JobRules.hero_of(content, job),
		"level": level,
		"gear": gear,
		"plus": plus,
		"ai": lerpf(float(band["ai"][0]), float(band["ai"][1]), t),
	}


## The band of the ladder `rank` starts in.
static func _band(content: ContentDB, rank: int) -> Dictionary:
	for band: Dictionary in spec(content).get("bands", []):
		if rank <= int(band["from"]) and rank >= int(band["to"]):
			return band
	return {}


## 0 at the band's weakest rank, 1 at its strongest.
static func _along(band: Dictionary, rank: int) -> float:
	var weakest := int(band["from"])
	var strongest := int(band["to"])
	return 1.0 if weakest == strongest else float(weakest - rank) / (weakest - strongest)


## The best equipment of each slot a hero of `level` may wear, among `grades`
## (ItemRules.score), as a player would have collected it.
static func best_gear(content: ContentDB, level: int, grades: Array) -> Array[String]:
	var out: Array[String] = []
	for slot: String in PlayerProfile.SLOTS:
		var best := ""
		for item_id: String in content.items:
			var item := content.item(item_id)
			if item.get("type") != "equipment" or str(item.get("slot")) != slot:
				continue
			if int(item.get("level", 1)) > level or str(item.get("rarity")) not in grades:
				continue
			if best == "" or ItemRules.score(item) > ItemRules.score(content.item(best)):
				best = item_id
		if best != "":
			out.append(best)
	return out


## A character made for rival `id`: its hero at its level, its gear worn and
## upgraded. Never saved.
static func rival_profile(content: ContentDB, id: String) -> PlayerProfile:
	var data := rival(content, id)
	var profile := PlayerProfile.new_game(content, str(data["hero"]), str(data["name"]))
	profile.level = int(data["level"])
	for item_id: String in data["gear"]:
		profile.add_item(item_id)
		profile.equip(item_id, content)
		var worn := str(profile.equipment[str(content.item(item_id)["slot"])])
		if int(data["plus"][item_id]) > 0 and worn != "":
			profile.enhance[worn] = int(data["plus"][item_id])
	return profile


## Combat power: one number for how strong a fighter's stats make it, as
## arenas show it (effective health times damage output).
static func power(stats: Dictionary, level: int) -> int:
	var health := float(stats["max_hp"]) * (1.0 + float(stats["defense"]) / 50.0)
	var output := float(stats["power"]) * (1.0 + float(stats["crit"]) * 0.5)
	output *= float(stats["attack_speed"])
	return roundi(health * output / 10.0) + level * 10


static func player_power(profile: PlayerProfile, content: ContentDB) -> int:
	return power(profile.stats(content), profile.level)


static func rival_power(content: ContentDB, id: String) -> int:
	var profile := rival_profile(content, id)
	return power(profile.stats(content), profile.level)


## What is wrong with data/arena.json.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var data := spec(content)
	var count := size(content)
	if count < 6:
		out.append("arena.names: at least six rivals")
	if not content.areas.has(str(data.get("area", ""))):
		out.append("arena.area: unknown area")
	elif not content.area(str(data["area"])).get("arena", false):
		out.append('arena.area: the area must say "arena": true')
	for field: String in ["entry_level", "choices", "match_seconds", "countdown_ticks"]:
		var value: Variant = data.get(field)
		if not (value is float or value is int) or value < 1:
			out.append("arena.%s: at least 1" % field)
	if float(data.get("hp_scale", 0)) < 1.0:
		out.append("arena.hp_scale: at least 1")
	var covered := {}
	for band: Variant in data.get("bands", []):
		out.append_array(_band_problems(band, covered))
	for rank in range(1, count + 1):
		if not covered.has(rank):
			out.append("arena.bands: rank %d is in no band" % rank)
	for reward: Variant in data.get("rewards", []):
		if not reward is Dictionary or int(reward.get("best", 0)) < 1:
			out.append("arena.rewards: each needs a best rank")
	return out


static func _band_problems(band: Variant, covered: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	if not band is Dictionary:
		out.append("arena.bands: expected objects")
		return out
	for rank in range(int(band.get("to", 1)), int(band.get("from", 0)) + 1):
		if covered.has(rank):
			out.append("arena.bands: rank %d in two bands" % rank)
		covered[rank] = true
	for field: String in ["level", "plus", "ai"]:
		var pair: Variant = band.get(field)
		if not pair is Array or (pair as Array).size() != 2 or pair[0] > pair[1]:
			out.append("arena.bands.%s: [weakest, strongest], rising" % field)
	if not band.get("grades") is Array or (band["grades"] as Array).is_empty():
		out.append("arena.bands.grades: a list of rarities")
	elif int(band.get("plus", [0, 0])[1]) > MAX_PLUS:
		out.append("arena.bands.plus: at most %d" % MAX_PLUS)
	return out
