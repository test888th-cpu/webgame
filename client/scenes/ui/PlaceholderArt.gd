class_name PlaceholderArt
extends RefCounted
## TEMPORARY art for the item catalog (data/placeholder_art.json), drawn by
## the game itself until final art exists: no image files, no art pipeline.
## * icons: 16x16, a simple silhouette per kind (stone, ore, bottle, core,
##   sigil, helmet, shirt, knuckle) in the item's grade colour, with a small
##   chequered corner that marks it as temporary;
## * appearance assets: headgear drawn above the head, an outfit as a tabard
##   over the torso, fist gear in the hand (EquipmentLayers places them).
## Final art replaces a placeholder by its asset or icon id (an icon in the
## UI sheet wins over a placeholder of the same id), never by an item id.
## Textures are built once and kept on GameSession (an autoload), as Fx does.

const ICON := 16
## The crown of every headgear drawing (see HEADGEAR), in its pixels.
const HAT_BODY := Rect2(2, 1, 20, 11)
const HAT_SIZE := Vector2i(28, 13)
## 14x14 silhouettes ("#" fill, "o" outline, "+" highlight), drawn at (1, 1).
const SHAPES := {
	"stone":
	[
		"..............",
		"......oo......",
		".....o++o.....",
		"....o+##+o....",
		"...o+####+o...",
		"..o+######+o..",
		".o##########o.",
		".o##########o.",
		"..o########o..",
		"...o######o...",
		"....o####o....",
		".....o##o.....",
		"......oo......",
		"..............",
	],
	"ore":
	[
		"..............",
		"..............",
		"....ooo.......",
		"...o+##o..oo..",
		"..o+####oo+#o.",
		"..o#####o###o.",
		".o######o###o.",
		".o##ooo##o##o.",
		".o#o+##o#oo...",
		"..oo####o.....",
		"...o####o.....",
		"....oooo......",
		"..............",
		"..............",
	],
	"bottle":
	[
		".....oooo.....",
		".....o++o.....",
		".....o##o.....",
		"....o####o....",
		"...o+#####o...",
		"..o+#######o..",
		"..o########o..",
		"..o##oooo##o..",
		"..o##o++o##o..",
		"..o##oooo##o..",
		"..o########o..",
		"...o######o...",
		"....oooooo....",
		"..............",
	],
	"core":
	[
		"..............",
		".....oooo.....",
		"...oo####oo...",
		"..o##oooo##o..",
		"..o#o++++o#o..",
		".o#o++##++o#o.",
		".o#o+####+o#o.",
		".o#o+####+o#o.",
		".o#o++##++o#o.",
		"..o#o++++o#o..",
		"..o##oooo##o..",
		"...oo####oo...",
		".....oooo.....",
		"..............",
	],
	"sigil":
	[
		"......oo......",
		"......o+o.....",
		".....o++#o....",
		"oooooo+##oooo.",
		"o+++++####+#o.",
		".o##########o.",
		"..o########o..",
		"...o######o...",
		"..o###oo###o..",
		"..o##o..o##o..",
		".o##o....o##o.",
		".ooo......ooo.",
		"..............",
		"..............",
	],
	"helmet":
	[
		"..............",
		"..............",
		"....oooooo....",
		"...o++####o...",
		"..o+#######o..",
		"..o########o..",
		".o##########o.",
		".o##########o.",
		".o###oooo###o.",
		".o##o....o##o.",
		".oooo....oooo.",
		"..............",
		"..............",
		"..............",
	],
	"shirt":
	[
		"..............",
		"..oooo..oooo..",
		".o+##oooo##+o.",
		"o+##########+o",
		"o############o",
		"oo##########oo",
		"..o########o..",
		"..o########o..",
		"..o##oooo##o..",
		"..o########o..",
		"..o########o..",
		"..oooooooooo..",
		"..............",
		"..............",
	],
	"knuckle":
	[
		"..............",
		"..............",
		"..oo.oo.oo.oo.",
		".o+#o+#o+#o+#o",
		".o##o##o##o##o",
		".o###########o",
		".o+##########o",
		".o###########o",
		"..o#########o.",
		"...o##ooo##o..",
		"...o#o...o#o..",
		"....oo...oo...",
		"..............",
		"..............",
	],
}
## Headgear, 28 wide: its crown fills HAT_BODY (cols 2-21, rows 1-11), the
## part EquipmentLayers stretches over the head it replaces.
const HEADGEAR := {
	"cap":
	[
		"..........................",
		".....oooooooooooo.........",
		"....o++##########oo.......",
		"...o+##############o......",
		"..o################o......",
		"..o##o#########o###o......",
		"..o################o......",
		"..o################o......",
		"..o################o......",
		"..o################ooooooo",
		"..o################+++++++o",
		"..oooooooooooooooooooooooo",
		"..........................",
	],
	"bandana":
	[
		"..........................",
		"......oooooooooooo........",
		"....oo++##########oo......",
		"...o+###############o.....",
		"..o#################o.....",
		"..o##o##o##o##o##o##o.....",
		"..o#################o.....",
		"..o#################o.....",
		"..o#################o.....",
		"..o#################o.....",
		".oo#################o.....",
		"o#oooooooooooooooooo......",
		"oo........................",
	],
	"helmet":
	[
		".......oooooooooo.........",
		".....oo++########oo.......",
		"....o++############o......",
		"...o+###############o.....",
		"..o#################o.....",
		"..o#################o.....",
		"..o#################o.....",
		"..oooooooooooooooooooo....",
		"..o+o+o+o+o+o+o+o+o+o.....",
		"..o#################o.....",
		"..o#################o.....",
		"..ooooooooooooooooooo.....",
		"..........................",
	],
	"helm":
	[
		"...........oo.............",
		"........ooo++ooo..........",
		".....oo++#######oo........",
		"....o+###########o........",
		"...o+#############o.......",
		"..o###############o.......",
		"..o###############ooo.....",
		"..o###########ooooooo.....",
		"..o##############o#o......",
		"..o###########ooooooo.....",
		"..o#################o.....",
		"..ooooooooooooooooooo.....",
		"..........................",
	],
	"crown":
	[
		"..o....o.....o.....o....o.",
		"..oo..o+o...o+o...o+o..oo.",
		"..o+oo##+ooo##+ooo##+oo+o.",
		"..o####################o..",
		"..o####################o..",
		"..o##oo####oo####oo####o..",
		"..o##oo####oo####oo####o..",
		"..o####################o..",
		"..o####################o..",
		"..o####################o..",
		"..o+++++++++++++++++++#o..",
		"..oooooooooooooooooooooo..",
		"..........................",
	],
}


