class_name SkillsScreen
extends RefCounted
## The Skills screen (V): what the hero can do, one card each (the attack
## and the job's nine skills, passives and the ultimate included: icon,
## name, cost and the level it unlocks at), in two columns; what the card
## last pointed at or pressed does is spelled out under them; and the hotbar
## row at the foot to put them on (HotbarEditor, skills only: food goes on
## from the Bag). A card's icon drags onto a slot; pointing at a card and
## pressing 1-7 puts it there; a
## slot dragged back onto the list is emptied. Locked skills can go on the
## bar too (the bar shows the lock until the level is reached).

const ICON := 26.0
const TEXT_WIDTH := 560.0
const COLUMNS := 2
## Room for a card's name and numbers beside its icon.
const CARD_TEXT := 236.0


static func build(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var page := VBoxContainer.new()
	page.name = "Skills"
	page.add_theme_constant_override("separation", UiTheme.GAP)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list := GridContainer.new()
	list.name = "SkillList"
	list.columns = COLUMNS
	list.add_theme_constant_override("h_separation", 4)
	list.add_theme_constant_override("v_separation", 3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var detail := UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, TEXT_WIDTH)
	detail.name = "SkillDetail"
	detail.custom_minimum_size.y = 26
	var keys: Array[String] = [HotbarRules.ATTACK]
	for skill_id: String in SkillRules.kit(content, profile.hero):
		keys.append("skill:" + skill_id)
	var bar := HotbarRules.layout(profile, content)
	for key in keys:
		list.add_child(_card(game, key, bar.find(key), detail))
	detail.text = _help(content, keys[mini(1, keys.size() - 1)])
	page.add_child(detail)
	page.add_child(HotbarEditor.bar(game, HotbarEditor.SKILLS))
	return page


## What a card's skill does, named, for the line under the cards.
static func _help(content: ContentDB, key: String) -> String:
	var entry := HotbarRules.entry_of(key)
	if entry["type"] == "attack":
		var attack := Hotbar.attack_entry(content)
		return "%s: %s" % [attack.get("name", "Attack"), attack.get("description", "")]
	var skill: Dictionary = content.skills[entry["id"]]
	return "%s: %s" % [skill["name"], skill["description"]]


## One skill: its icon (dragged onto the bar), name, numbers and which key it
## is on now. Pointing at it or pressing it explains it in `detail`.
static func _card(game: Game, key: String, on_slot: int, detail: Label) -> Control:
	var content := game.content
	var entry := HotbarRules.entry_of(key)
	var card := PanelContainer.new()
	card.name = "Card_" + key.replace(":", "_")
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(3)
	card.add_theme_stylebox_override("panel", style)
	# Pointing anywhere at the card and pressing 1-7 puts it on that slot.
	card.set_meta(HotbarEditor.KEY_META, key)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.tooltip_text = _help(content, key)
	card.mouse_entered.connect(func() -> void: detail.text = _help(content, key))
	card.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton or event is InputEventScreenTouch:
				detail.text = _help(content, key)
	)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	card.add_child(line)
	var icon := ItemSlot.new(ICON)
	icon.name = "Drag_" + key.replace(":", "_")
	icon.focus_mode = Control.FOCUS_NONE
	HotbarEditor.show_key(content, game.profile, icon, key)
	icon.set_meta(HotbarEditor.KEY_META, key)
	icon.drag_data = {"from": "skills", "key": key}
	# A slot dragged back onto the list comes off the bar.
	icon.accepts = func(data: Dictionary) -> bool: return str(data.get("from")) == "hotbar"
	icon.dropped = func(data: Dictionary) -> void: game._hotbar_clear(int(data["index"]))
	line.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(text)
	text.custom_minimum_size.x = CARD_TEXT
	var name := ""
	var facts := ""
	var locked := 0
	var passive := false
	if entry["type"] == "attack":
		name = str(Hotbar.attack_entry(content).get("name", "Attack"))
		facts = "No cooldown"
	else:
		var skill: Dictionary = content.skills[entry["id"]]
		name = str(skill["name"]).capitalize()
		facts = SkillRules.facts(content, str(entry["id"]), true)
		passive = SkillRules.is_passive(skill)
		var unlock := int(skill["unlock_level"])
		locked = unlock if game.profile.level < unlock else 0
	text.add_child(
		UiKit.label(name, UiTheme.SIZE_BODY, UiTheme.TEXT_DIM if locked else UiTheme.TEXT)
	)
	# Under the name, short enough for half the window at 150% text: the
	# level it unlocks at (while locked), its numbers, the key it is on.
	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 6)
	text.add_child(line2)
	if locked:
		line2.add_child(UiKit.label("Lv %d" % locked, UiTheme.SIZE_CAPTION, UiTheme.DANGER))
	line2.add_child(UiKit.label(facts, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	if not passive and on_slot >= 0:
		line2.add_child(UiKit.label("Key %d" % (on_slot + 1), UiTheme.SIZE_CAPTION, UiTheme.ACCENT))
	for child in text.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card
