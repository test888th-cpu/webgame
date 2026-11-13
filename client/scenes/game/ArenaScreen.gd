class_name ArenaScreen
extends RefCounted
## The arena's screens (ArenaFlow), all showing what the rules decide:
## - the ladder: the player's standing (rank, best, wins, losses, draws, win
##   rate, power) and the champion, and the five rivals offered, each with
##   rank, job, level, gear grade and highest upgrade, power, AI level and a
##   difficulty label, opening its details; "New rivals" and "Not now";
## - a rival's details: gear by slot with grade and upgrade, personality, AI
##   level and reaction time, power against the player's, and the challenge
##   (Challenge or Back);
## - the result: victory, defeat or draw, how and how long, the rank change,
##   any reward, and back to the ladder, a rematch or out to the city.

const WIDTH := 600.0
const HEIGHT := 330.0
const DETAILS_HEIGHT := 300.0
const LABEL_COLORS := {
	"Easy": UiTheme.GOOD, "Even": UiTheme.TEAL, "Hard": UiTheme.GOLD, "Very Hard": UiTheme.DANGER
}


static func ladder(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var profile := game.profile
	var parts := UiKit.window("Arena Ladder", Vector2(WIDTH, HEIGHT))
	parts["root"].name = "Arena"
	var body: VBoxContainer = parts["body"]
	body.add_child(_standing(game))
	var line := '%s: "%s"' % [npc.get("name", "Arena"), npc.get("line", "")]
	body.add_child(UiKit.label(line, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, WIDTH - 24))
	var list := VBoxContainer.new()
	list.name = "Rivals"
	list.add_theme_constant_override("separation", 3)
	body.add_child(list)
	var power := ArenaRules.player_power(profile, content)
	for id in ArenaRules.choices(profile, content):
		list.add_child(_rival_card(game, id, power))
	if ArenaRules.rank_of(profile, content) == 1:
		var arena := ArenaRules.state(profile, content)
		var defend := (
			"Champion. Title defenses: %d (streak %d). Wins keep your rank."
			% [int(arena["defenses"]), int(arena["streak"])]
		)
		body.add_child(UiKit.label(defend, UiTheme.SIZE_CAPTION, UiTheme.TEAL))
	var rules := "PvP rules: skills at PvP strength, health x%s, no food. Win: swap ranks."
	var note := UiKit.label(
		rules % str(ArenaRules.spec(content)["hp_scale"]), UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT
	)
	body.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", UiTheme.GAP)
	body.add_child(buttons)
	var fresh := UiKit.button("New rivals", game.arena.refresh_rivals)
	fresh.name = "Refresh"
	fresh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(fresh)
	var close := UiKit.button("Not now", game.close_menu)
	close.name = "Close"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(close)
	UiKit.focus_first(list)
	return parts["root"]


## Portrait, name and rank, then the record and the champion.
static func _standing(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var arena := ArenaRules.state(profile, content)
	var mine := ArenaRules.rank_of(profile, content)
	var count := ArenaRules.size(content)
	var row := HBoxContainer.new()
	row.name = "Standing"
	row.add_theme_constant_override("separation", 6)
	_add_face(row, content, str(content.hero(profile.hero)["sprites"]["default"]))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	row.add_child(text)
	var rank_text := "Unranked (#%d)" % mine if mine > count else "Rank #%d of %d" % [mine, count]
	var best := int(arena["best"])
	var top := (
		"%s   ·   %s   ·   Best #%s   ·   Power %d"
		% [
			profile.name,
			rank_text,
			str(best) if best <= count else "-",
			ArenaRules.player_power(profile, content),
		]
	)
	var head := UiKit.label(top, UiTheme.SIZE_BODY, UiTheme.GOLD)
	head.name = "Rank"
	text.add_child(head)
	var holder := ArenaRules.champion(profile, content)
	var champion := (
		profile.name + " (you)"
		if holder == ArenaRules.YOU
		else str(ArenaRules.rival(content, holder)["name"])
	)
	var record := (
		"%dW %dL %dD   ·   Win rate %d%%   ·   Champion: %s"
		% [
			int(arena["wins"]),
			int(arena["losses"]),
			int(arena["draws"]),
			roundi(ArenaRules.win_rate(arena) * 100.0),
			champion,
		]
	)
	var record_label := UiKit.label(record, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	record_label.name = "Record"
	text.add_child(record_label)
	return row


static func _add_face(row: Control, content: ContentDB, art_id: String) -> void:
	var art := UiKit.portrait(content, art_id)
	if art:
		var face := TextureRect.new()
		face.texture = art
		face.custom_minimum_size = Vector2(22, 22)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(face)


## One rival: rank, portrait, name, job, level, gear, AI; power and a
## difficulty label against the player; a button to its details.
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
	_add_face(row, content, str(hero["sprites"]["default"]))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiKit.label(str(data["name"]), UiTheme.SIZE_BODY, UiTheme.TEXT))
	var facts := (
		"%s  ·  Lv %d  ·  %s  ·  AI %s"
		% [
			job_name(hero),
			int(data["level"]),
			gear_text(data),
			ArenaRules.ai_label(content, float(data["ai"])),
		]
	)
	text.add_child(UiKit.label(facts, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	var hard := ArenaRules.difficulty(content, id, mine)
	var judged := VBoxContainer.new()
	judged.add_theme_constant_override("separation", -2)
	judged.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(judged)
	var shown := UiKit.label("Power %d" % int(hard["power"]), UiTheme.SIZE_SMALL, UiTheme.TEXT)
	shown.name = "Power"
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	judged.add_child(shown)
	var tag := UiKit.label(
		str(hard["label"]), UiTheme.SIZE_CAPTION, LABEL_COLORS.get(hard["label"], UiTheme.TEXT)
	)
	tag.name = "Difficulty"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	judged.add_child(tag)
	var fight := UiKit.button("Fight", game.arena.details.bind(id))
	fight.name = "Fight"
	fight.custom_minimum_size.x = 48
	row.add_child(fight)
	return card


static func job_name(hero: Dictionary) -> String:
	return str(hero["title"]).trim_prefix("The ")


## "Godforged +5 to +7", or the grades worn and their highest upgrade.
static func gear_text(data: Dictionary) -> String:
	var grades := {}
	var low := 99
	var high := 0
	for slot: String in data["slots"]:
		var worn: Dictionary = data["slots"][slot]
		grades[str(worn["grade"])] = true
		low = mini(low, int(worn["plus"]))
		high = maxi(high, int(worn["plus"]))
	var best := ""
	for rarity: String in ContentDB.RARITIES:
		if grades.has(rarity):
			best = rarity
	var text := best.capitalize() + (" mix" if grades.size() > 1 else "")
	if high == 0:
		return text + " +0"
	return text + (" +%d" % high if low == high else " +%d to +%d" % [low, high])


## A rival's details and the challenge.
static func details(game: Game, id: String) -> Control:
	var content := game.content
	var data := ArenaRules.rival(content, id)
	var hero := content.hero(str(data["hero"]))
	var parts := UiKit.window("Challenge", Vector2(WIDTH, DETAILS_HEIGHT))
	parts["root"].name = "ArenaDetails"
	var body: VBoxContainer = parts["body"]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	body.add_child(head)
	_add_face(head, content, str(hero["sprites"]["default"]))
	var rank := ArenaRules.rank_of(game.profile, content, id)
	var title := (
		"#%d  %s   ·   %s   ·   Lv %d" % [rank, data["name"], job_name(hero), int(data["level"])]
	)
	head.add_child(UiKit.label(title, UiTheme.SIZE_H2, UiTheme.ACCENT))
	var gear := GridContainer.new()
	gear.name = "Gear"
	gear.columns = 4
	gear.add_theme_constant_override("h_separation", 14)
	gear.add_theme_constant_override("v_separation", 0)
	body.add_child(gear)
	for slot: String in PlayerProfile.SLOTS:
		var worn: Dictionary = data["slots"].get(slot, {})
		if worn.is_empty():
			continue
		var item := content.item(str(worn["item"]))
		gear.add_child(UiKit.label(slot.capitalize(), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
		gear.add_child(UiKit.label(str(item.get("name", worn["item"])), UiTheme.SIZE_SMALL))
		gear.add_child(
			UiKit.label(str(worn["grade"]).capitalize(), UiTheme.SIZE_CAPTION, UiTheme.TEAL)
		)
		gear.add_child(UiKit.label("+%d" % int(worn["plus"]), UiTheme.SIZE_SMALL, UiTheme.GOLD))
	var brain: Dictionary = data["brain"]
	var style := (
		"Style: %s   ·   AI %s   ·   reacts in %d ms"
		% [
			str(data["personality"]).capitalize(),
			ArenaRules.ai_label(content, float(data["ai"])),
			roundi(float(brain["reaction_ticks"]) * 1000.0 / CombatRules.TICK_RATE),
		]
	)
	body.add_child(UiKit.label(style, UiTheme.SIZE_SMALL, UiTheme.TEXT))
	var mine := ArenaRules.player_power(game.profile, content)
	var hard := ArenaRules.difficulty(content, id, mine)
	var compare := UiKit.label(
		"Power %d against your %d   ·   %s" % [int(hard["power"]), mine, hard["label"]],
		UiTheme.SIZE_BODY,
		LABEL_COLORS.get(hard["label"], UiTheme.TEXT)
	)
	compare.name = "Compare"
	body.add_child(compare)
	var stake := "Win: you take rank #%d and they take yours. Lose or draw: no change." % rank
	if rank > ArenaRules.rank_of(game.profile, content):
		stake = "They rank below you: a win keeps your rank."
	body.add_child(UiKit.label(stake, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", UiTheme.GAP)
	body.add_child(buttons)
	var go := UiKit.button("Challenge", game.arena.start.bind(id))
	go.name = "Challenge"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(go)
	var back := UiKit.button("Back", game.arena.back)
	back.name = "Back"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(back)
	UiKit.focus_first(buttons)
	return parts["root"]


## After a match: victory, defeat or draw, the rank change, any reward, and
## back to the ladder, a rematch or out to the city.
static func result(game: Game, data: Dictionary) -> Control:
	var outcome := str(data.get("result", ArenaRules.WIN if data.get("won") else ArenaRules.LOSS))
	var titles := {ArenaRules.WIN: "VICTORY!", ArenaRules.LOSS: "DEFEAT", ArenaRules.DRAW: "DRAW"}
	var parts := UiKit.dialog(str(titles.get(outcome, "DEFEAT")), null)
	parts["root"].name = "ArenaResult"
	var body: VBoxContainer = parts["body"]
	var how := "Knock-out" if str(data.get("reason", "")) == "ko" else "Time up"
	var text := (
		"%s against %s after %d s." % [how, data.get("name", ""), int(data.get("seconds", 0))]
	)
	if str(data.get("reason", "")) == "time":
		text += (
			"  Health left: you %d%%, them %d%%."
			% [
				roundi(float(data.get("hero_share", 0)) * 100.0),
				roundi(float(data.get("rival_share", 0)) * 100.0),
			]
		)
	var old := int(data["old_rank"])
	var new := int(data["new_rank"])
	if new < old:
		text += "  Rank #%d -> #%d." % [old, new]
	elif outcome == ArenaRules.WIN:
		text += "  Your rank holds at #%d." % new
	else:
		text += "  Your rank stays #%d." % old
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
	var id := str(data.get("rival", ""))
	if id in ArenaRules.choices(game.profile, game.content):
		var rematch := UiKit.button("Rematch", game.arena.rematch.bind(id))
		rematch.name = "Rematch"
		body.add_child(rematch)
	var out := UiKit.button("Leave the arena", game.arena.leave.bind(true))
	out.name = "Leave"
	body.add_child(out)
	UiKit.focus_first(body)
	return parts["root"]
