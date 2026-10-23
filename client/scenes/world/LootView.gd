class_name LootView
extends Node2D
## Something lying on the street that the hero can pick up, drawn so it can
## be read at a glance: the item's own icon (or a spinning coin), a soft
## shadow, a glow and, for better items, a light beam in the rarity colour,
## and its name (or the coin amount). It pops out in a little arc when
## dropped and flies up when collected. Presentation only.

const POP_SECONDS := 0.45
const BOB_PIXELS := 2.0
## Beam height by rarity (no beam for common items).
const BEAMS := {"uncommon": 34.0, "rare": 54.0, "epic": 74.0, "legendary": 96.0}
## Items show at twice their icon size (whole pixels, so they stay sharp);
## coins at 1x with their amount.
const ITEM_ZOOM := 2.0
const ITEM_HEIGHT := 18.0
const COIN_HEIGHT := 10.0

var pickup: Dictionary
var color := Color.WHITE
var _icon: Sprite2D
var _beam := 0.0
var _time := 0.0
var _landed := false
var _rest := -COIN_HEIGHT


## Builds the view for a `pickup` from ZoneSim; `from` is where it flies from
## (the defeated enemy), in the same space as the pickup's position.
func setup(content: ContentDB, p_pickup: Dictionary, from: Vector2) -> void:
	pickup = p_pickup
	name = "Loot%d" % pickup["id"]
	position = pickup["position"]
	_time = randf() * TAU
	var money: bool = pickup["kind"] == "money"
	var item := {} if money else content.item(str(pickup["item"]))
	color = UiTheme.GOLD if money else ItemText.rarity_color(item)
	_beam = 0.0 if money else float(BEAMS.get(str(item.get("rarity", "common")), 0.0))
	_icon = Sprite2D.new()
	_icon.texture = UiKit.icon(content, "coin" if money else str(item.get("icon", "")))
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not money:
		_icon.scale = Vector2.ONE * ITEM_ZOOM
		_rest = -ITEM_HEIGHT
	_icon.position = Vector2(0, _rest)
	add_child(_icon)
	var label := Label.new()
	label.name = "Name"
	label.text = "%d" % int(pickup["amount"]) if money else str(item.get("name", ""))
	label.add_theme_font_size_override("font_size", UiTheme.SIZE_CAPTION)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(90, 10)
	label.position = Vector2(-45, _rest - 22.0 if money else _rest - 30.0)
	add_child(label)
	if item.get("rarity") in ["epic", "legendary"]:
		_add_sparkles()
	# Pop out of the enemy in an arc, then settle.
	var start := from - position
	if start.length() > 2.0:
		_icon.position = start + Vector2(0, _rest)
		var tween := create_tween().set_parallel()
		tween.tween_property(_icon, "position:x", 0.0, POP_SECONDS)
		tween.tween_method(_arc.bind(start.y), 0.0, 1.0, POP_SECONDS)
		tween.chain().tween_callback(func() -> void: _landed = true)
	else:
		_landed = true


## Flies up and fades, then frees itself (the hero collected it).
func collect() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 18.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.25)
	tween.chain().tween_callback(queue_free)


func _arc(t: float, start_y: float) -> void:
	var height := 22.0 * 4.0 * t * (1.0 - t)
	_icon.position.y = lerpf(start_y, 0.0, t) + _rest - height


func _process(delta: float) -> void:
	_time += delta
	if _landed:
		_icon.position.y = _rest - BOB_PIXELS * (0.5 + 0.5 * sin(_time * 3.0))
	if pickup.get("kind") == "money":
		# A spinning coin: squash the width.
		_icon.scale.x = maxf(0.15, absf(cos(_time * 4.0)))
	queue_redraw()


func _draw() -> void:
	# Shadow on the street, smaller while the item is in the air.
	var lift := clampf((_rest - _icon.position.y) / 20.0, 0.0, 1.0)
	var size := _icon.scale.y
	_ellipse(Vector2.ZERO, Vector2(7, 2.2) * size * (1.0 - 0.5 * lift), Color(0, 0, 0, 0.45))
	var pulse := 0.75 + 0.25 * sin(_time * 4.0)
	if _beam > 0.0:
		var height := _beam * pulse
		for i in 4:
			var width := (5.0 - i) * 1.6
			draw_rect(
				Rect2(-width / 2.0, -height, width, height),
				Color(color, 0.08 + 0.05 * i),
			)
	# Glow behind the icon.
	var at := _icon.position
	draw_circle(at, 9.0 * size, Color(color, 0.12 * pulse))
	draw_circle(at, 6.0 * size, Color(color, 0.18 * pulse))
	_ellipse(Vector2.ZERO, Vector2(9, 3) * size * pulse, Color(color, 0.18))


func _ellipse(center: Vector2, radius: Vector2, fill: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, fill)


func _add_sparkles() -> void:
	var sparkles := CPUParticles2D.new()
	sparkles.amount = 6
	sparkles.lifetime = 1.2
	sparkles.position = Vector2(0, _rest)
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparkles.emission_sphere_radius = 14.0
	sparkles.direction = Vector2.UP
	sparkles.spread = 30.0
	sparkles.gravity = Vector2.ZERO
	sparkles.initial_velocity_min = 6.0
	sparkles.initial_velocity_max = 12.0
	sparkles.scale_amount_min = 1.0
	sparkles.scale_amount_max = 2.0
	sparkles.color = color.lightened(0.4)
	add_child(sparkles)
