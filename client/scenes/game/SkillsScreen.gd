class_name SkillsScreen
extends RefCounted
## The Skills screen (V): what the hero can do, one card each (the attack
## and the hero's four skills: icon, name, energy, cooldown, the level it
## unlocks at and what it does), and the hotbar row at the foot to put them
## on (HotbarEditor, skills only: food goes on from the Bag). A card's icon
## drags onto a slot; pointing at a card and pressing 1-7 puts it there; a
## slot dragged back onto the list is emptied. Locked skills can go on the
## bar too (the bar shows the lock until the level is reached).

const ICON := 26.0
const TEXT_WIDTH := 500.0


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
	var list := VBoxContainer.new()
	list.name = "SkillList"
	list.add_theme_constant_override("separation", 3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var keys: Array[String] = [HotbarRules.ATTACK]
	for skill_id: String in content.hero(profile.hero).get("skills", []):
		keys.append("skill:" + skill_id)
	var bar := HotbarRules.layout(profile, content)
	for key in keys:
		list.add_child(_card(game, key, bar.find(key)))
	page.add_child(HotbarEditor.bar(game, HotbarEditor.SKILLS))
	return page


## One skill: its icon (dragged onto the bar), name, numbers and help, and
## which key it is on now.
static func _card(game: Game, key: String, on_slot: int) -> Control:
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
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	text.add_child(head)
	var name := ""
	var facts := ""
	var help := ""
	var locked := 0
	if entry["type"] == "attack":
		var attack := Hotbar.attack_entry(content)
		name = str(attack.get("name", "Attack"))
		facts = "No cooldown"
		help = str(attack.get("description", ""))
	else:
		var skill: Dictionary = content.skills[entry["id"]]
		var move := content.moves.get_move(str(skill["move"]))
		name = str(skill["name"])
		var seconds := snappedf(int(skill["cooldown"]) * CombatRules.TICK_SECONDS, 0.1)
		facts = "Energy %d  ·  Cooldown %ss" % [roundi(move.energy_cost), str(seconds)]
		help = str(skill["description"])
		var unlock := int(skill["unlock_level"])
		locked = unlock if game.profile.level < unlock else 0
	head.add_child(
		UiKit.label(name, UiTheme.SIZE_BODY, UiTheme.TEXT_DIM if locked else UiTheme.TEXT)
	)
	head.add_child(UiKit.label(facts, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	if locked:
		head.add_child(
			UiKit.label("Unlocks at Lv %d" % locked, UiTheme.SIZE_CAPTION, UiTheme.DANGER)
		)
	var slot_text := "Key %d" % (on_slot + 1) if on_slot >= 0 else "Not on the bar"
	head.add_child(
		UiKit.label(
			slot_text, UiTheme.SIZE_CAPTION, UiTheme.ACCENT if on_slot >= 0 else UiTheme.TEXT_FAINT
		)
	)
	text.add_child(UiKit.label(help, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, TEXT_WIDTH))
	for child in text.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card
