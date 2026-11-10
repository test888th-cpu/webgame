# แผนพัฒนาระบบ 5 อาชีพและ Player Skill — The Iron Legacy

**สถานะ:** อนุมัติแล้ว (เจ้าของ 2026-11-10: J1–J8 ตามคำแนะนำทุกข้อ บันทึกเป็น D15 ใน
`docs/BLUEPRINT.md`) **ทำแล้ว: JS-0 ถึง JS-11** คือชุดสกิลครบ 5 อาชีพ (30 Active, 10 Passive,
5 Ultimate), Grab/Throw, ท่าตั้งรับ, Ultimate gauge, หน้าจอ และ auto battle
**ยังเหลือ:** การอนุมัติค่าสมดุลโดยเจ้าของ (ส่วน "ผลวัดชุดสกิลครบ"), ภาพไอคอนและท่าทางเฉพาะสกิล,
และ PvP (หลัง IL-7) เอกสารนี้เทียบ "Blueprint ระบบ 5 อาชีพและ Player Skill System" ของเจ้าของกับ repo
แล้ววางแผนลงมือทำ คอลัมน์ "คำแนะนำ" ในส่วนที่ 3 เป็นข้อตกลงแล้ว

**สิ่งที่ต่างจากข้อตกลงเดิมและรอเจ้าของยืนยัน:** ตารางปลดล็อก (J4) เปลี่ยนจาก 1/10/20/25/35/40
(Passive 15/30) เป็น **1/2/3/5/15/30 (Passive 10/25)** Ultimate ยังอยู่ที่ 50 เหตุผลและตัวเลขอยู่ในส่วน
"ผลวัดชุดสกิลครบ"

## 1. Baseline ที่เจ้าของเสนอ (ย่อ)

- 5 อาชีพ: Boxer (Burst เป้าเดี่ยว), Brawler (กดดัน/AoE), Grappler (จับทุ่ม/คุมตำแหน่ง),
  Counter Fighter (ป้องกัน/สวนกลับ), Street Fighter (ความเร็ว/Combo)
- ต่ออาชีพ: Basic Attack 1 ชุด, Active 6, Passive 2, Ultimate 1 (รวม 30 + 10 + 5 = 45 รายการ)
- ต่อยด้วยหมัดเท่านั้น ไม่มีท่าเตะในระยะนี้ หยิบอาวุธจากพื้นใช้ชั่วคราวได้ทุกอาชีพ
- Grab/Throw เป็นระบบกลาง Grappler เก่งที่สุด บอสมี Grab Resistance
- Ultimate แรงกว่า Active ที่แรงที่สุดราว 2–3 เท่า มีช่วงเตือน มีวิธีรับมือ ใช้ Gauge
- PvE กับ PvP ใช้ Skill ID เดียวกัน แต่แยก Balance Profile
- ปลดล็อกตามเลเวล 1–50 (Ultimate ที่ 50) เลเวล 50–70 เป็นการพัฒนาช่วง Endgame
- ข้อมูลสกิลเป็น Data-driven ห้ามใช้สกิลบอสเป็นสกิลผู้เล่นหรือกลับกัน

## 2. ผลตรวจ repo: มีอะไรแล้ว ขาดอะไร

