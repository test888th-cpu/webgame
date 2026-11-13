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
## blows it misreads, whether it chains combos, takes stances and dodges.
## Its timing is human: it sees a blow only `react_after` ticks after the blow
## starts (never under 200 ms), decides every `decision_ticks`, and mashes
## free of a hold at a human rate. How it likes to fight is its personality
## (configure(): approach, attack_rate, defend_bias, combo_bias, grab_bias,
## stance_bias, spacing, punish_whiff, low_hp). All of it comes from
## data/arena.json through ArenaLoadout.brain_settings; without configure()
## it uses the same defaults from its skill. Deterministic: its only chance
## is the zone's seeded generator.

## A beginner misreads this share of incoming blows, the best MISS_BEST.
const MISS_WORST := 0.6
const MISS_BEST := 0.15
## Defaults when not configured (data/arena.json "timing" says the same):
## 400 to 200 ms to react, 100 to 50 ms between decisions, 133 to 83 ms
## between presses while held (7.5 to 12 a second, a human's mash).
const REACTION_WORST := 24
const REACTION_BEST := 12
const CADENCE_WORST := 6
const CADENCE_BEST := 3
const MASH_WORST := 8
const MASH_BEST := 5
## A guard raised in anticipation: at most this share of decisions (times
## skill and defend_bias), within this range, held this long.
const ANTICIPATE_SHARE := 0.1
const ANTICIPATE_RANGE := 60.0
const ANTICIPATE_TICKS := 18
## Share of chain finishes it ends with the class heavy where a light could follow.
const HEAVY_FINISH := 0.35
## How it plays below LOW_HP_SHARE of its health.
const LOW_HP := ["steady", "press", "turtle", "kite"]
const LOW_HP_SHARE := 0.3
## The skill from which it chains combos, takes stances and dodges.
const COMBOS_FROM := 0.25
const STANCES_FROM := 0.4
const DODGES_FROM := 0.15

var skill := 0.5
## No input before this zone tick (the arena's countdown).
var start_at := 0
## Ticks from a blow's start before it can be seen and answered.
var react_after := REACTION_WORST
var decision_ticks := CADENCE_WORST
var mash_ticks := MASH_WORST
## Personality (configure()); the defaults are a plain, eager fighter.
var approach := 1.0
var attack_rate := 1.0
var defend_bias := 1.0
var combo_bias := 1.0
var grab_bias := 1.0
var stance_bias := 1.0
var keep_away := 0.0
var punish_whiff := 0.0
var low_hp := "steady"
## Counts of what it did (for the balance harness and tests).
var stats := {"decisions": 0, "skills": 0, "defends": 0, "punishes": 0}
## Guard held until this tick (a guard raised in anticipation).
var _guard_until := 0
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
	react_after = roundi(lerpf(REACTION_WORST, REACTION_BEST, skill))
	decision_ticks = roundi(lerpf(CADENCE_WORST, CADENCE_BEST, skill))
	mash_ticks = roundi(lerpf(MASH_WORST, MASH_BEST, skill))
	engaged = true


## Takes ArenaLoadout.brain_settings: skill, timing in ticks, personality.
## Missing keys keep their defaults; reactions never drop under REACTION_BEST.
func configure(settings: Dictionary) -> void:
	skill = clampf(float(settings.get("skill", skill)), 0.0, 1.0)
	react_after = maxi(REACTION_BEST, int(settings.get("reaction_ticks", react_after)))
	decision_ticks = maxi(1, int(settings.get("decision_ticks", decision_ticks)))
	mash_ticks = maxi(MASH_BEST, int(settings.get("mash_ticks", mash_ticks)))
	approach = clampf(float(settings.get("approach", approach)), 0.0, 1.0)
	attack_rate = clampf(float(settings.get("attack_rate", attack_rate)), 0.0, 1.0)
	defend_bias = clampf(float(settings.get("defend_bias", defend_bias)), 0.0, 1.0)
	combo_bias = maxf(0.0, float(settings.get("combo_bias", combo_bias)))
	grab_bias = maxf(0.0, float(settings.get("grab_bias", grab_bias)))
	stance_bias = maxf(0.0, float(settings.get("stance_bias", stance_bias)))
	keep_away = maxf(0.0, float(settings.get("spacing", keep_away)))
	punish_whiff = clampf(float(settings.get("punish_whiff", punish_whiff)), 0.0, 1.0)
	var mode := str(settings.get("low_hp", low_hp))
	low_hp = mode if mode in LOW_HP else "steady"


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
			input.guard = target.state == Fighter.State.ATTACK or _ticks < _guard_until
		Fighter.State.IDLE:
			_rival_free(me, target, input)
	return input


