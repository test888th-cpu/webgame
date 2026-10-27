"""Gear icons for gen_ui.py: one 16x16 picture per piece of equipment that
used to borrow another item's icon, so every item looks like what it is.
Each is a small painter on an ImageDraw, in the house style: a dark outline,
two or three flat tones, one highlight. Painters that share a shape (caps,
helmets, vests, gloves, boots, rings) take their colours as arguments.
"""

from __future__ import annotations

from PIL import ImageDraw

OUTLINE = (24, 20, 28, 255)


def rgb(hex_colour: str) -> tuple[int, int, int, int]:
    h = hex_colour.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


# --- Head -------------------------------------------------------------------


def cap(d: ImageDraw.ImageDraw, crown: str, shade: str, brim: str, badge: str = "") -> None:
    """A peaked cap seen from the side, brim to the right."""
    d.pieslice((2, 4, 13, 17), 180, 360, fill=OUTLINE)
    d.pieslice((3, 5, 12, 16), 180, 360, fill=rgb(crown))
    d.line((4, 9, 11, 9), fill=rgb(shade))
    d.rectangle((2, 10, 15, 12), fill=OUTLINE)
    d.rectangle((3, 10, 14, 11), fill=rgb(brim))
    d.line((5, 6, 7, 5), fill=(255, 255, 255, 120))
    if badge:
        d.rectangle((7, 6, 8, 7), fill=rgb(badge))


def dockers_cap(d: ImageDraw.ImageDraw) -> None:
    cap(d, "#2f4f7a", "#223a5c", "#1b2c46", "#d8dde6")
    for x in (4, 6, 8, 10):  # quilted padding
        d.point((x, 8), fill=rgb("#4a6c9a"))


def watch_cap(d: ImageDraw.ImageDraw) -> None:
    # A rolled knit cap with the steel lining showing at the cuff.
    d.pieslice((2, 2, 14, 18), 180, 360, fill=OUTLINE)
    d.pieslice((3, 3, 13, 17), 180, 360, fill=rgb("#3b3f48"))
    for x in (5, 8, 11):
        d.line((x, 4, x, 9), fill=rgb("#2b2e35"))
    d.rectangle((2, 10, 14, 13), fill=OUTLINE)
    d.rectangle((3, 11, 13, 12), fill=rgb("#9aa2b0"))
    d.line((4, 11, 6, 11), fill=rgb("#d6dbe4"))


def helmet(d: ImageDraw.ImageDraw, shell: str, dark: str, visor: str, light: str) -> None:
    """A full helmet with a visor band."""
    d.pieslice((2, 1, 14, 19), 180, 360, fill=OUTLINE)
    d.pieslice((3, 2, 13, 18), 180, 360, fill=rgb(shell))
    d.rectangle((2, 10, 14, 14), fill=OUTLINE)
    d.rectangle((3, 11, 13, 13), fill=rgb(dark))
    d.rectangle((4, 7, 12, 9), fill=OUTLINE)
    d.rectangle((5, 8, 11, 8), fill=rgb(visor))
    d.point((10, 8), fill=rgb(light))
    d.line((5, 4, 6, 3), fill=(255, 255, 255, 140))


def facility_helmet(d: ImageDraw.ImageDraw) -> None:
    helmet(d, "#2c2f36", "#1d1f25", "#5fc8d6", "#d8f6fa")
    d.line((9, 4, 11, 5), fill=rgb("#8a8f9a"))  # the number, scratched off


def core_guard_helm(d: ImageDraw.ImageDraw) -> None:
    helmet(d, "#a7adba", "#6e7480", "#d23b3b", "#ffb0a0")
    d.line((8, 2, 8, 6), fill=rgb("#7c828e"))


def hazmat_hood(d: ImageDraw.ImageDraw) -> None:
    # A yellow rubber hood with a round window and a filter.
    d.ellipse((2, 1, 14, 15), fill=OUTLINE)
    d.ellipse((3, 2, 13, 14), fill=rgb("#e2c23a"))
    d.ellipse((5, 4, 12, 10), fill=OUTLINE)
    d.ellipse((6, 5, 11, 9), fill=rgb("#7fb7c9"))
    d.point((7, 6), fill=rgb("#e6f6fb"))
    d.ellipse((6, 10, 10, 14), fill=OUTLINE)
    d.ellipse((7, 11, 9, 13), fill=rgb("#4a4d55"))
    d.line((3, 13, 13, 13), fill=rgb("#b8971f"))