| เรื่องใน Blueprint | ของที่มีอยู่ | ช่องว่าง |
|---|---|---|
| อาชีพ | ฮีโร่ 6 ตัวใน `heroes.json` แต่ละตัวคืออาชีพ: Mika Footballer, Oren Street Brawler, Riku Boxer, Kan Basketball Player, Dao Police Officer, Pong Soldier (BLUEPRINT D3, STORY_BIBLE §ตัวละคร, `test_classes`) | ไม่มีแนวคิด "job" แยกจากตัวละคร มี 6 ไม่ใช่ 5 และชื่ออาชีพไม่ตรงกัน (ข้อ J1) |
| Basic Attack ต่ออาชีพ | ชุดเดียวใช้ร่วมทุกฮีโร่ (`moves.json` `starters` + `chains`) `Fighter.moveset` รองรับชุดเฉพาะตัวอยู่แล้ว (ศัตรูและอาวุธใช้) | เพิ่มข้อมูล combo ต่ออาชีพ ไม่ต้องแก้กฎ |
| Active Skill | 24 สกิล (ฮีโร่ละ 4) ใน `skills.json` สกิล = ท่าเดียวใน `moves.json` + cooldown + energy ปลดล็อกเลเวล 1–3 (`SkillRules`) | ต้อง 30 สกิลใหม่ ท่าเดิมหลายท่าเป็นเตะ/ศอก/โหม่ง (ข้อ J2) |
| หลาย Hit ในสกิลเดียว | ไม่มี ท่าหนึ่งโดนเป้าหนึ่งครั้ง (`Fighter.hit_ids`) | ต้องมี "ลำดับท่า" ในสกิล (ส่วนที่ 4.2) จำเป็นกับ Rapid Punch, Knockout Combo และ Ultimate ทุกท่า |
| Passive | ไม่มีระบบ มีเพียงค่าคงที่ต่อฮีโร่: `crit`, `attack_speed`, `parry_window` (Dao 12 ticks), `skill_armor` (Pong) | ต้องสร้าง `PassiveRules` (สะสม/หมดอายุตาม tick) |
| Ultimate + Gauge | ไม่มี สกิลช่อง 5 (เช่น Furnace Slam) เป็นท่าใหญ่แบบ cooldown 11–12.5 วินาที | ต้องสร้าง gauge, ท่าหลายจังหวะ, ช่วงเตือน (`telegraph` มีแล้วสำหรับศัตรู) |
| Counter / Parry | มี Perfect guard: การ์ดภายใน 8 ticks ก่อนโดน = parry, ศัตรูเซ 30 ticks, ตีถัดไป ×1.5 (`test_parry`) เฉพาะฮีโร่ | สกิลแบบ "ตั้งท่ารับแล้วสวนอัตโนมัติ" ยังไม่มี ต่อยอดจากกลไกนี้ได้ |
| Grab / Throw | มีเฉพาะหยิบและขว้าง**อาวุธ** (`test_throw`, `StreetWeapons`) "grab" ใน `EnemyBrain` คือบอสเดินไปเก็บอาวุธ BLUEPRINT ส่วนที่ 6 จดไว้ว่าจับทุ่มยังไม่มี | ต้องสร้างทั้งระบบ: สถานะจับ/ถูกจับ, ทุ่ม, ตัวที่ถูกทุ่มชนตัวอื่น, การหลุด |
| ความต้านทานของบอส | `unshaken` (บอสไม่ชะงัก มี break meter), `poise` (elite), บอสไม่สะเทือนกับอาวุธที่ขว้าง | ใช้เป็นฐานของ Grab Resistance ได้ เพิ่มฟิลด์ในข้อมูลศัตรู |
| กัน Stun lock | ฮีโร่มี `stun_limit` 40 ticks แล้วล้ม + ลุกอมตะ 36 ticks (`test_stun_lock`) | ใช้เป็นกติกา PvP ได้ทันที ต้องครอบคลุมการถูกจับด้วย |
| Critical | มี (`crit_chance`, ×1.5, สุ่มจาก rng ของโซน) | Critical Focus ต่อยอดได้ |
| PvP / Balance Profile | ไม่มี PvP ไม่มี networking (งานออนไลน์อยู่ IL-7 ตาม D4) ค่าทุกอย่างมีชุดเดียว | ใส่โครง profile ในข้อมูลได้ตอนนี้ แต่ทดสอบ PvP จริงยังทำไม่ได้ (ข้อ J6) |
| สกิลบอสแยกจากผู้เล่น | แยกอยู่แล้วโดยพฤตินัย: ตรวจแล้วไม่มีศัตรูตัวใดใช้ท่าของสกิลฮีโร่ บอสใช้ `enemies.json` + `BossMechanics` | ยังไม่มีเทสต์บังคับ เพิ่มการตรวจตอนโหลด |
| Hotbar | 7 ช่อง: โจมตี 1, สกิล 4, ของกิน 2 (`HotbarRules`) | 6 Active + Ultimate + Grab ไม่พอช่อง (ข้อ J3) |
| ปลดล็อกตามเลเวล | มีกลไก (`unlock_level`) เพดานเลเวล 70 ตรงกับ Blueprint | เปลี่ยนเฉพาะตัวเลข แต่กระทบ tutorial และสมดุลบทที่ 1 (ข้อ J4) |
| Animation | ท่าเล่นได้ 4 แบบ: `light`, `heavy`, `stab`, `swing` (`MoveLibrary.ANIMS`, ภาพ LPC) | ไม่มีท่าจับ ยก ทุ่ม เสย (ข้อ J8) |
| เซฟ | `PlayerProfile` เวอร์ชัน 10 เก็บ `hero` และ hotbar ไม่เก็บสกิล (คำนวณจากเลเวล) backend ยังเก็บแค่บัญชี | ไม่ต้องมี migration ฝั่ง backend `HotbarRules.clean` ล้างสกิลที่ไม่มีแล้วออกจาก hotbar เองอยู่แล้ว |
| Auto battle | `AutoPilot` เลือกสกิลจากข้อมูลท่า (วงกว้างกับกลุ่ม ท่าใหญ่เก็บไว้) | ต้องสอนให้ใช้ท่าตั้งรับ จับ และ Ultimate gauge |
| เครื่องมือวัดสมดุล | `client/tests/harness/` (FarmCheck, LevelingRun, WorldBossCheck) + `test_balance` | เพิ่มตัววัด Damage ต่อสกิลและอัตราส่วน Ultimate |

สรุป: โครงสร้างข้อมูลและกฎเดิมรองรับการขยายได้ดี ไม่ต้องเขียน Combat ใหม่
ของที่ต้องสร้างใหม่จริงมี 5 อย่าง: สกิลหลายจังหวะ, Passive, Ultimate gauge, ท่าตั้งรับสวนกลับ และ Grab/Throw

## 3. ข้อตกลง (อนุมัติ 2026-11-10)

