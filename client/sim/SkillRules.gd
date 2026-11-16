class_name SkillRules
extends RefCounted
## Which skills a hero has: the kit of the hero's job (jobs.json: six active
## skills, two passives and an ultimate), each from the hero's level and its
## unlock level (skills.json). The combat rules only see the result
## (Fighter.skills and Fighter.passives), so a skill a player has not
## unlocked, or that belongs to another hero, can never be used, whatever a
## client sends.


## Every skill id of `hero_id`, usable or passive, unlocked or not.
static func kit(content: ContentDB, hero_id: String) -> Array:
	var job: Dictionary = content.jobs.get(JobRules.job_of(content, hero_id), {})
	var built: Variant = job.get("skills", [])
	return built if built is Array else []


## The kit's skills of `type` ("active", "passive", "ultimate"), in order.
static func of_type(content: ContentDB, hero_id: String, type: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in kit(content, hero_id):
		if str(content.skills.get(id, {}).get("type", "")) == type:
			ids.append(id)
	return ids


## The active skills of `hero_id`, in the order they unlock.
static func actives(content: ContentDB, hero_id: String) -> Array[String]:
	return of_type(content, hero_id, "active")


## The hero's ultimate ("" if the job has none).
static func ultimate(content: ContentDB, hero_id: String) -> String:
	var found := of_type(content, hero_id, "ultimate")
	return found[0] if not found.is_empty() else ""


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
		for field: String in ["damage", "hitstun", "knockback", "advance"]:
			scale[field] = BalanceProfile.scale(skill, mode, field)
		result[id] = {
			"move": str(skill["move"]),
			"cooldown": BalanceProfile.cooldown(skill, mode),
			"then": SkillSequence.moves(skill).slice(1),
			"scale": scale,
			"grab": skill.get("grab", {}),
			"gauge": UltimateRules.FULL if is_ultimate(skill) else 0.0,
		}
	return result


## Energy `skill_id` costs to start (its first move's; none for a passive).
static func energy_cost(content: ContentDB, skill_id: String) -> float:
	var move := content.moves.get_move(str(content.skills.get(skill_id, {}).get("move", "")))
	return move.energy_cost if move else 0.0


## One line of numbers for a skill: what it costs and how often (`short`
## for a narrow card).
static func facts(content: ContentDB, skill_id: String, short := false) -> String:
	var skill: Dictionary = content.skills.get(skill_id, {})
	if is_passive(skill):
		return "Passive" if short else "Passive: always on"
	if is_ultimate(skill):
		return "Full gauge" if short else "Ultimate: needs a full gauge"
	var seconds := str(snappedf(int(skill.get("cooldown", 0)) * CombatRules.TICK_SECONDS, 0.1))
	var energy := roundi(energy_cost(content, skill_id))
	if short:
		return "Energy %d · %ss" % [energy, seconds]
	return "Energy %d  ·  Cooldown %ss" % [energy, seconds]


static func is_ultimate(skill: Dictionary) -> bool:
	return str(skill.get("type", "")) == "ultimate"


## What is wrong with a job skill beyond its moves: an ultimate warns before
## it strikes, and "buff", "bonus" and "grab" blocks are well formed.
static func problems(skill: Dictionary, library: MoveLibrary, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if is_passive(skill):
		return out
	var first := library.get_move(str(skill.get("move", "")))
	if is_ultimate(skill) and first != null and not first.telegraph:
		out.append(where + ": an ultimate's first move must be telegraphed")
	if skill.has("buff"):
		out.append_array(PassiveRules.rider_problems(skill["buff"], true, where + ".buff"))
	if skill.has("bonus"):
		out.append_array(PassiveRules.rider_problems(skill["bonus"], false, where + ".bonus"))
	out.append_array(GrabRules.plan_problems(skill, library, where))
	return out


## passive id -> its spec (PassiveRules) for the passives unlocked at `level`.
static func passives(content: ContentDB, hero_id: String, level: int) -> Dictionary:
	var result := {}
	for id: String in kit(content, hero_id):
		var skill: Dictionary = content.skills[id]
		if level < int(skill["unlock_level"]):
			continue
		if is_passive(skill):
			result[id] = skill.get("passive", {})
		if skill.has("buff"):
			var buff: Dictionary = skill["buff"].duplicate()
			buff["gain"] = PassiveRules.SKILL_EVENT + id
			buff["max"] = 1
			result["buff:" + id] = buff
		if skill.has("bonus"):
			var bonus: Dictionary = skill["bonus"].duplicate()
			bonus["always"] = true
			bonus["skill"] = id
			result["bonus:" + id] = bonus
	return result


## `hero_id`'s skills that unlock exactly when reaching `level`.
static func unlocked_at(content: ContentDB, hero_id: String, level: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in kit(content, hero_id):
		if int(content.skills[id]["unlock_level"]) == level:
			ids.append(id)
	return ids
