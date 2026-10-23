class_name Showcase
extends RefCounted
## A character shown large outside the game world (title, hero selection):
## its animated sprite standing on a soft shadow.


## Adds `art_id` under `parent` with its feet at `at`, scaled by `size`.
## Returns the sprite (null if the asset is not imported).
static func add(
	parent: Node, content: ContentDB, art_id: String, at: Vector2, size: float, face_left := false
) -> AnimatedSprite2D:
	var entry: Dictionary = content.art.get(art_id, {})
	if entry.get("status") != "imported":
		return null
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0, 0, 0, 0.45)
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(at + Vector2(cos(angle) * 11.0 * size, sin(angle) * 2.5 * size))
	shadow.polygon = points
	parent.add_child(shadow)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(str(entry["sheet"]).get_base_dir().path_join(art_id + ".tres"))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -Vector2(entry["origin"][0], entry["origin"][1])
	sprite.scale = Vector2(size, size)
	sprite.position = at
	sprite.flip_h = face_left
	parent.add_child(sprite)
	sprite.play("idle")
	return sprite
