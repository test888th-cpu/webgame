class_name WorldBossRules
extends RefCounted
## The world boss (world_boss.json): a boss far bigger than one fight, open
## on a clock for everyone at once. Every "period_minutes" a round opens for
## "open_minutes". The boss has one health pool per round, "pool" times its
## usual health, worn down attempt by attempt ("attempt_seconds" each);
## whoever deals damage climbs reward tiers (shares of the pool), each paid
## once per round. Rounds are numbered from the Unix epoch, so every client
## and the future server agree on which round it is.
##
## Single-player today, the pool is the hero's own; at IL-7 the server keeps
## one pool for all players and pays tiers by each player's share. These rules
## are pure (time is passed in), so the server can reuse them unchanged.


## The round at Unix time `now`: {"round": its number, "open": bool,
## "opens_at": the next opening (or this one's), "closes_at": when this round
## closes}. Times are Unix seconds.
static func window(content: ContentDB, now: int) -> Dictionary:
	var period := int(content.world_boss["period_minutes"]) * 60
	var length := int(content.world_boss["open_minutes"]) * 60
	var round := now / period
	var start := round * period
	var open := now - start < length
	return {
		"round": round,
		"open": open,
		"opens_at": start if open else start + period,
		"closes_at": start + length,
	}


## Why the hero cannot face the world boss at `now`, or "" when they can.
static func problem(profile: PlayerProfile, content: ContentDB, now: int) -> String:
	if not unlocked(profile, content):
		var unlock := str(content.enemy(str(content.world_boss["unlock"])).get("name", ""))
		return "Something stirs in the drains. Defeat %s first." % unlock
	if not window(content, now)["open"]:
		return "The Great Drain is quiet. It opens again in %s." % wait_text(content, now)
	return ""


static func unlocked(profile: PlayerProfile, content: ContentDB) -> bool:
	return int(profile.defeated.get(str(content.world_boss["unlock"]), 0)) > 0


## "1h 12m" or "42m": until the next opening, or until closing while open.
static func wait_text(content: ContentDB, now: int) -> String:
	var round := window(content, now)
	var left: int = (round["closes_at"] if round["open"] else round["opens_at"]) - now
	var minutes := maxi(1, ceili(left / 60.0))
	return "%dh %dm" % [minutes / 60, minutes % 60] if minutes >= 60 else "%dm" % minutes


## The level the boss fights at for this hero: a little above them, never
## below "min_level".
static func level_for(profile: PlayerProfile, content: ContentDB) -> int:
	var above := int(content.world_boss.get("level_above_hero", 2))
	return maxi(int(content.world_boss["min_level"]), profile.level + above)


## The round's health pool at boss level `level`.
static func pool(content: ContentDB, level: int) -> int:
	var data := content.enemy(str(content.world_boss["enemy"]))
	var stats := LevelRules.enemy_stats(data, level)
	return int(stats["max_hp"]) * int(content.world_boss["pool"])


## The hero's progress in round `round` (a fresh one when it is a new round).
static func progress(profile: PlayerProfile, round: int) -> Dictionary:
	if int(profile.world_boss.get("round", -1)) != round:
		profile.world_boss = {"round": round, "dealt": 0, "tiers": 0}
	return profile.world_boss


## Adds `dealt` damage to round `round` against a pool of `total`, and pays
## every tier newly reached: {"tiers": [tier indices], "money": int,
## "items": {item id: count}}. Money grows with the boss's level like other
## loot; rare drops are rolled with `rng` (seeded by the caller).
static func award(
	profile: PlayerProfile,
	content: ContentDB,
	round: int,
	dealt: int,
	total: int,
	level: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var state := progress(profile, round)
	state["dealt"] = mini(total, int(state["dealt"]) + maxi(0, dealt))
	var paid := {"tiers": [], "money": 0, "items": {}}
	var tiers: Array = content.world_boss["tiers"]
	var scale := 1.0 + LevelRules.MONEY_PER_LEVEL * (level - 1)
	while int(state["tiers"]) < tiers.size():
		var tier: Dictionary = tiers[int(state["tiers"])]
		if int(state["dealt"]) < ceili(total * float(tier["share"])):
			break
		paid["tiers"].append(int(state["tiers"]))
		paid["money"] += roundi(float(tier["money"]) * scale)
		var found: Dictionary = tier.get("items", {}).duplicate()
		var rolls: Dictionary = tier.get("rolls", {})
		var names: Array = rolls.keys()
		names.sort()
		for item_id: String in names:
			if rng.randf() < float(rolls[item_id]):
				found[item_id] = int(found.get(item_id, 0)) + 1
		for item_id: String in found:
			paid["items"][item_id] = int(paid["items"].get(item_id, 0)) + int(found[item_id])
		state["tiers"] = int(state["tiers"]) + 1
	profile.money += int(paid["money"])
	for item_id: String in paid["items"]:
		profile.add_item(item_id, int(paid["items"][item_id]))
	return paid
