extends CanvasLayer
## In-game heads-up display, built in code from UiKit/UiTheme:
##   top left   hero card: level badge, name, HP (with damage trail), energy, XP
##   top right  coins, area name, tracked quest card
##   bottom     boss bar (boss fights only), key hints
##   centre     notification banner
## Touch buttons appear only on touch devices. The HUD only reads state.

const TOAST_SECONDS := 2.4
const BAR_WIDTH := 118.0

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB

var _toast_left := 0.0
var _level: Label
var _name: Label
var _hp: StatBar
var _energy: StatBar
var _xp: StatBar
var _money: Label
var _area: Label
var _quest_card: PanelContainer
var _quest_name: Label
var _quest_progress: Label
var _boss: VBoxContainer
var _boss_name: Label
var _boss_bar: StatBar
var _toast: PanelContainer
var _toast_text: Label
var _fps: Label
var _touch: Control


func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_hero_card(root)
	_build_top_right(root)
	_build_boss_bar(root)
	_build_toast(root)
	_build_hints(root)
	_touch = TouchControls.build()
	_touch.visible = DisplayServer.is_touchscreen_available()
	root.add_child(_touch)


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	_area.text = str(zone.area.get("name", ""))
	_money_icon_once()


func toast(text: String) -> void:
	_toast_text.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.4, 0.0, 1.0)
		_toast.visible = _toast_left > 0.0
	_fps.visible = GameSession.settings.get("show_fps", false)
	if _fps.visible:
		_fps.text = "%d fps" % Engine.get_frames_per_second()
	if zone == null:
		return
	var hero := zone.hero
	_level.text = str(profile.level)
	_hp.set_values(hero.hp, hero.max_hp)
	_energy.set_values(hero.energy, CombatRules.MAX_ENERGY)
	_xp.set_values(profile.xp, profile.xp_to_next(content))
	_money.text = str(profile.money)
	_update_quest()
	var boss := zone.fighter(zone.boss_id) if zone.boss_id else null
	_boss.visible = boss != null and not boss.is_ko()
	if _boss.visible:
		_boss_name.text = str(content.enemy(boss.kind).get("name", "")).to_upper()
		_boss_bar.set_values(boss.hp, boss.max_hp)


func _build_hero_card(root: Control) -> void:
	var card := PanelContainer.new()
	card.name = "HeroCard"
	card.position = Vector2(6, 6)
	card.add_theme_stylebox_override("panel", _compact_panel())
	root.add_child(card)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	card.add_child(line)
	var badge := PanelContainer.new()
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("2a1d10")
	badge_style.border_color = UiTheme.ACCENT
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(3)
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.custom_minimum_size = Vector2(26, 26)
	line.add_child(badge)
	var badge_text := VBoxContainer.new()
	badge_text.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_text.add_theme_constant_override("separation", -4)
	badge.add_child(badge_text)
	var lv := UiKit.label("LV", UiTheme.SIZE_CAPTION, UiTheme.ACCENT)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.add_child(lv)
	_level = UiKit.label("1", UiTheme.SIZE_H2, UiTheme.TEXT)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.add_child(_level)
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 2)
	line.add_child(bars)
	_name = UiKit.label("MIKA", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	bars.add_child(_name)
	_hp = _bar(UiTheme.HP, Vector2(BAR_WIDTH, 9), true)
	bars.add_child(_hp)
	_energy = _bar(UiTheme.EP, Vector2(BAR_WIDTH, 5), false)
	bars.add_child(_energy)
	_xp = _bar(UiTheme.XP, Vector2(BAR_WIDTH, 3), false)
	bars.add_child(_xp)


func _build_top_right(root: Control) -> void:
	var column := VBoxContainer.new()
	column.name = "TopRight"
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 3)
	column.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	column.offset_left = -170
	column.offset_right = -6
	column.offset_top = 6
	root.add_child(column)
	var money := HBoxContainer.new()
	money.name = "Money"
	money.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(money)
	_money = UiKit.overlay_label("0", UiTheme.SIZE_H2, UiTheme.GOLD)
	money.add_child(_money)
	_area = UiKit.overlay_label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	_area.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_area)
	_quest_card = PanelContainer.new()
	_quest_card.add_theme_stylebox_override("panel", _compact_panel())
	column.add_child(_quest_card)
	var quest := VBoxContainer.new()
	quest.add_theme_constant_override("separation", 0)
	_quest_card.add_child(quest)
	quest.add_child(UiKit.label("QUEST", UiTheme.SIZE_CAPTION, UiTheme.ACCENT))
	_quest_name = UiKit.label("", UiTheme.SIZE_SMALL, UiTheme.TEXT, 150)
	quest.add_child(_quest_name)
	_quest_progress = UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	quest.add_child(_quest_progress)
	_fps = UiKit.overlay_label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_fps)


