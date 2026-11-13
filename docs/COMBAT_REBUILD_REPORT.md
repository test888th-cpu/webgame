# รายงานการสร้างระบบต่อสู้ใหม่ ห้าอาชีพ รอบที่ 2 (2026-11-13)

ตามคำขอของเจ้าของหลังตรวจรายงานรอบแรก: ทำสกิลทุกอาชีพให้ครบและไม่ซ้ำกัน, Ultimate ไม่ซ้ำ,
ระบบคอมโบครบทุกเส้นทาง, ตารางแอนิเมชัน, ตาราง PvP ทั้ง 10 คู่, วิเคราะห์ PvE ของ Oren
และเทสต์ครบทุกเรื่อง ทุกตัวเลขในไฟล์นี้วัดจริงด้วยกติกาของเกม (ไม่ได้ประมาณ)
ยังไม่ได้ commit หรือ push ตามที่สั่ง

สรุปสั้น:
- คู่ที่แพ้ทางขาด (Brawler/Boxer 94/6, Grappler/Brawler 88/11, Boxer/Striker 78/22)
  ตอนนี้อยู่ที่ 51/49, 58/42, 52/48
- ทั้ง 10 คู่อยู่ระหว่าง 42% ถึง 58% และทุกอาชีพอยู่ระหว่าง 47.1% ถึง 52.2%
- แก้ด้วยกลไก ไม่ได้ปรับดาเมจอย่างเดียว:
  - PvP คิดเกราะเป็นสัดส่วน;
  - เกราะของ Brawler รับได้หนึ่งหมัดต่อวง;
  - Boxer ก้าวเข้าชก;
  - Slip Counter;
  - คว้าคนที่กำลังเหวี่ยงหมัดเกราะไม่ได้
- PvE ทุกคนใกล้ค่าเดิม Oren 224 (เดิม 221) และคง Grappler PvE ×1.3 ไว้

> **อัปเดตหลัง Final Polish:** ตัวเลขและสถานะล่าสุดอยู่ใน [COMBAT_FINAL_REPORT.md](COMBAT_FINAL_REPORT.md).
> ที่เปลี่ยนจากไฟล์นี้: Oren PvE 212 (ไม่ใช่ 224 เพราะ auto battle เก็บ Power Throw ไว้ให้เส้นคอมโบ
> ซึ่งทำให้รอดในลานยากที่สุด) และแอนิเมชันทั้ง 5 ท่าที่ "ตรงบางส่วน" แก้แล้ว

## 1. การออกแบบสกิลแต่ละอาชีพ

ทุกอาชีพมีชุดของตัวเอง:
- เบสิกเบา (light chain) พร้อมคลิปเบาของตัวเอง;
- ท่าหนัก (heavy) ของตัวเอง;
- สกิลแอคทีฟ 6 อันที่มีกลไกต่างกัน;
- สกิลวงกว้างที่โดนหลายคนจริง;
- เส้นคอมโบ 3 เส้นพร้อมท่าปิด;
- Ultimate ที่มีคลิปของตัวเอง;
- พาสซีฟ 2 อันที่สร้างตัวตน

`SkillRegistry` ตรวจทุกครั้งที่โหลดข้อมูล: ท่าของอาชีพหนึ่งห้ามถูกใช้หรือถูกก๊อปไปเป็นของอีกอาชีพ
(เทียบเวลา ดาเมจ hitstun แรงกระเด็น ระยะ การเคลื่อน เอฟเฟกต์ เกราะ และแอนิเมชัน),
ห้ามมีสกิลสองอันที่ลำดับท่าเหมือนกัน, และ Ultimate ต้องมีคลิปของตัวเองที่ไม่ซ้ำใคร

ตัวตนของแต่ละอาชีพ (กลไก ไม่ใช่แค่ตัวเลข):

| อาชีพ | ตัวตน | กลไกเฉพาะ |
|---|---|---|
| Boxer | ฟุตเวิร์กและความแม่น | Heavy Cross, Body Blow, Uppercut ก้าวเข้าชก; Body Blow ดูดพลังงาน 35; Slip Counter มุดหลบ (ไม่โดนตี) แล้วสวนทันที; Overhand ทำลายการ์ด; พาสซีฟ Combination Puncher ลดคูลดาวน์ทุกครั้งที่ต่อคอมโบติด |
| Brawler | ช้า หนัก มีเกราะ ตีวงกว้าง | Hammer Fist, Double Smash ท่าสอง, Backhand Smash และ Street Carnage มีเกราะ (มอนสเตอร์ขัดไม่ได้ ถูกคว้าไม่ได้ตอนกำลังลง); Ground Pound ตีคนที่ล้มอยู่ได้; พาสซีฟ Crushing Momentum ยิ่งตีโดนยิ่งแรงและยิ่งทำลายการ์ด |
| Grappler | คว้า ทุ่ม คุมพื้นที่ | Collar Tie สตันยาวเพื่อคว้าต่อ; ทุ่มใส่คนอื่น; คลื่นของ Ground Slam โดนทุกคนรอบตัวรวมคนที่ล้มอยู่ แล้วต่อด้วยเบสิกได้; PvP ไม่มีทุ่มวน |
| Counter Fighter | อ่านแล้วสวน | ท่าตั้งรับรับหมัดจากด้านหน้าแล้วสวน; Perfect Parry รับได้แม้ท่าทำลายการ์ด; Check Hook ถอยหลังพร้อมชก; Reversal Strike หมุนสวนโดนทุกคนรอบตัว |
| Street Striker | ความเร็วและการเคลื่อนที่ | Dash Strike พุ่งทะลุฝูง; Chain Breaker พุ่งตามไปตีคนที่ล้ม; พาสซีฟ Slipstream หลบถูกลง และหลบยกเลิกท่าได้ทันทีที่ตีโดน |

รายละเอียดทุกท่า (เวลาเป็น tick ที่ 60 ต่อวินาที: startup / active / recovery, ดาเมจฐาน, ระยะเป็นพิกเซล
จากตัวผู้ตี ค่าลบคือด้านหลัง):

### Boxer (Riku)

| Skill (id) | Type, Lv | Moves: startup / active / recovery, damage, reach (px) | Mechanics |
|---|---|---|---|
| Light chain | basic | `boxer_jab` 4/3/9, 6, 6..38<br>`boxer_straight` 5/3/11, 8, 6..40<br>`boxer_heavy` 8/4/18, 14, 4..38 | – |
| Heavy (`boxer_overhand`) | basic | `boxer_overhand` 10/4/18, 13, 6..44<br>`boxer_shovel_hook` 7/3/20, 11, 4..34 | boxer_overhand: guard break<br>boxer_shovel_hook: knockdown |
| Power Jab (`power_jab`) | active, 1 | `power_jab` 4/3/14, 22, 6..46 | – |
| Heavy Cross (`heavy_cross`) | active, 2 | `heavy_cross` 9/4/20, 32, 4..38 | heavy_cross: guard break, step +14 px |
| Uppercut (`uppercut`) | active, 3 | `uppercut` 6/4/20, 30, 4..34 | uppercut: knockdown, step +8 px |
| Body Blow (`body_blow`) | active, 5 | `body_blow` 5/4/18, 36, 2..28 | body_blow: drains 35 energy, step +12 px |
| Slip Counter (`counter_punch`) | active, 15 | `boxer_slip` 2/10/1, 0, 0..1<br>`boxer_counter_hit` 3/4/20, 44, 4..38 | boxer_slip: untouchable, step +12 px<br>boxer_counter_hit: knockdown, step +24 px |
| Knockout Combo (`knockout_combo`) | active, 30 | `ko_combo_1` 4/3/6, 10, 6..38<br>`ko_combo_2` 3/3/6, 10, -38..-6<br>`ko_combo_3` 4/3/8, 12, -32..36<br>`ko_combo_4` 9/4/24, 26, 4..40 | ko_combo_2: AoE<br>ko_combo_3: AoE<br>ko_combo_4: knockdown |
| Critical Focus (`critical_focus`) | passive, 10 | – | Each blow landed in a row adds 3% critical chance, up to 15%. A miss loses it. |
| Combination Puncher (`precision_impact`) | passive, 25 | – | Each link of a skill combo that lands takes 0.75 s off your other skills' cooldowns: long combinations keep the Boxer's tools coming. |
| KNOCKOUT DEVASTATION (`knockout_devastation`) | ultimate, 50 | `ko_dev_lunge` 28/5/6, 12, 4..38<br>`ko_dev_1` 3/3/5, 14, 4..38<br>`ko_dev_2` 3/3/5, 14, 4..38<br>`ko_dev_3` 3/3/5, 14, 4..38<br>`ko_dev_4` 3/3/6, 14, 4..38<br>`ko_dev_blow` 10/4/10, 52, 4..42<br>`ko_dev_shock` 2/5/26, 16, -40..70 | ko_dev_lunge: step +60 px<br>ko_dev_blow: guard break<br>ko_dev_shock: AoE, guard break, knockdown |

