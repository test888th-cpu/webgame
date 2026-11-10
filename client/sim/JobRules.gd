class_name JobRules
extends RefCounted
## Jobs: the five ways to fight (jobs.json). A hero has exactly one job and a
## job exactly one hero. A job's kit is six active skills, two passives and
## one ultimate, unlocked at the levels jobs.json gives; a job whose kit is
## not built yet has an empty "skills" list and its hero keeps the skills
## heroes.json names. Player skills and enemy attacks never share a move, so
## tuning one side cannot change the other. Pure rules, checked on load.

## How many skills of each type a finished kit holds.
const KIT := {"active": 6, "passive": 2, "ultimate": 1}
const TEXT_FIELDS: Array[String] = ["name", "role", "description", "weakness", "combo"]


## The job of `hero_id` ("" if the hero or its job is unknown).
static func job_of(content: ContentDB, hero_id: String) -> String:
	var job := str(content.heroes.get(hero_id, {}).get("job", ""))
	return job if content.jobs.has(job) else ""


## The hero who has `job_id` ("" if none).
static func hero_of(content: ContentDB, job_id: String) -> String:
	for hero_id: String in content.hero_order:
		if str(content.heroes.get(hero_id, {}).get("job", "")) == job_id:
			return hero_id
	return ""


## The basic attacks of `hero_id`'s job: input -> the move it starts from
## neutral (the job's own punch combination, chained in moves.json).
static func moveset(content: ContentDB, hero_id: String) -> Dictionary:
	var job: Dictionary = content.jobs.get(job_of(content, hero_id), {})
	var found: Variant = job.get("moveset", {})
	return found.duplicate() if found is Dictionary else {}


## Every move reached from `starts` through chains, as a set.
static func reachable(content: ContentDB, starts: Array) -> Dictionary:
	var found := {}
	var open: Array = starts.duplicate()
	while not open.is_empty():
		var id := str(open.pop_back())
		if found.has(id):
			continue
		found[id] = true
		var move := content.moves.get_move(id)
		if move:
			for next: Variant in move.chains.values():
				open.append(str(next))
	return found


## The level the `index`-th skill of `type` unlocks at (0 if there is none).
static func unlock_level(content: ContentDB, type: String, index: int) -> int:
	var levels: Variant = content.job_unlocks.get(type, [])
	if not levels is Array or index < 0 or index >= levels.size():
		return 0
	return int(levels[index])


## Every move an enemy can use: its moveset, its phases' movesets and whatever
## those chain into.
static func enemy_moves(content: ContentDB) -> Dictionary:
	var open: Array = []
	for enemy: Variant in content.enemies.values():
		if not enemy is Dictionary:
			continue
		var sets: Array = [enemy.get("moveset", {})]
		for phase: Variant in enemy.get("phases", []):
			if phase is Dictionary:
				sets.append(phase.get("moveset", {}))
		for moveset: Variant in sets:
			if moveset is Dictionary:
				for move_id: Variant in moveset.values():
					open.append(str(move_id))
	return reachable(content, open)


static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var listed := content.job_order.duplicate()
	var known := content.jobs.keys()
	listed.sort()
	known.sort()
	if listed != known:
		out.append("jobs.order: must list every job once")
	out.append_array(_unlock_problems(content))
	for id: String in content.jobs:
		out.append_array(_job_problems(content, id))
	for hero_id: String in content.heroes:
		var hero: Variant = content.heroes[hero_id]
		if hero is Dictionary and not content.jobs.has(str(hero.get("job", ""))):
			out.append("heroes.%s.job: unknown job" % hero_id)
	var hostile := enemy_moves(content)
	for skill_id: String in content.skills:
		var skill: Variant = content.skills[skill_id]
		if not skill is Dictionary:
			continue
		var where := "skills.%s" % skill_id
		if hostile.has(str(skill.get("move", ""))):
			out.append("%s.move: %s is an enemy's move" % [where, skill["move"]])
		if not skill.has("job"):
			continue
		var job: Variant = content.jobs.get(str(skill["job"]))
		if not job is Dictionary:
			out.append("%s.job: unknown job" % where)
		elif skill_id not in job.get("skills", []):
			out.append("%s: not in the kit of job %s" % [where, skill["job"]])
		if str(skill.get("type", "")) not in KIT:
			out.append("%s.type: expected active, passive or ultimate" % where)
		out.append_array(BalanceProfile.problems(skill, where))
	return out


static func _unlock_problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var cap := int(content.progression.get("max_level", 1))
	for type: String in KIT:
		var levels: Variant = content.job_unlocks.get(type)
		if not levels is Array or levels.size() != int(KIT[type]):
			out.append("jobs.unlocks.%s: expected %d levels" % [type, KIT[type]])
			continue
		var last := 0
		for level: Variant in levels:
			if not (level is int or level is float) or level != floorf(level):
				out.append("jobs.unlocks.%s: expected whole levels" % type)
			elif level <= last or level > cap:
				out.append("jobs.unlocks.%s: levels must rise and stay within the cap" % type)
			else:
				last = int(level)
	return out


static func _job_problems(content: ContentDB, id: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var where := "jobs.%s" % id
	var job: Variant = content.jobs[id]
	if not job is Dictionary:
		out.append(where + ": expected an object")
		return out
	var basics: Variant = job.get("moveset")
	if not basics is Dictionary:
		out.append(where + ".moveset: expected an object")
	else:
		for input: String in MoveLibrary.CHAIN_INPUTS:
			if not content.moves.moves.has(str(basics.get(input, ""))):
				out.append("%s.moveset.%s: unknown move" % [where, input])
		var hostile := enemy_moves(content)
		for move_id: String in reachable(content, basics.values()):
			if hostile.has(move_id):
				out.append("%s.moveset: %s is an enemy's move" % [where, move_id])
	for field: String in TEXT_FIELDS:
		if str(job.get(field, "")) == "":
			out.append("%s.%s: required" % [where, field])
	var strengths: Variant = job.get("strengths")
	if not strengths is Array or strengths.is_empty():
		out.append(where + ".strengths: expected a list")
	var heroes := 0
	for hero: Variant in content.heroes.values():
		if hero is Dictionary and str(hero.get("job", "")) == id:
			heroes += 1
	if heroes != 1:
		out.append("%s: expected exactly one hero, found %d" % [where, heroes])
	var kit: Variant = job.get("skills")
	if not kit is Array:
		out.append(where + ".skills: expected a list (empty until the kit is built)")
		return out
	if kit.is_empty():
		return out
	var levels := {}
	for type: String in KIT:
		levels[type] = []
	for skill_id: Variant in kit:
		var skill: Variant = content.skills.get(str(skill_id))
		if not skill is Dictionary or str(skill.get("job", "")) != id:
			out.append("%s.skills: %s is not a skill of this job" % [where, skill_id])
		elif levels.has(str(skill.get("type", ""))):
			levels[str(skill["type"])].append(int(skill.get("unlock_level", 0)))
	for type: String in KIT:
		var have: Array = levels[type]
		have.sort()
		var want: Array = []
		for index in int(KIT[type]):
			want.append(unlock_level(content, type, index))
		if have.size() != want.size():
			out.append(
				"%s.skills: expected %d %s, found %d" % [where, KIT[type], type, have.size()]
			)
		elif have != want:
			out.append("%s.skills: %s must unlock at levels %s" % [where, type, want])
	return out
