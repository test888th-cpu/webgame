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


# Skill icons: 24x24, a glowing glyph over a radial backdrop, in the style of
# action-RPG hotbars. The hotbar draws the frame around them.
SKILL = 24


def backdrop(d: ImageDraw.ImageDraw, inner: tuple, outer: tuple, cx: int = 12, cy: int = 12) -> None:
    for y in range(SKILL):
        for x in range(SKILL):
            # Integer distance keeps the output identical on every platform.
            t = min(256, ((x - cx) * (x - cx) + (y - cy) * (y - cy)) * 256 // 200)
            d.point((x, y), fill=tuple((inner[i] * (256 - t) + outer[i] * t) // 256 for i in range(3)) + (255,))


def fist(d: ImageDraw.ImageDraw, x: int, y: int, skin: tuple, up: bool = False) -> None:
    """A taped fist, 10x9 with its top-left at (x, y): knuckles to the right,
    or knuckles up when `up`. Finger creases are shaded, not outlined."""
    shade = (196, 140, 100, 255)
    tape = (236, 236, 240, 255)
    if up:
        d.rounded_rectangle((x, y, x + 9, y + 9), radius=2, fill=OUTLINE)
        d.rounded_rectangle((x + 1, y + 1, x + 8, y + 8), radius=2, fill=skin)
        for k in (x + 3, x + 5, x + 7):
            d.line((k, y + 1, k, y + 3), fill=shade)
        d.line((x + 1, y + 6, x + 6, y + 6), fill=shade)
        d.rectangle((x + 2, y + 9, x + 7, y + 13), fill=OUTLINE)
        d.rectangle((x + 3, y + 9, x + 6, y + 13), fill=tape)
        d.line((x + 3, y + 11, x + 6, y + 11), fill=(190, 190, 200, 255))
        return
    d.rounded_rectangle((x, y, x + 9, y + 9), radius=2, fill=OUTLINE)
    d.rounded_rectangle((x + 1, y + 1, x + 8, y + 8), radius=2, fill=skin)
    for k in (y + 3, y + 5, y + 7):
        d.line((x + 6, k, x + 8, k), fill=shade)
    d.line((x + 3, y + 6, x + 3, y + 1), fill=shade)
    d.rectangle((x - 4, y + 2, x, y + 7), fill=OUTLINE)
    d.rectangle((x - 4, y + 3, x, y + 6), fill=tape)
    d.line((x - 2, y + 3, x - 2, y + 6), fill=(190, 190, 200, 255))


SKIN = (240, 196, 150, 255)


def skill_attack(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (150, 74, 30), (34, 14, 10))
    for y, length in ((7, 6), (11, 8), (15, 5)):
        d.line((2, y, 2 + length, y), fill=(255, 214, 140, 255))
    fist(d, 12, 7, SKIN)
    d.point((21, 8), fill=(255, 250, 220, 255))
    d.point((22, 12), fill=(255, 250, 220, 255))


def skill_uppercut(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (190, 46, 30), (40, 8, 10), cy=16)
    d.arc((3, 3, 21, 25), 200, 330, fill=(255, 226, 120, 255), width=2)
    d.arc((5, 6, 19, 24), 210, 320, fill=(255, 140, 60, 255))
    fist(d, 7, 4, SKIN, up=True)
    for x, y in ((5, 20), (19, 19), (12, 22)):
        d.point((x, y), fill=(255, 200, 90, 255))


def skill_whirlwind(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (40, 120, 190), (8, 16, 44))
    d.arc((2, 4, 22, 20), 0, 300, fill=(200, 240, 255, 255), width=2)
    d.arc((6, 7, 18, 17), 90, 400, fill=(110, 200, 240, 255), width=2)
    d.arc((9, 9, 15, 15), 180, 480, fill=(255, 255, 255, 255))
    d.polygon([(21, 9), (23, 13), (19, 12)], fill=(200, 240, 255, 255))


def skill_rush(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (210, 120, 30), (50, 20, 6), cx=15)
    for y, x0 in ((6, 1), (10, 0), (14, 2), (18, 4)):
        d.line((x0, y, x0 + 7, y), fill=(255, 230, 170, 255))
    # A charging figure: head, leading shoulder, trailing leg.
    d.ellipse((14, 3, 20, 9), fill=OUTLINE)
    d.ellipse((15, 4, 19, 8), fill=SKIN)
    d.polygon([(9, 9), (19, 9), (21, 15), (12, 16)], fill=OUTLINE)
    d.polygon([(10, 10), (18, 10), (20, 14), (12, 15)], fill=(230, 120, 40, 255))
    d.line((12, 16, 7, 21), fill=OUTLINE, width=3)
    d.line((16, 16, 19, 21), fill=OUTLINE, width=3)
    d.line((20, 11, 22, 13), fill=(255, 250, 220, 255))


def skill_slam(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (230, 90, 20), (50, 6, 4), cy=18)
    for x, top in ((4, 9), (8, 5), (16, 6), (20, 10), (12, 3)):
        d.polygon([(x - 2, 20), (x, top), (x + 2, 20)], fill=(255, 170, 40, 255))
        d.line((x, top + 3, x, 19), fill=(255, 236, 140, 255))
    d.rectangle((0, 20, 23, 23), fill=(60, 30, 20, 255))
    d.line((1, 20, 22, 20), fill=(255, 220, 120, 255))
    for x0, x1 in ((3, 7), (16, 21)):
        d.line((x0, 22, x1, 21), fill=(20, 10, 8, 255))
    fist(d, 8, 9, SKIN)


SKIN_DARK = (150, 96, 60, 255)
SHIRT = (200, 50, 44, 255)


def skill_headbutt(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (150, 50, 120), (30, 6, 30), cx=15)
    star = [(19, 4), (20, 9), (23, 9), (21, 12), (23, 16), (19, 14), (16, 17), (17, 12), (14, 9), (18, 9)]
    d.polygon(star, fill=(255, 236, 140, 255))
    d.polygon([(19, 7), (20, 10), (21, 11), (19, 12), (18, 11)], fill=(255, 255, 255, 255))
    d.ellipse((2, 5, 15, 18), fill=OUTLINE)
    d.ellipse((3, 6, 14, 17), fill=SKIN_DARK)
    d.pieslice((3, 5, 14, 16), 180, 360, fill=(30, 26, 30, 255))
    d.line((12, 11, 14, 11), fill=OUTLINE)
    d.rectangle((5, 18, 12, 23), fill=OUTLINE)
    d.rectangle((6, 18, 11, 23), fill=SHIRT)


def skill_clothesline(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (200, 110, 30), (50, 16, 6))
    d.arc((1, 3, 23, 23), 200, 340, fill=(255, 230, 160, 255), width=2)
    d.rectangle((1, 11, 7, 17), fill=OUTLINE)
    d.rectangle((2, 12, 6, 16), fill=SHIRT)
    d.rectangle((6, 12, 19, 16), fill=OUTLINE)
    d.rectangle((7, 13, 18, 15), fill=SKIN_DARK)
    d.rounded_rectangle((17, 11, 23, 17), radius=2, fill=OUTLINE)
    d.rounded_rectangle((18, 12, 22, 16), radius=1, fill=SKIN_DARK)
    for y in (19, 21):
        d.line((4, y, 14, y), fill=(255, 210, 140, 255))


def skill_charge(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (180, 40, 30), (40, 6, 6), cx=16)
    for y, x0 in ((5, 0), (9, 2), (13, 0), (17, 3)):
        d.line((x0, y, x0 + 8, y), fill=(255, 220, 160, 255))
    d.ellipse((15, 2, 22, 9), fill=OUTLINE)
    d.ellipse((16, 3, 21, 8), fill=SKIN_DARK)
    d.pieslice((16, 2, 21, 7), 180, 360, fill=(30, 26, 30, 255))
    d.polygon([(8, 9), (21, 8), (23, 16), (11, 18)], fill=OUTLINE)
    d.polygon([(9, 10), (20, 9), (22, 15), (12, 17)], fill=SHIRT)
    d.ellipse((17, 9, 23, 15), fill=SKIN_DARK, outline=OUTLINE)
    d.line((12, 18, 8, 23), fill=OUTLINE, width=3)
    d.line((17, 18, 20, 23), fill=OUTLINE, width=3)


def skill_earthshaker(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (170, 100, 40), (40, 20, 8), cy=18)
    d.rectangle((0, 17, 23, 23), fill=(70, 46, 30, 255))
    d.line((0, 17, 23, 17), fill=(255, 200, 110, 255))
    for points in (((12, 17), (9, 20), (10, 23)), ((12, 17), (15, 21), (19, 22)), ((12, 17), (5, 19), (2, 22))):
        d.line(points, fill=(255, 150, 40, 255), width=1)
    for x in (4, 19):
        d.polygon([(x - 2, 16), (x, 10), (x + 2, 16)], fill=(150, 120, 90, 255))
    d.rounded_rectangle((7, 4, 17, 14), radius=2, fill=OUTLINE)
    d.rounded_rectangle((8, 5, 16, 13), radius=2, fill=SKIN_DARK)
    for k in (10, 12, 14):
        d.line((k, 11, k, 13), fill=(110, 70, 44, 255))
    d.rectangle((9, 0, 15, 4), fill=OUTLINE)
    d.rectangle((10, 0, 14, 4), fill=SHIRT)


# Riku's skills: boxing, in his orange-and-black jacket.
JACKET = (214, 96, 40, 255)
SLEEVE = (232, 222, 200, 255)


def skill_liver(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (40, 150, 110), (6, 34, 26), cx=14, cy=14)
    for x, y in ((18, 4), (21, 7), (20, 2)):
        d.line((x, y, x + 2, y - 2), fill=(220, 255, 230, 255))
    d.rectangle((0, 13, 8, 18), fill=OUTLINE)
    d.rectangle((0, 14, 8, 17), fill=SLEEVE)
    d.line((7, 13, 11, 9), fill=OUTLINE, width=4)
    d.line((7, 13, 11, 9), fill=SLEEVE, width=2)
    fist(d, 12, 4, SKIN, up=True)


def skill_onetwo(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (220, 110, 40), (50, 18, 6), cx=14)
    for y, x0 in ((5, 0), (12, 1), (19, 0)):
        d.line((x0, y, x0 + 6, y), fill=(255, 226, 170, 255))
    d.rectangle((3, 3, 9, 8), fill=OUTLINE)
    d.rectangle((3, 4, 9, 7), fill=SLEEVE)
    fist(d, 12, 1, SKIN)
    d.rectangle((1, 14, 7, 19), fill=OUTLINE)
    d.rectangle((1, 15, 7, 18), fill=JACKET)
    fist(d, 10, 12, SKIN)
    d.point((22, 5), fill=(255, 250, 220, 255))
    d.point((21, 16), fill=(255, 250, 220, 255))


def skill_dempsey(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (190, 60, 40), (44, 8, 8), cx=12)
    # The weave: a figure eight the body sways through while charging.
    d.arc((1, 3, 12, 14), 0, 360, fill=(255, 210, 150, 255))
    d.arc((11, 10, 22, 21), 0, 360, fill=(255, 210, 150, 255))
    d.ellipse((7, 4, 15, 12), fill=OUTLINE)
    d.ellipse((8, 5, 14, 11), fill=SKIN)
    d.pieslice((8, 4, 14, 10), 180, 360, fill=(30, 26, 30, 255))
    d.polygon([(5, 12), (17, 12), (18, 20), (6, 21)], fill=OUTLINE)
    d.polygon([(6, 13), (16, 13), (17, 19), (7, 20)], fill=(40, 34, 40, 255))
    d.line((7, 14, 7, 19), fill=JACKET, width=2)
    fist(d, 15, 12, SKIN)


def skill_knockout(d: ImageDraw.ImageDraw) -> None:
    backdrop(d, (240, 200, 60), (70, 30, 6))
    star = [(12, 0), (14, 6), (21, 4), (17, 10), (23, 13), (16, 15), (17, 22), (12, 17), (7, 22), (8, 15),
            (1, 13), (7, 10), (3, 4), (10, 6)]
    d.polygon(star, fill=(255, 245, 190, 255))
    d.rectangle((0, 9, 5, 15), fill=OUTLINE)
    d.rectangle((0, 10, 5, 14), fill=JACKET)
    d.rounded_rectangle((5, 6, 17, 18), radius=3, fill=OUTLINE)
    d.rounded_rectangle((6, 7, 16, 17), radius=3, fill=SKIN)
    for k in (9, 12, 15):
        d.line((14, k - 1, 16, k - 1), fill=(196, 140, 100, 255))
    d.line((9, 14, 9, 8), fill=(196, 140, 100, 255))


def lock(d: ImageDraw.ImageDraw) -> None:
    d.arc((4, 1, 11, 9), 180, 360, fill=OUTLINE, width=3)
    d.arc((5, 2, 10, 8), 180, 360, fill=(170, 176, 190, 255))
    d.rectangle((2, 6, 13, 14), fill=OUTLINE)
    d.rectangle((3, 7, 12, 13), fill=(200, 160, 60, 255))
    d.rectangle((7, 9, 8, 11), fill=OUTLINE)


SKILL_ICONS = {
    "skill_attack": skill_attack,
    "skill_uppercut": skill_uppercut,
    "skill_whirlwind": skill_whirlwind,
    "skill_rush": skill_rush,
    "skill_slam": skill_slam,
    "skill_headbutt": skill_headbutt,
    "skill_clothesline": skill_clothesline,
    "skill_charge": skill_charge,
    "skill_earthshaker": skill_earthshaker,
    "skill_liver": skill_liver,
    "skill_onetwo": skill_onetwo,
    "skill_dempsey": skill_dempsey,
    "skill_knockout": skill_knockout,
}


def rebar_pipe(d: ImageDraw.ImageDraw) -> None:
    d.line((3, 13, 13, 3), fill=OUTLINE, width=4)
    d.line((3, 13, 13, 3), fill=(150, 90, 70, 255), width=2)
    for k in (5, 8, 11):
        d.point((k, 15 - k), fill=(200, 130, 100, 255))
    d.line((12, 2, 14, 4), fill=OUTLINE, width=2)


def dock_beanie(d: ImageDraw.ImageDraw) -> None:
    d.pieslice((2, 3, 14, 17), 180, 360, fill=OUTLINE)
    d.pieslice((3, 4, 13, 16), 180, 360, fill=(60, 110, 170, 255))
    d.rectangle((2, 9, 14, 13), fill=OUTLINE)
    d.rectangle((3, 10, 13, 12), fill=(40, 80, 130, 255))
    for x in (4, 7, 10):
        d.line((x, 10, x, 12), fill=(80, 130, 190, 255))
    d.ellipse((6, 1, 10, 5), fill=(230, 230, 236, 255), outline=OUTLINE)


def hard_hat(d: ImageDraw.ImageDraw) -> None:
    d.pieslice((3, 3, 13, 17), 180, 360, fill=OUTLINE)
    d.pieslice((4, 4, 12, 16), 180, 360, fill=(242, 193, 74, 255))
    d.rectangle((1, 9, 15, 12), fill=OUTLINE)
    d.rectangle((2, 10, 14, 11), fill=(220, 160, 50, 255))
    d.line((8, 4, 8, 9), fill=(255, 230, 150, 255))


def padded_vest(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(4, 2), (7, 4), (9, 4), (12, 2), (13, 14), (3, 14)], fill=OUTLINE)
    d.polygon([(5, 3), (7, 5), (9, 5), (11, 3), (12, 13), (4, 13)], fill=(130, 140, 110, 255))
    for y in (7, 10):
        d.line((5, y, 11, y), fill=(100, 110, 84, 255))
    d.line((8, 5, 8, 13), fill=(90, 98, 76, 255))


def fingerless_gloves(d: ImageDraw.ImageDraw) -> None:
    d.rounded_rectangle((3, 5, 12, 14), radius=2, fill=OUTLINE)
    d.rounded_rectangle((4, 6, 11, 13), radius=2, fill=(70, 60, 56, 255))
    for x in (4, 6, 8, 10):
        d.rectangle((x, 3, x + 1, 5), fill=(224, 170, 130, 255))
    d.rectangle((11, 8, 13, 10), fill=(224, 170, 130, 255))
    d.line((4, 12, 11, 12), fill=(200, 60, 50, 255))


def iron_wraps(d: ImageDraw.ImageDraw) -> None:
    d.rounded_rectangle((3, 3, 13, 13), radius=2, fill=OUTLINE)
    d.rounded_rectangle((4, 4, 12, 12), radius=2, fill=(110, 80, 56, 255))
    for y in (5, 8, 11):
        for x in (5, 8, 11):
            d.point((x, y), fill=(190, 196, 210, 255))
    d.line((4, 6, 12, 6), fill=(150, 156, 170, 255))
    d.line((4, 10, 12, 10), fill=(150, 156, 170, 255))


def canvas_sneakers(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(2, 6), (7, 6), (9, 9), (14, 10), (14, 13), (2, 13)], fill=OUTLINE)
    d.polygon([(3, 7), (7, 7), (8, 10), (13, 11), (13, 12), (3, 12)], fill=(220, 70, 60, 255))
    d.line((2, 13, 14, 13), fill=(236, 236, 240, 255))
    d.point((6, 9), fill=(255, 255, 255, 255))
    d.point((8, 10), fill=(255, 255, 255, 255))


def steel_toe_boots(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(3, 2), (8, 2), (8, 9), (14, 10), (14, 14), (3, 14)], fill=OUTLINE)
    d.polygon([(4, 3), (7, 3), (7, 10), (13, 11), (13, 13), (4, 13)], fill=(120, 80, 50, 255))
    d.rectangle((10, 11, 13, 13), fill=(170, 176, 190, 255))
    d.line((4, 6, 7, 6), fill=(90, 58, 36, 255))


