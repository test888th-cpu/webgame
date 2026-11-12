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
## After landing: the impact holds this long, then the mark fades out over
## LAND_FADE (quick, so a busy fight never leaves the street painted).
const LAND_HOLD := 0.2
const LAND_FADE := 0.3
## A warning called off (its boss fell or left) fades this fast, no impact.
const DISMISS_FADE := 0.18
## The safety net: a warning still on the street this long after it should
## have landed goes by itself, whatever happened to its hazard (presentation
## only; ZoneSim alone decides hits).
const OVERDUE_SECONDS := 0.5
const OVERDUE_SLACK := 1.5
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
## The telegraph language: the danger colour of
## each kind (what the ground does) and each boss theme's accent (who calls it).
const DANGER := {
	"quake": Color(1.0, 0.42, 0.12),
	"shock": Color(0.42, 0.86, 1.0),
	"steam": Color(1.0, 0.78, 0.52),
	"sludge": Color(0.55, 0.95, 0.25),
	"crane": Color(1.0, 0.3, 0.18),
	"rain": Color(1.0, 0.6, 0.18),
	"laser": Color(1.0, 0.2, 0.25),
}
const ACCENT := {
	"brawl": Color(1.0, 0.38, 0.28),
	"fire": Color(1.0, 0.66, 0.2),
	"toxic": Color(0.62, 1.0, 0.3),
	"tech": Color(0.4, 0.92, 1.0),
	"shadow": Color(0.78, 0.5, 1.0),
}
## The last seconds of a warning: the mark locks white-hot.
const LOCK_SECONDS := 0.2
## How far the drawn danger shape reaches past the hit rectangle (px).
const EDGE_GROW := 2.5
## A steam area this wide or wider is "large" (one big vented plate).
const LARGE_STEAM_WIDTH := 100.0
## A rain tile this tall or taller is "large" (a whole span of the street).
const LARGE_RAIN_HEIGHT := 40.0
## The last seconds of a large steam warning: the plate flashes twice.
const STEAM_FLASH_SECONDS := 0.35
## Heat ramp for steam: dull red to orange to white-hot (dark to bright).
const HEAT := [
	Color(0.45, 0.08, 0.05), Color(0.95, 0.35, 0.1), Color(1.0, 0.7, 0.3), Color(1.0, 0.95, 0.8)
]
## Sludge: oil-dark body, toxic front.
const OOZE := Color(0.1, 0.16, 0.05)
const TOXIC := Color(0.62, 1.0, 0.28)
## Rain: one target for every TARGET_CELL of footprint (at most RAIN_TARGETS).
const TARGET_CELL := Vector2(34.0, 22.0)
const RAIN_TARGETS := 4

var kind := "crane"
## The calling boss's theme (boss_fx.json "bosses"): the accent of its marks.
var theme := "brawl"
## How loudly it warns (boss_fx.json "telegraph"): "full" (an Ultimate's waves:
## the whole lifecycle) or "minimal" (any other hazard: a seam and the
## hazard's own cue, for the same unchanged warning time).
var level := "full"
## Half the footprint it hits (as ZoneSim measures it).
var half := Vector2(30, 10)
## The road's top and bottom edge (y, relative to this node): the street a
## "quake" is drawn on, so its crack never climbs onto the pavement or the
## shopfronts. Set by GameFeedback from the zone's bounds.
var lane := Vector2(-INF, INF)
## The zone's own hazard entry (ZoneSim.hazards), when known: its "ticks"
## drive the countdown, so the warning ends exactly when the hit lands, at
## any frame rate.
var source: Dictionary = {}
## The danger shape and its seam, built once (the geometry never changes).
var _outline := PackedVector2Array()
var _seam_points := PackedVector2Array()
var _seam_colors := PackedColorArray()
var _rings: Array[PackedVector2Array] = []
## The danger shape for fills: the same rounded rectangle without the 2 px
## points along its straight edges (only the seam needs those), so a fill is
## not re-triangulated from hundreds of points every frame.
var _fill := PackedVector2Array()
## The large warnings' unchanging parts, recorded once (HazardLayers); again
## only when what they are drawn from changes (_layer_key).
var _layers := HazardLayers.new()
var _layer_key := ""
var _bracket_slide := -1.0
## What is in the air (a falling container or drop, rising vapour): drawn
## above the fighters, while the warning itself lies on the street under them.
var _air: Node2D = null
var _left := 1.0
var _total := 1.0
var _landed := false
var _since_landed := 0.0
## Seconds since it appeared, and whether it is already on its way out.
var _age := 0.0
var _leaving := false
var _bolts := RandomNumberGenerator.new()


## `seconds` until it lands (or bursts) at this node's position (its feet line).
func setup(seconds: float, p_kind := "crane", p_half := Vector2(30, 10)) -> void:
	_total = maxf(seconds, 0.05)
	_left = _total
	kind = p_kind
	half = p_half


func _ready() -> void:
	# Only what has something in the air gets the layer above the fighters.
	if kind in ["crane", "rain"] or (kind == "steam" and level == "full"):
		_air = Node2D.new()
		_air.z_index = 4
		_air.draw.connect(_draw_air)
		add_child(_air)


func land() -> void:
	if _leaving:
		return
	_leaving = true
	_landed = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LAND_FADE).set_delay(LAND_HOLD)
	tween.tween_callback(queue_free)
	queue_redraw()


## Clears the warning without an impact: its hazard was called off.
func dismiss() -> void:
	if _leaving:
		return
	_leaving = true
	_layers.hide_all()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DISMISS_FADE)
	tween.tween_callback(queue_free)


## True when the warning has outstayed its hazard: its countdown ran out
## OVERDUE_SECONDS ago without landing, or it has been up far longer than it
## was ever meant to be (its hazard went without a word).
func overdue() -> bool:
	if _leaving:
		return false
	var late := _left <= 0.0 and _age > _total + OVERDUE_SECONDS
	return late or _age > _total * 1.5 + OVERDUE_SLACK


