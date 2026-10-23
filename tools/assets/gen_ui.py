#!/usr/bin/env python3
"""Generates the interface icons: original 16x16 pixel art drawn by code.

  python3 tools/assets/gen_ui.py

Writes client/assets/ui/icons.png and records each icon's region in the
manifest's "ui" section. Items name their icon in items.json ("icon"); the
validator checks every named icon exists and that this output is current.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "client" / "assets" / "ui"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"
SIZE = 16

OUTLINE = (24, 20, 28, 255)


def bun(d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 5, 13, 14), fill=OUTLINE)
    d.ellipse((3, 6, 12, 13), fill=(246, 236, 214, 255))
    d.line((5, 8, 10, 8), fill=(214, 196, 168, 255))
    d.point((7, 7), fill=(214, 196, 168, 255))
    d.line((4, 12, 11, 12), fill=(222, 206, 180, 255))


def tea(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((3, 7, 11, 14), fill=OUTLINE)
    d.rectangle((4, 8, 10, 13), fill=(232, 228, 216, 255))
    d.rectangle((4, 8, 10, 9), fill=(196, 140, 60, 255))
    d.rectangle((11, 9, 13, 12), outline=OUTLINE)
    for x, y in ((5, 5), (6, 4), (8, 5), (9, 3)):
        d.point((x, y), fill=(200, 210, 220, 255))


def knuckles(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((3, 4, 12, 13), fill=OUTLINE)
    d.rectangle((4, 5, 11, 12), fill=(224, 170, 130, 255))
    for x in (4, 6, 8, 10):
        d.line((x, 5, x, 8), fill=(190, 136, 100, 255))
    d.rectangle((4, 9, 11, 11), fill=(236, 236, 240, 255))
    d.line((4, 10, 11, 10), fill=(196, 196, 206, 255))


def wrench(d: ImageDraw.ImageDraw) -> None:
    d.line((4, 12, 11, 5), fill=OUTLINE, width=4)
    d.line((4, 12, 11, 5), fill=(150, 156, 170, 255), width=2)
    d.ellipse((9, 2, 14, 7), fill=OUTLINE)
    d.ellipse((10, 3, 13, 6), fill=(150, 156, 170, 255))
    d.point((12, 4), fill=OUTLINE)
    d.ellipse((2, 10, 6, 14), fill=(150, 156, 170, 255), outline=OUTLINE)


def jacket(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(5, 2), (10, 2), (14, 5), (13, 9), (11, 8), (11, 14), (4, 14), (4, 8), (2, 9), (1, 5)], fill=OUTLINE)
    d.polygon([(5, 3), (10, 3), (13, 5), (12, 7), (10, 6), (10, 13), (5, 13), (5, 6), (3, 7), (2, 5)], fill=(120, 84, 52, 255))
    d.line((7, 4, 7, 13), fill=(92, 62, 38, 255))
    d.point((8, 8), fill=(220, 190, 90, 255))
    d.point((8, 11), fill=(220, 190, 90, 255))


def whistle(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((2, 7, 10, 12), fill=OUTLINE)
    d.rectangle((3, 8, 9, 11), fill=(222, 178, 70, 255))
    d.ellipse((7, 6, 14, 13), fill=OUTLINE)
    d.ellipse((8, 7, 13, 12), fill=(222, 178, 70, 255))
    d.point((10, 9), fill=OUTLINE)
    d.line((2, 6, 5, 3), fill=(180, 60, 50, 255))


def coin(d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 2, 13, 13), fill=OUTLINE)
    d.ellipse((3, 3, 12, 12), fill=(242, 193, 74, 255))
    d.ellipse((5, 5, 10, 10), outline=(196, 140, 40, 255))
    d.point((5, 4), fill=(255, 240, 180, 255))


def quest(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((3, 2, 12, 14), fill=OUTLINE)
    d.rectangle((4, 3, 11, 13), fill=(236, 222, 186, 255))
    for y in (5, 7, 9):
        d.line((5, y, 10, y), fill=(150, 120, 90, 255))
    d.rectangle((9, 11, 11, 13), fill=(200, 60, 50, 255))


def star(d: ImageDraw.ImageDraw) -> None:
    points = [(8, 1), (10, 6), (15, 6), (11, 9), (13, 14), (8, 11), (3, 14), (5, 9), (1, 6), (6, 6)]
    d.polygon(points, fill=OUTLINE)
    inner = [(8, 3), (9, 7), (13, 7), (10, 9), (11, 12), (8, 10), (5, 12), (6, 9), (3, 7), (7, 7)]
    d.polygon(inner, fill=(242, 193, 74, 255))


def heart(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(8, 14), (1, 7), (1, 4), (4, 2), (8, 5), (12, 2), (15, 4), (15, 7)], fill=OUTLINE)
    d.polygon([(8, 12), (2, 6), (2, 5), (4, 3), (8, 6), (12, 3), (14, 5), (14, 6)], fill=(224, 82, 74, 255))
    d.point((4, 5), fill=(255, 170, 160, 255))


ICONS = {
    "steamed_bun": bun,
    "ginger_tea": tea,
    "taped_knuckles": knuckles,
    "foreman_wrench": wrench,
    "work_jacket": jacket,
    "brass_whistle": whistle,
    "coin": coin,
    "quest": quest,
    "star": star,
    "heart": heart,
}


def render() -> tuple[Image.Image, dict]:
    columns = 8
    rows = (len(ICONS) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * SIZE, rows * SIZE), (0, 0, 0, 0))
    regions = {}
    for index, (name, painter) in enumerate(ICONS.items()):
        cell = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        painter(ImageDraw.Draw(cell))
        x, y = (index % columns) * SIZE, (index // columns) * SIZE
        sheet.alpha_composite(cell, (x, y))
        regions[name] = [x, y, SIZE, SIZE]
    return sheet, regions


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet, regions = render()
    sheet.save(OUT / "icons.png", optimize=True)
    manifest = json.loads(MANIFEST.read_text())
    manifest["ui"] = {
        "license": "MIT (original art generated by tools/assets/gen_ui.py)",
        "icons": {"sheet": "res://assets/ui/icons.png", "regions": regions},
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(regions)} icons")
    return 0


if __name__ == "__main__":
    sys.exit(main())
