#!/usr/bin/env python3
"""Cut the owner's TEMPORARY PLACEHOLDER hat sheets into one sprite per hat.

  python3 tools/assets/import_placeholder_hats.py

PLACEHOLDER ART ONLY: these hats exist to build and test the equipment
appearance system. They are not production art and nothing depends on them:
the game knows each hat only by its appearance id (appearances.json), whose
asset entry (placeholder_art.json) names one of these sprites; final art from
the owner's own Blender 5.2 pipeline replaces an asset entry, never an item,
appearance id or save. This tool is not part of that pipeline.

Reads art/placeholder/hats/sheet_1.jpg .. sheet_4.jpg (the owner's magenta
background sheets, six hats each, every hat facing right like the
characters) and writes, per hat in HATS:
  client/assets/placeholder/hats/<id>.png       the hat at its size on the character
  client/assets/placeholder/hats/<id>_icon.png  a 16x16 icon
  client/assets/placeholder/hats/hats.json      sizes and the sheet each came from

How a hat is found: the sheet's background colour is the median of its
border; pixels far from it are the hat; touching pixels form one piece
(flood fill); a small piece (a halo, a sparkle) joins the big piece it lies
next to; big pieces never join. The hats are numbered left to right, top
row first. No sheet is cut into equal cells.
How it is cleaned: the background goes (alpha 0, hard edges, as pixel art),
the hat is cropped to its outline and scaled down by area averaging to the
width it is worn at (`width`), then its edge is hardened again.
"""

from __future__ import annotations

import collections
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art" / "placeholder" / "hats"
OUT = ROOT / "client" / "assets" / "placeholder" / "hats"
THRESHOLD = 70.0
MERGE = 30
BIG = 15000
ICON = 16
BAND_ROWS = {"crystal_tiara": 7, "phoenix_tiara": 7, "rising_sun_headband": 9, "cyber_visor": 12}

# (sheet, place on the sheet, id, fit, width worn in pixels)
# fit "cover": a hat, helmet, hood or crown that replaces whatever the
# character has on its head; "band": a headband, tiara or visor worn over the
# hair, its middle on row BAND_ROWS[id] from the top of the head (a tiara on
# the crown, a headband on the brow, a visor over the eyes); "hood": a hood or
# an open helm worn round the face, its dark opening made see-through so the
# face shows inside it.
HATS = [
    (1, 1, "arcane_wizard_hat", "cover", 32),
    (1, 2, "golden_lion_helm", "cover", 28),
    (1, 3, "sakura_wizard_hat", "cover", 32),
    (1, 4, "frost_fur_hood", "hood", 28),
    (1, 5, "dragonscale_hood", "hood", 28),
    (1, 6, "starlight_wizard_hat", "cover", 32),
    (2, 1, "lion_king_crown", "cover", 28),
    (2, 2, "crystal_tiara", "band", 26),
    (2, 3, "sakura_straw_hat", "cover", 34),
    (2, 4, "midnight_wizard_hat", "cover", 32),
    (2, 5, "glacier_crown", "cover", 27),
    (2, 6, "emerald_feather_hat", "cover", 32),
    (3, 1, "horned_crown", "cover", 28),
    (3, 2, "ice_crown", "cover", 27),
    (3, 3, "officer_cap", "cover", 30),
    (3, 4, "phoenix_feather_hat", "cover", 32),
    (3, 5, "obsidian_crown", "cover", 27),
    (3, 6, "crested_knight_helm", "cover", 28),
    (4, 1, "rising_sun_headband", "band", 30),
    (4, 2, "jewelled_crown", "cover", 27),
    (4, 3, "dragon_bandana", "cover", 29),
    (4, 4, "tiger_hood", "cover", 28),
    (4, 5, "phoenix_tiara", "band", 28),
    (4, 6, "cyber_visor", "band", 27),
]


