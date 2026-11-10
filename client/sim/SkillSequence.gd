class_name SkillSequence
extends RefCounted
## Skills of more than one blow. A skill names its first move ("move") and may
## list the moves that follow it ("then"); each stage starts by itself when
## the one before ends, with its own hitbox and its own record of who it hit,
## so a stage can strike a defender once and never twice. Only the first move
## costs energy. The sequence stops when the fighter is interrupted (any
## state but ATTACK clears Fighter.skill_id), and inputs do not cancel it
## until its last stage. Also answers a running skill's balance scale.


## The moves of `skill` (a skills.json entry or a Fighter.skills one), in order.
static func moves(skill: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if skill.has("move"):
		ids.append(str(skill["move"]))
	var later: Variant = skill.get("then", [])
	if later is Array:
		for id: Variant in later:
			ids.append(str(id))
	return ids


## True while the fighter's skill has stages still to come.
static func pending(f: Fighter) -> bool:
	if f.skill_id == "":
		return false
	return f.skill_step + 1 < moves(f.skills.get(f.skill_id, {})).size()


## Starts the next stage of the running skill. False when there is none.
static func advance(f: Fighter, library: MoveLibrary) -> bool:
	if not pending(f):
		return false
	var skill_id := f.skill_id
	var step := f.skill_step + 1
	var move := library.get_move(moves(f.skills[skill_id])[step])
	if move == null:
		return false
	f.enter(Fighter.State.ATTACK)
	f.move = move
	f.hit_landed = false
	f.hit_ids = {}
	f.skill_id = skill_id
	f.skill_step = step
	return true


## The running skill's multiplier on `field` ("damage", "hitstun",
## "knockback") from its balance profile; 1.0 outside a skill.
static func scale(f: Fighter, field: String) -> float:
	if f.skill_id == "" or f.state != Fighter.State.ATTACK:
		return 1.0
	var scales: Variant = f.skills.get(f.skill_id, {}).get("scale", {})
	return float(scales.get(field, 1.0)) if scales is Dictionary else 1.0


## What is wrong with `skill`'s moves: an active or ultimate skill needs a
## known first move, and later stages must exist and cost no energy.
static func problems(skill: Dictionary, library: MoveLibrary, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if not library.moves.has(str(skill.get("move"))):
		out.append("%s.move: unknown move" % where)
	var later: Variant = skill.get("then", [])
	if not later is Array:
		out.append("%s.then: expected a list of moves" % where)
		return out
	for id: Variant in later:
		var move := library.get_move(str(id))
		if move == null:
			out.append("%s.then: unknown move %s" % [where, id])
		elif move.energy_cost > 0.0:
			out.append("%s.then: %s must cost no energy (the first move pays)" % [where, id])
	return out
