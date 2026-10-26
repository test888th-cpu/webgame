class_name EnemyBrain
extends RefCounted
## Decides one enemy's input each tick. Waits at its preferred spacing until
## the zone grants it an attack token, then closes in, lines up in the lane,
## pauses for its reaction time and swings. Higher-level enemies also read
## the hero's wind-ups: they may guard or hop back out of reach, and they go
## and pick up weapons lying nearby (LevelRules sets these chances).
## Parameters come from the enemy's "ai" block in enemies.json. Randomness
## comes only from the zone's seeded generator, so a zone replays identically
## from the same seed and inputs.

## How far from the target's lane depth this enemy waits, so a crowd spreads
## out instead of stacking on one line.
const LANE_SPREAD := 24.0
## Slack in px around the move's reach when deciding to swing.
const RANGE_MARGIN := 4.0
## How far an enemy will walk to fetch a weapon, and how close is "on it".
const SCAVENGE_RANGE := 110.0
const PICK_REACH := 10.0
## How close in lane depth a ranged fighter must be to lob.
const LOB_LANE := 8.0
const DEFAULT_HEAVY_COOLDOWN := 270

var spacing := 56.0
var reaction_ticks := 12
var cooldown_ticks := 50
var cooldown_jitter := 30
var heavy_chance := 0.0
## Ticks an enemy must wait after a heavy (its signature blow, the lob for a
## thrower) before the next one, so it cannot chain them back to back. Longer
## than any hero skill short of an ultimate (ai.heavy_cooldown).
var heavy_cooldown_ticks := DEFAULT_HEAVY_COOLDOWN
## Ticks left before this enemy may use its heavy again.
var heavy_wait := 0
## Chance to guard, or to dodge away, when the target winds up an attack
## nearby; whether to fetch weapons.
var guard_chance := 0.0
var dodge_chance := 0.0
var scavenge := false
## Ranged fighters (ai.ranged {min, max}) hang back in this band of distance
## and lob from it; up close they still jab. 0: melee only.
var ranged_min := 0.0
var ranged_max := 0.0

## Ticks until this enemy may attack again.
var cooldown := 0
## Ticks left before acting on the current opening.
var reaction := 0
var lane_offset := 0.0
## The button chosen for the next attack, rolled once per opportunity.
var planned := ""
## Ticks left holding guard after reading an attack.
var guarding := 0
## The target attack (by its start tick) already reacted to.
var _read_attack := -1


func _init(ai: Dictionary, rng: RandomNumberGenerator) -> void:
	spacing = float(ai.get("spacing", spacing))
	reaction_ticks = int(ai.get("reaction", reaction_ticks))
	cooldown_ticks = int(ai.get("cooldown", cooldown_ticks))
	cooldown_jitter = int(ai.get("cooldown_jitter", cooldown_jitter))
	heavy_chance = float(ai.get("heavy_chance", 0.0))
	heavy_cooldown_ticks = int(ai.get("heavy_cooldown", DEFAULT_HEAVY_COOLDOWN))
	guard_chance = float(ai.get("guard_chance", 0.0))
	dodge_chance = float(ai.get("dodge_chance", 0.0))
	scavenge = bool(ai.get("scavenge", false))
	var ranged: Dictionary = ai.get("ranged", {})
	ranged_min = float(ranged.get("min", 0.0))
	ranged_max = float(ranged.get("max", 0.0))
	lane_offset = rng.randf_range(-LANE_SPREAD, LANE_SPREAD)
	# Freshly spawned enemies hesitate before their first attack.
	cooldown = rng.randi_range(30, 30 + cooldown_jitter)
	reaction = reaction_ticks


## `loot_at` is the nearest weapon on the ground (Vector2.INF if none).
func think(
	me: Fighter,
	target: Fighter,
	may_attack: bool,
	library: MoveLibrary,
	rng: RandomNumberGenerator,
	loot_at := Vector2.INF,
	tick := 0
) -> FighterInput:
	var input := FighterInput.new()
	cooldown = maxi(0, cooldown - 1)
	heavy_wait = maxi(0, heavy_wait - 1)
	if guarding > 0 and me.state in [Fighter.State.IDLE, Fighter.State.GUARD]:
		guarding -= 1
		input.guard = true
		return input
	if me.state != Fighter.State.IDLE or target == null or target.is_ko():
		return input
	var dx := target.position.x - me.position.x
	var dir_x := 1 if dx >= 0.0 else -1
	var distance := absf(dx)
	input.face = dir_x
	if _react_to_attack(me, target, distance, dir_x, input, rng, tick):
		return input
	if scavenge and me.weapon == "" and loot_at != Vector2.INF and not may_attack:
		var to_loot := loot_at - me.position
		if to_loot.length() <= SCAVENGE_RANGE:
			if absf(to_loot.x) <= PICK_REACH and absf(to_loot.y) <= PICK_REACH:
				input.pick = true
			else:
				input.move = to_loot.normalized()
			return input
	if ranged_max > 0.0:
		input = _keep_range(me, target, input, distance, dir_x, may_attack, library, rng)
	if ranged_max > 0.0 or (may_attack and cooldown == 0):
		return (
			input
			if ranged_max > 0.0
			else _press_attack(me, target, input, distance, dir_x, library, rng)
		)
	# Without a token: hold at spacing, drift to this enemy's own lane depth.
	var move_x := 0.0
	if distance < spacing - 12.0:
		move_x = -dir_x
	elif distance > spacing + 12.0:
		move_x = dir_x
	var to_lane := target.position.y + lane_offset - me.position.y
	var move_y := signf(to_lane) * 0.6 if absf(to_lane) > 4.0 else 0.0
	input.move = Vector2(move_x, move_y)
	return input


