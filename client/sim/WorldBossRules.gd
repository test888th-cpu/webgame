class_name WorldBossRules
extends RefCounted
## World bosses (world_boss.json): bosses far bigger than one fight, open on
## a clock for everyone at once. Each has its own schedule: every
## "period_minutes", starting "offset_minutes" past the epoch's period, a
## round opens for "open_minutes". The boss has one health pool per round,
## sized for "players" players ("pool" times its usual health each), worn
## down attempt by attempt ("attempt_seconds" each).
##
## Rewards come two ways:
## * personal tiers: shares of one player's part of the pool (the pool over
##   "players"), each paid once per round, so a player who pulls their weight
##   earns them all whatever the rest do;
## * the kill ("kill"): paid to everyone who fought, once the whole pool falls
##   within the round. A boss built for one player can fall to one player; a
##   boss built for ten needs ten, and its rarest drops come with the kill.
## Some bosses take only heroes of "min_hero_level" or more and fight at a
## fixed "level"; others keep pace with the hero ("level_above_hero", never
## below "min_level"). Rounds are numbered from the Unix epoch, so every
## client and the future server agree on which round it is.
##
## Single-player today, the pool is the hero's own; at IL-7 the server keeps
## one pool per boss for all players and pays from the damage it saw. These
## rules are pure (time is passed in), so the server reuses them unchanged.


static func spec(content: ContentDB, boss: String) -> Dictionary:
	return content.world_bosses.get(boss, {})


## Boss `boss`'s round at Unix time `now`: {"round": its number, "open":
## bool, "opens_at": the next opening (or this one's), "closes_at": when this
## round closes}. Times are Unix seconds.
static func window(content: ContentDB, boss: String, now: int) -> Dictionary:
	var data := spec(content, boss)
	var period := int(data["period_minutes"]) * 60
	var length := int(data["open_minutes"]) * 60
	var offset := int(data.get("offset_minutes", 0)) * 60
	var round := floori(float(now - offset) / period)
	var start := round * period + offset
	var open := now - start < length
	return {
		"round": round,
		"open": open,
		"opens_at": start if open else start + period,
		"closes_at": start + length,
	}


static func unlocked(profile: PlayerProfile, content: ContentDB, boss: String) -> bool:
	return int(profile.defeated.get(str(spec(content, boss)["unlock"]), 0)) > 0


## Why the hero cannot face `boss` at `now`, or "" when they can.
static func problem(profile: PlayerProfile, content: ContentDB, boss: String, now: int) -> String:
	var data := spec(content, boss)
	if not unlocked(profile, content, boss):
		var unlock := str(content.enemy(str(data["unlock"])).get("name", ""))
		return "Not yet. Defeat %s first." % unlock
	var needed := int(data.get("min_hero_level", 1))
	if profile.level < needed:
		return "Only heroes of level %d or more stand a chance." % needed
	if not window(content, boss, now)["open"]:
		return "Not out now. Back in %s." % wait_text(content, boss, now)
	return ""


## "1h 12m" or "42m": until the next opening, or until closing while open.
static func wait_text(content: ContentDB, boss: String, now: int) -> String:
	var round := window(content, boss, now)
	var left: int = (round["closes_at"] if round["open"] else round["opens_at"]) - now
	var minutes := maxi(1, ceili(left / 60.0))
	return "%dh %dm" % [minutes / 60, minutes % 60] if minutes >= 60 else "%dm" % minutes


## The level `boss` fights at for this hero.
static func level_for(profile: PlayerProfile, content: ContentDB, boss: String) -> int:
	var data := spec(content, boss)
	if data.has("level"):
		return int(data["level"])
	var above := int(data.get("level_above_hero", 2))
	return maxi(int(data.get("min_level", 1)), profile.level + above)


## The round's whole health pool at boss level `level`.
static func pool(content: ContentDB, boss: String, level: int) -> int:
	var data := spec(content, boss)
	var stats := LevelRules.enemy_stats(content.enemy(str(data["enemy"])), level)
	return int(stats["max_hp"]) * int(data["pool"]) * int(data.get("players", 1))


