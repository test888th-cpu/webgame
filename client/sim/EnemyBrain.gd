class_name EnemyBrain
extends RefCounted
## Decides one enemy's input each tick. Waits at its preferred spacing until
## the zone grants it an attack token, then closes in, lines up in the lane,
## pauses for its reaction time and swings. Parameters come from the enemy's
## "ai" block in enemies.json. Randomness comes only from the zone's seeded
## generator, so a zone replays identically from the same seed and inputs.

## How far from the target's lane depth this enemy waits, so a crowd spreads
## out instead of stacking on one line.
const LANE_SPREAD := 24.0
## Slack in px around the move's reach when deciding to swing.
const RANGE_MARGIN := 4.0

var spacing := 56.0
var reaction_ticks := 12
var cooldown_ticks := 50
var cooldown_jitter := 30
var heavy_chance := 0.0

## Ticks until this enemy may attack again.
var cooldown := 0
## Ticks left before acting on the current opening.
var reaction := 0
var lane_offset := 0.0
## The button chosen for the next attack, rolled once per opportunity.
var planned := ""


func _init(ai: Dictionary, rng: RandomNumberGenerator) -> void:
	spacing = float(ai.get("spacing", spacing))
	reaction_ticks = int(ai.get("reaction", reaction_ticks))
	cooldown_ticks = int(ai.get("cooldown", cooldown_ticks))
	cooldown_jitter = int(ai.get("cooldown_jitter", cooldown_jitter))
	heavy_chance = float(ai.get("heavy_chance", 0.0))
	lane_offset = rng.randf_range(-LANE_SPREAD, LANE_SPREAD)
	# Freshly spawned enemies hesitate before their first attack.
	cooldown = rng.randi_range(30, 30 + cooldown_jitter)
	reaction = reaction_ticks


func think(
	me: Fighter, target: Fighter, may_attack: bool, library: MoveLibrary, rng: RandomNumberGenerator
) -> FighterInput:
	var input := FighterInput.new()
	cooldown = maxi(0, cooldown - 1)
	if me.state != Fighter.State.IDLE or target == null or target.is_ko():
		return input
	var dx := target.position.x - me.position.x
	var dir_x := 1 if dx >= 0.0 else -1
	var distance := absf(dx)
	input.face = dir_x
	if may_attack and cooldown == 0:
		return _press_attack(me, target, input, distance, dir_x, library, rng)
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
		var can_heavy := CombatRules.starter(me, library, "heavy") != ""
		planned = "heavy" if can_heavy and rng.randf() < heavy_chance else "light"
	var move := library.get_move(CombatRules.starter(me, library, planned))
	if move == null:
		planned = ""
		return input
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH + RANGE_MARGIN
	var far := move.reach_offset + move.reach + CombatRules.HURT_HALF_WIDTH - RANGE_MARGIN
	var dy := target.position.y - me.position.y
	var in_lane := absf(dy) <= move.depth_tolerance * 0.6
	if distance >= near and distance <= far and in_lane:
		if reaction > 0:
			reaction -= 1
			return input
		input.set(planned, true)
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
