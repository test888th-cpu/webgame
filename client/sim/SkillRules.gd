class_name SkillRules
extends RefCounted
## Which skills a hero has, from data/skills.json and the hero's level. The
## combat rules only see the result (Fighter.skills), so a skill a player has
## not unlocked can never be used, whatever a client sends.


## skill id -> {"move", "cooldown"} for every skill unlocked at `level`.
static func unlocked(content: ContentDB, level: int) -> Dictionary:
	var result := {}
	for id: String in content.skills:
		var skill: Dictionary = content.skills[id]
		if level >= int(skill["unlock_level"]):
			result[id] = {"move": str(skill["move"]), "cooldown": int(skill["cooldown"])}
	return result


## Skills that unlock exactly when reaching `level`.
static func unlocked_at(content: ContentDB, level: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in content.skills:
		if int(content.skills[id]["unlock_level"]) == level:
			ids.append(id)
	return ids
