# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer.

## [Unreleased]

### Added — Milestone 2, part 1: combat core
- Deterministic 60 Hz combat simulation in `client/sim/` (`CombatRules`, `Fighter`,
  `FighterInput`, `CombatEvent`): light combo jab → cross → body hook (chains only
  after a connected hit), guard-breaking haymaker, dodge with invulnerability frames,
  guard (front only, chip damage, energy drain, guard break), hit stun, knockback,
  knockdown, KO, simultaneous-hit trades.
- Attacks are data: `client/data/moves.json`, loaded and validated by `MoveLibrary`.
- Test zone: training dummy with HP bar and respawn, HUD HP/energy bars, floating
  damage numbers, keyboard/gamepad/touch bindings for light, heavy, dodge, guard.
- 23 new tests (39 total). Browser smoke test now lands a combo on the dummy.
- `pages.yml` plays the live HTTPS site after each deploy.

### Changed
- CI jobs have time limits. The smoke test installs only Chromium's headless shell
  (cached) instead of `--with-deps`, which spent 10+ minutes on a slow apt mirror.
- Light hits push less (jab 4 px, cross 6 px) so the combo stays in reach.

## [0.1.0] — 2026-10-23 (Milestone 1 / Task 001)

### Added — Milestone 1 / Task 001: cloud build pipeline
- Godot 4.7.2 client project (`client/`): test street, placeholder hero with lane movement
  (keyboard, gamepad, touch), bounded camera, HUD.
- Shared rules module `client/sim/LaneMovement.gd` with unit tests.
- Headless Godot test runner that fails tests on any engine or script error.
- Release web export preset (single-threaded, Compatibility renderer).
- Browser smoke test (Playwright + Chromium) that verifies boot and keyboard movement.
- API service skeleton (Node 24.22.1, Fastify): `/healthz`, `/readyz`, checksummed
  forward-only migration runner, migration `0001_accounts`.
- CI: repository policy, gdlint/gdformat, Godot tests, web export + smoke test + artifact
  with SHA-256 manifest, backend tests on PostgreSQL 16, image build + Trivy + SBOM.
  Security: gitleaks, npm audit, dependency review. Gated GitHub Pages deployment of the
  CI artifact.
- Documentation set and repository audit.

### Security
- Runtime image drops npm, npx and corepack (multi-stage build). Their bundled
  `brace-expansion` 5.0.9 and `undici` 6.28.0 had HIGH CVEs (CVE-2026-102276,
  CVE-2026-102278, CVE-2026-19534) reported by Trivy; the API never runs them.
