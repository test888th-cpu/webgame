class_name GuidePages
extends RefCounted
## The Guide's lists and pages (GuideScreen). Every fact comes from the game's
## data through LootIndex (drops, places, kinds) and the rule classes (levels,
## health, item cards): nothing is typed in here, so a change to the data
## shows here at once. Names on a page are links (GuideScreen.open).
## Drop chances show as the real chance per kill, or, when progression.json
## "show_drop_rates" is false, as a rarity word worked out from that chance
## (LootIndex.rarity); a selection weight is never shown as a chance.

const KIND_NAMES := {
	LootIndex.MONSTER: "Monster",
	LootIndex.ELITE: "Elite",
	LootIndex.MINI_BOSS: "Mini-boss",
	LootIndex.STAGE_BOSS: "Stage boss",
	LootIndex.WORLD_BOSS: "World boss",
	LootIndex.RAID_BOSS: "Raid world boss",
}
const HOW := {
	"loot": "own drops",
	"catalog": "drop table",
	"boss_list": "boss prize",
	"ground": "ground prize",
	"elite": "field elite",
	"tier": "personal tier",
	"kill": "kill reward",
}
const PLACE_KINDS := [
	["All maps", ""],
	["Story streets", "street"],
	["Towns", "town"],
	["Farming grounds", "farm"],
	["Lairs", "lair"],
	["World boss arenas", "world_boss"],
]
const CATEGORY_NAMES := {
	"weapon": "Weapons",
	"headgear": "Headgear",
	"outfit": "Outfits",
	"accessory": "Accessories",
	"enhancement_material": "Enhancement Materials",
	"ore": "Ores & Minerals",
	"consumable": "Consumables",
	"boss_material": "Boss Materials",
	"special": "Special Items",
}


## The Guide's own item categories: the catalog's, with hands, feet and
## charms as accessories and story evidence as special.
static func category(content: ContentDB, item_id: String) -> String:
	var item := content.item(item_id)
	if item.get("type") == "equipment" and item.get("slot") in ["hands", "feet", "charm"]:
		return "accessory"
	return ItemCatalog.category(item)


## A tab's filter choices: [[label, value], ...], "All" first.
static func filters(content: ContentDB, tab: String) -> Array:
	match tab:
		"items":
			var out := [["All items", ""]]
			for cat: String in CATEGORY_NAMES:
				out.append([CATEGORY_NAMES[cat], "cat:" + cat])
			for grade: String in ContentDB.RARITIES:
				out.append([grade.capitalize() + " grade", "grade:" + grade])
			return out
		"monsters":
			return (
				[["All monsters", ""], ["Elites", "elite"], ["Ordinary", "monster"]]
				+ _map_filters(content)
			)
		"bosses":
			var out := [["All bosses", ""]]
			for kind: String in LootIndex.BOSSES:
				out.append([KIND_NAMES[kind], kind])
			return out
	return PLACE_KINDS.duplicate()


static func _map_filters(content: ContentDB) -> Array:
	var out := []
	for area_id: String in content.areas:
		out.append(["In " + str(content.area(area_id).get("name", area_id)), "map:" + area_id])
	return out


## What kind of place `area_id` is: "town", "farm", "lair", "world_boss",
## "arena" or "street".
static func place_kind(content: ContentDB, area_id: String) -> String:
	var area := content.area(area_id)
	if area.get("world_boss", false):
		return "world_boss"
	if area.get("arena", false):
		return "arena"
	if str(area.get("kind", "")) in ["farm", "lair"]:
		return str(area["kind"])
	return "town" if area.get("safe", false) else "street"


