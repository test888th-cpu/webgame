#!/usr/bin/env python3
"""Build character sprite sheets from the Universal LPC Spritesheet Character
Generator's open asset library, the same layers the website at lpc.4wall.ai /
liberatedpixelcup.github.io composes, without driving the website.

  python3 tools/assets/lpc_build.py [--only ID ...] [--cache DIR]

Reads art/lpc/characters.json (recipes) and writes, per character:
  client/assets/characters/<id>/sheet.png   one row per game animation
  client/assets/characters/<id>/credits.json
and updates client/assets/manifest.json. Run tools/assets/make_spriteframes.py
afterwards to (re)generate the Godot SpriteFrames resources.

Faithfulness to the generator (pinned commit in the recipe file):
  * file paths follow sources/state/path.ts:  spritesheets/<layer path>
    <animation folder>[/<variant file>].png
  * rows and frame cycles follow ANIMATION_CONFIGS in sources/state/constants.ts
  * layers are stacked by zPos; recolours map the material's base palette to
    the chosen palette, colour for colour, as the generator's recolouring does
  * credits come from each definition's "credits", matched to the files used
No frames are invented: every output frame is a composite of source frames.

Licensing: every credited file used must offer a licence from the recipe's
"allowed" list; the most permissive offered licence is recorded. A character
that needs anything else fails the build instead of shipping.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RECIPES = ROOT / "art" / "lpc" / "characters.json"
OUT_DIR = ROOT / "client" / "assets" / "characters"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"
FRAME = 64

# From the generator: animation id -> (file folder, first row in a combined
# sheet is irrelevant here; rows per file, frame cycle).
ANIMATIONS = {
    "spellcast": ("spellcast", 4, [0, 1, 2, 3, 4, 5, 6]),
    "thrust": ("thrust", 4, [0, 1, 2, 3, 4, 5, 6, 7]),
    "walk": ("walk", 4, [1, 2, 3, 4, 5, 6, 7, 8]),
    "slash": ("slash", 4, [0, 1, 2, 3, 4, 5]),
    "hurt": ("hurt", 1, [0, 1, 2, 3, 4, 5]),
    "idle": ("idle", 4, [0, 0, 1]),
    "jump": ("jump", 4, [0, 1, 2, 3, 4, 1]),
    "run": ("run", 4, [0, 1, 2, 3, 4, 5, 6, 7]),
    "combat": ("combat_idle", 4, [0, 0, 1]),
    "1h_slash": ("backslash", 4, [0, 1, 2, 3, 4, 5, 6]),
    "1h_halfslash": ("halfslash", 4, [0, 1, 2, 3, 4, 5]),
}
# Direction rows in 4-row sheets: up, left, down, right. Side view uses right;
# Godot flips it for left.
RIGHT_ROW = 3
LICENSE_ORDER = ["CC0", "OGA-BY", "CC-BY", "CC-BY-SA", "GPL"]


class BuildError(Exception):
    pass


def license_family(name: str) -> str:
    for family in LICENSE_ORDER:
        if name.startswith(family + " ") or name == family or name.startswith(family + "+"):
            # "CC-BY" must not swallow "CC-BY-SA".
            if family == "CC-BY" and name.startswith("CC-BY-SA"):
                continue
            return family
    if name.startswith("OGA-BY"):
        return "OGA-BY"
    return name


class Lpc:
    """A sparse, blobless checkout of the generator repository at a pinned commit."""

    def __init__(self, cache: Path, repo: str, commit: str) -> None:
        self.dir = cache
        if not (cache / ".git").exists():
            cache.parent.mkdir(parents=True, exist_ok=True)
            self._git(None, "clone", "--quiet", "--filter=blob:none", "--sparse", "--no-checkout", repo, str(cache))
        self._git(cache, "sparse-checkout", "set", "--no-cone", "/sheet_definitions/", "/palette_definitions/", "/CREDITS.csv")
        if self._git(cache, "cat-file", "-t", commit, check=False).strip() != "commit":
            self._git(cache, "fetch", "--quiet", "--depth", "1", "origin", commit)
        self._git(cache, "checkout", "--quiet", "--detach", commit)
        self._wanted: set[str] = set()

    @staticmethod
    def _git(cwd: Path | None, *args: str, check: bool = True) -> str:
        result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)
        if check and result.returncode != 0:
            raise BuildError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
        return result.stdout

    def definition(self, rel: str) -> dict:
        path = self.dir / "sheet_definitions" / rel
        if not path.exists():
            raise BuildError(f"unknown LPC definition {rel}")
        return json.loads(path.read_text())

    def palette(self, material: str, spec: str) -> list[str]:
        """spec is 'version.name' (e.g. 'ulpc.olive') or 'material.version.name'."""
        parts = spec.split(".")
        if len(parts) == 3:
            material, version, name = parts
        elif len(parts) == 2:
            version, name = parts
        else:
            version, name = "ulpc", spec
        path = self.dir / "palette_definitions" / material / f"{material}_{version}.json"
        if not path.exists():
            raise BuildError(f"unknown palette file {path.name}")
        colours = json.loads(path.read_text()).get(name)
        if not colours:
            raise BuildError(f"unknown palette {material}/{version}/{name}")
        return colours

    def material_base(self, material: str) -> str:
        meta = json.loads((self.dir / "palette_definitions" / material / f"meta_{material}.json").read_text())
        return f"{meta.get('default', 'ulpc')}.{meta['base']}"

    def fetch(self, rel_files: list[str]) -> None:
        new = sorted({"/" + f for f in rel_files} - self._wanted)
        if new:
            self._wanted.update(new)
            self._git(self.dir, "sparse-checkout", "add", "--no-cone", *new)

    def image(self, rel: str) -> Image.Image | None:
        path = self.dir / rel
        return Image.open(path).convert("RGBA") if path.exists() else None


def hex_rgb(colour: str) -> tuple[int, int, int]:
    colour = colour.lstrip("#")
    return tuple(int(colour[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def recolour(image: Image.Image, mapping: dict[tuple[int, int, int], tuple[int, int, int]]) -> tuple[Image.Image, int]:
    """Returns the recoloured image and how many pixels were changed."""
    if not mapping:
        return image, 0
    pixels = image.load()
    changed = 0
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a and (r, g, b) in mapping:
                pixels[x, y] = (*mapping[(r, g, b)], a)
                changed += 1
    return image, changed


def layer_recolour_map(lpc: Lpc, definition: dict, wanted: dict) -> dict:
    """Builds the colour map for one definition from the recipe's recolours.

    `wanted` maps a recolour channel ("color_1", "color_2", or "color" for a
    single-recolour item) to a palette spec.
    """
    recolors = definition.get("recolors")
    if not recolors or not wanted:
        return {}
    channels = {"color": recolors} if "material" in recolors else recolors
    mapping: dict = {}
    for channel, target in wanted.items():
        info = channels.get(channel)
        if info is None:
            raise BuildError(f"{definition.get('name')}: no recolour channel {channel}")
        material = info["material"]
        base_spec = info.get("base") or lpc.material_base(material)
        base = lpc.palette(material, base_spec)
        new = lpc.palette(material, target)
        for old_colour, new_colour in zip(base, new):
            mapping[hex_rgb(old_colour)] = hex_rgb(new_colour)
    return mapping


def sprite_path(layer_path: str, folder: str, variant: str | None) -> str:
    file_name = f"/{variant.replace(' ', '_')}" if variant else ""
    return f"spritesheets/{layer_path}{folder}{file_name}.png"


def credit_covers(key: str, path: str) -> bool:
    """True when a credit entry's "file" covers a used sprite path."""
    if path == key or path.startswith(key.rstrip("/") + "/"):
        return True
    # File-specific credits name the variant file, e.g. ".../male/gray_striped.png"
    # for ".../male/walk/gray_striped.png".
    if key.endswith(".png"):
        folder, _, name = key.rpartition("/")
        return path.startswith(folder + "/") and path.endswith("/" + name)
    return False