def lucky_coin(d: ImageDraw.ImageDraw) -> None:
    d.ellipse((2, 2, 13, 13), fill=OUTLINE)
    d.ellipse((3, 3, 12, 12), fill=(200, 160, 90, 255))
    d.ellipse((6, 6, 9, 9), fill=OUTLINE)
    d.arc((4, 4, 11, 11), 200, 300, fill=(250, 220, 150, 255))
    d.line((7, 0, 7, 3), fill=(180, 60, 50, 255))


def riveted_jacket(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(5, 2), (10, 2), (14, 5), (13, 9), (11, 8), (11, 14), (4, 14), (4, 8), (2, 9), (1, 5)], fill=OUTLINE)
    d.polygon([(5, 3), (10, 3), (13, 5), (12, 7), (10, 6), (10, 13), (5, 13), (5, 6), (3, 7), (2, 5)], fill=(70, 74, 84, 255))
    d.line((7, 4, 7, 13), fill=(44, 46, 54, 255))
    for x, y in ((6, 6), (6, 9), (6, 12), (9, 6), (9, 9), (9, 12), (3, 5), (12, 5)):
        d.point((x, y), fill=(210, 214, 226, 255))


def street_runners(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(2, 6), (7, 6), (9, 9), (14, 10), (14, 13), (2, 13)], fill=OUTLINE)
    d.polygon([(3, 7), (7, 7), (8, 10), (13, 11), (13, 12), (3, 12)], fill=(60, 120, 220, 255))
    d.line((3, 10, 9, 12), fill=(250, 210, 70, 255))
    d.line((2, 13, 14, 13), fill=(236, 236, 240, 255))
    d.point((5, 8), fill=(255, 255, 255, 255))


