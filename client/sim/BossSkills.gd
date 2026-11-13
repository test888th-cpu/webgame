class_name BossSkills
extends RefCounted
## Runs the boss's own skills (BossSkillRules) in a fight, beside
## BossMechanics, which ticks it. EnemyBrain picks a skill and presses it
## like a hero would (FighterInput.skill), so the shared combat rules start
## its first move and its cooldown; this class does what is particular to a
## boss skill from then on:
## * a combo's next moves, each as the last one ends (cut short if the boss is
##   knocked down or broken off, or raises its shield);
## * a cast's hazard or helpers, the moment its wind-up ends (no hitbox of its
##   own: the hazard is warned on the ground, then lands); an Ultimate's
##   waves, all called then, each landing on its own warning;
## * the cleanup: when the boss falls, the hero falls or the boss leaves
##   (a world boss's escape clears ZoneSim.boss_id), its skills are taken
##   away and every hazard still waiting is cleared, so nothing lands after.

## Ticks a boss keeps still after its Ultimate's last wave lands.
const CHANNEL_EXTRA := 20

var _boss_id := 0
var _stopped := false
## The skill under way ("" if none), its combo moves still to come, and
## whether its cast has yet to land.
var _active := ""
var _follow: Array[String] = []
var _cast_due := false
## An Ultimate's waves still to be marked: [[ticks left, wave]].
var _waves: Array = []
## Ticks until the boss's Ultimate has fully landed (0: not channelling).
var _channel := 0


## The skill under way ("" if none).
func active() -> String:
	return _active


## True while an Ultimate is channelled: its waves still to mark or to land.
## BossMechanics holds its own hazards and summons meanwhile, so nothing
## stacks on the Ultimate's waves and its safe ground stays safe.
func channeling() -> bool:
	return _channel > 0


func tick(zone: ZoneSim, mechanics: BossMechanics, events: Array[ZoneEvent]) -> void:
	if zone.boss_id != _boss_id:
		_stop(zone, events)
		_boss_id = zone.boss_id
		_stopped = false
		var boss := zone.fighter(_boss_id)
		if boss != null and boss.kind == ArenaRules.KIND:
			# An arena rival is a hero: it keeps its job's skills, and the
			# boss's skill table (it has none) must not replace them.
			_stopped = true
		elif _boss_id != 0:
			_arm(zone)
	if _boss_id == 0 or _stopped:
		return
	_channel = maxi(0, _channel - 1)
	var boss := zone.fighter(_boss_id)
	if boss == null or boss.is_ko() or zone.hero.is_ko():
		_stop(zone, events)
		return
	var brain: EnemyBrain = zone.brains.get(boss.id)
	if brain:
		brain.boss_phase = zone.phase_of(boss.id)
	if boss.state == Fighter.State.ATTACK and boss.state_tick == 0:
		_begin(zone, boss)
	if _active == "":
		_call_waves(zone, mechanics, boss, events)
		return
	_call_waves(zone, mechanics, boss, events)
	var data := BossSkillRules.skill(zone.content, _active)
	match boss.state:
		Fighter.State.ATTACK:
			if _cast_due and boss.state_tick >= boss.move.startup:
				_cast_due = false
				_land(zone, mechanics, boss, data, events)
		Fighter.State.IDLE:
			# Behind its shield a boss is untouchable and stands back
			# (BossMechanics): the rest of a combo is dropped, not swung.
			if _follow.is_empty() or mechanics.shield_up():
				_reset()
				return
			# The combo's next blow, turned to the hero.
			var next := zone.content.moves.get_move(_follow.pop_front())
			boss.facing = 1 if zone.hero.position.x >= boss.position.x else -1
			CombatRules.start_move(boss, next)
		_:
			# Knocked off its feet or broken: the rest of the skill is lost.
			_reset()


## A move began this tick: the start of one of the boss's skills, or of a
## plain blow (which ends any skill still noted).
func _begin(zone: ZoneSim, boss: Fighter) -> void:
	for id: String in boss.skills:
		if str(boss.skills[id]["move"]) == boss.move.id:
			var data := BossSkillRules.skill(zone.content, id)
			_active = id
			_follow.clear()
			for move_id: Variant in data["moves"].slice(1):
				_follow.append(str(move_id))
			_cast_due = BossSkillRules.is_cast(data)
			if BossSkillRules.is_ultimate(data):
				# Channelling from the first frame of its wind-up: the boss's own
				# hazard cycle and helpers wait from now (BossMechanics).
				_channel = boss.move.startup + 1
			return
	if _active != "" and boss.move.id not in BossSkillRules.skill(zone.content, _active)["moves"]:
		_reset()


