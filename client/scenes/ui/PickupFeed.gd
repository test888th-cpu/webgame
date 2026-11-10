class_name PickupFeed
extends VBoxContainer
## Items just picked up, listed small at the left edge of the screen: each
## row is the item's icon and its name in its grade's colour (ItemText), with
## "x2" and so on when more of it come. A row fades out after ROW_SECONDS; at
## most MAX_ROWS show, the newest at the bottom. Coins are left out (they come
## all the time; the HUD's purse counts them).

const MAX_ROWS := 5
const ROW_SECONDS := 4.0
const FADE_SECONDS := 0.6
const ICON := Vector2(14, 14)

var _rows: Array[Dictionary] = []


func _init() -> void:
	name = "PickupFeed"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	offset_left = 6
	offset_top = 10


## `amount` of `item_id` picked up: a new row, or more on its row if it is
## still showing.
func add(content: ContentDB, item_id: String, amount := 1) -> void:
	var item := content.item(item_id)
	if item.is_empty():
		return
	for row: Dictionary in _rows:
		if row["item"] == item_id:
			row["amount"] += amount
			row["left"] = ROW_SECONDS
			(row["label"] as Label).text = _text(item, int(row["amount"]))
			(row["node"] as Control).modulate.a = 1.0
			return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.55)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2)
	style.content_margin_right = 6
	panel.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	panel.add_child(line)
	var icon := TextureRect.new()
	icon.texture = UiKit.icon(content, str(item.get("icon", "")))
	icon.custom_minimum_size = ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.add_child(icon)
	var label := UiKit.label(_text(item, amount), UiTheme.SIZE_SMALL, ItemText.rarity_color(item))
	label.name = "Name"
	line.add_child(label)
	add_child(panel)
	_rows.append({"item": item_id, "amount": amount, "left": ROW_SECONDS, "node": panel})
	_rows.back()["label"] = label
	while _rows.size() > MAX_ROWS:
		(_rows.pop_front()["node"] as Node).queue_free()


## The rows showing, oldest first: [item id, ...].
func shown() -> Array[String]:
	var out: Array[String] = []
	for row: Dictionary in _rows:
		out.append(str(row["item"]))
	return out


func _process(delta: float) -> void:
	for row: Dictionary in _rows.duplicate():
		row["left"] = float(row["left"]) - delta
		(row["node"] as Control).modulate.a = clampf(float(row["left"]) / FADE_SECONDS, 0.0, 1.0)
		if float(row["left"]) <= 0.0:
			_rows.erase(row)
			(row["node"] as Node).queue_free()


static func _text(item: Dictionary, amount: int) -> String:
	var name := str(item.get("name", ""))
	return "%s x%d" % [name, amount] if amount > 1 else name
