extends RefCounted
## The UI audit's work, loaded by tests/ui/UiAuditRun.gd once the engine is
## running (autoloads such as SaveStore and GameSession only exist then).
## Opens every game screen at three window sizes, each with the input it is
## used with there, and in three text variants, and runs the UiAudit
## detectors on each. See UiAuditRun.gd for how to run it.

const BASELINE := "res://tests/ui/baseline.json"
const TEST_SAVE := "user://ui_audit_save"
## [name, window size, the input used there].
const SIZES := [
	["1280x720", Vector2i(1280, 720), "mouse"],
	["640x360", Vector2i(640, 360), "touch"],
	["360x640", Vector2i(360, 640), "touch"],
	["390x844", Vector2i(390, 844), "touch"],
	["412x915", Vector2i(412, 915), "touch"],
]
const VARIANTS := ["base", "text150", "strings140"]
## Reported for information, not compared with the baseline: they describe a
## design choice (a mouse shortcut with a keyboard path elsewhere), not a fault.
const INFO_CHECKS := ["mouse_only_button"]
const GAME_SCREENS := [
	"hud",
	"pause",
	"character",
	"bag",
	"skills",
	"quests",
	"map",
	"settings",
	"item_card",
	"shop",
	"conversation",
	"travel",
	"knocked_out",
]
const SCENES := {
	"title": "res://scenes/title/Title.tscn",
	"create": "res://scenes/create/CharacterCreate.tscn",
}

var tree: SceneTree
var root: Window
var findings: Array[Dictionary] = []
var problems: Array[String] = []


## Runs the whole audit in `p_tree`; returns the exit code (see _report).
func run(p_tree: SceneTree, out_dir: String, update: bool) -> int:
	tree = p_tree
	root = tree.root
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	for size: Array in SIZES:
		root.size = size[1]
		await _settle()
		for variant: String in VARIANTS:
			for screen: String in SCENES:
				await _audit_scene(size, variant, screen)
			for screen: String in GAME_SCREENS:
				await _audit_game(size, variant, screen)
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
	return _report(out_dir, update)


func _settle() -> void:
	for i in 3:
		await tree.process_frame


## Title and hero creation: their own scenes.
func _audit_scene(size: Array, variant: String, screen: String) -> void:
	var scene: Node = load(SCENES[screen]).instantiate()
	root.add_child(scene)
	await _settle()
	await _check(scene, size, variant, screen, false)
	scene.free()


## One screen of a fresh game: the HUD in Depot Yard, or a menu over it.
func _audit_game(size: Array, variant: String, screen: String) -> void:
	SaveStore.delete_all()
	# The input in use decides the layout (touch controls, key hints), as it
	# does for a player.
	InputSetup.set_device("touch" if size[2] == "touch" else "keyboard")
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await _settle()
	var hud: CanvasLayer = game.get("_hud")
	var target: Node = hud.get_node("Root") if screen == "hud" else _open(game, screen)
	if target == null:
		problems.append("could not open screen %s" % screen)
		game.free()
		return
	await _settle()
	await _check(target, size, variant, screen, true, game)
	game.free()


func _open(game: Game, screen: String) -> Control:
	match screen:
		"pause":
			game.open_pause()
		"item_card":
			game.open_inventory()
			var keys: Array = game.profile.inventory.keys()
			if keys.is_empty():
				return null
			game.inspect_item(str(keys[0]), "")
		"shop", "conversation", "travel":
			var role: String = {"shop": "shop", "conversation": "quests", "travel": "travel"}[screen]
			var npc := _npc(game, role)
			if npc.is_empty():
				return null
			game.zone.hero.position = Vector2(float(npc["x"]) - 20.0, float(npc["y"]))
			game.try_interact()
		"knocked_out":
			game.open_game_over()
		_:
			game.open_screen(screen)
	return game.menu


static func _npc(game: Game, role: String) -> Dictionary:
	for npc: Dictionary in game.zone.area.get("npcs", []):
		if npc.get("role") == role:
			return npc
	return {}


