"""Unit tests for tools/content/ts_eval.py (no reference checkout needed).

  python3 -m unittest tools/content/test_ts_eval.py -v
"""

from __future__ import annotations

import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ts_eval  # noqa: E402
from ts_eval import UNDEF, Interpreter, Unknown, Unsupported, num_to_str, to_json  # noqa: E402


def interp(files: dict[str, str]) -> Interpreter:
    return Interpreter(lambda p: files[p], lambda p: p in files)


def value(src: str, name: str = "X", extra: dict[str, str] | None = None):
    files = {"src/a.ts": src, **(extra or {})}
    return interp(files).module_for("src/a.ts").export(name)


class Literals(unittest.TestCase):
    def test_numbers_strings_and_types_are_erased(self):
        v = value("""
            // a comment
            export const X: Record<string, number> = {
              a: 1_000, b: 0.0875, c: 0x10, d: -2.5e-3, 'e': "q\\n", [`k${1 + 1}`]: true,
            } as const satisfies Record<string, unknown>;
        """)
        self.assertEqual(to_json(v), {"a": 1000, "b": 0.0875, "c": 16, "d": -0.0025, "e": "q\n", "k2": True})

    def test_constants_resolve_through_imports_and_reexports(self):
        v = value(
            "import { B as Bee } from './b';\nexport const X = { castId: Bee, list: [Bee, ...REST] };\nconst REST = ['r'];",
            extra={"src/b.ts": "export { B } from './c';", "src/c.ts": "export const B = 'brine_mend';"},
        )
        self.assertEqual(to_json(v), {"castId": "brine_mend", "list": ["brine_mend", "r"]})

    def test_origin_follows_imports(self):
        files = {
            "src/a.ts": "import { M } from './m';\nexport const X = { ...M };",
            "src/m.ts": "export { M } from './n';",
            "src/n.ts": "export const M = { a: 1 };",
        }
        i = interp(files)
        self.assertEqual(i.module_for("src/a.ts").origin("M"), ("src/n.ts", "M"))


class Functions(unittest.TestCase):
    def test_arrow_helpers_with_defaults_and_spreads(self):
        v = value("""
            const trashLoot = (c: number, rareId: string): LootEntry[] => [
              { copper: c, chance: 1 },
              { itemId: rareId, chance: 0.02 },
            ];
            function head(id: string, loot: readonly LootEntry[] = []): MobTemplate {
              return { id, hpBase: 150, loot };
            }
            export const X = [head('h1'), head('h2', trashLoot(160, 'mantle'))];
        """)
        self.assertEqual(to_json(v), [
            {"id": "h1", "hpBase": 150, "loot": []},
            {"id": "h2", "hpBase": 150, "loot": [{"copper": 160, "chance": 1}, {"itemId": "mantle", "chance": 0.02}]},
        ])

    def test_weighted_group_closure_with_mutation_matches_double_arithmetic(self):
        # The reference's weightedLootGroup, verbatim.
        v = value("""
            export function weightedLootGroup(
              rollGroup: string,
              entries: readonly (readonly [string, number])[],
              reserved: readonly LootEntry[] = [],
            ): LootEntry[] {
              const reservedChance = reserved.reduce((sum, entry) => sum + entry.chance, 0);
              const totalWeight = entries.reduce((sum, [, weight]) => sum + weight, 0);
              if (
                !entries.length ||
                !Number.isFinite(totalWeight) ||
                reservedChance >= 1 ||
                entries.some(([, weight]) => !Number.isFinite(weight) || weight <= 0)
              ) {
                throw new Error('Invalid guaranteed loot partition');
              }
              let cumulative = reservedChance;
              return [
                ...reserved.map((entry) => ({ ...entry, rollGroup })),
                ...entries.map(([itemId, weight], index) => {
                  const chance =
                    index === entries.length - 1
                      ? 1 - cumulative
                      : ((1 - reservedChance) * weight) / totalWeight;
                  cumulative += chance;
                  return { itemId, chance, rollGroup };
                }),
              ];
            }
            export const X = weightedLootGroup('g', [['a', 54], ['b', 26], ['c', 25]], [{ itemId: 'r', chance: 0.03 }]);
        """)
        r = 0.03
        total = 54 + 26 + 25
        a = (1 - r) * 54 / total
        b = (1 - r) * 26 / total
        c = 1 - (r + a + b)
        self.assertEqual(to_json(v), [
            {"itemId": "r", "chance": 0.03, "rollGroup": "g"},
            {"itemId": "a", "chance": a, "rollGroup": "g"},
            {"itemId": "b", "chance": b, "rollGroup": "g"},
            {"itemId": "c", "chance": c, "rollGroup": "g"},
        ])

    def test_a_throwing_source_is_unsupported_not_guessed(self):
        with self.assertRaises(Unsupported):
            value("function f(n: number) { if (n < 0) throw new Error('x'); return n; }\nexport const X = f(-1);")

    def test_loops_sets_maps_and_object_helpers(self):
        v = value("""
            const S = new Set<string>(['a', 'b']);
            const M = new Map<string, Array<number>>([['k', [1, 2]]]);
            const out: string[] = [];
            function build(): Record<string, number> {
              const r: Record<string, number> = {};
              for (const [k, xs] of M.entries()) { for (let i = 0; i < xs.length; i++) r[k + i] = xs[i] * 2; }
              return r;
            }
            export const X = {
              has: S.has('a'), size: S.size, built: build(),
              keys: Object.keys({ p: 1, q: 2 }).join('|'),
              entries: Object.fromEntries([['z', Math.max(1, 3)]]),
              frozen: Object.freeze([1, 2]).map((n) => n + 1).filter((n) => n > 2),
              ceil: Math.ceil(5000 * 1.4),
            };
        """)
        self.assertEqual(to_json(v), {
            "has": True, "size": 2, "built": {"k0": 2, "k1": 4}, "keys": "p|q",
            "entries": {"z": 3}, "frozen": [3], "ceil": 7000,
        })


