#!/usr/bin/env python3
"""Generates the training dummy: an original wooden sparring post, drawn by code.

  python3 tools/assets/gen_dummy.py

A wing-chun style post on a plank stand, with a straw-padded body, a painted
target, a burlap head and three practice arms. Animations: idle (straw
sways), hurt (rocks back and settles, straw flies) and down (tips over).
Writes client/assets/characters/training_dummy/ (sheet and credits) and the
manifest entry; make_spriteframes.py then builds its SpriteFrames.
"""

from __future__ import annotations

import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ASSET_ID = "training_dummy"
OUT = ROOT / "client" / "assets" / "characters" / ASSET_ID
MANIFEST = ROOT / "client" / "assets" / "manifest.json"

# Wide frames so the dummy can lie flat when knocked over.
FRAME = (112, 64)
PIVOT = (56, 61)

OUTLINE = (34, 22, 16, 255)
WOOD = (150, 98, 56, 255)
WOOD_DARK = (112, 70, 38, 255)
WOOD_LIGHT = (184, 128, 78, 255)
STRAW = (222, 186, 96, 255)
STRAW_DARK = (176, 140, 60, 255)
ROPE = (120, 92, 60, 255)
BURLAP = (196, 168, 120, 255)
BURLAP_DARK = (150, 124, 84, 255)
PAINT = (196, 52, 40, 255)
CREAM = (238, 226, 200, 255)

# Animation name -> list of (tilt degrees, straw sway) per frame.
ANIMATIONS = {
    "idle": [(0, 0), (0, 1)],
    "walk": [(0, 0), (0, 1)],
    "light": [(0, 0)],
    "hurt": [(10, 2), (-6, -1), (3, 1), (0, 0)],
    "down": [(18, 1), (42, 2), (68, 2), (86, 0), (90, 0)],
}
FPS = {"idle": 2, "walk": 2, "light": 4, "hurt": 12, "down": 12}


def draw_upright(sway: int) -> Image.Image:
    """The dummy standing, base centre at PIVOT."""
    image = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    cx, base = PIVOT
    # Plank stand.
    d.rectangle((cx - 16, base - 4, cx + 16, base), fill=OUTLINE)
    d.rectangle((cx - 15, base - 3, cx + 15, base - 1), fill=WOOD_DARK)
    d.line((cx - 15, base - 3, cx + 15, base - 3), fill=WOOD)
    d.rectangle((cx - 4, base - 9, cx + 4, base - 4), fill=OUTLINE)
    d.rectangle((cx - 3, base - 8, cx + 3, base - 4), fill=WOOD_DARK)
    # Post with grain.
    d.rectangle((cx - 4, 14, cx + 4, base - 8), fill=OUTLINE)
    d.rectangle((cx - 3, 15, cx + 3, base - 8), fill=WOOD)
    d.line((cx - 1, 16, cx - 1, base - 9), fill=WOOD_DARK)
    d.line((cx + 2, 15, cx + 2, base - 9), fill=WOOD_LIGHT)
    # Practice arms: two high, angled out; one low, straight ahead.
    for y, x0, x1 in ((24, cx + 4, cx + 15), (24, cx - 15, cx - 4)):
        d.rectangle((min(x0, x1), y - 2, max(x0, x1), y + 1), fill=OUTLINE)
        d.rectangle((min(x0, x1) + 1, y - 1, max(x0, x1) - 1, y), fill=WOOD_LIGHT)
    d.rectangle((cx + 4, 38, cx + 13, 41), fill=OUTLINE)
    d.rectangle((cx + 5, 39, cx + 12, 40), fill=WOOD_LIGHT)
    # Straw padding bound with rope, with a painted target.
    d.rounded_rectangle((cx - 9, 26, cx + 9, 48), radius=4, fill=OUTLINE)
    d.rounded_rectangle((cx - 8, 27, cx + 8, 47), radius=4, fill=STRAW)
    for x in range(cx - 7, cx + 8, 3):
        d.line((x + sway, 28, x, 46), fill=STRAW_DARK)
    for y in (30, 44):
        d.line((cx - 8, y, cx + 8, y), fill=ROPE)
        d.line((cx - 8, y + 1, cx + 8, y + 1), fill=OUTLINE)
    d.ellipse((cx - 5, 33, cx + 5, 42), fill=OUTLINE)
    d.ellipse((cx - 4, 34, cx + 4, 41), fill=CREAM)
    d.ellipse((cx - 3, 35, cx + 3, 40), fill=PAINT)
    d.ellipse((cx - 1, 36, cx + 1, 39), fill=CREAM)
    # Straw tufts poking out at the bottom.
    for x in (cx - 7, cx - 2, cx + 3, cx + 7):
        d.line((x, 48, x + sway, 51), fill=STRAW_DARK)
    # Burlap head with stitched features and a rope collar.
    d.rounded_rectangle((cx - 7, 4, cx + 7, 18), radius=5, fill=OUTLINE)
    d.rounded_rectangle((cx - 6, 5, cx + 6, 17), radius=5, fill=BURLAP)
    d.line((cx - 6, 14, cx + 6, 14), fill=BURLAP_DARK)
    for x in (cx - 3, cx + 2):
        d.line((x, 8, x + 2, 10), fill=OUTLINE)
        d.line((x + 2, 8, x, 10), fill=OUTLINE)
    d.line((cx - 2, 13, cx + 3, 13), fill=OUTLINE)
    d.line((cx - 5, 18, cx + 5, 18), fill=ROPE)
    d.line((cx + 5 + sway, 3, cx + 7 + sway, 1), fill=STRAW)
    d.line((cx - 4, 3, cx - 5 - sway, 1), fill=STRAW)
    return image


