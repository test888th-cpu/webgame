#!/usr/bin/env python3
"""Unit tests for the asset pipeline's validation and resource generation.

  python3 -m unittest tools/assets/test_pipeline.py
"""

from __future__ import annotations

import io
import json
import wave
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import custom_import  # noqa: E402
import import_sounds  # noqa: E402
import kit_import  # noqa: E402
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


class HandSocketTest(unittest.TestCase):
    def test_finds_each_hand_and_ignores_specks(self) -> None:
        cell = Image.new("RGBA", (64, 64))
        for x in range(20, 24):
            for y in range(40, 44):
                cell.putpixel((x, y), (200, 150, 120, 255))
                cell.putpixel((x + 20, y - 4), (200, 150, 120, 255))
        cell.putpixel((5, 5), (255, 255, 255, 255))
        centres = sorted(lpc_build.hand_clusters(cell))
        self.assertEqual(centres, [(21.5, 41.5), (41.5, 37.5)])

    def test_the_weapon_stays_in_the_near_hand(self) -> None:
        self.assertEqual(lpc_build.near_hand([(41, 40), (29, 44)], None), (29, 44))
        self.assertEqual(lpc_build.near_hand([(50, 44)], (29, 44)), (50, 44))
        self.assertEqual(lpc_build.near_hand([], (29, 44)), (29, 44))

    def test_the_weapon_stays_in_one_hand(self) -> None:
        # Standing, walking and the heavy swing keep the weapon in the same
        # hand: the socket never jumps across the body between frames.
        manifest = json.loads(lpc_build.MANIFEST.read_text())
        for char_id, asset in manifest["assets"].items():
            if asset.get("source") != "lpc":
                continue
            for name in ("idle", "walk", "heavy"):
                frames = asset["hands"].get(name, [])
                for a, b in zip(frames, frames[1:]):
                    self.assertLessEqual(abs(a[0] - b[0]), 12, f"{char_id} {name} {frames}")
            heavy = [f[0] for f in asset["hands"].get("heavy", [])]
            self.assertGreaterEqual(max(heavy) - min(heavy), 8, f"{char_id} swings the weapon in the heavy blow")

    def test_every_character_has_sockets_for_its_animations(self) -> None:
        manifest = json.loads(lpc_build.MANIFEST.read_text())
        for char_id, asset in manifest["assets"].items():
            if asset.get("source") != "lpc":
                continue
            for name in ("idle", "walk", "light", "heavy"):
                frames = asset["hands"].get(name, [])
                self.assertEqual(len(frames), asset["animations"][name]["frames"], f"{char_id} {name}")


class CustomImportTest(unittest.TestCase):
    def test_committed_custom_art_matches_a_fresh_import(self) -> None:
        manifest = json.loads(lpc_build.MANIFEST.read_text())
        for asset_id, asset in manifest["assets"].items():
            if asset.get("source") != "custom":
                continue
            with tempfile.TemporaryDirectory() as tmp:
                entry = custom_import.import_asset(asset_id, Path(tmp))
                self.assertEqual(entry, asset, asset_id)
                for name in ("sheet.png", "hands.png"):
                    with Image.open(Path(tmp) / asset_id / name) as fresh, \
                            Image.open(custom_import.OUT_DIR / asset_id / name) as saved:
                        self.assertEqual(fresh.tobytes(), saved.convert("RGBA").tobytes(), f"{asset_id}/{name}")

    def test_tilting_lays_a_figure_down_about_its_feet(self) -> None:
        frame = Image.new("RGBA", (64, 64))
        for y in range(30, 62):
            frame.putpixel((32, y), (255, 255, 255, 255))
        flat = custom_import.tilted(frame, 90, 0, (32, 62))
        box = flat.getbbox()
        self.assertLessEqual(box[3] - box[1], 2)
        self.assertLess(box[0], 32)


