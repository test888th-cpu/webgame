#!/usr/bin/env python3
"""The project's asset credit register and the monster licence validator.

  python3 tools/assets/credit_register.py build
      writes docs/credits/ASSET_CREDITS.csv and docs/credits/ASSET_CREDITS.md
      from the credit records the repository already keeps (each character's
      credits.json, client/assets/manifest.json's audio, font and kit entries,
      and the project's own generators).
  python3 tools/assets/credit_register.py check [--strict]
      validates every enemy in client/data/enemies.json against the monster
      art rules (docs/monster_art/LPC_GENERATOR_AUDIT.md) and writes
      docs/monster_art/LICENSE_AUDIT_REPORT.md. --strict exits 1 when any
      enemy is not compliant (for CI once the owner adopts the rules).

Nothing here invents a creator, licence or URL: a field the records lack is
reported as missing. A licence is "verified" only when a per-monster
asset_manifest.json says so for that component (a person checked the source);
matching the LPC generator's own records is not verification.

Standard library only. MIT, like the rest of the pipeline.
"""

from __future__ import annotations

import csv
import hashlib
import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / "client"
MANIFEST = CLIENT / "assets" / "manifest.json"
ENEMIES = CLIENT / "data" / "enemies.json"
RECIPES = ROOT / "art" / "lpc" / "characters.json"
CREDITS_DIR = ROOT / "docs" / "credits"
REPORT = ROOT / "docs" / "monster_art" / "LICENSE_AUDIT_REPORT.md"

# The licences selected for monster art (owner decision, 2026-11-03).
APPROVED = {"CC0", "OGA-BY 3.0", "OGA-BY 3.0+"}
STATUSES = {"VERIFIED_CC0", "VERIFIED_OGA_BY_3.0", "UNVERIFIED", "REJECTED"}
COLUMNS = [
    "Asset ID", "Asset Name", "Creator", "License", "License Version", "Original URL",
    "Source Repository", "Used In", "Asset File", "Attribution Text", "Verification Status",
]
# Problem kinds the validator tells apart (the brief's list, plus licences
# outside the selection and duplicates).
PROBLEMS = {
    "missing_sprite": "Missing sprite sheet",
    "missing_configuration": "Missing configuration (recipe or import file)",
    "missing_credits_file": "Missing credit file",
    "missing_credits_txt": "Missing original Credits TXT (website export)",
    "missing_credits_csv": "Missing original Credits CSV (website export)",
    "missing_manifest": "Missing asset_manifest.json",
    "invalid_manifest": "Invalid asset_manifest.json",
    "missing_creator": "Missing creator",
    "missing_license": "Missing licence",
    "missing_source_url": "Missing source URL",
    "unverified_license": "Licence not verified at its source",
    "outside_selection": "Licence outside CC0 / OGA-BY 3.0",
    "unverified_approved": "UNVERIFIED component marked production-approved",
    "not_in_global_credits": "Not listed in docs/credits/ASSET_CREDITS.csv",
    "duplicate_asset": "Same sheet as another enemy",
}


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def res(path: str) -> Path:
    return CLIENT / path.removeprefix("res://") if path.startswith("res://") else ROOT / path


def split_version(licence: str) -> tuple[str, str]:
    """("OGA-BY", "3.0") from "OGA-BY 3.0"; ("CC0", "") from "CC0"."""
    name, _, version = licence.partition(" ")
    return (name, version) if version and version[0].isdigit() else (licence, "")


def attribution(creators: list[str], title: str, licence: str, url: str) -> str:
    who = ", ".join(creators) if creators else "(creator not recorded)"
    where = f" ({url})" if url else ""
    return f'"{title}" by {who}{where}, {licence}'


# ------------------------------------------------------------- the register


