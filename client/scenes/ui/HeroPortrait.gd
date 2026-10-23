class_name HeroPortrait
extends Control
## The hero's face on the HUD: head and shoulders cut from the current sprite
## (so armour shows), on a backdrop in the hero's colour, with the level in a
## badge on the corner. It flashes red when the hero is hit and its frame
## pulses red while HP is low. Draws itself; reads nothing from the game.

const SIZE := Vector2(40, 40)
const BADGE_RADIUS := 8.5
## Below this share of max HP the frame pulses.
const LOW_HP := 0.25

var color := UiTheme.ACCENT
var level := 1
var low_hp := false
var _face: Texture2D
var _art_id := ""
var _flash := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = SIZE + Vector2(0, 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows `art_id`'s face (cut once per art change).
func set_art(content: ContentDB, art_id: String) -> void:
	if art_id == _art_id:
		return
	_art_id = art_id
	_face = UiKit.portrait(content, art_id)
	queue_redraw()


func set_state(p_level: int, hp_ratio: float) -> void:
	if p_level != level or (hp_ratio < LOW_HP) != low_hp:
		level = p_level
		low_hp = hp_ratio < LOW_HP
		queue_redraw()


func flash() -> void:
	_flash = 0.25


func _process(delta: float) -> void:
	_time += delta
	if _flash > 0.0 or low_hp:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, SIZE)
	# Backdrop: the hero's colour, darker towards the edges.
	draw_rect(box, Color(0, 0, 0, 0.8))
	var inner := box.grow(-1)
	draw_rect(inner, color.darkened(0.72))
	draw_circle(inner.get_center() + Vector2(0, 4), 15.0, color.darkened(0.5))
	draw_circle(inner.get_center() + Vector2(0, 4), 10.0, color.darkened(0.35))
	if _face:
		var face_rect := Rect2(inner.position + Vector2(1, 1), inner.size - Vector2(2, 1))
		draw_texture_rect(_face, face_rect, false)
	# Inner shade at the bottom so the badge reads.
	draw_rect(
		Rect2(inner.position + Vector2(0, inner.size.y - 8), Vector2(inner.size.x, 8)),
		Color(0, 0, 0, 0.35)
	)
	if _flash > 0.0:
		draw_rect(inner, Color(1, 0.15, 0.1, _flash / 0.25 * 0.55))
	var frame := color
	if low_hp:
		frame = UiTheme.DANGER.lerp(Color.WHITE, 0.5 + 0.5 * sin(_time * 8.0))
	draw_rect(box.grow(-0.5), frame, false, 1.5)
	# Level badge on the bottom-left corner.
	var centre := Vector2(BADGE_RADIUS - 2, SIZE.y - BADGE_RADIUS + 3)
	draw_circle(centre, BADGE_RADIUS + 1, Color(0, 0, 0, 0.9))
	draw_circle(centre, BADGE_RADIUS, Color("2a1d10"))
	draw_arc(centre, BADGE_RADIUS, 0, TAU, 24, UiTheme.GOLD, 1.2)
	var font := get_theme_default_font()
	var text := str(level)
	var font_size := 9 if level < 100 else 7
	var at := centre + Vector2(-BADGE_RADIUS, font_size * 0.36)
	draw_string_outline(
		font, at, text, HORIZONTAL_ALIGNMENT_CENTER, BADGE_RADIUS * 2, font_size, 3, Color.BLACK
	)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, BADGE_RADIUS * 2, font_size)
