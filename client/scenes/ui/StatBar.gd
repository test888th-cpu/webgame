class_name StatBar
extends Control
## A framed horizontal bar (HP, energy, XP, boss health) with optional
## "value/max" text. Draws itself, so it stays crisp and cheap.

@export var color := UiTheme.HP
@export var show_text := true
var value := 1.0
var max_value := 1.0
## Recent damage shown as a lighter trail that catches up.
var _trail := 1.0
var _flash := 0.0


## `instant` skips the damage trail (for bars that show a snapshot).
func set_values(p_value: float, p_max: float, instant := false) -> void:
	max_value = maxf(1.0, p_max)
	value = clampf(p_value, 0.0, max_value)
	if instant or value > _trail * max_value:
		_trail = value / max_value
	queue_redraw()


## Blinks the frame red: "not enough of this".
func flash() -> void:
	_flash = 0.4


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()
	var target := value / max_value
	if _trail > target:
		_trail = maxf(target, _trail - delta * 0.6)
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0, 0, 0, 0.65))
	var inner := rect.grow(-1)
	var ratio := value / max_value
	draw_rect(
		Rect2(inner.position, Vector2(inner.size.x * _trail, inner.size.y)), color.lightened(0.45)
	)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y)), color)
	if inner.size.y >= 4:
		var shine := Rect2(inner.position, Vector2(inner.size.x * ratio, 1))
		draw_rect(shine, color.lightened(0.3))
	draw_rect(rect, Color(0, 0, 0, 0.9), false, 1.0)
	if _flash > 0.0 and fmod(_flash, 0.13) > 0.05:
		draw_rect(rect.grow(1), UiTheme.DANGER, false, 1.5)
	if show_text and size.y >= 7:
		var font := get_theme_default_font()
		var text := "%d/%d" % [roundi(value), roundi(max_value)]
		var font_size := UiTheme.SIZE_CAPTION
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2((size.x - width) / 2.0, size.y / 2.0 + font_size * 0.35)
		draw_string_outline(
			font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color(0, 0, 0, 0.9)
		)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