### Brawler (Kan)

| Skill (id) | Type, Lv | Moves: startup / active / recovery, damage, reach (px) | Mechanics |
|---|---|---|---|
| Light chain | basic | `brawler_left` 5/3/10, 6, 4..36<br>`brawler_right` 6/3/12, 8, 4..38<br>`brawler_swing` 8/5/19, 12, 0..40 | brawler_swing: knockdown |
| Heavy (`brawler_hammer`) | basic | `brawler_hammer` 14/5/22, 18, 2..42 | brawler_hammer: guard break, knockdown, armour |
| Rapid Punch (`rapid_punch`) | active, 1 | `rapid_punch_1` 3/3/5, 6, 4..36<br>`rapid_punch_2` 3/3/5, 6, 4..36<br>`rapid_punch_3` 3/3/5, 6, 4..36<br>`rapid_punch_4` 4/3/14, 8, 4..38 | – |
| Double Smash (`double_smash`) | active, 2 | `double_smash_1` 8/4/8, 16, 4..38<br>`double_smash_2` 7/4/20, 18, 4..40 | double_smash_2: knockdown, armour |
| Wide Swing (`wide_swing`) | active, 3 | `wide_swing` 8/6/20, 26, -10..46 | wide_swing: AoE, knockdown |
| Ground Pound (`ground_pound`) | active, 5 | `ground_pound` 14/6/24, 32, -50..50 | ground_pound: AoE, guard break, knockdown, OTG |
| Brutal Rush (`brutal_rush`) | active, 15 | `brutal_rush_1` 5/5/4, 12, 0..30<br>`brutal_rush_2` 3/5/4, 12, 0..30<br>`brutal_rush_3` 4/6/20, 16, 0..32 | brutal_rush_1: step +40 px<br>brutal_rush_2: step +40 px<br>brutal_rush_3: guard break, knockdown, step +40 px |
| Backhand Smash (`backhand_smash`) | active, 30 | `backhand_smash` 10/6/22, 40, -44..44 | backhand_smash: AoE, knockdown, armour |
| Pain Resistance (`pain_resistance`) | passive, 10 | – | While attacking, blows that land on you deal 20% less damage. They still stagger. |
| Crushing Momentum (`berserk_momentum`) | passive, 25 | – | Each blow landed adds 4% damage and makes your blows on a raised guard drain 15% more of its energy, for 4 seconds, up to five times: once a Brawler gets going, guarding only delays the inevitable. |
| STREET CARNAGE (`street_carnage`) | ultimate, 50 | `carnage_1` 30/5/6, 16, -50..50<br>`carnage_2` 5/5/6, 16, -50..50<br>`carnage_3` 5/5/6, 16, -50..50<br>`carnage_punch` 8/5/10, 30, 0..40<br>`carnage_smash` 14/6/28, 36, -70..70 | carnage_1: AoE, armour<br>carnage_2: AoE, armour<br>carnage_3: AoE, armour<br>carnage_punch: guard break, step +40 px<br>carnage_smash: AoE, guard break, knockdown |

### Grappler (Oren)

| Skill (id) | Type, Lv | Moves: startup / active / recovery, damage, reach (px) | Mechanics |
|---|---|---|---|
| Light chain | basic | `grappler_short` 4/3/9, 9, 6..36<br>`grappler_heavy` 5/3/11, 12, 6..38<br>`grappler_push` 7/4/18, 18, 4..38 | grappler_push: knockdown |
| Heavy (`grappler_collar_tie`) | basic | `grappler_collar_tie` 9/4/14, 10, 2..28<br>`grappler_push` 7/4/18, 18, 4..38 | grappler_push: knockdown |
| Iron Grip (`iron_grip`) | active, 1 | `iron_grip` 6/5/18, 0, 2..32 | iron_grip: grab, step +50 px |
| Power Throw (`power_throw`) | active, 2 | `power_throw_grab` 6/5/18, 0, 2..32<br>`power_throw_hit` 1/1/1, 39, 0..1<br>`power_throw_crash` 1/1/1, 23, 0..1<br>`power_throw_shove` 1/1/1, 20, 0..1 | power_throw_grab: grab, step +20 px<br>power_throw_hit: knockdown, throw<br>power_throw_crash: knockdown, throw |
| Backbreaker (`backbreaker`) | active, 3 | `backbreaker_grab` 6/5/18, 0, 2..32<br>`backbreaker_hit` 1/1/1, 44, 0..1<br>`backbreaker_shove` 1/1/1, 30, 0..1 | backbreaker_grab: grab, step +20 px<br>backbreaker_hit: knockdown, throw |
| Ground Slam (`ground_slam`) | active, 5 | `ground_slam_grab` 6/5/18, 0, 2..32<br>`ground_slam_wave` 2/5/24, 22, -50..50<br>`ground_slam_hit` 1/1/1, 36, 0..1<br>`ground_slam_shove` 1/1/1, 22, 0..1 | ground_slam_grab: grab, step +20 px<br>ground_slam_wave: AoE, knockdown, OTG, throw<br>ground_slam_hit: knockdown, throw |
| Crowd Toss (`crowd_toss`) | active, 15 | `crowd_toss_grab` 6/5/18, 0, 2..32<br>`crowd_toss_hit` 1/1/1, 31, 0..1<br>`crowd_toss_crash` 1/1/1, 39, 0..1<br>`crowd_toss_shove` 1/1/1, 22, 0..1 | crowd_toss_grab: grab, step +20 px<br>crowd_toss_hit: knockdown, throw<br>crowd_toss_crash: knockdown, throw |
| Crushing Hold (`crushing_hold`) | active, 30 | `crushing_hold_grab` 6/5/18, 0, 2..32<br>`crushing_hold_drop` 1/1/1, 14, 0..1<br>`crushing_hold_squeeze` 1/1/1, 9, 0..1<br>`crushing_hold_shove` 1/1/1, 34, 0..1 | crushing_hold_grab: grab, step +20 px<br>crushing_hold_drop: knockdown, throw<br>crushing_hold_squeeze: throw |
| Unbreakable Hold (`unbreakable_hold`) | passive, 10 | – | Your grabs hold ordinary foes 40% longer. Bosses and mini-bosses still cannot be held, and nobody can be grabbed twice in a row. |
| Heavy Impact (`heavy_impact`) | passive, 25 | – | Throws, slams and thrown bodies deal 15% more damage. |
| TITAN DESTRUCTION (`titan_destruction`) | ultimate, 50 | `titan_grab` 28/5/18, 0, 2..36<br>`titan_wave` 2/6/30, 36, -80..80<br>`titan_slam` 1/1/1, 90, 0..1<br>`titan_crash` 1/1/1, 30, 0..1<br>`titan_shove` 1/1/1, 60, 0..1 | titan_grab: grab, step +70 px<br>titan_wave: AoE, guard break, knockdown, throw<br>titan_slam: knockdown, throw<br>titan_crash: knockdown, throw |

### Counter Fighter (Dao)