class Unknowns(unittest.TestCase):
    def test_an_unknown_field_is_kept_in_place_with_its_location(self):
        v = value("export const X = { a: 1, b: somethingUndeclared, c: [1, /re/] };")
        out = to_json(v)
        self.assertEqual(out["a"], 1)
        self.assertIn("$unknown", out["b"])
        self.assertIn("somethingUndeclared", out["b"]["$unknown"])
        self.assertTrue(out["b"]["at"].startswith("src/a.ts:"))
        self.assertIn("$unknown", out["c"][1])

    def test_classes_this_and_packages_are_unknown(self):
        files = {"src/a.ts": "import * as THREE from 'three';\nclass K {}\nexport const X = { k: K, t: THREE, f: function () { return this; } };"}
        i = interp(files)
        out = to_json(i.module_for("src/a.ts").export("X"))
        self.assertIn("$unknown", out["k"])
        self.assertIn("$unknown", out["t"])
        self.assertEqual(out["f"]["$function"], "anonymous")

    def test_unknown_values_never_feed_arithmetic(self):
        with self.assertRaises(Unsupported):
            ts_eval.binop("+", Unknown("x", "here"), 1.0, "w")

    def test_unsupported_statement_only_fails_when_reached(self):
        v = value("""
            function pick(k: string) {
              if (k === 'a') return 1;
              do { k = k + 'x'; } while (k.length < 3);
              return 3;
            }
            export const X = pick('a');
        """)
        self.assertEqual(v, 1.0)
        with self.assertRaises(Unsupported):
            value("function pick(k: string) { do { return 3; } while (true); }\nexport const X = pick('a');")


class NumberFormatting(unittest.TestCase):
    def test_ecmascript_number_to_string(self):
        cases = {0.0875: "0.0875", 1e21: "1e+21", 1e-7: "1e-7", 0.00001: "0.00001", 123.0: "123",
                 -2.5: "-2.5", 1.5e-10: "1.5e-10", 100.0: "100", 0.1 + 0.2: "0.30000000000000004"}
        for x, want in cases.items():
            self.assertEqual(num_to_str(x), want, x)
        self.assertEqual(num_to_str(math.inf), "Infinity")

    def test_json_keeps_exact_doubles(self):
        self.assertEqual(to_json(0.1 + 0.2), 0.30000000000000004)
        self.assertEqual(to_json(3.0), 3)
        self.assertEqual(to_json({"a": UNDEF, "b": None}), {"b": None})


class ApproximatedMath(unittest.TestCase):
    """ECMAScript leaves Math.sin and the like (and `**`) to the engine: their
    results are tracked so none can pass as a verified registry value."""

    def setUp(self):
        self.trace = ts_eval.Trace()
        ts_eval.TRACE = self.trace

    def tearDown(self):
        ts_eval.TRACE = None

    def test_taint_flows_through_arithmetic_and_text_and_becomes_unknown(self):
        v = value("export const X = { a: Math.round(Math.sin(1) * 100) / 100, s: `p${Math.cos(0)}`, e: Math.floor(2.5) };")
        out = to_json(v)
        self.assertIn("$unknown", out["a"])
        self.assertTrue(out["a"]["sites"][0].endswith("Math.sin"))
        self.assertIn("$unknown", out["s"])
        self.assertEqual(out["e"], 2, "an exact operation stays a plain value")
        calls = {(op, approx) for (op, _w, _c, approx) in self.trace.calls}
        self.assertIn(("Math.sin", True), calls)
        self.assertIn(("Math.floor", False), calls)

    def test_decisions_on_approximated_values_are_recorded(self):
        value("function f() { const t = Math.acos(0.5); if (t < 1) return 1; return 2; }\nexport const X = f();")
        kinds = [d["kind"] for d in self.trace.decisions]
        self.assertIn("operator <", kinds)
        self.assertTrue(self.trace.decisions[0]["sites"][0].endswith("Math.acos"))

    def test_exponent_exactness_rule_and_javascript_nan(self):
        v = value("export const X = [2 ** 10, 2 ** 0.5, (-8) ** (1 / 3), Math.pow(3, 2)];")
        out = to_json(v)
        self.assertEqual(out[0], 1024, "an integer power below 2^53 is exact")
        self.assertIn("$unknown", out[1])
        self.assertEqual(out[2]["value"], {"$number": "NaN"}, "JavaScript: a negative base to a fractional power is NaN")
        self.assertEqual(out[3], 9)

    def test_perturbation_hook_changes_only_approximated_results(self):
        self.trace.perturb = lambda site, v: math.nextafter(v, math.inf)
        v = value("export const X = [Math.sin(1), Math.floor(1.5)];")
        self.assertEqual(float(v[0]), math.nextafter(math.sin(1), math.inf))
        self.assertEqual(v[1], 1.0)


