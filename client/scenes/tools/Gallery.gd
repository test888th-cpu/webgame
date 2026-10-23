extends Node2D
## Character gallery: every imported asset, each animation playing in a row.
## Used to eyeball new art after an import, and by tests to check it loads.

const CELL := Vector2(72, 76)


func _ready() -> void:
	var art: Dictionary = GameSession.content.art
	var ids: Array = art.keys()
	ids.sort()
	var y := 24.0
	var background := ColorRect.new()
	background.color = Color(0.16, 0.16, 0.2)
	background.size = Vector2(1400, 80 + CELL.y * ids.size())
	add_child(background)
	for id: String in ids:
		var entry: Dictionary = art[id]
		if entry["status"] != "imported":
			continue
		var title := Label.new()
		title.text = "%s  (%s, %s)" % [id, entry["source"], ", ".join(entry["licenses"])]
		title.add_theme_font_size_override("font_size", 8)
		title.position = Vector2(8, y - 18)
		add_child(title)
		var frames: SpriteFrames = load(str(entry["sheet"]).get_base_dir().path_join(id + ".tres"))
		var x := 40.0
		var names: Array = entry["animations"].keys()
		names.sort()
		for anim: String in names:
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = frames
			sprite.centered = false
			sprite.offset = -Vector2(entry["origin"][0], entry["origin"][1])
			sprite.position = Vector2(x, y + 58)
			add_child(sprite)
			sprite.play(anim)
			var caption := Label.new()
			caption.text = anim
			caption.add_theme_font_size_override("font_size", 6)
			caption.position = Vector2(x - 20, y + 60)
			add_child(caption)
			x += CELL.x
		y += CELL.y
	var back := UiKit.button("Back to title", _back)
	back.position = Vector2(560, 4)
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(back)


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")
