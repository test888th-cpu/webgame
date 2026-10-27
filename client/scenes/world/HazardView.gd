class_name HazardView
extends Node2D
## A hazard on its way (ZoneSim hazards, called by BossMechanics): a red mark
## the size of what it will hit, darkening and pulsing as it comes, then a
## shipping container falling off a crane ("crane"), a burst of scalding
## steam from a floor vent ("steam"), a security laser sweeping the lane
## ("laser"), floor plates shocking ("shock") or a geyser of drain sludge
## ("sludge"). Drawn with shapes until the art pass. Presentation only;
## BossMechanics decides who it hits.

const FALL_SECONDS := 0.25
const DROP_HEIGHT := 220.0
const SHADOW := Vector2(30, 10)
const BOX := Vector2(56, 34)
const STEEL := Color("b4532a")
const RIB := Color("7a3418")
const EDGE := Color("1c1418")

const STEAM := Color(0.92, 0.95, 1.0, 0.85)
const SLUDGE := Color(0.35, 0.6, 0.2, 0.9)
const LASER := Color(1.0, 0.18, 0.25)
const SPARK := Color(0.55, 0.85, 1.0)

var kind := "crane"
## Half the footprint it hits (as ZoneSim measures it).
var half := Vector2(30, 10)
var _left := 1.0
var _total := 1.0
var _landed := false


## `seconds` until it lands (or bursts) at this node's position (its feet line).
func setup(seconds: float, p_kind := "crane", p_half := Vector2(30, 10)) -> void:
	_total = maxf(seconds, 0.05)
	_left = _total
	kind = p_kind
	half = p_half


func land() -> void:
	_landed = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tween.tween_callback(queue_free)
	queue_redraw()


func _process(delta: float) -> void:
	_left = maxf(0.0, _left - delta)
	queue_redraw()


func _draw() -> void:
	var near := 1.0 - _left / _total
	var pulse := 0.5 + 0.5 * sin(near * 24.0)
	if kind == "laser":
		_draw_laser(near, pulse)
		return
	if kind == "shock":
		_draw_shock(near, pulse)
		return
	if not _landed:
		var shade := Color(0.9, 0.1, 0.05, 0.25 + 0.35 * near + 0.15 * pulse)
		_ellipse(SHADOW * (0.6 + 0.4 * near), shade)
	if kind in ["steam", "sludge"]:
		_draw_steam(near)
		return
	var fall := 0.0 if _landed else clampf(_left / FALL_SECONDS, 0.0, 1.0)
	if _landed or _left <= FALL_SECONDS:
		var top := Vector2(-BOX.x / 2.0, -BOX.y - fall * DROP_HEIGHT)
		draw_rect(Rect2(top, BOX), STEEL)
		for i in range(1, 7):
			var x := top.x + BOX.x * i / 7.0
			draw_line(Vector2(x, top.y + 3), Vector2(x, top.y + BOX.y - 3), RIB, 2.0)
		draw_rect(Rect2(top, BOX), EDGE, false, 2.0)
		draw_line(Vector2(0, top.y), Vector2(0, top.y - DROP_HEIGHT), EDGE, 1.0)


func _ellipse(radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


## A floor grate that hisses as it comes, then a column of steam.
func _draw_steam(near: float) -> void:
	draw_rect(Rect2(-14, -3, 28, 6), Color("2a2a30"))
	for i in 5:
		draw_line(Vector2(-12 + i * 6, -3), Vector2(-12 + i * 6, 3), Color("55555c"), 1.0)
	if not _landed:
		for i in 3:
			var puff := Vector2(sin(near * 30.0 + i * 2.0) * 4.0, -6.0 - i * 5.0 * near)
			draw_circle(puff, 2.0 + near * 2.0, Color(STEAM, 0.3 * near))
		return
	for i in 8:
		var y := -10.0 - i * 14.0
		var puff := SLUDGE if kind == "sludge" else STEAM
		draw_circle(Vector2(sin(i * 1.7) * 6.0, y), 10.0 + i * 1.5, Color(puff, 0.75 - i * 0.07))


## A band across the lane, its full width: a thin aiming line that thickens
## and flickers as it charges, then a bright beam with a white core.
func _draw_laser(near: float, pulse: float) -> void:
	var band := Rect2(-half.x, -half.y, half.x * 2.0, half.y * 2.0)
	if not _landed:
		draw_rect(band, Color(LASER, 0.12 + 0.25 * near + 0.1 * pulse))
		draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(LASER, 0.5 + 0.5 * pulse), 1.0)
		return
	draw_rect(band, Color(LASER, 0.7))
	draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(1, 0.9, 0.9), 3.0)


## A floor plate the size of what it hits: its seams glow brighter as it
## charges, then it crackles with zigzag sparks.
func _draw_shock(near: float, pulse: float) -> void:
	var plate := Rect2(-half.x, -half.y, half.x * 2.0, half.y * 2.0)
	draw_rect(plate, Color(0.15, 0.17, 0.22, 0.6))
	var glow := Color(SPARK, 0.2 + 0.5 * near + 0.2 * pulse if not _landed else 0.9)
	draw_rect(plate, glow, false, 1.5)
	for i in range(1, 4):
		var x := -half.x + half.x * 2.0 * i / 4.0
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), Color(glow, glow.a * 0.6), 1.0)
	if not _landed:
		return
	for i in 4:
		var x := -half.x + half.x * 2.0 * (i + 0.5) / 4.0
		var bolt := PackedVector2Array()
		for step in 5:
			bolt.append(Vector2(x + (6.0 if step % 2 else -6.0), -step * 9.0))
		draw_polyline(bolt, Color(1, 1, 1, 0.9), 2.0)
