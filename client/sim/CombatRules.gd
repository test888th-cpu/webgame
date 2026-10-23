class_name CombatRules
extends RefCounted
## Deterministic fixed-tick combat. `tick` advances every fighter by one
## simulation step from its input, then resolves hits. No nodes, no engine
## state, no randomness: the same inputs always give the same result, which is
## what lets the zone server be authoritative and the client predict.

const TICK_RATE := 60
const TICK_SECONDS := 1.0 / TICK_RATE

const MAX_ENERGY := 100.0
const ENERGY_REGEN := 0.25

const DODGE_TICKS := 20
## Invulnerable on ticks [DODGE_IFRAME_START, DODGE_IFRAME_END).
const DODGE_IFRAME_START := 2
const DODGE_IFRAME_END := 14
const DODGE_SPEED := 210.0
const DODGE_COST := 20.0

## Blocked hits deal this share of their damage (minimum 1).
const GUARD_DAMAGE_FACTOR := 0.2
## Energy lost per point of blocked damage, and per tick held.
const GUARD_ENERGY_PER_DAMAGE := 1.5
const GUARD_DRAIN := 0.2
const GUARD_BREAK_STUN := 40

const KNOCKDOWN_TICKS := 50
## A button pressed this many ticks or fewer before an attack ends is not
## lost: it starts as soon as the attack is over (an input buffer), so
## mashing during a missed swing still feels responsive.
const INPUT_BUFFER_TICKS := 12
## Share of the remaining knockback applied each tick (ease-out slide).
const KNOCKBACK_RATE := 0.25
## Half the width of a fighter's body for hit tests.
const HURT_HALF_WIDTH := 8.0


## Advances all fighters one tick. `inputs` maps fighter id to FighterInput;
## fighters without an entry get no input. Returns the hits that happened.
static func tick(
	fighters: Array[Fighter], inputs: Dictionary, library: MoveLibrary, bounds: Rect2
) -> Array[CombatEvent]:
	var idle := FighterInput.new()
	for fighter in fighters:
		_step(fighter, inputs.get(fighter.id, idle), library, bounds)
	# Snapshot live hitboxes first, so two attacks landing on the same tick both
	# connect (a trade) instead of the first fighter in the array winning.
	var swings: Array = []
	for attacker in fighters:
		if (
			attacker.state == Fighter.State.ATTACK
			and attacker.move.is_active_tick(attacker.state_tick)
		):
			swings.append([attacker, attacker.move])
	var events: Array[CombatEvent] = []
	for swing: Array in swings:
		var attacker: Fighter = swing[0]
		var move: MoveData = swing[1]
		for defender in fighters:
			if defender.team == attacker.team or attacker.hit_ids.has(defender.id):
				continue
			if is_vulnerable(defender) and in_reach(attacker, defender, move):
				events.append(_apply_hit(attacker, defender, move))
	return events


static func is_vulnerable(fighter: Fighter) -> bool:
	match fighter.state:
		Fighter.State.KO, Fighter.State.DOWN:
			return false
		Fighter.State.DODGE:
			return fighter.state_tick < DODGE_IFRAME_START or fighter.state_tick >= DODGE_IFRAME_END
	return true


static func in_reach(attacker: Fighter, defender: Fighter, move: MoveData) -> bool:
	var ahead := (defender.position.x - attacker.position.x) * attacker.facing
	var near := move.reach_offset - HURT_HALF_WIDTH
	var far := move.reach_offset + move.reach + HURT_HALF_WIDTH
	var depth := absf(defender.position.y - attacker.position.y)
	return ahead >= near and ahead <= far and depth <= move.depth_tolerance


static func _step(f: Fighter, input: FighterInput, library: MoveLibrary, bounds: Rect2) -> void:
	f.state_tick += 1
	for skill_id: String in f.cooldowns.keys():
		f.cooldowns[skill_id] -= 1
		if f.cooldowns[skill_id] <= 0:
			f.cooldowns.erase(skill_id)
	match f.state:
		Fighter.State.KO:
			pass
		Fighter.State.DOWN:
			if f.state_tick >= KNOCKDOWN_TICKS:
				f.enter(Fighter.State.IDLE)
		Fighter.State.HITSTUN:
			if f.state_tick >= f.state_duration:
				f.enter(Fighter.State.IDLE)
		Fighter.State.DODGE:
			f.position = LaneMovement.clamp_to(
				f.position + Vector2(f.dodge_dir * DODGE_SPEED * TICK_SECONDS, 0), bounds
			)
			if f.state_tick >= DODGE_TICKS:
				f.enter(Fighter.State.IDLE)
		Fighter.State.ATTACK:
			_advance(f, bounds)
			_step_attack(f, input, library)
		Fighter.State.GUARD:
			if not input.guard:
				f.enter(Fighter.State.IDLE)
			else:
				f.energy = maxf(0.0, f.energy - GUARD_DRAIN)
	if f.state == Fighter.State.IDLE:
		_step_idle(f, input, library, bounds)
	if f.state not in [Fighter.State.GUARD, Fighter.State.DODGE]:
		f.energy = minf(MAX_ENERGY, f.energy + ENERGY_REGEN)
	if f.knockback_remaining != 0.0:
		var push := f.knockback_remaining * KNOCKBACK_RATE
		if absf(f.knockback_remaining) < 0.5:
			push = f.knockback_remaining
		f.knockback_remaining -= push
		f.position = LaneMovement.clamp_to(f.position + Vector2(push, 0), bounds)


