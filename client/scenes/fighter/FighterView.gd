class_name FighterView
extends Node2D
## Draws one Fighter from the simulation. Holds no gameplay state of its own:
## `sync` copies position and pose from the Fighter every frame, so the same
## view works for the local hero, remote players, enemies and NPCs.
##
## With art assigned (`set_art`), an AnimatedSprite2D plays the asset's
## animations, chosen from the fighter's state. Attack and hit animations are
## stepped by simulation ticks rather than by wall-clock time, so a swing's
## frames line up exactly with its startup, active and recovery ticks. Without
## art, a simple polygon figure is drawn instead.
##
## A held weapon is drawn in the fighter's hand: the art's per-frame hand
## sockets (from the sprite builder) place and turn it with every frame, and
## the hand itself is drawn again over it so the fist closes on the handle.

## Pixels the fist travels out during an attack's active ticks (polygon art).
const ARM_REACH := 14.0
const HIT_FLASH_TICKS := 6
## Ticks over which the knock-down animation plays before holding its last frame.
const DOWN_TICKS := 30
## What art without an animation plays instead (the rest fall back to idle).
const FALLBACK := {
	"swing": "light", "grab": "light", "throw": "heavy", "lift": "idle", "stance": "idle"
}
## Ticks over which a holder raises the foe they grabbed (the rules' own).
const LIFT_TICKS := GrabRules.LIFT_TICKS
## How much a holder bobs as they take their step forward with the foe.
const STEP_BOB := 2.0
## How a held body is drawn for each GrabRules pose, and thrown from there
## (GrabRules.AIR_TICKS in the air). It is always the fighter seen from the
## side (BODY_FRAME), never turned to the camera, and turns about its feet:
## * "rise": how high its feet are lifted; "reach": how far towards the
##   holder they sit (the body stands GrabRules.HOLD_GAP in front);
## * "turn": its rotation, times its facing (a quarter turn lays it flat with
##   its head towards the holder, minus a quarter away; a half turn hangs it
##   upside down from its feet);
## * "loft": the little lift as it leaves the hands before it falls ever
##   faster; "lie": how it ends up on the street (1: face down, head towards
##   the thrower; -1: on its back, head away);
## * "land" and "hop": a piledriver's feet height on impact, and how high the
##   thrower jumps with it.
## overhead (the shoulder toss, every job's grab): face to face, hands at the
## foe's waist (the grab frames), lifted across the shoulders head to the back
## (lift), a step forward, tossed forward (throw) flat as it was carried, to
## land face down, head towards the thrower. body_slam:
## lifted to the chest and slammed down ahead. piledriver: upside down against
## the holder's chest; the holder jumps and drives it head first into the street.
const POSES := {
	"overhead": {"rise": 44.0, "reach": -8.0, "turn": PI / 2, "loft": 10.0, "lie": 1.0},
	"body_slam": {"rise": 26.0, "reach": 18.0, "turn": -PI / 2, "loft": 6.0, "lie": -1.0},
	"piledriver": {"rise": 52.0, "reach": 8.0, "turn": PI, "land": 46.0, "hop": 14.0, "lie": 1.0},
}
## The side-on frame a carried, thrown or slammed body is drawn with.
const BODY_FRAME := "idle"
## A slammed body lies flat as its pose's "lie" says: its feet this far from
## where it fell and its middle this high, so it rests on the street centred
## there. It gets up over its last GET_UP_TICKS.
const LIE_REACH := 22.0
const LIE_HEIGHT := 8.0
const GET_UP_TICKS := 14
## Half a body's length (feet to the top of the head), and how far a tossed
## body's middle runs out ahead of where it will land on the way.
const BODY_HALF := 23.0
const LEAD := 14.0
const FLASH_SHADER := preload("res://scenes/fighter/flash.gdshader")
## The shadow under a fighter, in game pixels (scaled with a big one).
const SHADOW_WIDTH := 24.0
## Where a weapon sits without hand sockets (polygon figure), facing right.
const FALLBACK_HAND := Vector2(10, -24)
const FALLBACK_ANGLE := 35.0

