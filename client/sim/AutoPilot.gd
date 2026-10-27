class_name AutoPilot
extends RefCounted
## The hero's auto-battle brain. Each tick it reads the zone and presses the
## same buttons a player has (a FighterInput), plus at most one consumable to
## use through ZoneSim.use_item. It never changes the simulation itself, so it
## can do nothing a player could not, and a server only ever sees ordinary
## input. No randomness: the same zone always gets the same answer.
##
## Priorities, highest first:
##   1. a quick heal when health falls below `heal_below`;
##   2. getting out of a hazard's shadow or a thrown weapon's path;
##   3. answering a wind-up aimed at the hero: dodge what guard cannot stop
##      (guard breakers, telegraphed heavies), guard the rest just before it
##      lands (a perfect guard parries), or hit first when that is quicker;
##   4. skills, chosen from the hero's own move data: area skills into crowds,
##      single-target skills on the target, the big one saved for crowds and
##      bosses, always keeping energy for a dodge;
##   5. light combos chained into a heavy finisher, on the best target (close,
##      hurt, or a thrower left alone);
##   6. between fights: pick up a street weapon, collect drops, walk on to the
##      next fight. With nothing left, it reports "clear".

const STATUS_FIGHT := "Fighting"
const STATUS_EVADE := "Dodging"
const STATUS_LOOT := "Looting"
const STATUS_WEAPON := "Grabbing a weapon"
const STATUS_ADVANCE := "To the next fight"
const STATUS_CLEAR := "Area clear"
const STATUS_DOWN := "Knocked out"

## Skills with a cooldown this long are the big finishers: saved for a crowd
## of three or a boss.
const BIG_SKILL_COOLDOWN := 600
## Energy kept back for a dodge, unless a skill would hit a crowd.
const ENERGY_RESERVE := CombatRules.DODGE_COST
## How far a wind-up is read: a little beyond the attack's own reach.
const THREAT_MARGIN := 6.0
## Thrown weapons and lobs closer than this, in the hero's lane, are dodged.
const PROJECTILE_RANGE := 120.0
const PROJECTILE_LANE := 16.0
## Closer than this there is no time to step aside: guard instead.
const PROJECTILE_GUARD := 36.0
## Drops and weapons are only fetched with no foe this close.
const SAFE_DISTANCE := 70.0
const WEAPON_RANGE := 90.0
## Ticks of no progress before it steps around whatever blocks it.
const STUCK_TICKS := 12
const SIDESTEP_TICKS := 30
## Ticks spent walking to one drop or weapon without getting closer before
## giving up on it.
const CHASE_TICKS := 120

## Use a consumable once health is below this share of the maximum.
var heal_below := 0.5
## What it is doing now, for the HUD (one of the STATUS_ strings).
var status := ""
## The consumable to use this tick ("" for none); set by think().
var item := ""

var _content: ContentDB
var _target_id := 0
var _guard_until := -1
var _last_position := Vector2.INF
var _still := 0
var _sidestep := 0
var _sidestep_dir := Vector2.DOWN
## Drops or weapons it could not reach in time, skipped for this zone.
var _skipped: Array[Vector2] = []
var _chasing := Vector2.INF
var _chase_ticks := 0
var _chase_best := INF
var _zone_id := 0


func _init(content: ContentDB) -> void:
	_content = content


## This tick's input for the hero of `zone`. Also sets `item` and `status`.
func think(zone: ZoneSim) -> FighterInput:
	var input := FighterInput.new()
	var hero := zone.hero
	item = ""
	if zone.get_instance_id() != _zone_id:
		_zone_id = zone.get_instance_id()
		_skipped.clear()
		_chasing = Vector2.INF
		_target_id = 0
	if hero.is_ko():
		status = STATUS_DOWN
		return input
	item = _pick_heal(zone)
	if hero.state in [Fighter.State.HITSTUN, Fighter.State.DOWN, Fighter.State.DODGE]:
		return input
	if hero.state == Fighter.State.GUARD and zone.tick_count < _guard_until:
		input.guard = true
		return input
	_decide(zone, _foes(zone), input)
	return _unstuck(zone, input)


