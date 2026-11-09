#!/usr/bin/env python3
"""Level 50-70 content for The Iron Legacy, generated into client/data/*.json.

Run from the repository root:  python3 tools/content/level70_content.py

Idempotent: every id it writes is listed in the SPEC below and is replaced on
each run, so balance values are tuned here (or directly in the data) and the
script re-run. Everything it writes is ordinary game data, validated by
ContentDB on load; nothing here is read by the game at run time.

What it builds (all values are first-pass, configurable starting points):
* a farming ground at level 43 that fills the 41-43 gap before the finale, with a
  mini-boss whose body and head gear closes the boss-gear gap from 27 to 48;
* four farming grounds at levels 53, 58, 63 and 68, each with three monster
  roles (a standard or fast fighter, a heavy hitter and a fast or ranged one;
  the first is the most common) and a champion (an elite mini-boss), tinted
  in the tier's colour so a shared sprite still reads as its own kind, and beside each a boss lair (a short
  arena, AreaRules.LAIR) holding a rematch of a story boss; ground and lair
  open together, in a chain (each pair opens when the previous lair's boss
  falls);
* gear for every slot in four tiers (53, 58, 63, 68): uncommon (the market),
  rare (the ground's monsters), epic (the rematch boss and champion);
  Godforged pieces (the world bosses' own grade) from a level 60 world boss and a set from a level 70
  world boss, with stats priced by the ItemRules budget;
* market stock for each tier, opened by the previous rematch boss;
* two world bosses (unlimited entries, as every world boss), with a round
  enrage, and the rematch bosses' fight enrage.
"""

import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "client" / "data"
GODOT = os.environ.get("GODOT", "godot")
SLOTS = ["weapon", "body", "head", "hands", "feet", "charm"]

# Seconds a rematch boss fights before its enrage (chosen with LevelingRun /
# the enrage comparison; see docs).
REMATCH_ENRAGE = {"after_seconds": 75, "warn_seconds": 10, "damage": 1.5, "cooldown": 0.7}
WORLD_BOSS_ENRAGE = {"last_seconds": 1200, "warn_seconds": 60, "damage": 1.3, "cooldown": 0.8}
SHOP_PRICE_PER_POINT = 15.0
# Lair bosses' health over the story boss they are cloned from: at x1.0 every
# lair boss fell in 16-60 s with no knock-out even ten levels under
# (EnrageCompare), so the enrage timer never mattered. A tier may set its own
# "boss_hp" (the Wiroj Protocol keeps the Director's shield phases, which
# already make the fight long).
LAIR_BOSS_HP = 2.0

TIERS = [
    {
        "key": "coolant", "coins": 0.43, "xp": 0.92, "lair": "coolant_control_room", "lair_name": "Coolant Control Room",
        "level": 53, "ground": "farm_coolant_vaults", "ground_name": "Coolant Vaults",
        "unlock": "director_wiroj", "theme": "canal", "kit": "tunnels",
        "palette": {"sky": "#0a1218", "buildings": ["#14262e", "#183038", "#0f2026"], "windows": "#60d0ff",
                    "sidewalk": "#3c4648", "street": "#18222a"},
        "purpose": "The Core's flooded coolant vaults below the Main Control Centre, held by the Director's "
                   "loyal guard after the story: the first ground past level 50, Coolant gear and a rematch "
                   "with Commander Arthit, reinstated.",
        "tint": ("#a8dcff", "#7fc4ff"),
        "mobs": [("vault_trooper", "Vault Trooper", "facility_trooper", 5),
                 ("vault_runner", "Vault Runner", "network_runner", 3),
                 ("coolant_drone", "Coolant Drone", "patrol_unit", 2)],
        "champion": ("vault_warden", "Vault Warden", "core_sentinel"),
        "boss": ("arthit_reinstated", "Commander Arthit, Reinstated", "commander_arthit"),
        "uncommon": "Coolant", "rare": "Vault Guard", "epic": "Reinstated",
    },
    {
        "key": "underworks", "coins": 0.27, "xp": 1.18, "lair": "underworks_tank_hall", "lair_name": "Tank Hall",
        "level": 58, "ground": "farm_reactor_underworks", "ground_name": "Reactor Underworks",
        "unlock": "arthit_reinstated", "theme": "canal", "kit": "tunnels",
        "palette": {"sky": "#160c06", "buildings": ["#2e1a0e", "#382012", "#26150b"], "windows": "#ffb050",
                    "sidewalk": "#4a3e34", "street": "#24180f"},
        "purpose": "The reactor's underworks, where the Subject programme's last tank broke open: "
                   "Underworks gear and a rematch with Subject Twelve, relapsed.",
        "tint": ("#c4ec9c", "#a6e07a"),
        "mobs": [("underworks_brute", "Underworks Brute", "riot_trooper", 2),
                 ("tank_crawler", "Tank Crawler", "market_punk", 5),
                 ("reactor_tech", "Reactor Tech", "hazmat_sprayer", 3)],
        "champion": ("reactor_overseer", "Reactor Overseer", "plant_guard"),
        "boss": ("twelve_relapsed", "Subject Twelve, Relapsed", "subject_twelve"),
        "uncommon": "Underworks", "rare": "Reactor Crew", "epic": "Relapsed",
    },
    {
        "key": "foundry", "coins": 0.46, "xp": 1.02, "lair": "foundry_crucible", "lair_name": "The Crucible",
        "level": 63, "ground": "farm_foundry_depths", "ground_name": "Foundry Depths",
        "unlock": "twelve_relapsed", "theme": "canal", "kit": "tunnels",
        "palette": {"sky": "#1a0806", "buildings": ["#34130c", "#3e1810", "#2a0f09"], "windows": "#ff7040",
                    "sidewalk": "#4c3a34", "street": "#28140f"},
        "purpose": "The old foundry under Iron City, still firing for whoever pays: "
                   "Foundry gear and a rematch with Unit K-7, overdriven.",
        "tint": ("#ffc08a", "#ff9a5c"),
        "mobs": [("foundry_hand", "Foundry Hand", "facility_trooper", 5),
                 ("slag_slinger", "Slag Slinger", "dock_slinger", 3),
                 ("furnace_hauler", "Furnace Hauler", "stevedore", 2)],
        "champion": ("foundry_boss", "Foundry Boss", "riot_trooper"),
        "boss": ("k7_overdriven", "Unit K-7, Overdriven", "unit_k7"),
        "uncommon": "Foundry", "rare": "Slagworker", "epic": "Overdriven",
    },
    {
        "key": "heart", "boss_hp": 1.3, "coins": 0.54, "xp": 1.31, "lair": "heart_core_chamber", "lair_name": "Heart Core Chamber",
        "level": 68, "ground": "farm_iron_heart", "ground_name": "The Iron Heart",
        "unlock": "k7_overdriven", "theme": "canal", "kit": "tunnels",
        "palette": {"sky": "#100808", "buildings": ["#261012", "#2e1416", "#1e0c0e"], "windows": "#ff5060",
                    "sidewalk": "#3e3436", "street": "#1e1214"},
        "purpose": "The machine heart the Director built under the city, the last ground before level 70: "
                   "Heartforged gear, and the Wiroj Protocol (the Heart's defences, in his voice) waits in its core.",
        "tint": ("#ffb0b0", "#ff7a7a"),
        "mobs": [("heart_guard", "Heart Guard", "ring_fighter", 5),
                 ("rivet_thrower", "Rivet Thrower", "street_thrower", 3),
                 ("iron_sentry", "Iron Sentry", "core_sentinel", 2)],
        "champion": ("heart_keeper", "Heart Keeper", "core_sentinel"),
        "boss": ("wiroj_protocol", "The Wiroj Protocol", "director_wiroj"),
        "uncommon": "Heartforged", "rare": "Heart Sentry", "epic": "Protocol",
    },
]