func _process(delta: float) -> void:
	_age += delta
	if overdue():
		dismiss()
	if not source.is_empty() and not _landed:
		_left = maxf(0.0, float(source.get("ticks", 0)) / CombatRules.TICK_RATE)
	else:
		_left = maxf(0.0, _left - delta)
	if _landed:
		_since_landed += delta
	queue_redraw()
	if _air:
		_air.queue_redraw()


func _draw() -> void:
	var near := 1.0 - _left / _total
	var pulse := 0.5 + 0.5 * sin(near * 24.0)
	if not _landed and kind != "laser":
		_telegraph(near)
		return
	_layers.hide_all()
	if _landed and kind != "laser":
		_impact_mark()
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


func _draw_container(canvas: CanvasItem) -> void:
	var fall := 0.0 if _landed else clampf(_left / FALL_SECONDS, 0.0, 1.0)
	if _landed or _left <= FALL_SECONDS:
		var box := Vector2(half.x * 2.0, half.x * 2.0 * BOX_HEIGHT)
		var top := Vector2(-box.x / 2.0, -box.y - fall * DROP_HEIGHT)
		# A shipping container in pixel-art shading: lit roof, darker base,
		# corrugated ribs with a highlight each, and steel corner castings.
		canvas.draw_rect(Rect2(top, box), STEEL)
		canvas.draw_rect(Rect2(top, Vector2(box.x, 3)), STEEL.lightened(0.3))
		canvas.draw_rect(Rect2(top + Vector2(0, box.y - 4), Vector2(box.x, 4)), RIB)
		var ribs := maxi(4, roundi(box.x / 9.0))
		for i in range(1, ribs):
			var x := top.x + box.x * i / ribs
			canvas.draw_line(Vector2(x, top.y + 4), Vector2(x, top.y + box.y - 5), RIB, 2.0)
			canvas.draw_line(
				Vector2(x + 2, top.y + 4), Vector2(x + 2, top.y + box.y - 5), STEEL.lightened(0.15)
			)
		for corner in [top, top + Vector2(box.x - 4, 0), top + Vector2(0, box.y - 4)]:
			canvas.draw_rect(Rect2(corner, Vector2(4, 4)), EDGE)
		canvas.draw_rect(Rect2(top + Vector2(box.x - 4, box.y - 4), Vector2(4, 4)), EDGE)
		canvas.draw_rect(Rect2(top, box), EDGE, false, 1.0)
		# Two crane cables to the corners, cut the moment it lands.
		if not _landed:
			for corner in [top + Vector2(4, 0), top + Vector2(box.x - 4, 0)]:
				canvas.draw_line(corner, Vector2(0, top.y - DROP_HEIGHT), EDGE, 1.0)


func _ellipse_outline(radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 25:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_polyline(points, color, 1.5)


func _ellipse(radius: Vector2, color: Color, center := Vector2.ZERO) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


## A round floor vent as wide as what it hits, hissing wisps that thicken as it
## comes; the column itself is the pixelfx burst on landing (steam_burst,
## sludge_splash), after which only the vent stays, glowing as it cools.
func _draw_steam(near: float) -> void:
	var vent := Vector2(half.x * 0.6, 3.5)
	_ellipse(vent, GRATE)
	var bars := maxi(3, roundi(vent.x / 3.0))
	for i in range(1, bars):
		var x := -vent.x + vent.x * 2.0 * i / bars
		var depth := vent.y * sqrt(maxf(0.0, 1.0 - pow(x / vent.x, 2.0)))
		draw_line(Vector2(x, -depth), Vector2(x, depth), GRATE_BAR, 1.0)
	var tint := SLUDGE if kind == "sludge" else STEAM
	if _landed:
		_ellipse_outline(vent, Color(tint, 0.5 * maxf(0.0, 1.0 - _since_landed)))
		return
	for i in 4:
		var rise := fmod(near * 3.0 + i * 0.25, 1.0)
		var x := -vent.x + vent.x * 2.0 * (i + 0.5) / 4.0 + sin(rise * 9.0 + i) * 2.0
		draw_circle(
			Vector2(x, -4.0 - rise * 14.0 * near), 1.5 + near * 2.0, Color(tint, 0.35 * near)
		)


## A beam across the lane, its full width: while it charges, a dashed aiming
## line that flickers over a soft glow building at the hero's depth; when it
## fires, layered light (a wide haze, the beam, a white-hot core) that narrows
## as it fades. Spark sprites burst along it (GameFeedback), so it reads as
## light, not a painted band.
func _draw_laser(near: float, pulse: float) -> void:
	if not _landed:
		for layer in 3:
			var width := half.y * (1.0 + layer) * (0.4 + 0.8 * near)
			var alpha := (0.05 + 0.12 * near) / (layer + 1.0)
			draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(LASER, alpha), width)
		var dash := 10.0
		var x := -half.x + fmod(near * 160.0, dash * 2.0)
		while x < half.x:
			var aim := Color(LASER, 0.4 + 0.5 * pulse)
			draw_line(Vector2(x, 0), Vector2(minf(x + dash, half.x), 0), aim, 1.0 + near)
			x += dash * 2.0
		return
	var fade := clampf(1.0 - _since_landed / 0.35, 0.0, 1.0)
	var beam := half.y * (0.4 + 0.6 * fade)
	draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(LASER, 0.15 * fade), beam * 5.0)
	draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(LASER, 0.35 * fade), beam * 3.0)
	draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(LASER, 0.85), beam * 1.6)
	draw_line(Vector2(-half.x, 0), Vector2(half.x, 0), Color(1, 0.92, 0.92), 1.0 + 2.0 * fade)