## One player's part of a pool of `total`: what the personal tiers measure.
static func part(content: ContentDB, boss: String, total: int) -> int:
	return maxi(1, total / int(spec(content, boss).get("players", 1)))


## The hero's progress against `boss` in round `round` (fresh in a new round).
static func progress(profile: PlayerProfile, boss: String, round: int) -> Dictionary:
	var state: Dictionary = profile.world_boss.get(boss, {})
	if int(state.get("round", -1)) != round:
		state = {"round": round, "dealt": 0, "tiers": 0, "killed": false}
		profile.world_boss[boss] = state
	return state


## Banks `dealt` damage against `boss` in round `round` (a pool of `total`;
## `slain` when the pool fell), and pays every personal tier newly reached
## and the kill, once: {"tiers": [tier indices], "kill": bool, "money": int,
## "items": {item id: count}}. Money grows with the boss's level like other
## loot; rare drops are rolled with `rng` (seeded by the caller).
static func award(
	profile: PlayerProfile,
	content: ContentDB,
	boss: String,
	round: int,
	dealt: int,
	total: int,
	level: int,
	rng: RandomNumberGenerator,
	slain := false
) -> Dictionary:
	var data := spec(content, boss)
	var state := progress(profile, boss, round)
	state["dealt"] = mini(total, int(state["dealt"]) + maxi(0, dealt))
	var paid := {"tiers": [], "kill": false, "money": 0, "items": {}}
	var scale := 1.0 + LevelRules.MONEY_PER_LEVEL * (level - 1)
	var mine := part(content, boss, total)
	var tiers: Array = data["tiers"]
	while int(state["tiers"]) < tiers.size():
		var tier: Dictionary = tiers[int(state["tiers"])]
		if int(state["dealt"]) < ceili(mine * float(tier["share"])):
			break
		paid["tiers"].append(int(state["tiers"]))
		_pay(paid, tier, scale, rng)
		state["tiers"] = int(state["tiers"]) + 1
	if slain and not state.get("killed", false) and data.has("kill"):
		state["killed"] = true
		paid["kill"] = true
		_pay(paid, data["kill"], scale, rng)
	profile.money += int(paid["money"])
	for item_id: String in paid["items"]:
		profile.add_item(item_id, int(paid["items"][item_id]))
	state.erase("attempt")
	return paid


## Keeps the damage of an attempt still being fought on the profile, so it
## is saved with it: if the game closes mid-fight, settle() banks it later.
static func note_attempt(
	profile: PlayerProfile, boss: String, round: int, dealt: int, total: int, level: int
) -> void:
	var state := progress(profile, boss, round)
	state["attempt"] = {"dealt": dealt, "total": total, "level": level}


## Banks every attempt that never finished (the tab closed, the game
## crashed) as if it had ended there. Returns {boss id: what it paid}.
static func settle(
	profile: PlayerProfile, content: ContentDB, rng: RandomNumberGenerator
) -> Dictionary:
	var settled := {}
	for boss: String in profile.world_boss.keys():
		var state: Dictionary = profile.world_boss[boss]
		if not state.has("attempt") or spec(content, boss).is_empty():
			continue
		var attempt: Dictionary = state["attempt"]
		settled[boss] = award(
			profile,
			content,
			boss,
			int(state["round"]),
			int(attempt["dealt"]),
			int(attempt["total"]),
			int(attempt["level"]),
			rng
		)
	return settled


## Adds one reward (coins, items, rolled drops) to `paid`.
static func _pay(
	paid: Dictionary, reward: Dictionary, scale: float, rng: RandomNumberGenerator
) -> void:
	paid["money"] += roundi(float(reward.get("money", 0)) * scale)
	var found: Dictionary = reward.get("items", {}).duplicate()
	var rolls: Dictionary = reward.get("rolls", {})
	var names: Array = rolls.keys()
	names.sort()
	for item_id: String in names:
		if rng.randf() < float(rolls[item_id]):
			found[item_id] = int(found.get(item_id, 0)) + 1
	for item_id: String in found:
		paid["items"][item_id] = int(paid["items"].get(item_id, 0)) + int(found[item_id])
