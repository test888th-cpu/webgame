extends Control
## The game on World of ClaudeCraft's rules (Title → New game / Continue; owner order
## 2026-11-18: the new character system replaces the old heroes, whose saves were
## reset). A character is created here (name and one of the nine classes) and saved
## in SaveStore's player/ store (RpgSave v3); its spec, talents, gear, bags, XP,
## death and corpses are the reference's rules.
##
## It is also the character sheet (C in the street): spec, talents, gear, bags and
## abilities. The fighting is in the street (scenes/street/Street.tscn), where the
## reference monsters stand on the city's areas.
##
## Presentation only: every rule is in client/sim (RpgCharacter, RpgTalents, RpgGear,
## RpgSave); this screen sends commands and shows results. Names shown are interim ids.

const TITLE_SCENE := "res://scenes/title/Title.tscn"
const STREET_SCENE := "res://scenes/street/Street.tscn"
const CLASSES: Array[String] = [
	"warrior", "paladin", "rogue", "shaman", "hunter", "mage", "priest", "warlock", "druid"
]
const COLUMN := 200.0

var content: ContentDB
var pack: Dictionary
var state: Dictionary = {}
var message := ""
## Tests turn scene changes off and read where the screen would go.
var navigate := true
var went_to := ""
var _name_edit: LineEdit
var _columns: HBoxContainer
var _probe_timer := 0.0


func _ready() -> void:
	content = GameSession.content
	pack = RpgPack.of(content)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# The production character (SaveStore player/, RpgSave v3); none: a new one.
	state = {}
	if GameSession.character_id != "":
		state = SaveStore.load_player(GameSession.character_id, content)
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


## Read-only state for the browser smoke test: only what the screen already shows
## (the character line and the focused button's name).
func _process(delta: float) -> void:
	_probe_timer += delta
	if _probe_timer < 0.1:
		return
	_probe_timer = 0.0
	var focus := get_viewport().gui_get_focus_owner()
	var probe := {
		"scene": "rpg",
		"has_character": not state.is_empty(),
		"name": str(state.get("name", "")),
		"class": str(state.get("class_id", "")),
		"level": int(state.get("level", 0)),
		"kills": int(state.get("kills", 0)),
		"focus": str(focus.name) if focus != null else "",
	}
	GameSession.publish_probe(probe)


# -- layout --------------------------------------------------------------------