## An electric field on the ground, an oval the size of what it hits: a soft
## glow that brightens as it charges, its rim pulsing, arcs crawling across it
## (more as it comes, a new pattern every FLICKER seconds); when it fires the
## field flashes and bolts leap up from it, while lightning sprites strike
## across the whole field (GameFeedback, shock_zap).
func _draw_shock(near: float, pulse: float) -> void:
	var field := Vector2(half.x, half.y * 1.3)
	_bolts.seed = int((_total - _left + _since_landed) / FLICKER) * 7919 + get_instance_id()
	if not _landed:
		_ellipse(field, Color(SPARK, 0.06 + 0.16 * near + 0.06 * pulse))
		_ellipse_outline(field, Color(SPARK, 0.2 + 0.5 * near * pulse))
		for arc in 1 + roundi(near * 4.0):
			_ground_arc(field, Color(SPARK, 0.35 + 0.5 * near))
		return
	var fade := clampf(1.0 - _since_landed / 0.6, 0.0, 1.0)
	if fade <= 0.0:
		return
	_ellipse(field * (1.0 + 0.25 * (1.0 - fade)), Color(SPARK, 0.35 * fade))
	for arc in 4:
		_ground_arc(field, Color(1, 1, 1, 0.9 * fade))
	for bolt in 4:
		var x := _bolts.randf_range(-field.x * 0.8, field.x * 0.8)
		_bolt(x, 4, 5.0 + half.y * 0.6, Color(1, 1, 1, 0.9 * fade))


## A jagged arc crawling along the ground between two points of `field` (an
## oval's half size): a soft glow under a bright line.
func _ground_arc(field: Vector2, color: Color) -> void:
	var from := Vector2(
		_bolts.randf_range(-field.x, 0.0), _bolts.randf_range(-field.y, field.y) * 0.6
	)
	var to := Vector2(_bolts.randf_range(0.0, field.x), _bolts.randf_range(-field.y, field.y) * 0.6)
	var points := PackedVector2Array([from])
	for step in range(1, 6):
		var at := from.lerp(to, step / 6.0)
		points.append(at + Vector2(0, _bolts.randf_range(-4.0, 4.0)))
	points.append(to)
	draw_polyline(points, Color(SPARK, color.a * 0.35), 3.0)
	draw_polyline(points, color, 1.0)


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
	var top := maxf(-half.y, lane.x)
	var bottom := minf(half.y, lane.y)
	var points := PackedVector2Array()
	var steps := 8
	for i in steps + 1:
		var y := top + (bottom - top) * i / steps
		points.append(Vector2(_bolts.randf_range(-half.x * 0.5, half.x * 0.5), y))
	var glow := Vector2(half.x * 1.4, (bottom - top) / 2.0)
	var middle := Vector2(0, (top + bottom) / 2.0)
	if not _landed:
		_ellipse(glow, Color(CRACK, 0.05 + 0.12 * near + 0.05 * pulse), middle)
		# Readable on any street: the column it splits, at its true size (the
		# hit test's half extents), in the other ground warnings' danger red.
		var band := Rect2(Vector2(-half.x, top), Vector2(half.x * 2.0, bottom - top))
		draw_rect(band, Color(0.9, 0.1, 0.05, 0.12 + 0.22 * near + 0.08 * pulse))
		var edge := Color(1, 0.25, 0.1, 0.55 + 0.4 * pulse)
		draw_line(band.position, band.position + Vector2(0, band.size.y), edge, 2.0)
		draw_line(band.end - Vector2(0, band.size.y), band.end, edge, 2.0)
		draw_polyline(points, Color(0.1, 0.05, 0.03, 0.4 + 0.5 * near), 2.0 + 2.0 * near)
		draw_polyline(points, Color(CRACK, 0.3 + 0.6 * near * pulse), 1.0)
		return
	# The landing: the same fracture bursts open white-hot, then cools and
	# fades (the pixelfx slam and its dust are spawned on top).
	var fade := clampf(1.0 - _since_landed / 0.7, 0.0, 1.0)
	var seam := _crack_path(_footprint())
	draw_polyline(seam, Color(0.05, 0.02, 0.02, 0.9 * fade), 3.0)
	draw_polyline(seam, Color(1, 0.85, 0.55, fade), 1.0)
	for i in 6:
		var jump := sin(clampf(_since_landed / 0.5, 0.0, 1.0) * PI) * (6.0 + i * 2.0)
		var at := seam[clampi(1 + i * (seam.size() - 2) / 6, 0, seam.size() - 1)]
		draw_rect(
			Rect2(at + Vector2((i % 2) * 4.0 - 2.0, -jump), Vector2(2, 2)),
			Color(0.4, 0.36, 0.33, fade)
		)


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


# --- Telegraph ----------------------------------------------------------------


## Above the fighters: the container falling and landing, each rain drop
## falling on the countdown, the vapour a steam vent puffs.
func _draw_air() -> void:
	if kind == "crane" and (_landed or _left <= FALL_SECONDS):
		_draw_container(_air)
	if _landed:
		return
	var area := _footprint()
	var near := 1.0 - _left / _total
	if kind == "rain" and _left <= FALL_SECONDS * 2.0:
		var fall := clampf(_left / (FALL_SECONDS * 2.0), 0.0, 1.0) * RAIN_HEIGHT
		var drop := _rain_mark(area) + Vector2(0, -fall)
		_air.draw_line(drop + Vector2(0, -12), drop, Color(1.0, 0.62, 0.2, 0.5), 1.0)
		_air.draw_rect(Rect2(drop - Vector2(1, 2), Vector2(3, 4)), Color(1, 0.9, 0.6))
	if kind == "steam" and level == "full":
		var interval := lerpf(0.9, 0.16, near)
		var age := fmod(_total - _left, interval) / interval
		for k in 3:
			var life := fmod(age + k / 3.0, 1.0)
			var at := (
				area.get_center()
				+ Vector2((k - 1) * area.size.x * 0.1, -3.0 - life * (8.0 + 14.0 * near))
			)
			_air.draw_circle(
				at, 2.0 + life * (3.0 + 4.0 * near), Color(1, 0.97, 0.94, 0.45 * (1.0 - life))
			)


