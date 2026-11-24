#!/usr/bin/env python3
"""Parity fixtures for the playable slice's runtime (client/tests/unit/test_rpg_runtime.gd).

  python3 tools/content/runtime_parity_fixtures.py --ref <checkout> [--check]

Runs the pinned reference's own functions with the static evaluator
(tools/content/ts_eval.py) and stores what they returned, so the Godot runtime is
tested against the source, not against a copy of its own logic:
* rng.ts `Rng`: the first draws of a seeded generator;
* loot/loot_roll.ts `rollLoot` (with loot/enemy_quality.ts): the corpse loot of a
  mob for a player of a class, on scripted next() values, and how many were drawn;
* combat/auto_attack.ts `meleeSwing`: one swing's outcome and damage on scripted
  next() values, with every collaborator the swing reads given its no-aura value.

Writes client/tests/fixtures/rpg_runtime_parity.json.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_reference_registries as b  # noqa: E402
import reference_content as rc  # noqa: E402
import ts_eval  # noqa: E402
from ts_eval import UNDEF, Builtin  # noqa: E402

ROOT = b.ROOT
OUT = ROOT / "client" / "tests" / "fixtures" / "rpg_runtime_parity.json"
TALENT_OUT = ROOT / "client" / "tests" / "fixtures" / "rpg_talent_parity.json"
SEEDS = [1, 42, 123456789, 4294967295, 0]
CLASSES = ["warrior", "rogue", "mage", "paladin"]


TWO32 = 4294967296


def draw(rnd: random.Random) -> int:
    """A draw as the integer k of k / 2^32: exact in JSON and in every float parser,
    and the same set of values mulberry32 produces."""
    return rnd.randrange(TWO32)


class Exhausted(Exception):
    pass


class Dealt(BaseException):
    """Stops a swing once its damage is dealt: what follows (set, talent, weapon and
    thorns procs) needs gear or talents the slice does not have and draws nothing
    without them."""


class Runner:
    def __init__(self, checkout: Path) -> None:
        b.verify_checkout(checkout)
        self.src = b.Source(checkout)
        self.ref = rc.Reference(self.src, b.tree(checkout))
        self.it = self.ref.interp
        ts_eval.TRACE = None
        self.Rng = self.ref.module_value("src/sim/rng.ts", "Rng")

    def fn(self, path: str, name: str):
        m = self.it.module_for(path)
        return m.export(name) if m.has_export(name) else m._get_local(name)

    def call(self, fn, args):
        return self.it.call(fn, args, "parity")

    def scripted_rng(self, draws: list[float], used: list):
        real = self.it.construct(self.Rng, [1.0], "parity")
        values = iter(draws)

        def nxt(*_):
            try:
                v = float(next(values)) / TWO32
            except StopIteration:
                raise Exhausted() from None
            used.append(v)
            return v
        real["next"] = Builtin("scripted next", nxt)
        return real

    # -- rng.ts
    def rng_cases(self) -> list[dict]:
        out = []
        for seed in SEEDS:
            r = self.it.construct(self.Rng, [float(seed)], "parity")
            values = [self.it.method(r, "next", [], "parity") for _ in range(12)]
            assert all(float(v * TWO32).is_integer() for v in values)
            out.append({"seed": seed, "next_u32": [int(v * TWO32) for v in values]})
        return out

    # -- rollLoot
    def loot_cases(self, mob_ids: list[str], per_mob: int) -> tuple[list[dict], dict]:
        roll = self.fn("src/sim/loot/loot_roll.ts", "rollLoot")
        rnd = random.Random(20261117)
        cases = []
        items_used: set = set()
        for mob_id in mob_ids:
            template = self.ref.mobs[mob_id]
            for n in range(per_mob):
                cls = CLASSES[n % len(CLASSES)]
                draws = [draw(rnd) for _ in range(64)]
                # Push some draws to the extremes so rare branches (quality) run.
                for i in range(0, 64, 7):
                    draws[i] = int(rnd.choice([0.0, 0.95, 0.999, 0.9999]) * TWO32)
                used: list = []
                rng = self.scripted_rng(draws, used)
                ctx = self._loot_ctx(rng)
                mob = {"id": 7.0, "templateId": mob_id, "kind": "mob", "ownerId": None,
                       "devSpawnOwnerId": UNDEF, "affixSpawned": False, "loot": None,
                       "lootable": False, "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}
                meta = {"entityId": 1.0, "cls": cls, "name": "P", "questLog": ts_eval.JSMap(),
                        "characterId": UNDEF}
                self.call(roll, [ctx, mob, meta])
                loot = ts_eval.to_json(mob["loot"]) if mob["loot"] is not None else {"copper": 0, "items": []}
                result_items = [{
                    "item_id": s["itemId"], "count": s["count"],
                    "quality": ({"tier": s["instance"]["lootQuality"]["tier"],
                                 "weights": s["instance"]["lootQuality"]["weights"]}
                                if s.get("instance", {}).get("lootQuality") else None),
                } for s in loot["items"]]
                items_used.update(i["item_id"] for i in result_items)
                for e in ts_eval.to_json(template["loot"]):
                    if e.get("itemId"):
                        items_used.add(e["itemId"])
                cases.append({"mob": mob_id, "class": cls, "draws_u32": draws[:len(used)],
                              "draws_used": len(used), "copper": loot["copper"], "items": result_items})
        items = {}
        for iid in sorted(items_used):
            it = ts_eval.to_json(self.ref.items[iid])
            items[iid] = {"kind": it["kind"], "slot": it.get("slot"), "quality": it.get("quality"),
                          "soulbound": bool(it.get("soulbound", False)),
                          "required_class": it.get("requiredClass")}
        return cases, items

    def _loot_ctx(self, rng) -> dict:
        noop = Builtin("noop", lambda *a: UNDEF)
        return {"rng": rng, "instances": [], "emit": noop, "countItem": Builtin("countItem", lambda *a: 0.0),
                "players": ts_eval.JSMap(), "entities": ts_eval.JSMap(), "time": 0.0,
                "partyOf": Builtin("partyOf", lambda *a: None)}

    def loot_entries(self, mob_id: str) -> list[dict]:
        out = []
        for e in ts_eval.to_json(self.ref.mobs[mob_id]["loot"]):
            out.append({"item": e.get("itemId"), "chance": e["chance"], "copper": e.get("copper"),
                        "roll_group": e.get("rollGroup"), "quest_id": e.get("questId"),
                        "normal_only": e.get("normalOnly", False)})
        return out

    # -- meleeSwing
    def swing_cases(self, n: int) -> list[dict]:
        swing = self.fn("src/sim/combat/auto_attack.ts", "meleeSwing")
        rnd = random.Random(42)
        cases = []
        for i in range(n):
            a_level = rnd.randint(1, 20)
            t_level = max(1, min(23, a_level + rnd.randint(-4, 4)))
            weapon = {"min": float(rnd.randint(1, 8)), "max": 0.0, "speed": rnd.choice([1.8, 2.0, 2.6, 2.9])}
            weapon["max"] = weapon["min"] + float(rnd.randint(1, 8))
            dagger = rnd.random() < 0.3
            if dagger:
                weapon["dagger"] = True
            attacker = self._entity("player", a_level, weapon)
            attacker["critChance"] = round(rnd.uniform(0.05, 0.2), 4)
            attacker["hitBonus"] = round(rnd.choice([0.0, 0.0, 0.01, 0.03]), 4)
            attacker["attackPower"] = float(rnd.randint(0, 200))
            target = self._entity("mob", t_level, {"min": 1.0, "max": 2.0, "speed": 2.0})
            target["stats"]["armor"] = float(rnd.randint(0, 600))
            hand = rnd.choice(["mainhand", "offhand", None])
            opts = {"autoAttack": hand is not None}
            if hand is not None:
                opts["autoAttackHand"] = hand
                opts["whiteDualWieldPenalty"] = rnd.random() < 0.5
            else:
                opts["weaponMult"] = rnd.choice([1.0, 0.5, 1.25])
                opts["normalizedInstant"] = rnd.random() < 0.5
                opts["cannotBeDodged"] = rnd.random() < 0.3
                opts["critBonus"] = rnd.choice([0.0, 0.05])
            bonus = float(rnd.choice([0, 0, 5, 12])) if hand is None else 0.0
            draws = [draw(rnd) for _ in range(3)]
            if i % 5 == 0:
                draws[0] = int(rnd.random() * 0.12 * TWO32)  # land in the avoidance band often
            used: list = []
            dealt: list = []
            ctx = self._swing_ctx(self.scripted_rng(draws, used), dealt)
            try:
                hit = self.call(swing, [ctx, attacker, target, bonus, None if hand else "Strike", opts])
            except Dealt:
                hit = True
            cases.append({
                "attacker": {"level": a_level, "weapon": weapon, "crit": attacker["critChance"],
                             "hit_bonus": attacker["hitBonus"], "attack_power": attacker["attackPower"]},
                "target": {"level": t_level, "armor": target["stats"]["armor"]},
                "opts": {"hand": hand or "", "white_dw_penalty": bool(opts.get("whiteDualWieldPenalty", False)),
                         "weapon_mult": opts.get("weaponMult", 1.0), "normalized": bool(opts.get("normalizedInstant", False)),
                         "cannot_be_dodged": bool(opts.get("cannotBeDodged", False)),
                         "crit_bonus": opts.get("critBonus", 0.0), "bonus": bonus},
                "draws_u32": draws[:len(used)],
                "landed": bool(hit),
                "dealt": dealt[0] if dealt else None,
            })
        kinds = {c["dealt"]["kind"] if c["dealt"] else "avoided" for c in cases}
        if not {"hit", "avoided"} <= kinds:
            raise SystemExit(f"swing fixtures exercise only {sorted(kinds)}: a stub field is wrong")
        return cases

    def _entity(self, kind: str, level: int, weapon: dict) -> dict:
        return {"id": 1.0 if kind == "player" else 2.0, "kind": kind, "level": float(level),
                "templateId": "rogue" if kind == "player" else "x", "weapon": weapon, "auras": [],
                "stats": {"str": 0.0, "agi": 0.0, "sta": 0.0, "int": 0.0, "spi": 0.0, "armor": 0.0},
                "dodgeChance": 0.05, "critChance": 0.05, "critDmgPhysBonus": 0.0, "hitBonus": 0.0, "hostile": kind == "mob", "ownerId": None,
                "attackPower": 0.0, "pos": {"x": 0.0, "y": 0.0, "z": 0.0}, "facing": 0.0,
                "blockChance": 0.0, "blockValue": 0.0, "hp": 1000.0, "maxHp": 1000.0, "dead": False,
                "overpowerUntil": -1.0, "shapeshift": None, "form": None}

    def _swing_ctx(self, rng, dealt: list) -> dict:
        noop = Builtin("noop", lambda *a: UNDEF)

        def deal(src, tgt, amount, *rest):
            dealt.append({"amount": amount, "crit": bool(rest[0]), "kind": rest[3]})
            raise Dealt()
        return {"rng": rng, "emit": noop, "enterCombat": noop, "time": 0.0,
                "effectiveAttackPower": Builtin("ap", lambda e, *a: e["attackPower"]),
                "effectiveArmor": Builtin("armor", lambda e, *a: e["stats"]["armor"]),
                "dealDamage": Builtin("dealDamage", deal),
                "players": ts_eval.JSMap(), "entities": ts_eval.JSMap()}


def talent_cases(r: Runner, pack: dict, per_class: int) -> list[dict]:
    """computeTalentModifiers and abilitiesKnownAt on random allocations."""
    talents_ts = "src/sim/content/talents.ts"
    classes_ts = "src/sim/content/classes.ts"
    rnd = random.Random(5150)
    cases = []
    for cls, tree in sorted(pack["talents"].items()):
        specs = [None] + [s["id"] for s in tree["specs"]]
        for n in range(per_class):
            level = rnd.choice([1, 4, 5, 7, 8, 11, 14, 17, 19, 20])
            spec = specs[n % len(specs)]
            rows = {}
            for row in tree["rows"]:
                if rnd.random() < 0.8:
                    rows[str(row["level"])] = rnd.choice(row["options"])["id"]
            alloc = {"spec": spec, "rows": rows}
            mods = r.call(r.fn(talents_ts, "computeTalentModifiers"),
                          [cls, ts_eval.from_json(alloc), float(level)])
            known = ts_eval.to_json(r.call(r.fn(classes_ts, "abilitiesKnownAt"), [cls, float(level), mods]))
            m = ts_eval.to_json(mods)
            cases.append({
                "class": cls, "level": level, "alloc": {"spec": spec or "", "rows": rows},
                "mods": {k: m[k] for k in ("spec", "stats", "global", "abilities", "grants", "selected")},
                "known": [{
                    "id": e["def"]["id"], "rank": e["rank"], "cost": e["cost"], "castTime": e["castTime"],
                    "cooldown": e["cooldown"], "effects": e["effects"], "charges": e.get("charges"),
                } for e in known],
            })
    return cases


def build(checkout: Path) -> dict[Path, str]:
    r = Runner(checkout)
    pack = json.loads((ROOT / "client" / "data" / "rpg" / "runtime_pack.json").read_text())
    trial = sorted(m for m, v in pack["trial_monsters"].items() if v["loot"])
    # Beyond the trial, mobs whose tables have roll groups and quality-eligible gear,
    # so every branch of the roller is compared (base MOBS only; no quest rows).
    extra = []
    for mob_id, tmpl in sorted(r.ref.mobs.items()):
        loot = ts_eval.to_json(tmpl.get("loot", []))
        if any(e.get("rollGroup") for e in loot) and not any(
                e.get("questId") or e.get("normalOnly") or set(e) - {"itemId", "chance", "copper", "rollGroup"}
                for e in loot):
            extra.append(mob_id)
    mobs = trial + extra[:12]
    loot_cases, items = r.loot_cases(mobs, 24)
    doc = {
        "_comment": "Generated by tools/content/runtime_parity_fixtures.py: the pinned reference's own Rng, rollLoot and meleeSwing evaluated statically; do not edit.",
        "source": b.source_block(r.src),
        "rng": r.rng_cases(),
        "loot": {"entries": {m: r.loot_entries(m) for m in mobs}, "items": items, "cases": loot_cases},
        "swing": r.swing_cases(400),
    }
    talent_doc = {
        "_comment": "Generated by tools/content/runtime_parity_fixtures.py: the pinned reference's computeTalentModifiers and abilitiesKnownAt on random allocations; do not edit.",
        "source": b.source_block(r.src),
        "cases": talent_cases(r, pack, 24),
    }
    return {OUT: json.dumps(doc, indent=1, sort_keys=True) + "\n",
            TALENT_OUT: json.dumps(talent_doc, indent=1, sort_keys=True) + "\n"}


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv[1:])
    outputs = build(args.ref)
    stale = [p for p, t in outputs.items() if not p.exists() or p.read_text(encoding="utf-8") != t]
    if args.check:
        for p in stale:
            print("stale:", p.relative_to(ROOT))
        if not stale:
            print("the parity fixtures are current")
        return 1 if stale else 0
    for p, t in outputs.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(t, encoding="utf-8")
        print("wrote", p.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
