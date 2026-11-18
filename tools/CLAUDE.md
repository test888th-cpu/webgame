# tools/: build, asset and CI tooling

- `tools/assets/`: the asset pipeline (kit pieces, sprite sheets, manifest). Every asset
  keeps its source, licence and provenance in the manifest; CI checks them
  (`docs/ASSETS.md`). Never mark an UNVERIFIED asset as VERIFIED.
- `tools/ci/`: CI scripts. `check-repo.sh` (required files, no secrets) and
  `install-godot.sh` (the pinned Godot with SHA-512 hashes). Pinned versions change only
  deliberately (CLAUDE.md, CONTRIBUTING.md "Upgrades").
- `tools/web-smoke/`: the browser smoke test. It reads `window.ironboundProbe`, which
  must stay read-only and show nothing a player cannot already see.
- Tools never import game rules into another language: they run Godot headless or read
  `client/data/*.json`.
- `tools/content/`: the reference registries (docs/REFERENCE_REGISTRY_BUILDER.md).
  `ts_eval.py` evaluates World of ClaudeCraft's content tables as data, so that
  helper-built records and load-time additions are read exactly. It implements no game
  rule and never runs reference code. An unsupported construct is recorded as UNKNOWN,
  never guessed. Keep `test_ts_eval.py` green.
