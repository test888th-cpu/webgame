class_name RpgSwing
extends RefCounted
## Melee swings as World of ClaudeCraft resolves them, draw for draw.
## * A player's swing (white or special): src/sim/combat/auto_attack.ts meleeSwing.
##   One next() for the table (miss, dodge, parry, block), then range(min, max) for
##   the weapon, then chance(crit). Damage = (roll x rollMult + AP / 14 x apSpeed) x
##   weaponMult + bonus; x2 on a crit; x (1 - armorReduction(armor, attacker level));
##   a block subtracts the block value (shield_block.ts); at least 1, rounded.
## * A mob's swing: src/sim/sim.ts mobSwing. Its own table: the player's dodge,
##   range(min, max) + AP / 14 x speed (mobs have 0 AP), a flat chance(0.05) crit
##   draw, mobArmorReduction.
##
## A combatant is a dictionary: {kind ("player"|"mob"), class_id, spec_id, level,
## weapon {min, max, speed}, attack_power, crit, dodge, hit_bonus, armor, str,
## block_chance, block_value}. Auras, procs, forms, imbues, thorns, enrage, threat
## and spec modifiers are not modelled; the encounter refuses what needs them.


## A player's swing. `opts`: hand ("mainhand"|"offhand" for an auto attack, "" for a
## special), weapon (default the attacker's mainhand), weapon_mult, bonus, crit_bonus,
## cannot_be_dodged, normalized (a special's normalized speed), white_dw_penalty,
## offhand_mult. Returns {result: miss|dodge|parry|hit|block, amount, crit, connected}.
static func player_swing(
	attacker: Dictionary, target: Dictionary, rng: RpgRng, opts := {}
) -> Dictionary:
	var a_level := int(attacker["level"])
	var t_level := int(target["level"])
	var miss := RpgHitTable.swing_miss_chance(
		a_level, t_level, false, float(attacker.get("hit_bonus", 0.0))
	)
	miss += float(opts.get("miss_bonus", 0.0))
	if opts.get("white_dw_penalty", false):
		miss += RpgDamage.DUAL_WIELD_WHITE_MISS_PENALTY
	var dodge := 0.0
	if not opts.get("cannot_be_dodged", false):
		dodge = (
			float(target.get("dodge", 0.0))
			if str(target["kind"]) == "player"
			else RpgHitTable.mob_dodge_chance(a_level, t_level)
		)
	var defense := melee_defense(target)
	var parry: float = defense["parry"]
	var block: float = defense["block"]
	var roll := rng.next()
	if roll < miss:
		return _avoided("miss")
	if roll < miss + dodge:
		return _avoided("dodge")
	if roll < miss + dodge + parry:
		return _avoided("parry")
	var weapon: Dictionary = opts.get("weapon", attacker["weapon"])
	var hand := str(opts.get("hand", ""))
	var roll_mult := float(opts.get("roll_mult", 1.0))
	var ap_speed := float(attacker["weapon"]["speed"])
	if hand == "":
		if opts.get("normalized", false):
			var norm := RpgDamage.normalized_speed(weapon)
			roll_mult = norm / maxf(0.1, float(weapon["speed"]))
			ap_speed = norm
	elif hand == "offhand":
		roll_mult = RpgDamage.OFFHAND_AUTO_ATTACK_DMG_MULT
		ap_speed = float(weapon["speed"])
	if opts.has("ap_speed") and not (hand == "" and opts.get("normalized", false)):
		ap_speed = float(opts["ap_speed"])
	var dmg := (
		(
			(
				rng.range_f(float(weapon["min"]), float(weapon["max"])) * roll_mult
				+ float(attacker.get("attack_power", 0)) / RpgDamage.AP_PER_DPS * ap_speed
			)
			* float(opts.get("weapon_mult", 1.0))
			* float(opts.get("form_mult", 1.0))
		)
		+ float(opts.get("bonus", 0.0))
	)
	var crit_chance := RpgHitTable.crit_vs(
		float(attacker.get("crit", 0.0)), a_level, t_level, float(opts.get("crit_bonus", 0.0))
	)
	var crit := rng.chance(1.0 if opts.get("crit_forced", false) else crit_chance)
	crit = crit or opts.get("force_crit", false)
	if crit:
		dmg *= RpgDamage.PHYSICAL_CRIT_MULT + float(attacker.get("crit_dmg_phys", 0.0))
	dmg *= 1.0 - RpgHitTable.armor_reduction(float(target.get("armor", 0)), a_level)
	var blocked := block > 0.0 and roll < miss + dodge + parry + block
	if blocked:
		dmg = blocked_damage(dmg, target)
	return {"result": "block" if blocked else "hit", "amount": maxi(1, roundi(dmg)), "crit": crit}


