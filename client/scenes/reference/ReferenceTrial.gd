extends Control
## The game on World of ClaudeCraft's rules (Title → New game / Continue; owner order
## 2026-11-18: the new character system replaces the old heroes, whose saves were
## reset). A character is created here (name and one of the nine classes) and saved
## in SaveStore's player/ store (RpgSave v3); its spec, talents, gear, bags, XP,
## death and corpses are the reference's rules.
##
## Creation only: the character's screens (Character, Equipment, Bag, Skills,
## Settings) are the street's (scenes/street, StreetMenus), and a character that
## exists goes straight to the street.
##
## Presentation only: every rule is in client/sim (RpgCharacter, RpgSave); this
## screen sends commands and shows results. Names shown are interim ids.

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
## A new character is being saved: no second one until it is.
var _saving := false


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
	if not state.is_empty():
		_go.call_deferred(STREET_SCENE)
		return
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
	_build_class_choice()


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
	if _saving:
		return
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
	_saving = true
	# The new character is durable before the street opens. A slow browser store is
	# waited for (the commit goes on); only a refused write gives up.
	message = "Saving the new character..."
	_rebuild()
	if not SaveStore.save_player(state):
		state = {}
		_saving = false
		message = "Could not save the new character. Try again."
		_rebuild()
		return
	var path := SaveStore.player_folder().path_join(str(state["id"]) + ".json")
	var seq := DurableSave.request(path)
	while not await DurableSave.wait_durable(path, seq, 10.0):
		message = "Still saving the new character (the browser is busy)..."
		_rebuild()
	_go(STREET_SCENE)


# -- save and leave --------------------------------------------------------------


## Back to the title (a character is never half made: it exists once saved).
func _back() -> void:
	_go(TITLE_SCENE)


func _go(scene: String) -> void:
	went_to = scene
	if navigate:
		get_tree().change_scene_to_file(scene)
