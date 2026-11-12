extends CanvasLayer
## In-game heads-up display, built in code from UiKit/UiTheme:
##   top left   hero card: level badge, name, HP (with damage trail), energy, XP;
##              under it the held weapon and the AUTO battle switch
##   top centre boss bar (boss fights only)
##   top right  coins, the route card (MiniMap: district, area and level,
##              the district's areas with the hero and its boss), tracked
##              quest card
##   bottom     hotbar (attack, skills, items), key hints
##   centre     notification banner, level-up banner
##   edges      red vignette when the hero is hurt
## Touch buttons appear only while touch is the input in use, and key hints
## only for the keyboard. Where things go follows the screen layout
## (GameSession.layout, ScreenLayout): in portrait a HUD band on top and a
## control deck below the street hold them. The HUD only reads state and
## reports hotbar presses (slot_pressed).

signal slot_pressed(index: int)
## The AUTO switch was clicked or tapped.
signal auto_pressed
## The map strip was clicked or tapped.
signal menu_pressed(name: String)
## The quest card was pressed (or F): accept the new quest or claim a
## finished one's reward (QuestFlow.open_tracker).
signal quest_pressed

## How long "GO >>" blinks after a cleared fight.
const GO_SECONDS := 4.0
## A hit chain shows from this many blows; a completed combo's name stays up
## this long.
const CHAIN_SHOWN := 3
const COMBO_SECONDS := 1.6
const TOAST_SECONDS := 2.4
const BAR_WIDTH := 118.0
## The menu bar's buttons: screen id, icon, tooltip.
const MENU_BAR := [
	["character", "menu_character", "Character (C)"],
	["bag", "menu_bag", "Bag (B)"],
	["skills", "menu_skills", "Skills (V)"],
	["quests", "menu_quests", "Quests (O)"],
	["map", "menu_map", "Map (M)"],
	["settings", "menu_settings", "Settings"],
]
const MENU_BUTTON := Vector2(20, 20)
## Degrees a second the AUTO arrows turn while auto battle runs.
const AUTO_SPIN := 180.0

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
## What was just picked up, small at the left (PickupFeed).
var pickups := PickupFeed.new()

var _toast_left := 0.0
var _portrait: HeroPortrait
var _title: Label
var _name: Label
var _hp: StatBar
var _energy: StatBar
var _gauge: StatBar
var _xp: StatBar
var _money: Label
var _mini: MiniMap
var _quest_card: PanelContainer
## "GO >>" at the right edge after a fight is cleared: the way on is east.
var _go: Label
var _go_left := 0.0
var _quest_heading: Label
var _quest_name: Label
var _quest_progress: Label
## What pressing the card does now: "Accept  (F)", "Claim reward  (F)" or "".
var _quest_action: Label
var _boss: VBoxContainer
var _boss_name: Label
var _boss_icon: TextureRect
var _boss_bar: StatBar
var _toast: PanelContainer
var _toast_text: Label
var _fps: Label
var _touch: Control
var _hotbar: Hotbar
var _weapon: WeaponBadge
var _vignette: TextureRect
var _hurt := 0.0
## The hit chain ("12 HITS") and the name of a combo route just completed,
## at the right edge under "GO".
var _chain: Label
var _combo: Label
var _combo_left := 0.0
var _banner: VBoxContainer
var _banner_level: Label
var _banner_detail: Label
var _banner_left := 0.0
var _auto_button: Button
var _auto_spin: TextureRect
var _auto_label: Label
var _menu_bar: GridContainer
var _world_boss: Label
## Portrait's HUD band and control deck backgrounds, behind everything.
var _bands: Control
var _hero_card: PanelContainer
var _top_right: VBoxContainer
var _hints: HBoxContainer
var _hints_right: HBoxContainer
var _auto_column: VBoxContainer


