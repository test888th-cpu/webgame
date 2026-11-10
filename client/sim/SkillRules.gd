class_name SkillRules
extends RefCounted
## Which skills a hero has: the kit of the hero's job (jobs.json) once it is
## built, else the hero's own four (heroes.json), each from the hero's level
## and its unlock level (skills.json). The combat rules only see the result
## (Fighter.skills and Fighter.passives), so a skill a player has not
## unlocked, or that belongs to another hero, can never be used, whatever a
## client sends.


## Every skill id of `hero_id`, usable or passive, unlocked or not.
static func kit(content: ContentDB, hero_id: String) -> Array:
	var job: Dictionary = content.jobs.get(JobRules.job_of(content, hero_id), {})
	var built: Variant = job.get("skills", [])
	if built is Array and not built.is_empty():
		return built
	return content.hero(hero_id).get("skills", [])


static func is_passive(skill: Dictionary) -> bool:
	return str(skill.get("type", "")) == "passive"


## skill id -> {"move", "cooldown", "then", "scale"} for the skills `hero_id`
## can use at `level` (passives are not used; see `passives`).
static func unlocked(
	content: ContentDB, hero_id: String, level: int, mode := BalanceProfile.PVE
) -> Dictionary:
	var result := {}
	for id: String in kit(content, hero_id):
		var skill: Dictionary = content.skills[id]
		if is_passive(skill) or level < int(skill["unlock_level"]):
			continue
		var scale := {}
		for field: String in ["damage", "hitstun", "knockback"]:
			scale[field] = BalanceProfile.scale(skill, mode, field)
		result[id] = {
			"move": str(skill["move"]),
			"cooldown": BalanceProfile.cooldown(skill, mode),
			"then": SkillSequence.moves(skill).slice(1),
			"scale": scale,
		}
	return result


## passive id -> its spec (PassiveRules) for the passives unlocked at `level`.
static func passives(content: ContentDB, hero_id: String, level: int) -> Dictionary:
	var result := {}
	for id: String in kit(content, hero_id):
		var skill: Dictionary = content.skills[id]
		if is_passive(skill) and level >= int(skill["unlock_level"]):
			result[id] = skill.get("passive", {})
	return result


## `hero_id`'s skills that unlock exactly when reaching `level`.
static func unlocked_at(content: ContentDB, hero_id: String, level: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in kit(content, hero_id):
		if int(content.skills[id]["unlock_level"]) == level:
			ids.append(id)
	return ids
