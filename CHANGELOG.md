# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer.

## [Unreleased]

### Changed: the HUD map strip is a route card players can read at a glance
- **Before:** a row of unlabelled dots with no district name and no count.
  Players could not tell where they were.
- **Now** (`MiniMap.gd`, top right), two lines:
  - The district, then the area and its level ("SOUTH STREET   Depot Yard ·
    Lv 1").
  - The route, one node per area: ⌂ town, ○ area (filled once reached), an
    orange ▲ where the hero is, and the district's last area as a red ☠ BOSS
    (grey with a tick once beaten). The goal flies a gold flag. The way
    travelled is solid and the way ahead dashed.
  - A red bar on the road just east of the hero while the way on is still shut.
  - "GOAL" with an arrow, under BOSS, when the goal lies in another district.
  - A long district and area name never run off the card: the area name is
    shortened and the level always shows.
  - Under each node, the area's number in the district (1, 2, 3 …, the hero's in
    orange). The names stay, because quests and the story send the hero to
    places by name.
  - Hovering a node names its area, its boss and whether it is the goal. A tap
    still opens the map.
- `MapRules.boss_of` is now public.

### Fixed: nothing a player owns can be lost
- **Safe saves:**
  - A save is written to a temporary file and read back before it replaces the old
    one. A full disk or a quota error never truncates a good save.
  - The previous save is kept as `<id>.json.bak`. If the save cannot be read, the
    newest of the `.tmp` and `.bak` copies is used.
- **Unreadable characters are kept:** a corrupt save, or one from a newer build, is
  shown as "This save cannot be read" on the Characters screen. It is not hidden.
  - It still holds its slot, so a new character can never be made that then
    fails to save.
  - It can be deleted, which moves it aside.
- **Unknown items are kept:**
  - Items this build does not know (renamed, removed, or from a newer build) are
    parked in `unknown` with their upgrades, saved unchanged, and come back when a
    build knows them again.
  - Worn gear that no longer fits its slot goes to the bag. Before, it vanished.
- **Ground loot:**
  - Loot left on the ground is picked up automatically on leaving an area (taxi,
    recall, getting up, auto battle).
  - Picking something up saves at once.
- **More saves:** the game also saves every 20 seconds and when the tab is hidden or
  the window closes.
- **World boss:** a fight cut short by a closed tab or a crash is banked the next
  time the game starts.
- **One tab:** only one browser tab may hold the saves (Web Lock). A second tab says
  "Already open" and writes nothing, so two tabs can no longer undo each other's
  progress.
- **Old save:** the old single save can never overwrite a character it was already
  imported as.