# --- Body -------------------------------------------------------------------


def coat(d: ImageDraw.ImageDraw, main: str, dark: str, sleeves: bool = True) -> None:
    """A jacket (with sleeves) or a vest, front view."""
    if sleeves:
        shape = [(5, 2), (10, 2), (14, 5), (13, 9), (11, 8), (11, 14), (4, 14), (4, 8), (2, 9), (1, 5)]
        inner = [(5, 3), (10, 3), (13, 5), (12, 7), (10, 6), (10, 13), (5, 13), (5, 6), (3, 7), (2, 5)]
    else:
        shape = [(4, 2), (7, 4), (9, 4), (12, 2), (13, 14), (3, 14)]
        inner = [(5, 3), (7, 5), (9, 5), (11, 3), (12, 13), (4, 13)]
    d.polygon(shape, fill=OUTLINE)
    d.polygon(inner, fill=rgb(main))
    d.line((7, 4, 7, 13), fill=rgb(dark))


def port_jacket(d: ImageDraw.ImageDraw) -> None:
    coat(d, "#e2762e", "#a5501c")
    for y in (8, 11):  # reflective strips
        d.line((5, y, 10, y), fill=rgb("#dfe6ee"))
    d.point((3, 6), fill=rgb("#dfe6ee"))
    d.point((12, 6), fill=rgb("#dfe6ee"))


def plant_vest(d: ImageDraw.ImageDraw) -> None:
    coat(d, "#6f7a86", "#4c5560", sleeves=False)
    d.rectangle((5, 7, 10, 11), fill=OUTLINE)
    d.rectangle((6, 8, 9, 10), fill=rgb("#a9b3bf"))  # the plate
    d.rectangle((5, 5, 6, 5), fill=rgb("#e0c13a"))  # a security badge


def kevlar_jacket(d: ImageDraw.ImageDraw) -> None:
    coat(d, "#4a5236", "#323823")
    for y in (6, 9, 12):
        d.line((5, y, 10, y), fill=rgb("#5e6845"))
    d.point((6, 5), fill=rgb("#8e9672"))


def trooper_vest(d: ImageDraw.ImageDraw) -> None:
    coat(d, "#24262c", "#141519", sleeves=False)
    d.rectangle((5, 6, 10, 12), fill=rgb("#3a3d45"))
    for y in (7, 10):
        d.line((5, y, 10, y), fill=rgb("#5a5e68"))
    d.point((9, 5), fill=rgb("#5fc8d6"))


def reactor_plate(d: ImageDraw.ImageDraw) -> None:
    # Lead plates with a hazard stripe.
    d.polygon([(3, 2), (12, 2), (14, 6), (13, 14), (2, 14), (1, 6)], fill=OUTLINE)
    d.polygon([(4, 3), (11, 3), (13, 6), (12, 13), (3, 13), (2, 6)], fill=rgb("#7d838e"))
    d.line((3, 8, 12, 8), fill=rgb("#5b606a"))
    for x in (4, 7, 10):
        d.line((x, 10, x + 1, 11), fill=rgb("#e8c432"))
    d.point((5, 5), fill=rgb("#c4c9d2"))


def zeros_mantle(d: ImageDraw.ImageDraw) -> None:
    # A lab coat, hardened and stained with sludge.
    coat(d, "#e8ecef", "#b8bfc6")
    d.polygon([(5, 10), (8, 9), (10, 12), (10, 13), (5, 13)], fill=rgb("#5f9a4a"))
    d.point((11, 6), fill=rgb("#5f9a4a"))
    d.point((4, 7), fill=rgb("#78b45e"))


# --- Hands ------------------------------------------------------------------


def glove(d: ImageDraw.ImageDraw, main: str, dark: str, cuff: str) -> None:
    """A full glove, back of the hand, fingers up."""
    d.rounded_rectangle((3, 4, 12, 14), radius=2, fill=OUTLINE)
    for x in (3, 5, 7, 9):
        d.rectangle((x, 1, x + 2, 5), fill=OUTLINE)
        d.rectangle((x + 1, 2, x + 1, 5), fill=rgb(main))
    d.rounded_rectangle((4, 5, 11, 11), radius=1, fill=rgb(main))
    d.rectangle((12, 6, 14, 9), fill=OUTLINE)
    d.rectangle((12, 7, 13, 8), fill=rgb(main))
    d.rectangle((4, 11, 11, 13), fill=rgb(cuff))
    d.line((5, 8, 10, 8), fill=rgb(dark))


