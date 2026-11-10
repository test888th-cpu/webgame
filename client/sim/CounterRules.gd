class_name CounterRules
extends RefCounted
## Counter stances: a skill whose first move is a stance ("counter": true in
## moves.json). While the stance is open (the move's active ticks) a blow
## from the front does not land: the attacker reels as from a parry, open to
## a counter hit, and the skill's next moves (its "then") come out at once.
## A stance nobody hits ends without them, so a counter never deals its
## damage unprovoked, and the fighter stands open through the recovery.
## What beats a stance: waiting it out, a blow from behind, a guard-breaking
## blow, a grab, a thrown weapon and anything that is not a fighter's blow
## (a boss's hazards).


## True while `f` stands in an open counter stance.
static func open(f: Fighter) -> bool:
	return (
		f.state == Fighter.State.ATTACK
		and f.move != null
		and f.move.counter
		and f.move.is_active_tick(f.state_tick)
	)


## Whether `defender`'s stance catches a blow of `move` (from the front or not).
static func catches(defender: Fighter, move: MoveData, from_front: bool) -> bool:
	return open(defender) and from_front and not move.guard_break


## The stance caught a blow: the reply starts on the fighter's next tick.
static func caught(defender: Fighter) -> void:
	defender.countered = true


## Called when a fighter's move would go on or end. Returns true when the
## rules here settled it: a stance that caught a blow starts its reply, one
## that ran out caught nothing and the skill is over.
static func step(f: Fighter, library: MoveLibrary, ended: bool) -> bool:
	if not f.move.counter:
		return false
	if f.countered:
		f.countered = false
		if SkillSequence.advance(f, library):
			return true
	if ended:
		f.enter(Fighter.State.IDLE)
		return true
	return false


## What is wrong with a skill that uses counter stances: only its first move
## may be one, a stance deals nothing itself, and it needs a reply.
static func problems(skill: Dictionary, library: MoveLibrary, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var ids := SkillSequence.moves(skill)
	for index in ids.size():
		var move := library.get_move(ids[index])
		if move == null or not move.counter:
			continue
		if index > 0:
			out.append(
				"%s.then: %s is a counter stance; only the first move may be" % [where, ids[index]]
			)
		if move.damage > 0:
			out.append(
				"%s: the stance %s must deal no damage (the reply does)" % [where, ids[index]]
			)
		if ids.size() < 2:
			out.append('%s: a counter stance needs a reply in "then"' % where)
	return out