def knuckle_ring(d: ImageDraw.ImageDraw, metal: tuple, shine: tuple) -> None:
    d.rounded_rectangle((1, 5, 14, 10), radius=2, fill=OUTLINE)
    for x in (2, 5, 8, 11):
        d.ellipse((x, 5, x + 3, 9), fill=metal, outline=OUTLINE)
        d.point((x + 1, 6), fill=shine)
    d.polygon([(3, 10), (12, 10), (10, 14), (5, 14)], fill=OUTLINE)
    d.polygon([(4, 10), (11, 10), (9, 13), (6, 13)], fill=metal)


def brass_knuckles(d: ImageDraw.ImageDraw) -> None:
    knuckle_ring(d, (214, 168, 64, 255), (255, 236, 160, 255))


def baron_knuckledusters(d: ImageDraw.ImageDraw) -> None:
    knuckle_ring(d, (70, 66, 74, 255), (255, 140, 50, 255))
    for x in (3, 6, 9, 12):
        d.point((x, 3), fill=(255, 120, 40, 255))
        d.point((x, 4), fill=(200, 70, 30, 255))


def iron_helm(d: ImageDraw.ImageDraw) -> None:
    d.pieslice((2, 2, 14, 20), 180, 360, fill=OUTLINE)
    d.pieslice((3, 3, 13, 19), 180, 360, fill=(150, 156, 170, 255))
    d.rectangle((2, 10, 14, 14), fill=OUTLINE)
    d.rectangle((3, 11, 13, 13), fill=(110, 116, 130, 255))
    d.rectangle((7, 4, 9, 13), fill=(110, 116, 130, 255))
    d.line((5, 5, 6, 4), fill=(220, 224, 236, 255))
    d.line((4, 12, 6, 12), fill=OUTLINE)
    d.line((10, 12, 12, 12), fill=OUTLINE)


