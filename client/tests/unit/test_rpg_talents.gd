extends TestCase
## RpgTalents against the pinned reference's own computeTalentModifiers and
## abilitiesKnownAt (tests/fixtures/rpg_talent_parity.json, written by
## tools/content/runtime_parity_fixtures.py on random allocations for every class).

const FIXTURE := "res://tests/fixtures/rpg_talent_parity.json"

var _pack: Dictionary
var _cases: Array


func _setup() -> void:
	if _pack.is_empty():
		_pack = RpgPack.of(ContentDB.load_all())
		_cases = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))["cases"]


## Deep equality with numbers compared as numbers (JSON loads them as floats); a key
## holding null counts as absent, as in the reference's optional fields.
func _same(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a) - float(b)) < 1e-9
	if a is Dictionary and b is Dictionary:
		return _same_dict(a, b)
	if a is Array and b is Array:
		return (
			a.size() == b.size()
			and range(a.size()).all(func(i: int) -> bool: return _same(a[i], b[i]))
		)
	return a == b


func _same_dict(a: Dictionary, b: Dictionary) -> bool:
	var keys := {}
	for k: Variant in a:
		if a[k] != null:
			keys[k] = true
	for k: Variant in b:
		if b[k] != null:
			keys[k] = true
	for k: Variant in keys:
		if not _same(a.get(k), b.get(k)):
			return false
	return true


func test_modifiers_match_the_reference() -> void:
	_setup()
	assert_true(_cases.size() >= 200, "fixture size")
	for c: Dictionary in _cases:
		var label := "%s L%d %s" % [c["class"], c["level"], JSON.stringify(c["alloc"])]
		var mods := RpgTalents.mods_for(_pack, c["class"], c["alloc"], int(c["level"]))
		var want: Dictionary = c["mods"]
		assert_true(_same(mods["spec"], want["spec"]), label + ": spec")
		assert_true(_same(mods["stats"], want["stats"]), label + ": stats")
		assert_true(_same(mods["global"], want["global"]), label + ": global")
		assert_true(_same(mods["abilities"], want["abilities"]), label + ": ability mods")
		assert_true(_same(mods["grants"], want["grants"]), label + ": grants")
		assert_true(_same(mods["selected"], want["selected"]), label + ": selected")


func test_spellbook_matches_the_reference() -> void:
	_setup()
	var compared := 0
	for c: Dictionary in _cases:
		var label := "%s L%d %s" % [c["class"], c["level"], JSON.stringify(c["alloc"])]
		var mods := RpgTalents.mods_for(_pack, c["class"], c["alloc"], int(c["level"]))
		var mine := RpgTalents.known(_pack, c["class"], int(c["level"]), mods)
		var want: Array = c["known"]
		var ids: Array = mine.map(func(e: Dictionary) -> String: return e["id"])
		var want_ids: Array = want.map(func(e: Dictionary) -> String: return e["id"])
		assert_eq(ids, want_ids, label + ": known abilities in order")
		if ids != want_ids:
			continue
		for i in want.size():
			var e: Dictionary = mine[i]
			var w: Dictionary = want[i]
			var what := "%s %s" % [label, w["id"]]
			assert_eq(e["rank"], int(w["rank"]), what + ": rank")
			assert_true(_same(e["cost"], w["cost"]), what + ": cost")
			assert_true(_same(e["castTime"], w["castTime"]), what + ": cast time")
			assert_true(_same(e["cooldown"], w["cooldown"]), what + ": cooldown")
			assert_true(_same(e["effects"], w["effects"]), what + ": effects")
			assert_true(_same(e.get("charges"), w["charges"]), what + ": charges")
			compared += 1
	assert_true(compared > 1000, "entries compared: %d" % compared)


func test_allocation_rules() -> void:
	_setup()
	var row5: Dictionary = RpgTalents.class_talents(_pack, "warrior")["rows"][0]
	var option: String = row5["options"][0]["id"]
	var early := RpgTalents.repair(_pack, "warrior", {"spec": "arms", "rows": {"5": option}}, 4)
	assert_eq(early, {"spec": "", "rows": {}}, "nothing before level 5")
	var ok := RpgTalents.repair(_pack, "warrior", {"spec": "arms", "rows": {"5": option}}, 5)
	assert_eq(ok, {"spec": "arms", "rows": {"5": option}}, "spec and the level-5 row at 5")
	var foreign := RpgTalents.repair(_pack, "warrior", {"spec": "frost", "rows": {"5": "x"}}, 20)
	assert_eq(foreign, {"spec": "", "rows": {}}, "another class's spec and unknown options dropped")