- **Money rules:** the knock-out penalty and all fares (taxi, world boss ride, auto
  battle's ride back) moved to `sim/EconomyRules.gd`, so the server can apply the
  same rules.

### Fixed: upgrade review
- **Loading a save:** upgrades are kept only on a copy of its own (`#n` key) that
  the hero still has. A level on a plain item id would upgrade its whole stack
  again.
  - A copy found both worn and in the bag is kept in one place, the worn one.
  - A new copy never takes a key left over from an old upgrade or pity entry.
- **Item card:**
  - The comparison counts upgrades on both sides ("Compared with Foreman's Wrench
    +5").
  - A carried upgraded copy shows "Upgraded +N" and what it adds.
  - The note under the upgrade now says upgrades stay with the item. It used to
    say they stay with the slot.
- **Losing an upgraded copy:** the Sell tab shows "+N" on upgraded copies.
  Discarding one asks "Discard +N for good?".
- **Workbench:** says why nothing happened on an item that is already fully
  upgraded, or on an empty slot.

### Added: up to four characters per account
- **Before:** there was one save. Making a new hero replaced it, so a level 20 hero
  was lost when a new one was started.
- **Now:** every character has its own id and its own save file
  (`user://characters/<id>.json`). Making a new hero never touches another.
  - **Id:** 16 random hex digits, 64 bits, from `SaveStore.new_id()`.
  - **Rules:** `sim/RosterRules.gd` holds the id format, the limit (`max_characters`
    in progression.json, 4) and the rule that names must differ within an account,
    so the server can apply the same ones.
- **Title screen:** Continue plays the character played last. **Characters** lists
  every character with its look, hero, level, area and when it was last played.
  Click a card to choose it. Play, Enter or a double click plays it. A free slot
  makes a new character.
  - Delete asks a second time, by name.
  - A deleted character's file is moved to `characters/deleted/`, never erased.
- **Old saves:** the single save of earlier builds becomes the first character the
  first time the game starts. It is kept as `save.imported.json`.
  - Its id comes from its content, so it is never imported twice, even if the
    rename fails or it is carried over from the old data folder again.
  - An unreadable old save is set aside as `save.unreadable.json`.
- **Full account:** a fifth character is refused at save time, and character
  creation says that all slots are in use.
- **Separation:** items, upgrades, coins and quests belong to one character. A test
  checks that nothing leaks between two characters. A save whose content names a
  different id from its file name is refused.
- **Online plan:** BLUEPRINT.md sets out how the server will key characters and item
  copies, by (character id, copy key).

### Fixed: upgrading one item no longer upgrades every copy of it
- **Before:** upgrades were kept per item id, and identical items stack under one
  id. Upgrading the worn wrench to +10 showed, and gave, +10 on all 17 wrenches in
  the bag.
- **Now:** an upgrade belongs to one copy.
  - Untouched items still stack.
  - The first workbench attempt on a worn item makes it a copy of its own, under the
    key `"<item id>#<n>"`. Identical items in the bag stay +0.
  - An upgraded copy has its own cell in the bag and its own line in the Sell tab.
- **Save v10:** each old shared upgrade goes to one copy, the worn one if there is
  one, else one from the bag. The other copies are +0.
- **Code:** `ContentDB.item()` and `sources()` accept copy keys.
  `PlayerProfile.owned()` counts every copy.

### Fixed: blows land when the fist is out, not while it is raised
- **Before:** an attack animation played at an even pace over the whole move. A
  haymaker's damage showed while the fist was still raised beside the head.
- **Now:** each LPC attack animation names its contact frames (`contact` in the
  recipe and manifest). The game plays the wind-up over the move's start-up, the
  contact frames while the hit can land, and the rest over the recovery.
- **Who gets it:** every character, heroes and monsters, for light, heavy, swing
  and stab.
- **Tests:** the contact frames show on the hit tick, and they are where the hand
  reaches furthest forward.

### Added: selling, and a shop screen that always shows its Buy button
- **Sell tab** (Q/E switch tabs). A shop pays 30% of the price (`sell_rate` in
  progression.json). It never buys evidence or worn gear. Rare gear and upgraded
  items ask "Sure?" first.
- **Upgrades:** once the last copy of an item is sold or thrown away, its upgrades
  go with it, so an item bought back starts at +0.
- **Deal bar:** the amount, total and Buy/Sell button sit at the bottom of the shop
  window, under the scrolling item card. Before, a long card pushed the Buy button
  off screen.
- **Amounts:** food and materials can be bought or sold several at a time with
  -, + and Max (Left/Right on the list). Gear is bought one at a time.
- **Code:** the shop has its own screen (`ShopScreen.gd`, with the window's ×
  button). Its rules live in `sim/ShopRules.gd` (buy by amount, `sell`,
  `sell_price`, `affordable`) so a server can run the same ones later.

### Added: drag and drop in the bag
- Drag gear from the bag onto its slot, or onto the hero, to wear it. Drag worn gear
  onto the bag to take it off.
- While dragging, the slots the item can go to light up.
- Right click wears gear, eats food, or takes worn gear off, without opening the
  card.
- `tools/web-smoke/shots.ts` gains mouse `down`/`move`/`up` steps for drag shots.

### Fixed: skills and heavy blows are thrown with the right hand
- The `heavy` animation, played by heavy attacks and most skills, was LPC's `slash`.
  In side view that move strikes with the far arm, so fighters punched, and swung a
  held weapon, with the left hand.
- `heavy` is now built from the right-hand half-slash for every LPC character,
  monsters included:
  - a wind-up;
  - the right fist raised beside the head and held a beat, borrowed from spellcast
    like the weapon swing;
  - the strike forward;
  - a follow-through.
  The left fist stays at the chest, and a held weapon stays in the right hand.
- A pipeline test fails if any blow is again built from a move that strikes with the
  left arm.

### Fixed: upgrades stay with the item
- Upgrades now belong to the **item**, not the equipment slot. Save v9 moves each
  slot's level onto the item worn there. A +9 weapon taken off keeps its +9 in the
  bag, and the empty slot no longer shows a +.
- The worn slot's +N updates the moment an upgrade lands, without reopening the menu.
- Thirty-four pieces of gear that borrowed another item's picture now have their own
  icon (`tools/assets/gear_icons.py`).

### Changed: every screen does one job
- Character (C), Bag (B), Quests (O), Map (M) and Settings each open in their own
  window with an icon, a key cap and a × button, instead of sharing one tabbed pause
  window. A screen's key toggles it.
- Esc opens a short pause menu: Resume, the five screens, return home, save, and
  save and quit.
- The HUD gets a small menu bar: five 20x20 icon buttons, bottom right, with the
  key in each tooltip (`tools/assets/menu_icons.py`).
- The AUTO switch is a small round icon button. It glows, and its arrows turn,
  while auto battle runs. The status and tally text lines are gone from the HUD;
  the tally sits in the tooltip.
- Auto battle messages are shorter and plainer ("Auto on. Move or attack to take
  back control.").

### Changed: weapon blows and throws raise the weapon beside the head
- A new body animation, **`swing`**, plays for every weapon blow and throw:
  - bottle, plank, pipe, machete, chair, frying pan, wrench and bat;
  - the hero's weapon throw, and the bottle lob of the enemies who throw.
- **The motion:** wind up, raise the weapon beside the head, bring it down
  forward, level with the ground at the hit, then follow through. The left fist
  stays at the chest.
- **Who gets it:** every LPC character (heroes, enemies and anyone added later). It
  is built from LPC's half slash, with the raised frame borrowed from LPC's
  spellcast.
- Painted custom sheets fall back to their light attack.
- **Grip:** the weapon's angle follows the swing, and the fist is drawn over the
  handle, so the grip is always in the hand.
- **New `lpc_build.py` option, `borrow`:** puts a frame of another LPC move into an
  animation. It can erase parts of that frame and patch in pieces of others.
- Tests cover the swing's wind-up, raise, hit and follow-through, the fallback,
  and that every armed body has a hand socket per frame.

### Changed: the gallery is a proper browsing screen
- The title's **Characters** button is now **Gallery**. Before, items and characters
  were drawn over each other and the page could not scroll.
- **Characters tab:**
  - The roster on the left, grouped into heroes, people, enemies and bosses, each listed
    by name.
  - The chosen character stands large on a stage, with a button for each animation.
    One-shot moves return to idle.
  - Its source, licences and artists are shown below.
- **Items tab:**
  - Every item as slots, grouped by rarity (with counts) and sorted by type and name.
  - The chosen item shows its card and how it looks lying on the street.
- Works with keyboard and gamepad: arrows move, Q/E switch tabs and Esc goes back. The
  lists scroll to follow the focus.
- A UI test checks every character and item is listed, that selecting one plays it,
  and that the layout fits the screen.

### Changed: Riku has a new streetwear look, built from LPC
- Riku the Boxer is now built from LPC parts like the other heroes, so he has the same
  proportions and face style as the team.
- His outfit:
  - a white snapback with a hot-pink brim and a gold badge;
  - a hot-pink open top over a white tee, with a gold chain;
  - charcoal cuffed pants and white shoes.
- The owner-supplied sheets are no longer used.
- **Two new recipe options in `lpc_build.py`** restyle LPC parts without adding frames:
  - A recolour can give its own palette (hex colours, darkest first), for colours LPC
    lacks, such as hot pink.
  - `"cap"` turns the top of the hair layer into a snapback, shade for shade. The brim
    goes at the front in side views and along the crown in front views; it is left off
    when the hero lies on the ground.

### Added — City map
- **Map tab** in the pause window; **M** (gamepad: press the right stick) opens and
  closes it.
  - Shows where the hero is: the area, its level, and its district with the hero's place
    in it (e.g. "Port District 2 / 4").
  - Shows the goal: the tracked quest's area, the giver once the quest is done, or the
    next quest's giver.
  - The street is laid out in six districts, one row each, plus the world boss arenas
    once unlocked.
  - Each area's level is coloured by danger. The map marks the hero, the goal, towns
    (shop, quests, taxi) and bosses (green once beaten).
  - Only areas the hero has reached, and the next one east, are named. Further areas
    show `???`, and so does a district with nothing known.
  - Moving across the boxes shows what is known of each area: services, the boss, and
    why a gate is still shut.
- **HUD map strip** under the area name:
  - top line: the district's areas as dots, with the hero and the goal (or an arrow
    pointing to it);
  - bottom line: this area from west to east, with the fights still to win, a shut
    gate, and where the hero stands.
  - Tap it to open the map.
- Entering an area now also names its district, e.g. "Saltmarket Street · South Street
  2/11".
- **Data:**
  - `areas.json` `districts` defines the districts.
  - Every quest objective names its `area`.
  - `ContentDB` checks that districts run in street order and that each quest's area
    actually fields its target.
- `MapRules` (`client/sim/`) is pure and saves nothing new. Tests are in
  `tests/unit/test_map.gd`.

### Added — Group world bosses: The Iron Colossus and Subject Zero (decision D14)
- **The Iron Colossus**: Kraisorn's prototype security walker, woken in the Old Scrapyard.
  - For heroes of level 40 and up; it fights at level 52.
  - Built for 5 players; out every 6 hours.
  - Mechanics: lasers, shocking floor plates and falling scrap, a shield phase, and Core
    Sentinels called in.
- **Subject Zero**: the first worker The Core changed, broken out of the Sunken
  Reservoir.
  - For heroes of level 48 and up; it fights at level 55.
  - Built for 10 players; once a day at 20:00 Thailand time.
  - Mechanics: sludge, steam and lasers, a shield in its last phase, and Hybrid Brutes.
  - Both unlock after Director Wiroj, and each phase brings new heavy blows.
- **Group-sized pools, two kinds of reward** (`WorldBossRules`):
  - **Personal tiers** are measured against one player's part of the pool (the pool
    divided by the players it is built for). A player who pulls their weight earns
    every tier whatever the others do.
  - **The kill** is paid to everyone who fought, once the whole pool falls within the
    round.
- **Four new legendaries, rare and hard to get:**
  - Colossus Core and Piston Gauntlets (level 45);
  - Zero's Mantle and The Iron Legacy (level 50).
  - The top personal tier rolls them at 1–2%, the kill at 3–8%. A test checks the drop
    rate over 400 kills.
- **Built for groups, on purpose.** Measured with the auto-battle pilot, a level 50 hero
  alone deals about 6–13% of their part per Colossus attempt and 5–7% per Subject Zero
  attempt even in full end-game gear, and is usually knocked down. Alone, these bosses
  cannot be killed within a round. Their kill drops become reachable when online play
  arrives (IL-7), with the same rules on the server.
- **One schedule per boss** (`offset_minutes`); Win's taxi lists every unlocked boss
  with its level and group size. **Save version 8** keeps a round per boss and moves a
  version 7 round to the Tunnel Mother.
- Tests: the level gate and fixed level, Subject Zero's daily opening, tiers by one
  player's part, the kill paid once, the rarity of the drops, and the v7 migration.

### Added — World boss: The Tunnel Mother (decision D13)
- **The Tunnel Mother**, a giant mutant grown from The Core's sludge, rises in **The
  Great Drain** on a real clock: every 3 hours, for 1 hour. It unlocks once Unit K-7 is
  beaten. While a round is open, Win's taxi offers the ride, and a toast announces it.
- **One health pool per round**, 14 times a boss of her level. Each attempt lasts 2½
  minutes, and the damage adds up across attempts until she falls. She fights two levels
  above the hero (minimum 26), so she is worth fighting from Chapter 4 to level 50.
- **Five reward tiers** (5%, 15%, 35%, 60% and 100% of the pool dealt), each paid once
  per round. Coins grow with her level, and the higher tiers can roll the two new
  legendaries: **Mother's Fang** (weapon) and **Mother's Heart** (charm).
- **Her mechanics:** sludge geysers (the new `sludge` hazard kind) and Tar Rat broods,
  both faster as she weakens, with a new heavy attack in each of her three phases.
- **Attempts:** a results screen after each one shows the damage, the round so far, the
  next tier and what was won. Being knocked out there costs nothing. The HUD shows the
  attempt's clock and how much of her is left. Auto battle is not allowed against her.
- **Save version 7** keeps the round's progress; older saves start fresh.
- **Ready for online (ARCHITECTURE D8):** `WorldBossRules` and `WorldBossRun` are pure,
  with the time passed in. At IL-7 the server keeps one pool for all players using the
  same rules.
- **Bosses no longer show their name overhead.** The boss bar already shows it and the
  level, and on a giant boss the overhead label was huge.
- **Measured** with the auto-battle pilot and no gear: one attempt takes 12–22% of the
  pool at every level from 26 to 50, so a round takes about seven attempts, fewer with
  gear.
- **Tests:** the round clock; the unlock; level scaling; tiers paid once per round and
  reset next round; an attempt fighting the round's pool; ending on the clock; the taxi
  offering it only while open; the results screen instead of the game-over; the arena
  never entered without an attempt; and the round surviving a save and v6 migration.

### Added — Final chapter: The Iron Legacy, and the Epilogue (IL-5: main story complete)
- Four areas past the Control Room, open once Commander Arthit is down:
  - **Core Approach** (level 42)
  - **Cooling Tunnels** (44)
  - **Reactor Walkway** (46)
  - **The Core Chamber** (48)
- **Dr. Pim** gives the last quests: The Last Door, Cooling Down, The Walkway and The
  Iron Legacy. **Ama** brings South Street's supplies to the front line, selling level
  42–44 gear, and Win's taxi waits at the approach.
- New enemies: the **Core Sentinel** (elite machine Wiroj built to guard himself) and the
  **Hybrid Brute** (the longest-exposed workers).
- **Director Wiroj**, at the level cap (50), in three phases (story bible §4):
  1. His own blows, each heavy one announced.
  2. Below 70% health, the chamber's defences come up in turn: a steam vent, shocking
     floor plates, a sweeping laser. He waits behind a shield, untouchable for 7
     seconds, then the system resets for 5 seconds and he can be hit.
  3. Below 30%, the defences fail and he fights desperately: long lunging heavies with
     long recoveries to punish.
- **Epilogue: A City That Remains**, shown after he falls: what became of Ama, Chief
  Odo, Dr. Pim, Big Sak, Nattapong, Kraisorn, the night shift and the canal. The game
  then goes on: farming, enhancing and levelling to 50.
- Boss mechanics (`BossMechanics`):
  - a `cycle` of hazards called in turn;
  - per-phase `hazard` (`{}` turns them off);
  - a per-phase `shield` with `up` and `down` ticks, untouchable and standing back while
    up;
  - the new hazard kind `shock`;
  - a `boss_shield` event with a dome on the boss and toasts ("Defences up. Survive!" /
    "System reset. Strike now!").
  All are validated on load.
- Balance: the Hybrid Brute uses a regular telegraphed slam. Subject 12's long lunge
  stays his own, since in a crowd it took a quarter of the hero's health a hit.
- XP pacing: a straight run keeps the hero within two levels of every area to the Core
  Chamber.
- Measured with the auto-battle pilot, hero one level above each area, no gear, 10 of
  the food the loop would buy: 85 of 90 seeded runs clear from the Test Labs to the Core
  Chamber. The final chapter is the hardest, as it should be. With no food, Wiroj ends a
  close fight like every chapter boss before him.
- Tests: the street ends in the Core Chamber; Wiroj fights at the cap; three distinct
  phases; phase 1 without defences; the shield's rhythm (up, reset, up; no new hazards
  while reset); the defences in turn; the last stand without them; the epilogue plays
  and the game goes on.

