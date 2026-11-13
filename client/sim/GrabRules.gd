class_name GrabRules
extends RefCounted
## Grab and throw, the same for every job (jobs.json "grab" gives each its
## own reach, hold and throw). A fighter with a grab profile and EMPTY HANDS
## reaches out (the grab button, or the pick button with nothing to pick
## up); with a weapon in hand the grab button lets the weapon fall instead
## (`lets_go`), so the next press grabs. If the reach closes on a foe it
## holds them: the foe is HELD, cannot act or be hit, and is carried in front
## of the holder. Any attack button throws the foe the way the holder faces.
## A body is heavy: it is thrown only 3 to 4 bodies away (never more than
## MAX_THROW_BODIES from the thrower), flies for AIR_TICKS at an even
## pace, tumbling (down: it cannot be hit), knocks into others on the way
## and where it lands (the job's "crash") and slams into the street
## (`landed`, reported by ZoneSim as "slam"): only then does the throw's blow
## land, its damage and any KO with it.
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
## A thrown body knocks into fighters this close all the while it is in the
## air, and into a wider spot (LAND_HALF) where it comes down.
const CRASH_HALF := 22.0
const CRASH_DEPTH := 14.0
const PROFILE_MOVES: Array[String] = ["move", "release", "throw", "crash", "shove"]
const MIN_HOLD := 10
## A hold lifts the foe over LIFT_TICKS, then the holder takes one step
## forward (STEP_LENGTH px over STEP_TICKS) carrying them; only then can they
## be thrown (READY_TICKS into the hold). A throw pressed sooner waits for the
## step and goes as soon as it is taken.
const LIFT_TICKS := 8
const STEP_TICKS := 10
const STEP_LENGTH := 14.0
const READY_TICKS := LIFT_TICKS + STEP_TICKS
const MAX_HOLD := 120
## One space on the street: a person's width (Bodies.PERSON.x on each side).
const BODY := 18.0
## The farthest a thrown body lands from the thrower, in BODY spaces: a
## person is no sack of rice. MAX_THROW is the throw's knockback that puts it
## there (it starts HOLD_GAP in front).
const MAX_THROW_BODIES := 4.0
const MAX_THROW := BODY * MAX_THROW_BODIES - HOLD_GAP
## Ticks a thrown body is in the air before it hits the street.
const AIR_TICKS := 16
## Ticks a slammed body lies on the street before it gets up (1.5 s): the
## wind is knocked out of it, so a throw buys real room.
const SLAM_DOWN_TICKS := 90
## In PvP (a hero thrown by a hero) the body is down this long instead: a
## throw still opens the foe up, but cannot keep them on the street half the
## match (measured: 29-31 s of 55, docs/SKILL_FLOW_REPORT.md).
const SLAM_DOWN_PVP_TICKS := 60
## ...and once up again it cannot be grabbed for this long.
const PVP_REGRAB_AFTER := 90
## Where a thrown body lands, it knocks down anyone within a body and a half.
const LAND_HALF := BODY * 1.5


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
		f.landed = false
		if f.grab_guard > 0:
			f.grab_guard -= 1
		if f.state == Fighter.State.HELD:
			var holder := _find(fighters, f.held_by)
			if holder == null or holder.state != Fighter.State.GRAB or holder.holding != f.id:
				_free(f)
	for f in fighters:
		var input: FighterInput = inputs.get(f.id)
		if f.state == Fighter.State.GRAB:
			_hold(f, input, fighters, inputs, library, events)
		elif f.state == Fighter.State.ATTACK and f.move.grab:
			_reach(f, fighters, library, rng, events)
		elif f.state == Fighter.State.IDLE and input != null and wants(f, input):
			CombatRules.start_move(f, library.get_move(str(f.grab["move"])))
	for f in fighters:
		if f.thrown_by != 0:
			_fly(f, fighters, library, rng, events)
		if f.airborne > 0:
			f.airborne -= 1
			if f.airborne == 0:
				_slam(f, fighters, library, rng, events)
	return events


## True when this input asks `f` to grab: the grab button, or the pick
## button (ZoneSim has already used it on a weapon underfoot), and only with
## empty hands: a fighter holding a weapon cannot take hold of anyone.
static func wants(f: Fighter, input: FighterInput) -> bool:
	return not f.grab.is_empty() and f.weapon == "" and (input.grab or input.pick)


## True when the grab button asks `f` to let its weapon fall first: one
## press drops it (ZoneSim), the next grabs. Only a fighter free to act.
static func lets_go(f: Fighter, input: FighterInput) -> bool:
	return (
		f != null
		and input.grab
		and f.weapon != ""
		and not f.grab.is_empty()
		and f.state == Fighter.State.IDLE
	)


## True when `move` is a grab `f` cannot make: its hands are full. Grab
## skills wait too until the weapon is down (CombatRules.start_skill).
static func barred(f: Fighter, move: MoveData) -> bool:
	return move != null and move.grab and f.weapon != ""


## `input` with the grab press spent (it let a weapon fall), so the same tick
## does not grab as well. A copy: the caller's input is left as it was.
static func spent(input: FighterInput) -> FighterInput:
	var out := FighterInput.new()
	out.move = input.move
	out.light = input.light
	out.heavy = input.heavy
	out.dodge = input.dodge
	out.guard = input.guard
	out.skill = input.skill
	out.face = input.face
	return out


