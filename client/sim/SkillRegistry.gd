class_name SkillRegistry
extends RefCounted
## The uniqueness registry of the five classes' moves (jobs.json, skills.json,
## moves.json). Every class fights with moves of its own: its basic chains
## (light and heavy, followed through "chains"), and every move of its skills
## (a skill's "move" and "then", and the throw, crash, shove and squeeze of a
## grab skill). Checked on load (ContentDB):
## - a class move used by another class (the grab every class has, its throw,
##   release and shove, are the shared engine and allowed);
## - two different moves of different classes that play the same (the same
##   timing, damage, hitstun, knockback, hitbox, movement, effects and
##   animation): a renamed copy;
## - two skills, of any classes, made of the same sequence of moves;
## - a skill listed by two classes;
## - an ultimate without an animation of its own, or two ultimates sharing one.
## Shared engine code is not a duplicate: only what a move does is compared.

## What a move's gameplay is made of, for comparing two moves.
const SIGNATURE := [
	"startup",
	"active",
	"recovery",
	"damage",
	"hitstun",
	"knockback",
	"reach_offset",
	"reach",
	"depth_tolerance",
	"advance",
	"guard_break",
	"knockdown",
	"grab",
	"counter",
	"evade",
	"slam",
	"armor",
	"anim",
]
const GRAB_FIELDS := ["throw", "crash", "shove", "squeeze", "release", "move"]
## Clips every fighter plays: an ultimate's own animation is none of these.
const GENERIC_ANIMS := ["", "light", "heavy", "swing", "stab", "grab", "throw", "lift", "stance"]


## {job id: {move id: true}}: the moves each class fights with.
static func class_moves(content: ContentDB) -> Dictionary:
	var out := {}
	for job_id: String in content.jobs:
		var job: Dictionary = content.jobs[job_id]
		var own := {}
		for button: String in job.get("moveset", {}):
			_follow(content, str(job["moveset"][button]), own)
		for skill_id: String in job.get("skills", []):
			for move_id in skill_moves(content, skill_id):
				own[move_id] = true
		out[job_id] = own
	return out


## Every move of `skill_id`: its moves in order, then its grab's.
static func skill_moves(content: ContentDB, skill_id: String) -> Array[String]:
	var skill: Dictionary = content.skills.get(skill_id, {})
	var out: Array[String] = []
	for move_id in SkillSequence.moves(skill):
		out.append(move_id)
	var grab: Dictionary = skill.get("grab", {})
	for field: String in GRAB_FIELDS:
		if grab.has(field):
			out.append(str(grab[field]))
	return out


## The moves every class shares: the job grab's (the engine's grab).
static func shared_moves(content: ContentDB) -> Dictionary:
	var out := {}
	for job_id: String in content.jobs:
		var grab: Dictionary = content.jobs[job_id].get("grab", {})
		for field: String in GRAB_FIELDS:
			if grab.has(field):
				out[str(grab[field])] = true
	return out


static func signature(content: ContentDB, move_id: String) -> String:
	var move := content.moves.get_move(move_id)
	if move == null:
		return "missing:" + move_id
	var parts: Array = []
	for field: String in SIGNATURE:
		parts.append(str(move.get(field)))
	return "|".join(parts)


static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var owned := class_moves(content)
	var shared := shared_moves(content)
	var owner := {}
	var by_signature := {}
	for job_id: String in owned:
		for move_id: String in owned[job_id]:
			if shared.has(move_id) or not content.moves.moves.has(move_id):
				continue
			if owner.has(move_id) and owner[move_id] != job_id:
				out.append("moves: %s is used by %s and %s" % [move_id, owner[move_id], job_id])
			owner[move_id] = job_id
			var sig := signature(content, move_id)
			var twin: Array = by_signature.get(sig, [])
			for other: Array in twin:
				if other[1] != job_id:
					out.append(
						(
							"moves: %s (%s) plays the same as %s (%s)"
							% [move_id, job_id, other[0], other[1]]
						)
					)
			twin.append([move_id, job_id])
			by_signature[sig] = twin
	out.append_array(_skill_problems(content))
	return out


static func _skill_problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var listed := {}
	var sequences := {}
	var ultimate_anims := {}
	for job_id: String in content.jobs:
		for skill_id: String in content.jobs[job_id].get("skills", []):
			if listed.has(skill_id):
				out.append(
					"skills: %s is listed by %s and %s" % [skill_id, listed[skill_id], job_id]
				)
			listed[skill_id] = job_id
			var moves := skill_moves(content, skill_id)
			if moves.is_empty():
				continue
			var key := ",".join(moves.map(func(m: String) -> String: return signature(content, m)))
			if sequences.has(key):
				out.append("skills: %s plays the same as %s" % [skill_id, sequences[key]])
			sequences[key] = skill_id
			if str(content.skills[skill_id].get("type")) == "ultimate":
				out.append_array(_ultimate_problems(content, skill_id, moves, ultimate_anims))
	return out


## An ultimate needs an animation of its own (not a plain punch, grab or
## stance clip), and no other ultimate may play it.
static func _ultimate_problems(
	content: ContentDB, skill_id: String, moves: Array[String], seen: Dictionary
) -> PackedStringArray:
	var out: PackedStringArray = []
	var own := {}
	for move_id in moves:
		var anim := _anim(content, move_id)
		if not anim in GENERIC_ANIMS:
			own[anim] = true
	if own.is_empty():
		out.append("skills: ultimate %s has no animation of its own" % skill_id)
	for anim: String in own:
		if seen.has(anim) and seen[anim] != skill_id:
			out.append(
				(
					"skills: ultimates %s and %s share their animation %s"
					% [skill_id, seen[anim], anim]
				)
			)
		seen[anim] = skill_id
	return out


static func _anim(content: ContentDB, move_id: String) -> String:
	var move := content.moves.get_move(move_id)
	return move.anim if move != null else ""


static func _follow(content: ContentDB, move_id: String, own: Dictionary) -> void:
	if own.has(move_id) or not content.moves.moves.has(move_id):
		return
	own[move_id] = true
	var chains: Dictionary = content.moves.get_move(move_id).chains
	for button: String in chains:
		_follow(content, str(chains[button]), own)
