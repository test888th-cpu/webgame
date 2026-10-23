extends Node2D
## A single street used to prove the browser pipeline: scenery, the player,
## a bounded camera and the HUD. Replaced by data-driven zones in Milestone 2.

const BOOT_MARKER := "BOOT_OK"
const ZONE_SIZE := Vector2(1600, 360)
## Walkable band of the street (x along, y depth).
const WALK_BOUNDS := Rect2(16, 250, 1568, 90)
const PROBE_INTERVAL := 0.1

var _probe_timer := 0.0

@onready var player: Player = $Entities/Player
@onready var _camera: Camera2D = $Entities/Player/Camera
@onready var _hud: CanvasLayer = $Hud


func _ready() -> void:
	player.bounds = WALK_BOUNDS
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(ZONE_SIZE.x)
	_camera.limit_bottom = int(ZONE_SIZE.y)
	_hud.player = player
	# The web smoke test waits for this exact line on the browser console.
	print("%s %s" % [BOOT_MARKER, BuildInfo.summary()])


func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_probe_timer += delta
	if _probe_timer >= PROBE_INTERVAL:
		_probe_timer = 0.0
		_publish_probe()


## Exposes read-only state to the page so browser tests can verify that input
## actually moves the character. Contains nothing a player could not already
## see on screen.
func _publish_probe() -> void:
	var state := {"x": player.position.x, "y": player.position.y, "facing": player.facing}
	JavaScriptBridge.eval("window.ironboundProbe = %s;" % JSON.stringify(state), true)
