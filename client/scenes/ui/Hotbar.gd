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


## The street's bar (reference rules): slot 1 the auto attack, then the known
## abilities the engine runs, in spellbook order. Icons are temporary art chosen
## by the ability's first effect (data/rpg/ability_icons.json).
func build_rpg(content: ContentDB, fight: RpgEncounter) -> void:
	_content = content
	if _row == null:
		name = "Hotbar"
		var style := UiTheme.panel_style()
		style.bg_color = Color(0.04, 0.04, 0.07, 0.72)
		style.set_content_margin_all(3)
		style.shadow_size = 0
		add_theme_stylebox_override("panel", style)
		_row = HBoxContainer.new()
		_row.add_theme_constant_override("separation", 3)
		add_child(_row)
	# One source with the Skills screen: the saved layout, kept to usable abilities.
	var keys: Array[String] = ["attack"]
	var bar := RpgSpellbook.hotbar(
		fight.pack, fight.state, fight.player["mods"], InputSetup.HOTBAR_SLOTS - 1
	)
	for id: Variant in bar:
		keys.append(str(id))
	if keys == _keys:
		return
	_keys = keys
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	slots.clear()
	entries.clear()
	var icons: Dictionary = content.rpg.get("ability_icons", {}).get("by_effect", {})
	for i in keys.size():
		var slot := HotbarSlot.new()
		slot.name = "Slot%d" % (i + 1)
		slot.key = str(i + 1)
		var entry := {"type": "attack"} if i == 0 else {"type": "ability", "id": keys[i]}
		if i > 0 and keys[i] == "":
			entry = {"type": "empty"}
		entries.append(entry)
		var icon := "skill_attack"
		var tip := "Auto attack (J)"
		if entry["type"] == "empty":
			icon = ""
			tip = "Empty. Fill it from Skills (V)."
		elif i > 0:
			var doc: Dictionary = fight.pack["abilities"][keys[i]]
			var first: Array = doc["def"].get("effects", [])
			if not first.is_empty():
				icon = str(icons.get(str(first[0].get("type", "")), icon))
			tip = (
				"%s\nCost %s, cooldown %ss"
				% [doc["display_name"], doc["def"].get("cost", 0), doc["def"].get("cooldown", 0)]
			)
		slot.kind = "attack" if i == 0 else "skill"
		slot.icon = UiKit.icon(content, icon) if icon != "" else null
		slot.tooltip_text = tip
		slot.pressed.connect(func() -> void: slot_pressed.emit(i))
		_row.add_child(slot)
		slots.append(slot)


## The street's bar state: each ability's cooldown and whether the resource
## covers its cost, as the engine has them.
func refresh_rpg(fight: RpgEncounter) -> void:
	build_rpg(_content, fight)
	var p := fight.player
	for i in slots.size():
		var entry := entries[i]
		if entry["type"] != "ability":
			slots[i].set_state(0.0, 0.0, false, -1)
			continue
		var def: Dictionary = fight.pack["abilities"][entry["id"]]["def"]
		var left := float(p["cooldowns"].get(entry["id"], 0.0))
		var total := maxf(0.001, float(def.get("cooldown", 0)))
		var short := float(p["resource"]) < float(def.get("cost", 0))
		slots[i].set_state(clampf(left / total, 0.0, 1.0), left, short, -1)


## The id of the ability in slot `index` ("" for the attack or an empty slot).
func ability_at(index: int) -> String:
	if index < 0 or index >= entries.size() or entries[index]["type"] != "ability":
		return ""
	return str(entries[index]["id"])


## Mirrors the hero's state onto the slots.
func refresh(zone: ZoneSim, profile: PlayerProfile) -> void:
	var keys := HotbarRules.layout(profile, _content)
	if keys != _keys:
		_lay_out(keys)
	var hero := zone.hero
	var next := ComboRules.next_links(hero)
	for i in slots.size():
		var entry := entries[i]
		var slot := slots[i]
		slot.linked = entry["type"] == "skill" and str(entry["id"]) in next
		match entry["type"]:
			"skill":
				var skill: Dictionary = _content.skills[entry["id"]]
				var unlock := int(skill["unlock_level"])
				slot.locked_level = unlock if profile.level < unlock else 0
				var left := hero.cooldown_left(entry["id"])
				var cost := SkillRules.energy_cost(_content, str(entry["id"]))
				var wait := float(left) / int(skill["cooldown"])
				if SkillRules.is_ultimate(skill):
					# An ultimate waits for its gauge, not for a clock.
					wait = maxf(wait, 1.0 - hero.gauge / UltimateRules.FULL)
				slot.set_state(wait, left * CombatRules.TICK_SECONDS, hero.energy < cost, -1)
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
			return (
				"%s\n%s\n%s   Unlocks at Lv %d"
				% [
					skill["name"],
					skill["description"],
					SkillRules.facts(content, str(entry["id"])),
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