GAP_GROUND = {
    "id": "farm_core_spillway", "name": "Core Spillway", "level": 43, "region": "The Core Facility",
    "unlock": "commander_arthit",
    "purpose": "The facility's spillway after the Control Room falls: the ground for levels 41-45 before "
               "the final chapter, with facility Refined Alloy and coins.",
    "pool": {"facility_trooper": 6, "hazmat_sprayer": 2, "core_sentinel": 1},
    # A mini-boss at the east end closes the boss-gear gap for body and head
    # between Unit K-7 (23) / the Ringmaster (27) and the Director (48).
    "boss": ("spillway_chief", "Spillway Chief", "security_chief"),
    "lair": "spillway_gatehouse", "lair_name": "Spillway Gatehouse",
    # The Spillway Chief comes from a level 21 mid-boss: at x2.0 it fell in 31 s with shop
    # gear and even a hero with no gear won every fight (EnrageCompare, 10 seeds).
    "boss_hp": 2.5,
    "gear_level": 42,
    "gear": [("spillway_epic_body", "Spillway Chief's Coat", "body"),
             ("spillway_epic_head", "Spillway Chief's Visor", "head")],
}

WORLD_BOSSES = [
    {
        "id": "slag_titan", "name": "The Slag Titan", "clone": "iron_colossus", "level": 60, "players": 5,
        "tint": "#ffa070", "weapon": "baseball_bat", "arena": "slag_furnace", "arena_name": "Slag Furnace", "arena_clone": "old_scrapyard",
        "unlock": "twelve_relapsed", "period_minutes": 360, "offset_minutes": 240,
        "prizes": [("titan_slagfist", "Titan's Slagfist", "weapon"), ("titan_grip", "Titan's Grip", "hands"),
                   ("titan_core", "Titan's Ember Core", "charm")],
        "grade": "godforged", "item_level": 60,
    },
    {
        "id": "iron_sovereign", "name": "The Iron Sovereign", "clone": "subject_zero", "level": 70, "players": 10,
        "tint": "#d8b8ff", "weapon": "machete", "arena": "sovereign_vault", "arena_name": "Sovereign Vault", "arena_clone": "sunken_reservoir",
        "unlock": "wiroj_protocol", "period_minutes": 1440, "offset_minutes": 720,
        "prizes": [("sovereign_fists", "Sovereign Fists", "weapon"), ("sovereign_mantle", "Sovereign Mantle", "body"),
                   ("sovereign_crown", "Sovereign Crown", "head"), ("sovereign_grips", "Sovereign Grips", "hands"),
                   ("sovereign_treads", "Sovereign Treads", "feet"), ("sovereign_seal", "Sovereign Seal", "charm")],
        "grade": "godforged", "item_level": 70,
    },
] + [
    # Three raid bosses, one for each band past the story (50-60, 60-65, 65-70): each stronger
    # than the last, built for more players, armed, with its own moves and skills (the "quake"
    # column and "rain" volley hazards among them) and its own arena. Values are a first pass,
    # tuned here and re-run.
    {
        "id": "floodgate_marshal", "name": "The Floodgate Marshal", "clone": "commander_arthit",
        "spec_clone": "subject_zero", "level": 56, "players": 15, "tint": "#8fc8ff", "weapon": "pipe",
        "arena": "floodgate_barracks", "arena_name": "Floodgate Barracks", "arena_clone": "sunken_reservoir",
        "arena_palette": {"sky": "#06101a", "buildings": ["#0f2232", "#132a3c", "#0b1a28"], "windows": "#7fd4ff",
                          "sidewalk": "#33424c", "street": "#121c26"},
        "unlock": "arthit_reinstated", "period_minutes": 240, "offset_minutes": 60,
        "prizes": [("marshal_greatcoat", "Marshal's Greatcoat", "body"),
                   ("marshal_visor", "Marshal's Floodlight Visor", "head"),
                   ("marshal_sabatons", "Marshal's Sabatons", "feet")],
        "grade": "godforged", "item_level": 56,
        "moves": {
            "marshal_baton": ("arthit_baton", {"damage": 1.3, "reach": 1.4}),
            "marshal_charge": ("colossus_charge", {"damage": 1.15, "advance": 1.2}),
            "marshal_floodslam": ("colossus_stomp", {"damage": 1.2, "reach": 1.15}),
            "marshal_tidebreaker": ("colossus_overload", {"damage": 1.15}),
        },
        "enemy": {
            "max_hp": 1250, "power": 1.25, "defense": 6, "speed": 0.75, "scale": 2.2, "poise": 160, "xp": 5200,
            "moveset": {"light": "marshal_baton", "heavy": "marshal_charge"},
            "ai": {"spacing": 70, "reaction": 10, "cooldown": 38, "cooldown_jitter": 20, "heavy_chance": 0.3,
                   "heavy_cooldown": 320},
            "hazard": {"every": 200, "cycle": [
                {"kind": "shock", "warn": 60, "damage": 26, "half": [40, 14], "count": 4,
                      "spread": [260, 0], "stagger": 8},
                {"kind": "quake", "warn": 60, "damage": 28, "half": [24, 90]}]},
            "summon": {"enemy": "vault_trooper", "every": 560, "count": 2, "max": 3},
            "phases": [
                {"below": 0.6, "speed": 0.82, "power": 1.3, "cooldown": 32, "heavy_chance": 0.38,
                 "heavy_cooldown": 300,
                 "moveset": {"light": "marshal_baton", "heavy": "marshal_floodslam"},
                 "hazard": {"every": 150, "cycle": [
                     {"kind": "quake", "warn": 55, "damage": 30, "half": [24, 90]},
                     {"kind": "rain", "warn": 55, "damage": 28, "half": [14, 8], "count": 7,
                      "spread": [260, 40], "stagger": 5},
                     {"kind": "shock", "warn": 55, "damage": 26, "half": [60, 14]}]}},
                {"below": 0.3, "speed": 0.9, "power": 1.35, "cooldown": 28, "heavy_chance": 0.45,
                 "heavy_cooldown": 280, "shield": {"up": 280, "down": 360}, "summon_every": 420,
                 "moveset": {"light": "marshal_baton", "heavy": "marshal_tidebreaker"},
                 "hazard": {"every": 110, "cycle": [
                     {"kind": "quake", "warn": 50, "damage": 32, "half": [24, 90], "count": 2,
                      "spread": [220, 0], "stagger": 14},
                     {"kind": "shock", "warn": 50, "damage": 30, "half": [40, 14], "count": 4,
                      "spread": [260, 0], "stagger": 8}]}},
            ],
        },
    },
    {
        "id": "crucible_king", "name": "The Crucible King", "clone": "furnace_baron",
        "spec_clone": "subject_zero", "level": 64, "players": 20, "tint": "#ffb070", "weapon": "wrench",
        "arena": "crucible_pit", "arena_name": "The Crucible Pit", "arena_clone": "old_scrapyard",
        "arena_palette": {"sky": "#1c0804", "buildings": ["#3a1408", "#46190a", "#2e1006"], "windows": "#ff8a3c",
                          "sidewalk": "#4e3a30", "street": "#2a140c"},
        "unlock": "k7_overdriven", "period_minutes": 480, "offset_minutes": 180,
        "prizes": [("crucible_maul", "Crucible King's Maul", "weapon"),
                   ("crucible_gauntlets", "Crucible Gauntlets", "hands"),
                   ("crucible_heart", "Heart of the Crucible", "charm")],
        "grade": "godforged", "item_level": 64,
        "moves": {
            "crucible_haymaker": ("baron_haymaker", {"damage": 1.35, "reach": 1.4}),
            "crucible_rush": ("baron_rush", {"damage": 1.25, "advance": 1.3}),
            "crucible_eruption": ("baron_furnace", {"damage": 1.3, "reach": 1.3}),
            "crucible_meltdown": ("colossus_overload", {"damage": 1.2, "reach": 1.1}),
        },
        "enemy": {
            "max_hp": 1350, "power": 1.3, "defense": 6, "speed": 0.8, "scale": 2.4, "poise": 170, "xp": 6400,
            "moveset": {"light": "crucible_haymaker", "heavy": "crucible_rush"},
            "ai": {"spacing": 74, "reaction": 9, "cooldown": 36, "cooldown_jitter": 18, "heavy_chance": 0.32,
                   "heavy_cooldown": 300},
            "hazard": {"every": 190, "cycle": [
                {"kind": "rain", "warn": 55, "damage": 22, "half": [14, 8], "count": 6,
                 "spread": [240, 40], "stagger": 6},
                {"kind": "steam", "warn": 55, "damage": 28, "half": [26, 10]}]},
            "summon": {"enemy": "furnace_hauler", "every": 540, "count": 2, "max": 3},
            "phases": [
                {"below": 0.66, "speed": 0.86, "power": 1.35, "cooldown": 30, "heavy_chance": 0.4,
                 "heavy_cooldown": 280,
                 "moveset": {"light": "crucible_haymaker", "heavy": "crucible_eruption"},
                 "hazard": {"every": 140, "cycle": [
                     {"kind": "rain", "warn": 50, "damage": 24, "half": [14, 8], "count": 8,
                      "spread": [280, 44], "stagger": 5},
                     {"kind": "quake", "warn": 55, "damage": 30, "half": [24, 90]},
                     {"kind": "steam", "warn": 50, "damage": 30, "half": [26, 10]}]}},
                {"below": 0.33, "speed": 0.92, "power": 1.42, "cooldown": 26, "heavy_chance": 0.5,
                 "heavy_cooldown": 260, "shield": {"up": 300, "down": 340}, "summon_every": 400,
                 "moveset": {"light": "crucible_haymaker", "heavy": "crucible_meltdown"},
                 "hazard": {"every": 100, "cycle": [
                     {"kind": "rain", "warn": 45, "damage": 26, "half": [14, 8], "count": 10,
                      "spread": [320, 46], "stagger": 4},
                     {"kind": "quake", "warn": 50, "damage": 32, "half": [24, 90], "count": 2,
                      "spread": [200, 0], "stagger": 12}]}},
            ],
        },
    },
    {
        "id": "founders_engine", "name": "The Founder's Engine", "clone": "unit_k7",
        "spec_clone": "subject_zero", "level": 70, "players": 30, "tint": "#ffe08a", "weapon": "machete",
        "arena": "founders_floor", "arena_name": "The Founder's Floor", "arena_clone": "sovereign_vault",
        "arena_palette": {"sky": "#0e0c06", "buildings": ["#2a2410", "#342c14", "#211c0c"], "windows": "#ffd25a",
                          "sidewalk": "#4a4436", "street": "#221e14"},
        "unlock": "wiroj_protocol", "period_minutes": 1440, "offset_minutes": 840,
        "prizes": [("founders_edge", "The Founder's Edge", "weapon"), ("founders_plate", "Founder's Plate", "body"),
                   ("founders_halo", "Founder's Halo", "head"), ("founders_engine_core", "Engine Heart", "charm")],
        "grade": "godforged", "item_level": 70,
        "moves": {
            "founder_piston": ("k7_piston", {"damage": 1.45, "reach": 1.5}),
            "founder_press": ("k7_press", {"damage": 1.35, "reach": 1.35}),
            "founder_overdrive": ("k7_overdrive", {"damage": 1.35, "advance": 1.35}),
            "founder_cataclysm": ("colossus_overload", {"damage": 1.3, "reach": 1.2}),
            "founder_last_light": ("wiroj_ruin", {"damage": 1.35, "reach": 1.3}),
        },
        "enemy": {
            "max_hp": 1500, "power": 1.35, "defense": 7, "speed": 0.8, "scale": 2.6, "poise": 190, "xp": 8000,
            "moveset": {"light": "founder_piston", "heavy": "founder_press"},
            "ai": {"spacing": 80, "reaction": 9, "cooldown": 34, "cooldown_jitter": 16, "heavy_chance": 0.34,
                   "heavy_cooldown": 310},
            "hazard": {"every": 180, "cycle": [
                {"kind": "shock", "warn": 58, "damage": 28, "half": [40, 14], "count": 4,
                      "spread": [260, 0], "stagger": 8},
                {"kind": "shock", "warn": 55, "damage": 26, "half": [60, 14]},
                {"kind": "quake", "warn": 58, "damage": 30, "half": [24, 90]}]},
            "summon": {"enemy": "iron_sentry", "every": 520, "count": 2, "max": 3},
            "phases": [
                {"below": 0.7, "speed": 0.86, "power": 1.4, "cooldown": 30, "heavy_chance": 0.4,
                 "heavy_cooldown": 290,
                 "moveset": {"light": "founder_piston", "heavy": "founder_overdrive"},
                 "hazard": {"every": 130, "cycle": [
                     {"kind": "rain", "warn": 50, "damage": 24, "half": [14, 8], "count": 8,
                      "spread": [300, 44], "stagger": 5},
                     {"kind": "shock", "warn": 52, "damage": 30, "half": [40, 14], "count": 4,
                      "spread": [260, 0], "stagger": 8},
                     {"kind": "crane", "warn": 60, "damage": 30, "half": [30, 10]}]}},
                {"below": 0.4, "speed": 0.92, "power": 1.45, "cooldown": 26, "heavy_chance": 0.48,
                 "heavy_cooldown": 275, "shield": {"up": 300, "down": 330}, "summon_every": 380,
                 "moveset": {"light": "founder_piston", "heavy": "founder_cataclysm"},
                 "hazard": {"every": 100, "cycle": [
                     {"kind": "quake", "warn": 48, "damage": 32, "half": [24, 90], "count": 3,
                      "spread": [260, 0], "stagger": 10},
                     {"kind": "shock", "warn": 48, "damage": 30, "half": [60, 14]},
                     {"kind": "rain", "warn": 45, "damage": 26, "half": [14, 8], "count": 10,
                      "spread": [320, 46], "stagger": 4}]}},
                {"below": 0.15, "speed": 1.0, "power": 1.5, "cooldown": 22, "heavy_chance": 0.55,
                 "heavy_cooldown": 262,
                 "moveset": {"light": "founder_piston", "heavy": "founder_last_light"},
                 "hazard": {"every": 85, "cycle": [
                     {"kind": "shock", "warn": 46, "damage": 32, "half": [40, 14], "count": 4,
                      "spread": [260, 0], "stagger": 8},
                     {"kind": "quake", "warn": 46, "damage": 34, "half": [24, 90], "count": 3,
                      "spread": [260, 0], "stagger": 8},
                     {"kind": "rain", "warn": 42, "damage": 28, "half": [14, 8], "count": 12,
                      "spread": [340, 46], "stagger": 3}]}},
            ],
        },
    },
]

