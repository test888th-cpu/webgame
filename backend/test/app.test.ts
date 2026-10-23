import assert from "node:assert/strict";
import { test } from "node:test";
import { buildApp, type Readiness } from "../src/app.ts";

function appWith(readiness: Readiness) {
  return buildApp({ readiness, logLevel: "silent" });
}

test("healthz answers without touching dependencies", async () => {
  const app = appWith({ check: () => Promise.reject(new Error("must not be called")) });
  const res = await app.inject({ method: "GET", url: "/healthz" });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { status: "ok" });
  await app.close();
});

test("readyz is 200 when dependencies are ready", async () => {
  const app = appWith({ check: async () => ({ ok: true }) });
  const res = await app.inject({ method: "GET", url: "/readyz" });
  assert.equal(res.statusCode, 200);
  await app.close();
});

test("readyz is 503 with a reason when not ready", async () => {
  const app = appWith({ check: async () => ({ ok: false, reason: "1 pending migration(s)" }) });
  const res = await app.inject({ method: "GET", url: "/readyz" });
  assert.equal(res.statusCode, 503);
  assert.equal(res.json().reason, "1 pending migration(s)");
  await app.close();
});

test("oversized request bodies are rejected before parsing", async () => {
  const app = appWith({ check: async () => ({ ok: true }) });
  app.post("/echo", async (req) => req.body);
  const res = await app.inject({
    method: "POST",
    url: "/echo",
    headers: { "content-type": "application/json" },
    payload: JSON.stringify({ blob: "x".repeat(32 * 1024) }),
  });
  assert.equal(res.statusCode, 413);
  await app.close();
});
