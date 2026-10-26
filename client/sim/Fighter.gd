class_name Fighter
extends RefCounted
## Temporary combat state of one combatant. Never persisted: durable
## progression (level, equipment) lives in the backend and only seeds max_hp
## and similar values when a fighter enters a zone.

enum State { IDLE, ATTACK, HITSTUN, DODGE, GUARD, DOWN, KO }

var id := 0
## Fighters only hit fighters of other teams.
var team := 0
## Content id: "hero" or an enemy id from enemies.json.
var kind := ""
## Input -> move id. Empty means the library's default starters (the hero).
var moveset := {}
## Damage multiplier, flat damage reduction, and walk speed multiplier.
var power := 1.0
var defense := 0
var speed := 1.0
## Chance (0..1) that a landed blow is a critical hit, and attack speed (1.0
## normal; higher cuts the recovery after each attack). Enemies keep 0 / 1.
var crit_chance := 0.0
var attack_speed := 1.0
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
## Held weapon (weapons.json id, "" for bare hands), hits left before it
## breaks, its moves (input -> move id, used instead of the starters) and its
## walk speed multiplier.
var weapon := ""
var weapon_uses := 0
var weapon_moveset := {}
var weapon_speed := 1.0
## Skills this fighter can use: skill id -> {"move": move id, "cooldown": ticks}.
var skills := {}
## Ticks until each skill can be used again (absent or 0: ready).
var cooldowns := {}
## A skill pressed during an attack, used if the attack can be cancelled.
var queued_skill := ""
## state_tick of the latest queued press (for the input buffer).
var queued_tick := 0
## Stun-lock protection (0: off, the default for enemies so hero combos
## still chain). Hitstun taken adds to stun_meter, which drains while the
## fighter is in control; a hit that would push it past stun_limit knocks
## the fighter down instead, and getting up grants `grace` ticks in which
## nothing can hit them.
var stun_limit := 0
var stun_meter := 0
var grace := 0
## Perfect guard (the hero only, so enemy guards never punish the player's
## combos): a guard raised just before a hit parries it. parry_open says
## whether the current guard may parry (it may not while parry_lockout runs,
## so tapping guard repeatedly does not keep the window open). A parried
## attacker is `exposed`: the next hit on it is a counter.
var can_parry := false
var parry_open := false
var parry_lockout := 0
var exposed := 0
## With nothing underfoot to pick up, the pick button throws the held weapon
## instead of putting it down (the hero; enemies only put weapons down).
var throws := false


func _init(p_id := 0, p_team := 0, p_position := Vector2.ZERO, p_max_hp := 100) -> void:
	id = p_id
	team = p_team
	position = p_position
	max_hp = p_max_hp
	hp = p_max_hp


func cooldown_left(skill_id: String) -> int:
	return int(cooldowns.get(skill_id, 0))


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
		queued_skill = ""