### Added — Chapter 5: The Core Facility (IL-5)
- Four areas past Rattanachai Tower, open once Big Sak is down:
  - **Core Facility Gate** (level 33)
  - **Test Labs** (35)
  - **Machine Hall** (37)
  - **Control Room** (39)
- **Dr. Pim** gives the chapter: Facility Breach, Subject 12, Machine Hall and Commander
  Arthit. **Lek**, a laid-off lab technician, sells level 33–35 gear, and Win's taxi
  stands at the gate.
- New enemies: the **Facility Trooper**, the **Riot Trooper** (elite, heavy armour) and
  the first **Hybrid Workers**, workers The Core changed. Dr. Pim and the Exposure Report
  explain them (story bible §6), and they appear only in the facility.
- Two bosses:
  - **Subject 12**, mid-chapter: a lunge with a long reach and a frenzied sweep when
    hurt. Beating him hands over the **Exposure Report**: the change reverses if the
    exposure stops.
  - **Commander Arthit**, at the end: security **lasers** that sweep the whole street at
    the hero's depth, so the escape is a lane change or a roll, not walking away. He
    calls in a trooper too, and both come faster once he is enraged. Beating him hands
    over the **Core Source Data**.
- The hazard system gains the `laser` kind. Warnings now carry their footprint, so the
  red mark on screen is the size of what it hits. `CraneDrop` becomes `HazardView` (it
  draws all three kinds).
- Auto battle escapes a hazard the quicker way, along the street or across the lane, and
  rolls when it is too late to walk.
- **Fix:** the pilot could stall forever when pinned between a crate and the lane's edge
  (it tried to go round the far side, through the crate). It now passes obstacles on the
  side it is already on, or backs off and goes round.

### Changed — XP pacing for the late game
- XP curve squared term 6 → 5: late levels were costing more than the areas pay, so the
  hero fell 3 levels behind by the Test Labs.
- Two Chapter 1 quest rewards were trimmed (The Pit 850, Rat Nest 520), and Chapter 5's
  trooper and hybrid XP was set for its two-level steps.
- A straight run now keeps the hero within two levels of every area, Depot to Control
  Room (`test_levels`).
- Measured with the auto-battle pilot, hero one level above each area, no gear, 10 of
  the food the loop would buy: 126 of 126 seeded runs clear every area from the Crane
  Yard to the Control Room. With no food, each chapter boss ends a close fight (13–29%
  of its health left on average when it wins).

### Added — Chapter 4: The Black Network (IL-5)
- Four areas past the Factory Drains, open once Unit K-7 is down:
  - **Warehouse Row** (level 26)
  - **The Underground Ring** (27)
  - **The Counting House** (29)
  - **Rattanachai Tower** (31)
- **Kenji**, exposed as a one-time courier for the network, gives the chapter's quests to
  make it right: Follow the Money, The Ring, Cooked Books and Big Sak. **Uncle Thong**
  sells level 26–27 gear, and Win's taxi stands at Warehouse Row.
- New enemies: the **Network Runner** (fast, bare-handed courier), the **Network
  Enforcer** (heavy) and the **Ring Fighter** (elite).
- Two bosses:
  - **The Ringmaster**, mid-chapter, with a spinning kick that reaches both sides.
  - **Big Sak**, at the end. He whistles in his runners, two at a time and never more
    than two standing, and more often once enraged.
- Evidence: the **Money Trail** names Director Wiroj for the first time, and the **Core
  Facility Pass** leads to Chapter 5.
- **Boss mechanics moved out of ZoneSim** into `BossMechanics` (hazards plus the new
  `summon`, validated on load, only for bosses), with no change to how hazards play.
  The new `boss_summon` event shows a "calls for backup!" toast.

### Added — Food that scales with the hero
- **Rice Box** (heals 120) and **Herbal Tonic** (heals 220, plus energy), sold from the
  Depot onwards and dropped by later enemies. Steamed buns alone heal about 6% of a level
  30 hero.
- `FoodRules` picks what to eat: the smallest food that covers most of the wound, or the
  biggest when in trouble. The quick-heal key (H/Q) and auto battle both use it, so the
  quick-heal key now eats every kind of food, not just buns and tea.
- The farm loop buys food sized to the hero (about a third of their health per bite)
  instead of always the cheapest.
- Measured with the auto-battle pilot, hero one level above the area, no gear, 10 of the
  food the loop would buy: every hero clears every area from the Crane Yard to
  Rattanachai Tower (108 of 108 seeded runs). With no food at all, Big Sak and Unit K-7
  are about equally hard.
- Tests: Chapter 4's order, levels, quest chain and evidence; the Director kept out of
  earlier chapters; the Ringmaster's gate; Big Sak's whistle (count, limit, quicker when
  enraged, silent once he falls); summon validation; and food choice, shopping, restock
  and the quick-heal key.

### Added — Auto battle (decision D12)
- **Auto battle** (T, gamepad Back/Select, or the AUTO button under the hero card). It is
  allowed only in areas the hero has already beaten by hand: the next area east has been
  reached, or, at the end of the street, its bosses have been beaten. Elsewhere the
  button is dimmed, and pressing it says why. Any input of the player's own takes over
  for that tick.
- The pilot (`client/sim/AutoPilot.gd`) plays like a careful player. It is deterministic
  and only sends player input:
  - eats below a set health share, picking the smallest food that covers the loss and
    the biggest one in real trouble;
  - steps out of crane and steam shadows, sidesteps or blocks thrown weapons;
  - dodges guard breakers and telegraphed heavies, or walks out of their reach when
    there is time, and stops queuing combo links while one is coming;
  - guards plain blows just before they land (a perfect guard parries), and hits first
    when its jab is quicker against a foe that flinches;
  - picks skills from each hero's own move data: area skills into crowds, finishers saved
    for three foes or a boss, and always energy kept for a dodge;
  - chains light combos into a heavy finisher, and targets close, hurt or unguarded
    ranged foes;
  - between fights, picks up a street weapon, collects drops (giving up on any it cannot
    reach), walks around street furniture and on to the next fight.
- **Farm loop.** When an area is clear, or the hero is hurt with nothing left to eat, the
  hero goes home to rest. It buys food at home up to a set stock, always keeping the taxi
  fare, rides Win's taxi back and goes again. The HUD shows what it is doing and the
  session's runs, KOs, coins and XP. Settings are on the pause menu's Game tab: the
  health share to eat at, the loop on or off, and the food stock to keep.
- **Measured** with a hero one level above each area, no gear and 10 buns:
  - every hero clears every Chapter 1 to 3 area alone, bosses included (88 of 90 seeded
    runs in the five hardest areas);
  - 20 minutes of the farm loop gave 13 to 15 runs and 200+ KOs per hero, with no
    knock-outs.
- Tests: auto is allowed only where beaten; every hero clears a street alone and picks up
  the drops; eating; area skills on a crowd; the big skill saved for bosses; dodging and
  parrying; hazard shadows; the loop rules and the full loop through the game; the
  player's input winning; the HUD switch.

### Changed — Levels 1-50, climbing chapter by chapter (decision D11, replaces D9)
- The hero now levels up to **50**. Each chapter has its own level band: South Street
  areas run levels 1-10, the Port District 12-16 and the Industrial District 19-24.
  Elites fight one level above their area and bosses two (`LevelRules.enemy_level`;
  `level_bonus` still overrides). Item level requirements, weapon `min_level` and quest XP
  follow the new bands.
- Enemies grow at the hero's pace: per level +6% health (the hero's damage grows about
  as fast) and +8% damage (the hero's health grows about as fast), +1 defense every 8
  levels. An enemy at the hero's level is about as hard at level 40 as at level 4; the
  gap decides, and gear and enhancing keep the hero ahead.
- Brains sharpen slowly instead of peaking by level 13: reactions and attack pauses
  shorten 1.2% per level (at most halved), guarding starts at level 4, picking up weapons
  at 6 and dodging at 9. Chapter 1 enemies stay simple-minded.
- **Name colours by level gap** over every enemy and on the boss bar (which now shows
  the boss's level): grey (6+ levels below the hero), green (3-5 below), yellow (within
  2), orange (3-5 above), red (6+ above).
- XP depends on the gap too: grey foes pay 10%, green 60%, yellow 100%, orange 120%, red
  140%. Money is unchanged, so old streets can still be farmed for coins.
- XP curve `100 + 100·(L-1) + 6·(L-1)²` per level (new optional `square` term in
  `progression.json`), tuned so that clearing each area once and handing in its quests
  brings the hero in within two levels of every area.
- Tests: elites and bosses fight above their area, chapters stay in their bands, early
  enemies are simple-minded, an even-level fight stays fair from level 1 to 50, name
  colours, XP by gap, and a straight run keeps the hero near each area's level.

### Added — Return to the Depot Yard from the pause menu
- **Return to Depot Yard** (pause menu, Game tab) takes the hero straight home to upgrade
  gear at the workbench, shop and rest. Arriving heals and brings every street's fights
  back, as walking in would. Win's taxi rides back out to any area reached.
- It is never an escape from a fight: greyed out, with the reason shown, during a fight
  (bosses included), while knocked down, or at home already (`ZoneSim.recall_problem`).
- Tests: recall takes the hero home rested; there is no recall mid-fight; the menu offers it
  only when allowed.

### Added — Chapter 3: the Industrial District (IL-5)
- Four areas past the Crane Yard, open once Harbourmaster Chen is beaten: **Factory Gate**
  (level 14), **Production Line** (15), **Waste Pools** (16) and the **Factory Drains**
  (17).
- **Dr. Pim**, the former city inspector, gives the chapter's quests (Factory Doors, The
  Chief, Sample Run, Unit K-7). **Aunt Jum** sells level 14-15 gear (Hazmat Hood, Plant
  Security Vest, Insulated Gloves, Lab Boots), and Win's taxi stands at the gate.