func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_bands(root)
	_build_vignette(root)
	_build_hero_card(root)
	_build_top_right(root)
	_build_boss_bar(root)
	_build_toast(root)
	_build_banner(root)
	_build_go(root)
	_build_chain(root)
	_build_hints(root)
	_build_auto(root)
	root.add_child(pickups)
	_touch = TouchControls.build()
	_touch.visible = false
	root.add_child(_touch)
	GameSession.layout_changed.connect(apply_layout)
	apply_layout(GameSession.layout)


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	_mini.attach(zone, profile, content)
	_name.text = profile.name
	var hero_data := content.hero(profile.hero)
	var color := Color.from_string(str(hero_data.get("color", "")), UiTheme.ACCENT)
	_portrait.color = color
	_title.text = str(hero_data.get("title", "")).to_upper()
	_title.add_theme_color_override("font_color", color)
	_money_icon_once()
	if _hotbar == null:
		_hotbar = Hotbar.new()
		_hotbar.build(content, profile)
		_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_hotbar.offset_bottom = -4
		_hotbar.offset_top = -4
		_hotbar.slot_pressed.connect(slot_pressed.emit)
		get_node("Root").add_child(_hotbar)
	if _menu_bar == null:
		_build_menu_bar(get_node("Root"))
		_auto_spin.texture = UiKit.icon(content, "menu_auto")
	apply_layout(GameSession.layout)


## Flashes hotbar slot `index`: used (accepted) or refused.
func flash_slot(index: int, accepted: bool) -> void:
	if _hotbar:
		_hotbar.slots[index].flash(accepted)


## The energy bar blinks: an action needed more energy than the hero has.
func flash_energy() -> void:
	_energy.flash()


## Red edges for a moment: the hero was hit.
func hurt(strength := 1.0) -> void:
	_hurt = maxf(_hurt, 0.35 * strength)
	_portrait.flash()


## The end-of-chapter card: the same banner, held longer so it can be read.
func chapter(title: String, subtitle: String) -> void:
	_banner_level.text = title
	_banner_detail.text = subtitle
	_show_banner(5.0)


## The big level-up announcement, naming any skills it unlocked.
func level_up(level: int, unlocked: Array) -> void:
	_banner_level.text = "Level %d" % level
	var names: Array[String] = []
	for skill_id: String in unlocked:
		names.append(str(content.skills[skill_id]["name"]))
	var lines: Array[String] = []
	if names:
		lines.append("New skill: " + ", ".join(names))
	for route: Dictionary in ComboRules.routes(content, profile.hero):
		if int(route["unlock_level"]) == level:
			lines.append("New combo: %s (see Skills, V)" % route["name"])
	_banner_detail.text = "\n".join(lines) if lines else "Max HP and damage increased"
	_show_banner(3.2 if lines.size() > 1 else 2.6)


func _show_banner(seconds: float) -> void:
	_banner.visible = true
	_banner.scale = Vector2(1.4, 1.4)
	_banner.modulate.a = 1.0
	_banner.pivot_offset = _banner.size / 2.0
	_banner_left = seconds
	var tween := create_tween()
	tween.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func toast(text: String) -> void:
	_toast_text.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS


