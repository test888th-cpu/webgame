class_name HotbarEditor
extends RefCounted
## The hotbar's seven slots as an editable row, shown at the foot of the Bag
## (for food) and of the Skills screen (for the attack and skills). Each
## screen only adds its own kind, so items and skills never mix: the Bag's
## row takes food from the bag, the Skills row takes skills from its list.
## On either one:
## * drag something onto a slot to put it there (HotbarRules.place);
## * drag a slot onto another to swap them, or off the bar onto the screen's
##   list to empty it;
## * right click a slot to empty it;
## * or point at something and press 1-7 to put it on that slot.
## Every change goes through Game._hotbar_put / _hotbar_swap / _hotbar_clear,
## which save and rebuild the screen.

const CELL := 26.0
## The meta a control carries when it can go on the bar: its hotbar key.
const KEY_META := "hotbar_key"
## What each screen's row takes.
const ITEMS := "item"
const SKILLS := "skill"


## The row for a screen adding `kind` (ITEMS or SKILLS).
static func bar(game: Game, kind: String) -> Control:
	var box := VBoxContainer.new()
	box.name = "HotbarEditor"
	box.add_theme_constant_override("separation", 2)
	box.add_child(UiKit.label("HOTBAR", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 2)
	box.add_child(line)
	var keys := HotbarRules.layout(game.profile, game.content)
	for i in keys.size():
		line.add_child(_bar_cell(game, i, keys[i], kind))
	var what := "food" if kind == ITEMS else "a skill"
	box.add_child(
		UiKit.label(
			"Drag %s onto a slot, or point at it and press 1-7. Right click empties." % what,
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_FAINT
		)
	)
	return box


## True for a drag a slot of a `kind` row takes: another slot, or the
## screen's own kind of thing.
static func takes(game: Game, kind: String, data: Dictionary, index: int) -> bool:
	match str(data.get("from")):
		"hotbar":
			return int(data["index"]) != index
		"skills":
			return kind == SKILLS
		"bag":
			var food := "item:" + ContentDB.base_id(str(data["item_id"]))
			return kind == ITEMS and HotbarRules.allowed(game.profile, game.content, food)
	return false


## Shows hotbar key `key` in `slot`: its icon, frame and help.
static func show_key(
	content: ContentDB, profile: PlayerProfile, slot: ItemSlot, key: String
) -> void:
	var entry := HotbarRules.entry_of(key)
	var icon := Hotbar.icon_id(content, entry)
	slot.icon_texture = UiKit.icon(content, icon) if icon else null
	slot.frame_color = HotbarSlot.FRAMES.get(entry["type"], UiTheme.BORDER)
	slot.tooltip_text = Hotbar.tooltip(content, entry)
	slot.count = profile.count(entry["id"]) if entry["type"] == "item" else 0
	# Food that ran out stays on the bar, tinted, until something replaces it.
	slot.too_high_level = entry["type"] == "item" and slot.count == 0
	slot.item_id = key
	slot.queue_redraw()


static func _bar_cell(game: Game, index: int, key: String, kind: String) -> ItemSlot:
	var slot := ItemSlot.new(CELL)
	slot.name = "Bar%d" % (index + 1)
	slot.focus_mode = Control.FOCUS_NONE
	show_key(game.content, game.profile, slot, key)
	if key:
		slot.drag_data = {"from": "hotbar", "index": index, "key": key}
		slot.quick = game._hotbar_clear.bind(index)
	slot.accepts = func(data: Dictionary) -> bool: return takes(game, kind, data, index)
	slot.dropped = func(data: Dictionary) -> void:
		if str(data["from"]) == "hotbar":
			game._hotbar_swap(int(data["index"]), index)
		elif str(data["from"]) == "skills":
			game._hotbar_put(index, str(data["key"]))
		else:
			game._hotbar_put(index, "item:" + ContentDB.base_id(str(data["item_id"])))
	# The number over the slot: the key that presses it in play.
	var number := UiKit.overlay_label(str(index + 1), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	number.position = Vector2(2, -1)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(number)
	return slot
