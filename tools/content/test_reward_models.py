"""Unit tests for the reward-source execution models as stored in the registry
(data/registry/reference_loot_tables.json). No reference checkout is needed: the
expected values are the reference's own test goldens, cited by file and line.

  python3 -m unittest tools/content/test_reward_models.py -v

The full differential check against the source functions is
tools/content/verify_reward_models.py (needs the pinned checkout); its evidence is
data/registry/reward_model_verification.json.
"""

from __future__ import annotations

import json
import math
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import reward_models as rm  # noqa: E402

TABLES = json.loads((ROOT / "data/registry/reference_loot_tables.json").read_text())
VERIFICATION = json.loads((ROOT / "data/registry/reward_model_verification.json").read_text())
ITEMS = json.loads((ROOT / "data/registry/reference_items.json").read_text())["items"]


def stored_data() -> dict:
    data = {sid: src["model_data"] for sid, src in TABLES["reward_sources"].items()}
    data.update({mid: m["model_data"] for mid, m in TABLES["execution_submodels"].items()})
    return data


DEPS = {
    "item": lambda item_id: (ITEMS.get(item_id) or {}).get("source_fields"),
}


class StoredModels(unittest.TestCase):
    def test_the_registry_holds_the_code_models_and_their_verification(self):
        for sid, model in rm.MODELS.items():
            stored = TABLES["reward_sources"][sid]["execution_model"]
            self.assertEqual(stored["model_sha256"], VERIFICATION["sources"][sid]["model_sha256"], sid)
            self.assertEqual(VERIFICATION["sources"][sid]["result"], "PASS", sid)
            self.assertEqual(len(stored["steps"]), len(model["steps"]), sid)
            self.assertTrue(stored["entry_point"]["source"].startswith(model["entry_point"]["file"] + ":"), sid)
        self.assertEqual(VERIFICATION["result"], "PASS")

    def test_every_step_citation_is_located(self):
        def walk(v, sid):
            if isinstance(v, dict):
                if "code" in v:
                    self.assertRegex(v["source"], r"^(src|tests)/.+\.ts:\d+$", sid)
                for x in v.values():
                    walk(x, sid)
            elif isinstance(v, list):
                for x in v:
                    walk(x, sid)
        for sid, src in TABLES["reward_sources"].items():
            walk(src["execution_model"], sid)


class RngSemantics(unittest.TestCase):
    def test_int_chance_pick_follow_rng_ts(self):
        log: list = []
        r = rm.ScriptedRng([0.5, 0.25, 0.25, 0.999], log)
        self.assertEqual(r.call("int", [0.0, 3.0]), 2.0)          # floor(0 + 0.5 * 4)
        self.assertTrue(r.call("chance", [0.3]))                  # 0.25 < 0.3
        self.assertFalse(r.call("chance", [0.25]))                # 0.25 < 0.25 is false
        self.assertEqual(r.call("pick", [["a", "b", "c"]]), "c")  # floor(0.999 * 3)

    def test_seeded_generator_is_rng_ts_mulberry32(self):
        # The first three values of rng.ts `new Rng(1)`, as the static evaluator runs
        # the reference's own class (tools/content/verify_reward_models.py).
        g = rm.SeededRng(1, [], "r")
        self.assertEqual([g.next() for _ in range(3)],
                         [0.6270739405881613, 0.002735721180215478, 0.5274470399599522])


