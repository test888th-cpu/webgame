extends Control
## The gallery (Title → Gallery): every character and every item in the game,
## for players to browse and for reviewing new art after an import.
##   Characters  the roster on the left, grouped (heroes, people, enemies,
##               bosses); the chosen one large on a stage with a button per
##               animation, and where its art comes from (source, licences,
##               artists).
##   Items       every item as a grid of slots by rarity, rarest last; the
##               chosen one's card (ItemCard) and how it looks lying on the
##               street (LootView).
## Keyboard and gamepad: arrows move, Q/E (LB/RB) switch tabs, Esc (Start)
## goes back. Read-only: nothing here changes the save.

const TITLE_SCENE := "res://scenes/title/Title.tscn"
## Role, list heading, one of them.
const GROUPS := [
	["hero", "Heroes", "Hero"],
	["npc", "People", "Person"],
	["enemy", "Enemies", "Enemy"],
	["boss", "Bosses", "Boss"],
]
const LIST_WIDTH := 176.0
const DETAIL_WIDTH := 252.0
const STAGE_HEIGHT := 150.0
const SLOT_SIZE := 28.0
const ITEM_COLUMNS := 10
const AUTHORS_SHOWN := 4

var content: ContentDB
var tabs: TabContainer
## Art id → the name players know it by.
var names := {}
## Art id → its button in the roster.
var buttons := {}
var selected := ""
var _stage: SpriteView
var _anims: HBoxContainer
var _info: VBoxContainer
var _item_detail: VBoxContainer
var _ground: Control


func _ready() -> void:
	content = GameSession.content
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = UiTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_build_header()
	tabs = TabContainer.new()
	tabs.name = "Tabs"
	tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
	tabs.offset_left = UiTheme.SCREEN_MARGIN
	tabs.offset_right = -UiTheme.SCREEN_MARGIN
	tabs.offset_top = 32
	tabs.offset_bottom = -UiTheme.SCREEN_MARGIN
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	add_child(tabs)
	names = _display_names()
	tabs.add_child(_characters_tab())
	tabs.add_child(_items_tab())
	tabs.set_tab_title(0, "Characters")
	tabs.set_tab_title(1, "Items")
	tabs.tab_changed.connect(
		func(_i: int) -> void: UiKit.focus_first(tabs.get_current_tab_control())
	)
	UiKit.focus_first(tabs.get_current_tab_control())


