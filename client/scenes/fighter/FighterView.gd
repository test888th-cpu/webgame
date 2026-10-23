class_name FighterView
extends Node2D
## Draws one Fighter from the simulation. Holds no gameplay state of its own:
## `sync` copies position and pose from the Fighter every frame, so the same
## view works for the local hero, remote players and enemies.

## Pixels the fist travels out during an attack's active ticks.
const ARM_REACH := 14.0
const HIT_FLASH_TICKS := 6

@export var body_color := Color(0.86, 0.42, 0.2)
@export var show_health_bar := false

var fighter: Fighter

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
func setup_enemy(data: Dictionary) -> void:
	body_color = Color.from_string(str(data.get("color", "#777777")), Color.GRAY)
	_torso.color = body_color
	scale = Vector2.ONE * float(data.get("scale", 1.0))
	# Bosses get the big HUD bar instead of a small one overhead.
	show_health_bar = not data.get("boss", false)
	_health.visible = show_health_bar
	if data.get("elite", false) or data.get("boss", false):
		_name.text = str(data.get("name", ""))
		_name.visible = true


func sync() -> void:
	if fighter == null:
		return
	position = fighter.position
	_body.scale.x = fighter.facing
	_body.rotation = 0.0
	_body.modulate = Color.WHITE
	_arm.visible = false
	_shield.visible = false
	_warning.visible = false
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
	if show_health_bar:
		_health_fill.size.x = 24.0 * fighter.hp / fighter.max_hp


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