| # | คำถาม | คำแนะนำ | ผลกระทบ |
|---|---|---|---|
| J1 | ฮีโร่มี 6 ตัว แต่อาชีพใหม่มี 5 จะจับคู่อย่างไร | **ตัดสินแล้ว (เจ้าของ 2026-11-10): ฮีโร่ 5 ตัว 5 อาชีพ ตัวละหนึ่งอาชีพ** จับคู่ที่เสนอ: Riku = Boxer, Kan = Brawler, Oren = Grappler (ประวัติเป็นอดีตนักมวยปล้ำท่าเรือ), Dao = Counter Fighter (parry กว้างอยู่แล้ว), Mika = Street Fighter (เร็ว combo ยาว) **Pong ถูกถอดออกจากรายชื่อที่เลือกได้** (ยืนยันแล้ว) | เซฟที่เล่น Pong อยู่ต้องไม่หาย: migration ของ `PlayerProfile` (เวอร์ชัน 11) ย้ายเป็น Kan (Brawler ซึ่งใกล้ที่สุด) คงชื่อที่ผู้เล่นตั้ง เลเวล ของ และเควสไว้ ต้องแก้ STORY_BIBLE (Pong เป็น NPC หรือถอดออก; Footballer/Basketball/Police เป็นประวัติ ไม่ใช่อาชีพ), ยกเลิก D3, แก้ `test_classes`, หน้าสร้างตัวละคร และ `max_characters` ยังคง 4 |
| J2 | สกิลเดิม 24 สกิลมีเตะ ศอก โหม่ง (Whirlwind Kick, Breach Kick, Leg Sweep, Headbutt ฯลฯ) ขัดกับ "หมัดเท่านั้น" | เลิกใช้ทั้ง 24 สกิลเมื่อชุดใหม่ของอาชีพนั้นพร้อม ท่าที่เป็นหมัดอยู่แล้ว (Liver Shot, One-Two, Knockout Blow) ปรับเป็นสกิลใหม่ได้ | hotbar ของเซฟเดิมถูกล้างช่องสกิลเก่าอัตโนมัติ ผู้เล่นเดิมได้สกิลใหม่ตามเลเวลทันที |
| J3 | Hotbar 7 ช่องไม่พอ | Ultimate และ Grab มีปุ่มของตัวเอง ไม่กินช่อง hotbar ส่วน hotbar คง 7 ช่อง ผู้เล่นเลือกเองว่าจะวาง Active ตัวไหน (6 ตัว) กับของกิน | ต้องเพิ่ม 2 ปุ่มบนจอสัมผัส และผ่าน UI audit ที่ข้อความ 150% |
| J4 | ตารางปลดล็อกเริ่มสกิลแรกที่เลเวล 5 แต่ตอนนี้ได้ครบ 4 สกิลที่เลเวล 3 และ tutorial มีขั้น "ใช้สกิล" ที่ Depot Yard | ให้ Active 1 ที่เลเวล 1 (tutorial ไม่พัง) ที่เหลือตามตาราง: 10, 20, 25, 35, 40, Passive 15 และ 30, Ultimate 50 | เลเวล 1–19 จะมีสกิลน้อยกว่าเดิม ต้องวัดบทที่ 1–2 ใหม่ด้วย harness และอาจต้องปรับค่าศัตรู |
| J5 | Ultimate ใช้ cooldown หรือ gauge | Gauge อย่างเดียว เต็มจากการตีโดนและการถูกตี (ฝ่ายเสียเปรียบยังสะสมได้) ไม่ใช้ energy | เพิ่มแถบบน HUD |
| J6 | PvP ยังไม่มีในเกม | ใส่ `pve` และ `pvp` profile ในข้อมูลสกิลตั้งแต่ต้น แต่ทำและทดสอบเฉพาะ PvE ตอนนี้ การทดสอบ 25 คู่รอ IL-7 (zone server) | Phase 6 ของ Blueprint เลื่อนไปหลังงานออนไลน์ ระหว่างนี้วัดได้เฉพาะแบบจำลอง AutoPilot สู้กันเองใน sim |
| J7 | ชื่ออาชีพ "Street Fighter" ตรงกับเครื่องหมายการค้าของเกมอื่น และภาพอ้างอิงใน Blueprint เป็นตัวละครของเกมอื่น | ใช้ชื่อแสดงผลอื่น เช่น "Street Striker" (id `striker`) ภาพอ้างอิงใช้ดูอารมณ์เท่านั้น ภาพจริงมาจาก asset pipeline ที่มีใบอนุญาต (`docs/ASSETS.md`) | ต่ำ แก้เฉพาะชื่อ |
| J8 | Ultimate ต้องมี animation จริง แต่ภาพตัวละครมีแค่ 4 ท่าโจมตี | รอบแรกใช้ท่าที่มี + จังหวะ + VFX/กล้องสั่น/เสียง ให้ครบ แล้วเปิดงาน asset แยกสำหรับท่าจับ ยก ทุ่ม เสย (สอดคล้อง D10: ทำเกมให้ครบก่อน) | Grappler จะดูไม่สมบูรณ์จนกว่าจะมีภาพท่าจับ |

ค่าสมดุลทุกตัว (damage, cooldown, อัตรา gauge) เป็นค่าตั้งต้นจนกว่าจะวัดด้วย harness
และเจ้าของอนุมัติ ตามกฎใน `client/data/CLAUDE.md`

## 4. การออกแบบเชิงเทคนิค (ตามขอบเขตชั้นของ repo)

### 4.1 ข้อมูล (`client/data/`)

- `jobs.json` (ใหม่): ต่ออาชีพมี ชื่อ, ชุด Basic Attack (`moveset`: light/heavy → move id),
  รายการสกิล 9 ตัว, โปรไฟล์ Grab (ระยะ เวลาจับ ท่าทุ่ม), ค่า gauge
- `heroes.json`: เพิ่มฟิลด์ `job` ฟิลด์ `skills` เดิมเลิกใช้เมื่ออาชีพนั้นย้ายเสร็จ
- `skills.json`: เพิ่ม `job`, `type` (`active` / `passive` / `ultimate`), `sequence`
  (ลำดับ move id แทน `move` เดี่ยว), `gauge_cost`, `targeting`, `boss_rule`
  และ `profiles`: `{"pve": {...}, "pvp": {...}}` เป็นตัวคูณของ damage, hitstun, knockback,
  duration, cooldown ต่อโหมด ตรรกะสกิลไม่มีตัวเลขของโหมดใดฝังอยู่
- `moves.json`: ฟิลด์ใหม่ที่ต้องมี `grab` (ท่าจับ), `counter` (หน้าต่างรับแล้วสวน),
  และ `anim` เพิ่มเมื่อมีภาพ