NOUNS = {
    "weapon": "Knuckles", "body": "Plate", "head": "Helm", "hands": "Gloves", "feet": "Boots", "charm": "Charm",
}


def godot_prices(request):
    """[{"budget", "score"}] for each item in `request`, from the game's own ItemRules
    (client/tests/harness/ItemBudgetQuery.gd): the tool never re-implements the rule."""
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
        json.dump(request, handle)
        path = handle.name
    try:
        run = subprocess.run(
            [GODOT, "--headless", "--path", str(ROOT / "client"), "--script",
             "res://tests/harness/ItemBudgetQuery.gd", "--", "--in=" + path],
            capture_output=True, text=True, check=False)
    finally:
        os.unlink(path)
    for line in run.stdout.splitlines():
        if line.startswith("BUDGETS "):
            return json.loads(line[len("BUDGETS "):])
    raise SystemExit("ItemBudgetQuery failed:\n" + run.stdout + run.stderr)


# Stat mixes picked by hand where the highest existing piece of a grade is an
# early one with a skewed mix (the only uncommon charm is the level 3 Lucky Coin,
# nearly all crit): (slot, grade) -> the existing item whose mix is reused.
TEMPLATE_OVERRIDES = {("charm", "uncommon"): "kenjis_lucky_charm"}


