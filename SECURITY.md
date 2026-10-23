# Security

## Reporting
Report vulnerabilities privately through GitHub → **Security** → **Report a vulnerability**
(enable private vulnerability reporting in repository settings). Do not open public issues
for security problems.

## Runtime policy
- Production runs a **supported Node.js LTS** release. Before every runtime change, check
  the official release schedule (github.com/nodejs/Release) and security advisories
  (nodejs.org/en/blog/vulnerability), and record the result in ARCHITECTURE.md's decision log.
  - Current: **Node 24.22.1** (LTS "Krypton", security release of 2026-10-20, supported
    until 2028-04-30). Pinned in `.nvmrc`, the Dockerfile base image (`node:24.22.1-bookworm-slim`)
    and `engines`.
- Newer does not mean secure. Upgrades go through CI and staging before production.
- Lockfiles (`package-lock.json`) are committed; CI uses `npm ci`.
- **Emergency patch process:** advisory → branch with the bumped version → CI (tests,
  Trivy, audit) → staging deploy and smoke test → production → record in CHANGELOG. Target:
  critical issues patched within 48 h of a fix being available.

## Automated checks (all in GitHub Actions)
| Check | Where |
|---|---|
| Secret scanning of full history (gitleaks 8.30.1, checksum-verified) | security.yml |
| `npm audit --audit-level=high` for every npm package | security.yml, weekly too |
| Dependency review on PRs (fails on high) | security.yml |
| Container image scan (Trivy 0.76.1, fixable HIGH/CRITICAL fail) | ci.yml |
| SBOM (CycloneDX) for the API's production dependencies | ci.yml artifact |
| `.env.example` placeholder-only and no key files tracked | tools/ci/check-repo.sh |
Also enable, under **Settings → Advanced Security**, the **Dependency graph** (required by the dependency-review job), **Secret Protection with push protection** and **Dependabot alerts**
in repository settings (owner action, see DEPLOYMENT.md).

## Application rules
- **Never trust the client** for damage, currency, item ownership, loot, XP or quest
  completion. The client sends intent; servers decide (NETWORKING.md).
- **AuthN** [M3]: Argon2id password hashes (the DB constraint rejects anything else), short
  access tokens, rotating refresh tokens stored hashed, reuse detection revokes the family.
- **AuthZ** [M3]: every endpoint checks ownership of the hero or item. Zone→API calls use a
  separate service credential with its own narrow permissions.
- **Validation:** request bodies capped at 16 KiB **[built]**, schema-validated [M3].
  Zone frames are capped at 1 KiB from clients.
- **Rate limiting** per IP and per account on auth endpoints; per connection on the zone
  socket.
- **Anti-replay:** single-use join tickets with expiry; idempotency keys on grants.
- **Logging:** structured JSON (pino). Authorization and cookie headers are redacted
  **[built]**. A security log records failed logins, rate-limit hits and protocol violations.

## Infrastructure rules
- PostgreSQL and admin interfaces are on private networks only. docker-compose binds
  ports to 127.0.0.1 **[built]**.
- Containers run as non-root (`USER node`, checked in CI) **[built]**. One workload per
  container. Least-privilege database roles (app role cannot DDL; migration role can) [M3].
- Secrets come from the hosting platform's secret store or GitHub Environments. They
  never appear in Git, in browser code, or in the web export.
- Production deploys require green CI and security workflows (branch protection).

## Incident response (summary)
1. Contain: revoke credentials and tokens, scale down the affected service, enable
   maintenance mode.
2. Assess using security logs and the audit ledger.
3. Fix via the emergency patch process; restore from backup if data is corrupted
   (BACKUP_AND_RECOVERY.md).
4. Notify affected players as required; write a post-mortem in `docs/incidents/`.