func _money_icon_once() -> void:
	var money := _money.get_parent()
	if money.get_child_count() == 1:
		var coin := UiKit.icon_rect(content, "coin")
		money.add_child(coin)
		money.move_child(coin, 0)


func _build_boss_bar(root: Control) -> void:
	_boss = VBoxContainer.new()
	_boss.name = "Boss"
	_boss.visible = false
	_boss.add_theme_constant_override("separation", 1)
	_boss.position = Vector2(170, 318)
	_boss.custom_minimum_size = Vector2(300, 0)
	root.add_child(_boss)
	_boss_name = UiKit.overlay_label("", UiTheme.SIZE_SMALL, Color("ffb0a0"))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss.add_child(_boss_name)
	_boss_bar = _bar(UiTheme.DANGER, Vector2(300, 8), false)
	_boss.add_child(_boss_bar)


func _build_toast(root: Control) -> void:
	_toast = PanelContainer.new()
	_toast.name = "Toast"
	_toast.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.88)
	style.border_color = UiTheme.ACCENT
	style.border_width_left = 3
	style.set_corner_radius_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_toast.add_theme_stylebox_override("panel", style)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 60
	root.add_child(_toast)
	_toast_text = UiKit.label("", UiTheme.SIZE_H2, UiTheme.TEXT)
	_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_text)


func _build_hints(root: Control) -> void:
	var hints := HBoxContainer.new()
	hints.name = "Hints"
	hints.add_theme_constant_override("separation", 8)
	hints.position = Vector2(8, 346)
	hints.add_child(UiKit.key_hint("Esc", "Menu"))
	hints.add_child(UiKit.key_hint("H", "Eat"))
	hints.add_child(UiKit.key_hint("J K", "Attack"))
	hints.add_child(UiKit.key_hint("Space", "Dodge"))
	hints.add_child(UiKit.key_hint("Shift", "Guard"))
	hints.modulate.a = 0.8
	root.add_child(hints)


func _update_quest() -> void:
	for quest_id: String in profile.quests:
		var entry: Dictionary = profile.quests[quest_id]
		var quest: Dictionary = content.quests[quest_id]
		if entry["state"] == "active":
			_quest_card.visible = true
			_quest_name.text = str(quest["name"])
			_quest_progress.text = "%d / %d" % [entry["progress"], quest["objective"]["count"]]
			return
		if entry["state"] == "complete":
			_quest_card.visible = true
			_quest_name.text = str(quest["name"])
			_quest_progress.text = "Complete. Return to the giver."
			return
	_quest_card.visible = false


func _bar(color: Color, size: Vector2, text: bool) -> StatBar:
	var bar := StatBar.new()
	bar.color = color
	bar.show_text = text
	bar.custom_minimum_size = size
	return bar


func _compact_panel() -> StyleBoxFlat:
	var style := UiTheme.panel_style()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.78)
	style.set_content_margin_all(4)
	style.shadow_size = 0
	return style