@export var body_color := Color(0.86, 0.42, 0.2)
@export var show_health_bar := false

## The area's light on this fighter (ZoneView, from the street kit's tint):
## the sprite shader multiplies it in.
var ambient := Color.WHITE
## The enemy's own colour over its sprite (enemies.json "tint"; white: none).
var tint := Color.WHITE

var fighter: Fighter
var art_id := ""
## Weapon sprites come from here; without it no weapon is drawn.
var content: ContentDB
## The level shown over an enemy (0 for the hero and training dummies).
var enemy_level := 0

var _sprite: AnimatedSprite2D
var _last_position := Vector2.INF
## Impact feedback (presentation only): a colour flash fading out, and a
## short freeze of the sprite's pose with a shiver.
var _flash := 0.0
var _flash_color := Color.WHITE
var _freeze := 0.0
## Where the sprite sits on this view (raised while the fighter is held).
var _home := Vector2.ZERO
var _hands := {}
## The art's frame size (LPC sheets are 64x64; custom art may be larger).
var _frame := Vector2(64, 64)
var _rows := {}
## Animation -> [first, last] frame in which the blow lands (manifest).
var _contact := {}
var _hand_sheet: Texture2D
var _held: Sprite2D
var _cast: AnimatedSprite2D
var _fist: Sprite2D
var _held_id := ""
var _threat := ""
## The rank icon left of the overhead name: the map's own symbols, so a skull
## means a boss and horns a mini-boss everywhere; a star for a field elite.
var _badge: TextureRect

@onready var _body: Node2D = $Body
@onready var _torso: Polygon2D = $Body/Torso
@onready var _arm: Polygon2D = $Body/Arm
@onready var _shield: Polygon2D = $Body/Shield
@onready var _health: Node2D = $Health
@onready var _health_fill: ColorRect = $Health/Fill
@onready var _warning: Label = $Warning
@onready var _name: Label = $Name


func _ready() -> void:
	# A soft shadow on the street under the feet, first so all else is above.
	# The contact shadow: the cast shadow (Shade.cast) follows with the art.
	var shadow := Shade.make(SHADOW_WIDTH, 0.3, 0.6)
	shadow.name = "Shadow"
	shadow.position = Vector2(0, 1)
	add_child(shadow)
	move_child(shadow, 0)
	_torso.color = body_color
	_health.visible = show_health_bar


## Configures the view for an enemy from its enemies.json entry, fighting at
## `level` (shown over its head; 0 hides it).
## Colours the name by how this enemy compares with a hero at `hero_level`.
func show_threat(hero_level: int) -> void:
	# A farming ground's elite keeps its gold name (mark_elite), and a boss or
	# mini-boss its rank colour.
	if enemy_level <= 0 or fighter.elite or _badge:
		return
	var threat := LevelRules.threat(enemy_level, hero_level)
	if threat != _threat:
		_threat = threat
		_name.add_theme_color_override("font_color", UiTheme.THREAT[threat])


func setup_enemy(data: Dictionary, art: Dictionary, level := 0) -> void:
	body_color = Color.from_string(str(data.get("color", "#777777")), Color.GRAY)
	tint = Color.from_string(str(data.get("tint", "#ffffff")), Color.WHITE)
	if _sprite:
		_sprite.material.set_shader_parameter("tint", tint)
	_torso.color = body_color
	scale = Vector2.ONE * float(data.get("scale", 1.0))
	# Bosses get the big HUD bar instead of a small one overhead.
	show_health_bar = not data.get("boss", false)
	_health.visible = show_health_bar
	enemy_level = level if not data.get("training", false) else 0
	var tag := "Lv %d" % enemy_level if enemy_level > 0 else ""
	if data.get("boss", false):
		# The boss bar has its level; overhead, the skull and its name show
		# which one it is in a crowd.
		_rank(str(data.get("name", "")), "map_boss", UiTheme.DANGER)
	elif data.get("elite", false):
		var named := str(data.get("name", "")) + ("  " + tag if tag else "")
		_rank(named, "map_mini_boss", UiTheme.ACCENT)
	elif tag:
		_name.text = tag
		_name.visible = true
	if data.has("sprite"):
		set_art(str(data["sprite"]), art)


