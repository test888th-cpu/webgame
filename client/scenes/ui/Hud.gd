extends CanvasLayer
## In-game heads-up display, built in code from UiKit/UiTheme:
##   top left   hero card: level badge, name, HP (with damage trail), energy, XP
##   top centre boss bar (boss fights only)
##   top right  coins, area name, tracked quest card
##   bottom     hotbar (attack, skills, items), key hints
##   centre     notification banner, level-up banner
##   edges      red vignette when the hero is hurt
## Touch buttons appear only on touch devices. The HUD only reads state and
## reports hotbar presses (slot_pressed).

signal slot_pressed(index: int)

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
var _hotbar: Hotbar
var _vignette: TextureRect
var _hurt := 0.0
var _banner: VBoxContainer
var _banner_level: Label
var _banner_detail: Label
var _banner_left := 0.0


func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_vignette(root)
	_build_hero_card(root)
	_build_top_right(root)
	_build_boss_bar(root)
	_build_toast(root)
	_build_banner(root)
	_build_hints(root)
	_touch = TouchControls.build()
	_touch.visible = DisplayServer.is_touchscreen_available()
	root.add_child(_touch)


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	_area.text = str(zone.area.get("name", ""))
	_name.text = profile.name.to_upper()
	_money_icon_once()
	if _hotbar == null:
		_hotbar = Hotbar.new()
		_hotbar.build(content, profile.hero)
		_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_hotbar.offset_bottom = -4
		_hotbar.offset_top = -4
		_hotbar.slot_pressed.connect(slot_pressed.emit)
		get_node("Root").add_child(_hotbar)


## Flashes hotbar slot `index`: used (accepted) or refused.
func flash_slot(index: int, accepted: bool) -> void:
	if _hotbar:
		_hotbar.slots[index].flash(accepted)


## Red edges for a moment: the hero was hit.
func hurt(strength := 1.0) -> void:
	_hurt = maxf(_hurt, 0.35 * strength)


## The big level-up announcement, naming any skills it unlocked.
func level_up(level: int, unlocked: Array) -> void:
	_banner_level.text = "Level %d" % level
	var names: Array[String] = []
	for skill_id: String in unlocked:
		names.append(str(content.skills[skill_id]["name"]))
	_banner_detail.text = (
		"New skill: " + ", ".join(names) if names else "Max HP and damage increased"
	)
	_banner.visible = true
	_banner.scale = Vector2(1.4, 1.4)
	_banner.modulate.a = 1.0
	_banner.pivot_offset = _banner.size / 2.0
	_banner_left = 2.6
	var tween := create_tween()
	tween.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func toast(text: String) -> void:
	_toast_text.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS


func _process(delta: float) -> void:
	_hurt = maxf(0.0, _hurt - delta)
	_vignette.modulate.a = clampf(_hurt / 0.35, 0.0, 1.0) * 0.8
	if _banner_left > 0.0:
		_banner_left -= delta
		_banner.modulate.a = clampf(_banner_left / 0.5, 0.0, 1.0)
		_banner.visible = _banner_left > 0.0
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
	if _hotbar:
		_hotbar.refresh(zone, profile)
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
	_boss.position = Vector2(190, 8)
	_boss.custom_minimum_size = Vector2(260, 0)
	root.add_child(_boss)
	_boss_name = UiKit.overlay_label("", UiTheme.SIZE_SMALL, Color("ffb0a0"))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss.add_child(_boss_name)
	_boss_bar = _bar(UiTheme.DANGER, Vector2(260, 8), false)
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
	hints.add_child(UiKit.key_hint("K", "Heavy"))
	hints.add_child(UiKit.key_hint("Space", "Dodge"))
	hints.add_child(UiKit.key_hint("Shift", "Guard"))
	hints.modulate.a = 0.8
	root.add_child(hints)


func _build_vignette(root: Control) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.8, 0.05, 0.05, 0.0))
	gradient.set_color(1, Color(0.8, 0.05, 0.05, 0.75))
	gradient.add_point(0.55, Color(0.8, 0.05, 0.05, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	texture.width = 128
	texture.height = 72
	_vignette = TextureRect.new()
	_vignette.name = "Vignette"
	_vignette.texture = texture
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	root.add_child(_vignette)


func _build_banner(root: Control) -> void:
	_banner = VBoxContainer.new()
	_banner.name = "LevelUp"
	_banner.visible = false
	_banner.add_theme_constant_override("separation", 0)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 96
	root.add_child(_banner)
	var title := UiKit.overlay_label("LEVEL UP!", UiTheme.SIZE_LOGO - 6, UiTheme.GOLD)
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(title)
	_banner_level = UiKit.overlay_label("", UiTheme.SIZE_H1, UiTheme.TEXT)
	_banner_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_level)
	_banner_detail = UiKit.overlay_label("", UiTheme.SIZE_BODY, UiTheme.TEAL)
	_banner_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_detail)


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