- `enemies.json`: `grab_resist` (`none` / `brief` / `immune`) บอสเป็น `immune` โดยปริยาย
- `ContentDB` ตรวจตอนโหลด: ทุกอาชีพมี 6 + 2 + 1, id ไม่ซ้ำ, ทุกสกิลมีทั้งสอง profile,
  Ultimate มีช่วงเตือน, และ**ไม่มี move ใดถูกใช้ทั้งโดยสกิลผู้เล่นและ moveset ของศัตรู**

### 4.2 กฎ (`client/sim/`)

`ZoneSim.gd` ชนเพดาน 1000 บรรทัด ของใหม่ทุกอย่างจึงเป็นคลาสช่วยข้าง ๆ:

| คลาสใหม่ | หน้าที่ |
|---|---|
| `SkillSequence` | เดินสกิลหลายจังหวะ: จบท่าหนึ่งเริ่มท่าถัดไปเอง แต่ละจังหวะมี hitbox และ `hit_ids` ของตัวเอง จึงนับ Hit ซ้ำจาก bug ไม่ได้ หลุดลำดับเมื่อผู้ใช้ถูกขัดจังหวะ |
| `PassiveRules` | ตัวนับของ passive (Critical Focus, Momentum, Flow, Retaliation): เพิ่มเมื่อโดน ลดตาม tick รีเซ็ตเมื่อพลาด ให้ตัวคูณแก่ `CombatRules.damage_for` |
| `UltimateRules` | Gauge: เติมจาก damage ที่ทำและที่รับ ใช้เมื่อเต็ม เก็บใน `Fighter` (ไม่บันทึกลงเซฟ) |
| `CounterRules` | ท่าตั้งรับ: ถ้าถูกตีจากด้านหน้าในหน้าต่างของท่า จะยกเลิก hit นั้นและเริ่มท่าสวน ต่อยอด `_parry` ไม่สวนท่า `guard_break` ของบอสและไม่สวนของตกจากฟ้า (hazard) |
| `GrabRules` | สถานะ `GRAB` / `HELD` ใน `Fighter.State`, ระยะเวลาจับสูงสุด, ทุ่ม (ตัวที่ถูกทุ่มเป็นวัตถุชนตัวอื่นแบบเดียวกับ `thrown_hit`), การหลุด, ช่วงกันจับซ้ำหลังหลุด |
| `BalanceProfile` | เลือก profile ตามโหมดของโซน (`pve` ค่าเริ่มต้น) แล้วคืนค่าที่คูณแล้ว |

- `FighterInput` เพิ่ม `grab` (Ultimate ใช้ช่อง `skill` เดิมได้ เพราะเป็น skill id)
- `SkillRules.unlocked` อ่านจากอาชีพของฮีโร่ เซิร์ฟเวอร์ยังเป็นผู้ตัดสินว่าใครใช้สกิลไหนได้
- บอส: `unshaken` + `grab_resist: immune` = จับไม่ติด ท่าจับกลายเป็นการกระแทกธรรมดา
  (เหมือนที่บอสไม่สะเทือนกับอาวุธที่ขว้าง) Titan Destruction จึงยังทำ damage และ shockwave ได้
- ทุกอย่างคงความ deterministic: tick ล้วน ไม่มี randomness นอก rng ของโซน

### 4.3 การแสดงผล (`client/scenes/`) และส่วนอื่น

- HUD: แถบ Ultimate, ปุ่ม Ultimate และ Grab (แป้นและจอสัมผัส), ตัวบอก stack ของ passive
- FX/เสียง: ใช้ช่อง `fx`, `fx_at`, `sound` เดิมของ `skills.json` ต่อจังหวะของ sequence
- หน้าสร้างตัวละครและหน้า Status แสดงอาชีพและสกิลตามเลเวล
- `AutoPilot`: ใช้ท่าตั้งรับเมื่อเห็นศัตรูง้าง, จับตัวที่ไม่ใช่บอส, เก็บ Ultimate ไว้กับกลุ่มหรือบอส
- เซฟ: `SAVE_VERSION` 11 ถ้ามีการเปลี่ยนฟิลด์ที่บันทึก (hotbar ล้างเองอยู่แล้ว)
- `window.ironboundProbe` ไม่เพิ่มอะไรที่ผู้เล่นมองไม่เห็น

## 5. ลำดับงาน (PR ละหนึ่งหัวข้อ CI เขียวก่อน merge)

