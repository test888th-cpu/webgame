#!/usr/bin/env python3
"""The asset provenance inventory: one traceable record per asset.

  python3 tools/assets/provenance.py build
      writes data/asset_provenance.json (machine-readable),
      docs/asset_provenance.csv, docs/ASSET_PROVENANCE.md, docs/ASSET_CREDITS.md
      and docs/ASSET_REPLACEMENT_MAP.md from the records the repository already
      keeps (client/assets/manifest.json, each character's credits.json,
      art/*/ recipe files, client/data/placeholder_art.json) plus two files a
      person fills in: art/provenance/generation_records.json (how AI-generated
      art was made) and art/provenance/licence_checks.json (licences confirmed
      at their original source).
  python3 tools/assets/provenance.py check
      fails (exit 1) when the committed outputs are stale, an id is duplicated,
      a recorded file is missing, a shipped asset has no record, an external
      asset has no licence, or gameplay data names an image file.

Rules (docs/ASSET_PROVENANCE.md): nothing is invented. A field the records do
not hold is written as UNKNOWN. "Commercial use" is "Allowed" only when the
licence permits it AND the licence was confirmed at its source; otherwise it is
"Unverified" (or "Not Allowed"). One record per source contribution: an LPC
part used by many characters is one record listing where it is used.

Standard library only. MIT, like the rest of the pipeline.
"""

from __future__ import annotations

import csv
import io
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / "client"
MANIFEST = CLIENT / "assets" / "manifest.json"
PLACEHOLDER = CLIENT / "data" / "placeholder_art.json"
RECIPES = ROOT / "art" / "lpc" / "characters.json"
WEAPONS = ROOT / "art" / "weapons" / "weapons.json"
SOUNDS = ROOT / "art" / "sounds" / "sounds.json"
GENERATION = ROOT / "art" / "provenance" / "generation_records.json"
CHECKS = ROOT / "art" / "provenance" / "licence_checks.json"
REVIEW = ROOT / "art" / "provenance" / "lpc_source_review.json"
PIXELFX = ROOT / "art" / "pixelfx" / "effects.json"

OUT_JSON = ROOT / "data" / "asset_provenance.json"
OUT_CSV = ROOT / "docs" / "asset_provenance.csv"
OUT_MD = ROOT / "docs" / "ASSET_PROVENANCE.md"
OUT_CREDITS = ROOT / "docs" / "ASSET_CREDITS.md"
OUT_REPLACE = ROOT / "docs" / "ASSET_REPLACEMENT_MAP.md"
OUT_LPC = ROOT / "docs" / "LPC_LICENCE_VERIFICATION.md"
OUT_GAPS = ROOT / "docs" / "ASSET_PROVENANCE_GAPS.md"

LPC_REPO = "https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator"
UNKNOWN = "UNKNOWN"
TYPES = ("LPC", "Free External", "AI Generated", "Original", UNKNOWN)
STATUSES = ("Temporary", "Approved", "Rejected", "Replace Later")
# Licence classes (owner's brief, 2026-11-17): VERIFIED = permitted for the intended
# commercial use; RESTRICTED = permitted only under conditions (share-alike, GPL);
# UNVERIFIED = insufficient evidence; NOT APPROVED = incompatible.
CLASSES = ("VERIFIED", "RESTRICTED", "UNVERIFIED", "NOT APPROVED")
COMMERCIAL = {"VERIFIED": "Allowed", "RESTRICTED": "Restricted", "UNVERIFIED": "Unverified",
              "NOT APPROVED": "Not Allowed"}

# What each licence family allows, from the licence texts (docs/credits/LICENSE_REGISTER.md).
# (commercial use, modification, attribution required, share-alike)
LICENCE_TERMS = {
    "CC0": (True, True, False, False),
    "OGA-BY": (True, True, True, False),
    "CC-BY": (True, True, True, False),
    "MIT": (True, True, True, False),
    "OFL-1.1": (True, True, True, False),
    "CC-BY-SA": (True, True, True, True),
    "GPL": (True, True, True, True),
}
OWNER = "test888th-cpu (project owner)"
GAMEPLAY_FILES = (
    "items.json", "item_catalog.json", "weapons.json", "enemies.json", "heroes.json",
    "jobs.json", "progression.json", "drop_tables.json", "shops.json", "skills.json",
    "moves.json", "areas.json", "arena.json", "world_boss.json", "appearances.json",
)
IMAGE_PATH = re.compile(r"\.(png|jpe?g|webp|gif|svg|tres)\b|res://assets", re.IGNORECASE)


def load(path: Path, default=None):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: str) -> str:
    """Repository-relative path from a res:// or repository path."""
    return "client/" + path.removeprefix("res://") if path.startswith("res://") else path


def family(licence: str) -> str:
    """The licence family, longest name first so CC-BY-SA is not read as CC-BY.
    NonCommercial or NoDerivatives variants are not in the table: they stay unknown."""
    norm = licence.upper().replace(" ", "-")
    if re.search(r"-(NC|ND)\b", norm):
        return ""
    for name in sorted(LICENCE_TERMS, key=len, reverse=True):
        if norm.startswith(name.upper()):
            return name
    return ""


