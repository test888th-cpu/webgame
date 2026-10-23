extends Node
## Plays the game's sound effects (synthesised by tools/assets/gen_sfx.py and
## listed in the asset manifest). A small pool of players lets sounds overlap;
## the same sound is not restarted within a few milliseconds, so a sweep that
## hits five enemies on one tick plays once. Volume is a player setting.

const VOICES := 12
const REPEAT_MSEC := 40

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}


func _ready() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	# Release the streams before the engine checks for leaked resources.
	for player in _players:
		player.stop()
		player.stream = null
	_streams.clear()


## Plays `id` with a little random pitch so repeats do not sound identical.
func play(id: String, volume_db := 0.0, pitch_jitter := 0.06) -> void:
	var volume := float(GameSession.settings.get("sfx_volume", 0.8))
	if volume <= 0.0:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(id, -REPEAT_MSEC)) < REPEAT_MSEC:
		return
	var stream := _stream(id)
	if stream == null:
		return
	_last[id] = now
	# Headless runs (tests, the future zone server) resolve the sound, which
	# catches unknown ids, but never play it.
	if DisplayServer.get_name() == "headless":
		return
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(volume)
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


## Plays `id` after `seconds` (e.g. timed to an attack's impact frame).
func play_later(id: String, seconds: float, volume_db := 0.0) -> void:
	get_tree().create_timer(seconds).timeout.connect(play.bind(id, volume_db))


func _stream(id: String) -> AudioStream:
	if not _streams.has(id):
		var path := str(GameSession.content.audio.get("sounds", {}).get(id, ""))
		_streams[id] = load(path) if path else null
		if path == "":
			push_error("unknown sound " + id)
	return _streams[id]