## The ids a tab lists for `search` (names, and for enemies the maps they
## fight in), `filter` and `sort`.
static func entries(
	content: ContentDB, tab: String, search: String, filter: String, sort: String
) -> Array:
	var ids: Array = []
	var needle := search.strip_edges().to_lower()
	match tab:
		"items":
			for id: String in content.items:
				var item := content.item(id)
				if (
					filter.begins_with("cat:")
					and category(content, id) != filter.trim_prefix("cat:")
				):
					continue
				if (
					filter.begins_with("grade:")
					and item.get("rarity") != filter.trim_prefix("grade:")
				):
					continue
				if needle == "" or needle in str(item.get("name", id)).to_lower() or needle in id:
					ids.append(id)
		"monsters", "bosses":
			for id: String in content.enemies:
				var kind := LootIndex.kind_of(content, id)
				var boss := kind in LootIndex.BOSSES
				if kind == LootIndex.TRAINING or boss != (tab == "bosses"):
					continue
				if filter.begins_with("map:"):
					var at := filter.trim_prefix("map:")
					if not LootIndex.places(content, id).any(
						func(p: Dictionary) -> bool: return p["area"] == at
					):
						continue
				elif filter != "" and kind != filter:
					continue
				if needle == "" or _enemy_matches(content, id, needle):
					ids.append(id)
		"maps":
			for id: String in content.areas:
				var kind := place_kind(content, id)
				if kind == "arena" or (filter != "" and kind != filter):
					continue
				if needle == "" or needle in str(content.area(id).get("name", id)).to_lower():
					ids.append(id)
	# Each entry's sort key worked out once, not on every comparison.
	var keys := {}
	for id: String in ids:
		keys[id] = _key(content, tab, id, sort)
	ids.sort_custom(func(a: String, b: String) -> bool: return keys[a] < keys[b])
	return ids


static func _enemy_matches(content: ContentDB, id: String, needle: String) -> bool:
	if needle in str(content.enemy(id).get("name", id)).to_lower():
		return true
	for place: Dictionary in LootIndex.places(content, id):
		if needle in str(content.area(str(place["area"])).get("name", "")).to_lower():
			return true
	return false


static func _key(content: ContentDB, tab: String, id: String, sort: String) -> Array:
	var name := _name(content, tab, id)
	match sort:
		"grade":
			return [-ItemText.grade_rank(content.item(id)), name]
		"level":
			return [_level(content, tab, id), name]
	return [name]


static func _name(content: ContentDB, tab: String, id: String) -> String:
	match tab:
		"items":
			return str(content.item(id).get("name", id))
		"maps":
			return str(content.area(id).get("name", id))
	return str(content.enemy(id).get("name", id))


static func _level(content: ContentDB, tab: String, id: String) -> int:
	match tab:
		"items":
			return int(content.item(id).get("level", 0))
		"maps":
			return int(content.area(id).get("level", 0))
	var levels := enemy_levels(content, id)
	return levels[0] if not levels.is_empty() else 999


## The levels `enemy_id` fights at, lowest first: its area's level, a boss
## a little above (LevelRules), a world boss its own.
static func enemy_levels(content: ContentDB, enemy_id: String) -> Array[int]:
	var out: Array[int] = []
	var world := LootIndex.world_boss_of(content, enemy_id)
	if world != "":
		out.append(int(content.world_bosses[world].get("level", 1)))
		return out
	for place: Dictionary in LootIndex.places(content, enemy_id):
		var area_level := int(content.area(str(place["area"])).get("level", 1))
		var level := LevelRules.enemy_level(content.enemy(enemy_id), area_level)
		if level not in out:
			out.append(level)
	out.sort()
	return out


## A list row: [text, icon or null, colour].
static func row(content: ContentDB, tab: String, id: String) -> Array:
	match tab:
		"items":
			var item := content.item(id)
			return [
				str(item.get("name", id)),
				UiKit.icon(content, str(item.get("icon", ""))),
				ItemText.rarity_color(item)
			]
		"maps":
			var area := content.area(id)
			return [
				"%s  Lv %d" % [area.get("name", id), int(area.get("level", 0))], null, UiTheme.TEXT
			]
	var levels := enemy_levels(content, id)
	var level := ("  Lv %d" % levels[0]) if not levels.is_empty() else ""
	var kind := LootIndex.kind_of(content, id)
	var color := UiTheme.GOLD if kind == LootIndex.ELITE else UiTheme.TEXT
	if kind in [LootIndex.WORLD_BOSS, LootIndex.RAID_BOSS]:
		color = UiTheme.DANGER
	return [str(content.enemy(id).get("name", id)) + level, null, color]


