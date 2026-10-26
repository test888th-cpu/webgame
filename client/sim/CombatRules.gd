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
## Stun-lock protection for fighters with a stun_limit (the hero): at most
## this many ticks of hitstun in a row before the next hit knocks them down
## (so a crowd cannot keep them helpless), the meter drains this much per
## tick in control, and getting up leaves them untouchable for a moment.
## Worst case without input: HERO_STUN_LIMIT + KNOCKDOWN_TICKS = 1.5 s.
const HERO_STUN_LIMIT := 40
const STUN_DECAY := 1
const WAKE_GRACE_TICKS := 36
## Perfect guard: a guard raised at most PERFECT_GUARD_TICKS before a hit
## from the front parries it (no damage, no energy lost, guard breakers
## included) and refunds PARRY_ENERGY; the attacker reels for PARRY_STUN
## ticks, during which the first hit on them is a counter dealing
## COUNTER_DAMAGE times its damage. Letting go of guard closes the parry
## window for PARRY_LOCKOUT_TICKS so it rewards timing, not tapping.
const PERFECT_GUARD_TICKS := 8
const PARRY_LOCKOUT_TICKS := 24
const PARRY_STUN := 30
const PARRY_ENERGY := 15.0
const PARRY_PUSH := 14.0
const COUNTER_DAMAGE := 1.5
## A critical hit deals this much more.
const CRIT_DAMAGE := 1.5
## A thrown weapon that hits without knocking down stuns this long and
## pushes this far.
const THROWN_HITSTUN := 24
const THROWN_KNOCKBACK := 40.0
## Share of the remaining knockback applied each tick (ease-out slide).
const KNOCKBACK_RATE := 0.25
## Half the width of a fighter's body for hit tests.
const HURT_HALF_WIDTH := 8.0


