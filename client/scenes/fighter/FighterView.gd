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
const FLASH_SHADER := preload("res://scenes/fighter/flash.gdshader")
## Where a weapon sits without hand sockets (polygon figure), facing right.
const FALLBACK_HAND := Vector2(10, -24)
const FALLBACK_ANGLE := 35.0

@export var body_color := Color(0.86, 0.42, 0.2)
@export var show_health_bar := false

var fighter: Fighter
var art_id := ""
## Weapon sprites come from here; without it no weapon is drawn.
var content: ContentDB

var _sprite: AnimatedSprite2D
var _last_position := Vector2.INF
## Impact feedback (presentation only): a colour flash fading out, and a
## short freeze of the sprite's pose with a shiver.
var _flash := 0.0
var _flash_color := Color.WHITE
var _freeze := 0.0
var _hands := {}
## The art's frame size (LPC sheets are 64x64; custom art may be larger).
var _frame := Vector2(64, 64)
var _rows := {}
var _hand_sheet: Texture2D
var _held: Sprite2D
var _fist: Sprite2D
var _held_id := ""

@onready var _body: Node2D = $Body
@onready var _torso: Polygon2D = $Body/Torso
@onready var _arm: Polygon2D = $Body/Arm
@onready var _shield: Polygon2D = $Body/Shield
@onready var _health: Node2D = $Health
@onready var _health_fill: ColorRect = $Health/Fill
@onready var _warning: Label = $Warning
@onready var _name: Label = $Name


func _ready() -> void:
	_torso.color = body_color
	_health.visible = show_health_bar


## Configures the view for an enemy from its enemies.json entry, fighting at
## `level` (shown over its head; 0 hides it).
func setup_enemy(data: Dictionary, art: Dictionary, level := 0) -> void:
	body_color = Color.from_string(str(data.get("color", "#777777")), Color.GRAY)
	_torso.color = body_color
	scale = Vector2.ONE * float(data.get("scale", 1.0))
	# Bosses get the big HUD bar instead of a small one overhead.
	show_health_bar = not data.get("boss", false)
	_health.visible = show_health_bar
	var tag := "Lv %d" % level if level > 0 and not data.get("training", false) else ""
	if data.get("elite", false) or data.get("boss", false):
		_name.text = str(data.get("name", "")) + ("  " + tag if tag else "")
		_name.visible = true
	elif tag:
		_name.text = tag
		_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.88, 0.85))
		_name.visible = true
	if data.has("sprite"):
		set_art(str(data["sprite"]), art)


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
	for anim: String in entry.get("animations", {}):
		_rows[anim] = int(entry["animations"][anim]["row"])
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
		add_child(_sprite)
		move_child(_sprite, 1)  # above the shadow, below labels
	var sheet := str(entry["sheet"])
	_sprite.sprite_frames = load(sheet.get_base_dir().path_join(id + ".tres"))
	var origin: Array = entry.get("origin", [32, 62])
	_sprite.offset = -Vector2(origin[0], origin[1])
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
	if _sprite:
		var material := _sprite.material as ShaderMaterial
		material.set_shader_parameter("flash", clampf(_flash / 0.12, 0.0, 0.85))
		material.set_shader_parameter("flash_color", _flash_color)
		_sprite.position.x = randf_range(-1.5, 1.5) if _freeze > 0.0 else 0.0


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
		if _freeze <= 0.0:
			_animate_sprite(moved)
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
	var grip: Array = content.ui.get("weapon_grip", [8, 27])
	_held.offset = -Vector2(grip[0], grip[1])


func _animate_sprite(moved: bool) -> void:
	match fighter.state:
		Fighter.State.ATTACK:
			var move := fighter.move
			_warning.visible = move.telegraph and fighter.state_tick < move.startup
			_set_frame_by_progress(move.anim, float(fighter.state_tick) / move.total_ticks())
		Fighter.State.HITSTUN:
			if fighter.state_tick < HIT_FLASH_TICKS:
				_sprite.modulate = Color(1.8, 0.7, 0.7)
			_set_frame_by_progress(
				"hurt", float(fighter.state_tick) / maxi(1, fighter.state_duration)
			)
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
		_:
			_play("walk" if moved and _has("walk") else "idle")


func _has(anim: String) -> bool:
	return _sprite.sprite_frames.has_animation(anim)


## Shows the frame of `anim` at `progress` (0..1) without autoplay.
func _set_frame_by_progress(anim: String, progress: float) -> void:
	if not _has(anim):
		anim = "idle"
	if _sprite.animation != anim:
		_sprite.animation = anim
	_sprite.pause()
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