func _build_header() -> void:
	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = UiTheme.SCREEN_MARGIN
	header.offset_right = -UiTheme.SCREEN_MARGIN
	header.offset_top = 6
	header.add_theme_constant_override("separation", UiTheme.PAD)
	add_child(header)
	var title := UiKit.label("GALLERY", UiTheme.SIZE_H1, UiTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for hint: Array in [["Q E", "Tabs"], ["Esc", "Back"]]:
		var key := UiKit.key_hint(hint[0], hint[1])
		key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(key)
	var back := UiKit.button("Back to title", _back)
	back.focus_mode = Control.FOCUS_NONE
	header.add_child(back)


# --- Characters ---------------------------------------------------------------


func _characters_tab() -> Control:
	var row := HBoxContainer.new()
	row.name = "Characters"
	row.add_theme_constant_override("separation", UiTheme.PAD)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = LIST_WIDTH
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	row.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Roster"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	scroll.add_child(list)
	for group: Array in GROUPS:
		var ids := _art_with_role(str(group[0]))
		if ids.is_empty():
			continue
		var heading := UiKit.label(
			"%s  (%d)" % [str(group[1]).to_upper(), ids.size()],
			UiTheme.SIZE_CAPTION,
			UiTheme.ACCENT
		)
		list.add_child(heading)
		for art_id: String in ids:
			var button := Button.new()
			button.name = "Char_" + art_id
			button.text = str(names.get(art_id, art_id))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.clip_text = true
			button.custom_minimum_size = Vector2(LIST_WIDTH - 12, 16)
			button.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
			button.focus_entered.connect(_select.bind(art_id))
			button.pressed.connect(_select.bind(art_id))
			list.add_child(button)
			buttons[art_id] = button
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", UiTheme.GAP)
	row.add_child(side)
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", _inset())
	stage.custom_minimum_size.y = STAGE_HEIGHT
	side.add_child(stage)
	_stage = SpriteView.new()
	_stage.name = "Stage"
	stage.add_child(_stage)
	_anims = HBoxContainer.new()
	_anims.name = "Animations"
	_anims.add_theme_constant_override("separation", 3)
	side.add_child(_anims)
	_info = VBoxContainer.new()
	_info.add_theme_constant_override("separation", 1)
	side.add_child(_info)
	return row


## Imported art of `role`, heroes in roster order and the rest by name.
func _art_with_role(role: String) -> Array[String]:
	var out: Array[String] = []
	for art_id: String in content.art:
		var entry: Dictionary = content.art[art_id]
		if entry.get("role") == role and entry.get("status") == "imported":
			out.append(art_id)
	out.sort_custom(
		func(a: String, b: String) -> bool:
			return str(names.get(a, a)).naturalnocasecmp_to(str(names.get(b, b))) < 0
	)
	return out


## Shows character `art_id` on the stage, with its animations and credits.
func _select(art_id: String) -> void:
	if art_id == selected:
		return
	selected = art_id
	var entry: Dictionary = content.art[art_id]
	var height := float(entry["frame_size"][1])
	_stage.show_art(content, art_id, minf(3.0, floorf((STAGE_HEIGHT - 12.0) / height * 2.0) / 2.0))
	_clear(_anims)
	var anims: Array = entry["animations"].keys()
	anims.sort_custom(func(a: String, b: String) -> bool: return _anim_rank(a) < _anim_rank(b))
	for anim: String in anims:
		var play := Button.new()
		play.name = "Anim_" + anim
		play.text = anim
		play.add_theme_font_size_override("font_size", UiTheme.SIZE_CAPTION)
		play.focus_mode = Control.FOCUS_NONE
		play.pressed.connect(_play.bind(anim))
		_anims.add_child(play)
	_clear(_info)
	_info.add_child(UiKit.label(str(names.get(art_id, art_id)), UiTheme.SIZE_H2, UiTheme.TEXT))
	var source := {"lpc": "LPC", "custom": "Project art", "original": "Drawn by code"}
	var lines := [
		(
			"%s  ·  %s"
			% [_role_name(str(entry["role"])), source.get(entry["source"], entry["source"])]
		),
		"Licences: " + ", ".join(entry["licenses"]),
	]
	var artists := _artists(entry)
	if not artists.is_empty():
		lines.append("Art by " + artists)
	for line: String in lines:
		_info.add_child(UiKit.label(line, UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, 380))


## Idle and walk first, then attacks, then getting hit, then the rest.
func _anim_rank(anim: String) -> String:
	var order := ["idle", "walk", "light", "heavy", "stab", "dodge", "hurt", "down"]
	var at := order.find(anim)
	return "%02d%s" % [at if at >= 0 else order.size(), anim]


func _play(anim: String) -> void:
	if _stage.sprite and _stage.sprite.sprite_frames.has_animation(anim):
		_stage.sprite.play(anim)
		# One-shot moves return to idle, so the stage never freezes on a pose.
		if not _stage.sprite.sprite_frames.get_animation_loop(anim):
			await _stage.sprite.animation_finished
			if is_instance_valid(_stage.sprite) and _stage.sprite.animation == anim:
				_stage.sprite.play("idle")


func _role_name(role: String) -> String:
	for group: Array in GROUPS:
		if group[0] == role:
			return str(group[2])
	return role.capitalize()


## The artists credited for `entry`, the first few and how many more.
func _artists(entry: Dictionary) -> String:
	var path := str(entry.get("credits", ""))
	if not FileAccess.file_exists(path):
		return ""
	var credits: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var found: Array[String] = []
	for credit: Dictionary in credits if credits is Array else []:
		for author: Variant in credit.get("authors", []):
			if str(author) not in found:
				found.append(str(author))
	var shown := ", ".join(found.slice(0, AUTHORS_SHOWN))
	if found.size() > AUTHORS_SHOWN:
		shown += " and %d more" % (found.size() - AUTHORS_SHOWN)
	return shown


## Art id → name: heroes from heroes.json, enemies from enemies.json, people
## from the NPCs in areas.json. Art no one names keeps its id, made readable.
func _display_names() -> Dictionary:
	var out := {}
	for hero_id: String in content.hero_order:
		var hero := content.hero(hero_id)
		var sprites: Dictionary = hero.get("sprites", {})
		for look: String in sprites:
			var art_id := str(sprites[look])
			if not out.has(art_id):
				out[art_id] = str(hero["name"]) + ("" if look == "default" else " (armoured)")
	for enemy_id: String in content.enemies:
		var art_id := str(content.enemies[enemy_id].get("sprite", enemy_id))
		if not out.has(art_id):
			out[art_id] = str(content.enemies[enemy_id].get("name", enemy_id))
	for area_id: String in content.areas:
		for npc: Dictionary in content.area(area_id).get("npcs", []):
			var art_id := str(npc.get("sprite", ""))
			if art_id and not out.has(art_id):
				out[art_id] = str(npc.get("name", art_id))
	for art_id: String in content.art:
		if not out.has(art_id):
			out[art_id] = art_id.capitalize()
	return out


# --- Items --------------------------------------------------------------------


func _items_tab() -> Control:
	var row := HBoxContainer.new()
	row.name = "Items"
	row.add_theme_constant_override("separation", UiTheme.PAD)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	row.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Shelves"
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)
	for rarity: String in ContentDB.RARITIES:
		var ids := _items_of(rarity)
		if ids.is_empty():
			continue
		var color := ItemText.rarity_color({"rarity": rarity})
		list.add_child(
			UiKit.label("%s  (%d)" % [rarity.to_upper(), ids.size()], UiTheme.SIZE_CAPTION, color)
		)
		var grid := GridContainer.new()
		grid.columns = ITEM_COLUMNS
		grid.add_theme_constant_override("h_separation", 3)
		grid.add_theme_constant_override("v_separation", 3)
		list.add_child(grid)
		for item_id in ids:
			var slot := ItemSlot.new(SLOT_SIZE)
			slot.name = "Item_" + item_id
			slot.show_item(content, item_id)
			slot.focus_entered.connect(_show_item.bind(item_id))
			slot.mouse_entered.connect(slot.grab_focus)
			grid.add_child(slot)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _inset())
	panel.custom_minimum_size.x = DETAIL_WIDTH
	row.add_child(panel)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", UiTheme.GAP)
	panel.add_child(side)
	_item_detail = VBoxContainer.new()
	_item_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(_item_detail)
	side.add_child(UiKit.label("ON THE STREET", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT))
	_ground = Control.new()
	_ground.name = "Ground"
	_ground.custom_minimum_size = Vector2(DETAIL_WIDTH - 16, 62)
	_ground.clip_contents = true
	side.add_child(_ground)
	return row