def character_rows(manifest: dict, used_in: dict[str, list[str]]) -> list[dict]:
    rows = []
    for asset_id, entry in sorted(manifest.get("assets", {}).items()):
        credits_path = entry.get("credits", "")
        if not credits_path or not res(credits_path).exists():
            continue
        for credit in load(res(credits_path)):
            urls = credit.get("urls", [])
            licence = credit.get("license", "")
            name, version = split_version(licence)
            rows.append({
                "Asset ID": f"{asset_id}:{credit.get('file', '')}",
                "Asset Name": credit.get("file", ""),
                "Creator": "; ".join(credit.get("authors", [])),
                "License": name,
                "License Version": version,
                "Original URL": " ".join(urls),
                "Source Repository": (
                    "https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator"
                    if entry.get("source") == "lpc" else ""
                ),
                "Used In": "; ".join(used_in.get(asset_id, [asset_id])),
                "Asset File": entry.get("sheet", "").removeprefix("res://"),
                "Attribution Text": attribution(credit.get("authors", []), credit.get("file", ""), licence, urls[0] if urls else ""),
                "Verification Status": "UNVERIFIED" if licence else "",
            })
    return rows


def other_rows(manifest: dict) -> list[dict]:
    rows = []
    for sound_id, sound in sorted(manifest.get("audio", {}).get("recorded", {}).items()):
        name, version = split_version(sound.get("license", ""))
        rows.append({
            "Asset ID": f"audio:{sound_id}", "Asset Name": sound.get("title", sound_id),
            "Creator": "; ".join(sound.get("authors", [])), "License": name, "License Version": version,
            "Original URL": sound.get("url", ""), "Source Repository": "", "Used In": "sound effects",
            "Asset File": f"assets/audio/{sound_id}", "Attribution Text": sound.get("attribution", ""),
            "Verification Status": "UNVERIFIED",
        })
    for font_id, font in sorted(manifest.get("fonts", {}).items()):
        rows.append({
            "Asset ID": f"font:{font_id}", "Asset Name": Path(font.get("file", "")).name,
            "Creator": font.get("authors", ""), "License": font.get("license", ""), "License Version": "",
            "Original URL": font.get("source", ""), "Source Repository": "", "Used In": "all text",
            "Asset File": font.get("file", "").removeprefix("res://"),
            "Attribution Text": f"{Path(font.get('file', '')).name} by {font.get('authors', '')}, {font.get('license', '')}",
            "Verification Status": "UNVERIFIED",
        })
    kit = manifest.get("kit", {}).get("credits", {})
    if kit:
        rows.append({
            "Asset ID": "kit", "Asset Name": "Street kit (HD-2D scenery pieces)",
            "Creator": "; ".join(kit.get("authors", [])), "License": kit.get("license", ""), "License Version": "",
            "Original URL": "", "Source Repository": "", "Used In": "street scenery",
            "Asset File": "assets/kit/", "Attribution Text": "", "Verification Status": "UNVERIFIED",
        })
    for section in ("environment", "fx", "ui"):
        licence = manifest.get(section, {}).get("license", "")
        if licence:
            rows.append({
                "Asset ID": section, "Asset Name": f"{section} (generated)", "Creator": "project contributors",
                "License": licence.split(" (")[0], "License Version": "", "Original URL": "",
                "Source Repository": "this repository", "Used In": section, "Asset File": f"assets/{section}/",
                "Attribution Text": licence, "Verification Status": "UNVERIFIED",
            })
    synth = manifest.get("audio", {}).get("license", "")
    if synth:
        rows.append({
            "Asset ID": "audio:synthesised", "Asset Name": "synthesised sounds", "Creator": "project contributors",
            "License": synth.split(" (")[0], "License Version": "", "Original URL": "",
            "Source Repository": "this repository", "Used In": "sound effects", "Asset File": "assets/audio/",
            "Attribution Text": synth, "Verification Status": "UNVERIFIED",
        })
    return rows