def terms(licence: str, verified: bool) -> dict:
    fam = family(licence)
    if not licence or licence == UNKNOWN:
        return {"commercial_use": "Unverified", "modification": UNKNOWN,
                "attribution_required": UNKNOWN, "share_alike": UNKNOWN}
    if licence.startswith("Proprietary"):
        # The owner's own work: rights rest with the owner (not a licence grant).
        return {"commercial_use": "Allowed" if verified else "Unverified",
                "modification": "Allowed (owner)", "attribution_required": "No",
                "share_alike": "No"}
    if not fam:
        noncommercial = bool(re.search(r"-NC\b", licence.upper().replace(" ", "-")))
        return {"commercial_use": "Not Allowed" if noncommercial else "Unverified", "modification": UNKNOWN,
                "attribution_required": UNKNOWN, "share_alike": UNKNOWN}
    commercial, modify, attribute, share = LICENCE_TERMS[fam]
    return {
        "commercial_use": ("Allowed" if verified else "Unverified") if commercial
        else "Not Allowed",
        "modification": "Allowed" if modify else "Not Allowed",
        "attribution_required": "Yes" if attribute else "No",
        "share_alike": "Yes" if share else "No",
    }


def record(**fields) -> dict:
    base = {
        "asset_id": "", "display_name": "", "category": "", "files": [],
        "asset_type": UNKNOWN, "creator": UNKNOWN, "source_url": UNKNOWN,
        "source_repository": "", "license": UNKNOWN, "licence_verification": "UNVERIFIED",
        "attribution": "", "generation": None, "reference_files": [], "components": [],
        "used_in": [], "replacement_target": "", "status": "Temporary", "notes": "",
    }
    base.update(fields)
    checks = load(CHECKS, {}).get("checks", {})
    check = checks.get(base["asset_id"])
    if check:
        base["licence_verification"] = check.get("result", "UNVERIFIED")
        base["notes"] = (base["notes"] + " " if base["notes"] else "") + (
            f"Licence checked {check.get('date', UNKNOWN)} by {check.get('by', UNKNOWN)}.")
    review = load(REVIEW, {}).get("parts", {}).get(base["asset_id"])
    if review:
        base["licence_class"] = review["classification"]
        base["licence_verification"] = {
            "VERIFIED": "VERIFIED_AT_SOURCE", "RESTRICTED": "RESTRICTED_AT_SOURCE",
        }.get(review["classification"], review["classification"])
    verified = base["licence_verification"].startswith("VERIFIED")
    base.update(terms(base["license"], verified))
    if "licence_class" not in base:
        if base["licence_verification"].startswith("REJECTED"):
            base["licence_class"] = "NOT APPROVED"
        elif verified and base["commercial_use"] == "Allowed":
            base["licence_class"] = "VERIFIED"
        else:
            base["licence_class"] = "UNVERIFIED"
    if review:
        base["commercial_use"] = COMMERCIAL[base["licence_class"]]
        if base["licence_class"] == "RESTRICTED":
            base["share_alike"] = "Yes (a contribution is CC-BY-SA / GPL only)"
    base["release_ready"] = release_ready(base)
    if base["status"] in ("Temporary", "Replace Later") and not base["replacement_target"]:
        base["replacement_target"] = "original." + base["asset_id"]
    return base


def release_ready(rec: dict) -> bool:
    """Only verified rights, a known asset type and (for AI art) a complete record."""
    if rec["licence_class"] != "VERIFIED" or rec["asset_type"] == UNKNOWN:
        return False
    gen = rec.get("generation")
    return not (gen and any(v == UNKNOWN for v in gen.values()))


def worst(classes: list[str]) -> str:
    for cls in ("NOT APPROVED", "RESTRICTED", "UNVERIFIED"):
        if cls in classes:
            return cls
    return "VERIFIED"


def ai_generation(group: str) -> dict:
    """The generation record for an AI-generated group, UNKNOWN where not filled in."""
    known = load(GENERATION, {}).get("records", {}).get(group, {})
    fields = ("tool", "model", "date", "prompt", "references", "edited_after_generation")
    out = {f: known.get(f, UNKNOWN) for f in fields}
    out["record_source"] = (
        "art/provenance/generation_records.json" if known else
        "not recorded: the repository only states 'painted by the project owner with "
        "their own AI tools'"
    )
    return out


# ------------------------------------------------------------------ sources


