class_name ScreenLayout
extends RefCounted
## Where everything goes on the screen, worked out once from the window's
## size, its safe area and the input in use. The single place that knows
## about screen shape: GameSession applies it (the root's logical size) and
## the HUD, the street's camera and the touch controls only read it.
##
## Two modes:
## * landscape: the game's 640x360 logical canvas, as it has always been.
##   With touch input, the touch controls sit in the bottom corners, a row of
##   menu buttons at the top centre, and the hotbar between the corners.
## * portrait (window taller than wide, while the street is being played): a
##   360-wide logical canvas. A HUD band on top, the street (360 tall) under
##   it, and a control deck below with the hotbar, the movement pad (lower
##   left), the combat buttons (lower right) and the menu buttons between.
##   Story arenas are at least 320 px wide, so every fight fits the view.
##
## All rects are in logical pixels of the root canvas. Presentation only:
## nothing here changes how the game plays.

const LANDSCAPE := "landscape"
const PORTRAIT := "portrait"
## Logical canvas per mode (the root's content_scale_size).
const LANDSCAPE_BASE := Vector2i(640, 360)
const PORTRAIT_BASE := Vector2i(360, 640)
## The street is drawn 360 logical px tall (ZoneView.VIEW_HEIGHT).
const WORLD_HEIGHT := 360.0
## People in the street stand with their feet on the kerb, world y 262
## (areas.json NPCs): landscape touch clusters stay below it.
const KERB_Y := 262.0
## The portrait HUD band above the street, and how tall it may grow on tall
## screens (enough for the quest and route cards beside the hero card).
const HUD_BAND := 64.0
const HUD_BAND_MAX := 120.0
const MARGIN := 8.0
const GAP := 4.0
## The smallest comfortable touch target, in CSS px.
const MIN_TOUCH_CSS := 44.0
## Touch buttons are never smaller than the hotbar's slots are drawn.
const MIN_TOUCH_LOGICAL := 28.0
## The hotbar's own size (Hotbar.gd: 7 slots of 28, gaps of 3, a 3 px
## margin round them), scaled up to touch size in touch layouts.
const HOTBAR_NATURAL := Vector2(220, 34)
const HOTBAR_SLOT := 28.0

var mode := LANDSCAPE
## The root's logical canvas size for this mode (Window.content_scale_size).
var base := LANDSCAPE_BASE
## CSS (window) px per logical px.
var scale := 1.0
## The visible logical size (the canvas grows with "expand").
var size := Vector2(640, 360)
## Safe-area insets in logical px: left, top, right, bottom.
var insets := Vector4.ZERO
## Touch input in use: keyboard hints hidden, touch-sized buttons.
var touch := false
## The touch controls are shown: touch in use and no game screen open (a
## screen is used by tapping it; buttons under it would still take touches).
var controls := false
## The input in use: "keyboard", "touch" or "gamepad".
var device := "keyboard"
## The side of a touch button, in logical px (MIN_TOUCH_CSS on screen).
var touch_size := MIN_TOUCH_LOGICAL
## Where the street (world y 0 to WORLD_HEIGHT) is shown.
var world := Rect2()
## The HUD band (portrait), else empty.
var hud := Rect2()
## The control deck under the street (portrait), else empty.
var deck := Rect2()
## Touch movement pad and combat buttons (touch only).
var left_pad := Rect2()
var right_pad := Rect2()
## Where the hotbar goes (touch layouts), else empty: the HUD's own anchors.
var hotbar := Rect2()
## Touch menu: the menu bar's buttons (in `menu_items` order) and the cells
## for the pause touch button and the AUTO switch. Empty: the HUD's default.
var menu := Rect2()
var menu_columns := 0
var menu_items: Array[String] = []
var pause_cell := Rect2()
var auto_cell := Rect2()
## Where the boss bar's top-left goes.
var boss_at := Vector2(190, 8)
## Touch buttons' cells: name -> [pad rect, column and row in it].
var _cells := {}
var _hotbar_scale := 0.0