- New enemies: the **Plant Guard** (elite), the **Hazmat Sprayer** (ranged) and the **Patrol
  Unit**, the first machine.
- Two bosses:
  - **Security Chief Nattapong**, mid-chapter. Beaten, he takes off his badge and walks
    out (spared).
  - **Unit K-7**, at the end. Its floor vents burst with steam where the hero stands, after
    a warning. The hazard system now has kinds (`"kind": "crane" | "steam"`, validated on
    load).
- Evidence: the **Waste Sample**, then the **Experiment Log**, where the words "The Core"
  appear for the first time. K-7 ends Chapter 3.
- Fixed: the generated street backgrounds no longer crash on a sliver of building at an
  area's end.
- The story test allows The Core from Chapter 3 on, and only in late evidence, as the
  story bible says.
- Art is temporary (D10). The robots are LPC armour builds, and the vents are drawn with
  shapes.

### Added — Chapter 2: the Port District (IL-5)
- Four areas past the Gang Headquarters, open once the Furnace Baron is beaten: **Port
  Road** (level 10), **Freight Market** (11), **Container Yard** (12) and the **Crane
  Yard** (13).
- **Uncle Chai**, the dock canteen cook, gives the chapter's quests (Dock Shakedown,
  Market Watch, Hooks and Wrenches, The Harbourmaster). **Noi** sells level 10-11 gear (Docker's
  Cap, Port Authority Jacket, Cargo Gloves, Deck Boots), and Win's taxi waits at Port Road too.
- New enemies: the **Stevedore** (heavy), the **Port Guard** (elite) and the **Dock Slinger**
  (ranged, throws wrenches).
- **Harbourmaster Chen**, boss of Chapter 2, works the cranes: every few seconds a
  red shadow grows where the hero stands, and a container drops on it after at least a
  second. It hits everyone under it but Chen, his own crew included, and comes faster
  once he is enraged (`hazard` in `enemies.json`, validated on load; `hazard_warn` and
  `hazard_hit` zone events). Beating him gives the **Altered Manifest**, whose new
  destination points to the Industrial District, and ends Chapter 2.
- Art is temporary (decision D10: finish the game first, then one art pass). The new
  characters are LPC builds, the docks reuse kit pieces, and the container is drawn with
  shapes.
- Tests: the port follows the Gang HQ in story order; Chen ends the chapter with new
  evidence; the crane warns, then drops on the hero's spot; stepping out of the shadow is
  safe and Chen is never hit; it comes faster when he is enraged; there is no crane
  outside the boss fight. Ranged enemies are exempt from the heavy-blow pause test by their
  `ranged` block, not by name.

### Added — Painted enemy sheets on a green backdrop (IL-4, D6)
- **Four enemies repainted by the owner, as the story describes them**: the Tar Rat (a gang
  kid in a rubber rat mask and black hoodie), the Smogling (a drifter in a yellow raincoat
  and home-made bottle gas mask), the Smog Warden (grey hazmat suit with a skeleton
  pattern) and the Sludge Foreman (boar-masked boss in suspenders). Their LPC recipes
  are retired, and the hurt and knock-down frames are painted too.
- `custom_import.py` reads sheets of loose figures (`"figures": true`). It finds every figure
  on the green backdrop (grid lines and specks ignored), groups them into rows by where
  their feet stand, scales them so a chosen figure stands a set height (`row_scale`
  evens out rows painted at another size), and anchors each figure on its own feet.
  Animations pick `[row, index]`. Frames the painting got wrong (legs cut by the grid,
  two figures overlapping, a kick split across cells) are left out.
- `custom_import.py` cuts a flat green backdrop out of a painted sprite sheet
  (`"key": true` in `import.json`), like the street kit. The grid is kept, and green
  clothing inside the figure's outline stays green. A pipeline test checks both.
- `docs/ENEMY_PROMPTS.md`: sheet rules and prompts to repaint the Tar Rat, Smogling, Smog
  Warden and Sludge Foreman as the story describes them (rat-masked gang member, drifter in a
  home-made gas mask, hazmat security, boar-masked boss). LPC has no such masks under the
  allowed licences.

### Added — Checkpoints, remembered fights and the motorbike taxi
- **Knocked out, you get up where you fell**: at the west end of the same area, or just
  short of the boss fight you lost, to try again at once. Losing still costs coins.
  Before, every knockout sent the hero back to the Depot Yard.
- **Fights you win stay won** (`StreetMemory`, saved as `cleared`) until you rest at the
  Depot Yard, which brings every fight on every street back for farming coins, XP and
  drops (bosses too; quest rewards and evidence still come once). If an area's fights
  are all won while its gate is still shut, they come back, so a gate always opens
  where it stands.
- **Win, the motorbike taxi** (new LPC NPC in an orange shirt), at the Depot Yard and
  the Night Market: for 10 coins, rides to any area reached before (`visited`), in street
  order. Rest at the Depot first to farm a street from scratch.
- Save version 6 adds `cleared` and `visited`. Older saves load with every fight ready
  and every area up to the saved one reached.
- Night Market: one more Punk in the last fight, so its gate (10 Punks) opens in one
  pass. Before, it only opened by re-entering.
- Tests: won fights stay won and come back after a rest; a shut gate always has fights
  left; every gate opens in one pass; getting up at a boss's door; getting up keeps won
  fights; taxi destinations and fare; a version 5 save loads with its road reached.

### Changed — Skill pacing: heroes faster, enemies and bosses slower (IL-4)
- Every hero's skills come back sooner: regular skills in 2.5–4.25 s (were 4–7 s),
  ultimates in 11–12.5 s (were 20–22.5 s), for all six classes.
- Enemies and bosses can no longer chain their heavy blows. Each waits `heavy_cooldown`
  (in `enemies.json` `ai`, and per boss phase) between heavies: 4.5 s for street gangs,
  5 s for elites and bosses (4.5 s in phase 2), 5.5 s for the Furnace Baron (5 s in
  phase 2). That is always longer than any hero skill short of an ultimate. The Bottle
  Thrower's lob is its basic attack and waits 2 s.
- To keep the bosses a threat without the spam, they throw normal blows about 20% more
  often. The Sludge Foreman hits harder (power 1.3, 1.5 in phase 2, 460 HP), and the Pit
  Champion has 380 HP.
- Scripted-player boss probe (no gear, no food, no parry; 10 seeds per class): the
  Sludge Foreman is won 7–10/10 (was 3–8), the Pit Champion 1–5/10 (was 0–1), and the
  Furnace Baron still 0/10.
- Tests: hero skills come back within 4.5 s (ultimates within 13 s); every enemy's heavy
  waits longer than any hero skill short of an ultimate, bosses 5 s or more; a boss never
  chains heavies.

### Added — The rest of South Street: Parking Lot, Rat Nest, Gang HQ (IL-4)
- **Parking Lot** (level 4), between the Rusted Corner and the Rail Yards: a multi-storey car
  park whose ramps Pipe Brutes guard, with cars parked at the kerb. Quest "Night Shift":
  the refinery man's trucks hand their crates to the freight wagons here.
- **Rat Nest** (level 9), the drainage tunnels under the Refinery: the Tar Rats' lair, in
  the painted tunnel walls, pipes and grates with the wet tunnel floor. Quest "Rat Nest".
- **Gang Headquarters** (level 9), the end of South Street: the Furnace Baron's fortified
  building, behind a steel gate and guard booth. The Baron now fights here and closes
  Chapter 1; at the Refinery his enforcers hold the smelter (quest "The Smelter", gate:
  knock down 5 enforcers) and he escapes into the drains.
- Main quests run in street order: Glass Rain, Night Shift, Rail Yard Rumble, Market
  Lights, The Pit, The Smelter, Rat Nest, The Furnace Baron.
- Tests: the new areas stand in story order, the Baron fights only at his headquarters and
  ends the chapter, one quest chain follows the street, each new area has its own scenery.
  Boss probe: the Baron at the HQ (level 9) is about as hard as he was at the Refinery
  (level 8).

### Changed — Street scale, sidewalk and solid vehicles (IL-4)
- Buildings, shops and lamp posts are sized to the characters: doors are now taller
  than a person (shophouses 280, shops 170, lamp posts 185, power poles 250 game px),
  and buildings may rise past the top of the view. Booths, gates, stalls, the ring and
  the pickup grew to match.
- Fighters cannot walk onto the sidewalk: the kerb is drawn above the fighters' lane.
  Lamp posts, power poles, bins and traffic cones stand on the sidewalk; crates and
  oil drums stand at the kerb, never in the middle of the road.
- Parked vehicles (taxi, tuk-tuk, songthaew, pickup, motorbike, car wreck) are solid
  street furniture placed in `areas.json`, at the kerb of every street but the Fight
  Club. They block as rectangles (`"box"` in `obstacles.json`), so nobody slips
  between a car and the kerb; enemies walk round them. The kit no longer scatters
  vehicles.
- Vehicles are sized for the characters (about 52 px tall): a taxi 64, pickup 72,
  songthaew 78, tuk-tuk 66 and motorbike 48 game px, so a person fits in the cabin
  and on the seat; the skytrain is 80 px on a thicker beam, raised to clear the
  shops.
