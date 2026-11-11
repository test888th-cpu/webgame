class_name BlockRules
extends RefCounted
## Blocks: an area may be several blocks long (areas.json "blocks", 1 when
## left out), each the area's whole street again, walked through one after
## another. A farming ground and a lair are ten blocks of the same level, the
## same monsters and the same camps. Walking off a block's east edge enters
## the next block from the west; off its west edge, the block before from the
## east. The first block's west edge and the last block's east edge are the
## area's own exits. A taxi, the field truck or a knock-out always arrives in
## the first block (or the last, entering from the east). Pure rules, shared
## with the server.

const MAX_BLOCKS := 20


## How many blocks `area_id` is.
static func count(content: ContentDB, area_id: String) -> int:
	return clampi(int(content.area(area_id).get("blocks", 1)), 1, MAX_BLOCKS)


## The block a hero walking in by `entry` arrives in: the last when they come
## from the east, else the first.
static func entry_block(content: ContentDB, area_id: String, entry: String) -> int:
	return count(content, area_id) if entry == "east" else 1


## The exits from block `block` of `area_id`, by side, each {"to", "entry",
## "block"}: the neighbouring block of the same area, or the area's own exit
## at either end (arriving in the right block of the area it leads to).
static func exits(content: ContentDB, area_id: String, block: int) -> Dictionary:
	var out := {}
	var own: Dictionary = content.area(area_id).get("exits", {})
	for side: String in own:
		var exit: Dictionary = own[side].duplicate()
		var entry := str(exit.get("entry", "west"))
		exit["block"] = entry_block(content, str(exit.get("to", "")), entry)
		out[side] = exit
	if block < count(content, area_id):
		out["east"] = {"to": area_id, "entry": "west", "block": block + 1}
	if block > 1:
		out["west"] = {"to": area_id, "entry": "east", "block": block - 1}
	return out


## "Block 3/10" for a many-block area, "" for one block.
static func label(content: ContentDB, area_id: String, block: int) -> String:
	var blocks := count(content, area_id)
	return "Block %d/%d" % [block, blocks] if blocks > 1 else ""


## What is wrong with an area's "blocks": a whole number from 1 to
## MAX_BLOCKS, only where the street repeats (a farming ground or a lair).
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in content.areas:
		var blocks: Variant = content.area(id).get("blocks")
		if blocks == null:
			continue
		var where := "areas.%s.blocks" % id
		if not (blocks is float or blocks is int) or blocks < 1 or blocks > MAX_BLOCKS:
			out.append("%s: expected 1 to %d" % [where, MAX_BLOCKS])
		if AreaRules.kind(content, id) not in AreaRules.GATED:
			out.append(where + ": only a farming ground or a lair repeats")
	return out
