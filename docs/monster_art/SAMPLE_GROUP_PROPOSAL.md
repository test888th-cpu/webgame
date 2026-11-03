# First sample group: South Street Gang (Phase F, for approval)

Nothing is generated until the owner approves this proposal and the decisions
below. Designs: [CHARACTER_DESIGN_SPECIFICATIONS.md](CHARACTER_DESIGN_SPECIFICATIONS.md),
"South Street Gang".

## Why this group

- It is the first faction a player meets (Saltmarket Street onwards) and the
  one where the mix of looks is most visible.
- Every member is LPC, and every part its designs use was checked eligible
  (CC0 / OGA-BY 3.0) for the male body at the pinned generator commit. No
  non-LPC art is needed.
- It has every rank: ordinary (Dock Thug, Night Market Punk, Pipe Brute, Rail
  Bruiser), ranged (Bottle Thrower), elite (Refinery Enforcer), mini-boss (The
  Pit Champion), boss (The Furnace Baron).

| Enemy | Class | What changes |
|---|---|---|
| `dock_thug` | KEEP | nothing (reference for the group) |
| `street_thrower` | KEEP | drop the never-drawn open-vest layer (no visible change) |
| `rail_bruiser` | KEEP | nothing |
| `pit_champion` | KEEP | nothing |
| `market_punk` | REWORK | spiked hair (CC BY 4.0) → half-messy hair, pink; drop the never-drawn vest |
| `pipe_brute` | REWORK | orc head and green skin → human head, bronze skin, buzzcut, beard, red bandana |
| `refinery_enforcer` | REWORK | Roman armour and armoured legs → leather armour, gloves, pants; maroon headband |
| `furnace_baron` | REWORK | plumed cap removed; leather smelter's apron and gloves; never-drawn trench dropped |

The four painted members (Smogling, Tar Rat, Smog Warden, The Sludge Foreman)
are left as they are until the owner decides between keeping the painted style
and an LPC redesign (see the style guide).

## What happens after approval

1. Edit only these eight recipes in `art/lpc/characters.json`.
2. Build them **in a scratch copy** with `tools/assets/lpc_build.py --only ...`
   (the same pinned commit; the build refuses any file not offered under an
   allowed licence, with the allowed list narrowed to CC0 and OGA-BY for this
   group), then `make_spriteframes.py` and `validate.py`.
3. Phase 8 comparison sheet: the eight at in-game size, with the four painted
   members beside them, palettes and silhouettes, and the old sheets for
   comparison. The owner approves the group as a whole.
4. Only then copy the approved sheets, `.tres` and `credits.json` into
   `client/assets/characters/<id>/`. The previous files stay in Git history.
   Enemy ids, stats, AI, moves, hitboxes, drops, XP, coins, scale and save data
   do not change (the sheets keep the same rows, so `FighterView` is untouched).
5. Rebuild the credit register (`credit_register.py build`), re-run the licence
   check, the Godot suite, the UI audit and the browser checks.

## Owner decisions needed before step 1

1. **Production path for LPC art:** keep the project's build (recipes + pinned
   commit + credits per file drawn; reproducible in CI) as the production path,
   and add the website's configuration and Credits TXT/CSV beside it as
   provenance; or require website exports as the source and convert them. A
   website sheet cannot supply the game's fist sheet (`hands.png`) or borrowed
   frames, so it would be rebuilt by the project's tools either way
   ([LPC_GENERATOR_AUDIT.md](LPC_GENERATOR_AUDIT.md)).
2. **Website exports:** the build environment cannot reach the generator website
   or OpenGameArt. Either allow both hosts in the cloud environment's network
   settings, or export the configuration and Credits TXT/CSV in a browser and
   upload them.
3. **Verification at the source:** whether a licence that matches the
   generator's own records may count as VERIFIED, or each OpenGameArt page must
   be checked (needs the network access above). Until then every component stays
   UNVERIFIED and the validator reports it.
4. **Licence policy file:** narrow `license_policy.allowed` in
   `art/lpc/characters.json` from CC0, OGA-BY, CC-BY to CC0 and OGA-BY for
   monsters (heroes and NPCs keep CC-BY unless the owner says otherwise).
5. **The four painted enemies:** keep the painted style or redesign in LPC.
6. **Machines and the Tunnel Mother:** where their non-LPC art comes from
   (drawn in LPC style, commissioned, or a CC0/OGA-BY source).
