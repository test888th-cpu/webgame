class_name Fx
extends RefCounted
## Spawns the generated effect animations (tools/assets/gen_fx.py): hit
## sparks, dust, skill trails, level-up light. Each plays once and frees
## itself. Glows use additive blending so they light up the scene.

## The SpriteFrames, origins and additive material are built once and kept on
## GameSession (an autoload), not in static variables, which would outlive
## the engine at exit.


## Plays effect `id` under `parent` with its origin at `at` (parent space).
static func spawn(
	parent: Node, content: ContentDB, id: String, at: Vector2, flip := false, size := 1.0
) -> AnimatedSprite2D:
	var library := _library(content)
	var frames: SpriteFrames = library["frames"]
	if not frames.has_animation(id):
		push_error("unknown effect " + id)
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var origin: Vector2 = library["origins"][id]
	sprite.offset = -origin
	sprite.flip_h = flip
	if flip:
		# Mirror around the origin, not the frame's left edge.
		sprite.offset.x = origin.x - frames.get_frame_texture(id, 0).get_width()
	sprite.position = at
	sprite.scale = Vector2.ONE * size
	sprite.z_index = 5
	if content.fx["effects"][id]["blend"] == "add":
		sprite.material = library["additive"]
	parent.add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play(id)
	return sprite


static func _library(content: ContentDB) -> Dictionary:
	if not GameSession.fx_library.is_empty():
		return GameSession.fx_library
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var origins := {}
	var sheet: Texture2D = load(str(content.fx.get("sheet", "")))
	var effects: Dictionary = content.fx.get("effects", {})
	for id: String in effects:
		var effect: Dictionary = effects[id]
		var size := Vector2(effect["size"][0], effect["size"][1])
		frames.add_animation(id)
		frames.set_animation_loop(id, false)
		frames.set_animation_speed(id, float(effect["fps"]))
		for frame in int(effect["frames"]):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(Vector2(frame * size.x, effect["y"]), size)
			frames.add_frame(id, atlas)
		origins[id] = Vector2(effect["origin"][0], effect["origin"][1])
	GameSession.fx_library = {"frames": frames, "origins": origins, "additive": additive}
	return GameSession.fx_library
