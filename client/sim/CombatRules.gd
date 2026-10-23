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
	if input.dodge and f.energy >= DODGE_COST:
		f.energy -= DODGE_COST
		f.dodge_dir = f.facing
		f.enter(Fighter.State.DODGE)
	elif input.heavy and _start_move(f, library.get_move(library.starters["heavy"])):
		pass
	elif input.light and _start_move(f, library.get_move(library.starters["light"])):
		pass
	elif input.guard:
		f.enter(Fighter.State.GUARD)
	else:
		f.position = LaneMovement.step(f.position, input.move, TICK_SECONDS, bounds)


static func _step_attack(f: Fighter, input: FighterInput, library: MoveLibrary) -> void:
	if input.heavy:
		f.queued = "heavy"
	elif input.light:
		f.queued = "light"
	var move := f.move
	# Chains open once the hitbox has closed, and only after a connected hit.
	if f.hit_landed and f.queued and f.state_tick >= move.startup + move.active:
		var next_id: String = move.chains.get(f.queued, "")
		if next_id and _start_move(f, library.get_move(next_id)):
			return
	if f.state_tick >= move.total_ticks():
		f.enter(Fighter.State.IDLE)


static func _start_move(f: Fighter, move: MoveData) -> bool:
	if move == null or f.energy < move.energy_cost:
		return false
	f.energy -= move.energy_cost
	f.enter(Fighter.State.ATTACK)
	f.move = move
	f.hit_landed = false
	f.hit_ids = {}
	f.queued = ""
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
	if event.blocked:
		event.damage = maxi(1, roundi(move.damage * GUARD_DAMAGE_FACTOR))
		defender.energy -= move.damage * GUARD_ENERGY_PER_DAMAGE
		defender.knockback_remaining = attacker.facing * move.knockback * 0.5
		if defender.energy <= 0.0:
			defender.energy = 0.0
			event.guard_broken = true
			defender.enter(Fighter.State.HITSTUN, GUARD_BREAK_STUN)
	else:
		event.damage = move.damage
		defender.knockback_remaining = attacker.facing * move.knockback
		defender.facing = -attacker.facing
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