- A held weapon stays in the same hand in every animation. In the heavy blow the
  weapon now swings with the striking arm instead of resting at the hip while the
  other arm hits (`"hand": "front"` in the recipes' `weapon_pose`; while that arm is
  hidden behind the body the weapon waits where it next shows). The fist closes
  around the middle of the handle and the handle's end shows below it (`handle` in
  `art/weapons/weapons.json`), instead of the weapon starting at the back of the hand.
- The folding chair weapon is film-sized (about 42 px against 50 px characters). A
  painted weapon can ask for a bigger sprite cell (`cell` in
  `art/weapons/weapons.json`), and its grip follows (`weapon_grips` in the manifest).
- Tests: furniture on the sidewalk or at the kerb, the hero stays on the road,
  vehicles block with no gap at the kerb, enemies go round them, the chair's size,
  vehicles sized against a character, the weapon never jumping between hands, and
  every handle showing below the fist.

### Added — Street kit: all 22 pieces from the scene prompts (IL-4)
- Every piece in `docs/SCENE_PROMPTS.md`, painted by the owner and cut out by
  `kit_import.py`: Fight Club (warehouse wall, ring, crowd, work lamps, tyres, chairs),
  Rusted Corner (junk shop, fence, scrap, drums, car wreck), Parking Lot (car park,
  barrier booth, pickup, scooters), Rat Nest (tunnel wall, drain pipe, grate, the
  `tunnel_floor_tile` ground strip) and Gang HQ (facade, steel gate, guard booth).
- Crops drop what the paintings added outside the piece: the smear above the fence and
  the framed lamp section at the left of the crowd.
- Fight Club is now an underground ring: corrugated warehouse walls with work lamps
  strung overhead, the ring, the crowd, tyres, chairs and drums along the back. Rusted
  Corner is a junk-dealers' street: the junk shop and patched fences, scrap heaps, oil
  drums and a car wreck at the kerb. An area's `kit_theme` picks its own kit theme
  (the generated fallback scenery still follows `theme`), and themes can hang pieces
  overhead (`hanging`). Checked in a browser; one new pipeline test.
- The Parking Lot, Rat Nest and Gang HQ pieces are imported but wait for those areas.

### Added — Three more heroes: the Basketball Player, the Police Officer, the Soldier (IL-4)
- **Kan Srisuk, the Basketball Player**: the crowd controller. Crossover (a stunning
  change of direction), Elbow Clear (both sides), Post Up (breaks guard) and Slam Dunk,
  the widest hit in the crew. 110 HP, 105% speed and attack speed.
- **Dao Kittikun, the Police Officer**: defence and counters. Her parry window is 12
  ticks (everyone else 8), Wrist Lock holds a foe longest, Riot Shove floors a crowd.
  120 HP, 95% power. Hardest to play (3/3).
- **Pong Rattana, the Soldier**: once one of his skills starts, nothing interrupts it
  (Combat Elbow, Breach Kick, Shoulder Drive, Ground Pound). Toughest (140 HP, 3
  defense) and slowest (80%). Easiest to play.
- Each hero's edge is data (`heroes.json` `parry_window`, `skill_armor`) used by the
  existing rules, not new combat code paths. All six heroes pass the existing balance
  rules (same-slot skills within 15%, every skill 1.5x the heavy attack, the slot-5
  skill strongest); new tests check every class is in the roster, nobody tops health,
  power and speed together, the Soldier is slowest and toughest, Kan reaches widest,
  Dao parries where others only block, and Pong's skills cannot be interrupted.
- Measured with the same scripted player against the Smog Warden at level 5: Kan
  5.0 s, Dao 5.1 s, Pong 6.1 s (the first three heroes 3.8–4.9 s); all win 20/20.
- Sprites built with the LPC pipeline from licence-cleared layers; twelve new 24 px
  skill icons. Hero creation switches to compact cards when there are more than four
  heroes, so all six fit above the name bar (checked in a browser).
- `docs/SCENE_PROMPTS.md`: painting prompts and rules for the next street-kit pieces
  (Fight Club ring, Rusted Corner junk yard, and the planned Parking Lot, Rat Nest and
  Gang HQ). 5 new tests (225 total).

### Added — South Street grows: Rusted Corner, Fight Club, ranged enemies, a mini-boss (IL-4)
- **Rusted Corner** (level 3, between Canal Works and the Rail Yards) introduces the
  first ranged enemy, the **Bottle Thrower**: it hangs back 80–150 px, lines up in your
  lane, winds up (telegraphed) and lobs a bottle that stuns but never floors and
  shatters where it lands; caught up close it jabs. Its exit opens after 6 throwers.
- **Fight Club** (level 7, between the Night Market and the Refinery) ends in the
  **Pit Champion**, a mini-boss: a jab-cross chain, a telegraphed guard-breaking
  overhand, and below half HP a charging rush. Poise 70. Drops scrap and alloy always
  and the new **Champion's Wraps** (epic hands: attack, crit, attack speed) 25% of the
  time. His exit opens the back door to the Refinery.
- Two new LPC characters built with the asset pipeline from layers already cleared by
  the licence policy (OGA-BY): the red-bandana thrower and the shirtless champion.
  Scenery for both areas is laid out from the owner's kit like every other street.
- Two quests join Chief Odo's chain, voiced like the rest: "Glass Rain" (after the
  Foreman) and "The Pit" (after Market Lights, before the Baron). The story bible maps
  both areas and gives the champion his reason to fight.
- Ranged attacks reuse the throwing system (`ZoneSim` projectiles) instead of a second
  one; the AI is `EnemyBrain._keep_range`; the data (`ranged` on the enemy and its
  `ai`) is validated on load.
- Measured the rules' cost with 10 enemies on screen: 0.30 ms per tick on average
  (PERFORMANCE.md), well inside a 60 fps frame.
- After a fight is cleared, a blinking **GO >>** points the way on (only where the
  street continues east).
- New tests keep the street one connected line with rising levels, every gate
  winnable in its own area, every quest target findable, and check the thrower keeps
  its distance and its bottles stun and shatter. 6 new tests (220 total).
- Measured with a scripted player (no gear, no healing, no parries): the champion is
  as hard as the existing Furnace Baron for that player (both unbeaten), the Sludge
  Foreman is beaten 30–80% of the time. Real tuning needs playtests; recorded in
  docs/BLUEPRINT.md.

### Added — Elites and bosses cannot be pinned by mashing (poise)
- Found while balancing the classes: replaying a fight against the Smog Warden (one
  scripted player per hero, 20 seeds) showed a hero who just mashed light attacks kept
  the elite helpless 60–77% of the fight and was never hit back, which made its
  telegraphed attacks meaningless.
- Elites and bosses now have **poise** (`enemies.json` `poise`: 60 for elites, 80 for
  bosses). Hitstun fills it; past it they shrug blows off for 1.5 s (still taking
  damage, with a warm sheen and steel-grey damage numbers), and they are unflinching
  while winding up a telegraphed attack, so the answer is to dodge, guard or parry.
  A parry still staggers them. Same replay: helpless 39–55%, and at level 5 the elite
  now lands hits. Heroes and ordinary enemies are unchanged.
- The same replay showed why Mika's kills are slowest at level 1: both her starting
  skills knock down, and a floored enemy cannot be hit for 50 ticks. That is the
  intended trade (knockdowns buy safety), recorded in the blueprint rather than
  re-tuned without playtesting. 6 new tests (214 total).

### Added — Gear upgrades at the workbench (IL-3)
- Every equipment slot can be upgraded from +0 to +10. Each level adds 10% of the worn
  item's own stats (penalties are never amplified). Upgrades belong to the **slot**, so
  changing gear never throws them away, and there is no per-item bookkeeping that a
  save could lose.
- Each attempt costs coins and materials (+1: 40 coins and 1 Scrap; +10: 1,100 coins,
  8 Scrap, 3 Alloy) and succeeds at the level's rate (100% down to 20%). **A failure
  keeps the item and the level**, spends only the cost, and adds +5% to the next try in
  that slot until one succeeds. Costs and rates are data (`progression.json`
  `enhance`), validated on load (costs in materials, rates never rising).
- From the worn item's card in a safe area (the Depot Yard): what the upgrades add
  now, the next level's chance and cost (red where you are short), and an "Upgrade
  +N (chance)" button. Success and failure each have a sound and a message; a second
  press within 0.4 s is ignored and every attempt is saved at once. Upgraded slots
  show a gold "+N".
- The rule is `sim/EnhanceRules.gd`: check, pay, roll, apply in one call, with the
  roll from the caller (the server, once online). **Save version 5** stores levels and
  pity; version 4 saves start at +0, values are clamped and unknown slots dropped.
- 9 new tests (208 total).

### Added — Critical hits and attack speed (IL-3, decision D8)
- Two new stats: **Crit** (chance of a 1.5x blow; every hero starts at 5%, Riku the
  Boxer at 8%; capped at 50%) and **Atk Speed** (cuts the recovery after each attack,
  never the wind-up, so combos stay readable; 70–130%). Crits come only from the zone's
  seeded generator, so a fight replays identically; enemies do not crit. No accuracy
  stat: hits are decided by where the blow lands.
- Gear that fits: Lucky Coin, Iron Wraps, Brass Knuckles and the Baron Knuckledusters
  add crit; Fingerless Gloves, Street Runners and the Jade Charm add attack speed.
  Status and item cards show both. Crits show "CRIT" and shake the camera.
- 4 new tests (199 total); Riku's all-rounder test now covers the core stats and
  requires him to crit most often.

### Added — Upgrade materials and "where to get" (IL-3)
- Two materials (new item type `material`): **Scrap Metal** (common; dropped by street
  enemies 15–30%, elites 80%, sold by Ama and Kenji for 30) and **Refined Alloy**
  (rare; elites 25–30%, Kenji for 300). Every boss now guarantees both, so a boss kill
  always pays even when the signature gear does not drop. New icons; materials sort
  between gear and evidence in the bag and can be discarded.