| Skill (id) | Type, Lv | Moves: startup / active / recovery, damage, reach (px) | Mechanics |
|---|---|---|---|
| Light chain | basic | `counter_quick` 4/3/10, 5, 6..36<br>`counter_punch` 5/3/14, 7, 6..38<br>`counter_heavy` 8/4/18, 11, 4..38 | counter_heavy: knockdown |
| Heavy (`counter_check_hook`) | basic | `counter_check_hook` 9/3/16, 11, 4..38 | counter_check_hook: untouchable, step -16 px |
| Quick Counter (`quick_counter`) | active, 1 | `quick_counter_stance` 2/16/14, 0, 0..1<br>`quick_counter_hit` 3/4/14, 22, 4..38 | quick_counter_stance: counter stance<br>quick_counter_hit: step +24 px |
| Slip Punch (`slip_punch`) | active, 2 | `slip_punch` 8/4/16, 28, 0..30 | slip_punch: untouchable, step +30 px |
| Precision Blow (`precision_blow`) | active, 3 | `precision_blow` 6/4/18, 26, 4..36 | – |
| Defensive Stance (`defensive_stance`) | active, 5 | `defensive_stance` 2/1/10, 0, 0..1 | – |
| Perfect Parry (`perfect_parry`) | active, 15 | `perfect_parry_stance` 1/10/16, 0, 0..1<br>`perfect_parry_hit` 3/4/12, 18, 4..38 | perfect_parry_stance: catches all, counter stance<br>perfect_parry_hit: step +24 px |
| Reversal Strike (`reversal_strike`) | active, 30 | `reversal_stance` 3/22/22, 0, 0..1<br>`reversal_hit` 4/4/22, 52, -44..48 | reversal_stance: counter stance<br>reversal_hit: AoE, guard break, knockdown, step +24 px |
| Combat Awareness (`combat_awareness`) | passive, 10 | – | Your perfect guard opens 4 ticks earlier, so parries are easier to time. |
| Retaliation (`retaliation`) | passive, 25 | – | Each parry or caught blow stores power (up to 2): your next counter hit deals 25% more damage for each. |
| ABSOLUTE RETRIBUTION (`absolute_retribution`) | ultimate, 50 | `retribution_stance` 12/60/30, 0, 0..1<br>`retribution_1` 3/4/6, 28, -50..50<br>`retribution_2` 3/4/6, 28, -50..50<br>`retribution_blow` 9/4/28, 60, 4..42 | retribution_stance: counter stance<br>retribution_1: AoE, step +24 px<br>retribution_2: AoE<br>retribution_blow: guard break, knockdown |

### Street Striker (Mika)

| Skill (id) | Type, Lv | Moves: startup / active / recovery, damage, reach (px) | Mechanics |
|---|---|---|---|
| Light chain | basic | `striker_jab` 3/3/7, 5, 6..36<br>`striker_cross` 4/3/8, 6, 6..38<br>`striker_rapid` 3/3/7, 5, 6..36<br>`striker_finisher` 6/4/16, 10, 4..38 | striker_finisher: knockdown |
| Heavy (`striker_spin_backfist`) | basic | `striker_spin_backfist` 9/5/15, 10, -30..36 | striker_spin_backfist: AoE, step +10 px |
| Quick Jab (`quick_jab`) | active, 1 | `quick_jab` 3/3/8, 14, 6..38 | – |
| Triple Punch (`triple_punch`) | active, 2 | `triple_punch_1` 3/3/5, 8, 6..38<br>`triple_punch_2` 3/3/5, 8, 6..38<br>`triple_punch_3` 4/3/14, 12, 6..40 | triple_punch_3: knockdown |
| Rush Combo (`rush_combo`) | active, 3 | `rush_combo_1` 4/4/3, 7, 0..34<br>`rush_combo_2` 2/4/3, 7, 0..34<br>`rush_combo_3` 2/4/3, 7, 0..34<br>`rush_combo_4` 4/5/18, 12, -26..36 | rush_combo_1: step +25 px<br>rush_combo_2: step +25 px<br>rush_combo_3: step +25 px<br>rush_combo_4: AoE, knockdown, step +20 px |
| Rising Fist (`rising_fist`) | active, 5 | `rising_fist` 5/4/18, 30, 4..34 | rising_fist: knockdown |
| Dash Strike (`dash_strike`) | active, 15 | `dash_strike` 5/8/16, 30, -24..28 | dash_strike: AoE, guard break, step +90 px |
| Chain Breaker (`chain_breaker`) | active, 30 | `chain_breaker` 8/4/22, 44, 0..36 | chain_breaker: knockdown, OTG, step +60 px |
| Flow State (`flow_state`) | passive, 10 | – | Each blow landed adds 4% attack speed for 3 seconds, up to 20%. |
| Slipstream (`combo_mastery`) | passive, 25 | – | Dodges cost 40% less energy, and any blow that lands can be cancelled into a dodge: hit, then slip away or around the foe. |
| MILLION FIST ONSLAUGHT (`million_fist_onslaught`) | ultimate, 50 | `onslaught_dash` 26/6/3, 8, -24..28<br>`onslaught_1` 2/2/3, 9, 4..38<br>`onslaught_2` 2/2/3, 9, 2..36<br>`onslaught_3` 2/2/3, 9, 4..38<br>`onslaught_4` 2/2/3, 9, 2..36<br>`onslaught_5` 2/2/3, 9, 4..38<br>`onslaught_6` 2/2/3, 9, 2..36<br>`onslaught_blow` 9/4/28, 46, -44..44 | onslaught_dash: AoE, step +70 px<br>onslaught_1: step +3 px<br>onslaught_2: step +3 px<br>onslaught_3: step +3 px<br>onslaught_4: step +3 px<br>onslaught_5: step +3 px<br>onslaught_6: step +3 px<br>onslaught_blow: AoE, guard break, knockdown |

## 2. สกิลที่คงไว้

คงไว้ทั้งกลไกและตัวเลข เพราะทำงานดีและไม่ซ้ำอาชีพอื่นอยู่แล้ว (บางตัวได้แค่ "ต่อเบสิกหลังสกิล" เพิ่ม):

| อาชีพ | สกิลที่คงไว้ |
|---|---|
| Boxer | Power Jab (+ต่อหมัดตรง), Critical Focus |
| Brawler | Rapid Punch (+ต่อ Hammer Fist), Wide Swing, Brutal Rush, Pain Resistance |
| Grappler | Iron Grip, Power Throw, Backbreaker, Crowd Toss, Crushing Hold, Unbreakable Hold, Heavy Impact (และ PvE ×1.3 ทั้ง 6 สกิล) |
| Counter Fighter | Quick Counter, Slip Punch (+ต่อหมัด), Precision Blow (+ต่อ Check Hook), Defensive Stance, Combat Awareness, Retaliation |
| Street Striker | Quick Jab (+ต่อหมัดตรง), Triple Punch (+ต่อแย็บ), Rush Combo, Rising Fist (+ต่อ Spinning Backfist), Flow State |

## 3. สกิลที่ออกแบบใหม่

