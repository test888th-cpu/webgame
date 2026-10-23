class_name SkillRules
extends RefCounted
## Which skills a hero has, from data/heroes.json (each hero's four skills),
## data/skills.json (unlock levels) and the hero's level. The combat rules
## only see the result (Fighter.skills), so a skill a player has not
## unlocked, or that belongs to another hero, can never be used, whatever a
## client sends.


## skill id -> {"move", "cooldown"} for `hero_id`'s skills unlocked at `level`.
static func unlocked(content: ContentDB, hero_id: String, level: int) -> Dictionary:
	var result := {}
	for id: String in content.hero(hero_id).get("skills", []):
		var skill: Dictionary = content.skills[id]
		if level >= int(skill["unlock_level"]):
			result[id] = {"move": str(skill["move"]), "cooldown": int(skill["cooldown"])}
	return result


## `hero_id`'s skills that unlock exactly when reaching `level`.
static func unlocked_at(content: ContentDB, hero_id: String, level: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in content.hero(hero_id).get("skills", []):
		if int(content.skills[id]["unlock_level"]) == level:
			ids.append(id)
	return ids