| PR | งาน | เทสต์/เกณฑ์ผ่าน |
|---|---|---|
| JS-0 (เสร็จ) | บันทึกข้อตกลง J1–J8 ลง BLUEPRINT, GAME_DESIGN, STORY_BIBLE | เอกสารเท่านั้น |
| JS-1a (เสร็จ) | ถอดฮีโร่ตัวที่ 6 ออกจาก `heroes.json` `order` พร้อม migration ของเซฟ | `test_heroes`, `test_classes`, `test_save_carry_over`: เซฟ Pong เดิมโหลดได้ครบเป็นฮีโร่ตัวใหม่ |
| JS-1 (เสร็จ) | โครงข้อมูล: `jobs.json`, ฟิลด์ใหม่ใน `skills.json`, `BalanceProfile`, การตรวจใน `ContentDB` รวมกฎแยกสกิลบอส ฮีโร่ยังใช้สกิลเดิม | `test_content`, เทสต์ใหม่ `test_jobs`; เกมเล่นเหมือนเดิมทุกประการ |
| JS-2 (เสร็จ) | Basic Attack ต่ออาชีพ (ข้อมูล + `moveset` ของฮีโร่) | `test_combat`, เทสต์ combo ต่ออาชีพ, วัดบทที่ 1 ด้วย harness |
| JS-3 (เสร็จ) | `SkillSequence` (สกิลหลายจังหวะ) + `PassiveRules` | เทสต์: แต่ละจังหวะโดนเป้าหนึ่งครั้ง, ถูกขัดแล้วหยุด, passive สะสมและหมดอายุ |
| JS-4 (เสร็จ) | `GrabRules`: Basic Grab/Throw ของทุกอาชีพ, `grab_resist` | `test_grab`: จับ ทุ่ม ชนตัวอื่น หลุดเอง กันจับซ้ำ บอสจับไม่ติด |
| JS-5 (เสร็จ) | `CounterRules`: ท่าตั้งรับสวนกลับ | เทสต์: สวนเฉพาะในหน้าต่าง ด้านหน้าเท่านั้น ไม่สวนท่าทำลายการ์ดของบอส พลาดแล้วเปิดช่อง |
| JS-6 (เสร็จ) | Boxer ครบชุด (6 + 2) แทนสกิลเดิมของ Riku พร้อมตารางปลดล็อกใหม่, hotbar, tutorial, AutoPilot | `test_skills`, `test_balance` (กฎใหม่), `test_auto_battle`, harness บท 1–5 |
| JS-7 – JS-10 (เสร็จ) | Brawler, Grappler, Counter Fighter, Street Fighter อาชีพละ PR ตามแบบ JS-6 | เหมือน JS-6 + `test_classes`: ไม่มีอาชีพใดเก่งทุกด้าน (ตารางส่วนที่ 8 ของ Blueprint เป็นเทสต์) |
| JS-11 (เสร็จ) | `UltimateRules` + Ultimate ทั้ง 5 + HUD | เทสต์: gauge เติมจากการตีและการถูกตี, มีช่วงเตือน, damage รวม 2–3 เท่าของ Active ที่แรงที่สุด, Counter Ultimate ไม่ทำ damage ถ้าไม่ถูกตี, Titan Destruction ไม่บังคับทุ่มบอส |
| JS-12 | PvE Balance: Monster, Mini-boss, Stage boss, World boss, อุปกรณ์เริ่มต้นถึง Endgame, +0 ถึง +10 | รายงาน harness (หลาย seed) ให้เจ้าของอนุมัติ ปรับค่าเฉพาะใน profile `pve` |
| หลัง IL-7 | PvP: โหมดของโซน, profile `pvp`, Grab Break, ทดสอบ 5 × 5 | เทสต์ sim สองฮีโร่สู้กัน: ไม่มี lock เกินเพดาน, Ultimate ไม่ one-shot ที่ gear ใกล้เคียง |

แผนทดสอบ 10 รอบของ Blueprint ลงที่: Test 1–5 เป็น unit test ใน JS-2 ถึง JS-11,
Test 6, 8, 9 เป็น harness ใน JS-12, Test 7 รอ IL-7, Test 10 เป็นเทสต์ถดถอยในทุก PR
(cooldown, hitbox, นับ Hit ซ้ำ, สกิลที่ยังไม่ปลดล็อกใช้ไม่ได้ไม่ว่า client ส่งอะไรมา)

### ผลวัด JS-2 (Basic Attack ต่ออาชีพ, 2026-11-10)

ค่าใน `moves.json` (startup/active/recovery เป็น tick, ปุ่มหนักยังเป็น Haymaker ร่วมกันทุกอาชีพ):

| อาชีพ | ชุดหมัด | Damage | เอกลักษณ์ |
|---|---|---|---|
| Boxer | jab → straight → heavy | 6 / 8 / 14 | ระยะไกลสุด หมัดปิดแรงสุด ทำให้เซแต่ไม่ล้ม (ต่อหมัดได้) |
| Brawler | left → right → swing | 6 / 8 / 12 | กว้างกว่าทุกจังหวะ หมัดเหวี่ยงผลักไกลและล้ม เริ่มช้ากว่าเล็กน้อย |
| Grappler | short → heavy → push | 6 / 8 / 12 | **ค่าเท่าชุดเดิม** (ดูหมายเหตุ) |
| Counter Fighter | quick → counter → heavy | 5 / 7 / 11 | เบากว่า Boxer มีจังหวะพักหลังหมัดที่สอง |
| Street Striker | jab → cross → rapid jab → finisher | 5 / 6 / 5 / 10 | สี่หมัด เร็วที่สุด เบาต่อหมัด |

วัดด้วย auto battle ฟาร์ม 4 ลาน (เลเวล 4, 29, 43, 58) ฮีโร่เลเวลเท่าลาน ของร้าน +0, 4 seed, ครั้งละ 3 นาที
เทียบกับชุดหมัดเดิม (ผลรวม 4 ลาน): Riku ฆ่า +5% รับ damage −10%; Kan −4% / +3%; Oren 0% / 0%;
Dao +5% / +11%; Mika −1% / −9% ล้มรวม 3 ครั้งจาก 80 รอบก่อนเปลี่ยน และ 2 ครั้งหลังเปลี่ยน
ทั้งหมดอยู่ในช่วงความแปรปรวนของ seed (ราว ±10%) ด่านเนื้อเรื่องเลเวล 2–9: ไม่มีการล้มทั้งก่อนและหลัง

หมายเหตุ Grappler: ลองชุดระยะประชิด (ระยะสั้นลง 2–4 px, damage 7/10/11) แล้ว วัด 12 ลาน 6 seed ได้
ฆ่า −3% รับ damage −4% ล้ม 3/72 (เดิม 1/72) แต่ทำให้เทสต์ฟาร์มอัตโนมัติ seed เดียว
(`test_farming_loop`) ล้ม จึงคงค่าเท่าชุดเดิมไว้ก่อน ระยะประชิดของ Grappler จะมาพร้อมระบบ Grab (JS-4)
ซึ่งให้สิ่งตอบแทนกับระยะที่สั้นลง