| อาชีพ | สกิล | เดิม | ใหม่ (รอบ) |
|---|---|---|---|
| ทุกอาชีพ | ท่าหนัก | ใช้ `haymaker` ตัวเดียวกันทั้ง 5 อาชีพ | ท่าหนักของตัวเองทุกอาชีพ (รอบ 1) |
| ทุกอาชีพ | คลิปเบา/หนัก | คลิปเดียวกันทุกตัวละคร | Kan, Oren, Dao, Mika มีคลิปเบาและหนักของตัวเอง Riku ใช้คลิปฐาน (รอบ 2) |
| Boxer | Heavy Cross, Uppercut | ยืนชก | ก้าวเข้าชก 14 / 8 px (รอบ 2) |
| Boxer | Body Blow | ทำลายการ์ด | ดูดพลังงาน 35 ก้าวเข้า 12 px ไม่ทำลายการ์ด (รอบ 2) |
| Boxer | Counter Punch → **Slip Counter** | ท่าตั้งรับ (ซ้ำแนวกับ Counter Fighter) | มุดหลบ ไม่โดนตี 12 tick แล้วสวนทันที ใช้ได้ไม่ว่าอีกฝ่ายจะตีหรือไม่ (รอบ 2) |
| Boxer | Knockout Combo | ชกหน้าอย่างเดียว | ส่ายตัวชกหลังและสองข้าง เป็นสกิลวงกว้าง (รอบ 1) |
| Boxer | Precision Impact → **Combination Puncher** | +12% ดาเมจท่าปิด | ทุกลิงก์คอมโบที่ติด ลดคูลดาวน์สกิลอื่น 45 tick (รอบ 2) |
| Brawler | Double Smash, Backhand Smash | ไม่มีเกราะ | ท่าที่สอง/ท่าทั้งท่ามีเกราะ (รอบ 1) |
| Brawler | Ground Pound | วงกว้าง | + ตีคนที่ล้มอยู่ได้ (OTG) (รอบ 2) |
| Brawler | Berserk Momentum → **Crushing Momentum** | +4% ดาเมจต่อหมัด สูงสุด 5 | +4% ดาเมจ และ +15% ทำลายการ์ดต่อหมัด สูงสุด 5 (รอบ 2) |
| Brawler | Street Carnage | ไม่มีเกราะ คลิปทั่วไป | สามระลอกรอบตัวมีเกราะ + คลิป `brawler_ultimate` (รอบ 1–2) |
| Grappler | Ground Slam | ทุ่มแล้วจบ | คลื่นโดนทุกคนรอบตัวรวมคนที่ล้ม แล้วต่อเบสิกได้ (รอบ 1–2) |
| Grappler | Titan Destruction | คลิปทั่วไป | คลื่นใช้คลิป `grappler_ultimate` (รอบ 1) |
| Counter Fighter | Perfect Parry | รับไม่ได้กับท่าทำลายการ์ด | รับได้ทุกอย่างจากด้านหน้า (`catch_all`) หน้าต่างสั้นที่สุด (รอบ 2) |
| Counter Fighter | Reversal Strike | สวนหน้าอย่างเดียว | หมุนสวนโดนทุกคนรอบตัว ทำลายการ์ด ล้ม (รอบ 1) |
| Counter Fighter | Absolute Retribution | ห้าหมัด (คล้ายของ Boxer) | สองระลอกหมุนรอบตัว แล้วหมัดปิด (รอบ 2) |
| Street Striker | Dash Strike | พุ่งชนคนเดียว | พุ่งทะลุฝูง ตีทั้งทาง (รอบ 1) |
| Street Striker | Chain Breaker | หมัดปิดอยู่กับที่ | พุ่งตาม 60 px ตีคนที่ล้มได้ (รอบ 2) |
| Street Striker | Million Fist Onslaught | 12 หมัดตรง | พุ่งทะลุ, รัวหกหมัด, ปิดด้วยหมัดหมุนรอบตัว (รอบ 2) |
| Street Striker | Combo Mastery → **Slipstream** | สะสมดาเมจให้สกิลถัดไป | หลบถูกลง 40% และหลบยกเลิกท่าได้หลังตีโดน (รอบ 2) |

id ของพาสซีฟที่เปลี่ยนชื่อยังเป็น id เดิม (`precision_impact`, `berserk_momentum`, `combo_mastery`)
เพื่อไม่ให้เซฟเดิมพัง

## 4. สิ่งที่ยังไม่ได้ทำ

- **แอนิเมชันวาดใหม่ด้วยมือ:** ทุกคลิปประกอบจากเฟรม LPC ที่ตัวละครใช้อยู่ (เลือกเฟรม เรียงใหม่
  ยืมเฟรมจากท่าอื่นและจากมุมหน้า/หลัง) ไม่ได้วาดเฟรมใหม่ และสกิลส่วนใหญ่เล่นคลิปเบา/หนักของอาชีพตัวเอง
  มีแค่ท่าเอกลักษณ์ที่มีคลิปเฉพาะ (ดูข้อ 7)
- **Launcher → ต่อกลางอากาศ (juggle):** เกมไม่มีระบบลอยกลางอากาศสำหรับฮีโร่ (มีแค่ร่างที่ถูกทุ่มลอย)
  ผมทำ "ล้มแล้วตีต่อ" (OTG) แทน ระบบ juggle เป็นงานออกแบบใหญ่ที่ควรให้เจ้าของตัดสินก่อน
- **Defensive Stance** ยังเป็นบัฟป้องกันแบบเดิม (ไม่ได้ออกแบบใหม่)
- **การทดสอบกับผู้เล่นจริง:** ตัวเลข PvP ทั้งหมดเป็น AI ปะทะ AI

## 5. Ultimate ทั้งห้า

ดาเมจคือดาเมจฐานของท่าในข้อมูล (ก่อนพลังและเกราะ) PvP คูณ 0.5 ทุกตัว ทุกตัวเติมเกจเต็มก่อนใช้

| | Boxer | Brawler | Grappler | Counter Fighter | Street Striker |
|---|---|---|---|---|---|
| Skill ID | `knockout_devastation` | `street_carnage` | `titan_destruction` | `absolute_retribution` | `million_fist_onslaught` |
| คลิปเฉพาะ | `boxer_ultimate` | `brawler_ultimate` | `grappler_ultimate` | `counter_whirl`, `counter_ultimate` | `striker_dash`, `striker_ultimate` |
| ลำดับ | พุ่ง 60 px (เตือน 28 tick) → 4 หมัดเร็ว → หมัดน็อกทำลายการ์ด → คลื่นกระแทกสองทาง ล้ม | 3 ระลอกรอบตัวมีเกราะ → หมัดพุ่ง 40 px ทำลายการ์ด → ทุบพื้น -70..70 ล้ม | พุ่งคว้า 70 px (เตือน 28 tick) → ทุ่ม 90 ใส่คนที่คว้า, ร่างชนคนอื่น 30 → คลื่น -80..80 ทำลายการ์ด ล้ม | ตั้งการ์ดสมบูรณ์ 60 tick → ถ้ารับหมัดจากหน้าได้: 2 ระลอกหมุนรอบตัว → หมัดปิด 60 ทำลายการ์ด ล้ม | พุ่งทะลุ 70 px → 6 หมัดรัว (startup 2) → หมัดหมุนรอบตัว -44..44 ทำลายการ์ด ล้ม |
| ดาเมจรวมบนเป้าหลัก | 136 | 114 | 90 + 36 | 116 | 108 |
| เอกลักษณ์ | คอมโบตรงเข้าเป้าเดียว ปิดด้วยแรงกระแทกสองทาง | ตีไม่ขาด ขัดด้วยมอนสเตอร์ไม่ได้ ใช้กลางฝูง | อันเดียวที่เป็นการคว้า: การ์ดกันไม่ได้, กับบอสกลายเป็นผลัก 60 | อันเดียวที่ต้อง "รับ" ก่อน ถ้าไม่มีใครตีเกจเสียเปล่า | เคลื่อนที่มากที่สุด ตีมากครั้งที่สุด (8) |
| ต่างจากอีกสี่อย่างไร | เป้าเดียว เคลื่อนตรง | อยู่กับที่ ตีรอบตัว มีเกราะ | คว้า + ทุ่ม + คลื่น | สวนกลับ | พุ่งทะลุ + รัว |

ที่ซ้ำกันและแก้แล้ว:
- **รอบ 1:** หมัดหนึ่งใน Ultimate ของ Counter Fighter เป็นสำเนาหมัดของ Boxer
- **รอบ 2:** Absolute Retribution เดิมเป็นห้าหมัดรัว ซึ่งรูปแบบเดียวกับ Knockout Devastation จึงเปลี่ยนเป็นระลอกหมุนรอบตัว
- **รอบ 2:** Million Fist มีหมัดสลับหน้าหลัง ทำให้โดนเป้าเดียวแค่ครึ่ง จึงเปลี่ยนเป็นหมัดหน้าทั้งหมด
  แล้วให้วงกว้างมาจากการพุ่งทะลุและหมัดหมุนปิด

Registry ตอนนี้ปฏิเสธ Ultimate ที่ไม่มีคลิปของตัวเอง และ Ultimate สองตัวที่ใช้คลิปเดียวกัน
(`test_two_ultimates_sharing_an_animation_are_refused`) และทุก Ultimate ไม่มีท่าใดซ้ำกัน

## 6. เส้นทางคอมโบ

**กลไกกลาง** (ทุกอาชีพใช้ร่วมกัน ค่าใน `CombatRules`):

| ส่วน | ค่า |
|---|---|
| Input buffer | กดล่วงหน้าได้ 12 tick ก่อนท่าจบ |
| Cancel window | หลังหมัดโดน (hit confirm) และช่วงตีจบแล้ว: เบสิก→เบสิก, เบสิก→สกิล, สกิล→สกิล, สกิล→เบสิก |
| ตีวืด | ยกเลิกไม่ได้ ต้องรอ recovery เต็ม |
| Recovery | ของแต่ละท่า (ตารางข้อ 1) |
| Combo scaling | PvP: หมัดที่ 4 เป็นต้นไปบนคนที่ยังเซ ลด 10% ต่อหมัด ต่ำสุด 50% / PvE ไม่ลด |
| กันล็อกตาย | ฮีโร่: hitstun ต่อเนื่องสูงสุด 40 tick, ลุกขึ้นแล้วอมตะ 36 tick |
| เส้นคอมโบ | ใช้ลิงก์ตามลำดับภายใน window, ท่าปิดได้ดาเมจโบนัส + เกจ; โดนตีหรือตีวืดตัดเส้น |

