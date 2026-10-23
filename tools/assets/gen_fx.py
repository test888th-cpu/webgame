#!/usr/bin/env python3
"""Generates the combat effects: original pixel-art animations drawn by code.

  python3 tools/assets/gen_fx.py

Writes client/assets/fx/fx.png (one row per effect) and records each effect's
frames in the manifest's "fx" section. Only integer maths and a seeded random
generator are used, so the output is identical on every machine and the
validator can check it is current.
"""

from __future__ import annotations

import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "client" / "assets" / "fx"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"

# 16 directions as (cos, sin) * 1000, so no floating-point trigonometry.
DIRS = [
    (1000, 0), (924, 383), (707, 707), (383, 924), (0, 1000), (-383, 924), (-707, 707), (-924, 383),
    (-1000, 0), (-924, -383), (-707, -707), (-383, -924), (0, -1000), (383, -924), (707, -707), (924, -383),
]

WHITE = (255, 255, 255)
GOLD = (255, 214, 90)
ORANGE = (255, 140, 40)
RED = (230, 60, 30)
CYAN = (120, 220, 255)
BLUE = (70, 140, 255)
GREEN = (120, 255, 150)
DUST = (196, 186, 170)


def rgba(color: tuple, alpha: int) -> tuple:
    return color + (max(0, min(255, alpha)),)


def fade(frame: int, frames: int, hold: int = 1) -> int:
    """Full alpha for `hold` frames, then a linear fade to near zero."""
    if frame < hold:
        return 255
    return 255 * (frames - frame) // (frames - hold + 1)


