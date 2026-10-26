#!/usr/bin/env python3
"""Validates client/assets/manifest.json against the files it describes.

  python3 tools/assets/validate.py

For every asset: the sheet exists and is an RGBA PNG with real transparency;
its size matches the frame grid; every animation row is within the sheet and
none of its frames is empty; frame counts, fps and origin are sane; credits
exist, name authors and licences, and every licence is allowed by the policy
in art/lpc/characters.json; the generated SpriteFrames resource is up to date.
Pending manual imports (e.g. UnitForge exports not yet uploaded) are listed,
not failed. Exits non-zero on any problem, printing each one.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import gen_environment  # noqa: E402
import kit_import  # noqa: E402
import gen_dummy  # noqa: E402
import gen_fx  # noqa: E402
import gen_sfx  # noqa: E402
import gen_ui  # noqa: E402
import import_sounds  # noqa: E402
from make_spriteframes import render_tres  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / "client"
MANIFEST = CLIENT / "assets" / "manifest.json"
POLICY = ROOT / "art" / "lpc" / "characters.json"
SOURCES = {"lpc", "unitforge", "original", "custom"}
# Art the project owner made or commissioned for this game (art/custom/).
OWNER_LICENSE = "Proprietary (project owner)"
STATUSES = {"imported", "pending_manual_export"}
REQUIRED_ANIMATIONS = {"hero": {"idle", "walk", "light", "heavy", "hurt", "down"},
                       "enemy": {"idle", "walk", "light", "hurt", "down"},
                       "boss": {"idle", "walk", "light", "heavy", "hurt", "down"},
                       "npc": {"idle"}}


def res_path(res: str) -> Path:
    if not res.startswith("res://"):
        raise ValueError(f"not a res:// path: {res}")
    return CLIENT / res.removeprefix("res://")


def license_ok(name: str, allowed: list[str]) -> bool:
    for family in allowed:
        if name == family or name.startswith(family + " ") or name.startswith(family + "+"):
            if family == "CC-BY" and name.startswith("CC-BY-SA"):
                continue
            return True
    return False


def validate_asset(asset_id: str, asset: dict, allowed: list[str]) -> list[str]:
    problems: list[str] = []
    where = f"{asset_id}:"
    if asset.get("source") not in SOURCES:
        problems.append(f"{where} unknown source {asset.get('source')!r}")
    status = asset.get("status")
    if status not in STATUSES:
        problems.append(f"{where} unknown status {status!r}")
    if status == "pending_manual_export":
        return problems
    width, height = asset.get("frame_size", [0, 0])
    if width <= 0 or height <= 0:
        return problems + [f"{where} frame_size must be positive"]
    sheet_path = res_path(asset["sheet"])
    if not sheet_path.exists():
        return problems + [f"{where} missing sheet {sheet_path.relative_to(ROOT)}"]
    with Image.open(sheet_path) as opened:
        if opened.format != "PNG":
            problems.append(f"{where} sheet is {opened.format}, not PNG")
        sheet = opened.convert("RGBA")
        if opened.mode not in ("RGBA", "LA", "P"):
            problems.append(f"{where} sheet has no alpha channel (mode {opened.mode})")
    if sheet.width % width or sheet.height % height:
        problems.append(f"{where} sheet {sheet.size} is not a whole number of {width}x{height} frames")
    alpha = sheet.getchannel("A")
    if alpha.getextrema()[0] == 255:
        problems.append(f"{where} sheet has no transparent pixels")
    if asset.get("hand_sheet"):
        hand_path = res_path(asset["hand_sheet"])
        if not hand_path.exists():
            problems.append(f"{where} missing hand sheet {hand_path.relative_to(ROOT)}")
        else:
            with Image.open(hand_path) as hands:
                if hands.size != sheet.size:
                    problems.append(f"{where} hand sheet {hands.size} does not match the sheet {sheet.size}")
    animations = asset.get("animations", {})
    role = asset.get("role")
    missing = REQUIRED_ANIMATIONS.get(role, set()) - set(animations)
    if missing:
        problems.append(f"{where} role {role} is missing animations {sorted(missing)}")
    rows_used = set()
    for name, anim in animations.items():
        row, frames = anim.get("row", -1), anim.get("frames", 0)
        if row in rows_used:
            problems.append(f"{where} animation {name} reuses row {row}")
        rows_used.add(row)
        if not (0 <= row < sheet.height // height):
            problems.append(f"{where} animation {name} row {row} is outside the sheet")
            continue
        if not (1 <= frames <= sheet.width // width):
            problems.append(f"{where} animation {name} has {frames} frames; the sheet fits {sheet.width // width}")
            continue
        if not (0 < anim.get("fps", 0) <= 60):
            problems.append(f"{where} animation {name} fps must be in (0, 60]")
        for frame in range(frames):
            cell = alpha.crop((frame * width, row * height, (frame + 1) * width, (row + 1) * height))
            if cell.getbbox() is None:
                problems.append(f"{where} animation {name} frame {frame} is empty")
    ox, oy = asset.get("origin", [-1, -1])
    if not (0 <= ox <= width and 0 <= oy <= height):
        problems.append(f"{where} origin {asset.get('origin')} is outside the frame")
    credits_path = res_path(asset.get("credits", "res://missing"))
    if not credits_path.exists():
        problems.append(f"{where} missing credits file")
    else:
        credits = json.loads(credits_path.read_text())
        if not credits:
            problems.append(f"{where} credits are empty")
        for credit in credits:
            if not credit.get("authors") and not credit.get("license", "").startswith("CC0"):
                problems.append(f"{where} credit for {credit.get('file')} names no authors")
            # The project's own generated art carries the project's licence.
            own = (asset.get("source") == "original" and credit.get("license") == "MIT") or (
                asset.get("source") == "custom" and credit.get("license") == OWNER_LICENSE
            )
            if not own and not license_ok(credit.get("license", ""), allowed):
                problems.append(f"{where} {credit.get('file')} uses disallowed licence {credit.get('license')!r}")
    tres = sheet_path.with_name(f"{asset_id}.tres")
    if not tres.exists():
        problems.append(f"{where} missing {tres.relative_to(ROOT)}; run tools/assets/make_spriteframes.py")
    elif tres.read_text() != render_tres(asset_id, asset):
        problems.append(f"{where} {tres.name} is out of date; run tools/assets/make_spriteframes.py")
    return problems


def validate_environment(environment: dict) -> list[str]:
    """Every area has generated scenery; files exist, have the declared sizes,
    span the area's width, and match what the generator produces now."""
    problems: list[str] = []
    areas = json.loads(gen_environment.AREAS.read_text())["areas"]
    known = environment.get("areas", {})
    for area_id, area in sorted(areas.items()):
        entry = known.get(area_id)
        if entry is None:
            problems.append(f"environment: no scenery for area {area_id}; run tools/assets/gen_environment.py")
            continue
        theme = area.get("theme", "market")
        expected = {
            "sky": gen_environment.draw_sky(area_id, area["palette"]),
            "far": gen_environment.draw_far(area_id, area["palette"], theme),
            "buildings": gen_environment.draw_buildings(area_id, area, theme),
            "ground": gen_environment.draw_ground(area_id, area, theme),
        }
        for name, image in expected.items():
            layer = entry["layers"].get(name)
            path = res_path(layer["file"]) if layer else None
            if path is None or not path.exists():
                problems.append(f"environment: {area_id} is missing its {name} layer")
                continue
            with Image.open(path) as saved:
                if list(saved.size) != layer["size"]:
                    problems.append(f"environment: {area_id}/{name} is {saved.size}, manifest says {layer['size']}")
                elif saved.convert("RGBA").tobytes() != image.tobytes():
                    problems.append(f"environment: {area_id}/{name} is out of date; run tools/assets/gen_environment.py")
        if entry["layers"].get("buildings", {}).get("size", [0])[0] != int(area["width"]):
            problems.append(f"environment: {area_id} facades do not span the area width")
        if entry.get("props") != gen_environment.place_props(area_id, area, theme):
            problems.append(f"environment: {area_id} prop placements are out of date")
    for prop in {p["prop"] for e in known.values() for p in e.get("props", [])} | {"glow"}:
        if prop not in environment.get("props", {}).get("regions", {}):
            problems.append(f"environment: prop {prop} has no sprite region")
    return problems


