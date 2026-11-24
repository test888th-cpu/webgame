#!/usr/bin/env python3
"""Verify the seven reward-source execution models against the pinned source.

  python3 tools/content/verify_reward_models.py --ref <checkout> [--check]

For every model, many scenarios (inputs and scripted random values) are run twice:
1. the REAL source function, by the static evaluator (tools/content/ts_eval.py),
   with ctx.rng a real rng.ts `Rng` whose next() returns the scripted values, and
   with only side-effecting collaborators (attachPendingBuddy, grantHoardReward,
   addItem, ...) replaced by recorders. The code under test is the source's own;
2. the extracted model, by reward_models.run, with the same scripted values.
Rewards, owners, quantities and the full draw log (method, arguments, result) must
match exactly. Reference goldens: literal expected values copied from the
reference's own test files (file and line cited, and re-checked to still be at
that line) must be produced by the source as the evaluator runs it, and by the
model.

Writes data/registry/reward_model_verification.json; --check reruns and compares.
Nothing from the reference is executed by a JavaScript engine.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_reference_registries as b  # noqa: E402
import reference_content as rc  # noqa: E402
import reward_models as rm  # noqa: E402
import ts_eval  # noqa: E402
from ts_eval import UNDEF, Builtin, JSMap  # noqa: E402

OUT = b.REGISTRY / "reward_model_verification.json"
CLASSES = ["warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"]
# Literal expectations from the reference's own tests: (file, line, text that must
# be on that line, what it pins).
GOLDENS = {
    "world_quest_class_loot": [
        ("tests/world_quest_item_slots.test.ts", 89, "expect(worldQuestItemZonesForCycle('wq1_0')).toEqual([",
         {"zones": {"wq1_0": ["thornpeak_heights", "wraithwood", "amberfall"],
                    "wq1_1": ["amberfall", "drakelands", "eastbrook_vale"],
                    "wq1_2": ["wraithwood", "veiled_hollow", "drakelands"]}}),
        ("tests/world_quest_item_slots.test.ts", 107, "expect(perClass).toEqual({",
         {"items_wq1_0_thornpeak_heights": {"warrior": "bloodmane_warleggings", "paladin": "ysols_pearl_greaves",
                                            "hunter": "wyrmshadow_legguards", "rogue": "wildgrowth_leggings",
                                            "priest": "mantle_of_the_unhorsed", "shaman": "hoarfrost_edge",
                                            "mage": "architects_cornerstone", "warlock": "staff_of_velkhar",
                                            "druid": "grovewardens_grips"}}),
    ],
}


class Harness:
    def __init__(self, checkout: Path) -> None:
        b.verify_checkout(checkout)
        self.checkout = checkout
        self.src = b.Source(checkout)
        files = b.tree(checkout)
        self.ref = rc.Reference(self.src, files)
        self.it = self.ref.interp
        ts_eval.TRACE = None  # verification runs do not feed the Math audit
        self.items = {k: ts_eval.to_json(v) for k, v in self.ref.items.items()}
        self.model_data = {mid: self.ref.model_data(m) for mid, m in rm.all_models().items()}
        shell = self.it.module_for("src/sim/rift/progression.ts")._get_local("shellItemIdForClass")
        raw_items = self.ref.items
        f = lambda path, name: (lambda m: m.export(name) if m.has_export(name) else m._get_local(name))(self.it.module_for(path))
        heroic_item = f("src/sim/loot/heroic_item.ts", "heroicLootItemId")
        add_shelf = f("src/sim/weekly_reward_tables.ts", "addRelocatedRaidShelf")
        is_reloc = f("src/sim/weekly_reward_tables.ts", "isRelocatedRaidPiece")
        allowed = f("src/sim/weekly_reward_eligibility.ts", "weeklyRewardItemAllowed")
        fits = f("src/sim/weekly_reward_eligibility.ts", "weeklyRewardFitsClass")
        spec_fits = f("src/sim/weekly_loot_spec.ts", "weeklyLootSpecFitsItem")
        pool_fn = f("src/sim/weekly_rewards.ts", "weeklyLootPool")
        within = f("src/sim/weekly_reward_options.ts", "weeklyItemWithinLevel")
        heroic_loot = self.ref.heroic_boss_loot()
        c = lambda fn, args: self.it.call(fn, args, "verify")
        u = lambda v: UNDEF if v is None else v

        def shelf(heroic):
            st = ts_eval.JSSet()
            c(add_shelf, [st, heroic])
            return list(st.items)
        self.deps = {
            "item": lambda item_id: self.items.get(item_id),
            "shell_item": lambda cls: c(shell, [cls]),
            "mob_loot": lambda boss: ts_eval.to_json(self.ref.mobs.get(boss, {}).get("loot", [])),
            "heroic_append": lambda boss: ts_eval.to_json(heroic_loot.get(boss, [])),
            "heroic_item": lambda item_id, heroic: c(heroic_item, [item_id, heroic]),
            "relocated_shelf": shelf,
            "is_relocated": lambda item_id: c(is_reloc, [item_id]),
            "eligible": lambda item_id, pool, cls, spec: item_id in raw_items and bool(
                c(allowed, [raw_items[item_id], pool]) and c(fits, [cls, raw_items[item_id]])
                and c(spec_fits, [cls, u(spec), raw_items[item_id]])),
            "pool_items": lambda pool, cls, unlocks, spec: list(c(pool_fn, [pool, cls, u(unlocks), u(spec)])),
            "within_level": lambda item_id, level: bool(c(within, [item_id, float(level)])),
        }
        self.Rng = self.ref.module_value("src/sim/rng.ts", "Rng")

    # -- a real rng.ts Rng whose next() is scripted; every high-level call logged
    def rng(self, draws, log: list) -> dict:
        values = iter(draws)
        real = self.it.construct(self.Rng, [1.0], "verify")

        def scripted_next(*_):
            try:
                return float(next(values))
            except StopIteration:
                raise RuntimeError("scripted draws exhausted") from None
        real["next"] = Builtin("scripted next", scripted_next)

        def method(name):
            def call(*args):
                out = self.it.method(real, name, list(args), "verify")
                shown = [len(args[0])] if name == "pick" else list(args)
                log.append(["rng", name, rm._plain([float(a) if isinstance(a, int) else a for a in shown]),
                            rm._plain(out)])
                return out
            return Builtin(f"rng.{name}", call)
        return {"next": method("next"), "int": method("int"), "chance": method("chance"), "pick": method("pick"),
                "range": method("range")}

    mutation = None  # (model id, data name, new value) or (model id, "drop_draw", draw id)
    draw_ids: dict = {}

    def model(self, model_id, inputs, draws):
        data, models = self.model_data, None
        if self.mutation and self.mutation[0] == model_id:
            _mid, what, value = self.mutation
            if what == "drop_draw":
                models = {**rm.all_models(), model_id: drop_draw(rm.MODELS[model_id], value)}
            else:
                data = {**self.model_data, model_id: {**self.model_data[model_id], what: value}}
        out = rm.run(model_id, inputs, draws, self.deps, data, models)
        out["draws"] = [d for d in out["draws"] if d[0] == "rng"]
        self.draw_ids.setdefault(model_id, set()).update(out["draw_ids"])
        return out

    def fn(self, path, name):
        mod = self.it.module_for(path)
        return mod.export(name) if mod.has_export(name) else mod._get_local(name)

    def call(self, fn, args):
        return self.it.call(fn, args, "verify")


def drop_draw(model: dict, draw_id: str) -> dict:
    """A copy of a model with one draw step removed (a negative control)."""
    import copy
    m = copy.deepcopy(model)

    def walk(steps):
        out = []
        for st in steps:
            if st.get("do") == "draw" and st["id"] == draw_id:
                out.append({"do": "let", "bind": st["bind"], "value": False})
                continue
            for key in ("then", "else", "body"):
                if key in st:
                    st[key] = walk(st[key])
            out.append(st)
        return out
    m["steps"] = walk(m["steps"])
    return m


# Negative controls: each must make the model disagree with the source somewhere.
MUTATIONS = {
    "buddy_boss_drops": ("BUDDY_FULL_GROUP", 5),
    "world_quest_class_loot": ("SLOT_SEED_SALT", 0x51070001),
    "hoard_boss_loot": ("CLASS_BIAS", 0.3),
    "treasure_vault_payouts": ("drop_draw", "mount_roll"),
    "rift_clear_pools": ("PATTERN_CHANCE", 0.5),
    "rift_first_clear": ("TIER_POWER", {"C": 2, "B": 2, "A": 3, "S": 4}),
    "drowned_litany_chest": ("drop_draw", "placeholder"),
    "weekly_boss_tables": ("THRESHOLDS", {"raid": [1, 2, 3], "dungeon": [1, 4, 8], "world": [1, 4, 8], "pvp": [1, 3, 5]}),
}


def js(v):
    """A Python value as an evaluator value (numbers as doubles)."""
    if isinstance(v, bool) or v is None or isinstance(v, str):
        return v
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, list):
        return [js(x) for x in v]
    if isinstance(v, dict):
        return {k: js(x) for k, x in v.items()}
    return v


def scripts(rnd: random.Random, n: int, length: int, hot: float = 1.0):
    """Scripted next() sequences: boundary values and seeded uniform values. `hot`
    concentrates values near 0 so low-probability branches are reached."""
    edge = [0.0, 0.999999999, 0.5, 1e-9]
    out = [[edge[i % 4]] * length for i in range(4)]
    for _ in range(n):
        out.append([rnd.random() * (hot if rnd.random() < 0.5 else 1.0) for _ in range(length)])
    return out


# ---------------------------------------------------------------------------
# Per-source scenario runners: (inputs, draws) -> (source result, model result),
# both normalised to {"rewards": [...], "draws": [...]}.


def verify_buddy(h: Harness, rnd):
    mod = h.it.module_for("src/sim/buddy_drops.ts")
    fn = h.fn("src/sim/buddy_drops.ts", "rollBossBuddyDrops")
    bosses = sorted({r["bossId"] for r in h.model_data["buddy_boss_drops"]["BUDDY_BOSS_DROPS"]}) + ["sexton_marrow"]
    cases = []
    for boss in bosses:
        for n in (0, 1, 2, 5, 10, 12):
            for claim in (None, {"difficulty": "normal"}, {"difficulty": "heroic"}):
                for draws in scripts(rnd, 6, 40, hot=0.02):
                    recipients = [{"entityId": 100 + i} for i in range(n)]
                    got: list = []
                    mod.override("attachPendingBuddy", Builtin("record", lambda ctx, pid, key, source, pos, _g=got: _g.append(
                        {"kind": "buddy", "owner": rm._plain(pid), "key": key, "source": source})))
                    log: list = []
                    h.call(fn, [{"rng": h.rng(draws, log)}, {"templateId": boss, "pos": {"x": 0.0, "z": 0.0}},
                                js(recipients), js(claim)])
                    model = h.model("buddy_boss_drops", {"boss_template_id": boss, "recipients": recipients, "claim": claim}, draws)
                    cases.append(({"rewards": got, "draws": log},
                                  {"rewards": model["emitted"], "draws": model["draws"]},
                                  {"boss": boss, "recipients": n, "claim": claim}))
    return cases


def verify_world_quest(h: Harness, rnd):
    return verify_world_quest_items(h, rnd) + verify_world_quest_cycle(h, rnd)


def verify_world_quest_items(h: Harness, rnd):
    fn = h.fn("src/sim/world_quest_item_slots.ts", "worldQuestItemRewardForQuest")
    zones = h.model_data["world_quest_class_loot"]["WORLD_QUEST_ITEM_ZONES"]
    by_zone = h.ref.module_value("src/sim/world_quest_rotation.ts", "WORLD_QUESTS_BY_ZONE")
    always = set(h.model_data["world_quest_class_loot"]["ALWAYS_ACTIVE_WORLD_QUEST_IDS"])
    quests = []
    for zone in sorted(by_zone):
        for qid in by_zone[zone]:
            if qid in always or not any(q["zoneId"] == zone for q in quests if q["id"] not in always):
                quests.append({"id": qid, "zoneId": zone})
    cycles = [f"wq1_{n}" for n in range(0, 60, 3)] + ["wq3_1", "2026-09-05", "", "nonsense"]
    cases = []
    for cycle in cycles:
        for quest in quests:
            for cls in CLASSES:
                for level in (15, 16, 20):
                    src = h.call(fn, [cycle, js(quest), cls, float(level)])
                    got = [] if src is None else [{"kind": "item", "itemId": src, "count": 1, "owner": "completer"}]
                    model = h.model("world_quest_class_loot", {"cycle": cycle, "quest": quest, "cls": cls, "level": level}, [])
                    cases.append(({"rewards": got, "draws": []}, {"rewards": model["emitted"], "draws": model["draws"]},
                                  {"cycle": cycle, "quest": quest["id"], "cls": cls, "level": level}))
    assert zones, "no item zones"
    return cases


def verify_world_quest_cycle(h: Harness, rnd):
    """The cycle parser and the rotation (world_quest_rotation.ts) against the model."""
    number_fn = h.fn("src/sim/world_quest_rotation.ts", "worldQuestCycleNumber")
    active_fn = h.fn("src/sim/world_quest_rotation.ts", "activeWorldQuestsForCycle")
    inputs = ["wq1_0", "wq1_1", "wq1_59", "wq1_-4", "wq1_007", "wq1_x", "wq1_", "wq3_0", "wq3_7", "wq3_-2",
              "2026-08-31", "2026-09-05", "2027-02-29", "2028-02-29", "2026-13-01", "2026-04-31", "1999-12-31",
              "2400-02-29", "2100-02-29", "", "wq2_5", "x" * 40, "wq1_" + "9" * 20, None, 5.0, True]
    for _ in range(80):
        y, m, d = rnd.randint(1990, 2200), rnd.randint(0, 13), rnd.randint(0, 32)
        inputs.append(f"{y:04d}-{m:02d}-{d:02d}")
        inputs.append(f"wq1_{rnd.randint(-500, 5000)}")
    cases = []
    for cycle in inputs:
        src_n = h.call(number_fn, [UNDEF if cycle is None else cycle])
        src_n = None if src_n is None or src_n is UNDEF else rm._plain(src_n)
        m = rm.run("world_quest.cycle_number", {"cycle": cycle}, [], h.deps, h.model_data)
        cases.append(({"rewards": [src_n], "draws": []}, {"rewards": [m["result"]], "draws": []}, {"cycle_number": str(cycle)}))
        src_q = [q["id"] for q in h.call(active_fn, [UNDEF if cycle is None else cycle])]
        mq = rm.run("world_quest.active_quests", {"cycle": cycle}, [], h.deps, h.model_data)
        cases.append(({"rewards": src_q, "draws": []}, {"rewards": mq["result"] or [], "draws": []}, {"active_quests": str(cycle)}))
    return cases


def verify_rift_first(h: Harness, rnd):
    fn = h.fn("src/sim/rift/progression.ts", "addRiftProgressionLoot")
    cases = []
    for tier in ("C", "B", "A", "S"):
        for mult, bias in ((1, 0.25), (0.3, 0.25), (1.6, 0.5), (3, 0.6), (UNDEF, UNDEF)):
            for eligible in (True, False):
                for party in (["mage"], ["warrior", None, "rogue", "druid"], ["hunter", "priest", "shaman", "paladin", "warlock"]):
                    for draws in scripts(rnd, 3, 40, hot=0.2):
                        draws = [x if rnd.random() < 0.7 else 0.9 + 0.1 * x for x in draws]
                        log: list = []
                        pids = [100.0 + i for i in range(len(party))]
                        players = JSMap([[pid, {"cls": c}] for pid, c in zip(pids, party) if c is not None])
                        boss = {"kind": "mob", "ownerId": None if eligible else 9.0, "affixSpawned": False,
                                "templateId": "rift_boss_brute", "loot": {"copper": 5000.0, "items": []}}
                        args = [{"rng": h.rng(draws, log), "players": players}, boss, "evt", tier, pids]
                        if mult is not UNDEF:
                            args += [float(mult), float(bias)]
                        h.call(fn, args)
                        got = [{"kind": "copper", "amount": rm._plain(boss["loot"]["copper"])}]
                        for it in boss["loot"]["items"]:
                            q = it.get("instance", {}).get("lootQuality") if isinstance(it.get("instance"), dict) else None
                            got.append({"kind": "item", "owner": rm._plain(it["personalFor"][0]), "itemId": it["itemId"],
                                        "count": rm._plain(it["count"]),
                                        "quality": rm._plain({"tier": q["tier"], "weights": q["weights"]}) if q else None})
                        model = h.model("rift_first_clear", {
                            "tier": tier, "participants": [{"pid": int(pid), "cls": c} for pid, c in zip(pids, party)],
                            "loot_multiplier": 1 if mult is UNDEF else mult, "crafting_material_bias": 0.25 if bias is UNDEF else bias,
                            "boss_copper": 5000, "quality_source": eligible}, draws)
                        cases.append(({"rewards": got, "draws": log}, {"rewards": model["emitted"], "draws": model["draws"]},
                                      {"tier": tier, "mult": str(mult), "eligible": eligible, "party": len(party)}))
    return cases


def goldens_world_quest(h: Harness):
    zones_fn = h.fn("src/sim/world_quest_item_slots.ts", "worldQuestItemZonesForCycle")
    item_fn = h.fn("src/sim/world_quest_item_slots.ts", "worldQuestItemRewardFor")
    results = []
    for path, line, text, pins in GOLDENS["world_quest_class_loot"]:
        lines = h.src.read(path).splitlines()
        cited = 0 < line <= len(lines) and text in lines[line - 1]
        ok = cited
        if "zones" in pins:
            for cycle, want in pins["zones"].items():
                ok = ok and h.call(zones_fn, [cycle]) == want
                # The model: the zone list is internal; an item zone pays, another does not.
                for zone in want:
                    q = {"id": f"golden_{zone}", "zoneId": zone}
                    m = h.model("world_quest_class_loot", {"cycle": cycle, "quest": q, "cls": "mage", "level": 20}, [])
                    ok = ok and len(m["emitted"]) == 1
        if "items_wq1_0_thornpeak_heights" in pins:
            for cls, want in pins["items_wq1_0_thornpeak_heights"].items():
                ok = ok and h.call(item_fn, ["wq1_0", "thornpeak_heights", cls]) == want
                q = {"id": "golden_thornpeak", "zoneId": "thornpeak_heights"}
                m = h.model("world_quest_class_loot", {"cycle": "wq1_0", "quest": q, "cls": cls, "level": 20}, [])
                ok = ok and m["emitted"] and m["emitted"][0]["itemId"] == want
        results.append({"test": f"{path}:{line}", "cited_line_present": cited, "pass": bool(ok)})
    return results


def goldens_vault(h: Harness):
    """tests/hoard_reward_roll.test.ts: 'preserves the owners full payout and exact draw order'."""
    path, line = "tests/hoard_reward_roll.test.ts", 56
    lines = h.src.read(path).splitlines()
    cited = "const script = scriptedRng([1, 0, 0], [true, true, true, true, true]);" in lines[line - 1]
    payout = h.model_data["treasure_vault_payouts"]["VAULT_PAYOUTS"]["rare"]
    bias = h.model_data["hoard_boss_loot"]["CLASS_BIAS"]
    want_calls = [["int", [0, 4]], ["chance", [payout["gearChance"]]], ["chance", [bias]], ["int", [0, 3]],
                  ["chance", [payout["markChance"]]], ["chance", [payout["mountChance"]]],
                  ["chance", [payout["nextMapChance"]]], ["int", [0, 9999]]]
    want_items = [("pristine_silk", 6), ("rare_collapsar_band_of_nyxaris", 1), ("heroic_mark", 2),
                  ("reins_lanternback_troll", 1), ("treasure_map_epic", 1)]
    # The source, with the test's own decision script.
    ints, chances, calls = [1.0, 0.0, 0.0], [True] * 5, []

    def dint(a, b):
        calls.append(["int", [rm._plain(a), rm._plain(b)]])
        return ints.pop(0)

    def dchance(p):
        calls.append(["chance", [rm._plain(p)]])
        return chances.pop(0)
    rng = {"int": Builtin("int", dint), "chance": Builtin("chance", dchance)}
    inp = {"rarity": "rare", "bossTemplateId": "rift_boss_arcane", "cls": "mage", "level": 20.0, "owner": True,
           "guestCapped": True, "mountOwned": False}
    src = h.call(h.fn("src/sim/rift/hoard_reward_roll.ts", "rollHoardReward"), [rng, inp])
    src_ok = (calls == want_calls and [(i["itemId"], rm._plain(i["count"])) for i in src["items"]] == want_items
              and rm._plain(src["copper"]) == 54000 and src["capped"] is False)
    # The model, with the same script.
    m = rm.run("treasure_vault_payouts", {"rarity": "rare", "boss_template_id": "rift_boss_arcane", "cls": "mage", "level": 20,
                                          "owner": True, "guest_capped": True, "mount_owned": False},
               [], h.deps, h.model_data, rng=rm.DecisionRng([1, 0, 0], [True] * 5, []))
    m_calls = [[d[1], d[2]] for d in m["draws"] if d[0] == "rng"]
    m_items = [(e["itemId"], e["count"]) for e in m["emitted"] if e["kind"] == "item"]
    m_copper = [e["amount"] for e in m["emitted"] if e["kind"] == "copper"]
    model_ok = m_calls == want_calls and m_items == want_items and m_copper == [54000]
    return [{"test": f"{path}:{line}", "cited_line_present": cited, "source_pass": src_ok, "model_pass": model_ok,
             "pass": cited and src_ok and model_ok}]


def verify_hoard(h: Harness, rnd):
    fn = h.fn("src/sim/content/hoard_loot.ts", "rollHoardBossDrop")
    bosses = sorted(h.model_data["hoard_boss_loot"]["HOARD_BOSS_LOOT_TABLES"]) + [None, "not_a_keeper"]
    cases = []
    for boss in bosses:
        for rarity in ("common", "rare", "epic", "legendary"):
            for cls in CLASSES + [None]:
                for draws in scripts(rnd, 2, 4):
                    log: list = []
                    src = h.call(fn, [h.rng(draws, log), UNDEF if boss is None else boss, rarity, UNDEF if cls is None else cls])
                    model = h.model("hoard_boss_loot", {"boss_template_id": boss, "rarity": rarity, "cls": cls}, draws)
                    cases.append(({"rewards": [src], "draws": log}, {"rewards": [model["result"]], "draws": model["draws"]},
                                  {"boss": boss, "rarity": rarity, "cls": cls}))
    return cases


def vault_normalise_source(res) -> list:
    out = []
    quality = None
    for item in res["items"]:
        out.append({"kind": "item", "itemId": item["itemId"], "count": rm._plain(item["count"])})
        if "lootQuality" in item:
            quality = {"kind": "quality", "itemId": item["itemId"], "quality": rm._plain(
                {"tier": item["lootQuality"]["tier"], "weights": item["lootQuality"]["weights"]})}
    if quality:
        out.append(quality)
    out.append({"kind": "copper", "amount": rm._plain(res["copper"])})
    return out


def verify_vault(h: Harness, rnd):
    fn = h.fn("src/sim/rift/hoard_reward_roll.ts", "rollHoardReward")
    bosses = sorted(h.model_data["hoard_boss_loot"]["HOARD_BOSS_LOOT_TABLES"])[:3] + [None]
    cases = []
    for rarity in ("common", "rare", "epic", "legendary"):
        for boss in bosses:
            for owner in (True, False):
                for mount_owned in (False, True):
                    for cls, level in (("mage", 20), ("warrior", 16), ("rogue", 1)):
                        for draws in scripts(rnd, 3, 20, hot=0.05):
                            log: list = []
                            inp = {"rarity": rarity, "bossTemplateId": UNDEF if boss is None else boss, "cls": cls, "level": float(level),
                                   "owner": owner, "guestCapped": not owner, "mountOwned": mount_owned}
                            src = h.call(fn, [h.rng(draws, log), inp])
                            model = h.model("treasure_vault_payouts", {"rarity": rarity, "boss_template_id": boss, "cls": cls, "level": level,
                                                                       "owner": owner, "guest_capped": not owner, "mount_owned": mount_owned}, draws)
                            cases.append(({"rewards": vault_normalise_source(src), "draws": log},
                                          {"rewards": model["emitted"], "draws": model["draws"]},
                                          {"rarity": rarity, "boss": boss, "owner": owner, "mount_owned": mount_owned, "cls": cls}))
    return cases


def verify_vault_allocation(h: Harness):
    """payTreasureVault: who is paid, in which order, and who counts as owner."""
    mod = h.it.module_for("src/sim/treasure_vault.ts")
    fn = h.fn("src/sim/treasure_vault.ts", "payTreasureVault")
    calls: list = []
    mod.override("rollHoardReward", Builtin("record", lambda rng, inp: calls.append(
        {"cls": inp["cls"], "owner": inp["owner"], "level": rm._plain(inp["level"])}) or {"items": [], "copper": 0.0, "capped": False}))
    mod.override("grantHoardReward", Builtin("record", lambda *a: True))
    mod.override("mountOwned", Builtin("mountOwned", lambda meta, key: bool(meta.get("mount"))))
    players = JSMap([[1.0, {"cls": "mage", "characterId": "c1"}], [2.0, {"cls": "rogue", "characterId": "c2", "leaving": True}],
                     [3.0, {"cls": "druid", "characterId": "owner-char"}], [4.0, {"cls": "priest"}],
                     [6.0, {"cls": "hunter", "characterId": "guest"}]])
    entities = JSMap([[1.0, {"level": 20.0}], [2.0, {"level": 18.0}], [3.0, {"level": 17.0}], [6.0, {"level": 16.0}]])
    ctx = {"players": players, "entities": entities, "rng": {}}
    vault = {"rarity": "epic", "ownerPid": 1.0, "ownerCharacterId": "owner-char"}
    h.call(fn, [ctx, vault, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0], "x"])
    # The model's rules: skip a missing or leaving participant (2: leaving; 4: no entity;
    # 5: no meta); the owner by entity id (1) or by character id (3).
    want = [{"cls": "mage", "owner": True, "level": 20}, {"cls": "druid", "owner": True, "level": 17},
            {"cls": "hunter", "owner": False, "level": 16}]
    return {"calls": calls, "expected_by_model_rules": want, "pass": calls == want}


def rift_normalise_source(boss) -> list:
    loot = boss["loot"]
    slots = []
    for s in loot["items"]:
        q = s.get("instance", {}).get("lootQuality") if isinstance(s.get("instance"), dict) else None
        entry = {"itemId": s["itemId"], "count": rm._plain(s["count"])}
        if q is not None:
            entry["quality"] = rm._plain({"tier": q["tier"], "weights": q["weights"]})
        slots.append(entry)
    return [{"kind": "copper", "amount": rm._plain(loot["copper"])}, {"kind": "items", "slots": slots}]


def rift_normalise_model(emitted) -> list:
    copper = sum(e["amount"] for e in emitted if e["kind"] == "copper")
    slots = []
    for e in emitted:
        if e["kind"] == "items":
            for s in e["slots"]:
                entry = {"itemId": s["itemId"], "count": s["count"]}
                if s.get("quality") is not None:  # an Ordinary copy carries no quality, as in the source
                    entry["quality"] = s["quality"]
                slots.append(entry)
    return [{"kind": "copper", "amount": copper}, {"kind": "items", "slots": slots}]


def verify_rift(h: Harness, rnd):
    fn = h.fn("src/sim/rift/progression.ts", "addRiftClearGearLoot")
    cases = []
    for base_level in (20, 21, 22, 24, 25, 27, 28, 30):
        for eligible in (True, False):
            for draws in scripts(rnd, 8, 60, hot=0.01):
                log: list = []
                boss = {"kind": "mob", "ownerId": None if eligible else 7.0, "affixSpawned": False,
                        "templateId": "rift_boss_brute", "loot": None, "lootable": False}
                h.call(fn, [{"rng": h.rng(draws, log)}, boss, float(base_level)])
                model = h.model("rift_clear_pools", {"base_level": base_level, "quality_source": eligible}, draws)
                cases.append(({"rewards": rift_normalise_source(boss), "draws": log},
                              {"rewards": rift_normalise_model(model["emitted"]), "draws": model["draws"]},
                              {"base_level": base_level, "quality_source": eligible}))
    return cases


def verify_litany(h: Harness, rnd):
    mod = h.it.module_for("src/sim/delves/drowned_litany_rite.ts")
    open_fn = mod._get_local("openDrownedReliquary")
    for name in ("grantDelveRewards", "grantRiteBonus", "openDelveSurfaceExit", "emitPartyLog"):
        mod.override(name, Builtin("record", lambda *a: 0.0))
    cases = []
    for tier in ("premium", "medium", "low"):
        for bountiful, chest in ((False, 77), (True, 77), (True, 78)):
            for party in ([("warrior",)], [("mage",), ("rogue",), ("paladin",)], None):
                for draws in scripts(rnd, 3, 12):
                    log: list = []
                    events: list = []
                    members = [{"entityId": 10 + i, "cls": c[0]} for i, c in enumerate(party or [("hunter",)])]
                    players = JSMap([[float(m["entityId"]), {"cls": m["cls"]}] for m in members])
                    ctx = {"rng": h.rng(draws, log), "players": players, "entities": JSMap([]),
                           "partyMembersForKey": Builtin("party", lambda key, _m=members: [float(m["entityId"]) for m in _m]),
                           "emit": Builtin("emit", lambda ev, _e=events: _e.append(ev))}
                    run = {"drownedLitanyRite": {"opened": False, "reliquaryId": 77.0, "puzzleActive": True, "sequencePlaying": False},
                           "objectState": {}, "partyKey": "p" if party else None, "bountiful": bountiful,
                           "rewardChestId": float(chest), "delveId": "d", "tierId": "t"}
                    h.call(open_fn, [ctx, run, tier, float(members[0]["entityId"])])
                    got = [{"kind": "item", "owner": rm._plain(ev["pid"]), "itemId": it["itemId"], "count": rm._plain(it["count"])}
                           for ev in events if ev.get("type") == "delveChestLoot" for it in ev["items"]]
                    model = h.model("drowned_litany_chest", {"tier": tier, "members": members,
                                                              "bountiful": bountiful and chest == 77}, draws)
                    cases.append(({"rewards": got, "draws": log}, {"rewards": model["emitted"], "draws": model["draws"]},
                                  {"tier": tier, "bountiful": bountiful, "chest_is_reward": chest == 77, "members": len(members)}))
    # The tier rule.
    lt = mod._get_local("lootTierForMistakes")
    cap = mod._get_local("capTier")
    ceiling = mod._get_local("riteCeiling")
    intensities = list(h.model_data["drowned_litany.tier"]["RITE_INTENSITY"]) + [None]
    for mistakes in range(0, 5):
        for allowed in range(0, 4):
            for intensity in intensities:
                src = h.call(cap, [h.call(lt, [float(mistakes), float(allowed)]), h.call(ceiling, [intensity])])
                m = rm.run("drowned_litany.tier", {"mistakes": mistakes, "allowed": allowed, "intensity": intensity}, [], h.deps, h.model_data)
                cases.append(({"rewards": [src], "draws": []}, {"rewards": [m["result"]], "draws": []},
                              {"tier_rule": [mistakes, allowed, intensity]}))
    return cases


def verify_weekly(h: Harness, rnd):
    cases = []
    # (a) earning at the weekly reset
    advance = h.fn("src/sim/weekly_rewards.ts", "advanceWeeklyRewards")
    empty = h.fn("src/sim/weekly_rewards.ts", "emptyWeeklyRewards")
    pools = h.model_data["weekly_boss_tables"]["POOL_IDS"]
    for _ in range(60):
        st = h.call(empty, [1000.0])
        raid = sorted([rnd.choice([1, 2]) for _ in range(rnd.randint(0, 3))], reverse=True)
        dungeons = sorted([rnd.choice([1, 2]) for _ in range(rnd.randint(0, 8))], reverse=True)
        world, pvp = float(rnd.randint(0, 8)), float(rnd.randint(0, 5))
        st["raidClears"], st["dungeons"], st["world"], st["pvp"] = js(raid), js(dungeons), world, pvp
        available = {p: rnd.random() < 0.8 for p in pools}
        h.call(advance, [st, 5000.0, Builtin("next", lambda now: now + 604800000.0),
                         Builtin("available", lambda pool, _a=available: _a[pool])])
        got = [{"kind": "choice", "pool": c["pool"]} for c in (st["vaults"][-1]["choices"] if st["vaults"] else [])]
        model = h.model("weekly_boss_tables", {"phase": "earn", "available": available,
                                               "state": {"raidClears": raid, "dungeons": dungeons, "world": world, "pvp": pvp}}, [])
        cases.append(({"rewards": got, "draws": []}, {"rewards": model["emitted"], "draws": []},
                      {"phase": "earn", "raid": raid, "dungeons": dungeons, "world": world, "pvp": pvp}))
    # (a2) candidate construction: the real weeklyRewardTableOptions against the model
    options_real = h.fn("src/sim/weekly_reward_options.ts", "weeklyRewardTableOptions")
    profiles = h.ref.module_value("src/sim/weekly_loot_spec.ts", "WEEKLY_LOOT_PROFILES")
    btables = h.model_data["weekly_boss_tables"]["WEEKLY_BOSS_TABLES"]
    for k in range(240):
        cls = CLASSES[k % 9]
        pool = ["raid", "raid_heroic", "dungeon", "dungeon_heroic", "world", "pvp"][k % 6]
        level = float(rnd.choice([10, 16, 18, 20]))
        unlocks = {t["bossId"]: float(rnd.choice([1, 2])) for t in btables if rnd.random() < 0.7}
        # A loot spec of the class (WEEKLY_LOOT_PROFILES), none, or another class's.
        roll = rnd.random()
        spec = rnd.choice(sorted(profiles[cls])) if roll < 0.55 else (
            rnd.choice(sorted(profiles[CLASSES[(k + 1) % 9]])) if roll < 0.65 else None)
        choices = [{"pool": pool}]
        batch = {"resetAtMs": 1000.0, "choices": choices, "bossUnlocks": unlocks, "raidUnlocks": [2.0, 1.0, 2.0]}
        base = h.call(options_real, [batch, choices[0], cls, level, UNDEF if spec is None else spec])
        if base and rnd.random() < 0.6:  # reserve a few items through other choices of the batch
            pick = [i for o in base for i in o["items"]]
            for item_id in rnd.sample(pick, min(len(pick), rnd.randint(1, 3))):
                choices.append({"pool": pool, "itemId": item_id})
        src = h.call(options_real, [batch, choices[0], cls, level, UNDEF if spec is None else spec])
        got = [{"id": o["id"], "kind": o["kind"], "items": list(o["items"])} for o in src]
        model = rm.run("weekly.options", {"batch": ts_eval.to_json(batch), "pool": pool, "cls": cls, "level": level, "spec": spec},
                       [], h.deps, h.model_data)
        cases.append(({"rewards": got, "draws": []}, {"rewards": model["result"], "draws": []},
                      {"phase": "options", "pool": pool, "cls": cls, "level": level, "spec": spec, "reserved": len(choices) - 1}))
    # (b) opening a choice: the real prepareWeeklyRewardOpen, keeper reach and state stubbed
    mod = h.it.module_for("src/sim/weekly_reward_open.ts")
    prepare = h.fn("src/sim/weekly_reward_open.ts", "prepareWeeklyRewardOpen")
    options_fn = h.fn("src/sim/weekly_reward_options.ts", "weeklyRewardTableOptions")
    tables = h.model_data["weekly_boss_tables"]["WEEKLY_BOSS_TABLES"]
    mod.override("nearWeeklyKeeper", Builtin("near", lambda ctx, e: True))
    for _ in range(80):
        cls = rnd.choice(CLASSES)
        level = float(rnd.choice([16, 18, 20]))
        pool = rnd.choice(["dungeon", "dungeon_heroic", "raid", "raid_heroic", "world", "pvp"])
        unlocks = {t["bossId"]: float(rnd.choice([1, 2])) for t in tables if rnd.random() < 0.6}
        batch = {"resetAtMs": 1000.0, "choices": [{"pool": pool}], "bossUnlocks": unlocks, "raidUnlocks": [2.0, 2.0, 2.0]}
        state = {"resetAtMs": 2000.0, "claimSequence": 0.0, "vaults": [batch], "bossUnlocks": unlocks}
        mod.override("stateFor", Builtin("stateFor", lambda ctx, meta, _s=state: _s))
        options = h.call(options_fn, [batch, batch["choices"][0], cls, level, UNDEF])
        if not options:
            continue
        chosen_ids = sorted({o["id"] for o in rnd.sample(options, rnd.randint(1, len(options)))})
        selected_items = [o["items"] for o in options if o["id"] in chosen_ids]
        draws = [rnd.random()]
        log: list = []
        ctx = {"rng": h.rng(draws, log), "lockoutNowMs": Builtin("now", lambda: 5000.0),
               "resolve": Builtin("resolve", lambda pid, _c=cls, _l=level: {"meta": {"leaving": False, "cls": _c},
                                                                             "e": {"level": _l, "pos": {"x": 0.0, "z": 0.0}}})}
        res = h.call(prepare, [ctx, "1000:0", 1.0, UNDEF, chosen_ids])
        got = [] if res is None else [{"kind": "choice_item", "itemId": res["itemId"]}]
        model = h.model("weekly_boss_tables", {"phase": "open", "selected_items": selected_items}, draws)
        cases.append(({"rewards": got, "draws": log}, {"rewards": model["emitted"], "draws": model["draws"]},
                      {"phase": "open", "pool": pool, "cls": cls, "tables": chosen_ids}))
    # (c) claiming: the real claimWeeklyReward, quality draws through grantFreshLoot
    wmod = h.it.module_for("src/sim/weekly_rewards.ts")
    claim = h.fn("src/sim/weekly_rewards.ts", "claimWeeklyReward")
    wmod.override("nearWeeklyKeeper", Builtin("near", lambda ctx, e: True))
    item_ids = sorted(i for i, it in h.items.items() if it.get("kind") in ("armor", "weapon", "potion"))[:400]
    for _ in range(80):
        item_id = rnd.choice(item_ids)
        req = h.items[item_id].get("requiredClass")
        cls = req[0] if isinstance(req, list) and req else "warrior"
        batch = {"resetAtMs": 1000.0, "choices": [{"pool": "world", "itemId": item_id, "opened": True}]}
        state = {"resetAtMs": 2000.0, "claimSequence": 0.0, "vaults": [batch], "bossUnlocks": {}, "overflowed": False}
        wmod.override("stateFor", Builtin("stateFor", lambda ctx, meta, _s=state: _s))
        draws = [rnd.random() * (0.2 if rnd.random() < 0.5 else 1) + (0.9 if rnd.random() < 0.3 else 0) for _ in range(8)]
        draws = [min(d, 0.999999) for d in draws]
        log: list = []
        granted: list = []
        ctx = {"rng": h.rng(draws, log), "lockoutNowMs": Builtin("now", lambda: 5000.0),
               "resolve": Builtin("resolve", lambda pid, _c=cls: {"meta": {"leaving": False, "cls": _c}, "e": {"id": 1.0, "level": 20.0}}),
               "canAddItem": Builtin("can", lambda *a: True),
               "addItem": Builtin("addItem", lambda iid, n, pid, opts=UNDEF, _g=granted: _g.append(["plain", iid, rm._plain(n)]) or True),
               "addItemInstance": Builtin("addInst", lambda iid, inst, pid, n=1.0, opts=UNDEF, _g=granted: _g.append(
                   ["quality", iid, rm._plain({"tier": inst["lootQuality"]["tier"], "weights": inst["lootQuality"]["weights"]})]) or inst)}
        h.call(claim, [ctx, "1000:0", 1.0, UNDEF])
        qs = [g[2] for g in granted if g[0] == "quality"]
        plain = sum(g[2] for g in granted if g[0] == "plain")
        got = [{"kind": "item", "itemId": item_id, "count": 1, "qualities": qs + [None] * plain}] if granted else []
        model = h.model("weekly_boss_tables", {"phase": "claim", "item_id": item_id}, draws)
        mq = model["emitted"][0]["qualities"] if model["emitted"] else []
        model_norm = [{"kind": "item", "itemId": item_id, "count": 1, "qualities": mq if mq else [None]}] if model["emitted"] else []
        cases.append(({"rewards": got, "draws": log}, {"rewards": model_norm, "draws": model["draws"]},
                      {"phase": "claim", "item": item_id}))
    return cases


SOURCES = {
    "buddy_boss_drops": verify_buddy,
    "world_quest_class_loot": verify_world_quest,
    "hoard_boss_loot": verify_hoard,
    "treasure_vault_payouts": verify_vault,
    "rift_clear_pools": verify_rift,
    "rift_first_clear": verify_rift_first,
    "drowned_litany_chest": verify_litany,
    "weekly_boss_tables": verify_weekly,
}


def digest(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True).encode()).hexdigest()


def run(checkout: Path) -> dict:
    h = Harness(checkout)
    report = {}
    for source_id, fn in SOURCES.items():
        rnd = random.Random(f"verify:{source_id}")
        cases = fn(h, rnd)
        mismatches = [{"case": meta, "source": s, "model": m} for s, m, meta in cases if s != m]
        rewards = sum(len(s["rewards"]) for s, _m, _meta in cases)
        draws = sum(len(s["draws"]) for s, _m, _meta in cases)
        exercised = sorted(h.draw_ids.get(source_id, set()))
        declared = rm.all_draw_ids(rm.MODELS[source_id])
        # Negative control: a mutated model must disagree with the source.
        h.mutation = (source_id, *MUTATIONS[source_id])
        mutated = fn(h, random.Random(f"verify:{source_id}"))
        h.mutation = None
        caught = sum(1 for s, m, _ in mutated if s != m)
        report[source_id] = {
            "model_sha256": rc.sha256(json.dumps(rm.MODELS[source_id], sort_keys=True)),
            "scenarios_with_rewards": sum(1 for s, _m, _meta in cases if s["rewards"] and s["rewards"] != [None]),
            "draw_steps_declared": declared,
            "draw_steps_exercised": exercised,
            "negative_control": {"mutation": list(MUTATIONS[source_id]), "mismatches_detected": caught,
                                 "result": "PASS" if caught > 0 else "FAIL (the comparison could not see the change)"},
            "scenarios": len(cases),
            "rewards_compared": rewards,
            "draws_compared": draws,
            "mismatches": len(mismatches),
            "first_mismatches": mismatches[:3],
            "evidence_sha256": digest([[s, m] for s, m, _ in cases]),
            "result": "PASS" if not mismatches and cases and caught > 0 and set(declared) <= set(exercised) else "FAIL",
        }
    report["world_quest_class_loot"]["reference_goldens"] = goldens_world_quest(h)
    report["treasure_vault_payouts"]["allocation"] = verify_vault_allocation(h)
    report["treasure_vault_payouts"]["reference_goldens"] = goldens_vault(h)
    sub = {mid: rc.sha256(json.dumps(m, sort_keys=True)) for mid, m in sorted(rm.SUBMODELS.items())}
    ok = all(r["result"] == "PASS" for r in report.values()) and \
        all(g["pass"] for g in report["world_quest_class_loot"]["reference_goldens"]) and \
        all(g["pass"] for g in report["treasure_vault_payouts"]["reference_goldens"]) and \
        report["treasure_vault_payouts"]["allocation"]["pass"]
    return {
        "_comment": "Generated by tools/content/verify_reward_models.py: each reward-source execution model run against the real source function (static evaluator, a real rng.ts Rng with scripted next() values, side-effecting collaborators recorded) over the listed scenarios; rewards, owners, quantities and every draw (method, arguments, result) must match. Do not edit.",
        "commit": b.COMMIT,
        "rng_semantics": rm.RNG_SEMANTICS,
        "submodel_sha256": sub,
        "sources": report,
        "result": "PASS" if ok else "FAIL",
    }


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ref", required=True, type=Path)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args(argv[1:])
    doc = run(args.ref)
    text = json.dumps(doc, indent=1, sort_keys=True) + "\n"
    for sid, r in doc["sources"].items():
        print(f"{sid}: {r['result']} ({r['scenarios']} scenarios, {r['rewards_compared']} rewards, {r['draws_compared']} draws, {r['mismatches']} mismatches)")
    print("overall:", doc["result"])
    if args.check:
        same = OUT.exists() and OUT.read_text(encoding="utf-8") == text
        print("verification evidence is current" if same else f"stale: {OUT.relative_to(b.ROOT)}")
        return 0 if same and doc["result"] == "PASS" else 1
    OUT.write_text(text, encoding="utf-8")
    print("wrote", OUT.relative_to(b.ROOT))
    return 0 if doc["result"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
