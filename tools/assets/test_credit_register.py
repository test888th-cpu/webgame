"""Tests for tools/assets/credit_register.py: each problem the validator
reports is told apart, and a fully verified enemy passes.

  python3 -m unittest tools/assets/test_credit_register.py -v
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import credit_register as cr  # noqa: E402

GOOD_CREDIT = {
    "file": "body/bodies/male",
    "authors": ["A. Author"],
    "license": "OGA-BY 3.0",
    "offered": ["OGA-BY 3.0"],
    "urls": ["https://example.org/asset"],
}


class Tree:
    """A throwaway repository with one LPC enemy, pointed at by the module."""

    def __init__(self, credits: list[dict], files: tuple[str, ...] = ("credits.txt", "credits.csv"),
                 asset_manifest: dict | None = None, recipe: bool = True):
        self.dir = tempfile.TemporaryDirectory()
        root = Path(self.dir.name)
        folder = root / "client" / "assets" / "characters" / "thug"
        folder.mkdir(parents=True)
        (folder / "sheet.png").write_bytes(b"png")
        (folder / "credits.json").write_text(json.dumps(credits))
        for name in files:
            (folder / name).write_text("x")
        if asset_manifest is not None:
            (folder / "asset_manifest.json").write_text(json.dumps(asset_manifest))
        self.manifest = {"assets": {"thug": {
            "source": "lpc",
            "sheet": "res://assets/characters/thug/sheet.png",
            "credits": "res://assets/characters/thug/credits.json",
        }}}
        self.recipes = {"thug": {}} if recipe else {}
        self.saved = (cr.ROOT, cr.CLIENT)
        cr.ROOT, cr.CLIENT = root, root / "client"

    def check(self, register: set[str], owner: dict | None = None) -> set[str]:
        problems = cr.check_enemy("thug", {"sprite": "thug"}, self.manifest, self.recipes, register,
                                  owner if owner is not None else {})
        return {kind for kind, _ in problems}

    def close(self) -> None:
        cr.ROOT, cr.CLIENT = self.saved
        self.dir.cleanup()


def verified_manifest(status: str = "VERIFIED_OGA_BY_3.0", review: str = "APPROVED") -> dict:
    return {
        "monster_id": "thug", "source": "Universal LPC Spritesheet Character Generator",
        "files": {}, "verification": {"review_status": review},
        "components": [{"component_name": "body/bodies/male", "verification_status": status}],
    }


class CreditRegisterTest(unittest.TestCase):
    def test_a_fully_verified_enemy_is_compliant(self):
        tree = Tree([GOOD_CREDIT], asset_manifest=verified_manifest())
        try:
            self.assertEqual(tree.check({"thug:body/bodies/male"}), set())
        finally:
            tree.close()

    def test_a_credit_file_alone_is_not_compliance(self):
        tree = Tree([GOOD_CREDIT], files=())
        try:
            found = tree.check({"thug:body/bodies/male"})
            self.assertEqual(found, {"missing_credits_txt", "missing_credits_csv", "missing_manifest",
                                     "unverified_license"})
        finally:
            tree.close()

    def test_missing_creator_licence_and_url_are_told_apart(self):
        credit = {"file": "body/bodies/male", "authors": [], "license": "", "urls": []}
        tree = Tree([credit], asset_manifest=verified_manifest())
        try:
            found = tree.check({"thug:body/bodies/male"})
            self.assertTrue({"missing_creator", "missing_license", "missing_source_url"} <= found)
        finally:
            tree.close()

    def test_a_licence_outside_the_selection_is_reported(self):
        tree = Tree([dict(GOOD_CREDIT, license="CC-BY 4.0")], asset_manifest=verified_manifest())
        try:
            self.assertIn("outside_selection", tree.check({"thug:body/bodies/male"}))
        finally:
            tree.close()

    def test_an_unverified_component_cannot_be_approved(self):
        tree = Tree([GOOD_CREDIT], asset_manifest=verified_manifest(status="UNVERIFIED"))
        try:
            found = tree.check({"thug:body/bodies/male"})
            self.assertIn("unverified_approved", found)
            self.assertIn("unverified_license", found)
        finally:
            tree.close()

    def test_an_invalid_manifest_is_reported(self):
        tree = Tree([GOOD_CREDIT], asset_manifest={"monster_id": "thug"})
        try:
            self.assertIn("invalid_manifest", tree.check({"thug:body/bodies/male"}))
        finally:
            tree.close()
        bad_status = verified_manifest(status="PROBABLY_FINE")
        tree = Tree([GOOD_CREDIT], asset_manifest=bad_status)
        try:
            self.assertIn("invalid_manifest", tree.check({"thug:body/bodies/male"}))
        finally:
            tree.close()

    def test_an_asset_missing_from_the_global_credits_is_reported(self):
        tree = Tree([GOOD_CREDIT], asset_manifest=verified_manifest())
        try:
            self.assertEqual(tree.check(set()), {"not_in_global_credits"})
        finally:
            tree.close()

    def test_a_shared_sheet_is_reported_as_a_duplicate(self):
        tree = Tree([GOOD_CREDIT], asset_manifest=verified_manifest())
        try:
            owner: dict = {}
            tree.check({"thug:body/bodies/male"}, owner)
            problems = cr.check_enemy("thug_twin", {"sprite": "thug"}, tree.manifest, tree.recipes,
                                      {"thug:body/bodies/male"}, owner)
            self.assertIn("duplicate_asset", {kind for kind, _ in problems})
        finally:
            tree.close()

    def test_a_missing_recipe_is_reported(self):
        tree = Tree([GOOD_CREDIT], asset_manifest=verified_manifest(), recipe=False)
        try:
            self.assertIn("missing_configuration", tree.check({"thug:body/bodies/male"}))
        finally:
            tree.close()

    def test_the_register_covers_every_enemy_credit_in_the_repository(self):
        rows = cr.register_rows()
        ids = {row["Asset ID"] for row in rows}
        manifest = cr.load(cr.MANIFEST)
        for enemy in cr.load(cr.ENEMIES)["enemies"].values():
            entry = manifest["assets"][enemy["sprite"]]
            for credit in cr.load(cr.res(entry["credits"])):
                self.assertIn(f"{enemy['sprite']}:{credit['file']}", ids)
        for row in rows:
            self.assertIn(row["Verification Status"], cr.STATUSES | {""})


if __name__ == "__main__":
    unittest.main()
