"""Tests for tools/assets/provenance.py (the asset provenance inventory)."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import provenance  # noqa: E402


class ProvenanceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = provenance.inventory()["records"]

    def test_repository_inventory_has_no_problems(self) -> None:
        self.assertEqual(provenance.problems(self.records), [])

    def test_committed_outputs_are_current(self) -> None:
        for path, text in provenance.outputs().items():
            self.assertTrue(path.exists(), f"{path} missing: run provenance.py build")
            self.assertEqual(path.read_text(encoding="utf-8"), text, f"{path} is stale")

    def test_every_record_has_every_required_field(self) -> None:
        required = {
            "asset_id", "display_name", "category", "files", "asset_type", "creator",
            "source_url", "license", "commercial_use", "attribution", "modification",
            "generation", "reference_files", "replacement_target", "status",
        }
        for rec in self.records:
            self.assertLessEqual(required, set(rec), rec["asset_id"])
            self.assertIn(rec["asset_type"], provenance.TYPES)
            self.assertIn(rec["status"], provenance.STATUSES)

    def test_one_record_per_lpc_contribution(self) -> None:
        ids = [r["asset_id"] for r in self.records]
        self.assertEqual(len(ids), len(set(ids)))
        body = [r for r in self.records if r["asset_id"] == "lpc.body.bodies.male"]
        self.assertEqual(len(body), 1)
        self.assertGreater(len(body[0]["used_in"]), 1, "shared part lists all its users")

    def test_duplicates_and_missing_files_are_reported(self) -> None:
        rec = dict(self.records[0])
        bad = dict(rec, files=["client/assets/no_such_file.png"])
        found = provenance.problems([rec, rec, bad])
        self.assertTrue(any("duplicate" in p for p in found))
        self.assertTrue(any("file missing" in p for p in found))

    def test_commercial_use_needs_a_confirmed_licence(self) -> None:
        self.assertEqual(provenance.terms("OGA-BY 3.0", False)["commercial_use"], "Unverified")
        self.assertEqual(provenance.terms("OGA-BY 3.0", True)["commercial_use"], "Allowed")
        self.assertEqual(provenance.terms("CC-BY-SA 3.0", True)["share_alike"], "Yes")
        self.assertEqual(provenance.terms("UNKNOWN", True)["commercial_use"], "Unverified")
        self.assertEqual(provenance.terms("Some Custom Licence", True)["modification"], "UNKNOWN")
        self.assertEqual(provenance.terms("CC-BY-NC 4.0", True)["commercial_use"], "Not Allowed")
        self.assertEqual(provenance.terms("CC BY-ND 4.0", True)["modification"], "UNKNOWN")

    def test_ai_generated_art_carries_a_generation_record(self) -> None:
        ai = [r for r in self.records if r["asset_type"] == "AI Generated"]
        self.assertTrue(ai)
        for rec in ai:
            for field in ("tool", "model", "date", "prompt", "references",
                          "edited_after_generation"):
                self.assertIn(field, rec["generation"], rec["asset_id"])

    def test_gameplay_data_names_no_image_files(self) -> None:
        self.assertTrue(provenance.IMAGE_PATH.search('"icon": "res://assets/ui/x.png"'))
        self.assertFalse(provenance.IMAGE_PATH.search('"sprite": "class_mage_f"'))
        for name in provenance.GAMEPLAY_FILES + ("class_visuals.json",):
            path = provenance.CLIENT / "data" / name
            if path.exists():
                self.assertIsNone(provenance.IMAGE_PATH.search(path.read_text(encoding="utf-8")), name)

    def test_every_class_sprite_is_recorded_and_temporary(self) -> None:
        visuals = json.loads((provenance.CLIENT / "data" / "class_visuals.json").read_text())
        by_id = {r["asset_id"]: r for r in self.records}
        self.assertEqual(len(visuals["classes"]), 9)
        for bodies in visuals["classes"].values():
            for entry in bodies.values():
                rec = by_id[f"character.{entry['sprite']}"]
                self.assertEqual(rec["asset_type"], "LPC")
                self.assertEqual(rec["status"], "Temporary")
                parts = [by_id[c]["licence_class"] for c in rec["components"]]
                self.assertEqual(rec["licence_class"], provenance.worst(parts))

    def test_release_ready_needs_verified_rights_and_complete_records(self) -> None:
        for rec in self.records:
            if rec["release_ready"]:
                self.assertEqual(rec["licence_class"], "VERIFIED", rec["asset_id"])
                self.assertNotEqual(rec["asset_type"], "UNKNOWN", rec["asset_id"])
                self.assertNotEqual(rec["commercial_use"], "Unverified", rec["asset_id"])
        for rec in self.records:
            if rec["asset_type"] in ("UNKNOWN", "AI Generated"):
                self.assertFalse(rec["release_ready"], rec["asset_id"])

    def test_placeholder_hats_are_unknown_and_never_attributed(self) -> None:
        hats = [r for r in self.records if r["asset_type"] == "UNKNOWN"]
        self.assertTrue(hats)
        for rec in hats:
            self.assertEqual(rec["creator"], "UNKNOWN")
            self.assertEqual(rec["license"], "UNKNOWN")
            self.assertFalse(rec["release_ready"])
            self.assertNotIn("lpc", rec["source_url"].lower())

    def test_lpc_classes_come_from_the_source_review(self) -> None:
        review = json.loads(provenance.REVIEW.read_text())["parts"]
        by_id = {r["asset_id"]: r for r in self.records}
        for pid, part in review.items():
            self.assertIn(part["classification"], provenance.CLASSES)
            self.assertEqual(by_id[pid]["licence_class"], part["classification"], pid)
            if part["classification"] != "VERIFIED":
                self.assertFalse(by_id[pid]["release_ready"], pid)
        lpc_parts = [r for r in self.records if r["asset_id"].startswith("lpc.")]
        self.assertEqual(len(lpc_parts), len(review), "every LPC part has been reviewed")
        self.assertEqual(by_id["lpc.body.bodies.male"]["licence_class"], "RESTRICTED")
        self.assertEqual(provenance.worst(["VERIFIED", "UNVERIFIED"]), "UNVERIFIED")
        self.assertEqual(provenance.worst(["VERIFIED", "RESTRICTED", "UNVERIFIED"]), "RESTRICTED")


if __name__ == "__main__":
    unittest.main()