def template(items, slot, grade):
    """The highest-level existing item of `slot` (preferring `grade`), whose stat mix is reused."""
    if (slot, grade) in TEMPLATE_OVERRIDES:
        item_id = TEMPLATE_OVERRIDES[(slot, grade)]
        return item_id, items[item_id]
    gear = [(k, v) for k, v in items.items() if v.get("type") == "equipment" and v.get("slot") == slot
            and not is_generated(k)]
    same = [kv for kv in gear if kv[1].get("rarity") == grade] or gear
    return max(same, key=lambda kv: (int(kv[1].get("level", 1)), len(kv[1].get("stats", {}))))


PENDING = []


def is_generated(item_id):
    """True for an id this script writes (so a re-run never templates its own output)."""
    for tier in TIERS:
        for grade in ("uncommon", "rare", "epic"):
            if item_id.startswith("%s_%s_" % (tier["key"], grade)):
                return True
    if any(item_id == p[0] for p in GAP_GROUND["gear"]):
        return True
    return any(item_id == p[0] for wb in WORLD_BOSSES for p in wb["prizes"])


def make_item(items, item_id, name, slot, grade, level, description, price=0):
    """Adds an item with its template's stat mix; price_pending() scales the stats to the budget."""
    _, base = template(items, slot, "legendary" if grade == "godforged" else grade)
    item = {"name": name, "type": "equipment", "slot": slot, "rarity": grade, "level": level,
            "price": price, "stats": dict(base["stats"]), "icon": base.get("icon", ""),
            "description": description}
    items[item_id] = item
    PENDING.append(item_id)
    return item_id


