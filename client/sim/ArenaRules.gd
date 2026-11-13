class_name ArenaRules
extends RefCounted
## The arena ladder (data/arena.json). Rivals, each a player's hero played by
## the computer (ArenaBrain), are ranked 1 (the champion) down; a new
## challenger starts below them all. Beating a rival ranked above swaps the
## two places, and nobody else moves. A loss, a draw, or a win over a rival
## at or below the player's rank moves nobody.
##
## What each rival is (job, level, gear by slot and upgrade, AI, personality)
## is configuration resolved by ArenaLoadout; a rival keeps it as it moves.
##
## The ladder is kept per character (PlayerProfile.arena): "order" of rival
## ids and "you", top first; "best" rank; "wins", "losses", "draws";
## "defenses" and "streak" (won as champion); "paid" (reward ranks paid);
## "refresh" (the "New rivals" count); "next_match" and "last_recorded"
## (match ids: a result is applied once); "pending" (a match under way, a
## forfeit if the game ends during it); "history" (latest results). Pure
## rules, shared with the server.

## What an arena rival's Fighter.kind is (it is no enemy of enemies.json).
const KIND := "arena_rival"
const YOU := "you"
const WIN := "win"
const LOSS := "loss"
const DRAW := "draw"
const RESULTS := [WIN, LOSS, DRAW]
const COUNTERS := ["best", "wins", "losses", "draws", "defenses", "streak", "refresh"]
const IDS := ["next_match", "last_recorded"]
## Resolved rivals kept at most (see rival()).
const CACHE_LIMIT := 2000

static var _resolved := {}


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
	return rank >= 1 and rank <= size(content) and id == rival_id(rank)


## "" when `profile` may enter the arena, else why not.
static func closed(profile: PlayerProfile, content: ContentDB) -> String:
	var level := int(spec(content).get("entry_level", 1))
	if profile.level < level:
		return "The arena takes fighters from level %d." % level
	return ""


