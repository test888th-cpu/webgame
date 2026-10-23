#!/usr/bin/env python3
"""Imports characters exported from UnitForge (https://www.unitforge.net/character)
with its "Godot 4" export, after a person has uploaded the export to
art/unitforge/<asset_id>/ through the GitHub website.

  python3 tools/assets/unitforge_import.py [asset_id ...]

The website has no API this project can call, so exporting is manual (see
docs/ASSETS.md). This script does everything after that:

  * finds the SpriteFrames .tres and the PNG it references in the folder
  * reads every animation's AtlasTexture regions, checks they lie inside the
    PNG, share one frame size and are not empty
  * repacks the frames (unchanged, never resized) into this project's
    one-row-per-animation sheet and maps animation names to the game's names
    using art/unitforge/<asset_id>/import.json
  * requires art/unitforge/<asset_id>/import.json to state the licence and
    attribution; without it the asset stays "pending_manual_export"
  * writes client/assets/characters/<asset_id>/ and updates the manifest

NOTE: written against Godot 4's documented SpriteFrames text format. It has
not yet been run on a real UnitForge export (the site is unreachable from the
build environment); if UnitForge's export differs, this reports exactly what
it could not read instead of importing something broken.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art" / "unitforge"
OUT_DIR = ROOT / "client" / "assets" / "characters"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"

SUB_RE = re.compile(r'\[sub_resource type="AtlasTexture" id="([^"]+)"\](.*?)(?=\n\[|\Z)', re.S)
EXT_RE = re.compile(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"\]')
REGION_RE = re.compile(r"region = Rect2\(([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\)")
ATLAS_RE = re.compile(r'atlas = ExtResource\("([^"]+)"\)')
ANIM_RE = re.compile(r'\{\s*"frames": \[(.*?)\],\s*"loop": (true|false),\s*"name": &"([^"]+)",\s*"speed": ([\d.]+)\s*\}', re.S)
FRAME_TEX_RE = re.compile(r'"texture": SubResource\("([^"]+)"\)')


class ImportError_(Exception):
    pass


def parse_spriteframes(text: str) -> tuple[dict, dict, dict]:
    textures = {ext_id: path for path, ext_id in EXT_RE.findall(text)}
    regions = {}
    for sub_id, body in SUB_RE.findall(text):
        region = REGION_RE.search(body)
        atlas = ATLAS_RE.search(body)
        if not region or not atlas:
            raise ImportError_(f"AtlasTexture {sub_id} has no region or atlas")
        regions[sub_id] = (atlas.group(1), tuple(int(float(v)) for v in region.groups()))
    animations = {}
    for frames, loop, name, speed in ANIM_RE.findall(text):
        animations[name] = {
            "frames": FRAME_TEX_RE.findall(frames),
            "loop": loop == "true",
            "fps": float(speed),
        }
    if not animations:
        raise ImportError_("no animations found in the SpriteFrames resource")
    return textures, regions, animations


def import_asset(asset_id: str) -> dict:
    folder = SOURCE / asset_id
    config_path = folder / "import.json"
    if not config_path.exists():
        raise ImportError_(f"missing art/unitforge/{asset_id}/import.json (licence, attribution, animation names)")
    config = json.loads(config_path.read_text())
    for field in ("license", "attribution", "role", "animation_map"):
        if not config.get(field):
            raise ImportError_(f"import.json needs {field!r}")
    tres_files = sorted(folder.rglob("*.tres"))
    if len(tres_files) != 1:
        raise ImportError_(f"expected exactly one SpriteFrames .tres, found {len(tres_files)}")
    textures, regions, source_anims = parse_spriteframes(tres_files[0].read_text())
    images = {}
    for ext_id, res_path in textures.items():
        candidates = list(folder.rglob(Path(res_path).name))
        if len(candidates) != 1:
            raise ImportError_(f"cannot find the texture {res_path} in the upload")
        images[ext_id] = Image.open(candidates[0]).convert("RGBA")

    rows = []
    frame_size = None
    for game_name, source_name in config["animation_map"].items():
        if source_name not in source_anims:
            raise ImportError_(f"animation {source_name!r} not in the export (has {sorted(source_anims)})")
        cells = []
        for sub_id in source_anims[source_name]["frames"]:
            atlas_id, (x, y, w, h) = regions[sub_id]
            image = images[atlas_id]
            if frame_size is None:
                frame_size = (w, h)
            if (w, h) != frame_size:
                raise ImportError_(f"{source_name}: frames are not all {frame_size}")
            if x < 0 or y < 0 or x + w > image.width or y + h > image.height:
                raise ImportError_(f"{source_name}: region {x},{y},{w},{h} lies outside the texture")
            cell = image.crop((x, y, x + w, y + h))
            if cell.getbbox() is None:
                raise ImportError_(f"{source_name}: a frame is completely transparent")
            cells.append(cell)
        rows.append((game_name, cells, source_anims[source_name]))
    width = max(len(cells) for _, cells, _ in rows) * frame_size[0]
    sheet = Image.new("RGBA", (width, frame_size[1] * len(rows)), (0, 0, 0, 0))
    animations = {}
    for index, (name, cells, source) in enumerate(rows):
        for column, cell in enumerate(cells):
            sheet.alpha_composite(cell, (column * frame_size[0], index * frame_size[1]))
        animations[name] = {"row": index, "frames": len(cells), "fps": source["fps"], "loop": source["loop"],
                            "source": config["animation_map"][name]}
    out = OUT_DIR / asset_id
    out.mkdir(parents=True, exist_ok=True)
    sheet.save(out / "sheet.png", optimize=True)
    (out / "credits.json").write_text(json.dumps([{
        "file": f"art/unitforge/{asset_id}",
        "authors": [config["attribution"]],
        "license": config["license"],
        "urls": ["https://www.unitforge.net/character"],
    }], indent=2) + "\n")
    idle = animations.get("idle") or next(iter(animations.values()))
    box = sheet.crop((0, idle["row"] * frame_size[1], frame_size[0], (idle["row"] + 1) * frame_size[1])).getbbox()
    return {
        "source": "unitforge",
        "role": config["role"],
        "sheet": f"res://assets/characters/{asset_id}/sheet.png",
        "frame_size": list(frame_size),
        "origin": [frame_size[0] // 2, box[3] if box else frame_size[1]],
        "facing": config.get("facing", "right"),
        "animations": animations,
        "licenses": [config["license"]],
        "credits": f"res://assets/characters/{asset_id}/credits.json",
        "status": "imported",
    }


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    if sys.argv[1:]:
        wanted = sys.argv[1:]
    else:
        wanted = sorted(p.name for p in SOURCE.iterdir() if p.is_dir()) if SOURCE.exists() else []
    failures = 0
    for asset_id in wanted:
        try:
            manifest["assets"][asset_id] = import_asset(asset_id)
            print(f"imported {asset_id}")
        except ImportError_ as error:
            failures += 1
            print(f"NOT IMPORTED {asset_id}: {error}", file=sys.stderr)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"{len(wanted) - failures} imported, {failures} not imported")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
