# Item power: MR validation and final balance review

**Status: validation only.**

- No item stat, `ItemRules` value, grade weight, loot table, enhancement or
  combat formula, Godforged item or reward was changed. No production item was
  created.
- Every model below was applied **in memory only**, by a temporary simulation
  runner that has since been deleted.
- Nothing was committed, pushed, merged or deployed.

Labels used on findings:

- **VERIFIED:** read in source, data or tests.
- **SIMULATED:** measured by running the game's real rules with fixed seeds.
- **MODELED:** exact arithmetic with the game's formulas, not a fight.
- **PROPOSED:** a recommendation.
- **UNKNOWN:** could not be determined.

## 0. Method

### Models compared

All except Current include the 12 proposed Lv 55–70 Legendaries.

| Id | Grade weights (Common … Godforged) | Godforged |
|---|---|---|
| Current (M0) | 0.85 / 1.00 / 1.15 / 1.35 / 1.60 / 2.20 | unchanged |
| MR | 0.85 / 1.00 / 1.22 / 1.48 / 1.80 / 2.20 | unchanged |
| Model B | 0.85 / 1.105 / 1.445 / 1.87 / 2.465 / 3.23 | ×1.47 (needed so Legendary < Godforged) |
| Model A | 0.85 / 1.36 / 2.04 / 2.89 / 4.25 / 5.95 | ×2.70 |
| MR + Godforged re-mix (scenario B) | MR | stats moved, score unchanged (§10) |
| MR + Godforged ×1.2 (scenario C) | MR, with Godforged 2.64 | ×1.2 |

### Builds (SIMULATED)

- **Hero:** the default hero.
- **Builds:**
  - One per grade: the best item per slot of that grade at or below the hero's
    level. Legendary falls back to Epic where a slot has none; Common falls back
    to Uncommon.
  - **Mixed:** Epic weapon and charm, Rare head and body, Uncommon hands and feet.
    Usually under-enhanced at +3.
  - **Offence-picked Epic and defence-picked Epic:** specialisations.
- **Enhancement:** +0, +3, +5, +7 and +10 where listed.
- **Food:** 20 rice boxes and 10 tonics.

### Simulation runs

| Part | What runs |
|---|---|
| Farming | `LevelingSim._farm`, the auto-battle farming loop: 3 minutes, **6 seeds** per cell |
| Stage bosses | the story area with every other fight cleared, **10 seeds** |
| Mini-bosses | the lair mini-boss spawned alone at the lair's level, **10 seeds** |
| World and raid bosses | `WorldBossRun`, 2 minutes, **5 seeds** |
| Arena | `ArenaSim.fight`, Lv 70, same job both sides, AI 0.8, **40 matches**, sides swapped every match |
| Stat probes | **8 seeds** (farming), **6 seeds** (world boss) |

### Statistics

- **Each simulated cell** shows the mean ±95% confidence half-width (t
  distribution), then [minimum–maximum].
- **"MR vs current"** uses Welch's t on the two cells:
  - "clear" is |t| ≥ 3.
  - "likely" is 2 ≤ |t| < 3.
  - "noise" is |t| < 2, meaning not distinguishable at these sample sizes.
- **Arena win rates** carry Wilson 95% intervals.
- With 5–10 seeds, a difference has to be roughly 15–25% to show as "clear". No
  smaller difference should be read as real.

### Limits

`AutoPilot` and `ArenaBrain` stand in for players (`docs/HARNESS.md`, "Limits").
A person can do better or worse.

## 1. Current system versus MR

### 1.1 Kit strength [MODELED]

- Damage index = power × (1 + 0.5 × counted crit) × counted attack speed.
- EHP vs monsters = HP × hit / max(1, hit − defense). The hit is the median
  ordinary monster hit at that level (`docs/ITEM_POWER_BALANCE_PROPOSAL.md` §2.3).

| Lv | Build | Current dmg / EHP | MR dmg / EHP |
|---:|---|---:|---:|
| 35 | common | 4.49 / 873 | 4.49 / 873 |
| 35 | uncommon | 4.79 / 962 | 4.79 / 962 |
| 35 | rare | 4.39 / 1,013 | 4.50 / 1,028 |
| 35 | epic | 4.87 / 1,332 | 5.10 / 1,497 |
| 35 | legendary | 6.34 / 1,635 | 6.88 / 1,886 |
| 35 | mixed | 5.00 / 1,211 | 5.15 / 1,240 |
| 45 | common | 5.50 / 1,035 | 5.50 / 1,035 |
| 45 | uncommon | 5.96 / 1,157 | 5.96 / 1,157 |
| 45 | rare | 6.26 / 1,084 | 6.46 / 1,098 |
| 45 | epic | 5.73 / 1,820 | 6.00 / 2,030 |
| 45 | legendary | 8.22 / 1,570 | 8.76 / 1,747 |
| 45 | mixed | 5.90 / 1,249 | 6.06 / 1,275 |
| 55 | common | 6.97 / 1,320 | 6.97 / 1,320 |
| 55 | uncommon | 7.64 / 1,549 | 7.64 / 1,549 |
| 55 | rare | 8.22 / 1,772 | 8.45 / 1,855 |
| 55 | epic | 8.25 / 2,681 | 8.63 / 3,123 |
| 55 | legendary | 9.28 / 1,788 | 10.16 / 2,488 |
| 55 | mixed | 8.06 / 2,069 | 8.27 / 2,189 |
| 70 | common | 9.00 / 1,695 | 9.00 / 1,695 |
| 70 | uncommon | 9.89 / 1,913 | 9.89 / 1,913 |
| 70 | rare | 10.29 / 2,284 | 10.61 / 2,438 |
| 70 | epic | 10.41 / 3,379 | 10.93 / 4,134 |
| 70 | legendary | 10.50 / 1,839 | 12.01 / 8,591 |
| 70 | mixed | 10.09 / 2,620 | 10.36 / 2,831 |

**Reading the Current-vs-MR columns: two changes are mixed.**

- Current has neither the MR weights nor the 12 proposed Legendaries. MR has both.
- So the Common, Uncommon, Rare, Epic and Mixed rows show the **weight change
  alone**. Common and Uncommon are unchanged by design.
- The Legendary rows at Lv 55+ show the **weights plus the new items**.

[MODELED] The weight change alone raises a Lv 70 Epic kit's damage by 5% and its
PvE EHP by 22%; Rare's by 3% and 7%. The new items raise the Lv 70 Legendary kit's
damage by 14% and its PvE EHP by ×4.7, because today's "Legendary" kit is Lv
30–48 gear.


### 1.2 Farming: kills per hour [SIMULATED]

| Ground | Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) | MR vs current |
|---|---:|---|---|---|---|---|---|
| farm_facility_annex | 37 | common+0 | 730 ±120 [600–920] | 730 ±120 [600–920] | 723 ±126 [600–920] | 710 ±100 [560–820] | noise |
| farm_facility_annex | 37 | rare+0 | 663 ±120 [480–780] | 680 ±128 [520–800] | 773 ±110 [620–900] | 870 ±154 [640–1,000] | noise |
| farm_facility_annex | 37 | epic+0 | 713 ±108 [540–800] | 800 ±113 [600–900] | 940 ±85 [820–1,020] | 1,210 ±99 [1,060–1,320] | noise |
| farm_facility_annex | 37 | legendary+0 | 937 ±122 [760–1,080] | 1,050 ±175 [900–1,360] | 1,330 ±89 [1,240–1,460] | 1,527 ±130 [1,420–1,720] | noise |
| farm_facility_annex | 37 | mixed+3 | 883 ±94 [780–1,000] | 897 ±77 [820–980] | 1,097 ±94 [940–1,200] | 1,320 ±66 [1,240–1,400] | noise |
| farm_facility_annex | 37 | epic+10 | 1,123 ±67 [1,060–1,240] | 1,150 ±93 [1,040–1,300] | 1,323 ±134 [1,120–1,500] | 1,707 ±79 [1,640–1,840] | noise |
| farm_core_spillway | 43 | common+0 | 633 ±80 [560–740] | 633 ±80 [560–740] | 623 ±66 [560–720] | 687 ±80 [560–760] | noise |
| farm_core_spillway | 43 | rare+0 | 830 ±75 [740–900] | 857 ±162 [640–1,000] | 873 ±75 [780–960] | 1,090 ±115 [900–1,200] | noise |
| farm_core_spillway | 43 | epic+0 | 757 ±96 [660–880] | 780 ±82 [680–900] | 910 ±108 [800–1,080] | 1,120 ±130 [960–1,240] | noise |
| farm_core_spillway | 43 | legendary+0 | 987 ±45 [920–1,040] | 1,037 ±77 [920–1,140] | 1,240 ±148 [1,000–1,380] | 1,673 ±108 [1,500–1,780] | noise |
| farm_core_spillway | 43 | mixed+3 | 890 ±63 [840–1,000] | 857 ±95 [740–980] | 993 ±132 [880–1,180] | 1,200 ±88 [1,100–1,340] | noise |
| farm_core_spillway | 43 | epic+10 | 980 ±172 [720–1,140] | 1,117 ±145 [940–1,340] | 1,250 ±110 [1,120–1,400] | 1,627 ±124 [1,500–1,840] | noise |
| farm_coolant_vaults | 53 | common+0 | 750 ±74 [660–840] | 750 ±74 [660–840] | 750 ±74 [660–840] | 750 ±74 [660–840] | noise |
| farm_coolant_vaults | 53 | rare+0 | 943 ±95 [820–1,060] | 1,020 ±68 [960–1,120] | 1,120 ±137 [900–1,260] | 1,250 ±101 [1,100–1,380] | noise |
| farm_coolant_vaults | 53 | epic+0 | 920 ±206 [640–1,140] | 953 ±143 [760–1,120] | 1,047 ±94 [900–1,160] | 1,297 ±128 [1,120–1,420] | noise |
| farm_coolant_vaults | 53 | legendary+0 | 910 ±51 [840–960] | 913 ±161 [640–1,040] | 1,113 ±86 [1,000–1,240] | 1,460 ±144 [1,280–1,600] | noise |
| farm_coolant_vaults | 53 | mixed+3 | 1,090 ±136 [860–1,200] | 990 ±165 [700–1,120] | 1,057 ±124 [880–1,220] | 1,363 ±61 [1,300–1,440] | noise |
| farm_coolant_vaults | 53 | epic+10 | 1,257 ±68 [1,160–1,320] | 1,350 ±151 [1,160–1,560] | 1,590 ±136 [1,400–1,740] | 1,933 ±188 [1,720–2,120] | noise |
| farm_foundry_depths | 63 | common+0 | 1,013 ±75 [940–1,140] | 1,013 ±75 [940–1,140] | 1,013 ±75 [940–1,140] | 1,013 ±75 [940–1,140] | noise |
| farm_foundry_depths | 63 | rare+0 | 1,130 ±71 [1,020–1,200] | 1,167 ±94 [1,080–1,300] | 1,197 ±101 [1,020–1,280] | 1,440 ±170 [1,260–1,640] | noise |
| farm_foundry_depths | 63 | epic+0 | 1,147 ±107 [980–1,260] | 1,140 ±91 [1,080–1,300] | 1,257 ±100 [1,140–1,420] | 1,550 ±155 [1,340–1,700] | noise |
| farm_foundry_depths | 63 | legendary+0 | 1,043 ±88 [880–1,120] | 1,180 ±122 [980–1,280] | 1,490 ±168 [1,340–1,720] | 1,777 ±87 [1,660–1,900] | likely |
| farm_foundry_depths | 63 | mixed+3 | 1,273 ±54 [1,220–1,360] | 1,297 ±92 [1,160–1,400] | 1,337 ±114 [1,140–1,440] | 1,623 ±162 [1,420–1,840] | noise |
| farm_foundry_depths | 63 | epic+10 | 1,617 ±111 [1,520–1,760] | 1,617 ±92 [1,500–1,700] | 1,830 ±140 [1,680–2,020] | 2,217 ±101 [2,120–2,380] | noise |
| farm_iron_heart | 70 | common+0 | 970 ±102 [820–1,080] | 970 ±102 [820–1,080] | 970 ±102 [820–1,080] | 970 ±102 [820–1,080] | noise |
| farm_iron_heart | 70 | rare+0 | 1,007 ±127 [820–1,140] | 1,080 ±114 [940–1,260] | 1,187 ±110 [1,060–1,300] | 1,310 ±160 [1,080–1,500] | noise |
| farm_iron_heart | 70 | epic+0 | 973 ±117 [760–1,080] | 1,060 ±81 [960–1,160] | 1,153 ±60 [1,100–1,240] | 1,367 ±118 [1,220–1,500] | noise |
| farm_iron_heart | 70 | legendary+0 | 987 ±107 [820–1,100] | 1,153 ±124 [980–1,280] | 1,377 ±85 [1,240–1,480] | 1,733 ±161 [1,460–1,880] | likely |
| farm_iron_heart | 70 | mixed+3 | 1,143 ±119 [1,000–1,340] | 1,217 ±181 [920–1,380] | 1,270 ±86 [1,160–1,360] | 1,503 ±153 [1,280–1,720] | noise |
| farm_iron_heart | 70 | epic+10 | 1,380 ±133 [1,180–1,540] | 1,513 ±96 [1,380–1,640] | 1,660 ±200 [1,380–1,880] | 2,063 ±171 [1,760–2,220] | likely |
| farm_iron_heart | 70 | godforged+0 | 1,343 ±160 [1,120–1,560] | 1,343 ±160 [1,120–1,560] | 1,597 ±72 [1,520–1,700] | 2,213 ±163 [2,060–2,480] | noise |
| farm_iron_heart | 70 | legendary+7 | 1,220 ±148 [1,020–1,420] | 1,407 ±124 [1,240–1,560] | 1,740 ±87 [1,600–1,820] | 2,353 ±128 [2,140–2,440] | likely |
| farm_iron_heart | 70 | rare+10 | 1,503 ±169 [1,260–1,700] | 1,450 ±105 [1,280–1,580] | 1,620 ±136 [1,460–1,800] | 1,893 ±94 [1,780–2,020] | noise |

### 1.3 Farming: damage taken per hour [SIMULATED]