def jade_charm(d: ImageDraw.ImageDraw) -> None:
    d.arc((3, 0, 13, 9), 200, 340, fill=(200, 60, 50, 255))
    d.polygon([(8, 4), (13, 9), (8, 15), (3, 9)], fill=OUTLINE)
    d.polygon([(8, 5), (12, 9), (8, 14), (4, 9)], fill=(60, 170, 110, 255))
    d.polygon([(8, 6), (10, 9), (8, 12), (6, 9)], fill=(120, 220, 160, 255))
    d.point((7, 7), fill=(230, 255, 240, 255))


SILHOUETTE = (255, 255, 255, 46)


def slot_weapon(d: ImageDraw.ImageDraw) -> None:
    d.line((3, 13, 12, 4), fill=SILHOUETTE, width=3)
    d.ellipse((10, 1, 15, 6), fill=SILHOUETTE)


def slot_head(d: ImageDraw.ImageDraw) -> None:
    d.pieslice((3, 3, 13, 17), 180, 360, fill=SILHOUETTE)
    d.rectangle((2, 10, 14, 12), fill=SILHOUETTE)


def slot_body(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(5, 2), (11, 2), (15, 5), (13, 8), (12, 7), (12, 14), (4, 14), (4, 7), (3, 8), (1, 5)], fill=SILHOUETTE)