func _process(delta: float) -> void:
	if _go_left > 0.0:
		_go_left -= delta
		_go.visible = _go_left > 0.0 and fmod(_go_left, 0.6) > 0.2
	if _combo_left > 0.0:
		_combo_left -= delta
		_combo.modulate.a = clampf(_combo_left / 0.4, 0.0, 1.0)
		_combo.visible = _combo_left > 0.0
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
	if _auto_spin.has_meta("on") and _auto_spin.get_meta("on"):
		_auto_spin.rotation_degrees = fmod(_auto_spin.rotation_degrees + AUTO_SPIN * delta, 360.0)
	_fps.visible = GameSession.settings.get("show_fps", false)
	if _fps.visible:
		_fps.text = "%d fps" % Engine.get_frames_per_second()
	if zone == null:
		return
	var hero := zone.hero
	_portrait.set_art(content, content.hero_art(profile))
	_portrait.set_state(profile.level, float(hero.hp) / maxi(1, hero.max_hp))
	_hp.set_values(hero.hp, hero.max_hp)
	_energy.set_values(hero.energy, CombatRules.MAX_ENERGY)
	_gauge.set_values(hero.gauge, UltimateRules.FULL)
	_chain.visible = hero.hit_chain >= CHAIN_SHOWN
	if _chain.visible:
		_chain.text = "%d HITS" % hero.hit_chain
	_xp.set_values(profile.xp, profile.xp_to_next(content))
	_money.text = str(profile.money)
	_weapon.show_weapon(content, hero.weapon, hero.weapon_uses)
	_update_quest()
	if _hotbar:
		_hotbar.refresh(zone, profile)
	var boss := zone.fighter(zone.boss_id) if zone.boss_id else null
	_boss.visible = boss != null and not boss.is_ko()
	if _boss.visible:
		var level := zone.enemy_level(boss.id)
		var mini := MapRules.kind_of(content, zone.area_id) == MapRules.MINI_BOSS
		_boss_icon.texture = UiKit.icon(content, "map_mini_boss" if mini else "map_boss")
		_boss_name.text = (
			"%s%s  Lv %d"
			% [
				"MINI-BOSS " if mini else "",
				str(content.enemy(boss.kind).get("name", "")).to_upper(),
				level
			]
		)
		var threat := LevelRules.threat(level, profile.level)
		_boss_name.add_theme_color_override("font_color", UiTheme.THREAT[threat])
		_boss_bar.set_values(boss.hp, boss.max_hp)


func _build_hero_card(root: Control) -> void:
	var card := PanelContainer.new()
	card.name = "HeroCard"
	card.position = Vector2(6, 6)
	_hero_card = card
	card.add_theme_stylebox_override("panel", _compact_panel())
	root.add_child(card)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	card.add_child(line)
	_portrait = HeroPortrait.new()
	_portrait.name = "Portrait"
	line.add_child(_portrait)
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 2)
	line.add_child(bars)
	bars.alignment = BoxContainer.ALIGNMENT_CENTER
	var names := HBoxContainer.new()
	names.add_theme_constant_override("separation", 5)
	bars.add_child(names)
	_name = UiKit.overlay_label("", UiTheme.SIZE_SMALL, UiTheme.TEXT)
	names.add_child(_name)
	_title = UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	_title.size_flags_vertical = Control.SIZE_SHRINK_END
	names.add_child(_title)
	_hp = _bar(UiTheme.HP, Vector2(BAR_WIDTH, 9), true)
	bars.add_child(_hp)
	_energy = _bar(UiTheme.EP, Vector2(BAR_WIDTH, 5), false)
	bars.add_child(_energy)
	_xp = _bar(UiTheme.XP, Vector2(BAR_WIDTH, 3), false)
	bars.add_child(_xp)
	# The ultimate gauge: fills as the hero fights (UltimateRules).
	_gauge = _bar(UiTheme.GOLD, Vector2(BAR_WIDTH, 3), false)
	_gauge.name = "Gauge"
	bars.add_child(_gauge)
	_weapon = WeaponBadge.new()
	_weapon.name = "Weapon"
	_weapon.position = Vector2(6, 62)
	root.add_child(_weapon)