## An Ultimate's later waves, each marked when its delay runs out (they go on
## even if the boss is struck: the Ultimate was cast).
func _call_waves(zone: ZoneSim, mechanics: BossMechanics, boss: Fighter, events: Array) -> void:
	for pending: Array in _waves.duplicate():
		pending[0] -= 1
		if pending[0] <= 0:
			_waves.erase(pending)
			mechanics.call_hazard(zone, boss, pending[1], events)


## Ticks from the cast until `wave` lands.
static func _lands_after(wave: Dictionary) -> int:
	return int(wave.get("delay", 0)) + int(wave["warn"])


func _land(
	zone: ZoneSim, mechanics: BossMechanics, boss: Fighter, data: Dictionary, events: Array
) -> void:
	if data.has("summon"):
		mechanics.summon(zone, boss, data["summon"], events)
	elif data.has("hazard"):
		mechanics.call_hazard(zone, boss, data["hazard"], events)
	# An Ultimate: each wave marked when it is next ("delay" ticks on). The
	# boss channels, standing still and striking nothing until the last wave
	# has landed: its tiles stay where they were cast, its body never walks into
	# the hero's safe gap, and no blow pins the hero under a wave.
	#
	# Hazards the boss had already called (a regular skill's, its hazard
	# cycle's) keep their mechanics and land as warned, but the first wave is
	# marked only once they have: nothing of theirs can land in the Ultimate's
	# safe ground, and the boss channels through the wait.
	var waves: Array = data.get("waves", [])
	if waves.is_empty():
		return
	var wait := clear_in(zone)
	var last: int = waves.map(_lands_after).max()
	_channel = wait + last + CHANNEL_EXTRA
	var brain: EnemyBrain = zone.brains.get(boss.id)
	if brain:
		brain.hold = _channel
	for wave: Dictionary in waves:
		var tagged := wave.merged({"from": _active})
		var delay := wait + int(wave.get("delay", 0))
		if delay <= 0:
			mechanics.call_hazard(zone, boss, tagged, events)
		else:
			_waves.append([delay, tagged])


## Ticks until every hazard already on the ground has landed (0: none).
static func clear_in(zone: ZoneSim) -> int:
	var most := 0
	for drop: Dictionary in zone.hazards:
		most = maxi(most, int(drop["ticks"]))
	return most


## Gives the boss its skills: to its fighter (cooldowns, the combat rules) and
## to its brain (when to use each).
func _arm(zone: ZoneSim) -> void:
	var boss := zone.fighter(_boss_id)
	if boss == null:
		return
	boss.skills = BossSkillRules.fighter_table(zone.content, boss.kind)
	# Some skills (an Ultimate) wait a while into the fight before their first use.
	for id: String in boss.skills:
		var opening := int(BossSkillRules.skill(zone.content, id).get("opening", 0))
		if opening > 0:
			boss.cooldowns[id] = opening
	var brain: EnemyBrain = zone.brains.get(boss.id)
	if brain:
		brain.boss_skills = BossSkillRules.choices(zone.content, boss.kind)


## Ends every skill of the boss for good: none still under way, none to be
## chosen, no hazard left to land. Each hazard taken off the street is
## reported (hazard_cancel), so its warning is cleared with it and never lies
## on the ground after the boss is gone.
func _stop(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	if _boss_id == 0 or _stopped:
		return
	_stopped = true
	_reset()
	_waves.clear()
	_channel = 0
	for drop: Dictionary in zone.hazards:
		events.append(ZoneEvent.make("hazard_cancel", {"id": int(drop.get("id", 0))}))
	zone.hazards.clear()
	var boss := zone.fighter(_boss_id)
	if boss:
		boss.skills = {}
	var brain: EnemyBrain = zone.brains.get(_boss_id)
	if brain:
		brain.boss_skills = []
		brain.planned_skill = ""


func _reset() -> void:
	_active = ""
	_follow.clear()
	_cast_due = false
