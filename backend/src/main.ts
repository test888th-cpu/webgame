import pg from "pg";
import { buildApp } from "./app.ts";
import { loadConfig } from "./config.ts";
import { databaseReadiness } from "./readiness.ts";

const config = loadConfig();
const pool = new pg.Pool({ connectionString: config.databaseUrl, max: 10 });
const app = buildApp({ readiness: databaseReadiness(pool), logLevel: config.logLevel });

let shuttingDown = false;
async function shutdown(signal: string): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;
  app.log.info({ signal }, "shutting down");
  // Stop accepting connections, let in-flight requests finish, then exit even
  // if something hangs past the grace period.
  const force = setTimeout(() => process.exit(1), config.shutdownGraceMs);
  force.unref();
  await app.close();
  await pool.end();
}
process.on("SIGTERM", () => void shutdown("SIGTERM"));
process.on("SIGINT", () => void shutdown("SIGINT"));

await app.listen({ host: config.host, port: config.port });
