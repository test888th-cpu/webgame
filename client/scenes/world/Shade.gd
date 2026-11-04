class_name Shade
extends RefCounted
## Shadows on the street, two for each thing that stands on it (fighters,
## street furniture, props on the sidewalk):
## * a cast shadow: the thing's own silhouette laid down on the ground from
##   its base line, away from the light (the moon and the lamps, above and
##   behind the street), squashed by the low angle and slanted by the light's
##   direction; it starts exactly where the thing stands, so nothing floats;
## * a small, soft contact shadow right where it meets the ground: one small
##   radial gradient, made once and kept on GameSession (an autoload) rather
##   than in a static variable, which would outlive the engine at exit.

## How dark the middle of a contact shadow is.
const ALPHA := 0.55
## The cast shadow: how dark, how flat (its length for the thing's height)
## and how slanted (radians; the light comes from above, behind and a little
## to the left, so shadows fall forward and to the right).
const CAST_ALPHA := 0.3
const CAST_SQUASH := 0.32
const CAST_SKEW := -0.75
## The texture's size, in pixels; a shadow is scaled to its width.
const SIZE := 64


## A shadow `width` game pixels wide, `depth` of that deep (the street seen
## at a low angle), centred on (0, 0): add it before the thing it is under.
static func make(width: float, depth := 0.34, alpha := ALPHA) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Shade"
	sprite.texture = _texture()
	sprite.scale = Vector2(width, width * depth) / float(SIZE)
	sprite.modulate = Color(1, 1, 1, alpha / ALPHA)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite


static func _texture() -> Texture2D:
	if GameSession.has_meta("shade_texture"):
		return GameSession.get_meta("shade_texture")
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, ALPHA))
	gradient.set_color(1, Color(0, 0, 0, 0))
	gradient.add_point(0.55, Color(0, 0, 0, ALPHA * 0.7))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = SIZE
	texture.height = SIZE
	GameSession.set_meta("shade_texture", texture)
	return texture


## The cast shadow of `source` (a Sprite2D drawn from its top-left, standing
## with its base on y = `feet` in the parent's space): its texture, black and
## see-through, flipped onto the ground at `feet`. Add it before `source`.
static func cast(source: Sprite2D, feet: float) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.name = "Cast"
	shadow.texture = source.texture
	shadow.centered = false
	shadow.region_enabled = source.region_enabled
	shadow.region_rect = source.region_rect
	shadow.flip_v = true
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shadow.modulate = Color(0, 0, 0, CAST_ALPHA)
	shadow.scale = Vector2(source.scale.x, source.scale.y * CAST_SQUASH)
	shadow.skew = CAST_SKEW
	shadow.position = Vector2(source.position.x, feet)
	return shadow