def validate_kit(kit: dict) -> list[str]:
    """The street kit: every piece is cut from its current source and recipe
    (the digest), its file has the recorded size, every area is laid out, and
    the layouts are what the importer produces now."""
    problems: list[str] = []
    spec = json.loads(kit_import.SPEC.read_text())
    pieces = kit.get("pieces", {})
    if kit.get("credits", {}).get("license") != OWNER_LICENSE:
        problems.append(f"kit: licence must be {OWNER_LICENSE!r}")
    for piece_id, piece in sorted(spec["pieces"].items()):
        entry = pieces.get(piece_id)
        if entry is None or entry.get("digest") != kit_import.source_digest(piece):
            problems.append(f"kit: {piece_id} is missing or out of date; run tools/assets/kit_import.py")
            continue
        path = res_path(entry["file"])
        if not path.exists():
            problems.append(f"kit: {piece_id} has no texture")
            continue
        with Image.open(path) as saved:
            if list(saved.size) != entry["size"]:
                problems.append(f"kit: {piece_id} is {saved.size}, manifest says {entry['size']}")
    for piece_id in sorted(set(pieces) - set(spec["pieces"])):
        problems.append(f"kit: {piece_id} is no longer in art/kit/kit.json")
    if not problems and kit.get("areas") != kit_import.lay_out_all(spec, pieces):
        problems.append("kit: area layouts are out of date; run tools/assets/kit_import.py")
    return problems