def price_pending(items):
    """Scales every new item's stats so its score meets its ItemRules budget exactly."""
    request = [items[i] for i in PENDING]
    for item_id, priced in zip(PENDING, godot_prices(request)):
        item = items[item_id]
        factor = float(priced["budget"]) / float(priced["score"])
        stats = {}
        for key, value in item["stats"].items():
            scaled = float(value) * factor
            stats[key] = int(round(scaled)) if key in ("max_hp", "defense") else round(scaled, 2)
        item["stats"] = stats
        if item["price"]:
            item["price"] = int(round(float(priced["budget"]) * SHOP_PRICE_PER_POINT, -1))


def tier_items(items, tier):
    out = {"uncommon": [], "rare": [], "epic": []}
    for grade in out:
        word = tier[grade]
        for slot in SLOTS:
            item_id = "%s_%s_%s" % (tier["key"], grade, slot)
            name = "%s %s" % (word, NOUNS[slot])
            price = 1 if grade == "uncommon" else 0
            where = {"uncommon": "Ama's Market stocks it once the way down is open.",
                     "rare": "Carried by the %s's guards." % tier["ground_name"],
                     "epic": "Taken from %s." % tier["boss"][1]}[grade]
            make_item(items, item_id, name, slot, grade, tier["level"], where, price)
            out[grade].append(item_id)
    return out


def clone_enemy(enemies, new_id, name, base_id, loot, elite=None):
    data = json.loads(json.dumps(enemies[base_id]))
    data["name"] = name
    data["loot"] = loot
    if elite:
        data["elite"] = True
    else:
        # A ground has one elite (its champion); a clone of an elite base is a plain monster.
        data.pop("elite", None)
    enemies[new_id] = data
    return data


def coins(tier, low, high):
    """A field monster's coin range, scaled by the tier's "coins" factor: measured with
    FarmCheck so the coins per hour climb smoothly from Core Overflow's (about 35k/h at
    level 50) to about 47k, 49k, 62k and 77k/h on the four grounds (20-seed runs)."""
    factor = float(tier.get("coins", 1.0))
    return [max(1, int(round(low * factor))), max(2, int(round(high * factor)))]


def scaled_xp(tier, base):
    """A field monster's XP, its base kind's times the tier's "xp" factor: the roles are
    lighter or heavier than one another, so each tier's factor is measured with FarmCheck to
    keep its XP per hour where the level curve's target hours need it."""
    return max(1, int(round(int(base["xp"]) * float(tier.get("xp", 1.0)))))