def layer(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def ray(d: ImageDraw.ImageDraw, cx: int, cy: int, direction: int, r0: int, r1: int, color: tuple, width: int = 1) -> None:
    c, s = DIRS[direction % 16]
    d.line((cx + c * r0 // 1000, cy + s * r0 // 1000, cx + c * r1 // 1000, cy + s * r1 // 1000), fill=color, width=width)


def star(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int, color: tuple) -> None:
    d.polygon([(cx, cy - r), (cx + r // 3, cy), (cx, cy + r), (cx - r // 3, cy)], fill=color)
    d.polygon([(cx - r, cy), (cx, cy - r // 3), (cx + r, cy), (cx, cy + r // 3)], fill=color)


# Each effect: frames, frame size, fps, origin (the point placed at the
# spawn position), blend ("add" glows or "mix"), and a painter(frame) -> image.


def hit(f: int) -> Image.Image:
    image, d = layer(32, 32)
    a = fade(f, 5)
    r = 4 + f * 3
    for k in range(0, 16, 2):
        ray(d, 16, 16, k + (f % 2), r - 3, r + 4 - f, rgba(GOLD, a))
    if f < 3:
        star(d, 16, 16, 9 - f * 2, rgba(WHITE, a))
    d.ellipse((16 - r, 16 - r, 16 + r, 16 + r), outline=rgba(ORANGE, a // 2))
    return image


def hit_heavy(f: int) -> Image.Image:
    image, d = layer(48, 48)
    a = fade(f, 6)
    r = 6 + f * 4
    d.ellipse((24 - r, 24 - r, 24 + r, 24 + r), outline=rgba(ORANGE, a), width=2)
    for k in range(16):
        length = 8 if k % 2 else 14
        ray(d, 24, 24, k, r - 4, r + length - f * 2, rgba(GOLD if k % 2 else WHITE, a), 2 if k % 4 == 0 else 1)
    if f < 3:
        d.ellipse((18, 18, 30, 30), fill=rgba(GOLD, a // 2))
        star(d, 24, 24, 14 - f * 3, rgba(WHITE, a))
    return image


def block(f: int) -> Image.Image:
    image, d = layer(32, 32)
    a = fade(f, 4)
    r = 8 + f * 2
    d.arc((16 - r, 16 - r, 16 + r, 16 + r), 120, 240, fill=rgba(CYAN, a), width=2)
    d.arc((14 - r, 16 - r, 14 + r, 16 + r), 140, 220, fill=rgba(WHITE, a))
    for k in (7, 8, 9):
        ray(d, 16, 16, k, r + 1, r + 5, rgba(BLUE, a))
    return image


def dust(f: int) -> Image.Image:
    image, d = layer(40, 16)
    a = fade(f, 5) * 3 // 4
    for i, (x, size) in enumerate(((10, 4), (20, 6), (30, 4), (15, 3), (26, 3))):
        spread = (x - 20) * f // 3
        r = size + f
        cx, cy = x + spread, 11 - f - (i % 2)
        d.ellipse((cx - r, cy - r // 2, cx + r, cy + r // 2), fill=rgba(DUST, a))
    return image


def uppercut(f: int) -> Image.Image:
    image, d = layer(48, 64)
    a = fade(f, 6, 2)
    top = 50 - f * 9
    d.arc((8, top, 40, top + 40), 200, 340, fill=rgba(GOLD, a), width=3)
    d.arc((12, top + 4, 36, top + 36), 210, 330, fill=rgba(WHITE, a), width=1)
    rng = random.Random(f)
    for _ in range(5):
        x, y = rng.randint(10, 38), rng.randint(top + 10, 60)
        d.point((x, y), fill=rgba(ORANGE, a))
    return image


def whirlwind(f: int) -> Image.Image:
    image, d = layer(96, 48)
    a = fade(f, 6, 2)
    for i, (rx, ry, color) in enumerate(((44, 14, CYAN), (36, 10, WHITE), (28, 7, BLUE))):
        start = (f * 70 + i * 120) % 360
        d.arc((48 - rx, 30 - ry, 48 + rx, 30 + ry), start, start + 220, fill=rgba(color, a), width=2)
    rng = random.Random(10 + f)
    for _ in range(6):
        x, y = rng.randint(6, 90), rng.randint(14, 44)
        d.line((x, y, x + 4, y), fill=rgba(WHITE, a // 2))
    return image


def rush(f: int) -> Image.Image:
    image, d = layer(64, 32)
    a = fade(f, 5, 2)
    rng = random.Random(20 + f)
    for _ in range(9):
        y = rng.randint(4, 28)
        length = rng.randint(12, 34) - f * 3
        x = 62 - length - rng.randint(0, 8)
        color = WHITE if rng.random() < 0.4 else ORANGE
        d.line((x, y, x + max(2, length), y), fill=rgba(color, a))
    return image


def slam(f: int) -> Image.Image:
    image, d = layer(128, 48)
    a = fade(f, 7, 2)
    rx, ry = 12 + f * 9, 4 + f * 2
    d.ellipse((64 - rx, 40 - ry, 64 + rx, 40 + ry), outline=rgba(ORANGE, a), width=2)
    d.ellipse((64 - rx + 6, 41 - ry, 64 + rx - 6, 39 + ry), outline=rgba(GOLD, a // 2))
    rng = random.Random(30)
    for i in range(9):
        x = 64 + (i - 4) * 12 + rng.randint(-3, 3)
        height = (24 - abs(i - 4) * 4) * max(0, 4 - abs(f - 2)) // 4
        if height > 2:
            d.polygon([(x - 3, 41), (x, 41 - height), (x + 3, 41)], fill=rgba(ORANGE, a))
            d.line((x, 41 - height + 3, x, 40), fill=rgba(GOLD, a))
    for i in range(6):
        x = 64 + (i - 3) * 14 + f * (i - 3) * 2
        y = 38 - f * 3 + (i % 2) * 4
        d.rectangle((x, y, x + 1, y + 1), fill=rgba((110, 90, 80), a))
    return image


def levelup(f: int) -> Image.Image:
    image, d = layer(64, 96)
    a = 255 if f < 5 else 255 * (8 - f) // 4
    width = 6 + (f % 3) * 2 if f < 6 else 4
    d.rectangle((32 - width, 0, 32 + width, 88), fill=rgba(GOLD, a // 3))
    d.rectangle((32 - width // 2, 0, 32 + width // 2, 88), fill=rgba(WHITE, a // 3))
    rx = 10 + f * 3
    d.ellipse((32 - rx, 86 - rx // 3, 32 + rx, 86 + rx // 3), outline=rgba(GOLD, a), width=2)
    rng = random.Random(40)
    for i in range(10):
        x = rng.randint(14, 50)
        y = 90 - ((rng.randint(0, 60) + f * 10) % 90)
        star(d, x, y, 3 if i % 3 == 0 else 2, rgba(WHITE if i % 2 else GOLD, a))
    return image


def heal(f: int) -> Image.Image:
    image, d = layer(32, 48)
    a = fade(f, 6, 2)
    rng = random.Random(50)
    for i in range(7):
        x = rng.randint(6, 26)
        y = 44 - ((rng.randint(0, 20) + f * 6) % 44)
        if i % 3 == 0:
            d.rectangle((x - 1, y - 3, x + 1, y + 3), fill=rgba(GREEN, a))
            d.rectangle((x - 3, y - 1, x + 3, y + 1), fill=rgba(GREEN, a))
        else:
            d.point((x, y), fill=rgba(WHITE, a))
    d.ellipse((4, 40, 28, 46), outline=rgba(GREEN, a // 2))
    return image


EFFECTS = {
    "hit": {"paint": hit, "frames": 5, "size": (32, 32), "fps": 30, "origin": (16, 16), "blend": "add"},
    "hit_heavy": {"paint": hit_heavy, "frames": 6, "size": (48, 48), "fps": 24, "origin": (24, 24), "blend": "add"},
    "block": {"paint": block, "frames": 4, "size": (32, 32), "fps": 24, "origin": (16, 16), "blend": "add"},
    "dust": {"paint": dust, "frames": 5, "size": (40, 16), "fps": 16, "origin": (20, 14), "blend": "mix"},
    "uppercut": {"paint": uppercut, "frames": 6, "size": (48, 64), "fps": 24, "origin": (24, 60), "blend": "add"},
    "whirlwind": {"paint": whirlwind, "frames": 6, "size": (96, 48), "fps": 20, "origin": (48, 42), "blend": "add"},
    "rush": {"paint": rush, "frames": 5, "size": (64, 32), "fps": 20, "origin": (58, 28), "blend": "add"},
    "slam": {"paint": slam, "frames": 7, "size": (128, 48), "fps": 18, "origin": (64, 42), "blend": "add"},
    "levelup": {"paint": levelup, "frames": 8, "size": (64, 96), "fps": 12, "origin": (32, 88), "blend": "add"},
    "heal": {"paint": heal, "frames": 6, "size": (32, 48), "fps": 12, "origin": (16, 44), "blend": "add"},
}


def render() -> tuple[Image.Image, dict]:
    width = max(e["frames"] * e["size"][0] for e in EFFECTS.values())
    height = sum(e["size"][1] for e in EFFECTS.values())
    sheet = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    entries = {}
    y = 0
    for name, effect in EFFECTS.items():
        w, h = effect["size"]
        for frame in range(effect["frames"]):
            sheet.alpha_composite(effect["paint"](frame), (frame * w, y))
        entries[name] = {
            "y": y,
            "size": [w, h],
            "frames": effect["frames"],
            "fps": effect["fps"],
            "origin": list(effect["origin"]),
            "blend": effect["blend"],
        }
        y += h
    return sheet, entries


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet, entries = render()
    sheet.save(OUT / "fx.png", optimize=True)
    manifest = json.loads(MANIFEST.read_text())
    manifest["fx"] = {
        "license": "MIT (original art generated by tools/assets/gen_fx.py)",
        "sheet": "res://assets/fx/fx.png",
        "effects": entries,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(entries)} effects")
    return 0


if __name__ == "__main__":
    sys.exit(main())
