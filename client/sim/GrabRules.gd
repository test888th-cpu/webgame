class_name GrabRules
extends RefCounted
## Grab and throw, the same for every job (jobs.json "grab" gives each its
## own reach, hold and throw). A fighter with a grab profile reaches out
## (the grab button, or the pick button with empty hands and nothing to pick
## up); if the reach closes on a foe it holds them: the foe is HELD, cannot
## act or be hit, and is carried in front of the holder. Any attack button
## throws the foe the way the holder faces; a held foe flies as far as the
## throw's knockback and knocks into others on the way (the job's "crash").
## Fair by rule: a hold ends by itself, a hit on the holder frees the foe, a
## held fighter with stun protection (a player) shakes free faster by
## pressing buttons, nobody can be grabbed again for REGRAB_TICKS, and what
## cannot be held (a boss or mini-boss; anyone inside that window) is only
## shoved. Only ordinary monsters and players are ever held or thrown.
##
## A skill may open with a grab too (skills.json "grab": its own "throw",
## "crash", "shove" and "hold", and optionally a "squeeze" move dealt every
## "every" ticks of the hold). Such a hold is not the player's to end: it
## runs its ticks, throws with the skill's throw, and the skill's later moves
## follow. A skill's grab that closes on nobody ends the skill.

## Ticks each button press of a held player takes off the hold.
const ESCAPE_TICKS := 6
## Ticks after a hold or throw in which the same fighter cannot be grabbed.
const REGRAB_TICKS := 90
## How far in front of the holder the held fighter is carried.
const HOLD_GAP := 14.0
## A thrown body knocks into fighters this close, while it still travels at
## least THROWN_MIN px.
const CRASH_HALF := 22.0
const CRASH_DEPTH := 14.0
const THROWN_MIN := 6.0
const PROFILE_MOVES: Array[String] = ["move", "release", "throw", "crash", "shove"]
const MIN_HOLD := 10
const MAX_HOLD := 120


## One tick of grabbing for everyone. Returns the blows it landed (throws,
## crashes and shoves), judged like any other hit.
static func tick(
	fighters: Array[Fighter],
	inputs: Dictionary,
	library: MoveLibrary,
	rng: RandomNumberGenerator = null
) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []
	for f in fighters:
		if f.grab_guard > 0:
			f.grab_guard -= 1
		if f.state == Fighter.State.HELD:
			var holder := _find(fighters, f.held_by)
			if holder == null or holder.state != Fighter.State.GRAB or holder.holding != f.id:
				_free(f)
	for f in fighters:
		var input: FighterInput = inputs.get(f.id)
		if f.state == Fighter.State.GRAB:
			_hold(f, input, fighters, inputs, library, rng, events)
		elif f.state == Fighter.State.ATTACK and f.move.grab:
			_reach(f, fighters, library, rng, events)
		elif f.state == Fighter.State.IDLE and input != null and wants(f, input):
			CombatRules.start_move(f, library.get_move(str(f.grab["move"])))
	for f in fighters:
		if f.thrown_by != 0:
			_fly(f, fighters, library, rng, events)
	return events


## True when this input asks `f` to grab: the grab button, or the pick
## button with empty hands (ZoneSim has already used it on a weapon underfoot).
static func wants(f: Fighter, input: FighterInput) -> bool:
	return not f.grab.is_empty() and (input.grab or (input.pick and f.weapon == ""))


## Whether `defender` can be held (else a grab only shoves them): ordinary
## monsters and players can; bosses and mini-bosses never.
static func can_hold(defender: Fighter) -> bool:
	return not (defender.ungrabbable or defender.unshaken) and defender.grab_guard == 0


## Ticks `holder` holds `defender`: its job's hold, halved on a foe with
## poise (the tougher ordinary monsters).
static func hold_ticks(holder: Fighter, defender: Fighter) -> int:
	var ticks := int(holder.grab.get("hold", MIN_HOLD))
	ticks = roundi(ticks * (1.0 + PassiveRules.bonus(holder, "hold")))
	return ticks / 2 if defender.poise_limit > 0 else ticks


