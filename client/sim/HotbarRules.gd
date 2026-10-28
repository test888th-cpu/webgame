class_name HotbarRules
extends RefCounted
## The hero's hotbar: seven slots (keys 1-7) the player fills as they like.
## A slot holds a key: "attack", "skill:<skill id>" (one of the hero's own
## skills), "item:<item id>" (a consumable, kept on the bar when the last is
## eaten so another can take its place), or "" (empty). A key is on the bar
## at most once: putting it on a slot moves it there and swaps whatever was
## there into its old slot. The layout is saved with the character
## (PlayerProfile.hotbar); a character without one gets skills.json's
## default for its hero. Pure rules, shared with the server.

const SLOTS := 7
const ATTACK := "attack"


## skills.json's layout for `hero_id`, as keys.
static func default_layout(content: ContentDB, hero_id: String) -> Array[String]:
	var keys: Array[String] = []
	for entry: Dictionary in content.hotbar_for(hero_id):
		keys.append(key_of(entry))
	return keys


## The hero's seven keys: their own layout, or the default.
static func layout(profile: PlayerProfile, content: ContentDB) -> Array[String]:
	if profile.hotbar.size() == SLOTS:
		return profile.hotbar.duplicate()
	return default_layout(content, profile.hero)


## Slot `index` as an entry the HUD and the game read: {"type": "attack" |
## "skill" | "item" | "empty", "id"}.
static func entry(profile: PlayerProfile, content: ContentDB, index: int) -> Dictionary:
	return entry_of(layout(profile, content)[index])


static func entry_of(key: String) -> Dictionary:
	if key == ATTACK:
		return {"type": "attack", "id": ""}
	for kind: String in ["skill", "item"]:
		if key.begins_with(kind + ":"):
			return {"type": kind, "id": key.substr(kind.length() + 1)}
	return {"type": "empty", "id": ""}


static func key_of(entry: Dictionary) -> String:
	match str(entry.get("type", "")):
		"attack":
			return ATTACK
		"skill", "item":
			return "%s:%s" % [entry["type"], entry["id"]]
	return ""


## True when `key` may go on this hero's bar: the attack, one of the hero's
## own skills, or a consumable.
static func allowed(profile: PlayerProfile, content: ContentDB, key: String) -> bool:
	var what := entry_of(key)
	match what["type"]:
		"attack":
			return true
		"skill":
			return what["id"] in content.hero(profile.hero).get("skills", [])
		"item":
			return content.item(what["id"]).get("type") == "consumable"
	return false


## Puts `key` on slot `index` (moving it if it is on the bar already, and
## swapping the slot's old key into its place). Returns false, changing
## nothing, for a key this hero cannot use or a slot out of range.
static func place(profile: PlayerProfile, content: ContentDB, index: int, key: String) -> bool:
	if index < 0 or index >= SLOTS or not allowed(profile, content, key):
		return false
	var keys := layout(profile, content)
	var old := keys.find(key)
	if old >= 0:
		keys[old] = keys[index]
	keys[index] = key
	profile.hotbar = keys
	return true


## Swaps slots `a` and `b`.
static func swap(profile: PlayerProfile, content: ContentDB, a: int, b: int) -> bool:
	if a < 0 or b < 0 or a >= SLOTS or b >= SLOTS:
		return false
	var keys := layout(profile, content)
	var held := keys[a]
	keys[a] = keys[b]
	keys[b] = held
	profile.hotbar = keys
	return true


static func clear(profile: PlayerProfile, content: ContentDB, index: int) -> bool:
	if index < 0 or index >= SLOTS:
		return false
	var keys := layout(profile, content)
	keys[index] = ""
	profile.hotbar = keys
	return true


## A saved layout made safe: seven keys, each one this hero may use, none
## twice (later copies are emptied). Anything else gives the default.
static func clean(saved: Variant, profile: PlayerProfile, content: ContentDB) -> Array[String]:
	if not saved is Array or (saved as Array).size() != SLOTS:
		return default_layout(content, profile.hero)
	var keys: Array[String] = []
	for value: Variant in saved:
		var key := str(value)
		var fine := key == "" or allowed(profile, content, key)
		keys.append(key if fine and key not in keys else "")
	return keys