def validate_ui(ui: dict) -> list[str]:
    """The icon sheet matches what gen_ui.py draws now, and every icon an item
    names exists."""
    problems: list[str] = []
    sheet, regions = gen_ui.render()
    icons = ui.get("icons", {})
    path = res_path(icons["sheet"]) if icons.get("sheet") else None
    if path is None or not path.exists():
        return ["ui: icon sheet missing; run tools/assets/gen_ui.py"]
    with Image.open(path) as saved:
        if saved.convert("RGBA").tobytes() != sheet.tobytes() or icons.get("regions") != regions:
            problems.append("ui: icons are out of date; run tools/assets/gen_ui.py")
    items = json.loads((ROOT / "client" / "data" / "items.json").read_text())["items"]
    for item_id, item in sorted(items.items()):
        if item.get("icon") not in regions:
            problems.append(f"ui: item {item_id} names unknown icon {item.get('icon')}")
    weapons = json.loads((ROOT / "client" / "data" / "weapons.json").read_text())["weapons"]
    for weapon_id, weapon in sorted(weapons.items()):
        if weapon.get("sprite") not in regions:
            problems.append(f"ui: weapon {weapon_id} names unknown sprite {weapon.get('sprite')}")
    return problems


def validate_fx(fx: dict) -> list[str]:
    """The effects sheet and its frame table match what gen_fx.py draws now."""
    sheet, entries = gen_fx.render()
    path = res_path(fx["sheet"]) if fx.get("sheet") else None
    if path is None or not path.exists():
        return ["fx: effects sheet missing; run tools/assets/gen_fx.py"]
    with Image.open(path) as saved:
        if saved.convert("RGBA").tobytes() != sheet.tobytes() or fx.get("effects") != entries:
            return ["fx: effects are out of date; run tools/assets/gen_fx.py"]
    return []


def validate_dummy(assets: dict) -> list[str]:
    """The generated training dummy matches gen_dummy.py."""
    sheet, animations = gen_dummy.render()
    entry = assets.get(gen_dummy.ASSET_ID)
    if entry != gen_dummy.manifest_entry(animations):
        return ["training_dummy: manifest entry is out of date; run tools/assets/gen_dummy.py"]
    with Image.open(res_path(entry["sheet"])) as saved:
        if saved.convert("RGBA").tobytes() != sheet.tobytes():
            return ["training_dummy: sheet is out of date; run tools/assets/gen_dummy.py"]
    return []


def wav_samples(data: bytes) -> list[int]:
    import array
    import io
    import wave

    with wave.open(io.BytesIO(data)) as w:
        return list(array.array("h", w.readframes(w.getnframes())))


