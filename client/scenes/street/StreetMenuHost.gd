class_name StreetMenuHost
extends CanvasLayer
## Holds the street's open game screen (StreetMenus), one at a time, as the
## original Game does (Game.open_screen / close_menu): opening a screen replaces the
## one open, opening the open one closes it, and the street goes on behind it. The
## screens read the street's engine state through this node and send every change
## to menu_action, which runs it through the engine (RpgCharacter, RpgSpellbook),
## refreshes the live unit (RpgEncounter.character_changed), rebuilds the screen and
## saves (Street.save_durably).

var street: Node
var menu: Control = null
var menu_name := ""
## The selected thing on the open screen: "bag:<index>", "worn:<slot>",
## "skill:<id>" or "talent".
var menu_focus := ""
var content: ContentDB:
	get:
		return street.content
var pack: Dictionary:
	get:
		return street.pack
var state: Dictionary:
	get:
		return street.state
var fight: RpgEncounter:
	get:
		return street.fight


func _init(p_street: Node) -> void:
	street = p_street
	layer = 8
	name = "Menus"


func is_open() -> bool:
	return menu != null


## Screen `name` (StreetMenus.SCREENS), or close it if it is the one open.
func open_screen(name: String) -> void:
	if menu_name == name:
		close_menu()
		return
	if menu_name != name:
		menu_focus = ""
	Sfx.play("ui_select", -4.0)
	_show(name, StreetMenus.screen(self, name))


func open_pause() -> void:
	_show("pause", StreetMenus.pause_menu(self))


func close_menu() -> void:
	if menu:
		menu.queue_free()
		Sfx.play("ui_back", -4.0)
	menu = null
	menu_name = ""
	menu_focus = ""


## Q / E: the previous or next of the five screens.
func cycle(step: int) -> void:
	var at := StreetMenus.ORDER.find(menu_name)
	if at < 0:
		return
	var n := StreetMenus.ORDER.size()
	open_screen(StreetMenus.ORDER[(at + step + n) % n])


func menu_select(focus: String) -> void:
	menu_focus = focus
	_rebuild()


## One change from a screen, through the engine. A refusal is shown and changes
## nothing; a change refreshes the unit, the screen and the save.
func menu_action(action: String, arg: Variant) -> void:
	var why := ""
	match action:
		"equip":
			var index := int(arg)
			var item_id := str(state["inventory"][index]["item_id"])
			why = RpgCharacter.equip(content, pack, state, item_id, "", index)
			if why == "":
				menu_focus = "worn:" + _worn_slot_of(item_id)
		"unequip":
			why = RpgCharacter.unequip(state, str(arg))
			if why == "":
				menu_focus = "bag:%d" % (state["inventory"].size() - 1)
		"spec":
			why = RpgCharacter.choose_spec(content, pack, state, str(arg))
		"talent":
			why = RpgCharacter.choose_talent(pack, state, int(arg[0]), str(arg[1]))
			menu_focus = "talent"
		"hotbar":
			var mods: Dictionary = fight.player["mods"]
			why = RpgSpellbook.assign(pack, state, mods, int(arg[0]), str(arg[1]), 6)
		"save":
			pass
	if why != "":
		street.hud.toast(why)
		Sfx.play("denied", -6.0)
		_rebuild()
		return
	fight.character_changed()
	street.save_durably()
	if action == "save":
		street.hud.toast("Saved")
		return
	_rebuild()


func quit_to_title() -> void:
	street.quit_to_title()


func _worn_slot_of(item_id: String) -> String:
	for slot: String in state["equipment"]:
		if str(state["equipment"][slot]) == item_id:
			return slot
	return ""


func _rebuild() -> void:
	if menu_name != "" and menu_name != "pause":
		_show(menu_name, StreetMenus.screen(self, menu_name))


func _show(name: String, screen: Control) -> void:
	if menu:
		menu.queue_free()
	menu = screen
	menu_name = name
	add_child(menu)
	# The selected thing keeps the keyboard focus across a rebuild (as Game's Bag).
	var keep := _focus_node()
	if keep != "" and not menu.find_children(keep, "", true, false).is_empty():
		var node: Control = menu.find_children(keep, "", true, false)[0]
		if node.focus_mode != Control.FOCUS_NONE:
			node.grab_focus.call_deferred()
			return
	UiKit.focus_first(menu)


func _focus_node() -> String:
	if menu_focus.begins_with("skill:"):
		return "Skill_" + menu_focus.substr(6)
	if menu_focus.begins_with("bag:"):
		return "Bag_" + menu_focus.substr(4)
	if menu_focus.begins_with("worn:"):
		return "Worn_" + menu_focus.substr(5)
	return ""
