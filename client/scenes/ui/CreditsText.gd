class_name CreditsText
extends RefCounted
## Builds the in-game credits from the per-asset credits files listed in the
## asset manifest. Attribution licences (OGA-BY, CC-BY) require the authors to
## be credited where players can find them; this is that place.


static func build(content: ContentDB) -> String:
	var authors := {}
	var by_license := {}
	var sources := {}
	for id: String in content.art:
		var entry: Dictionary = content.art[id]
		if entry.get("status") != "imported":
			continue
		var credits: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(str(entry["credits"]))
		)
		if not credits is Array:
			continue
		for credit: Dictionary in credits:
			for author: String in credit.get("authors", []):
				authors[author] = true
			var license := str(credit.get("license", ""))
			by_license[license] = int(by_license.get(license, 0)) + 1
			for url: String in credit.get("urls", []):
				sources[url] = true
	var names: Array = authors.keys()
	names.sort()
	var licenses: Array = by_license.keys()
	licenses.sort()
	return (
		"Game design and code: the Ironbound Streets authors (MIT licence).\n\n"
		+ "Character sprites built from the Liberated Pixel Cup (LPC) collection, via the\n"
		+ "Universal LPC Spritesheet Character Generator.\n"
		+ "Sprite artists: %s.\n\n" % ", ".join(names)
		+ "Licences used: %s.\n" % ", ".join(licenses)
		+ "Per-file authors, licences and sources: assets/characters/*/credits.json\n"
		+ "(%d source pages on OpenGameArt.org).\n\n" % sources.size()
		+ "Riku Sato: character art by the project owner.\n\n"
		+ "Scenery, effects, icons, sounds and the training dummy: original, generated\n"
		+ "by the project's tools (MIT licence), except the recorded sounds below.\n\n"
		+ _sounds(content)
		+ _fonts(content)
		+ "Made with the Godot Engine (godotengine.org/license):\n"
		+ Engine.get_license_text()
	)


## Recorded sound effects and their authors (CC-BY asks for credit).
static func _sounds(content: ContentDB) -> String:
	var text := ""
	var seen := {}
	var recorded: Dictionary = content.audio.get("recorded", {})
	for sound_id: String in recorded:
		var sound: Dictionary = recorded[sound_id]
		# Several cuts of one recording are credited once.
		if seen.has(sound.get("url", sound_id)):
			continue
		seen[sound.get("url", sound_id)] = true
		# The attribution line exactly as the source asks for it, if given.
		if sound.has("attribution"):
			text += "Sound: %s\n" % sound["attribution"]
			continue
		text += (
			'Sound "%s" by %s (%s), %s\n'
			% [
				sound.get("title", sound_id),
				", ".join(sound.get("authors", [])),
				sound.get("license", ""),
				sound.get("url", ""),
			]
		)
	return text + "\n" if text else ""


## Bundled fonts and their licences (the SIL Open Font License asks for the
## copyright notice and licence to travel with the font).
static func _fonts(content: ContentDB) -> String:
	var text := ""
	for font_id: String in content.fonts:
		var font: Dictionary = content.fonts[font_id]
		text += (
			"Font: %s, %s (%s), %s\n\n"
			% [
				str(font["file"]).get_file().get_basename(),
				font.get("authors", ""),
				font.get("license", ""),
				font.get("source", ""),
			]
		)
	return text