## The hit footprint on the street: exactly the rectangle the hit test uses
## (BossMechanics: |dx| <= half.x, |dy| <= half.y), clipped to the walkable road.
func _footprint() -> Rect2:
	var top := maxf(-half.y, lane.x)
	var bottom := minf(half.y, lane.y)
	return Rect2(Vector2(-half.x, top), Vector2(half.x * 2.0, maxf(1.0, bottom - top)))


## The warning, in phases: appear (corners slide in), build (light gathers on
## the rim, the timing ring grows from the middle), lock (white-hot rim, the
## last LOCK_SECONDS). Lines and light, never a flat fill; the dark outer line
## keeps it readable on a bright street, the light on a dark one.
func _telegraph(near: float) -> void:
	var area := _footprint()
	var hue: Color = DANGER.get(kind, DANGER["crane"])
	var accent: Color = ACCENT.get(theme, ACCENT["brawl"])
	var appear := clampf(near / 0.12, 0.0, 1.0)
	var lock := _left <= LOCK_SECONDS
	var clock := _total - _left
	# The danger shape: the hit rectangle grown by EDGE_GROW with round
	# corners (it contains every point the hit test can reach, and claims at
	# most EDGE_GROW px more): soft ground, not a panel.
	var key := "%s|%s|%s|%s" % [kind, half, level, theme]
	if key != _layer_key:
		_layers.free_all()
		_bracket_slide = -1.0
		_outline = PackedVector2Array()
		_fill = PackedVector2Array()
		_rings.clear()
		_seam_points = PackedVector2Array()
		_layer_key = key
	_layers.hide_all()
	if _outline.is_empty():
		_build_shape(area)
	var outline := _outline
	var full := level == "full"
	match kind:
		"steam":
			_steam_family(area, near, appear, lock, clock, full)
			return
		"rain":
			_rain_family(area, near, appear, lock, clock, full)
			return
		"sludge":
			_sludge_family(area, near, appear, lock, clock, full)
			return
	if full:
		draw_colored_polygon(_fill, Color(0.02, 0.0, 0.02, (0.2 + 0.16 * near) * appear))
	match kind:
		"quake":
			if full:
				_quake_cracks(area, near, hue)
		"shock":
			if full or int((_total - _left) / 0.4) % 2 == 0:
				_shock_arcs(area, near * (1.0 if full else 0.3))
		"steam", "sludge":
			_vent_wisps(area, near, hue)
		"crane":
			_drop_shadow(area, near)
	# A little light pooled inside the seam.
	if not full:
		_seam(outline, area, hue, near * 0.6, appear, lock, clock, false)
		return
	for i in _rings.size():
		draw_polyline(_rings[i], Color(hue, (0.1 + 0.2 * near) * (1.0 - i / 3.0) * appear), 1.0)
	# The boss's accent pulsing out from the middle, quicker as it comes.
	var period := lerpf(0.7, 0.18, near)
	var phase := fmod(clock / period, 1.0)
	var size := area.size * phase
	if size.x >= 2.0 and size.y >= 2.0:
		var pulse_area := Rect2(area.get_center() - size / 2.0, size)
		var pulse_ring := HazardShapes.rounded(pulse_area, 2.0, false)
		draw_polyline(pulse_ring, Color(accent, 0.3 * (1.0 - phase) * appear), 1.0)
	_seam(outline, area, hue, near, appear, lock, clock, true)
	if lock:
		draw_colored_polygon(_fill, Color(1, 0.9, 0.75, 0.12))


## The danger's edge as a seam in the street: a dark crack that wanders only
## outward from the true edge (never inside it), its hot core glowing with
## the hazard's own colour, brighter and quicker as it comes, and in the last
## stretch the hazard itself escaping from it (dust and embers, sparks, ooze,
## vapour). White-hot when it locks.
func _seam(
	_outline_points: PackedVector2Array,
	_area: Rect2,
	hue: Color,
	near: float,
	appear: float,
	lock: bool,
	clock: float,
	escaping: bool
) -> void:
	var seam := _seam_points
	draw_polyline(seam, Color(0.04, 0.02, 0.03, 0.85 * appear), 2.0)
	var core := Color(1, 0.96, 0.88) if lock else hue.lerp(Color(1, 0.95, 0.8), 0.25 * near)
	var speed := lerpf(5.0, 16.0, near)
	for i in seam.size():
		var travel := 0.5 + 0.5 * sin(i * 0.55 - clock * speed)
		var alpha := 1.0 if lock else (0.25 + 0.55 * near) * (0.45 + 0.55 * travel)
		_seam_colors[i] = Color(core, alpha * appear)
	draw_polyline_colors(seam, _seam_colors, 1.0)
	if near < 0.55 or lock or not escaping:
		return
	var escape := (near - 0.55) / 0.45
	for e in 10:
		var at := seam[(e * 7 + int(clock * 3.0)) % seam.size()]
		var rise := fmod(clock * 1.6 + e * 0.13, 1.0)
		var fleck := at + Vector2(sin(e * 2.3 + clock * 4.0) * 1.5, -rise * (4.0 + 8.0 * escape))
		var tone := hue.lerp(Color(1, 1, 1), 0.4) if kind != "quake" else Color(0.55, 0.5, 0.45)
		draw_rect(Rect2(fleck, Vector2(1, 1)), Color(tone, (1.0 - rise) * escape))
		if kind == "quake" and e % 3 == 0:
			draw_rect(
				Rect2(at + Vector2(0, -rise * 6.0), Vector2(1, 1)),
				Color(1, 0.75, 0.35, (1.0 - rise) * escape)
			)


