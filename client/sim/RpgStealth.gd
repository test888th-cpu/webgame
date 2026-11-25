class_name RpgStealth
extends RefCounted
## Stealth (sim.ts breakStealth, src/sim/combat/stealth.ts).


## breakStealth: the stealth aura goes (the rogue's Dusk linger and the mage's
## Greater Invisibility aftereffect hook in with those classes' ports).
static func break_stealth(w: RpgEncounter, u: Dictionary) -> void:
	for a: Dictionary in u["auras"]:
		if a["kind"] == "stealth":
			RpgAbilityRules.remove_aura(w, u, a)
			RpgRogue.on_stealth_broken(w, u, a)
			return


static func is_stealthed(u: Dictionary) -> bool:
	return RpgAbilityRules.has_kind(u, "stealth")
