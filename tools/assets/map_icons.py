"""Icons for the map: the HUD's route card and the map screen (gen_ui.py).
16x16 cells, each picture about 9 to 12 pixels and centred, so they sit on a
route's nodes without crowding them. A dark outline keeps them readable on
the street behind the HUD.
"""

from __future__ import annotations

from PIL import ImageDraw

OUTLINE = (20, 16, 24, 255)
RED = (224, 82, 74, 255)
RED_DARK = (150, 40, 40, 255)
ORANGE = (242, 140, 60, 255)
ORANGE_DARK = (170, 82, 30, 255)
GOLD = (242, 193, 74, 255)
TEAL = (78, 196, 190, 255)
TEAL_DARK = (40, 120, 118, 255)
GREY = (150, 150, 165, 255)
GREY_DARK = (90, 90, 104, 255)
GREEN = (123, 211, 137, 255)
BONE = (238, 232, 220, 255)


def _skull(d: ImageDraw.ImageDraw, top: int, face, shade) -> None:
    # Cranium, cheeks, jaw with teeth, two eye sockets.
    d.ellipse((3, top, 12, top + 8), fill=OUTLINE)
    d.rectangle((5, top + 7, 10, top + 10), fill=OUTLINE)
    d.ellipse((4, top + 1, 11, top + 7), fill=face)
    d.rectangle((6, top + 7, 9, top + 9), fill=face)
    d.rectangle((4, top + 5, 11, top + 6), fill=shade)
    d.rectangle((5, top + 3, 6, top + 5), fill=OUTLINE)
    d.rectangle((9, top + 3, 10, top + 5), fill=OUTLINE)
    d.point((7, top + 9), fill=OUTLINE)
    d.point((8, top + 6), fill=OUTLINE)


def _tick(d: ImageDraw.ImageDraw) -> None:
    d.line((9, 12, 11, 14, 15, 9), fill=OUTLINE, width=3)
    d.line((9, 12, 11, 14, 15, 9), fill=GREEN, width=1)


def map_boss(d: ImageDraw.ImageDraw) -> None:
    # The district's boss: a red skull under a gold crown.
    d.polygon([(4, 4), (4, 0), (6, 2), (8, 0), (10, 2), (12, 0), (12, 4)], fill=OUTLINE)
    d.polygon([(5, 3), (5, 1), (6, 3), (8, 1), (10, 3), (11, 1), (11, 3)], fill=GOLD)
    _skull(d, 4, RED, RED_DARK)


def map_boss_beaten(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(4, 4), (4, 0), (6, 2), (8, 0), (10, 2), (12, 0), (12, 4)], fill=OUTLINE)
    d.polygon([(5, 3), (5, 1), (6, 3), (8, 1), (10, 3), (11, 1), (11, 3)], fill=GREY)
    _skull(d, 4, GREY, GREY_DARK)
    _tick(d)


def map_mini_boss(d: ImageDraw.ImageDraw) -> None:
    # A boss before the district's end: a smaller horned skull, orange.
    d.polygon([(3, 6), (2, 2), (5, 5)], fill=OUTLINE)
    d.polygon([(12, 6), (13, 2), (10, 5)], fill=OUTLINE)
    d.line((3, 5, 3, 3), fill=BONE)
    d.line((12, 5, 12, 3), fill=BONE)
    _skull(d, 4, ORANGE, ORANGE_DARK)


def map_mini_boss_beaten(d: ImageDraw.ImageDraw) -> None:
    d.polygon([(3, 6), (2, 2), (5, 5)], fill=OUTLINE)
    d.polygon([(12, 6), (13, 2), (10, 5)], fill=OUTLINE)
    _skull(d, 4, GREY, GREY_DARK)
    _tick(d)


def map_town(d: ImageDraw.ImageDraw) -> None:
    # A town (shop, quests, taxi): a teal house with a lit door.
    d.polygon([(2, 8), (8, 2), (14, 8)], fill=OUTLINE)
    d.rectangle((3, 7, 13, 14), fill=OUTLINE)
    d.polygon([(4, 7), (8, 3), (12, 7)], fill=TEAL)
    d.rectangle((4, 8, 12, 13), fill=TEAL)
    d.rectangle((4, 8, 12, 8), fill=TEAL_DARK)
    d.rectangle((7, 10, 9, 13), fill=GOLD)


def map_hero(d: ImageDraw.ImageDraw) -> None:
    # The hero: an orange marker pointing down at the node.
    d.polygon([(2, 3), (14, 3), (8, 13)], fill=OUTLINE)
    d.polygon([(4, 4), (12, 4), (8, 11)], fill=ORANGE)
    d.line((5, 5, 11, 5), fill=(255, 205, 140, 255))


def map_goal(d: ImageDraw.ImageDraw) -> None:
    # The goal: a gold flag.
    d.rectangle((4, 2, 5, 14), fill=OUTLINE)
    d.polygon([(6, 2), (13, 4), (6, 8)], fill=OUTLINE)
    d.polygon([(6, 3), (11, 4), (6, 7)], fill=GOLD)
    d.line((5, 3, 5, 13), fill=BONE)


MAP_ICONS = {
    "map_boss": map_boss,
    "map_boss_beaten": map_boss_beaten,
    "map_mini_boss": map_mini_boss,
    "map_mini_boss_beaten": map_mini_boss_beaten,
    "map_town": map_town,
    "map_hero": map_hero,
    "map_goal": map_goal,
}
