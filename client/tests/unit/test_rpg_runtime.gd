extends TestCase
## The playable reference slice's runtime (docs/PLAYABLE_SLICE.md).
## The combat engine's own tests (classes, specs, abilities, auras, death) are in
## test_rpg_combat_engine.gd. The parity tests
## compare against tests/fixtures/rpg_runtime_parity.json, written by
## tools/content/runtime_parity_fixtures.py from the pinned reference's own Rng,
## rollLoot and meleeSwing (static evaluation, scripted draws); the rest are the
## loop: create, fight (auto and manual through one door), rewards, gear, save.

const FIXTURE := "res://tests/fixtures/rpg_runtime_parity.json"
const TWO32 := 4294967296.0

var _content: ContentDB
var _fixture: Dictionary


func _db() -> ContentDB:
	if _content == null:
		_content = ContentDB.load_all()
	return _content


func _pack() -> Dictionary:
	return RpgPack.of(_db())


## Fixture draws are integers k of k / 2^32, so no float parser can change them.
static func _draws(u32: Array) -> Array:
	return u32.map(func(k: Variant) -> float: return float(k) / TWO32)


func _fix() -> Dictionary:
	if _fixture.is_empty():
		_fixture = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	return _fixture


# -- parity with the reference -------------------------------------------------


func test_rng_matches_the_reference_generator() -> void:
	for case: Dictionary in _fix()["rng"]:
		var rng := RpgRng.seeded(int(case["seed"]))
		for i in case["next_u32"].size():
			var u32 := int(rng.next() * TWO32)
			assert_eq(u32, int(case["next_u32"][i]), "seed %s draw %d" % [case["seed"], i])


func test_swings_match_the_reference_melee_swing() -> void:
	var cases: Array = _fix()["swing"]
	assert_true(cases.size() >= 400, "fixture size")
	for i in cases.size():
		var c: Dictionary = cases[i]
		var a: Dictionary = c["attacker"]
		var attacker := {
			"kind": "player",
			"class_id": "rogue",
			"level": int(a["level"]),
			"weapon": a["weapon"],
			"attack_power": float(a["attack_power"]),
			"crit": float(a["crit"]),
			"hit_bonus": float(a["hit_bonus"]),
		}
		var target := {
			"kind": "mob", "level": int(c["target"]["level"]), "armor": float(c["target"]["armor"])
		}
		var o: Dictionary = c["opts"]
		var opts := {
			"hand": str(o["hand"]),
			"white_dw_penalty": bool(o["white_dw_penalty"]),
			"weapon_mult": float(o["weapon_mult"]),
			"normalized": bool(o["normalized"]),
			"cannot_be_dodged": bool(o["cannot_be_dodged"]),
			"crit_bonus": float(o["crit_bonus"]),
			"bonus": float(o["bonus"]),
		}
		var rng := RpgRng.scripted(_draws(c["draws_u32"]))
		var hit := RpgSwing.player_swing(attacker, target, rng, opts)
		var landed: bool = hit["result"] == "hit" or hit["result"] == "block"
		assert_eq(landed, bool(c["landed"]), "swing %d landed" % i)
		assert_eq(rng.scripted_values.size(), 0, "swing %d draws every scripted value" % i)
		if landed and c["dealt"] != null:
			assert_eq(hit["amount"], int(c["dealt"]["amount"]), "swing %d damage" % i)
			assert_eq(hit["crit"], bool(c["dealt"]["crit"]), "swing %d crit" % i)


func test_corpse_loot_matches_the_reference_roll() -> void:
	var loot: Dictionary = _fix()["loot"]
	var qualities := 0
	for i in loot["cases"].size():
		var c: Dictionary = loot["cases"][i]
		var rng := RpgRng.scripted(_draws(c["draws_u32"]))
		var out := RpgLootRoll.roll(
			loot["entries"][c["mob"]],
			loot["items"],
			str(c["class"]),
			func(_q: String) -> bool: return false,
			true,
			rng
		)
		var label := "%s/%s #%d" % [c["mob"], c["class"], i]
		assert_eq(rng.scripted_values.size(), 0, label + ": same number of draws")
		assert_eq(out["copper"], int(c["copper"]), label + ": copper")
		assert_eq(out["items"].size(), c["items"].size(), label + ": item count")
		for j in mini(out["items"].size(), c["items"].size()):
			var mine: Dictionary = out["items"][j]
			var theirs: Dictionary = c["items"][j]
			assert_eq(mine["item_id"], theirs["item_id"], label + ": item")
			var q: Variant = theirs["quality"]
			if q == null:
				assert_eq(mine["quality"], null, label + ": ordinary copy")
			else:
				qualities += 1
				assert_eq(int(mine["quality"]["tier"]), int(q["tier"]), label + ": tier")
				for k in 5:
					assert_eq(
						int(mine["quality"]["weights"][k]), int(q["weights"][k]), label + ": w"
					)
	assert_true(qualities > 0, "a minted quality was compared")


# -- the loop ------------------------------------------------------------------


func test_new_character_wears_the_reference_kit() -> void:
	var state := RpgCharacter.create(_db(), _pack(), "warrior")
	assert_eq(state["equipment"]["mainhand"], "worn_sword", "start weapon")
	assert_eq(state["equipment"]["offhand"], "eastbrook_buckler", "start shield")
	assert_eq(state["equipment"]["chest"], "recruit_tunic", "start chest")
	var sheet := RpgCharacter.sheet(_db(), _pack(), state)
	var bare := RpgStats.sheet(RpgClassRegistry.class_def(_db(), "warrior"), 1)
	assert_eq(
		sheet["max_hp"], int(bare["max_hp"]) + 10 * 1, "buckler Stamina: 1 point past 20 = 10 HP"
	)
	assert_eq(sheet["armor"], int(bare["armor"]) + 34 + 20, "shield and tunic armor")
	assert_eq(sheet["block_value"], 6, "the buckler's block value")
	assert_near(sheet["block_chance"], 0.05, "SHIELD_BLOCK_BASE")
	assert_eq(RpgCharacter.create(_db(), _pack(), "nobody"), {}, "unknown class refused")
