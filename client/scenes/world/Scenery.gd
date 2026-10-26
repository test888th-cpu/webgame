class_name Scenery
extends RefCounted
## Builds an area's scenery under a node. Used by the game world and by the
## title and hero-select backdrops.
##
## Areas laid out from the HD-2D street kit (tools/assets/kit_import.py) get a
## generated sky fixed to the screen, then painted pieces in depth layers: a
## far skyline, towers and the skytrain behind the street scrolling slower than
## it, the shopfronts, road and sidewalk with posts, props and parked vehicles,
## and foliage in front of the fighters scrolling faster. Kit textures hold
## `hd` texture pixels per game pixel and are drawn scaled down with linear
## filtering, so they stay sharp at any window size while the characters stay
## pixel art. Areas without a kit layout fall back to the generated pixel-art
## scenery (tools/assets/gen_environment.py).

## Where the skyline stands, and the sidewalk strip and road, in game pixels.
## The kerb sits a few pixels above ZoneSim.LANE_TOP, so fighters always stand
## on the road and never on the sidewalk (tools/assets/kit_import.py matches).
const FAR_FEET := 236.0
const SIDEWALK_TOP := 220.0
const ROAD_TOP := 244.0
## Every piece of street furniture drawn is in this group.
const FURNITURE_GROUP := "street_furniture"
## Foliage in front of the fighters is drawn above them.
const FOREGROUND_Z := 1


## Builds the scenery of `area_id`; false when it has none to build. The
## area's solid street furniture is drawn too unless `with_furniture` is off
## (the game world draws it among the fighters, see `furniture`).
static func build(
	parent: Node2D, content: ContentDB, area_id: String, with_furniture := true
) -> bool:
	var scenery: Dictionary = content.environment.get("areas", {}).get(area_id, {})
	var kit: Dictionary = content.kit.get("areas", {}).get(area_id, {})
	if not kit.is_empty():
		if not scenery.is_empty():
			_parallax(parent, scenery["layers"]["sky"], 0.0)
		_build_kit(parent, content, kit)
		if with_furniture:
			for obstacle: Dictionary in content.area(area_id).get("obstacles", []):
				var node := furniture(content, str(obstacle["kind"]))
				if node != null:
					node.position = Vector2(obstacle["x"], obstacle["y"])
					parent.get_node("KitStreet").add_child(node)
		return true
	if scenery.is_empty():
		return false
	_build_generated(parent, content, scenery)
	return true


static func _build_kit(parent: Node2D, content: ContentDB, area: Dictionary) -> void:
	var pieces: Dictionary = content.kit["pieces"]
	var scroll: Dictionary = content.kit["scroll"]
	var tint: Dictionary = area.get("tint", {})
	var width := float(area["width"])

	var far := _layer(parent, "far", scroll["far"], tint)
	var skyline: Dictionary = pieces[area["far"]]
	far.repeat_size = Vector2(_game_size(skyline).x, 0)
	far.repeat_times = 3
	_piece(far, skyline, _game_size(skyline).x / 2.0, FAR_FEET)

	var layers := {}
	for layer: String in ["back", "track"]:
		layers[layer] = _layer(parent, layer, scroll[layer], tint)
	layers["front"] = _layer(parent, "front", 1.0, tint)
	var ground := _layer(parent, "ground", 1.0, tint)
	_tile(ground, pieces[area["ground"]["road"]], Vector2(0, ROAD_TOP), width)
	_tile(ground, pieces[area["ground"]["sidewalk"]], Vector2(0, SIDEWALK_TOP), width)
	if area.has("track"):
		# The elevated track runs unbroken; trains stand on it.
		var track: Dictionary = area["track"]
		var start := float(track["from"])
		_tile(
			layers["track"],
			pieces[track["piece"]],
			Vector2(start, float(track["top"])),
			float(track["to"]) - start
		)
	layers["sidewalk"] = _layer(parent, "sidewalk", 1.0, tint)
	layers["street"] = _layer(parent, "street", 1.0, tint)
	var foreground := _layer(parent, "fg", scroll["fg"], tint)
	foreground.z_index = FOREGROUND_Z
	layers["fg"] = foreground

	for placed: Dictionary in area["placed"]:
		var piece: Dictionary = pieces[placed["piece"]]
		var layer: Node2D = layers[placed["layer"]]
		var sprite := _piece(layer, piece, float(placed["x"]), float(placed["y"]))
		if piece.has("glow"):
			_glow(layer, content, sprite.position + _game_size(piece) * _vec(piece["glow"]))