## Fills `input` for a hero who can act, highest priority first.
func _decide(zone: ZoneSim, foes: Array[Fighter], input: FighterInput) -> void:
	var danger := _danger(zone, foes)
	if _evade(zone, input):
		status = STATUS_EVADE
	elif zone.hero.state == Fighter.State.ATTACK:
		status = STATUS_FIGHT
		# Nothing more queued while a blow that must be dodged is coming, so
		# the hero is free to move the moment this one ends.
		if danger.is_empty() or not _must_evade(danger["foe"]):
			_follow_up(zone, foes, input)
	elif not danger.is_empty() and _defend(zone, danger, input):
		status = STATUS_EVADE
	else:
		var target := _choose_target(zone, foes)
		if target and _fight(zone, foes, target, input):
			status = STATUS_FIGHT
		else:
			_between_fights(zone, foes, input)


## True when `profile` carries anything to eat.
func has_heals(profile: PlayerProfile) -> bool:
	return FoodRules.carried(profile, _content) > 0


## The food to eat now (see FoodRules): below `heal_below` only, the biggest
## one when health is under half of that. "" for none.
func _pick_heal(zone: ZoneSim) -> String:
	var hero := zone.hero
	var share := float(hero.hp) / maxf(1.0, hero.max_hp)
	if zone.item_cooldown > 0 or share >= heal_below:
		return ""
	var urgent := share < heal_below * 0.5
	return FoodRules.choose(zone.profile, _content, hero.max_hp - hero.hp, urgent)


## Foes still standing.
func _foes(zone: ZoneSim) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for enemy in zone.enemies():
		if not enemy.is_ko() and zone.brains.has(enemy.id):
			out.append(enemy)
	return out


## Out of a hazard's shadow, or out of the lane of something flying this way.
func _evade(zone: ZoneSim, input: FighterInput) -> bool:
	var hero := zone.hero
	if hero.state != Fighter.State.IDLE:
		return false
	for drop: Dictionary in zone.hazards:
		var at: Vector2 = drop["at"]
		var half: Vector2 = drop["half"] + Vector2(10.0, 6.0)
		var gap := hero.position - at
		if absf(gap.x) > half.x or absf(gap.y) > half.y:
			continue
		var away := signf(gap.x)
		if away == 0.0:
			away = 1.0 if at.x < zone.arena.get_center().x else -1.0
		if int(drop["ticks"]) <= 12 and hero.energy >= CombatRules.DODGE_COST:
			# Too late to walk out: roll, invulnerable as it lands.
			input.face = int(away)
			input.dodge = true
		else:
			input.move = _escape(zone, gap, half, away)
		return true
	for entry: Dictionary in zone.thrown:
		if int(entry["team"]) == hero.team:
			continue
		var at: Vector2 = entry["position"]
		var ahead := (hero.position.x - at.x) * float(entry["dir"])
		var lane := hero.position.y - at.y
		if ahead > 0.0 and ahead < PROJECTILE_RANGE and absf(lane) <= PROJECTILE_LANE:
			if ahead < PROJECTILE_GUARD:
				# Too close to step aside: block it, facing the throw.
				input.face = -int(entry["dir"])
				input.guard = true
				_guard_until = zone.tick_count + int(ahead / ZoneSim.THROW_SPEED) + 4
				return true
			var side := signf(lane)
			if side == 0.0:
				side = 1.0 if hero.position.y < zone.arena.get_center().y else -1.0
			input.move = Vector2(0.0, side)
			return true
	return false