**เส้นของแต่ละอาชีพ** (`heavy`/`light` คือหมัดเบา/หนักของอาชีพนั้น):

| อาชีพ | เส้น | ลิงก์ | Lv | window | โบนัสท่าปิด | เกจ |
|---|---|---|---|---|---|---|
| Boxer | One-Two | Power Jab → Heavy Cross | 3 | 120 | +70% | 8 |
| Boxer | Overhand Setup | heavy (Overhand) → Body Blow → Uppercut | 5 | 120 | +50% | 10 |
| Boxer | Knockout Sequence | Body Blow → Power Jab → Knockout Combo | 30 | 120 | +30% | 15 |
| Brawler | Hammer Time | Rapid Punch → Double Smash | 3 | 120 | +60% | 8 |
| Brawler | Hammer and Anvil | heavy (Hammer Fist) → Ground Pound (OTG) | 5 | 120 | +50% | 8 |
| Brawler | Street Riot | Rapid Punch → Brutal Rush → Backhand Smash | 30 | 120 | +85% | 15 |
| Grappler | Collar and Throw | heavy (Collar Tie) → Power Throw | 2 | 120 | +40% | 8 |
| Grappler | Lift and Drop | Iron Grip → Backbreaker | 3 | 180 | +30% | 8 |
| Grappler | Wrecking Crew | Power Throw → Crowd Toss → Crushing Hold | 30 | 180 | +40% | 15 |
| Counter Fighter | Slip and Punish | Slip Punch → Precision Blow | 3 | 120 | +35% | 8 |
| Counter Fighter | Check and Punish | light → Slip Punch → Precision Blow | 3 | 120 | +60% | 10 |
| Counter Fighter | Perfect Retort | Perfect Parry → Slip Punch → Precision Blow | 30 | 120 | +100% | 15 |
| Street Striker | Flurry | Quick Jab → Triple Punch | 3 | 120 | +100% | 8 |
| Street Striker | Rise and Chase | light → Rising Fist → Chain Breaker (OTG) | 30 | 120 | +60% | 15 |
| Street Striker | Chain Reaction | Quick Jab → Dash Strike → Chain Breaker | 30 | 120 | +90% | 15 |

PvP โบนัสท่าปิดครึ่งหนึ่ง (โปรไฟล์ของเส้น)

**ทุกชนิดการต่อที่ขอ:**

| ชนิด | Boxer | Brawler | Grappler | Counter Fighter | Street Striker |
|---|---|---|---|---|---|
| เบสิก→เบสิก | jab → straight → heavy | left → right → swing | short → heavy → push | quick → punch → heavy | jab → cross → rapid → finisher |
| เบสิก→ท่าหนัก | ทุกหมัดเบา → Overhand → Shovel Hook | → Hammer Fist | → Collar Tie → push | → Check Hook | → Spinning Backfist |
| เบสิก→สกิล | ทุกอาชีพ: ยกเลิก recovery หลังหมัดโดน | | | | |
| สกิล→เบสิก | Power Jab → straight, Body Blow → Overhand | Rapid Punch → Hammer, Double Smash → left | Ground Slam → short | Slip Punch → punch, Precision Blow → Check Hook | Quick Jab → cross, Triple Punch → jab, Rising Fist → Backfist |
| สกิล→สกิล | ทุกเส้นคอมโบ | | | | |
| ป้องกัน→สวน | Slip Counter | (เกราะ: ตีทะลุ) | – | Quick Counter, Perfect Parry, Reversal Strike, Absolute Retribution | Slipstream: ตีโดนแล้วหลบ |
| คว้า→ทุ่ม→ต่อ | คว้าพื้นฐาน | คว้าพื้นฐาน | ทุก grab skill, Ground Slam → คลื่น → เบสิก, Collar and Throw | คว้าพื้นฐาน | คว้าพื้นฐาน |
| ล้ม→ตีต่อ (OTG) | – | Hammer Fist → Ground Pound | ทุ่ม → คลื่น Ground Slam | – | Rising Fist → Chain Breaker |

Boxer และ Counter Fighter ไม่มีท่า OTG โดยตั้งใจ: Boxer เน้นชกคนที่ยืนอยู่ และ Counter Fighter รอให้อีกฝ่ายเข้ามา

ทุก 15 เส้นจบได้จริงโดยผู้เล่นจำลอง (`test_every_route_can_be_completed_by_a_player`)
และ auto battle ใช้ได้ (PvE 27 นาทีต่อคน, ครั้งที่จบเส้น):
- Oren: Lift and Drop 134, Wrecking Crew 7, Collar and Throw 5;
- Riku: One-Two 92;
- Kan: Hammer Time 104;
- Dao: Check and Punish 47, Slip and Punish 42;
- Mika: Flurry 125

## 7. แอนิเมชันของทุกสกิล

แต่ละฮีโร่มีชีตของตัวเอง ดังนั้น `light`/`heavy` ของ Kan คือคลิปของ Kan ไม่ใช่ของ Riku
ท่าที่ไม่มี anim จะเล่นคลิป `light` ทุกท่าที่อาชีพใช้มีอยู่ในชีตของฮีโร่ทุกชุดเกราะ
(`test_every_class_move_plays_an_animation_its_hero_draws`)

