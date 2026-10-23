extends Node2D
## Character gallery: every imported asset, each animation playing in a row.
## Used to eyeball new art after an import, and by tests to check it loads.

const CELL := Vector2(72, 76)
## Room for the loot rows at the top.
const LOOT_HEIGHT := 120.0
const LOOT_PER_ROW := 8


func _ready() -> void:
	var art: Dictionary = GameSession.content.art
	var ids: Array = art.keys()
	ids.sort()
	var y := 24.0
	var background := ColorRect.new()
	background.color = Color(0.16, 0.16, 0.2)
	background.size = Vector2(1400, 80 + LOOT_HEIGHT + CELL.y * ids.size())
	add_child(background)
	_loot_rows(y)
	y += LOOT_HEIGHT
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


## Every item as it looks on the street (LootView), rarest last, for review.
func _loot_rows(top: float) -> void:
	var content := GameSession.content
	var title := Label.new()
	title.text = "Loot on the ground"
	title.add_theme_font_size_override("font_size", 8)
	title.position = Vector2(8, top - 18)
	add_child(title)
	var ids: Array = content.items.keys()
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var ra := ContentDB.RARITIES.find(str(content.item(a).get("rarity")))
			var rb := ContentDB.RARITIES.find(str(content.item(b).get("rarity")))
			return ra < rb if ra != rb else a < b
	)
	ids.push_front("")  # coins
	for i in ids.size():
		var at := Vector2(45 + (i % LOOT_PER_ROW) * 76, top + 44 + int(i / LOOT_PER_ROW) * 56)
		var pickup := {"id": i, "kind": "item", "item": ids[i], "position": at}
		if ids[i] == "":
			pickup = {"id": i, "kind": "money", "amount": 25, "position": at}
		var loot := LootView.new()
		loot.setup(content, pickup, at)
		add_child(loot)


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")
