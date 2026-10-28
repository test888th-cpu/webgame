class_name RosterRules
extends RefCounted
## An account's characters: how many it may have (progression.json
## "max_characters"), what a character id looks like, and which names are
## free. Pure rules over the list of the account's characters, so the
## server can enforce the same ones; the client's SaveStore keeps the list.


## True for a character id: 16 lowercase hex digits (64 random bits).
static func is_id(text: String) -> bool:
	if text.length() != 16:
		return false
	for c in text:
		if not c in "0123456789abcdef":
			return false
	return true


static func max_characters(content: ContentDB) -> int:
	return int(content.progression.get("max_characters", 1))


## Why another character cannot be made ("" if it can): "full" (`used`
## slots, unreadable saves included, reach the limit) or "name" (another of
## the account's `characters` has that name, ignoring case). An invalid name
## is PlayerProfile.clean_name's to judge.
static func problem(used: int, characters: Array, content: ContentDB, name: String) -> String:
	if used >= max_characters(content):
		return "full"
	if name_taken(characters, name):
		return "name"
	return ""


static func name_taken(characters: Array, name: String) -> bool:
	for character: PlayerProfile in characters:
		if character.name.to_lower() == name.strip_edges().to_lower():
			return true
	return false
