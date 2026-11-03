// Reproducible UI screenshots of a web export at five window sizes, with the
// input each is used with, for review and as the UI regression baseline's
// pictures (the layout itself is checked by client/tests/ui/UiAuditRun.gd):
//
//   node ui-shots.ts <export-dir> <out-dir> [--layout=responsive|legacy]
//
//   1280x720  desktop: mouse and keyboard
//   640x360   phone held sideways: touch (and keyboard for the menus)
//   360x640, 390x844, 412x915   phones held upright: touch (and keyboard)
//
// At each size: the title, a new game's HUD with its touch controls, Bag,
// Map, the pause menu, a conversation with Chief Odo, and the phone turned
// round while playing and while the Bag is open. Input that must work there
// is checked: the screen keys, a mouse click on the HUD's Bag button
// (desktop), a touch on the pause button (phones). Screens are read back
// through the read-only window.ironboundProbe. Every screenshot is also
// checked for bands of Godot's default clear colour (77, 77, 77), which only
// show where nothing was drawn.
//
// Writes <out>/<size>/NN_<name>.png and <out>/summary.json, and exits
// non-zero on a page error, input that did not reach the game, or a grey
// band. It never judges layout beyond that: the Godot audit does.
import { createServer } from "node:http";
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";
import { inflateSync } from "node:zlib";
import type { AddressInfo } from "node:net";
import { chromium, type Page } from "playwright";

const BOOT_MARKER = "BOOT_OK";
const GREY = [77, 77, 77];
// A run of this many rows mostly grey is a band, not a stray pixel.
const GREY_BAND_ROWS = 8;

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
  area: string;
  menu: string;
  x: number;
  y: number;
}

interface Size {
  name: string;
  width: number;
  height: number;
  touch: boolean;
}

const SIZES: Size[] = [
  { name: "1280x720", width: 1280, height: 720, touch: false },
  { name: "640x360", width: 640, height: 360, touch: true },
  { name: "360x640", width: 360, height: 640, touch: true },
  { name: "390x844", width: 390, height: 844, touch: true },
  { name: "412x915", width: 412, height: 915, touch: true },
];

const args = process.argv.slice(2);
const positional = args.filter((a) => !a.startsWith("--"));
if (positional.length < 2) {
  console.error("usage: node ui-shots.ts <export-dir> <out-dir> [--layout=responsive|legacy]");
  process.exit(2);
}
const root = resolve(positional[0]);
const out = resolve(positional[1]);
const legacy = args.includes("--layout=legacy");

// Where the pause touch button and the HUD's Bag button are, in CSS px, for
// a window `w` x `h`. "legacy" is the layout before U1-A (fixed 640x360
// coordinates, scaled); "responsive" mirrors client/scenes/ui/ScreenLayout.gd.
// If the game moves them, the tap and click checks fail and say so.
function pauseAt(w: number, h: number): { x: number; y: number } {
  if (legacy) {
    const s = Math.min(w / 640, h / 360);
    return { x: (303 + 17) * s, y: (4 + 17) * s };
  }
  const portrait = h > w;
  const s = portrait ? Math.min(w / 360, h / 640) : Math.min(w / 640, h / 360);
  const lw = w / s;
  const lh = h / s;
  const t = Math.max(44 / s, 28);
  if (portrait) {
    // The 2x2 block between the pads (Bag over Map, AUTO over pause): the
    // pause button is its lower right cell.
    const padEnd = 8 + 3 * t + 2 * 4;
    const right = lw - 8 - (2 * t + 4);
    const block = 2 * t + 4;
    const x = (padEnd + right) / 2 - block / 2 + t + 4 + t / 2;
    const y = lh - 8 - t / 2;
    return { x: x * s, y: y * s };
  }
  // Landscape with touch: the first button of the top-centre row.
  const row = 5 * t + 4 * 4;
  return { x: (lw / 2 - row / 2 + t / 2) * s, y: (4 + t / 2) * s };
}

function bagAt(w: number, h: number): { x: number; y: number } {
  const s = Math.min(w / 640, h / 360);
  const lw = w / s;
  const lh = h / s;
  return { x: (lw - 6 - 130 + 32) * s, y: (lh - 20 - 10) * s };
}