def cargo_gloves(d: ImageDraw.ImageDraw) -> None:
    glove(d, "#9a6a3c", "#6e4826", "#5a3a1e")


def insulated_gloves(d: ImageDraw.ImageDraw) -> None:
    glove(d, "#e8c534", "#b8961c", "#2b2e35")
    d.line((6, 6, 8, 9), fill=rgb("#2b2e35"))  # a lightning mark
    d.line((8, 9, 9, 7), fill=rgb("#2b2e35"))


def fight_gloves(d: ImageDraw.ImageDraw) -> None:
    glove(d, "#b8392f", "#842620", "#efe8da")
    for y in (6, 9):  # fresh tape
        d.line((4, y, 11, y), fill=rgb("#efe8da"))


def grip_gloves(d: ImageDraw.ImageDraw) -> None:
    glove(d, "#3f7fc6", "#2a5a92", "#2a5a92")
    for x, y in ((5, 7), (7, 9), (9, 7), (6, 10)):  # rubber grip dots
        d.point((x, y), fill=rgb("#a9cdf0"))


def gauntlet(d: ImageDraw.ImageDraw, main: str, dark: str, light: str) -> None:
    """A heavy gauntlet with a flared cuff."""
    d.polygon([(2, 9), (4, 2), (12, 2), (14, 9), (13, 15), (3, 15)], fill=OUTLINE)
    d.polygon([(3, 9), (5, 3), (11, 3), (13, 9), (12, 14), (4, 14)], fill=rgb(main))
    for x in (5, 8, 11):
        d.line((x, 3, x, 6), fill=rgb(dark))
    d.line((3, 10, 13, 10), fill=rgb(dark))
    d.point((6, 4), fill=rgb(light))


def insulated_gauntlets(d: ImageDraw.ImageDraw) -> None:
    gauntlet(d, "#e07a2c", "#9e4f16", "#ffc58f")
    d.line((6, 7, 9, 7), fill=rgb("#2b2e35"))


def piston_gauntlets(d: ImageDraw.ImageDraw) -> None:
    gauntlet(d, "#8c929e", "#555a64", "#e4e8ef")
    for x in (5, 10):  # hydraulic rods
        d.rectangle((x, 8, x + 1, 13), fill=rgb("#d6a64a"))
    d.point((8, 12), fill=rgb("#ff7a3a"))


# --- Feet -------------------------------------------------------------------


def boot(d: ImageDraw.ImageDraw, upper: str, dark: str, sole: str) -> None:
    """A tall boot, toe to the right."""
    d.polygon([(3, 1), (8, 1), (8, 9), (14, 10), (14, 14), (3, 14)], fill=OUTLINE)
    d.polygon([(4, 2), (7, 2), (7, 10), (13, 11), (13, 12), (4, 12)], fill=rgb(upper))
    d.line((3, 13, 14, 13), fill=rgb(sole))
    d.line((4, 5, 7, 5), fill=rgb(dark))


def sneaker(d: ImageDraw.ImageDraw, upper: str, stripe: str, sole: str) -> None:
    """A low sneaker, toe to the right."""
    d.polygon([(2, 6), (7, 6), (9, 9), (14, 10), (14, 13), (2, 13)], fill=OUTLINE)
    d.polygon([(3, 7), (7, 7), (8, 10), (13, 11), (13, 12), (3, 12)], fill=rgb(upper))
    d.line((4, 11, 9, 9), fill=rgb(stripe))
    d.line((2, 13, 14, 13), fill=rgb(sole))
    d.point((5, 8), fill=(255, 255, 255, 255))


def deck_boots(d: ImageDraw.ImageDraw) -> None:
    boot(d, "#e2b62e", "#b08a18", "#2b2e35")  # yellow rubber


def lab_boots(d: ImageDraw.ImageDraw) -> None:
    boot(d, "#e8ecef", "#b8bfc6", "#5fa3c6")


def facility_boots(d: ImageDraw.ImageDraw) -> None:
    boot(d, "#2a2c33", "#17181d", "#8a8f9a")
    d.point((5, 3), fill=rgb("#5fc8d6"))


def walkway_boots(d: ImageDraw.ImageDraw) -> None:
    boot(d, "#6a707c", "#474c56", "#e07a2c")
    for x in (5, 8, 11):  # grip tread
        d.point((x, 14), fill=rgb("#e07a2c"))


def runner_sneakers(d: ImageDraw.ImageDraw) -> None:
    sneaker(d, "#3fae6a", "#f2e24a", "#ecedf2")