## The quicker way out of a hazard's footprint (`gap` from its centre to the
## hero, `half` its half size): along the street, or up or down the lane
## when it spans the street (a laser) and the lane has room.
func _escape(zone: ZoneSim, gap: Vector2, half: Vector2, away: float) -> Vector2:
	var hero := zone.hero
	var along := (half.x - absf(gap.x)) / LaneMovement.WALK_SPEED_X
	var up := signf(gap.y)
	if up == 0.0:
		up = 1.0 if hero.position.y < zone.arena.get_center().y else -1.0
	var edge := zone.arena.end.y if up > 0.0 else zone.arena.position.y
	var target := hero.position.y + up * (half.y - absf(gap.y) + 2.0)
	if (edge - target) * up < 0.0:
		up = -up
		target = hero.position.y + up * (half.y + absf(gap.y) + 2.0)
	var across := absf(target - hero.position.y) / LaneMovement.WALK_SPEED_Y
	if across < along:
		return Vector2(0.0, up)
	return Vector2(away, signf(gap.y) * 0.5)


## The soonest wind-up that will reach the hero: {"foe", "ticks"} (ticks
## until it lands, negative while it is live), or {} when none.
func _danger(zone: ZoneSim, foes: Array[Fighter]) -> Dictionary:
	var found := {}
	for foe in foes:
		if foe.state != Fighter.State.ATTACK or foe.move == null:
			continue
		var left := foe.move.startup - foe.state_tick
		if left < -foe.move.active or not _threatens(foe, zone.hero):
			continue
		if found.is_empty() or left < int(found["ticks"]):
			found = {"foe": foe, "ticks": left}
	return found


## Blows guard cannot stop well: guard breakers and telegraphed heavies.
func _must_evade(foe: Fighter) -> bool:
	return foe.move != null and (foe.move.guard_break or foe.move.telegraph)


## Foes a jab will not interrupt: bosses, elites and anything with poise.
func _tough(foe: Fighter) -> bool:
	var data := _content.enemy(foe.kind)
	return (
		bool(data.get("boss", false))
		or bool(data.get("elite", false))
		or foe.poise_limit > 0
		or CombatRules.is_unflinching(foe)
	)


## Answers `danger`: step out of reach or dodge what must be evaded, hit first
## when the hero's jab is quicker, or guard just before it lands (a perfect
## guard parries). True if it acted.
func _defend(zone: ZoneSim, danger: Dictionary, input: FighterInput) -> bool:
	var hero := zone.hero
	var threat: Fighter = danger["foe"]
	var soonest := int(danger["ticks"])
	var away := -signi(threat.position.x - hero.position.x)
	if away == 0:
		away = threat.facing
	if _must_evade(threat):
		if soonest <= 10 and hero.energy >= CombatRules.DODGE_COST:
			input.face = away
			input.dodge = true
		else:
			# Plenty of warning (or no energy): walk out of its reach.
			input.move = Vector2(away, 0.0)
		return true
	var jab := _light_move(zone)
	if not _tough(threat) and jab and soonest > jab.startup + 1:
		if _reaches(hero, jab, threat, -away):
			input.face = -away
			input.light = true
			return true
	if soonest > maxi(2, hero.parry_window - 2):
		return false
	input.face = -away
	input.guard = true
	_guard_until = zone.tick_count + maxi(0, soonest) + threat.move.active + 2
	return true


## True when `foe`'s current attack can reach `hero` (lunges included).
func _threatens(foe: Fighter, hero: Fighter) -> bool:
	var move := foe.move
	var ahead := (hero.position.x - foe.position.x) * foe.facing
	var far := move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH
	var depth := absf(hero.position.y - foe.position.y)
	return ahead >= near and ahead <= far + THREAT_MARGIN and depth <= move.depth_tolerance + 4.0


## Mid-attack: queue the next link only on a landed hit (or a skill to cancel
## into), so it never swings at empty air.
func _follow_up(zone: ZoneSim, foes: Array[Fighter], input: FighterInput) -> void:
	var hero := zone.hero
	status = STATUS_FIGHT
	if not hero.hit_landed:
		return
	var target := zone.fighter(_target_id)
	if target == null or target.is_ko():
		target = _choose_target(zone, foes)
	if target == null:
		return
	var skill := _pick_skill(zone, foes, target)
	if skill:
		input.skill = skill
		return
	var heavy := _content.moves.get_move(CombatRules.starter(hero, _content.moves, "heavy"))
	var finisher := hero.move.chains.has("heavy") and hero.weapon == ""
	if finisher and heavy and hero.energy >= heavy.energy_cost + ENERGY_RESERVE:
		input.heavy = true
	elif hero.move.chains.has("light"):
		input.light = true


