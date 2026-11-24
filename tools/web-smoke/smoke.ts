// Serves a Godot web export over HTTP, opens it in headless Chromium, waits
// for the client's boot marker on the console, then holds real keys and checks
// that the game plays: title -> new game -> name and class (the new character
// system) -> the street, walking, an auto fight to a kill, the game's screens
// (Character, Equipment, Bag, Skills, Settings: a setting, taking gear off and the
// hotbar changed), then, once the game confirms each save, an immediate reload and
// Continue to the same character with every change kept (all via the read-only
// window.ironboundProbe). --shots=<dir> saves a screenshot of each screen.
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
const shotsDir = args.find((a) => a.startsWith("--shots="))?.slice("--shots=".length);

interface Probe {
  scene: string;
  has_save?: boolean;
  has_character?: boolean;
  name?: string;
  class?: string;
  level?: number;
  kills?: number;
  focus?: string;
  menu?: string;
  save?: string;
  saves?: number;
  settings_saved?: number;
  show_fps?: boolean;
  equipment?: Record<string, string>;
  bag?: string[];
  hotbar?: string[];
  attack_power?: number;
  armor?: number;
  auto?: boolean;
  area?: string;
  x?: number;
  hp?: number;
  dead?: boolean;
  monsters?: number;
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
  const waitFor = async (what: string, ok: (p: Probe) => boolean, ms: number): Promise<Probe> => {
    const until = Date.now() + ms;
    let last = await probe();
    while (!ok(last)) {
      if (Date.now() > until) throw new Error(`timed out waiting for ${what}: ${JSON.stringify(last)}`);
      last = await probe();
    }
    return last;
  };
  // Moves keyboard focus with Tab until the focused control's name matches.
  const focusOn = async (what: string, ok: (name: string) => boolean): Promise<void> => {
    for (let i = 0; i < 150; i++) {
      if (ok((await probe()).focus ?? "")) return;
      await page.keyboard.press("Tab");
    }
    throw new Error(`could not reach ${what} with Tab`);
  };

  // A fresh browser: the title offers New game (focused by default).
  await waitFor("the title screen", (p) => p.scene === "title", 10_000);
  await page.keyboard.press("Enter");
  // The new character system: type a name, then choose a class.
  await waitFor("character creation", (p) => p.scene === "rpg" && !p.has_character, 10_000);
  await focusOn("the name field", (n) => n === "NameEdit");
  await page.keyboard.type("Smoke Test");
  await focusOn("the mage class", (n) => n === "Class_mage");
  await page.keyboard.press("Enter");
  // Creating the character opens the city: the street, on the new engine.
  const made = await waitFor("the street", (p) => p.scene === "street", 15_000);
  if (made.name !== "Smoke Test" || made.class !== "mage" || made.level !== 1) {
    problems.push(`created ${made.name}/${made.class}/${made.level}, expected Smoke Test/mage/1`);
  }
  console.log(`new character: "${made.name}", ${made.class}, level ${made.level}, in ${made.area}`);

  // Walking: held keys move the character along the street.
  const before = await probe();
  await page.keyboard.down("ArrowRight");
  await page.waitForTimeout(700);
  await page.keyboard.up("ArrowRight");
  const walked = await probe();
  if (!((walked.x ?? 0) > (before.x ?? 0))) problems.push(`walking right did not move: ${before.x} -> ${walked.x}`);
  console.log(`walk: x ${before.x} -> ${walked.x} in ${walked.area}`);

  // Into the first street with monsters, then auto (T) fights until a kill.
  let street = walked;
  const until = Date.now() + 30_000;
  while (street.monsters === 0 && Date.now() < until) {
    await page.keyboard.down("ArrowRight");
    await page.waitForTimeout(500);
    await page.keyboard.up("ArrowRight");
    street = await probe();
  }
  if (street.monsters === 0) throw new Error(`no street with monsters reached: ${JSON.stringify(street)}`);
  await page.keyboard.press("KeyT");
  const fought = await waitFor("a kill on auto", (p) => (p.kills ?? 0) >= 1 || p.dead === true, 120_000);
  if ((fought.kills ?? 0) < 1) problems.push(`no kill on auto: ${JSON.stringify(fought)}`);
  console.log(`street fight in ${fought.area}: kills ${fought.kills}, hp ${fought.hp}, level ${fought.level}`);
  await page.keyboard.press("KeyT"); // auto off: the screens are used standing still
  await waitFor("auto off", (p) => p.auto === false, 5_000);

