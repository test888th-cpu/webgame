// Serves a Godot web export over HTTP, opens it in headless Chromium, waits
// for the client's boot marker on the console, then holds real keys and checks
// that the character moved (via the read-only window.ironboundProbe).
//
//   node smoke.ts <export-dir> [--timeout-ms=60000] [--screenshot=path.png]
//
// Exits non-zero on timeout, uncaught page errors, failed requests, or if
// input does not move the character, so CI fails when the browser build does
// not actually start or cannot be played.
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";
import type { AddressInfo } from "node:net";
import { chromium } from "playwright";

const BOOT_MARKER = "BOOT_OK";

const MIME: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".json": "application/json",
};

const args = process.argv.slice(2);
const root = resolve(args.find((a) => !a.startsWith("--")) ?? "../../build/web");
const timeoutArg = args.find((a) => a.startsWith("--timeout-ms="));
const timeoutMs = timeoutArg ? Number(timeoutArg.split("=")[1]) : 60_000;
const screenshot = args.find((a) => a.startsWith("--screenshot="))?.split("=")[1];

interface Probe {
  x: number;
  y: number;
  facing: number;
}

const server = createServer(async (req, res) => {
  const urlPath = decodeURIComponent(new URL(req.url ?? "/", "http://x").pathname);
  const filePath = normalize(join(root, urlPath === "/" ? "index.html" : urlPath));
  if (!filePath.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  try {
    if (!(await stat(filePath)).isFile()) throw new Error("not a file");
    res.writeHead(200, { "Content-Type": MIME[extname(filePath)] ?? "application/octet-stream" });
    res.end(await readFile(filePath));
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise<void>((done) => server.listen(0, "127.0.0.1", done));
const { port } = server.address() as AddressInfo;

const problems: string[] = [];
const browser = await chromium.launch({
  // Headless CI machines have no GPU; SwiftShader provides WebGL 2.
  args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});
let bootLine = "";
try {
  const page = await browser.newPage();
  page.on("pageerror", (err) => problems.push(`page error: ${err.message}`));
  page.on("requestfailed", (r) => problems.push(`request failed: ${r.url()}`));
  page.on("response", (r) => {
    if (r.status() >= 400) problems.push(`HTTP ${r.status()}: ${r.url()}`);
  });
  const booted = new Promise<string>((done) => {
    page.on("console", (msg) => {
      const text = msg.text();
      if (msg.type() === "error") problems.push(`console error: ${text}`);
      if (text.startsWith(BOOT_MARKER)) done(text);
    });
  });
  const started = Date.now();
  await page.goto(`http://127.0.0.1:${port}/index.html`);
  let bootTimer: NodeJS.Timeout | undefined;
  bootLine = await Promise.race([
    booted,
    new Promise<string>((_, fail) => {
      bootTimer = setTimeout(
        () => fail(new Error(`no ${BOOT_MARKER} within ${timeoutMs} ms`)),
        timeoutMs,
      );
    }),
  ]).finally(() => clearTimeout(bootTimer)); // a pending timer would keep Node alive
  console.log(`booted in ${Date.now() - started} ms: ${bootLine}`);
  const canvas = page.locator("canvas");
  if ((await canvas.count()) === 0) throw new Error("no canvas element on the page");
  await canvas.first().click(); // focus the game like a player would

  const probe = async (): Promise<Probe> => {
    await page.waitForTimeout(250); // the probe refreshes every 100 ms
    const value = await page.evaluate(() => (window as { ironboundProbe?: Probe }).ironboundProbe);
    if (!value) throw new Error("window.ironboundProbe was never published");
    return value;
  };
  const hold = async (key: string, ms: number): Promise<void> => {
    await page.keyboard.down(key);
    await page.waitForTimeout(ms);
    await page.keyboard.up(key);
  };

  const start = await probe();
  await hold("ArrowRight", 800);
  const right = await probe();
  if (!(right.x > start.x + 20)) problems.push(`ArrowRight did not move right: ${start.x} -> ${right.x}`);
  await hold("KeyW", 500);
  const up = await probe();
  if (!(up.y < right.y - 5)) problems.push(`W did not move into the lane: ${right.y} -> ${up.y}`);
  await hold("ArrowLeft", 300);
  const left = await probe();
  if (left.facing !== -1) problems.push(`ArrowLeft did not turn the character (facing ${left.facing})`);
  console.log(
    `input: start (${start.x.toFixed(1)}, ${start.y.toFixed(1)}) -> right x=${right.x.toFixed(1)}` +
      ` -> up y=${up.y.toFixed(1)} -> left facing=${left.facing}`,
  );
  if (screenshot) await page.screenshot({ path: screenshot });
} catch (err) {
  problems.push(String(err));
} finally {
  await browser.close();
  server.close();
}

if (problems.length > 0) {
  for (const p of problems) console.error(p);
  process.exit(1);
}