## The foe to go for: close, hurt, and a thrower left alone counts as close.
## Keeps its current target unless another is clearly better.
func _choose_target(zone: ZoneSim, foes: Array[Fighter]) -> Fighter:
	var hero := zone.hero
	var best: Fighter = null
	var best_score := INF
	var current_score := INF
	var melee_near := false
	for foe in foes:
		if _content.enemy(foe.kind).get("ranged", {}).is_empty():
			melee_near = melee_near or hero.position.distance_to(foe.position) < 60.0
	for foe in foes:
		var gap := foe.position - hero.position
		var score := absf(gap.x) + absf(gap.y) * 2.0
		score -= (1.0 - float(foe.hp) / maxf(1.0, foe.max_hp)) * 40.0
		if not _content.enemy(foe.kind).get("ranged", {}).is_empty() and not melee_near:
			score -= 40.0
		if not CombatRules.is_vulnerable(foe):
			score += 60.0
		if foe.id == _target_id:
			current_score = score
		if score < best_score:
			best_score = score
			best = foe
	if current_score < best_score + 30.0:
		return zone.fighter(_target_id)
	_target_id = best.id if best else 0
	return best


## Closes in on `target` and attacks: a skill if one is worth it, else a jab.
## Returns false when there is nothing to fight here and now.
func _fight(zone: ZoneSim, foes: Array[Fighter], target: Fighter, input: FighterInput) -> bool:
	var hero := zone.hero
	if not zone.in_encounter() and hero.position.distance_to(target.position) > 160.0:
		return false
	var dir := signi(target.position.x - hero.position.x)
	if dir == 0:
		dir = hero.facing
	var skill := _pick_skill(zone, foes, target)
	if skill:
		input.face = _skill_facing(zone, foes, target, skill)
		input.skill = skill
		return true
	var jab := _light_move(zone)
	if jab == null:
		return false
	if CombatRules.is_vulnerable(target) and _reaches(hero, jab, target, dir):
		input.face = dir
		input.light = true
		return true
	# Step to a spot just inside reach, level with the target: on the near
	# side unless street furniture stands there.
	var gap := clampf(jab.reach_offset + jab.reach * 0.6, 14.0, 40.0)
	var spot := Vector2.INF
	for side: int in [dir, -dir]:
		var at := LaneMovement.clamp_to(
			Vector2(target.position.x - side * gap, target.position.y), zone.arena
		)
		if _free(zone, at):
			spot = at
			break
	if spot == Vector2.INF:
		spot = target.position
	if spot.distance_to(hero.position) > 2.0:
		input.move = _steer(zone, spot)
	else:
		input.face = dir
	return true


## The best skill to start now against `target` and the foes around, or "".
func _pick_skill(zone: ZoneSim, foes: Array[Fighter], target: Fighter) -> String:
	var hero := zone.hero
	var best := ""
	var best_score := 0.0
	var ids: Array = hero.skills.keys()
	ids.sort()
	for skill_id: String in ids:
		if hero.cooldown_left(skill_id) > 0:
			continue
		var skill: Dictionary = hero.skills[skill_id]
		var move := _content.moves.get_move(str(skill["move"]))
		if move == null:
			continue
		var facing := _skill_facing(zone, foes, target, skill_id)
		var hits := 0
		var weight := 0.0
		for foe in foes:
			if CombatRules.is_vulnerable(foe) and _reaches(hero, move, foe, facing):
				hits += 1
				var data := _content.enemy(foe.kind)
				weight += 1.0
				weight += 2.0 if data.get("boss", false) else 0.0
				weight += 1.0 if data.get("elite", false) else 0.0
				if move.guard_break and foe.state == Fighter.State.GUARD:
					weight += 1.0
		if hits == 0:
			continue
		var reserve := 0.0 if hits >= 3 else ENERGY_RESERVE
		if hero.energy < move.energy_cost + reserve:
			continue
		if int(skill["cooldown"]) >= BIG_SKILL_COOLDOWN and weight < 3.0:
			continue
		var score := weight * move.damage
		if score > best_score:
			best_score = score
			best = skill_id
	return best


