extends TestCase
## client/sim/ stays pure (CLAUDE.md "Boundaries"): the rules are shared with
## the future zone server and the headless tools, so no file there may reach
## the scene tree, input, rendering, host services, the wall clock or an
## unseeded random number generator. Comments are ignored. The few legitimate
## exceptions are listed by exact file in ALLOWED, so a new one is a reviewed
## decision, never an accident.

const SIM_DIR := "res://sim"
## Rule id -> regular expression a code line must not match.
const RULES := {
	"scene_type": "^\\s*extends\\s+(Node|Node2D|Node3D|Control|CanvasItem|CanvasLayer)\\b",
	"input_singleton": "(^|[^A-Za-z0-9_])Input\\.",
	"scene_tree": "(^|[^A-Za-z0-9_])(get_tree|get_node|get_viewport)\\s*\\(",
	"host_service":
	"(^|[^A-Za-z0-9_])(Engine|OS|Time|DisplayServer|RenderingServer|AudioServer|JavaScriptBridge)\\.",
	"scene_path": "res://scenes",
	"autoload":
	"(^|[^A-Za-z0-9_])(GameSession|SaveStore|Sfx|BuildInfo|InputSetup|UiKit|UiTheme)\\b",
	"global_random":
	"(^|[^A-Za-z0-9_.])(randf|randi|randf_range|randi_range|randfn|randomize)\\s*\\(",
	"file_io": "(^|[^A-Za-z0-9_])(FileAccess|DirAccess|ResourceLoader|HTTPRequest|HTTPClient)\\b",
}
## The verified exceptions: file name -> rule ids it may break. The data
## loaders read the content JSON; nothing else in sim/ touches files.
const ALLOWED := {
	"ContentDB.gd": ["file_io"],
	"MoveLibrary.gd": ["file_io"],
}


func test_every_sim_file_is_pure() -> void:
	var files := _sim_files()
	assert_true(files.size() > 20, "found the sim sources (%d)" % files.size())
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for problem in violations(path.get_file(), text):
			assert_true(false, "%s: %s" % [path.get_file(), problem])


func test_the_rules_fire_on_forbidden_code() -> void:
	var samples := {
		"scene_type": "extends Node2D",
		"input_singleton": '\tif Input.is_action_pressed("x"):',
		"scene_tree": "\tvar tree := get_tree()",
		"host_service": "\tvar now := Time.get_ticks_msec()",
		"scene_path": '\tvar s := load("res://scenes/game/Game.tscn")',
		"autoload": "\tGameSession.content = null",
		"global_random": "\tvar roll := randf()",
		"file_io": "\tvar f := FileAccess.open(path, FileAccess.READ)",
	}
	for rule: String in RULES:
		assert_true(samples.has(rule), "%s has a sample" % rule)
		var found := violations("Sample.gd", str(samples[rule]))
		assert_true(found.size() == 1 and found[0].begins_with(rule), "%s fires" % rule)
	var unseeded := violations("Sample.gd", "var rng := RandomNumberGenerator.new()")
	assert_eq(unseeded.size(), 1, "an RNG that is never seeded is caught")


func test_the_rules_spare_pure_code() -> void:
	var pure := (
		"\n"
		. join(
			[
				"extends RefCounted",
				"## Input.foo and get_tree() in a doc comment are fine",
				"var input := FighterInput.new()  # Input.is_action_pressed here too",
				"var rng := RandomNumberGenerator.new()",
				"func _init(seed: int) -> void:",
				"\trng.seed = seed",
				"\tvar roll := rng.randf()",
				'\tvar label := "# not a comment"',
			]
		)
	)
	assert_eq(violations("Pure.gd", pure), [], "seeded RNG, FighterInput and comments pass")
	var loader := "var text := FileAccess.get_file_as_string(path)"
	assert_eq(violations("ContentDB.gd", loader), [], "the data loader may read files")
	assert_eq(violations("Other.gd", loader).size(), 1, "nobody else may")


## Every rule a file breaks, as "rule: line N: code", allowances applied.
static func violations(file_name: String, text: String) -> Array[String]:
	var out: Array[String] = []
	var allowed: Array = ALLOWED.get(file_name, [])
	var lines := text.split("\n")
	for rule: String in RULES:
		if rule in allowed:
			continue
		var pattern := RegEx.create_from_string(str(RULES[rule]))
		for i in lines.size():
			var code := _code(lines[i])
			if pattern.search(code):
				out.append("%s: line %d: %s" % [rule, i + 1, code.strip_edges()])
	if text.contains("RandomNumberGenerator.new()") and not text.contains(".seed ="):
		out.append("unseeded_rng: a RandomNumberGenerator is created but never seeded")
	return out


## A line without its comment (a "#" outside a string literal).
static func _code(line: String) -> String:
	var quote := ""
	for i in line.length():
		var c := line[i]
		if quote != "":
			if c == quote and (i == 0 or line[i - 1] != "\\"):
				quote = ""
		elif c == '"' or c == "'":
			quote = c
		elif c == "#":
			return line.substr(0, i)
	return line


func _sim_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(SIM_DIR)
	if dir == null:
		return out
	for name in dir.get_files():
		if name.ends_with(".gd"):
			out.append(SIM_DIR.path_join(name))
	out.sort()
	return out
