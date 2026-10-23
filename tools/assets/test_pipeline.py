#!/usr/bin/env python3
"""Unit tests for the asset pipeline's validation and resource generation.

  python3 -m unittest tools/assets/test_pipeline.py
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import lpc_build  # noqa: E402
import make_spriteframes  # noqa: E402
import unitforge_import  # noqa: E402
import validate  # noqa: E402

ALLOWED = ["CC0", "OGA-BY", "CC-BY"]


class ValidateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.client = Path(self.tmp.name)
        validate.CLIENT = self.client
        (self.client / "assets" / "characters" / "x").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def make(self, empty_frame: bool = False, license: str = "OGA-BY 3.0", rows: int = 2) -> dict:
        sheet = Image.new("RGBA", (128, 64 * rows), (0, 0, 0, 0))
        for row in range(rows):
            for frame in range(2):
                if empty_frame and row == 1 and frame == 1:
                    continue
                sheet.paste((200, 50, 50, 255), (frame * 64 + 20, row * 64 + 10, frame * 64 + 40, row * 64 + 60))
        sheet.save(self.client / "assets/characters/x/sheet.png")
        (self.client / "assets/characters/x/credits.json").write_text(
            json.dumps([{"file": "a", "authors": ["Someone"], "license": license}])
        )
        asset = {
            "source": "lpc",
            "role": "npc",
            "status": "imported",
            "sheet": "res://assets/characters/x/sheet.png",
            "credits": "res://assets/characters/x/credits.json",
            "frame_size": [64, 64],
            "origin": [32, 60],
            "animations": {"idle": {"row": 0, "frames": 2, "fps": 4}, "walk": {"row": 1, "frames": 2, "fps": 8}},
        }
        (self.client / "assets/characters/x/x.tres").write_text(make_spriteframes.render_tres("x", asset))
        return asset

    def test_valid_asset_passes(self) -> None:
        self.assertEqual(validate.validate_asset("x", self.make(), ALLOWED), [])

    def test_empty_frame_is_reported(self) -> None:
        problems = validate.validate_asset("x", self.make(empty_frame=True), ALLOWED)
        self.assertTrue(any("walk frame 1 is empty" in p for p in problems), problems)

    def test_disallowed_license_is_reported(self) -> None:
        problems = validate.validate_asset("x", self.make(license="CC-BY-SA 3.0"), ALLOWED)
        self.assertTrue(any("disallowed licence" in p for p in problems), problems)

    def test_row_outside_sheet_and_missing_role_animations(self) -> None:
        asset = self.make()
        asset["animations"]["walk"]["row"] = 5
        asset["role"] = "enemy"
        problems = validate.validate_asset("x", asset, ALLOWED)
        self.assertTrue(any("outside the sheet" in p for p in problems), problems)
        self.assertTrue(any("missing animations" in p for p in problems), problems)

    def test_stale_spriteframes_are_reported(self) -> None:
        asset = self.make()
        asset["animations"]["idle"]["fps"] = 9
        problems = validate.validate_asset("x", asset, ALLOWED)
        self.assertTrue(any("out of date" in p for p in problems), problems)

    def test_pending_manual_export_is_not_a_failure(self) -> None:
        asset = {"source": "unitforge", "role": "enemy", "status": "pending_manual_export"}
        self.assertEqual(validate.validate_asset("u", asset, ALLOWED), [])


class UiIconsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.ui = json.loads(validate.MANIFEST.read_text())["ui"]

    def test_committed_icons_are_current(self) -> None:
        self.assertEqual(validate.validate_ui(self.ui), [])

    def test_changed_regions_are_reported(self) -> None:
        stale = json.loads(json.dumps(self.ui))
        stale["icons"]["regions"]["coin"] = [0, 0, 8, 8]
        self.assertIn("ui: icons are out of date; run tools/assets/gen_ui.py", validate.validate_ui(stale))


class GeneratedArtTest(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = json.loads(validate.MANIFEST.read_text())

    def test_effects_dummy_and_sounds_are_current(self) -> None:
        self.assertEqual(validate.validate_fx(self.manifest["fx"]), [])
        self.assertEqual(validate.validate_dummy(self.manifest["assets"]), [])
        self.assertEqual(validate.validate_audio(self.manifest["audio"]), [])

    def test_a_changed_sound_is_reported(self) -> None:
        audio = json.loads(json.dumps(self.manifest["audio"]))
        audio["sounds"]["coin"] = audio["sounds"]["ko"]
        self.assertIn("audio: coin is out of date; run tools/assets/gen_sfx.py", validate.validate_audio(audio))

    def test_sounds_are_audible_and_not_clipped(self) -> None:
        for sound_id in ("hit_light", "level_up", "skill_slam"):
            samples = validate.wav_samples(validate.gen_sfx.render(sound_id))
            self.assertGreater(max(map(abs, samples)), 8000, sound_id)
            self.assertLessEqual(max(map(abs, samples)), 32000, sound_id)


class LicenceTest(unittest.TestCase):
    def test_picks_most_permissive_allowed_option(self) -> None:
        credit = {"licenses": ["CC-BY-SA 3.0", "GPL 3.0", "OGA-BY 3.0"]}
        self.assertEqual(lpc_build.pick_license(credit, ALLOWED), "OGA-BY 3.0")

    def test_share_alike_only_is_refused_by_default(self) -> None:
        self.assertIsNone(lpc_build.pick_license({"licenses": ["CC-BY-SA 3.0", "GPL 3.0"]}, ALLOWED))

    def test_cc_by_sa_is_not_mistaken_for_cc_by(self) -> None:
        self.assertIsNone(lpc_build.pick_license({"licenses": ["CC-BY-SA 4.0"]}, ["CC-BY"]))
        self.assertEqual(lpc_build.pick_license({"licenses": ["CC-BY 4.0"]}, ["CC-BY"]), "CC-BY 4.0")

    def test_credit_matching(self) -> None:
        self.assertTrue(lpc_build.credit_covers("legs/pants/male", "legs/pants/male/walk.png"))
        self.assertFalse(lpc_build.credit_covers("hair/pony", "hair/ponytail2/adult/fg/walk.png"))
        self.assertTrue(lpc_build.credit_covers("torso/vest/male/gray.png", "torso/vest/male/walk/gray.png"))


class RecolourTest(unittest.TestCase):
    def test_maps_exact_colours_only(self) -> None:
        image = Image.new("RGBA", (2, 1))
        image.putpixel((0, 0), (10, 20, 30, 255))
        image.putpixel((1, 0), (99, 99, 99, 255))
        result, changed = lpc_build.recolour(image, {(10, 20, 30): (1, 2, 3)})
        self.assertEqual(changed, 1)
        self.assertEqual(result.getpixel((0, 0)), (1, 2, 3, 255))
        self.assertEqual(result.getpixel((1, 0)), (99, 99, 99, 255))


class UnitForgeImportTest(unittest.TestCase):
    """Uses a synthetic Godot 4 SpriteFrames export (the documented format)."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        unitforge_import.SOURCE = base / "src"
        unitforge_import.OUT_DIR = base / "out"
        self.folder = base / "src" / "demo"
        self.folder.mkdir(parents=True)
        image = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
        for i in range(3):
            image.paste((40 + 60 * i, 90, 200, 255), (i * 32 + 8, 8, i * 32 + 24, 30))
        image.paste((250, 250, 0, 255), (8, 40, 24, 60))
        image.save(self.folder / "demo.png")
        asset = {"sheet": "res://demo.png", "frame_size": [32, 32], "animations": {
            "idle": {"row": 0, "frames": 3, "fps": 6}, "attack": {"row": 1, "frames": 1, "fps": 10, "loop": False}}}
        (self.folder / "demo.tres").write_text(make_spriteframes.render_tres("demo", asset))
        self.config = {"license": "CC0", "attribution": "test", "role": "npc",
                       "animation_map": {"idle": "idle", "light": "attack"}}
        (self.folder / "import.json").write_text(json.dumps(self.config))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_repacks_frames_without_resizing(self) -> None:
        entry = unitforge_import.import_asset("demo")
        self.assertEqual(entry["frame_size"], [32, 32])
        self.assertEqual(entry["animations"]["idle"]["frames"], 3)
        self.assertEqual(entry["animations"]["light"]["source"], "attack")
        sheet = Image.open(unitforge_import.OUT_DIR / "demo" / "sheet.png")
        self.assertEqual(sheet.size, (96, 64))

    def test_refuses_without_licence_info(self) -> None:
        (self.folder / "import.json").unlink()
        with self.assertRaises(unitforge_import.ImportError_):
            unitforge_import.import_asset("demo")

    def test_refuses_unknown_animation(self) -> None:
        self.config["animation_map"]["heavy"] = "smash"
        (self.folder / "import.json").write_text(json.dumps(self.config))
        with self.assertRaisesRegex(unitforge_import.ImportError_, "smash"):
            unitforge_import.import_asset("demo")


if __name__ == "__main__":
    unittest.main()
