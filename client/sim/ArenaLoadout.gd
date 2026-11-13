class_name ArenaLoadout
extends RefCounted
## What each arena rival is (data/arena.json): its job, level, AI skill and
## timing, personality, and the gear it wears in every slot with its upgrade.
## All of it is configuration: nothing about a rival is written in code.
##
## A rival's settings are merged from layers, later ones winning:
##   defaults < its preset < its tier < rank_overrides covering its rank
##   < opponents[its id]
## A tier gives ranges ([weakest rank's, strongest rank's]) spread over its
## ranks. A per-slot setting (slots.<slot>.item / grade / plus / weights /
## empty, the last for a slot deliberately left bare)
## always beats a ladder-wide one (grades / plus / weights), whatever its
## layer: "this rival's weapon is +5" stays +5 under a tier's "+3 to +4".
##
## Gear is the real items of data/items.json, chosen as a player would have
## collected it: per slot the best item (ItemRules.score, weighted by the
## preset) at or under the rival's level among the allowed grades, or the
## item named. Nothing is ever substituted: a slot that cannot be filled, an
## unknown item, a wrong slot, an illegal upgrade or a level too high is an
## error, and a rival with errors is never offered (ArenaRules.choices).
## Pure rules, shared with the server.

## How upgrades spread across the six slots of a tier giving a range, so the
## gear is mixed (+3/+4/+3...) rather than all one level.
const SLOT_SPREAD: Array[int] = [1, 0, -1, 1, 0, -1]
## Fields a layer may set (anything else in a layer is a typo, reported).
const FIELDS := [
	"preset",
	"personality",
	"job",
	"name",
	"level",
	"ai",
	"grades",
	"plus",
	"weights",
	"slots",
	"reaction_ms",
]
const SLOT_FIELDS := ["item", "grade", "plus", "weights", "empty"]

## Equipment ids by slot (see _slot_items).
static var _by_slot := {}


## The rival with id `id` ("r<rank it starts at>") fully resolved:
## {"id", "rank", "name", "hero", "job", "level", "ai", "preset",
## "personality", "tier", "sources": [layers applied], "version",
## "slots": {slot: {"item", "grade", "plus"}}, "gear": [item ids, slot
## order], "plus": {item id: upgrade}, "brain": ArenaBrain settings,
## "errors": [what is wrong; empty when the rival may fight]}.
##
## `extra` is one more layer on top (the balance harness builds what it
## measures this way, through the same rules); the game never passes one.
static func resolve(content: ContentDB, id: String, extra := {}) -> Dictionary:
	var spec := content.arena
	var rank := ArenaRules.start_rank(id)
	var errors: PackedStringArray = []
	var layers := _layers(content, id, rank, errors, extra)
	var merged := {}
	var slot_settings := {}
	var sources: Array[String] = []
	for layer: Dictionary in layers:
		sources.append(str(layer["source"]))
		var fields: Dictionary = layer["fields"]
		for key: String in fields:
			if key == "slots":
				_merge_slots(slot_settings, fields["slots"])
			else:
				merged[key] = fields[key]
	var level := int(merged.get("level", 1))
	var job := str(merged.get("job", _job_for(content, rank)))
	var out := {
		"id": id,
		"rank": rank,
		"name": str(merged.get("name", _name_for(spec, rank))),
		"job": job,
		"hero": JobRules.hero_of(content, job),
		"level": level,
		"ai": clampf(float(merged.get("ai", 0.0)), 0.0, 1.0),
		"preset": str(merged.get("preset", "")),
		"personality": str(merged.get("personality", "")),
		"tier": _tier_of(spec, rank).get("id", ""),
		"sources": sources,
		"version": int(spec.get("config_version", 1)),
	}
	_check_fields(out, merged, content, errors)
	_fill_gear(out, merged, slot_settings, content, errors)
	out["brain"] = brain_settings(content, out, merged, errors)
	out["errors"] = errors
	return out


