class_name Footsteps
extends RefCounted
## Footfalls under everyone who walks, in step with the feet on screen: a
## fighter drawn with art steps when its walk animation puts a foot down
## (FighterView.footfall: the left foot, then the right); one without art,
## every STRIDE px walked. Recorded steps on stone (step_l1..3, step_r1..3),
## a different take each time. The hero's are close and clear, a monster's
## quieter and fading out with its distance from the hero, a boss's deeper.
## Presentation only: it reads what is on screen and never changes the game.

## Pixels walked between two footfalls without art: half a walk cycle (the
## walk plays 8 frames at 10 fps, two steps a cycle) at the base walk speed.
const STRIDE := LaneMovement.WALK_SPEED_X * 0.4
const TAKES := 3
const HERO_DB := -24.0
const ENEMY_DB := -29.0
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

## id -> pixels walked since that fighter's last footfall (no art).
var _walked := {}
## id -> where the fighter stood last frame.
var _last := {}
## id -> which foot lands next without art ("l" or "r").
var _foot := {}
var _enemy_at := -ENEMY_GAP_MSEC
var _take := 0


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


## Plays the footfalls of this frame. `views` maps fighter id to its
## FighterView (ZoneView's). Returns the ids of the fighters heard.
func update(zone: ZoneSim, now_msec: int, views := {}) -> Array[int]:
	var heard: Array[int] = []
	for f in zone.fighters:
		var view: FighterView = views.get(f.id)
		var foot := view.footfall() if view and view.has_art() else _stride(f)
		if foot == "" or not walking(f):
			continue
		var is_hero := f.id == ZoneSim.HERO_ID
		var db := volume(is_hero, f.position.distance_to(zone.hero.position))
		if db <= SILENT:
			continue
		if not is_hero:
			if now_msec - _enemy_at < ENEMY_GAP_MSEC:
				continue
			_enemy_at = now_msec
		_take = (_take + 1) % TAKES
		var boss: bool = not is_hero and zone.content.enemy(f.kind).get("boss", false)
		Sfx.step("step_%s%d" % [foot, _take + 1], db, BOSS_PITCH if boss else 1.0)
		heard.append(f.id)
	if _last.size() > zone.fighters.size():
		_forget(zone)
	return heard


## Without art: "l" or "r" when `f` has walked another STRIDE, else "".
func _stride(f: Fighter) -> String:
	var was: Vector2 = _last.get(f.id, f.position)
	_last[f.id] = f.position
	if not walking(f):
		# The first stride after standing comes quickly.
		_walked[f.id] = STRIDE * 0.5
		return ""
	var total := float(_walked.get(f.id, STRIDE * 0.5)) + f.position.distance_to(was)
	_walked[f.id] = fmod(total, STRIDE) if total >= STRIDE else total
	if total < STRIDE:
		return ""
	var foot := str(_foot.get(f.id, "l"))
	_foot[f.id] = "r" if foot == "l" else "l"
	return foot


func _forget(zone: ZoneSim) -> void:
	var alive := {}
	for f in zone.fighters:
		alive[f.id] = true
	for table: Dictionary in [_walked, _last, _foot]:
		for id: int in table.keys():
			if not alive.has(id):
				table.erase(id)
