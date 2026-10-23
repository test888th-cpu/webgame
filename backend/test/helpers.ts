// Test database helper. Each test file gets its own freshly created database
// so migration tests always start from an empty schema.
//
// TEST_DATABASE_URL must point at a server where the user may CREATE DATABASE.
// Without it, database tests are skipped locally but fail in CI (CI=true), so a
// misconfigured pipeline cannot pass by skipping them.
import { randomBytes } from "node:crypto";
import pg from "pg";

const adminUrl = process.env.TEST_DATABASE_URL;

export const dbSkip: string | false = adminUrl
  ? false
  : process.env.CI
    ? false
    : "TEST_DATABASE_URL not set";

export interface TestDatabase {
  pool: pg.Pool;
  drop(): Promise<void>;
}

export async function createTestDatabase(): Promise<TestDatabase> {
  if (!adminUrl) throw new Error("TEST_DATABASE_URL is required for database tests in CI");
  const name = `test_${randomBytes(6).toString("hex")}`;
  const admin = new pg.Client({ connectionString: adminUrl });
  await admin.connect();
  await admin.query(`CREATE DATABASE ${name}`);
  await admin.end();

  const url = new URL(adminUrl);
  url.pathname = `/${name}`;
  const pool = new pg.Pool({ connectionString: url.toString(), max: 4 });
  return {
    pool,
    async drop() {
      await pool.end();
      const cleanup = new pg.Client({ connectionString: adminUrl });
      await cleanup.connect();
      await cleanup.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
      await cleanup.end();
    },
  };
}
