#!/usr/bin/env python3
"""Every boss's and mini-boss's own skills, generated into client/data.

Run from the repository root:  python3 tools/content/boss_skills.py

Writes client/data/boss_skills.json (the boss skill catalogue, separate from
the heroes' skills.json) and each skill's own moves into client/data/moves.json
(ids "bs_<skill id>", never shared). Idempotent: every "bs_" move is replaced
on each run. Reads only client/data/*.json; the game's rules stay in Godot
(BossSkillRules validates the result on load, BossSkills and EnemyBrain run it).

Each boss gets the skills listed in ROSTER, built from an archetype (a strike, a
sweep, a combo, a charge, a leap, a grab, or a cast that calls a hazard or
helpers) and scaled from the boss's own heavy blow and level band:

* damage: a share of the boss's heavy move (so it rides the same power and
  level scaling as everything the boss does), never less than ABOVE_HEROES
  times the heroes' median skill (before power), so a boss's skill always
  outhits a hero's;
* telegraph: wind-ups shorten a little each band of ten levels, never below a
  floor (18 ticks for heavy blows, 12 for a combo's light hits), and hazards
  keep their ground warning on top of the cast;
* recovery: a punish window after every heavy skill, a little shorter later;
* cooldown: per archetype, a little shorter later, so a skill never repeats
  back to back.

Higher bands open more demanding archetypes (combos of three, volleys,
quakes, chains, phase finishers): see BAND_KINDS.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "client" / "data"
PREFIX = {"mini": "MB", "stage": "SB", "world": "WB"}
# The archetypes each level band (0: 1-10 ... 6: 61-70) may use: later bands
# keep the earlier ones and add more demanding mechanics.
BAND_KINDS = [
    {"strike", "sweep", "charge", "ground"},
    {"combo2", "crane"},
    {"leap", "grab", "row"},
    {"combo3", "volley", "summon"},
    {"quake", "chain"},
    set(),
    set(),
]

# boss: (tier, [(name, archetype, {options})]). Options: "kind" (hazard
# kind), "phase" (the phase from which it is used), "weight".
ROSTER = {
    "sludge_foreman": ("mini", [
        ("Wrench Clout", "strike", {}),
        ("Sludge Spit", "ground", {"kind": "sludge"}),
        ("Foreman's Shove", "charge", {}),
    ]),
    "pit_champion": ("mini", [
        ("Chair Smash", "strike", {}),
        ("Ring Rush", "charge", {}),
        ("Haymaker Sweep", "sweep", {}),
    ]),
    "furnace_baron": ("stage", [
        ("Furnace Pipe", "strike", {}),
        ("Bellows Charge", "charge", {}),
        ("Ember Spill", "ground", {"kind": "steam"}),
        ("Coal Sweep", "sweep", {"phase": 1}),
    ]),
    "harbourmaster_chen": ("stage", [
        ("Tide Cutter", "sweep", {}),
        ("Two-Hook Combo", "combo2", {}),
        ("Cargo Drop", "crane", {}),
        ("Dockside Charge", "charge", {"phase": 1}),
    ]),
    "security_chief": ("mini", [
        ("Baton Drill", "combo2", {}),
        ("Lockdown Tackle", "charge", {}),
        ("Cuff Grab", "grab", {}),
    ]),
    "unit_k7": ("stage", [
        ("Piston Jabs", "combo2", {}),
        ("Rail Leap", "leap", {}),
        ("Live Wire", "row", {"kind": "shock"}),
        ("Clamp Hold", "grab", {"phase": 1}),
    ]),
    "ringmaster": ("mini", [
        ("Plank Spin", "sweep", {}),
        ("Showstopper Leap", "leap", {}),
        ("Crowd Debris", "crane", {}),
    ]),
    "tunnel_mother": ("world", [
        ("Brood Swipe", "sweep", {}),
        ("Drain Slam", "leap", {}),
        ("Bile Rain", "volley", {"kind": "sludge"}),
        ("Call the Brood", "summon", {}),
        ("Sewer Surge", "charge", {"phase": 1}),
    ]),
    "big_sak": ("stage", [
        ("Grand Slam", "strike", {}),
        ("Tower Charge", "charge", {}),
        ("Bat Flurry", "combo3", {}),
        ("Call the Crew", "summon", {}),
        ("Rooftop Leap", "leap", {"phase": 1}),
    ]),
    "subject_twelve": ("mini", [
        ("Maul Flurry", "combo3", {}),
        ("Feral Pounce", "leap", {}),
        ("Black Bile", "row", {"kind": "sludge"}),
        ("Hybrid Grab", "grab", {"phase": 1}),
    ]),
    "commander_arthit": ("stage", [
        ("Command Baton", "combo3", {}),
        ("Volley Order", "volley", {"kind": "shock"}),
        ("Shield Wall Rush", "charge", {}),
        ("Arrest Lock", "grab", {}),
        ("Suppression Line", "row", {"kind": "shock", "phase": 1}),
    ]),
    "spillway_chief": ("mini", [
        ("Floodgate Swing", "sweep", {}),
        ("Spillway Rush", "charge", {}),
        ("Debris Wave", "quake", {}),
        ("Gate Bash Combo", "combo3", {"phase": 1}),
    ]),
    "director_wiroj": ("stage", [
        ("Board Cut Combo", "combo3", {}),
        ("Executive Leap", "leap", {}),
        ("Shareholder Grid", "chain", {}),
        ("Hostile Takeover", "grab", {}),
        ("Market Crash", "quake", {"phase": 1}),
    ]),
    "iron_colossus": ("world", [
        ("Wrench Crusher", "strike", {}),
        ("Scrap Quake", "quake", {}),
        ("Magnet Pull", "grab", {}),
        ("Junk Barrage", "volley", {"kind": "crane"}),
        ("Colossus Charge", "charge", {"phase": 1}),
    ]),
    "arthit_reinstated": ("mini", [
        ("Riot Line", "chain", {}),
        ("Reinstated Baton", "combo3", {}),
        ("Command Charge", "charge", {}),
        ("Squad Call", "summon", {"phase": 1}),
    ]),
    "subject_zero": ("world", [
        ("Zero Rend", "combo3", {}),
        ("Abyss Pounce", "leap", {}),
        ("Black Tide", "volley", {"kind": "rain"}),
        ("Reservoir Geysers", "row", {"kind": "steam"}),
        ("Null Grip", "grab", {"phase": 1}),
    ]),
    "floodgate_marshal": ("world", [
        ("Marshal's Drill", "combo3", {}),
        ("Flood Charge", "charge", {}),
        ("Gate Quake", "quake", {}),
        ("Squad Volley", "volley", {"kind": "rain"}),
        ("Arc Fence", "chain", {"phase": 1}),
        ("Martial Law", "leap", {"phase": 2}),
    ]),
    "slag_titan": ("world", [
        ("Slag Swing", "sweep", {}),
        ("Molten Leap", "leap", {}),
        ("Slag Rain", "volley", {"kind": "rain"}),
        ("Furnace Quake", "quake", {}),
        ("Titan Grip", "grab", {"phase": 1}),
        ("Forge Charge", "charge", {"phase": 2}),
    ]),
    "twelve_relapsed": ("mini", [
        ("Relapse Frenzy", "combo3", {}),
        ("Toxic Bloom", "volley", {"kind": "sludge"}),
        ("Lunging Rend", "leap", {}),
        ("Seizing Grip", "grab", {"phase": 1}),
    ]),
    "crucible_king": ("world", [
        ("Crucible Combo", "combo3", {}),
        ("Molten Pour", "row", {"kind": "steam"}),
        ("King's Charge", "charge", {}),
        ("Ember Storm", "volley", {"kind": "rain"}),
        ("Throne Slam", "leap", {"phase": 1}),
        ("Smelt Grip", "grab", {"phase": 2}),
    ]),
    "k7_overdriven": ("mini", [
        ("Overdrive Piston", "strike", {}),
        ("Arc Lattice", "chain", {}),
        ("Hydraulic Leap", "leap", {}),
        ("Meltdown Press", "quake", {"phase": 1}),
    ]),
    "iron_sovereign": ("world", [
        ("Sovereign Cleave", "sweep", {}),
        ("Vault Rend", "combo3", {}),
        ("Iron Decree", "quake", {}),
        ("Shadow Rain", "volley", {"kind": "rain"}),
        ("Sovereign Pounce", "leap", {}),
        ("Crown Grip", "grab", {"phase": 1}),
        ("Toll of Iron", "chain", {"phase": 2}),
    ]),
    "wiroj_protocol": ("mini", [
        ("Protocol Cuts", "combo3", {}),
        ("Executive Lunge", "charge", {}),
        ("Lockout Grid", "volley", {"kind": "shock"}),
        ("Palm of Authority", "grab", {"phase": 1}),
    ]),
    "founders_engine": ("world", [
        ("Piston Cascade", "combo3", {}),
        ("Engine Rush", "charge", {}),
        ("Grid Overload", "chain", {}),
        ("Foundation Quake", "quake", {}),
        ("Rivet Storm", "volley", {"kind": "rain"}),
        ("Press Grip", "grab", {"phase": 1}),
        ("Final Stroke", "leap", {"phase": 2}),
    ]),
}

# Shares of the boss's heavy move's damage.
DAMAGE = {
    "strike": 1.15, "sweep": 1.05, "charge": 1.2, "leap": 1.3, "grab": 1.35,
    "hit": 0.45, "finisher": 0.7, "ground": 1.0, "crane": 1.0, "row": 0.9,
    "volley": 0.75, "chain": 0.85, "quake": 1.0,
}
COOLDOWN = {
    "strike": 300, "sweep": 360, "charge": 420, "leap": 480, "grab": 540, "combo2": 360,
    "combo3": 420, "ground": 480, "crane": 480, "row": 540, "volley": 600, "chain": 600,
    "quake": 600, "summon": 900,
}
FX = {
    "strike": ("hit_heavy", "swing_heavy"), "sweep": ("whirlwind", "skill_whirlwind"),
    "charge": ("rush", "skill_rush"), "leap": ("slam", "skill_slam"),
    "grab": ("uppercut", "skill_uppercut"), "combo2": ("hit_heavy", "swing_heavy"),
    "combo3": ("hit_heavy", "swing_heavy"),
}
CASTS = {"ground", "crane", "row", "volley", "chain", "quake", "summon"}
HAZARD_SHAPES = {
    "ground": {"half": [36, 14]},
    "crane": {"kind": "crane", "half": [30, 10]},
    "row": {"half": [34, 12], "count": 3, "spread": [0, 46], "stagger": 6},
    "volley": {"half": [16, 10], "count": 6, "spread": [240, 40], "stagger": 5},
    "chain": {"kind": "shock", "half": [40, 14], "count": 4, "spread": [260, 0], "stagger": 8},
    "quake": {"kind": "quake", "half": [24, 90]},
}
SOUND_CAST = {"summon": "arena_lock"}
ABOVE_HEROES = 1.1
# The heroes' median skill damage the boss balance was approved against (the
# 24-skill roster). With the five job kits (30 actives, measured by
# hero_damage) the live median is 32; adopting it is the owner's call (P-2).
HERO_MEDIAN = 29
# Fairness timings (ticks): a charge's wind-up, a skill's first blow, and a
# combo's light hit's stun (BossSkillRules checks each).
CHARGE_WINDUP = 24
OPENER_WINDUP = 18
LIGHT_STUN = 6
# How near the hero must be for a boss to cast: further off, it closes in first
# (a boss never stands far away calling skills; the owner's rule).
CAST_REACH = 260


# Every boss's Ultimate (the owner's rule, November 2026): one cast, then one
# to four waves of hazards over a wide area, each wave warned on the ground
# (HazardView at true size) and laid out so a clear spot is always in reach.
# Patterns, relative to the boss (mirrored to its facing) unless "on": "hero":
#   ("row", xs, dy, half)       tiles along the street at x offsets xs
#   ("columns", xs)             quake columns splitting the whole depth
#   ("ring", r)                 four tiles around the boss
#   ("burst", half)             one wide blast centred on the boss
#   ("rain", count, spread)     a volley around the hero
#   ("chase",)                  one tile on the hero (waves keep following)
#   ("span", lo, hi, step, gap) a full line from lo to hi with one safe gap
# Later bands open more waves and the subtler patterns (BAND_KINDS-like):
# band 0-1 one or two simple waves; 2-3 two or three, mixed; 4-6 three or four
# with moving safe gaps.
ULTIMATES = {
    "sludge_foreman": ("Sludge Geyser Field", "sludge", [("row", [-70, 0, 70], 0, [34, 46])]),
    "pit_champion": ("Ring Collapse", "quake", [("columns", [-120, -50, 50, 120])]),
    "furnace_baron": ("Furnace Eruption", "steam", [("burst", [90, 46])]),
    "harbourmaster_chen": ("Cargo Avalanche", "crane", [
        ("row", [40, 160], 0, [40, 46]), ("row", [90, 210], 0, [40, 46])]),
    # The cage closes: the outer walls fall, then the inner ones, then the
    # boss's own ground (stay inside the cage, then step out of the centre).
    "security_chief": ("Lockdown", "quake", [
        ("columns", [-180, -120, 120, 180]), ("columns", [-60, 60]), ("burst", [46, 46])]),
    "unit_k7": ("Overload Grid", "shock", [
        ("row", [-150, -50, 50, 150], -24, [40, 25]), ("row", [-150, -50, 50, 150], 24, [40, 25])]),
    "ringmaster": ("Grand Finale", "crane", [("rain", 5, [160, 40]), ("row", [-90, 90], 0, [40, 46])]),
    "big_sak": ("Tower Collapse", "quake", [
        ("columns", [40, 110, 180]), ("columns", [-40, -110, -180]), ("burst", [56, 46])]),
    "tunnel_mother": ("Brood Deluge", "sludge", [
        ("rain", 8, [260, 40]), ("ring", 80), ("columns", [-150, 150])]),
    "subject_twelve": ("Feral Frenzy", "sludge", [
        ("chase",), ("row", [-70, 70], 0, [34, 46]), ("chase",)]),
    "commander_arthit": ("Total Suppression", "shock", [
        ("span", -240, 240, 60, 6), ("span", -240, 240, 60, 5), ("rain", 6, [220, 40])]),
    # The gates break one after the other, then the flood scatters over the hero.
    "spillway_chief": ("Floodgate Burst", "quake", [
        ("span", -240, 240, 60, 5), ("span", -240, 240, 60, 6), ("rain", 8, [240, 40])]),
    "director_wiroj": ("Hostile Liquidation", "shock", [
        ("span", -240, 240, 60, 5), ("span", -240, 240, 60, 6), ("columns", [0])]),
    "iron_colossus": ("Scrapyard Cataclysm", "crane", [
        ("columns", [-90, 90]), ("rain", 8, [260, 40]), ("ring", 90)]),
    "subject_zero": ("Abyssal Tide", "rain", [
        ("rain", 8, [260, 40]), ("span", -240, 240, 60, 5), ("chase",)]),
    "arthit_reinstated": ("Reinstatement Order", "shock", [
        ("span", -240, 240, 60, 5), ("span", -240, 240, 60, 6), ("span", -240, 240, 60, 7)]),
    "floodgate_marshal": ("Martial Flood", "quake", [
        ("span", -240, 240, 60, 5), ("columns", [-200, -100, 100, 200]), ("rain", 6, [280, 40]),
        ("burst", [70, 46])]),
    "slag_titan": ("Molten Collapse", "steam", [
        ("ring", 70), ("span", -240, 240, 60, 5), ("span", -240, 240, 60, 6), ("columns", [0])]),
    "twelve_relapsed": ("Relapse Bloom", "sludge", [
        ("chase",), ("rain", 6, [200, 40]), ("chase",)]),
    "crucible_king": ("Crucible Overflow", "steam", [
        ("burst", [70, 46]), ("span", -240, 240, 60, 6), ("span", -240, 240, 60, 5), ("rain", 8, [260, 40])]),
    "k7_overdriven": ("Critical Meltdown", "shock", [
        ("row", [-160, -80, 0, 80, 160], -24, [36, 25]), ("row", [-120, -40, 40, 120], 24, [36, 25]),
        ("columns", [-60, 60])]),
    "iron_sovereign": ("Iron Judgement", "rain", [
        ("chase",), ("span", -240, 240, 60, 5), ("columns", [-160, 160]), ("span", -240, 240, 60, 6)]),
    "wiroj_protocol": ("Final Protocol", "shock", [
        ("span", -240, 240, 60, 6), ("span", -240, 240, 60, 5), ("chase",), ("columns", [0])]),
    "founders_engine": ("Founder's Verdict", "shock", [
        ("columns", [-180, -60, 60, 180]), ("span", -240, 240, 60, 6), ("span", -240, 240, 60, 7),
        ("rain", 8, [260, 40])]),
}
# The Ultimate's damage: per hit, a share of the boss's light (basic) blow,
# within ULT_RANGE of it, never below the heroes' skills (ABOVE_HEROES).
ULT_SHARE = 2.5
ULT_RANGE = (2.0, 3.0)
# Owner-approved exceptions to ULT_SHARE (per-hit damage). Founder's Engine:
# 50 -> 46 (P-1, docs/BOSS_SKILL_QUALITY_AUDIT.md), so one wave stays under
# half of a level-geared hero's health in its last phase under the round's
# enrage. Still within ULT_RANGE and above the heroes' skills.
ULT_DAMAGE_OVERRIDE = {"founders_engine": 46}
# Owner-approved Ultimate timing exceptions (P-3, docs/BOSS_SKILL_QUALITY_AUDIT.md),
# so the slowest job (the Grappler) can walk out: extra ticks of warning on
# every wave ("warn"), or extra ticks between waves ("step"). Damage, layout
# and wave count are unchanged.
ULT_TIMING_OVERRIDE = {
    "subject_zero": {"warn": 10},
    "founders_engine": {"warn": 10},
    "floodgate_marshal": {"step": 8},
}
# Owner-approved damage exceptions for regular skills (P-2): four skills raised
# by one point to the five jobs' median skill. Skill id -> (what is set: a move
# id, or "hazard" for the skill's hazard, the value it is set to, the value the
# formula gives, checked so a formula change is never silently overridden).
SKILL_DAMAGE_OVERRIDE = {
    "SB_HARBOURMASTER_CHEN_002": ("bs_sb_harbourmaster_chen_002_2", 20, 19),
    "MB_SECURITY_CHIEF_001": ("bs_mb_security_chief_001_2", 20, 19),
    "WB_IRON_COLOSSUS_004": ("hazard", 30, 29),
    "WB_SLAG_TITAN_003": ("hazard", 30, 29),
}
ULT_COOLDOWN = 1500
ULT_OPENING = 540
# Ultimate tiles cover the street's whole depth (no strip to hide in), so the
# answer is always along the street: a safe gap, or out of reach. A span's
# first gap lies in front of the boss (the hero's side) and each next one
# beside the last, a step a hero walks between waves (ULT_STEP ticks), and
# never on the boss's own spot (offset 0), where its body stands.
ULT_DEPTH = 46
ULT_STEP = 48


def ult_wave(pattern, kind, warn, damage):
    """One wave of an Ultimate: a hazard spec for BossMechanics."""
    name = pattern[0]
    wave = {"kind": kind, "warn": warn, "damage": damage}
    if name == "row":
        wave.update({"origin": "boss", "offsets": [[x, pattern[2]] for x in pattern[1]],
                     "half": list(pattern[3])})
    elif name == "columns":
        wave.update({"kind": "quake", "origin": "boss", "offsets": [[x, 0] for x in pattern[1]],
                     "half": [24, 90]})
    elif name == "ring":
        r = pattern[1]
        wave.update({"origin": "boss", "offsets": [[-r, 0], [r, 0], [0, -30], [0, 30]],
                     "half": [30, 14]})
    elif name == "burst":
        wave.update({"origin": "boss", "offsets": [[0, 0]], "half": list(pattern[1])})
    elif name == "rain":
        wave.update({"kind": "rain" if kind in ("rain", "shock", "quake") else kind, "half": [16, 10],
                     "count": pattern[1], "spread": list(pattern[2]), "stagger": 4})
    elif name == "chase":
        wave.update({"origin": "hero", "offsets": [[0, 0]], "half": [34, ULT_DEPTH]})
    elif name == "span":
        lo, hi, step, gap = pattern[1], pattern[2], pattern[3], pattern[4]
        xs = [x for i, x in enumerate(range(lo, hi + 1, step)) if i != gap]
        wave.update({"origin": "boss", "offsets": [[x, 0] for x in xs],
                     "half": [step // 2 - 2, ULT_DEPTH]})
    return wave


def build_ultimate(skill_id, owner, band, light, least):
    """The boss's Ultimate: its entry and its cast move ({move id: move})."""
    name, kind, patterns = ULTIMATES[owner]
    damage = max(light * ULT_SHARE, least)
    damage = int(round(min(max(damage, light * ULT_RANGE[0]), light * ULT_RANGE[1])))
    if owner in ULT_DAMAGE_OVERRIDE:
        damage = ULT_DAMAGE_OVERRIDE[owner]
        assert light * ULT_RANGE[0] <= damage <= light * ULT_RANGE[1], owner
        assert damage >= least, owner
    first = max(96, 110 - 2 * band) + ULT_TIMING_OVERRIDE.get(owner, {}).get("warn", 0)
    step = ULT_STEP + ULT_TIMING_OVERRIDE.get(owner, {}).get("step", 0)
    # Each wave is marked on the ground when it is next ("delay" ticks after the
    # cast, ULT_STEP apart), every one with the same full warning: never all of
    # an Ultimate's tiles on the street at once.
    waves = []
    for i, p in enumerate(patterns):
        wave = ult_wave(p, kind, first, damage)
        wave["delay"] = i * step
        waves.append(wave)
    base = "bs_" + skill_id.lower()
    anim = "stab" if owner == "sludge_foreman" else "swing"
    cast = move(36, 4, 40, 0, knockback=0, hitstun=0, knockdown=False, anim=anim)
    skill = {"owner": owner, "name": name, "type": "ultimate", "ultimate": True,
             "cooldown": ULT_COOLDOWN, "opening": ULT_OPENING, "phase": 0, "weight": 3.0,
             "moves": [base], "range": [0, CAST_REACH], "lane": 0, "fx": "phase_burst",
             "sound": "boss_roar", "waves": waves}
    return skill, {base: cast}


