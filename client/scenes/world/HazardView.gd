class_name HazardView
extends Node2D
## A hazard on its way (ZoneSim hazards, called by BossMechanics): a red mark
## the size of what it will hit, darkening and pulsing as it comes, then a
## shipping container as wide as that mark falling off a crane ("crane"), a burst of scalding
## steam from a floor vent ("steam"), a security laser sweeping the lane
## ("laser"), floor plates shocking ("shock"), a geyser of drain sludge
## ("sludge"), the street splitting across its whole depth ("quake") or a
## rain of molten slag, rivets or debris, one drop per mark ("rain"). The
## marks, vents, plates and beams are drawn to the exact size of what they hit;
## the burst on landing is a pixelfx effect (BossFxRules.hazard, spawned by
## GameFeedback), so nothing is drawn twice.
## Presentation only; BossMechanics decides who it hits.

const FALL_SECONDS := 0.25
const DROP_HEIGHT := 260.0
## A container is as wide as what it hits, and this tall for its width.
const BOX_HEIGHT := 0.62
const STEEL := Color("b4532a")
const RIB := Color("7a3418")
const EDGE := Color("1c1418")

const STEAM := Color(0.92, 0.95, 1.0, 0.85)
const SLUDGE := Color(0.35, 0.6, 0.2, 0.9)
const LASER := Color(1.0, 0.18, 0.25)
const SPARK := Color(0.55, 0.85, 1.0)
const CRACK := Color(1.0, 0.55, 0.15)
const EMBER := Color(1.0, 0.62, 0.2)
## How high a rain drop starts above its mark, in pixels.
const RAIN_HEIGHT := 200.0
const GRATE := Color("2a2a30")
const GRATE_BAR := Color("55555c")
## Seconds a bolt pattern holds before the next, so the arcs flicker.
const FLICKER := 0.05

var kind := "crane"
## Half the footprint it hits (as ZoneSim measures it).
var half := Vector2(30, 10)
var _left := 1.0
var _total := 1.0
var _landed := false
var _since_landed := 0.0
var _bolts := RandomNumberGenerator.new()


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
	if _landed:
		_since_landed += delta
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
	if kind == "quake":
		_draw_quake(near, pulse)
		return
	if kind == "rain":
		_draw_rain(near, pulse)
		return
	if not _landed:
		var shade := Color(0.9, 0.1, 0.05, 0.25 + 0.35 * near + 0.15 * pulse)
		_ellipse(half * (0.6 + 0.4 * near), shade)
		if kind == "crane":
			# The shadow's edge, sharp from the start: exactly what it covers.
			_ellipse_outline(half, Color(1, 0.2, 0.1, 0.5 + 0.4 * pulse))
	if kind in ["steam", "sludge"]:
		_draw_steam(near)
		return
	var fall := 0.0 if _landed else clampf(_left / FALL_SECONDS, 0.0, 1.0)
	if _landed or _left <= FALL_SECONDS:
		var box := Vector2(half.x * 2.0, half.x * 2.0 * BOX_HEIGHT)
		var top := Vector2(-box.x / 2.0, -box.y - fall * DROP_HEIGHT)
		draw_rect(Rect2(top, box), STEEL)
		var ribs := maxi(4, roundi(box.x / 9.0))
		for i in range(1, ribs):
			var x := top.x + box.x * i / ribs
			draw_line(Vector2(x, top.y + 3), Vector2(x, top.y + box.y - 3), RIB, 2.0)
		draw_rect(Rect2(top, box), EDGE, false, 2.0)
		# Two crane cables to the corners, cut the moment it lands.
		if not _landed:
			for corner in [top + Vector2(4, 0), top + Vector2(box.x - 4, 0)]:
				draw_line(corner, Vector2(0, top.y - DROP_HEIGHT), EDGE, 1.0)


