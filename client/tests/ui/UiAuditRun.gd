extends SceneTree
## The UI audit: every game screen at three window sizes and in three text
## variants, checked by the UiAudit detectors.
##
##   godot --headless --path client --script res://tests/ui/UiAuditRun.gd -- \
##       --out=../build/ui-audit [--update-baseline]
##
## Sizes, landscape only: 1280x720 (desktop, mouse and keyboard), 640x360,
## 844x390 and 960x440 (phones held sideways: 16:9, 19.5:9, 20:9, touch).
## Variants: the game as it is, every text 150% larger, every string 40%
## longer.
##
## Writes report.json and report.md to --out. Known problems are listed in
## tests/ui/baseline.json; the run fails when a problem appears that is not
## in the baseline, and also when one in the baseline has gone (so a fix is
## recorded by removing it, and the baseline never hides anything). It also
## fails on any engine or script error. The audit only reads the game: it
## changes no game code, data or save.

const SESSION := "res://tests/ui/UiAuditSession.gd"


## Engine and script errors logged while the audit runs: any one fails it.
class Errors:
	extends Logger

	var seen: PackedStringArray = []

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if error_type != Logger.ERROR_TYPE_WARNING:
			seen.append(
				"%s (%s:%d in %s)" % [rationale if rationale else code, file, line, function]
			)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var errors := Errors.new()
	OS.add_logger(errors)
	var out_dir := "res://../build/ui-audit"
	var update := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		update = update or arg == "--update-baseline"
	var session: RefCounted = load(SESSION).new()
	var code: int = await session.run(self, out_dir, update)
	if not errors.seen.is_empty():
		for error in errors.seen:
			print("ERROR engine error during the audit: " + error)
		code = 1
	quit(code)
