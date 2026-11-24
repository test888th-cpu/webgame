// Reproducible UI screenshots of a web export of the production game (title →
// new character → the street and its screens) at four standard desktop window
// sizes, played with keyboard and mouse as on PC (the game's platform: Windows PC
// for Steam):
//
//   node ui-shots.ts <export-dir> <out-dir>
//
//   1280x720   16:9, the game's 640x360 canvas at 2x
//   1920x1080  16:9, full HD
//   1440x900   16:10
//   1024x768   4:3, a small window
//
// At each size, checked through the read-only window.ironboundProbe: the title;
// a new character entering the street; the HUD's menu buttons on screen;
// Character, Equipment, Bag, Skills and Settings opened by their keys and by the
// screens' row (Q / E), and by mouse (the HUD's buttons and the row's); the Esc
// menu, and a screen opened from it by mouse; taking gear off and putting it back
// on, by keyboard and by mouse; a setting switched and switched back, by keyboard
// and by mouse; windows closed by Esc and by their close button. Every window, its
// close button and its row of screens must be wholly on screen. Every screenshot is
// checked for bands of Godot's default clear colour (77, 77, 77) and for a blank
// (nearly one-colour) frame; any console or page error fails the size.
//
// NOT_IMPLEMENTED in the production street, so not run and never counted as a pass
// (docs/GAME_MIGRATION_REGISTER.md, "Not done"): npc_walk, npc_talk (NPCs are not in
// the street yet), map_screen (not ported to the new engine).
// OUT_OF_SCOPE (owner direction: a PC game; no phone, tablet, touch or portrait
// support is developed or tested): the earlier phone sizes and touch checks.
//
// Writes <out>/<size>/NN_<name>.png and <out>/summary.json (each check PASS or FAIL,
// plus the NOT_IMPLEMENTED and OUT_OF_SCOPE lists) and exits non-zero if any fails.
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
// A frame whose most common colour covers this share of it is blank.
const BLANK_SHARE = 0.97;

const MIME: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".json": "application/json",
};

type Rect = [number, number, number, number];

interface Probe {
  scene: string;
  menu?: string;
  focus?: string;
  has_character?: boolean;
  equipment?: Record<string, string>;
  bag?: string[];
  show_fps?: boolean;
  ui?: { view: [number, number]; window?: Rect; buttons?: Record<string, Rect>; hud_menu?: Record<string, Rect> };
}

interface Size {
  name: string;
  width: number;
  height: number;
}

const SIZES: Size[] = [
  { name: "1280x720", width: 1280, height: 720 },
  { name: "1920x1080", width: 1920, height: 1080 },
  { name: "1440x900", width: 1440, height: 900 },
  { name: "1024x768", width: 1024, height: 768 },
];
const SCREENS = ["character", "equipment", "bag", "skills", "settings"];
const NOT_IMPLEMENTED: Record<string, string> = {
  npc_walk: "NPCs are not in the production street yet",
  npc_talk: "NPC conversations are not in the production street yet",
  map_screen: "the Map screen is not ported to the new engine",
};
const OUT_OF_SCOPE: Record<string, string> = {
  phone_and_touch: "a PC game for Steam: phone sizes (360x640, 390x844, 412x915, 640x360) and touch input are not developed or tested",
};

const args = process.argv.slice(2);
const positional = args.filter((a) => !a.startsWith("--"));
if (positional.length < 2) {
  console.error("usage: node ui-shots.ts <export-dir> <out-dir>");
  process.exit(2);
}
const root = resolve(positional[0]);
const out = resolve(positional[1]);

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

// The share of the frame taken by its most common colour (sampled every 4 px).
function commonestShare(png: Buffer): number {
  const image = decodePng(png);
  const counts = new Map<number, number>();
  let total = 0;
  for (let y = 0; y < image.height; y += 4) {
    for (let x = 0; x < image.width; x += 4) {
      const [r, g, b] = image.pixel(x, y);
      const k = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      counts.set(k, (counts.get(k) ?? 0) + 1);
      total++;
    }
  }
  return Math.max(...counts.values()) / total;
}

const inside = (r: Rect | undefined, view: [number, number]): boolean =>
  !!r && r[2] > 0 && r[3] > 0 && r[0] >= -0.5 && r[1] >= -0.5 && r[0] + r[2] <= view[0] + 0.5 && r[1] + r[3] <= view[1] + 0.5;

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

// A local Chromium may be named (PLAYWRIGHT_CHROMIUM_PATH); CI uses Playwright's own.
const executablePath = process.env.PLAYWRIGHT_CHROMIUM_PATH || undefined;
const browser = await chromium.launch({ executablePath });
const summary: Record<string, unknown>[] = [];
let failed = false;