def slot_hands(d: ImageDraw.ImageDraw) -> None:
    d.rounded_rectangle((3, 5, 12, 14), radius=2, fill=SILHOUETTE)
    for x in (4, 6, 8, 10):
        d.rectangle((x, 2, x + 1, 4), fill=SILHOUETTE)


def slot_feet(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(3, 2), (8, 2), (8, 9), (14, 10), (14, 14), (3, 14)], fill=SILHOUETTE)


def slot_charm(d: ImageDraw.ImageDraw) -> None:
    d.ellipse((4, 5, 12, 13), fill=SILHOUETTE)
    d.line((8, 1, 8, 5), fill=SILHOUETTE)


ICONS = {
    "lock": lock,
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
    "rebar_pipe": rebar_pipe,
    "dock_beanie": dock_beanie,
    "hard_hat": hard_hat,
    "padded_vest": padded_vest,
    "fingerless_gloves": fingerless_gloves,
    "iron_wraps": iron_wraps,
    "canvas_sneakers": canvas_sneakers,
    "steel_toe_boots": steel_toe_boots,
    "lucky_coin": lucky_coin,
    "riveted_jacket": riveted_jacket,
    "street_runners": street_runners,
    "brass_knuckles": brass_knuckles,
    "baron_knuckledusters": baron_knuckledusters,
    "iron_helm": iron_helm,
    "jade_charm": jade_charm,
    "slot_weapon": slot_weapon,
    "slot_head": slot_head,
    "slot_body": slot_body,
    "slot_hands": slot_hands,
    "slot_feet": slot_feet,
    "slot_charm": slot_charm,
}


