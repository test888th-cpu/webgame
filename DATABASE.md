# Database

PostgreSQL 16.10. The API service is the only component with database credentials.

## Migrations [built]
- Plain SQL in `backend/migrations/NNNN_name.sql`, **forward only**.
- `npm run migrate` applies pending files in order. Each migration and its
  `schema_migrations` row commit in one transaction. An advisory lock serialises
  concurrent deployers.
- Applied files are SHA-256 checksummed. Editing a shipped migration fails the next run.
  A database containing a migration the build does not know is refused, which protects
  against rolling back to an older build on a newer schema.
- The API never migrates on start. `/readyz` returns 503 while migrations are pending.
- Changes must be backward compatible for one release (expand → migrate data → contract
  in a later release) so rollback of the app stays possible.
- Tests (`backend/test/migrate.test.ts`, run in CI against real PostgreSQL): fresh
  database, existing database plus new migration, failing migration rolls back, tampered
  checksum detected, schema constraints.

## Schema

| Migration | Tables | Status |
|---|---|---|
| 0001_accounts | `accounts` (uuid id, username with case-insensitive uniqueness, Argon2id hash only, status) | **built** |
| planned M3 | `sessions` (refresh token hash, rotation family, expiry), `player_profiles`, `heroes` | planned |
| planned M4 | `item_defs` (by content id), `items` (instances, owner, bound flag), `inventory_slots`, `currency_ledger`, `reward_grants`, `quest_progress`, `achievements` | planned |
| planned M5–6 | `housing_state`, `guilds`, `guild_members`, `parties` (if persisted), `mail`, `trades` | planned |

## Economy rules (M4)
- **Ledger:** `currency_ledger(id, account_id, hero_id, delta, reason, ref_id, created_at)`
  is append-only. The balance is a materialised column updated in the same transaction,
  with `CHECK (balance >= 0)`. A periodic integrity job verifies balance = sum(ledger).
- **Idempotent grants:** `reward_grants(grant_id uuid PRIMARY KEY, ...)`. The zone server
  creates `grant_id` when it decides the reward. Applying it is a single transaction: insert
  the grant row (a conflict means already applied, so return the previous result), insert
  items, write ledger rows. Crash and retry therefore cannot duplicate rewards.
- Trades and mail use the same pattern with two-sided ownership checks under
  `SELECT … FOR UPDATE`, locking rows in a consistent order.
- Valuable drop RNG runs on the zone server and is never seeded from client data.

## Persistence cadence
Position and HP: checkpoint every 60 s and on zone exit. Rewards and economy: immediately,
acknowledged to the client only after commit. Never every movement frame.

## Save and format versioning
Each JSON column (e.g. hero appearance, housing layout) carries a `v` field with tested
upgrade functions, like the SQL migrations.

## Retention and deletion
Account deletion: status `deleted`, credentials and personal fields scrubbed immediately,
rows removed after 30 days (keeps economy audit integrity with pseudonymous IDs). Security
logs are kept for 90 days. See BACKUP_AND_RECOVERY.md for backups.