## A piece of solid street furniture (areas.json "obstacles") standing with
## its feet at the node's origin, so it sorts in depth with the fighters; null
## if its picture is missing.
static func furniture(content: ContentDB, kind: String) -> Node2D:
	var piece_id := str(content.obstacles.get(kind, {}).get("piece", ""))
	var piece: Dictionary = content.kit.get("pieces", {}).get(piece_id, {})
	if piece.is_empty():
		return null
	var node := Node2D.new()
	node.name = "Furniture"
	node.add_to_group(FURNITURE_GROUP)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sprite := _piece(node, piece, 0.0, 0.0)
	if piece.has("glow"):
		_glow(node, content, sprite.position + _game_size(piece) * _vec(piece["glow"]))
	return node


## A depth layer: a Parallax2D scrolling at `scroll` (1 = with the street),
## drawing its HD pieces smoothly and tinted for distance.
static func _layer(parent: Node2D, layer: String, scroll: float, tint: Dictionary) -> Parallax2D:
	var node := Parallax2D.new()
	node.name = "Kit" + layer.capitalize()
	node.scroll_scale = Vector2(scroll, 1.0)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if tint.has(layer):
		node.modulate = Color.from_string(str(tint[layer]), Color.WHITE)
	parent.add_child(node)
	return node


## A kit piece standing with its feet centred on (x, feet).
static func _piece(layer: Node2D, piece: Dictionary, x: float, feet: float) -> Sprite2D:
	var size := _game_size(piece)
	var sprite := Sprite2D.new()
	sprite.texture = load(piece["file"])
	sprite.centered = false
	sprite.scale = Vector2.ONE / float(piece["hd"])
	sprite.position = Vector2(roundf(x - size.x / 2.0), roundf(feet - size.y))
	layer.add_child(sprite)
	return sprite


## A strip (road, sidewalk, the skytrain track) repeated for `width` from `at`.
static func _tile(layer: Node2D, piece: Dictionary, at: Vector2, width: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(piece["file"])
	sprite.centered = false
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	var hd := float(piece["hd"])
	sprite.region_rect = Rect2(0, 0, width * hd, float(piece["size"][1]))
	sprite.scale = Vector2.ONE / hd
	sprite.position = at
	layer.add_child(sprite)


static func _glow(layer: Node2D, content: ContentDB, at: Vector2) -> void:
	var props: Dictionary = content.environment.get("props", {})
	if not props.has("regions"):
		return
	var glow := Sprite2D.new()
	glow.texture = _atlas(load(props["sheet"]), props["regions"]["glow"])
	glow.position = at
	glow.scale = Vector2(2.5, 2.5)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	layer.add_child(glow)


static func _game_size(piece: Dictionary) -> Vector2:
	return _vec(piece["size"]) / float(piece["hd"])


static func _vec(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


## The generated pixel-art scenery: a sky fixed to the screen, a skyline
## scrolling at 30%, the street's facades and ground in the world, and props
## with additive lamp glow.
static func _build_generated(parent: Node2D, content: ContentDB, scenery: Dictionary) -> void:
	var layers: Dictionary = scenery["layers"]
	_parallax(parent, layers["sky"], 0.0)
	_parallax(parent, layers["far"], 0.3)
	_sprite(parent, layers["buildings"]["file"], Vector2.ZERO)
	_sprite(parent, layers["ground"]["file"], Vector2(0, ZoneSim.LANE_TOP - 20.0))
	var props: Dictionary = content.environment["props"]
	var sheet: Texture2D = load(props["sheet"])
	for placed: Dictionary in scenery["props"]:
		var region: Array = props["regions"][placed["prop"]]
		var prop := Sprite2D.new()
		prop.texture = _atlas(sheet, region)
		prop.centered = false
		prop.position = Vector2(placed["x"] - region[2] / 2.0, placed["y"] - region[3])
		parent.add_child(prop)
		if placed.get("glow", false):
			var glow := Sprite2D.new()
			glow.texture = _atlas(sheet, props["regions"]["glow"])
			glow.position = Vector2(placed["x"], placed["y"] - region[3] + 10)
			glow.scale = Vector2(2.5, 2.5)
			var additive := CanvasItemMaterial.new()
			additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			glow.material = additive
			parent.add_child(glow)


static func _atlas(sheet: Texture2D, region: Array) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(region[0], region[1], region[2], region[3])
	return atlas


static func _parallax(parent: Node2D, layer: Dictionary, scroll: float) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = Vector2(scroll, 1.0)
	parallax.repeat_size = Vector2(layer["size"][0], 0)
	parallax.repeat_times = 4
	parent.add_child(parallax)
	var sprite := Sprite2D.new()
	sprite.texture = load(layer["file"])
	sprite.centered = false
	parallax.add_child(sprite)


static func _sprite(parent: Node2D, path: String, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.position = at
	parent.add_child(sprite)