# Weapons a fighter can hold, drawn upright with the grip at WEAPON_GRIP so the
# game can turn them about that point (in the hand, lying on the street).
WEAPON_SIZE = (16, 32)
WEAPON_GRIP = (8, 27)
STEEL = (196, 202, 214, 255)
STEEL_DARK = (130, 136, 150, 255)
WOOD = (150, 104, 60, 255)
WOOD_DARK = (110, 74, 42, 255)


def weapon_knife(d: ImageDraw.ImageDraw) -> None:
    # Hand-sized: the handle (no outline) sits in the fist, the blade is ~9 px.
    d.rectangle((6, 15, 9, 24), fill=OUTLINE)
    d.rectangle((7, 16, 8, 23), fill=STEEL)
    d.point((8, 15), fill=STEEL)
    d.line((8, 16, 8, 23), fill=STEEL_DARK)
    d.line((5, 24, 10, 24), fill=OUTLINE)
    d.rectangle((7, 25, 8, 29), fill=(60, 44, 36, 255))


def weapon_bottle(d: ImageDraw.ImageDraw) -> None:
    d.rounded_rectangle((5, 10, 10, 21), radius=1, fill=OUTLINE)
    d.rectangle((6, 11, 9, 20), fill=(54, 130, 70, 255))
    d.rectangle((6, 14, 9, 16), fill=(232, 220, 180, 255))
    d.line((6, 11, 6, 19), fill=(150, 220, 160, 255))
    d.rectangle((7, 21, 8, 29), fill=(54, 130, 70, 255))
    d.line((7, 29, 8, 29), fill=(200, 160, 60, 255))