  // The game's own screens. C opens Character; E moves to the next screen.
  const shot = async (name: string): Promise<void> => {
    if (shotsDir) await page.screenshot({ path: `${shotsDir}/${name}.png` });
  };
  await page.keyboard.press("KeyC");
  const character = await waitFor("Character", (p) => p.menu === "character", 5_000);
  await shot("character");
  for (const name of ["equipment", "bag", "skills", "settings"]) {
    await page.keyboard.press("KeyE");
    await waitFor(name, (p) => p.menu === name, 5_000);
    await shot(name);
  }
  console.log(`screens: character (attack power ${character.attack_power}), equipment, bag, skills, settings`);

  // Settings: a real switch, saved apart from the character.
  const settingsBefore = (await probe()).settings_saved ?? 0;
  await focusOn("Show frame rate", (n) => n === "show_fps");
  await page.keyboard.press("Enter");
  await waitFor("the setting saved", (p) => p.show_fps === true && (p.settings_saved ?? 0) > settingsBefore, 15_000);
  console.log("settings: show frame rate on, confirmed saved");

  // Equipment: take the chest piece off; it goes to the bag, and the save is confirmed.
  await page.keyboard.press("KeyQ"); // skills
  await page.keyboard.press("KeyQ"); // bag
  await page.keyboard.press("KeyQ"); // equipment
  await waitFor("Equipment", (p) => p.menu === "equipment", 5_000);
  const armorBefore = (await probe()).armor ?? 0;
  await focusOn("the chest slot", (n) => n === "Worn_chest");
  await page.keyboard.press("Enter");
  await focusOn("Take off", (n) => n === "Unequip");
  let savesBefore = (await probe()).saves ?? 0;
  await page.keyboard.press("Enter");
  const undressed = await waitFor(
    "the chest piece in the bag",
    (p) => !("chest" in (p.equipment ?? {})) && (p.bag ?? []).includes("apprentice_robe") && p.save === "saved" && (p.saves ?? 0) > savesBefore,
    15_000,
  );
  if (!((undressed.armor ?? 0) < armorBefore)) problems.push(`armor did not fall: ${armorBefore} -> ${undressed.armor}`);
  console.log(`equipment: chest off, armor ${armorBefore} -> ${undressed.armor}, saved`);

  // Skills: put the usable ability in hotbar slot 4.
  await page.keyboard.press("KeyV");
  await waitFor("Skills", (p) => p.menu === "skills", 5_000);
  await focusOn("Frost Armor", (n) => n === "Skill_frost_armor");
  await page.keyboard.press("Enter");
  await focusOn("slot 4", (n) => n === "Assign_4");
  savesBefore = (await probe()).saves ?? 0;
  await page.keyboard.press("Enter");
  const assigned = await waitFor(
    "the hotbar saved",
    (p) => (p.hotbar ?? [])[2] === "frost_armor" && p.save === "saved" && (p.saves ?? 0) > savesBefore,
    15_000,
  );
  console.log(`skills: hotbar ${JSON.stringify(assigned.hotbar)}, saved`);
  await page.keyboard.press("Escape");
  await waitFor("back to the street", (p) => p.menu === "", 5_000);

  // Reload at once: the confirmed saves must be there (no waiting on a timer).
  await page.reload();
  // The reloaded page publishes the probe again once the game has booted.
  await page.waitForFunction(() => (window as { ironboundProbe?: unknown }).ironboundProbe, null, {
    timeout: timeoutMs,
  });
  await waitFor("the title after reload", (p) => p.scene === "title" && p.has_save === true, timeoutMs);
  await canvas.first().click();
  await page.keyboard.press("Enter");
  const back = await waitFor("the saved character", (p) => p.scene === "street", 15_000);
  if (back.name !== "Smoke Test" || (back.kills ?? 0) < (fought.kills ?? 0) || back.area !== fought.area) {
    problems.push(`after reload: ${back.name}, kills ${back.kills}, in ${back.area}`);
  }
  if ("chest" in (back.equipment ?? {}) || !(back.bag ?? []).includes("apprentice_robe")) {
    problems.push(`equipment not kept: ${JSON.stringify(back.equipment)} bag ${JSON.stringify(back.bag)}`);
  }
  if ((back.hotbar ?? [])[2] !== "frost_armor") problems.push(`hotbar not kept: ${JSON.stringify(back.hotbar)}`);
  if (back.show_fps !== true) problems.push("the setting was not kept");
  console.log(
    `continue: "${back.name}", kills ${back.kills}, in ${back.area}, chest in bag, ` +
      `hotbar ${JSON.stringify(back.hotbar)}, show frame rate ${back.show_fps}`,
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
