# Ironbound Streets *(working title)*

A browser-first, persistent online beat 'em up RPG built with **Godot 4.7.2 (GDScript)**.
All characters, places, art, audio and code are original to this project.

> **Status: Milestone 2 in progress — combat core.** A playable test street: one
> placeholder hero against a training dummy, with a light combo (jab → cross → body
> hook), a guard-breaking heavy, a dodge with invulnerability frames, a guard,
> hit stun, knockback, knockdown, HP/energy bars and damage numbers. Combat rules are
> data-driven (`client/data/moves.json`) and run in a deterministic 60 Hz simulation
> that the future zone server will reuse. There are **no enemies with AI, no loot,
> no online play and no game server yet**. See [docs/ROADMAP.md](docs/ROADMAP.md).

| | Version |
|---|---|
| Engine | Godot **4.7.2-stable**, standard build, Compatibility renderer |
| Web export | Release, **single-threaded**, no GDExtension, no PWA |
| API runtime | Node.js **24.22.1** (LTS "Krypton") |
| Database | PostgreSQL **16.10** |

## Everything runs in the cloud

You do not need any local tools. All building and testing happens in GitHub Actions.

### Play the latest build

- **Hosted (after deployment is enabled):** `https://<owner>.github.io/<repo>/`. The
  link appears on the repository's **Environments → github-pages** page once
  [DEPLOYMENT.md](DEPLOYMENT.md) step 1 is done. Until then nothing is deployed publicly.
- **From a CI run (always available):** GitHub → **Actions** → **CI** → pick a run →
  **Artifacts** → download **web-build**. The zip holds the complete export. Browsers block
  WebAssembly from `file://`, so it has to be served over http(s). Upload it to any static
  host such as GitHub Pages, Cloudflare Pages, Netlify or itch.io (HTML5 project, upload
  the zip). No special headers are required.

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Move | Arrows / WASD | Left stick, d-pad | On-screen pad (left) |
| Light attack (combo) | J or Z | X / Square | Red button |
| Heavy attack (breaks guard, costs energy) | K or X | Y / Triangle | Orange button |
| Dodge (invulnerable, costs energy) | Space or L | A / Cross | Blue button |
| Guard (hold; drains energy) | Shift or I | LB / L1 | Green button |

### See test results

GitHub → **Actions** → **CI**. Each run has these jobs:

| Job | What it proves |
|---|---|
| Repository policy | Required docs exist; `.env.example` has placeholders only; no key files tracked |
| GDScript lint and format | `gdlint` and `gdformat --check` (gdtoolkit 4.5.0) |
| Godot project opens and tests pass | Headless import with no script errors; 39 unit/scene tests (combat rules, content validation, zone) |
| Web export and browser smoke test | Release web export; headless Chromium loads it, waits for boot, **holds real keys, checks the hero moves, then walks to the dummy and lands a combo**; uploads the build, a manifest with SHA-256s and a screenshot |
| Backend typecheck, tests and migrations | `tsc`, API + migration tests against a real PostgreSQL, fresh-DB migration, API reaches `/readyz` |
| Backend image build, container scan and SBOM | Docker image builds, runs as non-root on the pinned Node, Trivy scan, CycloneDX SBOM |

The **Security** workflow runs gitleaks over the full history, `npm audit`, and
dependency review on pull requests. It also runs weekly.

### Make a change from the browser

1. Ask Claude Code on the web (or edit on github.com) on a **feature branch**.
2. Open a pull request. CI runs automatically and must be green before merging.
3. Merging to `main` produces a new `web-build` artifact, which is deployed if Pages
   deployment is enabled ([DEPLOYMENT.md](DEPLOYMENT.md)).

## Repository layout

```
client/            Godot project (the browser client; later also the headless zone server)
  sim/             Pure game rules shared by client and server (no nodes, no rendering)
  data/            Content as data (moves.json: every attack's timing, damage, reach)
  scenes/          Presentation: world, fighter views, UI
  scripts/core/    Autoloads: BuildInfo, InputSetup
  tests/           Headless test runner and tests (excluded from exports)
backend/           Account/persistence API (Node.js + TypeScript + Fastify + PostgreSQL)
  migrations/      Forward-only, checksummed SQL migrations
infra/             docker-compose for the local/dev stack
tools/ci/          Pinned, hash-verified Godot installer; repository policy checks
tools/web-smoke/   Headless-Chromium browser smoke test (Playwright)
docs/              Repository audit, roadmap and backlog
```

## Running locally (optional)

For contributors who do have tools. These are the same commands CI runs.

```bash
tools/ci/install-godot.sh ~/.godot-bin --with-web-templates
~/.godot-bin/godot --headless --path client --import
~/.godot-bin/godot --headless --path client --script res://tests/TestRunner.gd
~/.godot-bin/godot --headless --path client --export-release "Web" ../build/web/index.html
(cd tools/web-smoke && npm ci && npx playwright install chromium && node smoke.ts ../../build/web)

cd backend && npm ci && npm run typecheck
TEST_DATABASE_URL=postgres://user:pass@localhost:5432/postgres npm test
```

## Documentation

[ARCHITECTURE](ARCHITECTURE.md) · [GAME_DESIGN](GAME_DESIGN.md) · [NETWORKING](NETWORKING.md) ·
[DATABASE](DATABASE.md) · [SECURITY](SECURITY.md) · [WEB_EXPORT](WEB_EXPORT.md) ·
[PERFORMANCE](PERFORMANCE.md) · [DEPLOYMENT](DEPLOYMENT.md) ·
[BACKUP_AND_RECOVERY](BACKUP_AND_RECOVERY.md) · [CONTRIBUTING](CONTRIBUTING.md) ·
[CHANGELOG](CHANGELOG.md) · [Repository audit](docs/REPOSITORY_AUDIT.md) ·
[Roadmap and backlog](docs/ROADMAP.md) · [CLAUDE.md](CLAUDE.md)

## Licence

Code is MIT licensed ([LICENSE](LICENSE)). The placeholder visuals are drawn from
primitives in the scenes and are covered by the same licence. Licensing for future
art and audio is recorded per asset (see CONTRIBUTING.md).