func _build_top_right(root: Control) -> void:
	var column := VBoxContainer.new()
	column.name = "TopRight"
	_top_right = column
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 3)
	column.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	column.offset_left = -162
	column.offset_right = -6
	column.offset_top = 6
	root.add_child(column)
	var money := HBoxContainer.new()
	money.name = "Money"
	money.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(money)
	_money = UiKit.overlay_label("0", UiTheme.SIZE_H2, UiTheme.GOLD)
	money.add_child(_money)
	_mini = MiniMap.new()
	_mini.name = "MiniMap"
	_mini.size_flags_horizontal = Control.SIZE_FILL
	_mini.pressed.connect(menu_pressed.emit.bind("map"))
	column.add_child(_mini)
	_world_boss = UiKit.overlay_label("", UiTheme.SIZE_SMALL, UiTheme.GOLD)
	_world_boss.name = "WorldBoss"
	_world_boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_world_boss.visible = false
	column.add_child(_world_boss)
	_quest_card = PanelContainer.new()
	_quest_card.add_theme_stylebox_override("panel", _compact_panel())
	column.add_child(_quest_card)
	var quest := VBoxContainer.new()
	quest.add_theme_constant_override("separation", 0)
	_quest_card.add_child(quest)
	_quest_heading = UiKit.label("QUEST", UiTheme.SIZE_CAPTION, UiTheme.ACCENT)
	quest.add_child(_quest_heading)
	_quest_name = UiKit.label("", UiTheme.SIZE_SMALL, UiTheme.TEXT, 140)
	quest.add_child(_quest_name)
	_quest_progress = UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, 140)
	quest.add_child(_quest_progress)
	_quest_action = UiKit.label("", UiTheme.SIZE_SMALL, UiTheme.GOLD)
	_quest_action.name = "QuestAction"
	quest.add_child(_quest_action)
	_quest_card.name = "QuestCard"
	_quest_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_quest_card.gui_input.connect(
		func(event: InputEvent) -> void:
			var touch := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
			var click := event is InputEventMouseButton and (event as InputEventMouseButton).pressed
			if (touch or click) and _quest_action.text != "":
				quest_pressed.emit()
	)
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
	# The map's boss skull before the name: the same mark means a boss on the
	# map, over its head and here.
	var title := HBoxContainer.new()
	title.name = "Title"
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", 4)
	_boss.add_child(title)
	_boss_icon = UiKit.icon_rect(GameSession.content, "map_boss")
	_boss_icon.name = "BossIcon"
	title.add_child(_boss_icon)
	_boss_name = UiKit.overlay_label("", UiTheme.SIZE_SMALL, Color("ffb0a0"))
	title.add_child(_boss_name)
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
	_hints = hints
	hints.add_theme_constant_override("separation", 8)
	hints.position = Vector2(8, 346)
	hints.add_child(UiKit.key_hint("Esc", "Menu"))
	hints.add_child(UiKit.key_hint("X", "Heavy"))
	hints.add_child(UiKit.key_hint("Space", "Dodge"))
	hints.add_child(UiKit.key_hint("Shift", "Guard"))
	hints.modulate.a = 0.8
	root.add_child(hints)
	# The rest go right of the hotbar, which sits between the two rows.
	var more := HBoxContainer.new()
	more.name = "HintsRight"
	_hints_right = more
	more.add_theme_constant_override("separation", 8)
	more.alignment = BoxContainer.ALIGNMENT_END
	more.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	more.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	more.grow_vertical = Control.GROW_DIRECTION_BEGIN
	more.offset_right = -8
	more.offset_bottom = -4
	more.add_child(UiKit.key_hint("E", "Grab / Throw / Talk"))
	more.modulate.a = 0.8
	root.add_child(more)


## The game's screens, one small icon button each, bottom right above the
## hints. The keys are in the tooltips, so the bar stays small.
func _build_menu_bar(root: Control) -> void:
	# A grid, so touch layouts can make it a row or a column (apply_layout).
	_menu_bar = GridContainer.new()
	_menu_bar.name = "MenuBar"
	_menu_bar.columns = MENU_BAR.size()
	_menu_bar.add_theme_constant_override("h_separation", 2)
	_menu_bar.add_theme_constant_override("v_separation", 2)
	_dock_menu_bar()
	root.add_child(_menu_bar)
	for entry: Array in MENU_BAR:
		var button := Button.new()
		button.name = "Menu_" + str(entry[0])
		button.icon = UiKit.icon(content, entry[1])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = entry[2]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = MENU_BUTTON
		_style_round(button, false)
		button.pressed.connect(menu_pressed.emit.bind(entry[0]))
		_menu_bar.add_child(button)