## A character made for a resolved rival: its hero at its level, its gear
## worn and upgraded. Never saved; the player's own profile is not touched.
static func profile(content: ContentDB, data: Dictionary) -> PlayerProfile:
	var made := PlayerProfile.new_game(content, str(data["hero"]), str(data["name"]))
	made.level = int(data["level"])
	for slot: String in data["slots"]:
		var item_id := str(data["slots"][slot]["item"])
		made.add_item(item_id)
		made.equip(item_id, content)
		var worn := str(made.equipment[slot])
		var plus := int(data["slots"][slot]["plus"])
		if plus > 0 and worn != "":
			made.enhance[worn] = plus
	return made


## How a rival plays: AI skill, its timing in ticks (reaction to a blow,
## time between decisions, between presses when held) from its skill, and
## its personality's tendencies. Reactions are never under min_reaction_ms.
static func brain_settings(
	content: ContentDB, data: Dictionary, merged := {}, errors: PackedStringArray = []
) -> Dictionary:
	var spec := content.arena
	var timing: Dictionary = spec.get("timing", {})
	var skill := float(data["ai"])
	var reaction := _lerp_pair(timing.get("reaction_ms", [400, 200]), skill)
	if merged.has("reaction_ms"):
		reaction = float(merged["reaction_ms"])
	var floor_ms := float(timing.get("min_reaction_ms", 200))
	if reaction < floor_ms:
		errors.append(
			"%s: reaction_ms %d is under the human floor %d" % [data["id"], reaction, floor_ms]
		)
		reaction = floor_ms
	var out: Dictionary = (
		(spec.get("personalities", {}) as Dictionary).get(str(data["personality"]), {}).duplicate()
	)
	out["skill"] = skill
	out["reaction_ticks"] = ms_to_ticks(reaction)
	out["decision_ticks"] = maxi(
		1, ms_to_ticks(_lerp_pair(timing.get("decision_ms", [100, 50]), skill))
	)
	out["mash_ticks"] = maxi(1, ms_to_ticks(_lerp_pair(timing.get("mash_ms", [133, 83]), skill)))
	return out


static func ms_to_ticks(ms: float) -> int:
	return roundi(ms * CombatRules.TICK_RATE / 1000.0)


## The item a player of `level` would wear in `slot` among `grades`: the
## best by ItemRules.score with each stat weighted by `weights` (missing
## stats weigh 1). "" when none exists.
static func best_item(
	content: ContentDB, slot: String, level: int, grades: Array, weights := {}
) -> String:
	var best := ""
	var best_score := -1.0
	for item_id: String in _slot_items(content, slot):
		var item := content.item(item_id)
		if int(item.get("level", 1)) > level or str(item.get("rarity")) not in grades:
			continue
		var score := weighted_score(item, weights)
		if score > best_score:
			best_score = score
			best = item_id
	return best


## The equipment ids of `slot`, sorted (kept per content and item list).
static func _slot_items(content: ContentDB, slot: String) -> Array:
	var key := "%d|%d" % [content.get_instance_id(), content.items.size()]
	if _by_slot.get("key", "") != key:
		_by_slot = {"key": key}
		var ids: Array = content.items.keys()
		ids.sort()
		for item_id: String in ids:
			var item := content.item(item_id)
			if item.get("type") == "equipment":
				var list: Array = _by_slot.get(str(item.get("slot")), [])
				list.append(item_id)
				_by_slot[str(item.get("slot"))] = list
	return _by_slot.get(slot, [])


static func weighted_score(item: Dictionary, weights: Dictionary) -> float:
	var total := 0.0
	var stats: Dictionary = item.get("stats", {})
	for key: String in stats:
		var weight := float(ItemRules.STAT_WEIGHTS.get(key, 0.0))
		total += weight * float(stats[key]) * float(weights.get(key, 1.0))
	return total


