class_name LegalNotices
extends RefCounted
## The third-party notices that must travel with the game (data/legal/
## third_party_notices.json, the same text as THIRD_PARTY_NOTICES.md): shown in the
## title's Credits and in the street's Settings > Notices.

const PATH := "res://data/legal/third_party_notices.json"


static func notices() -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data.get("notices", []) if data is Dictionary else []


## Every notice as text: what is used, where from, the revision, then the licence
## text exactly as its LICENSE file has it.
static func text() -> String:
	var parts: Array[String] = []
	for n: Dictionary in notices():
		parts.append(
			(
				"%s (%s licence)\n%s\n%s at revision %s\n%s\n\n%s"
				% [
					n["name"],
					n["license"],
					n["what"],
					n["repository"],
					n["revision"],
					n["scope"],
					n["text"]
				]
			)
		)
	return "\n\n".join(parts)