## Items of `rarity`, by type (equipment, consumables, materials, keys), then name.
func _items_of(rarity: String) -> Array[String]:
	var types := ["equipment", "consumable", "material", "key"]
	var out: Array[String] = []
	for item_id: String in content.items:
		if str(content.item(item_id).get("rarity")) == rarity:
			out.append(item_id)
	out.sort_custom(
		func(a: String, b: String) -> bool:
			var ta := types.find(str(content.item(a).get("type")))
			var tb := types.find(str(content.item(b).get("type")))
			if ta != tb:
				return ta < tb
			return str(content.item(a)["name"]) < str(content.item(b)["name"])
	)
	return out


func _show_item(item_id: String) -> void:
	_clear(_item_detail)
	# A level-capped hero with nothing worn: the card shows the item itself.
	var viewer := PlayerProfile.new()
	viewer.level = int(content.progression.get("max_level", 50))
	_item_detail.add_child(ItemCard.details(content, viewer, item_id, "", false))
	_clear(_ground)
	var at := Vector2(_ground.custom_minimum_size.x / 2.0, 54)
	var loot := LootView.new()
	loot.setup(content, {"id": 1, "kind": "item", "item": item_id, "position": at}, at)
	_ground.add_child(loot)


## Empties `box` at once, so new children keep their names.
func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _inset() -> StyleBoxFlat:
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(6)
	return style


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_back()
	elif event.is_action_pressed("menu_prev") or event.is_action_pressed("menu_next"):
		get_viewport().set_input_as_handled()
		var step := -1 if event.is_action_pressed("menu_prev") else 1
		tabs.current_tab = posmod(tabs.current_tab + step, tabs.get_tab_count())


func _back() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)
