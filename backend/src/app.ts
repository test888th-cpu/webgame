// HTTP application. Built from injected dependencies so tests can run it with
// Fastify's in-process `inject` and a fake or real database.
import Fastify, { type FastifyInstance } from "fastify";

export interface Readiness {
  /** Resolves when the database is reachable and its schema is current. */
  check(): Promise<{ ok: true } | { ok: false; reason: string }>;
}

export interface AppOptions {
  readiness: Readiness;
  logLevel?: string;
}

// API payloads are small JSON documents. Anything larger is rejected before
// it is parsed.
const BODY_LIMIT_BYTES = 16 * 1024;

export function buildApp({ readiness, logLevel = "info" }: AppOptions): FastifyInstance {
  const app = Fastify({
    logger: { level: logLevel, redact: ["req.headers.authorization", "req.headers.cookie"] },
    bodyLimit: BODY_LIMIT_BYTES,
    requestIdHeader: false,
  });

  // Liveness: the process is up and the event loop answers.
  app.get("/healthz", async () => ({ status: "ok" }));

  // Readiness: dependencies are usable, so the load balancer may route here.
  app.get("/readyz", async (_req, reply) => {
    const result = await readiness.check();
    if (!result.ok) {
      return reply.code(503).send({ status: "unavailable", reason: result.reason });
    }
    return { status: "ready" };
  });

  return app;
}