// Decodes an 8-bit RGB or RGBA PNG (what Chromium screenshots are) into rows
// of pixels, with Node's zlib only.
function decodePng(png: Buffer): { width: number; height: number; pixel: (x: number, y: number) => number[] } {
  let at = 8;
  let width = 0;
  let height = 0;
  let channels = 4;
  const idat: Buffer[] = [];
  while (at < png.length) {
    const length = png.readUInt32BE(at);
    const type = png.toString("ascii", at + 4, at + 8);
    const data = png.subarray(at + 8, at + 8 + length);
    if (type === "IHDR") {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      channels = data[9] === 2 ? 3 : 4;
    } else if (type === "IDAT") {
      idat.push(data);
    }
    at += 12 + length;
  }
  const raw = inflateSync(Buffer.concat(idat));
  const stride = width * channels;
  const rows = Buffer.alloc(height * stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    for (let x = 0; x < stride; x++) {
      const v = raw[y * (stride + 1) + 1 + x];
      const a = x >= channels ? rows[y * stride + x - channels] : 0;
      const b = y > 0 ? rows[(y - 1) * stride + x] : 0;
      const c = x >= channels && y > 0 ? rows[(y - 1) * stride + x - channels] : 0;
      let p = v;
      if (filter === 1) p = v + a;
      else if (filter === 2) p = v + b;
      else if (filter === 3) p = v + ((a + b) >> 1);
      else if (filter === 4) {
        const pa = Math.abs(b - c);
        const pb = Math.abs(a - c);
        const pc = Math.abs(a + b - 2 * c);
        p = v + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c);
      }
      rows[y * stride + x] = p & 0xff;
    }
  }
  return {
    width,
    height,
    pixel: (x, y) => [rows[y * stride + x * channels], rows[y * stride + x * channels + 1], rows[y * stride + x * channels + 2]],
  };
}