## A boss that waits before a district's end (MapRules.MINI_BOSS): the map's
## mini-boss mark and "Mini-boss" overhead, in the accent colour, not the skull.
func mark_mini_boss(data: Dictionary) -> void:
	_rank("Mini-boss %s" % data.get("name", ""), "map_mini_boss", UiTheme.ACCENT)


## A farming ground's elite (FarmSpawner): its name and level overhead, in gold.
func mark_elite(data: Dictionary) -> void:
	var tag := "  Lv %d" % enemy_level if enemy_level > 0 else ""
	_rank("Elite %s%s" % [data.get("name", ""), tag], "star", UiTheme.GOLD)


## Shows `text` overhead in `color`, with icon `icon_id` just left of it.
func _rank(text: String, icon_id: String, color: Color) -> void:
	_name.text = text
	_name.add_theme_color_override("font_color", color)
	_name.visible = true
	if _badge == null:
		_badge = TextureRect.new()
		_badge.name = "Rank"
		_badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_badge.size = Vector2(8, 8)
		add_child(_badge)
	_badge.texture = UiKit.icon(GameSession.content, icon_id)
	var font := _name.get_theme_font("font")
	var size := _name.get_theme_font_size("font_size")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var middle := (_name.offset_left + _name.offset_right) / 2.0
	_badge.position = Vector2(middle - width / 2.0 - 10.0, _name.offset_top + 1.0)


## Switches to an imported character asset (or back to polygons with "").
func set_art(id: String, art: Dictionary) -> void:
	if id == art_id:
		return
	art_id = id
	var entry: Dictionary = art.get(id, {})
	_hands = entry.get("hands", {})
	var frame_size: Array = entry.get("frame_size", [64, 64])
	_frame = Vector2(frame_size[0], frame_size[1])
	_rows = {}
	_contact = {}
	for anim: String in entry.get("animations", {}):
		_rows[anim] = int(entry["animations"][anim]["row"])
		if entry["animations"][anim].has("contact"):
			_contact[anim] = entry["animations"][anim]["contact"]
	var hand_path := str(entry.get("hand_sheet", ""))
	_hand_sheet = load(hand_path) if hand_path and ResourceLoader.exists(hand_path) else null
	if entry.get("status") != "imported":
		if _sprite:
			_sprite.queue_free()
			_sprite = null
		_body.visible = true
		return
	if _sprite == null:
		_sprite = AnimatedSprite2D.new()
		_sprite.name = "Sprite"
		_sprite.centered = false
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.material = ShaderMaterial.new()
		_sprite.material.shader = FLASH_SHADER
		_sprite.material.set_shader_parameter("ambient", ambient)
		_sprite.material.set_shader_parameter("tint", tint)
		add_child(_sprite)
		move_child(_sprite, 1)  # above the shadow, below labels
	var sheet := str(entry["sheet"])
	_sprite.sprite_frames = load(sheet.get_base_dir().path_join(id + ".tres"))
	var origin: Array = entry.get("origin", [32, 62])
	_sprite.offset = -Vector2(origin[0], origin[1])
	_make_cast(Vector2(origin[0], origin[1]))
	# The polygon figure stays only for the guard shield and the attack warning.
	for part in _body.get_children():
		part.visible = part == _shield
	_play("idle")