## The layers that make rival `id`, weakest first: [{"source", "fields"}].
static func _layers(
	content: ContentDB, id: String, rank: int, errors: PackedStringArray, extra := {}
) -> Array[Dictionary]:
	var spec := content.arena
	var tier := _tier_fields(spec, rank)
	var opponent: Dictionary = (spec.get("opponents", {}) as Dictionary).get(id, {})
	var ranked: Array[Dictionary] = []
	for override: Variant in spec.get("rank_overrides", []):
		if override is Dictionary and _covers(override.get("ranks", []), rank):
			var fields: Dictionary = override.duplicate()
			fields.erase("ranks")
			ranked.append({"source": "rank:%s" % str(override["ranks"]), "fields": fields})
	# The preset is chosen by the strongest layer that names one.
	var preset_name := str(spec.get("defaults", {}).get("preset", ""))
	var namers: Array[Dictionary] = [tier]
	for layer in ranked:
		namers.append(layer["fields"])
	namers.append(opponent)
	namers.append(extra)
	for fields in namers:
		if fields.has("preset"):
			preset_name = str(fields["preset"])
	var presets: Dictionary = spec.get("presets", {})
	if not presets.has(preset_name):
		errors.append("%s: unknown preset %s" % [id, preset_name])
	var out: Array[Dictionary] = [{"source": "defaults", "fields": spec.get("defaults", {})}]
	out.append({"source": "preset:" + preset_name, "fields": presets.get(preset_name, {})})
	if not tier.is_empty():
		out.append({"source": "tier:" + str(_tier_of(spec, rank).get("id", "")), "fields": tier})
	out.append_array(ranked)
	if not opponent.is_empty():
		out.append({"source": "opponent:" + id, "fields": opponent})
	if not extra.is_empty():
		out.append({"source": "extra", "fields": extra})
	return out


## The tier covering `rank`, its ranges turned into this rank's values.
static func _tier_fields(spec: Dictionary, rank: int) -> Dictionary:
	var tier := _tier_of(spec, rank)
	if tier.is_empty():
		return {}
	var ranks: Array = tier["ranks"]
	var weakest := int(ranks[0])
	var strongest := int(ranks[1])
	var t := 1.0 if weakest == strongest else float(weakest - rank) / (weakest - strongest)
	var out := {}
	if tier.has("level"):
		out["level"] = roundi(_lerp_pair(tier["level"], t))
	if tier.has("ai"):
		out["ai"] = _lerp_pair(tier["ai"], t)
	if tier.has("plus"):
		var pair: Array = tier["plus"]
		out["plus"] = {"mix": _lerp_pair(pair, t), "lo": int(pair[0]), "hi": int(pair[1])}
	for key: String in ["grades", "weights", "slots", "job", "reaction_ms"]:
		if tier.has(key):
			out[key] = tier[key]
	for pair: Array in [["presets", "preset"], ["personalities", "personality"]]:
		var choices: Array = tier.get(pair[0], [])
		if not choices.is_empty():
			out[pair[1]] = choices[rank % choices.size()]
	return out


static func _tier_of(spec: Dictionary, rank: int) -> Dictionary:
	for tier: Variant in spec.get("tiers", []):
		if tier is Dictionary and _covers(tier.get("ranks", []), rank):
			return tier
	return {}


## Whether [weakest, strongest] (weakest the larger number) covers `rank`.
static func _covers(ranks: Variant, rank: int) -> bool:
	return (
		ranks is Array
		and (ranks as Array).size() == 2
		and rank <= int(ranks[0])
		and rank >= int(ranks[1])
	)


static func _merge_slots(into: Dictionary, slots: Variant) -> void:
	if not slots is Dictionary:
		return
	for slot: String in slots:
		var setting: Variant = slots[slot]
		if not setting is Dictionary:
			continue
		var held: Dictionary = into.get(slot, {})
		for key: String in setting:
			held[key] = setting[key]
		# A slot naming its grade drops an item named by a weaker layer, and
		# naming an item or a grade fills a slot a weaker layer left empty:
		# the stronger layer decides.
		if setting.has("grade") and not setting.has("item"):
			held.erase("item")
		if (setting.has("grade") or setting.has("item")) and not setting.has("empty"):
			held.erase("empty")
		into[slot] = held


static func _job_for(content: ContentDB, rank: int) -> String:
	var jobs: Array = content.job_order
	return str(jobs[rank % jobs.size()]) if not jobs.is_empty() else ""


static func _name_for(spec: Dictionary, rank: int) -> String:
	var names: Array = spec.get("names", [])
	return str(names[rank - 1]) if rank >= 1 and rank <= names.size() else "Rival %d" % rank


static func _lerp_pair(pair: Variant, t: float) -> float:
	if pair is Array and (pair as Array).size() == 2:
		return lerpf(float(pair[0]), float(pair[1]), t)
	return float(pair)