# --- Weapons ----------------------------------------------------------------


def harbour_hook(d: ImageDraw.ImageDraw) -> None:
    # A cargo hook on a wooden T-handle.
    d.rectangle((2, 2, 11, 5), fill=OUTLINE)
    d.rectangle((3, 3, 10, 4), fill=rgb("#8a5a32"))
    d.rectangle((5, 5, 8, 9), fill=OUTLINE)
    d.rectangle((6, 5, 7, 8), fill=rgb("#9aa2b0"))
    d.arc((4, 6, 14, 16), 270, 180, fill=OUTLINE, width=3)
    d.arc((5, 7, 13, 15), 270, 180, fill=rgb("#b9c0cc"))
    d.point((4, 11), fill=rgb("#e4e8ef"))


def baton(d: ImageDraw.ImageDraw, shaft: str, shine: str, grip: str) -> None:
    """A baton, diagonal, grip at the bottom left."""
    d.line((3, 13, 13, 3), fill=OUTLINE, width=4)
    d.line((3, 13, 13, 3), fill=rgb(shaft), width=2)
    d.line((6, 9, 12, 3), fill=rgb(shine))
    d.line((2, 14, 5, 11), fill=OUTLINE, width=4)
    d.line((2, 14, 5, 11), fill=rgb(grip), width=2)


def chiefs_baton(d: ImageDraw.ImageDraw) -> None:
    baton(d, "#2b2d33", "#5a5e68", "#7a5230")


def arthit_baton(d: ImageDraw.ImageDraw) -> None:
    baton(d, "#9aa2b0", "#e4e8ef", "#d6a64a")


def ringmaster_wraps(d: ImageDraw.ImageDraw) -> None:
    # Red hand wraps with a loose tail of tape.
    d.rounded_rectangle((3, 3, 12, 13), radius=3, fill=OUTLINE)
    d.rounded_rectangle((4, 4, 11, 12), radius=2, fill=rgb("#c3342c"))
    for y in (6, 9):
        d.line((4, y, 11, y), fill=rgb("#8a201a"))
    d.line((11, 11, 14, 14), fill=OUTLINE, width=3)
    d.line((11, 11, 14, 14), fill=rgb("#c3342c"))
    d.point((6, 5), fill=rgb("#ff8a7a"))


def mothers_fang(d: ImageDraw.ImageDraw) -> None:
    # A huge curved tooth set in tar-black tape.
    d.polygon([(4, 1), (12, 3), (13, 9), (9, 15), (7, 9), (3, 5)], fill=OUTLINE)
    d.polygon([(5, 2), (11, 4), (12, 8), (9, 13), (8, 8), (4, 5)], fill=rgb("#efe6cf"))
    d.line((9, 5, 11, 8), fill=rgb("#c9bd9e"))
    d.rectangle((3, 3, 8, 6), fill=OUTLINE)
    d.rectangle((4, 4, 7, 5), fill=rgb("#26222a"))


def iron_legacy(d: ImageDraw.ImageDraw) -> None:
    # Dark iron knuckles with the Core's glow in the seams.
    d.rounded_rectangle((1, 5, 14, 10), radius=2, fill=OUTLINE)
    for x in (2, 5, 8, 11):
        d.ellipse((x, 5, x + 3, 9), fill=rgb("#3a3d45"), outline=OUTLINE)
        d.point((x + 1, 7), fill=rgb("#5fe0f0"))
    d.polygon([(3, 10), (12, 10), (10, 14), (5, 14)], fill=OUTLINE)
    d.polygon([(4, 10), (11, 10), (9, 13), (6, 13)], fill=rgb("#3a3d45"))
    d.line((6, 12, 9, 12), fill=rgb("#5fe0f0"))


# --- Charms -----------------------------------------------------------------


def ring(d: ImageDraw.ImageDraw, band: str, shine: str, stone: str) -> None:
    """A signet ring with its seal."""
    d.ellipse((2, 5, 13, 15), fill=OUTLINE)
    d.ellipse((3, 6, 12, 14), fill=rgb(band))
    d.ellipse((5, 8, 10, 12), fill=OUTLINE)
    d.rectangle((4, 1, 11, 6), fill=OUTLINE)
    d.rectangle((5, 2, 10, 5), fill=rgb(stone))
    d.point((4, 9), fill=rgb(shine))