def where_used(enemies: dict) -> dict[str, list[str]]:
    used: dict[str, list[str]] = {}
    for enemy_id, enemy in enemies.items():
        used.setdefault(enemy.get("sprite", enemy_id), []).append(f"enemy {enemy_id}")
    return used


def register_rows() -> list[dict]:
    manifest = load(MANIFEST)
    enemies = load(ENEMIES)["enemies"]
    return character_rows(manifest, where_used(enemies)) + other_rows(manifest)


def build() -> None:
    rows = register_rows()
    CREDITS_DIR.mkdir(parents=True, exist_ok=True)
    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    (CREDITS_DIR / "ASSET_CREDITS.csv").write_text(out.getvalue(), encoding="utf-8")
    lines = [
        "# Asset credits", "",
        "Generated by `tools/assets/credit_register.py build` from the credit records",
        "the repository keeps; do not edit by hand. Licences are as recorded; see",
        "[LICENSE_REGISTER.md](LICENSE_REGISTER.md) and",
        "[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md). \"UNVERIFIED\" means the",
        "licence matches the record it came from but was not confirmed at its original",
        "source.", "",
        "| Asset | Creator | Licence | Source | Used in |", "|---|---|---|---|---|",
    ]
    for row in rows:
        licence = " ".join(x for x in (row["License"], row["License Version"]) if x)
        source = row["Original URL"].split(" ")[0] if row["Original URL"] else "(none recorded)"
        lines.append(f"| {row['Asset ID']} | {row['Creator'] or '(none recorded)'} | {licence or '(none recorded)'} | {source} | {row['Used In']} |")
    (CREDITS_DIR / "ASSET_CREDITS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"credit register: {len(rows)} rows")


# ---------------------------------------------------------------- the check


def check_manifest(data, problems: list) -> list[dict]:
    """Components of a per-monster asset_manifest.json, or [] (problems noted)."""
    if not isinstance(data, dict) or not isinstance(data.get("components"), list):
        problems.append(("invalid_manifest", "no components list"))
        return []
    for key in ("monster_id", "source", "files", "verification"):
        if key not in data:
            problems.append(("invalid_manifest", f"missing {key}"))
    approved = data.get("verification", {}).get("review_status") == "APPROVED"
    for component in data["components"]:
        status = component.get("verification_status")
        if status not in STATUSES:
            problems.append(("invalid_manifest", f"{component.get('component_name', '?')}: status {status!r}"))
        if approved and status in ("UNVERIFIED", "REJECTED"):
            problems.append(("unverified_approved", component.get("component_name", "?")))
    return data["components"]


def check_enemy(enemy_id: str, enemy: dict, manifest: dict, recipes: dict, register: set[str], sheet_owner: dict) -> list:
    problems: list[tuple[str, str]] = []
    entry = manifest.get("assets", {}).get(enemy.get("sprite", ""), {})
    sheet = entry.get("sheet", "")
    if not sheet or not res(sheet).exists():
        problems.append(("missing_sprite", sheet or "(none)"))
    else:
        digest = hashlib.sha256(res(sheet).read_bytes()).hexdigest()
        other = sheet_owner.setdefault(digest, enemy_id)
        if other != enemy_id:
            problems.append(("duplicate_asset", f"same sheet as {other}"))
    source = entry.get("source", "")
    sprite = enemy.get("sprite", enemy_id)
    if source == "lpc" and sprite not in recipes:
        problems.append(("missing_configuration", "no recipe in art/lpc/characters.json"))
    if source == "custom" and not (ROOT / "art" / "custom" / sprite / "import.json").exists():
        problems.append(("missing_configuration", f"no art/custom/{sprite}/import.json"))
    folder = res(sheet).parent if sheet else None
    if source == "lpc" and folder is not None:
        if not (folder / "credits.txt").exists():
            problems.append(("missing_credits_txt", "website export not stored"))
        if not (folder / "credits.csv").exists():
            problems.append(("missing_credits_csv", "website export not stored"))
    components: list[dict] = []
    manifest_path = folder / "asset_manifest.json" if folder is not None else None
    if manifest_path is not None and manifest_path.exists():
        try:
            components = check_manifest(load(manifest_path), problems)
        except json.JSONDecodeError as error:
            problems.append(("invalid_manifest", str(error)))
    else:
        problems.append(("missing_manifest", "not created yet"))
    statuses = {c.get("component_name"): c.get("verification_status") for c in components}
    credits_path = entry.get("credits", "")
    if not credits_path or not res(credits_path).exists():
        problems.append(("missing_credits_file", credits_path or "(none)"))
        return problems
    for credit in load(res(credits_path)):
        file = credit.get("file", "?")
        if not credit.get("authors"):
            problems.append(("missing_creator", file))
        licence = credit.get("license", "")
        if not licence:
            problems.append(("missing_license", file))
        elif licence not in APPROVED:
            problems.append(("outside_selection", f"{file}: {licence}"))
        if not credit.get("urls"):
            problems.append(("missing_source_url", file))
        if not str(statuses.get(file, "UNVERIFIED")).startswith("VERIFIED"):
            problems.append(("unverified_license", file))
        if f"{sprite}:{file}" not in register:
            problems.append(("not_in_global_credits", file))
    return problems


def check(strict: bool) -> int:
    manifest = load(MANIFEST)
    enemies = load(ENEMIES)["enemies"]
    recipes = load(RECIPES)["characters"]
    register: set[str] = set()
    csv_path = CREDITS_DIR / "ASSET_CREDITS.csv"
    if csv_path.exists():
        with csv_path.open(encoding="utf-8", newline="") as handle:
            register = {row["Asset ID"] for row in csv.DictReader(handle)}
    sheet_owner: dict[str, str] = {}
    results = {k: check_enemy(k, v, manifest, recipes, register, sheet_owner) for k, v in enemies.items()}
    write_report(results)
    bad = [k for k, v in results.items() if v]
    print(f"monster licence check: {len(results) - len(bad)} compliant, {len(bad)} not compliant")
    return 1 if strict and bad else 0


def write_report(results: dict[str, list]) -> None:
    totals = {kind: 0 for kind in PROBLEMS}
    enemies_with = {kind: set() for kind in PROBLEMS}
    for enemy_id, problems in results.items():
        for kind, _ in problems:
            totals[kind] += 1
            enemies_with[kind].add(enemy_id)
    compliant = [k for k, v in results.items() if not v]
    lines = [
        "# Licence audit report (monster art)", "",
        "Written by `tools/assets/credit_register.py check`; do not edit by hand.",
        "Rules: [LPC_GENERATOR_AUDIT.md](LPC_GENERATOR_AUDIT.md). A compliant enemy",
        "has every file the brief asks for and every component verified at its",
        "source under CC0 or OGA-BY 3.0; having a credit file is not enough.", "",
        f"**Enemies checked:** {len(results)}. **Compliant:** {len(compliant)}.", "",
        "| Problem | Findings | Enemies |", "|---|---|---|",
    ]
    for kind, label in PROBLEMS.items():
        lines.append(f"| {label} | {totals[kind]} | {len(enemies_with[kind])} |")
    lines += ["", "## Per enemy", ""]
    for enemy_id, problems in results.items():
        if not problems:
            lines.append(f"- `{enemy_id}`: compliant")
            continue
        grouped: dict[str, list[str]] = {}
        for kind, detail in problems:
            grouped.setdefault(kind, []).append(detail)
        parts = []
        for kind, details in grouped.items():
            shown = ", ".join(details[:3]) + (f" (+{len(details) - 3} more)" if len(details) > 3 else "")
            parts.append(f"{PROBLEMS[kind]}: {shown}")
        lines.append(f"- `{enemy_id}`: " + "; ".join(parts))
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[1] == "build":
        build()
        return 0
    if len(argv) >= 2 and argv[1] == "check":
        return check("--strict" in argv)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