## Advances all fighters one tick. `inputs` maps fighter id to FighterInput;
## fighters without an entry get no input. Returns the hits that happened.
## `rng` (the zone's seeded generator) decides critical hits; without one
## there are none, so the rules stay deterministic either way.
static func tick(
	fighters: Array[Fighter],
	inputs: Dictionary,
	library: MoveLibrary,
	bounds: Rect2,
	after_move := Callable(),
	rng: RandomNumberGenerator = null
) -> Array[CombatEvent]:
	var idle := FighterInput.new()
	for fighter in fighters:
		_step(fighter, inputs.get(fighter.id, idle), library, bounds)
	# The zone settles who bumped into what before any blow is judged.
	if after_move.is_valid():
		after_move.call()
	# Snapshot live hitboxes first, so two attacks landing on the same tick both
	# connect (a trade) instead of the first fighter in the array winning.
	var swings: Array = []
	for attacker in fighters:
		if (
			attacker.state == Fighter.State.ATTACK
			and attacker.move.damage > 0
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
				events.append(_apply_hit(attacker, defender, move, rng))
	return events


static func is_vulnerable(fighter: Fighter) -> bool:
	if fighter.grace > 0:
		return false
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
	if f.grace > 0:
		f.grace -= 1
	if f.parry_lockout > 0:
		f.parry_lockout -= 1
	if f.exposed > 0:
		f.exposed -= 1
	if f.state != Fighter.State.HITSTUN:
		f.stun_meter = maxi(0, f.stun_meter - STUN_DECAY)
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
				if f.stun_limit > 0:
					f.stun_meter = 0
					f.grace = WAKE_GRACE_TICKS
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
				if f.can_parry:
					f.parry_lockout = PARRY_LOCKOUT_TICKS
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
		f.parry_open = f.can_parry and f.parry_lockout == 0
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
	if f.state_tick >= move.total_ticks() - recovery_cut(f, move):
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


## Ticks attack speed takes off (or, below 1.0, adds to) a move's recovery.
## Startup and hit timing never change, so combos and cancels stay readable.
static func recovery_cut(f: Fighter, move: MoveData) -> int:
	return roundi(move.recovery * (1.0 - 1.0 / maxf(0.1, f.attack_speed)))


## Lunging moves carry the attacker forward until the hitbox closes.
static func _advance(f: Fighter, bounds: Rect2) -> void:
	var move := f.move
	var ticks := move.startup + move.active
	if move.advance > 0.0 and f.state_tick <= ticks:
		var step := Vector2(f.facing * move.advance / ticks, 0)
		f.position = LaneMovement.clamp_to(f.position + step, bounds)


## Starts `move` from outside the input step (a throw). See _start_move.
static func start_move(f: Fighter, move: MoveData) -> bool:
	return _start_move(f, move)


## A thrown object reaching `defender`, flying from `from_x`. Guard blocks it
## from the front (chip damage, energy drain, no parry); otherwise it stuns
## or knocks down. The caller has checked reach and vulnerability.
static func thrown_hit(
	defender: Fighter, thrower_id: int, from_x: float, damage: int, knockdown: bool, kind: String
) -> CombatEvent:
	var event := CombatEvent.new()
	event.attacker_id = thrower_id
	event.defender_id = defender.id
	event.move_id = kind
	event.position = defender.position
	var away := signf(defender.position.x - from_x)
	var from_front := -away != -defender.facing
	event.blocked = defender.state == Fighter.State.GUARD and from_front
	var full := maxi(1, damage - defender.defense)
	if event.blocked:
		event.damage = maxi(1, roundi(full * GUARD_DAMAGE_FACTOR))
		defender.energy = maxf(0.0, defender.energy - full * GUARD_ENERGY_PER_DAMAGE)
	else:
		event.damage = full
		defender.knockback_remaining = away * THROWN_KNOCKBACK
	defender.hp = maxi(0, defender.hp - event.damage)
	if defender.hp == 0:
		event.ko = true
		defender.enter(Fighter.State.KO)
	elif not event.blocked:
		event.knocked_down = knockdown
		if knockdown:
			defender.enter(Fighter.State.DOWN)
		else:
			event.knocked_down = _stun(defender, THROWN_HITSTUN)
	return event


static func _start_move(f: Fighter, move: MoveData) -> bool:
	if move == null or f.energy < move.energy_cost:
		return false
	f.energy -= move.energy_cost
	# Wake-up grace protects, it does not let you hit while untouchable.
	f.grace = 0
	f.enter(Fighter.State.ATTACK)
	f.move = move
	f.hit_landed = false
	f.hit_ids = {}
	f.queued = ""
	f.queued_skill = ""
	return true


static func _apply_hit(
	attacker: Fighter, defender: Fighter, move: MoveData, rng: RandomNumberGenerator = null
) -> CombatEvent:
	attacker.hit_ids[defender.id] = true
	attacker.hit_landed = true
	var event := CombatEvent.new()
	event.attacker_id = attacker.id
	event.defender_id = defender.id
	event.move_id = move.id
	event.position = defender.position
	var from_front := signf(attacker.position.x - defender.position.x) != -defender.facing
	if is_perfect_guard(defender, from_front):
		_parry(attacker, defender, event)
		return event
	event.blocked = (defender.state == Fighter.State.GUARD and not move.guard_break and from_front)
	var full := damage_for(move, attacker, defender)
	if defender.exposed > 0 and not event.blocked:
		full = roundi(full * COUNTER_DAMAGE)
		event.counter = true
		defender.exposed = 0
	# Rolled only for fighters who can crit, so enemy-only fights draw nothing.
	if rng and attacker.crit_chance > 0.0 and not event.blocked:
		if rng.randf() < attacker.crit_chance:
			full = roundi(full * CRIT_DAMAGE)
			event.critical = true
	if event.blocked:
		event.damage = maxi(1, roundi(full * GUARD_DAMAGE_FACTOR))
		defender.energy -= full * GUARD_ENERGY_PER_DAMAGE
		defender.knockback_remaining = attacker.facing * move.knockback * 0.5
		if defender.energy <= 0.0:
			defender.energy = 0.0
			event.guard_broken = true
			event.knocked_down = _stun(defender, GUARD_BREAK_STUN)
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
			event.knocked_down = _stun(defender, move.hitstun)
	return event


## Whether a hit arriving now (from the front or not) is perfectly guarded.
static func is_perfect_guard(defender: Fighter, from_front: bool) -> bool:
	return (
		defender.state == Fighter.State.GUARD
		and defender.parry_open
		and from_front
		and defender.state_tick <= PERFECT_GUARD_TICKS
	)


## The defender parries: unharmed and refunded; the attacker reels, open to
## a counter.
static func _parry(attacker: Fighter, defender: Fighter, event: CombatEvent) -> void:
	event.blocked = true
	event.parried = true
	defender.energy = minf(MAX_ENERGY, defender.energy + PARRY_ENERGY)
	var away := signf(attacker.position.x - defender.position.x)
	attacker.knockback_remaining = (away if away != 0.0 else -defender.facing) * PARRY_PUSH
	attacker.enter(Fighter.State.HITSTUN, PARRY_STUN)
	attacker.exposed = PARRY_STUN


## Puts the defender in hitstun, or knocks them down when stun-lock
## protection says they have been held long enough. Returns true if knocked
## down.
static func _stun(defender: Fighter, ticks: int) -> bool:
	if defender.stun_limit > 0 and defender.stun_meter + ticks > defender.stun_limit:
		defender.stun_meter = 0
		defender.enter(Fighter.State.DOWN)
		return true
	defender.stun_meter += ticks
	defender.enter(Fighter.State.HITSTUN, ticks)
	return false
