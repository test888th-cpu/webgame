class_name ArenaScreen
extends RefCounted
## The arena's screens (ArenaFlow): the ladder the arena master shows (your
## rank and combat power, the five rivals you may challenge, each with rank,
## ring name, job, level, combat power against yours and gear, and a Fight
## button) and the result after a match. What they show is the rules'
## (ArenaRules); they decide nothing.

const WIDTH := 600.0
const HEIGHT := 330.0


static func ladder(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var profile := game.profile
	var parts := UiKit.window("Arena Ladder", Vector2(WIDTH, HEIGHT))
	parts["root"].name = "Arena"
	var body: VBoxContainer = parts["body"]
	var arena := ArenaRules.state(profile, content)
	var mine := ArenaRules.rank_of(profile, content)
	var count := ArenaRules.size(content)
	var power := ArenaRules.player_power(profile, content)
	var rank_text := "Unranked (#%d)" % mine if mine > count else "Rank #%d of %d" % [mine, count]
	var best := int(arena["best"])
	var head := UiKit.label(
		(
			"%s   ·   Best #%s   ·   Power %d   ·   %dW %dL"
			% [
				rank_text,
				str(best) if best <= count else "-",
				power,
				int(arena["wins"]),
				int(arena["losses"])
			]
		),
		UiTheme.SIZE_BODY,
		UiTheme.GOLD
	)
	head.name = "Standing"
	body.add_child(head)
	var line := '%s: "%s"' % [npc.get("name", "Arena"), npc.get("line", "")]
	body.add_child(UiKit.label(line, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, WIDTH - 24))
	var list := VBoxContainer.new()
	list.name = "Rivals"
	list.add_theme_constant_override("separation", 3)
	body.add_child(list)
	for id in ArenaRules.choices(profile, content):
		list.add_child(_rival_card(game, id, power))
	if mine == 1:
		body.add_child(
			UiKit.label(
				"You are the champion. Defend your title: wins keep your rank.",
				UiTheme.SIZE_CAPTION,
				UiTheme.TEAL
			)
		)
	var rules := "PvP rules: skills at PvP strength, health x%s, no food. Win: take their rank."
	var note := UiKit.label(
		rules % str(ArenaRules.spec(content)["hp_scale"]), UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT
	)
	body.add_child(note)
	var close := UiKit.button("Not now", game.close_menu)
	close.name = "Close"
	body.add_child(close)
	UiKit.focus_first(list)
	return parts["root"]


## One rival: rank, ring name and job, level, combat power (coloured against
## yours), gear, and Fight.
static func _rival_card(game: Game, id: String, mine: int) -> Control:
	var content := game.content
	var data := ArenaRules.rival(content, id)
	var hero := content.hero(str(data["hero"]))
	var card := PanelContainer.new()
	card.name = "Rival_" + id
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(3)
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var rank := ArenaRules.rank_of(game.profile, content, id)
	var badge := UiKit.label("#%d" % rank, UiTheme.SIZE_H2, UiTheme.ACCENT)
	badge.custom_minimum_size.x = 34
	row.add_child(badge)
	var art := UiKit.portrait(content, str(hero["sprites"]["default"]))
	if art:
		var face := TextureRect.new()
		face.texture = art
		face.custom_minimum_size = Vector2(22, 22)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(face)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiKit.label(str(data["name"]), UiTheme.SIZE_BODY, UiTheme.TEXT))
	var job := str(hero["title"]).trim_prefix("The ")
	var facts := "%s  ·  Lv %d  ·  %s" % [job, int(data["level"]), _gear_text(content, data)]
	text.add_child(UiKit.label(facts, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	var power := ArenaRules.rival_power(content, id)
	var color := UiTheme.TEAL
	if power > mine * 1.15:
		color = UiTheme.DANGER
	elif power > mine * 0.95:
		color = UiTheme.GOLD
	var shown := UiKit.label("Power %d" % power, UiTheme.SIZE_SMALL, color)
	shown.name = "Power"
	shown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(shown)
	var fight := UiKit.button("Fight", game.arena.start.bind(id))
	fight.name = "Fight"
	fight.custom_minimum_size.x = 48
	row.add_child(fight)
	return card


## "Top gear +5" or the grades worn, short.
static func _gear_text(content: ContentDB, data: Dictionary) -> String:
	var grades := {}
	var plus := 0
	for item_id: String in data["gear"]:
		grades[str(content.item(item_id).get("rarity", ""))] = true
		plus = maxi(plus, int(data["plus"][item_id]))
	var best := ""
	for rarity: String in ContentDB.RARITIES:
		if grades.has(rarity):
			best = rarity
	var text := "%s gear" % best.capitalize()
	return text + (" up to +%d" % plus if plus > 0 else "")


## After a match: won or lost, the rank change, any reward, and back to the
## ladder (or out to the city).
static func result(game: Game, data: Dictionary) -> Control:
	var won := bool(data["won"])
	var parts := UiKit.dialog("VICTORY!" if won else "DEFEAT", null)
	parts["root"].name = "ArenaResult"
	var body: VBoxContainer = parts["body"]
	var how := "Knock-out" if str(data.get("reason", "")) == "ko" else "Time up"
	var text := "%s against %s." % [how, data.get("name", "")]
	var old := int(data["old_rank"])
	var new := int(data["new_rank"])
	if new < old:
		text += "  Rank #%d -> #%d." % [old, new]
	elif won:
		text += "  Your rank holds at #%d." % new
	else:
		text += "  Your rank stays #%d. Try another rival, or gear up." % old
	var said := UiKit.label(text, UiTheme.SIZE_BODY, UiTheme.TEXT, 470)
	said.name = "Outcome"
	body.add_child(said)
	if bool(data.get("new_best", false)):
		body.add_child(UiKit.label("New best rank!", UiTheme.SIZE_BODY, UiTheme.GOLD))
	if int(data.get("money", 0)) > 0:
		var paid := UiKit.label(
			"Ladder reward: %d coins." % int(data["money"]), UiTheme.SIZE_BODY, UiTheme.GOLD
		)
		body.add_child(paid)
	var again := UiKit.button("Back to the ladder", game.arena.leave)
	again.name = "Again"
	body.add_child(again)
	body.add_child(UiKit.button("Leave the arena", game.arena.leave.bind(true)))
	UiKit.focus_first(body)
	return parts["root"]