def sak_signet(d: ImageDraw.ImageDraw) -> None:
    ring(d, "#d6a64a", "#fff1a0", "#8a1f1a")
    d.point((7, 3), fill=rgb("#f2c14a"))  # the gang's mark


def director_signet(d: ImageDraw.ImageDraw) -> None:
    ring(d, "#dfe3ea", "#ffffff", "#2f5aa8")
    d.line((6, 3, 9, 3), fill=rgb("#c9d6f0"))


def k7_core_plate(d: ImageDraw.ImageDraw) -> None:
    # A warm metal plate with K-7's core still glowing.
    d.rectangle((2, 3, 13, 13), fill=OUTLINE)
    d.rectangle((3, 4, 12, 12), fill=rgb("#7d838e"))
    for x, y in ((4, 5), (11, 5), (4, 11), (11, 11)):
        d.point((x, y), fill=rgb("#c4c9d2"))
    d.ellipse((5, 6, 10, 11), fill=OUTLINE)
    d.ellipse((6, 7, 9, 10), fill=rgb("#5fe0f0"))
    d.point((7, 8), fill=rgb("#e6fbff"))


def subject_band(d: ImageDraw.ImageDraw) -> None:
    # A patient wristband with a name label.
    d.ellipse((1, 3, 14, 13), fill=OUTLINE)
    d.ellipse((2, 4, 13, 12), fill=rgb("#e8ecef"))
    d.ellipse((4, 6, 11, 10), fill=OUTLINE)
    d.rectangle((5, 10, 10, 13), fill=OUTLINE)
    d.rectangle((6, 11, 9, 12), fill=rgb("#efe6cf"))
    d.point((7, 11), fill=rgb("#5a4a3c"))


def mothers_heart(d: ImageDraw.ImageDraw) -> None:
    # A green stone heart on a cord.
    d.arc((3, 0, 13, 8), 200, 340, fill=rgb("#4a3a2c"))
    d.polygon([(8, 15), (2, 8), (2, 5), (5, 3), (8, 5), (11, 3), (14, 5), (14, 8)], fill=OUTLINE)
    d.polygon([(8, 14), (3, 8), (3, 5), (5, 4), (8, 6), (11, 4), (13, 5), (13, 8)], fill=rgb("#3f9a5a"))
    d.polygon([(8, 12), (5, 8), (6, 6), (8, 7)], fill=rgb("#6fd38a"))
    d.point((5, 6), fill=rgb("#d8ffe0"))


def colossus_core(d: ImageDraw.ImageDraw) -> None:
    # A power cell, still warm.
    d.rectangle((4, 1, 11, 15), fill=OUTLINE)
    d.rectangle((5, 2, 10, 14), fill=rgb("#555a64"))
    d.rectangle((6, 4, 9, 12), fill=rgb("#ff8a3a"))
    d.rectangle((7, 5, 8, 11), fill=rgb("#ffd08a"))
    d.rectangle((6, 1, 9, 2), fill=rgb("#9aa2b0"))
    d.line((5, 8, 10, 8), fill=rgb("#555a64"))


GEAR_ICONS = {
    "dockers_cap": dockers_cap,
    "watch_cap": watch_cap,
    "facility_helmet": facility_helmet,
    "core_guard_helm": core_guard_helm,
    "hazmat_hood": hazmat_hood,
    "port_jacket": port_jacket,
    "plant_vest": plant_vest,
    "kevlar_jacket": kevlar_jacket,
    "trooper_vest": trooper_vest,
    "reactor_plate": reactor_plate,
    "zeros_mantle": zeros_mantle,
    "cargo_gloves": cargo_gloves,
    "insulated_gloves": insulated_gloves,
    "fight_gloves": fight_gloves,
    "grip_gloves": grip_gloves,
    "insulated_gauntlets": insulated_gauntlets,
    "piston_gauntlets": piston_gauntlets,
    "deck_boots": deck_boots,
    "lab_boots": lab_boots,
    "facility_boots": facility_boots,
    "walkway_boots": walkway_boots,
    "runner_sneakers": runner_sneakers,
    "harbour_hook": harbour_hook,
    "chiefs_baton": chiefs_baton,
    "arthit_baton": arthit_baton,
    "ringmaster_wraps": ringmaster_wraps,
    "mothers_fang": mothers_fang,
    "iron_legacy": iron_legacy,
    "sak_signet": sak_signet,
    "director_signet": director_signet,
    "k7_core_plate": k7_core_plate,
    "subject_band": subject_band,
    "mothers_heart": mothers_heart,
    "colossus_core": colossus_core,
}
