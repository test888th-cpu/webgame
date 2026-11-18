class_name UnitSprite
extends Node2D
## Draws one engine unit (RpgEncounter player or monster) with an existing LPC
## character sheet (assets/characters/<id>/<id>.tres): idle, walk, swing, hurt and
## down. It holds no game state: Street calls show_unit() every frame with the
## unit record, and it only reads it.

const HIT_FLASH := 0.15
const BAR_WIDTH := 26.0

var unit_id := -1
var _sprite: AnimatedSprite2D
var _name: Label
var _bar_back: ColorRect
var _bar: ColorRect
var _last_x := INF
var _last_hp := -1
var _flash := 0.0
var _swing := 0.0
var _swing_timer := -1.0


## `art_id`: an assets/characters id from content.art; `title`: the overhead name.
func setup(content: ContentDB, art_id: String, title: String, color: Color) -> void:
	var shadow := Shade.make(18.0, 0.3, 0.6)
	add_child(shadow)
	var entry: Dictionary = content.art.get(art_id, {})
	if entry.get("status") == "imported":
		_sprite = AnimatedSprite2D.new()
		_sprite.centered = false
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sheet := str(entry["sheet"])
		_sprite.sprite_frames = load(sheet.get_base_dir().path_join(art_id + ".tres"))
		var origin: Array = entry.get("origin", [32, 62])
		_sprite.offset = -Vector2(origin[0], origin[1])
		add_child(_sprite)
		_sprite.play("idle")
	_name = UiKit.overlay_label(title, UiTheme.SIZE_CAPTION, color)
	_name.position = Vector2(-60, -78)
	_name.size = Vector2(120, 10)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0, 0, 0, 0.6)
	_bar_back.position = Vector2(-BAR_WIDTH / 2.0, -66)
	_bar_back.size = Vector2(BAR_WIDTH, 3)
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = UiTheme.DANGER
	_bar.position = _bar_back.position
	_bar.size = _bar_back.size
	add_child(_bar)


## Mirrors `u` at screen position `at`, facing `facing` (-1 or 1).
func show_unit(u: Dictionary, at: Vector2, facing: int, delta: float) -> void:
	var moved := _last_x != INF and absf(at.x - _last_x) > 0.05
	_last_x = at.x
	position = at
	var hp := int(u["hp"])
	if _last_hp >= 0 and hp < _last_hp:
		_flash = HIT_FLASH
	_last_hp = hp
	_bar.size.x = BAR_WIDTH * float(hp) / maxf(1.0, float(u["max_hp"]))
	var timer := float(u.get("swing_timer", 0.0))
	if _swing_timer >= 0.0 and timer > _swing_timer + 0.01:
		_swing = 0.4
	_swing_timer = timer
	_flash = maxf(0.0, _flash - delta)
	_swing = maxf(0.0, _swing - delta)
	if _sprite == null:
		return
	_sprite.flip_h = facing < 0
	_sprite.modulate = Color(1.8, 0.7, 0.7) if _flash > 0.0 else Color.WHITE
	var anim := "idle"
	if u["dead"]:
		anim = "down"
		_sprite.modulate.a = 0.6
	elif _swing > 0.0:
		anim = "swing"
	elif _flash > 0.0:
		anim = "hurt"
	elif moved:
		anim = "walk"
	if _sprite.animation != anim:
		_sprite.play(anim)
	_bar.visible = not u["dead"]
	_bar_back.visible = not u["dead"]


## The overhead name's colour (the targeted monster is highlighted).
func mark(color: Color) -> void:
	_name.add_theme_color_override("font_color", color)
