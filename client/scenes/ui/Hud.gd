extends CanvasLayer
## On-screen interface: build identity, hero HP and energy, status and help.

const BAR_WIDTH := 120.0

var hero: Fighter

@onready var _status: Label = $Status
@onready var _hp_fill: ColorRect = $Bars/HpFill
@onready var _energy_fill: ColorRect = $Bars/EnergyFill
@onready var _touch: Control = $Touch


func _ready() -> void:
	$Build.text = BuildInfo.summary()
	# Touch buttons only appear on touch devices; desktop players never see them.
	_touch.visible = DisplayServer.is_touchscreen_available()


func _process(_delta: float) -> void:
	if hero == null:
		return
	_hp_fill.size.x = BAR_WIDTH * hero.hp / hero.max_hp
	_energy_fill.size.x = BAR_WIDTH * hero.energy / CombatRules.MAX_ENERGY
	_status.text = (
		"x %d  depth %d  |  %s  |  %d fps"
		% [hero.position.x, hero.position.y, hero.state_name(), Engine.get_frames_per_second()]
	)