## Level, AI, job, personality and grades make sense.
static func _check_fields(
	out: Dictionary, merged: Dictionary, content: ContentDB, errors: PackedStringArray
) -> void:
	var id := str(out["id"])
	var max_level := int(content.progression.get("max_level", 70))
	if int(out["level"]) < 1 or int(out["level"]) > max_level:
		errors.append("%s: level %d is outside 1..%d" % [id, out["level"], max_level])
	var ai := float(merged.get("ai", 0.0))
	if ai < 0.0 or ai > 1.0:
		errors.append("%s: ai %s is outside 0..1" % [id, str(ai)])
	if not content.jobs.has(str(out["job"])):
		errors.append("%s: unknown job %s" % [id, out["job"]])
	if not (content.arena.get("personalities", {}) as Dictionary).has(str(out["personality"])):
		errors.append("%s: unknown personality %s" % [id, out["personality"]])
	for grade: Variant in merged.get("grades", []):
		if str(grade) not in ContentDB.RARITIES:
			errors.append("%s: unknown grade %s" % [id, grade])


## Fills "slots", "gear" and "plus": every slot's item and upgrade, checked.
static func _fill_gear(
	out: Dictionary,
	merged: Dictionary,
	slot_settings: Dictionary,
	content: ContentDB,
	errors: PackedStringArray
) -> void:
	var id := str(out["id"])
	var level := int(out["level"])
	var top := EnhanceRules.max_level(content)
	var grades: Array = merged.get("grades", ["common"])
	var weights: Dictionary = merged.get("weights", {})
	var plus := _plus_setting(merged.get("plus", 0))
	var slots := {}
	var gear: Array[String] = []
	var by_item := {}
	for slot: String in slot_settings:
		if slot not in PlayerProfile.SLOTS:
			errors.append("%s: unknown slot %s" % [id, slot])
	for i in PlayerProfile.SLOTS.size():
		var slot: String = PlayerProfile.SLOTS[i]
		var setting: Dictionary = slot_settings.get(slot, {})
		for key: String in setting:
			if key not in SLOT_FIELDS and not key.begins_with("_"):
				errors.append("%s.%s: unknown field %s" % [id, slot, key])
		if bool(setting.get("empty", false)):
			continue  # Deliberately nothing worn (a beginner's empty charm slot).
		var allowed: Array = [setting["grade"]] if setting.has("grade") else grades
		var item_id := str(setting.get("item", ""))
		if item_id != "":
			_check_item(id, slot, item_id, level, str(setting.get("grade", "")), content, errors)
		else:
			var slot_weights: Dictionary = weights.duplicate()
			slot_weights.merge(setting.get("weights", {}), true)
			item_id = best_item(content, slot, level, allowed, slot_weights)
			if item_id == "":
				errors.append(
					(
						"%s.%s: no %s item at level %d or under"
						% [id, slot, "/".join(PackedStringArray(allowed)), level]
					)
				)
				continue
		var steps := _slot_plus(plus, i, out["rank"])
		if setting.has("plus"):
			steps = int(setting["plus"])
			if not (setting["plus"] is int or setting["plus"] is float) or steps < 0 or steps > top:
				errors.append(
					"%s.%s: plus %s is outside +0..+%d" % [id, slot, str(setting["plus"]), top]
				)
				steps = clampi(steps, 0, top)
		if steps > top:
			errors.append("%s.%s: plus %d is over the game's +%d" % [id, slot, steps, top])
			steps = top
		if by_item.has(item_id):
			errors.append("%s: %s is worn twice" % [id, item_id])
		by_item[item_id] = steps
		var rarity := str(content.item(item_id).get("rarity", ""))
		slots[slot] = {"item": item_id, "grade": rarity, "plus": steps}
		gear.append(item_id)
	out["slots"] = slots
	out["gear"] = gear
	out["plus"] = by_item