def lpc_records(manifest: dict, recipes: dict, users: dict[str, list[str]]) -> list[dict]:
    """One record per LPC part (source contribution) and one per built sheet."""
    commit = recipes.get("lpc", {}).get("commit", "")
    parts: dict[str, dict] = {}
    sheets = []
    for asset_id, entry in sorted(manifest.get("assets", {}).items()):
        if entry.get("source") != "lpc":
            continue
        credits = load(ROOT / rel(entry.get("credits", "")), [])
        component_ids = []
        for credit in credits:
            part = credit.get("file", "")
            pid = "lpc." + part.replace("/", ".")
            component_ids.append(pid)
            rec = parts.get(pid)
            if rec is None:
                urls = credit.get("urls", [])
                licence = credit.get("license", "") or UNKNOWN
                authors = credit.get("authors", [])
                rec = parts[pid] = record(
                    asset_id=pid, display_name=part, category="Character part (LPC layer)",
                    asset_type="LPC", creator="; ".join(authors) or UNKNOWN,
                    source_url=urls[0] if urls else UNKNOWN,
                    source_repository=f"{LPC_REPO} @ {commit}", license=licence,
                    attribution=(
                        f"\"{part}\" by {', '.join(authors) or UNKNOWN}"
                        f" ({urls[0] if urls else UNKNOWN}), {licence}; modified "
                        "(composited and recoloured)"),
                    reference_files=[f"sheet_definitions (LPC generator) {part}"],
                    notes=("Licences offered: " + ", ".join(credit.get("offered", []))
                           + ". Other source pages: " + " ".join(urls[1:])).strip(),
                )
            rec["used_in"].append(f"character.{asset_id}")
        sheet = entry.get("sheet", "")
        sheets.append(record(
            asset_id=f"character.{asset_id}", display_name=asset_id,
            category=f"Character sprite sheet ({entry.get('role', UNKNOWN)})",
            files=[rel(sheet), rel(sheet).rsplit("/", 1)[0] + f"/{asset_id}.tres",
                   rel(entry.get("credits", ""))],
            asset_type="LPC", creator="composite: see components",
            source_url=LPC_REPO, source_repository=f"{LPC_REPO} @ {commit}",
            license="; ".join(entry.get("licenses", [])) or UNKNOWN,
            attribution="the credits of every component",
            reference_files=["art/lpc/characters.json"], components=component_ids,
            used_in=users.get(asset_id, []),
            notes="Built by tools/assets/lpc_build.py from the components at the pinned commit.",
        ))
    for rec in parts.values():
        rec["used_in"] = sorted(set(rec["used_in"]))
    for sheet in sheets:
        # A composite sheet is only as clear as its least clear part.
        cls = worst([parts[c]["licence_class"] for c in sheet["components"]])
        sheet["licence_class"] = cls
        sheet["licence_verification"] = "from components: " + cls
        sheet["commercial_use"] = COMMERCIAL[cls]
        if cls == "RESTRICTED":
            sheet["share_alike"] = "Yes (through a component)"
        sheet["release_ready"] = release_ready(sheet)
    return sorted(parts.values(), key=lambda r: r["asset_id"]) + sheets


def owner_ai_records(manifest: dict, users: dict[str, list[str]]) -> list[dict]:
    out = []
    for asset_id, entry in sorted(manifest.get("assets", {}).items()):
        if entry.get("source") != "custom":
            continue
        credits = load(ROOT / rel(entry.get("credits", "")), [{}])[0]
        sheet = entry.get("sheet", "")
        out.append(record(
            asset_id=f"character.{asset_id}", display_name=asset_id,
            category=f"Character sprite sheet ({entry.get('role', UNKNOWN)})",
            files=[rel(sheet), rel(entry.get("credits", ""))],
            asset_type="AI Generated", creator=OWNER, source_url="(supplied by the owner)",
            license="Proprietary (project owner)", generation=ai_generation(f"custom.{asset_id}"),
            reference_files=[f"art/custom/{asset_id}/"], used_in=users.get(asset_id, []),
            notes=credits.get("notes", "").strip(),
        ))
    kit = manifest.get("kit", {})
    for piece, entry in sorted(kit.get("pieces", {}).items()):
        out.append(record(
            asset_id=f"kit.{piece}", display_name=piece, category="Scenery piece (street kit)",
            files=[rel(entry["file"])], asset_type="AI Generated", creator=OWNER,
            source_url="(supplied by the owner)", license="Proprietary (project owner)",
            generation=ai_generation("kit"), reference_files=["art/kit/src/", "art/kit/kit.json"],
            used_in=["street scenery"], notes=kit.get("credits", {}).get("notes", ""),
        ))
    weapons = load(WEAPONS, {})
    for wid, entry in sorted(weapons.get("weapons", {}).items()):
        out.append(record(
            asset_id=f"weapon.{wid}", display_name=wid, category="Weapon sprite (held, icon)",
            files=["client/assets/ui/icons.png"], asset_type="AI Generated", creator=OWNER,
            source_url="(supplied by the owner)", license="Proprietary (project owner)",
            generation=ai_generation("weapons"),
            reference_files=[f"art/weapons/src/{entry.get('file', '')}"],
            used_in=[f"weapons.json sprite {wid}"],
            notes=weapons.get("credits", {}).get("notes", ""),
        ))
    return out


def appearance_users() -> dict[str, list[str]]:
    """Appearance asset id -> the items that show it (item_catalog -> appearances)."""
    data = CLIENT / "data"
    looks = load(data / "appearances.json", {}).get("appearances", {})
    by_asset: dict[str, list[str]] = {}
    for iid, item in load(data / "item_catalog.json", {}).get("items", {}).items():
        look = looks.get(item.get("appearance", "")) if isinstance(item, dict) else None
        if look:
            by_asset.setdefault(look["asset"], []).append(
                f"item {iid} (appearance {item['appearance']})")
    return by_asset


def placeholder_records(placeholder: dict) -> list[dict]:
    out = []
    users = appearance_users()
    for aid, entry in sorted(placeholder.get("appearance_assets", {}).items()):
        image = entry.get("image", "")
        if image:
            out.append(record(
                asset_id=f"appearance.{aid}", display_name=aid,
                category=f"Equipment appearance ({entry.get('slot', UNKNOWN)})",
                files=[rel(image)], asset_type=UNKNOWN, creator=UNKNOWN,
                source_url="UNKNOWN (supplied by the owner; origin not recorded)", license=UNKNOWN,
                reference_files=["art/placeholder/hats/"],
                used_in=users.get(aid, ["client/data/appearances.json"]), status="Temporary",
                notes="The owner's temporary hats (client/assets/placeholder/hats/credits.json):"
                " how they were made and their rights are not recorded; development only, not"
                " for release until recorded.",
            ))
        else:
            out.append(record(
                asset_id=f"appearance.{aid}", display_name=aid,
                category=f"Equipment appearance ({entry.get('slot', UNKNOWN)})",
                files=["client/scenes/ui/PlaceholderArt.gd"], asset_type="Original",
                creator="project contributors (drawn at runtime by code)", source_url="this repository",
                license="MIT", licence_verification="VERIFIED_PROJECT",
                used_in=["client/data/appearances.json"], status="Temporary",
            ))
    for icon, entry in sorted(placeholder.get("icons", {}).items()):
        out.append(record(
            asset_id=f"icon.{icon}", display_name=icon, category="Placeholder icon",
            files=["client/scenes/ui/PlaceholderArt.gd"], asset_type="Original",
            creator="project contributors (drawn at runtime by code)", source_url="this repository",
            license="MIT", licence_verification="VERIFIED_PROJECT",
            used_in=["client/data/placeholder_art.json"], status="Temporary",
        ))
    return out