## A hostile mob's swing at a player (sim.ts mobSwing).
static func mob_swing(
	mob: Dictionary, target: Dictionary, rng: RpgRng, mob_crit := 0.05, crit_immune := false
) -> Dictionary:
	var m_level := int(mob["level"])
	var t_level := int(target["level"])
	var player_side := str(target["kind"]) == "player"
	var miss := RpgHitTable.swing_miss_chance(m_level, t_level, player_side)
	var dodge := float(target.get("dodge", 0.0)) if player_side else RpgHitTable.MOB_DODGE_BASE
	var defense := melee_defense(target)
	var parry: float = defense["parry"]
	var block: float = defense["block"]
	var roll := rng.next()
	if roll < miss:
		return _avoided("miss")
	if roll < miss + dodge:
		return _avoided("dodge")
	if roll < miss + dodge + parry:
		return _avoided("parry")
	var weapon: Dictionary = mob["weapon"]
	var dmg := (
		rng.range_f(float(weapon["min"]), float(weapon["max"]))
		+ float(mob.get("attack_power", 0)) / RpgDamage.AP_PER_DPS * float(weapon["speed"])
	)
	# The roll is drawn even for a committed tank who never suffers it
	# (tank_crit_immunity.ts isCritImmuneTank).
	var crit := rng.chance(mob_crit) and not crit_immune
	if crit:
		dmg *= 2.0
	dmg *= (
		1.0
		- RpgHitTable.mob_armor_reduction(
			float(target.get("armor", 0)), m_level, t_level, player_side
		)
	)
	var blocked := block > 0.0 and roll < miss + dodge + parry + block
	if blocked:
		dmg = blocked_damage(dmg, target)
	return {"result": "block" if blocked else "hit", "amount": maxi(1, roundi(dmg)), "crit": crit}


## blockedMeleeDamage: a protection paladin first takes 20% off; then the block value
## comes off, leaving at least 1.
static func blocked_damage(dmg: float, target: Dictionary) -> float:
	if (
		str(target.get("class_id", "")) == "paladin"
		and str(target.get("spec_id", "")) == "protection"
	):
		dmg *= 1.0 - float(target.get("prot_paladin_block_reduction", 0.2))
	return maxf(1.0, dmg - float(target.get("block_value", 0)))


## Parry and block (src/sim/combat/warrior_hit_table.ts warriorMeleeDefense): only a
## warrior or paladin player, attacked from the front (the trial's fights are always
## face to face). Warrior parry = max(0, 0.05 + Str x 0.0005); block = the shield's
## block chance when it has a block value.
static func melee_defense(defender: Dictionary) -> Dictionary:
	var none := {"parry": 0.0, "block": 0.0}
	if str(defender["kind"]) != "player":
		return none
	var cls := str(defender.get("class_id", ""))
	if cls != "warrior" and cls != "paladin":
		return none
	var parry := 0.0
	if cls == "warrior":
		parry = maxf(0.0, 0.05 + float(defender.get("str", 0)) * 0.0005)
	var block := 0.0
	var bonus := 0.0
	for a: Dictionary in defender.get("auras", []):
		if a["kind"] == "buff_block":
			bonus += float(a["value"])
	var chance := float(defender.get("block_chance", 0)) + bonus
	if float(defender.get("block_value", 0)) > 0 and chance > 0:
		block = minf(1.0, chance)
	return {"parry": parry, "block": block}


static func _avoided(kind: String) -> Dictionary:
	return {"result": kind, "amount": 0, "crit": false}
