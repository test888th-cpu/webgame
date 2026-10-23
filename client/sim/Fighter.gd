class_name Fighter
extends RefCounted
## Temporary combat state of one combatant. Never persisted: durable
## progression (level, equipment) lives in the backend and only seeds max_hp
## and similar values when a fighter enters a zone.

enum State { IDLE, ATTACK, HITSTUN, DODGE, GUARD, DOWN, KO }

var id := 0
## Fighters only hit fighters of other teams.
var team := 0
var position := Vector2.ZERO
var facing := 1
var max_hp := 100
var hp := 100
var energy := 100.0

var state := State.IDLE
## Ticks spent in the current state, starting at 0 on the tick it began.
var state_tick := 0
## Length of timed states (hitstun).
var state_duration := 0
var move: MoveData = null
## The current attack connected (hit or blocked), which unlocks its chains.
var hit_landed := false
## Defender ids the current attack already hit, so one swing hits once.
var hit_ids := {}
## Last attack button pressed during the current attack ("light"/"heavy").
var queued := ""
## Signed pixels of push still to apply along the street.
var knockback_remaining := 0.0
var dodge_dir := 1


func _init(p_id := 0, p_team := 0, p_position := Vector2.ZERO, p_max_hp := 100) -> void:
	id = p_id
	team = p_team
	position = p_position
	max_hp = p_max_hp
	hp = p_max_hp


func is_ko() -> bool:
	return state == State.KO


func state_name() -> String:
	return State.keys()[state].to_lower()


func enter(new_state: State, duration := 0) -> void:
	state = new_state
	state_tick = 0
	state_duration = duration
	if new_state != State.ATTACK:
		move = null
		queued = ""
