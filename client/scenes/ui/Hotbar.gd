class_name Hotbar
extends PanelContainer
## The seven-slot action bar along the bottom of the screen, as the player
## laid it out (HotbarRules: any slot can hold the attack, a skill or food,
## in any order; the Bag screen edits it). It shows what the simulation says
## (cooldowns, energy, unlocks, counts) and reports presses; whether a press
## does anything is decided by the game and the simulation. It rebuilds
## itself when the layout changes.

signal slot_pressed(index: int)

var slots: Array[HotbarSlot] = []
var entries: Array[Dictionary] = []
var _content: ContentDB
var _keys: Array[String] = []
var _row: HBoxContainer


func build(content: ContentDB, profile: PlayerProfile) -> void:
	_content = content
	name = "Hotbar"
	var style := UiTheme.panel_style()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.72)
	style.set_content_margin_all(3)
	style.shadow_size = 0
	add_theme_stylebox_override("panel", style)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 3)
	add_child(_row)
	_lay_out(HotbarRules.layout(profile, content))


func _lay_out(keys: Array[String]) -> void:
	_keys = keys
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	slots.clear()
	entries.clear()
	for i in keys.size():
		var entry := HotbarRules.entry_of(keys[i])
		entries.append(entry)
		var slot := HotbarSlot.new()
		slot.name = "Slot%d" % (i + 1)
		# The attack shares its key with Z, so show both.
		slot.key = "%d Z" % (i + 1) if entry["type"] == "attack" else str(i + 1)
		slot.kind = str(entry["type"])
		var icon := icon_id(_content, entry)
		slot.icon = UiKit.icon(_content, icon) if icon else null
		slot.tooltip_text = tooltip(_content, entry)
		slot.pressed.connect(func() -> void: slot_pressed.emit(i))
		_row.add_child(slot)
		slots.append(slot)


## Mirrors the hero's state onto the slots.
func refresh(zone: ZoneSim, profile: PlayerProfile) -> void:
	var keys := HotbarRules.layout(profile, _content)
	if keys != _keys:
		_lay_out(keys)
	var hero := zone.hero
	for i in slots.size():
		var entry := entries[i]
		var slot := slots[i]
		match entry["type"]:
			"skill":
				var skill: Dictionary = _content.skills[entry["id"]]
				var unlock := int(skill["unlock_level"])
				slot.locked_level = unlock if profile.level < unlock else 0
				var left := hero.cooldown_left(entry["id"])
				var cost := _content.moves.get_move(str(skill["move"])).energy_cost
				slot.set_state(
					float(left) / int(skill["cooldown"]),
					left * CombatRules.TICK_SECONDS,
					hero.energy < cost,
					-1
				)
			"item":
				var total := maxi(1, _content.item_cooldown)
				slot.set_state(
					float(zone.item_cooldown) / total,
					zone.item_cooldown * CombatRules.TICK_SECONDS,
					false,
					profile.count(entry["id"])
				)
			_:
				slot.set_state(0.0, 0.0, false, -1)


static func icon_id(content: ContentDB, entry: Dictionary) -> String:
	match entry["type"]:
		"skill":
			return str(content.skills[entry["id"]]["icon"])
		"item":
			return str(content.item(entry["id"]).get("icon", ""))
		"attack":
			return str(attack_entry(content).get("icon", ""))
	return ""


## skills.json's attack slot (its icon, name and help).
static func attack_entry(content: ContentDB) -> Dictionary:
	for entry: Dictionary in content.hotbar:
		if entry.get("type") == "attack":
			return entry
	return {}


static func tooltip(content: ContentDB, entry: Dictionary) -> String:
	match entry["type"]:
		"skill":
			var skill: Dictionary = content.skills[entry["id"]]
			var move := content.moves.get_move(str(skill["move"]))
			return (
				"%s\n%s\nEnergy %d   Cooldown %ss   Unlocks at Lv %d"
				% [
					skill["name"],
					skill["description"],
					roundi(move.energy_cost),
					str(snappedf(int(skill["cooldown"]) * CombatRules.TICK_SECONDS, 0.1)),
					int(skill["unlock_level"]),
				]
			)
		"item":
			var item := content.item(entry["id"])
			return "%s\n%s" % [item["name"], item.get("description", "")]
		"attack":
			var attack := attack_entry(content)
			return "%s\n%s" % [attack.get("name", ""), attack.get("description", "")]
	return "Empty. Fill it from the Bag (B)."