## Flashes the sprite `color` (fading over `seconds`) and holds its pose for
## `freeze` seconds: the weight of a landed blow.
func impact(color: Color, seconds := 0.12, freeze := 0.0) -> void:
	_flash_color = color
	_flash = seconds
	_freeze = maxf(_freeze, freeze)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_freeze = maxf(0.0, _freeze - delta)
	if _cast and _sprite:
		_cast.animation = _sprite.animation
		_cast.frame = _sprite.frame
		_cast.flip_h = _sprite.flip_h
		_cast.visible = _sprite.visible
		_cast.modulate.a = Shade.CAST_ALPHA * _sprite.modulate.a * modulate.a
	if _sprite:
		var material := _sprite.material as ShaderMaterial
		material.set_shader_parameter("flash", clampf(_flash / 0.12, 0.0, 0.85))
		material.set_shader_parameter("flash_color", _flash_color)
		_sprite.position.x = _home.x + (randf_range(-1.5, 1.5) if _freeze > 0.0 else 0.0)


## The fighter's cast shadow (Shade): its own frames, flipped onto the street
## at its feet (`origin`: the feet in a frame), squashed and slanted away from
## the light; it follows the sprite's frame in _process.
func _make_cast(origin: Vector2) -> void:
	if _cast == null:
		_cast = AnimatedSprite2D.new()
		_cast.name = "Cast"
		_cast.centered = false
		_cast.flip_v = true
		_cast.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_cast.self_modulate = Color(0, 0, 0)
		_cast.scale = Vector2(1, Shade.CAST_SQUASH)
		_cast.skew = Shade.CAST_SKEW
		add_child(_cast)
		move_child(_cast, 1)  # over the contact shadow, under the sprite
	_cast.sprite_frames = _sprite.sprite_frames
	var anim := _sprite.animation
	var tall := 64
	if _cast.sprite_frames.has_animation(anim) and _cast.sprite_frames.get_frame_count(anim) > 0:
		tall = _cast.sprite_frames.get_frame_texture(anim, 0).get_height()
	# Flipped, the frame's feet row lands on y 0, its head furthest out.
	_cast.offset = Vector2(-origin.x, origin.y + 1.0 - tall)


func sync() -> void:
	if fighter == null:
		return
	var moved := (
		_last_position != Vector2.INF and fighter.position.distance_to(_last_position) > 0.05
	)
	_last_position = fighter.position
	position = fighter.position
	_body.scale.x = fighter.facing
	_body.rotation = 0.0
	_body.modulate = Color.WHITE
	_arm.visible = false
	_shield.visible = false
	_warning.visible = false
	if _sprite:
		_sprite.flip_h = fighter.facing < 0
		_sprite.modulate = Color.WHITE
		_sprite.rotation = 0.0
		_home = Vector2.ZERO
		_sprite.position = _home
		if _freeze <= 0.0:
			_animate_sprite(moved)
		if fighter.hop > 0:
			# The thrower's jump into a piledriver.
			var t := 1.0 - float(fighter.hop) / GrabRules.AIR_TICKS
			_home.y -= hop_height(POSES[GrabRules.PILEDRIVER], t)
			_sprite.position = _home
	else:
		_pose_polygons()
	# A warm sheen while poise armor holds: blows will not stop this one.
	if fighter.armor > 0 and fighter.armor % 10 < 6:
		_body.modulate = Color(1.25, 1.1, 0.8)
		if _sprite:
			_sprite.modulate = Color(1.25, 1.1, 0.8)
	# Blink through the wake-up grace so the player can see they are safe.
	if fighter.grace > 0 and fighter.grace % 8 < 4:
		_body.modulate.a = 0.45
		if _sprite:
			_sprite.modulate.a = 0.45
	if show_health_bar:
		_health_fill.size.x = 24.0 * fighter.hp / fighter.max_hp
	_update_held()