def weapon_plank(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((6, 6, 10, 29), fill=OUTLINE)
    d.rectangle((7, 7, 9, 28), fill=WOOD)
    for y in (10, 17):
        d.line((8, y, 9, y + 2), fill=WOOD_DARK)
    d.line((9, 8, 11, 7), fill=STEEL)
    d.rectangle((7, 24, 9, 28), fill=(90, 60, 40, 255))


def weapon_pipe(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((6, 6, 9, 29), fill=OUTLINE)
    d.rectangle((7, 7, 8, 28), fill=STEEL_DARK)
    d.line((7, 7, 7, 28), fill=STEEL)
    d.rectangle((5, 6, 10, 7), fill=OUTLINE)
    for y in range(24, 29, 2):
        d.line((7, y, 8, y), fill=(40, 40, 46, 255))


def weapon_machete(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(5, 23), (5, 12), (8, 8), (10, 10), (10, 23)], fill=OUTLINE)
    d.polygon([(6, 22), (6, 12), (8, 9), (9, 11), (9, 22)], fill=STEEL)
    d.line((6, 12, 6, 22), fill=(240, 244, 250, 255))
    d.line((9, 12, 9, 22), fill=STEEL_DARK)
    d.line((5, 24, 10, 24), fill=OUTLINE)
    d.rectangle((7, 25, 8, 29), fill=(40, 36, 34, 255))


def weapon_chair(d: ImageDraw.ImageDraw) -> None:
    # A folding chair from the side, held upside down by the top of its back:
    # backrest at the grip, seat and crossed legs swinging out beyond it.
    metal = (110, 116, 130, 255)
    d.line((6, 12, 6, 29), fill=OUTLINE, width=3)
    d.line((6, 12, 6, 29), fill=metal)
    d.rectangle((5, 23, 9, 29), fill=OUTLINE)
    d.rectangle((6, 24, 8, 28), fill=(170, 60, 50, 255))
    d.rectangle((5, 17, 13, 19), fill=OUTLINE)
    d.line((6, 18, 12, 18), fill=(170, 60, 50, 255))
    d.line((7, 17, 12, 9), fill=OUTLINE, width=3)
    d.line((7, 17, 12, 9), fill=metal)
    d.line((12, 17, 7, 9), fill=OUTLINE, width=3)
    d.line((12, 17, 7, 9), fill=metal)


WEAPONS = {
    "weapon_knife": weapon_knife,
    "weapon_bottle": weapon_bottle,
    "weapon_plank": weapon_plank,
    "weapon_pipe": weapon_pipe,
    "weapon_machete": weapon_machete,
    "weapon_chair": weapon_chair,
}


def render() -> tuple[Image.Image, dict]:
    """16px icons in rows of 8, then a row of 24px skill icons, then a row of
    weapons below."""
    columns = 8
    rows = (len(ICONS) + columns - 1) // columns
    top = rows * SIZE
    width = max(columns * SIZE, len(SKILL_ICONS) * SKILL, len(WEAPONS) * WEAPON_SIZE[0])
    sheet = Image.new("RGBA", (width, top + SKILL + WEAPON_SIZE[1]), (0, 0, 0, 0))
    regions = {}
    for index, (name, painter) in enumerate(ICONS.items()):
        cell = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        painter(ImageDraw.Draw(cell))
        x, y = (index % columns) * SIZE, (index // columns) * SIZE
        sheet.alpha_composite(cell, (x, y))
        regions[name] = [x, y, SIZE, SIZE]
    for index, (name, painter) in enumerate(SKILL_ICONS.items()):
        cell = Image.new("RGBA", (SKILL, SKILL), (0, 0, 0, 0))
        painter(ImageDraw.Draw(cell))
        sheet.alpha_composite(cell, (index * SKILL, top))
        regions[name] = [index * SKILL, top, SKILL, SKILL]
    for index, (name, painter) in enumerate(WEAPONS.items()):
        cell = Image.new("RGBA", WEAPON_SIZE, (0, 0, 0, 0))
        painter(ImageDraw.Draw(cell))
        x = index * WEAPON_SIZE[0]
        sheet.alpha_composite(cell, (x, top + SKILL))
        regions[name] = [x, top + SKILL, *WEAPON_SIZE]
    return sheet, regions


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet, regions = render()
    sheet.save(OUT / "icons.png", optimize=True)
    manifest = json.loads(MANIFEST.read_text())
    manifest["ui"] = {
        "license": "MIT (original art generated by tools/assets/gen_ui.py)",
        "icons": {"sheet": "res://assets/ui/icons.png", "regions": regions},
        "weapon_grip": list(WEAPON_GRIP),
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(regions)} icons")
    return 0


if __name__ == "__main__":
    sys.exit(main())
