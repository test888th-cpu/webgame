class_name RpgHunter
extends RefCounted
## The hunter's mechanics (src/sim/combat/hunter_*.ts, pet/*.ts).


## The selfBuff arm's hunter tail: onHunterGuiseActivated and the major windows.
static func on_self_buff(
	_w: RpgEncounter, _p: Dictionary, _def: Dictionary, _eff: Dictionary
) -> void:
	pass


## selfHealPctMax's Wildheart tail.
static func on_self_heal_pct(_w: RpgEncounter, _p: Dictionary, _id: String) -> void:
	pass


## huntingMomentumSpeedMult (Fieldcraft): +15% per stack, up to 3.
static func hunting_momentum_mult(u: Dictionary) -> float:
	for a: Dictionary in u["auras"]:
		if a["kind"] == "hunter_momentum":
			return 1.0 + 0.15 * clampi(int(a.get("stacks", 1)), 0, 3)
	return 1.0


## isFeigningDeath: no monster perceives Play Dead's "corpse".
static func is_feigning_death(u: Dictionary) -> bool:
	return RpgAbilityRules.has_kind(u, "feign_death")


## spawnHunterTrap (hunter_trap.ts).
static func spawn_trap(
	_w: RpgEncounter, _p: Dictionary, _eff: Dictionary, _def: Dictionary
) -> void:
	pass
