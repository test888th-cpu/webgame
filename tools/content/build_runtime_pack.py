#!/usr/bin/env python3
"""Build the playable reference slice's runtime data (docs/PLAYABLE_SLICE.md).

  python3 tools/content/build_runtime_pack.py --ref <checkout> [--check]

Writes client/data/rpg/runtime_pack.json: everything the Godot runtime reads to play
the reference rules, generated from World of ClaudeCraft at the pinned commit and
the committed reference registries. The reference registries live outside the Godot
project (data/registry, absent from exported builds), so the runtime reads this pack.

Nothing here is a rule written by hand. Where the runtime needs a reference
function's answer, the pinned function is evaluated by tools/content/ts_eval.py on
the inputs the runtime will use, and the answer is stored:
* abilitiesKnownAt(cls, level, computeTalentModifiers(cls, {spec, rows: {}}, level))
  for every class, every spec (and no spec) and every level 1-20: the known list,
  each ability's rank, cost, cooldown, cast time and effects;
* computeTalentModifiers for each spec: the modifiers this runtime does NOT apply
  yet, listed so the game can say so;
* requiredLevelFor(item) for every item in the pack.

Ability executability: an ability runs in this runtime only when every effect is a
general single-target `weaponStrike` (effect_dispatch.ts weaponStrike arm, general
path) and nothing about it touches a case the runtime does not model (see
EXECUTABLE_RULES). Every other ability is listed with the reason it is refused.

Trial opponents: no area placement is approved (the monster selection matrix stays
PROPOSED), so the slice places nobody in a world area. The trial offers the
reference's own world mobs that the runtime can fight faithfully (TRIAL_RULES); the
player picks one. Display names are interim, from ids (reference names are never
shown).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_reference_registries as builder  # noqa: E402
import reference_content as rc  # noqa: E402
import ts_eval  # noqa: E402
import skills_port  # noqa: E402

ROOT = builder.ROOT
OUT = ROOT / "client" / "data" / "rpg" / "runtime_pack.json"
REGISTRY = builder.REGISTRY
MAX_LEVEL = 20

# The weaponStrike arm's special cases (effect_dispatch.ts:702-868): any ability
# id the arm names, or a field it branches on, is outside the general path.
SPECIAL_WEAPON_STRIKE_IDS = {
    "mortal_strike", "raging_gale", "final_edict", "raptor_strike", "mongoose_bite",
    "red_harvest", "hammer_of_grace", "vowkeeper_strike",
}
GENERAL_EFFECT_KEYS = {"type", "bonus", "weaponMult", "normalized", "cannotBeDodged"}
GENERAL_DEF_KEYS = {
    "id", "name", "class", "learnLevel", "cost", "castTime", "cooldown", "range", "school",
    "requiresTarget", "effects", "ranks", "description", "threat", "specs", "excludeSpecs",
    "excludeSpecsAtLevel", "specNotes",
}
EXECUTABLE_RULES = [
    "every effect is weaponStrike with only bonus, weaponMult, normalized, cannotBeDodged "
    "(no sweepRadius, selfHealDamageFrac or restoreMana: effect_dispatch.ts:704, :723, :783)",
    "the ability id is not one the weaponStrike arm special-cases "
    "(effect_dispatch.ts:727, :741, :751, :757, :772, :829, :846)",
    "the ability declares nothing the runtime does not model (combo points, forms, "
    "stealth, positional requirements, charges, procs, next-swing queues, cast times)",
    "the ability costs no more than its class resource and has no cast time",
]
TRIAL_RULES = [
    "a MOBS record in the base world (context 'world'), classification 'normal'",
    "not of a family that flees at low health (mob/flee_rules.ts FLEEING_FAMILIES)",
    "no mechanic and no special flag (no dummy, practice target, muster, idle or "
    "immunity fields): it fights with its swing only, as the runtime models",
    "its loot rows use only chance, copper, itemId, rollGroup and questId (no heroic, "
    "level-cap or ownership gates); a questId row drops only for a player on that quest, "
    "and this build has no quests, so it never drops (loot.ts quest gate)",
]
TRIAL_SOURCE_FIELDS = {
    "aggroRadius", "armorPerLevel", "attackSpeed", "color", "dmgBase", "dmgPerLevel", "family",
    "hpBase", "hpPerLevel", "id", "maxLevel", "minLevel", "moveSpeed", "name", "scale",
    "xpMult", "respawnSeconds", "untameable", "componentTags", "loot",
}
LOOT_ROW_FIELDS = {"chance", "copper", "itemId", "rollGroup", "questId"}


# Constants the runtime reads, each from its own source binding.
CONSTANT_SOURCES = {
    "tick_rate": ("src/sim/types.ts", "TICK_RATE"),
    "melee_range": ("src/sim/types.ts", "MELEE_RANGE"),
    "melee_arc": ("src/sim/types.ts", "MELEE_ARC"),
    "projectile_speed": ("src/sim/projectile_travel.ts", "PROJECTILE_SPEED"),
    "projectile_reach": ("src/sim/projectile_travel.ts", "PROJECTILE_REACH"),
    "projectile_max_flight": ("src/sim/projectile_travel.ts", "PROJECTILE_MAX_FLIGHT"),
    "ranged_weapon_coeff": ("src/sim/combat/auto_attack.ts", "RANGED_WEAPON_COEFF"),
    "res_hp_fraction": ("src/sim/spirit.ts", "RES_HP_FRACTION"),
    "stance_rage_gen": ("src/sim/types.ts", "STANCE_RAGE_GEN"),
    "healing_sp_scale": ("src/sim/spell_scaling.ts", "HEALING_SP_SCALE"),
    "melee_spell_ap_scale": ("src/sim/types.ts", "MELEE_SPELL_AP_SCALE"),
    "ranged_spell_ap_scale": ("src/sim/types.ts", "RANGED_SPELL_AP_SCALE"),
    "spell_aoe_coeff_mult": ("src/sim/types.ts", "SPELL_AOE_COEFF_MULT"),
    "spell_coeff_divisor": ("src/sim/types.ts", "SPELL_COEFF_DIVISOR"),
    "spell_coeff_min_cast": ("src/sim/types.ts", "SPELL_COEFF_MIN_CAST"),
    "spell_coeff_max_cast": ("src/sim/types.ts", "SPELL_COEFF_MAX_CAST"),
    "spell_dot_coeff_duration": ("src/sim/types.ts", "SPELL_DOT_COEFF_DURATION"),
    "gcd": ("src/sim/types.ts", "GCD"),
    "max_aggro_radius": ("src/sim/mob/aggro_ranges.ts", "MAX_AGGRO_RADIUS"),
    "trivial_level_gap": ("src/sim/mob/targeting.ts", "TRIVIAL_LEVEL_GAP"),
    "corpse_duration": ("src/sim/combat/damage.ts", "CORPSE_DURATION"),
    "trash_respawn_seconds": ("src/sim/respawn_policy.ts", "TRASH_RESPAWN_SECONDS"),
    "run_speed": ("src/sim/types.ts", "RUN_SPEED"),
    "min_gcd": ("src/sim/types.ts", "MIN_GCD"),
    # Class mechanics (docs/SKILLS_PORT.md).
    "charge_max_duration": ("src/sim/combat/effect_dispatch.ts", "CHARGE_MAX_DURATION"),
    "charge_speed_mult": ("src/sim/combat/charge_route.ts", "CHARGE_SPEED_MULT"),
    "fear_break_chance_scale": ("src/sim/combat/effect_dispatch.ts", "FEAR_BREAK_CHANCE_SCALE"),
    "enrage_dmg_done": ("src/sim/types.ts", "ENRAGE_DMG_DONE"),
    "battle_trance_duration": ("src/sim/types.ts", "BATTLE_TRANCE_DURATION"),
    "sudden_death_duration": ("src/sim/combat/auto_attack.ts", "SUDDEN_DEATH_DURATION"),
    "stance_mastery_battle_crit_dmg": ("src/sim/types.ts", "STANCE_MASTERY_BATTLE_CRIT_DMG"),
    "stance_mastery_berserker_haste": ("src/sim/types.ts", "STANCE_MASTERY_BERSERKER_HASTE"),
    "stance_mastery_guarded_hp_pct": ("src/sim/types.ts", "STANCE_MASTERY_GUARDED_HP_PCT"),
    "stance_mastery_guarded_cut": ("src/sim/types.ts", "STANCE_MASTERY_GUARDED_CUT"),
    "enrage_haste_pct": ("src/sim/types.ts", "ENRAGE_HASTE_PCT"),
    "berserker_crit_chance": ("src/sim/types.ts", "BERSERKER_CRIT_CHANCE"),
    "berserker_crit_damage": ("src/sim/types.ts", "BERSERKER_CRIT_DAMAGE"),
    "second_wind_threshold": ("src/sim/combat/auras.ts", "SECOND_WIND_THRESHOLD"),
    "victory_rush_window": ("src/sim/combat/damage.ts", "VICTORY_RUSH_WINDOW"),
    "pursuit_speed_duration": ("src/sim/combat/damage.ts", "PURSUIT_SPEED_DURATION"),
    "bloodbath_duration": ("src/sim/combat/damage.ts", "BLOODBATH_DURATION"),
    "bloodbath_max_stacks": ("src/sim/combat/damage.ts", "BLOODBATH_MAX_STACKS"),
    "colossal_might_cap_seconds": ("src/sim/combat/casting_lifecycle.ts", "COLOSSAL_MIGHT_CAP_SECONDS"),
    "colossal_might_cap_window": ("src/sim/combat/casting_lifecycle.ts", "COLOSSAL_MIGHT_CAP_WINDOW"),
    "aoe_echo_radius": ("src/sim/combat/area_echo.ts", "AOE_ECHO_RADIUS"),
    "aoe_echo_mult": ("src/sim/combat/area_echo.ts", "AOE_ECHO_MULT"),
    "aoe_echo_max_targets": ("src/sim/combat/area_echo.ts", "AOE_ECHO_MAX_TARGETS"),
    "sweep_mult": ("src/sim/combat/area_echo.ts", "SWEEP_MULT"),
    "combo_point_duration": ("src/sim/sim.ts", "COMBO_POINT_DURATION"),
    "warlock_fear_damage_budget_pct": ("src/sim/combat/warlock_fear.ts", "WARLOCK_FEAR_DAMAGE_BUDGET_PCT"),
    "vespers_dot_damage_mult": ("src/sim/combat/priest/vespers.ts", "VESPERS_DOT_DAMAGE_MULT"),
    "enrage_move_mult": ("src/sim/types.ts", "ENRAGE_MOVE_MULT"),
    "cat_form_move_mult": ("src/sim/types.ts", "CAT_FORM_MOVE_MULT"),
    "sporemender_move_speed_mult": ("src/sim/combat/druid_sporemender.ts", "SPOREMENDER_MOVE_SPEED_MULT"),
    "sunder_armor_pct_per_stack": ("src/sim/types.ts", "SUNDER_ARMOR_PCT_PER_STACK"),
    "faerie_fire_armor_pct": ("src/sim/types.ts", "FAERIE_FIRE_ARMOR_PCT"),
    "flee_speed_mult": ("src/sim/flee_speed.ts", "FLEE_SPEED_MULT"),
    "flee_max_speed": ("src/sim/flee_speed.ts", "FLEE_MAX_SPEED"),
    "cat_form_swing_speed": ("src/sim/combat/form_swing.ts", "CAT_FORM_SWING_SPEED"),
    "cat_form_damage_mult": ("src/sim/combat/form_swing.ts", "CAT_FORM_DAMAGE_MULT"),
    "bear_form_swing_mult": ("src/sim/combat/form_swing.ts", "BEAR_FORM_SWING_MULT"),
    "bear_form_auto_damage_mult": ("src/sim/combat/form_swing.ts", "BEAR_FORM_AUTO_DAMAGE_MULT"),
    "bear_form_auto_rage_mult": ("src/sim/combat/form_swing.ts", "BEAR_FORM_AUTO_RAGE_MULT"),
    "revenge_free_chance": ("src/sim/types.ts", "REVENGE_FREE_CHANCE"),
    "revenge_free_duration": ("src/sim/types.ts", "REVENGE_FREE_DURATION"),
    "sated_duration": ("src/sim/combat/haste_burst.ts", "SATED_DURATION"),
    "overload_cost_mult": ("src/sim/combat/casting_lifecycle.ts", "OVERLOAD_COST_MULT"),
}

# The effect arms, aura kinds and definition fields this runtime executes, and the
# reference code it has ported, are the skills port's register (skills_port.py).
IMPLEMENTED_EFFECTS = set(skills_port.EFFECT_FIELDS)
IMPLEMENTED_AURA_KINDS = skills_port.AURA_KINDS
# Reference files whose code changes how a solo fight plays. An ability whose id appears
# in one of them has behaviour beyond its effect arm's general path. Files outside these
# (PvP diminishing returns, party threat, Rift, raids, social, tutorials, dev tools,
# tooltips) cannot change a one-player trial fight.
BEHAVIOUR_PREFIXES = (
    "src/sim/combat/", "src/sim/sim.ts", "src/sim/entity.ts", "src/sim/types.ts",
    "src/sim/paladin_devotion.ts", "src/sim/effective_stats.ts", "src/sim/player_motion.ts",
    "src/sim/major_cooldowns.ts", "src/sim/aura_classify.ts", "src/sim/mob/",
)
AUDITED_MENTIONS = skills_port.NOT_BEHAVIOUR
ALLOWED_DEF_KEYS = skills_port.DEF_KEYS


def engine_references(checkout: Path, ids: set[str]) -> dict[str, list[str]]:
    """Behaviour files that name each ability id as a string literal."""
    files = subprocess.run(["git", "-C", str(checkout), "ls-tree", "-r", "--name-only",
                            builder.COMMIT, "src/sim"], capture_output=True, text=True,
                           check=True).stdout.split()
    out: dict[str, set] = {}
    for f in files:
        if not f.endswith(".ts") or ".test." in f or not f.startswith(BEHAVIOUR_PREFIXES):
            continue
        text = subprocess.run(["git", "-C", str(checkout), "show", f"{builder.COMMIT}:{f}"],
                              capture_output=True, text=True, check=True).stdout
        text = re.sub(r"//[^\n]*", "", text)
        for m in re.finditer(r"'([a-z0-9_]+)'", text):
            if m.group(1) in ids:
                out.setdefault(m.group(1), set()).add(f)
    return {k: sorted(v) for k, v in out.items()}


def acquisition_paths(abilities: dict, classes: dict, talents: dict) -> dict[str, list[str]]:
    """How a player can come to know each ability (abilitiesKnownAt's inputs)."""
    out: dict[str, list[str]] = {}
    for cls in builder.CLASSES:
        for aid in classes[cls]["abilities"]:
            out.setdefault(aid, []).append(f"{cls} class kit")
        for spec in talents[cls]["specs"]:
            for aid in spec["signature_ids"]:
                out.setdefault(aid, []).append(f"{cls} {spec['id']} signature")
        for row in talents[cls]["rows"]:
            for opt in row["options"]:
                grant = (opt["effect"] or {}).get("grant")
                if grant:
                    out.setdefault(grant["ability"], []).append(f"{cls} talent {opt['id']}")
    for aid, d in abilities.items():
        rep = d.get("actionReplacement")
        reps = rep if isinstance(rep, list) else [rep] if rep else []
        for r in reps:
            cond = r.get("auraKind") or ("no " + str(r.get("absentAuraKind")))
            out.setdefault(r["abilityId"], []).append(f"replaces {aid} while {cond}")
    return {k: sorted(set(v)) for k, v in out.items()}


def effect_kinds(d: dict) -> set[str]:
    kinds = {e["type"] for e in d.get("effects") or []}
    for r in d.get("ranks") or []:
        kinds |= {e["type"] for e in r.get("effects") or []}
    return kinds


def aura_kinds(d: dict) -> set[str]:
    out = set()
    for effs in [d.get("effects") or []] + [r.get("effects") or [] for r in d.get("ranks") or []]:
        for e in effs:
            if e["type"] in ("selfBuff", "buffTarget"):
                out.add(e["kind"])
    return out


def effect_field_gaps(d: dict) -> list[str]:
    """Effect fields no ported arm reads, as "type.field"."""
    out = set()
    for effs in [d.get("effects") or []] + [r.get("effects") or [] for r in d.get("ranks") or []]:
        for e in effs:
            handled = skills_port.EFFECT_FIELDS.get(e["type"])
            if handled is None:
                continue
            out |= {f"{e['type']}.{k}" for k in set(e) - {"type"} - handled}
    return sorted(out)


def classify(aid: str, d: dict, reach: list[str], refs: list[str]) -> tuple[str, str | None]:
    """The runtime status of one ability, with its evidence."""
    if d.get("hiddenFromPlayer"):
        return "NOT_APPLICABLE_TO_PLAYER", "hiddenFromPlayer: retired; abilitiesKnownAt never lists it"
    if not reach:
        return "UNKNOWN", "no acquisition path in class kits, spec signatures, talent grants or action replacements"
    bespoke = [f for f in refs if (aid, f) not in AUDITED_MENTIONS and (aid, f) not in skills_port.PORTED]
    if d.get("passive"):
        if aid in skills_port.NEEDS_GROUP:
            # A passive whose only rule acts between group members: not claimed.
            return "NEEDS_GROUP", skills_port.NEEDS_GROUP[aid]
        if bespoke:
            return "BLOCKED", "passive: its behaviour lives in engine code not ported: " + ", ".join(bespoke)
        if refs and all((aid, f) in skills_port.PORTED or (aid, f) in AUDITED_MENTIONS for f in refs) \
                and any((aid, f) in skills_port.PORTED for f in refs):
            return "IMPLEMENTED_PASSIVE", None
        if aid in skills_port.PASSIVE_EVIDENCE:
            return "IMPLEMENTED_PASSIVE", None
        return "BLOCKED", "passive: its behaviour lives in engine code (none named)"
    if d.get("requiresQuest"):
        return "CONDITION_LOCKED", f"requires quest {d['requiresQuest']} (no reference quest runs in the trial)"
    if bespoke:
        return "BLOCKED", "bespoke engine code not ported: " + ", ".join(bespoke)
    if not effect_kinds(d) and aid not in skills_port.EFFECTLESS_PORTED:
        return "BLOCKED", "no effects: its behaviour is engine code keyed elsewhere"
    missing = sorted(effect_kinds(d) - IMPLEMENTED_EFFECTS)
    if missing:
        return "BLOCKED", "effect handler not implemented: " + ", ".join(missing)
    gaps = effect_field_gaps(d)
    if gaps:
        return "BLOCKED", "effect fields not implemented: " + ", ".join(gaps)
    extra = sorted(set(d) - ALLOWED_DEF_KEYS - {"passive", "hiddenFromPlayer"})
    if extra:
        return "BLOCKED", "ability fields not implemented: " + ", ".join(extra)
    kinds = sorted(aura_kinds(d) - IMPLEMENTED_AURA_KINDS)
    if kinds:
        return "BLOCKED", "aura kind consumers not implemented: " + ", ".join(kinds)
    need = d.get("requiresAuraKind")
    if need and need not in skills_port.REQUIRED_AURA_PRODUCERS:
        return "BLOCKED", f"requires aura {need}, whose producer is not ported"
    if aid in skills_port.NEEDS_GROUP:
        return "NEEDS_GROUP", skills_port.NEEDS_GROUP[aid]
    if any("signature" in r for r in reach) and not any("class kit" in r for r in reach):
        return "IMPLEMENTED_SPECIALIZATION", None
    if any("talent" in r for r in reach) and not any("class kit" in r for r in reach):
        return "IMPLEMENTED_TALENT_GRANT", None
    if any(r.startswith("replaces") for r in reach) and not any("class kit" in r for r in reach):
        return "CONDITION_LOCKED", "an action replacement: available only while its aura holds"
    return "IMPLEMENTED_ACTIVE", None


def strip_def(d: dict) -> dict:
    """The definition the runtime reads (descriptions and tooltip text dropped)."""
    return {k: v for k, v in d.items() if k not in ("description", "specNotes", "tooltipOmitEffectLines")}


def interim_name(record_id: str) -> str:
    return record_id.replace("_", " ").title()


def canonical(doc) -> str:
    return json.dumps(doc, indent=1, sort_keys=True, ensure_ascii=False) + "\n"


def js(value):
    return ts_eval.from_json(value)


def build(checkout: Path) -> dict[Path, str]:
    builder.verify_checkout(checkout)
    src = builder.Source(checkout)
    files = builder.tree(checkout)
    ref = rc.Reference(src, files)
    classes_ts = "src/sim/content/classes.ts"
    talents_ts = "src/sim/content/talents.ts"
    abilities = ts_eval.to_json(ref.module_value(classes_ts, "ABILITIES"))
    classes = ts_eval.to_json(ref.module_value(classes_ts, "CLASSES"))
    spec_unlock = int(ts_eval.to_json(ref.module_value(talents_ts, "SPEC_UNLOCK_LEVEL")))
    reference_classes = json.loads(builder.RPG_REFERENCE.read_text())["classes"]

    # -- talents (talents.ts TALENTS, talent_rows.ts ROW_TREES, spec_baselines.ts)
    talents_src = ts_eval.to_json(ref.module_value(talents_ts, "TALENTS"))
    rows_src = ts_eval.to_json(ref.module_value("src/sim/content/talent_rows.ts", "ROW_TREES"))
    baselines = ts_eval.to_json(ref.module_value("src/sim/content/spec_baselines.ts", "SPEC_BASELINES"))
    offensive = ts_eval.to_json(ref.module_value("src/sim/spec_output_tuning.ts", "OFFENSIVE_SPEC_TUNING"))
    talents: dict = {}
    for cls in builder.CLASSES:
        specs = []
        for spec in talents_src[cls]["specs"]:
            sig = ts_eval.to_json(ref.call(talents_ts, "specSignatureIds", js(spec)))
            specs.append({
                "id": spec["id"], "role": spec["role"], "signature_ids": sig,
                "mastery_effect": spec.get("mastery", {}).get("effect"),
                "baseline": baselines.get(cls, {}).get(spec["id"]),
            })
        rows = [{
            "level": row["level"],
            "options": [{"id": o["id"], "display_name": interim_name(o["id"]),
                         "display_name_status": "INTERIM: option id", "effect": o.get("effect")}
                        for o in row["options"]],
        } for row in rows_src[cls]]
        talents[cls] = {"specs": specs, "rows": rows}

    # -- every ability: its definition and how this runtime treats it
    behaviour_refs = engine_references(checkout, set(abilities))
    reach = acquisition_paths(abilities, classes, talents)
    ability_index: dict = {}
    for aid, d in sorted(abilities.items()):
        status, reason = classify(aid, d, reach.get(aid, []), behaviour_refs.get(aid, []))
        ability_index[aid] = {
            "def": strip_def(d),
            "display_name": interim_name(aid),
            "display_name_status": "INTERIM: ability id; original name pending a naming batch",
            "status": status,
            "reason": reason,
            "acquired_by": reach.get(aid, []),
            "audited_mentions": [AUDITED_MENTIONS[(aid, f)] for f in behaviour_refs.get(aid, [])
                                 if (aid, f) in AUDITED_MENTIONS],
            "engine_references": behaviour_refs.get(aid, []),
            "ported_mentions": [skills_port.PORTED[(aid, f)] for f in behaviour_refs.get(aid, [])
                                if (aid, f) in skills_port.PORTED],
        }
    status_counts = dict(sorted(Counter(v["status"] for v in ability_index.values()).items()))

    # -- trial opponents and their loot
    monsters_doc = json.loads((REGISTRY / "reference_monsters.json").read_text())["monsters"]
    tables = json.loads((REGISTRY / "reference_loot_tables.json").read_text())["tables"]
    entries_doc = json.loads((REGISTRY / "reference_loot_entries.json").read_text())["entries"]
    trial: dict = {}
    excluded: dict = {}
    fleeing = set(ts_eval.to_json(ref.module_value("src/sim/mob/flee_rules.ts", "FLEEING_FAMILIES"))["$set"])
    for mid, m in sorted(monsters_doc.items()):
        if m["registry_table"] != "MOBS" or m["context"] != "world" or m["classification"] != "normal":
            continue
        reasons = []
        if m["source_fields"]["family"] in fleeing:
            reasons.append("family flees at low health (mob/flee_rules.ts); flight is not modelled")
        if m["mechanics"]:
            reasons.append("mechanics: " + ", ".join(sorted(m["mechanics"])))
        extra = sorted(set(m["source_fields"]) - TRIAL_SOURCE_FIELDS)
        if extra:
            reasons.append("fields: " + ", ".join(extra))
        table = tables.get(m["loot_table"], {"entries": []})
        rows = [entries_doc[e] for e in table["entries"]]
        for row in rows:
            extra_row = sorted(set(row["source_fields"]) - LOOT_ROW_FIELDS)
            if extra_row:
                reasons.append("loot row fields: " + ", ".join(extra_row))
                break
            if row["item"] is not None and not row["item"]["resolves"]:
                reasons.append("unresolved loot item")
                break
        if reasons:
            excluded[mid] = reasons
            continue
        sf = m["source_fields"]
        trial[mid] = {
            "display_name": interim_name(mid),
            "display_name_status": "INTERIM: monster id; original name pending a naming batch",
            "family": sf["family"],
            "level_min": int(sf["minLevel"]),
            "level_max": int(sf["maxLevel"]),
            "template": {
                "hp_base": sf["hpBase"], "hp_per_level": sf["hpPerLevel"],
                "dmg_base": sf["dmgBase"], "dmg_per_level": sf["dmgPerLevel"],
                "attack_speed": sf["attackSpeed"], "armor_per_level": sf["armorPerLevel"],
                "elite": False,
            },
            "xp_mult": sf.get("xpMult", 1),
            "loot": [{
                "item": row["item"]["id"] if row["item"] else None,
                "chance": row["chance"],
                "copper": row["copper"],
                "roll_group": row["roll_group"],
                "quest_id": row["quest_id"],
            } for row in rows],
            "ref": m["ref"],
        }

    # -- items: the class kits and every trial loot item
    items_doc = json.loads((REGISTRY / "reference_items.json").read_text())["items"]
    kits: dict = {}
    wanted: set = set()
    for cls in builder.CLASSES:
        c = classes[cls]
        kit = {"start_weapon": c.get("startWeapon"), "start_offhand": c.get("startOffhand"),
               "start_chest": c.get("startChest")}
        kits[cls] = kit
        wanted.update(v for v in kit.values() if v)
    for mob in trial.values():
        wanted.update(row["item"] for row in mob["loot"] if row["item"])
    items: dict = {}
    for iid in sorted(wanted):
        it = items_doc[iid]
        sf = it["source_fields"]
        req = ref.call("src/sim/item_level_req.ts", "requiredLevelFor", ref.items[iid])
        items[iid] = {
            "display_name": interim_name(iid),
            "display_name_status": "INTERIM: item id; original name pending a naming batch",
            "kind": it["kind"], "slot": it["slot"], "quality": it["quality"],
            "armor_type": it["armor_type"], "hand": it["hand"], "weapon": it["weapon"],
            "stats": it["stats"],
            "required_class": sf.get("requiredClass"),
            "class_locked": bool(sf.get("classLocked", False)),
            "shield": bool(sf.get("shield", False)),
            "block_value": sf.get("blockValue", 0),
            "required_level": int(ts_eval.to_json(req)),
            "soulbound": bool(sf.get("soulbound", False)),
            "sell_value": it["sell_value"],
            "spell_power": sf.get("spellPower", 0), "crit_rating": sf.get("critRating", 0),
            "haste_rating": sf.get("hasteRating", 0), "hit_rating": sf.get("hitRating", 0),
            "not_modelled": sorted(set(sf) & {"use", "set", "healPower", "masterwrought", "questTool",
                                               "pvpDefenseRating", "pvpOffenseRating"}),
            "ref": it["ref"],
        }

    group_xp_bonus = ts_eval.to_json(ref.module_value("src/sim/data.ts", "GROUP_XP_BONUS"))

    def const(path: str, name: str):
        return ts_eval.to_json(ref.module_value(path, name))

    swing = {
        "dual_wield_white_miss_penalty": const("src/sim/combat/auto_attack.ts", "DUAL_WIELD_WHITE_MISS_PENALTY"),
        "offhand_auto_attack_dmg_mult": const("src/sim/combat/auto_attack.ts", "OFFHAND_AUTO_ATTACK_DMG_MULT"),
        "battle_trance_chance": const("src/sim/types.ts", "BATTLE_TRANCE_CHANCE"),
        "sudden_death_chance": const("src/sim/combat/auto_attack.ts", "SUDDEN_DEATH_CHANCE"),
        "shield_block_base": const("src/sim/types.ts", "SHIELD_BLOCK_BASE"),
        "protection_paladin_block_damage_reduction": const(
            "src/sim/combat/shield_block.ts", "PROTECTION_PALADIN_BLOCK_DAMAGE_REDUCTION"),
        "mob_crit_chance": 0.05,
        "mob_crit_chance_ref": "src/sim/sim.ts:7576 mobSwing: this.rng.chance(0.05)",
    }
    constants = {
        "spec_unlock_level": spec_unlock,
        "solo_group_xp_bonus": group_xp_bonus[0],
        "elite_xp_mult": 2,
        "elite_xp_mult_ref": "src/sim/combat/damage.ts:1851 (tmpl?.elite ? 2 : 1)",
        "max_level": MAX_LEVEL,
        "regen_every_ticks": 40,
        "regen_every_ticks_ref": "src/sim/combat/auras.ts:119 tickCount % 40",
        "mob_spell_crit_chance": 0.05,
    }
    for key, (path, name) in CONSTANT_SOURCES.items():
        constants[key] = const(path, name)
    constants["form_aura_kinds"] = sorted(const("src/sim/types.ts", "FORM_AURA_KINDS")["$set"])
    constants["action_locking_form_kinds"] = [
        k for k in constants["form_aura_kinds"]
        if ts_eval.to_json(ref.call("src/sim/combat/forms.ts", "isActionLockingFormAuraKind", k))]
    constants["colossal_might_cooldowns"] = sorted(
        const("src/sim/combat/casting_lifecycle.ts", "COLOSSAL_MIGHT_COOLDOWNS")["$set"])
    constants["debuff_aura_kinds"] = sorted(const("src/sim/aura_classify.ts", "DEBUFF_AURA_KINDS")["$set"])
    constants["melee_classes"] = sorted(const("src/sim/types.ts", "MELEE_CLASSES")["$set"])
    constants["source_independent_group_buffs"] = sorted(
        const("src/sim/combat/aura_stacking.ts", "SOURCE_INDEPENDENT_GROUP_BUFF_AURA_IDS")["$set"])
    constants["discipline_wand_offense_mult"] = ts_eval.to_json(
        ref.call("src/sim/spec_output_tuning.ts", "disciplineWandOffenseMultiplier"))
    class_info = {}
    for cls in builder.CLASSES:
        c = classes[cls]
        class_info[cls] = {
            "kit_abilities": c["abilities"],
            "ranged": c.get("ranged"),
            "resource": c["resourceType"],
        }
    for mid, mob in trial.items():
        scale = float(monsters_doc[mid]["source_fields"].get("scale", 1))
        prof = ts_eval.to_json(ref.call("src/sim/mob_combat.ts", "combatProfileForMob", mid, scale))
        mob["combat_profile"] = prof
        mob["body_edge_melee_range"] = ts_eval.to_json(
            ref.call("src/sim/combat/player_attack_reach.ts", "bodyEdgeMeleeRange", mid))
        mob["move_speed"] = monsters_doc[mid]["source_fields"]["moveSpeed"]
        mob["aggro_radius"] = monsters_doc[mid]["source_fields"]["aggroRadius"]
        mob["respawn_seconds"] = monsters_doc[mid]["source_fields"].get("respawnSeconds")
    pack = {
        "_comment": "Generated by tools/content/build_runtime_pack.py from the pinned reference; do not edit.",
        "schema": 2,
        "source": builder.source_block(src),
        "registry_inputs": {
            name: hashlib.sha256((REGISTRY / name).read_bytes()).hexdigest()
            for name in ("reference_items.json", "reference_monsters.json",
                         "reference_loot_tables.json", "reference_loot_entries.json")
        },
        "constants": constants,
        "swing": swing,
        "classes": class_info,
        "class_kits": kits,
        "talents": talents,
        "empty_modifiers": ts_eval.to_json(ref.call(talents_ts, "emptyModifiers")),
        "offensive_spec_tuning": offensive,
        "implemented_effects": sorted(IMPLEMENTED_EFFECTS),
        "implemented_aura_kinds": sorted(IMPLEMENTED_AURA_KINDS),
        "behaviour_files": list(BEHAVIOUR_PREFIXES),
        "abilities": ability_index,
        "trial_rules": TRIAL_RULES,
        "trial_monsters": trial,
        "trial_excluded": excluded,
        "items": items,
        "counts": {
            "abilities": len(ability_index),
            "ability_status": status_counts,
            "trial_monsters": len(trial),
            "items": len(items),
        },
    }
    return {OUT: canonical(pack)}


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv[1:])
    outputs = build(args.ref)
    stale = [p for p, text in outputs.items() if not p.exists() or p.read_text(encoding="utf-8") != text]
    if args.check:
        for p in stale:
            print("stale:", p.relative_to(ROOT))
        if not stale:
            print("the runtime pack is current")
        return 1 if stale else 0
    for path, text in outputs.items():
        path.write_text(text, encoding="utf-8")
        print("wrote", path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