## The AUTO switch: a round button whose arrows turn and glow while auto
## battle runs and fade where it cannot start (pressing it then says why).
func _build_auto(root: Control) -> void:
	var column := VBoxContainer.new()
	column.name = "Auto"
	_auto_column = column
	column.position = Vector2(8, 88)
	column.add_theme_constant_override("separation", 0)
	root.add_child(column)
	_auto_button = Button.new()
	_auto_button.name = "AutoButton"
	_auto_button.focus_mode = Control.FOCUS_NONE
	_auto_button.custom_minimum_size = Vector2(24, 24)
	_auto_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_auto_button.pressed.connect(auto_pressed.emit)
	column.add_child(_auto_button)
	_auto_spin = TextureRect.new()
	_auto_spin.name = "Spin"
	_auto_spin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_auto_spin.size = Vector2(16, 16)
	_auto_spin.position = Vector2(4, 4)
	_auto_spin.pivot_offset = Vector2(8, 8)
	_auto_button.add_child(_auto_spin)
	_auto_label = UiKit.overlay_label("AUTO", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	_auto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_auto_label)
	_style_auto(false)


## Shows auto battle's state: lit and turning while on, faded where it is not
## allowed. The run's tally sits in the tooltip, out of the way.
func show_auto(auto: AutoBattle, allowed: bool) -> void:
	_style_auto(auto.on)
	_auto_button.modulate.a = 1.0 if allowed else 0.45
	_auto_label.modulate.a = _auto_button.modulate.a
	_auto_button.tooltip_text = (
		"Auto battle (T)\n" + auto.summary() if auto.on else "Auto battle (T)"
	)


## The world boss attempt's clock and what is left of the pool ("" hides it).
func show_world_boss(text: String) -> void:
	_world_boss.visible = text != ""
	_world_boss.text = text


func _style_auto(on: bool) -> void:
	if _auto_spin.has_meta("on") and bool(_auto_spin.get_meta("on")) == on:
		return
	_auto_spin.set_meta("on", on)
	_style_round(_auto_button, on)
	_auto_spin.rotation_degrees = 0.0
	_auto_spin.modulate = UiTheme.BG if on else Color.WHITE
	_auto_label.add_theme_color_override("font_color", UiTheme.ACCENT if on else UiTheme.TEXT_DIM)


## Round dark buttons with an accent rim; `lit` fills them with the accent.
func _style_round(button: Button, lit: bool) -> void:
	var states := {"normal": 0.0, "hover": 0.18, "pressed": -0.1}
	for state: String in states:
		var style := StyleBoxFlat.new()
		var base := UiTheme.ACCENT if lit else Color(0.06, 0.06, 0.1, 0.78)
		style.bg_color = (
			base.lightened(states[state]) if states[state] > 0 else base.darkened(-states[state])
		)
		style.border_color = UiTheme.ACCENT if lit or state == "hover" else UiTheme.TEXT_FAINT
		style.set_border_width_all(1)
		style.set_corner_radius_all(int(button.custom_minimum_size.x / 2))
		style.set_content_margin_all(2)
		if lit:
			style.shadow_color = Color(UiTheme.ACCENT, 0.5)
			style.shadow_size = 3
		button.add_theme_stylebox_override(state, style)


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


func _build_go(root: Control) -> void:
	_go = UiKit.overlay_label("GO >>", UiTheme.SIZE_LOGO - 8, UiTheme.ACCENT)
	_go.name = "Go"
	_go.add_theme_constant_override("outline_size", 6)
	_go.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_go.offset_left = -110
	_go.offset_right = -14
	_go.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_go.visible = false
	root.add_child(_go)


## Blinks "GO >>" for a few seconds (or until `false`), as fights clear.
func show_go(on := true) -> void:
	_go_left = GO_SECONDS if on else 0.0
	_go.visible = on


func _build_chain(root: Control) -> void:
	_chain = UiKit.overlay_label("", UiTheme.SIZE_H1, UiTheme.TEXT)
	_chain.name = "HitChain"
	_chain.add_theme_constant_override("outline_size", 5)
	_chain.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_chain.offset_left = -150
	_chain.offset_right = -14
	_chain.offset_top = 24
	_chain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chain.visible = false
	root.add_child(_chain)
	_combo = UiKit.overlay_label("", UiTheme.SIZE_H1, UiTheme.GOLD)
	_combo.name = "ComboName"
	_combo.add_theme_constant_override("outline_size", 6)
	_combo.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_combo.offset_left = -220
	_combo.offset_right = -14
	_combo.offset_top = 46
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo.visible = false
	root.add_child(_combo)


