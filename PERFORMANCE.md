# Performance and capacity

**No performance or capacity claims are made yet.** Numbers in this file are either
*measured* (with method and hardware) or explicitly labelled *assumption*.

## Browser budgets (targets, set before production)
| Tier | Hardware | Target |
|---|---|---|
| Desktop reference | 4-core CPU ≥ 2018, integrated GPU, Chrome/Edge current | 60 fps, p99 frame ≤ 25 ms with 1 hero + 12 enemies + effects |
| Low-end / mobile | ~2020 mid-range Android, Chrome | 30 fps stable, reduced effects |
| First load | 25 Mbit/s connection | ≤ 12 MB compressed before the title screen; interactive ≤ 8 s |

### Measured so far
| Date | Item | Result | Method |
|---|---|---|---|
| 2026-10-23 | Web export size | wasm 39.5 MB raw / 10.1 MB gzip; pck 36 KB | Local export, `gzip -9` |
| 2026-10-23 | Boot to `BOOT_OK` in headless Chromium | ~1.3–1.7 s (localhost, SwiftShader) | `tools/web-smoke` |

The HUD's FPS reading in headless CI (~25 fps) comes from **software rendering** and is
not a performance measurement.

### How to measure (reproducible)
1. Open the deployed build in Chrome or Edge on the reference machine.
2. DevTools → Performance → record 30 s of play; note fps, p99 frame time, scripting
   and rendering split. Godot's own profiler does not run in web builds, so use DevTools.
3. Record in the table above with hardware, browser version and build commit.
   A dedicated performance scene (fixed enemy count, scripted movement) arrives in M2.

## Server capacity model (assumptions, to be replaced by measurements)
Definitions: **CCU** = all connected players across every zone. **Instance population** =
players sharing one simulated zone instance.

| Instance type | Cap (assumption) | Snapshot rate |
|---|---|---|
| City hub | 80 visible (more via additional instances) | 10 Hz |
| Farming zone | 24 | 20 Hz |
| Dungeon / boss | 4–5 / 10 | 20 Hz |

Bandwidth *estimate* (assumption): 30 entities in interest × ~12 B delta × 20 Hz ≈ 7 KB/s
≈ 58 kbit/s per player downstream. 4,000 CCU ≈ 230 Mbit/s egress before compression.
To be measured in M3.

## Load-test plan (M8)
Stages: 50 → 100 → 500 → 1,000 → 4,000 connections. Each stage runs twice: **idle
connections** (heartbeats only) and **active bots** (move + attack against monsters).
Thresholds are written down before each run. Starting proposal: p95 input-to-snapshot
latency < 150 ms on the server, tick overrun < 1 %, disconnect rate < 0.5 %, DB p95 < 20 ms,
CPU < 70 %. Measure CPU, memory, bandwidth, message rate and size, DB load, recovery time
after killing a zone process, and cost per CCU. Report hardware and raw results in
`docs/load-tests/`. Capacity is only claimed for stages that passed.
