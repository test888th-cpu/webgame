class_name QuestFlow
extends RefCounted
## The story's quests, as in mobile games (owner's choice, 2026-11-04): the
## HUD's quest card shows the quest a player is on and what to do next, all
## from wherever they are, with no walk back to the giver:
##   1. NEW QUEST: press the card (F) to read the giver's offer and accept it;
##   2. QUEST: the goal and its progress, where it is;
##   3. QUEST COMPLETE!: a popup says so; press the card to hear the giver
##      and claim the reward.
## The card opens the giver's own quest window (Game.open_quests), whose
## Accept and Hand in buttons pay through the usual rules, so the story's
## words are kept. A boss beaten before its quest was taken counts
## (QuestRules.catch_up). Auto battle accepts and claims by itself
## (StoryAuto). The givers stay at their rest points to talk to.


## The quest the card shows: one finished (to claim), else one on offer, else
## the one under way; "" when the story has none.
static func current(profile: PlayerProfile, content: ContentDB) -> String:
	for state in ["complete", "available", "active"]:
		for quest_id: String in content.quests:
			if QuestRules.status(profile, quest_id, content) == state:
				return quest_id
	return ""


## The card pressed (or F): the giver's window for the current quest, to
## accept it or claim its reward.
static func open_tracker(game: Game) -> void:
	var quest_id := current(game.profile, game.content)
	if quest_id == "" or game.menu_name == "quests_npc":
		return
	var giver := MapRules._npc(game.content, str(game.content.quests[quest_id]["giver"]))
	if not giver.is_empty():
		game.open_quests(giver)


## After a quest is done (and on load): counts bosses already beaten, and
## pops up that a quest is ready to claim.
static func run(game: Game) -> void:
	var done := QuestRules.catch_up(game.profile, game.content)
	game.view.update_npc_marks(game.profile)
	if not done.is_empty():
		var quest: Dictionary = game.content.quests[done[0]]
		game.hud_toast("QUEST COMPLETE: %s!  Press F to claim your reward." % quest["name"])