## Names a combo route the hero just completed, for a moment.
func show_combo(route_name: String) -> void:
	_combo.text = "%s!" % route_name.to_upper()
	_combo_left = COMBO_SECONDS
	_combo.visible = true


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
	# The tutorial takes the quest card's place until it is done: one thing
	# to look at, in the same spot as every goal after it.
	var step := TutorialRules.current(profile, content)
	# Its last step is the first quest: the card shows it, to accept with F.
	if step and step.get("id") != "talk":
		_quest_card.visible = true
		_quest_heading.text = "TUTORIAL  %d / %d" % [profile.tutorial + 1, content.tutorial.size()]
		_quest_name.text = str(step["text"])
		var count := int(step.get("count", 1))
		_quest_progress.text = "%d / %d" % [profile.tutorial_progress, count] if count > 1 else ""
		return
	# The story's quest, as in mobile games: a new one to accept, the one under
	# way with its goal and progress, a finished one whose reward to claim;
	# all from here, with no walk back to the giver (QuestFlow).
	_quest_action.text = ""
	_quest_card.visible = false
	var quest_id := QuestFlow.current(profile, content)
	if quest_id == "":
		return
	var quest: Dictionary = content.quests[quest_id]
	var state := QuestRules.status(profile, quest_id, content)
	_quest_card.visible = true
	_quest_name.text = str(quest["name"])
	match state:
		"available":
			_quest_heading.text = "NEW QUEST"
			_quest_heading.add_theme_color_override("font_color", UiTheme.ACCENT)
			_quest_progress.text = str(quest.get("description", ""))
			_quest_action.text = "Accept  (F)"
		"complete":
			_quest_heading.text = "QUEST COMPLETE!"
			_quest_heading.add_theme_color_override("font_color", UiTheme.GOLD)
			_quest_progress.text = "Well done."
			_quest_action.text = "Claim reward  (F)"
		_:
			_quest_heading.text = "QUEST"
			_quest_heading.add_theme_color_override("font_color", UiTheme.ACCENT)
			var objective: Dictionary = quest["objective"]
			var foe := str(content.enemy(str(objective["enemy"])).get("name", "foe"))
			var place := str(content.area(str(objective.get("area", ""))).get("name", ""))
			var count := int(objective["count"])
			var done := int(profile.quests[quest_id]["progress"])
			_quest_progress.text = (
				"Defeat %s  %d/%d" % [foe, done, count] + ("\n" + place if place else "")
			)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_action") and _quest_action.text != "":
		get_viewport().set_input_as_handled()
		quest_pressed.emit()


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


## The menu bar's own place: bottom right, above the hints.
func _dock_menu_bar() -> void:
	_menu_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_menu_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_menu_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_menu_bar.offset_right = -6
	_menu_bar.offset_bottom = -20
	_menu_bar.offset_left = 0
	_menu_bar.offset_top = 0


func _build_bands(root: Control) -> void:
	_bands = Control.new()
	_bands.name = "Bands"
	_bands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bands.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bands.visible = false
	root.add_child(_bands)
	for band in ["HudBand", "Deck"]:
		var fill := ColorRect.new()
		fill.name = band
		fill.color = UiTheme.BG
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bands.add_child(fill)
		var edge := ColorRect.new()
		edge.name = "Edge"
		edge.color = UiTheme.BORDER
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.add_child(edge)