## The ladder of `profile`, made whole. A damaged order is repaired keeping
## every valid entry where it stood (duplicates and unknown ids dropped, a
## missing rival put back at its starting rank, a missing player at the
## bottom), so a legitimate rank is never thrown away.
static func state(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	var arena: Dictionary = profile.arena
	var order: Variant = arena.get("order", [])
	if not _valid_order(content, order):
		arena["order"] = _repair(content, order)
	for field: String in COUNTERS + IDS:
		arena[field] = maxi(0, int(arena.get(field, 0)))
	var bottom := size(content) + 1
	if int(arena["best"]) == 0 or int(arena["best"]) > bottom:
		arena["best"] = bottom
	arena["best"] = mini(int(arena["best"]), (arena["order"] as Array).find(YOU) + 1)
	arena["next_match"] = maxi(int(arena["next_match"]), int(arena["last_recorded"]))
	if not arena.get("paid") is Array:
		arena["paid"] = []
	if not arena.get("history") is Array:
		arena["history"] = []
	if not arena.get("pending") is Dictionary:
		arena["pending"] = {}
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


static func _repair(content: ContentDB, order: Variant) -> Array:
	var kept: Array = []
	var seen := {}
	if order is Array:
		for id: Variant in order:
			var key := str(id)
			if not seen.has(key) and (key == YOU or is_rival(content, key)):
				kept.append(key)
				seen[key] = true
	for rank in range(1, size(content) + 1):
		var id := rival_id(rank)
		if not seen.has(id):
			kept.insert(mini(rank - 1, kept.size()), id)
	if not seen.has(YOU):
		kept.append(YOU)
	return kept


## The rank (1 = champion) of `who` ("you" or a rival id).
static func rank_of(profile: PlayerProfile, content: ContentDB, who := YOU) -> int:
	return (state(profile, content)["order"] as Array).find(who) + 1


## The champion's id: a rival, or "you".
static func champion(profile: PlayerProfile, content: ContentDB) -> String:
	return str(state(profile, content)["order"][0])


## Rival `id` resolved (ArenaLoadout.resolve). Resolutions are kept per
## content and configuration (a changed configuration is a new key), so the
## ladder screen can compare many rivals cheaply. Read-only: copy before
## changing it (ArenaMatch keeps its own copy).
static func rival(content: ContentDB, id: String) -> Dictionary:
	var key := "%d|%d|%s" % [content.get_instance_id(), content.arena.hash(), id]
	if not _resolved.has(key):
		if _resolved.size() > CACHE_LIMIT:
			_resolved.clear()
		_resolved[key] = ArenaLoadout.resolve(content, id)
	return _resolved[key]


## Whether rival `id` may be offered: it resolves without an error.
static func fit(content: ContentDB, id: String) -> bool:
	return is_rival(content, id) and (rival(content, id)["errors"] as PackedStringArray).is_empty()


static func rival_profile(content: ContentDB, id: String) -> PlayerProfile:
	return ArenaLoadout.profile(content, rival(content, id))


## The rivals offered now, nearest first. Below rank 5 they come from a
## window above the player that widens with the rank (selection.window_share
## of it, within window_min..window_max): the nearest fit rival, then for
## each of selection.targets the rival in the window whose difficulty ratio
## (difficulty()) is closest to it, so the five run from easy to much
## stronger whatever the gaps in the ladder. "New rivals" (refresh) moves the
## targets a little, deterministically, keeping the nearest. If even the
## hardest pick is Easy, the window widens. With fewer rivals above than
## choices, all of them are offered and the rest are the ranks just below,
## to defend; the champion is offered the ranks below. Rivals whose
## configuration has errors are never offered.
static func choices(profile: PlayerProfile, content: ContentDB) -> Array[String]:
	var arena := state(profile, content)
	var order: Array = arena["order"]
	var mine := order.find(YOU)
	var count := int(spec(content).get("choices", 5))
	if mine < count:
		return _nearest(content, order, mine, count)
	var sel: Dictionary = spec(content).get("selection", {})
	var window := clampi(
		roundi(float(sel.get("window_share", 0.16)) * (mine + 1)),
		int(sel.get("window_min", count)),
		int(sel.get("window_max", 40))
	)
	window = clampi(window, count, mine)
	var power := player_power(profile, content)
	var out: Array[String] = []
	for attempt in 4:
		out = _pick(content, order, mine, count, window, power, int(arena["refresh"]))
		if window >= mine or not _all_easy(content, out, power):
			break
		window = mini(mine, window * 2)
	return out


## The `count` fit rivals nearest above (then below) position `mine`.
static func _nearest(content: ContentDB, order: Array, mine: int, count: int) -> Array[String]:
	var out: Array[String] = []
	for at in range(mine - 1, -1, -1):
		if out.size() < count and fit(content, str(order[at])):
			out.append(str(order[at]))
	for at in range(mine + 1, order.size()):
		if out.size() < count and fit(content, str(order[at])):
			out.append(str(order[at]))
	return out


static func _pick(
	content: ContentDB, order: Array, mine: int, count: int, window: int, power: int, refresh: int
) -> Array[String]:
	var targets: Array = spec(content).get("selection", {}).get("targets", [0.75, 1.0, 1.2, 1.5])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([mine, refresh])
	var pool: Array[String] = []
	var offset := 1
	# The window, stretched past rivals that cannot be offered until `count`
	# can be.
	while offset <= mine and (offset <= window or pool.size() < count):
		var id := str(order[mine - offset])
		if fit(content, id):
			pool.append(id)
		offset += 1
	var out: Array[String] = []
	if pool.is_empty():
		return out
	out.append(pool[0])
	for target: Variant in targets:
		if out.size() >= count:
			break
		var want := float(target)
		if refresh > 0:
			want *= 1.0 + rng.randf_range(-0.15, 0.15)
		var best := ""
		var best_gap := INF
		for id in pool:
			if id in out:
				continue
			var gap := absf(log(maxf(0.01, _ratio(content, id, power)) / want))
			if gap < best_gap:
				best_gap = gap
				best = id
		if best != "":
			out.append(best)
	for id in pool:
		if out.size() < count and id not in out:
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return order.find(a) > order.find(b))
	return out


