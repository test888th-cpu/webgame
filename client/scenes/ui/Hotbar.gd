class_name Hotbar
extends PanelContainer
## The seven-slot action bar along the bottom of the screen, laid out by
## data/skills.json and the hero's skills: 1 attack, 2-5 skills, 6-7
## consumables. It shows what the
## simulation says (cooldowns, energy, unlocks, counts) and reports presses;
## whether a press does anything is decided by the game and the simulation.

signal slot_pressed(index: int)

var slots: Array[HotbarSlot] = []
var entries: Array[Dictionary] = []
var _content: ContentDB


func build(content: ContentDB, hero_id: String) -> void:
	_content = content
	entries = content.hotbar_for(hero_id)
	name = "Hotbar"
	var style := UiTheme.panel_style()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.72)
	style.set_content_margin_all(3)
	style.shadow_size = 0
	add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	add_child(row)
	for i in entries.size():
		var entry := entries[i]
		var slot := HotbarSlot.new()
		slot.name = "Slot%d" % (i + 1)
		slot.key = str(i + 1)
		slot.kind = str(entry["type"])
		slot.icon = UiKit.icon(content, icon_id(content, entry))
		slot.tooltip_text = tooltip(content, entry)
		slot.pressed.connect(func() -> void: slot_pressed.emit(i))
		row.add_child(slot)
		slots.append(slot)
		if i == 0 or i == 4:
			# Gaps group the bar: attack | skills | items.
			var gap := Control.new()
			gap.custom_minimum_size.x = 3
			row.add_child(gap)


## Mirrors the hero's state onto the slots.
func refresh(zone: ZoneSim, profile: PlayerProfile) -> void:
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
	return str(entry.get("icon", ""))


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
	return "%s\n%s" % [entry.get("name", ""), entry.get("description", "")]