static func _reach(
	f: Fighter,
	fighters: Array[Fighter],
	library: MoveLibrary,
	rng: RandomNumberGenerator,
	events: Array[CombatEvent]
) -> void:
	if f.hit_landed or not f.move.is_active_tick(f.state_tick):
		return
	var target: Fighter = null
	for other in fighters:
		if other.team == f.team or other.held_by != 0 or not CombatRules.is_vulnerable(other):
			continue
		if not CombatRules.in_reach(f, other, f.move):
			continue
		if (
			target == null
			or absf(other.position.x - f.position.x) < absf(target.position.x - f.position.x)
		):
			target = other
	if target == null:
		return
	f.hit_landed = true
	var plan: Dictionary = f.skills.get(f.skill_id, {}).get("grab", {})
	if not can_hold(target):
		var shove := library.get_move(str(plan.get("shove", f.grab.get("shove", ""))))
		events.append(CombatRules.strike(f, target, shove, rng))
		return
	var ticks := hold_ticks(f, target)
	if not plan.is_empty():
		plan = plan.duplicate()
		plan["skill"] = f.skill_id
		plan["step"] = f.skill_step
		ticks = int(plan.get("hold", ticks))
	f.enter(Fighter.State.GRAB, ticks)
	f.grab_plan = plan
	f.holding = target.id
	target.enter(Fighter.State.HELD)
	target.held_by = f.id
	target.knockback_remaining = 0.0
	_carry(f, target)


static func _hold(
	f: Fighter,
	input: FighterInput,
	fighters: Array[Fighter],
	inputs: Dictionary,
	library: MoveLibrary,
	rng: RandomNumberGenerator,
	events: Array[CombatEvent]
) -> void:
	var held := _find(fighters, f.holding)
	if held == null or held.state != Fighter.State.HELD:
		f.holding = 0
		f.enter(Fighter.State.IDLE)
		return
	var struggle: FighterInput = inputs.get(held.id)
	if held.stun_limit > 0 and struggle != null:
		if struggle.light or struggle.heavy or struggle.dodge:
			f.state_duration -= ESCAPE_TICKS
	if input != null:
		f.facing = LaneMovement.facing(f.facing, input.move)
	_carry(f, held)
	var over := f.state_tick >= f.state_duration
	if not f.grab_plan.is_empty():
		_squeeze(f, held, library, events)
		if over and held.state == Fighter.State.HELD:
			_throw(f, held, library, rng, events)
		return
	var throws := input != null and (input.light or input.heavy or input.grab or input.pick)
	if throws:
		_throw(f, held, library, rng, events)
	elif over:
		f.holding = 0
		_free(held)
		f.enter(Fighter.State.IDLE)


## Throws the held fighter: with the job's throw, or the skill's when a
## skill made the hold, whose later moves then follow.
static func _throw(
	f: Fighter,
	held: Fighter,
	library: MoveLibrary,
	rng: RandomNumberGenerator,
	events: Array[CombatEvent]
) -> void:
	var plan := f.grab_plan
	f.grab_plan = {}
	f.holding = 0
	_free(held)
	f.skill_id = str(plan.get("skill", ""))
	f.skill_step = int(plan.get("step", 0))
	f.crash_move = str(plan.get("crash", f.grab.get("crash", "")))
	var throw := library.get_move(str(plan.get("throw", f.grab.get("throw", ""))))
	events.append(CombatRules.strike(f, held, throw, rng))
	held.thrown_by = f.id
	held.thrown_hits = {}
	if not SkillSequence.advance(f, library):
		CombatRules.start_move(f, library.get_move(str(f.grab.get("release", ""))))


## A skill's hold that hurts: its "squeeze" move's damage every "every"
## ticks. The held fighter stays held; one that falls is let go.
static func _squeeze(
	f: Fighter, held: Fighter, library: MoveLibrary, events: Array[CombatEvent]
) -> void:
	var move := library.get_move(str(f.grab_plan.get("squeeze", "")))
	var every := int(f.grab_plan.get("every", 0))
	if move == null or every < 1 or f.state_tick == 0 or f.state_tick % every != 0:
		return
	var event := CombatEvent.new()
	event.attacker_id = f.id
	event.defender_id = held.id
	event.move_id = move.id
	event.position = held.position
	event.damage = CombatRules.damage_for(move, f, held)
	held.hp = maxi(0, held.hp - event.damage)
	if held.hp == 0:
		event.ko = true
		held.held_by = 0
		held.enter(Fighter.State.KO)
	events.append(event)