| Ground | Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) | MR vs current |
|---|---:|---|---|---|---|---|---|
| farm_facility_annex | 37 | common+0 | 25,587 ±4,208 [18,880–29,400] | 25,587 ±4,208 [18,880–29,400] | 27,910 ±3,492 [23,640–32,820] | 27,380 ±6,106 [21,020–38,120] | noise |
| farm_facility_annex | 37 | rare+0 | 24,107 ±2,381 [21,560–28,060] | 26,173 ±8,130 [17,060–36,860] | 19,370 ±5,625 [11,060–24,960] | 13,783 ±3,545 [9,600–18,840] | noise |
| farm_facility_annex | 37 | epic+0 | 13,827 ±6,080 [8,020–24,720] | 13,633 ±2,853 [9,960–18,220] | 11,340 ±2,790 [8,540–16,100] | 5,307 ±1,901 [3,180–7,560] | noise |
| farm_facility_annex | 37 | legendary+0 | 17,077 ±3,043 [13,520–21,340] | 14,607 ±2,925 [10,200–17,360] | 6,083 ±1,864 [4,000–9,120] | 1,513 ±674 [700–2,500] | noise |
| farm_facility_annex | 37 | mixed+3 | 12,587 ±3,431 [9,780–18,600] | 16,507 ±2,041 [14,940–20,220] | 9,857 ±2,594 [6,340–12,820] | 4,260 ±1,351 [2,240–6,100] | likely |
| farm_facility_annex | 37 | epic+10 | 4,813 ±1,760 [2,340–6,800] | 3,733 ±1,839 [1,580–6,860] | 1,587 ±787 [880–2,800] | 477 ±91 [340–600] | noise |
| farm_core_spillway | 43 | common+0 | 35,130 ±10,385 [25,840–51,760] | 35,130 ±10,385 [25,840–51,760] | 33,793 ±12,347 [17,820–51,760] | 33,513 ±7,325 [25,680–43,060] | noise |
| farm_core_spillway | 43 | rare+0 | 22,637 ±12,558 [11,740–44,200] | 29,703 ±3,760 [25,680–33,980] | 25,663 ±9,183 [14,400–39,900] | 20,533 ±13,426 [10,280–43,280] | noise |
| farm_core_spillway | 43 | epic+0 | 22,610 ±5,032 [16,100–29,400] | 15,590 ±6,395 [5,900–22,700] | 15,417 ±5,292 [8,040–22,460] | 5,557 ±1,545 [4,200–8,120] | likely |
| farm_core_spillway | 43 | legendary+0 | 21,370 ±6,582 [15,340–31,580] | 16,577 ±4,438 [9,440–22,640] | 14,890 ±5,908 [7,740–22,380] | 2,443 ±1,933 [420–5,620] | noise |
| farm_core_spillway | 43 | mixed+3 | 22,537 ±3,773 [18,620–28,120] | 20,943 ±5,476 [13,300–28,940] | 18,093 ±7,455 [9,460–29,060] | 12,490 ±3,066 [8,740–17,640] | noise |
| farm_core_spillway | 43 | epic+10 | 6,420 ±2,399 [3,800–10,020] | 6,890 ±4,345 [3,540–13,180] | 4,143 ±1,691 [2,080–5,840] | 1,050 ±749 [360–2,280] | noise |
| farm_coolant_vaults | 53 | common+0 | 36,010 ±15,658 [23,620–60,300] | 36,010 ±15,658 [23,620–60,300] | 36,010 ±15,658 [23,620–60,300] | 36,010 ±15,658 [23,620–60,300] | noise |
| farm_coolant_vaults | 53 | rare+0 | 27,900 ±4,720 [19,660–31,220] | 27,380 ±8,870 [14,180–35,860] | 22,370 ±5,408 [14,120–27,440] | 12,893 ±4,754 [8,800–19,880] | noise |
| farm_coolant_vaults | 53 | epic+0 | 26,483 ±8,967 [18,120–41,160] | 21,137 ±8,003 [10,640–32,140] | 15,110 ±4,442 [10,800–20,360] | 4,907 ±3,055 [2,240–10,500] | noise |
| farm_coolant_vaults | 53 | legendary+0 | 32,743 ±8,137 [23,280–40,680] | 26,503 ±10,584 [12,080–40,040] | 22,033 ±10,239 [8,760–34,920] | 11,230 ±4,817 [4,160–16,240] | noise |
| farm_coolant_vaults | 53 | mixed+3 | 19,523 ±4,526 [12,840–23,860] | 18,777 ±5,897 [14,060–27,320] | 17,023 ±5,320 [8,880–23,180] | 9,173 ±4,178 [4,120–15,300] | noise |
| farm_coolant_vaults | 53 | epic+10 | 6,397 ±3,476 [2,900–11,820] | 3,317 ±1,518 [880–5,220] | 3,297 ±1,564 [1,440–5,140] | 407 ±110 [240–560] | likely |
| farm_foundry_depths | 63 | common+0 | 23,657 ±6,350 [13,840–31,100] | 23,657 ±6,350 [13,840–31,100] | 23,657 ±6,350 [13,840–31,100] | 23,657 ±6,350 [13,840–31,100] | noise |
| farm_foundry_depths | 63 | rare+0 | 19,787 ±7,209 [12,300–29,760] | 20,547 ±8,351 [13,940–35,800] | 13,773 ±2,760 [10,800–17,240] | 8,557 ±2,900 [5,400–12,800] | noise |
| farm_foundry_depths | 63 | epic+0 | 12,957 ±3,692 [8,620–16,540] | 15,187 ±5,303 [8,720–21,600] | 6,457 ±2,371 [3,320–9,200] | 1,663 ±1,116 [580–3,660] | noise |
| farm_foundry_depths | 63 | legendary+0 | 25,777 ±8,615 [14,680–33,220] | 7,390 ±2,316 [5,120–10,460] | 4,323 ±2,224 [2,780–8,540] | 947 ±588 [440–1,660] | clear |
| farm_foundry_depths | 63 | mixed+3 | 8,057 ±2,547 [5,200–12,160] | 12,707 ±3,051 [8,800–15,840] | 6,740 ±629 [6,200–7,860] | 2,500 ±1,747 [940–5,340] | clear |
| farm_foundry_depths | 63 | epic+10 | 2,983 ±1,596 [1,080–4,900] | 2,173 ±617 [1,160–2,660] | 637 ±294 [380–1,060] | 467 ±101 [280–540] | noise |
| farm_iron_heart | 70 | common+0 | 49,893 ±7,570 [41,560–62,780] | 49,893 ±7,570 [41,560–62,780] | 49,893 ±7,570 [41,560–62,780] | 49,893 ±7,570 [41,560–62,780] | noise |
| farm_iron_heart | 70 | rare+0 | 56,037 ±10,860 [47,720–73,160] | 47,070 ±7,587 [36,300–58,300] | 33,987 ±3,604 [27,860–37,700] | 24,697 ±11,058 [10,980–41,840] | noise |
| farm_iron_heart | 70 | epic+0 | 40,943 ±12,220 [24,760–58,240] | 32,247 ±7,039 [24,500–41,720] | 28,220 ±6,720 [22,000–39,680] | 12,133 ±5,563 [8,000–21,120] | noise |
| farm_iron_heart | 70 | legendary+0 | 52,507 ±13,458 [36,500–71,220] | 27,107 ±4,803 [20,000–31,680] | 18,500 ±1,373 [16,000–19,720] | 5,757 ±1,837 [4,500–9,100] | clear |
| farm_iron_heart | 70 | mixed+3 | 31,980 ±14,361 [20,040–51,900] | 28,767 ±12,278 [13,960–47,320] | 25,200 ±9,084 [15,620–39,360] | 15,857 ±6,613 [10,040–24,000] | noise |
| farm_iron_heart | 70 | epic+10 | 16,370 ±3,049 [11,400–20,280] | 11,730 ±5,126 [5,580–18,420] | 7,440 ±5,462 [3,560–16,620] | 1,037 ±750 [580–2,320] | noise |
| farm_iron_heart | 70 | godforged+0 | 23,133 ±7,218 [14,900–32,600] | 23,133 ±7,218 [14,900–32,600] | 10,280 ±2,575 [5,520–12,280] | 3,000 ±1,429 [1,820–5,520] | noise |
| farm_iron_heart | 70 | legendary+7 | 34,450 ±6,744 [25,460–39,860] | 12,543 ±3,499 [7,240–16,280] | 4,573 ±1,606 [1,920–5,960] | 493 ±51 [420–560] | clear |
| farm_iron_heart | 70 | rare+10 | 19,720 ±3,927 [12,560–23,020] | 23,960 ±9,144 [11,320–36,060] | 17,117 ±5,860 [11,360–27,800] | 7,190 ±3,820 [3,460–11,900] | noise |

### 1.4 Farming: food eaten per hour (healing and recovery) [SIMULATED]

| Ground | Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) | MR vs current |
|---|---:|---|---|---|---|---|---|
| farm_facility_annex | 37 | common+0 | 147 ±17 [120–160] | 147 ±17 [120–160] | 157 ±16 [140–180] | 153 ±29 [120–200] | noise |
| farm_facility_annex | 37 | rare+0 | 140 ±13 [120–160] | 150 ±39 [100–200] | 120 ±27 [80–140] | 93 ±17 [80–120] | noise |
| farm_facility_annex | 37 | epic+0 | 90 ±29 [60–140] | 97 ±16 [80–120] | 87 ±11 [80–100] | 67 ±11 [60–80] | noise |
| farm_facility_annex | 37 | legendary+0 | 110 ±11 [100–120] | 103 ±16 [80–120] | 67 ±11 [60–80] | 60 ±0 [60–60] | noise |
| farm_facility_annex | 37 | mixed+3 | 90 ±18 [80–120] | 103 ±9 [100–120] | 80 ±13 [60–100] | 63 ±9 [60–80] | noise |
| farm_facility_annex | 37 | epic+10 | 63 ±9 [60–80] | 60 ±13 [40–80] | 60 ±0 [60–60] | 60 ±0 [60–60] | noise |
| farm_core_spillway | 43 | common+0 | 203 ±69 [140–320] | 203 ±69 [140–320] | 200 ±74 [120–320] | 183 ±41 [140–240] | noise |
| farm_core_spillway | 43 | rare+0 | 133 ±62 [80–240] | 160 ±19 [140–180] | 150 ±45 [100–220] | 137 ±72 [80–260] | noise |
| farm_core_spillway | 43 | epic+0 | 143 ±25 [120–180] | 110 ±32 [60–140] | 110 ±22 [80–140] | 80 ±0 [80–80] | likely |
| farm_core_spillway | 43 | legendary+0 | 133 ±34 [100–180] | 113 ±22 [80–140] | 110 ±26 [80–140] | 63 ±9 [60–80] | noise |
| farm_core_spillway | 43 | mixed+3 | 137 ±16 [120–160] | 130 ±22 [100–160] | 123 ±36 [80–180] | 100 ±13 [80–120] | noise |
| farm_core_spillway | 43 | epic+10 | 80 ±13 [60–100] | 87 ±22 [60–120] | 80 ±0 [80–80] | 83 ±9 [80–100] | noise |
| farm_coolant_vaults | 53 | common+0 | 217 ±90 [140–360] | 217 ±90 [140–360] | 217 ±90 [140–360] | 217 ±90 [140–360] | noise |
| farm_coolant_vaults | 53 | rare+0 | 170 ±18 [140–180] | 167 ±41 [100–200] | 143 ±28 [100–160] | 110 ±18 [100–140] | noise |
| farm_coolant_vaults | 53 | epic+0 | 167 ±45 [120–240] | 147 ±39 [100–200] | 120 ±23 [100–140] | 90 ±18 [80–120] | noise |
| farm_coolant_vaults | 53 | legendary+0 | 200 ±40 [160–240] | 163 ±45 [100–220] | 157 ±49 [100–220] | 123 ±21 [100–140] | noise |
| farm_coolant_vaults | 53 | mixed+3 | 133 ±25 [100–160] | 137 ±28 [120–180] | 137 ±25 [100–160] | 107 ±22 [80–140] | noise |
| farm_coolant_vaults | 53 | epic+10 | 97 ±16 [80–120] | 83 ±9 [80–100] | 93 ±11 [80–100] | 100 ±0 [100–100] | noise |
| farm_foundry_depths | 63 | common+0 | 150 ±29 [100–180] | 150 ±29 [100–180] | 150 ±29 [100–180] | 150 ±29 [100–180] | noise |
| farm_foundry_depths | 63 | rare+0 | 137 ±31 [100–180] | 143 ±41 [120–220] | 117 ±16 [100–140] | 103 ±16 [80–120] | noise |
| farm_foundry_depths | 63 | epic+0 | 113 ±11 [100–120] | 127 ±25 [100–160] | 90 ±11 [80–100] | 83 ±9 [80–100] | noise |
| farm_foundry_depths | 63 | legendary+0 | 167 ±39 [120–200] | 90 ±11 [80–100] | 83 ±9 [80–100] | 100 ±0 [100–100] | clear |
| farm_foundry_depths | 63 | mixed+3 | 93 ±17 [80–120] | 113 ±11 [100–120] | 100 ±0 [100–100] | 90 ±11 [80–100] | likely |
| farm_foundry_depths | 63 | epic+10 | 87 ±11 [80–100] | 90 ±11 [80–100] | 100 ±0 [100–100] | 120 ±0 [120–120] | noise |
| farm_iron_heart | 70 | common+0 | 313 ±62 [260–420] | 313 ±62 [260–420] | 313 ±62 [260–420] | 313 ±62 [260–420] | noise |
| farm_iron_heart | 70 | rare+0 | 343 ±99 [280–500] | 293 ±57 [220–380] | 210 ±18 [180–220] | 180 ±50 [120–260] | noise |
| farm_iron_heart | 70 | epic+0 | 263 ±82 [180–400] | 213 ±34 [180–260] | 193 ±32 [160–240] | 140 ±27 [120–180] | noise |
| farm_iron_heart | 70 | legendary+0 | 323 ±88 [220–460] | 190 ±22 [160–220] | 160 ±0 [160–160] | 143 ±9 [140–160] | clear |
| farm_iron_heart | 70 | mixed+3 | 223 ±84 [160–360] | 190 ±59 [120–280] | 183 ±45 [140–260] | 157 ±31 [120–200] | noise |
| farm_iron_heart | 70 | epic+10 | 160 ±13 [140–180] | 140 ±19 [120–160] | 133 ±25 [120–180] | 140 ±0 [140–140] | likely |
| farm_iron_heart | 70 | godforged+0 | 177 ±31 [140–220] | 177 ±31 [140–220] | 137 ±9 [120–140] | 143 ±9 [140–160] | noise |
| farm_iron_heart | 70 | legendary+7 | 223 ±36 [180–260] | 147 ±17 [120–160] | 133 ±11 [120–140] | 160 ±0 [160–160] | clear |
| farm_iron_heart | 70 | rare+10 | 157 ±21 [120–180] | 180 ±46 [120–240] | 153 ±29 [120–200] | 127 ±11 [120–140] | noise |

Knock-outs while farming (out of the seeds run):

| Ground | Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) |
|---|---:|---|---|---|---|---|
| farm_facility_annex | 37 | common+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_facility_annex | 37 | rare+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_facility_annex | 37 | epic+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_facility_annex | 37 | legendary+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_facility_annex | 37 | mixed+3 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_facility_annex | 37 | epic+10 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_core_spillway | 43 | common+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_core_spillway | 43 | rare+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_core_spillway | 43 | epic+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_core_spillway | 43 | legendary+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_core_spillway | 43 | mixed+3 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_core_spillway | 43 | epic+10 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_coolant_vaults | 53 | common+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_coolant_vaults | 53 | rare+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_coolant_vaults | 53 | epic+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_coolant_vaults | 53 | legendary+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_coolant_vaults | 53 | mixed+3 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_coolant_vaults | 53 | epic+10 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_foundry_depths | 63 | common+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_foundry_depths | 63 | rare+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_foundry_depths | 63 | epic+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_foundry_depths | 63 | legendary+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_foundry_depths | 63 | mixed+3 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_foundry_depths | 63 | epic+10 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | common+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | rare+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | epic+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | legendary+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | mixed+3 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | epic+10 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | godforged+0 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | legendary+7 | 0/6 | 0/6 | 0/6 | 0/6 |
| farm_iron_heart | 70 | rare+10 | 0/6 | 0/6 | 0/6 | 0/6 |

Farming findings [SIMULATED, 6 seeds × 3 minutes]:

- **No knock-out** in any model, build or ground: 0 of 6 everywhere. Ordinary and
  elite farming is never at risk. Farming grounds spawn their own elites, so elite
  fights are inside these numbers.
- **The weight change alone** (Rare, Epic and Mixed rows): kills per hour and
  damage taken mostly move by about 10–35% in MR's favour. Almost all of these
  rows are **"noise"** at 6 seeds.
  - The effect of the MR weights on farming is real in the formulas (§1.1) but
    smaller than run-to-run variation (±10–15% on kills, ±20–50% on damage
    taken).
  - It is **not demonstrated** by these runs. UNKNOWN beyond "small".
- **Warning about the verdicts (multiple comparisons):**
  - Farming at Lv 63, Mixed +3 shows damage taken *rising* under MR, rated
    "clear" (8,057 → 12,707).
  - Its MR kit is the same six items with strictly higher stats (HP 1,233 →
    1,273, defense 56 → 58, power 7.26 → 7.48).
  - So the difference is not caused by the stats. Any stat change sends a seeded
    fight down a different path, and with about 100 comparisons at 6–10 seeds a
    few false "clear" or "likely" verdicts are expected.
  - Treat a single "clear" row as a lead, not a result. Only consistent patterns
    across levels and builds are reported as findings here.
- **The new Legendaries** are a **clear** improvement:
  - Lv 70 Legendary kit damage taken per hour: 52,507 ± 13,458 (current) →
    27,107 ± 4,803 (MR).
  - Food: 323 → 190 per hour.
  - The same at Lv 63: 25,777 → 7,390.
- **Model A** cuts damage taken by 60–99% for Epic and Legendary kits at Lv
  37–70. For example, the Lv 70 Legendary kit takes 5,757 per hour against 27,107
  under MR. Kills rise 30–60%. Monsters stop being a threat.
- **Model B** sits between MR and Model A: damage taken −10–60% against MR.
- **Enhancement:** Epic +10 and Rare +10 out-farm every +0 kit except Model A's
  in all models. That is the enhancement lever (§5).


### 1.5 Stage bosses and mini-bosses: time to kill (seconds) [SIMULATED]

