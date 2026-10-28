"""Icons for the HUD's menu buttons and the auto battle switch (gen_ui.py):
16x16, light on transparent, so they read on the dark button frames.
"""

from __future__ import annotations

from PIL import ImageDraw

OUTLINE = (24, 20, 28, 255)
LIGHT = (236, 232, 223, 255)
DIM = (154, 155, 176, 255)
ACCENT = (242, 165, 74, 255)


def menu_character(d: ImageDraw.ImageDraw) -> None:
    # Head and shoulders.
    d.ellipse((5, 1, 11, 7), fill=OUTLINE)
    d.ellipse((6, 2, 10, 6), fill=LIGHT)
    d.pieslice((2, 8, 14, 22), 180, 360, fill=OUTLINE)
    d.pieslice((3, 9, 13, 21), 180, 360, fill=LIGHT)
    d.line((8, 10, 8, 14), fill=DIM)


def menu_bag(d: ImageDraw.ImageDraw) -> None:
    # A backpack with a flap and a strap.
    d.rounded_rectangle((2, 4, 13, 15), radius=3, fill=OUTLINE)
    d.rounded_rectangle((3, 5, 12, 14), radius=2, fill=LIGHT)
    d.arc((5, 1, 10, 7), 180, 360, fill=OUTLINE, width=2)
    d.rectangle((3, 5, 12, 8), fill=DIM)
    d.rectangle((7, 8, 8, 10), fill=OUTLINE)
    d.line((4, 12, 11, 12), fill=DIM)


def menu_skills(d: ImageDraw.ImageDraw) -> None:
    # A clenched fist with a spark: what the hero can do.
    d.rounded_rectangle((3, 5, 11, 14), radius=2, fill=OUTLINE)
    d.rounded_rectangle((4, 6, 10, 13), radius=1, fill=LIGHT)
    for x in (5, 7, 9):
        d.line((x, 6, x, 9), fill=DIM)
    d.rectangle((4, 10, 10, 10), fill=DIM)
    d.polygon([(12, 1), (13, 4), (16, 5), (13, 6), (12, 9), (11, 6), (8, 5), (11, 4)], fill=OUTLINE)
    d.polygon([(12, 2), (12, 4), (14, 5), (12, 6), (12, 8), (11, 5)], fill=ACCENT)


def menu_quests(d: ImageDraw.ImageDraw) -> None:
    # A scroll with lines of writing.
    d.rectangle((3, 2, 12, 14), fill=OUTLINE)
    d.rectangle((4, 3, 11, 13), fill=LIGHT)
    for y in (5, 7, 9):
        d.line((5, y, 10, y), fill=DIM)
    d.line((5, 11, 8, 11), fill=DIM)
    d.rectangle((2, 1, 13, 2), fill=OUTLINE)
    d.rectangle((2, 14, 13, 15), fill=OUTLINE)


def menu_map(d: ImageDraw.ImageDraw) -> None:
    # A folded map with a route and a marker.
    d.polygon([(1, 3), (5, 1), (10, 3), (15, 1), (15, 13), (10, 15), (5, 13), (1, 15)], fill=OUTLINE)
    d.polygon([(2, 4), (5, 2), (5, 12), (2, 14)], fill=LIGHT)
    d.polygon([(6, 2), (9, 4), (9, 14), (6, 12)], fill=DIM)
    d.polygon([(10, 4), (14, 2), (14, 12), (10, 14)], fill=LIGHT)
    d.point((3, 10), fill=OUTLINE)
    d.point((7, 7), fill=OUTLINE)
    d.point((12, 6), fill=OUTLINE)
    d.rectangle((11, 9, 13, 11), fill=ACCENT)


def menu_settings(d: ImageDraw.ImageDraw) -> None:
    # A cog: eight teeth round a ring.
    teeth = [(6, 0, 9, 3), (6, 12, 9, 15), (0, 6, 3, 9), (12, 6, 15, 9)]
    teeth += [(1, 2, 4, 4), (11, 2, 14, 4), (1, 11, 4, 13), (11, 11, 14, 13)]
    for box in teeth:
        d.rectangle(box, fill=OUTLINE)
    for box in [(7, 1, 8, 2), (7, 13, 8, 14), (1, 7, 2, 8), (13, 7, 14, 8)]:
        d.rectangle(box, fill=LIGHT)
    for box in [(2, 3, 3, 3), (12, 3, 13, 3), (2, 12, 3, 12), (12, 12, 13, 12)]:
        d.rectangle(box, fill=LIGHT)
    d.ellipse((2, 2, 13, 13), fill=OUTLINE)
    d.ellipse((3, 3, 12, 12), fill=LIGHT)
    d.ellipse((5, 5, 10, 10), fill=OUTLINE)
    d.ellipse((6, 6, 9, 9), fill=(32, 35, 58, 255))


def menu_auto(d: ImageDraw.ImageDraw) -> None:
    # Two arrows chasing each other round: it keeps going on its own.
    d.arc((2, 2, 13, 13), 200, 340, fill=OUTLINE, width=4)
    d.arc((2, 2, 13, 13), 20, 160, fill=OUTLINE, width=4)
    d.arc((3, 3, 12, 12), 205, 335, fill=LIGHT, width=2)
    d.arc((3, 3, 12, 12), 25, 155, fill=LIGHT, width=2)
    d.polygon([(11, 1), (15, 5), (10, 6)], fill=OUTLINE)
    d.polygon([(11, 2), (14, 5), (11, 5)], fill=LIGHT)
    d.polygon([(4, 14), (0, 10), (5, 9)], fill=OUTLINE)
    d.polygon([(4, 13), (1, 10), (4, 10)], fill=LIGHT)


MENU_ICONS = {
    "menu_character": menu_character,
    "menu_bag": menu_bag,
    "menu_skills": menu_skills,
    "menu_quests": menu_quests,
    "menu_map": menu_map,
    "menu_settings": menu_settings,
    "menu_auto": menu_auto,
}
