class_name QuestFlow
extends RefCounted
## Runs the story's quests by themselves (QuestRules.auto_flow): takes the
## next quest, hands in every one done through Game's own hand-in (rewards,
## level up, a chapter's end, the epilogue), and shows the quest giver's
## closing words in their quest window when no other screen is open (the
## street goes on behind it), else a short message. Called on load, so a save
## that played on without its quests catches up, and on every completed quest.

## The most hand-ins in one go (the whole story is twelve quests).
const MOST := 20


static func run(game: Game) -> void:
	var last := ""
	for i in MOST:
		var done := QuestRules.auto_flow(game.profile, game.content)
		if done.is_empty():
			break
		for quest_id in done:
			game._hand_in(quest_id)
			last = quest_id
	game.view.update_npc_marks(game.profile)
	if last == "" or game.menu_name == "epilogue":
		return
	var quest: Dictionary = game.content.quests[last]
	var giver := MapRules._npc(game.content, str(quest["giver"]))
	var words := str(quest.get("dialogue", {}).get("done", ""))
	if game.menu == null and not giver.is_empty():
		game.open_quests(giver, words)
	else:
		game.hud_toast("Quest complete: %s" % quest["name"])
