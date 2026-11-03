# Faction style guide (monster art, Phase C)

How each faction's enemies should look, so a group reads as one gang, crew or
security force. Built on [ENEMY_INVENTORY.md](ENEMY_INVENTORY.md) (what exists),
[STORY_BIBLE.md](../STORY_BIBLE.md) (who they are) and what the Universal LPC
Spritesheet Character Generator actually offers at the pinned commit
`9bf06be193b053db256b2536824af426de046aa2` ([LPC_GENERATOR_AUDIT.md](LPC_GENERATOR_AUDIT.md)).
Nothing here is built yet: this is the design to approve before any sprite is
generated. Per-enemy designs: [CHARACTER_DESIGN_SPECIFICATIONS.md](CHARACTER_DESIGN_SPECIFICATIONS.md).

## Rules for every faction

- **One style:** LPC 64×64 pixel art, the generator's own 1 px dark outline and
  shading, nearest-neighbour filtering. Painted (high-colour) art is not mixed into
  an LPC faction (see the owner decision on the four painted enemies below).
- **One proportion:** LPC's adult `male`/`female` body types only. No
  `muscular` or `pregnant` bodies (their files are not offered under CC0/OGA-BY),
  no child or teen bodies for enemies.
- **Modern city, no fantasy:** no orc, troll, goblin or animal heads on people,
  no Roman/medieval armour, plumed caps, tabards, wizard hats, tricornes or crowns.
  People are people; the setting is a present-day Thai industrial city.
- **Colour carries the faction:** LPC has almost no modern uniform parts (see
  below), so a faction is mainly recognised by its cloth palette (the generator's
  `ulpc` cloth colours) and one signature accessory.
- **Rank by silhouette and accent, not by size alone:** ordinary enemies use the
  faction base; an elite adds the faction's signature accessory; a boss adds a
  coat or jacket and a boss-only accent colour, and keeps its larger `scale`.
  Bosses wear their faction's colours.
- **Every part is checked per file:** licences are per file actually used (a
  part's male and female files can differ). Only files offered under CC0 or
  OGA-BY 3.0 (3.0+ includes 3.0) are used; the build already refuses anything else
  and records credits per file.

## What LPC can and cannot give a modern city

Available and licence-eligible for the male body, checked file by file at the
pinned commit: t-shirts (plain, v-neck), polos, buttoned, long-sleeved and
sleeveless shirts, overalls, aprons, suspenders, pants, cuffed pants, shorts, basic
and rimmed boots, shoes, bandanas, headbands, the cloth hood, plain glasses, the
plain cloth face mask, gloves, leather armour, beards and moustaches, short hair
(buzzcut, plain, curly short, short dreadlocks (CC0), half-messy), the
`hat_helmet_xeon` sci-fi helmet, and the human, elderly and gaunt heads.

**In LPC but not eligible** (offered only under CC-BY-SA/GPL or OGA-SA for these
files): open and closed vests, the trench coat, the tabard, the bowler, sunglasses,
shades and round glasses, necktie and scarf. Several current recipes name the open
vest, trench coat or tabard, but the build never drew them (see
[ENEMY_INVENTORY.md](ENEMY_INVENTORY.md), "Recipe parts that are not drawn").

**Not in LPC at all:** baseball or work caps, hard hats, beanies, hi-vis or
tactical vests, riot armour, gas masks, police caps, robots, large creatures.
Where a design needs one of these, it either uses the nearest LPC part named in
the specification, or is marked **non-LPC art needed** (an owner decision: draw
it in LPC style, commission it, or find a CC0/OGA-BY source).

## Factions

| Faction | Where | Members | Base palette (cloth) | Signature | Notes |
|---|---|---|---|---|---|
| South Street Gang | South Street (story), Saltmarket Backlots, Rail Sidings | Dock Thug, Bottle Thrower, Night Market Punk, Pipe Brute, Rail Bruiser, Refinery Enforcer (elite), Pit Champion (mini-boss), Furnace Baron (boss) | charcoal, gray, black, walnut; accent **red** | red bandana or headband | street clothes and work clothes; the Baron's people wear his maroon |
| Port Dock Crew | Port District, Harbour Stacks | Stevedore, Dock Slinger, Dock Thug, Port Guard (elite), Harbourmaster Chen (boss) | navy, teal, slate; accent **orange** | orange work shirt | the port's guards in navy buttoned shirts with gloves and a bandana in the port orange |
| Plant Security | Industrial District, Plant Outskirts | Plant Guard (elite), Hazmat Sprayer, Security Chief Nattapong (boss) | slate, gray, black; accent **yellow** | yellow (hazmat suit, yellow trims) | plant security uniform: slate buttoned shirt, black pants |
| The Black Network | The Black Network, Network Backrooms | Network Runner, Network Enforcer, Ring Fighter (elite), The Ringmaster (boss), Big Sak (boss) | black, charcoal, maroon; accent **purple** | purple shirt, plain glasses on the money men | money people in buttoned and polo shirts; ring fighters bare-chested with headbands |
| Facility Security | The Core Facility, Facility Annex, Main Control Centre | Facility Trooper, Riot Trooper (elite), Commander Arthit (boss) | slate, bluegray, black; accent **white** | `hat_helmet_xeon` helmet | the only faction with helmets; officers without helmet |
| Hybrids (victims) | The Core Facility, Main Control Centre, world boss | Hybrid Worker, Subject 12 (boss), Hybrid Brute, Subject Zero (world boss) | the clothes they worked in (overalls, white lab-issue shirt); skin `pale_green` | gaunt human head, pale skin, worn work clothes | people, not monsters: no orc heads, no claws; they look ill |
| Machines | Industrial District, Core Facility, Main Control Centre, world boss | Patrol Unit, Unit K-7 (boss), Core Sentinel (elite), The Iron Colossus (world boss) | steel gray, black, facility white | lights, plates, no face | **non-LPC art needed**: LPC has no robots |
| Creature | The Great Drain (world boss) | The Tunnel Mother | tar black, sludge green | huge, low, many-limbed | **non-LPC art needed**: LPC has no large creatures |
| Director | Main Control Centre | Director Wiroj (final boss) | white shirt, black coat | glasses, elderly head | keep as is |

## Farming grounds

Each farming ground uses its district's faction ([STORY_BIBLE.md](../STORY_BIBLE.md)
lists them): Saltmarket Backlots and Rail Sidings → South Street Gang; Harbour
Stacks → Port Dock Crew; Plant Outskirts → Plant Security and Machines; Network
Backrooms → The Black Network; Facility Annex → Facility Security and Machines;
Core Overflow → Facility Security and Machines. No Hybrid fights in a ground.

## The four painted enemies (owner decision)

Smogling, Tar Rat, Smog Warden and The Sludge Foreman were redrawn by the project
owner (painted with the owner's AI tools, imported by `tools/assets/custom_import.py`)
and match their Story Bible descriptions closely. They are a different style from
the LPC characters (high-colour painting) and are credited "Proprietary (project
owner)", which is outside the CC0/OGA-BY selection. Two consistent options:

1. keep the painted look for these four (they are the "Murk" and sewer-gang look
   of South Street), and accept a second style in that faction; or
2. redesign them in LPC style with the parts in the specifications.

This guide does not decide it; see the specification entries marked
**owner decision**.