## Puts everything where `layout` says: the portrait bands, the key hints
## (keyboard only), the touch controls (touch only), and the hotbar, menu
## buttons and AUTO switch at touch size where touch layouts place them.
func apply_layout(layout: ScreenLayout) -> void:
	if layout == null or _hero_card == null:
		return
	var inset := layout.insets
	_hero_card.position = Vector2(6 + inset.x, 6 + inset.y)
	_weapon.position = Vector2(6 + inset.x, 62 + inset.y)
	_top_right.offset_top = 6 + inset.y
	_top_right.offset_right = -6 - inset.z
	_top_right.offset_left = -162 - inset.z
	var portrait := layout.mode == ScreenLayout.PORTRAIT
	_bands.visible = portrait
	if portrait:
		var band: ColorRect = _bands.get_node("HudBand")
		band.position = layout.hud.position
		band.size = layout.hud.size
		var edge: ColorRect = band.get_node("Edge")
		edge.position = Vector2(0, layout.hud.size.y - 1)
		edge.size = Vector2(layout.hud.size.x, 1)
		var deck: ColorRect = _bands.get_node("Deck")
		deck.position = layout.deck.position
		deck.size = layout.deck.size
		var deck_edge: ColorRect = deck.get_node("Edge")
		deck_edge.position = Vector2.ZERO
		deck_edge.size = Vector2(layout.deck.size.x, 1)
	var keys := layout.device == "keyboard"
	_hints.visible = keys
	_hints_right.visible = keys
	_hints.position = Vector2(8 + inset.x, layout.size.y - 14 - inset.w)
	_boss.position = layout.boss_at
	_touch.visible = layout.controls
	if layout.controls:
		TouchControls.arrange(_touch, layout)
	_place_auto(layout)
	_place_menu_bar(layout)
	_place_hotbar(layout)


func _place_auto(layout: ScreenLayout) -> void:
	var cell := layout.auto_cell
	var side := 24.0 if cell.size == Vector2.ZERO else cell.size.x
	_auto_column.position = Vector2(8, 88) if cell.size == Vector2.ZERO else cell.position
	_auto_button.custom_minimum_size = Vector2(side, side)
	_auto_spin.position = Vector2(side - 16.0, side - 16.0) / 2.0
	# In portrait the switch sits in a grid of buttons: no caption under it.
	_auto_label.visible = layout.mode != ScreenLayout.PORTRAIT


func _place_menu_bar(layout: ScreenLayout) -> void:
	if _menu_bar == null:
		return
	var custom := layout.menu.size != Vector2.ZERO
	for button: Button in _menu_bar.get_children():
		var screen := str(button.name).trim_prefix("Menu_")
		button.visible = not custom or screen in layout.menu_items
		var side := layout.touch_size if custom else MENU_BUTTON.x
		button.custom_minimum_size = Vector2(side, side)
	if not custom:
		_menu_bar.columns = MENU_BAR.size()
		_menu_bar.add_theme_constant_override("h_separation", 2)
		_menu_bar.add_theme_constant_override("v_separation", 2)
		_dock_menu_bar()
		return
	_menu_bar.columns = layout.menu_columns
	_menu_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Grow right and down from its corner (docked, it grows left and up),
	# shrink to its buttons, then place it.
	_menu_bar.grow_horizontal = Control.GROW_DIRECTION_END
	_menu_bar.grow_vertical = Control.GROW_DIRECTION_END
	_menu_bar.size = Vector2.ZERO
	_menu_bar.position = layout.menu.position
	if layout.touch:
		var gap := int(ScreenLayout.GAP)
		_menu_bar.add_theme_constant_override("h_separation", gap)
		_menu_bar.add_theme_constant_override("v_separation", gap)


func _place_hotbar(layout: ScreenLayout) -> void:
	if _hotbar == null:
		return
	if layout.hotbar.size == Vector2.ZERO:
		_hotbar.scale = Vector2.ONE
		_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_hotbar.offset_bottom = -4
		_hotbar.offset_top = -4
		_hotbar.offset_left = 0
		_hotbar.offset_right = 0
		return
	_hotbar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hotbar.grow_horizontal = Control.GROW_DIRECTION_END
	_hotbar.grow_vertical = Control.GROW_DIRECTION_END
	_hotbar.scale = Vector2.ONE * layout.hotbar_scale()
	_hotbar.position = layout.hotbar.position
