class_name GearCheck
extends RefCounted
## A boss checks the hero's gear (progression.json "gear_check"), as the
## online RPGs it follows check gear score: levels alone do not carry a hero
## through, the gear must be ready. Every boss asks for a gear score: a full
## set's budget at its level (ItemRules, the scale every item is priced on)
## times its grade: "story_boss" for the story's bosses, "world_boss" for a
## world boss, or the boss's own "gear_grade" (enemies.json). A story boss's
## grade rises by "story_per_level" a level: an early boss asks for less than
## the shop's set at its level, the finale for more (upgraded or boss gear),
## as each chapter's shop falls further behind its bosses. A hero short of
## it by a share s deals that boss (1 - deal_per_shortfall * s) of each hit
## (never under min_deal) and takes (1 + take_per_shortfall * s) of its hits
## and hazards; at or above it nothing changes, so gear past the mark brings
## only its own stats. So starter clothes, half a set or gear left un-upgraded
## cannot stand and trade with a boss for long. Only the boss itself checks:
## its brood and the street fight as before. Pure rules, shared with the
## server.


## What `profile` wears, scored with its upgrades (ItemRules.copy_score).
static func score(profile: PlayerProfile, content: ContentDB) -> int:
	var total := 0.0
	for slot: String in PlayerProfile.SLOTS:
		total += ItemRules.copy_score(profile, str(profile.equipment.get(slot, "")), content)
	return roundi(total)


## The gear score boss `kind` asks for at `level` (0 for a non-boss).
static func required(content: ContentDB, kind: String, level: int) -> int:
	var data := content.enemy(kind)
	if not data.get("boss", false):
		return 0
	var rules: Dictionary = content.progression.get("gear_check", {})
	var grade := float(rules.get("world_boss", 0))
	if not _is_world_boss(content, kind):
		grade = float(rules.get("story_boss", 0)) + float(rules.get("story_per_level", 0)) * level
	grade = float(data.get("gear_grade", grade))
	var slots := 0.0
	for slot: String in ItemRules.SLOT_WEIGHTS:
		slots += float(ItemRules.SLOT_WEIGHTS[slot])
	return roundi((ItemRules.BASE + ItemRules.PER_LEVEL * level) * slots * grade)


## How far short of `need` a gear score of `have` falls, 0 (ready) to 1.
static func shortfall(have: int, need: int) -> float:
	return 0.0 if need <= 0 else clampf(1.0 - float(have) / need, 0.0, 1.0)


## The share of each hit the hero lands on the boss, `short` short.
static func dealt(content: ContentDB, short: float) -> float:
	var rules: Dictionary = content.progression.get("gear_check", {})
	var scale := 1.0 - float(rules.get("deal_per_shortfall", 0)) * short
	return maxf(float(rules.get("min_deal", 0.1)), scale)


## How much harder the boss hits the hero, `short` short.
static func taken(content: ContentDB, short: float) -> float:
	var rules: Dictionary = content.progression.get("gear_check", {})
	return 1.0 + float(rules.get("take_per_shortfall", 0)) * short


## Sets up boss `boss` (at its level in `zone`) against the hero's gear.
static func apply(zone: ZoneSim, boss: Fighter) -> void:
	var need := required(zone.content, boss.kind, zone.enemy_level(boss.id))
	var short := shortfall(score(zone.profile, zone.content), need)
	boss.hurt_scale = dealt(zone.content, short)
	boss.hit_scale = taken(zone.content, short)


static func _is_world_boss(content: ContentDB, kind: String) -> bool:
	for data: Dictionary in content.world_bosses.values():
		if str(data.get("enemy", "")) == kind:
			return true
	return false
