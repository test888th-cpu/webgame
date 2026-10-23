#!/usr/bin/env python3
"""Generates a Godot 4 SpriteFrames resource (.tres) for every imported asset
in client/assets/manifest.json, next to its sheet:

  client/assets/characters/<id>/<id>.tres

Each animation becomes AtlasTexture frames cut from the sheet's row, with the
manifest's fps and loop flag. Output is deterministic, so CI can check that
committed resources match the manifest (tools/assets/validate.py).

  python3 tools/assets/make_spriteframes.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / "client"
MANIFEST = CLIENT / "assets" / "manifest.json"


def render_tres(asset_id: str, asset: dict) -> str:
    width, height = asset["frame_size"]
    animations = asset["animations"]
    subs = []
    anim_entries = []
    for name in sorted(animations):
        anim = animations[name]
        frames = []
        for frame in range(anim["frames"]):
            sub_id = f"{name}_{frame}"
            subs.append(
                f'[sub_resource type="AtlasTexture" id="{sub_id}"]\n'
                f'atlas = ExtResource("sheet")\n'
                f"region = Rect2({frame * width}, {anim['row'] * height}, {width}, {height})\n"
            )
            frames.append(f'{{\n"duration": 1.0,\n"texture": SubResource("{sub_id}")\n}}')
        anim_entries.append(
            "{\n"
            f'"frames": [{", ".join(frames)}],\n'
            f'"loop": {"true" if anim.get("loop", True) else "false"},\n'
            f'"name": &"{name}",\n'
            f'"speed": {float(anim["fps"])}\n'
            "}"
        )
    header = (
        f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{asset["sheet"]}" id="sheet"]\n\n'
    )
    return header + "\n".join(subs) + f"\n[resource]\nanimations = [{', '.join(anim_entries)}]\n"


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    written = 0
    for asset_id, asset in sorted(manifest["assets"].items()):
        if asset.get("status") != "imported":
            continue
        target = CLIENT / asset["sheet"].removeprefix("res://")
        target = target.with_name(f"{asset_id}.tres")
        target.write_text(render_tres(asset_id, asset))
        written += 1
    print(f"wrote {written} SpriteFrames resource(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