## A thrown body in flight knocks into the thrower's other foes, once each.
static func _fly(
	body: Fighter,
	fighters: Array[Fighter],
	library: MoveLibrary,
	rng: RandomNumberGenerator,
	events: Array[CombatEvent]
) -> void:
	var thrower := _find(fighters, body.thrown_by)
	if thrower == null or absf(body.knockback_remaining) < THROWN_MIN:
		body.thrown_by = 0
		body.thrown_hits = {}
		return
	var crash := library.get_move(thrower.crash_move)
	if crash == null:
		body.thrown_by = 0
		return
	for other in fighters:
		if other == body or other.team == thrower.team or body.thrown_hits.has(other.id):
			continue
		if other.held_by != 0 or not CombatRules.is_vulnerable(other):
			continue
		var near := absf(other.position.x - body.position.x) <= CRASH_HALF
		if near and absf(other.position.y - body.position.y) <= CRASH_DEPTH:
			body.thrown_hits[other.id] = true
			events.append(CombatRules.strike(thrower, other, crash, rng))


static func _carry(holder: Fighter, held: Fighter) -> void:
	held.position = holder.position + Vector2(holder.facing * HOLD_GAP, 0)
	held.facing = -holder.facing


static func _free(held: Fighter) -> void:
	held.held_by = 0
	held.grab_guard = REGRAB_TICKS
	if held.state == Fighter.State.HELD:
		held.enter(Fighter.State.IDLE)


static func _find(fighters: Array[Fighter], id: int) -> Fighter:
	for f in fighters:
		if f.id == id and id != 0:
			return f
	return null


## What is wrong with a skill's grab plan (skills.json "grab"): the skill
## must open with a grab, and the plan's moves must exist.
static func plan_problems(
	skill: Dictionary, library: MoveLibrary, where: String
) -> PackedStringArray:
	var out: PackedStringArray = []
	var plan: Variant = skill.get("grab")
	var first := library.get_move(str(skill.get("move", "")))
	if plan == null:
		return out
	if not plan is Dictionary:
		out.append(where + ".grab: expected an object")
		return out
	if first == null or not first.grab:
		out.append(where + ".grab: the skill's first move must be a grab")
	for field: String in ["throw", "crash", "shove", "squeeze"]:
		if plan.has(field) and not library.moves.has(str(plan[field])):
			out.append("%s.grab.%s: unknown move" % [where, field])
	for field: String in ["throw", "shove"]:
		if not plan.has(field):
			out.append("%s.grab.%s: required" % [where, field])
	var hold: Variant = plan.get("hold")
	if not (hold is float or hold is int) or hold < 1 or hold > MAX_HOLD:
		out.append("%s.grab.hold: expected 1 to %d ticks" % [where, MAX_HOLD])
	if plan.has("squeeze") and int(plan.get("every", 0)) < 1:
		out.append(where + ".grab.every: expected ticks between squeezes")
	return out


## What is wrong with a job's grab profile (jobs.json "grab").
static func problems(profile: Variant, library: MoveLibrary, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if not profile is Dictionary:
		out.append(where + ": expected an object")
		return out
	for field: String in PROFILE_MOVES:
		if not library.moves.has(str(profile.get(field, ""))):
			out.append("%s.%s: unknown move" % [where, field])
	var reach := library.get_move(str(profile.get("move", "")))
	if reach != null and not reach.grab:
		out.append(where + '.move: must be a grab ("grab": true)')
	var release := library.get_move(str(profile.get("release", "")))
	if release != null and release.damage > 0:
		out.append(where + ".release: must deal no damage (the throw does)")
	var hold: Variant = profile.get("hold")
	if not (hold is float or hold is int) or hold < MIN_HOLD or hold > MAX_HOLD:
		out.append("%s.hold: expected %d to %d ticks" % [where, MIN_HOLD, MAX_HOLD])
	return out