class KitImportTest(unittest.TestCase):
    GREEN = (30, 220, 30)

    def painting(self) -> Image.Image:
        """A dark-outlined grey box on the green backdrop, with a pale green
        cross painted on it, a window cut through it showing the backdrop, and
        a warm haze in one corner of the backdrop."""
        image = Image.new("RGB", (200, 120), self.GREEN)
        for x in range(30):
            for y in range(30 - x):
                image.putpixel((x, y), (250, 200, 120))
        image.paste((20, 20, 24), (50, 20, 150, 100))
        image.paste((120, 120, 128), (53, 23, 147, 97))
        image.paste((150, 225, 150), (70, 40, 80, 80))  # the cross
        image.paste((20, 20, 24), (110, 40, 136, 70))
        image.paste(self.GREEN, (113, 43, 133, 67))  # the window
        return image

    def test_keys_out_the_backdrop_but_not_green_inside_the_outline(self) -> None:
        cut = kit_import.cut_out(self.painting(), {"haze": True})
        self.assertEqual(cut.size, (98, 78), "trimmed to the box less its fringe")
        alpha = cut.getchannel("A")
        self.assertEqual(alpha.getpixel((24, 30)), 255, "the pale cross stays")
        self.assertEqual(alpha.getpixel((72, 33)), 0, "the window shows through")
        self.assertEqual(alpha.getpixel((10, 10)), 255, "the box is solid")

    def test_keep_green_keeps_enclosed_green(self) -> None:
        cut = kit_import.cut_out(self.painting(), {"keep_green": True})
        self.assertEqual(cut.getchannel("A").getpixel((72, 33)), 255)

    def test_a_corner_haze_never_survives(self) -> None:
        for piece in ({}, {"haze": True}):
            cut = kit_import.cut_out(self.painting(), piece)
            self.assertEqual(cut.size, (98, 78), f"{piece}: the haze is not part of the piece")

    def test_ground_tiles_repeat_without_a_seam(self) -> None:
        source = Image.linear_gradient("L").convert("RGB").rotate(90)
        tile = kit_import.tile(source, {"height": 20}, 2)
        self.assertEqual(tile.height, 40)
        left = [tile.getpixel((0, y)) for y in range(tile.height)]
        right = [tile.getpixel((tile.width - 1, y)) for y in range(tile.height)]
        self.assertEqual(left, right, "the last column meets the first")

    def test_layouts_are_repeatable_and_line_the_street(self) -> None:
        spec = json.loads(kit_import.SPEC.read_text())
        manifest = json.loads(kit_import.MANIFEST.read_text())
        pieces = manifest["kit"]["pieces"]
        area = {"width": 1800, "theme": "market"}
        first = kit_import.lay_out("x", area, spec["themes"]["market"], pieces, spec["scroll"])
        again = kit_import.lay_out("x", area, spec["themes"]["market"], pieces, spec["scroll"])
        self.assertEqual(first, again)
        front = [p for p in first if p["layer"] == "front"]
        reach = max(p["x"] + kit_import.game_width(pieces, p["piece"]) / 2 for p in front)
        self.assertGreaterEqual(reach, 1800)
        for a, b in zip(front, front[1:]):
            self.assertNotEqual(a["piece"], b["piece"], "no two neighbours alike")
        for p in first:
            if p["layer"] == "street":
                half = kit_import.game_width(pieces, p["piece"]) / 2
                self.assertTrue(80 <= p["x"] - half and p["x"] + half <= 1720, "clear of the exits")

    def test_kit_theme_picks_its_own_pieces_and_hangs_lamps_overhead(self) -> None:
        spec = json.loads(kit_import.SPEC.read_text())
        manifest = json.loads(kit_import.MANIFEST.read_text())
        pieces = manifest["kit"]["pieces"]
        areas = kit_import.lay_out_all(spec, pieces)
        self.assertEqual(areas["fight_club"]["theme"], "fight_club")
        self.assertEqual(areas["rusted_corner"]["theme"], "junkyard")
        placed = areas["fight_club"]["placed"]
        hung = [p for p in placed if p["piece"] in spec["themes"]["fight_club"]["hanging"]]
        self.assertTrue(hung, "work lamps are strung over the ring")
        for p in hung:
            height = pieces[p["piece"]]["size"][1] / pieces[p["piece"]]["hd"]
            self.assertEqual(p["y"] - height, spec["themes"]["fight_club"]["hanging_top"])
        self.assertIn("warehouse_wall", {p["piece"] for p in placed if p["layer"] == "front"})


class KeyedSheetTest(unittest.TestCase):
    def test_a_green_backdrop_is_cut_out_but_green_clothes_stay(self) -> None:
        sheet = Image.new("RGB", (40, 20), (0, 255, 0))
        for x in range(5, 15):
            for y in range(3, 19):
                # A dark green jacket inside the figure's dark outline.
                edge = x in (5, 14) or y in (3, 18)
                sheet.putpixel((x, y), (24, 20, 28) if edge else (40, 120, 50))
        sheet.putpixel((10, 2), (200, 160, 120))
        keyed = custom_import.keyed(sheet)
        alpha = keyed.getchannel("A")
        self.assertEqual(alpha.getpixel((0, 0)), 0, "backdrop gone")
        self.assertEqual(alpha.getpixel((30, 10)), 0, "backdrop between frames gone")
        self.assertEqual(alpha.getpixel((10, 10)), 255, "the figure stays")
        self.assertEqual(keyed.getpixel((10, 10))[:3], (40, 120, 50), "its green clothes stay green")
        self.assertEqual(keyed.size, sheet.size, "the grid is kept")


