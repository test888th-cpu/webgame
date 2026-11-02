// Reproducible UI screenshots of a web export at four landscape window sizes, with the
// input each is used with, for review and as the UI regression baseline's
// pictures (the layout itself is checked by client/tests/ui/UiAuditRun.gd):
//
//   node ui-shots.ts <export-dir> <out-dir>
//
//   1280x720  desktop: mouse and keyboard
//   640x360   phone held sideways: touch (and keyboard for the menus)
//   844x390   phone held sideways, 19.5:9: touch (and keyboard for the menus)
//   960x440   phone held sideways, 20:9: touch (and keyboard for the menus)
//
// At each size: the title, a new game's HUD, every screen (Character, Bag,
// Skills, Quests, Map, pause menu), and input that must work there: a mouse
// click on the HUD's Bag button (desktop), a touch on the pause button
// (phones), and the screen keys. Screens are read back through the read-only
// window.ironboundProbe. Writes <out>/<size>/NN_<name>.png and
// <out>/summary.json, and exits non-zero on a page error or input that did
// not reach the game. It never judges layout: that is the Godot audit's job.
import { createServer } from "node:http";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";
import type { AddressInfo } from "node:net";
import { chromium } from "playwright";

const BOOT_MARKER = "BOOT_OK";
// The game's base viewport (project.godot); the window shows it scaled by
// min(width / 640, height / 360) from the top-left corner ("expand").
const BASE = { w: 640, h: 360 };
// Where the HUD's buttons sit in base pixels (client/scenes/ui/Hud.gd and
// TouchControls.gd). If these move, the click/tap checks fail and say so.
const HUD_BAG = (visibleW: number, visibleH: number) => ({ x: visibleW - 6 - 130 + 32, y: visibleH - 20 - 10 });
const TOUCH_PAUSE = { x: 303 + 17, y: 4 + 17 };

const MIME: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".json": "application/json",
};

interface Probe {
  scene: string;
  menu: string;
}

const SIZES = [
  { name: "1280x720", width: 1280, height: 720, touch: false },
  { name: "640x360", width: 640, height: 360, touch: true },
  { name: "844x390", width: 844, height: 390, touch: true },
  { name: "960x440", width: 960, height: 440, touch: true },
] as const;

const [rootArg, outArg] = process.argv.slice(2);
if (!rootArg || !outArg) {
  console.error("usage: node ui-shots.ts <export-dir> <out-dir>");
  process.exit(2);
}
const root = resolve(rootArg);
const out = resolve(outArg);

const server = createServer(async (req, res) => {
  const path = normalize(join(root, new URL(req.url ?? "/", "http://x").pathname.replace(/^\/$/, "/index.html")));
  if (!path.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  try {
    const body = await readFile(path);
    res.writeHead(200, { "content-type": MIME[extname(path)] ?? "application/octet-stream" }).end(body);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise<void>((ok) => server.listen(0, "127.0.0.1", ok));
const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}/index.html`;

const browser = await chromium.launch();
const summary: Record<string, unknown>[] = [];
let failed = false;

for (const size of SIZES) {
  const dir = join(out, size.name);
  await mkdir(dir, { recursive: true });
  const page = await browser.newPage({
    viewport: { width: size.width, height: size.height },
    hasTouch: size.touch,
    isMobile: size.touch,
  });
  const problems: string[] = [];
  const checks: Record<string, boolean> = {};
  const shots: string[] = [];
  page.on("pageerror", (err) => problems.push(`page error: ${err.message}`));
  const booted = new Promise<void>((done) => {
    page.on("console", (msg) => {
      if (msg.type() === "error") problems.push(`console error: ${msg.text()}`);
      if (msg.text().startsWith(BOOT_MARKER)) done();
    });
  });
  await page.goto(url);
  await Promise.race([booted, page.waitForTimeout(60_000)]);
  const scale = Math.min(size.width / BASE.w, size.height / BASE.h);
  const visible = { w: size.width / scale, h: size.height / scale };
  let n = 0;
  const shot = async (name: string): Promise<void> => {
    n += 1;
    const file = `${String(n).padStart(2, "0")}_${name}.png`;
    await page.waitForTimeout(400);
    await page.screenshot({ path: join(dir, file) });
    shots.push(file);
  };
  const probe = async (): Promise<Probe | undefined> => {
    await page.waitForTimeout(150);
    return page.evaluate(() => (window as { ironboundProbe?: Probe }).ironboundProbe);
  };
  const menuIs = async (want: string, ms = 3000): Promise<boolean> => {
    const until = Date.now() + ms;
    while (Date.now() < until) {
      if ((await probe())?.menu === want) return true;
    }
    return false;
  };
  const key = async (k: string): Promise<void> => {
    await page.keyboard.press(k);
    await page.waitForTimeout(250);
  };

  await page.waitForTimeout(1500);
  await shot("title");
  await page.locator("canvas").first().click({ position: { x: 2, y: 2 } });
  await key("Enter"); // New game
  await page.waitForTimeout(1200);
  await key("Enter"); // the first hero
  await page.keyboard.type("Shots");
  await key("Enter"); // into the street
  await page.waitForTimeout(2500);
  checks.in_game = (await probe())?.scene !== undefined;
  await shot("hud");

  for (const [k, screen] of [["KeyC", "character"], ["KeyB", "bag"], ["KeyV", "skills"], ["KeyO", "quests"], ["KeyM", "map"]] as const) {
    await key(k);
    checks[`key_${screen}`] = await menuIs(screen);
    await shot(screen);
    await key(k);
  }
  await key("Escape");
  checks.key_pause = await menuIs("pause");
  await shot("pause");
  await key("Escape");
  checks.key_close = await menuIs("");

  if (size.touch) {
    const at = { x: TOUCH_PAUSE.x * scale, y: TOUCH_PAUSE.y * scale };
    await page.touchscreen.tap(at.x, at.y);
    checks.touch_pause = await menuIs("pause");
    await shot("touch_pause");
    await key("Escape");
  } else {
    const bag = HUD_BAG(visible.w, visible.h);
    await page.mouse.click(bag.x * scale, bag.y * scale);
    checks.mouse_bag = await menuIs("bag");
    await shot("mouse_bag");
    await key("Escape");
  }

  const ok = problems.length === 0 && Object.values(checks).every(Boolean);
  failed ||= !ok;
  summary.push({ size: size.name, input: size.touch ? "touch" : "mouse", scale, ok, checks, problems, shots });
  console.log(`${ok ? "OK  " : "FAIL"} ${size.name}: ${JSON.stringify(checks)}${problems.length ? " " + problems.join("; ") : ""}`);
  await page.close();
}

await writeFile(join(out, "summary.json"), JSON.stringify(summary, null, 2) + "\n");
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