- Item cards show **WHERE TO GET**: who drops it (chance, where they fight), who sells
  it and for how much, which quest gives it. Worked out from the loot tables, shops and
  quests (`ContentDB.sources`), so it can never disagree with them.
- Fixed a test that only passed by luck: it expected the Sludge Foreman's wrench every
  time, which stopped being true when boss loot became farmable. 5 new tests (195 total).

### Added — A tutorial that teaches by doing (IL-2)
- New heroes are walked through the basics in the Depot Yard, one step at a time in
  the quest card's spot: move, punch the dummy (3 hits), heavy blow, a skill, dodge,
  guard (and how to parry), pick up a weapon, throw it, talk to Chief Odo. Each step
  finishes when the player does it, with a chime; the last says the street is open.
- Skippable from the menu (Game tab, "Skip tutorial"). Steps are data
  (`client/data/tutorial.json`, validated on load) and the rule lives in
  `sim/TutorialRules.gd`.
- **Save version 4** stores tutorial progress. Version 3 saves migrate with the
  tutorial marked finished, since those players already know the game; values are
  clamped on load. 7 new tests (190 total).

### Added — Prologue and Chapter 1 told through the quests (IL-2)
- Chief Odo's six quests are rewritten from `docs/STORY_BIBLE.md` as the Prologue
  ("First Night") and Chapter 1 ("South Street"): a shakedown at Ama's stall, a crate
  the crew came back for, masked guards at the canal, forged freight papers, Kenji's
  tip and the Furnace Baron's ledger, which points to the port.
- Quest givers speak: each quest has an offer, a nudge while it is under way and a
  closing line on hand-in (`quests.json` `dialogue`, one or two sentences). Below the
  speech the dialog always spells out the chapter, quest, **Goal** and reward, so
  skipping the words never leaves anyone lost.
- **Evidence** (new item type `key`): the Torn Shipping Label, Forged Delivery Note and
  the Baron's Ledger are handed over on completion ("New evidence: ..."), sorted at the
  end of the bag, readable from the item card and never sold, used or discarded (a
  sim rule, not only the UI). They are not listed as rewards, to keep the surprise. New
  16 px icons drawn by `gen_ui.py`.
- Handing in "The Furnace Baron" shows a **Chapter 1 complete** card naming where the
  trail leads next.
- Tests keep every quest in a chapter with all three lines, keep The Core unnamed in
  quests and items (story bible §7), and reject priced evidence. 6 new tests (183 total).

### Added — The street opens as the story moves on (IL-2)
- Exits east are now guarded: Saltmarket → Canal Works opens once the Smog Warden is
  down, Canal Works → Rail Yards after the Sludge Foreman, Rail Yards → Night Market
  after 8 Dock Thugs, Night Market → Refinery after 10 Night Market Punks (the same
  goals as Chief Odo's quests, counted whether or not the quest is active, so nobody
  has to fight a guard twice). Before, a new hero could walk straight to the level 8
  Refinery. The way back is always open.
- A locked exit's sign turns red and shows progress ("Locked 0/1 Canal Works >");
  pushing on it plays a refusal and says what opens it, once per push.
- Gates are data (`areas.json` `exits.*.requires`: enemy, count, hint), validated on
  load. 5 new tests (177 total).

### Changed — Boss loot is worth farming; heroes have their classes (IL-2)
- Bosses no longer hand out their best item every time: the Furnace Baron drops the
  Baron Knuckledusters (legendary) 12% of the time (was 100%) and the Jade Charm 20%
  (was 50%; his quest still gives one), the Sludge Foreman his Foreman Wrench (epic)
  30% (was 100%). Bosses respawn on re-entry, so they can be farmed. A test keeps every
  epic or legendary drop at 35% or less.
- Heroes carry their class (decision D3): Mika is **The Footballer** (new bio and
  tagline: sweeping kicks and line-breaking charges), Oren **The Street Brawler**,
  Riku stays **The Boxer**. Display text only; saves are unaffected. 1 new test (172 total).

### Changed — The game is now *The Iron Legacy* (IL-2, decision D1)
- Project name, browser tab, title logo ("THE / IRON / LEGACY") and credits. The title
  tagline promises only the street ("Take Iron City back, one street at a time"), since
  the story bible keeps The Core secret until chapter 3. The README is retitled.
- **Saves survive the rename.** Godot names the user data folder after the project, in
  the browser too (checked in Chromium: a save made by the old build was not seen by
  the renamed one). `SaveStore` now copies `save.json` and `settings.json` from the old
  "Ironbound Streets" folder on first start, never overwriting a newer file and never
  deleting the original. Verified in a real browser: a save made by the old build
  continues in the new one. 3 new tests (171 total).
- Internal names stay (`window.ironboundProbe`, the API image name), as renaming them
  changes nothing a player sees.

### Added — The Furnace Baron charges; fair-fight rules (IL-1)
- Below half HP the Furnace Baron no longer just hits harder: he charges (new
  `baron_rush`: 24 ticks of warning, carries him 110 px, breaks guard, knocks down) and
  is left open for 40 ticks after it. Enemy AI now starts lunging attacks from the range
  the lunge covers, so a charge is seen coming instead of starting point-blank.
- `tests/unit/test_fairness.gd` turns the blueprint's quality bar into rules every enemy
  must pass: openers that floor or break guard are telegraphed with at least 16 ticks of
  warning, telegraphed attacks leave at least 20 ticks to punish, and every boss phase
  adds a new attack. 4 new tests (168 total). This completes milestone IL-1.

### Added — Throw the weapon in hand (IL-1)
- With nothing underfoot to pick up, E now **throws** the held weapon instead of
  putting it down: a short wind-up, then it spins along the street (about 160 px), hits
  the first foe in its path for the weapon's heavy-blow damage at the hero's power and
  knocks them down, then lands at their feet with one use less, or breaks if that was
  its last. A guard blocks it from the front. Bosses are stunned, never floored, so a
  pile of pipes cannot trivialise them. A miss lands where it stops; it never leaves
  the area.
- Throws are simulation (`ZoneSim.thrown`, `CombatRules.thrown_hit`), drawn as a
  spinning weapon at chest height with a whoosh. The HUD hint reads "Grab / Throw /
  Talk". Enemies still only put weapons down.
- 6 new tests (164 total).

### Added — Perfect guard and counters (IL-1)
- Raise guard at most 8 ticks before a hit from the front and it is **parried**: no
  damage, no energy lost (15 energy back), guard breakers included. The attacker reels
  for 30 ticks and the first hit on them is a **counter** for 1.5x damage. Letting go
  of guard closes the parry window for 24 ticks, so it rewards timing, not tapping.
  Only the hero parries, so enemy guards never punish the player's combos.
- A parry flashes, clangs and freezes both fighters for a beat and shows "PARRY";
  counters show "COUNTER" and shake the camera. The Controls tab explains it.
- 6 new tests (158 total).

### Fixed — A crowd can no longer stun-lock the hero (IL-1)
- Hitstun the hero takes fills a stun meter that drains while they are in control. A hit
  that would push it past 40 ticks knocks the hero down instead of holding them, and
  getting up gives 36 ticks in which nothing can hit them (the hero blinks; attacking
  ends it). Measured worst case against three Night Market Punks with no input: 169 →
  68 ticks (2.8 s → 1.1 s); the cap is 90 ticks (1.5 s). Enemies are unchanged, so hero
  combos still chain.
- 4 new tests (152 total with the solid-street tests), including a zone test with three punks over three seeds.

### Changed — Direction approved
- The owner approved every recommendation in `docs/BLUEPRINT.md` (D1–D9): *The Iron
  Legacy*, Iron City and The Core, heroes mapped to classes, single player first (online
  work moves to IL-7). CLAUDE.md, GAME_DESIGN and ROADMAP point to the blueprint and the
  story bible.

### Added — The Iron Legacy: audit and blueprint (IL-0)
- `docs/BLUEPRINT.md`: audit of what exists, works, is missing or risky (baseline 140/140
  tests passing on Godot 4.7.2), conflicts between code, docs and the owner's brief,
  decisions the owner needs to make, the system blueprint built on the existing code, a
  roadmap by risk (IL-0 to IL-7) and a test plan. Measured stun-lock: three Night Market
  Punks keep an idle hero out of control for up to 169 ticks (2.8 s).
- `docs/STORY_BIBLE.md`: the proposed single source for the story (Iron City, The Core,
  characters, chapters, bosses, how the current areas and enemies fit), pending approval.
- Corrected stale lines in README (test count), GAME_DESIGN ("implemented so far") and
  ARCHITECTURE (shared rules). No game code or data changed.

### Added — Solid street: no walking through things or people
- Lamp posts, power poles, bins, cones, crates, NPCs, the training dummy, the hero and
  enemies are now solid. You bump into them and must walk round (a step at an angle
  slides along); enemies step round furniture and each other to reach you. Fighters
  in hitstun or knocked down do not block.
- Street furniture is gameplay data: kinds and footprints in
  `client/data/obstacles.json`, positions per area in `areas.json`, validated on load
  and shared with the future server. The game draws it among the fighters, sorted by
  depth; the scenery kit no longer scatters lamp posts at random and keeps sidewalk
  props and parked vehicles clear of it.
- Loot, weapons, spawns and arrivals never land inside furniture. Tests cover
  blocking, sliding, walking round, enemies detouring, NPCs, fallen fighters and
  furniture placement; the browser smoke test now walks round obstacles.

### Added — Painted street weapons, and a frying pan, wrench and bat
- The street weapons now use the project owner's paintings, reduced to hand-sized
  pixel sprites with an outline like the characters (in hand, on the street and on
  the HUD badge). `gen_ui.py` keys them from their green backdrop and puts the
  handle's end under the grip; `art/weapons/weapons.json` lists them.