func miss_share() -> float:
	return lerpf(MISS_WORST, MISS_BEST, skill)


func mash_every() -> int:
	return mash_ticks


func cadence() -> int:
	return decision_ticks


## Its tendencies now: at low health a personality may press, turtle or kite.
func _mood(me: Fighter) -> Dictionary:
	var mood := {
		"approach": approach, "attack": attack_rate, "defend": defend_bias, "spacing": keep_away
	}
	if float(me.hp) / maxf(1.0, me.max_hp) >= LOW_HP_SHARE:
		return mood
	match low_hp:
		"press":
			mood["approach"] = 1.0
			mood["attack"] = 1.0
		"turtle":
			mood["attack"] = attack_rate * 0.5
			mood["defend"] = 1.0
		"kite":
			mood["approach"] = approach * 0.5
			mood["spacing"] = maxf(keep_away, 48.0)
	return mood


## Free to act: defend, line up, strike with a skill or a punch, or close in.
func _rival_free(me: Fighter, foe: Fighter, input: FighterInput) -> void:
	var dir := 1 if foe.position.x >= me.position.x else -1
	var mood := _mood(me)
	if _rival_defend(me, foe, input, dir, float(mood["defend"])):
		return
	if absf(foe.position.y - me.position.y) > 4.0:
		input.move = Vector2(0, signf(foe.position.y - me.position.y))
		return
	input.face = dir
	var punish := _rival_whiffed(foe)
	if _ticks % cadence() != 0 and not punish:
		return
	stats["decisions"] += 1
	if not punish and _rival_anticipates(me, foe, float(mood["defend"])):
		input.guard = true
		_guard_until = _ticks + ANTICIPATE_TICKS
		stats["defends"] += 1
		return
	var chosen := _rival_skill(me, foe, dir)
	var jab := _db.moves.get_move(CombatRules.starter(me, _db.moves, "light"))
	var eager := punish or _gen.randf() < float(mood["attack"])
	var gap := absf(foe.position.x - me.position.x)
	var heavy := _db.moves.get_move(CombatRules.starter(me, _db.moves, "heavy"))
	if (
		foe.state == Fighter.State.GUARD
		and heavy != null
		and heavy.guard_break
		and me.energy >= heavy.energy_cost
		and _rival_reaches(me, heavy, foe, dir)
	):
		# A raised guard is what a guard-breaking heavy is for.
		input.heavy = true
		return
	if CounterRules.open(foe) and not _rival_grabs(me, chosen):
		# The raised guard of a stance shows: wait it out, or grab.
		input.move = Vector2(-dir, 0)
	elif eager and chosen != "":
		input.skill = chosen
		stats["skills"] += 1
		stats["punishes"] += 1 if punish else 0
	elif eager and CombatRules.is_vulnerable(foe) and _rival_reaches(me, jab, foe, dir):
		input.light = true
		stats["punishes"] += 1 if punish else 0
	elif punish or _gen.randf() < float(mood["approach"]):
		input.move = Vector2(dir, 0)
	elif gap < float(mood["spacing"]):
		input.move = Vector2(-dir, 0)