| Class | Skill | Move → animation | Matches the gameplay? | Why this clip |
|---|---|---|---|---|
| Boxer | Light chain | `boxer_jab`→light<br>`boxer_straight`→light<br>`boxer_heavy`→`heavy` | yes | plays the class's own light clip (each hero sheet has its own); the class's own heavy clip (each hero sheet has its own) |
| Boxer | Heavy | `boxer_overhand`→`boxer_overhand`<br>`boxer_shovel_hook`→`heavy` | yes | own class clip `boxer_overhand` |
| Boxer | Power Jab | `power_jab`→light | yes | plays the class's own light clip (each hero sheet has its own) |
| Boxer | Heavy Cross | `heavy_cross`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Boxer | Uppercut | `uppercut`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Boxer | Body Blow | `body_blow`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Boxer | Slip Counter | `boxer_slip`→`boxer_weave`<br>`boxer_counter_hit`→`heavy` | yes | own class clip `boxer_weave` |
| Boxer | Knockout Combo | `ko_combo_1`→light<br>`ko_combo_2`→`boxer_weave`<br>`ko_combo_3`→`boxer_weave`<br>`ko_combo_4`→`heavy` | yes | own class clip `boxer_weave` |
| Boxer | KNOCKOUT DEVASTATION | `ko_dev_lunge`→`heavy`<br>`ko_dev_1`→light<br>`ko_dev_2`→light<br>`ko_dev_3`→light<br>`ko_dev_4`→`heavy`<br>`ko_dev_blow`→`boxer_ultimate`<br>`ko_dev_shock`→`boxer_weave` | yes | own class clip `boxer_ultimate`, `boxer_weave` |
| Brawler | Light chain | `brawler_left`→light<br>`brawler_right`→light<br>`brawler_swing`→`heavy` | yes | plays the class's own light clip (each hero sheet has its own); the class's own heavy clip (each hero sheet has its own) |
| Brawler | Heavy | `brawler_hammer`→`brawler_hammer` | yes | own class clip `brawler_hammer` |
| Brawler | Rapid Punch | `rapid_punch_1`→light<br>`rapid_punch_2`→light<br>`rapid_punch_3`→light<br>`rapid_punch_4`→light | yes | plays the class's own light clip (each hero sheet has its own) |
| Brawler | Double Smash | `double_smash_1`→`heavy`<br>`double_smash_2`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Brawler | Wide Swing | `wide_swing`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Brawler | Ground Pound | `ground_pound`→`brawler_pound` | yes | own class clip `brawler_pound` |
| Brawler | Brutal Rush | `brutal_rush_1`→`heavy`<br>`brutal_rush_2`→`heavy`<br>`brutal_rush_3`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Brawler | Backhand Smash | `backhand_smash`→`brawler_whirl` | yes | own class clip `brawler_whirl` |
| Brawler | STREET CARNAGE | `carnage_1`→`brawler_whirl`<br>`carnage_2`→`brawler_whirl`<br>`carnage_3`→`brawler_whirl`<br>`carnage_punch`→`heavy`<br>`carnage_smash`→`brawler_ultimate` | yes | own class clip `brawler_whirl`, `brawler_ultimate` |
| Grappler | Light chain | `grappler_short`→light<br>`grappler_heavy`→light<br>`grappler_push`→light | yes (a two-hand shove on the thrust clip) | plays the class's own light clip (each hero sheet has its own) |
| Grappler | Heavy | `grappler_collar_tie`→`grappler_clinch`<br>`grappler_push`→light | yes (a two-hand shove on the thrust clip) | own class clip `grappler_clinch` |
| Grappler | Iron Grip | `iron_grip`→`grab` | yes | the engine grab every class shares |
| Grappler | Power Throw | `power_throw_grab`→`grab`<br>`power_throw_hit`→(throw: the holder plays `throw`)<br>`power_throw_crash`→(throw: the holder plays `throw`) | yes | the engine grab every class shares |
| Grappler | Backbreaker | `backbreaker_grab`→`grab`<br>`backbreaker_hit`→(throw: the holder plays `throw`) | yes | the engine grab every class shares |
| Grappler | Ground Slam | `ground_slam_grab`→`grab`<br>`ground_slam_wave`→`grappler_slam`<br>`ground_slam_hit`→(throw: the holder plays `throw`) | yes | own class clip `grappler_slam` |
| Grappler | Crowd Toss | `crowd_toss_grab`→`grab`<br>`crowd_toss_hit`→(throw: the holder plays `throw`)<br>`crowd_toss_crash`→(throw: the holder plays `throw`) | yes | the engine grab every class shares |
| Grappler | Crushing Hold | `crushing_hold_grab`→`grab`<br>`crushing_hold_drop`→(throw: the holder plays `throw`)<br>`crushing_hold_squeeze`→(throw: the holder plays `throw`) | yes | the engine grab every class shares |
| Grappler | TITAN DESTRUCTION | `titan_grab`→`grab`<br>`titan_wave`→`grappler_ultimate`<br>`titan_slam`→(throw: the holder plays `throw`)<br>`titan_crash`→(throw: the holder plays `throw`) | yes | own class clip `grappler_ultimate` |
| Counter Fighter | Light chain | `counter_quick`→light<br>`counter_punch`→light<br>`counter_heavy`→`heavy` | yes | plays the class's own light clip (each hero sheet has its own); the class's own heavy clip (each hero sheet has its own) |
| Counter Fighter | Heavy | `counter_check_hook`→`counter_check` | yes | own class clip `counter_check` |
| Counter Fighter | Quick Counter | `quick_counter_stance`→`stance`<br>`quick_counter_hit`→light | yes | plays the class's own light clip (each hero sheet has its own); the guard pose every stance uses (Dao's own) |
| Counter Fighter | Slip Punch | `slip_punch`→light | yes | plays the class's own light clip (each hero sheet has its own) |
| Counter Fighter | Precision Blow | `precision_blow`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Counter Fighter | Defensive Stance | `defensive_stance`→`stance` | yes | the guard pose every stance uses (Dao's own) |
| Counter Fighter | Perfect Parry | `perfect_parry_stance`→`stance`<br>`perfect_parry_hit`→light | yes | plays the class's own light clip (each hero sheet has its own); the guard pose every stance uses (Dao's own) |
| Counter Fighter | Reversal Strike | `reversal_stance`→`stance`<br>`reversal_hit`→`counter_whirl` | yes | own class clip `counter_whirl` |
| Counter Fighter | ABSOLUTE RETRIBUTION | `retribution_stance`→`stance`<br>`retribution_1`→`counter_whirl`<br>`retribution_2`→`counter_whirl`<br>`retribution_blow`→`counter_ultimate` | yes | own class clip `counter_whirl`, `counter_ultimate` |
| Street Striker | Light chain | `striker_jab`→light<br>`striker_cross`→light<br>`striker_rapid`→light<br>`striker_finisher`→light | yes | plays the class's own light clip (each hero sheet has its own) |
| Street Striker | Heavy | `striker_spin_backfist`→`striker_spin` | yes | own class clip `striker_spin` |
| Street Striker | Quick Jab | `quick_jab`→light | yes | plays the class's own light clip (each hero sheet has its own) |
| Street Striker | Triple Punch | `triple_punch_1`→light<br>`triple_punch_2`→light<br>`triple_punch_3`→light | yes | plays the class's own light clip (each hero sheet has its own) |
| Street Striker | Rush Combo | `rush_combo_1`→light<br>`rush_combo_2`→light<br>`rush_combo_3`→light<br>`rush_combo_4`→`striker_spin` | yes | own class clip `striker_spin` |
| Street Striker | Rising Fist | `rising_fist`→`heavy` | yes | the class's own heavy clip (each hero sheet has its own) |
| Street Striker | Dash Strike | `dash_strike`→`striker_dash` | yes | own class clip `striker_dash` |
| Street Striker | Chain Breaker | `chain_breaker`→`striker_dash` | yes | own class clip `striker_dash` |
| Street Striker | MILLION FIST ONSLAUGHT | `onslaught_dash`→`striker_dash`<br>`onslaught_1`→light<br>`onslaught_2`→light<br>`onslaught_3`→light<br>`onslaught_4`→light<br>`onslaught_5`→light<br>`onslaught_6`→light<br>`onslaught_blow`→`striker_ultimate` | yes | own class clip `striker_dash`, `striker_ultimate` |

ห้าท่าที่รอบสองระบุว่า "ตรงบางส่วน" (Ground Pound, ระลอกของ Street Carnage, คลื่นของ Ground Slam,
คลื่นของ Knockout Devastation, ท่าสุดท้ายของ Rush Combo) แก้แล้วใน Final Polish พร้อมภาพยืนยันในเกม:
[COMBAT_FINAL_REPORT.md](COMBAT_FINAL_REPORT.md) ข้อ 3

## 8. PvP: ตาราง 10 คู่

วิธีวัด:
- บอททั้งสองฝ่าย AI ระดับ 0.3/0.55/0.8 และบุคลิก 6 แบบ สุ่มต่อแมตช์;
- 200 แมตช์ต่อคู่ สลับฝั่งทุกแมตช์ seed 1000 + n × 7919;
- Godforged +0 เลเวล 70;
- คำสั่ง `ArenaBalance.gd --only=jobs_mixed`

ทั้งสองฝ่ายเป็น AI ไม่ใช่อัตราชนะของคนจริง

| A vs B | A ชนะ | B ชนะ | เสมอ | A% | ก่อนสร้างใหม่ (A/B) |
|---|---|---|---|---|---|
| Boxer vs Brawler | 98 | 102 | 0 | 49% | 6/94 |
| Boxer vs Grappler | 88 | 112 | 0 | 44% | – |
| Boxer vs Counter Fighter | 99 | 101 | 0 | 50% | – |
| Boxer vs Street Striker | 105 | 95 | 0 | 52% | 78/22 |
| Brawler vs Grappler | 84 | 116 | 0 | 42% | 11/88 |
| Brawler vs Counter Fighter | 89 | 111 | 0 | 44% | – |
| Brawler vs Street Striker | 102 | 98 | 0 | 51% | – |
| Grappler vs Street Striker | 91 | 108 | 1 | 46% | – |
| Counter Fighter vs Grappler | 116 | 84 | 0 | 58% | – |
| Counter Fighter vs Street Striker | 83 | 117 | 0 | 42% | – |

(คอลัมน์ "ก่อน" คือคู่แพ้ทางขาดสามคู่ที่รายงานรอบแรกระบุไว้)

รวมต่ออาชีพ:

| อาชีพ | ชนะ / 800 | ก่อนสร้างใหม่ | รอบ 1 |
|---|---|---|---|
| Street Striker | 418 (52.2%) | 32% | 50% |
| Counter Fighter | 411 (51.4%) | 69% | 48% |
| Grappler | 403 (50.4%) | 80% | 57% |
| Boxer | 390 (48.8%) | 49% | 51% |
| Brawler | 377 (47.1%) | 19% | 44% |