## The placeholder icon `id`, or null when it is not one.
static func icon(content: ContentDB, id: String) -> Texture2D:
	var spec: Dictionary = content.catalog.placeholders.get("icons", {}).get(id, {})
	if spec.is_empty():
		return null
	var key := "icon:" + id
	if spec.has("image"):  # art from a file (the owner's hats), not drawn here
		return load(str(spec["image"]))
	if not GameSession.placeholder_art.has(key):
		var image := Image.create(ICON, ICON, false, Image.FORMAT_RGBA8)
		_draw_icon(image, str(spec["shape"]), _grade_color(str(spec["grade"])))
		_mark_temporary(image)
		GameSession.placeholder_art[key] = ImageTexture.create_from_image(image)
	return GameSession.placeholder_art[key]


## The placeholder appearance asset `asset`: {"slot", "style", "color",
## "texture"} (texture for headgear and fist gear; an outfit is drawn as a
## shape by EquipmentLayers), or {} when it is not one.
static func appearance(content: ContentDB, asset: String) -> Dictionary:
	var spec: Dictionary = content.catalog.placeholders.get("appearance_assets", {}).get(asset, {})
	if spec.is_empty():
		return {}
	var key := "look:" + asset
	if spec.has("image"):
		# Art from a file (the owner's temporary hats, tools/assets/
		# import_placeholder_hats.py, or final art later): drawn
		# at its own size, worn by its "fit" (EquipmentLayers).
		if not GameSession.placeholder_art.has(key):
			GameSession.placeholder_art[key] = {
				"slot": spec["slot"],
				"texture": load(str(spec["image"])),
				"fit": str(spec.get("fit", "cover")),
			}
			for field: String in ["row", "anchor", "opening"]:
				if spec.has(field):
					GameSession.placeholder_art[key][field] = spec[field]
		return GameSession.placeholder_art[key]
	if not GameSession.placeholder_art.has(key):
		var color := _grade_color(str(spec["grade"]))
		var out := {"slot": spec["slot"], "style": spec["style"], "color": color}
		if spec["slot"] == "head":
			out["texture"] = ImageTexture.create_from_image(_headgear(str(spec["style"]), color))
		elif spec["slot"] == "weapon":
			out["texture"] = ImageTexture.create_from_image(_fist_gear(str(spec["style"]), color))
		GameSession.placeholder_art[key] = out
	return GameSession.placeholder_art[key]


static func _grade_color(grade: String) -> Color:
	return ItemText.RARITY_COLORS.get(grade, UiTheme.TEXT)


## A 3x3 black and white check in the bottom right corner: "temporary art".
static func _mark_temporary(image: Image) -> void:
	for y in 3:
		for x in 3:
			var on := (x + y) % 2 == 0
			image.set_pixel(ICON - 3 + x, ICON - 3 + y, Color.WHITE if on else Color.BLACK)


## Fills `cells` (a list of rows, "#" body, "o" outline) into `image`.
static func _stamp(image: Image, rows: Array, color: Color, at := Vector2i.ZERO) -> void:
	var dark := color.darkened(0.55)
	var light := color.lightened(0.35)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var c := row[x]
			if c == ".":
				continue
			var paint := color
			if c == "o":
				paint = dark
			elif c == "+":
				paint = light
			var px := at + Vector2i(x, y)
			if px.x >= 0 and px.y >= 0 and px.x < image.get_width() and px.y < image.get_height():
				image.set_pixel(px.x, px.y, paint)


static func _draw_icon(image: Image, shape: String, color: Color) -> void:
	var rows: Array = SHAPES.get(shape, SHAPES["stone"])
	_stamp(image, rows, color, Vector2i(1, 1))


## Headgear drawn in `color` (HEADGEAR).
static func _headgear(style: String, color: Color) -> Image:
	var rows: Array = HEADGEAR.get(style, HEADGEAR["cap"])
	var image := Image.create(HAT_SIZE.x, HAT_SIZE.y, false, Image.FORMAT_RGBA8)
	_stamp(image, rows, color)
	return image


## Fist gear for the hand socket, 8x6, centred on the knuckles.
static func _fist_gear(style: String, color: Color) -> Image:
	var rows: Array = [
		".oo.oo..",
		"o+#o+#o.",
		"o######o",
		"o######o",
		".o####o.",
		"..oooo..",
	]
	if style in ["gauntlet", "fist"]:
		rows = [
			"oooooooo",
			"o+#+#+#o",
			"o######o",
			"o#o##o#o",
			"o######o",
			"oooooooo",
		]
	var image := Image.create(8, rows.size(), false, Image.FORMAT_RGBA8)
	_stamp(image, rows, color)
	return image