## Whether `defender` can be held (else a grab only shoves them): ordinary
## monsters and players can; bosses and mini-bosses never.
static func can_hold(defender: Fighter) -> bool:
	if defender.ungrabbable or defender.unshaken or defender.grab_guard > 0:
		return false
	# Planted in a heavy-armoured blow (a Brawler's committed heavy): no grip.
	var move := defender.move
	var planted := defender.state == Fighter.State.ATTACK and move != null and move.armor
	return not (planted and defender.state_tick < move.startup + move.active)


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
	# Always long enough to lift, step and throw.
	ticks = maxi(ticks, READY_TICKS + 1)
	ComboRules.on_hold(f)
	ComboRules.on_hurt(target)
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
	if f.state_tick == LIFT_TICKS:
		# The step forward, carried by the same slide a shove uses (it keeps
		# to the street and stops at what stands in the way).
		f.knockback_remaining = f.facing * STEP_LENGTH
	var ready := f.state_tick >= READY_TICKS
	var over := f.state_tick >= f.state_duration
	if not f.grab_plan.is_empty():
		_squeeze(f, held, library, events)
		if over and ready and held.state == Fighter.State.HELD:
			_throw(f, held, library)
		return
	if input != null and (input.light or input.heavy or input.grab or input.pick):
		f.queued = "throw"
	if ready and f.queued == "throw":
		f.queued = ""
		_throw(f, held, library)
	elif over:
		f.holding = 0
		_free(held)
		f.enter(Fighter.State.IDLE)


## Throws the held fighter: with the job's throw, or the skill's when a
## skill made the hold, whose later moves then follow.
static func _throw(f: Fighter, held: Fighter, library: MoveLibrary) -> void:
	var plan := f.grab_plan
	f.grab_plan = {}
	f.holding = 0
	_free(held)
	f.skill_id = str(plan.get("skill", ""))
	f.skill_step = int(plan.get("step", 0))
	f.crash_move = str(plan.get("crash", f.grab.get("crash", "")))
	var throw := library.get_move(str(plan.get("throw", f.grab.get("throw", ""))))
	# The body leaves the hands tumbling (down: it cannot be hit or act) and
	# flies; the throw's blow lands with it (_slam). Whatever scaled the
	# throw, it lands at most MAX_THROW_BODIES away.
	var push := throw.knockback * SkillSequence.scale(f, "knockback") if throw else 0.0
	# The blow lands after the skill is over: keep its balance scale for it.
	f.throw_scale = SkillSequence.scale(f, "damage")
	held.enter(Fighter.State.DOWN)
	held.knockback_remaining = clampf(f.facing * push, -MAX_THROW, MAX_THROW)
	held.slam_by = f.id
	held.slam_move = throw.id if throw else ""
	held.airborne = AIR_TICKS
	held.thrown_by = f.id
	held.thrown_hits = {}
	if not SkillSequence.advance(f, library):
		CombatRules.start_move(f, library.get_move(str(f.grab.get("release", ""))))


## A thrown body hits the street: the throw's blow lands now (its damage, a
## KO), the body stays where it fell, and it lies there SLAM_DOWN_TICKS
## (longer than a blow's knockdown) unless the blow finished it.
static func _slam(
	body: Fighter,
	fighters: Array[Fighter],
	library: MoveLibrary,
	rng: RandomNumberGenerator,
	events: Array[CombatEvent]
) -> void:
	body.landed = true
	var thrower := _find(fighters, body.slam_by)
	var move := library.get_move(body.slam_move)
	body.slam_by = 0
	body.slam_move = ""
	if thrower != null and move != null:
		events.append(CombatRules.strike(thrower, body, move, rng))
	body.knockback_remaining = 0.0
	if not body.is_ko():
		var down := slam_down(thrower, body)
		body.enter(Fighter.State.DOWN, down)
		if down == SLAM_DOWN_PVP_TICKS:
			# PvP: back on their feet, a thrown hero cannot be seized again
			# at once (no throw, get up, throw loop).
			body.grab_guard = maxi(body.grab_guard, down + PVP_REGRAB_AFTER)


## How long `body`, slammed by `thrower`, stays down: shorter in PvP.
static func slam_down(thrower: Fighter, body: Fighter) -> int:
	if thrower != null and thrower.stun_limit > 0 and body.stun_limit > 0:
		return SLAM_DOWN_PVP_TICKS
	return SLAM_DOWN_TICKS


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
	if thrower == null or body.airborne == 0:
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
		# Where it comes down (its last tick aloft) it flattens a wider spot.
		var half := LAND_HALF if body.airborne == 1 else CRASH_HALF
		var near := absf(other.position.x - body.position.x) <= half
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
	out.append_array(_throw_problems(library.get_move(str(plan.get("throw", ""))), where + ".grab"))
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
	out.append_array(_throw_problems(library.get_move(str(profile.get("throw", ""))), where))
	var release := library.get_move(str(profile.get("release", "")))
	if release != null and release.damage > 0:
		out.append(where + ".release: must deal no damage (the throw does)")
	var hold: Variant = profile.get("hold")
	if not (hold is float or hold is int) or hold < MIN_HOLD or hold > MAX_HOLD:
		out.append("%s.hold: expected %d to %d ticks" % [where, MIN_HOLD, MAX_HOLD])
	return out


## A throw must floor the body (it slams into the street) and land it no
## farther than MAX_THROW_BODIES from the thrower.
static func _throw_problems(throw: MoveData, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if throw == null:
		return out
	if not throw.knockdown:
		out.append("%s.throw: a thrown body hits the ground (knockdown)" % where)
	if throw.knockback > MAX_THROW:
		out.append(
			(
				"%s.throw: knockback %d lands past %d bodies (at most %d)"
				% [where, throw.knockback, MAX_THROW_BODIES, MAX_THROW]
			)
		)
	return out