class ClassesRegexAndCollections(unittest.TestCase):
    def test_a_class_with_fields_constructor_methods_and_this(self):
        v = value("""
            export class Counter {
              private n: number = 1;
              private observer: ((v: number) => void) | null = null;
              constructor(start: number) { this.n = start >>> 0; if (this.n === 0) this.n = 7; }
              next(): number { this.n += 2; return this.n; }
              twice(): number[] { return [this.next(), this.next()]; }
              static zero(): number { return 0; }
            }
            const c = new Counter(0);
            export const X = { a: c.twice(), b: Counter.zero(), imul: Math.imul(0xffffffff, 5), shr: -1 >>> 28 };
        """)
        self.assertEqual(to_json(v), {"a": [9, 11], "b": 0, "imul": -5, "shr": 15})

    def test_an_own_property_shadows_a_method(self):
        v = value("""
            export class R { next(): number { return 1; } twice(): number { return this.next() + this.next(); } }
            const r = new R();
            r.next = () => 5;
            export const X = r.twice();
        """)
        self.assertEqual(v, 10.0)

    def test_regex_keeps_javascript_semantics(self):
        v = value("""
            const re = /^(\\d{4})-(\\d{2})$/;
            export const X = { ok: re.exec('2026-08'), trailing: re.exec('2026-08\\n'), unicode: re.test('２０２６-08'),
                               swapped: 'a-b'.replace(/(a)-(b)/, '$2-$1') };
        """)
        out = to_json(v)
        self.assertEqual(out["ok"], ["2026-08", "2026", "08"])
        self.assertIsNone(out["trailing"], "JavaScript $ does not match before a final newline")
        self.assertFalse(out["unicode"], "JavaScript \\d is ASCII only")
        self.assertEqual(out["swapped"], "b-a")

    def test_splice_and_set_delete(self):
        v = value("""
            const pool = ['a', 'b', 'c', 'd'];
            const removed = pool.splice(1, 2);
            const s = new Set(['x', 'y']);
            s.delete('x');
            export const X = { pool, removed, size: s.size, has: s.has('y') };
        """)
        self.assertEqual(to_json(v), {"pool": ["a", "d"], "removed": ["b", "c"], "size": 1, "has": True})

    def test_override_replaces_a_collaborator_only(self):
        files = {"src/a.ts": "function side(x: number) { throw new Error('no'); }\nexport function f(n: number) { side(n); return n * 2; }"}
        i = interp(files)
        mod = i.module_for("src/a.ts")
        seen = []
        mod.override("side", ts_eval.Builtin("record", lambda x: seen.append(x)))
        self.assertEqual(i.call(mod.export("f"), [3.0], "t"), 6.0)
        self.assertEqual(seen, [3.0])


if __name__ == "__main__":
    unittest.main()


class RuntimePackConstructs(unittest.TestCase):
    """Constructs the runtime pack's reference functions need (build_runtime_pack.py)."""

    def test_optional_link_short_circuits_the_whole_chain(self):
        v = value("""
            const M: any = { a: undefined, f: { g: () => 7 } };
            export const X = [M.a?.b.c.length, M.f?.g(), M.f.h?.(), M.a?.[0].x, (M.f?.g)()];
        """)
        self.assertEqual(to_json(v), [None, 7, None, None, 7])

    def test_switch_matches_strictly_falls_through_and_takes_default(self):
        v = value("""
            function f(k: unknown): string[] {
              const out: string[] = [];
              switch (k) {
                case 1: out.push('one');
                case 2: out.push('two'); break;
                default: out.push('other');
                case 3: out.push('three');
              }
              return out;
            }
            export const X = [f(1), f(2), f(3), f('1'), f(9)];
        """)
        self.assertEqual(to_json(v), [["one", "two"], ["two"], ["three"], ["other", "three"], ["other", "three"]])

    def test_plain_record_prototype_test(self):
        v = value("""
            const plain = (v: unknown) => Object.getPrototypeOf(v) === Object.prototype;
            export const X = [plain({ a: 1 }), plain({})];
        """)
        self.assertEqual(to_json(v), [True, True])
        with self.assertRaises(Unsupported):
            to_json(value("export const X = Object.getPrototypeOf([1]);"))
