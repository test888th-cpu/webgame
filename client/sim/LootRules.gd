class_name LootRules
extends RefCounted
## Rolls a loot table with a caller-supplied generator. Drops are decided by
## whoever owns the generator: the zone simulation today, the authoritative
## zone server in Milestone 4. A client never rolls its own loot online.
##
## Bad-luck protection: a drop marked "pity" (a boss's rare gear) grows more
## likely with every defeat of that enemy while the hero owns no copy of the
## item, PITY_STEP of its chance per earlier defeat, up to PITY_CAP. It reads
## what the save already keeps (PlayerProfile.defeated, owned), so nothing new
## is saved; once the hero has one, the chance is the base one again.

const PITY_STEP := 0.25
const PITY_CAP := 0.5


## Returns {"money": int, "items": Array[String]}. `profile` and `kind` (the
## enemy just defeated, already counted in profile.defeated) drive the pity.
static func roll(
	loot: Dictionary, rng: RandomNumberGenerator, profile: PlayerProfile = null, kind := ""
) -> Dictionary:
	var money: Array = loot.get("money", [0, 0])
	var items: Array[String] = []
	for drop: Dictionary in loot.get("drops", []):
		if rng.randf() < chance(drop, profile, kind):
			items.append(str(drop["item"]))
	return {"money": rng.randi_range(int(money[0]), int(money[1])), "items": items}


## The chance `drop` drops now: its base chance, raised by the pity for a
## "pity" drop the hero has none of (see the class comment).
static func chance(drop: Dictionary, profile: PlayerProfile = null, kind := "") -> float:
	var base := float(drop["chance"])
	if not drop.get("pity", false) or profile == null or kind == "":
		return base
	if profile.owned(str(drop["item"])) > 0:
		return base
	var before := maxi(0, int(profile.defeated.get(kind, 0)) - 1)
	return minf(maxf(base, PITY_CAP), base * (1.0 + PITY_STEP * before))