func _ellipse_outline(radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 25:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_polyline(points, color, 1.5)


func _ellipse(radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


## A floor vent as wide as what it hits, hissing wisps that thicken as it
## comes; the column itself is the pixelfx burst on landing (steam_burst,
## sludge_splash), after which only the vent stays, glowing as it cools.
func _draw_steam(near: float) -> void:
	var vent := Rect2(-half.x * 0.6, -3, half.x * 1.2, 6)
	draw_rect(vent, GRATE)
	var bars := maxi(3, roundi(vent.size.x / 6.0))
	for i in range(1, bars):
		var x := vent.position.x + vent.size.x * i / bars
		draw_line(Vector2(x, -3), Vector2(x, 3), GRATE_BAR, 1.0)
	var tint := SLUDGE if kind == "sludge" else STEAM
	if _landed:
		draw_rect(vent, Color(tint, 0.5 * maxf(0.0, 1.0 - _since_landed)), false, 1.0)
		return
	for i in 4:
		var rise := fmod(near * 3.0 + i * 0.25, 1.0)
		var x := vent.position.x + vent.size.x * (i + 0.5) / 4.0 + sin(rise * 9.0 + i) * 2.0
		draw_circle(
			Vector2(x, -4.0 - rise * 14.0 * near), 1.5 + near * 2.0, Color(tint, 0.35 * near)
		)


## A band across the lane, its full width: a thin aiming line that thickens
## and flickers as it charges, then the beam: a soft glow, a bright band and a
## white core that narrow as it fades.
func _draw_laser(near: float, pulse: float) -> void:
	var band := Rect2(-half.x, -half.y, half.x * 2.0, half.y * 2.0)
	if not _landed:
		draw_rect(band, Color(LASER, 0.08 + 0.2 * near + 0.08 * pulse))
		var aim := Color(LASER, 0.5 + 0.5 * pulse)
		draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), aim, 1.0 + near)
		return
	var fade := clampf(1.0 - _since_landed / 0.35, 0.0, 1.0)
	var glow := Rect2(-half.x, -half.y * 1.6, half.x * 2.0, half.y * 3.2)
	draw_rect(glow, Color(LASER, 0.25 * fade))
	var beam := half.y * (0.4 + 0.6 * fade)
	draw_rect(Rect2(-half.x, -beam, half.x * 2.0, beam * 2.0), Color(LASER, 0.85))
	draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(1, 0.92, 0.92), 1.0 + 2.0 * fade)


## A floor plate the size of what it hits: its seams glow brighter as it
## charges, with a stray spark now and then; on landing the plate flashes and
## arcs crackle across it, a new pattern every FLICKER seconds, dying away.
func _draw_shock(near: float, pulse: float) -> void:
	var plate := Rect2(-half.x, -half.y, half.x * 2.0, half.y * 2.0)
	draw_rect(plate, Color(0.15, 0.17, 0.22, 0.6))
	var fade := clampf(1.0 - _since_landed / 0.6, 0.0, 1.0) if _landed else 1.0
	var bright := (0.2 + 0.5 * near + 0.2 * pulse) if not _landed else 0.9 * fade
	var glow := Color(SPARK, bright)
	draw_rect(plate, glow, false, 1.5)
	var seams := maxi(2, roundi(plate.size.x / 30.0))
	for i in range(1, seams):
		var x := plate.position.x + plate.size.x * i / seams
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), Color(glow, glow.a * 0.6), 1.0)
	_bolts.seed = int((_total - _left + _since_landed) / FLICKER) * 7919 + get_instance_id()
	if not _landed:
		if near > 0.5 and _bolts.randf() < near:
			_bolt(_bolts.randf_range(-half.x, half.x), 2, 4.0, Color(SPARK, 0.6))
		return
	if fade <= 0.0:
		return
	draw_rect(plate, Color(SPARK, 0.35 * fade))
	for i in seams + 1:
		var x := plate.position.x + plate.size.x * (i + _bolts.randf()) / (seams + 1)
		_bolt(x, 4, 5.0 + half.y * 0.6, Color(1, 1, 1, 0.9 * fade))