class ReferenceGoldens(unittest.TestCase):
    def test_vault_owner_payout_and_exact_draw_order(self):
        # tests/hoard_reward_roll.test.ts:56 'preserves the owners full payout and exact draw order'
        out = rm.run("treasure_vault_payouts",
                     {"rarity": "rare", "boss_template_id": "rift_boss_arcane", "cls": "mage", "level": 20,
                      "owner": True, "guest_capped": True, "mount_owned": False},
                     [], DEPS, stored_data(), rng=rm.DecisionRng([1, 0, 0], [True] * 5, []))
        payout = TABLES["reward_sources"]["treasure_vault_payouts"]["model_data"]["VAULT_PAYOUTS"]["rare"]
        bias = TABLES["reward_sources"]["hoard_boss_loot"]["model_data"]["CLASS_BIAS"]
        self.assertEqual([[d[1], d[2]] for d in out["draws"]], [
            ["int", [0, 4]], ["chance", [payout["gearChance"]]], ["chance", [bias]], ["int", [0, 3]],
            ["chance", [payout["markChance"]]], ["chance", [payout["mountChance"]]],
            ["chance", [payout["nextMapChance"]]], ["int", [0, 9999]]])
        self.assertEqual([(e["itemId"], e["count"]) for e in out["emitted"] if e["kind"] == "item"], [
            ("pristine_silk", 6), ("rare_collapsar_band_of_nyxaris", 1), ("heroic_mark", 2),
            ("reins_lanternback_troll", 1), ("treasure_map_epic", 1)])
        self.assertEqual([e["amount"] for e in out["emitted"] if e["kind"] == "copper"], [54000])

    def test_world_quest_cycle_zero_items(self):
        # tests/world_quest_item_slots.test.ts:89 and :107
        want = {"warrior": "bloodmane_warleggings", "paladin": "ysols_pearl_greaves",
                "hunter": "wyrmshadow_legguards", "rogue": "wildgrowth_leggings",
                "priest": "mantle_of_the_unhorsed", "shaman": "hoarfrost_edge",
                "mage": "architects_cornerstone", "warlock": "staff_of_velkhar", "druid": "grovewardens_grips"}
        for cls, item in want.items():
            out = rm.run("world_quest_class_loot", {"cycle": "wq1_0", "quest": {"id": "q", "zoneId": "thornpeak_heights"},
                                                    "cls": cls, "level": 20}, [], DEPS, stored_data())
            self.assertEqual(out["emitted"][0]["itemId"], item, cls)
        for zone in ("thornpeak_heights", "wraithwood", "amberfall"):
            out = rm.run("world_quest_class_loot", {"cycle": "wq1_0", "quest": {"id": "q", "zoneId": zone},
                                                    "cls": "mage", "level": 20}, [], DEPS, stored_data())
            self.assertEqual(len(out["emitted"]), 1, zone)
        below = rm.run("world_quest_class_loot", {"cycle": "wq1_0", "quest": {"id": "q", "zoneId": "thornpeak_heights"},
                                                  "cls": "mage", "level": 15}, [], DEPS, stored_data())
        self.assertEqual(below["emitted"], [], "below the item bracket (level 16) pays no item")


class ExecutionSemantics(unittest.TestCase):
    def test_drowned_litany_draws_twice_per_member_on_every_path(self):
        members = [{"entityId": 1, "cls": "mage"}, {"entityId": 2, "cls": "warrior"}]
        for tier in ("premium", "medium", "low"):
            for bountiful in (False, True):
                out = rm.run("drowned_litany_chest", {"tier": tier, "members": members, "bountiful": bountiful},
                             [0.1] * 4, DEPS, stored_data())
                self.assertEqual(len(out["draws"]), 4, (tier, bountiful))
                self.assertEqual({e["owner"] for e in out["emitted"]}, {1, 2}, "personal loot per member")

    def test_buddy_split_keeps_the_kill_total(self):
        drops = TABLES["reward_sources"]["buddy_boss_drops"]["model_data"]["BUDDY_BOSS_DROPS"]
        lich = next(d for d in drops if d["key"] == "crystal_lich")
        for n, want in ((1, lich["chance"] * 10), (2, lich["chance"] * 10 / 2), (10, lich["chance"]), (12, lich["chance"])):
            out = rm.run("buddy_boss_drops", {"boss_template_id": lich["bossId"], "claim": {"difficulty": "heroic"},
                                              "recipients": [{"entityId": i} for i in range(n)]}, [0.9] * n, DEPS, stored_data())
            self.assertTrue(all(math.isclose(d[2][0], want) for d in out["draws"]), n)
            self.assertEqual(len(out["draws"]), n)
        normal = rm.run("buddy_boss_drops", {"boss_template_id": lich["bossId"], "claim": {"difficulty": "normal"},
                                             "recipients": [{"entityId": 1}]}, [0.0], DEPS, stored_data())
        self.assertEqual(normal["draws"], [], "heroic-only rows draw nothing on a normal claim")

    def test_rift_rank_c_returns_after_its_pick(self):
        out = rm.run("rift_clear_pools", {"base_level": 20, "quality_source": False}, [0.0], DEPS, stored_data())
        self.assertEqual([d[1] for d in out["draws"]], ["int"], "C: one pool pick, nothing else")

    def test_weekly_open_is_one_pick_over_the_sorted_union(self):
        out = rm.run("weekly_boss_tables", {"phase": "open", "selected_items": [["b", "a"], ["c", "a"]]}, [0.5], DEPS, stored_data())
        self.assertEqual(out["draws"][0][1:3], ["pick", [3]])
        self.assertEqual(out["emitted"], [{"kind": "choice_item", "itemId": "b"}])


if __name__ == "__main__":
    unittest.main()