def generated_records(manifest: dict) -> list[dict]:
    """The project's own procedural art and sound (code in this repository, MIT)."""
    note = ("Drawn or synthesised by project code (written in AI-assisted coding sessions);"
            " no image model and no third-party source.")
    groups = [
        ("generated.ui_icons", "Item, gear, menu and map icons", "Icon",
         ["client/assets/ui/icons.png"], "tools/assets/gen_ui.py, gear_icons.py, menu_icons.py,"
         " map_icons.py"),
        ("generated.environment", "Fallback area scenery", "Scenery",
         ["client/assets/environment/"], "tools/assets/gen_environment.py"),
        ("generated.fx", "Hit sparks and skill effects", "Effect", ["client/assets/fx/fx.png"],
         "tools/assets/gen_fx.py"),
        ("generated.sfx", "Synthesised sound effects", "Sound", ["client/assets/audio/"],
         "tools/assets/gen_sfx.py"),
    ]
    out = []
    for aid, name, cat, files, tool in groups:
        out.append(record(
            asset_id=aid, display_name=name, category=cat, files=files, asset_type="Original",
            creator="project contributors", source_url="this repository", license="MIT",
            licence_verification="VERIFIED_PROJECT", reference_files=[tool], status="Approved",
            notes=note + " Status 'Approved' only means no third-party rights; the owner may"
            " still replace them.",
        ))
    for asset_id, entry in sorted(manifest.get("assets", {}).items()):
        if entry.get("source") == "original":
            out.append(record(
                asset_id=f"character.{asset_id}", display_name=asset_id,
                category=f"Character sprite sheet ({entry.get('role', UNKNOWN)})",
                files=[rel(entry.get("sheet", ""))], asset_type="Original",
                creator="project contributors", source_url="this repository", license="MIT",
                licence_verification="VERIFIED_PROJECT", reference_files=["tools/assets/gen_dummy.py"],
                status="Approved", notes=note,
            ))
    return out


def external_records(manifest: dict) -> list[dict]:
    out = []
    sounds = load(SOUNDS, {}).get("sounds", {})
    for sid, sound in sorted(manifest.get("audio", {}).get("recorded", {}).items()):
        src = sounds.get(sid, {})
        replace = bool(src.get("replace_before_paid"))
        out.append(record(
            asset_id=f"sound.{sid}", display_name=sound.get("title", sid), category="Sound effect",
            files=[f"client/assets/audio/{sid}.wav"], asset_type="Free External",
            creator="; ".join(sound.get("authors", [])) or UNKNOWN,
            source_url=sound.get("url", "") or UNKNOWN, license=sound.get("license", "") or UNKNOWN,
            attribution=sound.get("attribution", ""), reference_files=[f"art/sounds/{src.get('file', '')}"],
            used_in=["sound effects"], status="Replace Later" if replace else "Temporary",
            notes=(sound.get("notes", "") + (
                " RISK: the file's own tags name a commercial sound library; the uploader may"
                " not have held the rights. Replace before any paid feature." if replace else ""
            )).strip(),
        ))
    for fid, font in sorted(manifest.get("fonts", {}).items()):
        out.append(record(
            asset_id=f"font.{fid}", display_name=Path(font.get("file", "")).name, category="Font",
            files=[rel(font.get("file", "")), rel(font.get("license_file", ""))],
            asset_type="Free External", creator=font.get("authors", UNKNOWN),
            source_url=font.get("source", UNKNOWN), license=font.get("license", UNKNOWN),
            attribution=f"Noto Sans Thai {font.get('version', '')}, The Noto Project Authors, SIL OFL 1.1",
            used_in=["all text"], status="Approved",
            notes="SHA-256 pinned in the manifest; the licence file ships beside the font.",
        ))
    pixelfx = manifest.get("fx_pixelfx", {})
    recipe = load(PIXELFX, {}).get("effects", {})
    commit = pixelfx.get("commit", UNKNOWN)
    for eid, entry in sorted(pixelfx.get("effects", {}).items()):
        spec = recipe.get(eid, {})
        use = spec.get("use", "IN USE: played by scenes/game/GameFeedback.gd and HazardView.gd")
        derived = any("Duprez" in a for a in entry.get("authors", []))
        changes = ["rendered with pixelfx's tools/render.mjs --sheet --no-actor at the pinned"
                   " commit", "cropped to the pixels used", "faded trailing frames dropped"]
        if spec.get("stride", 1) > 1:
            changes.append(f"1 frame in {spec['stride']} kept")
        if "start" in spec or "end" in spec:
            changes.append(f"cut to {spec.get('start', 0)}-{spec.get('end', 'end')} s")
        if spec.get("palette"):
            changes.append("recoloured with pixelfx's own palette option: " + ", ".join(spec["palette"]))
        seconds = round(entry["frames"] / float(entry["fps"]), 2)
        out.append(record(
            asset_id=f"fx.pixelfx.{eid}", display_name=eid, category="Visual effect",
            files=[rel(entry["sheet"]), "client/assets/fx/pixelfx/LICENSE.txt",
                   "client/assets/fx/pixelfx/NOTICE.md"],
            asset_type="Free External",
            creator="; ".join(entry.get("authors", [])) or UNKNOWN,
            source_url=f"{pixelfx.get('repository', UNKNOWN)}/blob/{commit}/src/fx/{entry.get('source', '')}.js",
            source_repository=f"{pixelfx.get('repository', '')} @ {commit}",
            license=pixelfx.get("license", UNKNOWN), licence_verification="VERIFIED_MIT",
            attribution=pixelfx.get("attribution", ""),
            reference_files=[f"pixelfx src/fx/{entry.get('source', '')}.js"],
            used_in=[use], status="Temporary",
            notes=(
                "Licence and notices read in LICENSE and NOTICE.md at the pinned commit (both ship"
                " beside the sheets). Copyright: " + "; ".join(pixelfx.get("copyright", []))
                + (". Third-party derivation: adapts Sprite Fusion's pixel art VFX by Hugo Duprez"
                   " (MIT), as the effect's own file header says" if derived else
                   ". Third-party derivation: none stated in the effect's file")
                + f". Modifications: {'; '.join(changes)}. Export: {entry['size'][0]}x"
                f"{entry['size'][1]} px frames, {entry['frames']} frames at {entry['fps']} fps"
                f" ({'loops' if entry.get('loop') else f'{seconds} s'}), origin {entry['origin']}."
            ),
        ))
    return out