// The longest run of rows that are at least 90% default grey, and how many
// such rows there are in all.
function greyBands(png: Buffer): { longest: number; rows: number } {
  const image = decodePng(png);
  let longest = 0;
  let run = 0;
  let rows = 0;
  for (let y = 0; y < image.height; y++) {
    let grey = 0;
    for (let x = 0; x < image.width; x += 2) {
      const [r, g, b] = image.pixel(x, y);
      if (Math.abs(r - GREY[0]) <= 2 && Math.abs(g - GREY[1]) <= 2 && Math.abs(b - GREY[2]) <= 2) grey++;
    }
    if (grey >= Math.ceil(image.width / 2) * 0.9) {
      run++;
      rows++;
      longest = Math.max(longest, run);
    } else {
      run = 0;
    }
  }
  return { longest, rows };
}

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
  const page: Page = await browser.newPage({
    viewport: { width: size.width, height: size.height },
    hasTouch: size.touch,
    isMobile: size.touch,
  });
  const problems: string[] = [];
  const checks: Record<string, boolean> = {};
  const shots: Record<string, unknown>[] = [];
  page.on("pageerror", (err) => problems.push(`page error: ${err.message}`));
  const booted = new Promise<void>((done) => {
    page.on("console", (msg) => {
      if (msg.type() === "error") problems.push(`console error: ${msg.text()}`);
      if (msg.text().startsWith(BOOT_MARKER)) done();
    });
  });
  await page.goto(url);
  await Promise.race([booted, page.waitForTimeout(60_000)]);
  let n = 0;
  const shot = async (name: string): Promise<void> => {
    n += 1;
    const file = `${String(n).padStart(2, "0")}_${name}.png`;
    await page.waitForTimeout(450);
    const png = await page.screenshot({ path: join(dir, file) });
    const grey = greyBands(png);
    shots.push({ file, grey_rows: grey.rows, longest_grey_band: grey.longest });
    if (grey.longest >= GREY_BAND_ROWS) problems.push(`${file}: a band of default grey ${grey.longest} rows tall`);
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
  const hold = async (k: string, ms: number): Promise<void> => {
    await page.keyboard.down(k);
    await page.waitForTimeout(ms);
    await page.keyboard.up(k);
  };
  // Walks the hero to (x, y) in the street with the arrow keys: along the
  // open lower lane (y 330, below the training dummy and parked cars), then
  // up to the spot once level with it.
  const walkTo = async (x: number, y: number): Promise<boolean> => {
    const until = Date.now() + 40_000;
    while (Date.now() < until) {
      const p = await probe();
      if (!p) return false;
      if (Math.abs(p.x - x) <= 14 && Math.abs(p.y - y) <= 10) return true;
      const laneY = Math.abs(p.x - x) < 40 ? y : 330;
      if (Math.abs(p.y - laneY) > 8) await hold(p.y > laneY ? "ArrowUp" : "ArrowDown", 120);
      else await hold(p.x < x ? "ArrowRight" : "ArrowLeft", Math.min(400, Math.abs(p.x - x) * 3));
    }
    return false;
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
  if (size.touch) {
    // A touch first, so the game knows it is played by touch (shows the
    // touch controls and hides keyboard hints).
    await page.touchscreen.tap(size.width / 2, size.height / 3);
    await page.waitForTimeout(300);
  }
  await shot("play_hud");

  await key("KeyB");
  checks.key_bag = await menuIs("bag");
  await shot("bag");
  await key("KeyB");
  await key("KeyM");
  checks.key_map = await menuIs("map");
  await shot("map");
  await key("KeyM");
  await key("Escape");
  checks.key_pause = await menuIs("pause");
  await shot("pause");
  await key("Escape");
  checks.key_close = await menuIs("");

  if (size.touch) {
    // Keys were just pressed (the menus above), which shows a keyboard
    // player's screen; a phone player only ever touches, so touch the street
    // once first, then the pause button.
    await page.touchscreen.tap(size.width / 2, size.height / 3);
    await page.waitForTimeout(300);
    const at = pauseAt(size.width, size.height);
    await page.touchscreen.tap(at.x, at.y);
    checks.touch_pause = await menuIs("pause");
    await shot("touch_pause");
    if ((await probe())?.menu === "pause") await key("Escape");
    await menuIs("");
  } else {
    const at = bagAt(size.width, size.height);
    await page.mouse.click(at.x, at.y);
    checks.mouse_bag = await menuIs("bag");
    await shot("mouse_bag");
    await key("Escape");
    await menuIs("");
  }

  // Talk to Chief Odo (Depot Yard: x 640, y 262).
  checks.walk_to_npc = await walkTo(620, 270);
  await key("KeyE");
  checks.npc_talk = await menuIs("quests_npc");
  await shot("npc_talk");
  await key("Escape");
  await menuIs("");

  // Turn the phone (or the window) round while playing, then with the Bag
  // open, then back.
  await page.setViewportSize({ width: size.height, height: size.width });
  await page.waitForTimeout(800);
  checks.rotated_play = (await probe())?.menu === "";
  await shot("rotated_play");
  await key("KeyB");
  checks.rotated_bag_open = await menuIs("bag");
  await page.setViewportSize({ width: size.width, height: size.height });
  await page.waitForTimeout(800);
  checks.rotated_back_bag = (await probe())?.menu === "bag";
  await shot("rotated_back_bag");
  await key("KeyB");
  checks.rotated_back_play = await menuIs("");
  await shot("rotated_back_play");

  const ok = problems.length === 0 && Object.values(checks).every(Boolean);
  failed ||= !ok;
  summary.push({ size: size.name, input: size.touch ? "touch" : "mouse", ok, checks, problems, shots });
  const failedChecks = Object.entries(checks).filter(([, v]) => !v).map(([k]) => k);
  console.log(
    `${ok ? "OK  " : "FAIL"} ${size.name}: ${Object.keys(checks).length - failedChecks.length}/${Object.keys(checks).length} checks` +
      (failedChecks.length ? ` (failed: ${failedChecks.join(", ")})` : "") +
      (problems.length ? ` | ${problems.join("; ")}` : ""),
  );
  await page.close();
}

await writeFile(join(out, "summary.json"), JSON.stringify(summary, null, 2) + "\n");
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