ไม่มีคู่ไหนสิ้นหวัง (แย่สุด 42%) ผมไม่ได้บังคับให้เป็น 50% ทุกคู่ ยังมีความได้เปรียบตามสไตล์ เช่น:
- Counter Fighter > Grappler: อ่านการคว้าออก;
- Striker > Counter Fighter: เร็วเกินกว่าจะตั้งรับทัน

**วิธีแก้คู่แพ้ทางขาด (กลไก ไม่ใช่แค่ดาเมจ):**

ผมวัดก่อนแก้ทุกครั้ง โดยนับดาเมจทีละท่าในแมตช์จริงด้วยสคริปต์วินิจฉัย:

1. **Brawler ชนะ Boxer 94/6 → 51/49**
   - ต้นเหตุ:
     - (ก) เกราะแบบลบตรงทำให้ jab ของ Boxer ทำดาเมจ 1 และ Power Jab เสียดาเมจ 60%
       ขณะที่ Ground Pound เสียแค่ 35%;
     - (ข) Brawler ตีไกลกว่า 46–50 px เทียบกับหมัด Boxer 30–40 px
       Boxer จึงแทบไม่ได้ใช้ Body Blow (0.5 ครั้งต่อแมตช์);
     - (ค) เกราะ Brawler รับทั้งเชน
   - แก้:
     - PvP คิดเกราะเป็นสัดส่วน defense/(defense+90) (startup/hitbox ไม่เปลี่ยน แต่หมัดเบาไม่สูญ);
     - Heavy Cross, Body Blow, Uppercut ก้าวเข้า 14/12/8 px (ระยะ);
     - เกราะ Brawler รับได้หนึ่งหมัดของฮีโร่ต่อวง (การป้องกัน);
     - Slip Counter ใช้เป็นท่าตอบโต้ได้แม้กับท่าทำลายการ์ด (เคาน์เตอร์)
2. **Grappler ชนะ Brawler 88/11 → 58/42**
   - แก้:
     - ท่าเกราะของ Brawler ถูกคว้าไม่ได้ระหว่างเหวี่ยงลง (grab interaction);
     - PvP ล้มหลังถูกทุ่ม 60 tick และห้ามคว้าซ้ำ 1.5 วินาที (รอบ 1);
     - Crushing Momentum ให้ Brawler ได้แรงจากการต่อหมัด;
     - Grappler PvP กลับเป็น 0.6 เท่าเดิม เพราะเกราะแบบสัดส่วนลดค่าของท่าทุ่มที่หนักครั้งเดียว
3. **Boxer ชนะ Striker 78/22 → 52/48**
   - แก้:
     - เกราะแบบสัดส่วน ทำให้หมัดเบาจำนวนมากของ Striker มีค่า;
     - Slipstream ให้ตีโดนแล้วหลบออกได้ทันที (recovery/การเคลื่อนที่)

**ที่ต้องรายงานตรง ๆ:** กลางรอบนี้ Brawler ตกไปเหลือ 16% เพราะสองอย่างที่ผมทำในรอบสองเอง:
- เปลี่ยนพาสซีฟ Momentum เป็น Guard Crusher อย่างเดียว;
- ให้สกิลใดก็ได้ทำลายเกราะ

ผมหาเจอด้วยการปิดทีละอย่าง แล้วแก้เป็นเกราะรับหนึ่งหมัดต่อวง (เฉพาะ PvP) และรวม Momentum กับ Guard Crusher

ผลข้างเคียงของเกราะแบบสัดส่วน: แมตช์สั้นลงเหลือเฉลี่ย 46–59 วินาที (รอบ 1: 51–76) และจบด้วยน็อก
1999 จาก 2000 แมตช์ ถ้าต้องการจังหวะเดิม ปรับ `hp_scale` ของอารีน่าได้ (ยังไม่ได้แตะ)

ข้อสังเกตเรื่องการวัด: 60 seed แรกต่างจาก 200 seed มาก (Boxer vs Brawler 22–38 ใน 60 แรก แต่ 98–102 ใน 200)
ทุกการตัดสินใจสุดท้ายจึงใช้ 200 แมตช์

## 9. PvE

วิธีวัด: auto battle 3 นาที × 3 seed บนลานเลเวล 9, 29, 50 (27 นาทีต่อคน) นับจำนวนที่ฆ่าได้

| ฮีโร่ | ก่อนสร้างใหม่ (397d21a) | รอบ 1 | ตอนนี้ |
|---|---|---|---|
| Riku (Boxer) | 284 | 282 | 284 |
| Mika (Street Striker) | 237 | 256 | 253 |
| Kan (Brawler) | 239 | 230 | 227 |
| Oren (Grappler) | 221 | 205 | 224 |
| Dao (Counter Fighter) | 201 | 199 | 196 |

**Oren 221 → 205 → 224: วิเคราะห์ด้วยการสลับทีละอย่าง** (Oren อย่างเดียว ค่าอื่นเท่าเดิม):

| การทดลอง | ฆ่า |
|---|---|
| ข้อมูลก่อนสร้างใหม่ + โค้ดปัจจุบัน | 216 |
| ข้อมูลรอบ 1 + โค้ดปัจจุบัน | 199 |
| ข้อมูลรอบ 1 แต่เปลี่ยนแค่ปุ่ม heavy กลับเป็น Haymaker | 200 |
| ข้อมูลรอบ 1 แต่ให้เชนเบาจบด้วย Haymaker (ปุ่ม + chains) | **221** |
| ข้อมูลรอบ 1 แต่ตัด chain ต่อเบสิกหลัง Ground Slam | 198 |
| ข้อมูลปัจจุบัน แต่ปิด OTG ของคลื่น Ground Slam | **204** |
| ข้อมูลปัจจุบัน แต่ตัดเส้น Collar and Throw | 224 |
| ข้อมูลปัจจุบัน แต่ใช้ Haymaker แทน Collar Tie | 207 |
| ข้อมูลปัจจุบัน | **224** |

สรุปสาเหตุ:
- ที่ตกในรอบ 1 เพราะ Collar Tie (ดาเมจ 10 ไม่ล้ม เป็นท่าเปิดให้คว้า) เข้ามาแทน Haymaker
  (ดาเมจสูงและล้ม) ในฐานะ "ท่าปิดเชนเบา";
- auto battle กดท่าหนักเป็นท่าปิดเชนบ่อย ฝูงจึงเคลียร์ช้าลง;
- โค้ดใหม่ไม่ได้เป็นต้นเหตุ (216 อยู่ในช่วงสุ่ม);
- ที่กลับมาในรอบ 2 เพราะคลื่นของ Ground Slam ตีคนที่ล้มอยู่ได้ (OTG) และ Oren ทุ่มให้ศัตรูล้มอยู่ตลอด
  (เปิด 224 ปิด 204);
- ไม่ได้ปรับตัวเลข PvE ใด ๆ ของ Grappler: ×1.3 ทั้ง 6 สกิลยังอยู่ (`profiles.pve.damage` 1.3)

ฮีโร่อื่น:
- **Dao 201 → 196:**
  - เส้นใหม่ Check and Punish เดิมเปิดด้วย Check Hook ซึ่งถอยหลัง แล้วต้องพุ่งกลับ ทำให้ Dao ตกไป 186;
  - ตัดเส้นทิ้งได้ 199 และเปลี่ยนให้เปิดด้วยหมัดเบาได้ 196 จึงใช้แบบหมัดเบา
- **Riku 284 → 284:**
  - การก้าวเข้าชกที่เพิ่มเพื่อ PvP ทำให้ PvE ขึ้นเป็น 306 และถ้าไม่ก้าวเลยตกเป็น 254
    (สกิลรอบสองอื่นลดลง);
  - ผมจึงเพิ่มฟิลด์ `advance` ในโปรไฟล์สกิล PvE ก้าว 60% ได้ 284 เท่าเดิมพอดี PvP ก้าวเต็ม
- **Kan 239 → 227 (-5%):** ลดลงตั้งแต่รอบ 1 (230) และไม่ได้ปรับเพิ่ม เพราะคำสั่งคือห้ามจูน PvE เพื่อ PvP
  ถ้าต้องการให้เท่าเดิม ควรเป็นการตัดสินใจแยก
- **Mika 237 → 253:** ขึ้นตั้งแต่รอบ 1 (256) และคงอยู่ ผมไม่ได้แยกวัดว่ามาจากท่าไหน