class FigureSheetTest(unittest.TestCase):
    def test_loose_figures_are_found_in_rows_by_their_feet(self) -> None:
        sheet = Image.new("RGB", (300, 200), (0, 255, 0))
        draw = ImageDraw.Draw(sheet)
        draw.line((0, 100, 299, 100), fill=(40, 40, 40))  # a painted grid line
        # Row 0: two figures standing on y=90, one taller; row 1: one lying on y=190.
        for box in ((20, 40, 40, 90), (120, 20, 140, 90), (60, 170, 120, 190)):
            draw.rectangle(box, fill=(200, 120, 60), outline=(24, 20, 28))
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sheet.png"
            sheet.save(path)
            rows = custom_import.figure_rows(path, 50, [0, 0])
        self.assertEqual([len(r) for r in rows], [2, 1], "two rows, the grid line ignored")
        first, second = rows[0][0][0], rows[0][1][0]
        self.assertEqual(first.height, 50, "the measured figure stands the target height")
        self.assertGreater(second.height, first.height, "and the rest keep their size to it")
        self.assertLess(rows[1][0][0].height, rows[1][0][0].width, "the lying figure stays lying")


class PaintedWeaponTest(unittest.TestCase):
    def test_painted_weapons_fit_the_cell_with_the_handle_in_the_fist(self) -> None:
        import gen_ui

        specs = gen_ui.weapon_specs()
        self.assertTrue(specs, "the owner's weapons are listed")
        for name, spec in specs.items():
            cell = gen_ui.painted_weapon(spec)
            self.assertEqual(cell.size, gen_ui.weapon_cell(spec), name)
            alpha = cell.getchannel("A")
            box = alpha.getbbox()
            self.assertIsNotNone(box, name)
            self.assertGreater(box[1], 0, f"{name} is not cut off at the top")
            grip = gen_ui.weapon_grip(cell.size)
            self.assertEqual(alpha.getpixel(grip), 255, f"{name} has its handle at the grip")

    def test_the_handle_runs_through_the_fist(self) -> None:
        import gen_ui

        for name, spec in gen_ui.weapon_specs().items():
            cell = gen_ui.painted_weapon(spec)
            grip = gen_ui.weapon_grip(cell.size)
            bottom = cell.getchannel("A").getbbox()[3]
            self.assertGreaterEqual(bottom - grip[1], 3, f"{name}: the handle's end shows below the fist")

    def test_vehicles_are_sized_for_the_characters(self) -> None:
        manifest = json.loads(kit_import.MANIFEST.read_text())
        pieces = manifest["kit"]["pieces"]
        hero = manifest["assets"]["hero_mika"]
        with Image.open(kit_import.ROOT / "client" / hero["sheet"].removeprefix("res://")) as sheet:
            idle = sheet.crop((0, 0, 64, 64)).getchannel("A").getbbox()
        person = idle[3] - idle[1]
        height = {k: pieces[k]["size"][1] / pieces[k]["hd"] for k in pieces}
        for car in ("taxi", "pickup_truck", "car_wreck"):
            self.assertGreaterEqual(height[car], person * 1.1, f"a {car} seats a person")
        self.assertGreaterEqual(height["motorbike"], person * 0.8, "a motorbike fits a rider")
        self.assertGreaterEqual(height["skytrain_train"], person, "the skytrain is bigger than a person")

    def test_the_chair_is_film_sized(self) -> None:
        import gen_ui

        chair = gen_ui.painted_weapon(gen_ui.weapon_specs()["weapon_chair"])
        box = chair.getchannel("A").getbbox()
        # Characters stand about 50 px tall: the chair is most of that.
        self.assertGreaterEqual(box[3] - box[1], 36)
        self.assertGreater(box[0], 0, "not cut off at the side")
        self.assertLess(box[2], chair.width, "not cut off at the side")


class RecordedSoundTest(unittest.TestCase):
    def test_recorded_sounds_are_cut_faded_and_below_full_scale(self) -> None:
        for sound_id, spec in import_sounds.recorded().items():
            data = import_sounds.render(spec)
            samples = validate.wav_samples(data)
            with wave.open(io.BytesIO(data)) as w:
                rate = w.getframerate()
            self.assertEqual(len(samples), int(spec["length"] * rate), sound_id)
            self.assertLessEqual(max(abs(v) for v in samples), 32767 * 0.9, sound_id)
            self.assertEqual(samples[0], 0, f"{sound_id} starts silent (no click)")
            self.assertLess(abs(samples[-1]), 200, f"{sound_id} fades out")


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
