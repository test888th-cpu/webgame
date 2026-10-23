# Deployment

## Environments
| | Client | Backend | Database |
|---|---|---|---|
| dev | CI artifact / compose | docker compose | compose PostgreSQL |
| staging | separate static site | separate host, staging secrets | separate instance |
| production | GitHub Pages (or CDN) | host with persistent WebSockets (decide before M3) | managed PostgreSQL with PITR |

Release artifacts are immutable. `pages.yml` deploys the **exact** `web-build` artifact of
a green CI run on `main` and verifies its SHA-256 manifest. Nothing is rebuilt during
deployment.

## Owner steps to enable public hosting of the client (browser only)
1. GitHub → repo **Settings → Pages** → *Build and deployment* → Source: **GitHub Actions**.
2. **Settings → Secrets and variables → Actions → Variables** → New repository variable
   `PAGES_DEPLOY_ENABLED` = `true`.
3. **Settings → Environments → github-pages** → *Deployment branches*: `main` only
   (created automatically after step 1).
4. Merge a PR to `main`. When CI finishes, *Deploy web client (GitHub Pages)* runs and
   prints the URL (normally `https://<owner>.github.io/<repo>/`). Private repositories
   need a paid GitHub plan for Pages.
5. Verify the game loads over HTTPS in Chrome or Edge and the hero moves. Record the result
   in CHANGELOG.

Recommended at the same time: **Settings → Code security** → enable Dependabot alerts,
secret scanning and push protection, and private vulnerability reporting. **Settings →
Branches** → protect `main`: require PRs and the CI + Security checks.

## Rollback (client)
Actions → *Deploy web client (GitHub Pages)* → **Run workflow** → enter the run ID of an
earlier green CI run. That run's artifact is redeployed. Artifacts are kept for 30 days;
tag releases (M7) to keep them longer.

## Backend (not deployed yet)
The API and zone servers need a host with long-lived WebSockets, private networking to
PostgreSQL, and secret management. Candidates to decide before M3 (owner decision,
affects cost): a container platform (e.g. Fly.io, Render, Railway) or a VM with Docker,
plus managed PostgreSQL with PITR. GitHub Pages cannot host them.

Deploy order: run migrations (`npm run migrate`) → roll out the API (readiness checks
`/readyz`) → drain and replace zone servers. Rollback: redeploy the previous image tag.
Migrations are backward compatible for one release, so this is always safe (DATABASE.md).

## Release record (per release)
Commit, Godot version, Node version, image digest, SBOM artifact, CI and security run
links, smoke-test result, deployment URL, verification notes → CHANGELOG.md.