for (const size of SIZES) {
  const dir = join(out, size.name);
  await mkdir(dir, { recursive: true });
  const page: Page = await browser.newPage({ viewport: { width: size.width, height: size.height } });
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
  const probe = async (): Promise<Probe | undefined> => {
    await page.waitForTimeout(150);
    return page.evaluate(() => (window as { ironboundProbe?: Probe }).ironboundProbe);
  };
  const until = async (ok: (p: Probe) => boolean, ms = 5000): Promise<Probe | undefined> => {
    const end = Date.now() + ms;
    while (Date.now() < end) {
      const p = await probe();
      if (p && ok(p)) return p;
    }
    return undefined;
  };
  const menuIs = async (want: string, ms = 5000): Promise<boolean> => !!(await until((p) => (p.menu ?? "") === want, ms));
  const key = async (k: string): Promise<void> => {
    await page.keyboard.press(k);
    await page.waitForTimeout(200);
  };
  const focusOn = async (name: string): Promise<boolean> => {
    for (let i = 0; i < 150; i++) {
      if ((await probe())?.focus === name) return true;
      await page.keyboard.press("Tab");
    }
    return false;
  };
  // Click the centre of a canvas-unit rect (the canvas is scaled to the window).
  const clickRect = async (p: Probe, r: Rect): Promise<void> => {
    const s = size.width / p.ui!.view[0];
    await page.mouse.click((r[0] + r[2] / 2) * s, (r[1] + r[3] / 2) * s);
  };
  // Click the open window's button `name`; false if it is not there.
  const click = async (name: string): Promise<boolean> => {
    const p = await probe();
    const r = p?.ui?.buttons?.[name];
    if (!p || !r) return false;
    await clickRect(p, r);
    return true;
  };
  // A screenshot of the open screen, with the checks every screenshot gets: no grey
  // band, not blank, and (with a screen open) its window, its close button (the Esc
  // menu's "Back to the game") and its row of screens wholly on screen.
  const shot = async (name: string): Promise<void> => {
    n += 1;
    const file = `${String(n).padStart(2, "0")}_${name}.png`;
    await page.waitForTimeout(450);
    const png = await page.screenshot({ path: join(dir, file) });
    const grey = greyBands(png);
    const share = commonestShare(png);
    shots.push({ file, grey_rows: grey.rows, longest_grey_band: grey.longest, commonest_colour_share: share });
    checks[`${name}_not_blank`] = share < BLANK_SHARE;
    checks[`${name}_no_grey_band`] = grey.longest < GREY_BAND_ROWS;
    const p = await probe();
    if (p?.scene === "street" && p.menu) {
      const view = p.ui!.view;
      const b = p.ui?.buttons ?? {};
      checks[`${name}_window_on_screen`] = inside(p.ui?.window, view);
      checks[`${name}_close_on_screen`] = inside(p.menu === "pause" ? b.Backtothegame : b.Close, view);
      if (p.menu !== "pause") {
        checks[`${name}_screen_row_on_screen`] = SCREENS.every((s) => inside(b[`Nav_${s}`], view));
      }
    }
  };

  await page.waitForTimeout(1500);
  checks.title = !!(await until((p) => p.scene === "title", 30_000));
  await shot("title");
  await page.locator("canvas").first().click({ position: { x: 2, y: 2 } });
  await key("Enter"); // New game
  checks.creation = !!(await until((p) => p.scene === "rpg" && p.has_character === false, 15_000));
  checks.name_field = await focusOn("NameEdit");
  await page.keyboard.type("Shots");
  checks.class_choice = await focusOn("Class_warrior");
  await shot("creation");
  await key("Enter");
  checks.in_street = !!(await until((p) => p.scene === "street", 60_000));
  await shot("street_hud");
  const hud = await probe();
  checks.hud_menu_buttons = SCREENS.every((s) => inside(hud?.ui?.hud_menu?.[s], hud!.ui!.view));

  // Keyboard: every screen by its key and by the screens' row (E: next, Q: previous).
  await key("KeyC");
  checks.key_character = await menuIs("character");
  await shot("character");
  for (const name of SCREENS.slice(1)) {
    await key("KeyE");
    checks[`key_next_${name}`] = await menuIs(name);
    await shot(name);
  }
  await key("KeyQ");
  checks.key_previous_skills = await menuIs("skills");
  await key("Escape");
  checks.key_escape_closes = await menuIs("");
  await key("KeyB");
  checks.key_bag = await menuIs("bag");
  await key("KeyB");
  checks.key_bag_toggles_off = await menuIs("");
  await key("KeyV");
  checks.key_skills = await menuIs("skills");
  await key("KeyV");
  checks.key_skills_toggles_off = await menuIs("");
  await key("Escape");
  checks.key_pause = await menuIs("pause");
  await shot("pause");
  await key("Escape");
  checks.key_pause_closes = await menuIs("");

  // Keyboard: take the chest piece off, then put it back on (Equipment, Bag).
  await key("KeyC");
  await key("KeyE");
  checks.key_equipment = await menuIs("equipment");
  const worn = (await probe())?.equipment?.chest ?? "";
  checks.key_chest_selected = (await focusOn("Worn_chest")) && worn !== "";
  await key("Enter");
  checks.key_take_off_offered = await focusOn("Unequip");
  await key("Enter");
  checks.key_taken_off = !!(await until((p) => !("chest" in (p.equipment ?? {})) && (p.bag ?? []).includes(worn)));
  await shot("equipment_taken_off");
  await key("KeyE");
  checks.key_bag_open = await menuIs("bag");
  const at = (await probe())?.bag?.lastIndexOf(worn) ?? -1;
  checks.key_bag_item_selected = await focusOn(`Bag_${at}`);
  await key("Enter");
  checks.key_equip_offered = await focusOn("Equip");
  await shot("bag_item");
  await key("Enter");
  checks.key_put_back_on = !!(await until((p) => p.equipment?.chest === worn && !(p.bag ?? []).includes(worn)));
  await key("Escape");
  await menuIs("");

  // Keyboard: a real setting, on and back.
  await key("KeyC");
  for (let i = 0; i < 4; i++) await key("KeyE");
  checks.key_settings = await menuIs("settings");
  const fps = (await probe())?.show_fps ?? false;
  checks.key_setting_focused = await focusOn("show_fps");
  await key("Enter");
  checks.key_setting_changed = !!(await until((p) => p.show_fps === !fps));
  await key("Enter");
  checks.key_setting_restored = !!(await until((p) => p.show_fps === fps));
  await key("Escape");
  await menuIs("");

  // Mouse: the HUD's Character button, then every screen by the screens' row.
  const street = await probe();
  checks.mouse_hud_button = false;
  if (street?.ui?.hud_menu?.character) {
    await clickRect(street, street.ui.hud_menu.character);
    checks.mouse_hud_button = await menuIs("character");
    await shot("mouse_character");
  }
  for (const name of SCREENS.slice(1)) {
    checks[`mouse_row_${name}`] = (await click(`Nav_${name}`)) && (await menuIs(name));
  }
  // Mouse: take the chest piece off and put it back on.
  checks.mouse_row_equipment_again = (await click("Nav_equipment")) && (await menuIs("equipment"));
  checks.mouse_chest_selected = (await click("Worn_chest")) && !!(await until((p) => !!p.ui?.buttons?.Unequip));
  checks.mouse_taken_off =
    (await click("Unequip")) && !!(await until((p) => !("chest" in (p.equipment ?? {})) && (p.bag ?? []).includes(worn)));
  checks.mouse_row_bag = (await click("Nav_bag")) && (await menuIs("bag"));
  const slot = (await probe())?.bag?.lastIndexOf(worn) ?? -1;
  checks.mouse_bag_item_selected = (await click(`Bag_${slot}`)) && !!(await until((p) => !!p.ui?.buttons?.Equip));
  checks.mouse_put_back_on = (await click("Equip")) && !!(await until((p) => p.equipment?.chest === worn));
  // Mouse: a real setting, on and back.
  checks.mouse_row_settings = (await click("Nav_settings")) && (await menuIs("settings"));
  checks.mouse_setting_changed = (await click("show_fps")) && !!(await until((p) => p.show_fps === !fps));
  checks.mouse_setting_restored = (await click("show_fps")) && !!(await until((p) => p.show_fps === fps));
  // Mouse: the close button, then a screen opened from the Esc menu.
  checks.mouse_close = (await click("Close")) && (await menuIs(""));
  await key("Escape");
  checks.mouse_pause_open = await menuIs("pause");
  checks.mouse_pause_to_skills = (await click("Menu_skills")) && (await menuIs("skills"));
  checks.mouse_skills_close = (await click("Close")) && (await menuIs(""));

  const ok = problems.length === 0 && Object.values(checks).every(Boolean);
  failed ||= !ok;
  const pass = Object.entries(checks).filter(([, v]) => v).map(([k]) => k);
  const fail = Object.entries(checks).filter(([, v]) => !v).map(([k]) => k);
  summary.push({ size: size.name, input: "keyboard and mouse", ok, pass, fail, problems, shots });
  console.log(
    `${ok ? "OK  " : "FAIL"} ${size.name}: PASS ${pass.length}, FAIL ${fail.length}` +
      (fail.length ? ` (${fail.join(", ")})` : "") +
      (problems.length ? ` | ${problems.join("; ")}` : ""),
  );
  await page.close();
}

console.log(`NOT_IMPLEMENTED (not run, not counted as passing): ${Object.keys(NOT_IMPLEMENTED).join(", ")}`);
console.log(`OUT_OF_SCOPE (PC game, not tested): ${Object.keys(OUT_OF_SCOPE).join(", ")}`);
await writeFile(
  join(out, "summary.json"),
  JSON.stringify({ sizes: summary, not_implemented: NOT_IMPLEMENTED, out_of_scope: OUT_OF_SCOPE }, null, 2) + "\n",
);
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
