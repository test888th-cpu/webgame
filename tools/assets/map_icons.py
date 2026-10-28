"""Icons for the map: the HUD's route card and the map screen (gen_ui.py).
16x16 cells with small pictures (about 7 pixels) centred in them, so they
sit on a route's nodes, 11 pixels apart, without crowding them or the HUD.
A dark outline keeps them readable on the street behind the HUD.
"""

from __future__ import annotations

from PIL import ImageDraw

OUTLINE = (20, 16, 24, 255)
RED = (224, 82, 74, 255)
ORANGE = (242, 140, 60, 255)
GOLD = (242, 193, 74, 255)
GREY = (140, 140, 156, 255)
GREEN = (123, 211, 137, 255)
BONE = (238, 232, 220, 255)


def _skull(d: ImageDraw.ImageDraw, face) -> None:
    # A 7x7 skull in the middle of the cell: cranium, eyes, jaw.
    d.rectangle((5, 6, 11, 11), fill=OUTLINE)
    d.rectangle((6, 5, 10, 5), fill=OUTLINE)
    d.rectangle((6, 12, 10, 12), fill=OUTLINE)
    d.rectangle((6, 6, 10, 10), fill=face)
    d.rectangle((7, 11, 9, 11), fill=face)
    d.rectangle((7, 7, 7, 8), fill=OUTLINE)
    d.rectangle((9, 7, 9, 8), fill=OUTLINE)
    d.point((8, 11), fill=OUTLINE)


def _tick(d: ImageDraw.ImageDraw) -> None:
    d.line((9, 11, 10, 12, 13, 9), fill=OUTLINE, width=2)
    d.line((9, 11, 10, 12, 12, 10), fill=GREEN)


def _horns(d: ImageDraw.ImageDraw, color) -> None:
    for x in (4, 12):
        d.rectangle((x, 3, x, 6), fill=OUTLINE)
    d.point((4, 4), fill=color)
    d.point((12, 4), fill=color)


def _round_skull(d: ImageDraw.ImageDraw, face) -> None:
    # The route's first boss mark: a round skull with a small jaw.
    d.ellipse((4, 3, 12, 11), fill=OUTLINE)
    d.rectangle((6, 10, 10, 13), fill=OUTLINE)
    d.ellipse((5, 4, 11, 10), fill=face)
    d.rectangle((7, 10, 9, 12), fill=face)
    d.rectangle((6, 6, 7, 7), fill=OUTLINE)
    d.rectangle((9, 6, 10, 7), fill=OUTLINE)
    d.point((8, 12), fill=OUTLINE)


def map_boss(d: ImageDraw.ImageDraw) -> None:
    # The district's boss: a round red skull.
    _round_skull(d, RED)


def map_boss_beaten(d: ImageDraw.ImageDraw) -> None:
    _round_skull(d, GREY)
    _tick(d)


def map_mini_boss(d: ImageDraw.ImageDraw) -> None:
    # A boss before the district's end: a horned orange skull.
    _horns(d, BONE)
    _skull(d, ORANGE)


def map_mini_boss_beaten(d: ImageDraw.ImageDraw) -> None:
    _horns(d, GREY)
    _skull(d, GREY)
    _tick(d)


def map_goal(d: ImageDraw.ImageDraw) -> None:
    # The goal: a small gold flag on a pole.
    d.rectangle((5, 3, 6, 12), fill=OUTLINE)
    d.polygon([(7, 3), (11, 5), (7, 7)], fill=OUTLINE)
    d.polygon([(7, 4), (10, 5), (7, 6)], fill=GOLD)
    d.line((6, 4, 6, 11), fill=BONE)


MAP_ICONS = {
    "map_boss": map_boss,
    "map_boss_beaten": map_boss_beaten,
    "map_mini_boss": map_mini_boss,
    "map_mini_boss_beaten": map_mini_boss_beaten,
    "map_goal": map_goal,
}
