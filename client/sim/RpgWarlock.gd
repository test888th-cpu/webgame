class_name RpgWarlock
extends RefCounted
## The warlock's engines (src/sim/combat/affliction.ts, destruction.ts,
## necromancy.ts, warlock_*.ts, pet/warlock_pet_*.ts).


## A drainTick channel pulse (applyChannelTick's drainTick arm).
static func drain_tick(
	_w: RpgEncounter,
	_src: Dictionary,
	_tgt: Dictionary,
	_res: Dictionary,
	_eff: Dictionary,
	_sp: int
) -> void:
	pass


## warlockFearBreakThreshold: Fear and Howl of Terror break past a damage budget;
## -1 for any other ability.
static func fear_break_threshold(ability_id: String, max_hp: int) -> int:
	if ability_id != "fear" and ability_id != "howl_of_terror":
		return -1
	return maxi(1, int(RpgTalents.js_round(maxf(0.0, float(max_hp)) * 0.08)))


## costTaxMult: 1 + the highest draining-curse cost_tax aura on the caster.
static func cost_tax_mult(u: Dictionary) -> float:
	var pct := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "cost_tax" and float(a["value"]) > pct:
			pct = float(a["value"])
	return 1.0 + pct


## applyLeadenHex.
static func leaden_hex(_w: RpgEncounter, _p: Dictionary, _id: String, _target: Dictionary) -> void:
	pass