## How a chance reads: the exact chance per kill, or (rates hidden) a word.
static func chance_text(content: ContentDB, drop: Dictionary) -> String:
	if drop.get("guaranteed", false):
		return "guaranteed"
	var chance := float(drop["chance"])
	if bool(content.progression.get("show_drop_rates", true)):
		return LootIndex.percent_text(chance)
	return LootIndex.rarity(chance)


## One drop as a player reads it: its chance per kill (or "guaranteed"), how
## many, whether it is guaranteed, random or conditional (on being a field
## elite, dealing a share of a world boss, the kill), a catalog value marked
## initial, and where it comes from.
static func drop_text(content: ContentDB, drop: Dictionary) -> String:
	var bits: Array[String] = [chance_text(content, drop), _quantity(drop)]
	var type := LootIndex.reward_type(drop)
	if type != LootIndex.GUARANTEED:
		bits.append(type)
	if drop.get("pity", false):
		bits.append("(rises)")
	bits.append(HOW.get(drop["how"], drop["how"]))
	var said := " ".join(bits.filter(func(b: String) -> bool: return b != ""))
	return said + ("*" if LootIndex.data_status(drop) == LootIndex.INITIAL else "")


## The note for the "*" on initial values, once under a list that has one.
static func _initial_note(box: VBoxContainer, drops: Array) -> void:
	if drops.any(func(d: Dictionary) -> bool: return LootIndex.data_status(d) == LootIndex.INITIAL):
		box.add_child(_text("* initial balance value, not yet playtested", UiTheme.TEXT_FAINT))


## Writes page `id` of `tab` into `box`.
static func page(guide: GuideScreen, tab: String, id: String, box: VBoxContainer) -> void:
	match tab:
		"items":
			_item(guide, id, box)
		"maps":
			_map(guide, id, box)
		_:
			_enemy(guide, id, box)


static func _item(guide: GuideScreen, id: String, box: VBoxContainer) -> void:
	var content := guide.content
	var item := content.item(id)
	box.add_child(ItemCard.details(content, guide.game.profile, id, "", true, false))
	var facts: Array[String] = [CATEGORY_NAMES.get(category(content, id), "Item")]
	if item.get("type") == "equipment":
		facts.append(
			"can be upgraded at the workbench (+0 to +%d)" % EnhanceRules.max_level(content)
		)
	elif item.get("type") in ["consumable", "material"]:
		facts.append("stacks to %d" % ShopRules.MAX_AMOUNT)
	if item.has("counts_as"):
		for material: String in item["counts_as"]:
			facts.append(
				(
					"counts as %d %s at the workbench"
					% [item["counts_as"][material], content.item(material).get("name", material)]
				)
			)
	box.add_child(_text(", ".join(facts), UiTheme.TEXT_DIM))
	_heading(box, "WHERE TO OBTAIN")
	var found := LootIndex.sources(content, id)
	if found.is_empty():
		box.add_child(_text("Not currently obtainable.", UiTheme.TEXT_FAINT))
	for source: Dictionary in found:
		match source["kind"]:
			"enemy":
				_source_line(guide, source, box)
			"shop":
				box.add_child(
					_text(
						"%s, %d coins" % [content.shops[source["id"]]["name"], source["price"]],
						UiTheme.TEXT
					)
				)
			"quest":
				box.add_child(
					_text('Quest reward: "%s"' % content.quests[source["id"]]["name"], UiTheme.TEXT)
				)
	_initial_note(box, found)