def users_of_assets() -> dict[str, list[str]]:
    used: dict[str, list[str]] = {}
    data = CLIENT / "data"
    for name, key, label in (("enemies.json", "enemies", "enemy"), ("heroes.json", "heroes", "hero")):
        for oid, obj in (load(data / name, {}).get(key, {}) or {}).items():
            if isinstance(obj, dict) and obj.get("sprite"):
                used.setdefault(obj["sprite"], []).append(f"{label} {oid}")
    visuals = load(data / "class_visuals.json", {}).get("classes", {})
    for cls, bodies in visuals.items():
        for body, entry in bodies.items():
            used.setdefault(entry["sprite"], []).append(f"class {cls} ({body}): {entry['visual_id']}")
    return {k: sorted(v) for k, v in used.items()}


def inventory() -> dict:
    manifest = load(MANIFEST)
    recipes = load(RECIPES, {})
    users = users_of_assets()
    records = (
        lpc_records(manifest, recipes, users) + owner_ai_records(manifest, users)
        + placeholder_records(load(PLACEHOLDER, {})) + generated_records(manifest)
        + external_records(manifest)
    )
    return {
        "_comment": "Generated by tools/assets/provenance.py build; do not edit by hand. Edit"
        " the source records, art/provenance/generation_records.json or"
        " art/provenance/licence_checks.json and rebuild.",
        "version": 1,
        "records": records,
    }


# ------------------------------------------------------------------ writers


CSV_COLUMNS = [
    ("Asset ID", "asset_id"), ("Display Name", "display_name"), ("Category", "category"),
    ("File Path", "files"), ("Asset Type", "asset_type"), ("Creator", "creator"),
    ("Source URL", "source_url"), ("License", "license"),
    ("Licence Verification", "licence_verification"), ("Licence Class", "licence_class"),
    ("Release Ready", "release_ready"), ("Commercial Use", "commercial_use"),
    ("Attribution", "attribution"), ("Modification", "modification"),
    ("Share-Alike", "share_alike"), ("Generation Prompt", "generation"),
    ("Reference Files", "reference_files"), ("Used In", "used_in"),
    ("Replacement Target", "replacement_target"), ("Status", "status"), ("Notes", "notes"),
]


def cell(rec: dict, key: str) -> str:
    value = rec.get(key)
    if key == "generation":
        return value.get("prompt", UNKNOWN) if value else "n/a (not AI-generated)"
    if isinstance(value, list):
        return "; ".join(value)
    return str(value if value not in (None, "") else "")


def to_csv(records: list[dict]) -> str:
    out = io.StringIO()
    writer = csv.writer(out, lineterminator="\n")
    writer.writerow([c for c, _ in CSV_COLUMNS])
    for rec in records:
        writer.writerow([cell(rec, k) for _, k in CSV_COLUMNS])
    return out.getvalue()


