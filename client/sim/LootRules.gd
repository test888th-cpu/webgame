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
## With `content`, a drop the hero may no longer receive (eligible) is left
## out, alone: the rest of the table still drops, on every kill and every
## story boss rematch. Each drop is rolled either way, so a seed gives the
## same rolls whatever is owned.
static func roll(
	loot: Dictionary,
	rng: RandomNumberGenerator,
	profile: PlayerProfile = null,
	kind := "",
	content: ContentDB = null
) -> Dictionary:
	var money: Array = loot.get("money", [0, 0])
	var items: Array[String] = []
	for drop: Dictionary in loot.get("drops", []):
		var hit := rng.randf() < chance(drop, profile, kind)
		if hit and eligible(str(drop["item"]), profile, content):
			items.append(str(drop["item"]))
	return {"money": rng.randi_range(int(money[0]), int(money[1])), "items": items}


## False when `item_id` is once-only and the hero already has it: evidence
## ("type": "key") and one-of-a-kind prizes ("unique") are granted once, so a
## replayed fight never hands them over again. Everything else is always
## eligible.
static func eligible(item_id: String, profile: PlayerProfile, content: ContentDB) -> bool:
	if profile == null or content == null:
		return true
	var item := content.item(item_id)
	var once: bool = item.get("type") == "key" or item.get("unique", false)
	return not once or profile.owned(item_id) == 0


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
