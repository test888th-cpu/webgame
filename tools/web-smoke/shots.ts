// Captures screenshots of key UI states from a web export, for visual review.
//   node shots.ts <export-dir> <out-dir> [steps...]
// Each step is "key:<Key>" (press), "hold:<Key>:<ms>", "wait:<ms>", "shot:<name>" or
// "walk:<x>:<y>" (walks the hero there, steering by the read-only probe).
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, resolve } from "node:path";
import type { AddressInfo } from "node:net";
import { chromium } from "playwright";

const [dir, out, ...steps] = process.argv.slice(2);
const root = resolve(dir ?? "../../build/web");
const types: Record<string, string> = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm" };
const server = createServer(async (req, res) => {
  const path = join(root, new URL(req.url ?? "/", "http://x").pathname.replace(/^\/$/, "/index.html"));
  try {
    res.writeHead(200, { "Content-Type": types[extname(path)] ?? "application/octet-stream" });
    res.end(await readFile(path));
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise<void>((done) => server.listen(0, "127.0.0.1", done));
const browser = await chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const booted = new Promise<void>((done) => page.on("console", (m) => m.text().startsWith("BOOT_OK") && done()));
await page.goto(`http://127.0.0.1:${(server.address() as AddressInfo).port}/index.html`);
await booted;
await page.locator("canvas").click();
await page.waitForTimeout(800);
for (const step of steps) {
  const [kind, a, b] = step.split(":");
  if (kind === "key") await page.keyboard.press(a!);
  if (kind === "hold") { await page.keyboard.down(a!); await page.waitForTimeout(Number(b)); await page.keyboard.up(a!); }
  if (kind === "wait") await page.waitForTimeout(Number(a));
  if (kind === "shot") await page.screenshot({ path: `${out}/${a}.png` });
  if (kind === "walk") await walk(Number(a), Number(b));
}

async function walk(x: number, y: number): Promise<void> {
  for (let i = 0; i < 100; i++) {
    const p = (await page.evaluate("window.ironboundProbe")) as { x: number; y: number } | undefined;
    if (!p) return;
    const dx = x - p.x;
    const dy = y - p.y;
    if (Math.abs(dx) < 6 && Math.abs(dy) < 4) return;
    const key = Math.abs(dx) >= 6 ? (dx > 0 ? "KeyD" : "KeyA") : dy > 0 ? "KeyS" : "KeyW";
    await page.keyboard.down(key);
    await page.waitForTimeout(Math.abs(dx) >= 6 ? Math.min(400, Math.abs(dx) * 4) : Math.min(300, Math.abs(dy) * 6));
    await page.keyboard.up(key);
    await page.waitForTimeout(120);
  }
}
await browser.close();
server.closeAllConnections();
server.close();