def band_of(level):
    return min(6, max(0, (level - 1) // 10))


def kinds_open(band):
    out = set()
    for b in range(band + 1):
        out |= BAND_KINDS[b]
    return out


def tel(base, band, floor):
    return max(floor, base - 2 * band)


def move(startup, active, recovery, damage, **extra):
    data = {"startup": startup, "active": active, "recovery": recovery, "damage": int(round(damage)),
            "hitstun": extra.pop("hitstun", 34), "knockback": extra.pop("knockback", 110),
            "reach_offset": extra.pop("reach_offset", 0), "reach": extra.pop("reach", 0),
            "depth_tolerance": extra.pop("depth", 0)}
    data.update({"guard_break": False, "knockdown": True, "telegraph": True, "anim": "heavy"})
    data.update(extra)
    return data


def build(skill_id, owner, name, kind, opts, heavy, band, summon, least):
    """The skill's catalogue entry and its moves ({move id: move}); `least` is
    the base damage the whole skill must reach (ABOVE_HEROES)."""
    base = "bs_" + skill_id.lower()
    share = DAMAGE.get(kind, 1.0)
    if kind in ("combo2", "combo3"):
        hits = 2 if kind == "combo2" else 3
        share = DAMAGE["hit"] * (hits - 1) + DAMAGE["finisher"]
    # Raise the boss's heavy for this skill until the skill outhits a hero's.
    heavy = max(heavy, least / share)
    moves = {}
    skill = {"owner": owner, "name": name, "type": kind, "cooldown": int(round(COOLDOWN[kind] * (1 - 0.03 * band))),
             "phase": int(opts.get("phase", 0)), "weight": float(opts.get("weight", 1.0))}
    rec = max(24, 38 - 2 * band)
    if kind == "strike":
        moves[base] = move(tel(30, band, 18), 6, rec, heavy * DAMAGE[kind], reach=52, depth=20)
    elif kind == "sweep":
        moves[base] = move(tel(32, band, 20), 8, rec, heavy * DAMAGE[kind], reach_offset=-44, reach=120,
                           depth=26, guard_break=True)
    elif kind == "charge":
        # The run starts in the wind-up (CombatRules._advance), so a charge's
        # wind-up is never under CHARGE_WINDUP and its active no longer than a
        # roll's invulnerability: on reaction, a hero can roll through it or step
        # off its lane (the audit's D-2).
        moves[base] = move(tel(28, band, CHARGE_WINDUP), 12, rec + 4, heavy * DAMAGE[kind], reach=32,
                           depth=18, advance=150 + 5 * band, guard_break=True)
    elif kind == "leap":
        # A leap runs through its wind-up like a charge (CHARGE_WINDUP).
        moves[base] = move(tel(34, band, CHARGE_WINDUP), 6, rec + 6, heavy * DAMAGE[kind], reach_offset=-30,
                           reach=76, depth=28, advance=120)
    elif kind == "grab":
        moves[base] = move(tel(24, band, 18), 5, rec + 2, heavy * DAMAGE[kind], reach=30, depth=14,
                           guard_break=True, knockback=60)
    elif kind in ("combo2", "combo3"):
        hits = 2 if kind == "combo2" else 3
        steps = []
        for i in range(hits - 1):
            # The opener winds up at least OPENER_WINDUP (seen and rolled on
            # reaction, the audit's R-1); the later light hits stay quick but
            # stun only LIGHT_STUN ticks, so a hero who is hit can still roll
            # out before the next one lands.
            startup = max(OPENER_WINDUP, tel(16, band, 12)) if i == 0 else tel(16, band, 12)
            steps.append(move(startup, 4, 10, heavy * DAMAGE["hit"], reach=46, depth=18,
                              hitstun=LIGHT_STUN, knockback=18, knockdown=False, telegraph=i == 0,
                              anim="light"))
        steps.append(move(tel(26, band, 18), 6, rec, heavy * DAMAGE["finisher"], reach=50, depth=20))
        for i, data in enumerate(steps):
            moves[base if i == 0 else "%s_%d" % (base, i + 1)] = data
    else:
        # A cast: the boss winds up (no hitbox: damage 0), then its hazard or
        # helpers arrive. The hazard's own warning is the telegraph on the ground.
        moves[base] = move(24, 4, 30, 0, knockback=0, hitstun=0, knockdown=False)
    skill["moves"] = list(moves)
    first = moves[base]
    if kind in CASTS:
        skill["range"] = [0, CAST_REACH]
    elif kind == "charge":
        skill["range"] = [70, int(first["advance"]) + 40]
    elif kind == "leap":
        skill["range"] = [80, int(first["advance"]) + 70]
    else:
        reach = first["reach_offset"] + first["reach"]
        skill["range"] = [0, int(reach) + 6]
    skill["lane"] = 0 if kind in CASTS else int(first["depth_tolerance"])
    fx, sound = FX.get(kind, ("", SOUND_CAST.get(kind, "hazard_warn")))
    skill["fx"], skill["sound"] = fx, sound
    if kind == "summon":
        skill["summon"] = {"enemy": summon, "count": 2, "max": 3}
    elif kind in CASTS:
        shape = dict(HAZARD_SHAPES[kind])
        shape.setdefault("kind", opts.get("kind", "steam"))
        if "kind" in opts:
            shape["kind"] = opts["kind"]
        shape["warn"] = tel(60, band, 42)
        shape["damage"] = int(round(heavy * DAMAGE[kind]))
        skill["hazard"] = shape
    return skill, moves


def levels(areas, enemies, world):
    out = {}
    for area in areas.values():
        for enc in area.get("encounters", []):
            for wave in enc.get("waves", []):
                for kind in wave:
                    if enemies.get(kind, {}).get("boss") and kind not in out:
                        out[kind] = int(area.get("level", 1))
    for spec in world.values():
        out[spec["enemy"]] = int(spec["level"])
    return out


def hero_damage(skill, moves):
    """What a hero's active skill deals on a hit, to measure the bosses' skills
    against (ABOVE_HEROES): its blows ("move" and "then"), and a grab skill's
    throw, or its squeeze over the hold and then its drop. Passives and the
    jobs' gauge-gated ultimates are not measured (0), nor are skills that deal
    nothing themselves (a plain grab, a counter stance). Data is read here at
    generation time only: the game never ties the two catalogues together."""
    if skill.get("type", "active") != "active":
        return 0
    total = sum(moves[i]["damage"] for i in [skill["move"]] + list(skill.get("then", [])))
    grab = skill.get("grab")
    if isinstance(grab, dict):
        if "squeeze" in grab:
            total += moves[grab["squeeze"]]["damage"] * (int(grab["hold"]) // int(grab["every"]))
        if "throw" in grab:
            total += moves[grab["throw"]]["damage"]
    return total


def load(name):
    return json.loads((DATA / name).read_text())


def save(name, data):
    (DATA / name).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def main():
    enemies = load("enemies.json")["enemies"]
    areas = load("areas.json")["areas"]
    world = load("world_boss.json")["world_bosses"]
    moves_doc = load("moves.json")
    moves = {k: v for k, v in moves_doc["moves"].items() if not k.startswith("bs_")}
    level_of = levels(areas, enemies, world)
    hero_skills = load("skills.json")["skills"]
    damages = sorted(d for d in (hero_damage(s, moves) for s in hero_skills.values()) if d > 0)
    live = damages[len(damages) // 2]
    # The bosses' balance is set against the approved baseline, not the live
    # median, so regenerating never moves a boss's damage on its own; a change
    # of baseline is an owner's balance decision (BOSS_SKILL_QUALITY_AUDIT.md).
    median = HERO_MEDIAN
    if live != HERO_MEDIAN:
        print("note: the heroes' median skill is now %d (the bosses are set against %d)"
              % (live, HERO_MEDIAN))
    bosses = [k for k, v in enemies.items() if v.get("boss")]
    missing = sorted(set(bosses) - set(ROSTER))
    assert not missing, "bosses without skills: %s" % missing
    catalogue = {"bosses": {}, "skills": {}}
    for owner in bosses:
        tier, table = ROSTER[owner]
        level = level_of[owner]
        band = band_of(level)
        heavy_id = enemies[owner]["moveset"]["heavy"]
        heavy = float(moves[heavy_id]["damage"])
        summon = (enemies[owner].get("summon") or {}).get("enemy", "")
        ids = []
        for i, (name, kind, opts) in enumerate(table):
            assert kind in kinds_open(band), "%s: %s opens later than level %d" % (owner, kind, level)
            skill_id = "%s_%s_%03d" % (PREFIX[tier], owner.upper(), i + 1)
            least = ABOVE_HEROES * median / float(enemies[owner].get("power", 1.0))
            skill, made = build(skill_id, owner, name, kind, opts, heavy, band, summon, least)
            if skill_id in SKILL_DAMAGE_OVERRIDE:
                target, value, formula = SKILL_DAMAGE_OVERRIDE[skill_id]
                holder = skill["hazard"] if target == "hazard" else made[target]
                assert holder["damage"] == formula, (skill_id, holder["damage"])
                holder["damage"] = value
            catalogue["skills"][skill_id] = skill
            moves.update(made)
            ids.append(skill_id)
        light = float(moves[enemies[owner]["moveset"]["light"]]["damage"])
        least = ABOVE_HEROES * median / float(enemies[owner].get("power", 1.0))
        ult_id = "%s_%s_ULT_001" % (PREFIX[tier], owner.upper())
        skill, made = build_ultimate(ult_id, owner, band, light, least)
        catalogue["skills"][ult_id] = skill
        moves.update(made)
        ids.append(ult_id)
        catalogue["bosses"][owner] = {"tier": tier, "level": level, "skills": ids}
    moves_doc["moves"] = moves
    save("moves.json", moves_doc)
    save("boss_skills.json", catalogue)
    ults = sum(1 for v in catalogue["skills"].values() if v.get("ultimate"))
    print("boss skills: %d skills (%d Ultimates) for %d bosses"
          % (len(catalogue["skills"]), ults, len(catalogue["bosses"])))


if __name__ == "__main__":
    main()