### ผลวัดชุดสกิลครบ (JS-6 ถึง JS-11, 2026-11-10)

**ตารางปลดล็อก.** วัดด่านเนื้อเรื่องเลเวล 2–9 ด้วย auto battle (ฮีโร่ 5 ตัว × 3 seed, ของร้าน, ข้าวกล่อง 10):

| ตาราง | เวลาเคลียร์เทียบของเดิม | Damage ที่รับตอนสู้บอสด่านแรก | อาหารที่ใช้กับบอสด่านแรก |
|---|---|---|---|
| ของเดิม (4 สกิลครบที่เลเวล 3) | 100% | 1.55 เท่าของ HP | 2.5 |
| 1/10/20/25/35/40 (ตามข้อตกลง J4) | ช้าลง 17–45% | 2.62 เท่า | 4.5 |
| **1/2/3/5/15/30 (ที่ใช้อยู่)** | ช้าลง 3–19% | 1.93 เท่า | 3.1 |

ตาราง J4 ทำให้ auto battle ผ่านบอสด่านแรกจากเซฟใหม่ไม่ได้ (เทสต์ `test_story_auto` ล้ม) จึงใช้ตารางที่สาม
ไม่มีการล้มในทั้งสามแบบ เปลี่ยนได้ที่เดียวคือ `jobs.json` `unlocks` (และ `unlock_level` ของแต่ละสกิล)

**ฟาร์ม.** 4 ลาน (เลเวล 4, 29, 43, 58) ฮีโร่เลเวลเท่าลาน ของร้าน +0, 4 seed เทียบกับเกมก่อนเริ่มงานนี้ (ผลรวม 4 ลาน):

| ฮีโร่ | อาชีพ | จำนวนฆ่าต่อชั่วโมง | Damage ที่รับ | ล้ม (จาก 16 รอบ) |
|---|---|---|---|---|
| Riku | Boxer | +6% | −20% | 1 (เดิม 0) |
| Kan | Brawler | −8% | −15% | 0 (เดิม 1) |
| Oren | Grappler | −4% | −6% | 1 (เดิม 0) |
| Dao | Counter Fighter | −3% | −24% | 0 (เดิม 0) |
| Mika | Street Striker | +6% | −3% | 0 (เดิม 2) |

**Ultimate ต่อเป้าหมายเดียว** (ผลรวม damage ของทุกจังหวะ ก่อนคูณ power): Boxer 136, Grappler 126,
Counter Fighter 130 (เมื่อสวนสำเร็จ), Striker 120, Brawler 114 (แต่โดนทุกตัวรอบตัว) ทุกท่าอยู่ที่ 2–3 เท่าของ
Active ที่แรงที่สุดของอาชีพ (`test_balance`)

**ยังไม่ได้วัด:** Mini-boss, Stage boss และ World boss ที่เลเวลสูง, อุปกรณ์ระดับ Endgame และ +10,
อัตราการเติม gauge ในการเล่นจริง (ตอนนี้ +1.5 ต่อหมัดที่โดน และ +60 ต่อการเสีย HP ทั้งหลอด)
ค่า PvP ใน profile เป็นค่าตั้งต้น (damage ×0.6, Ultimate ×0.5) ยังไม่มีโหมดให้ทดสอบ

**ข้อจำกัดที่รู้:** สกิลใช้ไอคอน เอฟเฟกต์ และเสียงชุดเดิมซ้ำกัน (ยังไม่มีไอคอนเฉพาะ 45 ตัว),
ท่าตั้งรับใช้ท่ายืน + โล่, gauge หายเมื่อเปลี่ยนพื้นที่, gamepad ใช้ Ultimate ผ่านช่อง hotbar

### ชุดสกิลที่ใช้อยู่ (สร้างจากข้อมูลเกม)

Damage คือผลรวมทุกจังหวะต่อเป้าหมายเดียว ก่อนคูณ power ของฮีโร่ สกิลตั้งรับทำ damage เฉพาะเมื่อรับหมัดได้

**Boxer** (Riku Sato): Precision and burst damage

| Lv | Skill | Type | Damage on one target | Energy | Cooldown | What it does |
|---|---|---|---|---|---|---|
| 1 | Power Jab | active | 22 | 8 | 2.5 s | A fast straight punch that reaches further than a normal jab. Opens an attack. |
| 2 | Heavy Cross | active | 32 | 14 | 4 s | A heavy cross with the whole body behind it. Staggers its target and breaks guard. |
| 3 | Uppercut | active | 30 | 12 | 3.5 s | A rising punch that lifts one foe off their feet. |
| 5 | Body Blow | active | 36 | 14 | 4.2 s | A short punch to the body at close range. Heavy damage to one foe and a long stagger. Breaks guard. |
| 15 | Counter Punch | active | 44 | 15 | 4.2 s | Guard for a moment; a blow caught from the front is answered with a heavy punch. Nothing happens if nobody attacks. |
| 30 | Knockout Combo | active | 58 | 30 | 10 s | Three quick punches and a heavy one that sends the foe flying. |
| 10 | Critical Focus | passive | - | - | - | Each blow landed in a row adds 3% critical chance, up to 15%. A miss loses it. |
| 25 | Precision Impact | passive | - | - | - | Heavy punches, skills and the last blow of a combination deal 12% more damage. |
| 50 | Knockout Devastation | ultimate | 136 | full gauge | - | Gather everything into one assault: lunge in, four heavy punches, then a knockout blow whose shock hits everyone nearby. Aim it: a miss wastes the gauge. |

