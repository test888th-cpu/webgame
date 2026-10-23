class_name Scenery
extends RefCounted
## Builds an area's generated pixel-art scenery (tools/assets/gen_environment.py)
## under a node: a sky fixed to the screen, a skyline scrolling at 30%, the
## street's facades and ground in the world, and props with additive lamp
## glow. Used by the game world and by the title screen backdrop.


static func build(parent: Node2D, content: ContentDB, scenery: Dictionary) -> void:
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
