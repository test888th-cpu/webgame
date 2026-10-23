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

## Pixels the fist travels out during an attack's active ticks (polygon art).
const ARM_REACH := 14.0
const HIT_FLASH_TICKS := 6
## Ticks over which the knock-down animation plays before holding its last frame.
const DOWN_TICKS := 30

@export var body_color := Color(0.86, 0.42, 0.2)
@export var show_health_bar := false

var fighter: Fighter
var art_id := ""

var _sprite: AnimatedSprite2D
var _last_position := Vector2.INF

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


## Configures the view for an enemy from its enemies.json entry.
func setup_enemy(data: Dictionary, art: Dictionary) -> void:
	body_color = Color.from_string(str(data.get("color", "#777777")), Color.GRAY)
	_torso.color = body_color
	scale = Vector2.ONE * float(data.get("scale", 1.0))
	# Bosses get the big HUD bar instead of a small one overhead.
	show_health_bar = not data.get("boss", false)
	_health.visible = show_health_bar
	if data.get("elite", false) or data.get("boss", false):
		_name.text = str(data.get("name", ""))
		_name.visible = true
	if data.has("sprite"):
		set_art(str(data["sprite"]), art)


## Switches to an imported character asset (or back to polygons with "").
func set_art(id: String, art: Dictionary) -> void:
	if id == art_id:
		return
	art_id = id
	var entry: Dictionary = art.get(id, {})
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
		_animate_sprite(moved)
	else:
		_pose_polygons()
	if show_health_bar:
		_health_fill.size.x = 24.0 * fighter.hp / fighter.max_hp


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
