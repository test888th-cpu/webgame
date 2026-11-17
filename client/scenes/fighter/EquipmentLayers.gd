class_name EquipmentLayers
extends Node2D
## Shows a fighter's worn headgear on its head (Fighter.appearance "head",
## kept by EquipmentLooks), frame by frame, for every job and move.
## Each frame the top of the head is measured from the frame's own pixels
## (the topmost BROW drawn rows: hair, or a cap the character's art wears),
## and the hat is worn by its "fit" (the asset's data):
## * "cover" (a hat, helmet, hood or crown): it REPLACES what the character
##   wears there. The body sprite stops drawing those rows (the shader's
##   hide_rect), and the hat sits on the head, its lower edge at the brow, so
##   the old headwear is never seen under or beside the new one.
## * "band" (a headband, tiara or visor): worn across the brow over the hair,
##   which stays.
## * "hood" (a hood or an open helm): worn round the face, its see-through
##   opening on the face, hiding the hair (and any cap) as "cover" does.
## Hats are drawn at their own pixel size (no stretching) and mirror with the
## body when it faces left. Wearing another hat swaps the one shown; taking it
## off brings the character's own head back.
## Outfits and weapons keep the character's own look for now (owner's
## decision): their appearance ids are kept on the fighter for later art,
## and nothing is drawn for them.
## The appearance id names an asset (appearances.json); final art takes its
## place under the same asset id without touching items or saves.

## Rows from the top of the head that a covering hat hides (hair or a cap,
## down to just above the brow, measured on the five heroes' art); its lower
## edge rests one row below, on the brow.
const BROW := 10
## Where a band's middle sits, in rows from the top of the head, when its
## asset names no "row" of its own.
const BAND_ROW := 9
## Where the face is, from the top of the head: rows down, and pixels forward
## of the head's middle (the way it faces), measured on the heroes' art.
const FACE_ROW := 15
const FACE_FORWARD := 3
const NO_HIDE := Vector4.ZERO
## Fewest drawn pixels in a row for it to be the top of the head.
const HEAD_MIN := 3

var _head: Sprite2D
var _shown := {}
var _hiding: AnimatedSprite2D


func _init() -> void:
	name = "Gear"
	_head = Sprite2D.new()
	_head.name = "Headgear"
	_head.centered = false
	_head.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_head.visible = false
	add_child(_head)


## The appearance ids worn now: {slot: id} (all slots, drawn or not).
func shown() -> Dictionary:
	return _shown.duplicate()


## How the hat on show is worn: "cover", "band" or "" (none).
func fit() -> String:
	return str(_head.get_meta("fit", "")) if _head.visible else ""


## The body's rows hidden under a covering hat, in the sprite's own space
## (empty without one).
func hidden_rect() -> Rect2:
	if _hiding == null:
		return Rect2()
	var r: Vector4 = _hiding.material.get_shader_parameter("hide_rect")
	return Rect2(r.x, r.y, r.z - r.x, r.w - r.y)


## Places the headgear for this frame. `sprite` is the body on screen (null
## for the polygon figure, which shows no gear).
func update(fighter: Fighter, content: ContentDB, sprite: AnimatedSprite2D) -> void:
	_shown = fighter.appearance.duplicate()
	var look := {}
	if _shown.has("head"):
		var asset := str(content.catalog.appearances.get(_shown["head"], {}).get("asset", ""))
		look = PlaceholderArt.appearance(content, asset)
	var texture: Texture2D = null
	if sprite != null and not fighter.is_ko() and look.has("texture"):
		texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	_head.visible = texture != null
	if not _head.visible:
		_hide(sprite, NO_HIDE)
		return
	var head := _cover(texture)
	if sprite.flip_h:
		head.position.x = texture.get_width() - head.end.x
	var hat: Texture2D = look["texture"]
	var size := hat.get_size()
	var fit_as := str(look.get("fit", "cover"))
	# The frame's top-left in the view (the sprite is not centred).
	var origin := sprite.offset + sprite.position
	var middle := origin.x + head.position.x + head.size.x / 2.0
	# Where the hat meets the head (its "anchor": centre of mass, the base of
	# its main body, the middle of it), mirrored with the body.
	var hold: Array = look.get("anchor", [size.x / 2.0, size.y - 1.0, size.y / 2.0])
	var hold_x := float(hold[0])
	if sprite.flip_h:
		hold_x = size.x - 1.0 - hold_x
	var at := Vector2(middle - hold_x, 0.0)
	if fit_as == "band":
		var row := float(look.get("row", BAND_ROW))
		at.y = origin.y + head.position.y + row - float(hold[2])
		_hide(sprite, NO_HIDE)
	elif fit_as == "hood" and look.has("opening"):
		var opening: Array = look["opening"]
		var open_x := float(opening[0])
		if sprite.flip_h:
			open_x = size.x - 1.0 - open_x
		var face_x := middle + (-FACE_FORWARD if sprite.flip_h else FACE_FORWARD)
		at = Vector2(face_x - open_x, origin.y + head.position.y + FACE_ROW - float(opening[1]))
		var local := sprite.offset + head.position
		_hide(sprite, Vector4(local.x, local.y, local.x + head.size.x, local.y + BROW))
	else:
		at.y = origin.y + head.position.y + BROW - float(hold[1])
		var local := sprite.offset + head.position
		_hide(sprite, Vector4(local.x, local.y, local.x + head.size.x, local.y + BROW))
	_head.texture = hat
	_head.flip_h = sprite.flip_h
	_head.position = at.round()
	_head.set_meta("fit", fit_as)


func _hide(sprite: AnimatedSprite2D, rect: Vector4) -> void:
	if sprite == null or not sprite.material is ShaderMaterial:
		return
	(sprite.material as ShaderMaterial).set_shader_parameter("hide_rect", rect)
	_hiding = sprite


## The top of the head in `texture`'s frame: the topmost BROW drawn rows, as
## wide as they reach. Kept per frame.
func _cover(texture: Texture2D) -> Rect2:
	# Per frame resource: every frame of a sheet shares one atlas RID.
	var key := "cover:%d" % texture.get_instance_id()
	if not GameSession.placeholder_art.has(key):
		GameSession.placeholder_art[key] = find_cover(texture.get_image())
	return GameSession.placeholder_art[key]


## The head's top rows in a frame: the first row with HEAD_MIN drawn pixels
## (a stray pixel is not a head), and over the BROW rows from there, the
## widest span of each row's longest run of drawn pixels (the head itself,
## not a stray pixel or a fist off to the side).
static func find_cover(image: Image) -> Rect2:
	if image == null:
		return Rect2()
	var top := -1
	var left := image.get_width()
	var right := -1
	for y in image.get_height():
		if top >= 0 and y >= top + BROW:
			break
		var run := _longest_run(image, y)
		if top < 0 and run.y - run.x + 1 < HEAD_MIN:
			continue
		top = y if top < 0 else top
		if run.y >= run.x:
			left = mini(left, run.x)
			right = maxi(right, run.y)
	if top < 0:
		return Rect2()
	return Rect2(left, top, right - left + 1, BROW)


## Row `y`'s longest run of drawn pixels: (first x, last x), or (0, -1).
static func _longest_run(image: Image, y: int) -> Vector2i:
	var best := Vector2i(0, -1)
	var start := -1
	for x in image.get_width() + 1:
		var drawn := x < image.get_width() and image.get_pixel(x, y).a > 0.5
		if drawn and start < 0:
			start = x
		elif not drawn and start >= 0:
			if x - 1 - start > best.y - best.x:
				best = Vector2i(start, x - 1)
			start = -1
	return best