static func _source_line(guide: GuideScreen, source: Dictionary, box: VBoxContainer) -> void:
	var content := guide.content
	var enemy_id := str(source["id"])
	var boss := LootIndex.kind_of(content, enemy_id) in LootIndex.BOSSES
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 3)
	line.add_child(
		_link(
			str(content.enemy(enemy_id).get("name", enemy_id)),
			guide.open.bind("bosses" if boss else "monsters", enemy_id)
		)
	)
	var said := _text(drop_text(content, source), UiTheme.TEXT_DIM)
	if source["area"]:
		said.text += " in"
		said.size_flags_horizontal = Control.SIZE_FILL  # the map link follows it
	line.add_child(said)
	if source["area"]:
		line.add_child(
			_link(
				str(content.area(str(source["area"])).get("name", "")),
				guide.open.bind("maps", str(source["area"]))
			)
		)
	box.add_child(line)
	if source["condition"]:
		box.add_child(_text("    " + str(source["condition"]), UiTheme.TEXT_FAINT))


static func _enemy(guide: GuideScreen, id: String, box: VBoxContainer) -> void:
	var content := guide.content
	var enemy := content.enemy(id)
	var kind := LootIndex.kind_of(content, id)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var art := UiKit.portrait(content, str(enemy.get("sprite", "")))
	if art:
		var face := TextureRect.new()
		face.texture = art
		face.custom_minimum_size = Vector2(28, 28)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(face)
	var levels := enemy_levels(content, id)
	var level_text := (
		"Lv " + "/".join(levels.map(func(l: int) -> String: return str(l)))
		if levels
		else "Level varies"
	)
	head.add_child(
		UiKit.label(
			"%s\n%s  ·  %s" % [enemy.get("name", id), KIND_NAMES.get(kind, kind), level_text],
			UiTheme.SIZE_BODY,
			UiTheme.ACCENT
		)
	)
	box.add_child(head)
	if not levels.is_empty():
		var hp := int(LevelRules.enemy_stats(enemy, levels[0])["max_hp"])
		box.add_child(_text("Health %d at Lv %d" % [hp, levels[0]], UiTheme.TEXT_DIM))
	_heading(box, "WHERE IT FIGHTS")
	var places := LootIndex.places(content, id)
	if places.is_empty():
		var by := _summoned_by(content, id)
		box.add_child(
			_text("Called in by " + by if by else "Location unknown.", UiTheme.TEXT_FAINT)
		)
	for place: Dictionary in places:
		var line := HBoxContainer.new()
		line.add_child(
			_link(
				str(content.area(str(place["area"])).get("name", place["area"])),
				guide.open.bind("maps", str(place["area"]))
			)
		)
		line.add_child(
			_text(
				(
					{
						"street": "on the street",
						"farm": "farming ground",
						"lair": "lair",
						"world_boss": "its arena"
					}
					. get(place["how"], "")
				),
				UiTheme.TEXT_DIM
			)
		)
		box.add_child(line)
	if kind in [LootIndex.WORLD_BOSS, LootIndex.RAID_BOSS]:
		box.add_child(
			_text(
				"Rewards are paid only if it falls within its round, to everyone who fought it.",
				UiTheme.TEXT_FAINT
			)
		)
	_heading(box, "REWARDS" if kind in LootIndex.BOSSES else "DROPS")
	var money: Array = enemy.get("loot", {}).get("money", [0, 0])
	box.add_child(_text("Coins %d to %d" % [int(money[0]), int(money[1])], UiTheme.GOLD))
	for drop: Dictionary in LootIndex.known_drops(content, id):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 3)
		var item := content.item(str(drop["item"]))
		var link := _link(
			str(item.get("name", drop["item"])), guide.open.bind("items", str(drop["item"]))
		)
		link.add_theme_color_override("font_color", ItemText.rarity_color(item))
		line.add_child(link)
		var said := drop_text(content, drop)
		if drop["area"]:
			said += " in " + str(content.area(str(drop["area"])).get("name", ""))
		line.add_child(_text(said, UiTheme.TEXT_DIM))
		box.add_child(line)
		if drop["condition"]:
			box.add_child(_text("    " + str(drop["condition"]), UiTheme.TEXT_FAINT))
	_initial_note(box, LootIndex.known_drops(content, id))


