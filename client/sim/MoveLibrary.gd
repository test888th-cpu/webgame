class_name MoveLibrary
extends RefCounted
## Loads and validates attack definitions from JSON. Content lives in
## res://data/moves.json so new attacks need no code changes. Invalid content
## fails loudly at load time instead of misbehaving in a fight.

const DEFAULT_PATH := "res://data/moves.json"

const INT_FIELDS := ["startup", "active", "recovery", "damage", "hitstun"]
const FLOAT_FIELDS := ["knockback", "reach_offset", "reach", "depth_tolerance", "energy_cost"]
const BOOL_FIELDS := ["guard_break", "knockdown"]
const CHAIN_INPUTS := ["light", "heavy"]

var moves: Dictionary = {}
## The move each input starts from neutral, e.g. {"light": "jab"}.
var starters: Dictionary = {}
var errors: PackedStringArray = []


static func load_file(path := DEFAULT_PATH) -> MoveLibrary:
	var text := FileAccess.get_file_as_string(path)
	var library := MoveLibrary.new()
	if text.is_empty():
		library.errors.append("cannot read %s" % path)
		return library
	library.parse(JSON.parse_string(text))
	return library


func get_move(id: String) -> MoveData:
	return moves.get(id)


func is_valid() -> bool:
	return errors.is_empty()


func parse(data: Variant) -> void:
	if not data is Dictionary or not data.get("moves") is Dictionary:
		errors.append('top level must be {"moves": {...}}')
		return
	var raw: Dictionary = data["moves"]
	for id: String in raw:
		var move := _parse_move(id, raw[id])
		if move:
			moves[id] = move
	var raw_starters: Variant = data.get("starters")
	if not raw_starters is Dictionary:
		errors.append('missing "starters": {"light": ..., "heavy": ...}')
	else:
		for input: String in CHAIN_INPUTS:
			var id := str(raw_starters.get(input, ""))
			if not raw.has(id):
				errors.append("starters.%s: unknown move %s" % [input, id])
			else:
				starters[input] = id
	# Chains may only point at moves that exist.
	for move: MoveData in moves.values():
		for input: String in move.chains:
			if not moves.has(move.chains[input]):
				errors.append(
					"%s: chain %s -> unknown move %s" % [move.id, input, move.chains[input]]
				)


func _parse_move(id: String, raw: Variant) -> MoveData:
	if not raw is Dictionary:
		errors.append("%s: must be an object" % id)
		return null
	var move := MoveData.new()
	move.id = id
	for field: String in INT_FIELDS:
		var value: Variant = raw.get(field)
		if not (value is float or value is int) or value != floorf(value) or value < 0:
			errors.append("%s.%s: expected a non-negative integer" % [id, field])
			continue
		move.set(field, int(value))
	for field: String in FLOAT_FIELDS:
		var value: Variant = raw.get(field, 0.0)
		if not (value is float or value is int) or value < 0:
			errors.append("%s.%s: expected a non-negative number" % [id, field])
			continue
		move.set(field, float(value))
	for field: String in BOOL_FIELDS:
		var value: Variant = raw.get(field, false)
		if not value is bool:
			errors.append("%s.%s: expected true or false" % [id, field])
			continue
		move.set(field, value)
	if move.active < 1:
		errors.append("%s.active: must be at least 1 tick" % id)
	var chains: Variant = raw.get("chains", {})
	if not chains is Dictionary:
		errors.append("%s.chains: expected an object" % id)
	else:
		for input: String in chains:
			if input not in CHAIN_INPUTS:
				errors.append("%s.chains: unknown input %s" % [id, input])
			else:
				move.chains[input] = str(chains[input])
	return move