func _check(
	target: Node, size: Array, variant: String, screen: String, in_game: bool, game: Game = null
) -> void:
	var where := "%s/%s/%s" % [size[0], variant, screen]
	if variant == "text150":
		UiAudit.scale_text(target, 1.5)
		await _settle()
	elif variant == "strings140":
		UiAudit.pseudo_text(target)
		await _settle()
	var visible := root.get_visible_rect()
	var css := float(root.size.x) / visible.size.x
	_add(where, UiAudit.offscreen(target, visible))
	_add(where, UiAudit.text_overflow(target))
	if variant != "base":
		return
	_add(where, UiAudit.small_text(target, css))
	if screen != "hud":
		_add(where, UiAudit.focus_missing(target, root.gui_get_focus_owner()))
		_add(where, UiAudit.mouse_only(target))
		if screen != "item_card":
			_add(where, UiAudit.covered(target))
	if not in_game or size[2] != "touch":
		return
	var hud: CanvasLayer = game.get("_hud")
	var touch: Array[TouchScreenButton] = []
	for node in (hud.get("_touch") as Control).find_children("*", "TouchScreenButton", true, false):
		touch.append(node)
	var taps: Array[Control] = []
	var tap_root: Node = hud.get_node("Root") if screen == "hud" else target
	for node in tap_root.find_children("*", "Control", true, false):
		if (
			(node is BaseButton or node is HotbarSlot)
			and not (hud.get("_touch") as Node).is_ancestor_of(node)
		):
			taps.append(node)
	if screen == "hud":
		_add(where, UiAudit.touch_targets(target, touch, taps, css))
		var xform := game.view.get_viewport().get_canvas_transform()
		var people: Array[Rect2] = []
		for npc: Dictionary in game.zone.area.get("npcs", []):
			people.append(
				(
					xform
					* Rect2(
						UiAudit.PERSON_RECT.position + Vector2(npc["x"], npc["y"]),
						UiAudit.PERSON_RECT.size
					)
				)
			)
		for placed: Dictionary in game.zone.area.get("placed", []):
			people.append(
				(
					xform
					* Rect2(
						UiAudit.PERSON_RECT.position + Vector2(placed["x"], placed["y"]),
						UiAudit.PERSON_RECT.size
					)
				)
			)
		var lane := xform * game.zone.bounds
		_add(where, UiAudit.touch_overlaps(target, touch, taps, people, lane))
		_add(where, UiAudit.touch_floating(target, touch, visible))
		var hints: Array[Control] = []
		for name in ["Hints", "HintsRight"]:
			var hint := target.get_node_or_null(name) as Control
			if hint:
				hints.append(hint)
		_add(where, UiAudit.hints_on_touch(target, hints))
		var top := (xform * Vector2(0.0, 0.0)).y
		var bottom := (xform * Vector2(0.0, ZoneView.VIEW_HEIGHT)).y
		_add(where, UiAudit.world_band(Rect2(0.0, top, visible.size.x, bottom - top), visible))
	else:
		# A menu's buttons, and the touch buttons still taking touches under it.
		var small := UiAudit.touch_targets(target, [] as Array[TouchScreenButton], taps, css)
		if not small.is_empty():
			_add(
				where,
				[{"check": "touch_target_small", "node": "", "detail": "%d buttons" % small.size()}]
			)
		_add(where, UiAudit.touch_overlaps(target, touch, taps, [] as Array[Rect2], Rect2()))


func _add(where: String, found: Array[Dictionary]) -> void:
	for finding in found:
		var entry := finding.duplicate()
		entry["where"] = where
		entry["key"] = "%s | %s | %s" % [finding["check"], where, finding["node"]]
		findings.append(entry)


## Writes the reports, compares with the baseline. 0 = matches, 1 = new or
## fixed problems (or a problem in the audit itself).
func _report(out_dir: String, update: bool) -> int:
	var keys: Array[String] = []
	for finding in findings:
		if str(finding["check"]) in INFO_CHECKS:
			continue
		if str(finding["key"]) not in keys:
			keys.append(str(finding["key"]))
	keys.sort()
	var baseline: Array = []
	if FileAccess.file_exists(BASELINE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
		if parsed is Dictionary:
			baseline = parsed.get("known", [])
	var added: Array[String] = []
	for key in keys:
		if key not in baseline:
			added.append(key)
	var fixed: Array[String] = []
	for key: String in baseline:
		if key not in keys:
			fixed.append(key)
	var dir := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dir)
	var report := {
		"sizes": SIZES.map(func(s: Array) -> String: return "%s (%s)" % [s[0], s[2]]),
		"variants": VARIANTS,
		"screens": SCENES.keys() + GAME_SCREENS,
		"counts": _counts(),
		"new": added,
		"fixed": fixed,
		"problems": problems,
		"findings": findings,
	}
	_write(dir.path_join("report.json"), JSON.stringify(report, "  ", false))
	_write(dir.path_join("report.md"), _markdown(added, fixed))
	if update:
		var saved := {
			"about":
			(
				"Known UI problems found by tests/ui/UiAuditRun.gd: check | size/variant/screen | node. "
				+ "Remove a line when its problem is fixed; never add one to hide a new problem "
				+ "without a decision recorded in docs/UI_TESTING.md."
			),
			"known": keys,
		}
		_write(ProjectSettings.globalize_path(BASELINE), JSON.stringify(saved, "  ", false) + "\n")
		print("ui audit: baseline written with %d known problems" % keys.size())
		return 0 if problems.is_empty() else 1
	print(
		(
			"ui audit: %d findings (%d known), %d new, %d fixed"
			% [keys.size(), baseline.size(), added.size(), fixed.size()]
		)
	)
	for key in added:
		print("NEW   " + key)
	for key in fixed:
		print("FIXED " + key + "  (remove it from tests/ui/baseline.json)")
	for problem in problems:
		print("ERROR " + problem)
	return 0 if added.is_empty() and fixed.is_empty() and problems.is_empty() else 1


func _counts() -> Dictionary:
	var counts := {}
	for finding in findings:
		var size := str(finding["where"]).get_slice("/", 0)
		var key := "%s @ %s" % [finding["check"], size]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


func _markdown(added: Array[String], fixed: Array[String]) -> String:
	var lines: Array[String] = ["# UI audit", ""]
	lines.append(
		"Sizes: 1280x720 mouse, 640x360 touch, 360x640 touch. Variants: base, text150, strings140."
	)
	lines.append("")
	lines.append("| Check @ size | Findings |")
	lines.append("|---|---|")
	var counts := _counts()
	var names: Array = counts.keys()
	names.sort()
	for name: String in names:
		lines.append("| %s | %d |" % [name, counts[name]])
	lines.append("")
	lines.append(
		(
			"New (not in the baseline): %d. Fixed (still in the baseline): %d."
			% [added.size(), fixed.size()]
		)
	)
	lines.append("")
	lines.append("| Check | Where | Node | Detail |")
	lines.append("|---|---|---|---|")
	for finding in findings:
		lines.append(
			(
				"| %s | %s | %s | %s |"
				% [
					finding["check"],
					finding["where"],
					finding["node"],
					str(finding["detail"]).replace("|", "/")
				]
			)
		)
	return "\n".join(lines) + "\n"


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		problems.append("cannot write %s" % path)
		return
	file.store_string(text)
