#!/usr/bin/env python3
"""Imports character art drawn outside the LPC generator: sprite sheets the
project owner supplies in art/custom/<asset_id>/ with an import.json.

  python3 tools/assets/custom_import.py [asset_id ...]

import.json names the source sheets (a grid of equal cells, `count` frames read
left to right, top to bottom) and the scale that brings each sheet to the game's
size; sheets drawn at different sizes get different scales so the character
matches across them. A sheet painted on a flat green backdrop says `"key": true`
and the green is cut out the way the street kit's is (tools/assets/kit_import.py);
otherwise the sheet must be transparent. Frames are anchored on the feet of each sheet's first
frame, so a whole sheet keeps its own alignment.

Each game animation either picks frames from a sheet, or (`from`) is derived
from one frame by tilting it about the feet: how hurt and knock-down are made
when the art has no such frames. Writes, like the LPC builder:
  client/assets/characters/<id>/sheet.png, hands.png, credits.json
and the manifest entry, including weapon hand sockets: the front fist found as
the most forward opaque pixel at arm height, with angles from `weapon_pose`.
Run make_spriteframes.py afterwards.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
import kit_import  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art" / "custom"
OUT_DIR = ROOT / "client" / "assets" / "characters"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"
# The arm band, as a share of the figure's height from the top of its head.
ARM_BAND = (0.3, 0.62)
FIST_RADIUS = 3
# The LPC characters have a dark 1 px outline; art without one gets it, so all
# characters read the same against the street.
OUTLINE = (24, 20, 28, 255)


class ImportError_(Exception):
    pass


def opaque_box(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()


def scaled_frames(folder: Path, spec: dict, size: tuple[int, int], feet: tuple[int, int]) -> list[Image.Image]:
    """The sheet's frames, scaled and placed so its first frame's feet land on `feet`."""
    with Image.open(folder / spec["file"]) as opened:
        sheet = keyed(opened) if spec.get("key", False) else opened.convert("RGBA")
    cols, rows = spec["cols"], spec["rows"]
    cw, ch = sheet.width // cols, sheet.height // rows
    if spec["count"] > cols * rows:
        raise ImportError_(f"{spec['file']}: {spec['count']} frames do not fit {cols}x{rows}")
    cells = [sheet.crop(((i % cols) * cw, (i // cols) * ch, (i % cols + 1) * cw, (i // cols + 1) * ch))
             for i in range(spec["count"])]
    box = opaque_box(cells[0])
    if box is None:
        raise ImportError_(f"{spec['file']}: the first frame is empty")
    scale = float(spec["scale"])
    anchor = ((box[0] + box[2]) / 2 * scale, box[3] * scale)
    out = []
    for index, cell in enumerate(cells):
        if opaque_box(cell) is None:
            raise ImportError_(f"{spec['file']}: frame {index} is empty")
        # Premultiplied resampling keeps edges clean; then a hard alpha cut
        # keeps the pixel-art look crisp.
        small = cell.convert("RGBa").resize((round(cw * scale), round(ch * scale)), Image.LANCZOS).convert("RGBA")
        alpha = small.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
        small.putalpha(alpha)
        frame = Image.new("RGBA", size, (0, 0, 0, 0))
        frame.alpha_composite(small, (round(feet[0] - anchor[0]), round(feet[1] - anchor[1])))
        out.append(outlined(frame) if spec.get("outline", False) else frame)
    return out


def keyed(source: Image.Image) -> Image.Image:
    """The sheet with its flat green backdrop (and green enclosed by a figure,
    between arm and body) made transparent, and the green fringe pulled out of
    the figures' edges. Unlike a kit piece it is not trimmed: the grid stays."""
    image = source.convert("RGB")
    w, h = image.size
    spill = kit_import.green_spill(image).tobytes()
    gone = kit_import.backdrop(spill, bytes(w * h), w, h)
    for i, value in enumerate(spill):
        if value >= kit_import.HOLE_MARGIN:
            gone[i] = 1
    mask = Image.frombytes("L", (w, h), bytes(255 * (1 - v) for v in gone))
    # Only the rim takes the green pulled out: green clothes stay green.
    rim = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(5)))
    r, g, b = image.split()
    g = Image.composite(ImageChops.darker(g, ImageChops.lighter(r, b)), g, rim)
    return Image.merge("RGBA", (r, g, b, mask))


