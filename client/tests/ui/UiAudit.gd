class_name UiAudit
extends RefCounted
## Detectors for interface problems, run on a built screen (a tree of
## Controls, TouchScreenButtons and the world behind them) at one window size.
## Each returns findings: {"check", "node", "detail"}. They only read the tree
## (the two text transforms change what they are given, for the 150% text and
## +40% string runs), so they can audit the real game without changing it.
##
## Sizes are in CSS pixels where it matters for people: a control 20 base
## pixels wide is 40 CSS px in a 1280x720 window but 20 in a 640x360 one.
## Used by tests/ui/UiAuditRun.gd (the full audit and its baseline) and
## tests/unit/test_ui_audit.gd (each detector on fixtures with known faults).

## The smallest comfortable touch target (WCAG 2.5.5, Apple and Android
## guidance agree on about 44 CSS px).
const MIN_TOUCH_CSS := 44.0
## The smallest text a player should have to read on a phone, in CSS px.
const MIN_TEXT_CSS := 10.0
## A world that fills less of the window's height than this is a thin band.
const MIN_WORLD_SHARE := 0.6
## Touch controls are expected in the bottom part of the window (thumb reach).
const THUMB_ZONE := 0.45
## Strings are made this much longer for the localization run.
const PSEUDO_GROWTH := 0.4
const PSEUDO_FILL := "ŵàŷłéñĝţĥ ẋŧŕâ "

## Rough on-screen size of a person (feet at the bottom centre), in world px.
const PERSON_RECT := Rect2(-12, -48, 24, 48)


## A path that names a node the same way on every run: its name, or (for an
## auto-named node such as @Label@123) its class and place among its siblings.
static func stable_path(root: Node, node: Node) -> String:
	var parts: Array[String] = []
	var at := node
	while at != null and at != root:
		var name := str(at.name)
		if name.begins_with("@"):
			name = "%s[%d]" % [at.get_class(), at.get_index()]
		parts.push_front(name)
		at = at.get_parent()
	return "/".join(parts)


## The screen rect of a TouchScreenButton (its shape, placed and scaled).
static func touch_rect(button: TouchScreenButton) -> Rect2:
	var shape := button.shape as RectangleShape2D
	var size := shape.size if shape else Vector2.ZERO
	var xform := button.get_global_transform_with_canvas()
	var origin := xform.origin
	if button.shape_centered:
		origin -= size * xform.get_scale() / 2.0
	return Rect2(origin, size * xform.get_scale())


static func _finding(check: String, root: Node, node: Node, detail: String) -> Dictionary:
	return {"check": check, "node": stable_path(root, node) if node else "", "detail": detail}


static func _shown(control: Control) -> bool:
	return control.is_visible_in_tree() and control.modulate.a > 0.01


static func _inside_scroll(control: Control, root: Node) -> bool:
	var up := control.get_parent()
	while up != null and up != root.get_parent():
		if up is ScrollContainer:
			return true
		up = up.get_parent()
	return false