## The danger shape, the light rings inside it and its seam (wandering only
## outward from the true edge), computed once.
func _build_shape(area: Rect2) -> void:
	_outline = HazardShapes.rounded(area, EDGE_GROW)
	_fill = HazardShapes.rounded(area, EDGE_GROW, false)
	for i in 2:
		var inset := 1.0 + i * 2.5
		if area.size.x <= inset * 2.0 + 1.0 or area.size.y <= inset * 2.0 + 1.0:
			break
		_rings.append(HazardShapes.rounded(area, EDGE_GROW - inset, false))
	_bolts.seed = get_instance_id() * 13
	var centre := area.get_center()
	for point in _outline:
		var out := point - centre
		out = Vector2(out.x / maxf(area.size.x, 1.0), out.y / maxf(area.size.y, 1.0)).normalized()
		_seam_points.append(point + out * _bolts.randf_range(0.0, 1.8))
	_seam_colors.resize(_seam_points.size())


## Hairline fractures growing across the column from its middle, a hot seam
## glowing inside, embers flickering on it, dust lifting as the hit nears.
## The fracture's path across the column: fine, wandering, the same every
## frame (warning and landing share it).
func _crack_path(area: Rect2) -> PackedVector2Array:
	_bolts.seed = get_instance_id()
	var steps := maxi(8, int(area.size.y / 4.0))
	var points := PackedVector2Array()
	var x := 0.0
	for i in steps + 1:
		x = clampf(x + _bolts.randf_range(-2.5, 2.5), -area.size.x * 0.2, area.size.x * 0.2)
		points.append(Vector2(area.get_center().x + x, area.position.y + area.size.y * i / steps))
	return points


func _quake_cracks(area: Rect2, near: float, hue: Color) -> void:
	var points := _crack_path(area)
	var steps := points.size() - 1
	# The seam opens from the middle outward as the quake gathers.
	var grown := clampf(near * 1.5, 0.0, 1.0)
	var middle := steps / 2
	var reach := roundi(grown * middle)
	var seam := PackedVector2Array()
	for i in range(middle - reach, middle + reach + 1):
		seam.append(points[clampi(i, 0, steps)])
	if seam.size() >= 2:
		draw_polyline(seam, Color(0.05, 0.02, 0.02, 0.8), 2.0)
		var hot := hue.lerp(Color(1, 0.9, 0.6), 0.3 + 0.5 * near)
		draw_polyline(seam, Color(hot, 0.35 + 0.55 * near), 1.0)
	# Hairline branches, short and late.
	for b in 4:
		var at := points[clampi(middle + (b - 2) * maxi(1, steps / 6), 0, steps)]
		var open := clampf((near - 0.3 - b * 0.08) * 2.5, 0.0, 1.0)
		if open <= 0.0:
			continue
		var side := 1.0 if b % 2 == 0 else -1.0
		var tip := (
			at + Vector2(side * (3.0 + area.size.x * 0.18) * open, _bolts.randf_range(-4.0, 4.0))
		)
		var bend := at.lerp(tip, 0.5) + Vector2(0, _bolts.randf_range(-2.0, 2.0))
		draw_polyline(PackedVector2Array([at, bend, tip]), Color(0.05, 0.02, 0.02, 0.7), 1.0)
		draw_line(at, bend, Color(hue, 0.5 * near), 1.0)
	# Embers in the seam; rubble hopping in the last fifth.
	for e in 8:
		var at := points[clampi(middle - reach + roundi(float(e) / 8.0 * reach * 2), 0, steps)]
		var flick := fmod(_total - _left + e * 0.37, 0.5) * 2.0
		draw_rect(Rect2(at, Vector2(1, 1)), Color(1, 0.9, 0.55, flick * grown))
	if near > 0.8:
		for d in 6:
			var hop := absf(sin((_total - _left) * 18.0 + d)) * 3.0 * (near - 0.8) * 5.0
			var at := points[clampi(d * steps / 6 + 1, 0, steps)] + Vector2(d % 3 - 1, -hop)
			draw_rect(Rect2(at, Vector2(1, 1)), Color(0.5, 0.46, 0.42, 0.9))


## Arcs crawling between points inside the footprint, more as it charges.
func _shock_arcs(area: Rect2, near: float) -> void:
	_bolts.seed = int((_total - _left) / FLICKER) * 7919 + get_instance_id()
	var field := area.size / 2.0
	for arc in 1 + roundi(near * 4.0):
		var c := area.get_center()
		var from := (
			c
			+ Vector2(
				_bolts.randf_range(-field.x, 0.0), _bolts.randf_range(-field.y, field.y) * 0.8
			)
		)
		var to := (
			c
			+ Vector2(_bolts.randf_range(0.0, field.x), _bolts.randf_range(-field.y, field.y) * 0.8)
		)
		var points := PackedVector2Array([from])
		for step in range(1, 6):
			points.append(from.lerp(to, step / 6.0) + Vector2(0, _bolts.randf_range(-3.0, 3.0)))
		points.append(to)
		draw_polyline(points, Color(SPARK, 0.2 + 0.2 * near), 3.0)
		draw_polyline(points, Color(0.9, 0.98, 1.0, 0.45 + 0.45 * near), 1.0)


## The floor vent and its wisps (steam, sludge), and for sludge bubbles
## popping across the footprint.
func _vent_wisps(area: Rect2, near: float, hue: Color) -> void:
	# The floor heats (steam) or floods (sludge) out from the vent.
	var spread := area.size * (0.35 + 0.65 * near) / 2.0
	_ellipse(spread, Color(hue, 0.08 + 0.14 * near), area.get_center())
	_ellipse(spread * 0.55, Color(hue.lightened(0.3), 0.06 + 0.12 * near), area.get_center())
	_draw_steam(near)
	if kind == "sludge":
		_bolts.seed = get_instance_id()
		for i in 6:
			var at := (
				area.get_center()
				+ Vector2(
					_bolts.randf_range(-0.8, 0.8) * area.size.x / 2.0,
					_bolts.randf_range(-0.7, 0.7) * area.size.y / 2.0
				)
			)
			var grow := fmod((_total - _left) * 1.4 + i * 0.17, 1.0)
			draw_arc(at, 1.0 + 2.5 * grow, 0.0, TAU, 10, Color(hue, 0.6 * (1.0 - grow) * near), 1.0)


