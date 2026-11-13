class_name ArenaBrain
extends EnemyBrain
## An arena rival: a player's hero played by the computer (ArenaRules). It
## uses the same inputs a player has: walks in, strikes with the best ready
## skill that reaches (a combo route's next skill first, the ultimate with a
## full gauge), grabs where its job grabs, throws at once, mashes out of a
## hold, and answers blows with a stance, a guard or a dodge. It never reads
## anything a player could not see.
##
## How well it plays is `skill` (0 a beginner, 1 the best): how many incoming
## blows it misreads, how often it decides, whether it chains combos, takes
## stances and dodges, and how fast it mashes free. The ladder raises it with
## the rank. Deterministic: its only chance is the zone's seeded generator.

## A beginner misreads this share of incoming blows, the best MISS_BEST.
const MISS_WORST := 0.6
const MISS_BEST := 0.15
## Ticks between decisions while free: a beginner hesitates.
const CADENCE_WORST := 6
## Ticks between presses while held: a beginner mashes slowly.
const MASH_WORST := 8
const MASH_BEST := 3
## The skill from which it chains combos, takes stances and dodges.
const COMBOS_FROM := 0.25
const STANCES_FROM := 0.4
const DODGES_FROM := 0.15

var skill := 0.5
## No input before this zone tick (the arena's countdown).
var start_at := 0
var _db: ContentDB
var _gen: RandomNumberGenerator
var _ticks := 0
## The incoming blow (the attacker's start tick) already read, so one blow is
## judged once; a misread one is stored negated.
var _blow_read := -1


func _init(content: ContentDB, rng: RandomNumberGenerator, p_skill := 0.5) -> void:
	super({}, rng)
	_db = content
	_gen = rng
	skill = clampf(p_skill, 0.0, 1.0)
	engaged = true


func wants_attack() -> bool:
	return true


## One tick of input for `me` against `target` (the zone calls it like any
## enemy's brain; the attack token and the weapon underfoot do not apply).
func think(
	me: Fighter,
	target: Fighter,
	_may_attack: bool,
	_library: MoveLibrary,
	_rng_in: RandomNumberGenerator,
	_loot_at := Vector2.INF,
	tick := 0
) -> FighterInput:
	_ticks += 1
	var input := FighterInput.new()
	if tick < start_at or target == null or target.is_ko():
		return input
	match me.state:
		Fighter.State.HELD:
			input.light = _ticks % mash_every() == 0
		Fighter.State.GRAB:
			input.light = true
		Fighter.State.ATTACK:
			_rival_follow_up(me, target, input)
		Fighter.State.GUARD:
			input.guard = target.state == Fighter.State.ATTACK
		Fighter.State.IDLE:
			_rival_free(me, target, input)
	return input


func miss_share() -> float:
	return lerpf(MISS_WORST, MISS_BEST, skill)


func mash_every() -> int:
	return roundi(lerpf(MASH_WORST, MASH_BEST, skill))


func cadence() -> int:
	return maxi(1, roundi(lerpf(CADENCE_WORST, 1, skill)))


## Free to act: defend, line up, strike with a skill or a punch, or close in.
func _rival_free(me: Fighter, foe: Fighter, input: FighterInput) -> void:
	var dir := 1 if foe.position.x >= me.position.x else -1
	if _rival_defend(me, foe, input, dir):
		return
	if absf(foe.position.y - me.position.y) > 4.0:
		input.move = Vector2(0, signf(foe.position.y - me.position.y))
		return
	input.face = dir
	if _ticks % cadence() != 0:
		return
	var chosen := _rival_skill(me, foe, dir)
	var jab := _db.moves.get_move(CombatRules.starter(me, _db.moves, "light"))
	if CounterRules.open(foe) and not _rival_grabs(me, chosen):
		# The raised guard of a stance shows: wait it out, or grab.
		input.move = Vector2(-dir, 0)
	elif chosen != "":
		input.skill = chosen
	elif CombatRules.is_vulnerable(foe) and _rival_reaches(me, jab, foe, dir):
		input.light = true
	else:
		input.move = Vector2(dir, 0)