## Draws the held weapon (if any) in the hand of the frame on screen.
func _update_held() -> void:
	if fighter.weapon != _held_id:
		_held_id = fighter.weapon
		_show_weapon(_held_id)
	if _held == null:
		return
	_held.visible = (
		_held.texture != null
		and fighter.state != Fighter.State.DOWN
		and fighter.state != Fighter.State.KO
	)
	_update_fist()
	if not _held.visible:
		return
	var hand := FALLBACK_HAND
	var angle := FALLBACK_ANGLE
	var frames: Array = _hands.get(str(_sprite.animation), []) if _sprite else []
	if not frames.is_empty():
		var socket: Array = frames[clampi(_sprite.frame, 0, frames.size() - 1)]
		hand = Vector2(socket[0], socket[1]) + _sprite.offset + _sprite.position
		angle = float(socket[2])
	var facing := float(fighter.facing)
	if _sprite and facing < 0.0:
		# The sheet is drawn facing right; flipping mirrors it within its frame.
		hand.x = 2.0 * (_sprite.offset.x + _sprite.position.x) + _frame.x - hand.x
	elif not _sprite:
		hand.x *= facing
	_held.position = hand
	_held.rotation_degrees = angle * facing
	_held.flip_h = facing < 0.0


## The hand of the frame on screen, redrawn over the weapon's handle.
func _update_fist() -> void:
	var anim := str(_sprite.animation) if _sprite else ""
	var show := _held.visible and _hand_sheet != null and _rows.has(anim)
	if _fist == null:
		if not show:
			return
		_fist = Sprite2D.new()
		_fist.name = "Fist"
		_fist.centered = false
		_fist.region_enabled = true
		_fist.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_fist)
		move_child(_fist, _held.get_index() + 1)
	_fist.visible = show
	if not show:
		return
	_fist.texture = _hand_sheet
	_fist.material = _sprite.material
	_fist.region_rect = Rect2(Vector2(_sprite.frame, _rows[anim]) * _frame, _frame)
	_fist.offset = _sprite.offset
	_fist.position = _sprite.position
	_fist.flip_h = _sprite.flip_h
	_fist.modulate = _sprite.modulate


func _show_weapon(weapon_id: String) -> void:
	if _held == null:
		_held = Sprite2D.new()
		_held.name = "Weapon"
		_held.centered = false
		_held.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_held)
		move_child(_held, _body.get_index() + 1)  # in front of the body, behind labels
	_held.texture = null
	if weapon_id == "" or content == null:
		return
	var sprite := str(content.weapons.get(weapon_id, {}).get("sprite", ""))
	_held.texture = UiKit.icon(content, sprite)
	var grip: Array = content.ui.get("weapon_grips", {}).get(
		sprite, content.ui.get("weapon_grip", [8, 27])
	)
	_held.offset = -Vector2(grip[0], grip[1])


func _animate_sprite(moved: bool) -> void:
	match fighter.state:
		Fighter.State.ATTACK:
			var move := fighter.move
			_warning.visible = move.telegraph and fighter.state_tick < move.startup
			# The guard shows while a counter stance is open, so it can be read.
			_shield.visible = CounterRules.open(fighter)
			var anim := _pick(move.anim)
			_show(anim)
			var count := _sprite.sprite_frames.get_frame_count(anim)
			var contact: Array = _contact.get(anim, [count / 2, count / 2])
			_sprite.frame = attack_frame(move, fighter.state_tick, count, contact)
		Fighter.State.HITSTUN:
			if fighter.state_tick < HIT_FLASH_TICKS:
				_sprite.modulate = Color(1.8, 0.7, 0.7)
			_set_frame_by_progress(
				"hurt", float(fighter.state_tick) / maxi(1, fighter.state_duration)
			)
		Fighter.State.DOWN, Fighter.State.KO when fighter.airborne > 0:
			_thrown_pose()
		Fighter.State.DOWN when fighter.state_duration >= GrabRules.SLAM_DOWN_TICKS:
			_slammed_pose()
		Fighter.State.DOWN, Fighter.State.KO:
			_set_frame_by_progress("down", float(fighter.state_tick) / DOWN_TICKS)
			if fighter.is_ko():
				_sprite.modulate.a = 0.6
		Fighter.State.DODGE:
			var anim := "dodge" if _has("dodge") else "walk"
			_set_frame_by_progress(anim, float(fighter.state_tick) / CombatRules.DODGE_TICKS)
			if not CombatRules.is_vulnerable(fighter):
				_sprite.modulate.a = 0.5
		Fighter.State.GUARD:
			_set_frame_by_progress("idle", 0.0)
			_shield.visible = true
		Fighter.State.GRAB:
			_set_frame_by_progress("lift", float(fighter.state_tick) / LIFT_TICKS)
			# The step forward before the throw (GrabRules): a heavy stride.
			var stride := float(fighter.state_tick - LIFT_TICKS) / GrabRules.STEP_TICKS
			if stride > 0.0 and stride < 1.0:
				_home.y = -STEP_BOB * sin(PI * stride)
				_sprite.position = _home
		Fighter.State.HELD:
			# Lifted into the pose over LIFT_TICKS (POSES).
			var pose := pose_of(fighter)
			_set_frame_by_progress(BODY_FRAME, 0.0)
			var rise := minf(1.0, float(fighter.state_tick) / LIFT_TICKS)
			_sprite.rotation = float(pose["turn"]) * fighter.facing * rise
			_home = Vector2(fighter.facing * float(pose["reach"]), -float(pose["rise"])) * rise
			_sprite.position = _home
		_:
			_play("walk" if moved and _has("walk") else "idle")


