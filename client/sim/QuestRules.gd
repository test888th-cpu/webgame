class_name QuestRules
extends RefCounted
## Quest state transitions on a PlayerProfile. Objectives and rewards come
## from quests.json; this code never names a specific quest.


## "locked" (requirement not turned in), "available", "active", "complete" or
## "turned_in".
static func status(profile: PlayerProfile, quest_id: String, content: ContentDB) -> String:
	if profile.quests.has(quest_id):
		return profile.quests[quest_id]["state"]
	var requires := str(content.quests.get(quest_id, {}).get("requires", ""))
	if requires and status(profile, requires, content) != "turned_in":
		return "locked"
	return "available"


static func accept(profile: PlayerProfile, quest_id: String, content: ContentDB) -> bool:
	if status(profile, quest_id, content) != "available":
		return false
	profile.quests[quest_id] = {"state": "active", "progress": 0}
	return true


## Counts a defeat towards active quests; returns the ids that just completed.
static func on_defeat(
	profile: PlayerProfile, enemy_id: String, content: ContentDB
) -> Array[String]:
	var completed: Array[String] = []
	for quest_id: String in profile.quests:
		var entry: Dictionary = profile.quests[quest_id]
		if entry["state"] != "active":
			continue
		var objective: Dictionary = content.quests[quest_id]["objective"]
		if objective["enemy"] != "any" and objective["enemy"] != enemy_id:
			continue
		entry["progress"] += 1
		if entry["progress"] >= int(objective["count"]):
			entry["state"] = "complete"
			completed.append(quest_id)
	return completed


## Grants the rewards of a completed quest exactly once. Returns the rewards
## given, or {} if the quest was not complete.
static func turn_in(profile: PlayerProfile, quest_id: String, content: ContentDB) -> Dictionary:
	if status(profile, quest_id, content) != "complete":
		return {}
	profile.quests[quest_id]["state"] = "turned_in"
	var rewards: Dictionary = content.quests[quest_id].get("rewards", {})
	profile.money += int(rewards.get("money", 0))
	var levels := profile.add_xp(int(rewards.get("xp", 0)), content)
	var items: Dictionary = rewards.get("items", {})
	for item_id: String in items:
		profile.add_item(item_id, int(items[item_id]))
	return {
		"money": int(rewards.get("money", 0)),
		"xp": int(rewards.get("xp", 0)),
		"items": items,
		"levels": levels,
	}
