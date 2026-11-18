# Building the reference registries

`tools/content/build_reference_registries.py` regenerates every reference-derived
registry from World of ClaudeCraft at the pinned commit,
`d2b91e0884cb269422c28d0b42d2a30a01de130a`.

## Run it

```bash
git clone https://github.com/levy-street/world-of-claudecraft /tmp/woc
```

```bash
git -C /tmp/woc checkout d2b91e0884cb269422c28d0b42d2a30a01de130a
```

```bash
python3 tools/content/build_reference_registries.py --ref /tmp/woc
```

```bash
python3 tools/content/build_reference_registries.py --ref /tmp/woc --check
```

```bash
python3 tools/content/render_monster_matrix.py
```

- **Writing.** Without `--check`, the builder writes all 12 outputs.
- **Checking.** `--check` rebuilds in memory, lists any stale output and exits 1;
  otherwise it prints `all 12 registries are current`.
- **The matrix** (`render_monster_matrix.py`) reads the committed monster registry,
  so run it after the builder. It also accepts `--check`.
- **CI** runs the evaluator's unit tests and the matrix check; neither needs the
  reference.

## Guarantees

- **Commit verification.**
  - The build stops unless the checkout's `HEAD` is the pinned commit.
  - Every input is read with `git show <commit>:<path>`, never from the working tree.
  - Changing the pin needs the owner's approval
    ([REFERENCE_FIDELITY_RULE.md](REFERENCE_FIDELITY_RULE.md)).
- **Nothing from the reference is executed.**
  - Class, talent, slot and quality rules are matched as text.
  - Content tables are evaluated by `tools/content/ts_eval.py`. It is a static
    evaluator for the data subset of TypeScript:
    - literals and operators;
    - constants, across imports;
    - spreads;
    - functions built from these;
    - standard Array, Object, Math, Set and Map built-ins.

    It has no file, network or process access of its own, reads source text only
    through the builder, and has no `Math.random`.
  - Anything outside that subset is recorded as `{"$unknown": reason, "at":
    "file:line"}`, never guessed.
- **Load-time statements.**
  - Top-level statements that change a table when a module loads run in source
    order, as an ES module's body does. Examples are the per-class Tideglass
    Reflections, `Object.assign(ITEMS, buildHeroicVariants(...))` and the buddy
    drop index.
  - **If any of them cannot be evaluated, the build fails.** A skipped mutation could
    silently change a registry.
- **Input hashes.** Every output records the SHA-256 of every source file read.
- **The manifest** (`data/registry/reference_registry_manifest.json`) records:
  - all inputs, and every output's hash and count;
  - the evaluator report:
    - modules evaluated;
    - each top-level effect and its result;
    - unparsed statements;
    - implementation-approximated `Math` calls (`sin`, `acos` and the like, used by
      layout code only; never by a loot chance or copper value);
  - a text-scan cross-check that lists records defined in source but never
    registered.
- **Determinism.** JSON is written with sorted keys; numbers are the source's exact
  doubles, written in their shortest round-trip form.
- **No silent skips.**
  - Every source field is kept (`source_fields`).
  - A field outside the `MobTemplate` interface is listed.
  - A loot entry field outside `LootEntry` is listed (`fields_not_in_loot_entry`).
  - A cited rule whose source text disappears fails the build.

## Approximated Math safeguard

- **Tracing.** The evaluator traces every Math call and `**` operation: its site, its
  function, and whether it is exact or implementation-approximated.
- **Approximated results are tagged.** A tagged value that reaches a registry is
  written as UNKNOWN, never as a value.
- **Decisions must stay confined.** A decision (comparison, branch, key) on a tagged
  value fails the build, unless it is inside a reviewed binding in
  `reference_content.CONFINED_BINDINGS`. That review is re-checked on every build:
  - the binding's source references must be exactly the recorded ones;
  - it must share no object with any registry.