## Which way to face for skill `skill_id`: towards the target, unless the
## skill also reaches behind and more foes stand the other way.
func _skill_facing(zone: ZoneSim, foes: Array[Fighter], target: Fighter, skill_id: String) -> int:
	var hero := zone.hero
	var dir := signi(target.position.x - hero.position.x)
	if dir == 0:
		dir = hero.facing
	var move := _content.moves.get_move(str(hero.skills[skill_id]["move"]))
	if move == null or move.reach_offset >= 0.0:
		return dir
	var ahead := 0
	var behind := 0
	for foe in foes:
		if _reaches(hero, move, foe, dir):
			ahead += 1
		if _reaches(hero, move, foe, -dir):
			behind += 1
	return -dir if behind > ahead else dir


## True when `move`, started now facing `facing`, would reach `foe`.
func _reaches(hero: Fighter, move: MoveData, foe: Fighter, facing: int) -> bool:
	var ahead := (foe.position.x - hero.position.x) * facing
	var near := move.reach_offset - CombatRules.HURT_HALF_WIDTH
	var far := move.reach_offset + move.reach + move.advance + CombatRules.HURT_HALF_WIDTH - 4.0
	var depth := absf(foe.position.y - hero.position.y)
	return ahead >= near and ahead <= far and depth <= move.depth_tolerance * 0.8


func _light_move(zone: ZoneSim) -> MoveData:
	return _content.moves.get_move(CombatRules.starter(zone.hero, _content.moves, "light"))


## No fight within reach: a weapon, then drops, then the next fight.
func _between_fights(zone: ZoneSim, foes: Array[Fighter], input: FighterInput) -> void:
	var hero := zone.hero
	var nearest_foe := INF
	for foe in foes:
		nearest_foe = minf(nearest_foe, hero.position.distance_to(foe.position))
	var safe := nearest_foe > SAFE_DISTANCE
	if safe and hero.weapon == "":
		var weapon := _nearest(zone, _weapon_spots(zone), WEAPON_RANGE)
		if weapon != Vector2.INF:
			status = STATUS_WEAPON
			if zone.weapon_in_reach(hero.position) >= 0:
				input.pick = true
			else:
				_chase(zone, weapon)
				input.move = _steer(zone, weapon)
			return
	if safe:
		var spots: Array[Vector2] = []
		for pickup: Dictionary in zone.pickups:
			spots.append(pickup["position"])
		var drop := _nearest(zone, spots, INF)
		if drop != Vector2.INF:
			status = STATUS_LOOT
			_chase(zone, drop)
			input.move = _steer(zone, drop)
			return
	if zone.in_encounter():
		# Between waves: wait mid-arena for the next one.
		status = STATUS_FIGHT
		var middle := zone.arena.get_center()
		if absf(middle.x - hero.position.x) > 24.0:
			input.move = Vector2(signf(middle.x - hero.position.x), 0.0)
		return
	var next := _next_fight_x(zone)
	if next == INF:
		status = STATUS_CLEAR
		return
	status = STATUS_ADVANCE
	var goal := Vector2(minf(next + 24.0, zone.bounds.end.x - 30.0), zone.bounds.get_center().y)
	input.move = _steer(zone, Vector2(goal.x, hero.position.y + (goal.y - hero.position.y) * 0.3))


## Where the next fight not won yet starts (its trigger line), or INF.
func _next_fight_x(zone: ZoneSim) -> float:
	var nearest := INF
	var encounters: Array = zone.area.get("encounters", [])
	for i in encounters.size():
		if not StreetMemory.is_cleared(zone.profile, zone.area_id, i):
			nearest = minf(nearest, float(encounters[i]["trigger_x"]))
	return nearest


func _weapon_spots(zone: ZoneSim) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for entry: Dictionary in zone.ground_weapons:
		out.append(entry["position"])
	return out


