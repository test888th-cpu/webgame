class_name Footsteps
extends RefCounted
## Soft footfalls under everyone who walks: the hero's close and clear, a
## monster's quieter and fading out with its distance from the hero, a boss's
## deeper. Presentation only: it reads how far each fighter walked since the
## last frame and never changes the game.

## Pixels walked between two footfalls (about one stride of the walk cycle).
const STRIDE := 24.0
const HERO_DB := -15.0
const ENEMY_DB := -19.0
## A monster's steps fade from NEAR px away from the hero, by FADE_DB at
## HEARD px; past HEARD they are not heard at all.
const NEAR := 80.0
const HEARD := 260.0
const FADE_DB := -14.0
const SILENT := -80.0
## At most one monster footfall this often, so a crowd does not drum.
const ENEMY_GAP_MSEC := 110
## A boss's steps are lower: something heavy is coming.
const BOSS_PITCH := 0.72

## id -> pixels walked since that fighter's last footfall.
var _walked := {}
## id -> where the fighter stood last frame.
var _last := {}
## id -> which foot lands next (0 or 1: step_1 or step_2).
var _foot := {}
var _enemy_at := -ENEMY_GAP_MSEC


## The volume (dB) of a footfall `distance` px from the hero, SILENT when it
## is too far to hear.
static func volume(is_hero: bool, distance: float) -> float:
	if is_hero:
		return HERO_DB
	if distance > HEARD:
		return SILENT
	return ENEMY_DB + FADE_DB * clampf((distance - NEAR) / (HEARD - NEAR), 0.0, 1.0)


## True while `f` is on its feet and free to walk (not hit, knocked back,
## thrown or dodging: those slides make no footfalls).
static func walking(f: Fighter) -> bool:
	return f.state == Fighter.State.IDLE and f.knockback_remaining == 0.0


## Plays the footfalls of this frame. Returns the ids of the fighters heard.
func update(zone: ZoneSim, now_msec: int) -> Array[int]:
	var heard: Array[int] = []
	for f in zone.fighters:
		var was: Vector2 = _last.get(f.id, f.position)
		_last[f.id] = f.position
		if not walking(f):
			# The first stride after standing comes quickly.
			_walked[f.id] = STRIDE * 0.5
			continue
		var total := float(_walked.get(f.id, STRIDE * 0.5)) + f.position.distance_to(was)
		_walked[f.id] = fmod(total, STRIDE) if total >= STRIDE else total
		if total < STRIDE:
			continue
		var is_hero := f.id == ZoneSim.HERO_ID
		var db := volume(is_hero, f.position.distance_to(zone.hero.position))
		if db <= SILENT:
			continue
		if not is_hero:
			if now_msec - _enemy_at < ENEMY_GAP_MSEC:
				continue
			_enemy_at = now_msec
		var foot := int(_foot.get(f.id, 0))
		_foot[f.id] = 1 - foot
		var boss: bool = not is_hero and zone.content.enemy(f.kind).get("boss", false)
		Sfx.step("step_%d" % (foot + 1), db, BOSS_PITCH if boss else 1.0)
		heard.append(f.id)
	if _last.size() > zone.fighters.size():
		_forget(zone)
	return heard


func _forget(zone: ZoneSim) -> void:
	var alive := {}
	for f in zone.fighters:
		alive[f.id] = true
	for table: Dictionary in [_walked, _last, _foot]:
		for id: int in table.keys():
			if not alive.has(id):
				table.erase(id)
