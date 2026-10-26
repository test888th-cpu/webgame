# The Iron Legacy

A browser-first, story-driven beat 'em up RPG built with **Godot 4.7.2 (GDScript)**,
single player first and built so it can go online later (formerly *Ironbound Streets*).
All characters, places, art, audio and code are original to this project.

> **Status: Milestone 2 — playable single-player loop.** Title screen, character status
> and equipment screens (six gear slots, item rarity and levels), hero creation
> (three heroes, Mika, Oren and Riku, each with their own stats and skills; name your hero), six areas
> of rising level (home base with a shop, a quest giver and a training dummy; streets of
> enemy waves; two boss zones), ten enemy types including elites and two-phase bosses
> that get tougher and smarter with the area level, street weapons held in hand (pick
> up, wear out, dropped when knocked down), combos, guard, dodge, loot, money, XP and levels, equipment, quests, local saves, pause and
> inventory. All rules run in a deterministic 60 Hz simulation (`client/sim/`) that the
> future zone server will reuse; all content is validated JSON (`client/data/`).
> Characters are LPC pixel-art sprites; the streets are HD-2D scenery assembled from
> pieces painted by the project owner, both from the cloud asset pipeline ([docs/ASSETS.md](docs/ASSETS.md)). There is **no online play
> or game server yet**. See [docs/ROADMAP.md](docs/ROADMAP.md).

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
| Talk / shop (near an NPC) | E or U | B / Circle | TALK |
| Hotbar: attack, skills, food (slots 1–7) | 1–7 | RT + X/Y/A/B for skills, RT + RB for slot 7 | Tap the slot |
| Eat (quick heal) | H or Q | RB / R1 | EAT |
| Pause, inventory, quests, save | Esc or P | Start | II |
| Switch menu tabs | Q / E | LB / RB | Tap the tab |

### See test results

GitHub → **Actions** → **CI**. Each run has these jobs:

| Job | What it proves |
|---|---|
| Repository policy | Required docs exist; `.env.example` has placeholders only; no key files tracked |
| GDScript lint and format | `gdlint` and `gdformat --check` (gdtoolkit 4.5.0) |
| Godot project opens and tests pass | Headless import with no script errors; 190 unit/scene tests (combat, skills, heroes, AI, encounters, loot, quests, shop, saves, game scenes, interface, effects) |
| Web export and browser smoke test | Release web export; headless Chromium loads it, waits for boot, **plays it with real keys: title → new game → hero creation (pick a hero, type a name) → combo on the dummy → a skill from the hotbar → pick up a weapon → pause → next area → a real fight**; uploads the build, a manifest with SHA-256s and a screenshot |
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
  data/            Content as data: moves, enemies, items, areas, quests, shops, progression
  scenes/          Presentation: world, fighter views, UI
  scripts/core/    Autoloads: BuildInfo, InputSetup
  tests/           Headless test runner and tests (excluded from exports)
backend/           Account/persistence API (Node.js + TypeScript + Fastify + PostgreSQL)
  migrations/      Forward-only, checksummed SQL migrations
infra/             docker-compose for the local/dev stack
tools/ci/          Pinned, hash-verified Godot installer; repository policy checks
tools/web-smoke/   Headless-Chromium browser smoke test (Playwright)
tools/assets/      Asset pipeline: LPC builder, UnitForge importer, SpriteFrames, validator
art/               Asset sources: LPC recipes, UnitForge uploads
client/assets/     Imported art + manifest.json (what the game loads)
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
[CHANGELOG](CHANGELOG.md) · [Blueprint](docs/BLUEPRINT.md) · [Story bible](docs/STORY_BIBLE.md) ·
[Repository audit](docs/REPOSITORY_AUDIT.md) ·
[Roadmap and backlog](docs/ROADMAP.md) · [Interface](docs/UI.md) · [CLAUDE.md](CLAUDE.md)

## Licence

Code is MIT licensed ([LICENSE](LICENSE)). The placeholder visuals are drawn from
primitives in the scenes and are covered by the same licence. Licensing for future
art and audio is recorded per asset (see CONTRIBUTING.md).