## Reads the target winding up an attack aimed this way: maybe guard for its
## duration, maybe hop back. One roll per attack. Returns true if it reacted.
func _react_to_attack(
	me: Fighter,
	target: Fighter,
	distance: float,
	dir_x: int,
	input: FighterInput,
	rng: RandomNumberGenerator,
	tick: int
) -> bool:
	if not _sees_wind_up(target, distance, dir_x, tick):
		return false
	_read_attack = tick - target.state_tick
	var roll := rng.randf()
	if roll < dodge_chance and me.energy >= CombatRules.DODGE_COST:
		input.face = -dir_x
		input.dodge = true
		return true
	if roll < dodge_chance + guard_chance:
		guarding = target.move.startup + target.move.active - target.state_tick + 2
		input.guard = true
		return true
	return false


## The target is winding up an attack, aimed this way and close enough to
## matter, that this brain has not reacted to yet.
func _sees_wind_up(target: Fighter, distance: float, dir_x: int, tick: int) -> bool:
	if guard_chance <= 0.0 and dodge_chance <= 0.0:
		return false
	if target.state != Fighter.State.ATTACK or target.move == null:
		return false
	var threat := target.move.reach_offset + target.move.reach + 16.0
	return (
		tick - target.state_tick != _read_attack
		and target.facing == -dir_x
		and distance <= threat
		and target.state_tick < target.move.startup
	)


## A ranged fighter: back off to its band, line up in the target's lane when
## it may attack, then lob (its "heavy"). Caught up close, it jabs instead.
func _keep_range(
	me: Fighter,
	target: Fighter,
	input: FighterInput,
	distance: float,
	dir_x: int,
	may_attack: bool,
	library: MoveLibrary,
	rng: RandomNumberGenerator
) -> FighterInput:
	var ready := may_attack and cooldown == 0
	var dy := target.position.y - me.position.y
	if ready and distance < ranged_min * 0.5:
		planned = "light"
		return _press_attack(me, target, input, distance, dir_x, library, rng)
	var lob_ready := ready and heavy_wait == 0
	if lob_ready and absf(dy) <= LOB_LANE and distance >= ranged_min and distance <= ranged_max:
		if reaction > 0:
			reaction -= 1
			return input
		input.heavy = true
		heavy_wait = heavy_cooldown_ticks
		reaction = reaction_ticks
		cooldown = cooldown_ticks + rng.randi_range(0, cooldown_jitter)
		return input
	var move_x := 0.0
	if distance < ranged_min:
		move_x = -dir_x
	elif distance > ranged_max:
		move_x = dir_x
	# With a turn to throw, line up exactly; otherwise keep its own lane.
	var to_lane := dy if lob_ready else dy + lane_offset
	var move_y := signf(to_lane) * 0.7 if absf(to_lane) > 4.0 else 0.0
	input.move = Vector2(move_x, move_y)
	return input


## True when this brain is ready to use an attack token.
func wants_attack() -> bool:
	return cooldown == 0


func _press_attack(
	me: Fighter,
	target: Fighter,
	input: FighterInput,
	distance: float,
	dir_x: int,
	library: MoveLibrary,
	rng: RandomNumberGenerator
) -> FighterInput:
	if not planned:
		var can_heavy := heavy_wait == 0 and CombatRules.starter(me, library, "heavy") != ""
		planned = "heavy" if can_heavy and rng.randf() < heavy_chance else "light"
	var move := library.get_move(CombatRules.starter(me, library, planned))
	if move == null:
		planned = ""
		return input
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH + RANGE_MARGIN
	# A lunge carries its hitbox forward, so a charge starts from further out.
	var far := (
		move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH - RANGE_MARGIN
	)
	var dy := target.position.y - me.position.y
	var in_lane := absf(dy) <= move.depth_tolerance * 0.6
	if distance >= near and distance <= far and in_lane:
		if reaction > 0:
			reaction -= 1
			return input
		input.set(planned, true)
		if planned == "heavy":
			heavy_wait = heavy_cooldown_ticks
		planned = ""
		reaction = reaction_ticks
		cooldown = cooldown_ticks + rng.randi_range(0, cooldown_jitter)
		return input
	var move_x := 0.0
	if distance > far:
		move_x = dir_x
	elif distance < near:
		move_x = -dir_x
	input.move = Vector2(move_x, 0.0 if in_lane else signf(dy))
	return input
