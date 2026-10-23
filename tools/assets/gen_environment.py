#!/usr/bin/env python3
"""Generates the scenery for every area: original pixel art, drawn by code.

  python3 tools/assets/gen_environment.py

For each area in client/data/areas.json (its width, palette and "theme") it
writes to client/assets/environment/<area>/:

  sky.png        static backdrop: gradient, stars, moon        (640 x 230)
  far.png        distant skyline, tiles horizontally, parallax (640 x 230)
  buildings.png  the street's facades at full area width       (W x 230)
  ground.png     sidewalk, kerb and street at full area width  (W x 130)

and client/assets/environment/props.png (shared prop sprites), then records
everything, including deterministic prop placements, in the manifest's
"environment" section. Output depends only on the area data and a seed derived
from the area id, so it is reproducible and CI can check it is up to date.

Style rules (to sit with the 64x64 LPC characters): hard pixels, no
anti-aliasing, a small palette per area derived from its data palette, light
from lamps and windows rather than global shading.
"""

from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / "client"
AREAS = CLIENT / "data" / "areas.json"
OUT = CLIENT / "assets" / "environment"
MANIFEST = CLIENT / "assets" / "manifest.json"

VIEW_W = 640
SKY_H = 230  # the sidewalk starts at y = 230
GROUND_TOP = 230  # sidewalk 230..250, street 250..360
GROUND_H = 130
LANE_MARK_Y = 298 - GROUND_TOP

# Props: name -> (x, y, w, h) in props.png, and the anchor (feet) offset.
PROP_SIZE = {
    "lamp": (16, 72),
    "crate": (20, 18),
    "barrel": (14, 18),
    "bin": (16, 20),
    "hydrant": (10, 14),
    "stall": (52, 44),
    "lantern_string": (64, 16),
    "cones": (12, 12),
    "pipe_valve": (18, 26),
    "bench": (32, 14),
    "glow": (48, 48),
}


def rgb(hex_colour: str) -> tuple[int, int, int]:
    h = hex_colour.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def shade(colour: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, int(c * factor))) for c in colour)  # type: ignore[return-value]


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def seeded(area_id: str, salt: str) -> random.Random:
    digest = hashlib.sha256(f"{area_id}:{salt}".encode()).hexdigest()
    return random.Random(int(digest[:16], 16))


# ---------------------------------------------------------------- sky


