class_name Fighter
extends RefCounted
## Temporary combat state of one combatant. Never persisted: durable
## progression (level, equipment) lives in the backend and only seeds max_hp
## and similar values when a fighter enters a zone.

## GRAB: holding a foe. HELD: in someone's hold (GrabRules).
enum State { IDLE, ATTACK, HITSTUN, DODGE, GUARD, DOWN, KO, GRAB, HELD }

var id := 0
## Fighters only hit fighters of other teams.
var team := 0
## Content id: "hero" or an enemy id from enemies.json.
var kind := ""
## A name to show instead of the kind's (an arena rival's ring name), and the
## art it is drawn with ("" for its kind's own).
var title := ""
var look := ""
## A farming ground's elite (FarmSpawner): tougher, worth more, named in gold.
var elite := false
## Input -> move id. Empty means the library's default starters (the hero).
var moveset := {}
## Damage multiplier, flat damage reduction, and walk speed multiplier.
var power := 1.0
var defense := 0
var speed := 1.0
## A boss's pace: its hazard and summon intervals are multiplied by this
## (below 1 once enraged, BossEnrage).
var rage := 1.0
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
## Skills this fighter can use: skill id -> {"move": move id, "cooldown":
## ticks, "then": later moves, "scale": balance multipliers} (SkillRules).
var skills := {}
## Grab and throw (GrabRules). `grab` is the job's profile ({} for fighters
## who cannot grab): {"move", "release", "throw", "crash", "shove", "hold"}.
## `holding` / `held_by` are the other fighter's id (0: nobody); grab_guard
## the ticks in which this fighter cannot be grabbed again. A thrown body
## remembers who threw it and whom it has already knocked into.
var grab := {}
## Never held or thrown: bosses and mini-bosses (enemies.json "boss" or
## "elite"). A grab on them lands as a shove.
var ungrabbable := false
var holding := 0
var held_by := 0
var grab_guard := 0
var thrown_by := 0
var thrown_hits := {}
## Ticks a thrown body is still in the air (GrabRules.AIR_TICKS at the
## throw): it travels its knockback evenly while aloft, then drops.
var airborne := 0
## True on the one tick a thrown body hits the ground (the slam).
var landed := false
## Who threw this body and with what (a move id): the throw's blow lands
## when the body hits the street (GrabRules).
var slam_by := 0
var slam_move := ""
## The skill being used ("" outside one) and which of its moves is running
## (SkillSequence). Cleared by any state but ATTACK, so a hit ends the skill.
var skill_id := ""
var skill_step := 0
## The ultimate gauge (0..UltimateRules.FULL) and what fills it: points per
## blow landed and per share of health lost ({} for fighters without one).
var gauge := 0.0
var gauge_rates := {}
## The skill behind the current hold, if a skill's grab made it: its own
## throw, crash, hold and squeeze, and where the skill continues after.
var grab_plan := {}
## The balance scale (BalanceProfile damage, PvE or PvP) of the skill behind
## this fighter's last throw: its blow and crashes land after the skill ends.
var throw_scale := 1.0
## The move a body thrown by this fighter crashes into others with.
var crash_move := ""
## Skill combos (ComboRules): the routes this fighter knows, the skills of
## the chain so far, whether its latest link has landed, ticks left to start
## the next one, the route being finished ({} if none) and whether its
## completion was counted; `combo_done` is a route just completed, for the
## zone to report. The hit chain counts blows landed in a row.
var combos: Array[Dictionary] = []
var combo_chain: Array = []
var combo_landed := false
var combo_timer := 0
var combo_finish := {}
var combo_shown := false
var combo_done := ""
var hit_chain := 0
var hit_chain_timer := 0
## A counter stance caught a blow: the reply starts next tick (CounterRules).
var countered := false
## Passive skills (id -> spec) and the stacks earned (id -> {"count",
## "ticks"}); see PassiveRules.
var passives := {}
var stacks := {}
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
## Blows landed in a row on this hero while reeling (CombatRules.combo_scale).
var combo_taken := 0
var grace := 0
## Poise (elites and bosses): hitstun taken fills the same stun_meter; past
## poise_limit the fighter shrugs blows off for `armor` ticks (still taking
## damage), so mashing cannot pin them. They are also unflinching while
## winding up a telegraphed attack: dodge it, guard it or parry it.
var poise_limit := 0
var armor := 0
## Bosses: no blow makes them flinch, stagger, reel or fall; only a break
## does (CombatRules BREAK_*). break_meter is the damage piled on them
## lately, break_rest the ticks before it can fill again.
var unshaken := false
var break_meter := 0.0
var break_rest := 0
## A heavy-armoured move (MoveData.armor) already shrugged off one hero's
## blow: in PvP the next one gets through. Reset by every new move.
var armor_spent := false
## Skills cannot be interrupted once started (heroes.json `skill_armor`).
var skill_armor := false
## Perfect guard (the hero only, so enemy guards never punish the player's
## combos): a guard raised just before a hit parries it. parry_open says
## whether the current guard may parry (it may not while parry_lockout runs,
## so tapping guard repeatedly does not keep the window open). A parried
## attacker is `exposed`: the next hit on it is a counter.
var can_parry := false
## How many ticks before a hit a raised guard still parries (Dao: wider).
var parry_window := CombatRules.PERFECT_GUARD_TICKS
var parry_open := false
var parry_lockout := 0
var exposed := 0
## The pick button throws the held weapon (even with others underfoot)
## instead of swapping or putting it down (the hero; enemies never throw).
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
		skill_id = ""
		skill_step = 0
		countered = false
