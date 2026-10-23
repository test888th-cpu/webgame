extends SceneTree
## Headless test entry point:
##   godot --headless --path client --script res://tests/TestRunner.gd
## Runs every tests/unit/test_*.gd, prints one line per test, and exits with a
## non-zero code if any test fails, any test logs an engine or script error, or
## no tests were found.

const UNIT_DIR := "res://tests/unit"


## Records errors (not warnings) the engine logs while a test runs. Godot keeps executing a
## function after most script errors, so without this a crashing test would
## still count as passed.
class ErrorCapture:
	extends Logger

	var errors: PackedStringArray = []
	var _mutex := Mutex.new()

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
		# Warnings (expected, handled situations) are printed, not failures.
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		errors.append("%s (%s:%d in %s)" % [rationale if rationale else code, file, line, function])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var taken := errors.duplicate()
		errors.clear()
		_mutex.unlock()
		return taken


func _initialize() -> void:
	# Scenes added to the tree only receive _ready once the main loop runs.
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var capture := ErrorCapture.new()
	OS.add_logger(capture)
	var passed := 0
	var failed := 0
	for path in _test_files():
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var case: TestCase = script.new()
			case.tree = self
			await case.call(name)
			var failures := case.failures
			for error in capture.take():
				failures.append("engine error: " + error)
			if failures.is_empty():
				passed += 1
				print("PASS %s::%s" % [path.get_file(), name])
			else:
				failed += 1
				for failure in failures:
					printerr("FAIL %s::%s: %s" % [path.get_file(), name, failure])
	OS.remove_logger(capture)
	print("tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file in DirAccess.get_files_at(UNIT_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(UNIT_DIR.path_join(file))
	files.sort()
	return files