## The layout for a window `window` px big (`insets`: safe-area insets in
## window px, left, top, right, bottom), played with `device`. Portrait is
## used only where the game has portrait designs (`portrait_ok`); while a
## game screen is open (`screen_open`) the touch controls are hidden.
static func compute(
	window: Vector2, insets_px: Vector4, p_device: String, portrait_ok: bool, screen_open := false
) -> ScreenLayout:
	var l := ScreenLayout.new()
	l.device = p_device
	l.touch = p_device == "touch"
	l.controls = l.touch and not screen_open
	var tall := window.y > window.x
	l.mode = PORTRAIT if portrait_ok and tall else LANDSCAPE
	l.base = PORTRAIT_BASE if l.mode == PORTRAIT else LANDSCAPE_BASE
	l.scale = minf(window.x / l.base.x, window.y / l.base.y)
	l.size = window / maxf(l.scale, 0.001)
	l.insets = insets_px / maxf(l.scale, 0.001)
	l.touch_size = maxf(MIN_TOUCH_CSS / maxf(l.scale, 0.001), MIN_TOUCH_LOGICAL)
	if l.mode == PORTRAIT:
		l._portrait()
	else:
		l._landscape()
	return l


func _landscape() -> void:
	# The street fills the height (centred if the window is squarer than
	# 16:9, so nothing moves on the usual screens).
	var top := maxf(0.0, (size.y - WORLD_HEIGHT) / 2.0)
	if touch:
		top = 0.0
	world = Rect2(0, top, size.x, WORLD_HEIGHT)
	if not touch:
		return
	var t := touch_size
	# Both clusters are two rows tall and sit below the kerb, where people
	# stand (KERB_Y), so they never cover anyone in the street: arrow keys in
	# an inverted T on the left, the combat buttons 3 by 2 on the right.
	var bottom := size.y - insets.w - GAP
	var wide := 3.0 * t + 2.0 * GAP
	var tall := 2.0 * t + GAP
	left_pad = Rect2(insets.x + MARGIN, bottom - tall, wide, tall)
	right_pad = Rect2(size.x - insets.z - MARGIN - wide, bottom - tall, wide, tall)
	_cells = {
		"Up": [left_pad, Vector2(1, 0)],
		"Left": [left_pad, Vector2(0, 1)],
		"Down": [left_pad, Vector2(1, 1)],
		"Right": [left_pad, Vector2(2, 1)],
		"Item": [right_pad, Vector2(0, 0)],
		"Interact": [right_pad, Vector2(1, 0)],
		"Guard": [right_pad, Vector2(2, 0)],
		"Dodge": [right_pad, Vector2(0, 1)],
		"Heavy": [right_pad, Vector2(1, 1)],
		"Light": [right_pad, Vector2(2, 1)],
	}
	# The hotbar between the clusters, as large as fits (touch-sized where
	# the screen is wide enough).
	var room := right_pad.position.x - left_pad.end.x - 2.0 * GAP
	_hotbar_scale = minf(t / HOTBAR_SLOT, room / HOTBAR_NATURAL.x)
	var bar := HOTBAR_NATURAL * _hotbar_scale
	var middle := (left_pad.end.x + right_pad.position.x) / 2.0
	hotbar = Rect2(middle - bar.x / 2.0, bottom - bar.y, bar.x, bar.y)
	# Menu buttons in a row at the top centre: the pause button first.
	menu_items = ["bag", "map", "quests", "character"]
	var row := (menu_items.size() + 1) * t + menu_items.size() * GAP
	var left := size.x / 2.0 - row / 2.0
	pause_cell = Rect2(left, insets.y + GAP, t, t)
	menu = Rect2(left + t + GAP, insets.y + GAP, row - t - GAP, t)
	menu_columns = menu_items.size()
	auto_cell = Rect2(insets.x + MARGIN, 88, t, t)
	boss_at = Vector2(size.x / 2.0 - 130.0, menu.end.y + GAP)