**Brawler** (Kan Srisuk): Pressure and area damage

| Lv | Skill | Type | Damage on one target | Energy | Cooldown | What it does |
|---|---|---|---|---|---|---|
| 1 | Rapid Punch | active | 26 | 10 | 2.5 s | A burst of four punches at whatever stands in front. |
| 2 | Double Smash | active | 34 | 14 | 4 s | Two heavy blows, the second one flooring whoever it hits. |
| 3 | Wide Swing | active | 26 | 15 | 4 s | A sweeping punch across a wide arc that knocks down several foes at once. |
| 5 | Ground Pound | active | 32 | 25 | 7 s | Punch the street itself. Damages and floors everyone around. Breaks guard. |
| 15 | Brutal Rush | active | 40 | 22 | 4.2 s | Charge forward throwing three punches, ploughing through anyone in the way. The last breaks guard. |
| 30 | Backhand Smash | active | 40 | 28 | 9 s | A swinging backhand that hits behind and in front. Clears whoever closed in at the sides. |
| 10 | Pain Resistance | passive | - | - | - | While attacking, blows that land on you deal 20% less damage. They still stagger. |
| 25 | Berserk Momentum | passive | - | - | - | Each blow landed adds 4% damage for 4 seconds, up to 20%. Keep hitting to keep it. |
| 50 | Street Carnage | ultimate | 114 | full gauge | - | Let it all out: three bursts of punches all around, a heavy punch forward, then a ground smash whose shockwave floors the whole street corner. |

**Grappler** (Oren Vale): Grab, throw and control

| Lv | Skill | Type | Damage on one target | Energy | Cooldown | What it does |
|---|---|---|---|---|---|---|
| 1 | Iron Grip | active | - | 10 | 3 s | Lunge in and seize a foe from further away. Then throw them with any attack. |
| 2 | Power Throw | active | 30 | 15 | 4.2 s | Seize a foe and hurl them far ahead. They knock down everyone they hit. |
| 3 | Backbreaker | active | 44 | 18 | 4.2 s | Seize a foe and break them over your knee. Heavy damage to that one foe. |
| 5 | Ground Slam | active | 52 | 25 | 7 s | Lift a foe and slam them into the street. The impact floors everyone close by. |
| 15 | Crowd Toss | active | 24 | 22 | 4.2 s | Use the foe you seize as a missile: thrown a long way, hitting hard everyone in their path. |
| 30 | Crushing Hold | active | 50 | 30 | 10 s | Lock a foe in a crushing hold for a second, hurting them all the while, then drop them. |
| 10 | Unbreakable Hold | passive | - | - | - | Your grabs hold ordinary foes 40% longer. Bosses still cannot be held, and nobody can be grabbed twice in a row. |
| 25 | Heavy Impact | passive | - | - | - | Throws, slams and thrown bodies deal 15% more damage. |
| 50 | Titan Destruction | ultimate | 126 | full gauge | - | Lunge, seize a foe, lift them overhead and drive them into the street. The shockwave floors everyone around. A boss cannot be lifted: it takes the blow and the shockwave instead. |

**Counter Fighter** (Dao Kittikun): Defence and punishment

| Lv | Skill | Type | Damage on one target | Energy | Cooldown | What it does |
|---|---|---|---|---|---|---|
| 1 | Quick Counter | active | 22 | 8 | 2.5 s | Guard for an instant; a blow caught from the front is answered at once. Nothing happens if nobody attacks. |
| 2 | Slip Punch | active | 28 | 12 | 3.5 s | Slip past an attack and punch from the side. You cannot be hit while slipping in. |
| 3 | Precision Blow | active | 26 | 12 | 4 s | A picked punch that deals 60% more damage to a foe who is staggered or left open by a parry. |
| 5 | Defensive Stance | active | - | 20 | 12 s | Brace yourself: for 5 seconds every blow that lands on you deals 40% less damage. |
| 15 | Perfect Parry | active | 18 | 10 | 4.2 s | A very short parry. A blow it catches is answered with a punch that leaves the attacker staggered for a long time. |
| 30 | Reversal Strike | active | 52 | 20 | 10 s | Wait for the attack, then answer it with a heavy punch that floors the attacker. Breaks guard. Nothing happens if nobody attacks. |
| 10 | Combat Awareness | passive | - | - | - | Your perfect guard opens 4 ticks earlier, so parries are easier to time. |
| 25 | Retaliation | passive | - | - | - | Each parry or caught blow stores power (up to 2): your next counter hit deals 25% more damage for each. |
| 50 | Absolute Retribution | ultimate | 130 | full gauge | - | Take the perfect guard for a second. A blow caught from the front is answered with five punches and a reversal that ends the fight. If nobody attacks, the gauge is wasted. |

**Street Striker** (Mika Tanabe): Speed, combos and flow

| Lv | Skill | Type | Damage on one target | Energy | Cooldown | What it does |
|---|---|---|---|---|---|---|
| 1 | Quick Jab | active | 14 | 6 | 2 s | A very fast jab. Opens a combo. |
| 2 | Triple Punch | active | 28 | 12 | 3.5 s | Three punches in a row; the last knocks the foe down. |
| 3 | Rush Combo | active | 33 | 16 | 4.2 s | Dash in throwing four punches at everyone in the way; the last is a wide hook that floors foes on both sides. |
| 5 | Rising Fist | active | 30 | 12 | 4 s | A rising punch that lifts a foe off their feet, ready for more. |
| 15 | Dash Strike | active | 30 | 15 | 4 s | A short dash ending in a punch. Breaks guard. |
| 30 | Chain Breaker | active | 44 | 25 | 8 s | The punch that ends a combo: heavy damage, and the foe is thrown back. |
| 10 | Flow State | passive | - | - | - | Each blow landed adds 4% attack speed for 3 seconds, up to 20%. |
| 25 | Combo Mastery | passive | - | - | - | Each blow landed stores 5% damage (up to 20%, for 2.5 seconds) for your next skill. |
| 50 | Million Fist Onslaught | ultimate | 120 | full gauge | - | Dash in and let fly a dozen punches too fast to count, then a heavy one that sends the foe away. A foe who gets out of reach escapes the rest. |