static func _check_item(
	id: String,
	slot: String,
	item_id: String,
	level: int,
	grade: String,
	content: ContentDB,
	errors: PackedStringArray
) -> void:
	var where := "%s.%s" % [id, slot]
	if not content.items.has(item_id):
		errors.append("%s: unknown item %s" % [where, item_id])
		return
	var item := content.item(item_id)
	if item.get("type") != "equipment":
		errors.append("%s: %s is not equipment" % [where, item_id])
	elif str(item.get("slot")) != slot:
		errors.append("%s: %s goes in %s" % [where, item_id, item.get("slot")])
	if int(item.get("level", 1)) > level:
		errors.append(
			"%s: %s needs level %d (rival is %d)" % [where, item_id, item["level"], level]
		)
	if grade != "" and grade not in ContentDB.RARITIES:
		errors.append("%s: unknown grade %s" % [where, grade])
	elif grade != "" and str(item.get("rarity")) != grade:
		errors.append("%s: %s is %s, not %s" % [where, item_id, item.get("rarity"), grade])


## A layer's "plus": a number for every slot, or a tier's {"mix", "lo", "hi"}.
static func _plus_setting(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	var steps := int(value)
	return {"mix": float(steps), "lo": steps, "hi": steps}


## Slot `i`'s upgrade under a ladder-wide setting: the tier's level for this
## rank, spread across slots and kept within the tier's range.
static func _slot_plus(plus: Dictionary, i: int, rank: int) -> int:
	var lo := int(plus.get("lo", 0))
	var hi := int(plus.get("hi", lo))
	var mix := float(plus.get("mix", lo))
	var spread := SLOT_SPREAD[(i + rank) % SLOT_SPREAD.size()] if hi > lo else 0
	return clampi(roundi(mix) + spread, lo, hi)


## What is wrong with the arena's rival configuration: its structure, and
## every rival it makes (each must resolve and its stats compute).
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var spec := content.arena
	if int(spec.get("config_version", 0)) < 1:
		out.append("arena.config_version: a whole number from 1")
	var layers: Array = [spec.get("defaults", {})]
	for name: String in spec.get("presets", {}):
		layers.append(spec["presets"][name])
	layers.append_array(spec.get("rank_overrides", []))
	for id: String in spec.get("opponents", {}):
		layers.append(spec["opponents"][id])
		if not ArenaRules.is_rival(content, id):
			out.append("arena.opponents: %s is no rival on the ladder" % id)
	for layer: Variant in layers:
		if not layer is Dictionary:
			out.append("arena: a layer must be an object")
			continue
		for key: String in layer:
			if key not in FIELDS and key != "ranks" and not key.begins_with("_"):
				out.append("arena: unknown setting %s" % key)
	out.append_array(_tier_problems(spec, ArenaRules.size(content)))
	for name: String in spec.get("personalities", {}):
		var p: Variant = spec["personalities"][name]
		if not p is Dictionary or str(p.get("low_hp", "steady")) not in ArenaBrain.LOW_HP:
			out.append("arena.personalities.%s: low_hp is one of %s" % [name, ArenaBrain.LOW_HP])
	for rank in range(1, ArenaRules.size(content) + 1):
		var data := resolve(content, ArenaRules.rival_id(rank))
		out.append_array(data["errors"])
		if (data["errors"] as PackedStringArray).is_empty():
			var stats := profile(content, data).stats(content)
			if int(stats["max_hp"]) <= 0:
				out.append("%s: its stats do not compute" % data["id"])
	return out


static func _tier_problems(spec: Dictionary, count: int) -> PackedStringArray:
	var out: PackedStringArray = []
	var covered := {}
	for tier: Variant in spec.get("tiers", []):
		if not tier is Dictionary or not _pair(tier.get("ranks")):
			out.append("arena.tiers: each needs ranks [weakest, strongest]")
			continue
		var ranks: Array = tier["ranks"]
		if int(ranks[0]) < int(ranks[1]):
			out.append("arena.tiers.%s: ranks run [weakest, strongest]" % tier.get("id", "?"))
		for rank in range(int(ranks[1]), int(ranks[0]) + 1):
			if covered.has(rank):
				out.append("arena.tiers: rank %d is in two tiers" % rank)
			covered[rank] = true
		for field: String in ["level", "ai", "plus"]:
			if tier.has(field) and not _pair(tier[field]):
				out.append("arena.tiers.%s.%s: [weakest, strongest]" % [tier.get("id", "?"), field])
	for rank in range(1, count + 1):
		if not covered.has(rank):
			out.append("arena.tiers: rank %d is in no tier" % rank)
	return out


static func _pair(value: Variant) -> bool:
	return value is Array and (value as Array).size() == 2
