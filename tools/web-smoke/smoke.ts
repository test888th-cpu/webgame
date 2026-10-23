// Serves a Godot web export over HTTP, opens it in headless Chromium, waits
// for the client's boot marker on the console, then holds real keys and checks
// that the game plays: title -> new game, movement, a combo on the training
// dummy, the pause menu, walking to the next area and fighting its enemies
// (all via the read-only window.ironboundProbe).
//
//   node smoke.ts <export-dir> [--timeout-ms=60000] [--screenshot=path.png]
//   node smoke.ts --url=https://example.org/game/ [...]   (a deployed build)
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
const remoteUrl = args.find((a) => a.startsWith("--url="))?.slice("--url=".length);

interface Foe {
  x: number;
  y: number;
  hp: number;
  kind: string;
}

interface Probe {
  scene: string;
  area: string;
  menu: string;
  x: number;
  y: number;
  facing: number;
  hp: number;
  energy: number;
  state: string;
  level: number;
  money: number;
  fighting: boolean;
  enemies: Foe[];
  hits: number;
  hero_hits: number;
}

// A deployed build is tested where it is; an export directory is served
// locally over HTTP.
let server: ReturnType<typeof createServer> | undefined;
let pageUrl = remoteUrl;
if (!pageUrl) {
  server = createServer(async (req, res) => {
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
  const listening = server;
  await new Promise<void>((done) => listening.listen(0, "127.0.0.1", done));
  const { port } = listening.address() as AddressInfo;
  pageUrl = `http://127.0.0.1:${port}/index.html`;
}

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
  await page.goto(pageUrl);
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
    await page.waitForTimeout(120); // the probe refreshes every 100 ms
    const value = await page.evaluate(() => (window as { ironboundProbe?: Probe }).ironboundProbe);
    if (!value) throw new Error("window.ironboundProbe was never published");
    return value;
  };
  const hold = async (key: string, ms: number): Promise<void> => {
    await page.keyboard.down(key);
    await page.waitForTimeout(ms);
    await page.keyboard.up(key);
  };

  const waitFor = async (what: string, ok: (p: Probe) => boolean, ms: number): Promise<Probe> => {
    const until = Date.now() + ms;
    let last = await probe();
    while (!ok(last)) {
      if (Date.now() > until) throw new Error(`timed out waiting for ${what}: ${JSON.stringify(last)}`);
      last = await probe();
    }
    return last;
  };
  const nearest = (p: Probe): Foe | undefined =>
    [...p.enemies].sort((a, b) => Math.abs(a.x - p.x) - Math.abs(b.x - p.x))[0];
  // Steps toward `foe` (lane first, then along the street) and swings once.
  // The jab reaches 12 px of lane depth and about 40 px along the street.
  const engage = async (p: Probe, foe: Foe, swing = true): Promise<void> => {
    if (Math.abs(p.y - foe.y) > 8) {
      await hold(p.y > foe.y ? "ArrowUp" : "ArrowDown", 60);
    } else if (Math.abs(foe.x - p.x) > 34) {
      await hold(foe.x > p.x ? "ArrowRight" : "ArrowLeft", 80);
    } else {
      if ((foe.x > p.x ? 1 : -1) !== p.facing) await hold(foe.x > p.x ? "ArrowRight" : "ArrowLeft", 30);
      if (swing) await page.keyboard.press("KeyJ");
    }
  };

  // Title screen -> New game (focused by default).
  await waitFor("the title screen", (p) => p.scene === "title", 10_000);
  await page.keyboard.press("Enter");
  const start = await waitFor("the game to start", (p) => p.scene === "game", 15_000);
  console.log(`new game: ${start.area}, level ${start.level}, ${start.enemies.length} enemy`);

  // Movement.
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

  // Training dummy: line up, then a three-hit combo.
  let near = await probe();
  for (let i = 0; i < 60; i++) {
    const dummy = nearest(near);
    if (!dummy || (Math.abs(near.y - dummy.y) <= 3 && dummy.x - near.x <= 26 && near.facing === 1)) break;
    // Line up without swinging, so the combo below starts on a fresh dummy.
    if (Math.abs(near.y - dummy.y) > 3) await hold(near.y > dummy.y ? "ArrowUp" : "ArrowDown", 50);
    else await hold("ArrowRight", 70);
    near = await probe();
  }
  const before = near;
  for (let i = 0; i < 3; i++) {
    await page.keyboard.press("KeyJ");
    await page.waitForTimeout(140);
  }
  const fought = await probe();
  const dummyBefore = nearest(before)?.hp ?? 0;
  const dummyAfter = nearest(fought)?.hp ?? 0;
  if (!(fought.hero_hits > before.hero_hits && dummyAfter < dummyBefore)) {
    problems.push(
      `attacks did not land on the dummy: hits ${before.hero_hits} -> ${fought.hero_hits}, ` +
        `dummy hp ${dummyBefore} -> ${dummyAfter}`,
    );
  }
  console.log(`combat: ${fought.hero_hits - before.hero_hits} hit(s), dummy hp ${dummyBefore} -> ${dummyAfter}`);

  // Pause menu opens and closes.
  await page.keyboard.press("Escape");
  await waitFor("the pause menu", (p) => p.menu === "pause", 3_000);
  await page.keyboard.press("Escape");
  await waitFor("the pause menu to close", (p) => p.menu === "", 3_000);
  console.log("pause menu: opened and closed");

  // Walk east into the next area, then into its first fight.
  await page.keyboard.down("ArrowRight");
  const street = await waitFor("the next area", (p) => p.area !== start.area, 20_000);
  const fight = await waitFor("an encounter", (p) => p.fighting && p.enemies.length > 0, 20_000);
  await page.keyboard.up("ArrowRight");
  console.log(`travelled: ${start.area} -> ${street.area}; encounter with ${fight.enemies.map((e) => e.kind).join(", ")}`);
  let state = fight;
  const until = Date.now() + 30_000;
  while (state.hero_hits - fight.hero_hits < 3 && Date.now() < until && state.hp > 0) {
    const foe = nearest(state);
    if (foe) await engage(state, foe);
    state = await probe();
  }
  if (state.hero_hits - fight.hero_hits < 3) {
    problems.push(`could not land 3 hits on real enemies (landed ${state.hero_hits - fight.hero_hits}, hero hp ${state.hp})`);
  }
  console.log(
    `street fight: ${state.hero_hits - fight.hero_hits} hero hit(s), hero hp ${state.hp}, ` +
      `total hits ${state.hits - fight.hits}, coins ${state.money}`,
  );
  if (screenshot) await page.screenshot({ path: screenshot });
} catch (err) {
  problems.push(String(err));
} finally {
  await browser.close();
  server?.close();
}

if (problems.length > 0) {
  for (const p of problems) console.error(p);
  process.exit(1);
}
