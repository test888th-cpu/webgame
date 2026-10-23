# Roadmap, backlog and risks

Each milestone is its own series of small PRs, with acceptance criteria verified by CI or a
recorded manual test. Nothing is marked done without evidence.

## Milestone 1 — Audit, architecture, pipeline (this PR, = Task 001)

Acceptance criteria:
- [x] Repository and reference repos audited (docs/REPOSITORY_AUDIT.md)
- [x] Architecture, risks and backlog documented
- [x] Godot 4.7.2 project with a controllable placeholder hero, camera and HUD
- [x] CI: lint, headless tests, web export, browser smoke test with real input, artifact upload
- [x] CI: backend typecheck, tests, migrations on real PostgreSQL, image scan, SBOM, secret scan
- [ ] CI green on GitHub (verified in the PR)
- [ ] Owner enables Pages; the game loads over HTTPS (DEPLOYMENT.md)

## Milestone 2 — Browser vertical slice (single player, server-ready rules)

Progress: part 1 (combat core) done — criteria 2 (except the special) and 6 are met,
5 is partly met (HP/energy bars, damage numbers, all input methods; no pause menu).

Acceptance criteria:
1. One original street zone with props, depth lanes and a camera that follows the hero.
2. One hero with light ×3 combo, heavy, dodge (with i-frames), guard and one special.
   Hitboxes, hurtboxes, hit stun, knockback and recovery are data-driven (`client/data/moves`).
3. Three enemy types and one elite with telegraphed attacks, spacing, and a cap on how many
   attack at once.
4. Loot drops and pickups. These are marked *offline only*; authority moves to the server in M4.
5. HUD: HP, energy, damage numbers. Pause menu. Keyboard, gamepad and touch.
6. All rules in `client/sim/` with unit tests (combo windows, i-frames, damage, knockback),
   driven by a fixed 60 Hz step that is independent of render FPS.
7. Browser smoke test plays a scripted fight to a kill.
8. Performance scene: 1 hero + 12 enemies + effects reaches ≥ 60 fps on the reference
   desktop in Chrome and Edge (measured, recorded in PERFORMANCE.md).
9. Web download ≤ 12 MB compressed for the first screen.

## Milestone 3 — Online foundation
Auth (Argon2id, sessions, refresh rotation, rate limits) · hero persistence · zone server
(headless export) with WSS + binary protocol v1 · join tickets · authoritative movement with
client prediction and reconciliation · shared test zone · reconnect grace period · first
measurement of zone server memory and CPU per player.

## Milestone 4 — Farming and progression
Inventory, equipment, currency ledger, idempotent grants, drop tables (server RNG),
XP and levels, quests, save versioning tests, crash-replay test (no duplicate rewards).

## Milestone 5 — City and world
City hub with data-driven NPCs, shops, crafting and upgrades, storage, housing (ownership
separate from shared visuals), multiple zones, teleports, capacity limits and queues.

## Milestone 6 — Multiplayer content
Parties, shared farming, elites on schedules, instanced bosses (multi-phase), dungeons,
guilds and mail (Redis decision record if needed).

## Milestone 7 — Production hardening
Metrics, logs, alerts, backups with tested restores, rollback drills, security testing,
incident runbooks.

## Milestone 8 — Scale validation
Load tests at 50 / 100 / 500 / 1,000 / 4,000 connections, idle and in combat, with
thresholds defined before each run. Publish the capacity actually measured.

## Prioritised backlog (next items)
1. M1: CI green, enable Pages, verify on HTTPS (owner action)
2. M2: fixed-step simulation loop + `sim/` combat core with tests
3. M2: data-driven moves/enemies (`client/data/`) + content validation test
4. M2: placeholder art pipeline (sprite sheets from source files; replaceable)
5. M2: enemy AI with attack tokens; elite variant
6. M2: browser performance scene + recorded measurements
7. M3: auth endpoints + migrations 0002 (sessions) with authorisation tests

## Risks and blockers

| ID | Risk | Mitigation |
|---|---|---|
| R1 | Godot headless memory/CPU per zone instance unknown | Measure in M3 before committing to process-per-instance |
| R2 | Web export is ~39.5 MB uncompressed wasm, so first load is slow | Gzip or Brotli on the host (~10 MB); later evaluate a custom template that strips unused modules |
| R3 | Single-threaded export: no threads in the browser | Keep the client light; the server does the simulation |
| R4 | Headless CI uses SwiftShader, so it proves correctness, not performance | Manual and recorded measurements on real hardware (PERFORMANCE.md) |
| R5 | GitHub Pages: no custom headers or server | Fine for the single-threaded client. The backend needs separate hosting (DEPLOYMENT.md) |
| R6 | Backend hosting not chosen yet (owner decision, cost) | Decide before M3. Options are in DEPLOYMENT.md |
| R7 | Art and audio production capacity | Asset pipeline that allows swaps without code changes; placeholder art is clearly marked |
| R8 | Docker image build could not be exercised in the development sandbox (no registry access from containers) | Built and scanned in CI instead |