static func _summoned_by(content: ContentDB, id: String) -> String:
	for boss: String in content.enemies:
		var data := content.enemy(boss)
		for key: String in ["summon", "elite_summon"]:
			if str(data.get(key, {}).get("enemy", "")) == id:
				return str(data.get("name", boss))
	return ""


static func _map(guide: GuideScreen, id: String, box: VBoxContainer) -> void:
	var content := guide.content
	var area := content.area(id)
	var kind := place_kind(content, id)
	var kinds := {
		"street": "Story street",
		"town": "Town",
		"farm": "Farming ground",
		"lair": "Lair",
		"world_boss": "World boss arena"
	}
	box.add_child(UiKit.label(str(area.get("name", id)), UiTheme.SIZE_H2, UiTheme.ACCENT))
	var spot := MapRules.locate(content, id)
	var where := (
		("  ·  %s %d/%d" % [spot["name"], int(spot["index"]) + 1, spot["count"]]) if spot else ""
	)
	box.add_child(
		_text(
			"%s  ·  Lv %d%s" % [kinds.get(kind, kind), int(area.get("level", 0)), where],
			UiTheme.TEXT_DIM
		)
	)
	var info := LootIndex.area_info(content, id)
	for group: Array in [["MONSTERS HERE", false], ["BOSSES HERE", true]]:
		var here: Array = info["enemies"].filter(
			func(e: Dictionary) -> bool: return (e["kind"] in LootIndex.BOSSES) == group[1]
		)
		if here.is_empty():
			continue
		_heading(box, str(group[0]))
		for entry: Dictionary in here:
			var name := str(content.enemy(str(entry["id"])).get("name", entry["id"]))
			box.add_child(
				_link(name, guide.open.bind("bosses" if group[1] else "monsters", str(entry["id"])))
			)
	var items: Dictionary = info["items"]
	if items.is_empty():
		box.add_child(_text("No one to fight here.", UiTheme.TEXT_FAINT))
		return
	_heading(box, "WHAT YOU CAN FARM HERE")
	var ids: Array = items.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return items[a] > items[b])
	for item_id: String in ids:
		var item := content.item(item_id)
		var line := HBoxContainer.new()
		var link := _link(str(item.get("name", item_id)), guide.open.bind("items", item_id))
		link.add_theme_color_override("font_color", ItemText.rarity_color(item))
		line.add_child(link)
		line.add_child(
			_text(
				(
					"best "
					+ chance_text(
						content, {"chance": items[item_id], "guaranteed": items[item_id] >= 1.0}
					)
				),
				UiTheme.TEXT_DIM
			)
		)
		box.add_child(line)


static func _quantity(drop: Dictionary) -> String:
	var span: Array = drop.get("quantity", [1, 1])
	if span[0] == span[1]:
		return "" if span[0] == 1 else "x%d" % span[0]
	return "x%d-%d" % [span[0], span[1]]


static func _heading(box: VBoxContainer, text: String) -> void:
	box.add_child(UiKit.label(text, UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT))


static func _text(text: String, color: Color) -> Label:
	var label := UiKit.label(text, UiTheme.SIZE_SMALL, color)
	# Fills what is left of a line after its links (clipped, never squeezed
	# to nothing).
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = minf(40.0, label.get_minimum_size().x)
	return label


static func _link(text: String, go: Callable) -> LinkButton:
	var link := LinkButton.new()
	link.text = text
	link.focus_mode = Control.FOCUS_NONE
	link.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	link.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	link.add_theme_color_override("font_color", UiTheme.TEAL)
	link.pressed.connect(go)
	return link