## The POSES entry for `f`'s grab pose (overhead when it has none).
static func pose_of(f: Fighter) -> Dictionary:
	return POSES.get(f.grab_pose, POSES[GrabRules.OVERHEAD])


## How high a jumping thrower is off the street `t` of the way through it.
static func hop_height(pose: Dictionary, t: float) -> float:
	return float(pose.get("hop", 0.0)) * 4.0 * t * (1.0 - t)


## A thrown body in the air: from where HELD carried it down onto the street,
## gathering speed as it falls, so it lands with weight instead of floating
## like a thrown bottle, and ends lying as `_slammed_pose` starts. A
## piledriver rides the thrower's jump, head down.
func _thrown_pose() -> void:
	var pose := pose_of(fighter)
	var t := 1.0 - float(fighter.airborne) / GrabRules.AIR_TICKS
	_set_frame_by_progress(BODY_FRAME, 0.0)
	var facing := float(fighter.facing)
	var rise := float(pose["rise"])
	if pose.has("hop"):
		# A piledriver: straight down with the thrower's jump, head first.
		var land := float(pose["land"])
		var drop := land + (rise - land) * (1.0 - t * t) + hop_height(pose, t)
		_sprite.rotation = float(pose["turn"]) * facing
		_home = Vector2(float(pose["reach"]) * facing * (1.0 - t), -drop)
		_sprite.position = _home
		return
	# The body turns about its middle, which leads out ahead of the thrower
	# (forward is -facing: the thrown body faces back at the thrower) and
	# falls ever faster onto the street; the sprite is drawn from its feet.
	var start_turn := float(pose["turn"]) * facing
	var lie := _lying(pose, fighter.facing)
	var end_turn: float = lie["turn"]
	var turn := lerpf(start_turn, end_turn, t) * (1.0 + 0.1 * sin(PI * t))
	var start_mid := Vector2(float(pose["reach"]) * facing, -rise) + _head(start_turn) * BODY_HALF
	var end_mid: Vector2 = lie["feet"] + _head(end_turn) * BODY_HALF
	var ahead := 1.0 - (1.0 - t) * (1.0 - t)
	var mid := Vector2(lerpf(start_mid.x, end_mid.x, ahead) - facing * LEAD * sin(PI * t), 0.0)
	mid.y = end_mid.y + (start_mid.y - end_mid.y) * (1.0 - t * t)
	mid.y -= float(pose.get("loft", 0.0)) * 4.0 * t * (1.0 - t)
	_sprite.rotation = turn
	_home = mid - _head(turn) * BODY_HALF
	_sprite.position = _home


## How a body of `pose` facing `facing` lies on the street: {"turn", "feet"}.
static func _lying(pose: Dictionary, facing: int) -> Dictionary:
	var lie := float(pose.get("lie", 1.0))
	return {
		"turn": lie * PI / 2 * facing,
		"feet": Vector2(-lie * LIE_REACH * facing, -LIE_HEIGHT),
	}