def draw_frame(tilt: int, sway: int, flying: bool) -> Image.Image:
    upright = draw_upright(sway)
    # Rotate about the stand: positive tilts the top backwards (left; the
    # dummy faces right like every character sheet).
    image = upright.rotate(tilt, resample=Image.Resampling.NEAREST, center=PIVOT)
    if flying:
        d = ImageDraw.Draw(image)
        rng = random.Random(tilt)
        for _ in range(6):
            x, y = PIVOT[0] + rng.randint(2, 16), rng.randint(24, 44)
            d.line((x, y, x + rng.randint(1, 3), y - rng.randint(0, 2)), fill=STRAW)
    return image


def render() -> tuple[Image.Image, dict]:
    names = list(ANIMATIONS)
    columns = max(len(frames) for frames in ANIMATIONS.values())
    sheet = Image.new("RGBA", (FRAME[0] * columns, FRAME[1] * len(names)), (0, 0, 0, 0))
    animations = {}
    for row, name in enumerate(names):
        for column, (tilt, sway) in enumerate(ANIMATIONS[name]):
            flying = name == "hurt" and column < 2
            sheet.alpha_composite(draw_frame(tilt, sway, flying), (column * FRAME[0], row * FRAME[1]))
        animations[name] = {
            "row": row,
            "frames": len(ANIMATIONS[name]),
            "fps": FPS[name],
            "loop": name in ("idle", "walk"),
        }
    return sheet, animations


def manifest_entry(animations: dict) -> dict:
    return {
        "animations": animations,
        "credits": f"res://assets/characters/{ASSET_ID}/credits.json",
        "facing": "right",
        "frame_size": list(FRAME),
        "generator": {"script": "tools/assets/gen_dummy.py"},
        "licenses": ["MIT"],
        "origin": list(PIVOT),
        "role": "enemy",
        "sheet": f"res://assets/characters/{ASSET_ID}/sheet.png",
        "source": "original",
        "status": "imported",
    }


CREDITS = [
    {
        "file": "tools/assets/gen_dummy.py",
        "authors": ["Ironbound Streets contributors"],
        "license": "MIT",
        "urls": [],
    }
]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet, animations = render()
    sheet.save(OUT / "sheet.png", optimize=True)
    (OUT / "credits.json").write_text(json.dumps(CREDITS, indent=2) + "\n")
    manifest = json.loads(MANIFEST.read_text())
    manifest["assets"][ASSET_ID] = manifest_entry(animations)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {ASSET_ID}: {', '.join(animations)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
