import assert from "node:assert/strict";
import { cp, mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { loadMigrations, migrate, migrationStatus, MIGRATIONS_DIR } from "../src/db/migrate.ts";
import { databaseReadiness } from "../src/readiness.ts";
import { createTestDatabase, dbSkip } from "./helpers.ts";

async function copyOfMigrations(): Promise<string> {
  const dir = await mkdtemp(join(tmpdir(), "migrations-"));
  await cp(MIGRATIONS_DIR, dir, { recursive: true });
  return dir;
}

test("migration files are well formed and numbered without gaps", async () => {
  const migrations = await loadMigrations();
  assert.ok(migrations.length > 0);
  migrations.forEach((m, i) => assert.equal(m.version, i + 1, `${m.name} is number ${i + 1}`));
});

test("fresh database: applies every migration, then is up to date", { skip: dbSkip }, async () => {
  const db = await createTestDatabase();
  try {
    const all = (await loadMigrations()).map((m) => m.version);
    assert.deepEqual(await migrate(db.pool), all);
    assert.deepEqual(await migrate(db.pool), [], "second run applies nothing");
    const status = await migrationStatus(db.pool);
    assert.deepEqual(status.applied, all);
    assert.equal(status.pending.length, 0);
    assert.deepEqual(await databaseReadiness(db.pool).check(), { ok: true });
  } finally {
    await db.drop();
  }
});

test("existing database: only new migrations are applied", { skip: dbSkip }, async () => {
  const db = await createTestDatabase();
  const dir = await copyOfMigrations();
  try {
    await migrate(db.pool, dir);
    await writeFile(join(dir, "9000_later_change.sql"), "CREATE TABLE later_change (id int);");
    const readiness = await migrationStatus(db.pool, dir);
    assert.deepEqual(readiness.pending.map((m) => m.version), [9000]);
    assert.deepEqual(await migrate(db.pool, dir), [9000]);
  } finally {
    await db.drop();
  }
});

test("a failing migration leaves no partial schema", { skip: dbSkip }, async () => {
  const db = await createTestDatabase();
  const dir = await copyOfMigrations();
  try {
    await migrate(db.pool, dir);
    await writeFile(
      join(dir, "9000_broken.sql"),
      "CREATE TABLE half_done (id int); SELECT * FROM table_that_does_not_exist;",
    );
    await assert.rejects(migrate(db.pool, dir), /9000_broken failed/);
    const { rows } = await db.pool.query("SELECT to_regclass('half_done') AS t");
    assert.equal(rows[0].t, null, "table from the failed migration was rolled back");
    assert.deepEqual((await migrationStatus(db.pool, dir)).pending.map((m) => m.version), [9000]);
  } finally {
    await db.drop();
  }
});

test("editing an applied migration is detected", { skip: dbSkip }, async () => {
  const db = await createTestDatabase();
  const dir = await copyOfMigrations();
  try {
    await migrate(db.pool, dir);
    await writeFile(join(dir, "0001_accounts.sql"), "-- rewritten\n");
    await assert.rejects(migrate(db.pool, dir), /was modified after it was applied/);
  } finally {
    await db.drop();
  }
});

test("accounts schema enforces its invariants", { skip: dbSkip }, async () => {
  const db = await createTestDatabase();
  const hash = "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA";
  try {
    await migrate(db.pool);
    await db.pool.query("INSERT INTO accounts (username, password_hash) VALUES ($1, $2)", [
      "River_Fox",
      hash,
    ]);
    await assert.rejects(
      db.pool.query("INSERT INTO accounts (username, password_hash) VALUES ($1, $2)", [
        "river_fox",
        hash,
      ]),
      /accounts_username_lower_key/,
      "usernames are unique regardless of case",
    );
    await assert.rejects(
      db.pool.query("INSERT INTO accounts (username, password_hash) VALUES ($1, $2)", [
        "plain",
        "hunter2",
      ]),
      /check constraint/,
      "only argon2id hashes are accepted",
    );
  } finally {
    await db.drop();
  }
});
