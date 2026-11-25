class_name SkillsCase
extends TestCase
## Shared setup for the skills-port tests (docs/SKILLS_PORT.md): a street of sturdy
## monsters, a character of any class, level, spec and talents, and a cast with the
## resource filled.

const CLASSES: Array[String] = [
	"warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"
]

var _content: ContentDB


func _db() -> ContentDB:
	if _content == null:
		_content = ContentDB.load_all()
	return _content


func _pack() -> Dictionary:
	return RpgPack.of(_db())


func _char(cls: String, level: int, spec := "", talents := {}) -> Dictionary:
	var s := RpgCharacter.create(_db(), _pack(), cls)
	s["level"] = level
	s["spec_id"] = spec
	s["talents"] = talents
	return s


## A street with monsters at the given positions; the player at 0, targeting the
## first, auto off.
func _street(state: Dictionary, xs: Array, seed := 7) -> RpgEncounter:
	var spawns: Array = []
	for x: float in xs:
		spawns.append({"monster": "shore_scuttler", "x": x})
	var f := RpgEncounter.start_zone(_db(), _pack(), state, spawns, RpgRng.seeded(seed), 0.0)
	f.auto_mode = false
	f.bounds = Vector2(-60.0, 60.0)
	f.command({"op": "target_nearest"})
	return f


## Monsters that outlast the test's own blows.
func _sturdy(f: RpgEncounter) -> RpgEncounter:
	for m: Dictionary in f.mobs:
		m["max_hp"] = 100000
		m["hp"] = 100000
	return f


func _full(f: RpgEncounter) -> void:
	f.player["resource"] = float(f.player["max_resource"])
	f.player["gcd"] = 0.0


func _cast(f: RpgEncounter, id: String) -> String:
	_full(f)
	return f.command({"op": "cast", "ability": id})


func _has_aura(u: Dictionary, id: String) -> bool:
	for a: Dictionary in u["auras"]:
		if a["id"] == id:
			return true
	return false
