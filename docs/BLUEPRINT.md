# The Iron Legacy: Master Blueprint (Milestone IL-0)

> **สถานะ: อนุมัติแล้ว 2026-10-26** เจ้าของอนุมัติคำแนะนำทุกข้อในส่วนที่ 3 (D1–D9)
> เอกสารนี้เป็น **เอกสารหลัก** ของทิศทางเกมตาม Master Prompt "The Iron Legacy"
> เนื้อเรื่อง ชื่อตัวละคร และสถานที่อยู่ใน [STORY_BIBLE.md](STORY_BIBLE.md) ที่เดียว
> ตัวเลขของเกม (ศัตรู ไอเท็ม ท่า) มีแหล่งจริงแหล่งเดียวคือ `client/data/*.json`
> ตารางในเอกสารนี้เป็นภาพรวม ณ วันที่ตรวจ ถ้าขัดกันให้ถือ JSON เป็นหลัก
>
> ตรวจเมื่อ 2026-10-26 ที่ commit `f422677` (main หลัง merge PR #14)

เพื่อไม่ให้ชนกับเลข Milestone เดิมใน [ROADMAP.md](ROADMAP.md) (M1–M8 ซึ่งเน้นออนไลน์)
Milestone ของ Master Prompt ใช้ชื่อ **IL-0 ถึง IL-7** ส่วนที่ 8 แสดงว่าแต่ละขั้นตรงกับของเดิมอย่างไร

---

## 1. Project Audit

### 1.1 สิ่งที่ตรวจ

| ส่วน | ไฟล์ที่อ่าน |
|---|---|
| เอกสาร | README, ARCHITECTURE, GAME_DESIGN, CHANGELOG, CLAUDE.md, docs/ROADMAP, docs/REPOSITORY_AUDIT, docs/ASSETS, docs/UI |
| กฎเกม (`client/sim/`) | CombatRules, Fighter, ZoneSim, EnemyBrain, LevelRules, LootRules, QuestRules, SkillRules, ShopRules, PlayerProfile, ContentDB, MoveLibrary |
| ข้อมูล (`client/data/`) | areas, enemies, heroes, items, moves, progression, quests, shops, skills, weapons |
| Presentation | `scenes/` (Game, Hud, FighterView, ZoneView, CharacterCreate, Title), `scripts/core/` (SaveStore, Sfx, InputSetup) |
| Asset | `art/lpc/characters.json`, `art/kit/kit.json`, `art/weapons/`, `art/sounds/sounds.json` |
| ค่าโปรเจกต์ | `project.godot`: Godot 4.7.2, Compatibility renderer, physics 60 ticks/s |

### 1.2 การทดสอบที่รันจริง (baseline ก่อนแก้อะไร)

| คำสั่ง | ผล |
|---|---|
| `tools/ci/install-godot.sh` | ติดตั้ง Godot 4.7.2.stable.official.ed1daf0bf (ตรวจ SHA-512 แล้ว) |
| `godot --headless --path client --import` | exit 0 |
| `godot --headless --path client --script res://tests/TestRunner.gd` | **140 passed, 0 failed** |
| Probe stun-lock (สคริปต์ชั่วคราว ไม่ได้ commit; ดู 1.4 ข้อ B1) | วัดค่าได้ตามตารางใน B1 |

ยังไม่ได้รันในเซสชันนี้: web export และ browser smoke test (CI รันให้ทุก PR), เกมบนเบราว์เซอร์จริง
และการวัด FPS ข้อสรุปเรื่องเว็บมาจาก CI และเอกสาร ไม่ได้มาจากการทดสอบในเซสชันนี้

### 1.3 แยกตามสถานะ

**A. มีและทำงาน (มีโค้ดและเทสต์รองรับ)**

| ระบบ | หลักฐาน |
|---|---|
| Simulation 60 ticks/s แบบ deterministic | `CombatRules.TICK_RATE`, `test_zone_sim::test_same_seed_and_inputs_replay_identically` |
| เคลื่อนที่ 2 แกน (x และความลึก y) | `LaneMovement`, `test_lane_movement` |
| คอมโบเบา 3 จังหวะ, โจมตีหนัก (ทำลายการ์ด), หลบ (i-frame tick 2–13), การ์ด (เฉพาะด้านหน้า, chip 20%), ล้มและลุก | `CombatRules`, `test_combat` |
| Input buffer 12 ticks | `test_input_buffer` |
| สกิล 4 ช่องต่อฮีโร่, energy, cooldown, ปลดล็อกตามเลเวล, ยกเลิกท่าที่โดนแล้วด้วยสกิล | `SkillRules`, `test_skills`, `test_balance` |
| ฮีโร่ 3 ตัว (Mika, Oren, Riku) เลือกได้ ตั้งชื่อได้ (รวมภาษาไทย) | `heroes.json`, `CharacterCreate`, `test_heroes` |
| อาวุธจากพื้น 9 ชนิด: หยิบ/วาง, สึกหรอ, แตก, หลุดเมื่อล้ม, อยู่ในพื้นที่ของมัน | `weapons.json`, `ZoneSim`, `test_weapons` |
| ศัตรู 10 ชนิด + หุ่นซ้อม, Elite 2, Boss 2 (บอสละ 2 phase) | `enemies.json`, `test_zone_sim::test_boss_enters_second_phase_below_half_hp` |
| AI: เว้นระยะ, attack token (โจมตีพร้อมกันได้สูงสุด 2), เตือนก่อนท่าหนัก, การ์ด/ถอยหลบตามเลเวลพื้นที่, เก็บอาวุธ | `EnemyBrain`, `LevelRules`, `test_levels` |
| เลเวลพื้นที่ปรับพลังศัตรู รางวัล XP/เงิน | `LevelRules`, `test_levels` |
| พื้นที่ 6 แห่งเรียงต่อกัน, encounter ล็อกฉากจนกว่าจะเคลียร์, ฟาร์มซ้ำได้ | `areas.json`, `ZoneSim` |
| XP/เลเวล (สูงสุด 20), เงิน, เสียเงิน 10% เมื่อแพ้ | `progression.json`, `test_progression` |
| Loot table ใช้ RNG แบบ seed | `LootRules` |
| อุปกรณ์ 6 ช่อง (head, body, hands, weapon, feet, charm), rarity 5 ระดับ, required level, ค่าสถานะ | `PlayerProfile`, `items.json` (21 รายการ) |
| Inventory, ร้านค้า 2 ร้าน (Ama, Kenji) | `ShopRules`, `shops.json` |
| Quest แบบสายเดียว 6 ภารกิจ (กำจัดศัตรู), รับ/ส่ง/รางวัล | `QuestRules`, `quests.json` |
| Save/Load ในเครื่อง: มี version (3), migrate ทีละขั้น, ทำความสะอาดค่า, เขียนแบบ atomic, IndexedDB บนเว็บ | `PlayerProfile.migrate`, `SaveStore`, `test_progression` |
| UI: Title, สร้างตัวละคร, HUD, Hotbar, Pause แบบแท็บ, Status, Equipment, Item card เปรียบเทียบของ, Quest log, Dialog NPC | `scenes/ui`, `scenes/game`, `test_ui` |
| Input: คีย์บอร์ด, เกมแพด, ทัชสกรีน | `InputSetup`, `TouchControls` |
| เสียงเอฟเฟกต์ (สังเคราะห์ + บันทึกจริงพร้อมเครดิต), VFX, camera shake | `Sfx`, `GameFeedback`, `Fx` |
| Web export single-thread + smoke test ใน CI | `.github/workflows/ci.yml`, `tools/web-smoke/smoke.ts` |
| Asset pipeline ตรวจ license และความสดใหม่ของไฟล์ใน CI | `tools/assets/validate.py` |
| Backend: health, migration (ยังไม่มี auth) | `backend/` |

**B. มีแต่ยังไม่ครบ**

| ระบบ | ที่ขาด |
|---|---|
| ค่าสถานะ | มี HP, power (≈ATK), defense, speed (ความเร็วเดิน), energy (≈STA) แต่ **ไม่มี** Attack Speed, CRIT, ACC |
| ฮีโร่/อาชีพ | มี 3 ตัว ยังไม่ผูกกับ 6 อาชีพของ Master Prompt |
| Quest | ประเภทเดียวคือ `defeat` ไม่มีภารกิจเสริม ไม่มีภารกิจเก็บของหรือคุยกับ NPC |
| การปลดล็อกพื้นที่ | ทางออกทุกพื้นที่เปิดตลอด ไม่ผูกกับภารกิจหรือบอส |
| บอส | บอสละ 1 การเปลี่ยน phase (ที่ HP < 50%): Sludge Foreman เปลี่ยน moveset, Furnace Baron เปลี่ยนแค่ตัวเลข ยังไม่มีการใช้สภาพแวดล้อม |
| อาวุธชั่วคราว | ยังขว้างไม่ได้ (Master Prompt ข้อ 7) |
| Save | ช่องเซฟเดียว ฮีโร่เดียวต่อเซฟ (GAME_DESIGN บอกว่าจะเก็บแยกต่อฮีโร่ แต่ยังเป็นแค่แผน) ไม่มี unlock progress แยก |
| เนื้อเรื่อง | มีแค่คำบรรยายภารกิจและ bio ฮีโร่ ไม่มีบทสนทนาเชิงเรื่อง ไม่มีบท (chapter) |
| การตั้งค่า | มีเสียง, screen shake, FPS counter (`user://settings.json`) ยังไม่มีเพลง |

**C. ยังไม่มี**

กระโดด · โต้กลับ (counter/parry) · จับทุ่ม · ศัตรูระยะไกล · วัตถุดิบ (materials) · ระบบตีบวก ·
ระบบเนื้อเรื่อง/ฉากคั่น/หลักฐาน · ภารกิจเสริม · Endgame · เพลงประกอบ · การป้องกัน stun-lock ·
อาชีพ Basketball, Police, Soldier · ระบบออนไลน์ใด ๆ (มีแค่ backend เปล่า)

**D. เสียหายหรือมีความเสี่ยง**

| ID | ปัญหา | หลักฐาน | ความรุนแรง |
|---|---|---|---|
| B1 | **Stun-lock** (**แก้แล้วใน IL-1** ดู 1.5): ไม่มีกลไกจำกัดการโดนต่อเนื่อง | Probe: ฮีโร่ยืนเฉย ถูกล้อมด้วยศัตรู 3 ตัวชนิดเดียว ที่ Night Market, seed 1–5, 3,600 ticks ต่อรอบ (ตารางด้านล่าง) | สูง |
| B2 | (**แก้แล้ว IL-2**: legendary 12%, epic 30%, เทสต์คุมไม่เกิน 35%) **บอสดรอปของหายากแน่นอน 100%**: Furnace Baron → Baron Knuckledusters (legendary), Sludge Foreman → Foreman Wrench (epic) | `enemies.json` `chance: 1.0` ขัดกับ Master Prompt 9.3 | กลาง |
| B3 | (**แก้แล้ว IL-2**: ทางออกฝั่งตะวันออกเปิดเมื่อชนะศัตรูที่เฝ้าทาง) ทางออกไม่ล็อก ผู้เล่นเดินไป Refinery (เลเวล 8) ได้ตั้งแต่เริ่ม | `areas.json` `exits` ไม่มีเงื่อนไข | กลาง |
| B4 | ศัตรูหลายชนิดเป็นแฟนตาซี (zombie-goblin, skeleton, rat-man, boar-man) ขัดกับ "The Core ไม่ใช่เวทมนตร์" | `art/lpc/characters.json` | กลาง (ต้องตีความหรือเปลี่ยนภาพ) |
| B5 | Web export ~39.5 MB wasm ก่อนบีบอัด, ยังไม่มีผลวัด FPS บนเครื่องจริง | ROADMAP R2, R4 | กลาง |
| B6 | เปลี่ยนชื่อ id ของพื้นที่/ไอเท็ม/ฮีโร่ จะทำให้เซฟเก่าหาไม่เจอ (`from_dict` ตัดของที่ไม่รู้จักทิ้ง) | `PlayerProfile.from_dict` | สูงถ้าทำ → **ห้ามเปลี่ยน id; เปลี่ยนได้เฉพาะชื่อที่แสดง** |

ผล probe B1 (ช่วงเวลาติดต่อกันที่ยาวที่สุดที่ฮีโร่ควบคุมไม่ได้ คือ HITSTUN หรือ DOWN):

| ศัตรู ×3 | นานสุด | % เวลาที่ควบคุมไม่ได้ |
|---|---|---|
| Smogling | 28 ticks (0.47 s) | 39% |
| Rail Bruiser | 100 ticks (1.67 s) | 50% |
| Dock Thug | 109 ticks (1.82 s) | 61% |
| Refinery Enforcer | 112 ticks (1.87 s) | 64% |
| Smog Warden | 113 ticks (1.88 s) | 64% |
| Furnace Baron | 132 ticks (2.20 s) | 71% |
| Night Market Punk | **169 ticks (2.82 s)** | 65% |

นี่คือกรณีแย่ที่สุด (ผู้เล่นไม่กดอะไรเลย) ผู้เล่นจริงหลบหรือการ์ดได้ แต่ระหว่าง HITSTUN ทำอะไรไม่ได้
ช่วงเกือบ 3 วินาทีจึงเป็นเหตุผลพอที่จะแก้ใน IL-1

### 1.5 หลังแก้ B1 (IL-1, ส่วนที่ 1)

กลไก (ใน `CombatRules`, ใช้กับฮีโร่เท่านั้น ศัตรูยังโดนคอมโบต่อเนื่องได้ตามเดิม):
hitstun ที่โดนสะสมใน `stun_meter` และลดลง 1 ต่อ tick ที่ควบคุมได้ ถ้าการโดนครั้งถัดไปจะทำให้เกิน
`HERO_STUN_LIMIT` (40 ticks) จะล้มแทน ลุกแล้วได้ช่วงอมตะ 36 ticks (ตัวกะพริบ) ซึ่งจบทันทีเมื่อโจมตี
เพดานกรณีแย่สุด = 40 + 50 (ล้ม) = 90 ticks (1.5 s)

ผล probe เดียวกันหลังแก้: Smogling 28, Dock Thug 65, Rail Bruiser 65, Smog Warden 65,
Market Punk 68 (เดิม 169), Refinery Enforcer 68, Furnace Baron 74 ticks; เวลาที่ควบคุมไม่ได้ลดเหลือ 39–52%
เทสต์ `test_stun_lock.gd` (3 ตัว) และ `test_zone_sim::test_a_crowd_cannot_stun_lock_the_hero` คุมไว้

---

## 2. ข้อขัดแย้งระหว่างโค้ด เอกสาร และ Master Prompt

### 2.1 เอกสารเดิมไม่ตรงกับโค้ด (แก้ได้เลย ไม่กระทบเกม)

| เอกสาร | เขียนว่า | ความจริงในโค้ด |
|---|---|---|
| GAME_DESIGN.md บรรทัดแรก ๆ | "Implemented so far: one test street with a placeholder hero and a training dummy" | มี 6 พื้นที่ 3 ฮีโร่ 2 บอส |
| GAME_DESIGN.md "The crew" | "Persistent data is stored per hero" | เซฟเดียว ฮีโร่เดียว |
| README.md | "117 unit/scene tests" | 140 tests |
| ARCHITECTURE.md | Shared rules "[built] movement" | มีระบบต่อสู้ครบแล้ว |
| docs/ROADMAP.md M1 | ยังไม่ติ๊ก "CI green" และ "Pages" | มี live build ที่ `test888th-cpu.github.io/webgame` |

### 2.2 Master Prompt ขัดกับเกมเดิม (ต้องให้เจ้าของตัดสิน ดูส่วนที่ 3)

| เรื่อง | เกมเดิม | Master Prompt |
|---|---|---|
| ชื่อเกม | Ironbound Streets (working title) | The Iron Legacy |
| เมือง | Port Verrin เมืองท่า | Iron City เมืองอุตสาหกรรมในไทย (ภาพฉากปัจจุบันเป็นถนนกรุงเทพฯ อยู่แล้ว) |
| ภัยหลัก | The Murk: หมอกควันมีชีวิตจากอุโมงค์ (กึ่งเหนือธรรมชาติ) | The Core: โครงการอุตสาหกรรมลับ ไม่ใช่เวทมนตร์ |
| ตัวเอก | ทีม 6 คนมีชื่อ (3 ตัวทำแล้ว + Striker, Tinkerer, Medic) | ตัวเอกเลือก 6 อาชีพ: Boxer, Street Brawler, Footballer, Basketball, Police, Soldier |
| ลำดับพัฒนา | ROADMAP M3 ถัดไปคือระบบออนไลน์ | ทำ Single-player ให้เสร็จก่อน ออนไลน์ไว้ท้ายสุด |
| ช่องอุปกรณ์ | head, body, hands, **weapon** (สนับมือ), feet, charm | Head, Chest, Gloves, **Pants**, Shoes, Accessory |
| ค่าสถานะ | HP, power, defense, speed, energy | + Attack Speed, CRIT, ACC แยก Move Speed |
| Level | สูงสุด 20, พื้นที่เลเวล 1–8 | ระยะยาว 1–150, South Street 1–50 |
| บทแรก | Depot → Saltmarket → Canal Works (Sludge Foreman) → Rail Yards → Night Market → Refinery (Furnace Baron) | South Street 10 พื้นที่ย่อย จบที่ Gang Headquarters; เขตอุตสาหกรรมคือบทที่ 3 |

---

## 3. การตัดสินใจของเจ้าของ

**อนุมัติทุกข้อตามคำแนะนำเมื่อ 2026-10-26** คอลัมน์ "คำแนะนำ" จึงเป็นข้อตกลงแล้ว
งานแต่ละข้อลงใน Milestone ตามส่วนที่ 8 (D4 มีผลทันที: งานออนไลน์อยู่ IL-7)

| # | คำถาม | คำแนะนำ | ผลกระทบ |
|---|---|---|---|
| D1 | เปลี่ยนชื่อเกมเป็น "The Iron Legacy"? | ใช่ เปลี่ยนเฉพาะชื่อที่แสดง (`project.godot` `config/name`, Title, README) | ต่ำ แต่บน desktop โฟลเดอร์ `user://` ของ Godot ตั้งชื่อตาม `config/name` (ตอนนี้ไม่ได้ตั้ง `custom_user_dir_name`): **ต้องตั้งให้คงที่ก่อนเปลี่ยนชื่อ ไม่อย่างนั้นเซฟเดิมหาย** บนเว็บต้องทดสอบยืนยันใน smoke test **(ทำแล้ว IL-2: ทดสอบในเบราว์เซอร์จริงพบว่าเว็บก็ย้ายด้วย จึงให้ `SaveStore` คัดลอก save/settings จากโฟลเดอร์ชื่อเก่าตอนเปิดเกมครั้งแรก ไม่ลบของเดิม)** |
| D2 | ใช้โลก Iron City + The Core แทน Port Verrin + The Murk? | ใช่ โดยตีความ The Murk ใหม่ว่าเป็นควันพิษจากของเสียของ The Core (STORY_BIBLE §2) | ต่ำ: แก้ข้อความใน JSON และเอกสาร id ไม่เปลี่ยน |
| D3 | ผูกฮีโร่เดิมกับอาชีพ: Riku = Boxer, Oren = Street Brawler, Mika = Footballer แล้วเพิ่ม Basketball, Police, Soldier ภายหลัง? Sela/Juno/Ivy ยกเลิก? | ใช่ (ชุดท่าเดิมเข้ากับอาชีพเหล่านี้: Oren มี headbutt/clothesline, Mika มี whirlwind kick และ rush) | ต่ำ: เพิ่มฟิลด์ `class` ใน `heroes.json` เซฟไม่กระทบ |
| D4 | เลื่อนงานออนไลน์ (ROADMAP M3) ไปหลัง Single-player เสร็จ? | ใช่ ตาม Master Prompt แต่ยังคงกฎ "rules อยู่ใน `sim/`" เพื่อให้ server ใช้ได้ภายหลัง | ต้องแก้ ROADMAP และบรรทัด "Milestone 3" ใน CLAUDE.md |
| D5 | จัดพื้นที่เดิมเข้า South Street ตาม STORY_BIBLE §5 (เปลี่ยนชื่อที่แสดง, คง id)? | ใช่ | ต่ำ |
| D6 | ศัตรูหน้าตาแฟนตาซี (B4): ตีความใหม่ (หน้ากากแก๊ง, ชุดกันสารพิษ) หรือวาดใหม่? | ตีความใหม่ก่อน (STORY_BIBLE §6) แล้วค่อยเปลี่ยนภาพทีละตัวใน IL-4 | ต่ำถ้าตีความ, กลางถ้าวาดใหม่ |
| D7 | ช่องอุปกรณ์: คงของเดิม 6 ช่อง หรือเปลี่ยน weapon → pants? | **คงของเดิม** ใช้ชื่อแสดงผล Chest/Gloves/Shoes/Accessory ได้ ช่อง weapon (สนับมือ) เข้ากับ "ต่อยด้วยหมัด" อยู่แล้ว | ถ้าเปลี่ยน: ต้องเซฟ v4 + migration + เทสต์ |
| D8 | ค่าสถานะใหม่: เพิ่ม CRIT และ Attack Speed, **ไม่เพิ่ม ACC**? | ใช่ เกมใช้ hitbox ตามตำแหน่งอยู่แล้ว ACC แบบสุ่มพลาดจะทำให้การโดนที่ "เห็นว่าโดน" กลับไม่โดน ซึ่งขัดกับข้อ "ไม่โกง" | CRIT ต้องใช้ RNG ที่ seed จาก ZoneSim เท่านั้น |
| D9 | เพดานเลเวล: คง 20 ไว้จนจบ IL-3? | ใช่ ขยายเมื่อมีพื้นที่และของรองรับ | ไม่มี |
| D10 | สไตล์ภาพตัวละครและฉากสุดท้ายยังไม่เลือก | **ทำเกมให้ครบก่อน (เจ้าของตัดสินใจ 2026-10-27)** เนื้อหาใหม่ใช้ภาพชั่วคราว (LPC, ชิ้นฉากเดิม, รูปทรงวาดด้วยโค้ด) แล้วค่อยทำภาพทั้งเกมในรอบเดียวตอนท้าย | ต่ำ: ภาพแยกจากข้อมูลและกติกาอยู่แล้ว เปลี่ยนภาพไม่ต้องแก้ gameplay |

---

## 4. Game Master Blueprint (ระบบ ผูกกับของที่มีอยู่)

หลัก: **ต่อยอดระบบเดิม ไม่สร้างซ้ำ** ทุกแถวบอกว่าจะต่อจากไฟล์ไหน

### 4.1 Core loop

รับภารกิจ (`QuestRules`) → เข้าพื้นที่ (`ZoneSim`) → ต่อสู้ (`CombatRules`, `EnemyBrain`) →
XP/เงิน/ของ (`LootRules`, `LevelRules`) → เปรียบเทียบและใส่ของ (`ItemCard`, `PlayerProfile.equip`) →
ตีบวก (ใหม่, IL-3) → ฟาร์มซ้ำ (encounter รีเซ็ตเมื่อกลับเข้า) → บอส → ปลดล็อกพื้นที่ถัดไป (ใหม่, IL-2)

ส่วนที่ขาดในวงนี้ตอนนี้: การปลดล็อกพื้นที่ (B3), วัตถุดิบ, ตีบวก, เนื้อเรื่อง

### 4.2 ระบบต่อสู้ (ใช้ร่วมทุกอาชีพ)

| การกระทำ | สถานะ | แผน |
|---|---|---|
| เดิน, หลบ, การ์ด, เบา, หนัก, คอมโบ, โดนและฟื้น, ล้มและลุก | มีแล้ว | ปรับใน IL-1 เท่านั้น ไม่เขียนใหม่ |
| หยิบ/ใช้/ปล่อยอาวุธ | มีแล้ว | เพิ่ม **ขว้าง** (กด E ค้าง หรือ หนัก+การ์ด) เป็นท่าใน `moves.json` |
| สกิลเฉพาะอาชีพ | มีแล้ว (4 ช่อง) | อาชีพใหม่ใช้ระบบเดียวกัน แค่เพิ่มข้อมูลใน `heroes.json`/`skills.json`/`moves.json` |
| โต้กลับ | ไม่มี | **Perfect guard**: การ์ดภายใน ~6 ticks ก่อนโดน = ไม่เสียพลังงาน และเปิดหน้าต่างสวนกลับสั้น ๆ ทำใน `CombatRules._apply_hit` |
| จับทุ่ม | ไม่มี | IL-4 หรือหลังจากนั้น เป็นท่าแบบ `grab: true` ใช้ได้กับศัตรูที่ไม่ใช่บอส (Street Brawler, Police ได้ประโยชน์มากกว่า) |
| กระโดด | ไม่มี | **ไม่ทำในช่วงแรก**: ต้องเพิ่มแกน z ให้ simulation, hitbox และภาพทั้งหมด ความเสี่ยงสูงเทียบกับประโยชน์ Basketball ใช้ท่า "กระโดดโจมตี" ที่เป็นท่าปกติแทนได้ |
| ป้องกัน stun-lock | ไม่มี (B1) | **Hit budget**: นับ hitstun สะสมในหน้าต่างเวลา ถ้าเกิน (เช่น 90 ticks ใน 2 วินาที) การโดนครั้งถัดไปทำให้ล้มพร้อมลุกแบบอมตะ หรือให้ "burst" หลุดออกโดยใช้พลังงาน ค่าทั้งหมดอยู่ใน `CombatRules` และมีเทสต์จาก probe |

### 4.3 อาชีพ (เสนอ ผูกกับ D3)

ทุกอาชีพผ่านเนื้อเรื่องได้ ไม่มีบอสที่บังคับอาชีพ ตัวเลขคุมด้วย `test_balance.gd` ที่มีอยู่ (ขยายให้ครอบคลุม 6 อาชีพ)

| อาชีพ | ฮีโร่ | จุดเด่น | ข้อแลก |
|---|---|---|---|
| Boxer | Riku (มีแล้ว) | คอมโบหมัดเร็ว stun นาน | ระยะสั้น |
| Street Brawler | Oren (มีแล้ว) | หมัดหนัก ทำให้เสียหลัก ควบคุมฝูง ทนสุด | ช้า |
| Footballer | Mika (มีแล้ว) | เคลื่อนที่เร็ว เตะกวาด พุ่งชน | HP ต่ำสุด, defense 0 |
| Basketball Player | ใหม่ | ท่าจู่โจมจากบนลงล่าง (ไม่ต้องมีระบบกระโดด) ตีพื้นที่ | ท่าเริ่มช้า |
| Police Officer | ใหม่ | perfect guard กว้างกว่า สวนกลับแรง จับล็อก | ดาเมจคอมโบปกติต่ำ |
| Soldier | ใหม่ | ท่าบุกหนัก ขัดจังหวะ (super armor สั้น ๆ ระหว่างท่า) ทนทาน | ช้า สกิล cooldown นาน |

### 4.4 ค่าสถานะ

| Master Prompt | ในโค้ด | แผน |
|---|---|---|
| HP | `max_hp` | คงไว้ |
| ATK | `power` (ตัวคูณ) | คงไว้ แสดงผลเป็น ATK |
| DEF | `defense` | คงไว้ |
| Move Speed | `speed` | คงไว้ แสดงผลเป็น Move Speed |
| STA | energy (100, ใช้กับหลบ/การ์ด/หนัก/สกิล) | คงไว้ แสดงผลเป็น STA หรือ Energy |
| Attack Speed | **ทำแล้ว IL-3** | ลดเฉพาะ recovery (70–130%) ไม่แตะ startup |
| CRIT | **ทำแล้ว IL-3** | ฐาน 5% (Riku 8%), ×1.5, เพดาน 50%, ใช้ `ZoneSim.rng` เท่านั้น |
| ACC | ไม่มี | ไม่ทำ (D8) |

### 4.5 อุปกรณ์ Loot และตีบวก

- คง 6 ช่องเดิม (D7) และ 5 rarity เดิม
- ไอเท็มมีอยู่แล้ว: ชื่อ, ช่อง, rarity, level, stats, ราคา, คำอธิบาย ที่ขาดคือ "แหล่งดรอป" ในข้อมูลไอเท็ม
  → **ไม่เก็บซ้ำ** ให้ `ContentDB` คำนวณจาก loot table ของศัตรูและร้านค้า แล้วแสดงใน Item card
- แก้ B2: บอสดรอปของประจำตัวแบบโอกาส (เช่น legendary 8–15%) และรับประกัน **วัตถุดิบบอส** แทน
  ต้องมี "ของรางวัลภารกิจ" ครั้งแรกที่ชนะบอส เพื่อให้ผู้เล่นทุกคนได้ของที่จำเป็นต่อเนื้อเรื่อง
- วัตถุดิบ: ไอเท็มชนิดใหม่ `"type": "material"` ใน `items.json` เก็บใน inventory เดิม (ไม่ต้องเปลี่ยนเซฟ)
- ตีบวก +0 ถึง +10 (IL-3, **ทำแล้ว**: เซฟ v5, ล้มเหลวไม่ลดระดับเลย ไม่ใช่แค่ถึง +5, pity +5%/ครั้ง): เก็บเป็น `enhance: {slot: level}` ใน `PlayerProfile` (ค่าเริ่ม 0)
  - ใช้เงิน + วัตถุดิบ, แสดงอัตราสำเร็จก่อนกด, ล้มเหลวเสียแค่วัตถุดิบ/เงิน ไม่ทำลายไอเท็ม ไม่ลดระดับจนถึง +5
  - กฎอยู่ใน `sim/EnhanceRules.gd` (pure function + RNG ที่ส่งเข้าไป) ทำงานแบบ transaction: ตรวจ → หัก → สุ่ม → บันทึก → เซฟ ในการเรียกครั้งเดียว ปุ่มถูกปิดจนกว่าเซฟเสร็จ (กันกดรัว)
  - ออนไลน์ภายหลัง: กฎเดียวกันย้ายไปรันที่ server ได้ทันที

### 4.6 ภารกิจและเนื้อเรื่อง

- ขยาย `quests.json` ไม่สร้างระบบใหม่: เพิ่ม objective `talk` (คุยกับ NPC), `collect` (เก็บไอเท็มหลักฐาน), `reach` (ไปถึงพื้นที่)
  และฟิลด์ `chapter`, `main: true/false`
- เพิ่ม `requires` ให้ทางออกใน `areas.json` (เช่น `"requires_quest": "warden"`) แก้ B3; `ContentDB` ตรวจ reference
- บทสนทนา: ใช้ dialog box ที่มีอยู่ เพิ่มข้อมูล `dialogue` สั้น ๆ ต่อภารกิจ (ก่อนรับ/ระหว่างทำ/ส่ง) ไม่เกิน 3–4 บรรทัดต่อครั้ง
- หลักฐาน (evidence) เป็นไอเท็มประเภท `key` ที่ขายและทิ้งไม่ได้ เปิดอ่านได้จาก inventory **(ทำแล้ว IL-2: บทสนทนา 3 จังหวะต่อภารกิจ, หลักฐาน 3 ชิ้น, การ์ดจบบทที่ 1; objective แบบ talk/collect/reach ยังไม่ทำ เพราะเนื้อหาบทที่ 1 ยังไม่ต้องใช้)**

### 4.7 ศัตรูและบอส

ทะเบียนเต็มอยู่ใน STORY_BIBLE §6 (ชื่อและบทบาท) ตัวเลขอยู่ใน `enemies.json`
หลักการ: ใช้ฐาน animation ร่วม (LPC) ต่างกันที่ท่า สี ชุด พฤติกรรม ซึ่งระบบเดิมรองรับแล้ว (`moveset`, `ai`, `scale`, `color`)

บอสต้องมีอย่างน้อย: ท่าเตือน (telegraph มีแล้ว), ช่วงพักหลังท่าหนัก (recovery ใน `moves.json`), phase ที่ **เพิ่มท่าใหม่**
ไม่ใช่แค่ตัวเลข (`phases[].moveset` รองรับแล้ว Sludge Foreman ใช้อยู่ Furnace Baron ยังไม่ใช้)

### 4.8 UI

HUD ปัจจุบันมี: การ์ดฮีโร่ + เลเวล, HP, energy, XP, เงิน, ภารกิจที่ติดตาม, hotbar, ปุ่มสัมผัส ตรงตาม Master Prompt 14 แล้ว
ที่ต้องเพิ่ม: แท็บวัตถุดิบ/ของสำคัญใน Bag, หน้าต่างตีบวก, ชื่อบทใน Quest log

### 4.9 Single-player first, online later

สิ่งที่ทำไว้แล้วและต้องรักษา: กฎทั้งหมดอยู่ใน `sim/`, RNG มี seed, `PlayerProfile` แยกจากสถานะการต่อสู้,
รางวัลถูกตัดสินโดย `ZoneSim` ไม่ใช่ UI. ห้ามอ้างความสามารถรองรับผู้เล่นพร้อมกันจนกว่าจะทดสอบโหลดจริง (ROADMAP M8)

---

## 5. Enemy and Boss Registry (สรุปจาก `enemies.json`)

| id (ห้ามเปลี่ยน) | ชื่อปัจจุบัน | บทบาท | HP | พบที่ | กลุ่มตาม Master Prompt (เสนอ) |
|---|---|---|---|---|---|
| `training_dummy` | Training Dummy | หุ่นซ้อม | 120 | Depot Yard | - |
| `smogling` | Smogling | Normal | 30 | Saltmarket, Canal Works, Rail Yards | Mutants |
| `tar_hound` | Tar Rat | Fast | 22 | Saltmarket, Canal Works, Rail Yards | Gangsters (แก๊งหน้ากากหนู) |
| `pipe_brute` | Pipe Brute | Heavy | 70 | Saltmarket, Canal Works | Gangsters |
| `smog_warden` | Smog Warden | Elite | 140 | Saltmarket, Canal Works, Night Market | Industrial Security |
| `sludge_foreman` | The Sludge Foreman | Boss (2 phase) | 420 | Canal Works | Gangsters (หัวหน้าแก๊ง) |
| `dock_thug` | Dock Thug | Normal | 45 | Rail Yards, Night Market, Refinery | Gangsters |
| `rail_bruiser` | Rail Bruiser | Heavy | 95 | Rail Yards, Night Market, Refinery | Gangsters |
| `market_punk` | Night Market Punk | Fast | 55 | Night Market, Refinery | Gangsters |
| `refinery_enforcer` | Refinery Enforcer | Elite | 160 | Refinery | Industrial Security |
| `furnace_baron` | The Furnace Baron | Boss (2 phase) | 520 | Refinery | Gangsters (หัวหน้าแก๊ง South Street) |

ยังไม่มี: Ranged, Mini-boss, Machines, Hybrid Humanoids ที่มีที่มาชัด

## 6. Item Registry (สรุปจาก `items.json`, 21 รายการ)

| ช่อง | Common | Uncommon | Rare | Epic | Legendary |
|---|---|---|---|---|---|
| head | Dock Beanie | Hard Hat | Iron Helm | | |
| body | Padded Vest | Work Jacket | Riveted Jacket | | |
| hands | Fingerless Gloves | | Iron Wraps | | |
| weapon (สนับมือ) | Taped Knuckles | Rebar Pipe | Brass Knuckles | Foreman Wrench | Baron Knuckledusters |
| feet | Canvas Sneakers | Steel-toe Boots | Street Runners | | |
| charm | | Lucky Coin | Brass Whistle | Jade Charm | |
| ของใช้ | Steamed Bun (ฟื้น HP) | Ginger Tea (ฟื้น energy) | | | |

ยังไม่มี: วัตถุดิบ, ของสำคัญ (หลักฐาน), ของประจำบอสแบบไม่รับประกัน, ของ epic/legendary ช่อง head/body/hands/feet

อาวุธจากพื้น (`weapons.json`, ไม่ใช่อุปกรณ์): knife, bottle, plank, pipe, machete, chair, frying pan, wrench, baseball bat

---

## 7. ความเสี่ยงของการแก้โค้ด

| ความเสี่ยง | ป้องกันโดย |
|---|---|
| เปลี่ยน id แล้วเซฟเก่าหาย | ห้ามเปลี่ยน id; เปลี่ยนเฉพาะ `name`; เทสต์โหลดเซฟ v1–v3 |
| เปลี่ยนชื่อโปรเจกต์แล้ว `user://` ย้าย (D1) | ตั้ง `custom_user_dir_name` ก่อนเปลี่ยนชื่อ; ทดสอบใน smoke test ว่า Continue ยังเห็นเซฟ |
| ปรับ stun-lock แล้วเกมง่ายเกิน หรือ balance test พัง | ค่าเป็นค่าคงที่ใน `CombatRules`, เทสต์ใหม่ใช้ probe เดิมเป็นเกณฑ์, รัน `test_balance` |
| เพิ่ม CRIT แล้วเสีย determinism | ใช้ `ZoneSim.rng` เท่านั้น; เทสต์ replay ที่มีอยู่จะจับได้ |
| เพิ่มตีบวกแล้วข้อมูลเสีย/ปั๊มของ | เซฟ v4 + migration + เทสต์ transaction, กันกดซ้ำ |
| ขยายเนื้อหาจน web build ใหญ่ | วัดขนาด export ทุก PR ที่เพิ่ม asset (CI อัปโหลด manifest พร้อมขนาด) |

---

## 8. Roadmap เรียงตามความเสี่ยงและความสำคัญ

| IL | งาน | ตรงกับ ROADMAP เดิม | ความสำคัญ |
|---|---|---|---|
| IL-0 | Audit + Blueprint + Story Bible (PR นี้) | - | เสร็จเมื่อเจ้าของตอบส่วนที่ 3 |
| IL-1 | Stable Combat: แก้ stun-lock (B1), perfect guard/สวนกลับ, ขว้างอาวุธ, ตรวจ recovery ท่าศัตรูและบอส, phase บอสมีท่าใหม่ | M2 (ต่อ) | **สูงสุด** ความสนุกหลักขึ้นกับข้อนี้ |
| IL-2 | (ทำแล้ว: เปลี่ยนชื่อ+ย้ายเซฟ, ล็อกทางออก, ดรอปบอส, อาชีพ, บทสนทนา/หลักฐาน/จบบท 1, tutorial + เซฟ v4) Complete Early Game: tutorial ใน Depot Yard, ล็อกทางออกตามภารกิจ (B3), quest objective ใหม่, บทสนทนา Prologue + บทที่ 1, เปลี่ยนชื่อแสดงผลตาม D1/D2/D5, แก้ B2 | M4 บางส่วน | สูง |
| IL-3 | Progression: วัตถุดิบ, แหล่งดรอปใน Item card, CRIT/Attack Speed, ตีบวก (เซฟ v4), สมดุลอาชีพ | M4 | สูง |
| IL-4 | (ทำแล้ว: Rusted Corner, Parking Lot, Fight Club, Rat Nest, Gang HQ, ศัตรูระยะไกล, Mini-boss, GO >>, อาชีพใหม่ 3 อาชีพ, ฉากวาดเองครบ 22 ชิ้น, ภาพศัตรูวาดใหม่ 4 ตัวตาม D6: Tar Rat, Smogling, Smog Warden, Sludge Foreman) Complete South Street: พื้นที่ย่อยที่เหลือ, ศัตรู Ranged/Mini-boss, เพิ่มอาชีพ Basketball/Police/Soldier ทีละตัว, ภาพศัตรูใหม่ (D6) | M5 บางส่วน | กลาง |
| IL-5 | (ทำแล้ว: บทที่ 2 Port District 4 พื้นที่ + บอส Chen กับเครน) Main Story: Port, Industrial, Black Network, Core Facility, บอสสุดท้าย 3 phase, Epilogue | M5 | กลาง |
| IL-4+ | (ทำแล้ว) ฟื้นที่จุดล้ม/หน้าประตูบอส, ด่านที่ชนะจำไว้จนพักที่ Depot (ฟาร์มได้), วินมอเตอร์ไซค์ไปพื้นที่ที่เคยไป, เซฟ v6 | - | สูง (ลดการเล่นซ้ำที่น่าเบื่อ) |
| IL-6 | Endgame and Polish: บอสฟาร์ม, ของระดับสูง, ภารกิจเสริม, วัด FPS/ขนาด web (B5), เพลง | M2 ข้อ 8–9, M7 | กลาง |
| IL-7 | Online Preparation | M3, M6, M8 | หลัง single-player เสถียร (D4) |

ลำดับ PR ใน IL-1 (PR ละเรื่อง):
1. ~~กลไกป้องกัน stun-lock~~ (เสร็จ)
2. ~~Perfect guard + สวนกลับ~~ (เสร็จ: การ์ดภายใน 8 ticks ก่อนโดน = parry, ศัตรูเซ 30 ticks, ตีแรกหลังจากนั้น ×1.5)
3. ~~ขว้างอาวุธ~~ (เสร็จ: E ตอนไม่มีของใต้เท้า = ขว้าง, โดนตัวแรกแล้วตก/แตก, บอสแค่เซไม่ล้ม)
4. ~~บอส: phase ที่มีท่าใหม่~~ (เสร็จ: Furnace Baron phase 2 พุ่งชน 110 px มีเตือน 24 ticks แล้วเปิดช่อง 40 ticks; AI เริ่มท่าพุ่งจากระยะไกลได้)
5. ~~ตรวจท่าศัตรูทุกตัวด้วยเทสต์~~ (เสร็จ: `test_fairness.gd` บังคับเตือน ≥ 16 ticks สำหรับท่าเปิดที่ล้ม/ทำลายการ์ด, ช่องสวน ≥ 20 ticks, ทุก phase บอสต้องมีท่าใหม่)

**IL-1 เสร็จครบ** ต่อไปคือ IL-2

---

## 9.5 สมดุลอาชีพ (IL-3, วัดด้วยการจำลอง)

จำลองการสู้กับ Smog Warden ด้วยผู้เล่นสคริปต์เดียวกันทุกฮีโร่ (กด light รัว + ใช้สกิลทันทีที่พร้อม, 20 seed):

| | Mika | Oren | Riku |
|---|---|---|---|
| เวลาล้ม Elite Lv1 (ก่อน poise) | 11.9 s | 7.5 s | 5.8 s |
| เวลาล้ม Elite Lv5 (หลัง poise) | 4.6 s | 4.9 s | 3.8 s |
| ดาเมจรวมต่อการต่อสู้ | ~162 | ~144 | ~141 |

ข้อสรุป:
- ดาเมจรวมใกล้กัน ความต่างมาจาก**สกิลที่ทำให้ล้ม** (ศัตรูนอน 50 ticks ตีไม่เข้า): Mika มีสองท่าตั้งแต่เลเวล 1 จึงช้าที่ Lv1 แต่ปลอดภัยกว่า เป็นการแลกที่ตั้งใจ ไม่ปรับตัวเลขจนกว่าจะมี playtest จริง
- พบปัญหาจริง: กดรัวแล้ว Elite ขยับไม่ได้ 60–77% → เพิ่มระบบ poise (CHANGELOG)
- ผู้เล่นสคริปต์ไม่ใช่ผู้เล่นจริง: ใช้หาความผิดปกติ ไม่ใช่ตั้งค่าสุดท้าย

### 9.6 IL-4: ความยากบอส (ผู้เล่นสคริปต์ ไม่มีอุปกรณ์/ไม่กินยา/ไม่ parry, 10 seed)

| บอส | Mika | Oren | Riku |
|---|---|---|---|
| Sludge Foreman (Lv3) | ชนะ 5/10 | 3/10 | 8/10 |
| Pit Champion (Lv8) | 0/10 | 0/10 | 0/10 |
| Furnace Baron (Lv8) | 0/10 | 0/10 | 0/10 |

ผู้เล่นสคริปต์นี้อ่อนกว่าผู้เล่นจริงมาก (ไม่ใช้อุปกรณ์เลเวล 5–8, ไม่กินบัน, ไม่ parry) ตัวเลขนี้จึงใช้เทียบบอสกันเอง:
Champion อยู่ระดับเดียวกับ Baron (ลด HP จาก 380 เป็น 340 ให้ง่ายกว่า Baron เล็กน้อย) **ต้องมี playtest จริงก่อนปรับเพิ่ม**

Baron ย้ายไป Gang HQ (Lv9) ผลยังเป็น 0/10 ทุกอาชีพเหมือนเดิม และอยู่รอดได้ใกล้เคียงกัน (18–25 วินาที เทียบกับ 18–24 วินาทีที่ Refinery Lv8)
เลเวลที่สูงขึ้น 1 ถูกชดเชยด้วย XP จาก 3 ภารกิจและ 2 พื้นที่ที่เพิ่มก่อนถึงตัวเขา

**จังหวะสกิล (หลังปรับ):** สกิลฮีโร่คูลดาวน์ 2.5–4.25 วินาที ส่วนอัลติเมต 11–12.5 วินาที
ท่าหนักของศัตรูต้องรอ `heavy_cooldown` นานกว่าสกิลฮีโร่ทุกท่า (ยกเว้นอัลติเมต): ลูกน้องรอ 4.5 วินาที บอสรอ 5–5.5 วินาที
บอสจึงออกท่าเบาถี่ขึ้น 20% ส่วน Foreman ตีแรงขึ้น

| บอส (ผู้เล่นสคริปต์, 10 seed ต่ออาชีพ) | ก่อน | หลัง |
|---|---|---|
| Sludge Foreman (Lv3) | 3–8/10 | 7–10/10 |
| Pit Champion (Lv8) | 0–1/10 | 1–5/10 |
| Furnace Baron (Lv9) | 0/10 | 0/10 |

**บทที่ 2:** Harbourmaster Chen (Lv13) วัดโดยไม่มีเครน (ผู้เล่นสคริปต์ไม่ได้เข้าฉากสู้จริง) อยู่รอดได้ 12–18 วินาที ใกล้ Baron (16–24 วินาที)
เครนเพิ่มความยาก แต่หลบได้ทุกครั้งถ้าเดินออกจากเงา ศัตรู Lv10–13 ตีแรงขึ้น 8%/เลเวล ผู้เล่นจริงต้องใช้ของจากร้าน Noi (ระดับ 10–11)

## 10. มาตรฐานเกมขายจริง (Quality bar)

เกณฑ์นี้ใช้ตรวจทุก PR ที่แตะ gameplay หรือ UI นอกเหนือจาก CI

### 10.1 ความรู้สึกการต่อสู้ (game feel)

| เกณฑ์ | ค่าเป้าหมาย | สถานะ |
|---|---|---|
| ปุ่มตอบสนอง | ท่าเริ่มใน tick ถัดไป หรือถูก buffer (12 ticks) ไม่มีการกดหาย | มีแล้ว |
| ถูกขังโดยไม่มีทางออก | ≤ 1.5 s (90 ticks) ทุกสถานการณ์ | มีแล้ว (IL-1) |
| ท่าหนักของศัตรู | มีสัญญาณเตือน ≥ 20 ticks และ recovery ≥ 20 ticks | มีเตือนแล้ว จะเพิ่มเทสต์ |
| hit-stop, ประกาย, เสียง, สั่นกล้อง ทุกการโดน | ทุกครั้ง | มีแล้ว |
| 60 FPS บนเครื่องอ้างอิงในเบราว์เซอร์ | 1 ฮีโร่ + 12 ศัตรู + เอฟเฟกต์ | ยังไม่วัด (IL-6) |

### 10.2 UI/UX

- **อ่านออกใน 1 วินาที**: HUD แสดงแค่ HP, STA, เลเวล, เงิน, ภารกิจที่ติดตาม, hotbar ข้อมูลอื่นอยู่ในเมนู
- **ไม่ต้องเปิดเมนูเพื่อเล่นต่อ**: ภารกิจบอกเป้าหมายบน HUD, ลูกศรบอกทางเมื่อพื้นที่เคลียร์แล้ว (IL-2)
- **ทุกการกระทำมี feedback**: กดแล้วทำไม่ได้ต้องมีเสียงและภาพบอก (มีแล้วสำหรับพลังงานไม่พอ)
- **ทุก input ใช้ได้ทุกหน้าจอ**: คีย์บอร์ด เกมแพด เมาส์ ทัช (`test_ui` ตรวจ focus แล้ว)
- **เปรียบเทียบของก่อนใส่**: ลูกศรขึ้น/ลงสีเขียว/แดงในการ์ดไอเท็ม (มีแล้ว) และใน Bag grid (IL-3)
- **ไม่เสียของโดยไม่ตั้งใจ**: ทิ้ง/ขาย/ตีบวกที่เสี่ยงต้องยืนยัน, กันกดซ้ำ
- **อ่านง่ายบนจอเล็ก**: ฐาน 640×360 ขยายแบบ integer, ข้อความไม่ต่ำกว่าขนาดใน `UiTheme`, ปุ่มทัชไม่บังพื้นที่ต่อสู้
- **ไทยเป็นภาษาหลักได้**: ฟอนต์ Noto Sans Thai มีแล้ว; ข้อความในเกมจะย้ายไปใช้ระบบแปลภาษาของ Godot (IL-2) เพื่อรองรับไทย/อังกฤษ
- **โหลดเร็ว**: หน้าแรก ≤ 12 MB บีบอัด (ROADMAP M2 ข้อ 9), ไม่มีหน้าจอค้างระหว่างเปลี่ยนพื้นที่

### 10.3 สถาปัตยกรรม (สรุปข้อตกลง)

```
client/data/*.json  ──►  ContentDB (ตรวจทุกไฟล์และ reference ตอนโหลด)
                              │
client/sim/  (กฎล้วน, deterministic, RNG มี seed)
  CombatRules ◄── ZoneSim ──► EnemyBrain, LootRules, LevelRules, QuestRules, (EnhanceRules)
                    │ ZoneEvent
                    ▼
client/scenes/ (แสดงผลและรับ input เท่านั้น)  ──►  PlayerProfile (เซฟมี version) ──► SaveStore
                                                       └─► ภายหลัง: backend เป็นผู้เขียนข้อมูลถาวร (IL-7)
```

- เพิ่มเนื้อหา (ศัตรู ไอเท็ม ภารกิจ ด่าน อาชีพ) = แก้ JSON + ภาพ ไม่ต้องแก้โค้ด
- กฎใหม่ทุกข้ออยู่ใน `sim/` พร้อมเทสต์ ฉากห้ามคำนวณกฎเอง
- ข้อมูลเซฟเปลี่ยน = เพิ่ม version + migration + เทสต์โหลดเซฟทุกเวอร์ชันเก่า
- ทุกอย่างที่ server ต้องตรวจในอนาคต (ดาเมจ, ของ, เงิน, XP, ตีบวก) ถูกตัดสินใน `sim/` เท่านั้น

---

## 9. แผนทดสอบ

### 9.1 ก่อนแก้ทุกครั้ง (baseline)

1. `gdformat --check . && gdlint .` ใน `client/`
2. `godot --headless --path client --import`
3. `godot --headless --path client --script res://tests/TestRunner.gd` → บันทึกจำนวนที่ผ่าน (ตอนนี้ 140)
4. ถ้าแตะ backend: `npm run typecheck && npm test`

### 9.2 หลังแก้

| งาน | เทสต์ที่ต้องเพิ่ม |
|---|---|
| Stun-lock | ย้าย probe เป็น `test_combat` หรือ `test_zone_sim`: ฮีโร่ยืนเฉยต่อศัตรู 3 ตัว ช่วงควบคุมไม่ได้ต้องไม่เกินเพดานที่ตั้ง (เช่น ≤ 90 ticks) ทุก seed |
| Perfect guard / ขว้างอาวุธ | หน้าต่าง tick ที่ถูกต้อง, ผลเมื่อพลาดหน้าต่าง, อาวุธหายจากมือและสร้าง projectile/ดาเมจ |
| ล็อกทางออก | ออกไม่ได้ก่อนภารกิจ, ออกได้หลังส่ง, เซฟเก่าที่อยู่ในพื้นที่ "ล็อก" ไม่ติด |
| Quest objective ใหม่ | แต่ละประเภทเริ่ม/คืบหน้า/จบได้, `ContentDB` ปฏิเสธ reference ผิด |
| เซฟ v4 | โหลดเซฟ v1, v2, v3 ได้ ค่าใหม่เป็นค่าเริ่มต้นปลอดภัย, ค่าแปลกถูก clamp |
| ตีบวก | อัตราตรงกับข้อมูล, ล้มเหลวไม่ทำลายไอเท็ม, เงิน/วัตถุดิบไม่พอ = ไม่เปลี่ยนอะไร, เรียกซ้ำเร็ว ๆ ไม่หักซ้ำ |
| CRIT | replay ด้วย seed เดิมได้ผลเดิม |
| บอส | ทุก phase เข้าได้, มีหน้าต่างสวนกลับหลังท่าหนัก (recovery ≥ ค่าที่ตั้ง) |
| อาชีพใหม่ | `test_balance` ครอบคลุมทุกอาชีพ, `test_heroes` สร้างตัวละครได้, smoke test เลือกได้ |
| ทุกงานที่เปลี่ยนภาพ/เสียง | `tools/assets/validate.py` (license และความสดใหม่) |

### 9.3 ทุก PR (CI)

Repository policy, lint, Godot tests, web export + smoke test บน Chromium, backend, security scan
ต้องเขียวก่อน merge ห้ามอ้างว่าผ่านถ้าไม่ได้เห็นผล