## The container's shadow darkening on the street as it comes.
func _drop_shadow(area: Rect2, near: float) -> void:
	var size := area.size * (0.45 + 0.55 * near)
	draw_rect(
		Rect2(area.get_center() - size / 2.0, size), Color(0.02, 0.02, 0.03, 0.18 + 0.3 * near)
	)


## The landing: the footprint flashes and is gone (the hazard's own landing
## effects and the pixelfx burst follow).
func _impact_mark() -> void:
	var fade := clampf(1.0 - _since_landed / 0.25, 0.0, 1.0)
	if fade <= 0.0:
		return
	var area := _footprint()
	var hue: Color = DANGER.get(kind, DANGER["crane"])
	draw_rect(area, Color(hue.lerp(Color.WHITE, 0.6), 0.45 * fade * fade))


# --- Steam / rain / sludge families --------------------------------------------


func _heat(t: float) -> Color:
	var x := clampf(t, 0.0, 1.0) * (HEAT.size() - 1)
	var i := mini(int(x), HEAT.size() - 2)
	return (HEAT[i] as Color).lerp(HEAT[i + 1], x - i)


## The seam as one line: dark under, `core` over.
func _plain_seam(core: Color, alpha: float, appear: float) -> void:
	draw_polyline(_seam_points, Color(0.04, 0.02, 0.03, 0.8 * appear), 2.0)
	draw_polyline(_seam_points, Color(core, alpha * appear), 1.0)


## STEAM: the deck plates heat up around a vent while the pressure builds:
## the seam and the plate joints glow from dull red to white-hot, the vent
## puffs quicker and quicker, the floor around it warms. Locks white-hot.
func _steam_family(
	area: Rect2, near: float, appear: float, lock: bool, clock: float, full: bool
) -> void:
	if full and area.size.x >= LARGE_STEAM_WIDTH:
		_steam_large(area, near, appear, lock, clock)
		return
	var heat := _heat(0.65 + 0.35 * near) if not lock else Color(1, 0.97, 0.9)
	var centre := area.get_center()
	# The plate scorches dark as it heats: the area reads on any street.
	var scorch := (0.26 + 0.2 * near) if full else 0.16
	draw_colored_polygon(_fill, Color(0.07, 0.02, 0.01, scorch * appear))
	if full:
		var warm := area.size * (0.3 + 0.35 * near) / 2.0
		_ellipse(warm, Color(_heat(0.4 + 0.4 * near), (0.08 + 0.14 * near) * appear), centre)
		var joints := maxi(1, int(area.size.x / 28.0))
		for j in joints:
			var x := area.position.x + area.size.x * (j + 1) / (joints + 1)
			var dark := Color(0.05, 0.02, 0.02, 0.5 * appear)
			draw_line(Vector2(x, area.position.y + 2), Vector2(x, area.end.y - 2), dark, 1.0)
			var lit := Color(heat, (0.15 + 0.5 * near) * appear)
			draw_line(Vector2(x + 1, area.position.y + 3), Vector2(x + 1, area.end.y - 3), lit, 1.0)
	_draw_steam(near)
	# The vent's hot core, brighter as the pressure builds.
	_ellipse(
		Vector2(area.size.x * 0.12, 2.5),
		Color(_heat(0.6 + 0.4 * near), (0.3 + 0.6 * near) * appear),
		centre
	)
	var interval := lerpf(0.9, 0.16, near)
	var age := fmod(clock, interval) / interval
	if full:
		# Heat glowing inward from the seam, the plate's edges first.
		for i in _rings.size():
			var band := (0.5 - i * 0.15) * (0.55 + 0.45 * near)
			draw_polyline(_rings[i], Color(heat, band * appear), 2.0)
	var glow := 1.0 if lock else (0.3 + 0.6 * near) * (0.75 + 0.25 * sin(age * TAU))
	draw_polyline(_seam_points, Color(0.05, 0.02, 0.02, 0.8 * appear), 3.0)
	draw_polyline(
		_seam_points, Color(heat, (glow if full else glow * 0.7) * appear), 2.0 if full else 1.0
	)
	if lock and full:
		draw_colored_polygon(_fill, Color(1, 0.85, 0.6, 0.14))


## Where the drop lands in `area`: near the middle, a little off it.
func _rain_mark(area: Rect2) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id() * 7
	var jitter := Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
	return area.get_center() + jitter * area.size


## RAIN: where each drop will land, marked into the street: the drop's
## shadow growing as it falls, an ember glint blinking faster, scuffs at the
## true corners of what it hits; the drop itself falls on the countdown.
func _rain_family(
	area: Rect2, near: float, appear: float, lock: bool, clock: float, full: bool
) -> void:
	if full and area.size.y > LARGE_RAIN_HEIGHT:
		_rain_large(area, near, appear, lock, clock)
		return
	var ember := Color(1.0, 0.62, 0.2)
	var mark := _rain_mark(area)
	if area.size.y > 40.0:
		draw_colored_polygon(_fill, Color(0.05, 0.02, 0.01, (0.12 + 0.14 * near) * appear))
	var shadow := Vector2(area.size.x * (0.12 + 0.22 * near), area.size.y * (0.08 + 0.16 * near))
	_ellipse(shadow, Color(0.02, 0.01, 0.02, (0.25 + 0.4 * near) * appear), mark)
	var blink := 0.5 + 0.5 * sin(clock * lerpf(6.0, 24.0, near))
	var glint := Color(ember.lerp(Color.WHITE, 0.3), (0.5 + 0.5 * blink) * appear)
	draw_rect(Rect2(mark - Vector2(1, 1), Vector2(2, 2)), glint)
	var tick := minf(4.0, minf(area.size.x, area.size.y) * 0.25)
	var tick_color := Color(ember.lerp(Color.WHITE, 0.2), (0.55 + 0.4 * near) * appear)
	if lock:
		tick_color = Color(1, 0.96, 0.88)
	for cx in [-1.0, 1.0]:
		for cy in [-1.0, 1.0]:
			var half_size := area.size / 2.0 + Vector2.ONE
			var corner := area.get_center() + Vector2(cx * half_size.x, cy * half_size.y)
			draw_line(corner, corner - Vector2(cx * tick, 0), tick_color, 1.0)
			draw_line(corner, corner - Vector2(0, cy * tick), tick_color, 1.0)
	_plain_seam(ember, 1.0 if lock else (0.45 + 0.45 * near) * (1.0 if full else 0.7), appear)


