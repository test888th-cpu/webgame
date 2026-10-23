class_name UiTheme
extends RefCounted
## The game's single visual language for interface: colours, type scale and
## the styles of every control type we use, built once and set on the root
## window (GameSession) so every screen inherits it. Screens never hard-code
## a colour or size that exists here; they use these constants or theme types.
##
## Layout is designed on the 640x360 base viewport (stretched with
## "canvas_items", so text stays sharp at any window size).

# Palette: dark slate panels, warm orange accent (street lamps), teal second
# accent (the Murk's glow), stat colours that read on dark backgrounds.
const BG := Color("0d0e15")
const PANEL := Color("161824f2")
const PANEL_LIGHT := Color("20233a")
const BORDER := Color("3a3f5c")
const ACCENT := Color("f2a54a")
const ACCENT_DARK := Color("b9712a")
const TEAL := Color("5fc8d6")
const TEXT := Color("ece8df")
const TEXT_DIM := Color("9a9bb0")
const TEXT_FAINT := Color("62647a")
const GOOD := Color("7bd389")
const DANGER := Color("e0524a")
const HP := Color("e0524a")
const EP := Color("4aa3e0")
const XP := Color("a77be0")
const GOLD := Color("f2c14a")

# Type scale (base-viewport pixels).
const SIZE_LOGO := 34
const SIZE_H1 := 16
const SIZE_H2 := 11
const SIZE_BODY := 9
const SIZE_SMALL := 8
const SIZE_CAPTION := 7

# Spacing grid.
const GAP := 4
const PAD := 8
const SCREEN_MARGIN := 10


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = SIZE_BODY

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	theme.set_constant("outline_size", "Label", 0)

	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "Panel", panel_style())

	theme.set_stylebox("normal", "Button", _box(PANEL_LIGHT, BORDER, 1, Vector4(8, 3, 8, 3)))
	theme.set_stylebox(
		"hover", "Button", _box(Color("2c3150"), ACCENT_DARK, 1, Vector4(8, 3, 8, 3))
	)
	theme.set_stylebox("pressed", "Button", _box(ACCENT_DARK, ACCENT, 1, Vector4(8, 3, 8, 3)))
	theme.set_stylebox(
		"disabled", "Button", _box(Color("191b2a"), Color("2a2d42"), 1, Vector4(8, 3, 8, 3))
	)
	var focus := _box(Color(0, 0, 0, 0), ACCENT, 2, Vector4.ZERO)
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", TEXT_FAINT)
	theme.set_font_size("font_size", "Button", SIZE_BODY)

	var tab_selected := _box(PANEL, ACCENT, 0, Vector4(10, 3, 10, 3))
	tab_selected.border_width_top = 2
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox(
		"tab_unselected", "TabContainer", _box(Color("10121c"), BORDER, 0, Vector4(10, 3, 10, 3))
	)
	theme.set_stylebox(
		"tab_hovered", "TabContainer", _box(Color("1d2032"), BORDER, 0, Vector4(10, 3, 10, 3))
	)
	theme.set_stylebox("tab_focus", "TabContainer", focus)
	theme.set_stylebox("panel", "TabContainer", _box(PANEL, BORDER, 1, Vector4(PAD, PAD, PAD, PAD)))
	theme.set_color("font_selected_color", "TabContainer", ACCENT)
	theme.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	theme.set_color("font_hovered_color", "TabContainer", TEXT)
	theme.set_font_size("font_size", "TabContainer", SIZE_SMALL)

	theme.set_stylebox("panel", "ItemList", _box(Color("10121c"), BORDER, 1, Vector4(3, 3, 3, 3)))
	theme.set_stylebox("focus", "ItemList", focus)
	theme.set_stylebox(
		"selected",
		"ItemList",
		_box(Color(0.95, 0.65, 0.29, 0.25), Color(0, 0, 0, 0), 0, Vector4.ZERO)
	)
	theme.set_stylebox(
		"selected_focus", "ItemList", _box(Color(0.95, 0.65, 0.29, 0.35), ACCENT, 1, Vector4.ZERO)
	)
	theme.set_stylebox("cursor", "ItemList", StyleBoxEmpty.new())
	theme.set_stylebox("cursor_unfocused", "ItemList", StyleBoxEmpty.new())
	theme.set_color("font_color", "ItemList", TEXT)
	theme.set_color("font_selected_color", "ItemList", Color.WHITE)
	theme.set_font_size("font_size", "ItemList", SIZE_BODY)
	theme.set_constant("v_separation", "ItemList", 3)
	theme.set_constant("icon_margin", "ItemList", 4)

	theme.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "CheckButton", focus)
	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_font_size("font_size", "CheckButton", SIZE_BODY)

	var separator := StyleBoxLine.new()
	separator.color = BORDER
	separator.thickness = 1
	theme.set_stylebox("separator", "HSeparator", separator)
	theme.set_constant("separation", "HSeparator", 6)
	theme.set_stylebox(
		"scroll", "VScrollBar", _box(Color("10121c"), Color(0, 0, 0, 0), 0, Vector4(2, 0, 2, 0))
	)
	theme.set_stylebox(
		"grabber", "VScrollBar", _box(BORDER, Color(0, 0, 0, 0), 0, Vector4(2, 0, 2, 0))
	)
	return theme


## Styles for the large title-screen buttons: no frame at rest, a warm wash
## and an accent bar on the left when focused or hovered. Applied as
## overrides (type variations do not survive Theme.merge_with).
static func menu_button_styles() -> Dictionary:
	var rest := _box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, Vector4(12, 4, 12, 4))
	var lit := _box(Color(0.95, 0.65, 0.29, 0.22), ACCENT, 0, Vector4(12, 4, 12, 4))
	lit.border_width_left = 3
	return {"normal": rest, "disabled": rest, "hover": lit, "pressed": lit, "focus": lit}


static func panel_style() -> StyleBoxFlat:
	var style := _box(PANEL, BORDER, 1, Vector4(PAD, PAD, PAD, PAD))
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


## A flat box with a border and content margins (left, top, right, bottom).
static func _box(bg: Color, border: Color, width: int, margin: Vector4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.content_margin_left = margin.x
	style.content_margin_top = margin.y
	style.content_margin_right = margin.z
	style.content_margin_bottom = margin.w
	return style
