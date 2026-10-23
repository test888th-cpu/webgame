# Web export

## Configuration [built]
`client/export_presets.cfg`, preset **Web**:

| Setting | Value | Why |
|---|---|---|
| Engine and templates | Godot 4.7.2-stable, official templates (SHA-512 verified) | Pinned in `tools/ci/install-godot.sh` |
| Renderer | `gl_compatibility` (WebGL 2) | The only renderer supported on the web |
| Threads | **off** (`variant/thread_support=false`) | No COOP/COEP headers needed, so it works on GitHub Pages and any static host or iframe |
| GDExtension | off | Smaller download, no dlink template |
| PWA | off | Avoids service-worker caching surprises while iterating |
| Excluded | `tests/*` | Test code is not shipped |
| Texture compression | desktop + mobile (ETC2/ASTC) | Mobile GPUs |

## Output (measured on the Task 001 build)
`index.html`, `index.js` (280 KB), `index.wasm` (39.5 MB; **10.1 MB gzip -9**), `index.pck`
(36 KB), `index.audio.worklet.js`, `index.audio.position.worklet.js`, icons. CI adds
`BUILD_MANIFEST.txt` with SHA-256 of every file.

## Hosting requirements
- Must be served over **http(s)**. `file://` is blocked for WebAssembly.
- `.wasm` should be served as `application/wasm` with gzip or Brotli. GitHub Pages,
  Cloudflare Pages and Netlify do this.
- Threaded builds would need `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: require-corp`. **Not required** for this build.

## Supported browsers
Target: current Chrome and Edge on desktop (primary), then Firefox and Safari (desktop),
then Chrome Android and Safari iOS. CI verifies **headless Chromium only** (Playwright
1.56.1 with SwiftShader).

## Known limitations of Godot web export
- A large single wasm makes the first load slow. Repeat visits are cached by the browser.
- Single-threaded: audio mixing and game logic share the main thread.
- Browsers require a user gesture before audio plays.
- Mobile browsers: memory limits and virtual keyboards are less predictable. Not yet tested.
- Gamepad support depends on the browser's Gamepad API mapping.

## What the smoke test can and cannot prove
It **does**: serve the export, load it in Chromium, wait for `BOOT_OK`, fail on page
errors, console errors or HTTP errors, hold ArrowRight / W / ArrowLeft, and check through
`window.ironboundProbe` that the hero moved and turned. It saves a screenshot.

It **does not**: test touch input or gamepads (Playwright cannot emulate the Gamepad API;
touch holds are not reliably reproducible), real GPUs, frame rate (SwiftShader is software
rendering), Firefox or Safari, or HTTPS hosting. Those need the manual checklist in
PERFORMANCE.md.