## The closest of `spots` inside the fight's bounds and within `range`.
func _nearest(zone: ZoneSim, spots: Array[Vector2], within: float) -> Vector2:
	var best := Vector2.INF
	var best_distance := within
	for at in spots:
		if not zone.arena.grow(1.0).has_point(at) or at in _skipped:
			continue
		var distance := zone.hero.position.distance_to(at)
		if distance <= best_distance:
			best_distance = distance
			best = at
	return best


## Walking but not getting anywhere (a parked car, a crowd): step up or down
## the lane for a moment, the other way each time.
func _unstuck(zone: ZoneSim, input: FighterInput) -> FighterInput:
	var hero := zone.hero
	if input.move == Vector2.ZERO or hero.state != Fighter.State.IDLE:
		_still = 0
		_last_position = hero.position
		return input
	if _sidestep > 0:
		_sidestep -= 1
		input.move = (input.move * 0.3 + _sidestep_dir).normalized()
		_last_position = hero.position
		return input
	if _last_position != Vector2.INF and hero.position.distance_to(_last_position) < 0.2:
		_still += 1
	else:
		_still = 0
	_last_position = hero.position
	if _still >= STUCK_TICKS:
		_still = 0
		_sidestep = SIDESTEP_TICKS
		if absf(input.move.x) >= absf(input.move.y):
			var room_below := zone.arena.end.y - hero.position.y
			var room_above := hero.position.y - zone.arena.position.y
			_sidestep_dir = Vector2.DOWN if room_below >= room_above else Vector2.UP
		else:
			var room_right := zone.arena.end.x - hero.position.x
			var room_left := hero.position.x - zone.arena.position.x
			_sidestep_dir = Vector2.RIGHT if room_right >= room_left else Vector2.LEFT
	return input


## Walks towards `goal`, around any street furniture in the way: past it on
## the side the hero is on, or, pinned against the lane's edge, back and
## round the other side.
func _steer(zone: ZoneSim, goal: Vector2) -> Vector2:
	var hero := zone.hero
	var to := goal - hero.position
	if to.length() < 1.0:
		return Vector2.ZERO
	var dir := to.normalized()
	var block := Bodies.blocker(
		hero.position, hero.position + dir * 6.0, Bodies.PERSON, zone.solids
	)
	if block.is_empty():
		return dir
	var centre: Vector2 = block["position"]
	var half: Vector2 = block["half"]
	if absf(dir.x) >= absf(dir.y):
		# Pass on the side the hero is already on; with no room there (the
		# lane's edge), back off and go round the far side instead.
		var side := signf(hero.position.y - centre.y)
		if side == 0.0:
			side = signf(goal.y - centre.y) if goal.y != centre.y else 1.0
		var room := (
			zone.arena.end.y - (centre.y + half.y)
			if side > 0.0
			else (centre.y - half.y) - zone.arena.position.y
		)
		if room < Bodies.PERSON.y * 2.0 + 1.0:
			return Vector2(-signf(dir.x), -side * 0.7).normalized()
		return Vector2(dir.x * 0.2, side).normalized()
	var across := signf(goal.x - centre.x)
	if across == 0.0:
		across = signf(hero.position.x - centre.x)
	if across == 0.0:
		across = 1.0
	return Vector2(across, dir.y * 0.2).normalized()


## True when a person could stand at `at` without overlapping street furniture.
func _free(zone: ZoneSim, at: Vector2) -> bool:
	for solid: Dictionary in zone.solids:
		if Bodies.gap(at, Bodies.PERSON, solid) < 1.0:
			return false
	return true


## Going for one spot: after CHASE_TICKS without getting any closer (it lies
## somewhere the hero cannot stand), it is skipped for this zone.
func _chase(zone: ZoneSim, at: Vector2) -> void:
	var distance := zone.hero.position.distance_to(at)
	if at != _chasing or distance < _chase_best - 1.0:
		_chasing = at
		_chase_best = distance
		_chase_ticks = 0
		return
	_chase_ticks += 1
	if _chase_ticks > CHASE_TICKS:
		_skipped.append(at)
		_chasing = Vector2.INF