## A guard raised before a blow, on what a player sees: the foe idle, close
## and facing this way. Likelier the better it plays and the more defensive
## it is; never a read of what the foe will press.
func _rival_anticipates(me: Fighter, foe: Fighter, will: float) -> bool:
	if foe.state != Fighter.State.IDLE or absf(foe.position.x - me.position.x) > ANTICIPATE_RANGE:
		return false
	if signf(me.position.x - foe.position.x) != signf(foe.facing):
		return false
	return _gen.randf() < skill * will * ANTICIPATE_SHARE


## Whether `foe` is recovering from a blow that missed (a whiff), and this
## rival chooses to punish it: decided once per blow (punish_whiff).
func _rival_whiffed(foe: Fighter) -> bool:
	if punish_whiff <= 0.0 or foe.state != Fighter.State.ATTACK or foe.move == null:
		return false
	if foe.hit_landed or foe.state_tick < foe.move.startup + foe.move.active:
		return false
	if foe.state_tick - foe.move.startup - foe.move.active < react_after / 2:
		return false
	return _rival_reads(foe) and _gen.randf() < punish_whiff


## Mid-attack: the next combo link if it is ready, else the next punch of the
## combination once a blow has landed.
func _rival_follow_up(me: Fighter, foe: Fighter, input: FighterInput) -> void:
	if not me.hit_landed:
		return
	if skill >= COMBOS_FROM:
		var dir := 1 if foe.position.x >= me.position.x else -1
		for link in ComboRules.next_links(me):
			if not me.skills.has(link) or me.cooldown_left(link) > 0:
				continue
			# Only a link that reaches: the last blow may have knocked the foe away.
			var link_move := _db.moves.get_move(str(me.skills[link]["move"]))
			if link_move != null and (link_move.counter or _rival_reaches(me, link_move, foe, dir)):
				input.skill = link
				return
	if not CombatRules.is_vulnerable(foe):
		return
	var heavy := _db.moves.get_move(CombatRules.starter(me, _db.moves, "heavy"))
	var route_links: Array[String] = []
	if skill >= COMBOS_FROM:
		route_links = ComboRules.next_links(me)
	if "heavy" in route_links and heavy != null and me.energy >= heavy.energy_cost:
		input.heavy = true
		return
	if "light" in route_links:
		input.light = true
		return
	var can_heavy := me.move.chains.has("heavy") and heavy != null
	can_heavy = can_heavy and me.energy >= heavy.energy_cost + CombatRules.DODGE_COST
	# The class heavy finishes a chain: always where no light follows, else
	# now and then (HEAVY_FINISH), so its timing is not read off the light.
	if can_heavy and (not me.move.chains.has("light") or _gen.randf() < HEAVY_FINISH):
		input.heavy = true
	elif me.move.chains.has("light"):
		input.light = true


## A blow on its way: a stance to catch it, a dodge from what guard cannot
## stop, else a guard just before it lands (a perfect guard parries).
func _rival_defend(me: Fighter, foe: Fighter, input: FighterInput, dir: int, will := 1.0) -> bool:
	if foe.state != Fighter.State.ATTACK or foe.move == null or foe.move.damage <= 0:
		return false
	# A blow is seen only reaction_ticks after it starts, as a person sees it.
	if foe.state_tick < react_after:
		return false
	var due := foe.move.startup - foe.state_tick
	if due < 0 or not _rival_threatens(foe, me) or not _rival_reads(foe):
		return false
	if will < 1.0 and _gen.randf() >= will:
		return false
	stats["defends"] += 1
	var wants_stance := skill >= STANCES_FROM and _gen.randf() < stance_bias
	var breaker := foe.move.guard_break
	var stance := AutoSkills.stance(_db, me, due, breaker) if wants_stance else ""
	var unstoppable := foe.move.guard_break or foe.move.grab
	var can_dodge := skill >= DODGES_FROM and me.energy >= CombatRules.DODGE_COST
	if stance != "":
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
			var weight := AutoSkills.combo_weight(me, skill_id, true)
			score *= 1.0 + (weight - 1.0) * combo_bias
		if move.grab:
			score *= grab_bias
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