def pieces(image: Image.Image) -> list[dict]:
    w, h = image.size
    px = image.load()
    border = [px[x, y] for x in range(w) for y in (0, 1, h - 2, h - 1)]
    border += [px[x, y] for y in range(h) for x in (0, 1, w - 2, w - 1)]
    bg = [sorted(c[i] for c in border)[len(border) // 2] for i in range(3)]

    def far(c: tuple) -> bool:
        return sum((c[i] - bg[i]) ** 2 for i in range(3)) ** 0.5 > THRESHOLD

    label = [[0] * w for _ in range(h)]
    found = []
    for y in range(h):
        for x in range(w):
            if label[y][x] or not far(px[x, y]):
                continue
            n = len(found) + 1
            label[y][x] = n
            todo = collections.deque([(x, y)])
            box = [x, y, x, y]
            area = 0
            while todo:
                cx, cy = todo.popleft()
                area += 1
                box = [min(box[0], cx), min(box[1], cy), max(box[2], cx), max(box[3], cy)]
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not label[ny][nx] and far(px[nx, ny]):
                        label[ny][nx] = n
                        todo.append((nx, ny))
            found.append({"box": box, "area": area, "labels": {n}})
    big = [p for p in found if p["area"] >= BIG]
    for p in found:
        if p["area"] >= BIG:
            continue
        for b in big:
            bx, px_ = b["box"], p["box"]
            if bx[0] - MERGE <= px_[2] and px_[0] - MERGE <= bx[2] and bx[1] - MERGE <= px_[3] and px_[1] - MERGE <= bx[3]:
                b["box"] = [min(bx[0], px_[0]), min(bx[1], px_[1]), max(bx[2], px_[2]), max(bx[3], px_[3])]
                b["labels"] |= p["labels"]
                break
    big.sort(key=lambda p: (int((p["box"][1] + p["box"][3]) / 2 > h / 2), p["box"][0]))
    for p in big:
        p["label_map"] = label
    return big


def cut(image: Image.Image, piece: dict) -> Image.Image:
    x0, y0, x1, y1 = piece["box"]
    out = Image.new("RGBA", (x1 - x0 + 1, y1 - y0 + 1), (0, 0, 0, 0))
    src, dst = image.load(), out.load()
    label = piece["label_map"]
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if label[y][x] in piece["labels"]:
                r, g, b = src[x, y]
                dst[x - x0, y - y0] = (r, g, b, 255)
    return out


def shrink(hat: Image.Image, width: int) -> Image.Image:
    height = max(1, round(hat.height * width / hat.width))
    # Area averaging with premultiplied colour, then hard edges again.
    small = hat.resize((width, height), Image.Resampling.BOX, reducing_gap=None)
    px = small.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 110 else (0, 0, 0, 0)
    return small


def anchor(hat: Image.Image) -> list[int]:
    """Where the hat meets the head, in its own pixels: [x, base, middle].
    x is the centre of its mass (so a knot, a feather or a wizard's tip does
    not pull it off the head); the main body is the rows at least half as
    wide as the widest, base its lowest row (the brim, not a dangling
    ribbon) and middle its centre row (for a band)."""
    px = hat.load()
    widths = []
    total = sum_x = 0
    for y in range(hat.height):
        row = [x for x in range(hat.width) if px[x, y][3] > 0]
        widths.append(len(row))
        total += len(row)
        sum_x += sum(row)
    body = [y for y, w in enumerate(widths) if w >= max(widths) / 2]
    return [round(sum_x / max(total, 1)), body[-1], round((body[0] + body[-1]) / 2)]


# Where each hood's opening is (where the face goes), read off the art: a
# point inside it (share of the cut-out's width and height), how far its
# colour may drift from that point's, and how far (share of the width) it may
# reach. The region grows from the point over pixels like their neighbours
# and like it, so it stops at the rim; the reach keeps it off the dark
# outlines that run on round the hood.
OPENINGS = {
    "frost_fur_hood": ((0.65, 0.55), 95.0, 1.0),
    "dragonscale_hood": ((0.70, 0.62), 22.0, 0.2),
}
STEP = 38.0


def open_hood(hat: Image.Image, spec: tuple) -> None:
    """Makes a hood's opening see-through, so the face shows inside it."""
    seed_at, spread, reach = spec
    px = hat.load()
    w, h = hat.size
    sx, sy = int(w * seed_at[0]), int(h * seed_at[1])
    radius = reach * w
    seed = px[sx, sy][:3]

    def near(a: tuple, b: tuple, limit: float) -> bool:
        return sum((a[i] - b[i]) ** 2 for i in range(3)) ** 0.5 < limit

    seen = {(sx, sy)}
    todo = collections.deque([(sx, sy)])
    while todo:
        cx, cy = todo.popleft()
        here = px[cx, cy][:3]
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if not (0 <= nx < w and 0 <= ny < h) or (nx, ny) in seen or px[nx, ny][3] == 0:
                continue
            there = px[nx, ny][:3]
            close = ((nx - sx) ** 2 + (ny - sy) ** 2) ** 0.5 <= radius
            if close and near(here, there, STEP) and near(seed, there, spread):
                seen.add((nx, ny))
                todo.append((nx, ny))
    for x, y in seen:
        px[x, y] = (0, 0, 0, 0)


def opening_of(worn: Image.Image, cut: Image.Image) -> list[int]:
    """The see-through opening's centre in the worn sprite: the centre of
    the transparent pixels inside the hat's outline."""
    px = worn.load()
    inside = []
    for y in range(worn.height):
        row = [x for x in range(worn.width) if px[x, y][3] > 0]
        if len(row) < 2:
            continue
        for x in range(row[0], row[-1] + 1):
            if px[x, y][3] == 0:
                inside.append((x, y))
    if not inside:
        return [worn.width // 2, worn.height // 2]
    return [round(sum(p[0] for p in inside) / len(inside)), round(sum(p[1] for p in inside) / len(inside))]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    sheets = {}
    for sheet, place, hat_id, fit, width in HATS:
        if sheet not in sheets:
            image = Image.open(SOURCE / f"sheet_{sheet}.jpg").convert("RGB")
            found = pieces(image)
            if len(found) != 6:
                raise SystemExit(f"sheet_{sheet}.jpg: {len(found)} hats found, expected 6")
            sheets[sheet] = (image, found)
        image, found = sheets[sheet]
        hat = cut(image, found[place - 1])
        if fit == "hood":
            open_hood(hat, OPENINGS[hat_id])
        worn = shrink(hat, width)
        opening = opening_of(worn, hat) if fit == "hood" else None
        worn.save(OUT / f"{hat_id}.png")
        icon = hat.copy()
        icon.thumbnail((ICON * 8, ICON * 8))
        side = max(icon.size)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        square.alpha_composite(icon, ((side - icon.width) // 2, (side - icon.height) // 2))
        shrink(square, ICON).save(OUT / f"{hat_id}_icon.png")
        meta[hat_id] = {
            "sheet": f"art/placeholder/hats/sheet_{sheet}.jpg",
            "place": place,
            "box": found[place - 1]["box"],
            "fit": fit,
            "size": list(worn.size),
            "anchor": anchor(worn),
        }
        if fit == "band":
            meta[hat_id]["row"] = BAND_ROWS[hat_id]
        if opening:
            meta[hat_id]["opening"] = opening
    (OUT / "hats.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(f"{len(meta)} hats from {len(sheets)} sheets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
