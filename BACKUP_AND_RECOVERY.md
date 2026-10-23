# Backup and recovery

Status: **no production data exists yet.** This is the plan that must be in place, and
tested, before the first public online release (Definition of Production Ready).

## What is backed up
- PostgreSQL: all durable player state (accounts, heroes, items, ledger).
- Not backed up: zone server memory (temporary by design), web builds (reproducible
  from Git and kept as CI artifacts or releases).

## Policy (targets)
| Item | Target |
|---|---|
| Method | Managed PostgreSQL continuous WAL archiving (PITR) + daily logical dump (`pg_dump -Fc`) to separate storage in another region |
| RPO | ≤ 5 min (PITR) |
| RTO | ≤ 1 h |
| Retention | PITR 7 days; daily dumps 30 days; monthly dumps 12 months |
| Encryption | At rest and in transit; backup storage credentials separate from app credentials |

## Restore drills (required, recorded)
Monthly, and before every major release:
1. Restore the latest dump into an isolated database.
2. Run `npm run migrate -- --check` (schema current) and the integrity checks: ledger sums
   equal balances, no orphaned items, every grant has its items.
3. Point a staging API at it and run the smoke tests.
4. Record date, backup used, duration and result in `docs/restore-drills.md`.

A backup that has not been restored in a drill is not counted as a backup.

## Recovery scenarios
- **Bad deploy:** roll back the app image (DEPLOYMENT.md). The schema is backward
  compatible.
- **Data corruption or bad migration:** freeze writes (maintenance mode) → PITR to just
  before the event into a new instance → verify → switch over → replay legitimate grants
  from logs using their idempotent grant IDs.
- **Zone server crash:** players reconnect; rewards already committed are safe; uncommitted
  grants are retried with the same ID.
- **Region loss:** restore the latest cross-region dump; RPO is up to 24 h unless PITR is
  replicated.