func _portrait() -> void:
	var t := touch_size
	var bar := HOTBAR_NATURAL * hotbar_scale()
	var cross := 3.0 * t + 2.0 * GAP
	# What the deck needs (hotbar over the controls), and what is left over:
	# the HUD band grows first (so the quest and route cards sit above the
	# street, not on it), up to HUD_BAND_MAX.
	var deck_needed := MARGIN + bar.y + MARGIN + cross + MARGIN + insets.w
	var spare := maxf(0.0, size.y - insets.y - HUD_BAND - WORLD_HEIGHT - deck_needed)
	var band := HUD_BAND + minf(spare, HUD_BAND_MAX - HUD_BAND)
	hud = Rect2(0, 0, size.x, insets.y + band)
	world = Rect2(0, hud.end.y, size.x, WORLD_HEIGHT)
	deck = Rect2(0, world.end.y, size.x, maxf(0.0, size.y - world.end.y))
	boss_at = Vector2(size.x / 2.0 - 130.0, world.position.y + GAP)
	var bottom := size.y - insets.w - MARGIN
	if touch:
		_pads(bottom)
	else:
		left_pad = Rect2(insets.x + MARGIN, bottom, 0, 0)
		right_pad = Rect2(size.x - insets.z - MARGIN, bottom, 0, 0)
	# The hotbar right above the controls, in thumb reach.
	var controls_top := bottom - (cross if touch else 2.0 * t + GAP)
	hotbar = Rect2(size.x / 2.0 - bar.x / 2.0, controls_top - MARGIN - bar.y, bar.x, bar.y)
	# A 2x2 block between the pads: Bag over Map, AUTO over the pause button.
	var block := 2.0 * t + GAP
	var centre := (left_pad.end.x + right_pad.position.x) / 2.0
	var x := centre - block / 2.0
	var y := bottom - block
	menu_items = ["bag", "map"]
	menu_columns = 1
	menu = Rect2(x, y, t, block)
	auto_cell = Rect2(x + t + GAP, y, t, t)
	pause_cell = Rect2(x + t + GAP, y + t + GAP, t, t)


## The movement pad (a cross of 3x3 cells) in the lower left and the combat
## buttons (2 columns, 3 rows) in the lower right, their bottoms at `bottom`.
func _pads(bottom: float) -> void:
	var t := touch_size
	var cross := 3.0 * t + 2.0 * GAP
	left_pad = Rect2(insets.x + MARGIN, bottom - cross, cross, cross)
	var wide := 2.0 * t + GAP
	right_pad = Rect2(size.x - insets.z - MARGIN - wide, bottom - cross, wide, cross)
	_cells = {
		"Up": [left_pad, Vector2(1, 0)],
		"Left": [left_pad, Vector2(0, 1)],
		"Right": [left_pad, Vector2(2, 1)],
		"Down": [left_pad, Vector2(1, 2)],
		"Item": [right_pad, Vector2(0, 0)],
		"Interact": [right_pad, Vector2(1, 0)],
		"Dodge": [right_pad, Vector2(0, 1)],
		"Guard": [right_pad, Vector2(1, 1)],
		"Heavy": [right_pad, Vector2(0, 2)],
		"Light": [right_pad, Vector2(1, 2)],
	}


## How much the hotbar is scaled: touch-sized slots, or as large as fits.
func hotbar_scale() -> float:
	return _hotbar_scale if _hotbar_scale > 0.0 else touch_size / HOTBAR_SLOT


## A touch button's cell, by its TouchControls name (empty if it has none
## in this layout).
func pad_cell(name: String) -> Rect2:
	if name == "Pause":
		return pause_cell
	if not _cells.has(name):
		return Rect2()
	var pad: Rect2 = _cells[name][0]
	var at: Vector2 = _cells[name][1] * (touch_size + GAP)
	return Rect2(pad.position + at, Vector2(touch_size, touch_size))
