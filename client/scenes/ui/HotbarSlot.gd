class_name HotbarSlot
extends Control
## One hotbar slot: framed icon, key number, and its state drawn on top: a
## clockwise cooldown sweep with seconds left, a blue tint when there is not
## enough energy, a lock with the unlock level, and an item count. Flashes
## when it comes off cooldown and when it is used or refused. Clicking or
## tapping it presses it.

signal pressed

const SIZE := 28.0
const FRAMES := {
	"attack": Color("f2a54a"),
	"skill": Color("d0503a"),
	"item": Color("5fbf7a"),
	"empty": Color("3a3d55"),
}

var key := ""
var kind := "skill"
var icon: Texture2D
## 0..1 of the cooldown still to run, and seconds left.
var cooldown := 0.0
var seconds_left := 0.0
var no_energy := false
var locked_level := 0
## Item count, or -1 for slots that are not items.
var count := -1

var _ready_flash := 0.0
var _press_flash := 0.0
var _deny_flash := 0.0
var _was_cooling := false


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func set_state(p_cooldown: float, p_seconds: float, p_no_energy: bool, p_count: int) -> void:
	var cooling := p_cooldown > 0.0
	if _was_cooling and not cooling:
		_ready_flash = 0.35
	_was_cooling = cooling
	cooldown = p_cooldown
	seconds_left = p_seconds
	no_energy = p_no_energy
	count = p_count
	queue_redraw()


## Visual answer to a press: accepted (bright pulse) or refused (red).
func flash(accepted: bool) -> void:
	if accepted:
		_press_flash = 0.18
	else:
		_deny_flash = 0.3
	queue_redraw()


func _process(delta: float) -> void:
	if _ready_flash > 0.0 or _press_flash > 0.0 or _deny_flash > 0.0:
		_ready_flash = maxf(0.0, _ready_flash - delta)
		_press_flash = maxf(0.0, _press_flash - delta)
		_deny_flash = maxf(0.0, _deny_flash - delta)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press: bool = (
		(
			event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT
		)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if press:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var frame: Color = FRAMES.get(kind, Color.WHITE)
	var unusable := locked_level > 0 or count == 0
	# Bevelled frame: dark rim, coloured border, inner shadow.
	draw_rect(rect, Color(0, 0, 0, 0.75))
	draw_rect(rect.grow(-1), frame.darkened(0.45 if unusable else 0.0), false, 1.0)
	draw_rect(rect.grow(-2), Color("0b0c14"))
	var inner := rect.grow(-2)
	if icon:
		var tint := Color(0.45, 0.45, 0.5) if unusable else Color.WHITE
		if no_energy and not unusable:
			tint = Color(0.55, 0.65, 1.0)
		var icon_size := icon.get_size()
		var at := inner.position + (inner.size - icon_size) / 2.0
		draw_texture(icon, at.round(), tint)
	draw_line(inner.position, Vector2(inner.end.x, inner.position.y), Color(1, 1, 1, 0.12))
	if cooldown > 0.0:
		_draw_sweep(inner, cooldown)
		var text := "%.1f" % seconds_left if seconds_left < 10.0 else str(ceili(seconds_left))
		_text(text, inner, HORIZONTAL_ALIGNMENT_CENTER, 9, Color.WHITE, 0.62)
	if no_energy and not unusable and cooldown <= 0.0:
		draw_rect(inner, Color(0.1, 0.25, 0.8, 0.25))
	if locked_level > 0:
		draw_rect(inner, Color(0, 0, 0, 0.55))
		_text("Lv%d" % locked_level, inner, HORIZONTAL_ALIGNMENT_CENTER, 7, UiTheme.ACCENT, 0.95)
	if count >= 0:
		var color := UiTheme.TEXT if count > 0 else UiTheme.DANGER
		_text(str(count), inner, HORIZONTAL_ALIGNMENT_RIGHT, 7, color, 1.0)
	_text(key, Rect2(inner.position + Vector2(1, 0), inner.size), 0, 7, UiTheme.TEXT_DIM, 0.36)
	if _ready_flash > 0.0:
		draw_rect(rect.grow(-1), Color(1, 1, 1, _ready_flash / 0.35), false, 2.0)
	if _press_flash > 0.0:
		draw_rect(inner, Color(1, 0.95, 0.8, _press_flash / 0.18 * 0.45))
	if _deny_flash > 0.0:
		draw_rect(rect.grow(-1), Color(1, 0.2, 0.15, _deny_flash / 0.3), false, 2.0)


## Dark pie over the part of the cooldown still to run, clockwise from 12.
func _draw_sweep(inner: Rect2, remaining: float) -> void:
	var center := inner.get_center()
	var radius := inner.size.length()
	var points := PackedVector2Array([center])
	var steps := 24
	var start := -PI / 2.0 + TAU * (1.0 - remaining)
	for i in steps + 1:
		var angle := start + TAU * remaining * i / steps
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		points.append(
			Vector2(
				clampf(point.x, inner.position.x, inner.end.x),
				clampf(point.y, inner.position.y, inner.end.y)
			)
		)
	draw_colored_polygon(points, Color(0, 0, 0, 0.62))


## Outlined text inside `box`; `baseline` is the fraction of the box height.
func _text(
	text: String,
	box: Rect2,
	align: HorizontalAlignment,
	font_size: int,
	color: Color,
	baseline: float
) -> void:
	var font := get_theme_default_font()
	var at := Vector2(box.position.x, box.position.y + box.size.y * baseline)
	if align == HORIZONTAL_ALIGNMENT_RIGHT:
		at.x -= 1
	draw_string_outline(font, at, text, align, box.size.x, font_size, 3, Color(0, 0, 0, 0.9))
	draw_string(font, at, text, align, box.size.x, font_size, color)
