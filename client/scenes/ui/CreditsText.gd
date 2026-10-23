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
		+ "(%d source pages on OpenGameArt.org)." % sources.size()
	)