def md_escape(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def to_markdown(records: list[dict]) -> str:
    by_type: dict[str, list[dict]] = {}
    for rec in records:
        by_type.setdefault(rec["asset_type"], []).append(rec)
    lines = [
        "# Asset provenance (master inventory)", "",
        "Generated by `tools/assets/provenance.py build`; do not edit by hand. The",
        "machine-readable copy is [data/asset_provenance.json](../data/asset_provenance.json)",
        "and a spreadsheet export is [asset_provenance.csv](asset_provenance.csv). How the",
        "inventory works, its rules and its open items: [ASSET_PIPELINE_POLICY.md](ASSET_PIPELINE_POLICY.md).",
        "",
        "- **UNKNOWN** means the repository does not record the fact. Nothing is guessed.",
        "- **Licence class** (owner's brief): **VERIFIED** = permitted for the intended",
        "  commercial use, confirmed at the original source; **RESTRICTED** = permitted only",
        "  under share-alike or GPL terms; **UNVERIFIED** = insufficient or conflicting",
        "  evidence; **NOT APPROVED** = incompatible. LPC evidence, part by part:",
        "  [LPC_LICENCE_VERIFICATION.md](LPC_LICENCE_VERIFICATION.md).",
        "- **Release-ready** = VERIFIED, a known asset type and, for AI-generated art, a",
        "  complete generation record. **Nothing that is not release-ready may ship in a",
        "  release package.** What the owner must supply: [ASSET_PROVENANCE_GAPS.md](ASSET_PROVENANCE_GAPS.md).",
        "- This is a record, not legal advice.",
        "- One record per source contribution: an LPC part shared by many characters is",
        "  listed once with everything that uses it.", "",
        "## Summary", "",
        "| Asset type | Records | VERIFIED | RESTRICTED | UNVERIFIED | NOT APPROVED | Release-ready | Temporary or Replace Later |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for kind in TYPES:
        recs = by_type.get(kind, [])
        if not recs:
            continue
        counts = " | ".join(str(sum(r["licence_class"] == c for r in recs)) for c in CLASSES)
        lines.append(
            f"| {kind} | {len(recs)} | {counts} | {sum(r['release_ready'] for r in recs)} |"
            f" {sum(r['status'] in ('Temporary', 'Replace Later') for r in recs)} |")
    total = " | ".join(str(sum(r["licence_class"] == c for r in records)) for c in CLASSES)
    lines.append(f"| **All** | **{len(records)}** | {total} |"
                 f" {sum(r['release_ready'] for r in records)} | |")
    for kind in TYPES:
        recs = by_type.get(kind, [])
        if not recs:
            continue
        lines += ["", f"## {kind}", ""]
        if kind == "AI Generated":
            lines += [
                "Generation records (tool, model, date, prompt, references, edits) are",
                "required for these. Where the table says UNKNOWN, the owner has not yet",
                "recorded them in `art/provenance/generation_records.json`.", "",
                "| Asset ID | Category | Files | Creator | Licence | Tool | Model | Date | Prompt"
                " | Edited | Status |",
                "|---|---|---|---|---|---|---|---|---|---|---|",
            ]
            for r in recs:
                g = r["generation"] or {}
                lines.append("| " + " | ".join(md_escape(x) for x in (
                    r["asset_id"], r["category"], "; ".join(r["files"]), r["creator"],
                    r["license"], str(g.get("tool")), str(g.get("model")), str(g.get("date")),
                    str(g.get("prompt"))[:80], str(g.get("edited_after_generation")), r["status"],
                )) + " |")
            continue
        lines += [
            "| Asset ID | Category | Files | Creator | Source | Licence | Class | Commercial"
            " | Release-ready | Used in | Status |",
            "|---|---|---|---|---|---|---|---|---|---|---|",
        ]
        for r in recs:
            used = r["used_in"]
            used_text = "; ".join(used[:4]) + (f" (+{len(used) - 4} more)" if len(used) > 4 else "")
            lines.append("| " + " | ".join(md_escape(x) for x in (
                r["asset_id"], r["category"], "; ".join(r["files"]) or "(source part, not"
                " shipped alone)", r["creator"], r["source_url"], r["license"],
                r["licence_class"], r["commercial_use"], "yes" if r["release_ready"] else "**no**",
                used_text,
                r["status"],
            )) + " |")
    return "\n".join(lines) + "\n"


def to_credits(records: list[dict]) -> str:
    lines = [
        "# Asset credits and licence notices", "",
        "Generated by `tools/assets/provenance.py build`; do not edit by hand. Every",
        "third-party work the game ships, with the credit its licence asks for. The",
        "in-game Credits screen is built from the same records. Licence texts and",
        "obligations: [credits/LICENSE_REGISTER.md](credits/LICENSE_REGISTER.md) and",
        "[credits/THIRD_PARTY_LICENSES.md](credits/THIRD_PARTY_LICENSES.md).", "",
        "LPC sprite sheets are composites of the parts below, recoloured and arranged for",
        f"this game (a modification), built from the Universal LPC Spritesheet Character",
        f"Generator's asset library ({LPC_REPO}).", "",
    ]
    # LPC parts (the source contributions, not the composite sheets) and other external works.
    third = [r for r in records if r["asset_id"].startswith("lpc.")
             or r["asset_type"] == "Free External"]
    for kind, title in (("LPC", "LPC character parts"), ("Free External", "Other third-party works")):
        lines += [f"## {title}", ""]
        for r in third:
            if r["asset_type"] != kind:
                continue
            credit = r["attribution"] or f"{r['display_name']} by {r['creator']}, {r['license']}"
            status = {
                "VERIFIED": "verified at source",
                "RESTRICTED": "**RESTRICTED**: a contribution is granted only as CC-BY-SA /"
                " GPL at its source; credit and share-alike terms apply",
                "UNVERIFIED": "**UNVERIFIED** at source",
            }.get(r["licence_class"], r["licence_class"])
            lines.append(f"- **{md_escape(r['display_name'])}**: {md_escape(credit)}."
                         f" Licence recorded: {r['license']} ({status}). Source: {r['source_url']}.")
        lines.append("")
    lines += [
        "## The project's own art", "",
        "- Art supplied by the project owner (street kit, weapon paintings, four painted",
        "  enemies): rights held by the owner, made with the owner's AI tools (see",
        "  ASSET_PROVENANCE.md for the generation records).",
        "- Procedural art and sound drawn by project code: MIT, this repository.", "",
    ]
    return "\n".join(lines)


def to_replacement_map(records: list[dict]) -> str:
    temp = [r for r in records if r["status"] in ("Temporary", "Replace Later")]
    shipped = [r for r in temp if r["files"]]
    lines = [
        "# Asset replacement map", "",
        "Generated by `tools/assets/provenance.py build`; do not edit by hand. Every",
        "temporary visual or sound the game ships, and the id its original replacement",
        "will take. The workflow and the id rules are in",
        "[ASSET_PIPELINE_POLICY.md](ASSET_PIPELINE_POLICY.md) §4 and §5.", "",
        "- **Gameplay never names an image file.** Content refers to a sprite or",
        "  appearance id (`enemies.json` `sprite`, `appearances.json` `asset`,",
        "  `weapons.json` `sprite`, `items.json` `icon`); only the manifest and",
        "  `placeholder_art.json` map ids to files. `provenance.py check` enforces this.",
        "- **A replacement keeps the id.** Register the new file under the same id;",
        "  item ids, stats, drop tables and saves do not change.",
        f"- {len(shipped)} shipped temporary assets ({len(temp) - len(shipped)} more are LPC",
        "  source parts, replaced when every sheet using them is).", "",
        "| Asset ID (kept) | Category | Type | Current file(s) | Replacement target | Status |",
        "|---|---|---|---|---|---|",
    ]
    for r in shipped:
        lines.append("| " + " | ".join(md_escape(x) for x in (
            r["asset_id"], r["category"], r["asset_type"], "; ".join(r["files"]),
            r["replacement_target"], r["status"])) + " |")
    return "\n".join(lines) + "\n"


def to_lpc_report(records: list[dict]) -> str:
    review = load(REVIEW, {})
    parts = review.get("parts", {})
    by_id = {r["asset_id"]: r for r in records}
    sheets = [r for r in records if r["asset_id"].startswith("character.") and r["asset_type"] == "LPC"]
    pages: dict[str, dict] = {}
    for part in parts.values():
        for page in part["pages"]:
            pages.setdefault(page["url"].replace("http://", "https://"), page)
    count = {c: sum(p["classification"] == c for p in parts.values()) for c in CLASSES}
    lines = [
        "# LPC licence verification (at the original sources)", "",
        "Generated by `tools/assets/provenance.py build` from",
        "`art/provenance/lpc_source_review.json`; do not edit by hand. Checked on",
        f"{next(iter(parts.values()), {}).get('checked', UNKNOWN)} against the pages each LPC part's credits cite,",
        "the credits files inside the downloads those pages offer, and the ElizaWy/LPC",
        "repository (read with git). Not legal advice.", "",
        "## Result", "",
        f"- **{len(parts)} LPC parts** in use: **{count['VERIFIED']} VERIFIED**,",
        f"  **{count['RESTRICTED']} RESTRICTED**, **{count['UNVERIFIED']} UNVERIFIED**,",
        f"  {count['NOT APPROVED']} NOT APPROVED.",
        f"- **{len(sheets)} LPC character sheets:** "
        + ", ".join(f"{sum(s['licence_class'] == c for s in sheets)} {c}" for c in CLASSES) + ".",
        "  A sheet is only as clear as its least clear part. Every sheet uses a body or",
        "  head that is RESTRICTED, so **no LPC character sheet is release-ready** under",
        "  the project's current no-share-alike policy.",
        "- **The LPC generator's licence records are not reliable on their own.** It",
        "  records the adult bodies and human heads as `OGA-BY 3.0`, and cites",
        "  `lpc-character-bases`, whose own page and download credits say",
        "  `CC-BY-SA 3.0 / GPL 3.0` for those files.", "",
        f"## Source pages ({len(pages)} distinct, "
        f"{sum(p['result'] in ('read', 'read via git') for p in pages.values())} read)", "",
        "| Page | Result | Licences listed on the page |", "|---|---|---|",
    ]
    for url, page in sorted(pages.items()):
        lines.append(f"| {url} | {page['result']} | {', '.join(page.get('licences', [])) or '-'} |")
    lines += ["", "## Parts", "",
              "| Part | Class | Recorded licence | Evidence | Note | Used by |", "|---|---|---|---|---|---|"]
    for pid, part in sorted(parts.items(), key=lambda kv: (CLASSES.index(kv[1]["classification"]), kv[0])):
        ev = "; ".join(f"{e['source']}: {e['quote']}" for e in part["item_evidence"]) or (
            "page licences: every readable cited page offers a permissive licence")
        used = by_id.get(pid, {}).get("used_in", [])
        lines.append("| " + " | ".join(md_escape(x) for x in (
            pid, f"**{part['classification']}**", part["recorded_licence"], ev, part["note"] or "-",
            f"{len(used)} sheet(s)")) + " |")
    lines += ["", "## What would clear the RESTRICTED and UNVERIFIED parts", "",
              "1. **Accept CC-BY-SA 3.0 for LPC sheets** (owner decision): the derived sheets",
              "   would then be CC-BY-SA 3.0 and must be offered under it, with credits; GPL is",
              "   not needed as CC-BY-SA is one of the offered options.",
              "2. **Or ask the contributors** (BenCreating, bluecarrot16, Manuel Riecke, Nila122,",
              "   JaidynReiman) to confirm OGA-BY for their parts, and record each answer.",
              "3. **Or replace** the parts: ElizaWy's LPC Revised bodies and heads are OGA-BY 3.0",
              "   throughout (github.com/ElizaWy/LPC) but use a different frame layout, so the",
              "   pipeline's animations would need re-mapping; or original art.", ""]
    return "\n".join(lines)


def to_gaps(records: list[dict]) -> str:
    ai = [r for r in records if r["asset_type"] == "AI Generated"]
    groups: dict[str, list[dict]] = {}
    for r in ai:
        key = r["generation"].get("record_source", "") and (
            "kit" if r["asset_id"].startswith("kit.") else
            "weapons" if r["asset_id"].startswith("weapon.") else "custom." + r["display_name"])
        groups.setdefault(key, []).append(r)
    unknown = [r for r in records if r["asset_type"] == UNKNOWN]
    lines = [
        "# Asset provenance: what the owner must supply", "",
        "Generated by `tools/assets/provenance.py build`; do not edit by hand. Nothing",
        "below was guessed. Until each item is supplied, the assets stay **not",
        "release-ready** (ASSET_PROVENANCE.md).", "",
        "## 1. AI-generated art: generation records", "",
        "Fill these in `art/provenance/generation_records.json` under the key shown, then",
        "run `python3 tools/assets/provenance.py build`. The assets stay classified **AI",
        "Generated**. Record the generation tool's terms for the output too, since the",
        "rights to AI output depend on them.", "",
        "| Key | Assets | Files | Missing fields |", "|---|---:|---|---|",
    ]
    for key, recs in sorted(groups.items()):
        missing = [f for f, v in recs[0]["generation"].items() if v == UNKNOWN]
        files = sorted({f for r in recs for f in r["files"]})
        shown = "; ".join(files[:3]) + (f" (+{len(files) - 3} more)" if len(files) > 3 else "")
        refs = "; ".join(sorted({f for r in recs for f in r["reference_files"]}))[:160]
        lines.append(f"| `{key}` | {len(recs)} | {shown} (sources: {refs}) | {', '.join(missing) or 'none'} |")
    lines += ["", "## 2. Placeholder hats: unknown source and licence (excluded from release)", "",
              "Source, licence and how they were made are UNKNOWN. They are **not** LPC and are",
              "not attributed to anyone else. They are excluded from any release-ready",
              "package (`release_ready: false`). Only the items below show them; no class,",
              "enemy or NPC sprite contains them (hats are drawn over a character only while",
              "one of these items is worn).", "",
              "**Fallback without them (prepared, not applied):** in",
              "`client/data/placeholder_art.json`, replace a hat's `image` entry with",
              "`\"style\"` and `\"grade\"` fields; `PlaceholderArt.appearance` then draws the",
              "existing code-made headgear (MIT) under the same appearance id. Item ids,",
              "stats, appearance ids and saves do not change. Removing the files needs the",
              "owner's approval.", "",
              "| Asset ID | File | Shown by |", "|---|---|---|"]
    for r in unknown:
        lines.append(f"| {r['asset_id']} | {'; '.join(r['files'])} | {'; '.join(r['used_in'])} |")
    lines.append("")
    return "\n".join(lines)


def outputs() -> dict[Path, str]:
    inv = inventory()
    records = inv["records"]
    return {
        OUT_JSON: json.dumps(inv, indent=2, ensure_ascii=False) + "\n",
        OUT_CSV: to_csv(records),
        OUT_MD: to_markdown(records),
        OUT_CREDITS: to_credits(records),
        OUT_REPLACE: to_replacement_map(records),
        OUT_LPC: to_lpc_report(records),
        OUT_GAPS: to_gaps(records),
    }


# ------------------------------------------------------------------ check


def problems(records: list[dict]) -> list[str]:
    out = []
    seen: set[str] = set()
    for r in records:
        aid = r["asset_id"]
        if aid in seen:
            out.append(f"duplicate asset id {aid}")
        seen.add(aid)
        if r["asset_type"] not in TYPES:
            out.append(f"{aid}: unknown asset type {r['asset_type']}")
        if r["status"] not in STATUSES:
            out.append(f"{aid}: unknown status {r['status']}")
        for f in r["files"]:
            if not (ROOT / f).exists():
                out.append(f"{aid}: file missing: {f}")
        if r["asset_type"] in ("LPC", "Free External") and r["license"] == UNKNOWN:
            out.append(f"{aid}: external asset without a licence")
        if r["asset_type"] == "AI Generated" and not r["generation"]:
            out.append(f"{aid}: AI-generated asset without a generation record")
        if r.get("share_alike") == "Yes":
            out.append(f"{aid}: share-alike licence {r['license']} needs the owner's approval")
    manifest = load(MANIFEST)
    for asset_id in manifest.get("assets", {}):
        if f"character.{asset_id}" not in seen:
            out.append(f"manifest asset {asset_id} has no provenance record")
    for name in GAMEPLAY_FILES:
        path = CLIENT / "data" / name
        if path.exists() and IMAGE_PATH.search(path.read_text(encoding="utf-8")):
            out.append(f"gameplay data {name} names an image file (use a sprite or appearance id)")
    return out


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] not in ("build", "check"):
        print(__doc__)
        return 2
    outs = outputs()
    if argv[1] == "build":
        for path, text in outs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        print(f"provenance: {len(json.loads(outs[OUT_JSON])['records'])} records")
        return 0
    found = problems(json.loads(outs[OUT_JSON])["records"])
    for path, text in outs.items():
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            found.append(f"{path.relative_to(ROOT)} is stale: run provenance.py build")
    for p in found:
        print("PROBLEM:", p)
    print(f"provenance check: {len(found)} problem(s)")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