func _rebuild() -> void:
	for child: Node in get_children():
		if child.name == "Ui":
			remove_child(child)
			child.queue_free()
	var ui := VBoxContainer.new()
	ui.name = "Ui"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.offset_left = UiTheme.SCREEN_MARGIN
	ui.offset_right = -UiTheme.SCREEN_MARGIN
	ui.offset_top = UiTheme.SCREEN_MARGIN
	ui.offset_bottom = -UiTheme.SCREEN_MARGIN
	add_child(ui)
	var top := HBoxContainer.new()
	var title := "The Iron Legacy" if state.is_empty() else str(state.get("name", ""))
	top.add_child(UiKit.label(title, UiTheme.SIZE_H1, UiTheme.ACCENT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(UiKit.button("Back", _back))
	ui.add_child(top)
	ui.add_child(
		UiKit.label(
			"World of ClaudeCraft rules (pinned d2b91e08), single player, saved on this device.",
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_DIM
		)
	)
	if message != "":
		ui.add_child(UiKit.label(message, UiTheme.SIZE_SMALL, UiTheme.GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ui.add_child(scroll)
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", UiTheme.PAD)
	scroll.add_child(_columns)
	if state.is_empty():
		_build_class_choice()
		return
	_build_play()
	_build_character()
	_build_abilities()


func _column(title: String) -> VBoxContainer:
	var col := UiKit.section(title)
	col.custom_minimum_size.x = COLUMN
	_columns.add_child(col)
	return col


func _line(col: Container, text: String, color := UiTheme.TEXT, size := UiTheme.SIZE_SMALL) -> void:
	col.add_child(UiKit.label(text, size, color, COLUMN))


# -- class choice --------------------------------------------------------------


func _build_class_choice() -> void:
	var col := _column("New character: name and class")
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.placeholder_text = "Name"
	_name_edit.max_length = PlayerProfile.NAME_MAX
	_name_edit.custom_minimum_size.x = COLUMN
	col.add_child(_name_edit)
	for cls: String in CLASSES:
		var why := RpgEncounter.can_fight(pack, {"class_id": cls})
		var b := UiKit.button(cls.capitalize(), _create.bind(cls))
		b.name = "Class_" + cls
		col.add_child(b)
		if why != "":
			_line(
				col, "Cannot fight in this build: " + why, UiTheme.TEXT_FAINT, UiTheme.SIZE_CAPTION
			)
	UiKit.focus_first(col)


func _create(cls: String) -> void:
	var name := PlayerProfile.clean_name(_name_edit.text if _name_edit else "")
	if name.length() < PlayerProfile.NAME_MIN:
		message = (
			"Choose a name of %d to %d letters." % [PlayerProfile.NAME_MIN, PlayerProfile.NAME_MAX]
		)
		_rebuild()
		return
	state = RpgCharacter.create(content, pack, cls)
	state["id"] = SaveStore.new_id()
	state["name"] = name
	GameSession.character_id = state["id"]
	_save()
	_go(STREET_SCENE)


# -- character, gear and bags --------------------------------------------------


func _build_character() -> void:
	var col := _column("Character")
	var sheet := RpgCharacter.sheet(content, pack, state)
	var unit := RpgUnit.player(content, pack, state)
	RpgEncounter.restore_vitals(unit, state)
	var vitals := {"hp": unit["hp"], "resource": unit["resource"]}
	var spec := str(state["spec_id"])
	var title := str(state["class_id"]).capitalize() + ("" if spec == "" else " (" + spec + ")")
	_line(col, "%s, level %d" % [title, state["level"]])
	var need := RpgProgression.xp_for_level(int(state["level"]))
	_line(
		col,
		"XP %d / %d   Copper %d   Kills %d" % [state["xp"], need, state["copper"], state["kills"]]
	)
	_line(col, "Health %d / %d" % [vitals["hp"], sheet["max_hp"]], UiTheme.HP)
	_line(
		col,
		"%s %d / %d" % [sheet["resource"].capitalize(), vitals["resource"], sheet["max_resource"]],
		UiTheme.EP
	)
	var s: Dictionary = sheet["stats"]
	_line(
		col,
		"Str %d Agi %d Sta %d Int %d Spi %d" % [s["str"], s["agi"], s["sta"], s["int"], s["spi"]]
	)
	_line(
		col,
		(
			"Armor %d  AP %d  Crit %.1f%%  Dodge %.1f%%"
			% [sheet["armor"], sheet["attack_power"], sheet["crit"] * 100, sheet["dodge"] * 100]
		)
	)
	var w: Dictionary = sheet["weapon"]
	_line(col, "Weapon %d-%d, speed %.1f" % [w["min"], w["max"], w["speed"]])
	if spec == "" and int(state["level"]) >= int(RpgPack.constant(pack, "spec_unlock_level")):
		for sp: Dictionary in RpgClassRegistry.specs(content, str(state["class_id"])):
			col.add_child(UiKit.button("Choose " + str(sp["display_name"]), _spec.bind(sp["id"])))
	col.add_child(UiKit.section("Equipped"))
	for slot: String in state["equipment"]:
		var row := HBoxContainer.new()
		row.add_child(
			UiKit.label("%s: %s" % [slot, _name(state["equipment"][slot])], UiTheme.SIZE_SMALL)
		)
		row.add_child(UiKit.button("Unequip", _unequip.bind(slot)))
		col.add_child(row)
	col.add_child(UiKit.section("Bags (%d)" % state["inventory"].size()))
	for i in state["inventory"].size():
		var item_id := str(state["inventory"][i]["item_id"])
		var row := HBoxContainer.new()
		row.add_child(UiKit.label(_name(item_id), UiTheme.SIZE_SMALL))
		if RpgPack.item(pack, item_id).get("slot") != null:
			row.add_child(UiKit.button("Equip", _equip.bind(item_id)))
		row.add_child(UiKit.button("Sell", _sell.bind(i)))
		col.add_child(row)
	col.add_child(UiKit.button("Rest", _rest))
	col.add_child(UiKit.button("Delete character", _start_over))


func _name(item_id: String) -> String:
	return str(RpgPack.item(pack, item_id).get("display_name", item_id))


func _spec(spec_id: String) -> void:
	message = RpgCharacter.choose_spec(content, pack, state, spec_id)
	_after_change()


func _equip(item_id: String) -> void:
	message = RpgCharacter.equip(content, pack, state, item_id)
	_after_change()


func _unequip(slot: String) -> void:
	message = RpgCharacter.unequip(state, slot)
	_after_change()


func _sell(index: int) -> void:
	message = RpgCharacter.sell(pack, state, index)
	_after_change()


func _rest() -> void:
	RpgEncounter.wait(content, pack, state, 10.0)
	message = "Ten seconds out of combat (2-second regen ticks)."
	_after_change()


## Delete this character (its save goes) and go back to the title.
func _start_over() -> void:
	SaveStore.delete_player(str(state.get("id", "")))
	state = {}
	GameSession.character_id = ""
	_go(TITLE_SCENE)


func _after_change() -> void:
	_save()
	_rebuild()


# -- abilities -----------------------------------------------------------------


func _build_abilities() -> void:
	var col := _column("Abilities and talents (reference)")
	var unit := RpgUnit.player(content, pack, state)
	var known := RpgTalents.known(pack, str(state["class_id"]), int(state["level"]), unit["mods"])
	var usable := 0
	for k: Dictionary in known:
		usable += int(str(pack["abilities"][k["id"]]["status"]).begins_with("IMPLEMENTED"))
	_line(col, "%d known, %d usable in this build." % [known.size(), usable], UiTheme.TEXT_DIM)
	for k: Dictionary in known:
		var doc: Dictionary = pack["abilities"][k["id"]]
		var ok := str(doc["status"]).begins_with("IMPLEMENTED")
		_line(
			col,
			"%s (rank %d)" % [doc["display_name"], k["rank"]],
			UiTheme.GOOD if ok else UiTheme.TEXT
		)
		if not ok:
			_line(col, str(doc["reason"]), UiTheme.TEXT_FAINT, UiTheme.SIZE_CAPTION)
	_build_talents(col)


## Talent rows (one option per row, from its level); a choice applies from the next
## step in the street.
func _build_talents(col: VBoxContainer) -> void:
	var chosen: Dictionary = state.get("talents", {})
	for row: Dictionary in RpgTalents.class_talents(pack, str(state["class_id"]))["rows"]:
		var lvl := int(row["level"])
		col.add_child(UiKit.section("Talents, level %d" % lvl))
		for o: Dictionary in row["options"]:
			var picked: bool = chosen.get(str(lvl), "") == o["id"]
			var b := UiKit.button(
				("* " if picked else "") + str(o["display_name"]),
				_talent.bind(lvl, o["id"]),
				int(state["level"]) < lvl
			)
			col.add_child(b)


func _talent(row_level: int, option_id: String) -> void:
	message = RpgCharacter.choose_talent(pack, state, row_level, option_id)
	_after_change()


# -- save and leave --------------------------------------------------------------


func _save() -> void:
	if state.is_empty():
		return
	if not SaveStore.save_player(state):
		message = "Could not save."


## Back to the street with a character; to the title without one.
func _back() -> void:
	_save()
	_go(TITLE_SCENE if state.is_empty() else STREET_SCENE)


func _go(scene: String) -> void:
	went_to = scene
	if navigate:
		get_tree().change_scene_to_file(scene)


func _build_play() -> void:
	var col := _column("Play")
	var enter := UiKit.button("Enter the city", _back)
	enter.name = "EnterCity"
	col.add_child(enter)
	var where := str(content.area(str(state.get("area", ""))).get("name", "the start"))
	_line(col, "You stand in %s." % where, UiTheme.TEXT_DIM)
	UiKit.focus_first(col)