## Mid-attack: the next combo link if it is ready, else the next punch of the
## combination once a blow has landed.
func _rival_follow_up(me: Fighter, foe: Fighter, input: FighterInput) -> void:
	if not me.hit_landed:
		return
	if skill >= COMBOS_FROM:
		for link in ComboRules.next_links(me):
			if me.skills.has(link) and me.cooldown_left(link) == 0:
				input.skill = link
				return
	if me.move.chains.has("light") and CombatRules.is_vulnerable(foe):
		input.light = true


## A blow on its way: a stance to catch it, a dodge from what guard cannot
## stop, else a guard just before it lands (a perfect guard parries).
func _rival_defend(me: Fighter, foe: Fighter, input: FighterInput, dir: int) -> bool:
	if foe.state != Fighter.State.ATTACK or foe.move == null or foe.move.damage <= 0:
		return false
	var due := foe.move.startup - foe.state_tick
	if due < 0 or not _rival_threatens(foe, me) or not _rival_reads(foe):
		return false
	var stance := AutoSkills.stance(_db, me, due) if skill >= STANCES_FROM else ""
	var unstoppable := foe.move.guard_break or foe.move.grab
	var can_dodge := skill >= DODGES_FROM and me.energy >= CombatRules.DODGE_COST
	if stance != "" and not foe.move.guard_break:
		input.face = dir
		input.skill = stance
	elif unstoppable and due <= 10 and can_dodge:
		input.face = -dir
		input.dodge = true
	elif not unstoppable and due <= maxi(2, me.parry_window - 2):
		input.face = dir
		input.guard = true
	else:
		return false
	return true


## Whether the blow `foe` is throwing is read: decided once per blow.
func _rival_reads(foe: Fighter) -> bool:
	var start := _ticks - foe.state_tick
	if start != _blow_read and -start - 2 != _blow_read:
		_blow_read = start if _gen.randf() >= miss_share() else -start - 2
	return _blow_read == start


## The best skill to start now: the next link of a combo route, the ultimate
## with a full gauge, else the hardest-hitting ready one that reaches.
func _rival_skill(me: Fighter, foe: Fighter, dir: int) -> String:
	if not CombatRules.is_vulnerable(foe):
		return ""
	var best := ""
	var best_score := 0.0
	var ids: Array = me.skills.keys()
	ids.sort()
	for skill_id: String in ids:
		var data: Dictionary = me.skills[skill_id]
		if me.cooldown_left(skill_id) > 0 or not UltimateRules.ready(me, data):
			continue
		var move := _db.moves.get_move(str(data["move"]))
		if move == null or move.counter or me.energy < move.energy_cost:
			continue
		if move.grab and not GrabRules.can_hold(foe):
			continue
		if not _rival_reaches(me, move, foe, dir):
			continue
		var score := AutoSkills.power(_db, me, data, foe)
		if skill >= COMBOS_FROM:
			score *= AutoSkills.combo_weight(me, skill_id)
		if score > best_score:
			best_score = score
			best = skill_id
	return best


func _rival_grabs(me: Fighter, skill_id: String) -> bool:
	if skill_id == "":
		return false
	var move := _db.moves.get_move(str(me.skills[skill_id]["move"]))
	return move != null and move.grab


func _rival_reaches(me: Fighter, move: MoveData, foe: Fighter, facing: int) -> bool:
	if move == null:
		return false
	var ahead := (foe.position.x - me.position.x) * facing
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH
	var far := move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH - 4.0
	var depth := absf(foe.position.y - me.position.y)
	return ahead >= near and ahead <= far and depth <= move.depth_tolerance * 0.8


func _rival_threatens(foe: Fighter, me: Fighter) -> bool:
	var move := foe.move
	var ahead := (me.position.x - foe.position.x) * foe.facing
	var far := move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH + 6.0
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH
	return ahead >= near and ahead <= far