static func _step_idle(
	f: Fighter, input: FighterInput, library: MoveLibrary, bounds: Rect2
) -> void:
	f.facing = LaneMovement.facing(f.facing, input.move)
	if input.face != 0:
		f.facing = signi(input.face)
	if input.dodge and f.energy >= DODGE_COST:
		f.energy -= DODGE_COST
		f.dodge_dir = f.facing
		f.enter(Fighter.State.DODGE)
	elif input.skill and start_skill(f, input.skill, library):
		pass
	elif input.heavy and _start_move(f, library.get_move(starter(f, library, "heavy"))):
		pass
	elif input.light and _start_move(f, library.get_move(starter(f, library, "light"))):
		pass
	elif input.guard:
		f.enter(Fighter.State.GUARD)
	else:
		f.position = LaneMovement.step(
			f.position, input.move, TICK_SECONDS, bounds, f.speed * f.weapon_speed
		)


## The move a button starts from neutral for this fighter ("" if none).
static func starter(f: Fighter, library: MoveLibrary, input: String) -> String:
	if f.weapon_moveset.has(input):
		return f.weapon_moveset[input]
	if f.moveset.is_empty():
		return library.starters.get(input, "")
	return f.moveset.get(input, "")


## Damage a move deals before guard: scaled by the attacker's power, reduced
## by the defender's defense, never below 1.
static func damage_for(move: MoveData, attacker: Fighter, defender: Fighter) -> int:
	return maxi(1, roundi(move.damage * attacker.power) - defender.defense)


## Starts a skill if the fighter knows it, it is off cooldown and there is
## energy for its move. Starts the cooldown. Returns false otherwise.
static func start_skill(f: Fighter, skill_id: String, library: MoveLibrary) -> bool:
	var skill: Dictionary = f.skills.get(skill_id, {})
	if skill.is_empty() or f.cooldown_left(skill_id) > 0:
		return false
	if not _start_move(f, library.get_move(str(skill["move"]))):
		return false
	f.cooldowns[skill_id] = int(skill["cooldown"])
	return true


static func _step_attack(f: Fighter, input: FighterInput, library: MoveLibrary) -> void:
	if input.skill:
		f.queued_skill = input.skill
		f.queued_tick = f.state_tick
	elif input.heavy:
		f.queued = "heavy"
		f.queued_tick = f.state_tick
	elif input.light:
		f.queued = "light"
		f.queued_tick = f.state_tick
	var move := f.move
	# Chains open once the hitbox has closed, and only after a connected hit.
	# A queued skill cancels the rest of any attack that connected.
	var cancel_window := f.hit_landed and f.state_tick >= move.startup + move.active
	if cancel_window and f.queued_skill:
		var skill_id := f.queued_skill
		f.queued_skill = ""
		if start_skill(f, skill_id, library):
			return
	if cancel_window and f.queued:
		var next_id: String = move.chains.get(f.queued, "")
		if next_id and _start_move(f, library.get_move(next_id)):
			return
	if f.state_tick >= move.total_ticks():
		var buffered := f.state_tick - f.queued_tick <= INPUT_BUFFER_TICKS
		var skill_id := f.queued_skill
		var button := f.queued
		f.enter(Fighter.State.IDLE)
		if not buffered:
			return
		if skill_id and start_skill(f, skill_id, library):
			return
		if button:
			_start_move(f, library.get_move(starter(f, library, button)))


## Lunging moves carry the attacker forward until the hitbox closes.
static func _advance(f: Fighter, bounds: Rect2) -> void:
	var move := f.move
	var ticks := move.startup + move.active
	if move.advance > 0.0 and f.state_tick <= ticks:
		var step := Vector2(f.facing * move.advance / ticks, 0)
		f.position = LaneMovement.clamp_to(f.position + step, bounds)


static func _start_move(f: Fighter, move: MoveData) -> bool:
	if move == null or f.energy < move.energy_cost:
		return false
	f.energy -= move.energy_cost
	f.enter(Fighter.State.ATTACK)
	f.move = move
	f.hit_landed = false
	f.hit_ids = {}
	f.queued = ""
	f.queued_skill = ""
	return true


static func _apply_hit(attacker: Fighter, defender: Fighter, move: MoveData) -> CombatEvent:
	attacker.hit_ids[defender.id] = true
	attacker.hit_landed = true
	var event := CombatEvent.new()
	event.attacker_id = attacker.id
	event.defender_id = defender.id
	event.move_id = move.id
	event.position = defender.position
	var from_front := signf(attacker.position.x - defender.position.x) != -defender.facing
	event.blocked = (defender.state == Fighter.State.GUARD and not move.guard_break and from_front)
	var full := damage_for(move, attacker, defender)
	if event.blocked:
		event.damage = maxi(1, roundi(full * GUARD_DAMAGE_FACTOR))
		defender.energy -= full * GUARD_ENERGY_PER_DAMAGE
		defender.knockback_remaining = attacker.facing * move.knockback * 0.5
		if defender.energy <= 0.0:
			defender.energy = 0.0
			event.guard_broken = true
			defender.enter(Fighter.State.HITSTUN, GUARD_BREAK_STUN)
	else:
		event.damage = full
		# Away from the attacker, so sweeps that reach behind push outward.
		var away := signf(defender.position.x - attacker.position.x)
		if away == 0.0:
			away = attacker.facing
		defender.knockback_remaining = away * move.knockback
		defender.facing = -int(away)
	defender.hp = maxi(0, defender.hp - event.damage)
	if defender.hp == 0:
		event.ko = true
		defender.enter(Fighter.State.KO)
	elif not event.blocked:
		event.knocked_down = move.knockdown
		if move.knockdown:
			defender.enter(Fighter.State.DOWN)
		else:
			defender.enter(Fighter.State.HITSTUN, move.hitstun)
	return event
