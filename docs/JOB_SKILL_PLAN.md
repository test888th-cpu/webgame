# แผนพัฒนาระบบ 5 อาชีพและ Player Skill — The Iron Legacy

**สถานะ:** ข้อเสนอ (2026-11-10) ยังไม่มีโค้ดหรือข้อมูลเกมเปลี่ยน เอกสารนี้เทียบ
"Blueprint ระบบ 5 อาชีพและ Player Skill System" ของเจ้าของกับ repo ปัจจุบัน
แล้วเสนอแผนลงมือทำเป็น PR ย่อย งานเริ่มได้เมื่อเจ้าของตอบข้อ J1–J8 ในส่วนที่ 3
เมื่ออนุมัติแล้ว ข้อตกลงย้ายเข้า `docs/BLUEPRINT.md` ส่วนที่ 6 และ `GAME_DESIGN.md`

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

## 3. เรื่องที่เจ้าของต้องตัดสินก่อนเริ่ม

| # | คำถาม | คำแนะนำ | ผลกระทบ |
|---|---|---|---|
| J1 | ฮีโร่มี 6 ตัว แต่อาชีพใหม่มี 5 จะจับคู่อย่างไร | แยก "อาชีพ" ออกจาก "ตัวละคร": ตัวละครคือชื่อ หน้าตา ประวัติ ส่วนอาชีพคือชุดท่า จับคู่ Riku = Boxer, Oren = Grappler (ประวัติเป็นอดีตนักมวยปล้ำท่าเรือ), Dao = Counter Fighter (parry กว้างอยู่แล้ว), Mika = Street Fighter (เร็ว combo ยาว), Kan = Brawler (สกิลกว้างที่สุด) ส่วน Pong ให้เจ้าของเลือก: ใช้อาชีพ Brawler ร่วมกับ Kan หรือพักไว้จนมีอาชีพที่ 6 | เซฟเดิมไม่เสีย (id ฮีโร่คงเดิม) ต้องแก้ STORY_BIBLE ให้ Footballer/Basketball/Police/Soldier เป็นประวัติ ไม่ใช่อาชีพ และยกเลิก D3 |
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
| JS-0 | บันทึกข้อตกลง J1–J8 ลง BLUEPRINT, GAME_DESIGN, STORY_BIBLE | เอกสารเท่านั้น |
| JS-1 | โครงข้อมูล: `jobs.json`, ฟิลด์ใหม่ใน `skills.json`, `BalanceProfile`, การตรวจใน `ContentDB` รวมกฎแยกสกิลบอส ฮีโร่ยังใช้สกิลเดิม | `test_content`, เทสต์ใหม่ `test_jobs`; เกมเล่นเหมือนเดิมทุกประการ |
| JS-2 | Basic Attack ต่ออาชีพ (ข้อมูล + `moveset` ของฮีโร่) | `test_combat`, เทสต์ combo ต่ออาชีพ, วัดบทที่ 1 ด้วย harness |
| JS-3 | `SkillSequence` (สกิลหลายจังหวะ) + `PassiveRules` | เทสต์: แต่ละจังหวะโดนเป้าหนึ่งครั้ง, ถูกขัดแล้วหยุด, passive สะสมและหมดอายุ |
| JS-4 | `GrabRules`: Basic Grab/Throw ของทุกอาชีพ, `grab_resist` | `test_grab`: จับ ทุ่ม ชนตัวอื่น หลุดเอง กันจับซ้ำ บอสจับไม่ติด |
| JS-5 | `CounterRules`: ท่าตั้งรับสวนกลับ | เทสต์: สวนเฉพาะในหน้าต่าง ด้านหน้าเท่านั้น ไม่สวนท่าทำลายการ์ดของบอส พลาดแล้วเปิดช่อง |
| JS-6 | Boxer ครบชุด (6 + 2) แทนสกิลเดิมของ Riku พร้อมตารางปลดล็อกใหม่, hotbar, tutorial, AutoPilot | `test_skills`, `test_balance` (กฎใหม่), `test_auto_battle`, harness บท 1–5 |
| JS-7 – JS-10 | Brawler, Grappler, Counter Fighter, Street Fighter อาชีพละ PR ตามแบบ JS-6 | เหมือน JS-6 + `test_classes`: ไม่มีอาชีพใดเก่งทุกด้าน (ตารางส่วนที่ 8 ของ Blueprint เป็นเทสต์) |
| JS-11 | `UltimateRules` + Ultimate ทั้ง 5 + HUD | เทสต์: gauge เติมจากการตีและการถูกตี, มีช่วงเตือน, damage รวม 2–3 เท่าของ Active ที่แรงที่สุด, Counter Ultimate ไม่ทำ damage ถ้าไม่ถูกตี, Titan Destruction ไม่บังคับทุ่มบอส |
| JS-12 | PvE Balance: Monster, Mini-boss, Stage boss, World boss, อุปกรณ์เริ่มต้นถึง Endgame, +0 ถึง +10 | รายงาน harness (หลาย seed) ให้เจ้าของอนุมัติ ปรับค่าเฉพาะใน profile `pve` |
| หลัง IL-7 | PvP: โหมดของโซน, profile `pvp`, Grab Break, ทดสอบ 5 × 5 | เทสต์ sim สองฮีโร่สู้กัน: ไม่มี lock เกินเพดาน, Ultimate ไม่ one-shot ที่ gear ใกล้เคียง |

แผนทดสอบ 10 รอบของ Blueprint ลงที่: Test 1–5 เป็น unit test ใน JS-2 ถึง JS-11,
Test 6, 8, 9 เป็น harness ใน JS-12, Test 7 รอ IL-7, Test 10 เป็นเทสต์ถดถอยในทุก PR
(cooldown, hitbox, นับ Hit ซ้ำ, สกิลที่ยังไม่ปลดล็อกใช้ไม่ได้ไม่ว่า client ส่งอะไรมา)

## 6. ความเสี่ยง

- **สมดุลช่วงต้นเกม:** สกิลมาช้าลงทำให้บทที่ 1–2 ยากขึ้น ต้องวัดก่อน merge JS-6
- **เทสต์เดิมที่ต้องเขียนใหม่ ไม่ใช่ปิด:** `test_balance` (กฎ "ช่อง 5 แรงสุด"),
  `test_classes` (6 อาชีพ), `test_skills`, `test_skill_pacing`, `test_hotbar`, `test_tutorial`
- **ภาพ:** ท่าจับและท่าไม้ตายจะใช้ท่าทางเดิมจนกว่างาน asset จะเสร็จ (J8)
- **PvP:** ออกแบบ profile ได้ แต่ยืนยันความยุติธรรมจริงไม่ได้จนกว่าจะมี zone server
- **ขนาดงาน:** 45 รายการ + 5 ระบบใหม่ ประมาณ 13 PR ทำทีละอาชีพเพื่อให้เกมเล่นได้ตลอดทาง
