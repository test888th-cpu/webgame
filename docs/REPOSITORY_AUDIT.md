# Repository audit — 2026-10-23

## 1. This repository (`test888th-cpu/webgame`)

At audit time it held one commit (`dd12925 Initial commit`) and one file, `README.md`,
containing `# webgame`. There was no Godot project, code, assets, CI or dependencies,
so the project was initialised from scratch. No working features existed that could be
broken.

## 2. Reference repositories

Each was cloned (shallow) and inspected. Claims marked *verified* were checked by running
code. Anything else comes from reading the files.

| | A. Sidewalk Kings | B. Downtown Beatdown (Quiver) | C. YokosukaJS | D. RCRness | E. NES-Games-Disassembly |
|---|---|---|---|---|---|
| URL | OuterHeavenX/sidewalk-kings | quiver-dev/template-beat-em-up | allenu/YokosukaJS | NJH-1001/RCRness | cyneprepou4uk/NES-Games-Disassembly |
| Last commit | 2026-09-06 | 2024-03-29 | 2018-07-23 | 2026-08-29 | 2026-08-12 |
| Engine / language | Godot 4.7.2, GDScript (~13.3k lines, 66 scripts) | Godot **4.0** (RC6+), GDScript (~18.7k lines incl. addon) | Plain JS + Canvas (15 files) | C + PowerShell build kit around NESRecomp | 6502 assembly + ca65 / Lua tooling |
| **Licence** | **None.** No LICENSE file; README asserts originality but grants no rights, so all rights are reserved | **MIT** (code) + **CC BY 4.0** (art, music, sound) | **MIT** | Own code unlicensed; dependency NESRecomp is **PolyForm Noncommercial** | **None**; content is derived from commercial ROMs |
| What exists | Open-world brawler: data-driven moves, enemies, quests, shops, dialogue, 12 areas, boss with 2 phases, save migration, touch controls, single-threaded web build committed (39 MB wasm). *Verified:* its smoke test passes 415/415 on Godot 4.7.2 here | Template: player and 2 enemies, AnimationTree state machines, attack resources, custom inspectors, level blocking, day/night | Functional engine: `tick(state, input) → state`; YAML actor models; spritesheet JSON | Windows-only tooling that statically recompiles a user-supplied RCR ROM | Disassemblies of 26 games. **River City Ransom is listed as WIP and is not in the repo** |
| Missing | Any networking, server, accounts or persistence beyond local saves | Web preset (only Linux, macOS, Windows), docs ("coming soon"), progression, networking | Tests, combat depth, maintenance | Not a game engine, not Godot, contains no source for the game | n/a |
| Web compatibility | Good (single-threaded export) | Unknown; would need a 4.0 → 4.7 port | Native web | None (desktop exe) | None |
| Notable risks | Cannot legally reuse code or art | **Assets live in Git LFS** (clone yields pointer files); combat is tied to AnimationTree and physics nodes, which is heavy for a headless authoritative server | Unmaintained for 8 years | Legal: ROM-derived code; noncommercial-only dependency | Legal: copyrighted ROM content; ships `.exe`/`.dll` binaries (never execute) |

## 3. Verdicts

- **A. Sidewalk Kings: study only.** It is the closest match in scope and quality, but it
  has no licence, so its code and assets cannot be copied. It is useful as evidence that
  Godot 4.7 single-threaded web export works for this genre, and for design ideas such as
  data-driven moves and versioned saves. To reuse code, ask the author for an explicit
  licence first.
- **B. Downtown Beatdown: study, adapt small patterns with attribution.** MIT and CC BY
  allow reuse, but its node-heavy combat does not fit an authoritative headless server, and
  the target is Godot 4.0 with LFS assets. Its art is not used because the brief requires
  original art. Any adapted code must keep the MIT notice and be recorded in CHANGELOG.
- **C. YokosukaJS: adopt the idea, not the code.** Its pure `tick(state, input)` model is
  the right shape for `client/sim/`. Mixing JavaScript into the Godot client is not worth it.
- **D. RCRness: do not use.** It is not a Godot engine and not River City Ransom source
  code: it recompiles a ROM the user supplies. Nothing in it applies to an original
  online game.
- **E. NES-Games-Disassembly: do not use.** The RCR disassembly does not exist in the repo,
  and all content derives from copyrighted ROMs.

**Base chosen:** a new project (this repository). None of the candidates is both licensed
for reuse and architected for an authoritative multiplayer server.