def pick_license(credit: dict, allowed: list[str]) -> str | None:
    offered = credit.get("licenses", [])
    for family in LICENSE_ORDER:
        if family in allowed:
            for name in offered:
                if license_family(name) == family:
                    return name
    return None


def feet_y(sheet: Image.Image, animations: dict) -> int:
    """The lowest opaque row of the idle (or walk) frames: where the feet touch
    the ground, so the game can anchor the sprite on the fighter's position."""
    name = "idle" if "idle" in animations else "walk"
    row = animations[name]["row"]
    strip = sheet.crop((0, row * FRAME, FRAME * animations[name]["frames"], (row + 1) * FRAME))
    box = strip.getbbox()
    return box[3] if box else FRAME


def build_character(lpc: Lpc, char_id: str, recipe: dict, game_anims: dict, allowed: list[str]) -> dict:
    body_type = recipe["body_type"]
    layers = []  # (zPos, order, definition, layer dict, item spec)
    for order, item in enumerate(recipe["layers"]):
        definition = lpc.definition(item["def"])
        for key, layer in definition.items():
            if key.startswith("layer_") and not layer.get("custom_animation"):
                if body_type not in layer:
                    raise BuildError(f"{char_id}: {item['def']} has no {key} for body type {body_type}")
                layers.append((layer["zPos"], order, definition, layer, item))
    layers.sort(key=lambda entry: (entry[0], entry[1]))

    files = []
    for _, _, definition, layer, item in layers:
        for anim in game_anims.values():
            folder = ANIMATIONS[anim["lpc"]][0]
            files.append(sprite_path(layer[body_type], folder, item.get("variant")))
    lpc.fetch(files)

    used_paths: list[tuple[dict, str]] = []
    rows = []
    for game_name, anim in game_anims.items():
        folder, row_count, cycle = ANIMATIONS[anim["lpc"]]
        frames = anim.get("frames", cycle)
        row_index = RIGHT_ROW if row_count == 4 else 0
        strip = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
        for _, _, definition, layer, item in layers:
            if anim["lpc"] not in definition.get("animations", []) and folder not in definition.get("animations", []):
                if item.get("optional_animations"):
                    continue
            rel = sprite_path(layer[body_type], folder, item.get("variant"))
            image = lpc.image(rel)
            if image is None:
                if item.get("required", True) and definition.get("type_name") in ("body", "head"):
                    raise BuildError(f"{char_id}: missing {rel}")
                continue  # e.g. hair has no hurt sheet: the generator also skips it
            used_paths.append((definition, rel.removeprefix("spritesheets/")))
            mapping = layer_recolour_map(lpc, definition, item.get("recolor", {}))
            image, changed = recolour(image, mapping)
            # A requested recolour that touches no pixel means the source does
            # not use the palette we assumed: fail rather than ship wrong colours.
            if mapping and changed == 0 and image.getbbox() is not None:
                raise BuildError(f"{char_id}: recolour {item['recolor']} matched no pixels in {rel}")
            if image.height < FRAME * (row_index + 1):
                raise BuildError(f"{char_id}: {rel} has {image.height // FRAME} rows, expected {row_count}")
            for i, frame in enumerate(frames):
                if (frame + 1) * FRAME > image.width:
                    raise BuildError(f"{char_id}: {rel} has no frame {frame}")
                cell = image.crop((frame * FRAME, row_index * FRAME, (frame + 1) * FRAME, (row_index + 1) * FRAME))
                strip.alpha_composite(cell, (i * FRAME, 0))
        rows.append((game_name, strip, len(frames), anim))

    credits = []
    seen = set()
    for definition, path in used_paths:
        matched = False
        for credit in definition.get("credits", []):
            key = credit["file"]
            if not credit_covers(key, path):
                continue
            matched = True
            if key in seen:
                continue
            seen.add(key)
            chosen = pick_license(credit, allowed)
            if chosen is None:
                raise BuildError(
                    f"{char_id}: {key} is only offered under {credit['licenses']}, "
                    f"none of which is allowed ({allowed})"
                )
            credits.append({
                "file": key,
                "authors": credit.get("authors", []),
                "license": chosen,
                "offered": credit.get("licenses", []),
                "urls": credit.get("urls", []),
                "notes": credit.get("notes", ""),
            })
        if not matched:
            raise BuildError(f"{char_id}: no credit entry covers {path}; refusing to ship it unattributed")

    width = max(strip.width for _, strip, _, _ in rows)
    sheet = Image.new("RGBA", (width, FRAME * len(rows)), (0, 0, 0, 0))
    animations = {}
    for index, (name, strip, count, anim) in enumerate(rows):
        sheet.alpha_composite(strip, (0, index * FRAME))
        animations[name] = {
            "row": index,
            "frames": count,
            "fps": anim.get("fps", 10),
            "loop": anim.get("loop", True),
            "source": anim["lpc"],
        }
    out = OUT_DIR / char_id
    out.mkdir(parents=True, exist_ok=True)
    sheet.save(out / "sheet.png", optimize=True)
    (out / "credits.json").write_text(json.dumps(credits, indent=2) + "\n")
    return {
        "source": "lpc",
        "role": recipe["role"],
        "sheet": f"res://assets/characters/{char_id}/sheet.png",
        "frame_size": [FRAME, FRAME],
        "origin": [FRAME // 2, feet_y(sheet, animations)],
        "facing": "right",
        "animations": animations,
        "licenses": sorted({c["license"] for c in credits}),
        "credits": f"res://assets/characters/{char_id}/credits.json",
        "generator": {"repo": "LPC", "recipe": f"art/lpc/characters.json#{char_id}"},
        "status": "imported",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--only", nargs="*", help="build only these character ids")
    parser.add_argument("--cache", default=str(ROOT / ".cache" / "lpc"), help="LPC checkout directory")
    args = parser.parse_args()

    recipes = json.loads(RECIPES.read_text())
    lpc = Lpc(Path(args.cache), recipes["lpc"]["repo"], recipes["lpc"]["commit"])
    allowed = recipes["license_policy"]["allowed"]
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"version": 1, "assets": {}}
    failures = 0
    for char_id, recipe in recipes["characters"].items():
        if args.only and char_id not in args.only:
            continue
        # A recipe may swap an animation's source (bodies differ in what LPC
        # drew for them) or drop it with null; it can never add made-up frames.
        overrides = recipe.get("animation_overrides", {})
        anims = {}
        for name, base in recipes["animations"].items():
            if name in overrides and overrides[name] is None:
                continue
            anims[name] = overrides.get(name) or base
        try:
            manifest["assets"][char_id] = build_character(lpc, char_id, recipe, anims, allowed)
            print(f"built {char_id}: {', '.join(manifest['assets'][char_id]['licenses'])}")
        except BuildError as error:
            failures += 1
            print(f"FAILED {char_id}: {error}", file=sys.stderr)
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
