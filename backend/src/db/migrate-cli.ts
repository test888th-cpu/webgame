// `npm run migrate` — applies pending migrations. Run as a deploy step before
// new API or zone server versions start; the API itself never migrates.
//   npm run migrate            apply pending migrations
//   npm run migrate -- --check exit 1 if any migration is pending
import pg from "pg";
import { label, migrate, migrationStatus } from "./migrate.ts";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("DATABASE_URL is required");
  process.exit(2);
}

const pool = new pg.Pool({ connectionString: databaseUrl, max: 1 });
try {
  if (process.argv.includes("--check")) {
    const { applied, pending } = await migrationStatus(pool);
    console.log(`applied: ${applied.length}, pending: ${pending.length}`);
    for (const m of pending) console.log(`pending ${label(m)}`);
    process.exitCode = pending.length > 0 ? 1 : 0;
  } else {
    const done = await migrate(pool);
    console.log(done.length ? `applied ${done.join(", ")}` : "schema is up to date");
  }
} catch (err) {
  console.error((err as Error).message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