- Three new weapons: **frying pan** (from level 1; the heavy bonk dazes and breaks a
  guard), **pipe wrench** (from level 2; quick, sturdy), **baseball bat** (from level
  3; long reach, a heavy swing that sends them flying). Added to the area weapon
  pools.

### Changed — HD-2D Bangkok streets
- Every area is now built from a kit of painted pieces (Octopath-style HD-2D): shops
  (convenience store, noodle shop, massage shop, pharmacy, a shuttered shop),
  shophouses, condo towers and an unbroken elevated skytrain track with trains behind them, a skyline, sidewalk and road
  tiles, street lamps and power poles, food carts, umbrella stalls, stools, plants,
  bins, cones, crates, a vending machine and bus stop, spirit houses (with Nang Kwak), cats and dogs, and a tuk-tuk,
  taxi, songthaew or motorbike parked at the kerb. Layers scroll at different speeds
  for depth, and leaves in front of the fighters scroll faster. Pieces are painted at
  twice the game size and drawn smoothly, so they stay sharp at any window size while
  the characters stay pixel art. Lamps glow. Depot, market and canal areas each
  have their own mix and tint.
- `tools/assets/kit_import.py` keys the pieces out of their green backdrops (green
  inside the outline, like the pharmacy cross, stays), trims, scales and lays out
  every area deterministically; `art/kit/kit.json` holds the recipe. The validator
  checks pieces against their sources and that layouts are current. Art by the
  project owner, credited in game. The generated sky stays; the generated buildings
  remain as a fallback.

### Added — A real punch sound
- Fists and kicks that land now sound like a punch, picked at random from six recorded
  hits so combos do not repeat one sound: "Punch 5" by jakeeaton (Freesound, CC-BY 4.0)
  and five punches cut from "multi punch" by Shikamarunara74 (Freesound, CC-BY 3.0),
  each trimmed so the impact plays within 20 ms. The in-game credits use each recording's attribution line
  as given, e.g. "multi punch.wav by Shikamarunara74 -- https://freesound.org/s/126317/
  -- License: Attribution 3.0".
- Four more punches from "Punches.mp3" by mrrap4food (Freesound, CC0 as listed), ten in
  all. That file's tags name a commercial library (Hollywood Edge), so it is kept only
  while the game is free: it is marked `replace_before_paid` and the validator reminds
  on every run (docs/ASSETS.md). Heavy blows play it lower with the old thump under
  it; weapon hits keep their own sounds. Credited in the in-game credits.
- `tools/assets/import_sounds.py` imports recorded sounds listed in
  `art/sounds/sounds.json` (cut, fade, normalise to -1 dBFS) with their authors,
  licence and source; the validator checks the licence against the policy and that the
  file matches a fresh import. The other supplied file (punches.mp3) was not used: its
  tags say "copyright 1999 Hollywood Edge", a commercial library.

### Changed — Riku at hero size
- Riku looked smaller than the NPCs: he was as tall as them in pixels, but his realistic
  proportions (small head, slim build) read smaller next to the big-headed LPC cast. He
  is now drawn 20% larger (about 60 px tall in his guard, in 80x80 frames), so he stands
  out as a hero. `FighterView` reads each art's frame size for the weapon hand and fist
  instead of assuming 64x64.

### Added — Riku Sato, the Boxer (third hero)
- A third playable hero with art by the project owner (walk and punch sheets in
  `art/custom/hero_riku/`): the all-rounder, between Mika and Oren on every stat
  (115 HP, 105% power, 1 defense, 100% speed). Jab on Z, cross on X, a guard-up idle.
  Skills: Liver Shot (fastest, long stun, breaks guard), One-Two (step-in knockdown),
  Dempsey Roll (weaving charge, breaks guard), Knockout Blow (big area finisher), each
  with its own icon. Starts with fingerless gloves, sneakers, buns and ginger tea.
- `tools/assets/custom_import.py` imports sheets drawn outside LPC: evens out sheets
  drawn at different sizes, scales to the game's size with crisp edges, adds the LPC-style
  dark outline, derives hurt and knock-down by tilting a frame about the feet (the art
  has no such frames), finds the fist for held weapons, and a portrait crop on the head.
  Credited to the project owner; the validator accepts owner art for `custom` sources.
- The "E Grab / Talk" hint moved right of the hotbar so it is not hidden at 1280x720.
- 1 new game test (139 total) and 2 pipeline tests.

### Fixed — Weapons stay in one hand and move like the weapon
- A held weapon now always sits in the same (near) hand, through idle, walk, swing, hit
  and dodge. Before, the socket followed whichever hand was closest, so the weapon
  jumped between hands.
