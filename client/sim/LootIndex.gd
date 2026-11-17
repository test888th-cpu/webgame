class_name LootIndex
extends RefCounted
## One index over every way an item reaches a player, built from the very
## rules that pay it, so a guide or report can never disagree with the game:
## * an enemy's own loot table (enemies.json "loot", LootRules: each drop an
##   independent roll per kill, chance 1.0 guaranteed, "pity" ones rising);
## * the item catalog's drop tables (DropTables: a chance per roll, then a
##   category, a grade and an item, and a boss's own list);
## * a farming ground (FarmSpawner): its enemies' loot at the ground's
##   "reward_scale", its own "drops" at full chance, and a field elite's
##   ELITE_REWARD rolls of its loot plus one of the ground's "elite_drops";
## * a world boss (world_boss.json): personal tiers (a share of one player's
##   part of the pool dealt) and the kill, paid only when the boss falls in
##   its round;
## * shops and quest rewards.
## Every chance here is the real chance per kill (or per reward), worked out,
## never rolled. Where a drop goes through selection steps, "steps" gives
## each conditional share separately (a category weight is not a drop
## chance). Pure rules, shared with the server.

const MONSTER := "monster"
const ELITE := "elite"
const MINI_BOSS := "mini_boss"
const STAGE_BOSS := "stage_boss"
const WORLD_BOSS := "world_boss"
const RAID_BOSS := "raid_world_boss"
const TRAINING := "training"
## Kinds that are bosses (their rewards are listed apart from monsters').
const BOSSES: Array[String] = [MINI_BOSS, STAGE_BOSS, WORLD_BOSS, RAID_BOSS]

## A drop's kind of certainty (reward_type).
const GUARANTEED := "guaranteed"
const RANDOM := "random"
const CONDITIONAL := "conditional"
## Where a drop's numbers stand (data_status): the game's own values, or the
## catalog's initial balance values, not yet playtested.
const CONFIRMED := "confirmed"
const INITIAL := "initial"
## Drops paid only on a condition: being a field elite, dealing a share of a
## world boss's health, the world boss falling.
const CONDITIONAL_HOW: Array[String] = ["elite", "tier", "kill"]

## Words for a chance per kill, from the most likely down (rarity()).
const RARITY_WORDS := [
	[1.0, "guaranteed"],
	[0.25, "common"],
	[0.05, "uncommon"],
	[0.01, "rare"],
	[0.001, "very rare"],
]

## Every enemy's drops by item, for sources(): {"key", "by_item"}.
static var _index := {}


## What `enemy_id` is: one of the kinds above.
static func kind_of(content: ContentDB, enemy_id: String) -> String:
	var enemy := content.enemy(enemy_id)
	if enemy.get("training", false):
		return TRAINING
	var world := world_boss_of(content, enemy_id)
	if world != "":
		return RAID_BOSS if content.world_bosses[world].get("raid", false) else WORLD_BOSS
	if enemy.get("boss", false):
		for area_id: String in content.areas:
			if str(content.areas[area_id].get("mini_boss", "")) == enemy_id:
				return MINI_BOSS
		return STAGE_BOSS
	return ELITE if enemy.get("elite", false) else MONSTER


## The world boss `enemy_id` is (its world_boss.json id), or "".
static func world_boss_of(content: ContentDB, enemy_id: String) -> String:
	for boss: String in content.world_bosses:
		if str(content.world_bosses[boss].get("enemy", "")) == enemy_id:
			return boss
	return ""