## Visible panels, buttons and labels that reach outside `visible` (the
## window's visible rect). Rows a scroll box clips are skipped, the scroll box
## itself is checked; a node inside one already reported is not repeated.
static func offscreen(root: Node, visible: Rect2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var reported: Array[Node] = []
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if not _shown(control) or _inside_scroll(control, root):
			continue
		if not (
			control is PanelContainer
			or control is BaseButton
			or control is Label
			or control is ScrollContainer
		):
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0 or visible.grow(1).encloses(rect):
			continue
		var nested := false
		for parent in reported:
			nested = nested or parent.is_ancestor_of(control)
		if nested:
			continue
		reported.append(control)
		out.append(_finding("offscreen", root, control, "%s at %s" % [control.get_class(), rect]))
	return out


## Touch controls smaller than MIN_TOUCH_CSS: TouchScreenButtons, and the
## buttons a touch player has to tap (`taps`), at `css_scale` CSS px per
## canvas px.
static func touch_targets(
	root: Node, touch: Array[TouchScreenButton], taps: Array[Control], css_scale: float
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for button in touch:
		if not button.is_visible_in_tree():
			continue
		var size := touch_rect(button).size * css_scale
		if minf(size.x, size.y) < MIN_TOUCH_CSS:
			out.append(_finding("touch_target_small", root, button, "%.0f CSS px" % size.x))
	for control in taps:
		if not _shown(control):
			continue
		var size := control.get_global_rect().size * css_scale
		if minf(size.x, size.y) < MIN_TOUCH_CSS:
			out.append(
				_finding("touch_target_small", root, control, "%.0fx%.0f CSS px" % [size.x, size.y])
			)
	return out


## Touch controls that cover something else: another control the player taps,
## a person in the street, or the lane the hero fights in (`lane`, screen px).
static func touch_overlaps(
	root: Node,
	touch: Array[TouchScreenButton],
	taps: Array[Control],
	people: Array[Rect2],
	lane: Rect2
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for button in touch:
		if not button.is_visible_in_tree():
			continue
		var rect := touch_rect(button)
		for control in taps:
			if _shown(control) and rect.intersects(control.get_global_rect()):
				var other := stable_path(root, control)
				out.append(_finding("touch_covers_control", root, button, other))
		for other_button in touch:
			if (
				other_button != button
				and other_button.is_visible_in_tree()
				and button.get_index() < other_button.get_index()
				and rect.intersects(touch_rect(other_button))
			):
				out.append(_finding("touch_covers_control", root, button, str(other_button.name)))
		var covered := 0
		for person in people:
			covered += 1 if rect.intersects(person) else 0
		if covered > 0:
			out.append(_finding("touch_covers_npc", root, button, "%d people" % covered))
		if lane.size.y > 0.0 and rect.intersects(lane):
			out.append(_finding("touch_covers_lane", root, button, "over the fighting lane"))
	return out


## Touch controls floating away from the bottom edge (out of thumb reach):
## their bottom is above the window's lower THUMB_ZONE.
static func touch_floating(
	root: Node, touch: Array[TouchScreenButton], visible: Rect2
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var line := visible.end.y - visible.size.y * THUMB_ZONE
	for button in touch:
		if button.is_visible_in_tree() and touch_rect(button).end.y < line:
			var gap := visible.end.y - touch_rect(button).end.y
			out.append(
				_finding("touch_floating", root, button, "%.0f px above the bottom edge" % gap)
			)
	return out


## Keyboard hints (`hints`) shown to a touch player.
static func hints_on_touch(root: Node, hints: Array[Control]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for hint in hints:
		if _shown(hint):
			out.append(_finding("keyboard_hint_on_touch", root, hint, "visible on a touch device"))
	return out


## The game world (`world`, its screen rect) filling too little of the
## window's height: the 640x360 street letterboxed into a band.
static func world_band(world: Rect2, visible: Rect2) -> Array[Dictionary]:
	var share := world.size.y / maxf(1.0, visible.size.y)
	if share >= MIN_WORLD_SHARE:
		return []
	return [
		{
			"check": "world_band",
			"node": "",
			"detail": "the street fills %d%% of the height" % roundi(share * 100.0)
		}
	]


## Text smaller than MIN_TEXT_CSS: one finding per screen (with the count and
## the smallest size) so a screen of small text is one line, not fifty.
static func small_text(root: Node, css_scale: float) -> Array[Dictionary]:
	var count := 0
	var smallest := INF
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if not (control is Label or control is Button) or not _shown(control):
			continue
		if str(control.get("text")) == "":
			continue
		var size := float(control.get_theme_font_size("font_size")) * css_scale
		if size < MIN_TEXT_CSS:
			count += 1
			smallest = minf(smallest, size)
	if count == 0:
		return []
	return [
		{
			"check": "text_too_small",
			"node": "",
			"detail": "%d texts below %d CSS px" % [count, int(MIN_TEXT_CSS)],
			"smallest": smallest,
		}
	]


## Single-line labels whose text is cut off (clipped or ended with "…"), and
## labels that stick out of the panel around them.
static func text_overflow(root: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for node in root.find_children("*", "Label", true, false):
		var label: Label = node
		if not _shown(label) or label.text == "" or _inside_scroll(label, root):
			continue
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var font := label.get_theme_font("font")
			var size := label.get_theme_font_size("font_size")
			var wide := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			# Only a clipped or "…"-trimmed label can be narrower than its
			# text: otherwise its minimum width is the text's.
			if wide > label.size.x + 1.0:
				var cut := "%.0f of %.0f px" % [label.size.x, wide]
				out.append(_finding("text_truncated", root, label, cut))
				continue
		var panel := _panel_of(label, root)
		if panel and not panel.get_global_rect().grow(1).encloses(label.get_global_rect()):
			out.append(_finding("text_outside_panel", root, label, str(panel.name)))
	return out


static func _panel_of(control: Control, root: Node) -> Control:
	var up := control.get_parent()
	while up != null and up != root.get_parent():
		if up is PanelContainer:
			return up
		up = up.get_parent()
	return null


## Buttons only a mouse or finger can press (focus_mode NONE). Usually a
## shortcut with a keyboard path elsewhere (the window's ×, hotbar drag
## targets), so this is reported as information, not a fault.
static func mouse_only(root: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for node in root.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node
		if _shown(button) and not button.disabled and button.focus_mode == Control.FOCUS_NONE:
			out.append(_finding("mouse_only_button", root, button, button.get_class()))
	return out


## A screen with controls a keyboard or gamepad could use, but nothing of it
## focused once open: the player has to reach for the mouse to start.
static func focus_missing(root: Node, focused: Control) -> Array[Dictionary]:
	var focusable := 0
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if _shown(control) and control.focus_mode != Control.FOCUS_NONE:
			focusable += 1
	if focusable == 0 or (focused != null and root.is_ancestor_of(focused)):
		return []
	var owner := "nothing" if focused == null else str(focused.name)
	return [
		{
			"check": "no_keyboard_focus",
			"node": "",
			"detail": "%d focusable controls; focus is on %s" % [focusable, owner]
		}
	]


## Buttons whose centre is under another control that takes the click
## (drawn later, MOUSE_FILTER_STOP, not part of the button).
static func covered(root: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var all: Array[Control] = []
	for node in root.find_children("*", "Control", true, false):
		if _shown(node):
			all.append(node)
	for i in all.size():
		var button := all[i] as BaseButton
		if button == null or _inside_scroll(button, root):
			continue
		var centre := button.get_global_rect().get_center()
		for j in range(i + 1, all.size()):
			var top := all[j]
			if (
				top.mouse_filter == Control.MOUSE_FILTER_STOP
				and not button.is_ancestor_of(top)
				and not top.is_ancestor_of(button)
				and top.get_global_rect().has_point(centre)
			):
				out.append(_finding("control_covered", root, button, stable_path(root, top)))
				break
	return out


## Every label's and button's font size times `factor` (the 150% text run).
static func scale_text(root: Node, factor: float) -> void:
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if control is Label or control is Button or control is LineEdit:
			var size := control.get_theme_font_size("font_size")
			control.add_theme_font_size_override("font_size", roundi(size * factor))


## `text` made PSEUDO_GROWTH longer with accented filler, the way a longer
## translation would be (the localization run).
static func pseudo(text: String) -> String:
	if text.strip_edges() == "":
		return text
	var extra := ceili(text.length() * PSEUDO_GROWTH)
	var fill := ""
	while fill.length() < extra:
		fill += PSEUDO_FILL
	return text + fill.substr(0, extra)


## Every label's and button's text through pseudo().
static func pseudo_text(root: Node) -> void:
	for node in root.find_children("*", "Control", true, false):
		if node is Label or node is Button:
			node.set("text", pseudo(str(node.get("text"))))
