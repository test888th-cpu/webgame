# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer.

## [Unreleased]

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
