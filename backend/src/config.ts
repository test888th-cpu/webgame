// Runtime configuration, read once from environment variables.
// Secrets (DATABASE_URL) come from the environment or a secrets manager and are
// never committed; see .env.example for the variable names.

export interface Config {
  host: string;
  port: number;
  databaseUrl: string;
  logLevel: string;
  shutdownGraceMs: number;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const databaseUrl = env.DATABASE_URL;
  if (!databaseUrl) throw new Error("DATABASE_URL is required");
  return {
    host: env.API_HOST ?? "0.0.0.0",
    port: parsePort(env.API_PORT ?? "8080"),
    databaseUrl,
    logLevel: env.LOG_LEVEL ?? "info",
    shutdownGraceMs: Number(env.SHUTDOWN_GRACE_MS ?? "10000"),
  };
}

function parsePort(value: string): number {
  const port = Number(value);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error(`API_PORT must be an integer between 1 and 65535, got "${value}"`);
  }
  return port;
}