### JS-4: Grab/Throw ที่ทำแล้ว (2026-11-10)

- ปุ่ม: G จับ หรือ E/USE/B เมื่อมือว่างและไม่มีอาวุธให้เก็บ; ระหว่างจับ กดปุ่มโจมตีใดก็ได้เพื่อทุ่ม
  หันทิศก่อนทุ่มได้ จอสัมผัสไม่มีปุ่มใหม่ (ใช้ USE) จึงไม่กระทบ layout
- กติกาความยุติธรรม: การจับหมดเวลาเอง, ตีผู้จับแล้วเหยื่อหลุด, ผู้เล่นที่ถูกจับกดปุ่มรัวเพื่อหลุดเร็วขึ้น,
  หลังหลุดจับซ้ำไม่ได้ 90 ticks, บอสจับไม่ติด (โดนผลักแทน), elite ถูกจับได้ครึ่งเวลา
- ค่าตั้งต้นต่ออาชีพ (รอวัดและอนุมัติ; auto battle ยังไม่ใช้การจับ จึงยังไม่กระทบผลวัดเดิม):

| อาชีพ | จับได้นาน (ticks) | Damage ทุ่ม | ระยะทุ่ม (px) | ล้ม | ตัวที่ถูกชน |
|---|---|---|---|---|---|
| Boxer | 36 | 8 | 40 | ไม่ (เซนาน เปิดช่องหมัดหนัก) | 8 |
| Brawler | 45 | 14 | 110 | ใช่ | 8 |
| Grappler | 75 | 22 | 150 | ใช่ | 14 |
| Counter Fighter | 45 | 12 | 80 | ใช่ | 8 |
| Street Striker | 30 | 8 | 50 | ไม่ (ต่อ combo ได้) | 8 |

- Animation: `grab` (ยื่นมือจับ), `lift` (ยกเหนือศีรษะ), `throw` (ทุ่ม) สร้างจากเฟรม LPC ที่มีอยู่
  (thrust, spellcast, slash) ให้ตัวละคร LPC ทั้ง 51 ตัว แถวภาพเดิมไม่เปลี่ยน ผู้ถูกจับใช้เฟรม `hurt`
  วาดนอนขวางเหนือศีรษะผู้จับ ภาพวาดเอง (ไม่ใช่ LPC) ใช้ท่า light/heavy แทน
- ยังไม่ทำ: auto battle ใช้การจับ, ศัตรูจับผู้เล่น, ขั้น tutorial ของการจับ, ท่าทุ่มพิเศษของ Grappler (JS-8)

### JS-5: ท่าตั้งรับสวนกลับที่ทำแล้ว (2026-11-10)

- สกิลที่ move แรกเป็นท่าตั้งรับ (`"counter": true`) จะรับหมัดจากด้านหน้าในช่วง active ของท่า:
  หมัดนั้นไม่เข้า ผู้โจมตีเซเหมือนโดน parry และท่าสวน (`then`) ออกทันที หมัดแรกของท่าสวนได้ damage ×1.5
- ถ้าไม่มีใครตี ท่าสวนไม่ออกเลย เสีย cooldown และ energy และยืนเปิดช่องตลอดช่วง recovery
- สิ่งที่ชนะท่าตั้งรับ: รอให้หมดเวลา, ตีจากด้านหลัง, ท่าทำลายการ์ด, การจับ, อาวุธที่ขว้าง และ hazard ของบอส
- บอสถูกรับหมัดได้แต่ไม่เซ (ท่าสวนยังเข้าเป็น counter hit)
- การรับหมัดสำเร็จนับเป็น parry สำหรับ Passive (Retaliation)
- มี move กลาง `counter_stance` (เปิด 24 ticks, energy 15) ให้สกิลใช้ ยังไม่มีสกิลใดใช้จนกว่าจะถึง JS-6
- ยังไม่ทำ: Defensive Stance (ลด damage ชั่วคราว) เป็นกลไก buff คนละแบบ จะทำพร้อมชุด Counter Fighter (JS-9)

## 6. ความเสี่ยง

- **สมดุลช่วงต้นเกม:** สกิลมาช้าลงทำให้บทที่ 1–2 ยากขึ้น ต้องวัดก่อน merge JS-6
- **เทสต์เดิมที่ต้องเขียนใหม่ ไม่ใช่ปิด:** `test_balance` (กฎ "ช่อง 5 แรงสุด"),
  `test_classes` (6 อาชีพ), `test_skills`, `test_skill_pacing`, `test_hotbar`, `test_tutorial`
- **ภาพ:** ท่าจับและท่าไม้ตายจะใช้ท่าทางเดิมจนกว่างาน asset จะเสร็จ (J8)
- **PvP:** ออกแบบ profile ได้ แต่ยืนยันความยุติธรรมจริงไม่ได้จนกว่าจะมี zone server
- **ขนาดงาน:** 45 รายการ + 5 ระบบใหม่ ประมาณ 13 PR ทำทีละอาชีพเพื่อให้เกมเล่นได้ตลอดทาง