| Fight | Target | Hero Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) | MR vs current |
|---|---|---:|---|---|---|---|---|---|
| stage boss | test_labs | 35 | common+0 | 45.9 ±3.4 [39.5–55.3] | 45.9 ±3.4 [39.5–55.3] | 45.9 ±3.4 [39.5–55.3] | 45.8 ±3.5 [39.3–55.3] | noise |
| stage boss | test_labs | 35 | rare+0 | 49.5 ±2.6 [43.3–56.0] | 49.3 ±4.8 [37.5–60.5] | 41.9 ±6.5 [30.0–60.1] | 41.6 ±2.9 [35.8–48.5] | noise |
| stage boss | test_labs | 35 | epic+0 | 44.0 ±3.5 [37.6–53.1] | 42.6 ±4.3 [28.4–49.1] | 41.0 ±4.1 [34.3–54.6] | 31.3 ±3.5 [25.6–41.0] | noise |
| stage boss | test_labs | 35 | legendary+0 | 39.8 ±5.0 [26.0–53.2] | 34.8 ±2.4 [29.2–40.8] | 31.7 ±4.1 [23.8–42.0] | 24.4 ±3.2 [19.1–30.8] | likely |
| stage boss | test_labs | 35 | mixed+3 | 35.6 ±3.6 [27.9–44.9] | 33.7 ±3.6 [23.6–40.8] | 32.1 ±4.6 [23.0–39.9] | 30.5 ±3.8 [24.2–38.4] | noise |
| stage boss | test_labs | 35 | epic+10 | 31.2 ±3.5 [23.6–38.1] | 34.1 ±3.7 [28.3–43.1] | 26.1 ±4.2 [20.6–37.0] | 21.1 ±2.4 [16.7–28.8] | noise |
| stage boss | control_room | 39 | common+0 | 42.2 ±4.9 [34.2–54.0] | 42.2 ±4.9 [34.2–54.0] | 41.9 ±4.8 [34.2–54.0] | 41.7 ±5.5 [27.6–53.9] | noise |
| stage boss | control_room | 39 | rare+0 | 37.5 ±5.6 [27.6–55.9] | 39.3 ±5.1 [30.4–53.7] | 38.4 ±4.0 [28.3–46.4] | 32.6 ±3.6 [27.7–41.2] | noise |
| stage boss | control_room | 39 | epic+0 | 48.0 ±7.0 [34.3–63.7] | 40.5 ±6.7 [24.7–53.6] | 37.6 ±5.6 [25.8–50.1] | 31.3 ±3.3 [23.0–37.1] | noise |
| stage boss | control_room | 39 | legendary+0 | 36.1 ±7.8 [22.1–55.1] | 34.3 ±6.7 [20.8–53.0] | 32.1 ±3.9 [23.0–41.2] | 22.8 ±3.7 [13.6–32.9] | noise |
| stage boss | control_room | 39 | mixed+3 | 39.8 ±6.7 [32.4–63.2] | 37.9 ±6.2 [28.6–57.3] | 35.8 ±5.4 [20.7–47.1] | 31.8 ±5.1 [21.6–43.0] | noise |
| stage boss | control_room | 39 | epic+10 | 32.9 ±7.8 [19.1–53.6] | 30.5 ±4.3 [19.4–37.0] | 27.7 ±5.2 [15.1–37.9] | 20.9 ±4.2 [14.5–32.5] | noise |
| stage boss | core_chamber | 48 | common+0 | 64.2 ±8.0 [52.3–90.3] | 64.2 ±8.0 [52.3–90.3] | 64.2 ±8.0 [52.3–90.3] | 64.4 ±8.0 [52.0–90.3] | noise |
| stage boss | core_chamber | 48 | rare+0 | 55.0 ±5.4 [40.8–68.0] | 51.5 ±6.4 [33.8–62.1] | 49.5 ±4.9 [33.9–59.5] | 45.2 ±4.4 [38.4–57.4] | noise |
| stage boss | core_chamber | 48 | epic+0 | 66.8 ±8.2 [53.8–87.6] | 58.2 ±5.1 [48.2–68.3] | 55.0 ±5.8 [36.9–68.6] | 43.9 ±4.9 [34.0–54.6] | noise |
| stage boss | core_chamber | 48 | legendary+0 | 50.1 ±6.4 [35.0–63.1] | 45.9 ±8.2 [23.8–61.2] | 41.2 ±8.3 [25.4–64.2] | 29.7 ±5.2 [17.3–43.0] | noise |
| stage boss | core_chamber | 48 | mixed+3 | 54.5 ±6.4 [42.8–68.2] | 51.6 ±6.2 [37.3–68.2] | 49.5 ±5.4 [38.6–61.0] | 40.4 ±7.0 [25.9–61.0] | noise |
| stage boss | core_chamber | 48 | epic+10 | 45.3 ±3.9 [32.8–52.9] | 52.4 ±6.9 [38.1–66.0] | 42.0 ±3.7 [33.5–47.5] | 30.2 ±3.4 [21.8–34.9] | likely |
| mini-boss | spillway_chief | 45 | common+0 | 42.2 ±6.4 [31.6–58.8] | 42.2 ±6.4 [31.6–58.8] | 42.2 ±6.5 [31.6–59.5] | 42.1 ±6.6 [31.6–59.5] | noise |
| mini-boss | spillway_chief | 45 | rare+0 | 39.0 ±4.4 [27.8–46.7] | 37.5 ±5.1 [19.8–44.5] | 33.0 ±3.7 [23.9–41.1] | 26.2 ±3.4 [20.4–36.5] | noise |
| mini-boss | spillway_chief | 45 | epic+0 | 39.5 ±5.1 [32.7–56.7] | 40.2 ±4.6 [28.9–48.9] | 39.4 ±6.3 [24.6–56.2] | 34.2 ±4.0 [23.4–42.0] | noise |
| mini-boss | spillway_chief | 45 | legendary+0 | 35.6 ±4.0 [24.2–44.5] | 36.1 ±5.1 [22.2–48.8] | 26.5 ±4.5 [19.6–40.0] | 17.8 ±5.5 [10.4–36.1] | noise |
| mini-boss | spillway_chief | 45 | mixed+3 | 34.6 ±3.1 [28.6–42.9] | 33.9 ±4.3 [27.1–46.6] | 31.7 ±3.9 [23.8–38.1] | 25.9 ±5.8 [14.5–38.3] | noise |
| mini-boss | spillway_chief | 45 | epic+10 | 36.9 ±4.0 [27.4–44.2] | 37.8 ±7.9 [15.9–51.3] | 34.0 ±5.4 [23.1–46.0] | 22.2 ±3.8 [12.9–31.8] | noise |
| mini-boss | arthit_reinstated | 55 | common+0 | 54.3 ±6.8 [41.4–70.7] | 54.3 ±6.8 [41.4–70.7] | 54.3 ±6.8 [41.4–70.7] | 54.3 ±6.8 [41.4–70.7] | noise |
| mini-boss | arthit_reinstated | 55 | rare+0 | 46.8 ±6.5 [35.9–62.1] | 47.3 ±7.2 [34.5–67.0] | 51.3 ±8.2 [33.7–71.4] | 37.8 ±4.1 [30.1–49.0] | noise |
| mini-boss | arthit_reinstated | 55 | epic+0 | 50.6 ±4.9 [39.0–59.7] | 45.9 ±7.4 [30.6–61.4] | 44.6 ±4.4 [33.7–52.9] | 36.5 ±7.8 [17.6–51.8] | noise |
| mini-boss | arthit_reinstated | 55 | legendary+0 | 45.2 ±4.9 [33.6–53.2] | 38.9 ±5.8 [28.0–52.8] | 36.0 ±5.1 [25.6–47.9] | 23.1 ±4.1 [10.6–31.1] | noise |
| mini-boss | arthit_reinstated | 55 | mixed+3 | 47.4 ±7.6 [37.0–73.3] | 42.4 ±5.0 [31.7–56.0] | 39.7 ±5.6 [24.6–53.8] | 32.2 ±5.9 [17.9–42.2] | noise |
| mini-boss | arthit_reinstated | 55 | epic+10 | 43.4 ±6.7 [30.1–59.6] | 33.3 ±3.3 [24.2–40.9] | 28.2 ±3.1 [22.6–35.0] | 21.3 ±3.6 [12.7–27.8] | clear |
| mini-boss | k7_overdriven | 65 | common+0 | 50.4 ±9.7 [33.9–79.0] | 50.4 ±9.7 [33.9–79.0] | 50.4 ±9.7 [33.9–79.0] | 50.4 ±9.7 [33.9–79.0] | noise |
| mini-boss | k7_overdriven | 65 | rare+0 | 43.9 ±5.2 [30.6–57.7] | 42.5 ±7.8 [29.9–68.0] | 38.5 ±4.1 [30.1–46.9] | 33.8 ±5.0 [18.5–42.1] | noise |
| mini-boss | k7_overdriven | 65 | epic+0 | 46.0 ±6.8 [31.1–62.0] | 44.7 ±4.3 [33.6–50.7] | 45.9 ±5.6 [31.5–56.6] | 37.0 ±3.5 [29.0–43.8] | noise |
| mini-boss | k7_overdriven | 65 | legendary+0 | 49.7 ±6.6 [33.5–63.8] | 42.3 ±4.5 [29.3–51.7] | 36.2 ±5.8 [27.3–52.8] | 24.7 ±3.3 [18.7–33.5] | likely |
| mini-boss | k7_overdriven | 65 | mixed+3 | 43.4 ±6.6 [33.0–60.6] | 41.2 ±7.1 [32.5–65.5] | 38.0 ±5.0 [29.1–50.3] | 35.8 ±4.6 [24.0–43.4] | noise |
| mini-boss | k7_overdriven | 65 | epic+10 | 34.2 ±3.9 [27.5–45.0] | 36.0 ±3.9 [24.9–45.0] | 29.4 ±3.5 [19.8–37.7] | 21.0 ±2.3 [17.6–26.8] | noise |
| mini-boss | wiroj_protocol | 70 | common+0 | 58.0 ±8.6 [40.6–77.6] | 58.0 ±8.6 [40.6–77.6] | 58.0 ±8.6 [40.6–77.6] | 58.0 ±8.6 [40.6–77.6] | noise |
| mini-boss | wiroj_protocol | 70 | rare+0 | 51.1 ±6.8 [41.4–70.2] | 50.1 ±4.7 [40.3–61.0] | 57.2 ±9.0 [32.2–79.6] | 45.5 ±9.4 [26.7–63.8] | noise |
| mini-boss | wiroj_protocol | 70 | epic+0 | 54.3 ±5.0 [43.2–63.3] | 53.1 ±7.2 [42.7–73.1] | 51.0 ±6.4 [37.3–62.6] | 34.0 ±2.8 [28.6–39.7] | noise |
| mini-boss | wiroj_protocol | 70 | legendary+0 | 56.8 ±9.1 [42.1–79.0] | 51.3 ±4.4 [39.1–58.6] | 42.1 ±7.1 [22.3–57.2] | 30.5 ±6.2 [14.9–43.6] | noise |
| mini-boss | wiroj_protocol | 70 | mixed+3 | 51.7 ±9.4 [31.4–73.8] | 54.3 ±7.5 [39.5–73.9] | 46.4 ±4.9 [38.3–60.0] | 34.5 ±6.4 [21.6–49.4] | noise |
| mini-boss | wiroj_protocol | 70 | epic+10 | 36.6 ±4.4 [24.8–46.2] | 37.0 ±4.6 [29.0–49.9] | 32.5 ±4.0 [25.8–39.3] | 21.2 ±3.9 [12.7–32.9] | noise |

### 1.6 Stage bosses and mini-bosses: damage taken per fight [SIMULATED]

| Fight | Target | Hero Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) | MR vs current |
|---|---|---:|---|---|---|---|---|---|
| stage boss | test_labs | 35 | common+0 | 567 ±109 [230–792] | 567 ±109 [230–792] | 567 ±109 [230–792] | 562 ±107 [230–792] | noise |
| stage boss | test_labs | 35 | rare+0 | 625 ±178 [256–1,044] | 716 ±217 [214–1,244] | 537 ±139 [142–782] | 394 ±169 [42–667] | noise |
| stage boss | test_labs | 35 | epic+0 | 567 ±132 [325–843] | 431 ±181 [95–795] | 444 ±158 [97–817] | 95 ±48 [4–197] | noise |
| stage boss | test_labs | 35 | legendary+0 | 427 ±109 [200–598] | 333 ±137 [60–679] | 236 ±75 [18–412] | 66 ±24 [2–105] | noise |
| stage boss | test_labs | 35 | mixed+3 | 336 ±87 [156–543] | 364 ±96 [207–543] | 211 ±70 [81–406] | 155 ±77 [21–308] | noise |
| stage boss | test_labs | 35 | epic+10 | 150 ±87 [25–375] | 188 ±98 [20–435] | 63 ±49 [1–203] | 24 ±22 [0–78] | noise |
| stage boss | control_room | 39 | common+0 | 819 ±116 [646–1,119] | 819 ±116 [646–1,119] | 799 ±104 [646–1,119] | 732 ±148 [383–1,119] | noise |
| stage boss | control_room | 39 | rare+0 | 614 ±139 [344–955] | 640 ±177 [121–1,036] | 551 ±154 [270–1,080] | 362 ±107 [131–578] | noise |
| stage boss | control_room | 39 | epic+0 | 692 ±131 [441–976] | 587 ±124 [380–844] | 306 ±94 [101–544] | 230 ±112 [35–564] | noise |
| stage boss | control_room | 39 | legendary+0 | 416 ±136 [88–803] | 450 ±129 [183–630] | 289 ±57 [152–404] | 77 ±43 [3–173] | noise |
| stage boss | control_room | 39 | mixed+3 | 564 ±147 [201–887] | 524 ±110 [310–711] | 470 ±154 [44–785] | 239 ±95 [79–407] | noise |
| stage boss | control_room | 39 | epic+10 | 193 ±91 [14–364] | 210 ±130 [22–575] | 157 ±57 [3–253] | 40 ±24 [1–78] | noise |
| stage boss | core_chamber | 48 | common+0 | 707 ±130 [369–983] | 707 ±130 [369–983] | 707 ±130 [369–983] | 748 ±99 [569–983] | noise |
| stage boss | core_chamber | 48 | rare+0 | 710 ±155 [242–990] | 675 ±174 [284–1,011] | 522 ±183 [211–983] | 525 ±191 [146–846] | noise |
| stage boss | core_chamber | 48 | epic+0 | 650 ±123 [409–898] | 611 ±108 [316–790] | 520 ±119 [168–735] | 208 ±103 [5–504] | noise |
| stage boss | core_chamber | 48 | legendary+0 | 483 ±119 [222–810] | 438 ±82 [313–713] | 289 ±159 [8–756] | 78 ±58 [0–197] | noise |
| stage boss | core_chamber | 48 | mixed+3 | 547 ±156 [293–878] | 506 ±118 [280–755] | 495 ±159 [181–827] | 320 ±142 [103–734] | noise |
| stage boss | core_chamber | 48 | epic+10 | 315 ±73 [155–446] | 243 ±89 [1–444] | 97 ±50 [1–236] | 54 ±30 [1–140] | noise |
| mini-boss | spillway_chief | 45 | common+0 | 847 ±215 [309–1,317] | 847 ±215 [309–1,317] | 852 ±226 [309–1,411] | 852 ±226 [309–1,411] | noise |
| mini-boss | spillway_chief | 45 | rare+0 | 803 ±131 [517–1,038] | 629 ±179 [206–956] | 534 ±125 [226–750] | 458 ±110 [296–743] | noise |
| mini-boss | spillway_chief | 45 | epic+0 | 724 ±181 [410–1,093] | 684 ±143 [357–962] | 512 ±166 [165–864] | 316 ±117 [5–571] | noise |
| mini-boss | spillway_chief | 45 | legendary+0 | 607 ±221 [232–1,016] | 586 ±182 [176–970] | 278 ±71 [126–432] | 139 ±80 [2–394] | noise |
| mini-boss | spillway_chief | 45 | mixed+3 | 861 ±112 [652–1,099] | 740 ±130 [440–953] | 538 ±135 [317–816] | 282 ±146 [0–565] | noise |
| mini-boss | spillway_chief | 45 | epic+10 | 373 ±79 [242–574] | 366 ±100 [84–520] | 216 ±66 [20–355] | 41 ±27 [4–134] | noise |
| mini-boss | arthit_reinstated | 55 | common+0 | 1,938 ±198 [1,459–2,437] | 1,938 ±198 [1,459–2,437] | 1,938 ±198 [1,459–2,437] | 1,938 ±198 [1,459–2,437] | noise |
| mini-boss | arthit_reinstated | 55 | rare+0 | 1,317 ±275 [923–1,809] | 1,343 ±223 [806–1,769] | 1,160 ±178 [728–1,609] | 684 ±163 [395–973] | noise |
| mini-boss | arthit_reinstated | 55 | epic+0 | 1,206 ±213 [738–1,666] | 1,126 ±172 [657–1,527] | 708 ±123 [521–1,133] | 380 ±88 [222–580] | noise |
| mini-boss | arthit_reinstated | 55 | legendary+0 | 1,375 ±187 [1,092–1,780] | 1,038 ±198 [634–1,526] | 653 ±143 [330–925] | 183 ±68 [3–354] | likely |
| mini-boss | arthit_reinstated | 55 | mixed+3 | 1,077 ±189 [659–1,478] | 881 ±89 [633–1,037] | 654 ±136 [426–999] | 350 ±126 [79–601] | likely |
| mini-boss | arthit_reinstated | 55 | epic+10 | 490 ±120 [282–711] | 329 ±65 [171–485] | 163 ±51 [38–271] | 19 ±7 [4–36] | likely |
| mini-boss | k7_overdriven | 65 | common+0 | 1,735 ±324 [1,080–2,574] | 1,735 ±324 [1,080–2,574] | 1,735 ±324 [1,080–2,574] | 1,735 ±324 [1,080–2,574] | noise |
| mini-boss | k7_overdriven | 65 | rare+0 | 1,266 ±231 [716–1,832] | 1,286 ±344 [677–2,452] | 1,341 ±208 [930–1,747] | 568 ±118 [382–867] | noise |
| mini-boss | k7_overdriven | 65 | epic+0 | 1,298 ±254 [428–1,693] | 1,089 ±224 [426–1,520] | 850 ±189 [490–1,287] | 298 ±117 [95–598] | noise |
| mini-boss | k7_overdriven | 65 | legendary+0 | 1,483 ±274 [968–2,317] | 700 ±242 [229–1,484] | 569 ±158 [258–1,094] | 121 ±43 [46–243] | clear |
| mini-boss | k7_overdriven | 65 | mixed+3 | 1,147 ±234 [573–1,543] | 1,093 ±206 [518–1,473] | 802 ±96 [635–1,096] | 365 ±119 [156–578] | noise |
| mini-boss | k7_overdriven | 65 | epic+10 | 329 ±113 [101–543] | 355 ±78 [204–546] | 217 ±51 [145–345] | 12 ±8 [1–31] | noise |
| mini-boss | wiroj_protocol | 70 | common+0 | 1,097 ±358 [299–1,768] | 1,097 ±358 [299–1,768] | 1,097 ±358 [299–1,768] | 1,097 ±358 [299–1,768] | noise |
| mini-boss | wiroj_protocol | 70 | rare+0 | 1,012 ±148 [703–1,258] | 1,010 ±191 [509–1,273] | 862 ±273 [268–1,381] | 336 ±114 [62–561] | noise |
| mini-boss | wiroj_protocol | 70 | epic+0 | 830 ±248 [454–1,379] | 758 ±248 [85–1,160] | 497 ±161 [0–838] | 293 ±145 [12–601] | noise |
| mini-boss | wiroj_protocol | 70 | legendary+0 | 1,134 ±371 [649–2,458] | 693 ±170 [439–1,172] | 363 ±121 [118–679] | 82 ±81 [1–303] | likely |
| mini-boss | wiroj_protocol | 70 | mixed+3 | 766 ±268 [33–1,240] | 661 ±168 [338–1,050] | 512 ±63 [385–704] | 330 ±115 [75–605] | noise |
| mini-boss | wiroj_protocol | 70 | epic+10 | 287 ±92 [109–566] | 268 ±103 [100–591] | 160 ±97 [5–450] | 11 ±10 [1–40] | noise |