- The fist closes around the handle: the weapon hand is drawn again over the weapon
  (a per-character `hands.png` cut from each frame with LPC's glove mask), so the
  handle sits inside the hand instead of lying across the back of it.
- Each weapon moves like itself: the knife **stabs** straight forward (new `stab`
  animation from LPC's one-handed slash, arm extended), while the bottle, plank, steel
  pipe, machete and chair **swing**: wound up behind the head, then brought forward and
  down in an arc. Before, every weapon pointed straight ahead and looked like a stab.
- Only enemies that can wield weapons go and fetch them; the Smog Warden (skeleton
  body, no one-handed swing in LPC) no longer wields. 3 new tests (138 total).

### Changed — Weapons sized to the hand
- Held weapons are redrawn at the characters' scale (knife blade ~9 px, bottle ~12 px,
  plank and pipe ~23 px, folding chair ~20 px) with slim, unoutlined handles so the fist
  still shows around the grip. Before, they were nearly half a character tall.

### Changed — Weapons stay on their street
- Walking into another area puts the held weapon down where the hero stood; it cannot be
  carried between areas. Each area keeps the weapons lying in it for the session, so a
  dropped weapon (with its wear) is still there on return. 2 new tests (136 total).

### Added — Three new areas, street weapons and smarter enemies
- The street goes on past the Sludge Foreman: **Rail Yards** (level 4), **Night Market**
  (level 6, with Kenji's Night Stall) and **Smokestack Refinery** (level 8, boss: the
  Furnace Baron). Every area has a level; enemies scale with it (HP, damage, defense,
  speed, XP, coins) and get smarter: faster reactions, guarding against wind-ups (from
  level 3), hopping back and grabbing weapons (from level 5). Enemy level shows over
  their heads and the area level on the HUD. New enemies with their own outfits: Dock
  Thug, Rail Bruiser, Market Punk, Refinery Enforcer (elite), Furnace Baron (boss).
- **Street weapons**: knife, bottle, wooden plank, steel pipe, machete and folding chair
  lie around (random by area and level; two in the Depot Yard to practise with). E picks
  one up or puts it down; it gives Z/X its own moves, wears out per landed blow (pips on
  the HUD), breaks with a sound, and is **drawn in the hand, following every frame of
  the swing**. Anyone knocked down drops their weapon and has to pick it up again.
  Wielding enemies may start armed.
- Quests Rail Yard Rumble, Market Lights and The Furnace Baron; six new items (rare to
  legendary, levels 5-8) with their own icons.
- Sprite builder: per-frame hand sockets from LPC's glove layer; weapon sprites and
  sounds (grab, drop, glass/wood/metal break) generated like the other assets.
- Smoke test picks up a weapon in the yard. 17 new tests (134 total), 2 pipeline tests.

### Changed — Skills worth their cooldown
- The heavy attack (X/K) has no cooldown, so it no longer rivals skills: 13 damage
  (was 18) and 20 energy (was 15). Skills hit harder: Mika 26/22/28/45, Oren
  28/24/30/50 (base). `test_balance.gd` now requires every skill to hit at least 1.5x
  the heavy attack.

### Added — Readable loot
- Items on the street show their own icon (at 2x, sharp) with a shadow, a glow and, for
  uncommon and better, a light beam in the rarity colour (taller for rarer items); epic
  and legendary items sparkle. Each shows its name in its rarity colour; coins spin and
  show their amount. Drops pop out of the enemy in an arc and fly off when collected.
- The bag and worn slots show icons at 2x in larger cells.
- The Characters gallery shows every item as it looks on the ground.
- 1 new test (117 total).

### Changed — Hero balance
- Clear roles: Mika is damage and mobility (power 110%, speed 110%, 100 HP); Oren is
  toughness and control (power 100%, speed 85%, 130 HP, 2 defense, wider skills).
- Skill damage retuned so every skill out-damages the free heavy attack, each hero's
  slot-5 skill is their strongest, and same-slot skills of both heroes land within 15%
  of each other: Mika 20/18/22/38, Oren 22/20/24/42 (base, before power).
- `test_balance.gd` keeps these rules (4 tests, 116 total).

### Fixed — Attack buttons felt unresponsive
- Input buffer: a light/heavy attack or skill pressed in the last 12 ticks (0.2 s) of a
  missed swing now starts as soon as that swing ends; before, the press was dropped,
  so Z/X (and J/K) seemed not to work when mashed.
- A heavy attack or dodge without enough energy now plays a refusal sound and blinks the
  energy bar instead of silently doing nothing. 3 new tests (112 total).
- The attack slot (1) lights up when Z/J is pressed and is labelled "1 Z", so it is
  clear Z is the same basic attack (no cooldown); the key hint shows X for heavy.

### Added — Hero portrait on the HUD
- The hero card shows the hero's face (cut from the current sprite, so armour shows) on
  a backdrop in the hero's colour, with the level in a gold badge on its corner, the
  player's name and the hero's role. The portrait flashes red when the hero is hit and
  its frame pulses red below 25% HP. 1 new test (109 total).

### Added — Character status, equipment and items
- Status tab: the hero (sprite, level, role, HP/energy/XP), read-only attributes (Max HP,
  Attack, Defense, Speed) as total + gear bonus with a line of help each, what the next
  level brings (stats and skills), and a record.
- Equipment tab: six worn slots around the hero (head, body, hands, weapon, feet, charm,
  with empty-slot silhouettes and a turnable preview), a stats summary, and the bag as a
  grid with stack counts and rarity frames.
- Item card on any item: icon, name in its rarity colour, rarity and slot, required
  level, effects in player terms, comparison with what is worn, description, and
  Equip / Unequip / Use / Discard (asks first). The shop shows the same details.
- Items: rarity, required level, `stats` bonuses (penalties allowed), descriptions.
  15 items with new icons; Ama sells ten, enemies drop the rest. Each hero starts with a
  small kit (worn gear, buns, coins).
- Saves (version 3) map the old `armor`/`accessory` slots to `body`/`charm`.
- 3 new tests (108 total).

### Added — Hero creation and a second hero
- Hero creation screen after New game: roster cards with portraits, a large animated
  preview, bio, play style, difficulty, stats compared across heroes, the hero's four
  skills, and a name field (2–16 characters, any script including Thai; Random
  suggestions). Keyboard, gamepad, mouse and touch.
- Oren Vale, a male bruiser (LPC, OGA-BY): 130 HP, 115% power, 2 defense, 85% speed,
  with Headbutt, Clothesline, Shoulder Charge and Earthshaker (new moves and icons) and
  an armoured look.
- Heroes are data (`data/heroes.json`): stats, sprites and looks, skills. The hotbar
  template fills its skill slots from the hero. Items change looks by name (`look`).
- Saves (version 2) store the hero and the player's name; version 1 saves become Mika.
- The title shows the saved hero (card and line-up). Credits now include the Godot
  licence and the bundled font.
- Noto Sans Thai (OFL) as a font fallback, pinned by SHA-256 and validated in CI.
- 8 new tests (105 total); the smoke test picks Oren and types a name.

### Changed
- `progression.json` no longer holds hero stats; they live with each hero.

### Added — Skills, combat feedback and sound
- Skill hotbar (`data/skills.json`): slot 1 attack, slots 2–5 Rising Uppercut, Whirlwind
  Kick, Shoulder Rush and Furnace Slam, slots 6–7 Steamed Bun and Ginger Tea. Skills
  cost energy, have cooldowns, unlock at levels 1/1/2/3 and can cancel a landed attack.
  Cooldowns, unlocks and a shared 2 s consumable cooldown are simulation rules
  (`SkillRules`, `CombatRules.start_skill`, `ZoneSim.use_item`). New move fields:
  `advance` (lunges). Knockback now pushes away from the attacker.
- Hotbar UI: icons, key numbers, cooldown sweep and seconds, energy and lock states, item
  counts, tooltips, click/tap; keys 1–7 and gamepad RT combinations.
- Combat feedback: hit sparks, impact flash and freeze, dust, per-skill effects, camera
  shake, hurt vignette, level-up light and banner naming unlocked skills.
- Sound: 25 original synthesised effects and a sound-volume option.
- Training dummy: an original wooden sparring post that rocks when hit and tips over.
- Generators `gen_fx.py`, `gen_sfx.py`, `gen_dummy.py` and skill icons in `gen_ui.py`, all
  validated in CI. 15 new tests (97 total); the smoke test casts a skill.

### Added — Interface overhaul
- One visual language (`UiTheme`: palette, type scale, control styles) applied to
  every screen through the project theme, and a kit of building blocks (`UiKit`).
  See `docs/UI.md`.
- Title screen: live street backdrop, logo, Continue first when a save exists,
  confirmation before a new game replaces a save, key hints.
- HUD: hero card with level badge and HP/energy/XP bars (damage trail), coins
  with icon, area name, tracked quest card, boss bar, notification banner, key
  hints; touch controls on touch devices only.
- Pause window with tabs (Status, Bag, Quests, Controls, Game) switched with Q/E or
  LB/RB; bag and shop list items with icons and a detail panel; quest cards with
  progress and rewards; options for screen shake and a frame-rate counter
  (`user://settings.json`).
- NPC conversations in a dialog box with a portrait; "[E] Talk/Shop" prompt over
  the NPC in reach; knock-out screen; outlined names and damage numbers; camera
  shake on heavy hits.
- Generated item and interface icons (`tools/assets/gen_ui.py`), validated in CI.
- `test_ui.gd`: screens fit the 640x360 base view, wrapping text has a width,
  focus is set, tabs switch, prompts appear only near NPCs (82 tests total).
- `tools/web-smoke/shots.ts` for screenshots of a web build.

### Fixed
- The title text wrapped one word per line (an autowrapping label without a width).

### Added — Character art pipeline and first art pack
- `tools/assets/`: LPC character builder (pinned generator commit, licence policy,
  recolouring, credits), UnitForge "Godot 4" export importer, SpriteFrames
  generator, asset validator and 14 pipeline unit tests; `Assets` workflow to
  build/import in the cloud; CI job validating every asset. See `docs/ASSETS.md`.
- Nine LPC-built characters (CC0/OGA-BY/CC-BY only): hero Mika and an armoured
  variant (shown when the Work Jacket is equipped), NPCs Ama and Chief Odo, and all
  five enemy types including the elite and the boss. `FighterView` plays them with
  `AnimatedSprite2D`, attack frames stepped by simulation ticks.
- Title screen: Characters (gallery) and Credits.
- Tar Hound renamed "Tar Rat" to match its art.
- Generated scenery for every area (`tools/assets/gen_environment.py`, original
  MIT art): sky and parallax skyline, themed facades (depot warehouses and
  containers, market shophouses and stalls, canal factories and water), detailed
  street, props and lamp glow. Validated for freshness in CI.

### Added — Milestone 2, part 2: playable single-player loop
- Title screen (New game / Continue), pause menu, inventory and equipment, shop,
  quest dialog and log, game over with a coin penalty, notifications, boss HP bar.
- Three areas from `data/areas.json`: Depot Yard (home: vendor, quest giver, training
  dummy, heals on entry), Saltmarket Street and Canal Works, joined by exits.
- Enemies from `data/enemies.json`: Smogling, Tar Hound, Pipe Brute, elite Smog Warden
  and a two-phase boss, the Sludge Foreman. `EnemyBrain` AI keeps spacing, lines up,
  reacts and swings; at most two attack at once (attack tokens); telegraphed heavies
  show a warning. Enemies push apart instead of stacking.
- Encounters with waves lock the arena until cleared and reset on re-entry (farming).
- Rewards decided by the zone simulation from a seeded generator: XP and levels,
  money and item drops from loot tables, quest progress. Items, shops, quests and
  progression are data (`items.json`, `shops.json`, `quests.json`, `progression.json`),
  validated together with cross-references by `ContentDB`.
- `PlayerProfile` with versioned, sanitising (de)serialisation; local save via
  `SaveStore` (atomic write; IndexedDB in browsers), autosave on area change, defeat,
  purchase and quest hand-in.
- 30 new tests (69 total); the test runner now ignores warnings but still fails on
  errors. The browser smoke test plays title -> new game -> dummy combo -> pause ->
  next area -> a real street fight.

### Added — Milestone 2, part 1: combat core
- Deterministic 60 Hz combat simulation in `client/sim/` (`CombatRules`, `Fighter`,
  `FighterInput`, `CombatEvent`): light combo jab → cross → body hook (chains only
  after a connected hit), guard-breaking haymaker, dodge with invulnerability frames,
  guard (front only, chip damage, energy drain, guard break), hit stun, knockback,
  knockdown, KO, simultaneous-hit trades.
- Attacks are data: `client/data/moves.json`, loaded and validated by `MoveLibrary`.
- Test zone: training dummy with HP bar and respawn, HUD HP/energy bars, floating
  damage numbers, keyboard/gamepad/touch bindings for light, heavy, dodge, guard.
- 23 new tests (39 total). Browser smoke test now lands a combo on the dummy.
- `pages.yml` plays the live HTTPS site after each deploy.

### Security
- Asset tools pin Pillow 13.0.0: dependency review flagged 20+ HIGH advisories in
  12.3.0 (PDF, TIFF, JPEG, GIF decoders). Rebuilt assets are byte-identical.

### Changed
- CI jobs have time limits. The smoke test installs only Chromium's headless shell
  (cached) instead of `--with-deps`, which spent 10+ minutes on a slow apt mirror.
- Light hits push less (jab 4 px, cross 6 px) so the combo stays in reach.

## [0.1.0] — 2026-10-23 (Milestone 1 / Task 001)

### Added — Milestone 1 / Task 001: cloud build pipeline
- Godot 4.7.2 client project (`client/`): test street, placeholder hero with lane movement
  (keyboard, gamepad, touch), bounded camera, HUD.
- Shared rules module `client/sim/LaneMovement.gd` with unit tests.
- Headless Godot test runner that fails tests on any engine or script error.
- Release web export preset (single-threaded, Compatibility renderer).
- Browser smoke test (Playwright + Chromium) that verifies boot and keyboard movement.
- API service skeleton (Node 24.22.1, Fastify): `/healthz`, `/readyz`, checksummed
  forward-only migration runner, migration `0001_accounts`.
- CI: repository policy, gdlint/gdformat, Godot tests, web export + smoke test + artifact
  with SHA-256 manifest, backend tests on PostgreSQL 16, image build + Trivy + SBOM.
  Security: gitleaks, npm audit, dependency review. Gated GitHub Pages deployment of the
  CI artifact.
- Documentation set and repository audit.

### Security
- Runtime image drops npm, npx and corepack (multi-stage build). Their bundled
  `brace-expansion` 5.0.9 and `undici` 6.28.0 had HIGH CVEs (CVE-2026-102276,
  CVE-2026-102278, CVE-2026-19534) reported by Trivy; the API never runs them.
