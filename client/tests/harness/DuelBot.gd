class_name DuelBot
extends RefCounted
## A plain PvP opponent for DuelSim: walks in, strikes with the best ready
## skill that reaches (a combo route's next skill first, the ultimate when
## the gauge is full), grabs when its job's skills grab, throws at once,
## mashes out of a hold, and answers blows with a stance, a guard or a dodge.
## It reacts like a fair player, not a perfect one: it misses MISS_SHARE of
## its defensive reads, so parries cannot loop for ever. Same rules for every
## job; measurement only.

## Share of incoming blows the bot fails to read in time.
const MISS_SHARE := 0.35
## Ticks between presses while held (a player mashing).
const MASH_EVERY := 4

var _content: ContentDB
var _rng: RandomNumberGenerator
var _tick := 0
## The blow (attacker state_tick at its start) already read, so one blow is
## judged once.
var _read := -1


func _init(content: ContentDB, rng: RandomNumberGenerator) -> void:
	_content = content
	_rng = rng


func think(me: Fighter, foe: Fighter) -> FighterInput:
	_tick += 1
	var input := FighterInput.new()
	match me.state:
		Fighter.State.HELD:
			input.light = _tick % MASH_EVERY == 0
		Fighter.State.GRAB:
			input.light = true
		Fighter.State.ATTACK:
			_follow_up(me, foe, input)
		Fighter.State.GUARD:
			input.guard = foe.state == Fighter.State.ATTACK
		Fighter.State.IDLE:
			_free(me, foe, input)
	return input


## Free to act: defend, line up, strike with a skill or a punch, or close in.
func _free(me: Fighter, foe: Fighter, input: FighterInput) -> void:
	var dir := 1 if foe.position.x >= me.position.x else -1
	if _defend(me, foe, input, dir):
		return
	if absf(foe.position.y - me.position.y) > 4.0:
		input.move = Vector2(0, signf(foe.position.y - me.position.y))
		return
	var skill := _pick_skill(me, foe, dir)
	var jab := _content.moves.get_move(CombatRules.starter(me, _content.moves, "light"))
	input.face = dir
	if CounterRules.open(foe) and not _grabs(me, skill):
		# A player sees the raised guard of a stance: wait it out, or grab.
		input.move = Vector2(-dir, 0)
	elif skill != "":
		input.skill = skill
	elif CombatRules.is_vulnerable(foe) and _reaches(me, jab, foe, dir):
		input.light = true
	else:
		input.move = Vector2(dir, 0)


## Mid-attack: the next combo link if it is ready, else the next punch of the
## combination once a blow has landed.
func _follow_up(me: Fighter, foe: Fighter, input: FighterInput) -> void:
	if not me.hit_landed:
		return
	for link in ComboRules.next_links(me):
		if me.skills.has(link) and me.cooldown_left(link) == 0:
			input.skill = link
			return
	if me.move.chains.has("light") and CombatRules.is_vulnerable(foe):
		input.light = true


## A blow on its way: a stance to catch it, a dodge from what guard cannot
## stop, else a guard just before it lands (a perfect guard parries). Misses
## MISS_SHARE of them.
func _defend(me: Fighter, foe: Fighter, input: FighterInput, dir: int) -> bool:
	if foe.state != Fighter.State.ATTACK or foe.move == null or foe.move.damage <= 0:
		return false
	var due := foe.move.startup - foe.state_tick
	if due < 0 or not _threatens(foe, me) or not _reads(foe):
		return false
	var stance := AutoSkills.stance(_content, me, due)
	var unstoppable := foe.move.guard_break or foe.move.grab
	if stance != "" and not foe.move.guard_break:
		input.face = dir
		input.skill = stance
	elif unstoppable and due <= 10 and me.energy >= CombatRules.DODGE_COST:
		input.face = -dir
		input.dodge = true
	elif not unstoppable and due <= maxi(2, me.parry_window - 2):
		input.face = dir
		input.guard = true
	else:
		return false
	return true


## Whether the bot reads the blow `foe` is throwing: decided once per blow,
## missed MISS_SHARE of the time.
func _reads(foe: Fighter) -> bool:
	var start := _tick - foe.state_tick
	if start != _read and -start - 2 != _read:
		_read = start if _rng.randf() >= MISS_SHARE else -start - 2
	return _read == start


## The best skill to start now: the next link of a combo route, the ultimate
## with a full gauge, else the hardest-hitting ready one that reaches.
func _pick_skill(me: Fighter, foe: Fighter, dir: int) -> String:
	if not CombatRules.is_vulnerable(foe):
		return ""
	var best := ""
	var best_score := 0.0
	var ids: Array = me.skills.keys()
	ids.sort()
	for skill_id: String in ids:
		var skill: Dictionary = me.skills[skill_id]
		if me.cooldown_left(skill_id) > 0 or not UltimateRules.ready(me, skill):
			continue
		var move := _content.moves.get_move(str(skill["move"]))
		if move == null or move.counter or me.energy < move.energy_cost:
			continue
		if move.grab and not GrabRules.can_hold(foe):
			continue
		if not _reaches(me, move, foe, dir):
			continue
		var score := AutoSkills.power(_content, me, skill, foe)
		score *= AutoSkills.combo_weight(me, skill_id)
		if score > best_score:
			best_score = score
			best = skill_id
	return best


func _grabs(me: Fighter, skill_id: String) -> bool:
	if skill_id == "":
		return false
	var move := _content.moves.get_move(str(me.skills[skill_id]["move"]))
	return move != null and move.grab


func _reaches(me: Fighter, move: MoveData, foe: Fighter, facing: int) -> bool:
	if move == null:
		return false
	var ahead := (foe.position.x - me.position.x) * facing
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH
	var far := move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH - 4.0
	var depth := absf(foe.position.y - me.position.y)
	return ahead >= near and ahead <= far and depth <= move.depth_tolerance * 0.8


func _threatens(foe: Fighter, me: Fighter) -> bool:
	var move := foe.move
	var ahead := (me.position.x - foe.position.x) * foe.facing
	var far := move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH + 6.0
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH
	return ahead >= near and ahead <= far
