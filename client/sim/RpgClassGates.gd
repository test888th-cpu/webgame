class_name RpgClassGates
extends RefCounted
## castAbility's per-effect target checks on a hostile target (the loop over the
## resolved effects, casting_lifecycle.ts), in its order: a behind-the-target strike
## needs a dagger and the target's back; Polymorph refuses undead (and gorrak, and
## cc-immune mobs); a taunt needs a mob.


static func target_gate(
	w: RpgEncounter, p: Dictionary, _def: Dictionary, res: Dictionary, target: Dictionary
) -> String:
	for eff: Dictionary in res["effects"]:
		if eff["type"] == "weaponStrike" and eff.get("requiresBehind", false):
			if not bool(p["weapon"].get("dagger", false)):
				return "You must wield a dagger."
			if not RpgStealth.is_stealthed(p) and RpgRogue.veil_waives_behind(w, p):
				continue
			if not behind(target, p):
				return "You must be behind your target."
		if eff["type"] == "polymorph":
			if target["kind"] == "mob":
				var fam := str(RpgPack.monster(w.pack, str(target["template_id"])).get("family"))
				if fam == "undead" or target["template_id"] == "gorrak":
					return "This creature cannot be polymorphed."
				if target.get("cc_immune", false):
					return "This creature cannot be polymorphed."
			elif target["kind"] != "player":
				return "This creature cannot be polymorphed."
		if eff["type"] == "taunt" and target["kind"] != "mob":
			return "You cannot taunt that."
	return ""


## Behind (castAbility: |angle(target -> caster) - target facing| >= 90 degrees, and
## not overlapping): on the street, the caster stands on the side the target does
## not face.
static func behind(target: Dictionary, caster: Dictionary) -> bool:
	var dx := float(caster["x"]) - float(target["x"])
	if absf(dx) < RpgAbilityRules.FACING_HOLD_DIST:
		return false
	return signf(dx) != float(target.get("facing", 1.0))