def validate_audio(audio: dict) -> list[str]:
    """Every synthesised sound exists and matches gen_sfx.py within a few
    steps of 16-bit rounding (floating-point sine can differ in the last bit
    between machines)."""
    problems: list[str] = []
    sounds = audio.get("sounds", {})
    for sound_id in gen_sfx.SOUNDS:
        path = res_path(sounds[sound_id]) if sound_id in sounds else None
        if path is None or not path.exists():
            problems.append(f"audio: {sound_id} missing; run tools/assets/gen_sfx.py")
            continue
        saved, fresh = wav_samples(path.read_bytes()), wav_samples(gen_sfx.render(sound_id))
        if len(saved) != len(fresh) or any(abs(a - b) > 4 for a, b in zip(saved, fresh)):
            problems.append(f"audio: {sound_id} is out of date; run tools/assets/gen_sfx.py")
    recorded = audio.get("recorded", {})
    allowed = json.loads(POLICY.read_text())["license_policy"]["allowed"]
    for sound_id, spec in import_sounds.recorded().items():
        path = res_path(sounds[sound_id]) if sound_id in sounds else None
        if path is None or not path.exists() or sound_id not in recorded:
            problems.append(f"audio: recorded sound {sound_id} missing; run tools/assets/import_sounds.py")
            continue
        if path.read_bytes() != import_sounds.render(spec):
            problems.append(f"audio: {sound_id} is out of date; run tools/assets/import_sounds.py")
        if not spec.get("authors") or not spec.get("url"):
            problems.append(f"audio: {sound_id} needs authors and a source url")
        if not license_ok(str(spec.get("license", "")), allowed):
            problems.append(f"audio: {sound_id} uses disallowed licence {spec.get('license')!r}")
    for sound_id in set(sounds) - set(gen_sfx.SOUNDS) - set(import_sounds.recorded()):
        problems.append(f"audio: {sound_id} is listed but not generated or imported")
    return problems


def validate_fonts(fonts: dict) -> list[str]:
    """Bundled fonts are the pinned files (SHA-256), with their licence beside them."""
    import hashlib

    problems: list[str] = []
    for font_id, font in sorted(fonts.items()):
        path, licence = res_path(font["file"]), res_path(font["license_file"])
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != font.get("sha256"):
            problems.append(f"fonts: {font_id} is missing or not the pinned file")
        if not licence.exists():
            problems.append(f"fonts: {font_id} has no licence file")
        if font.get("license") not in ("OFL-1.1", "MIT", "CC0"):
            problems.append(f"fonts: {font_id} licence {font.get('license')!r} is not allowed")
    return problems


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    allowed = json.loads(POLICY.read_text())["license_policy"]["allowed"]
    problems: list[str] = []
    pending: list[str] = []
    for asset_id, asset in sorted(manifest.get("assets", {}).items()):
        problems += validate_asset(asset_id, asset, allowed)
        if asset.get("status") == "pending_manual_export":
            pending.append(asset_id)
    problems += validate_environment(manifest.get("environment", {}))
    problems += validate_kit(manifest.get("kit", {}))
    problems += validate_ui(manifest.get("ui", {}))
    problems += validate_fx(manifest.get("fx", {}))
    problems += validate_dummy(manifest.get("assets", {}))
    problems += validate_audio(manifest.get("audio", {}))
    problems += validate_fonts(manifest.get("fonts", {}))
    for problem in problems:
        print(f"INVALID {problem}")
    count = len(manifest.get("assets", {}))
    print(f"assets: {count} checked, {len(problems)} problem(s), {len(pending)} pending manual export")
    for asset_id in pending:
        print(f"PENDING {asset_id}: {manifest['assets'][asset_id].get('manual_steps', 'see docs/ASSETS.md')}")
    # Allowed for the free game, but flagged so a paid launch cannot miss them.
    for sound_id, spec in sorted(import_sounds.recorded().items()):
        if spec.get("replace_before_paid"):
            print(f"REPLACE BEFORE PAID FEATURES {sound_id}: {spec['attribution']}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