## A jagged arc rising from (x, 0): `steps` kinks, each `rise` higher.
func _bolt(x: float, steps: int, rise: float, color: Color) -> void:
	var points := PackedVector2Array([Vector2(x, 0)])
	for step in range(1, steps + 1):
		points.append(Vector2(x + _bolts.randf_range(-6.0, 6.0), -step * rise))
	draw_polyline(points, Color(SPARK, color.a * 0.5), 3.0)
	draw_polyline(points, color, 1.0)


## A seam splitting the street across its whole depth at the mark: a dark
## crack that zig-zags from the far kerb to the near one, glowing hotter as it
## comes; on landing it bursts open (the slam effect is spawned on top) and
## chunks of road jump and fall back.
func _draw_quake(near: float, pulse: float) -> void:
	_bolts.seed = get_instance_id()
	var points := PackedVector2Array()
	var steps := 8
	for i in steps + 1:
		var y := -half.y + half.y * 2.0 * i / steps
		points.append(Vector2(_bolts.randf_range(-half.x * 0.5, half.x * 0.5), y))
	var zone := Rect2(-half.x, -half.y, half.x * 2.0, half.y * 2.0)
	if not _landed:
		draw_rect(zone, Color(CRACK, 0.06 + 0.14 * near + 0.06 * pulse))
		draw_polyline(points, Color(0.1, 0.05, 0.03, 0.4 + 0.5 * near), 2.0 + 2.0 * near)
		draw_polyline(points, Color(CRACK, 0.3 + 0.6 * near * pulse), 1.0)
		return
	var fade := clampf(1.0 - _since_landed / 0.7, 0.0, 1.0)
	draw_rect(zone, Color(CRACK, 0.3 * fade))
	draw_polyline(points, Color(0.08, 0.04, 0.02, 0.9 * fade), 5.0)
	draw_polyline(points, Color(1, 0.85, 0.5, fade), 2.0)
	for i in 6:
		var jump := sin(clampf(_since_landed / 0.5, 0.0, 1.0) * PI) * (10.0 + i * 3.0)
		var at := points[i + 1] + Vector2((i % 2) * 8.0 - 4.0, -jump)
		draw_rect(Rect2(at - Vector2(2, 2), Vector2(4, 4)), Color(0.35, 0.3, 0.28, fade))


## One drop of a rain volley: a glowing mark on the ground that tightens as
## the drop comes, the drop itself falling with a short trail, and a splash of
## embers where it lands (the hit effect is spawned on top).
func _draw_rain(near: float, pulse: float) -> void:
	if not _landed:
		_ellipse(half * (1.4 - 0.5 * near), Color(EMBER, 0.15 + 0.3 * near + 0.1 * pulse))
		_ellipse_outline(half, Color(EMBER, 0.5 + 0.4 * pulse))
		if _left <= FALL_SECONDS * 2.0:
			var fall := clampf(_left / (FALL_SECONDS * 2.0), 0.0, 1.0) * RAIN_HEIGHT
			draw_line(Vector2(0, -fall - 14.0), Vector2(0, -fall), Color(EMBER, 0.5), 2.0)
			draw_circle(Vector2(0, -fall), 3.0, Color(1, 0.85, 0.5))
		return
	var fade := clampf(1.0 - _since_landed / 0.45, 0.0, 1.0)
	_ellipse(half * (1.0 + _since_landed), Color(EMBER, 0.45 * fade))
	for i in 5:
		var angle := -PI * (0.15 + 0.7 * i / 4.0)
		var reach := 6.0 + 18.0 * clampf(_since_landed / 0.3, 0.0, 1.0)
		draw_circle(Vector2(cos(angle), sin(angle)) * reach, 1.5, Color(1, 0.8, 0.4, fade))