def draw_sky(area_id: str, palette: dict) -> Image.Image:
    rng = seeded(area_id, "sky")
    top = shade(rgb(palette["sky"]), 0.55)
    bottom = mix(rgb(palette["sky"]), rgb(palette.get("windows", "#f2c96b")), 0.18)
    image = Image.new("RGBA", (VIEW_W, SKY_H))
    draw = ImageDraw.Draw(image)
    # Banded gradient (pixel-art style: 8 px bands, no smooth blend).
    bands = SKY_H // 8 + 1
    for band in range(bands):
        colour = mix(top, bottom, band / (bands - 1))
        draw.rectangle((0, band * 8, VIEW_W, band * 8 + 7), fill=(*colour, 255))
    for _ in range(90):
        x, y = rng.randrange(VIEW_W), rng.randrange(SKY_H - 70)
        bright = rng.choice([160, 200, 255])
        image.putpixel((x, y), (bright, bright, min(255, bright + 20), 255))
        if rng.random() < 0.08 and 0 < x < VIEW_W - 1:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                image.putpixel((x + dx, y + dy), (bright // 2, bright // 2, bright // 2, 255))
    mx, my = rng.randrange(380, 580), rng.randrange(24, 60)
    moon = (236, 232, 210, 255)
    draw.ellipse((mx - 14, my - 14, mx + 14, my + 14), fill=(*shade(moon[:3], 0.35), 255))
    draw.ellipse((mx - 11, my - 11, mx + 11, my + 11), fill=moon)
    draw.ellipse((mx - 5, my - 6, mx + 1, my), fill=(210, 205, 185, 255))
    draw.ellipse((mx + 3, my + 2, mx + 7, my + 6), fill=(214, 209, 190, 255))
    return image


# ---------------------------------------------------------------- far skyline


def draw_far(area_id: str, palette: dict, theme: str) -> Image.Image:
    rng = seeded(area_id, "far")
    base = mix(rgb(palette["sky"]), (10, 10, 18), 0.35)
    lit = mix(rgb(palette.get("windows", "#f2c96b")), base, 0.55)
    image = Image.new("RGBA", (VIEW_W, SKY_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x = 0
    while x < VIEW_W:
        w = rng.randrange(28, 70)
        h = rng.randrange(60, 150)
        top = SKY_H - h
        draw.rectangle((x, top, min(VIEW_W - 1, x + w - 2), SKY_H), fill=(*base, 255))
        if rng.random() < 0.3:  # stepped roof
            draw.rectangle((x + w // 4, top - 10, x + w // 2, top), fill=(*base, 255))
        if rng.random() < 0.2:  # antenna
            draw.line((x + w // 2, top - 22, x + w // 2, top), fill=(*base, 255))
            image.putpixel((min(VIEW_W - 1, x + w // 2), top - 22), (220, 70, 60, 255))
        for wy in range(top + 6, SKY_H - 6, 7):
            for wx in range(x + 4, x + w - 5, 6):
                if rng.random() < 0.18 and wx < VIEW_W - 2:
                    draw.rectangle((wx, wy, wx + 1, wy + 2), fill=(*lit, 255))
        x += w
    if theme == "depot":  # a harbour crane silhouette
        cx = rng.randrange(120, 420)
        draw.rectangle((cx, 60, cx + 5, SKY_H), fill=(*base, 255))
        draw.rectangle((cx - 60, 60, cx + 90, 65), fill=(*base, 255))
        draw.line((cx + 2, 30, cx - 60, 60), fill=(*base, 255))
        draw.line((cx + 2, 30, cx + 90, 60), fill=(*base, 255))
        draw.line((cx + 70, 65, cx + 70, 110), fill=(*base, 255))
    # Tile seamlessly: copy the left edge's pixels where the last building ran off.
    return image


# ---------------------------------------------------------------- buildings


def brick(draw: ImageDraw.ImageDraw, box, colour, rng: random.Random) -> None:
    x0, y0, x1, y1 = box
    mortar = shade(colour, 0.72)
    draw.rectangle(box, fill=(*colour, 255))
    for row, y in enumerate(range(y0, y1, 4)):
        draw.line((x0, y, x1, y), fill=(*mortar, 255))
        offset = 0 if row % 2 else 4
        for x in range(x0 + offset, x1, 8):
            draw.line((x, y, x, min(y + 3, y1)), fill=(*mortar, 255))
            if rng.random() < 0.06:
                draw.rectangle((x + 1, y + 1, min(x + 6, x1), min(y + 3, y1)), fill=(*shade(colour, rng.choice([0.88, 1.1])), 255))


def panels(draw: ImageDraw.ImageDraw, box, colour) -> None:
    x0, y0, x1, y1 = box
    draw.rectangle(box, fill=(*colour, 255))
    for x in range(x0, x1, 3):
        draw.line((x, y0, x, y1), fill=(*shade(colour, 0.82 if (x // 3) % 2 else 1.08), 255))


def window(draw, x, y, w, h, frame, lit_colour, rng, lit: bool) -> None:
    draw.rectangle((x - 1, y - 1, x + w, y + h), fill=(*frame, 255))
    glass = lit_colour if lit else (28, 32, 44)
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=(*glass, 255))
    if lit:
        draw.rectangle((x, y, x + w - 1, y + 1), fill=(*shade(lit_colour, 0.8), 255))  # curtain rail
        if rng.random() < 0.4:
            draw.rectangle((x, y, x + w // 3, y + h - 1), fill=(*shade(lit_colour, 0.7), 255))  # curtain
    else:
        draw.line((x, y + h - 1, x + w - 1, y), fill=(44, 50, 66, 255))  # glint
    draw.line((x - 1, y + h + 1, x + w, y + h + 1), fill=(*shade(frame, 1.25), 255))  # sill
    if rng.random() < 0.08:  # air conditioner
        draw.rectangle((x + 1, y + h + 2, x + w - 2, y + h + 6), fill=(150, 150, 156, 255))
        draw.line((x + 2, y + h + 4, x + w - 3, y + h + 4), fill=(110, 110, 116, 255))


def sign(draw, x, y, w, colour, rng) -> None:
    draw.rectangle((x, y, x + w, y + 9), fill=(*shade(colour, 0.5), 255))
    draw.rectangle((x + 1, y + 1, x + w - 1, y + 8), fill=(*colour, 255))
    # Glyph-like blocks: suggests lettering without being any real text.
    cx = x + 3
    while cx < x + w - 4:
        gw = rng.choice([2, 3, 3, 4])
        draw.rectangle((cx, y + 3, cx + gw - 1, y + 6), fill=(250, 245, 230, 255))
        cx += gw + rng.choice([1, 1, 2])


def awning(draw, x0, x1, y, colour) -> None:
    stripe = shade(colour, 1.35)
    for x in range(x0, x1):
        c = colour if ((x - x0) // 4) % 2 else stripe
        draw.line((x, y, x, y + 7), fill=(*c, 255))
    for x in range(x0, x1, 4):  # scalloped edge
        draw.rectangle((x, y + 8, x + 1, y + 9), fill=(*(colour if (x // 4) % 2 else stripe), 255))
    draw.line((x0, y, x1, y), fill=(*shade(colour, 0.6), 255))


def draw_buildings(area_id: str, area: dict, theme: str) -> Image.Image:
    rng = seeded(area_id, "buildings")
    palette = area["palette"]
    width = int(area["width"])
    lit = rgb(palette.get("windows", "#f2c96b"))
    tones = [rgb(c) for c in palette["buildings"]]
    image = Image.new("RGBA", (width, SKY_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x = 0
    index = 0
    while x < width:
        w = rng.randrange(104, 184) if theme != "depot" else rng.randrange(150, 230)
        h = rng.randrange(120, 196)
        top = SKY_H - h
        base = shade(tones[index % len(tones)], rng.choice([1.15, 1.3, 1.45]))
        right = min(width - 1, x + w - 4)
        if theme == "depot":
            panels(draw, (x, top, right, SKY_H - 1), shade(base, 0.9))
            # Big rolling door and a high window band.
            door_w = rng.randrange(48, 80)
            dx = x + (w - door_w) // 2
            draw.rectangle((dx, SKY_H - 70, dx + door_w, SKY_H - 1), fill=(*shade(base, 0.6), 255))
            for yy in range(SKY_H - 68, SKY_H, 4):
                draw.line((dx + 2, yy, dx + door_w - 2, yy), fill=(*shade(base, 0.45), 255))
            for wx in range(x + 8, right - 12, 14):
                window(draw, wx, top + 14, 9, 6, shade(base, 0.5), lit, rng, rng.random() < 0.35)
            sign(draw, x + 10, top + 30, min(70, w - 24), rng.choice([(176, 60, 48), (52, 96, 160), (60, 130, 90)]), rng)
        else:
            if rng.random() < 0.55 or theme == "market":
                brick(draw, (x, top, right, SKY_H - 1), base, rng)
            else:
                draw.rectangle((x, top, right, SKY_H - 1), fill=(*base, 255))
                for yy in range(top + 2, SKY_H, 9):  # stucco cracks
                    if rng.random() < 0.2:
                        cx = rng.randrange(x + 4, max(x + 5, right - 4))
                        draw.line((cx, yy, cx + 3, yy + 4), fill=(*shade(base, 0.8), 255))
            frame = shade(base, 0.55)
            floors = (h - 46) // 26
            cols = max(1, (w - 16) // 22)
            for floor in range(floors):
                wy = top + 12 + floor * 26
                for col in range(cols):
                    wx = x + 10 + col * 22
                    if wx + 12 < right:
                        window(draw, wx, wy, 11, 14, frame, lit, rng, rng.random() < 0.42)
            if theme != "canal" and rng.random() < 0.45 and floors > 1:  # fire escape
                fx = x + 10 + rng.randrange(cols) * 22 - 3
                for floor in range(floors - 1):
                    fy = top + 12 + floor * 26 + 16
                    draw.rectangle((fx, fy, fx + 17, fy + 1), fill=(30, 30, 34, 255))
                    for rx in range(fx, fx + 18, 3):
                        draw.line((rx, fy - 5, rx, fy), fill=(30, 30, 34, 255))
                    draw.line((fx + 2, fy + 2, fx + 15, fy + 24), fill=(36, 36, 40, 255))
            # Ground floor: shop front.
            shop_top = SKY_H - 40
            draw.rectangle((x + 4, shop_top, right - 4, SKY_H - 1), fill=(*shade(base, 0.7), 255))
            draw.rectangle((x + 8, shop_top + 12, right - 26, SKY_H - 4), fill=(*mix(lit, (40, 30, 30), 0.35 if rng.random() < 0.6 else 0.85), 255))
            draw.rectangle((right - 22, shop_top + 10, right - 8, SKY_H - 1), fill=(*shade(base, 0.4), 255))  # door
            draw.point((right - 11, SKY_H - 16), fill=(220, 200, 120, 255))
            awning_colour = rng.choice([(176, 52, 52), (46, 110, 120), (196, 140, 40), (90, 60, 130), (60, 120, 70)])
            if theme == "market" or rng.random() < 0.6:
                awning(draw, x + 4, right - 4, shop_top - 2, awning_colour)
            sign(draw, x + 10, shop_top - 14, min(64, w - 30), shade(awning_colour, 0.9), rng)
        # Roof: parapet, water tower, chimneys or pipes.
        draw.rectangle((x, top - 3, right, top), fill=(*shade(base, 0.6), 255))
        roll = rng.random()
        if roll < 0.25 and theme != "depot":
            tx = x + rng.randrange(10, max(11, w - 30))
            draw.rectangle((tx, top - 26, tx + 16, top - 8), fill=(92, 64, 48, 255))
            for yy in range(top - 24, top - 8, 3):
                draw.line((tx, yy, tx + 16, yy), fill=(72, 50, 38, 255))
            draw.polygon([(tx - 2, top - 26), (tx + 8, top - 34), (tx + 18, top - 26)], fill=(70, 70, 76, 255))
            draw.line((tx + 2, top - 8, tx + 2, top - 3), fill=(40, 40, 44, 255))
            draw.line((tx + 14, top - 8, tx + 14, top - 3), fill=(40, 40, 44, 255))
        elif roll < 0.5:
            cx = x + rng.randrange(8, max(9, w - 16))
            draw.rectangle((cx, top - 12, cx + 6, top - 3), fill=(*shade(base, 0.5), 255))
        if theme == "canal":
            # Exterior pipes and a smoke stack.
            py = top + rng.randrange(10, max(11, h - 60))
            draw.rectangle((x, py, right, py + 4), fill=(96, 104, 92, 255))
            draw.line((x, py + 1, right, py + 1), fill=(130, 140, 124, 255))
            for jx in range(x + 6, right, 30):
                draw.rectangle((jx, py - 1, jx + 3, py + 5), fill=(70, 76, 66, 255))
            if rng.random() < 0.35:
                sx = x + rng.randrange(10, max(11, w - 20))
                draw.rectangle((sx, top - 46, sx + 9, top - 3), fill=(80, 60, 56, 255))
                draw.rectangle((sx, top - 46, sx + 9, top - 43), fill=(160, 70, 50, 255))
        x += w
        index += 1
    if theme == "canal":  # polluted canal between the buildings and the walkway
        water = mix(rgb(palette["street"]), (40, 110, 70), 0.5)
        draw.rectangle((0, SKY_H - 16, width, SKY_H - 1), fill=(*water, 255))
        for i in range(0, width, 6):
            if rng.random() < 0.5:
                y = SKY_H - rng.randrange(3, 15)
                draw.line((i, y, i + 3, y), fill=(*shade(water, 1.4), 255))
        for post in range(0, width, 24):  # railing
            draw.rectangle((post, SKY_H - 22, post + 1, SKY_H - 1), fill=(60, 62, 66, 255))
        draw.line((0, SKY_H - 22, width, SKY_H - 22), fill=(84, 86, 92, 255))
        draw.line((0, SKY_H - 14, width, SKY_H - 14), fill=(70, 72, 78, 255))
    if theme == "depot":  # stacked shipping containers in front of the sheds
        cx = rng.randrange(40, 120)
        while cx < width - 80:
            colour = rng.choice([(150, 52, 40), (40, 90, 140), (60, 120, 80), (180, 130, 40)])
            stacks = rng.choice([1, 1, 2])
            for level in range(stacks):
                y1 = SKY_H - 1 - level * 26
                panels(draw, (cx, y1 - 25, cx + 70, y1), colour)
                draw.rectangle((cx, y1 - 25, cx + 70, y1 - 24), fill=(*shade(colour, 0.6), 255))
                draw.rectangle((cx + 62, y1 - 22, cx + 64, y1 - 2), fill=(*shade(colour, 0.55), 255))
            cx += rng.randrange(160, 320)
    return image


# ---------------------------------------------------------------- ground


def draw_ground(area_id: str, area: dict, theme: str) -> Image.Image:
    rng = seeded(area_id, "ground")
    palette = area["palette"]
    width = int(area["width"])
    walk = rgb(palette["sidewalk"])
    street = rgb(palette["street"])
    image = Image.new("RGBA", (width, GROUND_H), (*street, 255))
    draw = ImageDraw.Draw(image)
    # Sidewalk slabs.
    draw.rectangle((0, 0, width, 19), fill=(*walk, 255))
    for x in range(0, width, 24):
        draw.line((x, 0, x, 18), fill=(*shade(walk, 0.82), 255))
    draw.line((0, 9, width, 9), fill=(*shade(walk, 0.88), 255))
    for _ in range(width // 30):
        x, y = rng.randrange(width), rng.randrange(19)
        image.putpixel((x, y), (*shade(walk, rng.choice([0.85, 1.12])), 255))
    # Kerb.
    draw.rectangle((0, 18, width, 21), fill=(*shade(walk, 1.25), 255))
    draw.line((0, 22, width, 22), fill=(*shade(street, 0.6), 255))
    # Asphalt texture (ordered speckle, no smoothing).
    for y in range(23, GROUND_H):
        for x in range(rng.randrange(3), width, 3):
            if rng.random() < 0.18:
                image.putpixel((x, y), (*shade(street, rng.choice([0.84, 0.9, 1.1, 1.16])), 255))
    # Cracks.
    for _ in range(width // 120):
        x, y = rng.randrange(width - 20), rng.randrange(30, GROUND_H - 10)
        for step in range(rng.randrange(6, 14)):
            image.putpixel((min(width - 1, x), min(GROUND_H - 1, y)), (*shade(street, 0.62), 255))
            x += rng.choice([1, 1, 2])
            y += rng.choice([-1, 0, 1])
    # Lane markings.
    mark = (198, 180, 96)
    for x in range(10, width, 80):
        draw.rectangle((x, LANE_MARK_Y, x + 39, LANE_MARK_Y + 2), fill=(*mark, 255))
        for _ in range(6):
            image.putpixel((x + rng.randrange(40), LANE_MARK_Y + rng.randrange(3)), (*shade(street, 1.05), 255))
    # Manholes and drains.
    for x in range(rng.randrange(60, 200), width - 30, rng.randrange(260, 420)):
        y = rng.randrange(40, GROUND_H - 22)
        draw.ellipse((x, y, x + 20, y + 9), fill=(*shade(street, 0.55), 255))
        draw.ellipse((x + 2, y + 1, x + 18, y + 8), fill=(*shade(street, 0.75), 255))
        for gx in range(x + 5, x + 16, 3):
            draw.line((gx, y + 2, gx, y + 6), fill=(*shade(street, 0.55), 255))
    for x in range(rng.randrange(20, 100), width - 20, rng.randrange(180, 260)):
        draw.rectangle((x, 23, x + 14, 26), fill=(20, 20, 24, 255))
        for gx in range(x + 1, x + 14, 2):
            draw.point((gx, 24), fill=(70, 70, 76, 255))
    # Puddles that reflect the window colour.
    lit = rgb(palette.get("windows", "#f2c96b"))
    for x in range(rng.randrange(100, 300), width - 60, rng.randrange(300, 500)):
        y = rng.randrange(36, GROUND_H - 16)
        w = rng.randrange(26, 50)
        draw.ellipse((x, y, x + w, y + 7), fill=(*mix(street, (60, 70, 96), 0.5), 255))
        draw.line((x + 6, y + 3, x + w // 2, y + 3), fill=(*mix(lit, street, 0.5), 255))
    if theme == "canal":
        for x in range(0, width, 40):  # oily sheen streaks
            if rng.random() < 0.4:
                y = rng.randrange(30, GROUND_H - 4)
                draw.line((x, y, x + rng.randrange(8, 20), y), fill=(*mix(street, (80, 140, 90), 0.35), 255))
    return image


# ---------------------------------------------------------------- props


def draw_props() -> tuple[Image.Image, dict]:
    sheet = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    regions = {}

    def place(name: str, x: int, y: int) -> tuple[int, int]:
        w, h = PROP_SIZE[name]
        regions[name] = [x, y, w, h]
        return x, y

    x, y = place("lamp", 0, 0)
    pole = (52, 56, 64)
    draw.rectangle((x + 7, y + 8, x + 8, y + 71), fill=(*pole, 255))
    draw.rectangle((x + 5, y + 66, x + 10, y + 71), fill=(*shade(pole, 0.8), 255))
    draw.rectangle((x + 3, y + 4, x + 12, y + 8), fill=(*pole, 255))
    draw.rectangle((x + 4, y + 8, x + 11, y + 11), fill=(255, 226, 150, 255))
    draw.rectangle((x + 5, y + 2, x + 10, y + 4), fill=(*shade(pole, 0.8), 255))

    x, y = place("crate", 16, 0)
    wood = (150, 104, 60)
    draw.rectangle((x, y, x + 19, y + 17), fill=(*wood, 255))
    draw.rectangle((x, y, x + 19, y + 17), outline=(*shade(wood, 0.6), 255))
    draw.line((x + 1, y + 1, x + 18, y + 16), fill=(*shade(wood, 0.75), 255))
    draw.line((x + 1, y + 8, x + 18, y + 8), fill=(*shade(wood, 0.8), 255))

    x, y = place("barrel", 36, 0)
    steel = (70, 110, 150)
    draw.rectangle((x + 1, y, x + 12, y + 17), fill=(*steel, 255))
    draw.rectangle((x + 1, y + 4, x + 12, y + 5), fill=(*shade(steel, 0.6), 255))
    draw.rectangle((x + 1, y + 12, x + 12, y + 13), fill=(*shade(steel, 0.6), 255))
    draw.line((x + 4, y + 1, x + 4, y + 16), fill=(*shade(steel, 1.3), 255))

    x, y = place("bin", 50, 0)
    green = (60, 90, 70)
    draw.rectangle((x + 1, y + 4, x + 14, y + 19), fill=(*green, 255))
    draw.rectangle((x, y + 2, x + 15, y + 5), fill=(*shade(green, 0.7), 255))
    for gx in range(x + 3, x + 13, 3):
        draw.line((gx, y + 7, gx, y + 17), fill=(*shade(green, 0.8), 255))

    x, y = place("hydrant", 66, 0)
    red = (180, 50, 44)
    draw.rectangle((x + 2, y + 3, x + 7, y + 13), fill=(*red, 255))
    draw.rectangle((x, y + 6, x + 9, y + 8), fill=(*shade(red, 0.8), 255))
    draw.rectangle((x + 3, y, x + 6, y + 3), fill=(*shade(red, 1.2), 255))

    x, y = place("stall", 76, 0)
    canopy = (176, 52, 52)
    awning(draw, x, x + 52, y + 2, canopy)
    draw.rectangle((x + 2, y + 12, x + 3, y + 43), fill=(90, 70, 50, 255))
    draw.rectangle((x + 48, y + 12, x + 49, y + 43), fill=(90, 70, 50, 255))
    draw.rectangle((x + 1, y + 28, x + 50, y + 34), fill=(130, 92, 56, 255))
    for fx in range(x + 4, x + 48, 5):  # produce
        draw.rectangle((fx, y + 25, fx + 3, y + 28), fill=(random.Random(fx).choice([(220, 120, 40), (90, 170, 70), (200, 60, 60), (230, 200, 70)]) + (255,)))

    x, y = place("lantern_string", 128, 0)
    draw.line((x, y + 2, x + 63, y + 2), fill=(40, 36, 40, 255))
    for lx in range(x + 4, x + 64, 12):
        draw.rectangle((lx, y + 4, lx + 4, y + 10), fill=(230, 80, 60, 255))
        draw.point((lx + 2, y + 3), fill=(40, 36, 40, 255))
        draw.rectangle((lx + 1, y + 6, lx + 3, y + 8), fill=(255, 200, 120, 255))

    x, y = place("cones", 192, 0)
    orange = (230, 120, 40)
    draw.polygon([(x + 6, y), (x + 1, y + 10), (x + 11, y + 10)], fill=(*orange, 255))
    draw.line((x + 3, y + 6, x + 9, y + 6), fill=(240, 240, 240, 255))
    draw.rectangle((x, y + 10, x + 11, y + 11), fill=(*shade(orange, 0.6), 255))

    x, y = place("pipe_valve", 204, 0)
    pipe = (110, 120, 104)
    draw.rectangle((x + 6, y + 6, x + 11, y + 25), fill=(*pipe, 255))
    draw.rectangle((x + 4, y + 22, x + 13, y + 25), fill=(*shade(pipe, 0.7), 255))
    draw.ellipse((x + 2, y, x + 15, y + 9), outline=(170, 60, 50, 255))
    draw.line((x + 8, y + 1, x + 8, y + 8), fill=(170, 60, 50, 255))

    x, y = place("bench", 128, 20)
    draw.rectangle((x, y + 4, x + 31, y + 6), fill=(130, 92, 56, 255))
    draw.rectangle((x, y, x + 31, y + 1), fill=(130, 92, 56, 255))
    draw.rectangle((x + 2, y + 7, x + 3, y + 13), fill=(50, 50, 56, 255))
    draw.rectangle((x + 28, y + 7, x + 29, y + 13), fill=(50, 50, 56, 255))

    x, y = place("glow", 0, 76)
    for r in range(24, 0, -1):  # stepped radial glow (drawn additive in game)
        alpha = int(70 * (1 - r / 24) ** 1.5)
        draw.ellipse((x + 24 - r, y + 24 - r, x + 24 + r, y + 24 + r), fill=(255, 210, 140, alpha))
    return sheet, regions


THEME_PROPS = {
    "depot": [("crate", 0.5), ("barrel", 0.4), ("cones", 0.3), ("bench", 0.15)],
    "market": [("stall", 0.5), ("crate", 0.3), ("bin", 0.3), ("hydrant", 0.2), ("lantern_string", 0.5)],
    "canal": [("pipe_valve", 0.45), ("barrel", 0.4), ("cones", 0.3), ("bin", 0.2)],
}


def place_props(area_id: str, area: dict, theme: str) -> list[dict]:
    """Deterministic placements: lamps every ~180 px on the sidewalk, themed
    props between them. y is the prop's foot line in world coordinates."""
    rng = seeded(area_id, "props")
    width = int(area["width"])
    placed = []
    for x in range(90, width - 40, 180):
        placed.append({"prop": "lamp", "x": x + rng.randrange(-10, 10), "y": 246, "glow": True})
    x = 40
    while x < width - 60:
        x += rng.randrange(50, 120)
        for name, chance in THEME_PROPS[theme]:
            if rng.random() < chance:
                y = 244 if name != "lantern_string" else 196
                if any(abs(p["x"] - x) < 30 and p["y"] == y for p in placed):
                    continue
                placed.append({"prop": name, "x": x, "y": y})
                break
    return sorted(placed, key=lambda p: (p["y"], p["x"]))


def main() -> int:
    data = json.loads(AREAS.read_text())
    manifest = json.loads(MANIFEST.read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    props, regions = draw_props()
    props.save(OUT / "props.png", optimize=True)
    environment = {
        "license": "MIT (original art generated by tools/assets/gen_environment.py)",
        "props": {"sheet": "res://assets/environment/props.png", "regions": regions},
        "areas": {},
    }
    for area_id, area in sorted(data["areas"].items()):
        theme = area.get("theme", "market")
        folder = OUT / area_id
        folder.mkdir(exist_ok=True)
        layers = {
            "sky": draw_sky(area_id, area["palette"]),
            "far": draw_far(area_id, area["palette"], theme),
            "buildings": draw_buildings(area_id, area, theme),
            "ground": draw_ground(area_id, area, theme),
        }
        entry = {"theme": theme, "layers": {}, "props": place_props(area_id, area, theme)}
        for name, image in layers.items():
            image.save(folder / f"{name}.png", optimize=True)
            entry["layers"][name] = {
                "file": f"res://assets/environment/{area_id}/{name}.png",
                "size": list(image.size),
            }
        environment["areas"][area_id] = entry
        print(f"generated {area_id} ({theme}): {len(entry['props'])} props")
    manifest["environment"] = environment
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
