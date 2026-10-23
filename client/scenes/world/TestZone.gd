extends Node2D
## Test street: the hero against a training dummy. Owns the combat simulation
## for this zone and drives it at a fixed 60 ticks per second; the views only
## draw what the simulation says. In Milestone 3 the same CombatRules.tick
## runs on the zone server and this node switches to prediction.

const BOOT_MARKER := "BOOT_OK"
const ZONE_SIZE := Vector2(1600, 360)
## Walkable band of the street (x along, y depth).
const WALK_BOUNDS := Rect2(16, 250, 1568, 90)
const PROBE_INTERVAL := 0.1

const HERO_ID := 1
const DUMMY_ID := 2
const HERO_START := Vector2(120, 300)
const DUMMY_START := Vector2(300, 300)
const DUMMY_HP := 120
const DUMMY_RESPAWN_TICKS := 120

var library: MoveLibrary
var hero: Fighter
var dummy: Fighter
var fighters: Array[Fighter] = []
## Hits landed by anyone since the zone loaded (shown to the smoke test).
var hits := 0
var _dummy_down_ticks := 0
var _probe_timer := 0.0

@onready var hero_view: FighterView = $Entities/Hero
@onready var dummy_view: FighterView = $Entities/Dummy
@onready var _camera: Camera2D = $Entities/Hero/Camera
@onready var _hud: CanvasLayer = $Hud
@onready var _effects: Node2D = $Effects


func _ready() -> void:
	library = MoveLibrary.load_file()
	for error in library.errors:
		push_error("moves.json: " + error)
	hero = Fighter.new(HERO_ID, 1, HERO_START, 100)
	dummy = Fighter.new(DUMMY_ID, 2, DUMMY_START, DUMMY_HP)
	dummy.facing = -1
	fighters = [hero, dummy]
	hero_view.fighter = hero
	dummy_view.fighter = dummy
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(ZONE_SIZE.x)
	_camera.limit_bottom = int(ZONE_SIZE.y)
	_hud.hero = hero
	_sync_views()
	# The web smoke test waits for this exact line on the browser console.
	print("%s %s" % [BOOT_MARKER, BuildInfo.summary()])


func _physics_process(_delta: float) -> void:
	step(PlayerInput.read())


## Advances the zone by one simulation tick with the given hero input.
func step(hero_input: FighterInput) -> Array[CombatEvent]:
	var events := CombatRules.tick(fighters, {HERO_ID: hero_input}, library, WALK_BOUNDS)
	for event in events:
		hits += 1
		var label := DamageNumber.new()
		label.add_theme_font_size_override("font_size", 10)
		_effects.add_child(label)
		label.show_hit(event)
	_respawn_dummy_when_ko()
	_sync_views()
	return events


func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_probe_timer += delta
	if _probe_timer >= PROBE_INTERVAL:
		_probe_timer = 0.0
		_publish_probe()


func _respawn_dummy_when_ko() -> void:
	if not dummy.is_ko():
		return
	_dummy_down_ticks += 1
	if _dummy_down_ticks >= DUMMY_RESPAWN_TICKS:
		_dummy_down_ticks = 0
		dummy.hp = dummy.max_hp
		dummy.position = DUMMY_START
		dummy.knockback_remaining = 0.0
		dummy.enter(Fighter.State.IDLE)


func _sync_views() -> void:
	hero_view.sync()
	dummy_view.sync()


## Exposes read-only state to the page so browser tests can verify that input
## actually moves and fights. Contains nothing a player could not already see
## on screen.
func _publish_probe() -> void:
	var state := {
		"x": hero.position.x,
		"y": hero.position.y,
		"facing": hero.facing,
		"hp": hero.hp,
		"energy": hero.energy,
		"state": hero.state_name(),
		"dummy": {"x": dummy.position.x, "y": dummy.position.y, "hp": dummy.hp},
		"hits": hits,
	}
	JavaScriptBridge.eval("window.ironboundProbe = %s;" % JSON.stringify(state), true)
