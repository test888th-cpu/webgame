#!/usr/bin/env python3
"""Imports pixelfx effects (github.com/patch-gg/pixelfx, MIT) as sprite sheets.

art/pixelfx/effects.json names which pixelfx effect plays as which game
effect id, at the pinned pixelfx commit. Render those effects with pixelfx's
own tool at that commit (it needs only Node):

  git clone https://github.com/patch-gg/pixelfx && cd pixelfx
  git checkout <commit from art/pixelfx/effects.json>
  node tools/render.mjs impacts/hit-spark ... --sheet --no-actor --out <dir>

then:

  python3 tools/assets/import_pixelfx.py <dir> <path to the pixelfx checkout>

For each effect it keeps every `stride`-th frame, drops the trailing frames
that have faded to almost nothing, crops to the pixels any kept frame uses,
and writes client/assets/fx/pixelfx/<id>.png (a grid, `columns` wide), the
manifest's "fx_pixelfx" section (frames, fps, origin, size, licence,
copyright, attribution) and the licence text next to the sheets, which the
MIT licence asks to travel with the art. ContentDB merges these effects over
the generated ones (tools/assets/gen_fx.py) with the same id.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "art" / "pixelfx" / "effects.json"
OUT = ROOT / "client" / "assets" / "fx" / "pixelfx"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"
## A trailing frame is dropped once it holds less than this share of the
## brightest frame's opacity.
FADED = 0.02
## The widest a sheet gets (WebGL takes 4096 everywhere).
MAX_WIDTH = 2048


def load_rendered(rendered: Path, source: str) -> tuple[list[Image.Image], dict]:
    name = source.split("/")[-1]
    folder = rendered / source
    meta = json.loads((folder / f"{name}.json").read_text())
    sheet = Image.open(folder / f"{name}.png").convert("RGBA")
    frames = meta["frames"] if isinstance(meta["frames"], list) else list(meta["frames"].values())
    images = []
    for frame in frames:
        rect = frame["frame"]
        images.append(sheet.crop((rect["x"], rect["y"], rect["x"] + rect["w"], rect["y"] + rect["h"])))
    return images, meta["meta"]["pixelfx"]


def opacity(image: Image.Image) -> int:
    histogram = image.getchannel("A").histogram()
    return sum(level * count for level, count in enumerate(histogram))


def authors(checkout: Path, source: str) -> list[str]:
    """Who made `source`: Patch, and Hugo Duprez where the effect's file says it
    adapts his Sprite Fusion effects (pixelfx's NOTICE)."""
    head = "\n".join((checkout / "src" / "fx" / f"{source}.js").read_text().splitlines()[:12])
    names = ["Patch"]
    if "Duprez" in head or "Sprite Fusion" in head:
        names.append("Hugo Duprez (adapted from Sprite Fusion's pixel art VFX)")
    return names


def build(effect_id: str, spec: dict, rendered: Path) -> tuple[Image.Image, dict]:
    images, meta = load_rendered(rendered, spec["source"])
    stride = int(spec.get("stride", 1))
    kept = images[::stride]
    peak = max(opacity(image) for image in kept)
    while len(kept) > 1 and opacity(kept[-1]) < peak * FADED:
        kept.pop()
    box = None
    for image in kept:
        bbox = image.getchannel("A").getbbox()
        if bbox:
            box = bbox if box is None else (
                min(box[0], bbox[0]), min(box[1], bbox[1]), max(box[2], bbox[2]), max(box[3], bbox[3])
            )
    w0, h0 = kept[0].size
    left, top, right, bottom = box if box else (0, 0, w0, h0)
    left, top = max(0, left - 1), max(0, top - 1)
    right, bottom = min(w0, right + 1), min(h0, bottom + 1)
    w, h = right - left, bottom - top
    columns = max(1, min(len(kept), MAX_WIDTH // w))
    rows = (len(kept) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * w, rows * h), (0, 0, 0, 0))
    for i, image in enumerate(kept):
        sheet.paste(image.crop((left, top, right, bottom)), ((i % columns) * w, (i // columns) * h))
    pivot = meta["pivot"]
    entry = {
        "sheet": f"res://assets/fx/pixelfx/{effect_id}.png",
        "source": spec["source"],
        "blend": "mix",
        "fps": round(int(meta["fps"]) / stride),
        "frames": len(kept),
        "columns": columns,
        "size": [w, h],
        "origin": [int(pivot[0]) - left, int(pivot[1]) - top],
    }
    return sheet, entry


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__)
        return 2
    rendered, checkout = Path(argv[1]), Path(argv[2])
    config = json.loads(CONFIG.read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    effects = {}
    for effect_id, spec in config["effects"].items():
        sheet, entry = build(effect_id, spec, rendered)
        entry["authors"] = authors(checkout, spec["source"])
        sheet.save(OUT / f"{effect_id}.png", optimize=True)
        effects[effect_id] = entry
        print(f"{effect_id}: {spec['source']} {entry['frames']} frames {entry['size']} -> {sheet.size}")
    license_text = (checkout / "LICENSE").read_text()
    notice = (checkout / "NOTICE.md").read_text()
    (OUT / "LICENSE.txt").write_text(license_text)
    (OUT / "NOTICE.md").write_text(notice)
    manifest = json.loads(MANIFEST.read_text())
    manifest["fx_pixelfx"] = {
        "license": config["license"],
        "copyright": config["copyright"],
        "attribution": config["attribution"],
        "repository": config["source"]["repository"],
        "commit": config["source"]["commit"],
        "license_file": "res://assets/fx/pixelfx/LICENSE.txt",
        # The notice itself too: the web export leaves .txt files out.
        "notice": license_text.strip(),
        "effects": effects,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