def tier_enemies(enemies, tier, gear):
    lvl = tier["level"]
    alloy = min(0.45, 0.2 + 0.03 * (lvl - 50) / 5)
    share = len(gear["rare"]) // len(tier["mobs"])
    for i, (mob_id, name, base, _weight) in enumerate(tier["mobs"]):
        rares = gear["rare"][i * share:(i + 1) * share]
        drops = [{"item": "rice_box", "chance": 0.12}, {"item": "herbal_tonic", "chance": 0.05}]
        drops += [{"item": r, "chance": 0.02} for r in rares]
        drops += [{"item": "refined_alloy", "chance": round(alloy, 2)}, {"item": "scrap_metal", "chance": 0.8}]
        mob = clone_enemy(enemies, mob_id, name, base,
                          {"money": coins(tier, 30 + lvl // 2, 48 + lvl // 2), "drops": drops})
        mob["tint"] = tier["tint"][0]
        mob["xp"] = scaled_xp(tier, enemies[base])
    champ_id, champ_name, champ_base = tier["champion"]
    drops = [{"item": "herbal_tonic", "chance": 0.25}]
    drops += [{"item": r, "chance": 0.04} for r in gear["rare"]]
    drops += [{"item": e, "chance": 0.01} for e in gear["epic"][:2]]
    drops += [{"item": "refined_alloy", "chance": 0.6}, {"item": "scrap_metal", "chance": 1.0}]
    champ = clone_enemy(enemies, champ_id, champ_name, champ_base,
                        {"money": coins(tier, 80 + lvl, 120 + lvl), "drops": drops}, elite=True)
    champ["tint"] = tier["tint"][1]
    champ["xp"] = scaled_xp(tier, enemies[champ_base])
    boss_id, boss_name, boss_base = tier["boss"]
    drops = [{"item": e, "chance": 0.15} for e in gear["epic"]]
    drops += [{"item": "refined_alloy", "chance": 1.0}, {"item": "herbal_tonic", "chance": 0.5}]
    boss = clone_enemy(enemies, boss_id, boss_name, boss_base,
                       {"money": [900 + 20 * lvl, 1200 + 20 * lvl], "drops": drops})
    boss["enrage"] = dict(REMATCH_ENRAGE)
    boss["max_hp"] = int(round(int(enemies[boss_base]["max_hp"]) * tier.get("boss_hp", LAIR_BOSS_HP)))
    boss["tint"] = tier["tint"][1]


def ground_area(areas, tier):
    base = json.loads(json.dumps(areas["farm_core_overflow"]))
    base.update({
        "name": tier["ground_name"], "level": tier["level"], "theme": tier["theme"], "kit_theme": tier["kit"],
        "palette": tier["palette"], "region": "Main Control Centre", "purpose": tier["purpose"],
        "unlock": {"defeated": tier["unlock"]}, "width": 2000,
    })
    base["spawning"] = dict(base["spawning"])
    pool = {mob[0]: mob[3] for mob in tier["mobs"]}
    pool[tier["champion"][0]] = 1
    base["spawning"]["pool"] = pool
    base["spawning"]["reward_scale"] = 0.6
    base["spawning"]["elite_drops"] = [{"item": "%s_epic_body" % tier["key"], "chance": 0.02}]
    base["obstacles"] = [{"kind": "oil_drums", "x": 300, "y": 258}, {"kind": "crates", "x": 640, "y": 258},
                         {"kind": "oil_drums", "x": 980, "y": 258}, {"kind": "crates", "x": 1320, "y": 258}]
    areas[tier["ground"]] = base
    lair_area(areas, tier["lair"], tier["lair_name"], base, tier["boss"][0], tier["mobs"][0][0], tier["unlock"],
              "%s's stand at the end of the %s: a boss fight that comes back after every rest, with %s gear."
              % (tier["boss"][1], tier["ground_name"], tier["epic"]))


def gap_area(areas, enemies, items):
    base = json.loads(json.dumps(areas["farm_facility_annex"]))
    g = GAP_GROUND
    base.update({"name": g["name"], "level": g["level"], "region": g["region"], "purpose": g["purpose"],
                 "unlock": {"defeated": g["unlock"]}})
    gear = []
    for item_id, name, slot in g["gear"]:
        make_item(items, item_id, name, slot, "epic", g["gear_level"], "Taken from the %s." % g["boss"][1])
        gear.append(item_id)
    base["spawning"] = dict(base["spawning"])
    base["spawning"]["pool"] = dict(g["pool"])
    base["spawning"]["elite_drops"] = [{"item": i, "chance": 0.02} for i in gear]
    boss_id, boss_name, boss_base = g["boss"]
    drops = [{"item": i, "chance": 0.2} for i in gear]
    drops += [{"item": "refined_alloy", "chance": 1.0}, {"item": "herbal_tonic", "chance": 0.5}]
    boss = clone_enemy(enemies, boss_id, boss_name, boss_base, {"money": [500, 700], "drops": drops})
    boss["tint"] = "#cfdcff"
    boss["enrage"] = dict(REMATCH_ENRAGE)
    boss["max_hp"] = int(round(int(enemies[boss_base]["max_hp"]) * g.get("boss_hp", LAIR_BOSS_HP)))
    areas[g["id"]] = base
    lair_area(areas, g["lair"], g["lair_name"], base, boss_id, "facility_trooper", g["unlock"],
              "The spillway's gatehouse, where the Spillway Chief keeps the sluice keys: a boss fight "
              "that comes back after every rest, with Spillway Chief gear.")


def lair_area(areas, lair_id, name, ground, boss_id, guard, unlock, purpose):
    """A boss lair (AreaRules.LAIR): one boss fight in a short arena, reached by the field truck,
    opened with its farming ground and back after every rest."""
    lair = {key: json.loads(json.dumps(ground[key])) for key in ("theme", "kit_theme", "palette", "region")
            if key in ground}
    lair.update({
        "name": name, "level": int(ground["level"]) + 2, "width": 1300, "safe": False, "kind": "lair",
        "purpose": purpose, "unlock": {"defeated": unlock},
        "exits": {"west": {"to": "main_city", "entry": "west"}}, "npcs": [], "placed": [],
        "weapons": {"count": [1, 2], "pool": {"pipe": 2, "wrench": 2}},
        "obstacles": [{"kind": "oil_drums", "x": 260, "y": 258}, {"kind": "crates", "x": 1180, "y": 258}],
        "encounters": [{"trigger_x": 420, "arena": [300, 1280], "max_alive": 3,
                        "waves": [[boss_id], [guard, guard]]}],
    })
    areas[lair_id] = lair


# Farm grounds' enemy toughness and pay (the owner's request, November 2026:
# some grounds died far too easily to unenhanced gear). Measured with
# FarmCheck (shop gear +0, hero at the ground's level, 4 seeds) so the time to
# clear an enemy and the damage taken rise in step with the level, and the pay
# rises with the toughness, so a harder ground is not a worse one.
# {ground: (hp, power, reward_scale)}
FARM_TUNING = {
    "farm_saltmarket_backlots": (3.0, 1.3, 1.0),
    "farm_rail_sidings": (2.3, 1.2, 1.0),
    "farm_harbour_stacks": (1.45, 1.1, 0.91),
    "farm_plant_outskirts": (1.0, 1.0, 0.72),
    "farm_network_backrooms": (1.55, 1.1, 0.74),
    "farm_facility_annex": (1.0, 1.0, 0.63),
    "farm_core_spillway": (1.0, 1.0, 0.63),
    "farm_core_overflow": (1.0, 1.0, 0.57),
    "farm_coolant_vaults": (1.1, 1.0, 0.66),
    "farm_reactor_underworks": (1.55, 1.15, 0.93),
    "farm_foundry_depths": (1.0, 1.0, 0.6),
    "farm_iron_heart": (1.0, 1.0, 0.6),
}


def tune_farms(areas):
    for area_id, (hp, power, reward) in FARM_TUNING.items():
        spawning = areas[area_id]["spawning"]
        spawning["toughness"] = {"hp": hp, "power": power}
        spawning["reward_scale"] = reward


# Each ground's own prizes, on any enemy there (the owner's request: a reason
# to leave the story and farm). The Uncommon and Rare gear of the ground's
# band, no shop sells it: a share of FARM_DROP_TOTAL per grade, split evenly.
FARM_DROP_WINDOW = (7, 1)
FARM_DROP_TOTAL = {"uncommon": 0.02, "rare": 0.006}


def farm_drops(areas, items, quests):
    rewards = set()
    for quest in quests.values():
        rewards |= set(quest.get("rewards", {}).get("items", {}))
    for area_id, area in areas.items():
        if area.get("kind") != "farm":
            continue
        level = int(area["level"])
        drops = []
        for grade, total in FARM_DROP_TOTAL.items():
            ids = sorted(k for k, v in items.items()
                         if v.get("type") == "equipment" and v.get("rarity") == grade
                         and level - FARM_DROP_WINDOW[0] <= int(v["level"]) <= level + FARM_DROP_WINDOW[1]
                         and not v.get("unique") and k not in rewards)
            drops += [{"item": k, "chance": round(total / len(ids), 4)} for k in ids]
        area["spawning"]["drops"] = drops


def chain_farm_exits(areas):
    """Farming grounds are walked like a street: west out of a ground leads into the next lower
    ground (arriving at its east end), and only the lowest leads back west to the city. Grounds
    open in order of level (each opens later in the story than the one below), so the way west
    is always open."""
    farms = sorted((k for k, v in areas.items() if v.get("kind") == "farm"),
                   key=lambda k: (int(areas[k].get("level", 1)), k))
    for i, area_id in enumerate(farms):
        west = {"to": "main_city", "entry": "west"} if i == 0 else {"to": farms[i - 1], "entry": "east"}
        areas[area_id]["exits"] = {"west": west}


def boss_moves(moves, wb):
    """A boss's own moves: each copies an existing move (its timing, its telegraph, so it reads
    fair) and multiplies the listed numbers (damage, reach, advance)."""
    for move_id, (source, scale) in wb.get("moves", {}).items():
        move = json.loads(json.dumps(moves[source]))
        for key, factor in scale.items():
            move[key] = int(round(float(move[key]) * factor))
        moves[move_id] = move


def world_boss(enemies, areas, specs, items, wb, moves):
    data = json.loads(json.dumps(enemies[wb["clone"]]))
    boss_moves(moves, wb)
    if "enemy" in wb:
        # A raid boss of its own: the clone gives the sprite and the body; everything it does
        # in the fight (moves, skills, phases, summons) is its own.
        for key in ("hazard", "summon", "phases", "moveset", "ai"):
            data.pop(key, None)
        data.update(json.loads(json.dumps(wb["enemy"])))
        data["boss"] = True
        data["wields"] = False
    data["name"] = wb["name"]
    data["tint"] = wb["tint"]
    data["weapon"] = wb["weapon"]  # world bosses fight armed (held weapons last longer: LevelRules)
    # Rewards come from the world-boss tiers; the kill itself still guarantees
    # upgrade material, as every boss does.
    data["loot"] = {"money": [0, 0], "drops": [{"item": "refined_alloy", "chance": 1.0}]}
    enemies[wb["id"]] = data
    arena = json.loads(json.dumps(areas[wb["arena_clone"]]))
    arena["name"] = wb["arena_name"]
    arena["level"] = wb["level"] - 2
    if "arena_palette" in wb:
        arena["palette"] = dict(wb["arena_palette"])
    arena["encounters"] = [{"trigger_x": 120, "arena": [60, 1280], "max_alive": 4, "waves": [[wb["id"]]]}]
    areas[wb["arena"]] = arena
    prize_ids = []
    for item_id, name, slot in wb["prizes"]:
        make_item(items, item_id, name, slot, wb["grade"], wb["item_level"], "A prize of %s." % wb["name"])
        prize_ids.append(item_id)
    base = json.loads(json.dumps(specs[wb.get("spec_clone", wb["clone"])]))
    base.pop("unlock", None)  # the owner's rule: open to every hero from one entry level
    rare_roll = 0.03 if wb["players"] >= 10 else 0.05
    rolls = {p: rare_roll for p in prize_ids}
    base.update({
        "enemy": wb["id"], "area": wb["arena"], "level": wb["level"],
        "players": wb["players"], "period_minutes": wb["period_minutes"], "offset_minutes": wb["offset_minutes"],
        "open_minutes": 60, "enrage": dict(WORLD_BOSS_ENRAGE),
    })
    base["tiers"] = [
        {"share": 0.1, "money": 1500, "items": {"refined_alloy": 5}},
        {"share": 0.3, "money": 2500, "items": {"refined_alloy": 8, "herbal_tonic": 3}},
        {"share": 0.6, "money": 3500, "items": {"refined_alloy": 10}},
        {"share": 1.0, "money": 5000, "items": {"refined_alloy": 14}, "rolls": dict(rolls)},
    ]
    base["kill"] = {"money": 7000, "items": {"refined_alloy": 18}, "rolls": {p: round(rare_roll * 3, 3) for p in prize_ids}}
    specs[wb["id"]] = base


def godforge_world_boss_prizes(items, specs):
    """Every world boss prize is Godforged (ItemRules: the top grade, world bosses only), its
    stats re-priced to that budget, so a world boss pays gear well above anything else of its
    level. Covers the bosses written by hand (the Tunnel Mother, the Iron Colossus, Subject
    Zero) as well as the ones this script writes; re-running re-prices from the budget, so the
    stats never compound."""
    for spec in specs.values():
        rewards = list(spec.get("tiers", [])) + [spec.get("kill", {})]
        for reward in rewards:
            for item_id in reward.get("rolls", {}):
                if item_id in items and item_id not in PENDING:
                    items[item_id]["rarity"] = "godforged"
                    PENDING.append(item_id)


# The owner's rule (November 2026): two shops in the city. Ama sells food,
# every grade, and nothing else; Kenji's stall sells gear, Common only. Every
# better grade comes from enemies, and upgrade materials are never sold. Each
# piece the market used to sell keeps its grade as a drop; the stall sells a
# Common copy ("Used ..."), opened by the same chapter as before.
GEAR_STALL = [
    ({}, ["taped_knuckles", "fingerless_gloves", "dock_beanie", "padded_vest", "canvas_sneakers",
          "work_jacket", "hard_hat", "steel_toe_boots"]),
    ({"reached": "night_market", "from": "Kenji"},
     ["riveted_jacket", "street_runners", "brass_knuckles", "iron_helm"]),
    ({"reached": "port_road", "from": "Noi"},
     ["dockers_cap", "port_jacket", "cargo_gloves", "deck_boots", "dock_hook"]),
    ({"reached": "factory_gate", "from": "Aunt Jum"},
     ["hazmat_hood", "plant_vest", "insulated_gloves", "lab_boots", "shock_baton"]),
    ({"reached": "warehouse_row", "from": "Uncle Thong"},
     ["watch_cap", "kevlar_jacket", "fight_gloves", "runner_sneakers", "weighted_knuckles"]),
    ({"reached": "facility_gate", "from": "Lek"},
     ["facility_helmet", "trooper_vest", "grip_gloves", "facility_boots", "riot_baton"]),
    ({"reached": "core_approach", "from": "Ama's supply run"},
     ["core_guard_helm", "reactor_plate", "insulated_gauntlets", "walkway_boots", "alloy_knuckles"]),
]
USED = []
FOOD_PRICES = {"steamed_bun": 10, "ginger_tea": 22, "rice_box": 55, "herbal_tonic": 110}


def used_copy(items, item_id):
    """A Common copy of `item_id` for the gear stall: same look and stat mix, a Common budget."""
    if items[item_id]["rarity"] == "common":
        return item_id
    copy_id = "used_" + item_id
    original = items[item_id]
    items[copy_id] = {
        "name": "Used " + original["name"], "type": "equipment", "slot": original["slot"],
        "rarity": "common", "level": original["level"], "price": 1,
        "stats": dict(original["stats"]), "icon": original.get("icon", ""),
        "description": "Second-hand, from Kenji's stall. The real thing drops on the street.",
    }
    PENDING.append(copy_id)
    USED.append(copy_id)
    return copy_id


def price_used(items):
    """A used copy costs what its original did, less the Common grade's share (0.85)."""
    for copy_id in USED:
        original = items[copy_id[len("used_"):]]
        items[copy_id]["price"] = max(10, int(round(original["price"] * 0.85, -1)))


def split_shops(shops, items, tiers):
    shops["city_market"] = {"name": "Ama's Kitchen", "items": list(FOOD_PRICES), "stock": []}
    for food, price in FOOD_PRICES.items():
        items[food]["price"] = price
    stock = []
    for rule, ids in GEAR_STALL:
        copies = [used_copy(items, i) for i in ids]
        if rule:
            stock.append(dict(rule, items=copies))
        else:
            first = copies
    for tier in tiers:
        ids = ["%s_uncommon_%s" % (tier["key"], slot) for slot in SLOTS]
        stock.append({"defeated": tier["unlock"], "from": "Ama's supply run",
                      "items": [used_copy(items, i) for i in ids]})
    shops["city_gear"] = {"name": "Kenji's Gear Stall", "items": first, "stock": stock}


def boss_fx(path, themes):
    text = path.read_text()
    for boss_id, theme in themes.items():
        if '"%s":' % boss_id in text:
            continue
        anchor = '    "subject_zero": "shadow"'
        assert anchor in text, "boss_fx.json layout changed"
        text = text.replace(anchor, anchor + ',\n    "%s": "%s"' % (boss_id, theme), 1)
    path.write_text(text)


def load(name):
    return json.loads((DATA / name).read_text())


def save(name, data):
    (DATA / name).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def main():
    items_doc, enemies_doc, areas_doc = load("items.json"), load("enemies.json"), load("areas.json")
    shops_doc, wb_doc, fx = load("shops.json"), load("world_boss.json"), load("boss_fx.json")
    items = items_doc.get("items", items_doc)
    enemies = enemies_doc.get("enemies", enemies_doc)
    areas = areas_doc["areas"]
    specs = wb_doc["world_bosses"]
    gear = {}
    for tier in TIERS:
        gear[tier["key"]] = tier_items(items, tier)
        tier_enemies(enemies, tier, gear[tier["key"]])
        ground_area(areas, tier)
    gap_area(areas, enemies, items)
    chain_farm_exits(areas)
    tune_farms(areas)
    moves_doc = load("moves.json")
    for wb in WORLD_BOSSES:
        world_boss(enemies, areas, specs, items, wb, moves_doc["moves"])
    godforge_world_boss_prizes(items, specs)
    split_shops(shops_doc.get("shops", shops_doc), items, TIERS)
    price_pending(items)
    price_used(items)
    farm_drops(areas, items, load("quests.json")["quests"])
    themes = {t["boss"][0]: fx["bosses"][t["boss"][2]] for t in TIERS}
    themes[GAP_GROUND["boss"][0]] = fx["bosses"][GAP_GROUND["boss"][2]]
    themes.update({wb["id"]: fx["bosses"][wb["clone"]] for wb in WORLD_BOSSES})
    for name, doc in (("items.json", items_doc), ("enemies.json", enemies_doc), ("areas.json", areas_doc),
                      ("shops.json", shops_doc), ("world_boss.json", wb_doc), ("moves.json", moves_doc)):
        save(name, doc)
    boss_fx(DATA / "boss_fx.json", themes)
    count = len(PENDING)
    print("level70 content: %d items, %d grounds, %d world bosses" % (count, len(TIERS) + 1, len(WORLD_BOSSES)))


if __name__ == "__main__":
    main()