**PvP กับ PvE แยกกันอย่างไร:** กติกา PvP ทุกข้อทำงานเฉพาะเมื่อทั้งสองฝ่ายเป็นฮีโร่:
- เกราะแบบสัดส่วน;
- combo scaling;
- ทุ่มล้มสั้น;
- ห้ามคว้าซ้ำ;
- เกราะ Brawler รับหนึ่งหมัด

ส่วนตัวเลขของสกิลแยกด้วย `profiles.pve` / `profiles.pvp` เทสต์ `test_pvp_only_rules_leave_pve_alone` ยืนยัน

บอสและการฟาร์ม: เทสต์บอส (world boss, boss mechanics, break) และ `test_farming_loop`
(auto battle รอดทุกลานที่เลเวลของมัน) ผ่านทั้งหมด

ระหว่างทาง เทสต์ฟาร์มจับปัญหาได้หนึ่งอย่าง:
- กฎใหม่ของผม "ไม่เก็บสกิลรอเส้นคอมโบที่เปิดด้วยหมัด" ทำให้ Oren ใช้ Power Throw เดี่ยว ๆ แล้วถูกน็อกบน
  farm_core_overflow;
- แก้ให้กฎนี้ใช้กับสกิลวงกว้างเท่านั้น

## 10. ผลเทสต์

ทุกรายการรันจริงในเซสชันนี้กับโค้ดชุดสุดท้าย:

| ตรวจ | ผล |
|---|---|
| `gdformat --check`, `gdlint` (client ทั้งหมด) | ผ่าน |
| Godot unit + scene tests (`TestRunner.gd`) | **854 ผ่าน, 0 ล้ม** (exit 0) |
| UI audit (`UiAuditRun.gd`) | 0 ข้อใหม่ (200 ข้อที่รู้อยู่แล้ว) |
| Web export + browser smoke (`smoke.ts`) | ผ่าน (boot, เกมใหม่, คอมโบ, สกิล, อาวุธ, เมนู, เดินทาง, ต่อสู้บนถนน) |
| Asset pipeline (`test_pipeline.py`, 49 tests) + `validate.py` | ผ่าน |
| `check-repo.sh` | ผ่าน |
| gitleaks (ไดเรกทอรีและประวัติ git 214 commits) + ค้นหาคำลับด้วยมือ | ไม่พบความลับ |

เทสต์ที่เพิ่ม/แก้ตามหัวข้อที่ขอ:

| หัวข้อ | เทสต์ |
|---|---|
| สกิลไม่ซ้ำ | `test_no_class_move_is_shared_or_copied` (registry: ก๊อปท่าข้ามอาชีพ, ท่าเปลี่ยนชื่อ) |
| Ultimate ไม่ซ้ำ | `test_every_ultimate_has_its_own_signature_animation`, `test_two_ultimates_sharing_an_animation_are_refused` |
| AoE หลายเป้า | `test_every_class_area_attack_hits_several_foes` (ศัตรู 2 ตัวต่ออาชีพ, ของจริงผ่าน tick) |
| คอมโบเฉพาะอาชีพ + ท่าปิด | `test_every_job_has_an_early_and_a_late_route` (3 เส้น เส้นที่สามเปิดด้วยหมัด จบด้วยสกิล), `test_every_route_can_be_completed_by_a_player` (15 เส้น), `test_the_finisher_hits_harder_and_fills_the_gauge`, `test_a_landed_route_link_refreshes_the_boxers_cooldowns` |
| การต่อ | `test_skill_to_basic_and_basic_to_skill_transitions`, `test_a_whiffed_basic_cannot_be_cancelled`, `test_a_landed_striker_blow_cancels_into_a_dodge`, `test_otg_blows_hit_a_foe_on_the_ground_for_damage_only`, `test_perfect_parry_catches_even_a_guard_breaker`, `test_an_armoured_swing_cannot_be_grabbed_until_it_is_through` |
| แอนิเมชัน | `test_every_class_has_its_own_heavy_and_animations`, `test_every_class_move_plays_an_animation_its_hero_draws`, `test_blows_land_with_the_fist_out` |
| PvP/PvE แยกกัน | `test_pvp_only_rules_leave_pve_alone`, `test_pvp_combos_scale_down_but_monsters_are_never_scaled`, `test_a_throw_keeps_a_hero_down_less_long_in_pvp_only`, `test_pvp_halves_the_bonus_and_pve_keeps_it` |
| สมดุลคู่ต่อสู้ | `test_no_class_pairing_is_hopeless_in_the_arena` (10 คู่ × 20 แมตช์ ฝั่งแพ้ต้องชนะอย่างน้อย 25%) |
| บอสและฟาร์ม | ชุดเดิมทั้งหมด (`test_farming_loop`, world boss, boss mechanics) ผ่าน |

เทสต์เดิมที่แก้ความคาดหวัง (เพราะการออกแบบเปลี่ยน ไม่ใช่เพื่อให้ผ่าน):
- `test_combos` (2 → 3 เส้น);
- `test_jobs` (ชุดสกิลทดลองมีเส้นที่สาม);
- `test_art` (ใช้ Riku ที่ยังเป็นคลิปฐาน);
- `test_weapons` (ใช้คลิป `swing` ของ Oren แทน `light` ที่เปลี่ยนแล้ว);
- `test_arena_integrity` บุคลิก: วัด 3 แมตช์แทน 1 เพราะแมตช์เดียวพลิกตามการก้าวเข้าของ Riku;
- `test_pipeline.py`: ยอมรับคลิปที่ตีด้วยแขนข้างที่ถืออาวุธ (half-slash, back-slash, thrust)
  แต่ยังห้าม slash สองมือ

## 11. ปัญหาที่ยังเหลือ

1. **แอนิเมชันเป็นการประกอบเฟรม LPC** ไม่ใช่วาดใหม่ 5 ท่าตรงกับเกมเพลย์แค่บางส่วน (ข้อ 7)
   ถ้าต้องการคลิปทุบพื้น/หมุนรอบตัวจริง ต้องมีงานศิลป์ใหม่
2. **ไม่มีระบบ juggle กลางอากาศ** ใช้ OTG แทน (ข้อ 4)
3. **ตัวเลข PvP มาจาก AI ปะทะ AI** คู่ที่ห่างที่สุดคือ Counter/Striker และ Brawler/Grappler ที่ 42/58
4. **แมตช์ PvP สั้นลง** (46–59 วินาที) จากเกราะแบบสัดส่วน ถ้าต้องการจังหวะเดิม ปรับ `hp_scale` ได้
   (เป็นการตัดสินใจของเจ้าของ)
5. **Kan PvE ต่ำกว่าเดิม 5%** (239 → 227) ตั้งแต่รอบ 1 ไม่ได้แก้เพราะห้ามจูน PvE เพื่อ PvP
6. **AI ของสกิลตอบโต้ (Slip Counter, ท่าตั้งรับ):**
   - ใช้ได้เฉพาะบอทระดับ 0.4 ขึ้นไป;
   - Counter Fighter รับหมัด Striker ได้น้อย เพราะ startup 3–5 tick เร็วกว่าเวลาตอบสนองของบอท;
   - คนจริงอาจทำได้ต่างกัน
7. **id พาสซีฟเดิม** (`precision_impact`, `berserk_momentum`, `combo_mastery`) คงไว้เพื่อเซฟ
   ชื่อที่แสดงเปลี่ยนแล้ว
8. **ยังไม่ commit/push** รอการตรวจและอนุมัติ ไฟล์ที่เปลี่ยน: `client/sim` (CombatRules, ComboRules,
   AutoSkills, AutoPilot, ArenaBrain, GrabRules, CounterRules, PassiveRules, BalanceProfile, SkillRules,
   ContentDB, Fighter, MoveData, MoveLibrary, SkillRegistry ใหม่), `client/scenes` (FighterView,
   SkillsScreen, Gallery), `client/data` (moves, skills, jobs), `art/lpc/characters.json` + ชีตฮีโร่
   ที่สร้างใหม่และ `client/assets/manifest.json`, `tools/assets` (lpc_build, test_pipeline), เทสต์,
   `docs/COMBAT_SYSTEM.md`, `docs/ARENA_BALANCE.md`, `CHANGELOG.md` และไฟล์นี้
