import type { Pool } from "pg";
import type { Readiness } from "./app.ts";
import { migrationStatus } from "./db/migrate.ts";

/** Ready when the database answers and no migration is pending. */
export function databaseReadiness(pool: Pool, timeoutMs = 2000): Readiness {
  return {
    async check() {
      try {
        const status = await withTimeout(migrationStatus(pool), timeoutMs);
        if (status.pending.length > 0) {
          return { ok: false, reason: `${status.pending.length} pending migration(s)` };
        }
        return { ok: true };
      } catch (err) {
        return { ok: false, reason: `database: ${(err as Error).message}` };
      }
    },
  };
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(`timed out after ${ms} ms`)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}