# A painted sheet of loose figures ("figures": true): the sheet is keyed at this
# width at most, grid lines (long straight dark runs) are taken for backdrop,
# and blobs smaller than MIN_FIGURE pixels (specks, slash marks) are dropped.
FIGURE_WORK_WIDTH = 1000
GRID_RUN = 60
MIN_FIGURE = 120
# Figures whose feet lie within this many working pixels form one row.
ROW_GAP = 20


def figure_rows(
    path: Path, target: int, measure: list[int], row_scale: dict | None = None
) -> list[list[Image.Image]]:
    """The figures painted on a sheet without a strict grid, as rows (top to
    bottom, by where their feet are) of frames (left to right). Each figure is
    scaled so the `measure` figure ([row, index]) stands `target` pixels tall,
    cut out on its own (bits of a neighbour never come along), with its feet
    (the middle of its lowest fifth) at the bottom middle of a tight image."""
    with Image.open(path) as opened:
        image = opened.convert("RGB")
    if image.width > FIGURE_WORK_WIDTH:
        image = image.resize((FIGURE_WORK_WIDTH, round(image.height * FIGURE_WORK_WIDTH / image.width)), Image.LANCZOS)
    w, h = image.size
    spill = bytearray(kit_import.green_spill(image).tobytes())
    for i in grid_lines(image):
        spill[i] = 255
    gone = kit_import.backdrop(bytes(spill), bytes(w * h), w, h)
    for i, value in enumerate(spill):
        if value >= kit_import.HOLE_MARGIN:
            gone[i] = 1
    solid = bytearray(1 - v for v in gone)
    blobs = [g for g in kit_import.components(solid, w, h) if len(g) >= MIN_FIGURE]
    keyed_image = keyed(image)
    found = []
    for blob in blobs:
        xs = [i % w for i in blob]
        ys = [i // w for i in blob]
        box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        low = box[3] - max(1, (box[3] - box[1]) // 5)
        feet_x = sum(x for x, y in zip(xs, ys) if y >= low) / max(1, sum(1 for y in ys if y >= low))
        cut = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), (0, 0, 0, 0))
        src = keyed_image.load()
        dst = cut.load()
        for x, y in zip(xs, ys):
            dst[x - box[0], y - box[1]] = src[x, y]
        found.append((box, feet_x, cut))
    found.sort(key=lambda f: f[0][3])
    rows: list[list[tuple]] = []
    for figure in found:
        if rows and figure[0][3] - rows[-1][-1][0][3] <= ROW_GAP:
            rows[-1].append(figure)
        else:
            rows.append([figure])
    for row in rows:
        row.sort(key=lambda f: f[0][0])
    ref = rows[measure[0]][measure[1]][0]
    base = target / (ref[3] - ref[1])
    out = []
    for index, row in enumerate(rows):
        # A row the painter drew smaller (or larger) than the rest is brought
        # back to the same size ("row_scale": {"row": factor}).
        scale = base * float((row_scale or {}).get(str(index), 1.0))
        frames = []
        for box, feet_x, cut in row:
            small = cut.convert("RGBa").resize(
                (max(1, round(cut.width * scale)), max(1, round(cut.height * scale))), Image.LANCZOS
            ).convert("RGBA")
            small.putalpha(small.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
            frames.append((small, (feet_x - box[0]) * scale))
        out.append(frames)
    return out


def grid_lines(image: Image.Image) -> list[int]:
    """Pixel indices of straight dark runs at least GRID_RUN long, across or
    down: the grid a painter drew between cells, never part of a figure."""
    w, h = image.size
    px = image.load()
    out = []

    def dark(p: tuple[int, int, int]) -> bool:
        return max(p) < 90 and max(p) - min(p) < 40

    for y in range(h):
        run = 0
        for x in range(w + 1):
            if x < w and dark(px[x, y]):
                run += 1
                continue
            if run >= GRID_RUN:
                out.extend(y * w + xx for xx in range(x - run, x))
            run = 0
    for x in range(w):
        run = 0
        for y in range(h + 1):
            if y < h and dark(px[x, y]):
                run += 1
                continue
            if run >= GRID_RUN:
                out.extend(yy * w + x for yy in range(y - run, y))
            run = 0
    return out


def placed(figure: tuple[Image.Image, float], size: tuple[int, int], feet: tuple[int, int]) -> Image.Image:
    small, feet_x = figure
    frame = Image.new("RGBA", size, (0, 0, 0, 0))
    frame.alpha_composite(small, (round(feet[0] - feet_x), feet[1] - small.height))
    return frame


def outlined(frame: Image.Image) -> Image.Image:
    alpha = frame.getchannel("A").load()
    out = frame.copy()
    pixels = out.load()
    w, h = frame.size
    for y in range(h):
        for x in range(w):
            if alpha[x, y]:
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h and alpha[nx, ny]:
                    pixels[x, y] = OUTLINE
                    break
    return out


def tilted(frame: Image.Image, degrees: float, shift: int, feet: tuple[int, int]) -> Image.Image:
    """`frame` leaning back by `degrees` about the feet (90 = flat on its back)."""
    turned = frame.rotate(degrees, resample=Image.NEAREST, center=feet)
    out = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    if shift >= 0:
        out.alpha_composite(turned, dest=(shift, 0))
    else:
        out.alpha_composite(turned, source=(-shift, 0))
    return out


def fist(frame: Image.Image) -> tuple[int, int] | None:
    """The front fist: the most forward opaque pixel at arm height."""
    box = opaque_box(frame)
    if box is None:
        return None
    top = box[1] + round((box[3] - box[1]) * ARM_BAND[0])
    bottom = box[1] + round((box[3] - box[1]) * ARM_BAND[1])
    alpha = frame.getchannel("A").load()
    for x in range(frame.width - 1, -1, -1):
        ys = [y for y in range(top, bottom + 1) if alpha[x, y] >= 128]
        if ys:
            return (x - 2, round(sum(ys) / len(ys)))
    return None


def fist_pixels(frame: Image.Image, at: tuple[int, int]) -> list[tuple[int, int]]:
    alpha = frame.getchannel("A").load()
    pixels = []
    for y in range(max(0, at[1] - FIST_RADIUS), min(frame.height, at[1] + FIST_RADIUS + 1)):
        for x in range(max(0, at[0] - FIST_RADIUS), min(frame.width, at[0] + FIST_RADIUS + 1)):
            if alpha[x, y] >= 128 and (x - at[0]) ** 2 + (y - at[1]) ** 2 <= FIST_RADIUS ** 2:
                pixels.append((x, y))
    return pixels


def head_and_shoulders(frame: Image.Image, size: int) -> list[int]:
    """A square crop around the head of the first idle frame, for HUD and
    hero-select portraits: the head's centre is found from its top rows."""
    box = opaque_box(frame)
    if box is None:
        return [0, 0, size, size]
    alpha = frame.getchannel("A").load()
    xs = [x for y in range(box[1], box[1] + 8) for x in range(frame.width) if alpha[x, y] >= 128]
    centre = round(sum(xs) / len(xs))
    return [centre - size // 2, max(0, box[1] - 2), size, size]


def pick(frames: list, at: int | list[int]) -> Image.Image:
    """Frame `at` of a grid sheet, or [row, index] of a sheet of figures."""
    if isinstance(at, list):
        try:
            return frames[at[0]][at[1]]
        except IndexError as error:
            raise ImportError_(f"no figure at row {at[0]}, index {at[1]}") from error
    return frames[at]


def import_asset(asset_id: str, out_dir: Path = OUT_DIR) -> dict:
    folder = SOURCE / asset_id
    spec = json.loads((folder / "import.json").read_text())
    size = tuple(spec["frame_size"])
    feet = tuple(spec["feet"])
    sheets = {}
    for name, sheet_spec in spec["sheets"].items():
        if sheet_spec.get("figures", False):
            rows_found = figure_rows(
                folder / sheet_spec["file"],
                sheet_spec["height"],
                sheet_spec["measure"],
                sheet_spec.get("row_scale"),
            )
            sheets[name] = [[placed(f, size, feet) for f in row] for row in rows_found]
        else:
            sheets[name] = scaled_frames(folder, sheet_spec, size, feet)
    rows: list[tuple[str, list[Image.Image], dict]] = []
    for name, anim in spec["animations"].items():
        if "from" in anim:
            base = pick(sheets[anim["from"]], anim["frame"])
            shifts = anim.get("shift", [0] * len(anim["tilt"]))
            frames = [tilted(base, t, s, feet) for t, s in zip(anim["tilt"], shifts)]
        else:
            frames = [pick(sheets[anim["sheet"]], i) for i in anim["frames"]]
        rows.append((name, frames, anim))

    width = max(len(frames) for _, frames, _ in rows) * size[0]
    sheet = Image.new("RGBA", (width, size[1] * len(rows)), (0, 0, 0, 0))
    hands_sheet = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    animations, hands = {}, {}
    poses = spec.get("weapon_pose", {})
    for row, (name, frames, anim) in enumerate(rows):
        sockets = []
        pose = poses.get(name, 45)
        angles = pose if isinstance(pose, list) else [pose] * len(frames)
        if len(angles) != len(frames):
            raise ImportError_(f"{asset_id}: weapon_pose.{name} has {len(angles)} angles for {len(frames)} frames")
        previous = (feet[0], feet[1] - size[1] // 2)
        for index, frame in enumerate(frames):
            at = (index * size[0], row * size[1])
            sheet.alpha_composite(frame, at)
            found = fist(frame) or previous
            previous = found
            for x, y in fist_pixels(frame, found):
                hands_sheet.putpixel((at[0] + x, at[1] + y), frame.getpixel((x, y)))
            sockets.append([found[0], found[1], angles[index]])
        hands[name] = sockets
        animations[name] = {
            "row": row,
            "frames": len(frames),
            "fps": anim.get("fps", 10),
            "loop": anim.get("loop", True),
            "source": anim.get("sheet", "derived from " + anim.get("from", "")),
        }

    out = out_dir / asset_id
    out.mkdir(parents=True, exist_ok=True)
    portrait = head_and_shoulders(rows[0][1][0], spec.get("portrait_size", 22))
    sheet.save(out / "sheet.png", optimize=True)
    hands_sheet.save(out / "hands.png", optimize=True)
    credit = spec["credits"]
    credits = [{
        "file": f"art/custom/{asset_id}",
        "authors": credit["authors"],
        "license": credit["license"],
        "offered": [credit["license"]],
        "urls": [],
        "notes": credit.get("notes", ""),
    }]
    (out / "credits.json").write_text(json.dumps(credits, indent=2) + "\n")
    return {
        "source": "custom",
        "role": spec["role"],
        "sheet": f"res://assets/characters/{asset_id}/sheet.png",
        "frame_size": list(size),
        "origin": list(feet),
        "facing": "right",
        "animations": animations,
        "hands": hands,
        "hand_sheet": f"res://assets/characters/{asset_id}/hands.png",
        "portrait": portrait,
        "licenses": [credit["license"]],
        "credits": f"res://assets/characters/{asset_id}/credits.json",
        "generator": {"recipe": f"art/custom/{asset_id}/import.json"},
        "status": "imported",
    }


def main() -> int:
    wanted = sys.argv[1:] or sorted(p.name for p in SOURCE.iterdir() if (p / "import.json").exists())
    manifest = json.loads(MANIFEST.read_text())
    failures = 0
    for asset_id in wanted:
        try:
            manifest["assets"][asset_id] = import_asset(asset_id)
            print(f"imported {asset_id}")
        except (ImportError_, OSError, KeyError) as error:
            failures += 1
            print(f"FAILED {asset_id}: {error}", file=sys.stderr)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