- **The manifest** (`math_audit`) records:
  - every site, with its file, line, function, operation and calls;
  - the result for each site;
  - the totals for exact and approximated operations.

**Empirical evidence.** This tool rebuilds every registry with each site's results
moved one ulp up, one ulp down and grossly, and compares the registries byte for byte.
It takes a few minutes and writes `data/registry/math_perturbation_audit.json`:

```bash
python3 tools/content/audit_math_perturbation.py --ref /tmp/woc
```

```bash
python3 tools/content/audit_math_perturbation.py --ref /tmp/woc --check
```

## Reward-source execution models

- **The models** live in `tools/content/reward_models.py`, as data plus a small
  runner. The builder stores each one in `reference_loot_tables.json`, with its
  citations re-located and its source data evaluated.
- **The verifier** runs every model against the real source function, with the same
  scripted draws, plus the reference's test goldens and negative controls. It takes
  about 30 seconds and writes `data/registry/reward_model_verification.json`:

```bash
python3 tools/content/verify_reward_models.py --ref /tmp/woc
```

```bash
python3 tools/content/verify_reward_models.py --ref /tmp/woc --check
```

- **After changing a model,** run the builder first, then the verifier: the evidence
  records each model's hash.
- **CI** runs `tools/content/test_reward_models.py` on the stored models, with the
  reference goldens. It needs no checkout.

## Runtime pack and parity fixtures (the playable slice)

Two more generators read the same pinned checkout. Neither changes a registry.

```bash
python3 tools/content/build_runtime_pack.py --ref /tmp/woc --check
```

```bash
python3 tools/content/runtime_parity_fixtures.py --ref /tmp/woc --check
```

- `build_runtime_pack.py` writes `client/data/rpg/runtime_pack.json`. The registries
  stay outside the Godot project, so the game reads this pack instead. It evaluates
  `abilitiesKnownAt`, `computeTalentModifiers` and `requiredLevelFor` on the inputs
  the game uses.
- `runtime_parity_fixtures.py` writes `client/tests/fixtures/rpg_runtime_parity.json`
  from the reference's own `Rng`, `rollLoot` and `meleeSwing`.
- Run both after the registries. CI runs the Godot side (`test_rpg_runtime.gd`) on the
  committed files. See `docs/PLAYABLE_SLICE.md`.

## Outputs

| Output | Content |
|---|---|
| `client/data/rpg_reference.json` | classes and specs |
| `client/data/rpg/talent_structure.json` | talent rows |
| `client/data/rpg/equipment_slots.json` | 13 slots and the class equipment rules |
| `client/data/rpg/quality.json` | quality tiers, per-copy quality |
| `data/registry/reference_items.json` | 2,263 items |
| `data/registry/legacy_items.json` | the game's 305 items, labelled LEGACY |
| `data/registry/reference_monsters.json` | 379 monsters |
| `data/registry/reference_loot_tables.json` | 400 tables, rollers, reward sources, coverage |
| `data/registry/reference_loot_entries.json` | 1,190 entries |
| `data/registry/loot_selection.json` | adoption status and legacy loot hashes |
| `data/registry/id_collisions.json` | the namespace collision audit |
| `data/registry/reference_registry_manifest.json` | the source manifest and the approximated-Math audit |
| `data/registry/math_perturbation_audit.json` | perturbation evidence (written by `audit_math_perturbation.py`, not the builder) |
| `data/registry/reward_model_verification.json` | reward-model evidence (written by `verify_reward_models.py`, not the builder) |

Large registries live in `data/registry/`, outside the Godot project, so they are not
shipped in the web build.

## Changing the builder

- **Tests.** Add evaluator tests to `tools/content/test_ts_eval.py`.
- **Error handling.** A construct the evaluator does not model must raise
  `Unsupported`, never return a guess.
- **Regeneration.** After a change, run the builder, then `--check` twice in separate
  processes to confirm the output is deterministic. Then run the matrix and the
  Godot tests.