### 1.7 Stage bosses and mini-bosses: food eaten per fight [SIMULATED]

| Fight | Target | Hero Lv | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) | MR vs current |
|---|---|---:|---|---|---|---|---|---|
| stage boss | test_labs | 35 | common+0 | 1.8 ±0.6 [0.0–3.0] | 1.8 ±0.6 [0.0–3.0] | 1.7 ±0.6 [0.0–3.0] | 1.7 ±0.6 [0.0–3.0] | noise |
| stage boss | test_labs | 35 | rare+0 | 1.9 ±0.9 [0.0–4.0] | 2.4 ±1.0 [0.0–5.0] | 1.6 ±0.7 [0.0–3.0] | 0.9 ±0.7 [0.0–2.0] | noise |
| stage boss | test_labs | 35 | epic+0 | 1.6 ±0.7 [0.0–3.0] | 1.0 ±0.8 [0.0–3.0] | 1.0 ±0.8 [0.0–3.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | test_labs | 35 | legendary+0 | 0.8 ±0.6 [0.0–2.0] | 0.5 ±0.5 [0.0–2.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | test_labs | 35 | mixed+3 | 0.4 ±0.4 [0.0–1.0] | 0.4 ±0.4 [0.0–1.0] | 0.1 ±0.2 [0.0–1.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | test_labs | 35 | epic+10 | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | control_room | 39 | common+0 | 2.4 ±0.4 [2.0–3.0] | 2.4 ±0.4 [2.0–3.0] | 2.4 ±0.4 [2.0–3.0] | 2.1 ±0.4 [1.0–3.0] | noise |
| stage boss | control_room | 39 | rare+0 | 1.9 ±0.5 [1.0–3.0] | 1.9 ±1.1 [-1.0–4.0] | 1.4 ±0.8 [0.0–4.0] | 0.5 ±0.4 [0.0–1.0] | noise |
| stage boss | control_room | 39 | epic+0 | 2.0 ±0.5 [1.0–3.0] | 1.6 ±0.7 [0.0–3.0] | 0.0 ±0.5 [-1.0–1.0] | 0.0 ±0.3 [-1.0–1.0] | noise |
| stage boss | control_room | 39 | legendary+0 | 0.6 ±0.6 [-1.0–2.0] | 0.8 ±0.6 [0.0–2.0] | -0.1 ±0.2 [-1.0–0.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | control_room | 39 | mixed+3 | 1.3 ±0.6 [0.0–2.0] | 1.0 ±0.8 [-1.0–2.0] | 0.8 ±0.6 [0.0–2.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | control_room | 39 | epic+10 | -0.2 ±0.3 [-1.0–0.0] | 0.1 ±0.2 [0.0–1.0] | 0.0 ±0.0 [0.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | noise |
| stage boss | core_chamber | 48 | common+0 | 2.1 ±0.5 [1.0–3.0] | 2.1 ±0.5 [1.0–3.0] | 2.0 ±0.6 [1.0–3.0] | 2.1 ±0.5 [1.0–3.0] | noise |
| stage boss | core_chamber | 48 | rare+0 | 2.2 ±0.7 [0.0–3.0] | 1.8 ±0.7 [0.0–3.0] | 1.1 ±0.9 [0.0–3.0] | 0.9 ±0.7 [0.0–2.0] | noise |
| stage boss | core_chamber | 48 | epic+0 | 1.5 ±0.6 [0.0–3.0] | 1.2 ±0.6 [0.0–2.0] | 0.7 ±0.5 [0.0–2.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| stage boss | core_chamber | 48 | legendary+0 | 0.7 ±0.5 [0.0–2.0] | 0.1 ±0.2 [0.0–1.0] | 0.2 ±0.3 [0.0–1.0] | 0.0 ±0.0 [0.0–0.0] | likely |
| stage boss | core_chamber | 48 | mixed+3 | 1.1 ±0.8 [0.0–3.0] | 1.0 ±0.6 [0.0–2.0] | 0.7 ±0.6 [0.0–2.0] | 0.2 ±0.3 [0.0–1.0] | noise |
| stage boss | core_chamber | 48 | epic+10 | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| mini-boss | spillway_chief | 45 | common+0 | 2.6 ±1.0 [0.0–5.0] | 2.6 ±1.0 [0.0–5.0] | 2.6 ±1.0 [0.0–5.0] | 2.6 ±1.0 [0.0–5.0] | noise |
| mini-boss | spillway_chief | 45 | rare+0 | 2.5 ±0.7 [1.0–4.0] | 1.5 ±0.8 [0.0–3.0] | 1.3 ±0.6 [0.0–2.0] | 0.7 ±0.6 [0.0–2.0] | likely |
| mini-boss | spillway_chief | 45 | epic+0 | 1.9 ±1.1 [0.0–4.0] | 1.5 ±0.7 [0.0–3.0] | 0.7 ±0.7 [0.0–2.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| mini-boss | spillway_chief | 45 | legendary+0 | 1.4 ±0.9 [0.0–3.0] | 1.2 ±0.8 [0.0–3.0] | 0.0 ±0.0 [0.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | noise |
| mini-boss | spillway_chief | 45 | mixed+3 | 2.5 ±0.6 [1.0–4.0] | 1.9 ±0.6 [1.0–3.0] | 0.9 ±0.6 [0.0–2.0] | 0.1 ±0.2 [0.0–1.0] | noise |
| mini-boss | spillway_chief | 45 | epic+10 | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | noise |
| mini-boss | arthit_reinstated | 55 | common+0 | 6.5 ±0.9 [4.0–9.0] | 6.5 ±0.9 [4.0–9.0] | 6.5 ±0.9 [4.0–9.0] | 6.5 ±0.9 [4.0–9.0] | noise |
| mini-boss | arthit_reinstated | 55 | rare+0 | 4.0 ±1.5 [2.0–7.0] | 3.9 ±1.0 [1.0–6.0] | 2.9 ±1.3 [1.0–6.0] | 0.4 ±0.7 [-1.0–2.0] | noise |
| mini-boss | arthit_reinstated | 55 | epic+0 | 3.0 ±1.5 [-2.0–6.0] | 2.8 ±0.9 [1.0–5.0] | 0.5 ±0.8 [-1.0–3.0] | -0.4 ±0.5 [-2.0–0.0] | noise |
| mini-boss | arthit_reinstated | 55 | legendary+0 | 3.7 ±0.8 [2.0–5.0] | 2.8 ±1.0 [0.0–5.0] | 0.3 ±0.8 [-1.0–2.0] | -0.1 ±0.2 [-1.0–0.0] | noise |
| mini-boss | arthit_reinstated | 55 | mixed+3 | 2.8 ±0.9 [1.0–5.0] | 1.7 ±0.7 [0.0–3.0] | 0.5 ±0.7 [-1.0–2.0] | -0.4 ±0.4 [-1.0–0.0] | likely |
| mini-boss | arthit_reinstated | 55 | epic+10 | -0.4 ±0.4 [-1.0–0.0] | -0.4 ±0.5 [-2.0–0.0] | 0.0 ±0.0 [0.0–0.0] | -0.4 ±0.4 [-1.0–0.0] | noise |
| mini-boss | k7_overdriven | 65 | common+0 | 5.9 ±1.4 [3.0–10.0] | 5.9 ±1.4 [3.0–10.0] | 5.9 ±1.4 [3.0–10.0] | 5.9 ±1.4 [3.0–10.0] | noise |
| mini-boss | k7_overdriven | 65 | rare+0 | 3.4 ±1.2 [0.0–6.0] | 3.7 ±1.5 [1.0–9.0] | 3.6 ±1.1 [1.0–6.0] | 0.2 ±0.3 [0.0–1.0] | noise |
| mini-boss | k7_overdriven | 65 | epic+0 | 3.4 ±1.0 [0.0–5.0] | 2.6 ±1.0 [0.0–5.0] | 1.3 ±1.0 [-1.0–3.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| mini-boss | k7_overdriven | 65 | legendary+0 | 4.6 ±1.4 [2.0–8.0] | 0.8 ±1.0 [-1.0–4.0] | 0.2 ±0.5 [0.0–2.0] | 0.0 ±0.0 [0.0–0.0] | clear |
| mini-boss | k7_overdriven | 65 | mixed+3 | 2.8 ±1.2 [0.0–5.0] | 2.4 ±1.0 [0.0–4.0] | 0.9 ±0.6 [-1.0–2.0] | -0.1 ±0.2 [-1.0–0.0] | noise |
| mini-boss | k7_overdriven | 65 | epic+10 | -0.1 ±0.2 [-1.0–0.0] | -0.3 ±0.3 [-1.0–0.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| mini-boss | wiroj_protocol | 70 | common+0 | 2.9 ±1.6 [0.0–6.0] | 2.9 ±1.6 [0.0–6.0] | 2.9 ±1.6 [0.0–6.0] | 2.9 ±1.6 [0.0–6.0] | noise |
| mini-boss | wiroj_protocol | 70 | rare+0 | 2.3 ±0.8 [1.0–4.0] | 2.1 ±1.0 [-1.0–4.0] | 1.6 ±1.1 [0.0–4.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| mini-boss | wiroj_protocol | 70 | epic+0 | 1.4 ±1.3 [-1.0–4.0] | 1.1 ±0.8 [0.0–3.0] | 0.0 ±0.3 [-1.0–1.0] | 0.0 ±0.0 [0.0–0.0] | noise |
| mini-boss | wiroj_protocol | 70 | legendary+0 | 2.9 ±1.3 [1.0–7.0] | 0.5 ±0.5 [0.0–2.0] | 0.0 ±0.0 [0.0–0.0] | 0.0 ±0.0 [0.0–0.0] | clear |
| mini-boss | wiroj_protocol | 70 | mixed+3 | 1.0 ±0.8 [0.0–3.0] | 0.4 ±0.7 [-1.0–2.0] | -0.2 ±0.3 [-1.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | noise |
| mini-boss | wiroj_protocol | 70 | epic+10 | 0.0 ±0.0 [0.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | 0.0 ±0.0 [0.0–0.0] | -0.1 ±0.2 [-1.0–0.0] | noise |

Boss findings [SIMULATED, 10 seeds]:

- **Every stage-boss and mini-boss fight was won**, with no downs, in every model
  and build, Common +0 included. Hero at the boss area's level.
- **MR against current:**
  - Kill times differ by at most about 15%, and only 3 of 42 rows are more than
    noise. Two of those 3 are Legendary kits with the new items.
  - Damage taken is "clear" only for the Lv 65 Legendary kit (1,483 → 700) and
    "likely" for 4 more rows. Everything else is noise.
  - One "likely" row goes the other way: `director_wiroj` with an Epic +10 kit,
    45 → 52 s. One "clear" row is unexpectedly large: `arthit_reinstated` with an
    Epic +10 kit, 43 → 33 s, for a kit only +5% stronger. Both are within what
    chaotic divergence produces (see the warning in §1.4); neither is a finding.
- **Model A** cuts kill times by 25–50% and damage taken by 60–98%. For example,
  the Lv 65 mini-boss with an Epic +10 kit takes 12 damage. The bosses would need
  re-tuning.
- **Healing:** food per fight follows damage taken. Today and MR use 0–3 items
  per fight; Model A uses about 0.


## 2. MR versus Model A and Model B

All tables in §1 carry the Model B and Model A columns too.


Summary [SIMULATED, with the confidence above]:

| | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) |
|---|---|---|---|
| Farming, Lv 37–70 (kills / damage taken against current) | small; within noise except the new Legendaries | kills +5–40%, damage taken −20–65% | kills +30–75%, damage taken −60–99% |
| Stage and mini-bosses | within noise | kill time 0 to −27%, damage taken −10–70% | kill time −25–50%, damage taken −60–98% |
| World bosses, one hero, damage per minute | within noise (±15%) | 0 to +40% (more against today's weak Legendary kit) | +40–190% |
| Raid `founders_engine`, downs at +0 (out of 5) | Epic 5, Legendary 2, Godforged 4 | Epic 2, Legendary 0, Godforged 0 | 0 for all |
| PvP, Rare +10 against Legendary +0 | Rare wins 39/40 | 34–36/40 | 13–14/40 |
| Godforged stats changed | no | yes (all 25 items) | yes (all 25 items) |

- **Model B and Model A make the game easier across the board**, and Model A
  removes most PvE threat.
- **MR changes little in PvE beyond the new Legendaries.** That is consistent with
  its goal: order and spacing, not difficulty.


## 3. Level progression

### 3.1 The newest item a player can wear, per slot and grade [VERIFIED]

From the data. **Bold** marks Rare or Epic gear 15 or more levels older than the
hero.

| Hero Lv | Slot | Common | Uncommon | Rare | Epic | Legendary (today → with proposal) | Godforged |
|---:|---|---:|---:|---:|---:|---|---:|
| 39 | weapon | 35 | 35 | 38 | 27 | 39 | 30 |
| 39 | head | 33 | 33 | 30 | **22** | 30 | none |
| 39 | body | 33 | 33 | **24** | **23** | 30 | none |
| 39 | hands | 35 | 35 | **20** | **21** | 35 | none |
| 39 | feet | 35 | 35 | 34 | 39 | none | none |
| 39 | charm | none | 3 | 26 | 35 | 31 | 30 |
| 49 | weapon | 44 | 44 | 38 | **27** | 39 | 30 |
| 49 | head | 42 | 42 | **30** | 42 | 48 | none |
| 49 | body | 42 | 42 | **24** | 48 | 30 | none |
| 49 | hands | 44 | 44 | 44 | **21** | 35 | 45 |
| 49 | feet | 44 | 44 | **34** | 39 | none | none |
| 49 | charm | none | 3 | **26** | 35 | 48 | 45 |
| 59 | weapon | 58 | 58 | 58 | 58 | 39 → 55 | 50 |
| 59 | head | 58 | 58 | 58 | 58 | 48 | 56 |
| 59 | body | 58 | 58 | 58 | 58 | 30 | 56 |
| 59 | hands | 58 | 58 | 58 | 58 | 35 → 55 | 45 |
| 59 | feet | 58 | 58 | 58 | 58 | none → 55 | 56 |
| 59 | charm | 58 | 58 | 58 | 58 | 48 | 45 |
| 70 | weapon | 68 | 68 | 68 | 68 | 39 → 65 | 70 |
| 70 | head | 68 | 68 | 68 | 68 | 48 → 70 | 70 |
| 70 | body | 68 | 68 | 68 | 68 | 30 → 70 | 70 |
| 70 | hands | 68 | 68 | 68 | 68 | 35 → 65 | 70 |
| 70 | feet | 68 | 68 | 68 | 68 | none → 65 | 70 |
| 70 | charm | 68 | 68 | 68 | 68 | 48 → 70 | 70 |

Findings from the table above (VERIFIED from data):

- **Lv 30–39: Epic and Rare are thin.**
  - At Lv 39 the newest Epic weapon is Lv 27, Epic head Lv 22, Epic body Lv 23
    and Epic hands Lv 21.
  - The newest Rare body is Lv 24 and Rare hands Lv 20.
  - Players in this band wear Common or Uncommon shop gear, or old boss pieces.
- **Lv 40–49: the largest gap.**
  - The newest Epic weapon stays at **Lv 27** and Epic hands at **Lv 21** until
    the Lv 53 tier.
  - Rare body stays at Lv 24 and Rare charm at Lv 26.
  - Only Spillway Chief's Lv 42 Epic head and body and the Lv 48 Legendaries are
    new.
  - So at Lv 45 the "Epic" kit does less damage than the "Rare" kit (§1.1:
    5.73 against 6.26, current).
- **Lv 50–59** is well covered from Lv 53. Today it has no Legendary newer than
  Lv 48. The proposal adds Lv 55 weapon, hands and feet.
- **Lv 60–70** is fully covered from Lv 63 to 68 for Common to Epic. The proposal
  adds Legendary at 60, 65 and 70.
- **Charms:** no Common or Uncommon charm exists between Lv 3 and Lv 53
  (VERIFIED).
- **PROPOSED (needs approval; not part of the grade decision):** an Epic and Rare
  refresh around Lv 40–45 for weapon, hands and charm. That is the most important
  progression gap. No grade-weight model fixes it, because the items do not
  exist.


## 4. Grade progression

The same tables, read across builds at one level:

- Damage and EHP: §1.1 [MODELED].
- Farming, bosses and survival by grade: §1.2–1.7 [SIMULATED].


Grade findings:

- [MODELED] Under MR, every grade step at Lv 70 raises PvE EHP (Rare 2,438 →
  Epic 4,134 → Legendary 8,591 → Godforged 9,831). Damage rises 3–23% per step.
  Damage steps are small because of the caps (§8).
- [SIMULATED] In farming and bosses the order shows in damage taken and food used
  (§1.3, §1.6). Kill speed is within noise between adjacent grades at most
  levels.
- **Lv 45 exception** [MODELED, VERIFIED data]: the Epic kit does less damage than
  the Rare kit (5.73 against 6.26 current; 6.00 against 6.46 MR), because no Epic
  weapon exists between Lv 27 and 53 (§3).
- **Mixed builds** (Epic weapon and charm, the rest Rare or Uncommon, +3) sit
  between Rare and Epic +0. In PvP, Mixed +3 beats Epic +0 in 27–32 of 40 matches
  (65–80%), except under Model A.
- **Specialisations:** offence-picked against defence-picked Epic split about
  evenly in PvP (16–27 of 40; Wilson intervals overlap 50% in every model). The
  stat mixes are balanced against each other.


## 5. Enhancement

### 5.1 Lv 70 kits from +0 to +10 [MODELED]

Cell: damage / PvE EHP / PvP EHP.

| Build | Model | +0 | +1 | +3 | +5 | +7 | +10 |
|---|---|---:|---:|---:|---:|---:|---:|
| rare | Current | 10.29 / 2,284 / 3,432 | 10.81 / 2,593 / 3,649 | 11.89 / 3,446 / 4,103 | 13.00 / 4,873 / 4,584 | 14.15 / 7,749 / 5,091 | 15.96 / 35,009 / 5,901 |
| rare | MR | 10.61 / 2,438 / 3,550 | 11.17 / 2,800 / 3,782 | 12.32 / 3,836 / 4,270 | 13.52 / 5,712 / 4,788 | 14.76 / 10,137 / 5,335 | 16.48 / 135,362 / 6,211 |
| rare | Model B (+Godforged ×1.47) | 11.65 / 3,201 / 3,995 | 12.34 / 3,896 / 4,289 | 13.76 / 6,398 / 4,909 | 15.25 / 14,610 / 5,570 | 16.55 / 135,955 / 6,273 | 18.18 / 147,906 / 7,407 |
| rare | Model A (+Godforged ×2.70) | 14.59 / 9,751 / 5,285 | 15.66 / 22,977 / 5,766 | 17.28 / 141,286 / 6,790 | 18.82 / 152,526 / 7,898 | 20.35 / 163,765 / 9,089 | 22.65 / 180,624 / 11,034 |
| epic | Current | 10.41 / 3,379 / 4,121 | 10.96 / 4,156 / 4,433 | 12.07 / 7,070 / 5,091 | 13.24 / 18,172 / 5,794 | 14.38 / 140,422 / 6,542 | 15.63 / 153,161 / 7,750 |
| epic | MR | 10.93 / 4,134 / 4,423 | 11.54 / 5,389 / 4,778 | 12.80 / 11,745 / 5,528 | 14.11 / 138,032 / 6,333 | 15.07 / 147,338 / 7,193 | 16.44 / 161,298 / 8,585 |
| epic | Model B (+Godforged ×1.47) | 12.56 / 9,234 / 5,363 | 13.38 / 19,665 / 5,855 | 14.80 / 144,702 / 6,905 | 15.96 / 156,467 / 8,040 | 17.11 / 168,232 / 9,262 | 18.84 / 185,879 / 11,257 |
| epic | Model A (+Godforged ×2.70) | 16.22 / 159,179 / 8,388 | 17.11 / 168,274 / 9,353 | 18.89 / 186,464 / 11,439 | 20.67 / 204,653 / 13,736 | 22.45 / 222,843 / 16,242 | 25.12 / 250,127 / 20,395 |
| legendary | Current | 10.50 / 1,839 / 3,168 | 10.82 / 2,004 / 3,349 | 11.45 / 2,398 / 3,726 | 12.09 / 2,904 / 4,123 | 12.73 / 3,582 / 4,540 | 13.68 / 5,169 / 5,202 |
| legendary | MR | 12.01 / 8,591 / 5,319 | 12.76 / 16,878 / 5,805 | 14.30 / 144,372 / 6,840 | 15.39 / 156,086 / 7,959 | 16.46 / 167,799 / 9,164 | 18.08 / 185,370 / 11,129 |
| legendary | Model B (+Godforged ×1.47) | 14.68 / 148,500 / 7,242 | 15.42 / 156,526 / 8,023 | 16.89 / 172,580 / 9,705 | 18.37 / 188,633 / 11,548 | 19.84 / 204,687 / 13,550 | 22.05 / 228,767 / 16,854 |
| legendary | Model A (+Godforged ×2.70) | 20.02 / 206,730 / 13,767 | 21.29 / 220,579 / 15,632 | 23.83 / 248,279 / 19,717 | 26.38 / 275,979 / 24,275 | 28.92 / 303,678 / 29,307 | 32.73 / 345,227 / 37,743 |
| godforged | Current | 14.76 / 9,831 / 5,710 | 15.50 / 21,003 / 6,254 | 16.99 / 155,391 / 7,415 | 18.48 / 168,800 / 8,674 | 19.96 / 182,209 / 10,032 | 22.20 / 202,322 / 12,253 |
| godforged | MR | 14.76 / 9,831 / 5,710 | 15.50 / 21,003 / 6,254 | 16.99 / 155,391 / 7,415 | 18.48 / 168,800 / 8,674 | 19.96 / 182,209 / 10,032 | 22.20 / 202,322 / 12,253 |
| godforged | Model B (+Godforged ×1.47) | 18.24 / 166,638 / 8,476 | 19.33 / 176,479 / 9,453 | 21.52 / 196,160 / 11,566 | 23.70 / 215,841 / 13,893 | 25.89 / 235,523 / 16,431 | 29.17 / 265,045 / 20,638 |
| godforged | Model A (+Godforged ×2.70) | 27.44 / 249,533 / 18,384 | 29.45 / 267,664 / 21,053 | 33.48 / 303,924 / 26,933 | 37.50 / 340,184 / 33,535 | 41.53 / 376,445 / 40,860 | 47.57 / 430,835 / 53,202 |
| mixed | Current | 10.09 / 2,620 / 3,687 | 10.59 / 3,048 / 3,939 | 11.62 / 4,328 / 4,466 | 12.68 / 6,877 / 5,027 | 13.78 / 14,434 / 5,622 | 15.50 / 140,108 / 6,575 |
| mixed | MR | 10.36 / 2,831 / 3,839 | 10.89 / 3,340 / 4,111 | 11.98 / 4,945 / 4,684 | 13.11 / 8,551 / 5,294 | 14.28 / 24,090 / 5,942 | 16.11 / 145,533 / 6,982 |
| mixed | Model B (+Godforged ×1.47) | 11.41 / 4,011 / 4,416 | 12.06 / 5,162 / 4,769 | 13.41 / 10,563 / 5,517 | 14.82 / 110,255 / 6,319 | 16.28 / 148,347 / 7,176 | 18.13 / 162,485 / 8,563 |
| mixed | Model A (+Godforged ×2.70) | 14.21 / 20,362 / 6,063 | 15.21 / 144,592 / 6,661 | 17.28 / 158,476 / 7,940 | 19.36 / 172,359 / 9,332 | 20.96 / 186,243 / 10,835 | 23.37 / 207,069 / 13,301 |

### 5.2 Enhancement's share of what gear adds (MR, Lv 70) [MODELED]

| Lv 70 kit, MR | Base stats (+0) gain over a bare Lv 70 hero: damage / PvP EHP | +10 gain over +0: damage / PvP EHP | Enhancement's share of the total gear gain (damage / PvP EHP) |
|---|---|---|---|
| common | +92% / +81% | +50% / +58% | 51% / 56% |
| rare | +127% / +118% | +55% / +75% | 50% / 58% |
| epic | +134% / +172% | +50% / +94% | 47% / 60% |
| legendary | +157% / +227% | +51% / +109% | 45% / 61% |
| godforged | +215% / +251% | +50% / +115% | 42% / 62% |

### 5.3 How much enhancement a lower kit needs to match a higher kit at +0 (Lv 70) [MODELED]

| Model | Lower kit | Higher kit +0 | Lower + needed for damage | for PvE EHP | for PvP EHP |
|---|---|---|---|---|---|
| Current | rare | epic | +1 | +3 | +4 |
| Current | epic | legendary | +1 | +0 | +0 |
| Current | legendary | godforged | not by +10 | not by +10 | not by +10 |
| Current | rare | legendary | +1 | +0 | +0 |
| Current | mixed | epic | +1 | +2 | +2 |
| MR | rare | epic | +1 | +4 | +4 |
| MR | epic | legendary | +2 | +3 | +3 |
| MR | legendary | godforged | +4 | +1 | +1 |
| MR | rare | legendary | +3 | +7 | +7 |
| MR | mixed | epic | +2 | +3 | +3 |
| Model B (+Godforged ×1.47) | rare | epic | +2 | +5 | +5 |
| Model B (+Godforged ×1.47) | epic | legendary | +3 | +4 | +4 |
| Model B (+Godforged ×1.47) | legendary | godforged | +5 | +3 | +2 |
| Model B (+Godforged ×1.47) | rare | legendary | +5 | not by +10 | +10 |
| Model B (+Godforged ×1.47) | mixed | epic | +2 | +3 | +3 |
| Model A (+Godforged ×2.70) | rare | epic | +2 | +7 | +6 |
| Model A (+Godforged ×2.70) | epic | legendary | +5 | +6 | +6 |
| Model A (+Godforged ×2.70) | legendary | godforged | +6 | +4 | +3 |
| Model A (+Godforged ×2.70) | rare | legendary | +7 | not by +10 | not by +10 |
| Model A (+Godforged ×2.70) | mixed | epic | +2 | +4 | +4 |

### 5.4 Cost of enhancing one item [VERIFIED rates and costs; MODELED expectation]

Expected values from `progression.json`:

- Each attempt pays its cost.
- A failure keeps the level (`EnhanceRules`, no pity).
- Expected tries per level = 1 / success rate.
- Item Lv 51+ costs ×2 coins and ×1.5 materials; Lv 61+ costs ×3 and ×2.

| Item Lv | To +1 | To +3 | To +5 | To +7 | To +10 |
|---:|---|---|---|---|---|
| 40 | 1.0 tries, 40 coins, 1 scrap, 0 alloy | 3.2 tries, 236 coins, 4 scrap, 0 alloy | 5.8 tries, 764 coins, 11 scrap, 0 alloy | 9.5 tries, 2,178 coins, 24 scrap, 4 alloy | 20.3 tries, 11,844 coins, 97 scrap, 30 alloy |
| 55 | 1.0 tries, 80 coins, 2 scrap, 0 alloy | 3.2 tries, 472 coins, 7 scrap, 0 alloy | 5.8 tries, 1,529 coins, 17 scrap, 0 alloy | 9.5 tries, 4,356 coins, 36 scrap, 7 alloy | 20.3 tries, 23,689 coins, 146 scrap, 45 alloy |
| 68 | 1.0 tries, 120 coins, 2 scrap, 0 alloy | 3.2 tries, 708 coins, 9 scrap, 0 alloy | 5.8 tries, 2,293 coins, 22 scrap, 0 alloy | 9.5 tries, 6,533 coins, 48 scrap, 7 alloy | 20.3 tries, 35,533 coins, 193 scrap, 61 alloy |

Answers:

- **How much does enhancement contribute compared with grade?** [MODELED, §5.2]
  - At Lv 70, +10 adds about +50% damage and +60% to +115% PvP EHP to any kit.
  - That is **42–51% of everything gear adds to damage, and 56–62% of what it adds
    to PvP survival.**
  - Enhancement is as large a lever as base stats in every model, because it
    scales base stats ×2.0 at +10.
- **Does higher-grade +0 gear stay valuable?** Yes in MR.
  - Rare needs +3 (damage) to +7 (survival) to match Legendary +0, and Epic
    needs +2 to +3 (§5.3).
  - **Today** Epic +1 already beats the Lv 70 "Legendary" kit, so Legendary +0
    has no value at Lv 70.
- **Is it reasonable for lower-grade +10 to beat higher-grade +0?** For one grade
  step, yes:
  - A Rare +10 costs about 20 tries and 23,700–35,500 coins plus 145–193 scrap
    and 45–61 alloy at item Lv 55–68 (§5.4).
  - That is the long-term sink the enhancement system is built as.
  - Two steps (Rare +10 beating Legendary +0) is borderline. In MR it holds for
    damage (from +3) and needs +7 for survival. Measured in PvP in §7.
- **Does Legendary +7 beat Godforged +0 too easily?** [MODELED, §5.3]
  - In MR, Legendary needs +4 for damage and +1 for survival.
  - The +1 comes from Godforged spending 14% of its set budget on crit and attack
    speed past the caps (§10).
  - Simulated PvP is in §7 and §10.
- **Does enhancement give long-term value?** Yes, in every model:
  - Each level is +10% of base stats.
  - Expected tries double from +7 (9.5) to +10 (20.3).
  - Coins rise about 5.4× from +7 to +10.
  - Diminishing value per coin at the top is intended.


## 6. PvE

Every PvE table is in §1, and world and raid bosses are below.

### 6.1 World and raid bosses: damage per minute, one hero [SIMULATED]

| Boss | Lv | Raid | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) |
|---|---:|---|---|---|---|---|---|
| tunnel_mother | 32 |  | mixed+3 | 4,776 ±550 [4,093–5,328] | 5,180 ±311 [4,737–5,343] | 5,628 ±517 [5,040–6,067] | 7,028 ±1,046 [6,081–8,320] |
| tunnel_mother | 32 |  | epic+0 | 4,079 ±460 [3,734–4,493] | 4,107 ±658 [3,394–4,738] | 4,374 ±623 [3,941–5,183] | 6,293 ±932 [5,529–7,503] |
| tunnel_mother | 32 |  | legendary+0 | 4,637 ±440 [4,030–4,877] | 4,650 ±525 [3,999–5,043] | 6,234 ±809 [5,573–7,041] | 8,795 ±655 [8,106–9,321] |
| tunnel_mother | 32 |  | legendary+7 | 6,587 ±419 [6,233–7,058] | 7,083 ±880 [6,137–8,108] | 7,857 ±1,383 [6,652–9,335] | 12,487 ±2,425 [10,350–14,815] |
| tunnel_mother | 32 |  | godforged+0 | 5,473 ±723 [4,868–6,283] | 5,473 ±723 [4,868–6,283] | 7,118 ±475 [6,582–7,549] | 9,493 ±1,351 [8,249–10,551] |
| tunnel_mother | 32 |  | epic+10 | 6,000 ±305 [5,700–6,209] | 7,145 ±849 [6,242–7,814] | 7,507 ±1,090 [6,500–8,436] | 10,263 ±461 [9,653–10,576] |
| iron_colossus | 52 |  | mixed+3 | 5,134 ±943 [3,957–5,780] | 5,917 ±692 [5,430–6,869] | 6,182 ±786 [5,466–6,792] | 7,530 ±1,587 [5,787–9,231] |
| iron_colossus | 52 |  | epic+0 | 4,498 ±305 [4,193–4,755] | 4,824 ±341 [4,633–5,306] | 4,623 ±805 [3,727–5,519] | 6,337 ±1,373 [4,756–7,522] |
| iron_colossus | 52 |  | legendary+0 | 5,704 ±950 [4,692–6,529] | 5,449 ±1,114 [4,482–6,848] | 7,148 ±888 [6,139–8,028] | 10,109 ±1,997 [7,827–12,347] |
| iron_colossus | 52 |  | legendary+7 | 7,547 ±1,663 [5,782–9,510] | 8,358 ±1,312 [7,574–10,191] | 9,264 ±1,527 [7,506–10,808] | 14,137 ±1,401 [12,252–15,212] |
| iron_colossus | 52 |  | godforged+0 | 9,015 ±762 [8,475–9,781] | 9,015 ±762 [8,475–9,781] | 9,867 ±1,705 [8,620–12,099] | 17,108 ±2,506 [15,251–20,198] |
| iron_colossus | 52 |  | epic+10 | 6,371 ±1,898 [4,629–8,792] | 6,414 ±1,495 [4,732–7,524] | 6,620 ±1,587 [4,904–8,019] | 8,739 ±1,308 [7,253–9,748] |
| subject_zero | 55 |  | mixed+3 | 5,814 ±1,088 [4,748–7,060] | 6,049 ±1,034 [5,222–7,264] | 7,309 ±1,938 [5,337–9,527] | 8,403 ±1,531 [7,241–10,154] |
| subject_zero | 55 |  | epic+0 | 5,002 ±1,112 [4,076–6,032] | 5,921 ±1,766 [4,255–7,885] | 6,850 ±1,270 [5,559–8,258] | 6,934 ±937 [6,217–8,093] |
| subject_zero | 55 |  | legendary+0 | 5,229 ±1,227 [3,591–6,150] | 6,450 ±1,664 [4,398–7,649] | 7,559 ±1,741 [5,525–9,414] | 10,962 ±1,739 [9,013–12,726] |
| subject_zero | 55 |  | legendary+7 | 6,328 ±1,695 [4,659–7,817] | 9,221 ±1,415 [7,951–10,502] | 10,255 ±1,971 [8,209–12,611] | 17,644 ±1,299 [16,019–18,797] |
| subject_zero | 55 |  | godforged+0 | 6,928 ±480 [6,493–7,398] | 6,928 ±480 [6,493–7,398] | 8,124 ±486 [7,701–8,588] | 13,949 ±1,211 [12,369–15,001] |
| subject_zero | 55 |  | epic+10 | 7,333 ±1,638 [5,453–8,823] | 6,763 ±904 [5,711–7,560] | 8,968 ±1,298 [8,158–10,640] | 12,331 ±1,313 [11,064–13,414] |
| slag_titan | 60 |  | mixed+3 | 6,474 ±1,426 [4,848–7,650] | 6,898 ±1,205 [5,837–7,768] | 8,436 ±1,618 [6,675–10,123] | 8,354 ±956 [7,732–9,652] |
| slag_titan | 60 |  | epic+0 | 5,862 ±859 [5,219–6,914] | 5,598 ±1,491 [4,565–7,425] | 6,836 ±1,259 [5,774–8,202] | 8,552 ±966 [7,974–9,815] |
| slag_titan | 60 |  | legendary+0 | 5,103 ±782 [4,226–5,948] | 6,049 ±308 [5,757–6,379] | 8,304 ±1,046 [7,368–9,641] | 10,577 ±2,432 [8,872–13,760] |
| slag_titan | 60 |  | legendary+7 | 6,829 ±791 [5,968–7,527] | 8,201 ±1,346 [6,794–9,616] | 10,035 ±1,073 [8,797–11,077] | 18,646 ±3,289 [15,435–22,428] |
| slag_titan | 60 |  | godforged+0 | 7,777 ±1,140 [6,593–8,790] | 7,777 ±1,140 [6,593–8,790] | 9,715 ±1,636 [8,400–11,915] | 15,080 ±832 [14,025–15,807] |
| slag_titan | 60 |  | epic+10 | 8,297 ±1,572 [6,889–9,758] | 8,397 ±1,812 [6,817–9,955] | 9,169 ±767 [8,316–9,998] | 13,666 ±3,135 [10,324–16,578] |
| iron_sovereign | 70 |  | mixed+3 | 6,060 ±1,605 [4,753–7,762] | 6,118 ±698 [5,465–6,777] | 6,825 ±812 [5,868–7,434] | 9,069 ±2,901 [6,498–12,589] |
| iron_sovereign | 70 |  | epic+0 | 5,405 ±1,092 [4,151–6,262] | 5,639 ±1,119 [4,123–6,382] | 7,352 ±1,907 [5,618–9,809] | 8,348 ±3,150 [4,603–10,804] |
| iron_sovereign | 70 |  | legendary+0 | 5,127 ±1,469 [3,379–6,711] | 6,577 ±1,148 [5,108–7,655] | 8,859 ±2,731 [7,150–12,361] | 10,348 ±1,704 [8,931–12,107] |
| iron_sovereign | 70 |  | legendary+7 | 6,915 ±1,529 [5,774–8,728] | 8,178 ±1,981 [6,369–10,279] | 10,583 ±1,046 [9,635–11,431] | 17,804 ±3,578 [13,704–21,332] |
| iron_sovereign | 70 |  | godforged+0 | 8,334 ±1,333 [6,650–9,572] | 8,334 ±1,333 [6,650–9,572] | 9,798 ±1,040 [8,513–10,812] | 16,476 ±2,527 [13,826–19,298] |
| iron_sovereign | 70 |  | epic+10 | 8,433 ±1,392 [7,064–9,632] | 8,140 ±1,264 [7,055–9,648] | 9,819 ±2,075 [8,095–12,510] | 12,712 ±4,142 [7,455–15,630] |
| floodgate_marshal | 56 | raid | mixed+3 | 5,175 ±892 [4,225–5,929] | 5,550 ±1,258 [4,326–7,011] | 7,337 ±1,920 [5,664–9,372] | 8,182 ±1,791 [6,789–10,143] |
| floodgate_marshal | 56 | raid | epic+0 | 5,004 ±583 [4,326–5,546] | 4,935 ±487 [4,345–5,393] | 5,801 ±1,171 [4,531–7,082] | 6,703 ±994 [5,688–7,899] |
| floodgate_marshal | 56 | raid | legendary+0 | 4,486 ±1,825 [2,564–6,537] | 6,123 ±1,137 [4,975–7,188] | 7,901 ±481 [7,247–8,175] | 9,540 ±1,166 [8,170–10,617] |
| floodgate_marshal | 56 | raid | legendary+7 | 6,713 ±1,721 [4,935–8,634] | 8,226 ±1,724 [6,477–10,219] | 11,186 ±2,094 [9,425–13,153] | 16,269 ±2,247 [13,995–18,053] |
| floodgate_marshal | 56 | raid | godforged+0 | 6,895 ±1,107 [5,903–7,811] | 6,895 ±1,107 [5,903–7,811] | 7,360 ±693 [6,701–8,143] | 12,802 ±2,554 [9,326–14,776] |
| floodgate_marshal | 56 | raid | epic+10 | 6,210 ±531 [5,691–6,665] | 7,498 ±2,207 [4,818–9,188] | 8,544 ±1,714 [6,774–10,064] | 11,589 ±2,325 [9,835–14,587] |
| crucible_king | 64 | raid | mixed+3 | 6,812 ±969 [6,057–7,728] | 6,349 ±1,024 [5,276–7,504] | 7,194 ±1,259 [6,281–8,432] | 9,581 ±1,813 [7,593–11,196] |
| crucible_king | 64 | raid | epic+0 | 6,020 ±1,187 [4,980–7,588] | 6,445 ±303 [6,036–6,660] | 7,303 ±964 [6,233–8,288] | 8,967 ±1,118 [7,565–10,023] |
| crucible_king | 64 | raid | legendary+0 | 6,124 ±1,401 [5,004–8,014] | 6,650 ±558 [6,113–7,249] | 7,058 ±1,286 [5,775–8,312] | 9,613 ±2,131 [7,669–12,361] |
| crucible_king | 64 | raid | legendary+7 | 6,982 ±1,581 [5,474–8,311] | 8,640 ±1,121 [7,695–9,696] | 9,708 ±2,178 [7,768–11,628] | 14,504 ±1,452 [12,579–15,430] |
| crucible_king | 64 | raid | godforged+0 | 8,204 ±1,625 [5,991–9,110] | 8,204 ±1,625 [5,991–9,110] | 10,301 ±1,208 [8,641–11,040] | 14,245 ±2,478 [12,248–17,425] |
| crucible_king | 64 | raid | epic+10 | 7,457 ±1,589 [6,162–9,011] | 8,305 ±2,140 [6,084–10,590] | 9,850 ±968 [8,640–10,606] | 13,894 ±1,836 [11,483–15,360] |
| founders_engine | 70 | raid | mixed+3 | 6,584 ±2,344 [4,693–9,128] | 6,636 ±1,891 [4,586–8,720] | 7,710 ±1,887 [5,563–9,571] | 8,942 ±2,071 [7,362–11,573] |
| founders_engine | 70 | raid | epic+0 | 4,716 ±1,223 [3,474–5,586] | 5,646 ±2,005 [3,770–8,059] | 5,823 ±935 [4,778–6,513] | 8,783 ±1,519 [7,001–10,447] |
| founders_engine | 70 | raid | legendary+0 | 4,627 ±1,318 [3,157–5,718] | 6,398 ±1,285 [5,190–7,416] | 6,289 ±1,609 [4,261–7,523] | 11,551 ±2,076 [9,345–13,805] |
| founders_engine | 70 | raid | legendary+7 | 5,480 ±1,645 [3,773–7,456] | 8,944 ±3,131 [6,399–11,913] | 11,741 ±2,198 [9,711–14,463] | 15,700 ±3,152 [12,291–18,938] |
| founders_engine | 70 | raid | godforged+0 | 7,139 ±1,427 [6,018–8,778] | 7,139 ±1,427 [6,018–8,778] | 9,357 ±1,918 [7,882–11,808] | 14,431 ±2,534 [11,924–17,443] |
| founders_engine | 70 | raid | epic+10 | 7,964 ±2,170 [6,742–10,974] | 7,939 ±981 [6,730–8,788] | 10,062 ±1,555 [8,154–11,379] | 14,549 ±1,902 [12,788–16,737] |

### 6.2 World and raid bosses: survival and food [SIMULATED]

| Boss | Lv | Raid | Build | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) |
|---|---:|---|---|---|---|---|---|
| tunnel_mother | 32 |  | mixed+3 | 0/5 downs, food 5.2 | 0/5 downs, food 6.4 | 0/5 downs, food 5.0 | 0/5 downs, food 3.0 |
| tunnel_mother | 32 |  | epic+0 | 0/5 downs, food 5.4 | 0/5 downs, food 5.4 | 0/5 downs, food 4.8 | 0/5 downs, food 1.8 |
| tunnel_mother | 32 |  | legendary+0 | 0/5 downs, food 3.4 | 0/5 downs, food 5.0 | 0/5 downs, food 2.6 | 0/5 downs, food 0.2 |
| tunnel_mother | 32 |  | legendary+7 | 0/5 downs, food 1.8 | 0/5 downs, food 1.6 | 0/5 downs, food 0.6 | 0/5 downs, food 0.0 |
| tunnel_mother | 32 |  | godforged+0 | 0/5 downs, food 10.8 | 0/5 downs, food 10.8 | 0/5 downs, food 9.8 | 0/5 downs, food 8.6 |
| tunnel_mother | 32 |  | epic+10 | 0/5 downs, food 2.2 | 0/5 downs, food 2.4 | 0/5 downs, food 1.0 | 0/5 downs, food 0.0 |
| iron_colossus | 52 |  | mixed+3 | 0/5 downs, food 18.6 | 0/5 downs, food 23.8 | 0/5 downs, food 18.8 | 0/5 downs, food 9.6 |
| iron_colossus | 52 |  | epic+0 | 0/5 downs, food 20.2 | 0/5 downs, food 18.0 | 0/5 downs, food 14.2 | 0/5 downs, food 7.0 |
| iron_colossus | 52 |  | legendary+0 | 0/5 downs, food 18.6 | 0/5 downs, food 15.2 | 0/5 downs, food 14.0 | 0/5 downs, food 5.6 |
| iron_colossus | 52 |  | legendary+7 | 0/5 downs, food 11.6 | 0/5 downs, food 10.0 | 0/5 downs, food 5.2 | 0/5 downs, food -0.4 |
| iron_colossus | 52 |  | godforged+0 | 0/5 downs, food 20.0 | 0/5 downs, food 20.0 | 0/5 downs, food 10.4 | 0/5 downs, food 5.0 |
| iron_colossus | 52 |  | epic+10 | 0/5 downs, food 7.6 | 0/5 downs, food 7.2 | 0/5 downs, food 2.8 | 0/5 downs, food -0.4 |
| subject_zero | 55 |  | mixed+3 | 0/5 downs, food 11.4 | 0/5 downs, food 16.2 | 0/5 downs, food 10.0 | 0/5 downs, food 2.4 |
| subject_zero | 55 |  | epic+0 | 0/5 downs, food 14.4 | 0/5 downs, food 16.0 | 0/5 downs, food 9.6 | 0/5 downs, food 1.0 |
| subject_zero | 55 |  | legendary+0 | 0/5 downs, food 24.8 | 0/5 downs, food 20.4 | 0/5 downs, food 11.0 | 0/5 downs, food 0.8 |
| subject_zero | 55 |  | legendary+7 | 0/5 downs, food 12.6 | 0/5 downs, food 6.0 | 0/5 downs, food -0.6 | 0/5 downs, food -2.8 |
| subject_zero | 55 |  | godforged+0 | 0/5 downs, food 21.8 | 0/5 downs, food 21.8 | 0/5 downs, food 16.8 | 0/5 downs, food 3.0 |
| subject_zero | 55 |  | epic+10 | 0/5 downs, food 2.2 | 0/5 downs, food 1.6 | 0/5 downs, food -1.8 | 0/5 downs, food -2.2 |
| slag_titan | 60 |  | mixed+3 | 0/5 downs, food 14.2 | 0/5 downs, food 10.8 | 0/5 downs, food 10.8 | 0/5 downs, food 2.0 |
| slag_titan | 60 |  | epic+0 | 0/5 downs, food 15.8 | 0/5 downs, food 11.4 | 0/5 downs, food 8.4 | 0/5 downs, food 3.8 |
| slag_titan | 60 |  | legendary+0 | 0/5 downs, food 20.2 | 0/5 downs, food 11.6 | 0/5 downs, food 4.8 | 0/5 downs, food -0.8 |
| slag_titan | 60 |  | legendary+7 | 0/5 downs, food 13.2 | 0/5 downs, food 2.6 | 0/5 downs, food -0.6 | 0/5 downs, food -1.0 |
| slag_titan | 60 |  | godforged+0 | 0/5 downs, food 8.8 | 0/5 downs, food 8.8 | 0/5 downs, food 3.8 | 0/5 downs, food -1.2 |
| slag_titan | 60 |  | epic+10 | 0/5 downs, food 3.4 | 0/5 downs, food 2.8 | 0/5 downs, food 0.6 | 0/5 downs, food -0.8 |
| iron_sovereign | 70 |  | mixed+3 | 0/5 downs, food 23.2 | 0/5 downs, food 20.6 | 0/5 downs, food 13.4 | 0/5 downs, food 5.8 |
| iron_sovereign | 70 |  | epic+0 | 0/5 downs, food 23.4 | 0/5 downs, food 22.8 | 0/5 downs, food 14.2 | 0/5 downs, food 5.8 |
| iron_sovereign | 70 |  | legendary+0 | 3/5 downs, food 26.2 | 0/5 downs, food 16.0 | 0/5 downs, food 7.0 | 0/5 downs, food -1.8 |
| iron_sovereign | 70 |  | legendary+7 | 0/5 downs, food 22.0 | 0/5 downs, food 1.6 | 0/5 downs, food -1.4 | 0/5 downs, food -2.6 |
| iron_sovereign | 70 |  | godforged+0 | 0/5 downs, food 16.0 | 0/5 downs, food 16.0 | 0/5 downs, food 3.2 | 0/5 downs, food -2.2 |
| iron_sovereign | 70 |  | epic+10 | 0/5 downs, food 4.6 | 0/5 downs, food 3.2 | 0/5 downs, food 0.2 | 0/5 downs, food -2.0 |
| floodgate_marshal | 56 | raid | mixed+3 | 0/5 downs, food 14.8 | 0/5 downs, food 15.8 | 0/5 downs, food 17.2 | 0/5 downs, food 6.2 |
| floodgate_marshal | 56 | raid | epic+0 | 0/5 downs, food 17.0 | 0/5 downs, food 16.6 | 0/5 downs, food 9.8 | 0/5 downs, food 2.4 |
| floodgate_marshal | 56 | raid | legendary+0 | 1/5 downs, food 20.8 | 0/5 downs, food 17.4 | 0/5 downs, food 14.6 | 0/5 downs, food 3.4 |
| floodgate_marshal | 56 | raid | legendary+7 | 0/5 downs, food 17.6 | 0/5 downs, food 8.8 | 0/5 downs, food 3.2 | 0/5 downs, food -2.6 |
| floodgate_marshal | 56 | raid | godforged+0 | 0/5 downs, food 10.4 | 0/5 downs, food 10.4 | 0/5 downs, food 5.0 | 0/5 downs, food -3.4 |
| floodgate_marshal | 56 | raid | epic+10 | 0/5 downs, food 4.2 | 0/5 downs, food 3.4 | 0/5 downs, food 0.8 | 0/5 downs, food -2.2 |
| crucible_king | 64 | raid | mixed+3 | 0/5 downs, food 15.4 | 0/5 downs, food 16.8 | 0/5 downs, food 10.0 | 0/5 downs, food 5.8 |
| crucible_king | 64 | raid | epic+0 | 0/5 downs, food 21.6 | 0/5 downs, food 20.4 | 0/5 downs, food 10.4 | 0/5 downs, food 6.2 |
| crucible_king | 64 | raid | legendary+0 | 1/5 downs, food 23.8 | 0/5 downs, food 14.4 | 0/5 downs, food 5.4 | 0/5 downs, food -0.4 |
| crucible_king | 64 | raid | legendary+7 | 0/5 downs, food 14.4 | 0/5 downs, food 4.4 | 0/5 downs, food -1.4 | 0/5 downs, food -1.8 |
| crucible_king | 64 | raid | godforged+0 | 0/5 downs, food 13.0 | 0/5 downs, food 13.0 | 0/5 downs, food 6.2 | 0/5 downs, food -2.0 |
| crucible_king | 64 | raid | epic+10 | 0/5 downs, food 2.6 | 0/5 downs, food 3.6 | 0/5 downs, food 0.8 | 0/5 downs, food -2.0 |
| founders_engine | 70 | raid | mixed+3 | 5/5 downs, food 30.0 | 3/5 downs, food 29.2 | 5/5 downs, food 28.6 | 0/5 downs, food 24.6 |
| founders_engine | 70 | raid | epic+0 | 5/5 downs, food 27.8 | 5/5 downs, food 20.6 | 2/5 downs, food 29.0 | 0/5 downs, food 15.0 |
| founders_engine | 70 | raid | legendary+0 | 5/5 downs, food 24.0 | 2/5 downs, food 26.0 | 0/5 downs, food 21.4 | 0/5 downs, food 6.0 |
| founders_engine | 70 | raid | legendary+7 | 2/5 downs, food 28.8 | 0/5 downs, food 13.6 | 0/5 downs, food 7.2 | 0/5 downs, food -1.4 |
| founders_engine | 70 | raid | godforged+0 | 4/5 downs, food 28.0 | 4/5 downs, food 28.0 | 0/5 downs, food 16.4 | 0/5 downs, food 0.6 |
| founders_engine | 70 | raid | epic+10 | 0/5 downs, food 19.8 | 0/5 downs, food 18.8 | 0/5 downs, food 9.8 | 0/5 downs, food -1.6 |

World and raid boss findings [SIMULATED, 5 seeds × 2 minutes, one hero]:

- **Damage per minute:** MR against current is within noise for every boss and
  build (intervals overlap). Model B is 0 to +40% and Model A +40–190% (against current).
- **Survival today:**
  - The Lv 70 "Legendary" kit goes down 3 of 5 times against `iron_sovereign`.
    Epic goes down 0 of 5.
  - Today's Legendary +0 also goes down against `floodgate_marshal` (1/5) and
    `crucible_king` (1/5).
  - Under MR all three are 0 of 5.
- **`founders_engine`** (raid, 30 players):
  - +0 kits go down in most runs today: Epic 5/5, Legendary 5/5, Godforged 4/5.
  - Under MR: Epic 5/5, Legendary 2/5, Godforged 4/5.
  - Under Model B: 0–2/5. Under Model A: 0/5.
  - Solo survival there is not expected at +0. The point is that MR does not make
    the raid soloable, and Model A does.
- **Food:** a negative food count means the hero picked up more food drops than it
  ate.


## 7. PvP (arena, Lv 70) [SIMULATED]

| Job | Side A | Side B | Current | MR | Model B (+Godforged ×1.47) | Model A (+Godforged ×2.70) |
|---|---|---|---|---|---|---|
| boxer | legendary+0 | godforged+0 | A 0/40 (95% 0–9%), HP left 0.00 | A 4/40 (95% 4–23%), HP left 0.01 | A 0/40 (95% 0–9%), HP left 0.00 | A 0/40 (95% 0–9%), HP left 0.00 |
| boxer | legendary+3 | godforged+0 | A 0/40 (95% 0–9%), HP left 0.00 | A 28/40 (95% 55–82%), HP left 0.13 | A 22/40 (95% 40–69%), HP left 0.12 | A 16/40 (95% 26–55%), HP left 0.05 |
| boxer | legendary+7 | godforged+0 | A 4/40 (95% 4–23%), HP left 0.00 | A 40/40 (95% 91–100%), HP left 0.44 | A 40/40 (95% 91–100%), HP left 0.45 | A 40/40 (95% 91–100%), HP left 0.41 |
| boxer | legendary+10 | godforged+0 | – | A 40/40 (95% 91–100%), HP left 0.57 | – | – |
| grappler | legendary+0 | godforged+0 | A 0/40 (95% 0–9%), HP left 0.00 | A 4/40 (95% 4–23%), HP left 0.07 | A 2/40 (95% 1–17%), HP left 0.07 | A 0/40 (95% 0–9%), HP left 0.14 |
| grappler | legendary+3 | godforged+0 | A 0/40 (95% 0–9%), HP left 0.00 | A 27/40 (95% 52–80%), HP left 0.28 | A 19/40 (95% 33–63%), HP left 0.28 | A 14/40 (95% 22–50%), HP left 0.43 |
| grappler | legendary+7 | godforged+0 | A 2/40 (95% 1–17%), HP left 0.02 | A 40/40 (95% 91–100%), HP left 0.51 | A 40/40 (95% 91–100%), HP left 0.51 | A 39/40 (95% 87–100%), HP left 0.60 |
| grappler | legendary+10 | godforged+0 | – | A 40/40 (95% 91–100%), HP left 0.61 | – | – |
| boxer | epic+0 | legendary+0 | A 38/40 (95% 83–99%), HP left 0.29 | A 2/40 (95% 1–17%), HP left 0.01 | A 0/40 (95% 0–9%), HP left 0.00 | A 0/40 (95% 0–9%), HP left 0.00 |
| boxer | rare+10 | legendary+0 | A 40/40 (95% 91–100%), HP left 0.63 | A 39/40 (95% 87–100%), HP left 0.34 | A 36/40 (95% 77–96%), HP left 0.25 | A 13/40 (95% 20–48%), HP left 0.05 |
| boxer | epic+5 | legendary+0 | A 40/40 (95% 91–100%), HP left 0.57 | A 36/40 (95% 77–96%), HP left 0.24 | A 38/40 (95% 83–99%), HP left 0.20 | A 22/40 (95% 40–69%), HP left 0.08 |
| boxer | epic+10 | legendary+0 | A 40/40 (95% 91–100%), HP left 0.74 | A 40/40 (95% 91–100%), HP left 0.52 | A 40/40 (95% 91–100%), HP left 0.51 | A 40/40 (95% 91–100%), HP left 0.46 |
| boxer | mixed+3 | epic+0 | A 29/40 (95% 57–84%), HP left 0.14 | A 27/40 (95% 52–80%), HP left 0.14 | A 30/40 (95% 60–86%), HP left 0.14 | A 14/40 (95% 22–50%), HP left 0.05 |
| boxer | offE+0 | defE+0 | A 21/40 (95% 37–67%), HP left 0.11 | A 23/40 (95% 42–71%), HP left 0.11 | A 16/40 (95% 26–55%), HP left 0.07 | A 18/40 (95% 31–60%), HP left 0.05 |
| boxer | common+10 | rare+0 | A 38/40 (95% 83–99%), HP left 0.40 | A 40/40 (95% 91–100%), HP left 0.37 | A 33/40 (95% 68–91%), HP left 0.21 | A 6/40 (95% 7–29%), HP left 0.03 |
| grappler | epic+0 | legendary+0 | A 38/40 (95% 83–99%), HP left 0.31 | A 3/40 (95% 3–20%), HP left 0.08 | A 1/40 (95% 0–13%), HP left 0.08 | A 0/40 (95% 0–9%), HP left 0.12 |
| grappler | rare+10 | legendary+0 | A 40/40 (95% 91–100%), HP left 0.67 | A 39/40 (95% 87–100%), HP left 0.41 | A 34/40 (95% 71–93%), HP left 0.36 | A 14/40 (95% 22–50%), HP left 0.31 |
| grappler | epic+5 | legendary+0 | A 40/40 (95% 91–100%), HP left 0.58 | A 37/40 (95% 80–97%), HP left 0.38 | A 34/40 (95% 71–93%), HP left 0.41 | A 21/40 (95% 37–67%), HP left 0.46 |
| grappler | epic+10 | legendary+0 | A 40/40 (95% 91–100%), HP left 0.74 | A 40/40 (95% 91–100%), HP left 0.57 | A 40/40 (95% 91–100%), HP left 0.55 | A 40/40 (95% 91–100%), HP left 0.64 |
| grappler | mixed+3 | epic+0 | A 32/40 (95% 65–90%), HP left 0.21 | A 27/40 (95% 52–80%), HP left 0.18 | A 30/40 (95% 60–86%), HP left 0.22 | A 14/40 (95% 22–50%), HP left 0.26 |
| grappler | offE+0 | defE+0 | A 27/40 (95% 52–80%), HP left 0.14 | A 17/40 (95% 29–58%), HP left 0.12 | A 19/40 (95% 33–63%), HP left 0.19 | A 16/40 (95% 26–55%), HP left 0.29 |
| grappler | common+10 | rare+0 | A 39/40 (95% 87–100%), HP left 0.37 | A 39/40 (95% 87–100%), HP left 0.35 | A 35/40 (95% 74–95%), HP left 0.26 | A 10/40 (95% 14–40%), HP left 0.06 |

Arena findings [SIMULATED, 40 matches, Wilson 95% intervals]:

- **The reported problem, confirmed:** today, Epic +0 beats the Lv 70 "Legendary"
  kit 38/40 (83–99%). With the new Legendaries (MR, Model B, Model A), Legendary
  +0 beats Epic +0 37–40/40.
- **Enhancement dominates grade in PvP under today's weights and under MR:**
  - Epic +5 beats Legendary +0 36–37/40.
  - Rare +10 beats Legendary +0 39/40.
  - Common +10 beats Rare +0 39–40/40.
  - **Legendary +3 beats Godforged +0 in 27–28 of 40 (52–82%)**, and Legendary +7
    in 40/40.
  - Only Model A reverses this: Rare +10 wins 13–14/40 and Common +10 wins
    6–10/40.
- Why: PvP gives 2× HP and a defense share of `def / (def + 90)`, so enhancement's
  ×1.3–2.0 on every stat compounds on both offence and defence.
- **Grade steps decide equal-enhancement fights** (+0 against +0) in every model
  with the new items: 37–40 of 40.


## 8. Stat pricing: `ItemRules` against combat value

### 8.1 What one `ItemRules` point of each stat adds [MODELED]

Per point: 0.01 power, 2 HP, 0.2 defense, 0.005 crit, 0.0067 attack speed or
0.01 movement speed. The table gives the % change per point for a current Epic
kit at each level; caps apply.

| Hero Lv (Epic kit, current) | Worn crit / attack speed / defense | Power: dmg | Max HP: PvE / PvP EHP | Defense: PvE / PvP EHP | Crit: dmg | Attack speed: dmg | Speed |
|---:|---|---:|---|---|---:|---:|---:|
| 35 | 0.34 / 1.09 / 24 | 0.26% | 0.30% / 0.30% | 0.98% / 0.18% | 0.21% | 0.61% | 0 (no combat term) |
| 45 | 0.39 / 1.11 / 31 | 0.23% | 0.23% / 0.23% | 0.84% / 0.17% | 0.21% | 0.60% | 0 (no combat term) |
| 55 | 0.62 / 1.14 / 42 | 0.17% | 0.19% / 0.19% | 0.86% / 0.15% | 0.00% | 0.58% | 0 (no combat term) |
| 70 | 0.75 / 1.18 / 52 | 0.14% | 0.15% / 0.15% | 0.70% / 0.14% | 0.00% | 0.51% | 0 (no combat term) |

### 8.2 Stat probes in real fights [SIMULATED]

Points of each stat were added to the worn Epic weapon in memory: +50 at Lv 37,
+100 at Lv 70.

| Ground (hero Lv) | Probe (+points of ItemRules score on the weapon) | Kills / h | Δ kills | Damage taken / h | Δ taken | Food / h | Significance (kills, taken) |
|---|---|---|---:|---|---:|---|---|
| farm_facility_annex (37) | baseline (Epic +0) | 728 ±76 [540–800] | +0% | 15,685 ±5,061 [8,020–24,720] | +0% | 100 | noise, noise |
| farm_facility_annex (37) | power=0.5 | 878 ±73 [760–980] | +21% | 17,760 ±2,738 [12,480–21,840] | +13% | 110 | clear, noise |
| farm_facility_annex (37) | max_hp=100 | 782 ±102 [640–940] | +8% | 18,235 ±3,972 [13,100–26,220] | +16% | 120 | noise, noise |
| farm_facility_annex (37) | defense=10.0 | 762 ±80 [580–880] | +5% | 12,475 ±2,698 [6,840–16,920] | -20% | 88 | noise, noise |
| farm_facility_annex (37) | crit=0.25 | 822 ±57 [720–900] | +13% | 20,102 ±3,504 [14,920–26,580] | +28% | 122 | likely, noise |
| farm_facility_annex (37) | attack_speed=0.3333 | 785 ±85 [620–900] | +8% | 17,848 ±1,471 [14,380–20,120] | +14% | 112 | noise, noise |
| farm_facility_annex (37) | speed=0.5 | 825 ±53 [760–940] | +13% | 17,370 ±5,211 [7,640–25,600] | +11% | 108 | likely, noise |
| farm_iron_heart (70) | baseline (Epic +0) | 995 ±90 [760–1,120] | +0% | 39,182 ±9,119 [24,760–58,240] | +0% | 250 | noise, noise |
| farm_iron_heart (70) | power=1.0 | 1,148 ±104 [1,000–1,400] | +15% | 36,510 ±6,815 [21,580–45,820] | -7% | 232 | likely, noise |
| farm_iron_heart (70) | max_hp=200 | 1,005 ±90 [880–1,180] | +1% | 42,575 ±8,327 [22,860–54,460] | +9% | 285 | noise, noise |
| farm_iron_heart (70) | defense=20.0 | 932 ±99 [800–1,160] | -6% | 30,288 ±9,417 [12,900–47,680] | -23% | 200 | noise, noise |
| farm_iron_heart (70) | crit=0.5 | 995 ±90 [760–1,120] | +0% | 39,182 ±9,119 [24,760–58,240] | +0% | 250 | noise, noise |
| farm_iron_heart (70) | attack_speed=0.6667 | 1,055 ±82 [840–1,180] | +6% | 35,442 ±10,013 [17,760–58,060] | -10% | 225 | noise, noise |
| farm_iron_heart (70) | speed=1.0 | 1,020 ±176 [660–1,280] | +3% | 44,930 ±10,374 [29,680–68,420] | +15% | 295 | noise, noise |

| World boss probe, `iron_sovereign` (Lv 70, Epic +0) | Damage per minute | Δ | Downs | Significance |
|---|---|---:|---|---|
| baseline | 5,768 ±1,246 [4,151–7,587] | +0% | 0/6 | noise |
| power=1.0 | 6,100 ±1,064 [4,325–7,031] | +6% | 0/6 | noise |
| max_hp=200 | 5,856 ±1,258 [4,602–7,422] | +2% | 0/6 | noise |
| defense=20.0 | 5,543 ±1,341 [4,171–7,850] | -4% | 0/6 | noise |
| crit=0.5 | 5,768 ±1,246 [4,151–7,587] | +0% | 0/6 | noise |
| attack_speed=0.6667 | 5,816 ±1,297 [3,783–7,085] | +1% | 1/6 | noise |
| speed=1.0 | 6,075 ±789 [5,003–6,951] | +5% | 2/6 | noise |

Stat pricing findings:

- **Crit beyond the cap is worth exactly 0.** [SIMULATED]
  - With 100 points of crit added at Lv 70, kills, damage taken and world boss
    damage per minute are **identical** to the baseline, every seed. Deterministic
    seeds plus no change in counted stats.
  - Below the cap (Lv 37) the same 50 points of crit add +13% kills ("likely").
  - `ItemRules` prices crit at 200 per 1.0 whatever the cap.
- **Attack speed** is the best stat per point *below* its cap. [MODELED]
  - 0.5–0.6% damage per point against power's 0.14–0.26%.
  - Simulated at Lv 70, +100 points gives +6% kills ("noise"), because only
    +0.12 of the +0.67 added counts.
  - Underpriced below the cap, worthless above it.
- **Power:** +50 points at Lv 37 gives +21% kills ("clear"); +100 at Lv 70 gives
  +15% ("likely"). [SIMULATED] It is the most reliable offence stat in real fights.
- **Defense:**
  - [MODELED] It is 3–5× HP's value per point in PvE (flat reduction), and about
    equal to HP in PvP (share).
  - [SIMULATED] +20 defense at Lv 70 cut damage taken 23%, but within noise at 8
    seeds.
  - At Lv 50–70 its PvE value rises steeply as gear defense nears the monster hit,
    the 1-damage floor (`docs/ITEM_POWER_BALANCE_PROPOSAL.md` §8).
- **Max HP:** steady and lower per point in PvE. 200 HP at Lv 70 changed nothing
  measurable in farming (noise).
- **Movement speed** has no combat term [VERIFIED, `CombatRules`] but real farming
  value. [SIMULATED]
  - +0.5 at Lv 37 gave +13% kills ("likely"): the hero reaches the next group
    sooner.
  - +1.0 at Lv 70 gave +3% (noise).
  - It is not worthless, but its value is in farming tempo, not fights.
- **Slot-specific pricing:**
  - The evidence supports **per-slot ceilings for crit and attack speed**, so a
    full set cannot exceed what counts.
  - It does **not** support re-weighting `STAT_WEIGHTS` globally. That would
    re-score all 267 items and their sell values, for effects these sample sizes
    cannot resolve.
  - PROPOSED: ceilings, plus showing capped values (option C/D of the proposal).


## 9. Validation of the 12 proposed Legendary items [MODELED and VERIFIED]

| Proposed ID | Slot | Lv | Lair (Lv) and mini-boss | Story Bible row | Budget M0 / MR | Score M0 / MR (÷ budget) | MR +10 score | Epic same tier MR +0 / +10 | Godforged same slot MR +0 | Leg +k to pass Godforged +0 score |
|---|---|---:|---|---|---|---|---:|---|---:|---:|
| `coolant_legendary_weapon` | weapon | 55 | `coolant_control_room` (55), `arthit_reinstated` | STORY_BIBLE.md line 309 | 250 / 281 | 248 (0.99) / 282 (1.00) | 564 | 224 / 447 | 428 (`sovereign_fists`) | +6 |
| `coolant_legendary_hands` | hands | 55 | `coolant_control_room` (55), `arthit_reinstated` | STORY_BIBLE.md line 309 | 127 / 143 | 127 (1.00) / 144 (1.01) | 289 | 109 / 217 | 218 (`sovereign_grips`) | +6 |
| `coolant_legendary_feet` | feet | 55 | `coolant_control_room` (55), `arthit_reinstated` | STORY_BIBLE.md line 309 | 106 / 119 | 104 (0.98) / 117 (0.98) | 233 | 98 / 196 | 180 (`sovereign_treads`) | +6 |
| `underworks_legendary_head` | head | 60 | `underworks_tank_hall` (60), `twelve_relapsed` | STORY_BIBLE.md line 311 | 152 / 171 | 152 (1.00) / 173 (1.01) | 346 | 138 / 275 | 238 (`sovereign_crown`) | +4 |
| `underworks_legendary_body` | body | 60 | `underworks_tank_hall` (60), `twelve_relapsed` | STORY_BIBLE.md line 311 | 191 / 215 | 189 (0.99) / 215 (1.00) | 430 | 176 / 352 | 306 (`sovereign_mantle`) | +5 |
| `underworks_legendary_charm` | charm | 60 | `underworks_tank_hall` (60), `twelve_relapsed` | STORY_BIBLE.md line 311 | 156 / 176 | 156 (1.00) / 177 (1.01) | 353 | 140 / 280 | 248 (`sovereign_seal`) | +5 |
| `foundry_legendary_weapon` | weapon | 65 | `foundry_crucible` (65), `k7_overdriven` | STORY_BIBLE.md line 313 | 291 / 328 | 289 (0.99) / 329 (1.00) | 658 | 259 / 518 | 428 (`sovereign_fists`) | +4 |
| `foundry_legendary_hands` | hands | 65 | `foundry_crucible` (65), `k7_overdriven` | STORY_BIBLE.md line 313 | 148 / 166 | 147 (0.99) / 166 (1.00) | 333 | 128 / 256 | 218 (`sovereign_grips`) | +4 |
| `foundry_legendary_feet` | feet | 65 | `foundry_crucible` (65), `k7_overdriven` | STORY_BIBLE.md line 313 | 123 / 139 | 125 (1.02) / 140 (1.01) | 279 | 114 / 227 | 180 (`sovereign_treads`) | +3 |
| `heart_legendary_head` | head | 70 | `heart_core_chamber` (70), `wiroj_protocol` | STORY_BIBLE.md line 315 | 175 / 197 | 173 (0.99) / 196 (1.00) | 392 | 156 / 313 | 238 (`sovereign_crown`) | +3 |
| `heart_legendary_body` | body | 70 | `heart_core_chamber` (70), `wiroj_protocol` | STORY_BIBLE.md line 315 | 221 / 248 | 220 (0.99) / 248 (1.00) | 495 | 198 / 397 | 306 (`sovereign_mantle`) | +3 |
| `heart_legendary_charm` | charm | 70 | `heart_core_chamber` (70), `wiroj_protocol` | STORY_BIBLE.md line 315 | 180 / 202 | 179 (0.99) / 203 (1.00) | 405 | 158 / 316 | 248 (`sovereign_seal`) | +3 |

Checks (VERIFIED against data, MODELED for budgets):

- **Slots:** the 12 items cover every slot. Weapon, hands and feet at 55 and 65;
  head, body and charm at 60 and 70. Feet gains its first Legendary ever.
- **Levels:** each item is at its lair's level (55, 60, 65 and 70). Each is 2
  levels above that tier's Epic set (53, 58, 63, 68) and at or below the Lv 70
  Godforged.
- **Budgets:** every item is within 0–2% of its `ItemRules` budget under both
  today's weights (M0) and MR, so `ItemRules.problems` would accept them.
- **Grade weight:** Legendary, 1.6 today and 1.8 under MR.
- **Enhancement:** the same rule as every item; +10 doubles positive stats.
- **Against Godforged:**
  - No proposed Legendary reaches a Godforged item's score at +0. The ratio is
    0.65–0.82 of the Lv 70 Godforged of its slot.
  - With enhancement, a proposed Legendary passes the same-slot Godforged +0
    *score* at +3 to +6. In *counted* combat value it passes sooner (§5.3, §10),
    because part of Godforged's score is past the caps.
- **Against Epic:** each is 1.19–1.32 × its tier's Epic at +0 (MR), and Epic +2
  to +3 matches it. It does not make the tier's Epic pointless: Epic drops at 15%
  per kill, the Legendary would be a 6% pity drop.
- **Sources:**
  - The four mini-bosses exist in `enemies.json` and are lair rematch bosses.
  - They appear in `docs/STORY_BIBLE.md` (lines 309, 311, 313 and 315, the lair
    table): Commander Arthit, Reinstated; Subject Twelve, Relapsed; Unit K-7,
    Overdriven; The Wiroj Protocol.
  - Each already drops its tier's six Epics at 15%. A Legendary signature drop
    fits the pattern the story-boss Legendaries set (their own character's
    piece). It is not a monster drop, so the rule "no Legendary from monsters"
    holds.
- **Names: UNKNOWN.** The Story Bible gives the bosses but no item names. Names
  must be written from it and approved. The IDs used here are placeholders.
- **Acquisition difficulty: MODELED.**
  - A 6% pity drop reaches 50% after about 30 kills of that mini-boss without
    one.
  - Mini-bosses respawn on their lair timer (`LairRules`). Time to obtain is
    therefore days of play, comparable to a stage-boss Legendary.


## 10. Godforged scenarios

- **A. Unchanged:** the MR column everywhere.
- **B. Re-mix:**
  - Crit is held to per-slot ceilings (weapon 0.15, hands 0.12, charm 0.10,
    head 0.05).
  - Attack speed is held to ceilings (feet 0.20, hands 0.05, weapon 0.05).
  - The removed points go to power (weapon and hands) or max HP (other slots) at
    `ItemRules` prices. Every item's score is unchanged.
- **C. Grade weight ×1.2.**

None was applied.

### 10.1 World and raid bosses [SIMULATED]

| Boss | Lv | Raid | Build | MR | MR + Godforged re-mix (B) | MR + Godforged ×1.2 (C) |
|---|---:|---|---|---|---|---|
| tunnel_mother | 32 |  | legendary+7 | 7,083 ±880 [6,137–8,108] | 7,083 ±880 [6,137–8,108] | 7,083 ±880 [6,137–8,108] |
| tunnel_mother | 32 |  | godforged+0 | 5,473 ±723 [4,868–6,283] | 5,440 ±461 [4,945–5,829] | 6,157 ±414 [5,746–6,467] |
| iron_colossus | 52 |  | legendary+7 | 8,358 ±1,312 [7,574–10,191] | 8,358 ±1,312 [7,574–10,191] | 8,358 ±1,312 [7,574–10,191] |
| iron_colossus | 52 |  | godforged+0 | 9,015 ±762 [8,475–9,781] | 8,162 ±1,793 [6,488–10,225] | 7,894 ±1,448 [6,497–9,182] |
| subject_zero | 55 |  | legendary+7 | 9,221 ±1,415 [7,951–10,502] | 9,221 ±1,415 [7,951–10,502] | 9,221 ±1,415 [7,951–10,502] |
| subject_zero | 55 |  | godforged+0 | 6,928 ±480 [6,493–7,398] | 7,372 ±1,897 [5,840–8,992] | 8,187 ±863 [7,453–9,036] |
| slag_titan | 60 |  | legendary+7 | 8,201 ±1,346 [6,794–9,616] | 8,201 ±1,346 [6,794–9,616] | 8,201 ±1,346 [6,794–9,616] |
| slag_titan | 60 |  | godforged+0 | 7,777 ±1,140 [6,593–8,790] | 9,311 ±1,244 [7,913–10,260] | 9,656 ±1,315 [8,495–11,130] |
| iron_sovereign | 70 |  | legendary+7 | 8,178 ±1,981 [6,369–10,279] | 8,178 ±1,981 [6,369–10,279] | 8,178 ±1,981 [6,369–10,279] |
| iron_sovereign | 70 |  | godforged+0 | 8,334 ±1,333 [6,650–9,572] | 9,988 ±2,745 [7,258–13,367] | 8,862 ±1,162 [7,702–10,110] |
| floodgate_marshal | 56 | raid | legendary+7 | 8,226 ±1,724 [6,477–10,219] | 8,226 ±1,724 [6,477–10,219] | 8,226 ±1,724 [6,477–10,219] |
| floodgate_marshal | 56 | raid | godforged+0 | 6,895 ±1,107 [5,903–7,811] | 6,529 ±1,956 [4,567–8,230] | 8,950 ±1,506 [7,089–10,051] |
| crucible_king | 64 | raid | legendary+7 | 8,640 ±1,121 [7,695–9,696] | 8,640 ±1,121 [7,695–9,696] | 8,640 ±1,121 [7,695–9,696] |
| crucible_king | 64 | raid | godforged+0 | 8,204 ±1,625 [5,991–9,110] | 9,821 ±2,797 [7,696–13,493] | 9,082 ±2,076 [7,533–11,616] |
| founders_engine | 70 | raid | legendary+7 | 8,944 ±3,131 [6,399–11,913] | 8,944 ±3,131 [6,399–11,913] | 8,944 ±3,131 [6,399–11,913] |
| founders_engine | 70 | raid | godforged+0 | 7,139 ±1,427 [6,018–8,778] | 8,006 ±1,091 [6,739–9,164] | 9,392 ±2,659 [7,343–12,390] |

| Boss | Lv | Raid | Build | MR | MR + Godforged re-mix (B) | MR + Godforged ×1.2 (C) |
|---|---:|---|---|---|---|---|
| tunnel_mother | 32 |  | legendary+7 | 0/5 downs, food 1.6 | 0/5 downs, food 1.6 | 0/5 downs, food 1.6 |
| tunnel_mother | 32 |  | godforged+0 | 0/5 downs, food 10.8 | 0/5 downs, food 11.6 | 0/5 downs, food 9.6 |
| iron_colossus | 52 |  | legendary+7 | 0/5 downs, food 10.0 | 0/5 downs, food 10.0 | 0/5 downs, food 10.0 |
| iron_colossus | 52 |  | godforged+0 | 0/5 downs, food 20.0 | 0/5 downs, food 20.2 | 0/5 downs, food 14.6 |
| subject_zero | 55 |  | legendary+7 | 0/5 downs, food 6.0 | 0/5 downs, food 6.0 | 0/5 downs, food 6.0 |
| subject_zero | 55 |  | godforged+0 | 0/5 downs, food 21.8 | 0/5 downs, food 23.8 | 0/5 downs, food 21.0 |
| slag_titan | 60 |  | legendary+7 | 0/5 downs, food 2.6 | 0/5 downs, food 2.6 | 0/5 downs, food 2.6 |
| slag_titan | 60 |  | godforged+0 | 0/5 downs, food 8.8 | 0/5 downs, food 8.8 | 0/5 downs, food 8.8 |
| iron_sovereign | 70 |  | legendary+7 | 0/5 downs, food 1.6 | 0/5 downs, food 1.6 | 0/5 downs, food 1.6 |
| iron_sovereign | 70 |  | godforged+0 | 0/5 downs, food 16.0 | 0/5 downs, food 12.4 | 0/5 downs, food 11.0 |
| floodgate_marshal | 56 | raid | legendary+7 | 0/5 downs, food 8.8 | 0/5 downs, food 8.8 | 0/5 downs, food 8.8 |
| floodgate_marshal | 56 | raid | godforged+0 | 0/5 downs, food 10.4 | 0/5 downs, food 14.0 | 0/5 downs, food 6.0 |
| crucible_king | 64 | raid | legendary+7 | 0/5 downs, food 4.4 | 0/5 downs, food 4.4 | 0/5 downs, food 4.4 |
| crucible_king | 64 | raid | godforged+0 | 0/5 downs, food 13.0 | 0/5 downs, food 15.4 | 0/5 downs, food 10.6 |
| founders_engine | 70 | raid | legendary+7 | 0/5 downs, food 13.6 | 0/5 downs, food 13.6 | 0/5 downs, food 13.6 |
| founders_engine | 70 | raid | godforged+0 | 4/5 downs, food 28.0 | 0/5 downs, food 26.0 | 0/5 downs, food 27.0 |

### 10.2 Arena: Legendary +k against Godforged +0 [SIMULATED]

| Job | Side A | Side B | MR | MR + Godforged re-mix (B) | MR + Godforged ×1.2 (C) |
|---|---|---|---|---|---|
| boxer | legendary+0 | godforged+0 | A 4/40 (95% 4–23%), HP left 0.01 | A 0/40 (95% 0–9%), HP left 0.00 | A 0/40 (95% 0–9%), HP left 0.00 |
| boxer | legendary+3 | godforged+0 | A 28/40 (95% 55–82%), HP left 0.13 | A 13/40 (95% 20–48%), HP left 0.04 | A 9/40 (95% 12–38%), HP left 0.03 |
| boxer | legendary+7 | godforged+0 | A 40/40 (95% 91–100%), HP left 0.44 | A 36/40 (95% 77–96%), HP left 0.28 | A 38/40 (95% 83–99%), HP left 0.27 |
| boxer | legendary+10 | godforged+0 | A 40/40 (95% 91–100%), HP left 0.57 | A 40/40 (95% 91–100%), HP left 0.46 | A 40/40 (95% 91–100%), HP left 0.44 |
| grappler | legendary+0 | godforged+0 | A 4/40 (95% 4–23%), HP left 0.07 | A 1/40 (95% 0–13%), HP left 0.02 | A 0/40 (95% 0–9%), HP left 0.03 |
| grappler | legendary+3 | godforged+0 | A 27/40 (95% 52–80%), HP left 0.28 | A 11/40 (95% 16–43%), HP left 0.18 | A 11/40 (95% 16–43%), HP left 0.20 |
| grappler | legendary+7 | godforged+0 | A 40/40 (95% 91–100%), HP left 0.51 | A 40/40 (95% 91–100%), HP left 0.43 | A 39/40 (95% 87–100%), HP left 0.40 |
| grappler | legendary+10 | godforged+0 | A 40/40 (95% 91–100%), HP left 0.61 | A 40/40 (95% 91–100%), HP left 0.53 | A 40/40 (95% 91–100%), HP left 0.49 |

Godforged findings [SIMULATED]:

- **A, unchanged (MR):**
  - Legendary +3 beats Godforged +0 in 27–28/40 PvP matches; +7 in 40/40.
  - Against world bosses, Legendary +7 matches or beats Godforged +0 in damage
    per minute (for example `subject_zero`: 9,221 against 6,928).
  - Godforged +0 goes down 4 of 5 times against `founders_engine`.
- **B, re-mix (same score):**
  - Legendary +3 now wins only 11–13/40 (16–48%), and +7 still wins 36–40/40.
  - Godforged +0 goes down **0 of 5** against `founders_engine` (4 of 5 under MR):
    the moved budget went into HP.
  - Damage per minute is within noise of MR, with +20% against `slag_titan` and
    `crucible_king`.
- **C, ×1.2 grade weight:**
  - Legendary +3 wins 9–11/40, and +7 38–39/40.
  - 0 of 5 downs against `founders_engine`.
  - Damage per minute within noise of B.
- **B and C protect Godforged equally well in these measurements.**
  - B does it without raising the approved budget, using power already paid for
    but capped.
  - C raises all 25 items' budgets by 20% and moves world boss balance.
  - Neither keeps Godforged +0 ahead of Legendary +7 in PvP. Enhancement's ×1.7
    outweighs a 22% grade step plus the re-mix.
  - Stopping that would need either a much larger Godforged gap (Model A-like) or
    an enhancement change. Both are outside this phase.
- **PvE impact of B:** none harmful.
  - World boss damage per minute is within noise.
  - Survival is better on the hardest raid.
  - No reward, source or table changes.


## 11. Risks and unresolved issues


- **Statistical:**
  - With 5–10 seeds, most MR-vs-current differences are noise. MR's effect on
    PvE difficulty is small, and its size is UNKNOWN beyond "under about
    10–15%".
  - Arena results (40 matches) are clear wherever win counts reach 0–4 or 36–40
    of 40.
- **Bot play:** `AutoPilot` and `ArenaBrain` are not players. A skilled player
  gains more from defense and positioning than the bot does.
- **Enhancement dominance in PvP** is a property of the enhancement rule, not of
  grade weights. MR does not change it, and only Model A-scale gaps do. Accepting
  it, or capping enhancement in PvP, is an open design decision. UNKNOWN which the
  owner wants.
- **The Lv 40–49 Epic and Rare gap** (§3) is the largest progression problem, and
  no grade-weight model fixes it.
- **Flat defense near the 1-damage floor** at Lv 70 (+7 or more) still needs its
  separate decision (proposal §8.3).
- **Model B and Model A** both require Godforged changes, and Model A trivialises
  PvE.
- **The 12 Legendaries** depend on approved names and sources, and the drop
  database must be regenerated.
- **Story Bible:** the Iron Sovereign row still says "Mythic set" (older name for
  Godforged). A documentation fix, separate.


## 12. Recommended final model


**PROPOSED (needs approval): MR, plus the 12 Legendaries, plus Godforged scenario
B.**

1. **Grade weights:** MR (Common 0.85, Uncommon 1.00, Rare 1.22, Epic 1.48,
   Legendary 1.80, Godforged 2.20).
   - It restores order and spacing.
   - It does not measurably change PvE difficulty (§1, §6).
   - It keeps Common, Uncommon and Godforged budgets.
2. **The 12 Lv 55–70 Legendaries** (§9).
   - This is the change with the largest measured effect: Legendary beats Epic
     at +0 in PvP 37–40/40, and Lv 70 damage taken in farming halves.
3. **Godforged re-mix (scenario B):** same budgets, same rewards.
   - It matches the ×1.2 raise in protecting Godforged against Legendary +3.
   - It turns the hardest raid's Godforged +0 downs from 4/5 to 0/5.
4. **Not recommended:**
   - Model B and Model A: they need large Godforged raises, and Model A
     trivialises PvE.
   - Scenario C: same effect as B, at a higher cost.
5. **Separately, and more important than the weights:**
   - Fill the Lv 40–49 Epic and Rare gap (weapon, hands, charm).
   - Per-slot crit and attack-speed ceilings, with capped values shown.
   - Decide whether enhancement should outweigh grade in PvP.


## 13. Exact implementation changes required after approval


Only after approval, in this order. Each step has its tests and docs in the same
change.

1. **`client/sim/ItemRules.gd`:** set `GRADES` to the approved model. For MR:
   `"rare": 1.22, "epic": 1.48, "legendary": 1.8` (Common, Uncommon and Godforged
   unchanged).
2. **Rescale the Rare, Epic and Legendary items** to the new budgets, keeping
   each item's stat mix:
   - Rare ×1.061, Epic ×1.096, Legendary ×1.125 on positive stats; HP and defense
     rounded.
   - Through `tools/content/level70_content.py` for generated items. A scripted
     pass over `items.json` for hand-made ones, and over `item_catalog.json` for
     catalog gear (its grade table).
   - No ID changes. Saves need no migration.
3. **Add the 12 Legendary items** after the Story Bible names are approved.
   - Each mini-boss gets a 6% pity drop entry (a drop-table change; separate
     approval).
4. **Tests:**
   - Update `test_level70_gear` (the Godforged/Legendary ratio assertion) and
     `test_item_catalog`.
   - Add tests: the 12 items are on budget, Legendary sits strictly between Epic
     and Godforged at the same level, and there is no Legendary from monsters.
   - Re-run `test_arena_integrity` and the class-balance tests.
5. **Regenerate** `docs/ITEM_DROP_DATABASE.md` and
   `docs/GODFORGED_IMPACT_REPORT.md` (`DropReportRun.gd`).
6. **Optional and separately approved:**
   - The Godforged re-mix (§10, scenario B).
   - Cap display on the stat sheet.
   - Per-slot crit and attack-speed ceilings in the content check.
7. **Re-measure** with the full harnesses (`FarmCheck`, `EnrageCompare`,
   `WorldBossCheck`, `ArenaBalance`, `DuelCheck`) and update their balance docs.

