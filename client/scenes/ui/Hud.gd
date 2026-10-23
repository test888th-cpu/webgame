extends CanvasLayer
## On-screen interface: build identity, controls help, player position and FPS.

var player: Player

@onready var _status: Label = $Status
@onready var _touch: Control = $Touch


func _ready() -> void:
	$Build.text = BuildInfo.summary()
	# Touch buttons only appear on touch devices; desktop players never see them.
	_touch.visible = DisplayServer.is_touchscreen_available()


func _process(_delta: float) -> void:
	if player:
		_status.text = (
			"x %d  depth %d  |  %d fps"
			% [player.position.x, player.position.y, Engine.get_frames_per_second()]
		)