## SLUDGE: drain sludge seeping up through the street and spreading: an
## oil-dark, see-through body with a bright toxic front that reaches the seam
## exactly at the impact; bubbles break on it, the seam darkens and stains.
func _sludge_family(
	area: Rect2, near: float, appear: float, lock: bool, clock: float, full: bool
) -> void:
	var centre := area.get_center()
	var spread := 0.25 + 0.75 * near
	var body := PackedVector2Array()
	_bolts.seed = get_instance_id() * 3
	var phase_a := _bolts.randf_range(0.0, TAU)
	var phase_b := _bolts.randf_range(0.0, TAU)
	for i in 32:
		var angle := TAU * i / 32.0
		var lobe := 1.0 + 0.09 * sin(angle * 3.0 + phase_a) + 0.05 * sin(angle * 5.0 + phase_b)
		lobe += 0.02 * sin(clock * 2.0 + angle * 2.0)
		var reach := Vector2(cos(angle) * area.size.x, sin(angle) * area.size.y) * 0.72
		var at := centre + reach * spread * lobe
		at.x = clampf(at.x, area.position.x, area.end.x)
		at.y = clampf(at.y, area.position.y, area.end.y)
		body.append(at.round())
	var oil := (0.32 + 0.2 * near) if full else 0.22
	draw_colored_polygon(body, Color(OOZE, oil * appear))
	var front := body.duplicate()
	front.append(body[0])
	draw_polyline(front, Color(TOXIC, (0.35 + 0.35 * near) * appear), 1.0)
	_draw_steam(near)
	if full:
		for i in 4:
			var spot := Vector2(_bolts.randf_range(-0.5, 0.5), _bolts.randf_range(-0.4, 0.4))
			var at := centre + spot * area.size * spread
			var pop := fmod(clock * 1.2 + i * 0.27, 1.0)
			draw_arc(
				at, 1.0 + 2.0 * pop, 0.0, TAU, 8, Color(TOXIC, 0.6 * (1.0 - pop) * appear), 1.0
			)
	var stain := Color(0.9, 1, 0.75) if lock else Color(0.04, 0.06, 0.02)
	draw_polyline(_seam_points, Color(stain, 0.85 * appear), 2.0)
	var edge := 1.0 if lock else (0.2 + 0.45 * near)
	draw_polyline(_seam_points, Color(TOXIC, edge * appear), 1.0)


## LARGE STEAM: one big plate over a vent. Pressure waves ripple from the
## vent to the edge on a quickening beat, the edge glows inward first and
## its seam runs white-hot with a dark line under it and a heat halo out of
## it, the vent's core swells with every beat, and the plate flashes twice
## in its last moments.
func _steam_large(area: Rect2, near: float, appear: float, lock: bool, clock: float) -> void:
	var centre := area.get_center()
	var heat := _heat(0.7 + 0.3 * near) if not lock else Color(1, 0.98, 0.92)
	var interval := lerpf(0.85, 0.2, near)
	var beat := fmod(clock, interval) / interval
	if _layers.is_empty():
		_record_steam_large()
	_layers.show("fill", Color(0.07, 0.02, 0.01, (0.38 + 0.17 * near) * appear))
	# The edge heats first: light bands glowing inward from the seam.
	for i in _rings.size():
		var band := (0.6 - i * 0.2) * (0.6 + 0.4 * near)
		_layers.show("ring%d" % i, Color(heat, band * appear))
	# Pressure waves: from the vent out to the edge, once a beat.
	for k in 2:
		var phase := fmod(beat + k * 0.5, 1.0)
		var size := Vector2(area.size.x * 0.2, area.size.y * 0.2).lerp(area.size, phase)
		var wave := Rect2(centre - size / 2.0, size)
		var ring := Color(_heat(0.75 + 0.25 * near), (0.5 * (1.0 - phase)) * appear)
		draw_polyline(HazardShapes.rounded(wave, 3.0, false), ring, 1.0)
	var joints := maxi(1, int(area.size.x / 28.0))
	for j in joints:
		var x := area.position.x + area.size.x * (j + 1) / (joints + 1)
		var dark := Color(0.05, 0.02, 0.02, 0.6 * appear)
		draw_line(Vector2(x, area.position.y + 3), Vector2(x, area.end.y - 3), dark, 1.0)
		var lit := Color(heat, (0.25 + 0.55 * near) * appear)
		draw_line(Vector2(x + 1, area.position.y + 4), Vector2(x + 1, area.end.y - 4), lit, 1.0)
	_draw_steam(near)
	# The vent's core swells with each beat.
	var swell := 1.0 + 0.35 * (1.0 - beat)
	var core := Vector2(area.size.x * 0.16 * swell, 3.5 * swell)
	_ellipse(core, Color(_heat(0.75 + 0.25 * near), (0.45 + 0.5 * near) * appear), centre)
	# The seam: a heat halo out of it, a dark line under it, a white-hot core.
	var halo := Color(heat, (0.2 + 0.25 * near) * appear)
	_layers.show("halo", halo)
	_layers.show("dark", Color(0.04, 0.01, 0.01, 0.9 * appear))
	var hot := heat.lerp(Color(1, 0.97, 0.9), 0.35 + 0.5 * near)
	var glow := 1.0 if lock else (0.55 + 0.45 * near) * (0.8 + 0.2 * sin(beat * TAU))
	_layers.show("hot", Color(hot, glow * appear))
	# The last moments: the plate flashes on the last two beats.
	if _left <= STEAM_FLASH_SECONDS:
		var flash := 0.5 + 0.5 * cos(_left / STEAM_FLASH_SECONDS * TAU * 2.0)
		_layers.show("flash", Color(1, 0.85, 0.6, 0.22 * flash))


