# CLAUDE.md — working rules for this repository

## What this is

A browser-first online beat 'em up RPG. The Godot client is in `client/`, the account and
persistence API is in `backend/`, and the authoritative zone servers will be a headless
export of `client/` in Milestone 3. Read `ARCHITECTURE.md` before changing structure.

The owner works **only through cloud sessions and GitHub**. Every check must therefore run
in GitHub Actions, and instructions for the owner must be browser-dashboard steps.

## Pinned versions (change only deliberately, see CONTRIBUTING.md "Upgrades")

- Godot **4.7.2-stable** (`tools/ci/install-godot.sh`, with SHA-512 hashes), Compatibility renderer
- gdtoolkit **4.5.0** (gdlint/gdformat)
- Node.js **24.22.1** (`.nvmrc`, Dockerfile, `engines`), TypeScript 5.9.3, Fastify 5.12.7, pg 8.23.1
- PostgreSQL **16.10**, Playwright 1.56.1, Trivy 0.76.1, gitleaks 8.30.1
- GitHub Actions pinned by commit SHA, with the tag in a comment

## Boundaries (do not blur them)

| Layer | Location | Rule |
|---|---|---|
| Combat/movement rules | `client/sim/` | Pure static functions or RefCounted. No nodes, Input, rendering or randomness without an injected seed. Shared with the server. |
| Presentation | `client/scenes/` | Reads input and renders. Calls `sim/`; never re-implements rules. |
| Networking | `client/net/` (M3) | Message schemas and versioning only. |
| Persistence/economy | `backend/` | The only writer of durable player state. |
| Content | `client/data/` (M2) | Data-driven definitions (`.tres`/JSON); adding a monster or item must not need code changes. |

## Coding rules

- GDScript: static typing everywhere; `gdformat` and `gdlint` must pass (line length 100).
- TypeScript runs with Node's type stripping: use only erasable syntax (no enums or
  namespaces) and `.ts` import extensions.
- Match the surrounding style. Comments explain *why*.
- Never trust the client for damage, currency, items, loot, XP or quest state.
- SQL: parameterised queries only. Schema changes only through a new file in
  `backend/migrations/`; never edit an applied migration (checksums enforce this).

## Testing (run what CI runs before pushing)

```bash
cd client && gdformat --check . && gdlint .
godot --headless --path client --import
godot --headless --path client --script res://tests/TestRunner.gd   # exit code != 0 on failure
cd backend && npm run typecheck && TEST_DATABASE_URL=... npm test
```

- Godot tests live in `client/tests/unit/test_*.gd` and extend `TestCase`. Any engine or
  script error logged during a test fails it.
- New gameplay rules get unit tests in `sim/`. New scenes get a scene test. New endpoints
  get authorisation and validation tests. New migrations get a fresh-DB test and an
  existing-DB test.
- The browser smoke test (`tools/web-smoke/smoke.ts`) reads `window.ironboundProbe`. Keep
  that probe read-only and free of anything a player cannot already see.
- Report results honestly. Never claim a check passed unless you ran it and saw it pass.

## Security requirements

- No secrets in Git or browser code. `.env.example` holds placeholders only (CI enforces this).
- The browser never talks to PostgreSQL. Database ports are never public.
- All client input is validated server-side with size and rate limits.
- Passwords use Argon2id only.
- Containers run as non-root. Keep dependencies minimal and pin them.
- Read `SECURITY.md` before touching auth, sessions, economy or deployment.

## Workflow

- Work on a feature branch and open a PR. CI must be green before merging. No force-pushes to `main`.
- Keep PRs small and limited to one milestone task.
- Update `CHANGELOG.md` and any affected doc in the same PR.