## Where `enemy_id` fights: [{"area", "how"}], "how" one of "street"
## (placed or in a fight), "farm" (a farming ground's field), "lair" (a
## lair's mini-boss), "world_boss" (its arena). Empty when it fights nowhere.
static func places(content: ContentDB, enemy_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for area_id: String in content.areas:
		var area: Dictionary = content.areas[area_id]
		var how := ""
		for placed: Dictionary in area.get("placed", []):
			how = "street" if placed.get("enemy") == enemy_id else how
		for encounter: Dictionary in area.get("encounters", []):
			for wave: Variant in encounter.get("waves", []):
				how = "street" if enemy_id in (wave as Array) else how
		if area.get("spawning", {}).get("pool", {}).has(enemy_id):
			how = "farm"
		if str(area.get("mini_boss", "")) == enemy_id:
			how = "lair"
		var world := world_boss_of(content, enemy_id)
		if world != "" and str(content.world_bosses[world].get("area", "")) == area_id:
			how = "world_boss"
		if how != "":
			out.append({"area": area_id, "how": how})
	return out


## Everything a kill of `enemy_id` can give, in each place it fights:
## [{"item", "chance" (per kill, 0..1), "quantity": [min, max],
##   "guaranteed": bool, "how", "area" ("" for anywhere it fights),
##   "condition" (a plain sentence, "" for none), "steps" (the conditional
##   shares of a selected drop, or {}), "pity": bool}].
## "how": "loot" (its own table), "catalog" (the catalog's table),
## "boss_list" (a boss's own catalog list), "ground" / "elite" (a farming
## ground's), "tier" / "kill" (a world boss's rewards).
static func drops(content: ContentDB, enemy_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var enemy := content.enemy(enemy_id)
	if enemy.is_empty() or enemy.get("training", false):
		return out
	var where := places(content, enemy_id)
	var hows := where.map(func(p: Dictionary) -> String: return p["how"])
	# Its own table at full chance on the street, in a lair and in a world
	# boss's arena (a farming ground scales it, below); the catalog's
	# everywhere but a world boss's arena (DropTables.roll).
	if where.is_empty() or hows.any(func(h: String) -> bool: return h != "farm"):
		out.append_array(_loot(enemy, 1.0, "", "loot"))
	if where.is_empty() or hows.any(func(h: String) -> bool: return h != "world_boss"):
		out.append_array(_catalog(content, enemy_id))
	for place: Dictionary in where:
		if place["how"] == "farm":
			out.append_array(_farm(content, enemy_id, str(place["area"])))
	var world := world_boss_of(content, enemy_id)
	if world != "":
		out.append_array(_world(content, world))
	return out


## The enemy's own loot table at `scale` of its chances.
static func _loot(enemy: Dictionary, scale: float, area: String, how: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for drop: Dictionary in enemy.get("loot", {}).get("drops", []):
		var chance := minf(1.0, float(drop["chance"]) * scale)
		var pity: bool = drop.get("pity", false)
		out.append(
			_entry(
				str(drop["item"]),
				chance,
				[1, 1],
				how,
				area,
				(
					(
						"rises after each kill without one (up to %d%%)"
						% roundi(LootRules.PITY_CAP * 100)
					)
					if pity
					else ""
				),
				{},
				pity
			)
		)
	return out


## The catalog's drops for a kill (not in a world boss arena).
static func _catalog(content: ContentDB, enemy_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if content.catalog == null:
		return out
	var table := DropTables.table_for(content, enemy_id)
	if not table.is_empty():
		var source := str(table.get("source", "monster"))
		var cats: Dictionary = table.get("categories", {})
		var cat_total := DropTables._total(cats)
		var per_kill := DropTables.table_chances(content, table)
		for cat: String in cats:
			var pool := DropTables.pool_for(content, cat, source)
			var grades := DropTables.grade_weights(content, source, pool)
			var grade_total := DropTables._total(grades)
			var span: Array = table.get("quantity", {}).get(cat, [1, 1])
			for grade: String in grades:
				for item_id: String in pool[grade]:
					var steps := {
						"roll_chance": float(table.get("chance", 0.0)),
						"rolls": int(table.get("rolls", 1)),
						"category": cat,
						"category_share": float(cats[cat]) / cat_total,
						"grade": grade,
						"grade_share": float(grades[grade]) / grade_total,
						"item_share": 1.0 / pool[grade].size(),
					}
					var chance := float(per_kill.get(item_id, 0.0))
					out.append(_entry(item_id, chance, span, "catalog", "", "", steps, false))
	if content.enemy(enemy_id).get("boss", false):
		for entry: Dictionary in content.catalog.drops.get("bosses", {}).get(enemy_id, []):
			var span: Array = entry.get("quantity", [1, 1])
			var item_id := str(entry["item"])
			out.append(
				_entry(item_id, float(entry["chance"]), span, "boss_list", "", "", {}, false)
			)
	return out


## A farming ground's kill of `enemy_id`: its loot at the ground's reward
## scale and the ground's own drops; as a field elite, its loot rolled
## ELITE_REWARD times and one roll of the ground's elite prizes.
static func _farm(content: ContentDB, enemy_id: String, area_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var spawning: Dictionary = content.area(area_id).get("spawning", {})
	var scale := float(spawning.get("reward_scale", 1.0))
	out.append_array(_loot(content.enemy(enemy_id), scale, area_id, "loot"))
	for drop: Dictionary in spawning.get("drops", []):
		out.append(
			_entry(
				str(drop["item"]), float(drop["chance"]), [1, 1], "ground", area_id, "", {}, false
			)
		)
	var elite_chance := float(spawning.get("elite_chance", 0.0))
	if elite_chance > 0.0:
		var rolls := roundi(FarmSpawner.ELITE_REWARD)
		var said := "when it comes as a field elite (%s of spawns)" % _percent(elite_chance)
		for drop: Dictionary in content.enemy(enemy_id).get("loot", {}).get("drops", []):
			var one := minf(1.0, float(drop["chance"]) * scale)
			var chance := 1.0 - pow(1.0 - one, rolls)
			out.append(
				_entry(str(drop["item"]), chance, [1, rolls], "elite", area_id, said, {}, false)
			)
		for drop: Dictionary in spawning.get("elite_drops", []):
			var item_id := str(drop["item"])
			out.append(
				_entry(item_id, float(drop["chance"]), [1, 1], "elite", area_id, said, {}, false)
			)
	return out


## A world boss's rewards: each personal tier (paid to whoever dealt that
## share of one player's part of the pool) and the kill; only when the boss
## falls within its round.
static func _world(content: ContentDB, boss: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var spec: Dictionary = content.world_bosses[boss]
	var area := str(spec.get("area", ""))
	var paid := "paid only if the boss falls within its round"
	var rewards: Array = []
	for tier: Dictionary in spec.get("tiers", []):
		var share := roundi(float(tier.get("share", 0.0)) * 100)
		rewards.append(
			[tier, "tier", "dealing %d%% of one player's share of its health, %s" % [share, paid]]
		)
	rewards.append(
		[spec.get("kill", {}), "kill", "to everyone who fought it when it falls, %s" % paid]
	)
	for reward: Array in rewards:
		var data: Dictionary = reward[0]
		for item_id: String in data.get("items", {}):
			var n := int(data["items"][item_id])
			out.append(
				_entry(item_id, 1.0, [n, n], str(reward[1]), area, str(reward[2]), {}, false)
			)
		for item_id: String in data.get("rolls", {}):
			var chance := float(data["rolls"][item_id])
			out.append(
				_entry(item_id, chance, [1, 1], str(reward[1]), area, str(reward[2]), {}, false)
			)
	return out


static func _entry(
	item_id: String,
	chance: float,
	quantity: Array,
	how: String,
	area: String,
	condition: String,
	steps: Dictionary,
	pity: bool
) -> Dictionary:
	return {
		"item": item_id,
		"chance": chance,
		"quantity": [int(quantity[0]), int(quantity[1])],
		"guaranteed": chance >= 1.0,
		"how": how,
		"area": area,
		"condition": condition,
		"steps": steps,
		"pity": pity,
	}


## Every source of `item_id`: [{"kind": "enemy" | "shop" | "quest", "id",
## and for an enemy the drops() entry fields}], enemies first by chance.
## Read from an index of every enemy's drops, built once per content (and
## rebuilt when its items, enemies or tables change size).
static func sources(content: ContentDB, item_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for found: Dictionary in _by_item(content).get(item_id, []):
		out.append(found.duplicate())
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["chance"] > b["chance"])
	for shop_id: String in content.shops:
		if item_id in ShopRules.all_items(content.shops[shop_id]):
			var price := ShopRules.buy_price(content, shop_id, item_id)
			out.append({"kind": "shop", "id": shop_id, "price": price})
	for quest_id: String in content.quests:
		var given: Dictionary = content.quests[quest_id].get("rewards", {}).get("items", {})
		if given.has(item_id):
			out.append(
				{"kind": "quest", "id": quest_id, "quantity": [given[item_id], given[item_id]]}
			)
	return out


static func _by_item(content: ContentDB) -> Dictionary:
	var key := (
		"%d|%d|%d|%s"
		% [
			content.get_instance_id(),
			content.items.size(),
			content.enemies.size(),
			hash(content.catalog.drops) if content.catalog else 0,
		]
	)
	if _index.get("key", "") != key:
		var by_item := {}
		var by_enemy := {}
		for enemy_id: String in content.enemies:
			by_enemy[enemy_id] = drops(content, enemy_id)
			for drop: Dictionary in by_enemy[enemy_id]:
				var found := drop.duplicate()
				found["kind"] = "enemy"
				found["id"] = enemy_id
				if not by_item.has(drop["item"]):
					by_item[drop["item"]] = []
				by_item[drop["item"]].append(found)
		_index = {"key": key, "by_item": by_item, "by_enemy": by_enemy}
	return _index["by_item"]


## drops(), read from the same index as sources() (for pages that list many).
static func known_drops(content: ContentDB, enemy_id: String) -> Array:
	_by_item(content)
	return _index["by_enemy"].get(enemy_id, [])


## What area `area_id` holds: {"enemies": [{"id", "kind", "how"}], "items":
## {item id: best chance per kill there}}.
static func area_info(content: ContentDB, area_id: String) -> Dictionary:
	var enemies: Array[Dictionary] = []
	var items := {}
	for enemy_id: String in content.enemies:
		for place: Dictionary in places(content, enemy_id):
			if place["area"] != area_id:
				continue
			enemies.append(
				{"id": enemy_id, "kind": kind_of(content, enemy_id), "how": place["how"]}
			)
			for drop: Dictionary in known_drops(content, enemy_id):
				if drop["area"] in ["", area_id]:
					items[drop["item"]] = maxf(float(items.get(drop["item"], 0.0)), drop["chance"])
	return {"enemies": enemies, "items": items}


## Whether `drop` (a drops() entry) is guaranteed, random, or conditional on
## something beyond the kill (being a field elite, a world boss share).
static func reward_type(drop: Dictionary) -> String:
	if str(drop.get("how", "")) in CONDITIONAL_HOW:
		return CONDITIONAL
	return GUARANTEED if drop.get("guaranteed", false) else RANDOM


## Whether `drop`'s numbers are the game's own (confirmed) or the item
## catalog's initial balance values (drop_tables.json, not yet playtested).
static func data_status(drop: Dictionary) -> String:
	return INITIAL if str(drop.get("how", "")) in ["catalog", "boss_list"] else CONFIRMED


## A chance as a percentage, with as many places as it needs to be honest.
static func percent_text(chance: float) -> String:
	var value := chance * 100.0
	if value >= 10.0:
		return "%s%%" % String.num(value, 1)
	if value >= 0.01:
		return "%s%%" % String.num(value, 3)
	return "%s%%" % String.num(value, 5)


## A chance in words, for when exact rates are not shown (progression.json
## "show_drop_rates" false): worked out from the real chance, never guessed.
static func rarity(chance: float) -> String:
	for step: Array in RARITY_WORDS:
		if chance >= float(step[0]):
			return str(step[1])
	return "extremely rare"


static func _percent(chance: float) -> String:
	var percent := chance * 100.0
	return "%d%%" % roundi(percent) if percent >= 1.0 else "%s%%" % String.num(percent, 2)
