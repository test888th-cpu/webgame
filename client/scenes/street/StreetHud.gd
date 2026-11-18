class_name StreetHud
extends CanvasLayer
## The street's HUD: the character's health, resource and experience, the target,
## the hotbar of known abilities (keys 1-7), auto, loot and the menu buttons. It
## reads the engine's records and sends every action back through Street, which
## turns it into an RpgEncounter command.

signal cast_pressed(ability_id: String)
signal action_pressed(action: String)

const SLOT_SIZE := Vector2(52, 22)

var _me: Label
var _hp: ProgressBar
var _res: ProgressBar
var _xp: ProgressBar
var _target: Label
var _target_hp: ProgressBar
var _area: Label
var _log: Label
var _slots: HBoxContainer
var _auto: Button
var _loot: Button
var _revive: Button
var _slot_ids: Array[String] = []


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := VBoxContainer.new()
	top.position = Vector2(8, 6)
	root.add_child(top)
	_me = UiKit.overlay_label("", UiTheme.SIZE_SMALL, UiTheme.TEXT)
	top.add_child(_me)
	_hp = _bar(UiTheme.DANGER, 140)
	top.add_child(_hp)
	_res = _bar(UiTheme.EP, 140)
	top.add_child(_res)
	_xp = _bar(UiTheme.XP, 140, 3)
	top.add_child(_xp)
	var right := VBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-168, 6)
	right.custom_minimum_size.x = 160
	root.add_child(right)
	_area = UiKit.overlay_label("", UiTheme.SIZE_SMALL, UiTheme.ACCENT)
	right.add_child(_area)
	_target = UiKit.overlay_label("", UiTheme.SIZE_SMALL, UiTheme.TEXT)
	right.add_child(_target)
	_target_hp = _bar(UiTheme.DANGER, 160)
	right.add_child(_target_hp)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.position = Vector2(8, -78)
	root.add_child(bottom)
	_log = UiKit.overlay_label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	bottom.add_child(_log)
	var row := HBoxContainer.new()
	bottom.add_child(row)
	_auto = _button(row, "Auto (T)", "auto")
	_loot = _button(row, "Loot (E)", "loot")
	_revive = _button(row, "Resurrect", "revive")
	_button(row, "Character (C)", "character")
	_button(row, "Menu (Esc)", "menu")
	_slots = HBoxContainer.new()
	bottom.add_child(_slots)


func _bar(color: Color, width: float, height := 6) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, height)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.55)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _button(row: HBoxContainer, text: String, action: String) -> Button:
	var b := UiKit.button(text, func() -> void: action_pressed.emit(action))
	b.name = "Hud_" + action
	b.focus_mode = Control.FOCUS_NONE
	row.add_child(b)
	return b


## The hotbar: the known abilities the engine can run, in spellbook order.
func set_abilities(pack: Dictionary, known: Array) -> void:
	for child: Node in _slots.get_children():
		child.queue_free()
	_slot_ids.clear()
	for k: Dictionary in known:
		var def: Dictionary = pack["abilities"].get(k["id"], {})
		if not str(def.get("status", "")).begins_with("IMPLEMENTED"):
			continue
		if _slot_ids.size() >= InputSetup.HOTBAR_SLOTS:
			break
		_slot_ids.append(str(k["id"]))
		var text := "%d %s" % [_slot_ids.size(), def.get("display_name", k["id"])]
		var b := UiKit.button(text, func() -> void: cast_pressed.emit(str(k["id"])))
		b.name = "Slot_" + str(k["id"])
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = SLOT_SIZE
		b.clip_text = true
		_slots.add_child(b)


func slot_ability(slot: int) -> String:
	return _slot_ids[slot - 1] if slot >= 1 and slot <= _slot_ids.size() else ""


func show_state(fight: RpgEncounter, state: Dictionary, area_name: String) -> void:
	var p := fight.player
	_me.text = (
		"%s  Lv %d %s  %d copper"
		% [state["name"], state["level"], str(state["class_id"]).capitalize(), state["copper"]]
	)
	_hp.max_value = float(p["max_hp"])
	_hp.value = float(p["hp"])
	_res.visible = float(p["max_resource"]) > 0.0
	_res.max_value = maxf(1.0, float(p["max_resource"]))
	_res.value = float(p["resource"])
	var need := RpgProgression.xp_for_level(int(state["level"]))
	_xp.max_value = maxf(1.0, float(need))
	_xp.value = float(state["xp"])
	_area.text = area_name
	var t := fight.mob
	_target.visible = not t.is_empty()
	_target_hp.visible = not t.is_empty()
	if not t.is_empty():
		var name := str(RpgPack.monster(fight.pack, str(t["template_id"])).get("display_name"))
		_target.text = "%s  Lv %d" % [name, t["level"]]
		_target_hp.max_value = float(t["max_hp"])
		_target_hp.value = float(t["hp"])
	_auto.text = "Auto ON (T)" if fight.auto_mode else "Auto (T)"
	_loot.visible = _has_loot(state)
	_revive.visible = fight.outcome == "defeat"
	for b: Node in _slots.get_children():
		var id := str(b.name).trim_prefix("Slot_")
		(b as Button).disabled = p["cooldowns"].has(id) or p["dead"]


func say(text: String) -> void:
	_log.text = text


static func _has_loot(state: Dictionary) -> bool:
	for c: Dictionary in state.get("corpses", []):
		if int(c["loot"]["copper"]) > 0 or not c["loot"]["items"].is_empty():
			return true
	return false
