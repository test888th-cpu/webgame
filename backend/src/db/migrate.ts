// Forward-only SQL migration runner.
//
// Migrations are plain files named NNNN_description.sql in backend/migrations.
// Each one runs in its own transaction together with its schema_migrations row,
// so a failed migration leaves no partial schema behind. A session-level
// advisory lock serialises concurrent deploys. Applied files are checksummed:
// editing a migration after it shipped is an error, not a silent drift.
import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import type { Pool, PoolClient } from "pg";

export const MIGRATIONS_DIR = new URL("../../migrations", import.meta.url).pathname;

// Arbitrary constant shared by every process that runs migrations.
const ADVISORY_LOCK_KEY = 4_205_001;

export interface Migration {
  version: number;
  name: string;
  sql: string;
  checksum: string;
}

export interface MigrationStatus {
  applied: number[];
  pending: Migration[];
}

export async function loadMigrations(dir = MIGRATIONS_DIR): Promise<Migration[]> {
  const files = (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort();
  const migrations: Migration[] = [];
  for (const file of files) {
    const match = /^(\d{4})_([a-z0-9_]+)\.sql$/.exec(file);
    if (!match) throw new Error(`migration file name must look like 0001_name.sql: ${file}`);
    const sql = await readFile(join(dir, file), "utf8");
    const version = Number(match[1]);
    if (migrations.some((m) => m.version === version)) {
      throw new Error(`duplicate migration version ${version}`);
    }
    migrations.push({ version, name: match[2]!, sql, checksum: sha256(sql) });
  }
  return migrations;
}

export async function migrationStatus(pool: Pool, dir = MIGRATIONS_DIR): Promise<MigrationStatus> {
  const client = await pool.connect();
  try {
    return await verify(client, await loadMigrations(dir));
  } finally {
    client.release();
  }
}

/** Applies every pending migration in version order and returns the versions applied. */
export async function migrate(pool: Pool, dir = MIGRATIONS_DIR): Promise<number[]> {
  const migrations = await loadMigrations(dir);
  const client = await pool.connect();
  try {
    await client.query("SELECT pg_advisory_lock($1)", [ADVISORY_LOCK_KEY]);
    try {
      const { pending } = await verify(client, migrations);
      const done: number[] = [];
      for (const m of pending) {
        await client.query("BEGIN");
        try {
          await client.query(m.sql);
          await client.query(
            "INSERT INTO schema_migrations (version, name, checksum) VALUES ($1, $2, $3)",
            [m.version, m.name, m.checksum],
          );
          await client.query("COMMIT");
        } catch (err) {
          await client.query("ROLLBACK");
          throw new Error(`migration ${label(m)} failed: ${(err as Error).message}`, {
            cause: err,
          });
        }
        done.push(m.version);
      }
      return done;
    } finally {
      await client.query("SELECT pg_advisory_unlock($1)", [ADVISORY_LOCK_KEY]);
    }
  } finally {
    client.release();
  }
}

async function verify(client: PoolClient, migrations: Migration[]): Promise<MigrationStatus> {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version    integer     PRIMARY KEY,
      name       text        NOT NULL,
      checksum   text        NOT NULL,
      applied_at timestamptz NOT NULL DEFAULT now()
    )`);
  const { rows } = await client.query<{ version: number; name: string; checksum: string }>(
    "SELECT version, name, checksum FROM schema_migrations ORDER BY version",
  );
  const known = new Map(migrations.map((m) => [m.version, m]));
  for (const row of rows) {
    const m = known.get(row.version);
    if (!m) {
      throw new Error(
        `database has migration ${label(row)} that this build does not know; ` +
          "refusing to run an older build against a newer schema",
      );
    }
    if (m.checksum !== row.checksum) {
      throw new Error(`migration ${label(row)} was modified after it was applied`);
    }
  }
  const applied = rows.map((r) => r.version);
  const appliedSet = new Set(applied);
  return { applied, pending: migrations.filter((m) => !appliedSet.has(m.version)) };
}

/** The migration's file stem, e.g. "0001_accounts". */
export function label(m: { version: number; name: string }): string {
  return `${String(m.version).padStart(4, "0")}_${m.name}`;
}

function sha256(text: string): string {
  return createHash("sha256").update(text).digest("hex");
}