## LARGE RAIN: a whole span of street where the drop comes down. Its corners
## lock on with bold brackets, its edge runs as an ember seam with a dark line
## under it, short ground lines aim at where the drop lands, and the drop's
## shadow grows and darkens as it falls. Each tile keeps its own blink, so
## neighbours stay apart.
func _rain_large(area: Rect2, near: float, appear: float, lock: bool, clock: float) -> void:
	var ember := Color(1.0, 0.62, 0.2)
	var mark := _rain_mark(area)
	var own := float(get_instance_id() % 97) / 97.0 * TAU
	if _layers.is_empty():
		_record_rain_large()
	_layers.show("fill", Color(0.05, 0.02, 0.01, (0.16 + 0.16 * near) * appear))
	# The drop's shadow: wider and darker as it nears the ground.
	var shadow := Vector2(area.size.x * (0.16 + 0.24 * near), area.size.y * (0.07 + 0.11 * near))
	_ellipse(shadow, Color(0.02, 0.01, 0.02, (0.35 + 0.45 * near) * appear), mark)
	# Ground lines aiming at the landing point (a gap at the point itself).
	var aim := Color(ember, (0.35 + 0.4 * near) * appear)
	var reach := minf(area.size.x, area.size.y) * 0.22
	for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(mark + dir * 4.0, mark + dir * (4.0 + reach), aim, 1.0)
	var blink := 0.5 + 0.5 * sin(clock * lerpf(6.0, 24.0, near) + own)
	var glint := Color(ember.lerp(Color.WHITE, 0.4), (0.6 + 0.4 * blink) * appear)
	draw_rect(Rect2(mark - Vector2(1, 1), Vector2(3, 3)), glint)
	# The edge: dark under, ember over.
	_layers.show("dark", Color(0.04, 0.02, 0.01, 0.85 * appear))
	var edge := 1.0 if lock else (0.55 + 0.4 * near) * (0.85 + 0.15 * blink)
	_layers.show("edge", Color(ember.lerp(Color.WHITE, 0.15), edge * appear))
	# Bold brackets on the true corners, sliding in as it appears.
	var arm := minf(10.0, minf(area.size.x, area.size.y) * 0.3)
	var slide := (1.0 - appear) * 6.0
	var bracket := Color(1, 0.96, 0.88) if lock else ember.lerp(Color.WHITE, 0.35)
	bracket.a = 1.0 if lock else (0.7 + 0.3 * near) * appear
	# Their place changes only while they slide in: recorded again only then.
	if slide != _bracket_slide:
		_bracket_slide = slide
		_record_brackets(area, arm, slide)
	_layers.show("shade", Color(0.03, 0.01, 0.01, 0.7 * appear))
	_layers.show("bracket", bracket)


## Large steam's unchanging parts, in drawing order: under the vent and its
## waves, the fill and light bands; over them, the seam's halo, dark line and
## hot core, and the last moments' flash.
func _record_steam_large() -> void:
	_add_layer("fill", _fill, 0.0, true)
	for i in _rings.size():
		_add_layer("ring%d" % i, _rings[i], 3.0, true)
	_add_layer("halo", _seam_points, 6.0, false)
	_add_layer("dark", _seam_points, 3.0, false)
	_add_layer("hot", _seam_points, 2.0, false)
	_add_layer("flash", _fill, 0.0, false)


## Large rain's: the fill under its shadow and aim lines; the seam's dark line
## and ember edge over them, then the corner brackets (shade, then light).
func _record_rain_large() -> void:
	_add_layer("fill", _fill, 0.0, true)
	_add_layer("dark", _seam_points, 3.0, false)
	_add_layer("edge", _seam_points, 1.5, false)
	_add_layer("shade", PackedVector2Array(), 0.0, false)
	_add_layer("bracket", PackedVector2Array(), 0.0, false)


## The four corner brackets, `slide` px out from the true corners, in white
## (the shade a pixel down and right of the light).
func _record_brackets(area: Rect2, arm: float, slide: float) -> void:
	var light := PackedVector2Array()
	var shade := PackedVector2Array()
	for cx in [-1.0, 1.0]:
		for cy in [-1.0, 1.0]:
			var half_size := area.size / 2.0 + Vector2(2.0 + slide, 2.0 + slide)
			var c := area.get_center() + Vector2(cx * half_size.x, cy * half_size.y)
			light.append_array([c, c - Vector2(cx * arm, 0), c, c - Vector2(0, cy * arm)])
	for point in light:
		shade.append(point + Vector2(1, 1))
	_layers.record("shade", shade, 2.0, true)
	_layers.record("bracket", light, 2.0, true)


## A layer of this warning's, `points` recorded once in white (HazardLayers).
func _add_layer(layer: String, points: PackedVector2Array, width: float, under: bool) -> void:
	_layers.add(get_canvas_item(), layer, points, width, under)


func _notification(what: int) -> void:
	# Before this node's canvas item goes, so no layer outlives it.
	if what == NOTIFICATION_PREDELETE and _layers != null:
		_layers.free_all()
