class_name BalanceProfile
extends RefCounted
## A skill's balance per game mode. A job skill (skills.json, with a "job")
## carries "profiles": {"pve": {...}, "pvp": {...}}: multipliers on the
## skill's own values, so the two modes are tuned apart and a change for one
## never moves the other. Skill logic holds no number of either mode; it asks
## here. A skill without profiles, or a field a profile leaves out, is 1.0.

const PVE := "pve"
const PVP := "pvp"
const MODES: Array[String] = [PVE, PVP]
## What a profile may scale: damage dealt, hitstun and knockback given, how
## long a hold or stance lasts, and the cooldown.
const FIELDS: Array[String] = ["damage", "hitstun", "knockback", "duration", "cooldown"]


## The multiplier on `field` of `skill` in `mode`.
static func scale(skill: Dictionary, mode: String, field: String) -> float:
	var profiles: Variant = skill.get("profiles")
	if not profiles is Dictionary:
		return 1.0
	var profile: Variant = profiles.get(mode)
	if not profile is Dictionary:
		return 1.0
	return float(profile.get(field, 1.0))


## The skill's cooldown in ticks in `mode`; never below one tick.
static func cooldown(skill: Dictionary, mode: String) -> int:
	return maxi(1, roundi(float(skill.get("cooldown", 1)) * scale(skill, mode, "cooldown")))


## What is wrong with `skill`'s profiles: both modes are required, and each
## holds only known fields with multipliers above zero.
static func problems(skill: Dictionary, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var profiles: Variant = skill.get("profiles")
	if not profiles is Dictionary:
		out.append('%s.profiles: expected {"pve": {...}, "pvp": {...}}' % where)
		return out
	for mode: Variant in profiles:
		if str(mode) not in MODES:
			out.append("%s.profiles: unknown mode %s" % [where, mode])
	for mode: String in MODES:
		var profile: Variant = profiles.get(mode)
		if not profile is Dictionary:
			out.append("%s.profiles.%s: required" % [where, mode])
			continue
		for field: Variant in profile:
			var value: Variant = profile[field]
			if str(field) not in FIELDS:
				out.append("%s.profiles.%s: unknown field %s" % [where, mode, field])
			elif not (value is float or value is int) or value <= 0:
				out.append("%s.profiles.%s.%s: expected a number above 0" % [where, mode, field])
	return out