static func _ratio(content: ContentDB, id: String, power: int) -> float:
	return float(difficulty(content, id, power)["ratio"])


static func _all_easy(content: ContentDB, ids: Array[String], power: int) -> bool:
	for id in ids:
		if _ratio(content, id, power) >= _easy_below(content):
			return false
	return true


static func _easy_below(content: ContentDB) -> float:
	var labels: Array = spec(content).get("difficulty", [])
	return float(labels[0]["below"]) if not labels.is_empty() else 0.85


## "New rivals": a different spread of the same window, free and unlimited.
static func refresh(profile: PlayerProfile, content: ContentDB) -> void:
	var arena := state(profile, content)
	arena["refresh"] = int(arena["refresh"]) + 1


## How hard rival `id` is for a player of combat power `power`:
## {"power", "ratio", "label"}. The ratio is the rival's power over the
## player's, scaled by its AI (0.85 at skill 0 to 1.15 at skill 1), and the
## label is the first of data's "difficulty" bands it is below.
static func difficulty(content: ContentDB, id: String, power: int) -> Dictionary:
	var data := rival(content, id)
	var theirs := rival_power(content, id)
	var ratio := float(theirs) / maxf(1.0, float(power)) * (0.85 + 0.3 * float(data["ai"]))
	var label := ""
	for band: Dictionary in spec(content).get("difficulty", []):
		if label == "" and ratio < float(band["below"]):
			label = str(band["label"])
	return {"power": theirs, "ratio": ratio, "label": label}


## The name of an AI skill level ("Beginner" .. "Master").
static func ai_label(content: ContentDB, skill: float) -> String:
	var label := ""
	for level: Dictionary in spec(content).get("ai_levels", []):
		if skill >= float(level["from"]) - 0.0001:
			label = str(level["label"])
	return label


## A new match id, for a match against `id` about to start.
static func begin(profile: PlayerProfile, content: ContentDB) -> int:
	var arena := state(profile, content)
	arena["next_match"] = int(arena["next_match"]) + 1
	return int(arena["next_match"])


## The match `match_id` has started fighting: kept so a game closed during
## it counts as a forfeit (settle_pending). The countdown is not a match yet.
static func mark_active(
	profile: PlayerProfile, content: ContentDB, match_id: int, id: String
) -> void:
	var arena := state(profile, content)
	arena["pending"] = {
		"match": match_id, "rival": id, "version": int(spec(content).get("config_version", 1))
	}