## The way the head points from the feet for a body turned by `turn`.
static func _head(turn: float) -> Vector2:
	return Vector2(sin(turn), -cos(turn))


## A slammed body lying on the street as its pose lands it, for
## GrabRules.SLAM_DOWN_TICKS; it gets up over the last
## GET_UP_TICKS.
func _slammed_pose() -> void:
	_set_frame_by_progress(BODY_FRAME, 0.0)
	var left := fighter.state_duration - fighter.state_tick
	var lying := clampf(float(left) / GET_UP_TICKS, 0.0, 1.0)
	var lie := _lying(pose_of(fighter), fighter.facing)
	_sprite.rotation = float(lie["turn"]) * lying
	_home = Vector2(lie["feet"]) * lying
	_sprite.position = _home


func _has(anim: String) -> bool:
	return _sprite.sprite_frames.has_animation(anim)


## The frame of a `count`-frame attack animation at `tick` of `move`: the
## wind-up frames play over the start-up, the `contact` frames ([first,
## last]) while the blow can land, the rest over the recovery. So the fist or
## weapon is out at the moment the damage shows, however the move is timed.
static func attack_frame(move: MoveData, tick: int, count: int, contact: Array) -> int:
	var first := clampi(int(contact[0]), 0, count - 1)
	var last := clampi(int(contact[1]), first, count - 1)
	if tick < move.startup:
		return mini(first - 1, floori(float(tick) / move.startup * first)) if first > 0 else 0
	var landed := tick - move.startup
	if landed < move.active:
		var span := last - first + 1
		return first + mini(span - 1, floori(float(landed) / move.active * span))
	var rest := count - 1 - last
	if rest <= 0:
		return last
	var into := float(landed - move.active) / maxi(1, move.recovery)
	return last + 1 + mini(rest - 1, floori(into * rest))


## `anim`, or what stands in for it where this art does not have it.
func _pick(anim: String) -> String:
	if _has(anim):
		return anim
	return FALLBACK.get(anim, "idle") if _has(FALLBACK.get(anim, "idle")) else "idle"


## Holds `anim` (no autoplay); the caller sets the frame.
func _show(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
	_sprite.pause()


## Shows the frame of `anim` at `progress` (0..1) without autoplay.
func _set_frame_by_progress(anim: String, progress: float) -> void:
	anim = _pick(anim)
	_show(anim)
	var count := _sprite.sprite_frames.get_frame_count(anim)
	_sprite.frame = clampi(int(clampf(progress, 0.0, 1.0) * count), 0, count - 1)


func _play(anim: String) -> void:
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


func _pose_polygons() -> void:
	match fighter.state:
		Fighter.State.ATTACK:
			_pose_attack()
		Fighter.State.HITSTUN:
			if fighter.state_tick < HIT_FLASH_TICKS:
				_body.modulate = Color(1.6, 0.6, 0.6)
			_body.rotation = -0.15 * fighter.facing
		Fighter.State.DOWN, Fighter.State.KO:
			_body.rotation = -PI / 2 * fighter.facing
			if fighter.is_ko():
				_body.modulate.a = 0.5
		Fighter.State.DODGE:
			if not CombatRules.is_vulnerable(fighter):
				_body.modulate.a = 0.45
		Fighter.State.GUARD:
			_shield.visible = true
		Fighter.State.HELD:
			_body.rotation = -PI / 2 * fighter.facing


func _pose_attack() -> void:
	var move := fighter.move
	var tick := fighter.state_tick
	_arm.visible = true
	var extension := 0.0
	# Telegraphed attacks show a warning for their whole wind-up.
	_warning.visible = move.telegraph and tick < move.startup
	if move.is_active_tick(tick):
		extension = 1.0
	elif tick >= move.startup + move.active:
		var into_recovery := tick - move.startup - move.active
		extension = 1.0 - float(into_recovery) / maxi(1, move.recovery)
	_arm.position.x = -4.0 + extension * ARM_REACH
