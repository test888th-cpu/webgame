class_name RpgEffectsClass
extends RefCounted
## runEffects' class-only arms (summons, pets, devotion, affliction, hunter
## commands, ...), each routed to its class module. False when no arm handles it.


static func run_arm(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> bool:
	if RpgPaladin.run_arm(w, p, eff):
		return true
	if RpgDruidKit.run_arm(w, p, target, res, eff, ctx):
		return true
	if eff["type"] == "chainHeal":
		RpgShamanKit.chain_heal(w, p, target, res, eff, ctx)
		return true
	return RpgPaladinKit.run_arm(w, p, target, res, eff, ctx)