## A match left under way (the game closed during it): recorded as a loss
## by forfeit, once. Returns the record() result, or {} when none was left.
static func settle_pending(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	var pending: Dictionary = state(profile, content)["pending"]
	if pending.is_empty():
		return {}
	var id := str(pending.get("rival", ""))
	var match_id := int(pending.get("match", 0))
	if not is_rival(content, id) or match_id <= 0:
		profile.arena["pending"] = {}
		return {}
	var details := {"reason": "forfeit", "version": int(pending.get("version", 0))}
	return record(profile, content, id, LOSS, match_id, details)


## Records the result of match `match_id` against `id`: `result` is WIN,
## LOSS or DRAW. A win over a rival ranked above swaps their places. A match
## id already recorded changes nothing (the result says "duplicate"), so a
## result applied twice cannot move a rank or pay twice. `details` may give
## "reason", "seconds" and "version" for the history. Returns {"result",
## "won", "old_rank", "new_rank", "best", "new_best", "money", "match",
## "duplicate"}; money is the reward for a best rank first reached.
static func record(
	profile: PlayerProfile,
	content: ContentDB,
	id: String,
	result: String,
	match_id := 0,
	details := {}
) -> Dictionary:
	var arena := state(profile, content)
	if match_id <= 0:
		match_id = begin(profile, content)
	var order: Array = arena["order"]
	var mine := order.find(YOU)
	var out := {
		"result": result,
		"won": result == WIN,
		"old_rank": mine + 1,
		"new_rank": mine + 1,
		"best": int(arena["best"]),
		"new_best": false,
		"money": 0,
		"match": match_id,
		"duplicate": false,
	}
	if (
		match_id <= int(arena["last_recorded"])
		or result not in RESULTS
		or not is_rival(content, id)
	):
		out["duplicate"] = match_id <= int(arena["last_recorded"])
		return out
	arena["last_recorded"] = match_id
	arena["next_match"] = maxi(int(arena["next_match"]), match_id)
	if int(arena["pending"].get("match", -1)) == match_id:
		arena["pending"] = {}
	var theirs := order.find(id)
	match result:
		WIN:
			arena["wins"] = int(arena["wins"]) + 1
			if theirs >= 0 and theirs < mine:
				order[mine] = id
				order[theirs] = YOU
				out["new_rank"] = theirs + 1
			elif mine == 0:
				arena["defenses"] = int(arena["defenses"]) + 1
				arena["streak"] = int(arena["streak"]) + 1
		LOSS:
			arena["losses"] = int(arena["losses"]) + 1
			arena["streak"] = 0
		DRAW:
			arena["draws"] = int(arena["draws"]) + 1
	out["new_best"] = int(out["new_rank"]) < int(arena["best"])
	arena["best"] = mini(int(arena["best"]), int(out["new_rank"]))
	out["best"] = arena["best"]
	for reward: Dictionary in spec(content).get("rewards", []):
		var at := int(reward["best"])
		if int(arena["best"]) <= at and at not in arena["paid"]:
			arena["paid"].append(at)
			out["money"] = int(out["money"]) + int(reward.get("money", 0))
	profile.money += int(out["money"])
	_remember(arena, content, id, out, details)
	return out


static func _remember(
	arena: Dictionary, content: ContentDB, id: String, out: Dictionary, details: Dictionary
) -> void:
	var history: Array = arena["history"]
	(
		history
		. push_front(
			{
				"match": out["match"],
				"rival": id,
				"result": out["result"],
				"reason": str(details.get("reason", "")),
				"old_rank": out["old_rank"],
				"new_rank": out["new_rank"],
				"seconds": int(details.get("seconds", 0)),
				"version": int(details.get("version", spec(content).get("config_version", 1))),
			}
		)
	)
	var keep := int(spec(content).get("history_size", 20))
	while history.size() > keep:
		history.pop_back()


## Wins over all recorded matches, 0..1 (0 before any).
static func win_rate(arena: Dictionary) -> float:
	var total := int(arena["wins"]) + int(arena["losses"]) + int(arena["draws"])
	return float(arena["wins"]) / total if total > 0 else 0.0


## Combat power: one number for how strong a fighter's stats make it, as
## arenas show it (effective health times damage output).
static func power(stats: Dictionary, level: int) -> int:
	var health := float(stats["max_hp"]) * (1.0 + float(stats["defense"]) / 50.0)
	var output := float(stats["power"]) * (1.0 + float(stats["crit"]) * 0.5)
	output *= float(stats["attack_speed"])
	return roundi(health * output / 10.0) + level * 10


static func player_power(profile: PlayerProfile, content: ContentDB) -> int:
	return power(profile.stats(content), profile.level)


static func power_of(content: ContentDB, data: Dictionary) -> int:
	var made := ArenaLoadout.profile(content, data)
	return power(made.stats(content), made.level)


static func rival_power(content: ContentDB, id: String) -> int:
	var data := rival(content, id)
	if not data.has("_power"):
		data["_power"] = power_of(content, data)
	return int(data["_power"])


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
	var margin := float(data.get("draw_margin", 0.02))
	if margin < 0.0 or margin >= 0.5:
		out.append("arena.draw_margin: from 0 to under 0.5")
	for reward: Variant in data.get("rewards", []):
		if not reward is Dictionary or int(reward.get("best", 0)) < 1:
			out.append("arena.rewards: each needs a best rank")
	var labels: Array = data.get("difficulty", [])
	if labels.is_empty():
		out.append("arena.difficulty: at least one band")
	out.append_array(ArenaLoadout.problems(content))
	return out
