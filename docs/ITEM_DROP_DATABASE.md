# Item and drop database

Generated from the game's data by `client/tests/harness/DropReport.gd`
(LootIndex). Do not edit by hand: change the data and run
`godot --headless --path client --script res://tests/harness/DropReportRun.gd`.

- Chances are the **actual chance per kill** (or per reward), worked out from the
  rules, never rolled. A selection weight is never shown as a chance: section G
  gives the conditional shares of the catalog's drop tables separately.
- Legacy drops (`items.json` items in enemies' tables, farming grounds, world
  bosses) are the game's existing values, preserved.
- The catalog's drops (`drop_tables.json`) are **INITIAL BALANCE VALUES**,
  not yet playtested.

## A. Item catalog

| Item ID | Name | Category | Grade | Slot | Level | Stats | Sources |
|---|---|---|---|---|---|---|---|
| `baron_furnace_core` | Furnace Baron's Core | boss_material | epic | - | - | - | 1 |
| `chen_anchor_link` | Harbourmaster's Anchor Link | boss_material | rare | - | - | - | 1 |
| `k7_reactor_cell` | K-7 Reactor Cell | boss_material | epic | - | - | - | 1 |
| `wiroj_protocol_chip` | Wiroj Protocol Chip | boss_material | epic | - | - | - | 1 |
| `adrenal_shot` | Adrenal Shot | consumable | rare | - | - | energy 70.0 | 55 |
| `energy_drink_ironworks` | Ironworks Energy Drink | consumable | uncommon | - | - | energy 40.0 | 55 |
| `focus_gum` | Focus Gum | consumable | common | - | - | energy 20.0 | 55 |
| `ginger_tea` | Ginger Tea | consumable | uncommon | - | - | heal 50.0, energy 40.0 | 33 |
| `herbal_tonic` | Herbal Tonic | consumable | rare | - | - | heal 220.0, energy 60.0 | 88 |
| `rice_box` | Rice Box | consumable | uncommon | - | - | heal 120.0 | 96 |
| `second_wind_tonic` | Second Wind Tonic | consumable | epic | - | - | energy 100.0 | 55 |
| `steamed_bun` | Steamed Bun | consumable | common | - | - | heal 25.0 | 30 |
| `enhance_catalyst_rare` | Rare Enhancement Catalyst | enhancement_material | epic | - | - | - | 55 |
| `enhance_catalyst_special` | Special Enhancement Catalyst | enhancement_material | legendary | - | - | - | 17 |
| `enhance_stone_advanced` | Advanced Enhancement Stone | enhancement_material | rare | - | - | - | 56 |
| `enhance_stone_basic` | Basic Enhancement Stone | enhancement_material | common | - | - | - | 55 |
| `enhance_stone_refined` | Refined Enhancement Stone | enhancement_material | uncommon | - | - | - | 55 |
| `refined_alloy` | Refined Alloy | enhancement_material | rare | - | - | - | 182 |
| `scrap_metal` | Scrap Metal | enhancement_material | common | - | - | - | 162 |
| `arcane_wizard_hat` | Arcane Wizard Hat | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `champion_headband` | Champion's Headband | headgear | epic | head | 7.0 | max_hp 30.0, crit 0.04 | 1 |
| `coolant_epic_head` | Reinstated Helm | headgear | epic | head | 53.0 | defense 9.0, max_hp 117.0, crit 0.06 | 1 |
| `coolant_rare_head` | Vault Guard Helm | headgear | rare | head | 53.0 | defense 8.0, max_hp 84.0, crit 0.07 | 24 |
| `coolant_uncommon_head` | Coolant Helm | headgear | uncommon | head | 53.0 | defense 8.0, max_hp 94.0 | 16 |
| `core_guard_helm` | Core Guard Helm | headgear | uncommon | head | 42.0 | defense 6.0, max_hp 75.0 | 13 |
| `crimson_warlord_helm` | Crimson Warlord Helm | headgear | legendary | head | 30.0 | defense 10.0, max_hp 64.0 | 17 |
| `crystal_tiara` | Crystal Tiara | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `cyber_visor` | Cyber Visor | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `director_crown` | Director's Crown | headgear | legendary | head | 48.0 | defense 9.0, max_hp 115.0, crit 0.11 | 1 |
| `dock_beanie` | Dock Beanie | headgear | common | head | 1.0 | max_hp 15.0 | 4 |
| `dockers_cap` | Docker's Cap | headgear | uncommon | head | 11.0 | defense 2.0, max_hp 25.0 | 7 |
| `dragonscale_hood` | Dragonscale Hood | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `emerald_feather_hat` | Emerald Feather Hat | headgear | uncommon | head | 9.0 | defense 2.0, max_hp 21.0 | 55 |
| `facility_helmet` | Facility Helmet | headgear | uncommon | head | 33.0 | defense 5.0, max_hp 60.0 | 13 |
| `founders_halo` | Founder's Halo | headgear | godforged | head | 70.0 | defense 17.0, max_hp 223.0, crit 0.21 | 2 |
| `foundry_epic_head` | Overdriven Helm | headgear | epic | head | 63.0 | defense 10.0, max_hp 137.0, crit 0.07 | 1 |
| `foundry_rare_head` | Slagworker Helm | headgear | rare | head | 63.0 | defense 10.0, max_hp 98.0, crit 0.08 | 24 |
| `foundry_uncommon_head` | Foundry Helm | headgear | uncommon | head | 63.0 | defense 9.0, max_hp 110.0 | 16 |
| `frost_fur_hood` | Frost Fur Hood | headgear | uncommon | head | 9.0 | defense 2.0, max_hp 21.0 | 55 |
| `gilded_brawler_helm` | Gilded Brawler Helm | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `glacier_crown` | Glacier Crown | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `harbourmaster_cap` | Harbourmaster's Cap | headgear | epic | head | 15.0 | defense 3.0, max_hp 40.0, crit 0.02 | 5 |
| `hard_hat` | Hard Hat | headgear | uncommon | head | 4.0 | max_hp 16.0, defense 1.0 | 9 |
| `hazmat_hood` | Hazmat Hood | headgear | uncommon | head | 19.0 | defense 3.0, max_hp 40.0 | 6 |
| `heart_epic_head` | Protocol Helm | headgear | epic | head | 68.0 | defense 11.0, max_hp 148.0, crit 0.07 | 1 |
| `heart_rare_head` | Heart Sentry Helm | headgear | rare | head | 68.0 | defense 11.0, max_hp 106.0, crit 0.08 | 16 |
| `heart_uncommon_head` | Heartforged Helm | headgear | uncommon | head | 68.0 | defense 9.0, max_hp 118.0 | 8 |
| `ice_crown` | Ice Crown | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `iron_helm` | Iron Helm | headgear | uncommon | head | 7.0 | defense 2.0, max_hp 13.0 | 7 |
| `jewelled_crown` | Jewelled Crown | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `lion_king_crown` | Lion King's Crown | headgear | legendary | head | 30.0 | defense 10.0, max_hp 64.0 | 16 |
| `marshal_visor` | Marshal's Floodlight Visor | headgear | godforged | head | 56.0 | defense 14.0, max_hp 181.0, crit 0.17 | 2 |
| `midnight_wizard_hat` | Midnight Wizard Hat | headgear | uncommon | head | 9.0 | defense 2.0, max_hp 21.0 | 55 |
| `obsidian_crown` | Obsidian Crown | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `patched_street_cap` | Patched Street Cap | headgear | common | head | 4.0 | defense 1.0, max_hp 12.0 | 55 |
| `phoenix_feather_hat` | Phoenix Feather Hat | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `phoenix_tiara` | Phoenix Tiara | headgear | epic | head | 22.0 | defense 6.0, max_hp 46.0 | 55 |
| `reinforced_bandana` | Reinforced Bandana | headgear | uncommon | head | 9.0 | defense 2.0, max_hp 21.0 | 55 |
| `ringmaster_topper` | Ringmaster's Topper | headgear | legendary | head | 27.0 | defense 5.0, max_hp 70.0, crit 0.07 | 1 |
| `rising_sun_headband` | Rising Sun Headband | headgear | common | head | 4.0 | defense 1.0, max_hp 12.0 | 55 |
| `riveted_work_helmet` | Riveted Work Helmet | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `runners_cap` | Runner's Cap | headgear | rare | head | 30.0 | defense 5.0, max_hp 50.0, crit 0.04 | 1 |
| `sakura_straw_hat` | Sakura Straw Hat | headgear | common | head | 4.0 | defense 1.0, max_hp 12.0 | 55 |
| `sakura_wizard_hat` | Sakura Wizard Hat | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `sovereign_crown` | Sovereign Crown | headgear | godforged | head | 70.0 | defense 17.0, max_hp 223.0, crit 0.21 | 2 |
| `spillway_epic_head` | Spillway Chief's Visor | headgear | epic | head | 42.0 | defense 7.0, max_hp 95.0, crit 0.05 | 7 |
| `starlight_wizard_hat` | Starlight Wizard Hat | headgear | rare | head | 15.0 | defense 4.0, max_hp 27.0 | 55 |
| `tiger_hood` | Tiger Hood | headgear | uncommon | head | 9.0 | defense 2.0, max_hp 21.0 | 55 |
| `underworks_epic_head` | Relapsed Helm | headgear | epic | head | 58.0 | defense 10.0, max_hp 127.0, crit 0.06 | 1 |
| `underworks_rare_head` | Reactor Crew Helm | headgear | rare | head | 58.0 | defense 9.0, max_hp 91.0, crit 0.07 | 24 |
| `underworks_uncommon_head` | Underworks Helm | headgear | uncommon | head | 58.0 | defense 8.0, max_hp 102.0 | 16 |
| `used_coolant_uncommon_head` | Used Coolant Helm | headgear | common | head | 53.0 | defense 6.0, max_hp 80.0 | 1 |
| `used_core_guard_helm` | Used Core Guard Helm | headgear | common | head | 42.0 | defense 5.0, max_hp 65.0 | 1 |
| `used_dockers_cap` | Used Docker's Cap | headgear | common | head | 11.0 | defense 2.0, max_hp 22.0 | 1 |
| `used_facility_helmet` | Used Facility Helmet | headgear | common | head | 33.0 | defense 4.0, max_hp 51.0 | 1 |
| `used_foundry_uncommon_head` | Used Foundry Helm | headgear | common | head | 63.0 | defense 8.0, max_hp 94.0 | 1 |
| `used_hard_hat` | Used Hard Hat | headgear | common | head | 4.0 | max_hp 14.0, defense 1.0 | 1 |
| `used_hazmat_hood` | Used Hazmat Hood | headgear | common | head | 19.0 | defense 3.0, max_hp 34.0 | 1 |
| `used_heart_uncommon_head` | Used Heartforged Helm | headgear | common | head | 68.0 | defense 8.0, max_hp 101.0 | 1 |
| `used_iron_helm` | Used Iron Helm | headgear | common | head | 7.0 | defense 2.0, max_hp 12.0 | 1 |
| `used_underworks_uncommon_head` | Used Underworks Helm | headgear | common | head | 58.0 | defense 7.0, max_hp 87.0 | 1 |
| `used_watch_cap` | Used Night Watch Cap | headgear | common | head | 26.0 | defense 3.0, max_hp 43.0 | 1 |
| `watch_cap` | Night Watch Cap | headgear | uncommon | head | 26.0 | defense 4.0, max_hp 50.0 | 6 |
| `watchmans_cap` | Watchman's Cap | headgear | rare | head | 10.0 | defense 3.0, max_hp 25.0 | 1 |
| `mineral_azure` | Azure Mineral | ore | rare | - | - | - | 58 |
| `mineral_crimson` | Crimson Special Mineral | ore | legendary | - | - | - | 17 |
| `mineral_gilded` | Gilded Mineral | ore | epic | - | - | - | 57 |
| `mineral_rare` | Rare Mineral | ore | uncommon | - | - | - | 55 |
| `ore_copper` | Copper Ore | ore | common | - | - | - | 55 |
| `ore_iron` | Iron Ore | ore | common | - | - | - | 55 |
| `ore_refined` | Refined Ore | ore | uncommon | - | - | - | 55 |
| `canvas_work_shirt` | Canvas Work Shirt | outfit | common | body | 4.0 | max_hp 15.0, defense 1.0 | 55 |
| `coolant_epic_body` | Reinstated Plate | outfit | epic | body | 53.0 | defense 15.0, max_hp 136.0 | 13 |
| `coolant_rare_body` | Vault Guard Plate | outfit | rare | body | 53.0 | defense 14.0, max_hp 108.0 | 24 |
| `coolant_uncommon_body` | Coolant Plate | outfit | uncommon | body | 53.0 | defense 11.0, max_hp 104.0 | 16 |
| `crimson_warlord_mantle` | Crimson Warlord Mantle | outfit | legendary | body | 30.0 | max_hp 113.0, defense 9.0 | 17 |
| `director_coat` | Director's Coat | outfit | epic | body | 48.0 | defense 14.0, max_hp 125.0 | 4 |
| `founders_plate` | Founder's Plate | outfit | godforged | body | 70.0 | defense 32.0, max_hp 292.0 | 2 |
| `foundry_epic_body` | Overdriven Plate | outfit | epic | body | 63.0 | defense 18.0, max_hp 159.0 | 13 |
| `foundry_rare_body` | Slagworker Plate | outfit | rare | body | 63.0 | defense 16.0, max_hp 127.0 | 24 |
| `foundry_uncommon_body` | Foundry Plate | outfit | uncommon | body | 63.0 | defense 13.0, max_hp 122.0 | 16 |
| `gilded_fight_robe` | Gilded Fight Robe | outfit | epic | body | 22.0 | max_hp 74.0, defense 6.0 | 55 |
| `heart_epic_body` | Protocol Plate | outfit | epic | body | 68.0 | defense 19.0, max_hp 171.0 | 13 |
| `heart_rare_body` | Heart Sentry Plate | outfit | rare | body | 68.0 | defense 17.0, max_hp 136.0 | 16 |
| `heart_uncommon_body` | Heartforged Plate | outfit | uncommon | body | 68.0 | defense 14.0, max_hp 130.0 | 8 |
| `k7_plating` | K7 Plating | outfit | epic | body | 23.0 | defense 7.0, max_hp 70.0 | 4 |
| `kevlar_jacket` | Kevlar Jacket | outfit | uncommon | body | 26.0 | defense 6.0, max_hp 55.0 | 6 |
| `marshal_greatcoat` | Marshal's Greatcoat | outfit | godforged | body | 56.0 | defense 26.0, max_hp 237.0 | 2 |
| `night_market_jacket` | Night Market Jacket | outfit | rare | body | 7.0 | defense 3.0, max_hp 25.0 | 1 |
| `padded_street_jacket` | Padded Street Jacket | outfit | uncommon | body | 9.0 | max_hp 28.0, defense 2.0 | 55 |
| `padded_vest` | Padded Vest | outfit | common | body | 1.0 | defense 2.0 | 1 |
| `pims_field_vest` | Pim's Field Vest | outfit | rare | body | 24.0 | defense 7.0, max_hp 55.0 | 1 |
| `plant_vest` | Plant Security Vest | outfit | uncommon | body | 19.0 | defense 5.0, max_hp 40.0 | 6 |
| `port_jacket` | Port Authority Jacket | outfit | uncommon | body | 11.0 | defense 3.0, max_hp 30.0 | 7 |
| `reactor_plate` | Reactor Plate | outfit | uncommon | body | 42.0 | defense 9.0, max_hp 85.0 | 13 |
| `riveted_dock_coat` | Riveted Dock Coat | outfit | rare | body | 15.0 | max_hp 47.0, defense 4.0 | 55 |
| `riveted_jacket` | Riveted Jacket | outfit | uncommon | body | 6.0 | defense 2.0, max_hp 21.0 | 10 |
| `smelter_apron` | Smelter's Apron | outfit | epic | body | 9.0 | defense 3.0, max_hp 40.0 | 5 |
| `sovereign_mantle` | Sovereign Mantle | outfit | godforged | body | 70.0 | defense 32.0, max_hp 292.0 | 2 |
| `spillway_epic_body` | Spillway Chief's Coat | outfit | epic | body | 42.0 | defense 12.0, max_hp 110.0 | 7 |
| `trooper_vest` | Trooper Vest | outfit | uncommon | body | 33.0 | defense 8.0, max_hp 60.0 | 7 |
| `underworks_epic_body` | Relapsed Plate | outfit | epic | body | 58.0 | defense 17.0, max_hp 148.0 | 13 |
| `underworks_rare_body` | Reactor Crew Plate | outfit | rare | body | 58.0 | defense 15.0, max_hp 117.0 | 24 |
| `underworks_uncommon_body` | Underworks Plate | outfit | uncommon | body | 58.0 | defense 12.0, max_hp 113.0 | 16 |
| `used_coolant_uncommon_body` | Used Coolant Plate | outfit | common | body | 53.0 | defense 9.0, max_hp 88.0 | 1 |
| `used_foundry_uncommon_body` | Used Foundry Plate | outfit | common | body | 63.0 | defense 11.0, max_hp 103.0 | 1 |
| `used_heart_uncommon_body` | Used Heartforged Plate | outfit | common | body | 68.0 | defense 12.0, max_hp 111.0 | 1 |
| `used_kevlar_jacket` | Used Kevlar Jacket | outfit | common | body | 26.0 | defense 5.0, max_hp 46.0 | 1 |
| `used_plant_vest` | Used Plant Security Vest | outfit | common | body | 19.0 | defense 4.0, max_hp 33.0 | 1 |
| `used_port_jacket` | Used Port Authority Jacket | outfit | common | body | 11.0 | defense 3.0, max_hp 25.0 | 1 |
| `used_reactor_plate` | Used Reactor Plate | outfit | common | body | 42.0 | defense 8.0, max_hp 71.0 | 1 |
| `used_riveted_jacket` | Used Riveted Jacket | outfit | common | body | 6.0 | defense 2.0, max_hp 18.0 | 1 |
| `used_trooper_vest` | Used Trooper Vest | outfit | common | body | 33.0 | defense 7.0, max_hp 51.0 | 1 |
| `used_underworks_uncommon_body` | Used Underworks Plate | outfit | common | body | 58.0 | defense 10.0, max_hp 96.0 | 1 |
| `used_work_jacket` | Used Work Jacket | outfit | common | body | 3.0 | defense 2.0, max_hp 8.0 | 1 |
| `work_jacket` | Work Jacket | outfit | uncommon | body | 3.0 | defense 2.0, max_hp 10.0 | 12 |
| `zeros_mantle` | Zero's Mantle | outfit | godforged | body | 50.0 | defense 22.0, max_hp 226.0 | 2 |
| `altered_manifest` | The Altered Manifest | special | epic | - | - | - | 1 |
| `baron_ledger` | The Baron's Ledger | special | epic | - | - | - | 1 |
| `brass_whistle` | Brass Whistle | special | rare | charm | 1.0 | max_hp 20.0 | 1 |
| `canvas_sneakers` | Canvas Sneakers | special | common | feet | 1.0 | speed 0.06 | 1 |
| `cargo_gloves` | Cargo Gloves | special | uncommon | hands | 13.0 | power 0.13, defense 1.0, attack_speed 0.04 | 7 |
| `chais_deck_shoes` | Chai's Deck Shoes | special | rare | feet | 15.0 | speed 0.13, defense 3.0 | 1 |
| `champion_wraps` | Champion's Wraps | special | epic | hands | 7.0 | power 0.09, crit 0.04, attack_speed 0.03 | 1 |
| `chiefs_gloves` | Chief's Gloves | special | epic | hands | 21.0 | power 0.22, defense 2.0, crit 0.07 | 4 |
| `colossus_core` | Colossus Core | special | godforged | charm | 45.0 | max_hp 207.0, power 0.3, attack_speed 0.21 | 2 |
| `commander_greaves` | Commander's Greaves | special | epic | feet | 39.0 | speed 0.24, defense 5.0, attack_speed 0.11 | 1 |
| `coolant_epic_charm` | Reinstated Charm | special | epic | charm | 53.0 | max_hp 145.0, defense 4.0, crit 0.12 | 1 |
| `coolant_epic_feet` | Reinstated Boots | special | epic | feet | 53.0 | speed 0.32, defense 7.0, attack_speed 0.14 | 1 |
| `coolant_epic_hands` | Reinstated Gloves | special | epic | hands | 53.0 | power 0.49, defense 4.0, crit 0.16 | 1 |
| `coolant_rare_charm` | Vault Guard Charm | special | rare | charm | 53.0 | max_hp 105.0, power 0.21, crit 0.13 | 24 |
| `coolant_rare_feet` | Vault Guard Boots | special | rare | feet | 53.0 | speed 0.25, defense 6.0, attack_speed 0.12 | 24 |
| `coolant_rare_hands` | Vault Guard Gloves | special | rare | hands | 53.0 | power 0.5, defense 3.0, crit 0.1 | 24 |
| `coolant_uncommon_charm` | Coolant Charm | special | uncommon | charm | 53.0 | max_hp 91.0, power 0.18, crit 0.12 | 16 |
| `coolant_uncommon_feet` | Coolant Boots | special | uncommon | feet | 53.0 | speed 0.22, defense 5.0, attack_speed 0.12 | 16 |
| `coolant_uncommon_hands` | Coolant Gloves | special | uncommon | hands | 53.0 | power 0.46, defense 2.0, crit 0.09 | 16 |
| `core_source_data` | Core Source Data | special | legendary | - | - | - | 1 |
| `crucible_gauntlets` | Crucible Gauntlets | special | godforged | hands | 64.0 | power 0.88, defense 7.0, crit 0.26, attack_speed 0.17 | 2 |
| `crucible_heart` | Heart of the Crucible | special | godforged | charm | 64.0 | max_hp 254.0, power 0.44, crit 0.16, attack_speed 0.16 | 2 |
| `deck_boots` | Deck Boots | special | uncommon | feet | 13.0 | speed 0.07, defense 1.0, max_hp 16.0 | 7 |
| `director_signet` | Director's Signet | special | legendary | charm | 48.0 | max_hp 155.0, power 0.24, crit 0.13 | 1 |
| `dockmaster_boots` | Dockmaster's Boots | special | epic | feet | 15.0 | speed 0.1, defense 2.0, max_hp 20.0 | 5 |
| `experiment_log` | Experiment Log | special | epic | - | - | - | 1 |
| `exposure_report` | Exposure Report | special | epic | - | - | - | 1 |
| `facility_boots` | Facility Boots | special | uncommon | feet | 35.0 | speed 0.17, defense 3.0, attack_speed 0.08 | 7 |
| `facility_pass` | Core Facility Pass | special | epic | - | - | - | 1 |
| `fight_gloves` | Taped Fight Gloves | special | uncommon | hands | 27.0 | power 0.25, defense 1.0, crit 0.06 | 6 |
| `fingerless_gloves` | Fingerless Gloves | special | common | hands | 1.0 | power 0.02, attack_speed 0.03 | 6 |
| `foreman_boots` | Foreman's Boots | special | epic | feet | 3.0 | defense 1.0, max_hp 7.0, speed 0.03 | 6 |
| `forged_note` | Forged Delivery Note | special | rare | - | - | - | 1 |
| `founders_crimson_sigil` | Founder's Crimson Sigil | special | legendary | - | - | - | 1 |
| `founders_engine_core` | Engine Heart | special | godforged | charm | 70.0 | max_hp 276.0, power 0.47, crit 0.18, attack_speed 0.18 | 2 |
| `foundry_epic_charm` | Overdriven Charm | special | epic | charm | 63.0 | max_hp 170.0, defense 5.0, crit 0.14 | 1 |
| `foundry_epic_feet` | Overdriven Boots | special | epic | feet | 63.0 | speed 0.37, defense 8.0, attack_speed 0.17 | 1 |
| `foundry_epic_hands` | Overdriven Gloves | special | epic | hands | 63.0 | power 0.58, defense 5.0, crit 0.18 | 1 |
| `foundry_rare_charm` | Slagworker Charm | special | rare | charm | 63.0 | max_hp 123.0, power 0.25, crit 0.16 | 24 |
| `foundry_rare_feet` | Slagworker Boots | special | rare | feet | 63.0 | speed 0.3, defense 7.0, attack_speed 0.14 | 24 |
| `foundry_rare_hands` | Slagworker Gloves | special | rare | hands | 63.0 | power 0.58, defense 4.0, crit 0.12 | 24 |
| `foundry_uncommon_charm` | Foundry Charm | special | uncommon | charm | 63.0 | max_hp 107.0, power 0.21, crit 0.14 | 16 |
| `foundry_uncommon_feet` | Foundry Boots | special | uncommon | feet | 63.0 | speed 0.26, defense 6.0, attack_speed 0.14 | 16 |
| `foundry_uncommon_hands` | Foundry Gloves | special | uncommon | hands | 63.0 | power 0.54, defense 3.0, crit 0.11 | 16 |
| `grip_gloves` | Lab Grip Gloves | special | uncommon | hands | 35.0 | power 0.31, defense 2.0, crit 0.06 | 5 |
| `heart_epic_charm` | Protocol Charm | special | epic | charm | 68.0 | max_hp 182.0, defense 5.0, crit 0.15 | 1 |
| `heart_epic_feet` | Protocol Boots | special | epic | feet | 68.0 | speed 0.4, defense 8.0, attack_speed 0.18 | 1 |
| `heart_epic_hands` | Protocol Gloves | special | epic | hands | 68.0 | power 0.62, defense 6.0, crit 0.2 | 1 |
| `heart_of_iron_city` | Heart of Iron City | special | legendary | charm | 48.0 | max_hp 140.0, power 0.24, crit 0.09, attack_speed 0.09 | 1 |
| `heart_rare_charm` | Heart Sentry Charm | special | rare | charm | 68.0 | max_hp 132.0, power 0.26, crit 0.17 | 16 |
| `heart_rare_feet` | Heart Sentry Boots | special | rare | feet | 68.0 | speed 0.32, defense 8.0, attack_speed 0.15 | 16 |
| `heart_rare_hands` | Heart Sentry Gloves | special | rare | hands | 68.0 | power 0.63, defense 4.0, crit 0.13 | 16 |
| `heart_uncommon_charm` | Heartforged Charm | special | uncommon | charm | 68.0 | max_hp 115.0, power 0.23, crit 0.15 | 8 |
| `heart_uncommon_feet` | Heartforged Boots | special | uncommon | feet | 68.0 | speed 0.28, defense 6.0, attack_speed 0.15 | 8 |
| `heart_uncommon_hands` | Heartforged Gloves | special | uncommon | hands | 68.0 | power 0.58, defense 3.0, crit 0.12 | 8 |
| `inspectors_gloves` | Inspector's Gloves | special | rare | hands | 20.0 | power 0.18, defense 2.0, crit 0.06 | 1 |
| `insulated_gauntlets` | Insulated Gauntlets | special | uncommon | hands | 44.0 | power 0.39, defense 2.0, crit 0.08 | 10 |
| `insulated_gloves` | Insulated Gloves | special | uncommon | hands | 21.0 | power 0.19, defense 1.0, crit 0.05 | 12 |
| `iron_legacy_relic` | Iron Legacy Relic | special | epic | - | - | - | 3 |
| `iron_wraps` | Iron Wraps | special | rare | hands | 5.0 | power 0.06, defense 1.0, crit 0.02 | 12 |
| `jade_charm` | Jade Charm | special | epic | charm | 8.0 | max_hp 25.0, power 0.05, attack_speed 0.06 | 6 |
| `k7_core_plate` | K-7 Core Plate | special | legendary | charm | 23.0 | max_hp 65.0, power 0.15, attack_speed 0.13 | 1 |
| `kenjis_lucky_charm` | Kenji's Lucky Charm | special | rare | charm | 26.0 | max_hp 55.0, power 0.11, crit 0.07 | 1 |
| `lab_boots` | Lab Boots | special | uncommon | feet | 21.0 | speed 0.11, defense 2.0, attack_speed 0.05 | 10 |
| `leks_lab_boots` | Lek's Lab Boots | special | rare | feet | 34.0 | speed 0.17, defense 4.0, attack_speed 0.08 | 1 |
| `lucky_coin` | Lucky Coin | special | uncommon | charm | 3.0 | max_hp 9.0, power 0.01, crit 0.03 | 12 |
| `marshal_sabatons` | Marshal's Sabatons | special | godforged | feet | 56.0 | speed 0.52, defense 11.0, attack_speed 0.28 | 2 |
| `money_trail` | Money Trail | special | epic | - | - | - | 1 |
| `mothers_heart` | Mother's Heart | special | godforged | charm | 30.0 | max_hp 144.0, power 0.21, attack_speed 0.15 | 4 |
| `odos_old_gloves` | Odo's Old Gloves | special | rare | hands | 3.0 | power 0.04, defense 1.0, crit 0.02 | 1 |
| `piston_gauntlets` | Piston Gauntlets | special | godforged | hands | 45.0 | power 0.88, defense 5.0, crit 0.16 | 2 |
| `runner_sneakers` | Runner Sneakers | special | uncommon | feet | 27.0 | speed 0.16, defense 2.0, attack_speed 0.06 | 6 |
| `sak_loafers` | Sak's Loafers | special | epic | feet | 31.0 | speed 0.2, defense 4.0, attack_speed 0.09 | 5 |
| `sak_signet` | Sak's Signet | special | legendary | charm | 31.0 | max_hp 90.0, power 0.19, crit 0.11 | 1 |
| `sentinel_gauntlets` | Sentinel Gauntlets | special | rare | hands | 44.0 | power 0.43, defense 3.0, crit 0.09 | 1 |
| `sovereign_grips` | Sovereign Grips | special | godforged | hands | 70.0 | power 0.95, defense 8.0, crit 0.28, attack_speed 0.18 | 2 |
| `sovereign_seal` | Sovereign Seal | special | godforged | charm | 70.0 | max_hp 276.0, power 0.47, crit 0.18, attack_speed 0.18 | 2 |
| `sovereign_treads` | Sovereign Treads | special | godforged | feet | 70.0 | speed 0.64, defense 13.0, attack_speed 0.34 | 2 |
| `steel_toe_boots` | Steel-toe Boots | special | uncommon | feet | 4.0 | defense 1.0, max_hp 14.0, speed -0.02 | 12 |
| `street_runners` | Street Runners | special | uncommon | feet | 6.0 | speed 0.04, defense 1.0, attack_speed 0.02 | 7 |
| `subject_band` | Subject 12's Band | special | epic | charm | 35.0 | max_hp 100.0, defense 3.0, crit 0.08 | 5 |
| `subject_grips` | Subject Grips | special | legendary | hands | 35.0 | power 0.37, defense 3.0, crit 0.11, attack_speed 0.07 | 1 |
| `titan_core` | Titan's Ember Core | special | godforged | charm | 60.0 | max_hp 239.0, power 0.41, crit 0.15, attack_speed 0.15 | 2 |
| `titan_grip` | Titan's Grip | special | godforged | hands | 60.0 | power 0.83, defense 7.0, crit 0.25, attack_speed 0.16 | 2 |
| `torn_label` | Torn Shipping Label | special | uncommon | - | - | - | 1 |
| `underworks_epic_charm` | Relapsed Charm | special | epic | charm | 58.0 | max_hp 158.0, defense 5.0, crit 0.13 | 1 |
| `underworks_epic_feet` | Relapsed Boots | special | epic | feet | 58.0 | speed 0.34, defense 7.0, attack_speed 0.16 | 1 |
| `underworks_epic_hands` | Relapsed Gloves | special | epic | hands | 58.0 | power 0.54, defense 5.0, crit 0.17 | 1 |
| `underworks_rare_charm` | Reactor Crew Charm | special | rare | charm | 58.0 | max_hp 114.0, power 0.23, crit 0.14 | 24 |
| `underworks_rare_feet` | Reactor Crew Boots | special | rare | feet | 58.0 | speed 0.28, defense 7.0, attack_speed 0.13 | 24 |
| `underworks_rare_hands` | Reactor Crew Gloves | special | rare | hands | 58.0 | power 0.54, defense 4.0, crit 0.11 | 24 |
| `underworks_uncommon_charm` | Underworks Charm | special | uncommon | charm | 58.0 | max_hp 99.0, power 0.2, crit 0.13 | 16 |
| `underworks_uncommon_feet` | Underworks Boots | special | uncommon | feet | 58.0 | speed 0.24, defense 5.0, attack_speed 0.13 | 16 |
| `underworks_uncommon_hands` | Underworks Gloves | special | uncommon | hands | 58.0 | power 0.5, defense 3.0, crit 0.1 | 16 |
| `used_cargo_gloves` | Used Cargo Gloves | special | common | hands | 13.0 | power 0.11, defense 1.0, attack_speed 0.03 | 1 |
| `used_coolant_uncommon_charm` | Used Coolant Charm | special | common | charm | 53.0 | max_hp 77.0, power 0.15, crit 0.1 | 1 |
| `used_coolant_uncommon_feet` | Used Coolant Boots | special | common | feet | 53.0 | speed 0.19, defense 4.0, attack_speed 0.1 | 1 |
| `used_coolant_uncommon_hands` | Used Coolant Gloves | special | common | hands | 53.0 | power 0.39, defense 2.0, crit 0.08 | 1 |
| `used_deck_boots` | Used Deck Boots | special | common | feet | 13.0 | speed 0.06, defense 1.0, max_hp 13.0 | 1 |
| `used_facility_boots` | Used Facility Boots | special | common | feet | 35.0 | speed 0.14, defense 3.0, attack_speed 0.07 | 1 |
| `used_fight_gloves` | Used Taped Fight Gloves | special | common | hands | 27.0 | power 0.21, defense 1.0, crit 0.05 | 1 |
| `used_foundry_uncommon_charm` | Used Foundry Charm | special | common | charm | 63.0 | max_hp 91.0, power 0.18, crit 0.12 | 1 |
| `used_foundry_uncommon_feet` | Used Foundry Boots | special | common | feet | 63.0 | speed 0.22, defense 5.0, attack_speed 0.12 | 1 |
| `used_foundry_uncommon_hands` | Used Foundry Gloves | special | common | hands | 63.0 | power 0.46, defense 2.0, crit 0.09 | 1 |
| `used_grip_gloves` | Used Lab Grip Gloves | special | common | hands | 35.0 | power 0.26, defense 2.0, crit 0.05 | 1 |
| `used_heart_uncommon_charm` | Used Heartforged Charm | special | common | charm | 68.0 | max_hp 98.0, power 0.2, crit 0.12 | 1 |
| `used_heart_uncommon_feet` | Used Heartforged Boots | special | common | feet | 68.0 | speed 0.24, defense 5.0, attack_speed 0.13 | 1 |
| `used_heart_uncommon_hands` | Used Heartforged Gloves | special | common | hands | 68.0 | power 0.49, defense 3.0, crit 0.1 | 1 |
| `used_insulated_gauntlets` | Used Insulated Gauntlets | special | common | hands | 44.0 | power 0.33, defense 2.0, crit 0.07 | 1 |
| `used_insulated_gloves` | Used Insulated Gloves | special | common | hands | 21.0 | power 0.16, defense 1.0, crit 0.04 | 1 |
| `used_lab_boots` | Used Lab Boots | special | common | feet | 21.0 | speed 0.09, defense 2.0, attack_speed 0.04 | 1 |
| `used_runner_sneakers` | Used Runner Sneakers | special | common | feet | 27.0 | speed 0.14, defense 2.0, attack_speed 0.05 | 1 |
| `used_steel_toe_boots` | Used Steel-toe Boots | special | common | feet | 4.0 | defense 1.0, max_hp 12.0, speed -0.02 | 1 |
| `used_street_runners` | Used Street Runners | special | common | feet | 6.0 | speed 0.03, defense 1.0, attack_speed 0.02 | 1 |
| `used_underworks_uncommon_charm` | Used Underworks Charm | special | common | charm | 58.0 | max_hp 84.0, power 0.17, crit 0.11 | 1 |
| `used_underworks_uncommon_feet` | Used Underworks Boots | special | common | feet | 58.0 | speed 0.21, defense 4.0, attack_speed 0.11 | 1 |
| `used_underworks_uncommon_hands` | Used Underworks Gloves | special | common | hands | 58.0 | power 0.42, defense 2.0, crit 0.09 | 1 |
| `used_walkway_boots` | Used Walkway Boots | special | common | feet | 44.0 | speed 0.16, defense 3.0, attack_speed 0.08 | 1 |
| `walkway_boots` | Walkway Boots | special | uncommon | feet | 44.0 | speed 0.19, defense 4.0, attack_speed 0.1 | 10 |
| `waste_sample` | Waste Sample | special | epic | - | - | - | 1 |
| `alloy_knuckles` | Alloy Knuckles | weapon | uncommon | weapon | 44.0 | power 1.06, crit 0.11 | 9 |
| `arthit_baton` | Commander's Baton | weapon | legendary | weapon | 39.0 | power 1.35, crit 0.15, attack_speed 0.12 | 1 |
| `azure_steel_knuckles` | Azure Steel Knuckles | weapon | rare | weapon | 15.0 | power 0.48, crit 0.06 | 55 |
| `baron_knuckledusters` | Baron's Knuckledusters | weapon | legendary | weapon | 9.0 | power 0.36, max_hp 16.0, crit 0.07 | 1 |
| `brass_knuckles` | Brass Knuckles | weapon | uncommon | weapon | 6.0 | power 0.21, crit 0.04 | 7 |
| `chiefs_baton` | Chief's Baton | weapon | epic | weapon | 21.0 | power 0.68, defense 1.0, crit 0.09 | 4 |
| `coolant_epic_weapon` | Reinstated Knuckles | weapon | epic | weapon | 53.0 | power 1.55, defense 2.0, crit 0.2 | 5 |
| `coolant_rare_weapon` | Vault Guard Knuckles | weapon | rare | weapon | 53.0 | power 1.41, crit 0.16 | 24 |
| `coolant_uncommon_weapon` | Coolant Knuckles | weapon | uncommon | weapon | 53.0 | power 1.25, crit 0.13 | 16 |
| `copper_plated_knuckles` | Copper-Plated Knuckles | weapon | uncommon | weapon | 9.0 | power 0.36 | 55 |
| `crimson_warlord_fists` | Crimson Warlord Fists | weapon | legendary | weapon | 30.0 | power 1.16, crit 0.146 | 17 |
| `crucible_maul` | Crucible King's Maul | weapon | godforged | weapon | 64.0 | power 2.91, crit 0.32, attack_speed 0.26 | 2 |
| `dock_hook` | Dock Hook | weapon | uncommon | weapon | 13.0 | power 0.37, crit 0.05 | 4 |
| `foreman_wrench` | Foreman's Wrench | weapon | epic | weapon | 5.0 | power 0.31, max_hp 9.0 | 1 |
| `founders_edge` | The Founder's Edge | weapon | godforged | weapon | 70.0 | power 3.16, crit 0.35, attack_speed 0.28 | 2 |
| `foundry_epic_weapon` | Overdriven Knuckles | weapon | epic | weapon | 63.0 | power 1.81, defense 2.0, crit 0.23 | 5 |
| `foundry_rare_weapon` | Slagworker Knuckles | weapon | rare | weapon | 63.0 | power 1.65, crit 0.19 | 24 |
| `foundry_uncommon_weapon` | Foundry Knuckles | weapon | uncommon | weapon | 63.0 | power 1.46, crit 0.15 | 16 |
| `gilded_crusher_gauntlets` | Gilded Crusher Gauntlets | weapon | epic | weapon | 22.0 | power 0.76, crit 0.095 | 55 |
| `harbour_hook` | Harbourmaster's Hook | weapon | legendary | weapon | 15.0 | power 0.55, max_hp 25.0, crit 0.08 | 1 |
| `heart_epic_weapon` | Protocol Knuckles | weapon | epic | weapon | 68.0 | power 1.94, defense 2.0, crit 0.25 | 5 |
| `heart_rare_weapon` | Heart Sentry Knuckles | weapon | rare | weapon | 68.0 | power 1.77, crit 0.2 | 16 |
| `heart_uncommon_weapon` | Heartforged Knuckles | weapon | uncommon | weapon | 68.0 | power 1.57, crit 0.16 | 8 |
| `iron_legacy` | The Iron Legacy | weapon | godforged | weapon | 50.0 | power 2.32, crit 0.27, attack_speed 0.19 | 2 |
| `mothers_fang` | Mother's Fang | weapon | godforged | weapon | 30.0 | power 1.54, crit 0.23 | 4 |
| `night_shift_crowbar` | Night Shift Crowbar | weapon | rare | weapon | 38.0 | power 1.04, crit 0.12 | 1 |
| `rebar_pipe` | Rebar Pipe | weapon | uncommon | weapon | 4.0 | power 0.29, speed -0.06 | 12 |
| `ringmaster_wraps` | Ringmaster's Wraps | weapon | epic | weapon | 27.0 | power 0.85, defense 1.0, crit 0.11 | 4 |
| `riot_baton` | Riot Baton | weapon | uncommon | weapon | 35.0 | power 0.84, crit 0.1 | 4 |
| `shock_baton` | Shock Baton | weapon | uncommon | weapon | 21.0 | power 0.54, crit 0.07 | 3 |
| `sovereign_fists` | Sovereign Fists | weapon | godforged | weapon | 70.0 | power 3.16, crit 0.35, attack_speed 0.28 | 2 |
| `taped_knuckles` | Taped Knuckles | weapon | common | weapon | 1.0 | power 0.13 | 4 |
| `titan_slagfist` | Titan's Slagfist | weapon | godforged | weapon | 60.0 | power 2.74, crit 0.3, attack_speed 0.24 | 2 |
| `underworks_epic_weapon` | Relapsed Knuckles | weapon | epic | weapon | 58.0 | power 1.68, defense 2.0, crit 0.22 | 5 |
| `underworks_rare_weapon` | Reactor Crew Knuckles | weapon | rare | weapon | 58.0 | power 1.53, crit 0.18 | 24 |
| `underworks_uncommon_weapon` | Underworks Knuckles | weapon | uncommon | weapon | 58.0 | power 1.36, crit 0.14 | 16 |
| `used_alloy_knuckles` | Used Alloy Knuckles | weapon | common | weapon | 44.0 | power 0.9, crit 0.09 | 1 |
| `used_brass_knuckles` | Used Brass Knuckles | weapon | common | weapon | 6.0 | power 0.18, crit 0.03 | 1 |
| `used_coolant_uncommon_weapon` | Used Coolant Knuckles | weapon | common | weapon | 53.0 | power 1.06, crit 0.11 | 1 |
| `used_dock_hook` | Used Dock Hook | weapon | common | weapon | 13.0 | power 0.31, crit 0.04 | 1 |
| `used_foundry_uncommon_weapon` | Used Foundry Knuckles | weapon | common | weapon | 63.0 | power 1.24, crit 0.13 | 1 |
| `used_heart_uncommon_weapon` | Used Heartforged Knuckles | weapon | common | weapon | 68.0 | power 1.34, crit 0.14 | 1 |
| `used_riot_baton` | Used Riot Baton | weapon | common | weapon | 35.0 | power 0.71, crit 0.09 | 1 |
| `used_shock_baton` | Used Shock Baton | weapon | common | weapon | 21.0 | power 0.46, crit 0.06 | 1 |
| `used_underworks_uncommon_weapon` | Used Underworks Knuckles | weapon | common | weapon | 58.0 | power 1.15, crit 0.12 | 1 |
| `used_weighted_knuckles` | Used Weighted Knuckles | weapon | common | weapon | 27.0 | power 0.57, crit 0.07 | 1 |
| `weighted_knuckles` | Weighted Knuckles | weapon | uncommon | weapon | 27.0 | power 0.68, crit 0.08 | 3 |
| `wrapped_iron_knuckles` | Wrapped Iron Knuckles | weapon | common | weapon | 4.0 | power 0.2 | 55 |

## B. Monster drop matrix

### Smogling (`smogling`, Monster)

- Found: Saltmarket Street (Lv 2, street), Canal Works (Lv 3, street), Rail Yards (Lv 6, street), Rat Nest (Lv 10, street), Waste Pools (Lv 23, street), Factory Drains (Lv 24, street), Saltmarket Backlots (Lv 4, farm)
- Coins: 2 to 5 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 12.0% | 1 | own loot table | anywhere it fights |
| Dock Beanie (`dock_beanie`) | common | 4.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 15.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 12.0% | 1 | own loot table | Saltmarket Backlots |
| Dock Beanie (`dock_beanie`) | common | 4.0% | 1 | own loot table | Saltmarket Backlots |
| Scrap Metal (`scrap_metal`) | common | 15.0% | 1 | own loot table | Saltmarket Backlots |
| Hard Hat (`hard_hat`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Lucky Coin (`lucky_coin`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Work Jacket (`work_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Saltmarket Backlots |
| Steamed Bun (`steamed_bun`) | common | 31.9% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Dock Beanie (`dock_beanie`) | common | 11.5% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 38.6% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Foreman's Boots (`foreman_boots`) | epic | 3.0% | 1 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |

### Tar Rat (`tar_hound`, Monster)

- Found: Saltmarket Street (Lv 2, street), Canal Works (Lv 3, street), Rusted Corner (Lv 4, street), Parking Lot (Lv 5, street), Rail Yards (Lv 6, street), Rat Nest (Lv 10, street), Saltmarket Backlots (Lv 4, farm)
- Coins: 3 to 6 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 10.0% | 1 | own loot table | anywhere it fights |
| Lucky Coin (`lucky_coin`) | uncommon | 5.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 15.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 10.0% | 1 | own loot table | Saltmarket Backlots |
| Lucky Coin (`lucky_coin`) | uncommon | 5.0% | 1 | own loot table | Saltmarket Backlots |
| Scrap Metal (`scrap_metal`) | common | 15.0% | 1 | own loot table | Saltmarket Backlots |
| Hard Hat (`hard_hat`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Lucky Coin (`lucky_coin`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Work Jacket (`work_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Saltmarket Backlots |
| Steamed Bun (`steamed_bun`) | common | 27.1% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Lucky Coin (`lucky_coin`) | uncommon | 14.3% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 38.6% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Foreman's Boots (`foreman_boots`) | epic | 3.0% | 1 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |

### Pipe Brute (`pipe_brute`, Monster)

- Found: Saltmarket Street (Lv 2, street), Canal Works (Lv 3, street), Rusted Corner (Lv 4, street), Parking Lot (Lv 5, street), Rat Nest (Lv 10, street), Saltmarket Backlots (Lv 4, farm)
- Coins: 6 to 12 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Ginger Tea (`ginger_tea`) | uncommon | 15.0% | 1 | own loot table | anywhere it fights |
| Taped Knuckles (`taped_knuckles`) | common | 4.0% | 1 | own loot table | anywhere it fights |
| Rebar Pipe (`rebar_pipe`) | uncommon | 8.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 30.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 15.0% | 1 | own loot table | Saltmarket Backlots |
| Taped Knuckles (`taped_knuckles`) | common | 4.0% | 1 | own loot table | Saltmarket Backlots |
| Rebar Pipe (`rebar_pipe`) | uncommon | 8.0% | 1 | own loot table | Saltmarket Backlots |
| Scrap Metal (`scrap_metal`) | common | 30.0% | 1 | own loot table | Saltmarket Backlots |
| Hard Hat (`hard_hat`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Lucky Coin (`lucky_coin`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Work Jacket (`work_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Saltmarket Backlots |
| Ginger Tea (`ginger_tea`) | uncommon | 38.6% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Taped Knuckles (`taped_knuckles`) | common | 11.5% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Rebar Pipe (`rebar_pipe`) | uncommon | 22.1% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 65.7% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Foreman's Boots (`foreman_boots`) | epic | 3.0% | 1 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |

### Smog Warden (`smog_warden`, Elite)

- Found: Saltmarket Street (Lv 2, street), Canal Works (Lv 3, street), Rusted Corner (Lv 4, street), Night Market (Lv 7, street), Rat Nest (Lv 10, street), Waste Pools (Lv 23, street), Factory Drains (Lv 24, street), Saltmarket Backlots (Lv 4, farm)
- Coins: 20 to 35 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Ginger Tea (`ginger_tea`) | uncommon | 60.0% | 1 | own loot table | anywhere it fights |
| Work Jacket (`work_jacket`) | uncommon | 20.0% | 1 | own loot table | anywhere it fights |
| Iron Wraps (`iron_wraps`) | rare | 35.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 80.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 25.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 60.0% | 1 | own loot table | Saltmarket Backlots |
| Work Jacket (`work_jacket`) | uncommon | 20.0% | 1 | own loot table | Saltmarket Backlots |
| Iron Wraps (`iron_wraps`) | rare | 35.0% | 1 | own loot table | Saltmarket Backlots |
| Scrap Metal (`scrap_metal`) | common | 80.0% | 1 | own loot table | Saltmarket Backlots |
| Refined Alloy (`refined_alloy`) | rare | 25.0% | 1 | own loot table | Saltmarket Backlots |
| Hard Hat (`hard_hat`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Lucky Coin (`lucky_coin`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Work Jacket (`work_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Saltmarket Backlots |
| Ginger Tea (`ginger_tea`) | uncommon | 93.6% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Work Jacket (`work_jacket`) | uncommon | 48.8% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Iron Wraps (`iron_wraps`) | rare | 72.5% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 99.2% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 57.8% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Foreman's Boots (`foreman_boots`) | epic | 3.0% | 1 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |

### Dock Thug (`dock_thug`, Monster)

- Found: Rusted Corner (Lv 4, street), Parking Lot (Lv 5, street), Rail Yards (Lv 6, street), Night Market (Lv 7, street), Smokestack Refinery (Lv 9, street), Gang Headquarters (Lv 10, street), Port Road (Lv 12, street), Rail Sidings (Lv 9, farm), Harbour Stacks (Lv 15, farm)
- Coins: 4 to 9 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 12.0% | 1 | own loot table | anywhere it fights |
| Fingerless Gloves (`fingerless_gloves`) | common | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 20.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 12.0% | 1 | own loot table | Rail Sidings |
| Fingerless Gloves (`fingerless_gloves`) | common | 3.0% | 1 | own loot table | Rail Sidings |
| Scrap Metal (`scrap_metal`) | common | 20.0% | 1 | own loot table | Rail Sidings |
| Brass Knuckles (`brass_knuckles`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Hard Hat (`hard_hat`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Helm (`iron_helm`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Lucky Coin (`lucky_coin`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Riveted Jacket (`riveted_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Street Runners (`street_runners`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Work Jacket (`work_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Rail Sidings |
| Steamed Bun (`steamed_bun`) | common | 31.9% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Fingerless Gloves (`fingerless_gloves`) | common | 8.733% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 48.8% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Smelter's Apron (`smelter_apron`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Jade Charm (`jade_charm`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Steamed Bun (`steamed_bun`) | common | 10.9% | 1 | own loot table | Harbour Stacks |
| Fingerless Gloves (`fingerless_gloves`) | common | 2.73% | 1 | own loot table | Harbour Stacks |
| Scrap Metal (`scrap_metal`) | common | 18.2% | 1 | own loot table | Harbour Stacks |
| Cargo Gloves (`cargo_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Deck Boots (`deck_boots`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Dock Hook (`dock_hook`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Docker's Cap (`dockers_cap`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Port Authority Jacket (`port_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Steamed Bun (`steamed_bun`) | common | 29.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Fingerless Gloves (`fingerless_gloves`) | common | 7.968% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 45.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Harbourmaster's Cap (`harbourmaster_cap`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Dockmaster's Boots (`dockmaster_boots`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |

### Rail Bruiser (`rail_bruiser`, Monster)

- Found: Parking Lot (Lv 5, street), Rail Yards (Lv 6, street), Night Market (Lv 7, street), Fight Club (Lv 8, street), Smokestack Refinery (Lv 9, street), Gang Headquarters (Lv 10, street), Port Road (Lv 12, street), Rail Sidings (Lv 9, farm)
- Coins: 8 to 15 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Ginger Tea (`ginger_tea`) | uncommon | 18.0% | 1 | own loot table | anywhere it fights |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 4.0% | 1 | own loot table | anywhere it fights |
| Riveted Jacket (`riveted_jacket`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 30.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 18.0% | 1 | own loot table | Rail Sidings |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 4.0% | 1 | own loot table | Rail Sidings |
| Riveted Jacket (`riveted_jacket`) | uncommon | 3.0% | 1 | own loot table | Rail Sidings |
| Scrap Metal (`scrap_metal`) | common | 30.0% | 1 | own loot table | Rail Sidings |
| Brass Knuckles (`brass_knuckles`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Hard Hat (`hard_hat`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Helm (`iron_helm`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Lucky Coin (`lucky_coin`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Riveted Jacket (`riveted_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Street Runners (`street_runners`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Work Jacket (`work_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Rail Sidings |
| Ginger Tea (`ginger_tea`) | uncommon | 44.9% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 11.5% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Riveted Jacket (`riveted_jacket`) | uncommon | 8.733% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 65.7% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Smelter's Apron (`smelter_apron`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Jade Charm (`jade_charm`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |

### Night Market Punk (`market_punk`, Monster)

- Found: Night Market (Lv 7, street), Fight Club (Lv 8, street), Smokestack Refinery (Lv 9, street), Gang Headquarters (Lv 10, street), Freight Market (Lv 13, street), Rail Sidings (Lv 9, farm)
- Coins: 6 to 12 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Ginger Tea (`ginger_tea`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Street Runners (`street_runners`) | uncommon | 4.0% | 1 | own loot table | anywhere it fights |
| Brass Knuckles (`brass_knuckles`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 20.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 12.0% | 1 | own loot table | Rail Sidings |
| Street Runners (`street_runners`) | uncommon | 4.0% | 1 | own loot table | Rail Sidings |
| Brass Knuckles (`brass_knuckles`) | uncommon | 3.0% | 1 | own loot table | Rail Sidings |
| Scrap Metal (`scrap_metal`) | common | 20.0% | 1 | own loot table | Rail Sidings |
| Brass Knuckles (`brass_knuckles`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Hard Hat (`hard_hat`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Helm (`iron_helm`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Lucky Coin (`lucky_coin`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Riveted Jacket (`riveted_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Street Runners (`street_runners`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Work Jacket (`work_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Rail Sidings |
| Ginger Tea (`ginger_tea`) | uncommon | 31.9% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Street Runners (`street_runners`) | uncommon | 11.5% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Brass Knuckles (`brass_knuckles`) | uncommon | 8.733% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 48.8% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Smelter's Apron (`smelter_apron`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Jade Charm (`jade_charm`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |

### Refinery Enforcer (`refinery_enforcer`, Elite)

- Found: Smokestack Refinery (Lv 9, street), Gang Headquarters (Lv 10, street), Freight Market (Lv 13, street), Rail Sidings (Lv 9, farm)
- Coins: 25 to 40 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Ginger Tea (`ginger_tea`) | uncommon | 50.0% | 1 | own loot table | anywhere it fights |
| Iron Helm (`iron_helm`) | uncommon | 15.0% | 1 | own loot table | anywhere it fights |
| Riveted Jacket (`riveted_jacket`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 80.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 30.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 50.0% | 1 | own loot table | Rail Sidings |
| Iron Helm (`iron_helm`) | uncommon | 15.0% | 1 | own loot table | Rail Sidings |
| Riveted Jacket (`riveted_jacket`) | uncommon | 12.0% | 1 | own loot table | Rail Sidings |
| Scrap Metal (`scrap_metal`) | common | 80.0% | 1 | own loot table | Rail Sidings |
| Refined Alloy (`refined_alloy`) | rare | 30.0% | 1 | own loot table | Rail Sidings |
| Brass Knuckles (`brass_knuckles`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Hard Hat (`hard_hat`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Helm (`iron_helm`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Lucky Coin (`lucky_coin`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Riveted Jacket (`riveted_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Street Runners (`street_runners`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Work Jacket (`work_jacket`) | uncommon | 0.22% | 1 | farming ground prize | Rail Sidings |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Rail Sidings |
| Ginger Tea (`ginger_tea`) | uncommon | 87.5% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Iron Helm (`iron_helm`) | uncommon | 38.6% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Riveted Jacket (`riveted_jacket`) | uncommon | 31.9% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 99.2% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 65.7% | 1-3 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Smelter's Apron (`smelter_apron`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |
| Jade Charm (`jade_charm`) | epic | 3.0% | 1 | field elite | Rail Sidings; when it comes as a field elite (5% of spawns) |

### Bottle Thrower (`street_thrower`, Monster)

- Found: Rusted Corner (Lv 4, street), Parking Lot (Lv 5, street), Fight Club (Lv 8, street), Saltmarket Backlots (Lv 4, farm)
- Coins: 5 to 10 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 12.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 20.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 12.0% | 1 | own loot table | Saltmarket Backlots |
| Scrap Metal (`scrap_metal`) | common | 20.0% | 1 | own loot table | Saltmarket Backlots |
| Hard Hat (`hard_hat`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Lucky Coin (`lucky_coin`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Rebar Pipe (`rebar_pipe`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Steel-toe Boots (`steel_toe_boots`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Work Jacket (`work_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Saltmarket Backlots |
| Iron Wraps (`iron_wraps`) | rare | 0.6% | 1 | farming ground prize | Saltmarket Backlots |
| Steamed Bun (`steamed_bun`) | common | 31.9% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 48.8% | 1-3 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |
| Foreman's Boots (`foreman_boots`) | epic | 3.0% | 1 | field elite | Saltmarket Backlots; when it comes as a field elite (5% of spawns) |

### Stevedore (`stevedore`, Monster)

- Found: Port Road (Lv 12, street), Freight Market (Lv 13, street), Container Yard (Lv 15, street), Crane Yard (Lv 16, street), Factory Gate (Lv 19, street), Production Line (Lv 21, street), Harbour Stacks (Lv 15, farm)
- Coins: 12 to 20 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 20.0% | 1 | own loot table | anywhere it fights |
| Deck Boots (`deck_boots`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 10.9% | 1 | own loot table | Harbour Stacks |
| Ginger Tea (`ginger_tea`) | uncommon | 18.2% | 1 | own loot table | Harbour Stacks |
| Deck Boots (`deck_boots`) | uncommon | 2.73% | 1 | own loot table | Harbour Stacks |
| Scrap Metal (`scrap_metal`) | common | 45.5% | 1 | own loot table | Harbour Stacks |
| Cargo Gloves (`cargo_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Deck Boots (`deck_boots`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Dock Hook (`dock_hook`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Docker's Cap (`dockers_cap`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Port Authority Jacket (`port_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Rice Box (`rice_box`) | uncommon | 29.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Ginger Tea (`ginger_tea`) | uncommon | 45.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Deck Boots (`deck_boots`) | uncommon | 7.968% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 83.8% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Harbourmaster's Cap (`harbourmaster_cap`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Dockmaster's Boots (`dockmaster_boots`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |

### Port Guard (`port_guard`, Elite)

- Found: Port Road (Lv 12, street), Freight Market (Lv 13, street), Container Yard (Lv 15, street), Crane Yard (Lv 16, street), Factory Gate (Lv 19, street), Harbour Stacks (Lv 15, farm)
- Coins: 16 to 26 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 30.0% | 1 | own loot table | anywhere it fights |
| Docker's Cap (`dockers_cap`) | uncommon | 4.0% | 1 | own loot table | anywhere it fights |
| Port Authority Jacket (`port_jacket`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 12.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 10.9% | 1 | own loot table | Harbour Stacks |
| Ginger Tea (`ginger_tea`) | uncommon | 27.3% | 1 | own loot table | Harbour Stacks |
| Docker's Cap (`dockers_cap`) | uncommon | 3.64% | 1 | own loot table | Harbour Stacks |
| Port Authority Jacket (`port_jacket`) | uncommon | 2.73% | 1 | own loot table | Harbour Stacks |
| Refined Alloy (`refined_alloy`) | rare | 10.9% | 1 | own loot table | Harbour Stacks |
| Scrap Metal (`scrap_metal`) | common | 45.5% | 1 | own loot table | Harbour Stacks |
| Cargo Gloves (`cargo_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Deck Boots (`deck_boots`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Dock Hook (`dock_hook`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Docker's Cap (`dockers_cap`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Port Authority Jacket (`port_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Rice Box (`rice_box`) | uncommon | 29.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Ginger Tea (`ginger_tea`) | uncommon | 61.6% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Docker's Cap (`dockers_cap`) | uncommon | 10.5% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Port Authority Jacket (`port_jacket`) | uncommon | 7.968% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 29.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 83.8% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Harbourmaster's Cap (`harbourmaster_cap`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Dockmaster's Boots (`dockmaster_boots`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |

### Dock Slinger (`dock_slinger`, Monster)

- Found: Port Road (Lv 12, street), Freight Market (Lv 13, street), Container Yard (Lv 15, street), Crane Yard (Lv 16, street), Warehouse Row (Lv 26, street), The Counting House (Lv 29, street), Core Facility Gate (Lv 33, street), Core Approach (Lv 42, street), Cooling Tunnels (Lv 44, street), Harbour Stacks (Lv 15, farm)
- Coins: 10 to 16 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 15.0% | 1 | own loot table | anywhere it fights |
| Cargo Gloves (`cargo_gloves`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 40.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 13.7% | 1 | own loot table | Harbour Stacks |
| Cargo Gloves (`cargo_gloves`) | uncommon | 2.73% | 1 | own loot table | Harbour Stacks |
| Scrap Metal (`scrap_metal`) | common | 36.4% | 1 | own loot table | Harbour Stacks |
| Cargo Gloves (`cargo_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Deck Boots (`deck_boots`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Dock Hook (`dock_hook`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Docker's Cap (`dockers_cap`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Port Authority Jacket (`port_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Harbour Stacks |
| Steamed Bun (`steamed_bun`) | common | 35.6% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Cargo Gloves (`cargo_gloves`) | uncommon | 7.968% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 74.3% | 1-3 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Harbourmaster's Cap (`harbourmaster_cap`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |
| Dockmaster's Boots (`dockmaster_boots`) | epic | 3.0% | 1 | field elite | Harbour Stacks; when it comes as a field elite (5% of spawns) |

### Plant Guard (`plant_guard`, Elite)

- Found: Factory Gate (Lv 19, street), Production Line (Lv 21, street), Waste Pools (Lv 23, street), Plant Outskirts (Lv 22, farm)
- Coins: 18 to 30 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 30.0% | 1 | own loot table | anywhere it fights |
| Hazmat Hood (`hazmat_hood`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Plant Security Vest (`plant_vest`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 15.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 8.64% | 1 | own loot table | Plant Outskirts |
| Ginger Tea (`ginger_tea`) | uncommon | 21.6% | 1 | own loot table | Plant Outskirts |
| Hazmat Hood (`hazmat_hood`) | uncommon | 2.16% | 1 | own loot table | Plant Outskirts |
| Plant Security Vest (`plant_vest`) | uncommon | 2.16% | 1 | own loot table | Plant Outskirts |
| Refined Alloy (`refined_alloy`) | rare | 10.8% | 1 | own loot table | Plant Outskirts |
| Scrap Metal (`scrap_metal`) | common | 36.0% | 1 | own loot table | Plant Outskirts |
| Hazmat Hood (`hazmat_hood`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Insulated Gloves (`insulated_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Lab Boots (`lab_boots`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Plant Security Vest (`plant_vest`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Shock Baton (`shock_baton`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Rice Box (`rice_box`) | uncommon | 23.7% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Ginger Tea (`ginger_tea`) | uncommon | 51.8% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Hazmat Hood (`hazmat_hood`) | uncommon | 6.341% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Plant Security Vest (`plant_vest`) | uncommon | 6.341% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 29.0% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 73.8% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Chief's Gloves (`chiefs_gloves`) | epic | 3.0% | 1 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Chief's Baton (`chiefs_baton`) | epic | 3.0% | 1 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |

### Hazmat Sprayer (`hazmat_sprayer`, Monster)

- Found: Factory Gate (Lv 19, street), Production Line (Lv 21, street), Waste Pools (Lv 23, street), Factory Drains (Lv 24, street), Warehouse Row (Lv 26, street), The Counting House (Lv 29, street), Core Facility Gate (Lv 33, street), Test Labs (Lv 35, street), Machine Hall (Lv 37, street), Core Approach (Lv 42, street), Cooling Tunnels (Lv 44, street), Reactor Walkway (Lv 46, street), Plant Outskirts (Lv 22, farm), Facility Annex (Lv 37, farm), Core Spillway (Lv 43, farm), Spillway Gatehouse (Lv 45, farm)
- Coins: 12 to 20 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 15.0% | 1 | own loot table | anywhere it fights |
| Insulated Gloves (`insulated_gloves`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 40.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 10.8% | 1 | own loot table | Plant Outskirts |
| Insulated Gloves (`insulated_gloves`) | uncommon | 2.16% | 1 | own loot table | Plant Outskirts |
| Scrap Metal (`scrap_metal`) | common | 28.8% | 1 | own loot table | Plant Outskirts |
| Hazmat Hood (`hazmat_hood`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Insulated Gloves (`insulated_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Lab Boots (`lab_boots`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Plant Security Vest (`plant_vest`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Shock Baton (`shock_baton`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Steamed Bun (`steamed_bun`) | common | 29.0% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Insulated Gloves (`insulated_gloves`) | uncommon | 6.341% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 63.9% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Chief's Gloves (`chiefs_gloves`) | epic | 3.0% | 1 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Chief's Baton (`chiefs_baton`) | epic | 3.0% | 1 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Steamed Bun (`steamed_bun`) | common | 9.45% | 1 | own loot table | Facility Annex |
| Insulated Gloves (`insulated_gloves`) | uncommon | 1.89% | 1 | own loot table | Facility Annex |
| Scrap Metal (`scrap_metal`) | common | 25.2% | 1 | own loot table | Facility Annex |
| Facility Boots (`facility_boots`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Facility Helmet (`facility_helmet`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Lab Grip Gloves (`grip_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Riot Baton (`riot_baton`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Trooper Vest (`trooper_vest`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Steamed Bun (`steamed_bun`) | common | 25.8% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Insulated Gloves (`insulated_gloves`) | uncommon | 5.564% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 58.1% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Sak's Loafers (`sak_loafers`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Subject 12's Band (`subject_band`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Steamed Bun (`steamed_bun`) | common | 9.45% | 1 | own loot table | Core Spillway |
| Insulated Gloves (`insulated_gloves`) | uncommon | 1.89% | 1 | own loot table | Core Spillway |
| Scrap Metal (`scrap_metal`) | common | 25.2% | 1 | own loot table | Core Spillway |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Core Guard Helm (`core_guard_helm`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Reactor Plate (`reactor_plate`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Walkway Boots (`walkway_boots`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Steamed Bun (`steamed_bun`) | common | 25.8% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Insulated Gloves (`insulated_gloves`) | uncommon | 5.564% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 58.1% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 2.0% | 1 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 2.0% | 1 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Steamed Bun (`steamed_bun`) | common | 9.45% | 1 | own loot table | Spillway Gatehouse |
| Insulated Gloves (`insulated_gloves`) | uncommon | 1.89% | 1 | own loot table | Spillway Gatehouse |
| Scrap Metal (`scrap_metal`) | common | 25.2% | 1 | own loot table | Spillway Gatehouse |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Core Guard Helm (`core_guard_helm`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Reactor Plate (`reactor_plate`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Walkway Boots (`walkway_boots`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Steamed Bun (`steamed_bun`) | common | 25.8% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Insulated Gloves (`insulated_gloves`) | uncommon | 5.564% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 58.1% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 2.0% | 1 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 2.0% | 1 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |

### Patrol Unit (`patrol_unit`, Monster)

- Found: Production Line (Lv 21, street), Waste Pools (Lv 23, street), Factory Drains (Lv 24, street), Core Facility Gate (Lv 33, street), Machine Hall (Lv 37, street), Plant Outskirts (Lv 22, farm), Facility Annex (Lv 37, farm), Core Overflow (Lv 50, farm)
- Coins: 14 to 24 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Lab Boots (`lab_boots`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 20.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 90.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 8.64% | 1 | own loot table | Plant Outskirts |
| Lab Boots (`lab_boots`) | uncommon | 2.16% | 1 | own loot table | Plant Outskirts |
| Refined Alloy (`refined_alloy`) | rare | 14.4% | 1 | own loot table | Plant Outskirts |
| Scrap Metal (`scrap_metal`) | common | 64.8% | 1 | own loot table | Plant Outskirts |
| Hazmat Hood (`hazmat_hood`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Insulated Gloves (`insulated_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Lab Boots (`lab_boots`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Plant Security Vest (`plant_vest`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Shock Baton (`shock_baton`) | uncommon | 0.4% | 1 | farming ground prize | Plant Outskirts |
| Rice Box (`rice_box`) | uncommon | 23.7% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Lab Boots (`lab_boots`) | uncommon | 6.341% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.3% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 95.6% | 1-3 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Chief's Gloves (`chiefs_gloves`) | epic | 3.0% | 1 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Chief's Baton (`chiefs_baton`) | epic | 3.0% | 1 | field elite | Plant Outskirts; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.56% | 1 | own loot table | Facility Annex |
| Lab Boots (`lab_boots`) | uncommon | 1.89% | 1 | own loot table | Facility Annex |
| Refined Alloy (`refined_alloy`) | rare | 12.6% | 1 | own loot table | Facility Annex |
| Scrap Metal (`scrap_metal`) | common | 56.7% | 1 | own loot table | Facility Annex |
| Facility Boots (`facility_boots`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Facility Helmet (`facility_helmet`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Lab Grip Gloves (`grip_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Riot Baton (`riot_baton`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Trooper Vest (`trooper_vest`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Rice Box (`rice_box`) | uncommon | 21.0% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Lab Boots (`lab_boots`) | uncommon | 5.564% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 33.2% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 91.9% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Sak's Loafers (`sak_loafers`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Subject 12's Band (`subject_band`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 6.84% | 1 | own loot table | Core Overflow |
| Lab Boots (`lab_boots`) | uncommon | 1.71% | 1 | own loot table | Core Overflow |
| Refined Alloy (`refined_alloy`) | rare | 11.4% | 1 | own loot table | Core Overflow |
| Scrap Metal (`scrap_metal`) | common | 51.3% | 1 | own loot table | Core Overflow |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Walkway Boots (`walkway_boots`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Rice Box (`rice_box`) | uncommon | 19.1% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Lab Boots (`lab_boots`) | uncommon | 5.043% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 30.4% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 88.4% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Director's Coat (`director_coat`) | epic | 3.0% | 1 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |

### Network Runner (`network_runner`, Monster)

- Found: Warehouse Row (Lv 26, street), The Underground Ring (Lv 27, street), The Counting House (Lv 29, street), Rattanachai Tower (Lv 31, street), Network Backrooms (Lv 29, farm)
- Coins: 14 to 24 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Steamed Bun (`steamed_bun`) | common | 15.0% | 1 | own loot table | anywhere it fights |
| Runner Sneakers (`runner_sneakers`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 30.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Steamed Bun (`steamed_bun`) | common | 11.1% | 1 | own loot table | Network Backrooms |
| Runner Sneakers (`runner_sneakers`) | uncommon | 2.22% | 1 | own loot table | Network Backrooms |
| Scrap Metal (`scrap_metal`) | common | 22.2% | 1 | own loot table | Network Backrooms |
| Taped Fight Gloves (`fight_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Kevlar Jacket (`kevlar_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Runner Sneakers (`runner_sneakers`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Night Watch Cap (`watch_cap`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Weighted Knuckles (`weighted_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Steamed Bun (`steamed_bun`) | common | 29.7% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Runner Sneakers (`runner_sneakers`) | uncommon | 6.513% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 52.9% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| K7 Plating (`k7_plating`) | epic | 3.0% | 1 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Ringmaster's Wraps (`ringmaster_wraps`) | epic | 3.0% | 1 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |

### Network Enforcer (`network_enforcer`, Monster)

- Found: Warehouse Row (Lv 26, street), The Underground Ring (Lv 27, street), The Counting House (Lv 29, street), Rattanachai Tower (Lv 31, street), Core Facility Gate (Lv 33, street), Network Backrooms (Lv 29, farm)
- Coins: 18 to 30 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 25.0% | 1 | own loot table | anywhere it fights |
| Kevlar Jacket (`kevlar_jacket`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 15.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 8.88% | 1 | own loot table | Network Backrooms |
| Ginger Tea (`ginger_tea`) | uncommon | 18.5% | 1 | own loot table | Network Backrooms |
| Kevlar Jacket (`kevlar_jacket`) | uncommon | 2.22% | 1 | own loot table | Network Backrooms |
| Refined Alloy (`refined_alloy`) | rare | 11.1% | 1 | own loot table | Network Backrooms |
| Scrap Metal (`scrap_metal`) | common | 37.0% | 1 | own loot table | Network Backrooms |
| Taped Fight Gloves (`fight_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Kevlar Jacket (`kevlar_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Runner Sneakers (`runner_sneakers`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Night Watch Cap (`watch_cap`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Weighted Knuckles (`weighted_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Rice Box (`rice_box`) | uncommon | 24.3% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Ginger Tea (`ginger_tea`) | uncommon | 45.9% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Kevlar Jacket (`kevlar_jacket`) | uncommon | 6.513% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 29.7% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 75.0% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| K7 Plating (`k7_plating`) | epic | 3.0% | 1 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Ringmaster's Wraps (`ringmaster_wraps`) | epic | 3.0% | 1 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |

### Ring Fighter (`ring_fighter`, Elite)

- Found: The Underground Ring (Lv 27, street), The Counting House (Lv 29, street), Rattanachai Tower (Lv 31, street), Network Backrooms (Lv 29, farm)
- Coins: 20 to 32 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 12.0% | 1 | own loot table | anywhere it fights |
| Ginger Tea (`ginger_tea`) | uncommon | 30.0% | 1 | own loot table | anywhere it fights |
| Taped Fight Gloves (`fight_gloves`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Night Watch Cap (`watch_cap`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 15.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 8.88% | 1 | own loot table | Network Backrooms |
| Ginger Tea (`ginger_tea`) | uncommon | 22.2% | 1 | own loot table | Network Backrooms |
| Taped Fight Gloves (`fight_gloves`) | uncommon | 2.22% | 1 | own loot table | Network Backrooms |
| Night Watch Cap (`watch_cap`) | uncommon | 2.22% | 1 | own loot table | Network Backrooms |
| Refined Alloy (`refined_alloy`) | rare | 11.1% | 1 | own loot table | Network Backrooms |
| Scrap Metal (`scrap_metal`) | common | 37.0% | 1 | own loot table | Network Backrooms |
| Taped Fight Gloves (`fight_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Kevlar Jacket (`kevlar_jacket`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Runner Sneakers (`runner_sneakers`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Night Watch Cap (`watch_cap`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Weighted Knuckles (`weighted_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Network Backrooms |
| Rice Box (`rice_box`) | uncommon | 24.3% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Ginger Tea (`ginger_tea`) | uncommon | 52.9% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Taped Fight Gloves (`fight_gloves`) | uncommon | 6.513% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Night Watch Cap (`watch_cap`) | uncommon | 6.513% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 29.7% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 75.0% | 1-3 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| K7 Plating (`k7_plating`) | epic | 3.0% | 1 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |
| Ringmaster's Wraps (`ringmaster_wraps`) | epic | 3.0% | 1 | field elite | Network Backrooms; when it comes as a field elite (5% of spawns) |

### Facility Trooper (`facility_trooper`, Monster)

- Found: Core Facility Gate (Lv 33, street), Test Labs (Lv 35, street), Machine Hall (Lv 37, street), Control Room (Lv 39, street), Core Approach (Lv 42, street), Cooling Tunnels (Lv 44, street), Reactor Walkway (Lv 46, street), The Core Chamber (Lv 48, street), Facility Annex (Lv 37, farm), Core Overflow (Lv 50, farm), Core Spillway (Lv 43, farm), Spillway Gatehouse (Lv 45, farm)
- Coins: 20 to 32 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 15.0% | 1 | own loot table | anywhere it fights |
| Facility Helmet (`facility_helmet`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 15.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 9.45% | 1 | own loot table | Facility Annex |
| Facility Helmet (`facility_helmet`) | uncommon | 1.89% | 1 | own loot table | Facility Annex |
| Refined Alloy (`refined_alloy`) | rare | 9.45% | 1 | own loot table | Facility Annex |
| Scrap Metal (`scrap_metal`) | common | 31.5% | 1 | own loot table | Facility Annex |
| Facility Boots (`facility_boots`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Facility Helmet (`facility_helmet`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Lab Grip Gloves (`grip_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Riot Baton (`riot_baton`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Trooper Vest (`trooper_vest`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Rice Box (`rice_box`) | uncommon | 25.8% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Facility Helmet (`facility_helmet`) | uncommon | 5.564% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 25.8% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 67.9% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Sak's Loafers (`sak_loafers`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Subject 12's Band (`subject_band`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 8.55% | 1 | own loot table | Core Overflow |
| Facility Helmet (`facility_helmet`) | uncommon | 1.71% | 1 | own loot table | Core Overflow |
| Refined Alloy (`refined_alloy`) | rare | 8.55% | 1 | own loot table | Core Overflow |
| Scrap Metal (`scrap_metal`) | common | 28.5% | 1 | own loot table | Core Overflow |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Walkway Boots (`walkway_boots`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Rice Box (`rice_box`) | uncommon | 23.5% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Facility Helmet (`facility_helmet`) | uncommon | 5.043% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 23.5% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 63.4% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Director's Coat (`director_coat`) | epic | 3.0% | 1 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 9.45% | 1 | own loot table | Core Spillway |
| Facility Helmet (`facility_helmet`) | uncommon | 1.89% | 1 | own loot table | Core Spillway |
| Refined Alloy (`refined_alloy`) | rare | 9.45% | 1 | own loot table | Core Spillway |
| Scrap Metal (`scrap_metal`) | common | 31.5% | 1 | own loot table | Core Spillway |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Core Guard Helm (`core_guard_helm`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Reactor Plate (`reactor_plate`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Walkway Boots (`walkway_boots`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Rice Box (`rice_box`) | uncommon | 25.8% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Facility Helmet (`facility_helmet`) | uncommon | 5.564% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 25.8% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 67.9% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 2.0% | 1 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 2.0% | 1 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 9.45% | 1 | own loot table | Spillway Gatehouse |
| Facility Helmet (`facility_helmet`) | uncommon | 1.89% | 1 | own loot table | Spillway Gatehouse |
| Refined Alloy (`refined_alloy`) | rare | 9.45% | 1 | own loot table | Spillway Gatehouse |
| Scrap Metal (`scrap_metal`) | common | 31.5% | 1 | own loot table | Spillway Gatehouse |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Core Guard Helm (`core_guard_helm`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Reactor Plate (`reactor_plate`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Walkway Boots (`walkway_boots`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Rice Box (`rice_box`) | uncommon | 25.8% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Facility Helmet (`facility_helmet`) | uncommon | 5.564% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 25.8% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 67.9% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 2.0% | 1 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 2.0% | 1 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |

### Riot Trooper (`riot_trooper`, Elite)

- Found: Core Facility Gate (Lv 33, street), Machine Hall (Lv 37, street), Control Room (Lv 39, street), Core Approach (Lv 42, street), Reactor Walkway (Lv 46, street), The Core Chamber (Lv 48, street), Facility Annex (Lv 37, farm)
- Coins: 24 to 38 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 20.0% | 1 | own loot table | anywhere it fights |
| Trooper Vest (`trooper_vest`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Facility Boots (`facility_boots`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 20.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 60.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 12.6% | 1 | own loot table | Facility Annex |
| Trooper Vest (`trooper_vest`) | uncommon | 1.89% | 1 | own loot table | Facility Annex |
| Facility Boots (`facility_boots`) | uncommon | 1.89% | 1 | own loot table | Facility Annex |
| Refined Alloy (`refined_alloy`) | rare | 12.6% | 1 | own loot table | Facility Annex |
| Scrap Metal (`scrap_metal`) | common | 37.8% | 1 | own loot table | Facility Annex |
| Facility Boots (`facility_boots`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Facility Helmet (`facility_helmet`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Lab Grip Gloves (`grip_gloves`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Riot Baton (`riot_baton`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Trooper Vest (`trooper_vest`) | uncommon | 0.4% | 1 | farming ground prize | Facility Annex |
| Rice Box (`rice_box`) | uncommon | 33.2% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Trooper Vest (`trooper_vest`) | uncommon | 5.564% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Facility Boots (`facility_boots`) | uncommon | 5.564% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 33.2% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 75.9% | 1-3 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Sak's Loafers (`sak_loafers`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |
| Subject 12's Band (`subject_band`) | epic | 3.0% | 1 | field elite | Facility Annex; when it comes as a field elite (5% of spawns) |

### Hybrid Worker (`hybrid_worker`, Monster)

- Found: Test Labs (Lv 35, street), Machine Hall (Lv 37, street), Control Room (Lv 39, street), Core Approach (Lv 42, street), Cooling Tunnels (Lv 44, street), Reactor Walkway (Lv 46, street), The Core Chamber (Lv 48, street)
- Coins: 16 to 28 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 15.0% | 1 | own loot table | anywhere it fights |
| Lab Grip Gloves (`grip_gloves`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 15.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 40.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |

### Core Sentinel (`core_sentinel`, Elite)

- Found: Core Approach (Lv 42, street), Reactor Walkway (Lv 46, street), The Core Chamber (Lv 48, street), Core Overflow (Lv 50, farm), Core Spillway (Lv 43, farm), Spillway Gatehouse (Lv 45, farm)
- Coins: 28 to 44 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 20.0% | 1 | own loot table | anywhere it fights |
| Core Guard Helm (`core_guard_helm`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Reactor Plate (`reactor_plate`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 30.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 90.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 11.4% | 1 | own loot table | Core Overflow |
| Core Guard Helm (`core_guard_helm`) | uncommon | 1.71% | 1 | own loot table | Core Overflow |
| Reactor Plate (`reactor_plate`) | uncommon | 1.71% | 1 | own loot table | Core Overflow |
| Refined Alloy (`refined_alloy`) | rare | 17.1% | 1 | own loot table | Core Overflow |
| Scrap Metal (`scrap_metal`) | common | 51.3% | 1 | own loot table | Core Overflow |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Walkway Boots (`walkway_boots`) | uncommon | 0.67% | 1 | farming ground prize | Core Overflow |
| Rice Box (`rice_box`) | uncommon | 30.4% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Core Guard Helm (`core_guard_helm`) | uncommon | 5.043% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Reactor Plate (`reactor_plate`) | uncommon | 5.043% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 43.0% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 88.4% | 1-3 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Director's Coat (`director_coat`) | epic | 3.0% | 1 | field elite | Core Overflow; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 12.6% | 1 | own loot table | Core Spillway |
| Core Guard Helm (`core_guard_helm`) | uncommon | 1.89% | 1 | own loot table | Core Spillway |
| Reactor Plate (`reactor_plate`) | uncommon | 1.89% | 1 | own loot table | Core Spillway |
| Refined Alloy (`refined_alloy`) | rare | 18.9% | 1 | own loot table | Core Spillway |
| Scrap Metal (`scrap_metal`) | common | 56.7% | 1 | own loot table | Core Spillway |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Core Guard Helm (`core_guard_helm`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Reactor Plate (`reactor_plate`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Walkway Boots (`walkway_boots`) | uncommon | 0.4% | 1 | farming ground prize | Core Spillway |
| Rice Box (`rice_box`) | uncommon | 33.2% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Core Guard Helm (`core_guard_helm`) | uncommon | 5.564% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Reactor Plate (`reactor_plate`) | uncommon | 5.564% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.7% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 91.9% | 1-3 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 2.0% | 1 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 2.0% | 1 | field elite | Core Spillway; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 12.6% | 1 | own loot table | Spillway Gatehouse |
| Core Guard Helm (`core_guard_helm`) | uncommon | 1.89% | 1 | own loot table | Spillway Gatehouse |
| Reactor Plate (`reactor_plate`) | uncommon | 1.89% | 1 | own loot table | Spillway Gatehouse |
| Refined Alloy (`refined_alloy`) | rare | 18.9% | 1 | own loot table | Spillway Gatehouse |
| Scrap Metal (`scrap_metal`) | common | 56.7% | 1 | own loot table | Spillway Gatehouse |
| Alloy Knuckles (`alloy_knuckles`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Core Guard Helm (`core_guard_helm`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Reactor Plate (`reactor_plate`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Walkway Boots (`walkway_boots`) | uncommon | 0.4% | 1 | farming ground prize | Spillway Gatehouse |
| Rice Box (`rice_box`) | uncommon | 33.2% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Core Guard Helm (`core_guard_helm`) | uncommon | 5.564% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Reactor Plate (`reactor_plate`) | uncommon | 5.564% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.7% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 91.9% | 1-3 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 2.0% | 1 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 2.0% | 1 | field elite | Spillway Gatehouse; when it comes as a field elite (5% of spawns) |

### Hybrid Brute (`hybrid_brute`, Monster)

- Found: Cooling Tunnels (Lv 44, street), Reactor Walkway (Lv 46, street)
- Coins: 22 to 36 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Rice Box (`rice_box`) | uncommon | 20.0% | 1 | own loot table | anywhere it fights |
| Insulated Gauntlets (`insulated_gauntlets`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Walkway Boots (`walkway_boots`) | uncommon | 3.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | 20.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |

### Vault Trooper (`vault_trooper`, Monster)

- Found: Coolant Vaults (Lv 53, farm), Coolant Control Room (Lv 55, farm)
- Coins: 24 to 32 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.92% | 1 | own loot table | Coolant Vaults |
| Herbal Tonic (`herbal_tonic`) | rare | 3.3% | 1 | own loot table | Coolant Vaults |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 1.32% | 1 | own loot table | Coolant Vaults |
| Vault Guard Plate (`coolant_rare_body`) | rare | 1.32% | 1 | own loot table | Coolant Vaults |
| Refined Alloy (`refined_alloy`) | rare | 14.5% | 1 | own loot table | Coolant Vaults |
| Scrap Metal (`scrap_metal`) | common | 52.8% | 1 | own loot table | Coolant Vaults |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Rice Box (`rice_box`) | uncommon | 21.9% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 9.577% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 3.908% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Plate (`coolant_rare_body`) | rare | 3.908% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.5% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 89.5% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.92% | 1 | own loot table | Coolant Control Room |
| Herbal Tonic (`herbal_tonic`) | rare | 3.3% | 1 | own loot table | Coolant Control Room |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 1.32% | 1 | own loot table | Coolant Control Room |
| Vault Guard Plate (`coolant_rare_body`) | rare | 1.32% | 1 | own loot table | Coolant Control Room |
| Refined Alloy (`refined_alloy`) | rare | 14.5% | 1 | own loot table | Coolant Control Room |
| Scrap Metal (`scrap_metal`) | common | 52.8% | 1 | own loot table | Coolant Control Room |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Rice Box (`rice_box`) | uncommon | 21.9% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 9.577% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 3.908% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Plate (`coolant_rare_body`) | rare | 3.908% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.5% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 89.5% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |

### Coolant Drone (`coolant_drone`, Monster)

- Found: Coolant Vaults (Lv 53, farm), Coolant Control Room (Lv 55, farm)
- Coins: 24 to 32 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.92% | 1 | own loot table | Coolant Vaults |
| Herbal Tonic (`herbal_tonic`) | rare | 3.3% | 1 | own loot table | Coolant Vaults |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 1.32% | 1 | own loot table | Coolant Vaults |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 1.32% | 1 | own loot table | Coolant Vaults |
| Refined Alloy (`refined_alloy`) | rare | 14.5% | 1 | own loot table | Coolant Vaults |
| Scrap Metal (`scrap_metal`) | common | 52.8% | 1 | own loot table | Coolant Vaults |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Rice Box (`rice_box`) | uncommon | 21.9% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 9.577% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 3.908% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 3.908% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.5% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 89.5% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.92% | 1 | own loot table | Coolant Control Room |
| Herbal Tonic (`herbal_tonic`) | rare | 3.3% | 1 | own loot table | Coolant Control Room |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 1.32% | 1 | own loot table | Coolant Control Room |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 1.32% | 1 | own loot table | Coolant Control Room |
| Refined Alloy (`refined_alloy`) | rare | 14.5% | 1 | own loot table | Coolant Control Room |
| Scrap Metal (`scrap_metal`) | common | 52.8% | 1 | own loot table | Coolant Control Room |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Rice Box (`rice_box`) | uncommon | 21.9% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 9.577% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 3.908% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 3.908% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.5% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 89.5% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |

### Vault Warden (`vault_warden`, Elite)

- Found: Coolant Vaults (Lv 53, farm), Coolant Control Room (Lv 55, farm)
- Coins: 57 to 74 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 16.5% | 1 | own loot table | Coolant Vaults |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 2.64% | 1 | own loot table | Coolant Vaults |
| Vault Guard Plate (`coolant_rare_body`) | rare | 2.64% | 1 | own loot table | Coolant Vaults |
| Vault Guard Helm (`coolant_rare_head`) | rare | 2.64% | 1 | own loot table | Coolant Vaults |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 2.64% | 1 | own loot table | Coolant Vaults |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 2.64% | 1 | own loot table | Coolant Vaults |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 2.64% | 1 | own loot table | Coolant Vaults |
| Reinstated Knuckles (`coolant_epic_weapon`) | epic | 0.66% | 1 | own loot table | Coolant Vaults |
| Reinstated Plate (`coolant_epic_body`) | epic | 0.66% | 1 | own loot table | Coolant Vaults |
| Refined Alloy (`refined_alloy`) | rare | 39.6% | 1 | own loot table | Coolant Vaults |
| Scrap Metal (`scrap_metal`) | common | 66.0% | 1 | own loot table | Coolant Vaults |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Herbal Tonic (`herbal_tonic`) | rare | 41.8% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 7.713% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Plate (`coolant_rare_body`) | rare | 7.713% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Helm (`coolant_rare_head`) | rare | 7.713% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 7.713% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 7.713% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 7.713% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Reinstated Knuckles (`coolant_epic_weapon`) | epic | 1.967% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 1.967% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 78.0% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 96.1% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 16.5% | 1 | own loot table | Coolant Control Room |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 2.64% | 1 | own loot table | Coolant Control Room |
| Vault Guard Plate (`coolant_rare_body`) | rare | 2.64% | 1 | own loot table | Coolant Control Room |
| Vault Guard Helm (`coolant_rare_head`) | rare | 2.64% | 1 | own loot table | Coolant Control Room |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 2.64% | 1 | own loot table | Coolant Control Room |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 2.64% | 1 | own loot table | Coolant Control Room |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 2.64% | 1 | own loot table | Coolant Control Room |
| Reinstated Knuckles (`coolant_epic_weapon`) | epic | 0.66% | 1 | own loot table | Coolant Control Room |
| Reinstated Plate (`coolant_epic_body`) | epic | 0.66% | 1 | own loot table | Coolant Control Room |
| Refined Alloy (`refined_alloy`) | rare | 39.6% | 1 | own loot table | Coolant Control Room |
| Scrap Metal (`scrap_metal`) | common | 66.0% | 1 | own loot table | Coolant Control Room |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Herbal Tonic (`herbal_tonic`) | rare | 41.8% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 7.713% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Plate (`coolant_rare_body`) | rare | 7.713% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Helm (`coolant_rare_head`) | rare | 7.713% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 7.713% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 7.713% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 7.713% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Reinstated Knuckles (`coolant_epic_weapon`) | epic | 1.967% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 1.967% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 78.0% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 96.1% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |

### Underworks Brute (`underworks_brute`, Monster)

- Found: Reactor Underworks (Lv 58, farm), Tank Hall (Lv 60, farm)
- Coins: 16 to 21 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 11.2% | 1 | own loot table | Reactor Underworks |
| Herbal Tonic (`herbal_tonic`) | rare | 4.65% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 1.86% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 1.86% | 1 | own loot table | Reactor Underworks |
| Refined Alloy (`refined_alloy`) | rare | 23.2% | 1 | own loot table | Reactor Underworks |
| Scrap Metal (`scrap_metal`) | common | 74.4% | 1 | own loot table | Reactor Underworks |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Rice Box (`rice_box`) | uncommon | 29.9% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 13.3% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 5.477% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 5.477% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 54.8% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 98.3% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 11.2% | 1 | own loot table | Tank Hall |
| Herbal Tonic (`herbal_tonic`) | rare | 4.65% | 1 | own loot table | Tank Hall |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 1.86% | 1 | own loot table | Tank Hall |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 1.86% | 1 | own loot table | Tank Hall |
| Refined Alloy (`refined_alloy`) | rare | 23.2% | 1 | own loot table | Tank Hall |
| Scrap Metal (`scrap_metal`) | common | 74.4% | 1 | own loot table | Tank Hall |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Rice Box (`rice_box`) | uncommon | 29.9% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 13.3% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 5.477% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 5.477% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 54.8% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 98.3% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |

### Reactor Tech (`reactor_tech`, Monster)

- Found: Reactor Underworks (Lv 58, farm), Tank Hall (Lv 60, farm)
- Coins: 16 to 21 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 11.2% | 1 | own loot table | Reactor Underworks |
| Herbal Tonic (`herbal_tonic`) | rare | 4.65% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 1.86% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 1.86% | 1 | own loot table | Reactor Underworks |
| Refined Alloy (`refined_alloy`) | rare | 23.2% | 1 | own loot table | Reactor Underworks |
| Scrap Metal (`scrap_metal`) | common | 74.4% | 1 | own loot table | Reactor Underworks |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Rice Box (`rice_box`) | uncommon | 29.9% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 13.3% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 5.477% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 5.477% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 54.8% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 98.3% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 11.2% | 1 | own loot table | Tank Hall |
| Herbal Tonic (`herbal_tonic`) | rare | 4.65% | 1 | own loot table | Tank Hall |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 1.86% | 1 | own loot table | Tank Hall |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 1.86% | 1 | own loot table | Tank Hall |
| Refined Alloy (`refined_alloy`) | rare | 23.2% | 1 | own loot table | Tank Hall |
| Scrap Metal (`scrap_metal`) | common | 74.4% | 1 | own loot table | Tank Hall |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Rice Box (`rice_box`) | uncommon | 29.9% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 13.3% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 5.477% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 5.477% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 54.8% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 98.3% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |

### Reactor Overseer (`reactor_overseer`, Elite)

- Found: Reactor Underworks (Lv 58, farm), Tank Hall (Lv 60, farm)
- Coins: 37 to 48 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 23.2% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 3.72% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 3.72% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 3.72% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 3.72% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 3.72% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 3.72% | 1 | own loot table | Reactor Underworks |
| Relapsed Knuckles (`underworks_epic_weapon`) | epic | 0.93% | 1 | own loot table | Reactor Underworks |
| Relapsed Plate (`underworks_epic_body`) | epic | 0.93% | 1 | own loot table | Reactor Underworks |
| Refined Alloy (`refined_alloy`) | rare | 55.8% | 1 | own loot table | Reactor Underworks |
| Scrap Metal (`scrap_metal`) | common | 93.0% | 1 | own loot table | Reactor Underworks |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Herbal Tonic (`herbal_tonic`) | rare | 54.8% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 10.7% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 10.7% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 10.7% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 10.7% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 10.7% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 10.7% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Relapsed Knuckles (`underworks_epic_weapon`) | epic | 2.764% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.764% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 91.4% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 100.0% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 23.2% | 1 | own loot table | Tank Hall |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 3.72% | 1 | own loot table | Tank Hall |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 3.72% | 1 | own loot table | Tank Hall |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 3.72% | 1 | own loot table | Tank Hall |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 3.72% | 1 | own loot table | Tank Hall |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 3.72% | 1 | own loot table | Tank Hall |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 3.72% | 1 | own loot table | Tank Hall |
| Relapsed Knuckles (`underworks_epic_weapon`) | epic | 0.93% | 1 | own loot table | Tank Hall |
| Relapsed Plate (`underworks_epic_body`) | epic | 0.93% | 1 | own loot table | Tank Hall |
| Refined Alloy (`refined_alloy`) | rare | 55.8% | 1 | own loot table | Tank Hall |
| Scrap Metal (`scrap_metal`) | common | 93.0% | 1 | own loot table | Tank Hall |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Herbal Tonic (`herbal_tonic`) | rare | 54.8% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 10.7% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 10.7% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 10.7% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 10.7% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 10.7% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 10.7% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Relapsed Knuckles (`underworks_epic_weapon`) | epic | 2.764% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.764% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 91.4% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 100.0% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |

### Foundry Hand (`foundry_hand`, Monster)

- Found: Foundry Depths (Lv 63, farm), The Crucible (Lv 65, farm)
- Coins: 28 to 36 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | Foundry Depths |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | Foundry Depths |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 1.2% | 1 | own loot table | Foundry Depths |
| Slagworker Plate (`foundry_rare_body`) | rare | 1.2% | 1 | own loot table | Foundry Depths |
| Refined Alloy (`refined_alloy`) | rare | 16.8% | 1 | own loot table | Foundry Depths |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | Foundry Depths |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 3.557% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Plate (`foundry_rare_body`) | rare | 3.557% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 42.4% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | The Crucible |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | The Crucible |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 1.2% | 1 | own loot table | The Crucible |
| Slagworker Plate (`foundry_rare_body`) | rare | 1.2% | 1 | own loot table | The Crucible |
| Refined Alloy (`refined_alloy`) | rare | 16.8% | 1 | own loot table | The Crucible |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | The Crucible |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 3.557% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Plate (`foundry_rare_body`) | rare | 3.557% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 42.4% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |

### Slag Slinger (`slag_slinger`, Monster)

- Found: Foundry Depths (Lv 63, farm), The Crucible (Lv 65, farm)
- Coins: 28 to 36 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | Foundry Depths |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | Foundry Depths |
| Slagworker Helm (`foundry_rare_head`) | rare | 1.2% | 1 | own loot table | Foundry Depths |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 1.2% | 1 | own loot table | Foundry Depths |
| Refined Alloy (`refined_alloy`) | rare | 16.8% | 1 | own loot table | Foundry Depths |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | Foundry Depths |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Helm (`foundry_rare_head`) | rare | 3.557% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 3.557% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 42.4% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | The Crucible |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | The Crucible |
| Slagworker Helm (`foundry_rare_head`) | rare | 1.2% | 1 | own loot table | The Crucible |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 1.2% | 1 | own loot table | The Crucible |
| Refined Alloy (`refined_alloy`) | rare | 16.8% | 1 | own loot table | The Crucible |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | The Crucible |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Helm (`foundry_rare_head`) | rare | 3.557% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 3.557% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 42.4% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |

### Foundry Boss (`foundry_boss`, Elite)

- Found: Foundry Depths (Lv 63, farm), The Crucible (Lv 65, farm)
- Coins: 66 to 84 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 15.0% | 1 | own loot table | Foundry Depths |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 2.4% | 1 | own loot table | Foundry Depths |
| Slagworker Plate (`foundry_rare_body`) | rare | 2.4% | 1 | own loot table | Foundry Depths |
| Slagworker Helm (`foundry_rare_head`) | rare | 2.4% | 1 | own loot table | Foundry Depths |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 2.4% | 1 | own loot table | Foundry Depths |
| Slagworker Boots (`foundry_rare_feet`) | rare | 2.4% | 1 | own loot table | Foundry Depths |
| Slagworker Charm (`foundry_rare_charm`) | rare | 2.4% | 1 | own loot table | Foundry Depths |
| Overdriven Knuckles (`foundry_epic_weapon`) | epic | 0.6% | 1 | own loot table | Foundry Depths |
| Overdriven Plate (`foundry_epic_body`) | epic | 0.6% | 1 | own loot table | Foundry Depths |
| Refined Alloy (`refined_alloy`) | rare | 36.0% | 1 | own loot table | Foundry Depths |
| Scrap Metal (`scrap_metal`) | common | 60.0% | 1 | own loot table | Foundry Depths |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Herbal Tonic (`herbal_tonic`) | rare | 38.6% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 7.029% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Plate (`foundry_rare_body`) | rare | 7.029% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Helm (`foundry_rare_head`) | rare | 7.029% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 7.029% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Boots (`foundry_rare_feet`) | rare | 7.029% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Charm (`foundry_rare_charm`) | rare | 7.029% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Overdriven Knuckles (`foundry_epic_weapon`) | epic | 1.789% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 1.789% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 73.8% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 93.6% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 15.0% | 1 | own loot table | The Crucible |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 2.4% | 1 | own loot table | The Crucible |
| Slagworker Plate (`foundry_rare_body`) | rare | 2.4% | 1 | own loot table | The Crucible |
| Slagworker Helm (`foundry_rare_head`) | rare | 2.4% | 1 | own loot table | The Crucible |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 2.4% | 1 | own loot table | The Crucible |
| Slagworker Boots (`foundry_rare_feet`) | rare | 2.4% | 1 | own loot table | The Crucible |
| Slagworker Charm (`foundry_rare_charm`) | rare | 2.4% | 1 | own loot table | The Crucible |
| Overdriven Knuckles (`foundry_epic_weapon`) | epic | 0.6% | 1 | own loot table | The Crucible |
| Overdriven Plate (`foundry_epic_body`) | epic | 0.6% | 1 | own loot table | The Crucible |
| Refined Alloy (`refined_alloy`) | rare | 36.0% | 1 | own loot table | The Crucible |
| Scrap Metal (`scrap_metal`) | common | 60.0% | 1 | own loot table | The Crucible |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Herbal Tonic (`herbal_tonic`) | rare | 38.6% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 7.029% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Plate (`foundry_rare_body`) | rare | 7.029% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Helm (`foundry_rare_head`) | rare | 7.029% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 7.029% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Boots (`foundry_rare_feet`) | rare | 7.029% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Charm (`foundry_rare_charm`) | rare | 7.029% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Overdriven Knuckles (`foundry_epic_weapon`) | epic | 1.789% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 1.789% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 73.8% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 93.6% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |

### Heart Guard (`heart_guard`, Monster)

- Found: The Iron Heart (Lv 68, farm), Heart Core Chamber (Lv 70, farm)
- Coins: 35 to 44 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | The Iron Heart |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | The Iron Heart |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 1.2% | 1 | own loot table | The Iron Heart |
| Heart Sentry Plate (`heart_rare_body`) | rare | 1.2% | 1 | own loot table | The Iron Heart |
| Refined Alloy (`refined_alloy`) | rare | 18.6% | 1 | own loot table | The Iron Heart |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | The Iron Heart |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 3.557% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Plate (`heart_rare_body`) | rare | 3.557% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.1% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | Heart Core Chamber |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 1.2% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Plate (`heart_rare_body`) | rare | 1.2% | 1 | own loot table | Heart Core Chamber |
| Refined Alloy (`refined_alloy`) | rare | 18.6% | 1 | own loot table | Heart Core Chamber |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | Heart Core Chamber |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 3.557% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Plate (`heart_rare_body`) | rare | 3.557% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.1% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |

### Iron Sentry (`iron_sentry`, Monster)

- Found: The Iron Heart (Lv 68, farm), Heart Core Chamber (Lv 70, farm)
- Coins: 35 to 44 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | The Iron Heart |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | The Iron Heart |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 1.2% | 1 | own loot table | The Iron Heart |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 1.2% | 1 | own loot table | The Iron Heart |
| Refined Alloy (`refined_alloy`) | rare | 18.6% | 1 | own loot table | The Iron Heart |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | The Iron Heart |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 3.557% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 3.557% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.1% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | Heart Core Chamber |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 1.2% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 1.2% | 1 | own loot table | Heart Core Chamber |
| Refined Alloy (`refined_alloy`) | rare | 18.6% | 1 | own loot table | Heart Core Chamber |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | Heart Core Chamber |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 3.557% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 3.557% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.1% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |

### Heart Keeper (`heart_keeper`, Elite)

- Found: The Iron Heart (Lv 68, farm), Heart Core Chamber (Lv 70, farm)
- Coins: 80 to 102 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 15.0% | 1 | own loot table | The Iron Heart |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 2.4% | 1 | own loot table | The Iron Heart |
| Heart Sentry Plate (`heart_rare_body`) | rare | 2.4% | 1 | own loot table | The Iron Heart |
| Heart Sentry Helm (`heart_rare_head`) | rare | 2.4% | 1 | own loot table | The Iron Heart |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 2.4% | 1 | own loot table | The Iron Heart |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 2.4% | 1 | own loot table | The Iron Heart |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 2.4% | 1 | own loot table | The Iron Heart |
| Protocol Knuckles (`heart_epic_weapon`) | epic | 0.6% | 1 | own loot table | The Iron Heart |
| Protocol Plate (`heart_epic_body`) | epic | 0.6% | 1 | own loot table | The Iron Heart |
| Refined Alloy (`refined_alloy`) | rare | 36.0% | 1 | own loot table | The Iron Heart |
| Scrap Metal (`scrap_metal`) | common | 60.0% | 1 | own loot table | The Iron Heart |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Herbal Tonic (`herbal_tonic`) | rare | 38.6% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 7.029% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Plate (`heart_rare_body`) | rare | 7.029% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Helm (`heart_rare_head`) | rare | 7.029% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 7.029% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 7.029% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 7.029% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Protocol Knuckles (`heart_epic_weapon`) | epic | 1.789% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 1.789% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 73.8% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 93.6% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 15.0% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 2.4% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Plate (`heart_rare_body`) | rare | 2.4% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Helm (`heart_rare_head`) | rare | 2.4% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 2.4% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 2.4% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 2.4% | 1 | own loot table | Heart Core Chamber |
| Protocol Knuckles (`heart_epic_weapon`) | epic | 0.6% | 1 | own loot table | Heart Core Chamber |
| Protocol Plate (`heart_epic_body`) | epic | 0.6% | 1 | own loot table | Heart Core Chamber |
| Refined Alloy (`refined_alloy`) | rare | 36.0% | 1 | own loot table | Heart Core Chamber |
| Scrap Metal (`scrap_metal`) | common | 60.0% | 1 | own loot table | Heart Core Chamber |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Herbal Tonic (`herbal_tonic`) | rare | 38.6% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 7.029% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Plate (`heart_rare_body`) | rare | 7.029% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Helm (`heart_rare_head`) | rare | 7.029% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 7.029% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 7.029% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 7.029% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Protocol Knuckles (`heart_epic_weapon`) | epic | 1.789% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 1.789% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 73.8% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 93.6% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |

### Vault Runner (`vault_runner`, Monster)

- Found: Coolant Vaults (Lv 53, farm), Coolant Control Room (Lv 55, farm)
- Coins: 24 to 32 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.92% | 1 | own loot table | Coolant Vaults |
| Herbal Tonic (`herbal_tonic`) | rare | 3.3% | 1 | own loot table | Coolant Vaults |
| Vault Guard Helm (`coolant_rare_head`) | rare | 1.32% | 1 | own loot table | Coolant Vaults |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 1.32% | 1 | own loot table | Coolant Vaults |
| Refined Alloy (`refined_alloy`) | rare | 14.5% | 1 | own loot table | Coolant Vaults |
| Scrap Metal (`scrap_metal`) | common | 52.8% | 1 | own loot table | Coolant Vaults |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Vaults |
| Rice Box (`rice_box`) | uncommon | 21.9% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 9.577% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Helm (`coolant_rare_head`) | rare | 3.908% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 3.908% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.5% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 89.5% | 1-3 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Vaults; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.92% | 1 | own loot table | Coolant Control Room |
| Herbal Tonic (`herbal_tonic`) | rare | 3.3% | 1 | own loot table | Coolant Control Room |
| Vault Guard Helm (`coolant_rare_head`) | rare | 1.32% | 1 | own loot table | Coolant Control Room |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 1.32% | 1 | own loot table | Coolant Control Room |
| Refined Alloy (`refined_alloy`) | rare | 14.5% | 1 | own loot table | Coolant Control Room |
| Scrap Metal (`scrap_metal`) | common | 52.8% | 1 | own loot table | Coolant Control Room |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.33% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.1% | 1 | farming ground prize | Coolant Control Room |
| Rice Box (`rice_box`) | uncommon | 21.9% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 9.577% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Helm (`coolant_rare_head`) | rare | 3.908% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 3.908% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 37.5% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 89.5% | 1-3 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |
| Reinstated Plate (`coolant_epic_body`) | epic | 2.0% | 1 | field elite | Coolant Control Room; when it comes as a field elite (5% of spawns) |

### Tank Crawler (`tank_crawler`, Monster)

- Found: Reactor Underworks (Lv 58, farm), Tank Hall (Lv 60, farm)
- Coins: 16 to 21 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 11.2% | 1 | own loot table | Reactor Underworks |
| Herbal Tonic (`herbal_tonic`) | rare | 4.65% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 1.86% | 1 | own loot table | Reactor Underworks |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 1.86% | 1 | own loot table | Reactor Underworks |
| Refined Alloy (`refined_alloy`) | rare | 23.2% | 1 | own loot table | Reactor Underworks |
| Scrap Metal (`scrap_metal`) | common | 74.4% | 1 | own loot table | Reactor Underworks |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Reactor Underworks |
| Rice Box (`rice_box`) | uncommon | 29.9% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 13.3% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 5.477% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 5.477% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 54.8% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 98.3% | 1-3 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Reactor Underworks; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 11.2% | 1 | own loot table | Tank Hall |
| Herbal Tonic (`herbal_tonic`) | rare | 4.65% | 1 | own loot table | Tank Hall |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 1.86% | 1 | own loot table | Tank Hall |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 1.86% | 1 | own loot table | Tank Hall |
| Refined Alloy (`refined_alloy`) | rare | 23.2% | 1 | own loot table | Tank Hall |
| Scrap Metal (`scrap_metal`) | common | 74.4% | 1 | own loot table | Tank Hall |
| Coolant Plate (`coolant_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Charm (`coolant_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Boots (`coolant_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Gloves (`coolant_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Helm (`coolant_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Coolant Knuckles (`coolant_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Tank Hall |
| Vault Guard Plate (`coolant_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Charm (`coolant_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Boots (`coolant_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Gloves (`coolant_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Helm (`coolant_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Vault Guard Knuckles (`coolant_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Tank Hall |
| Rice Box (`rice_box`) | uncommon | 29.9% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 13.3% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 5.477% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 5.477% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 54.8% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 98.3% | 1-3 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |
| Relapsed Plate (`underworks_epic_body`) | epic | 2.0% | 1 | field elite | Tank Hall; when it comes as a field elite (5% of spawns) |

### Furnace Hauler (`furnace_hauler`, Monster)

- Found: Foundry Depths (Lv 63, farm), The Crucible (Lv 65, farm)
- Coins: 28 to 36 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | Foundry Depths |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | Foundry Depths |
| Slagworker Boots (`foundry_rare_feet`) | rare | 1.2% | 1 | own loot table | Foundry Depths |
| Slagworker Charm (`foundry_rare_charm`) | rare | 1.2% | 1 | own loot table | Foundry Depths |
| Refined Alloy (`refined_alloy`) | rare | 16.8% | 1 | own loot table | Foundry Depths |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | Foundry Depths |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Foundry Depths |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Foundry Depths |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Boots (`foundry_rare_feet`) | rare | 3.557% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Slagworker Charm (`foundry_rare_charm`) | rare | 3.557% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 42.4% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | Foundry Depths; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | The Crucible |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | The Crucible |
| Slagworker Boots (`foundry_rare_feet`) | rare | 1.2% | 1 | own loot table | The Crucible |
| Slagworker Charm (`foundry_rare_charm`) | rare | 1.2% | 1 | own loot table | The Crucible |
| Refined Alloy (`refined_alloy`) | rare | 16.8% | 1 | own loot table | The Crucible |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | The Crucible |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Plate (`underworks_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Charm (`underworks_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Boots (`underworks_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Gloves (`underworks_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Helm (`underworks_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Underworks Knuckles (`underworks_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Crucible |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Plate (`underworks_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Charm (`underworks_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Boots (`underworks_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Gloves (`underworks_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Helm (`underworks_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Reactor Crew Knuckles (`underworks_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Crucible |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Boots (`foundry_rare_feet`) | rare | 3.557% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Slagworker Charm (`foundry_rare_charm`) | rare | 3.557% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 42.4% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |
| Overdriven Plate (`foundry_epic_body`) | epic | 2.0% | 1 | field elite | The Crucible; when it comes as a field elite (5% of spawns) |

### Rivet Thrower (`rivet_thrower`, Monster)

- Found: The Iron Heart (Lv 68, farm), Heart Core Chamber (Lv 70, farm)
- Coins: 35 to 44 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 2.1% | 1 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 0.56% | 1 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 0.126% | 1 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 0.014% | 1 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 1.2% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 0.32% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 0.144% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 0.016% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 0.9% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 0.24% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 0.054% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.006% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 0.068% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 0.011% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.00175% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.00019% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 0.198% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 0.053% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 0.012% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.00132% | 1 | catalog drop table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | The Iron Heart |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | The Iron Heart |
| Heart Sentry Helm (`heart_rare_head`) | rare | 1.2% | 1 | own loot table | The Iron Heart |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 1.2% | 1 | own loot table | The Iron Heart |
| Refined Alloy (`refined_alloy`) | rare | 18.6% | 1 | own loot table | The Iron Heart |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | The Iron Heart |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | The Iron Heart |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | The Iron Heart |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Helm (`heart_rare_head`) | rare | 3.557% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 3.557% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.1% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | The Iron Heart; when it comes as a field elite (5% of spawns) |
| Rice Box (`rice_box`) | uncommon | 7.2% | 1 | own loot table | Heart Core Chamber |
| Herbal Tonic (`herbal_tonic`) | rare | 3.0% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Helm (`heart_rare_head`) | rare | 1.2% | 1 | own loot table | Heart Core Chamber |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 1.2% | 1 | own loot table | Heart Core Chamber |
| Refined Alloy (`refined_alloy`) | rare | 18.6% | 1 | own loot table | Heart Core Chamber |
| Scrap Metal (`scrap_metal`) | common | 48.0% | 1 | own loot table | Heart Core Chamber |
| Foundry Plate (`foundry_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Charm (`foundry_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Boots (`foundry_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Gloves (`foundry_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Helm (`foundry_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Foundry Knuckles (`foundry_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Plate (`heart_uncommon_body`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Charm (`heart_uncommon_charm`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Boots (`heart_uncommon_feet`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Gloves (`heart_uncommon_hands`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Helm (`heart_uncommon_head`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Heartforged Knuckles (`heart_uncommon_weapon`) | uncommon | 0.17% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Plate (`foundry_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Charm (`foundry_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Boots (`foundry_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Gloves (`foundry_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Helm (`foundry_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Slagworker Knuckles (`foundry_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Plate (`heart_rare_body`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Charm (`heart_rare_charm`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Boots (`heart_rare_feet`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Helm (`heart_rare_head`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Heart Sentry Knuckles (`heart_rare_weapon`) | rare | 0.05% | 1 | farming ground prize | Heart Core Chamber |
| Rice Box (`rice_box`) | uncommon | 20.1% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Herbal Tonic (`herbal_tonic`) | rare | 8.733% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Helm (`heart_rare_head`) | rare | 3.557% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Heart Sentry Gloves (`heart_rare_hands`) | rare | 3.557% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Refined Alloy (`refined_alloy`) | rare | 46.1% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Scrap Metal (`scrap_metal`) | common | 85.9% | 1-3 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |
| Protocol Plate (`heart_epic_body`) | epic | 2.0% | 1 | field elite | Heart Core Chamber; when it comes as a field elite (5% of spawns) |

## C. Mini-boss drop matrix

### Commander Arthit, Reinstated (`arthit_reinstated`, Mini-boss)

- Found: Coolant Control Room (Lv 55, lair)
- Coins: 1960 to 2260 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Reinstated Knuckles (`coolant_epic_weapon`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Reinstated Plate (`coolant_epic_body`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Reinstated Helm (`coolant_epic_head`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Reinstated Gloves (`coolant_epic_hands`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Reinstated Boots (`coolant_epic_feet`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Reinstated Charm (`coolant_epic_charm`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### Subject Twelve, Relapsed (`twelve_relapsed`, Mini-boss)

- Found: Tank Hall (Lv 60, lair)
- Coins: 2060 to 2360 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Relapsed Knuckles (`underworks_epic_weapon`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Relapsed Plate (`underworks_epic_body`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Relapsed Helm (`underworks_epic_head`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Relapsed Gloves (`underworks_epic_hands`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Relapsed Boots (`underworks_epic_feet`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Relapsed Charm (`underworks_epic_charm`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### Unit K-7, Overdriven (`k7_overdriven`, Mini-boss)

- Found: The Crucible (Lv 65, lair)
- Coins: 2160 to 2460 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Overdriven Knuckles (`foundry_epic_weapon`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Overdriven Plate (`foundry_epic_body`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Overdriven Helm (`foundry_epic_head`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Overdriven Gloves (`foundry_epic_hands`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Overdriven Boots (`foundry_epic_feet`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Overdriven Charm (`foundry_epic_charm`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### Spillway Chief (`spillway_chief`, Mini-boss)

- Found: Spillway Gatehouse (Lv 45, lair)
- Coins: 500 to 700 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Spillway Chief's Coat (`spillway_epic_body`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Spillway Chief's Visor (`spillway_epic_head`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### The Wiroj Protocol (`wiroj_protocol`, Mini-boss)

- Found: Heart Core Chamber (Lv 70, lair)
- Coins: 2260 to 2560 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Protocol Knuckles (`heart_epic_weapon`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Protocol Plate (`heart_epic_body`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Protocol Helm (`heart_epic_head`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Protocol Gloves (`heart_epic_hands`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Protocol Boots (`heart_epic_feet`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Protocol Charm (`heart_epic_charm`) | epic | 15.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 50.0% | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

## D. Stage boss drop matrix

### The Sludge Foreman (`sludge_foreman`, Stage boss)

- Found: Canal Works (Lv 3, street)
- Coins: 90 to 130 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Foreman's Wrench (`foreman_wrench`) | epic | 30.0% | 1 | own loot table | anywhere it fights |
| Foreman's Boots (`foreman_boots`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### The Furnace Baron (`furnace_baron`, Stage boss)

- Found: Gang Headquarters (Lv 10, street)
- Coins: 160 to 220 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Baron's Knuckledusters (`baron_knuckledusters`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Jade Charm (`jade_charm`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Smelter's Apron (`smelter_apron`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Furnace Baron's Core (`baron_furnace_core`) | epic | 25.0% | 1 | boss's own list | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.5% | 1 | boss's own list | anywhere it fights |
| Iron Legacy Relic (`iron_legacy_relic`) | epic | 3.0% | 1 | boss's own list | anywhere it fights |

### The Pit Champion (`pit_champion`, Stage boss)

- Found: Fight Club (Lv 8, street)
- Coins: 120 to 180 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Champion's Wraps (`champion_wraps`) | epic | 25.0% | 1 | own loot table | anywhere it fights |
| Champion's Headband (`champion_headband`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### Harbourmaster Chen (`harbourmaster_chen`, Stage boss)

- Found: Crane Yard (Lv 16, street)
- Coins: 220 to 300 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Harbourmaster's Hook (`harbour_hook`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Harbourmaster's Cap (`harbourmaster_cap`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Dockmaster's Boots (`dockmaster_boots`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Harbourmaster's Anchor Link (`chen_anchor_link`) | rare | 30.0% | 1 | boss's own list | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 15.0% | 1-2 | boss's own list | anywhere it fights |

### Security Chief Nattapong (`security_chief`, Stage boss)

- Found: Production Line (Lv 21, street)
- Coins: 120 to 180 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Chief's Baton (`chiefs_baton`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Chief's Gloves (`chiefs_gloves`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |

### Unit K-7 (`unit_k7`, Stage boss)

- Found: Factory Drains (Lv 24, street)
- Coins: 260 to 340 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| K-7 Core Plate (`k7_core_plate`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| K7 Plating (`k7_plating`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| K-7 Reactor Cell (`k7_reactor_cell`) | epic | 25.0% | 1 | boss's own list | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 10.0% | 1 | boss's own list | anywhere it fights |

### The Ringmaster (`ringmaster`, Stage boss)

- Found: The Underground Ring (Lv 27, street)
- Coins: 240 to 320 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Ringmaster's Wraps (`ringmaster_wraps`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Ringmaster's Topper (`ringmaster_topper`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 15.0% | 1 | boss's own list | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 20.0% | 1 | boss's own list | anywhere it fights |

### Big Sak (`big_sak`, Stage boss)

- Found: Rattanachai Tower (Lv 31, street)
- Coins: 320 to 420 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Sak's Signet (`sak_signet`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Sak's Loafers (`sak_loafers`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 15.0% | 1 | boss's own list | anywhere it fights |

### Subject 12 (`subject_twelve`, Stage boss)

- Found: Test Labs (Lv 35, street)
- Coins: 300 to 400 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Subject 12's Band (`subject_band`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Subject Grips (`subject_grips`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 1.0% | 1 | boss's own list | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 1.0% | 1 | boss's own list | anywhere it fights |
| Founder's Crimson Sigil (`founders_crimson_sigil`) | legendary | 0.2% | 1 | boss's own list | anywhere it fights |

### Commander Arthit (`commander_arthit`, Stage boss)

- Found: Control Room (Lv 39, street)
- Coins: 420 to 540 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Commander's Baton (`arthit_baton`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Commander's Greaves (`commander_greaves`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.5% | 1 | boss's own list | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 10.0% | 1 | boss's own list | anywhere it fights |
| Iron Legacy Relic (`iron_legacy_relic`) | epic | 3.0% | 1 | boss's own list | anywhere it fights |

### Director Wiroj (`director_wiroj`, Stage boss)

- Found: The Core Chamber (Lv 48, street)
- Coins: 600 to 800 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Director's Signet (`director_signet`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Director's Coat (`director_coat`) | epic | 20.0% | 1 | own loot table | anywhere it fights |
| Director's Crown (`director_crown`) | legendary | 6.0% | 1 | own loot table | anywhere it fights; rises after each kill without one (up to 50%) |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Scrap Metal (`scrap_metal`) | common | guaranteed | 1 | own loot table | anywhere it fights |
| Basic Enhancement Stone (`enhance_stone_basic`) | common | 22.6% | 1-2 | catalog drop table | anywhere it fights |
| Refined Enhancement Stone (`enhance_stone_refined`) | uncommon | 19.9% | 1-2 | catalog drop table | anywhere it fights |
| Advanced Enhancement Stone (`enhance_stone_advanced`) | rare | 11.6% | 1-2 | catalog drop table | anywhere it fights |
| Rare Enhancement Catalyst (`enhance_catalyst_rare`) | epic | 2.859% | 1-2 | catalog drop table | anywhere it fights |
| Special Enhancement Catalyst (`enhance_catalyst_special`) | legendary | 0.12% | 1-2 | catalog drop table | anywhere it fights |
| Iron Ore (`ore_iron`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Copper Ore (`ore_copper`) | common | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Refined Ore (`ore_refined`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Rare Mineral (`mineral_rare`) | uncommon | 10.2% | 1-3 | catalog drop table | anywhere it fights |
| Azure Mineral (`mineral_azure`) | rare | 11.6% | 1-3 | catalog drop table | anywhere it fights |
| Gilded Mineral (`mineral_gilded`) | epic | 2.859% | 1-3 | catalog drop table | anywhere it fights |
| Crimson Special Mineral (`mineral_crimson`) | legendary | 0.12% | 1-3 | catalog drop table | anywhere it fights |
| Focus Gum (`focus_gum`) | common | 7.855% | 1 | catalog drop table | anywhere it fights |
| Ironworks Energy Drink (`energy_drink_ironworks`) | uncommon | 6.891% | 1 | catalog drop table | anywhere it fights |
| Adrenal Shot (`adrenal_shot`) | rare | 3.968% | 1 | catalog drop table | anywhere it fights |
| Second Wind Tonic (`second_wind_tonic`) | epic | 0.96% | 1 | catalog drop table | anywhere it fights |
| Patched Street Cap (`patched_street_cap`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Sakura Straw Hat (`sakura_straw_hat`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Rising Sun Headband (`rising_sun_headband`) | common | 2.649% | 1 | catalog drop table | anywhere it fights |
| Reinforced Bandana (`reinforced_bandana`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Emerald Feather Hat (`emerald_feather_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Midnight Wizard Hat (`midnight_wizard_hat`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Tiger Hood (`tiger_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Frost Fur Hood (`frost_fur_hood`) | uncommon | 1.395% | 1 | catalog drop table | anywhere it fights |
| Riveted Work Helmet (`riveted_work_helmet`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Arcane Wizard Hat (`arcane_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Sakura Wizard Hat (`sakura_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Starlight Wizard Hat (`starlight_wizard_hat`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Crystal Tiara (`crystal_tiara`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Cyber Visor (`cyber_visor`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Ice Crown (`ice_crown`) | rare | 0.571% | 1 | catalog drop table | anywhere it fights |
| Gilded Brawler Helm (`gilded_brawler_helm`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Dragonscale Hood (`dragonscale_hood`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Feather Hat (`phoenix_feather_hat`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Phoenix Tiara (`phoenix_tiara`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Glacier Crown (`glacier_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Jewelled Crown (`jewelled_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Obsidian Crown (`obsidian_crown`) | epic | 0.137% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Lion King's Crown (`lion_king_crown`) | legendary | 0.02% | 1 | catalog drop table | anywhere it fights |
| Canvas Work Shirt (`canvas_work_shirt`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Padded Street Jacket (`padded_street_jacket`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Riveted Dock Coat (`riveted_dock_coat`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Fight Robe (`gilded_fight_robe`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Mantle (`crimson_warlord_mantle`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wrapped Iron Knuckles (`wrapped_iron_knuckles`) | common | 7.84% | 1 | catalog drop table | anywhere it fights |
| Copper-Plated Knuckles (`copper_plated_knuckles`) | uncommon | 6.878% | 1 | catalog drop table | anywhere it fights |
| Azure Steel Knuckles (`azure_steel_knuckles`) | rare | 3.96% | 1 | catalog drop table | anywhere it fights |
| Gilded Crusher Gauntlets (`gilded_crusher_gauntlets`) | epic | 0.958% | 1 | catalog drop table | anywhere it fights |
| Crimson Warlord Fists (`crimson_warlord_fists`) | legendary | 0.04% | 1 | catalog drop table | anywhere it fights |
| Wiroj Protocol Chip (`wiroj_protocol_chip`) | epic | 25.0% | 1 | boss's own list | anywhere it fights |
| Crimson Warlord Helm (`crimson_warlord_helm`) | legendary | 0.5% | 1 | boss's own list | anywhere it fights |
| Iron Legacy Relic (`iron_legacy_relic`) | epic | 3.0% | 1 | boss's own list | anywhere it fights |

## E. World boss drop matrix

Tiers and the kill are paid only when the boss falls within its round,
to everyone who fought it (WorldBossRules); a hero who fell or left still
counts what they dealt. No entry limits or waiting times.

### The Tunnel Mother (`tunnel_mother`, World boss)

- Found: The Great Drain (Lv 26, world_boss)
- Coins: 400 to 600 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 50.0% | 1 | own loot table | anywhere it fights |
| Rice Box (`rice_box`) | uncommon | guaranteed | 3 | personal tier | The Great Drain; dealing 5% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 2 | personal tier | The Great Drain; dealing 15% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 2 | personal tier | The Great Drain; dealing 15% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 4 | personal tier | The Great Drain; dealing 35% of one player's share of its health, paid only if the boss falls within its round |
| Mother's Fang (`mothers_fang`) | godforged | 8.0% | 1 | personal tier | The Great Drain; dealing 35% of one player's share of its health, paid only if the boss falls within its round |
| Mother's Heart (`mothers_heart`) | godforged | 8.0% | 1 | personal tier | The Great Drain; dealing 35% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 6 | personal tier | The Great Drain; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | The Great Drain; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Mother's Fang (`mothers_fang`) | godforged | 12.0% | 1 | personal tier | The Great Drain; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Mother's Heart (`mothers_heart`) | godforged | 12.0% | 1 | personal tier | The Great Drain; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | The Great Drain; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Mother's Fang (`mothers_fang`) | godforged | 30.0% | 1 | personal tier | The Great Drain; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Mother's Heart (`mothers_heart`) | godforged | 30.0% | 1 | personal tier | The Great Drain; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | kill reward | The Great Drain; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Mother's Fang (`mothers_fang`) | godforged | 15.0% | 1 | kill reward | The Great Drain; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Mother's Heart (`mothers_heart`) | godforged | 15.0% | 1 | kill reward | The Great Drain; to everyone who fought it when it falls, paid only if the boss falls within its round |

### The Iron Colossus (`iron_colossus`, World boss)

- Found: The Old Scrapyard (Lv 50, world_boss)
- Coins: 800 to 1100 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 60.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 4 | personal tier | The Old Scrapyard; dealing 10% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 6 | personal tier | The Old Scrapyard; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | The Old Scrapyard; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | personal tier | The Old Scrapyard; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 12 | personal tier | The Old Scrapyard; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Colossus Core (`colossus_core`) | godforged | 2.0% | 1 | personal tier | The Old Scrapyard; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Piston Gauntlets (`piston_gauntlets`) | godforged | 2.0% | 1 | personal tier | The Old Scrapyard; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 15 | kill reward | The Old Scrapyard; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Colossus Core (`colossus_core`) | godforged | 8.0% | 1 | kill reward | The Old Scrapyard; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Piston Gauntlets (`piston_gauntlets`) | godforged | 8.0% | 1 | kill reward | The Old Scrapyard; to everyone who fought it when it falls, paid only if the boss falls within its round |

### Subject Zero (`subject_zero`, World boss)

- Found: The Sunken Reservoir (Lv 53, world_boss)
- Coins: 1000 to 1400 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Herbal Tonic (`herbal_tonic`) | rare | 80.0% | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 6 | personal tier | The Sunken Reservoir; dealing 5% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | The Sunken Reservoir; dealing 20% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 5 | personal tier | The Sunken Reservoir; dealing 20% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 14 | personal tier | The Sunken Reservoir; dealing 50% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 20 | personal tier | The Sunken Reservoir; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Zero's Mantle (`zeros_mantle`) | godforged | 2.0% | 1 | personal tier | The Sunken Reservoir; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| The Iron Legacy (`iron_legacy`) | godforged | 1.0% | 1 | personal tier | The Sunken Reservoir; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 30 | kill reward | The Sunken Reservoir; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Zero's Mantle (`zeros_mantle`) | godforged | 5.0% | 1 | kill reward | The Sunken Reservoir; to everyone who fought it when it falls, paid only if the boss falls within its round |
| The Iron Legacy (`iron_legacy`) | godforged | 3.0% | 1 | kill reward | The Sunken Reservoir; to everyone who fought it when it falls, paid only if the boss falls within its round |

### The Slag Titan (`slag_titan`, World boss)

- Found: Slag Furnace (Lv 58, world_boss)
- Coins: 0 to 0 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 5 | personal tier | Slag Furnace; dealing 10% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | personal tier | Slag Furnace; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | Slag Furnace; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | Slag Furnace; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 14 | personal tier | Slag Furnace; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Titan's Slagfist (`titan_slagfist`) | godforged | 5.0% | 1 | personal tier | Slag Furnace; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Titan's Grip (`titan_grip`) | godforged | 5.0% | 1 | personal tier | Slag Furnace; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Titan's Ember Core (`titan_core`) | godforged | 5.0% | 1 | personal tier | Slag Furnace; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 18 | kill reward | Slag Furnace; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Titan's Slagfist (`titan_slagfist`) | godforged | 15.0% | 1 | kill reward | Slag Furnace; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Titan's Grip (`titan_grip`) | godforged | 15.0% | 1 | kill reward | Slag Furnace; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Titan's Ember Core (`titan_core`) | godforged | 15.0% | 1 | kill reward | Slag Furnace; to everyone who fought it when it falls, paid only if the boss falls within its round |

### The Iron Sovereign (`iron_sovereign`, World boss)

- Found: Sovereign Vault (Lv 68, world_boss)
- Coins: 0 to 0 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 5 | personal tier | Sovereign Vault; dealing 10% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | personal tier | Sovereign Vault; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | Sovereign Vault; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | Sovereign Vault; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 14 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Sovereign Fists (`sovereign_fists`) | godforged | 3.0% | 1 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Sovereign Mantle (`sovereign_mantle`) | godforged | 3.0% | 1 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Sovereign Crown (`sovereign_crown`) | godforged | 3.0% | 1 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Sovereign Grips (`sovereign_grips`) | godforged | 3.0% | 1 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Sovereign Treads (`sovereign_treads`) | godforged | 3.0% | 1 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Sovereign Seal (`sovereign_seal`) | godforged | 3.0% | 1 | personal tier | Sovereign Vault; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 18 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Sovereign Fists (`sovereign_fists`) | godforged | 9.0% | 1 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Sovereign Mantle (`sovereign_mantle`) | godforged | 9.0% | 1 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Sovereign Crown (`sovereign_crown`) | godforged | 9.0% | 1 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Sovereign Grips (`sovereign_grips`) | godforged | 9.0% | 1 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Sovereign Treads (`sovereign_treads`) | godforged | 9.0% | 1 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Sovereign Seal (`sovereign_seal`) | godforged | 9.0% | 1 | kill reward | Sovereign Vault; to everyone who fought it when it falls, paid only if the boss falls within its round |

## F. Raid world boss drop matrix

Tiers and the kill are paid only when the boss falls within its round,
to everyone who fought it (WorldBossRules); a hero who fell or left still
counts what they dealt. No entry limits or waiting times.

### The Floodgate Marshal (`floodgate_marshal`, Raid world boss)

- Found: Floodgate Barracks (Lv 54, world_boss)
- Coins: 0 to 0 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 5 | personal tier | Floodgate Barracks; dealing 10% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | personal tier | Floodgate Barracks; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | Floodgate Barracks; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | Floodgate Barracks; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 14 | personal tier | Floodgate Barracks; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Marshal's Greatcoat (`marshal_greatcoat`) | godforged | 3.0% | 1 | personal tier | Floodgate Barracks; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Marshal's Floodlight Visor (`marshal_visor`) | godforged | 3.0% | 1 | personal tier | Floodgate Barracks; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Marshal's Sabatons (`marshal_sabatons`) | godforged | 3.0% | 1 | personal tier | Floodgate Barracks; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 18 | kill reward | Floodgate Barracks; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Marshal's Greatcoat (`marshal_greatcoat`) | godforged | 9.0% | 1 | kill reward | Floodgate Barracks; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Marshal's Floodlight Visor (`marshal_visor`) | godforged | 9.0% | 1 | kill reward | Floodgate Barracks; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Marshal's Sabatons (`marshal_sabatons`) | godforged | 9.0% | 1 | kill reward | Floodgate Barracks; to everyone who fought it when it falls, paid only if the boss falls within its round |

### The Crucible King (`crucible_king`, Raid world boss)

- Found: The Crucible Pit (Lv 62, world_boss)
- Coins: 0 to 0 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 5 | personal tier | The Crucible Pit; dealing 10% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | personal tier | The Crucible Pit; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | The Crucible Pit; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | The Crucible Pit; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 14 | personal tier | The Crucible Pit; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Crucible King's Maul (`crucible_maul`) | godforged | 3.0% | 1 | personal tier | The Crucible Pit; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Crucible Gauntlets (`crucible_gauntlets`) | godforged | 3.0% | 1 | personal tier | The Crucible Pit; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Heart of the Crucible (`crucible_heart`) | godforged | 3.0% | 1 | personal tier | The Crucible Pit; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 18 | kill reward | The Crucible Pit; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Crucible King's Maul (`crucible_maul`) | godforged | 9.0% | 1 | kill reward | The Crucible Pit; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Crucible Gauntlets (`crucible_gauntlets`) | godforged | 9.0% | 1 | kill reward | The Crucible Pit; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Heart of the Crucible (`crucible_heart`) | godforged | 9.0% | 1 | kill reward | The Crucible Pit; to everyone who fought it when it falls, paid only if the boss falls within its round |

### The Founder's Engine (`founders_engine`, Raid world boss)

- Found: The Founder's Floor (Lv 68, world_boss)
- Coins: 0 to 0 per kill

| Item | Grade | Chance per kill | Quantity | From | Where / condition |
|---|---|---|---|---|---|
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 1 | own loot table | anywhere it fights |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 5 | personal tier | The Founder's Floor; dealing 10% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 8 | personal tier | The Founder's Floor; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Herbal Tonic (`herbal_tonic`) | rare | guaranteed | 3 | personal tier | The Founder's Floor; dealing 30% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 10 | personal tier | The Founder's Floor; dealing 60% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 14 | personal tier | The Founder's Floor; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| The Founder's Edge (`founders_edge`) | godforged | 3.0% | 1 | personal tier | The Founder's Floor; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Founder's Plate (`founders_plate`) | godforged | 3.0% | 1 | personal tier | The Founder's Floor; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Founder's Halo (`founders_halo`) | godforged | 3.0% | 1 | personal tier | The Founder's Floor; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Engine Heart (`founders_engine_core`) | godforged | 3.0% | 1 | personal tier | The Founder's Floor; dealing 100% of one player's share of its health, paid only if the boss falls within its round |
| Refined Alloy (`refined_alloy`) | rare | guaranteed | 18 | kill reward | The Founder's Floor; to everyone who fought it when it falls, paid only if the boss falls within its round |
| The Founder's Edge (`founders_edge`) | godforged | 9.0% | 1 | kill reward | The Founder's Floor; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Founder's Plate (`founders_plate`) | godforged | 9.0% | 1 | kill reward | The Founder's Floor; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Founder's Halo (`founders_halo`) | godforged | 9.0% | 1 | kill reward | The Founder's Floor; to everyone who fought it when it falls, paid only if the boss falls within its round |
| Engine Heart (`founders_engine_core`) | godforged | 9.0% | 1 | kill reward | The Founder's Floor; to everyone who fought it when it falls, paid only if the boss falls within its round |

## G. Drop probability: per-kill chances and conditional shares

An enemy's own loot table and a farming ground's prizes roll each item
independently: the chance listed is the chance per kill. A catalog table
rolls in steps; each share below is **conditional** on the step before.

### Table `street` (monster)

- Rolls per kill: 1; a roll drops something: 8.0%

| Category | Share of a drop | Grade shares within it | Quantity |
|---|---|---|---|
| enhancement_material | 35.0% | common 75.0% (1 items), uncommon 20.0% (1 items), rare 4.5% (1 items), epic 0.5% (1 items) | 1-1 |
| ore | 40.0% | common 75.0% (2 items), uncommon 20.0% (2 items), rare 4.5% (1 items), epic 0.5% (1 items) | 1-3 |
| consumable | 15.0% | common 75.0% (1 items), uncommon 20.0% (1 items), rare 4.5% (1 items), epic 0.5% (1 items) | 1-1 |
| headgear | 3.4% | common 75.0% (3 items), uncommon 20.0% (5 items), rare 4.5% (7 items), epic 0.5% (7 items) | 1-1 |
| outfit | 3.3% | common 75.0% (1 items), uncommon 20.0% (1 items), rare 4.5% (1 items), epic 0.5% (1 items) | 1-1 |
| weapon | 3.3% | common 75.0% (1 items), uncommon 20.0% (1 items), rare 4.5% (1 items), epic 0.5% (1 items) | 1-1 |

### Table `boss` (boss)

- Rolls per kill: 2; a roll drops something: 100.0%

| Category | Share of a drop | Grade shares within it | Quantity |
|---|---|---|---|
| enhancement_material | 30.0% | common 40.0% (1 items), uncommon 35.0% (1 items), rare 20.0% (1 items), epic 4.8% (1 items), legendary 0.2% (1 items) | 1-2 |
| ore | 30.0% | common 40.0% (2 items), uncommon 35.0% (2 items), rare 20.0% (1 items), epic 4.8% (1 items), legendary 0.2% (1 items) | 1-3 |
| consumable | 10.0% | common 40.1% (1 items), uncommon 35.1% (1 items), rare 20.0% (1 items), epic 4.81% (1 items) | 1-1 |
| headgear | 10.0% | common 40.0% (3 items), uncommon 35.0% (5 items), rare 20.0% (7 items), epic 4.8% (7 items), legendary 0.2% (2 items) | 1-1 |
| outfit | 10.0% | common 40.0% (1 items), uncommon 35.0% (1 items), rare 20.0% (1 items), epic 4.8% (1 items), legendary 0.2% (1 items) | 1-1 |
| weapon | 10.0% | common 40.0% (1 items), uncommon 35.0% (1 items), rare 20.0% (1 items), epic 4.8% (1 items), legendary 0.2% (1 items) | 1-1 |

Grade weights by source (shares of a successful drop, before limiting to
the grades a category has): monster { "common": 75.0, "uncommon": 20.0, "rare": 4.5, "epic": 0.5, "legendary": 0.0, "godforged": 0.0 }; boss { "common": 40.0, "uncommon": 35.0, "rare": 20.0, "epic": 4.8, "legendary": 0.2, "godforged": 0.0 }.

## H. Item acquisition index

- `adrenal_shot` Adrenal Shot: Unit K-7 3.968% (catalog drop table); Security Chief Nattapong 3.968% (catalog drop table); Subject Twelve, Relapsed 3.968% (catalog drop table); Harbourmaster Chen 3.968% (catalog drop table); Commander Arthit, Reinstated 3.968% (catalog drop table); The Ringmaster 3.968% (catalog drop table); Unit K-7, Overdriven 3.968% (catalog drop table); The Pit Champion 3.968% (catalog drop table); Big Sak 3.968% (catalog drop table); The Furnace Baron 3.968% (catalog drop table); Spillway Chief 3.968% (catalog drop table); The Wiroj Protocol 3.968% (catalog drop table); The Sludge Foreman 3.968% (catalog drop table); Subject 12 3.968% (catalog drop table); Commander Arthit 3.968% (catalog drop table); Director Wiroj 3.968% (catalog drop table); Vault Warden 0.054% (catalog drop table); Coolant Drone 0.054% (catalog drop table); Vault Trooper 0.054% (catalog drop table); Underworks Brute 0.054% (catalog drop table); Reactor Tech 0.054% (catalog drop table); Reactor Overseer 0.054% (catalog drop table); Foundry Hand 0.054% (catalog drop table); Slag Slinger 0.054% (catalog drop table); Foundry Boss 0.054% (catalog drop table); Heart Guard 0.054% (catalog drop table); Iron Sentry 0.054% (catalog drop table); Heart Keeper 0.054% (catalog drop table); Vault Runner 0.054% (catalog drop table); Tank Crawler 0.054% (catalog drop table); Furnace Hauler 0.054% (catalog drop table); Rivet Thrower 0.054% (catalog drop table); Smogling 0.054% (catalog drop table); Tar Rat 0.054% (catalog drop table); Pipe Brute 0.054% (catalog drop table); Smog Warden 0.054% (catalog drop table); Dock Thug 0.054% (catalog drop table); Rail Bruiser 0.054% (catalog drop table); Night Market Punk 0.054% (catalog drop table); Refinery Enforcer 0.054% (catalog drop table); Bottle Thrower 0.054% (catalog drop table); Stevedore 0.054% (catalog drop table); Port Guard 0.054% (catalog drop table); Dock Slinger 0.054% (catalog drop table); Plant Guard 0.054% (catalog drop table); Hazmat Sprayer 0.054% (catalog drop table); Patrol Unit 0.054% (catalog drop table); Network Runner 0.054% (catalog drop table); Network Enforcer 0.054% (catalog drop table); Ring Fighter 0.054% (catalog drop table); Facility Trooper 0.054% (catalog drop table); Riot Trooper 0.054% (catalog drop table); Hybrid Worker 0.054% (catalog drop table); Core Sentinel 0.054% (catalog drop table); Hybrid Brute 0.054% (catalog drop table)
- `alloy_knuckles` Alloy Knuckles: Patrol Unit 0.67% (farming ground prize, Core Overflow); Facility Trooper 0.67% (farming ground prize, Core Overflow); Core Sentinel 0.67% (farming ground prize, Core Overflow); Hazmat Sprayer 0.4% (farming ground prize, Core Spillway); Hazmat Sprayer 0.4% (farming ground prize, Spillway Gatehouse); Facility Trooper 0.4% (farming ground prize, Core Spillway); Facility Trooper 0.4% (farming ground prize, Spillway Gatehouse); Core Sentinel 0.4% (farming ground prize, Core Spillway); Core Sentinel 0.4% (farming ground prize, Spillway Gatehouse)
- `altered_manifest` The Altered Manifest: quest "The Harbourmaster"
- `arcane_wizard_hat` Arcane Wizard Hat: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `arthit_baton` Commander's Baton: Commander Arthit 6.0% (own loot table)
- `azure_steel_knuckles` Azure Steel Knuckles: Unit K-7 3.96% (catalog drop table); Security Chief Nattapong 3.96% (catalog drop table); Subject Twelve, Relapsed 3.96% (catalog drop table); Harbourmaster Chen 3.96% (catalog drop table); Commander Arthit, Reinstated 3.96% (catalog drop table); The Ringmaster 3.96% (catalog drop table); Unit K-7, Overdriven 3.96% (catalog drop table); The Pit Champion 3.96% (catalog drop table); Big Sak 3.96% (catalog drop table); The Furnace Baron 3.96% (catalog drop table); Spillway Chief 3.96% (catalog drop table); The Wiroj Protocol 3.96% (catalog drop table); The Sludge Foreman 3.96% (catalog drop table); Subject 12 3.96% (catalog drop table); Commander Arthit 3.96% (catalog drop table); Director Wiroj 3.96% (catalog drop table); Vault Warden 0.012% (catalog drop table); Coolant Drone 0.012% (catalog drop table); Vault Trooper 0.012% (catalog drop table); Underworks Brute 0.012% (catalog drop table); Reactor Tech 0.012% (catalog drop table); Reactor Overseer 0.012% (catalog drop table); Foundry Hand 0.012% (catalog drop table); Slag Slinger 0.012% (catalog drop table); Foundry Boss 0.012% (catalog drop table); Heart Guard 0.012% (catalog drop table); Iron Sentry 0.012% (catalog drop table); Heart Keeper 0.012% (catalog drop table); Vault Runner 0.012% (catalog drop table); Tank Crawler 0.012% (catalog drop table); Furnace Hauler 0.012% (catalog drop table); Rivet Thrower 0.012% (catalog drop table); Smogling 0.012% (catalog drop table); Tar Rat 0.012% (catalog drop table); Pipe Brute 0.012% (catalog drop table); Smog Warden 0.012% (catalog drop table); Dock Thug 0.012% (catalog drop table); Rail Bruiser 0.012% (catalog drop table); Night Market Punk 0.012% (catalog drop table); Refinery Enforcer 0.012% (catalog drop table); Bottle Thrower 0.012% (catalog drop table); Stevedore 0.012% (catalog drop table); Port Guard 0.012% (catalog drop table); Dock Slinger 0.012% (catalog drop table); Plant Guard 0.012% (catalog drop table); Hazmat Sprayer 0.012% (catalog drop table); Patrol Unit 0.012% (catalog drop table); Network Runner 0.012% (catalog drop table); Network Enforcer 0.012% (catalog drop table); Ring Fighter 0.012% (catalog drop table); Facility Trooper 0.012% (catalog drop table); Riot Trooper 0.012% (catalog drop table); Hybrid Worker 0.012% (catalog drop table); Core Sentinel 0.012% (catalog drop table); Hybrid Brute 0.012% (catalog drop table)
- `baron_furnace_core` Furnace Baron's Core: The Furnace Baron 25.0% (boss's own list)
- `baron_knuckledusters` Baron's Knuckledusters: The Furnace Baron 6.0% (own loot table)
- `baron_ledger` The Baron's Ledger: quest "The Furnace Baron"
- `brass_knuckles` Brass Knuckles: Night Market Punk 8.733% (field elite, Rail Sidings); Night Market Punk 3.0% (own loot table); Night Market Punk 3.0% (own loot table, Rail Sidings); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `brass_whistle` Brass Whistle: quest "The Sludge Foreman"
- `canvas_sneakers` Canvas Sneakers: shop Kenji's Gear Stall, 35 coins
- `canvas_work_shirt` Canvas Work Shirt: Unit K-7 7.84% (catalog drop table); Security Chief Nattapong 7.84% (catalog drop table); Subject Twelve, Relapsed 7.84% (catalog drop table); Harbourmaster Chen 7.84% (catalog drop table); Commander Arthit, Reinstated 7.84% (catalog drop table); The Ringmaster 7.84% (catalog drop table); Unit K-7, Overdriven 7.84% (catalog drop table); The Pit Champion 7.84% (catalog drop table); Big Sak 7.84% (catalog drop table); The Furnace Baron 7.84% (catalog drop table); Spillway Chief 7.84% (catalog drop table); The Wiroj Protocol 7.84% (catalog drop table); The Sludge Foreman 7.84% (catalog drop table); Subject 12 7.84% (catalog drop table); Commander Arthit 7.84% (catalog drop table); Director Wiroj 7.84% (catalog drop table); Vault Warden 0.198% (catalog drop table); Coolant Drone 0.198% (catalog drop table); Vault Trooper 0.198% (catalog drop table); Underworks Brute 0.198% (catalog drop table); Reactor Tech 0.198% (catalog drop table); Reactor Overseer 0.198% (catalog drop table); Foundry Hand 0.198% (catalog drop table); Slag Slinger 0.198% (catalog drop table); Foundry Boss 0.198% (catalog drop table); Heart Guard 0.198% (catalog drop table); Iron Sentry 0.198% (catalog drop table); Heart Keeper 0.198% (catalog drop table); Vault Runner 0.198% (catalog drop table); Tank Crawler 0.198% (catalog drop table); Furnace Hauler 0.198% (catalog drop table); Rivet Thrower 0.198% (catalog drop table); Smogling 0.198% (catalog drop table); Tar Rat 0.198% (catalog drop table); Pipe Brute 0.198% (catalog drop table); Smog Warden 0.198% (catalog drop table); Dock Thug 0.198% (catalog drop table); Rail Bruiser 0.198% (catalog drop table); Night Market Punk 0.198% (catalog drop table); Refinery Enforcer 0.198% (catalog drop table); Bottle Thrower 0.198% (catalog drop table); Stevedore 0.198% (catalog drop table); Port Guard 0.198% (catalog drop table); Dock Slinger 0.198% (catalog drop table); Plant Guard 0.198% (catalog drop table); Hazmat Sprayer 0.198% (catalog drop table); Patrol Unit 0.198% (catalog drop table); Network Runner 0.198% (catalog drop table); Network Enforcer 0.198% (catalog drop table); Ring Fighter 0.198% (catalog drop table); Facility Trooper 0.198% (catalog drop table); Riot Trooper 0.198% (catalog drop table); Hybrid Worker 0.198% (catalog drop table); Core Sentinel 0.198% (catalog drop table); Hybrid Brute 0.198% (catalog drop table)
- `cargo_gloves` Cargo Gloves: Dock Slinger 7.968% (field elite, Harbour Stacks); Dock Slinger 3.0% (own loot table); Dock Slinger 2.73% (own loot table, Harbour Stacks); Dock Thug 0.4% (farming ground prize, Harbour Stacks); Stevedore 0.4% (farming ground prize, Harbour Stacks); Port Guard 0.4% (farming ground prize, Harbour Stacks); Dock Slinger 0.4% (farming ground prize, Harbour Stacks)
- `chais_deck_shoes` Chai's Deck Shoes: quest "The Harbourmaster"
- `champion_headband` Champion's Headband: The Pit Champion 20.0% (own loot table)
- `champion_wraps` Champion's Wraps: The Pit Champion 25.0% (own loot table)
- `chen_anchor_link` Harbourmaster's Anchor Link: Harbourmaster Chen 30.0% (boss's own list)
- `chiefs_baton` Chief's Baton: Security Chief Nattapong 20.0% (own loot table); Plant Guard 3.0% (field elite, Plant Outskirts); Hazmat Sprayer 3.0% (field elite, Plant Outskirts); Patrol Unit 3.0% (field elite, Plant Outskirts)
- `chiefs_gloves` Chief's Gloves: Security Chief Nattapong 20.0% (own loot table); Plant Guard 3.0% (field elite, Plant Outskirts); Hazmat Sprayer 3.0% (field elite, Plant Outskirts); Patrol Unit 3.0% (field elite, Plant Outskirts)
- `colossus_core` Colossus Core: The Iron Colossus 8.0% (kill reward, The Old Scrapyard); The Iron Colossus 2.0% (personal tier, The Old Scrapyard)
- `commander_greaves` Commander's Greaves: Commander Arthit 20.0% (own loot table)
- `coolant_epic_body` Reinstated Plate: Commander Arthit, Reinstated 15.0% (own loot table); Vault Trooper 2.0% (field elite, Coolant Vaults); Vault Trooper 2.0% (field elite, Coolant Control Room); Coolant Drone 2.0% (field elite, Coolant Vaults); Coolant Drone 2.0% (field elite, Coolant Control Room); Vault Warden 2.0% (field elite, Coolant Vaults); Vault Warden 2.0% (field elite, Coolant Control Room); Vault Runner 2.0% (field elite, Coolant Vaults); Vault Runner 2.0% (field elite, Coolant Control Room); Vault Warden 1.967% (field elite, Coolant Vaults); Vault Warden 1.967% (field elite, Coolant Control Room); Vault Warden 0.66% (own loot table, Coolant Vaults); Vault Warden 0.66% (own loot table, Coolant Control Room)
- `coolant_epic_charm` Reinstated Charm: Commander Arthit, Reinstated 15.0% (own loot table)
- `coolant_epic_feet` Reinstated Boots: Commander Arthit, Reinstated 15.0% (own loot table)
- `coolant_epic_hands` Reinstated Gloves: Commander Arthit, Reinstated 15.0% (own loot table)
- `coolant_epic_head` Reinstated Helm: Commander Arthit, Reinstated 15.0% (own loot table)
- `coolant_epic_weapon` Reinstated Knuckles: Commander Arthit, Reinstated 15.0% (own loot table); Vault Warden 1.967% (field elite, Coolant Vaults); Vault Warden 1.967% (field elite, Coolant Control Room); Vault Warden 0.66% (own loot table, Coolant Vaults); Vault Warden 0.66% (own loot table, Coolant Control Room)
- `coolant_rare_body` Vault Guard Plate: Vault Warden 7.713% (field elite, Coolant Control Room); Vault Warden 7.713% (field elite, Coolant Vaults); Vault Trooper 3.908% (field elite, Coolant Vaults); Vault Trooper 3.908% (field elite, Coolant Control Room); Vault Warden 2.64% (own loot table, Coolant Vaults); Vault Warden 2.64% (own loot table, Coolant Control Room); Vault Trooper 1.32% (own loot table, Coolant Vaults); Vault Trooper 1.32% (own loot table, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Vaults); Vault Warden 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Vaults); Coolant Drone 0.1% (farming ground prize, Coolant Control Room); Coolant Drone 0.1% (farming ground prize, Coolant Vaults); Vault Trooper 0.1% (farming ground prize, Coolant Control Room); Vault Trooper 0.1% (farming ground prize, Coolant Vaults); Underworks Brute 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Tank Crawler 0.05% (farming ground prize, Tank Hall)
- `coolant_rare_charm` Vault Guard Charm: Vault Warden 7.713% (field elite, Coolant Control Room); Vault Warden 7.713% (field elite, Coolant Vaults); Coolant Drone 3.908% (field elite, Coolant Vaults); Coolant Drone 3.908% (field elite, Coolant Control Room); Vault Warden 2.64% (own loot table, Coolant Vaults); Vault Warden 2.64% (own loot table, Coolant Control Room); Coolant Drone 1.32% (own loot table, Coolant Vaults); Coolant Drone 1.32% (own loot table, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Vaults); Vault Warden 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Vaults); Coolant Drone 0.1% (farming ground prize, Coolant Control Room); Coolant Drone 0.1% (farming ground prize, Coolant Vaults); Vault Trooper 0.1% (farming ground prize, Coolant Control Room); Vault Trooper 0.1% (farming ground prize, Coolant Vaults); Underworks Brute 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Tank Crawler 0.05% (farming ground prize, Tank Hall)
- `coolant_rare_feet` Vault Guard Boots: Vault Warden 7.713% (field elite, Coolant Control Room); Vault Warden 7.713% (field elite, Coolant Vaults); Coolant Drone 3.908% (field elite, Coolant Vaults); Coolant Drone 3.908% (field elite, Coolant Control Room); Vault Warden 2.64% (own loot table, Coolant Vaults); Vault Warden 2.64% (own loot table, Coolant Control Room); Coolant Drone 1.32% (own loot table, Coolant Vaults); Coolant Drone 1.32% (own loot table, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Vaults); Vault Warden 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Vaults); Coolant Drone 0.1% (farming ground prize, Coolant Control Room); Coolant Drone 0.1% (farming ground prize, Coolant Vaults); Vault Trooper 0.1% (farming ground prize, Coolant Control Room); Vault Trooper 0.1% (farming ground prize, Coolant Vaults); Underworks Brute 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Tank Crawler 0.05% (farming ground prize, Tank Hall)
- `coolant_rare_hands` Vault Guard Gloves: Vault Warden 7.713% (field elite, Coolant Vaults); Vault Warden 7.713% (field elite, Coolant Control Room); Vault Runner 3.908% (field elite, Coolant Vaults); Vault Runner 3.908% (field elite, Coolant Control Room); Vault Warden 2.64% (own loot table, Coolant Vaults); Vault Warden 2.64% (own loot table, Coolant Control Room); Vault Runner 1.32% (own loot table, Coolant Vaults); Vault Runner 1.32% (own loot table, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Vaults); Vault Runner 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Vaults); Coolant Drone 0.1% (farming ground prize, Coolant Control Room); Coolant Drone 0.1% (farming ground prize, Coolant Vaults); Vault Trooper 0.1% (farming ground prize, Coolant Control Room); Vault Trooper 0.1% (farming ground prize, Coolant Vaults); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `coolant_rare_head` Vault Guard Helm: Vault Warden 7.713% (field elite, Coolant Vaults); Vault Warden 7.713% (field elite, Coolant Control Room); Vault Runner 3.908% (field elite, Coolant Vaults); Vault Runner 3.908% (field elite, Coolant Control Room); Vault Warden 2.64% (own loot table, Coolant Vaults); Vault Warden 2.64% (own loot table, Coolant Control Room); Vault Runner 1.32% (own loot table, Coolant Vaults); Vault Runner 1.32% (own loot table, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Vaults); Vault Runner 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Vaults); Coolant Drone 0.1% (farming ground prize, Coolant Control Room); Coolant Drone 0.1% (farming ground prize, Coolant Vaults); Vault Trooper 0.1% (farming ground prize, Coolant Control Room); Vault Trooper 0.1% (farming ground prize, Coolant Vaults); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `coolant_rare_weapon` Vault Guard Knuckles: Vault Warden 7.713% (field elite, Coolant Control Room); Vault Warden 7.713% (field elite, Coolant Vaults); Vault Trooper 3.908% (field elite, Coolant Vaults); Vault Trooper 3.908% (field elite, Coolant Control Room); Vault Warden 2.64% (own loot table, Coolant Vaults); Vault Warden 2.64% (own loot table, Coolant Control Room); Vault Trooper 1.32% (own loot table, Coolant Vaults); Vault Trooper 1.32% (own loot table, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Control Room); Vault Runner 0.1% (farming ground prize, Coolant Vaults); Vault Warden 0.1% (farming ground prize, Coolant Control Room); Vault Warden 0.1% (farming ground prize, Coolant Vaults); Coolant Drone 0.1% (farming ground prize, Coolant Control Room); Coolant Drone 0.1% (farming ground prize, Coolant Vaults); Vault Trooper 0.1% (farming ground prize, Coolant Control Room); Vault Trooper 0.1% (farming ground prize, Coolant Vaults); Underworks Brute 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Tank Crawler 0.05% (farming ground prize, Tank Hall)
- `coolant_uncommon_body` Coolant Plate: Vault Trooper 0.33% (farming ground prize, Coolant Vaults); Vault Trooper 0.33% (farming ground prize, Coolant Control Room); Coolant Drone 0.33% (farming ground prize, Coolant Vaults); Coolant Drone 0.33% (farming ground prize, Coolant Control Room); Vault Warden 0.33% (farming ground prize, Coolant Vaults); Vault Warden 0.33% (farming ground prize, Coolant Control Room); Vault Runner 0.33% (farming ground prize, Coolant Vaults); Vault Runner 0.33% (farming ground prize, Coolant Control Room); Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall)
- `coolant_uncommon_charm` Coolant Charm: Vault Trooper 0.33% (farming ground prize, Coolant Vaults); Vault Trooper 0.33% (farming ground prize, Coolant Control Room); Coolant Drone 0.33% (farming ground prize, Coolant Vaults); Coolant Drone 0.33% (farming ground prize, Coolant Control Room); Vault Warden 0.33% (farming ground prize, Coolant Vaults); Vault Warden 0.33% (farming ground prize, Coolant Control Room); Vault Runner 0.33% (farming ground prize, Coolant Vaults); Vault Runner 0.33% (farming ground prize, Coolant Control Room); Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall)
- `coolant_uncommon_feet` Coolant Boots: Vault Trooper 0.33% (farming ground prize, Coolant Vaults); Vault Trooper 0.33% (farming ground prize, Coolant Control Room); Coolant Drone 0.33% (farming ground prize, Coolant Vaults); Coolant Drone 0.33% (farming ground prize, Coolant Control Room); Vault Warden 0.33% (farming ground prize, Coolant Vaults); Vault Warden 0.33% (farming ground prize, Coolant Control Room); Vault Runner 0.33% (farming ground prize, Coolant Vaults); Vault Runner 0.33% (farming ground prize, Coolant Control Room); Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall)
- `coolant_uncommon_hands` Coolant Gloves: Vault Trooper 0.33% (farming ground prize, Coolant Vaults); Vault Trooper 0.33% (farming ground prize, Coolant Control Room); Coolant Drone 0.33% (farming ground prize, Coolant Vaults); Coolant Drone 0.33% (farming ground prize, Coolant Control Room); Vault Warden 0.33% (farming ground prize, Coolant Vaults); Vault Warden 0.33% (farming ground prize, Coolant Control Room); Vault Runner 0.33% (farming ground prize, Coolant Vaults); Vault Runner 0.33% (farming ground prize, Coolant Control Room); Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall)
- `coolant_uncommon_head` Coolant Helm: Vault Trooper 0.33% (farming ground prize, Coolant Vaults); Vault Trooper 0.33% (farming ground prize, Coolant Control Room); Coolant Drone 0.33% (farming ground prize, Coolant Vaults); Coolant Drone 0.33% (farming ground prize, Coolant Control Room); Vault Warden 0.33% (farming ground prize, Coolant Vaults); Vault Warden 0.33% (farming ground prize, Coolant Control Room); Vault Runner 0.33% (farming ground prize, Coolant Vaults); Vault Runner 0.33% (farming ground prize, Coolant Control Room); Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall)
- `coolant_uncommon_weapon` Coolant Knuckles: Vault Trooper 0.33% (farming ground prize, Coolant Vaults); Vault Trooper 0.33% (farming ground prize, Coolant Control Room); Coolant Drone 0.33% (farming ground prize, Coolant Vaults); Coolant Drone 0.33% (farming ground prize, Coolant Control Room); Vault Warden 0.33% (farming ground prize, Coolant Vaults); Vault Warden 0.33% (farming ground prize, Coolant Control Room); Vault Runner 0.33% (farming ground prize, Coolant Vaults); Vault Runner 0.33% (farming ground prize, Coolant Control Room); Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall)
- `copper_plated_knuckles` Copper-Plated Knuckles: Unit K-7 6.878% (catalog drop table); Security Chief Nattapong 6.878% (catalog drop table); Subject Twelve, Relapsed 6.878% (catalog drop table); Harbourmaster Chen 6.878% (catalog drop table); Commander Arthit, Reinstated 6.878% (catalog drop table); The Ringmaster 6.878% (catalog drop table); Unit K-7, Overdriven 6.878% (catalog drop table); The Pit Champion 6.878% (catalog drop table); Big Sak 6.878% (catalog drop table); The Furnace Baron 6.878% (catalog drop table); Spillway Chief 6.878% (catalog drop table); The Wiroj Protocol 6.878% (catalog drop table); The Sludge Foreman 6.878% (catalog drop table); Subject 12 6.878% (catalog drop table); Commander Arthit 6.878% (catalog drop table); Director Wiroj 6.878% (catalog drop table); Vault Warden 0.053% (catalog drop table); Coolant Drone 0.053% (catalog drop table); Vault Trooper 0.053% (catalog drop table); Underworks Brute 0.053% (catalog drop table); Reactor Tech 0.053% (catalog drop table); Reactor Overseer 0.053% (catalog drop table); Foundry Hand 0.053% (catalog drop table); Slag Slinger 0.053% (catalog drop table); Foundry Boss 0.053% (catalog drop table); Heart Guard 0.053% (catalog drop table); Iron Sentry 0.053% (catalog drop table); Heart Keeper 0.053% (catalog drop table); Vault Runner 0.053% (catalog drop table); Tank Crawler 0.053% (catalog drop table); Furnace Hauler 0.053% (catalog drop table); Rivet Thrower 0.053% (catalog drop table); Smogling 0.053% (catalog drop table); Tar Rat 0.053% (catalog drop table); Pipe Brute 0.053% (catalog drop table); Smog Warden 0.053% (catalog drop table); Dock Thug 0.053% (catalog drop table); Rail Bruiser 0.053% (catalog drop table); Night Market Punk 0.053% (catalog drop table); Refinery Enforcer 0.053% (catalog drop table); Bottle Thrower 0.053% (catalog drop table); Stevedore 0.053% (catalog drop table); Port Guard 0.053% (catalog drop table); Dock Slinger 0.053% (catalog drop table); Plant Guard 0.053% (catalog drop table); Hazmat Sprayer 0.053% (catalog drop table); Patrol Unit 0.053% (catalog drop table); Network Runner 0.053% (catalog drop table); Network Enforcer 0.053% (catalog drop table); Ring Fighter 0.053% (catalog drop table); Facility Trooper 0.053% (catalog drop table); Riot Trooper 0.053% (catalog drop table); Hybrid Worker 0.053% (catalog drop table); Core Sentinel 0.053% (catalog drop table); Hybrid Brute 0.053% (catalog drop table)
- `core_guard_helm` Core Guard Helm: Core Sentinel 5.564% (field elite, Core Spillway); Core Sentinel 5.564% (field elite, Spillway Gatehouse); Core Sentinel 5.043% (field elite, Core Overflow); Core Sentinel 3.0% (own loot table); Core Sentinel 1.89% (own loot table, Core Spillway); Core Sentinel 1.89% (own loot table, Spillway Gatehouse); Core Sentinel 1.71% (own loot table, Core Overflow); Hazmat Sprayer 0.4% (farming ground prize, Core Spillway); Hazmat Sprayer 0.4% (farming ground prize, Spillway Gatehouse); Facility Trooper 0.4% (farming ground prize, Core Spillway); Facility Trooper 0.4% (farming ground prize, Spillway Gatehouse); Core Sentinel 0.4% (farming ground prize, Core Spillway); Core Sentinel 0.4% (farming ground prize, Spillway Gatehouse)
- `core_source_data` Core Source Data: quest "Commander Arthit"
- `crimson_warlord_fists` Crimson Warlord Fists: The Furnace Baron 0.5% (boss's own list); The Wiroj Protocol 0.04% (catalog drop table); Spillway Chief 0.04% (catalog drop table); Unit K-7, Overdriven 0.04% (catalog drop table); Subject Twelve, Relapsed 0.04% (catalog drop table); Commander Arthit, Reinstated 0.04% (catalog drop table); Director Wiroj 0.04% (catalog drop table); Commander Arthit 0.04% (catalog drop table); Subject 12 0.04% (catalog drop table); Big Sak 0.04% (catalog drop table); The Ringmaster 0.04% (catalog drop table); Unit K-7 0.04% (catalog drop table); Security Chief Nattapong 0.04% (catalog drop table); Harbourmaster Chen 0.04% (catalog drop table); The Pit Champion 0.04% (catalog drop table); The Furnace Baron 0.04% (catalog drop table); The Sludge Foreman 0.04% (catalog drop table)
- `crimson_warlord_helm` Crimson Warlord Helm: Director Wiroj 0.5% (boss's own list); The Wiroj Protocol 0.02% (catalog drop table); Spillway Chief 0.02% (catalog drop table); Unit K-7, Overdriven 0.02% (catalog drop table); Subject Twelve, Relapsed 0.02% (catalog drop table); Commander Arthit, Reinstated 0.02% (catalog drop table); Director Wiroj 0.02% (catalog drop table); Commander Arthit 0.02% (catalog drop table); Subject 12 0.02% (catalog drop table); Big Sak 0.02% (catalog drop table); The Ringmaster 0.02% (catalog drop table); Unit K-7 0.02% (catalog drop table); Security Chief Nattapong 0.02% (catalog drop table); Harbourmaster Chen 0.02% (catalog drop table); The Pit Champion 0.02% (catalog drop table); The Furnace Baron 0.02% (catalog drop table); The Sludge Foreman 0.02% (catalog drop table)
- `crimson_warlord_mantle` Crimson Warlord Mantle: Commander Arthit 0.5% (boss's own list); The Wiroj Protocol 0.04% (catalog drop table); Spillway Chief 0.04% (catalog drop table); Unit K-7, Overdriven 0.04% (catalog drop table); Subject Twelve, Relapsed 0.04% (catalog drop table); Commander Arthit, Reinstated 0.04% (catalog drop table); Director Wiroj 0.04% (catalog drop table); Commander Arthit 0.04% (catalog drop table); Subject 12 0.04% (catalog drop table); Big Sak 0.04% (catalog drop table); The Ringmaster 0.04% (catalog drop table); Unit K-7 0.04% (catalog drop table); Security Chief Nattapong 0.04% (catalog drop table); Harbourmaster Chen 0.04% (catalog drop table); The Pit Champion 0.04% (catalog drop table); The Furnace Baron 0.04% (catalog drop table); The Sludge Foreman 0.04% (catalog drop table)
- `crucible_gauntlets` Crucible Gauntlets: The Crucible King 9.0% (kill reward, The Crucible Pit); The Crucible King 3.0% (personal tier, The Crucible Pit)
- `crucible_heart` Heart of the Crucible: The Crucible King 9.0% (kill reward, The Crucible Pit); The Crucible King 3.0% (personal tier, The Crucible Pit)
- `crucible_maul` Crucible King's Maul: The Crucible King 9.0% (kill reward, The Crucible Pit); The Crucible King 3.0% (personal tier, The Crucible Pit)
- `crystal_tiara` Crystal Tiara: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `cyber_visor` Cyber Visor: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `deck_boots` Deck Boots: Stevedore 7.968% (field elite, Harbour Stacks); Stevedore 3.0% (own loot table); Stevedore 2.73% (own loot table, Harbour Stacks); Dock Thug 0.4% (farming ground prize, Harbour Stacks); Stevedore 0.4% (farming ground prize, Harbour Stacks); Port Guard 0.4% (farming ground prize, Harbour Stacks); Dock Slinger 0.4% (farming ground prize, Harbour Stacks)
- `director_coat` Director's Coat: Director Wiroj 20.0% (own loot table); Patrol Unit 3.0% (field elite, Core Overflow); Facility Trooper 3.0% (field elite, Core Overflow); Core Sentinel 3.0% (field elite, Core Overflow)
- `director_crown` Director's Crown: Director Wiroj 6.0% (own loot table)
- `director_signet` Director's Signet: Director Wiroj 6.0% (own loot table)
- `dock_beanie` Dock Beanie: Smogling 11.5% (field elite, Saltmarket Backlots); Smogling 4.0% (own loot table); Smogling 4.0% (own loot table, Saltmarket Backlots); shop Kenji's Gear Stall, 30 coins
- `dock_hook` Dock Hook: Dock Thug 0.4% (farming ground prize, Harbour Stacks); Stevedore 0.4% (farming ground prize, Harbour Stacks); Port Guard 0.4% (farming ground prize, Harbour Stacks); Dock Slinger 0.4% (farming ground prize, Harbour Stacks)
- `dockers_cap` Docker's Cap: Port Guard 10.5% (field elite, Harbour Stacks); Port Guard 4.0% (own loot table); Port Guard 3.64% (own loot table, Harbour Stacks); Dock Thug 0.4% (farming ground prize, Harbour Stacks); Stevedore 0.4% (farming ground prize, Harbour Stacks); Port Guard 0.4% (farming ground prize, Harbour Stacks); Dock Slinger 0.4% (farming ground prize, Harbour Stacks)
- `dockmaster_boots` Dockmaster's Boots: Harbourmaster Chen 20.0% (own loot table); Dock Thug 3.0% (field elite, Harbour Stacks); Stevedore 3.0% (field elite, Harbour Stacks); Port Guard 3.0% (field elite, Harbour Stacks); Dock Slinger 3.0% (field elite, Harbour Stacks)
- `dragonscale_hood` Dragonscale Hood: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `emerald_feather_hat` Emerald Feather Hat: Unit K-7 1.395% (catalog drop table); Security Chief Nattapong 1.395% (catalog drop table); Subject Twelve, Relapsed 1.395% (catalog drop table); Harbourmaster Chen 1.395% (catalog drop table); Commander Arthit, Reinstated 1.395% (catalog drop table); The Ringmaster 1.395% (catalog drop table); Unit K-7, Overdriven 1.395% (catalog drop table); The Pit Champion 1.395% (catalog drop table); Big Sak 1.395% (catalog drop table); The Furnace Baron 1.395% (catalog drop table); Spillway Chief 1.395% (catalog drop table); The Wiroj Protocol 1.395% (catalog drop table); The Sludge Foreman 1.395% (catalog drop table); Subject 12 1.395% (catalog drop table); Commander Arthit 1.395% (catalog drop table); Director Wiroj 1.395% (catalog drop table); Vault Warden 0.011% (catalog drop table); Coolant Drone 0.011% (catalog drop table); Vault Trooper 0.011% (catalog drop table); Underworks Brute 0.011% (catalog drop table); Reactor Tech 0.011% (catalog drop table); Reactor Overseer 0.011% (catalog drop table); Foundry Hand 0.011% (catalog drop table); Slag Slinger 0.011% (catalog drop table); Foundry Boss 0.011% (catalog drop table); Heart Guard 0.011% (catalog drop table); Iron Sentry 0.011% (catalog drop table); Heart Keeper 0.011% (catalog drop table); Vault Runner 0.011% (catalog drop table); Tank Crawler 0.011% (catalog drop table); Furnace Hauler 0.011% (catalog drop table); Rivet Thrower 0.011% (catalog drop table); Smogling 0.011% (catalog drop table); Tar Rat 0.011% (catalog drop table); Pipe Brute 0.011% (catalog drop table); Smog Warden 0.011% (catalog drop table); Dock Thug 0.011% (catalog drop table); Rail Bruiser 0.011% (catalog drop table); Night Market Punk 0.011% (catalog drop table); Refinery Enforcer 0.011% (catalog drop table); Bottle Thrower 0.011% (catalog drop table); Stevedore 0.011% (catalog drop table); Port Guard 0.011% (catalog drop table); Dock Slinger 0.011% (catalog drop table); Plant Guard 0.011% (catalog drop table); Hazmat Sprayer 0.011% (catalog drop table); Patrol Unit 0.011% (catalog drop table); Network Runner 0.011% (catalog drop table); Network Enforcer 0.011% (catalog drop table); Ring Fighter 0.011% (catalog drop table); Facility Trooper 0.011% (catalog drop table); Riot Trooper 0.011% (catalog drop table); Hybrid Worker 0.011% (catalog drop table); Core Sentinel 0.011% (catalog drop table); Hybrid Brute 0.011% (catalog drop table)
- `energy_drink_ironworks` Ironworks Energy Drink: Unit K-7 6.891% (catalog drop table); Security Chief Nattapong 6.891% (catalog drop table); Subject Twelve, Relapsed 6.891% (catalog drop table); Harbourmaster Chen 6.891% (catalog drop table); Commander Arthit, Reinstated 6.891% (catalog drop table); The Ringmaster 6.891% (catalog drop table); Unit K-7, Overdriven 6.891% (catalog drop table); The Pit Champion 6.891% (catalog drop table); Big Sak 6.891% (catalog drop table); The Furnace Baron 6.891% (catalog drop table); Spillway Chief 6.891% (catalog drop table); The Wiroj Protocol 6.891% (catalog drop table); The Sludge Foreman 6.891% (catalog drop table); Subject 12 6.891% (catalog drop table); Commander Arthit 6.891% (catalog drop table); Director Wiroj 6.891% (catalog drop table); Vault Warden 0.24% (catalog drop table); Coolant Drone 0.24% (catalog drop table); Vault Trooper 0.24% (catalog drop table); Underworks Brute 0.24% (catalog drop table); Reactor Tech 0.24% (catalog drop table); Reactor Overseer 0.24% (catalog drop table); Foundry Hand 0.24% (catalog drop table); Slag Slinger 0.24% (catalog drop table); Foundry Boss 0.24% (catalog drop table); Heart Guard 0.24% (catalog drop table); Iron Sentry 0.24% (catalog drop table); Heart Keeper 0.24% (catalog drop table); Vault Runner 0.24% (catalog drop table); Tank Crawler 0.24% (catalog drop table); Furnace Hauler 0.24% (catalog drop table); Rivet Thrower 0.24% (catalog drop table); Smogling 0.24% (catalog drop table); Tar Rat 0.24% (catalog drop table); Pipe Brute 0.24% (catalog drop table); Smog Warden 0.24% (catalog drop table); Dock Thug 0.24% (catalog drop table); Rail Bruiser 0.24% (catalog drop table); Night Market Punk 0.24% (catalog drop table); Refinery Enforcer 0.24% (catalog drop table); Bottle Thrower 0.24% (catalog drop table); Stevedore 0.24% (catalog drop table); Port Guard 0.24% (catalog drop table); Dock Slinger 0.24% (catalog drop table); Plant Guard 0.24% (catalog drop table); Hazmat Sprayer 0.24% (catalog drop table); Patrol Unit 0.24% (catalog drop table); Network Runner 0.24% (catalog drop table); Network Enforcer 0.24% (catalog drop table); Ring Fighter 0.24% (catalog drop table); Facility Trooper 0.24% (catalog drop table); Riot Trooper 0.24% (catalog drop table); Hybrid Worker 0.24% (catalog drop table); Core Sentinel 0.24% (catalog drop table); Hybrid Brute 0.24% (catalog drop table)
- `enhance_catalyst_rare` Rare Enhancement Catalyst: Unit K-7 2.859% (catalog drop table); Security Chief Nattapong 2.859% (catalog drop table); Subject Twelve, Relapsed 2.859% (catalog drop table); Harbourmaster Chen 2.859% (catalog drop table); Commander Arthit, Reinstated 2.859% (catalog drop table); The Ringmaster 2.859% (catalog drop table); Unit K-7, Overdriven 2.859% (catalog drop table); The Pit Champion 2.859% (catalog drop table); Big Sak 2.859% (catalog drop table); The Furnace Baron 2.859% (catalog drop table); Spillway Chief 2.859% (catalog drop table); The Wiroj Protocol 2.859% (catalog drop table); The Sludge Foreman 2.859% (catalog drop table); Subject 12 2.859% (catalog drop table); Commander Arthit 2.859% (catalog drop table); Director Wiroj 2.859% (catalog drop table); Vault Warden 0.014% (catalog drop table); Coolant Drone 0.014% (catalog drop table); Vault Trooper 0.014% (catalog drop table); Underworks Brute 0.014% (catalog drop table); Reactor Tech 0.014% (catalog drop table); Reactor Overseer 0.014% (catalog drop table); Foundry Hand 0.014% (catalog drop table); Slag Slinger 0.014% (catalog drop table); Foundry Boss 0.014% (catalog drop table); Heart Guard 0.014% (catalog drop table); Iron Sentry 0.014% (catalog drop table); Heart Keeper 0.014% (catalog drop table); Vault Runner 0.014% (catalog drop table); Tank Crawler 0.014% (catalog drop table); Furnace Hauler 0.014% (catalog drop table); Rivet Thrower 0.014% (catalog drop table); Smogling 0.014% (catalog drop table); Tar Rat 0.014% (catalog drop table); Pipe Brute 0.014% (catalog drop table); Smog Warden 0.014% (catalog drop table); Dock Thug 0.014% (catalog drop table); Rail Bruiser 0.014% (catalog drop table); Night Market Punk 0.014% (catalog drop table); Refinery Enforcer 0.014% (catalog drop table); Bottle Thrower 0.014% (catalog drop table); Stevedore 0.014% (catalog drop table); Port Guard 0.014% (catalog drop table); Dock Slinger 0.014% (catalog drop table); Plant Guard 0.014% (catalog drop table); Hazmat Sprayer 0.014% (catalog drop table); Patrol Unit 0.014% (catalog drop table); Network Runner 0.014% (catalog drop table); Network Enforcer 0.014% (catalog drop table); Ring Fighter 0.014% (catalog drop table); Facility Trooper 0.014% (catalog drop table); Riot Trooper 0.014% (catalog drop table); Hybrid Worker 0.014% (catalog drop table); Core Sentinel 0.014% (catalog drop table); Hybrid Brute 0.014% (catalog drop table)
- `enhance_catalyst_special` Special Enhancement Catalyst: Subject 12 1.0% (boss's own list); The Wiroj Protocol 0.12% (catalog drop table); Spillway Chief 0.12% (catalog drop table); Unit K-7, Overdriven 0.12% (catalog drop table); Subject Twelve, Relapsed 0.12% (catalog drop table); Commander Arthit, Reinstated 0.12% (catalog drop table); Director Wiroj 0.12% (catalog drop table); Commander Arthit 0.12% (catalog drop table); Subject 12 0.12% (catalog drop table); Big Sak 0.12% (catalog drop table); The Ringmaster 0.12% (catalog drop table); Unit K-7 0.12% (catalog drop table); Security Chief Nattapong 0.12% (catalog drop table); Harbourmaster Chen 0.12% (catalog drop table); The Pit Champion 0.12% (catalog drop table); The Furnace Baron 0.12% (catalog drop table); The Sludge Foreman 0.12% (catalog drop table)
- `enhance_stone_advanced` Advanced Enhancement Stone: The Ringmaster 20.0% (boss's own list); Unit K-7 11.6% (catalog drop table); Security Chief Nattapong 11.6% (catalog drop table); Subject Twelve, Relapsed 11.6% (catalog drop table); Commander Arthit, Reinstated 11.6% (catalog drop table); Harbourmaster Chen 11.6% (catalog drop table); The Ringmaster 11.6% (catalog drop table); Unit K-7, Overdriven 11.6% (catalog drop table); The Pit Champion 11.6% (catalog drop table); Big Sak 11.6% (catalog drop table); The Furnace Baron 11.6% (catalog drop table); Spillway Chief 11.6% (catalog drop table); The Wiroj Protocol 11.6% (catalog drop table); The Sludge Foreman 11.6% (catalog drop table); Subject 12 11.6% (catalog drop table); Commander Arthit 11.6% (catalog drop table); Director Wiroj 11.6% (catalog drop table); Vault Warden 0.126% (catalog drop table); Coolant Drone 0.126% (catalog drop table); Vault Trooper 0.126% (catalog drop table); Underworks Brute 0.126% (catalog drop table); Reactor Tech 0.126% (catalog drop table); Reactor Overseer 0.126% (catalog drop table); Foundry Hand 0.126% (catalog drop table); Slag Slinger 0.126% (catalog drop table); Foundry Boss 0.126% (catalog drop table); Heart Guard 0.126% (catalog drop table); Iron Sentry 0.126% (catalog drop table); Heart Keeper 0.126% (catalog drop table); Vault Runner 0.126% (catalog drop table); Tank Crawler 0.126% (catalog drop table); Furnace Hauler 0.126% (catalog drop table); Rivet Thrower 0.126% (catalog drop table); Smogling 0.126% (catalog drop table); Tar Rat 0.126% (catalog drop table); Pipe Brute 0.126% (catalog drop table); Smog Warden 0.126% (catalog drop table); Dock Thug 0.126% (catalog drop table); Rail Bruiser 0.126% (catalog drop table); Night Market Punk 0.126% (catalog drop table); Refinery Enforcer 0.126% (catalog drop table); Bottle Thrower 0.126% (catalog drop table); Stevedore 0.126% (catalog drop table); Port Guard 0.126% (catalog drop table); Dock Slinger 0.126% (catalog drop table); Plant Guard 0.126% (catalog drop table); Hazmat Sprayer 0.126% (catalog drop table); Patrol Unit 0.126% (catalog drop table); Network Runner 0.126% (catalog drop table); Network Enforcer 0.126% (catalog drop table); Ring Fighter 0.126% (catalog drop table); Facility Trooper 0.126% (catalog drop table); Riot Trooper 0.126% (catalog drop table); Hybrid Worker 0.126% (catalog drop table); Core Sentinel 0.126% (catalog drop table); Hybrid Brute 0.126% (catalog drop table)
- `enhance_stone_basic` Basic Enhancement Stone: Unit K-7 22.6% (catalog drop table); Security Chief Nattapong 22.6% (catalog drop table); Subject Twelve, Relapsed 22.6% (catalog drop table); Harbourmaster Chen 22.6% (catalog drop table); Commander Arthit, Reinstated 22.6% (catalog drop table); The Ringmaster 22.6% (catalog drop table); Unit K-7, Overdriven 22.6% (catalog drop table); The Pit Champion 22.6% (catalog drop table); Big Sak 22.6% (catalog drop table); The Furnace Baron 22.6% (catalog drop table); Spillway Chief 22.6% (catalog drop table); The Wiroj Protocol 22.6% (catalog drop table); The Sludge Foreman 22.6% (catalog drop table); Subject 12 22.6% (catalog drop table); Commander Arthit 22.6% (catalog drop table); Director Wiroj 22.6% (catalog drop table); Vault Warden 2.1% (catalog drop table); Coolant Drone 2.1% (catalog drop table); Vault Trooper 2.1% (catalog drop table); Underworks Brute 2.1% (catalog drop table); Reactor Tech 2.1% (catalog drop table); Reactor Overseer 2.1% (catalog drop table); Foundry Hand 2.1% (catalog drop table); Slag Slinger 2.1% (catalog drop table); Foundry Boss 2.1% (catalog drop table); Heart Guard 2.1% (catalog drop table); Iron Sentry 2.1% (catalog drop table); Heart Keeper 2.1% (catalog drop table); Vault Runner 2.1% (catalog drop table); Tank Crawler 2.1% (catalog drop table); Furnace Hauler 2.1% (catalog drop table); Rivet Thrower 2.1% (catalog drop table); Smogling 2.1% (catalog drop table); Tar Rat 2.1% (catalog drop table); Pipe Brute 2.1% (catalog drop table); Smog Warden 2.1% (catalog drop table); Dock Thug 2.1% (catalog drop table); Rail Bruiser 2.1% (catalog drop table); Night Market Punk 2.1% (catalog drop table); Refinery Enforcer 2.1% (catalog drop table); Bottle Thrower 2.1% (catalog drop table); Stevedore 2.1% (catalog drop table); Port Guard 2.1% (catalog drop table); Dock Slinger 2.1% (catalog drop table); Plant Guard 2.1% (catalog drop table); Hazmat Sprayer 2.1% (catalog drop table); Patrol Unit 2.1% (catalog drop table); Network Runner 2.1% (catalog drop table); Network Enforcer 2.1% (catalog drop table); Ring Fighter 2.1% (catalog drop table); Facility Trooper 2.1% (catalog drop table); Riot Trooper 2.1% (catalog drop table); Hybrid Worker 2.1% (catalog drop table); Core Sentinel 2.1% (catalog drop table); Hybrid Brute 2.1% (catalog drop table)
- `enhance_stone_refined` Refined Enhancement Stone: Unit K-7 19.9% (catalog drop table); Security Chief Nattapong 19.9% (catalog drop table); Subject Twelve, Relapsed 19.9% (catalog drop table); Harbourmaster Chen 19.9% (catalog drop table); Commander Arthit, Reinstated 19.9% (catalog drop table); The Ringmaster 19.9% (catalog drop table); Unit K-7, Overdriven 19.9% (catalog drop table); The Pit Champion 19.9% (catalog drop table); Big Sak 19.9% (catalog drop table); The Furnace Baron 19.9% (catalog drop table); Spillway Chief 19.9% (catalog drop table); The Wiroj Protocol 19.9% (catalog drop table); The Sludge Foreman 19.9% (catalog drop table); Subject 12 19.9% (catalog drop table); Commander Arthit 19.9% (catalog drop table); Director Wiroj 19.9% (catalog drop table); Vault Warden 0.56% (catalog drop table); Coolant Drone 0.56% (catalog drop table); Vault Trooper 0.56% (catalog drop table); Underworks Brute 0.56% (catalog drop table); Reactor Tech 0.56% (catalog drop table); Reactor Overseer 0.56% (catalog drop table); Foundry Hand 0.56% (catalog drop table); Slag Slinger 0.56% (catalog drop table); Foundry Boss 0.56% (catalog drop table); Heart Guard 0.56% (catalog drop table); Iron Sentry 0.56% (catalog drop table); Heart Keeper 0.56% (catalog drop table); Vault Runner 0.56% (catalog drop table); Tank Crawler 0.56% (catalog drop table); Furnace Hauler 0.56% (catalog drop table); Rivet Thrower 0.56% (catalog drop table); Smogling 0.56% (catalog drop table); Tar Rat 0.56% (catalog drop table); Pipe Brute 0.56% (catalog drop table); Smog Warden 0.56% (catalog drop table); Dock Thug 0.56% (catalog drop table); Rail Bruiser 0.56% (catalog drop table); Night Market Punk 0.56% (catalog drop table); Refinery Enforcer 0.56% (catalog drop table); Bottle Thrower 0.56% (catalog drop table); Stevedore 0.56% (catalog drop table); Port Guard 0.56% (catalog drop table); Dock Slinger 0.56% (catalog drop table); Plant Guard 0.56% (catalog drop table); Hazmat Sprayer 0.56% (catalog drop table); Patrol Unit 0.56% (catalog drop table); Network Runner 0.56% (catalog drop table); Network Enforcer 0.56% (catalog drop table); Ring Fighter 0.56% (catalog drop table); Facility Trooper 0.56% (catalog drop table); Riot Trooper 0.56% (catalog drop table); Hybrid Worker 0.56% (catalog drop table); Core Sentinel 0.56% (catalog drop table); Hybrid Brute 0.56% (catalog drop table)
- `experiment_log` Experiment Log: quest "Unit K-7"
- `exposure_report` Exposure Report: quest "Subject 12"
- `facility_boots` Facility Boots: Riot Trooper 5.564% (field elite, Facility Annex); Riot Trooper 3.0% (own loot table); Riot Trooper 1.89% (own loot table, Facility Annex); Hazmat Sprayer 0.4% (farming ground prize, Facility Annex); Patrol Unit 0.4% (farming ground prize, Facility Annex); Facility Trooper 0.4% (farming ground prize, Facility Annex); Riot Trooper 0.4% (farming ground prize, Facility Annex)
- `facility_helmet` Facility Helmet: Facility Trooper 5.564% (field elite, Facility Annex); Facility Trooper 5.564% (field elite, Core Spillway); Facility Trooper 5.564% (field elite, Spillway Gatehouse); Facility Trooper 5.043% (field elite, Core Overflow); Facility Trooper 3.0% (own loot table); Facility Trooper 1.89% (own loot table, Facility Annex); Facility Trooper 1.89% (own loot table, Core Spillway); Facility Trooper 1.89% (own loot table, Spillway Gatehouse); Facility Trooper 1.71% (own loot table, Core Overflow); Hazmat Sprayer 0.4% (farming ground prize, Facility Annex); Patrol Unit 0.4% (farming ground prize, Facility Annex); Facility Trooper 0.4% (farming ground prize, Facility Annex); Riot Trooper 0.4% (farming ground prize, Facility Annex)
- `facility_pass` Core Facility Pass: quest "Big Sak"
- `fight_gloves` Taped Fight Gloves: Ring Fighter 6.513% (field elite, Network Backrooms); Ring Fighter 3.0% (own loot table); Ring Fighter 2.22% (own loot table, Network Backrooms); Network Runner 0.4% (farming ground prize, Network Backrooms); Network Enforcer 0.4% (farming ground prize, Network Backrooms); Ring Fighter 0.4% (farming ground prize, Network Backrooms)
- `fingerless_gloves` Fingerless Gloves: Dock Thug 8.733% (field elite, Rail Sidings); Dock Thug 7.968% (field elite, Harbour Stacks); Dock Thug 3.0% (own loot table); Dock Thug 3.0% (own loot table, Rail Sidings); Dock Thug 2.73% (own loot table, Harbour Stacks); shop Kenji's Gear Stall, 35 coins
- `focus_gum` Focus Gum: Unit K-7 7.855% (catalog drop table); Security Chief Nattapong 7.855% (catalog drop table); Subject Twelve, Relapsed 7.855% (catalog drop table); Harbourmaster Chen 7.855% (catalog drop table); Commander Arthit, Reinstated 7.855% (catalog drop table); The Ringmaster 7.855% (catalog drop table); Unit K-7, Overdriven 7.855% (catalog drop table); The Pit Champion 7.855% (catalog drop table); Big Sak 7.855% (catalog drop table); The Furnace Baron 7.855% (catalog drop table); Spillway Chief 7.855% (catalog drop table); The Wiroj Protocol 7.855% (catalog drop table); The Sludge Foreman 7.855% (catalog drop table); Subject 12 7.855% (catalog drop table); Commander Arthit 7.855% (catalog drop table); Director Wiroj 7.855% (catalog drop table); Vault Warden 0.9% (catalog drop table); Coolant Drone 0.9% (catalog drop table); Vault Trooper 0.9% (catalog drop table); Underworks Brute 0.9% (catalog drop table); Reactor Tech 0.9% (catalog drop table); Reactor Overseer 0.9% (catalog drop table); Foundry Hand 0.9% (catalog drop table); Slag Slinger 0.9% (catalog drop table); Foundry Boss 0.9% (catalog drop table); Heart Guard 0.9% (catalog drop table); Iron Sentry 0.9% (catalog drop table); Heart Keeper 0.9% (catalog drop table); Vault Runner 0.9% (catalog drop table); Tank Crawler 0.9% (catalog drop table); Furnace Hauler 0.9% (catalog drop table); Rivet Thrower 0.9% (catalog drop table); Smogling 0.9% (catalog drop table); Tar Rat 0.9% (catalog drop table); Pipe Brute 0.9% (catalog drop table); Smog Warden 0.9% (catalog drop table); Dock Thug 0.9% (catalog drop table); Rail Bruiser 0.9% (catalog drop table); Night Market Punk 0.9% (catalog drop table); Refinery Enforcer 0.9% (catalog drop table); Bottle Thrower 0.9% (catalog drop table); Stevedore 0.9% (catalog drop table); Port Guard 0.9% (catalog drop table); Dock Slinger 0.9% (catalog drop table); Plant Guard 0.9% (catalog drop table); Hazmat Sprayer 0.9% (catalog drop table); Patrol Unit 0.9% (catalog drop table); Network Runner 0.9% (catalog drop table); Network Enforcer 0.9% (catalog drop table); Ring Fighter 0.9% (catalog drop table); Facility Trooper 0.9% (catalog drop table); Riot Trooper 0.9% (catalog drop table); Hybrid Worker 0.9% (catalog drop table); Core Sentinel 0.9% (catalog drop table); Hybrid Brute 0.9% (catalog drop table)
- `foreman_boots` Foreman's Boots: The Sludge Foreman 20.0% (own loot table); Smogling 3.0% (field elite, Saltmarket Backlots); Tar Rat 3.0% (field elite, Saltmarket Backlots); Pipe Brute 3.0% (field elite, Saltmarket Backlots); Smog Warden 3.0% (field elite, Saltmarket Backlots); Bottle Thrower 3.0% (field elite, Saltmarket Backlots)
- `foreman_wrench` Foreman's Wrench: The Sludge Foreman 30.0% (own loot table)
- `forged_note` Forged Delivery Note: quest "The Sludge Foreman"
- `founders_crimson_sigil` Founder's Crimson Sigil: Subject 12 0.2% (boss's own list)
- `founders_edge` The Founder's Edge: The Founder's Engine 9.0% (kill reward, The Founder's Floor); The Founder's Engine 3.0% (personal tier, The Founder's Floor)
- `founders_engine_core` Engine Heart: The Founder's Engine 9.0% (kill reward, The Founder's Floor); The Founder's Engine 3.0% (personal tier, The Founder's Floor)
- `founders_halo` Founder's Halo: The Founder's Engine 9.0% (kill reward, The Founder's Floor); The Founder's Engine 3.0% (personal tier, The Founder's Floor)
- `founders_plate` Founder's Plate: The Founder's Engine 9.0% (kill reward, The Founder's Floor); The Founder's Engine 3.0% (personal tier, The Founder's Floor)
- `foundry_epic_body` Overdriven Plate: Unit K-7, Overdriven 15.0% (own loot table); Foundry Hand 2.0% (field elite, Foundry Depths); Foundry Hand 2.0% (field elite, The Crucible); Slag Slinger 2.0% (field elite, Foundry Depths); Slag Slinger 2.0% (field elite, The Crucible); Foundry Boss 2.0% (field elite, Foundry Depths); Foundry Boss 2.0% (field elite, The Crucible); Furnace Hauler 2.0% (field elite, Foundry Depths); Furnace Hauler 2.0% (field elite, The Crucible); Foundry Boss 1.789% (field elite, Foundry Depths); Foundry Boss 1.789% (field elite, The Crucible); Foundry Boss 0.6% (own loot table, Foundry Depths); Foundry Boss 0.6% (own loot table, The Crucible)
- `foundry_epic_charm` Overdriven Charm: Unit K-7, Overdriven 15.0% (own loot table)
- `foundry_epic_feet` Overdriven Boots: Unit K-7, Overdriven 15.0% (own loot table)
- `foundry_epic_hands` Overdriven Gloves: Unit K-7, Overdriven 15.0% (own loot table)
- `foundry_epic_head` Overdriven Helm: Unit K-7, Overdriven 15.0% (own loot table)
- `foundry_epic_weapon` Overdriven Knuckles: Unit K-7, Overdriven 15.0% (own loot table); Foundry Boss 1.789% (field elite, Foundry Depths); Foundry Boss 1.789% (field elite, The Crucible); Foundry Boss 0.6% (own loot table, Foundry Depths); Foundry Boss 0.6% (own loot table, The Crucible)
- `foundry_rare_body` Slagworker Plate: Foundry Boss 7.029% (field elite, Foundry Depths); Foundry Boss 7.029% (field elite, The Crucible); Foundry Hand 3.557% (field elite, Foundry Depths); Foundry Hand 3.557% (field elite, The Crucible); Foundry Boss 2.4% (own loot table, Foundry Depths); Foundry Boss 2.4% (own loot table, The Crucible); Foundry Hand 1.2% (own loot table, Foundry Depths); Foundry Hand 1.2% (own loot table, The Crucible); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths)
- `foundry_rare_charm` Slagworker Charm: Foundry Boss 7.029% (field elite, Foundry Depths); Foundry Boss 7.029% (field elite, The Crucible); Furnace Hauler 3.557% (field elite, The Crucible); Furnace Hauler 3.557% (field elite, Foundry Depths); Foundry Boss 2.4% (own loot table, Foundry Depths); Foundry Boss 2.4% (own loot table, The Crucible); Furnace Hauler 1.2% (own loot table, The Crucible); Furnace Hauler 1.2% (own loot table, Foundry Depths); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths)
- `foundry_rare_feet` Slagworker Boots: Foundry Boss 7.029% (field elite, Foundry Depths); Foundry Boss 7.029% (field elite, The Crucible); Furnace Hauler 3.557% (field elite, The Crucible); Furnace Hauler 3.557% (field elite, Foundry Depths); Foundry Boss 2.4% (own loot table, Foundry Depths); Foundry Boss 2.4% (own loot table, The Crucible); Furnace Hauler 1.2% (own loot table, The Crucible); Furnace Hauler 1.2% (own loot table, Foundry Depths); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths)
- `foundry_rare_hands` Slagworker Gloves: Foundry Boss 7.029% (field elite, Foundry Depths); Foundry Boss 7.029% (field elite, The Crucible); Slag Slinger 3.557% (field elite, Foundry Depths); Slag Slinger 3.557% (field elite, The Crucible); Foundry Boss 2.4% (own loot table, Foundry Depths); Foundry Boss 2.4% (own loot table, The Crucible); Slag Slinger 1.2% (own loot table, Foundry Depths); Slag Slinger 1.2% (own loot table, The Crucible); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths)
- `foundry_rare_head` Slagworker Helm: Foundry Boss 7.029% (field elite, Foundry Depths); Foundry Boss 7.029% (field elite, The Crucible); Slag Slinger 3.557% (field elite, Foundry Depths); Slag Slinger 3.557% (field elite, The Crucible); Foundry Boss 2.4% (own loot table, Foundry Depths); Foundry Boss 2.4% (own loot table, The Crucible); Slag Slinger 1.2% (own loot table, Foundry Depths); Slag Slinger 1.2% (own loot table, The Crucible); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths)
- `foundry_rare_weapon` Slagworker Knuckles: Foundry Boss 7.029% (field elite, Foundry Depths); Foundry Boss 7.029% (field elite, The Crucible); Foundry Hand 3.557% (field elite, Foundry Depths); Foundry Hand 3.557% (field elite, The Crucible); Foundry Boss 2.4% (own loot table, Foundry Depths); Foundry Boss 2.4% (own loot table, The Crucible); Foundry Hand 1.2% (own loot table, Foundry Depths); Foundry Hand 1.2% (own loot table, The Crucible); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths)
- `foundry_uncommon_body` Foundry Plate: Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `foundry_uncommon_charm` Foundry Charm: Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `foundry_uncommon_feet` Foundry Boots: Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `foundry_uncommon_hands` Foundry Gloves: Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `foundry_uncommon_head` Foundry Helm: Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `foundry_uncommon_weapon` Foundry Knuckles: Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `frost_fur_hood` Frost Fur Hood: Unit K-7 1.395% (catalog drop table); Security Chief Nattapong 1.395% (catalog drop table); Subject Twelve, Relapsed 1.395% (catalog drop table); Harbourmaster Chen 1.395% (catalog drop table); Commander Arthit, Reinstated 1.395% (catalog drop table); The Ringmaster 1.395% (catalog drop table); Unit K-7, Overdriven 1.395% (catalog drop table); The Pit Champion 1.395% (catalog drop table); Big Sak 1.395% (catalog drop table); The Furnace Baron 1.395% (catalog drop table); Spillway Chief 1.395% (catalog drop table); The Wiroj Protocol 1.395% (catalog drop table); The Sludge Foreman 1.395% (catalog drop table); Subject 12 1.395% (catalog drop table); Commander Arthit 1.395% (catalog drop table); Director Wiroj 1.395% (catalog drop table); Vault Warden 0.011% (catalog drop table); Coolant Drone 0.011% (catalog drop table); Vault Trooper 0.011% (catalog drop table); Underworks Brute 0.011% (catalog drop table); Reactor Tech 0.011% (catalog drop table); Reactor Overseer 0.011% (catalog drop table); Foundry Hand 0.011% (catalog drop table); Slag Slinger 0.011% (catalog drop table); Foundry Boss 0.011% (catalog drop table); Heart Guard 0.011% (catalog drop table); Iron Sentry 0.011% (catalog drop table); Heart Keeper 0.011% (catalog drop table); Vault Runner 0.011% (catalog drop table); Tank Crawler 0.011% (catalog drop table); Furnace Hauler 0.011% (catalog drop table); Rivet Thrower 0.011% (catalog drop table); Smogling 0.011% (catalog drop table); Tar Rat 0.011% (catalog drop table); Pipe Brute 0.011% (catalog drop table); Smog Warden 0.011% (catalog drop table); Dock Thug 0.011% (catalog drop table); Rail Bruiser 0.011% (catalog drop table); Night Market Punk 0.011% (catalog drop table); Refinery Enforcer 0.011% (catalog drop table); Bottle Thrower 0.011% (catalog drop table); Stevedore 0.011% (catalog drop table); Port Guard 0.011% (catalog drop table); Dock Slinger 0.011% (catalog drop table); Plant Guard 0.011% (catalog drop table); Hazmat Sprayer 0.011% (catalog drop table); Patrol Unit 0.011% (catalog drop table); Network Runner 0.011% (catalog drop table); Network Enforcer 0.011% (catalog drop table); Ring Fighter 0.011% (catalog drop table); Facility Trooper 0.011% (catalog drop table); Riot Trooper 0.011% (catalog drop table); Hybrid Worker 0.011% (catalog drop table); Core Sentinel 0.011% (catalog drop table); Hybrid Brute 0.011% (catalog drop table)
- `gilded_brawler_helm` Gilded Brawler Helm: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `gilded_crusher_gauntlets` Gilded Crusher Gauntlets: Unit K-7 0.958% (catalog drop table); Security Chief Nattapong 0.958% (catalog drop table); Subject Twelve, Relapsed 0.958% (catalog drop table); Harbourmaster Chen 0.958% (catalog drop table); Commander Arthit, Reinstated 0.958% (catalog drop table); The Ringmaster 0.958% (catalog drop table); Unit K-7, Overdriven 0.958% (catalog drop table); The Pit Champion 0.958% (catalog drop table); Big Sak 0.958% (catalog drop table); The Furnace Baron 0.958% (catalog drop table); Spillway Chief 0.958% (catalog drop table); The Wiroj Protocol 0.958% (catalog drop table); The Sludge Foreman 0.958% (catalog drop table); Subject 12 0.958% (catalog drop table); Commander Arthit 0.958% (catalog drop table); Director Wiroj 0.958% (catalog drop table); Vault Warden 0.00132% (catalog drop table); Coolant Drone 0.00132% (catalog drop table); Vault Trooper 0.00132% (catalog drop table); Underworks Brute 0.00132% (catalog drop table); Reactor Tech 0.00132% (catalog drop table); Reactor Overseer 0.00132% (catalog drop table); Foundry Hand 0.00132% (catalog drop table); Slag Slinger 0.00132% (catalog drop table); Foundry Boss 0.00132% (catalog drop table); Heart Guard 0.00132% (catalog drop table); Iron Sentry 0.00132% (catalog drop table); Heart Keeper 0.00132% (catalog drop table); Vault Runner 0.00132% (catalog drop table); Tank Crawler 0.00132% (catalog drop table); Furnace Hauler 0.00132% (catalog drop table); Rivet Thrower 0.00132% (catalog drop table); Smogling 0.00132% (catalog drop table); Tar Rat 0.00132% (catalog drop table); Pipe Brute 0.00132% (catalog drop table); Smog Warden 0.00132% (catalog drop table); Dock Thug 0.00132% (catalog drop table); Rail Bruiser 0.00132% (catalog drop table); Night Market Punk 0.00132% (catalog drop table); Refinery Enforcer 0.00132% (catalog drop table); Bottle Thrower 0.00132% (catalog drop table); Stevedore 0.00132% (catalog drop table); Port Guard 0.00132% (catalog drop table); Dock Slinger 0.00132% (catalog drop table); Plant Guard 0.00132% (catalog drop table); Hazmat Sprayer 0.00132% (catalog drop table); Patrol Unit 0.00132% (catalog drop table); Network Runner 0.00132% (catalog drop table); Network Enforcer 0.00132% (catalog drop table); Ring Fighter 0.00132% (catalog drop table); Facility Trooper 0.00132% (catalog drop table); Riot Trooper 0.00132% (catalog drop table); Hybrid Worker 0.00132% (catalog drop table); Core Sentinel 0.00132% (catalog drop table); Hybrid Brute 0.00132% (catalog drop table)
- `gilded_fight_robe` Gilded Fight Robe: Unit K-7 0.958% (catalog drop table); Security Chief Nattapong 0.958% (catalog drop table); Subject Twelve, Relapsed 0.958% (catalog drop table); Harbourmaster Chen 0.958% (catalog drop table); Commander Arthit, Reinstated 0.958% (catalog drop table); The Ringmaster 0.958% (catalog drop table); Unit K-7, Overdriven 0.958% (catalog drop table); The Pit Champion 0.958% (catalog drop table); Big Sak 0.958% (catalog drop table); The Furnace Baron 0.958% (catalog drop table); Spillway Chief 0.958% (catalog drop table); The Wiroj Protocol 0.958% (catalog drop table); The Sludge Foreman 0.958% (catalog drop table); Subject 12 0.958% (catalog drop table); Commander Arthit 0.958% (catalog drop table); Director Wiroj 0.958% (catalog drop table); Vault Warden 0.00132% (catalog drop table); Coolant Drone 0.00132% (catalog drop table); Vault Trooper 0.00132% (catalog drop table); Underworks Brute 0.00132% (catalog drop table); Reactor Tech 0.00132% (catalog drop table); Reactor Overseer 0.00132% (catalog drop table); Foundry Hand 0.00132% (catalog drop table); Slag Slinger 0.00132% (catalog drop table); Foundry Boss 0.00132% (catalog drop table); Heart Guard 0.00132% (catalog drop table); Iron Sentry 0.00132% (catalog drop table); Heart Keeper 0.00132% (catalog drop table); Vault Runner 0.00132% (catalog drop table); Tank Crawler 0.00132% (catalog drop table); Furnace Hauler 0.00132% (catalog drop table); Rivet Thrower 0.00132% (catalog drop table); Smogling 0.00132% (catalog drop table); Tar Rat 0.00132% (catalog drop table); Pipe Brute 0.00132% (catalog drop table); Smog Warden 0.00132% (catalog drop table); Dock Thug 0.00132% (catalog drop table); Rail Bruiser 0.00132% (catalog drop table); Night Market Punk 0.00132% (catalog drop table); Refinery Enforcer 0.00132% (catalog drop table); Bottle Thrower 0.00132% (catalog drop table); Stevedore 0.00132% (catalog drop table); Port Guard 0.00132% (catalog drop table); Dock Slinger 0.00132% (catalog drop table); Plant Guard 0.00132% (catalog drop table); Hazmat Sprayer 0.00132% (catalog drop table); Patrol Unit 0.00132% (catalog drop table); Network Runner 0.00132% (catalog drop table); Network Enforcer 0.00132% (catalog drop table); Ring Fighter 0.00132% (catalog drop table); Facility Trooper 0.00132% (catalog drop table); Riot Trooper 0.00132% (catalog drop table); Hybrid Worker 0.00132% (catalog drop table); Core Sentinel 0.00132% (catalog drop table); Hybrid Brute 0.00132% (catalog drop table)
- `ginger_tea` Ginger Tea: Smog Warden 93.6% (field elite, Saltmarket Backlots); Refinery Enforcer 87.5% (field elite, Rail Sidings); Port Guard 61.6% (field elite, Harbour Stacks); Smog Warden 60.0% (own loot table); Smog Warden 60.0% (own loot table, Saltmarket Backlots); Ring Fighter 52.9% (field elite, Network Backrooms); Plant Guard 51.8% (field elite, Plant Outskirts); Refinery Enforcer 50.0% (own loot table); Refinery Enforcer 50.0% (own loot table, Rail Sidings); Network Enforcer 45.9% (field elite, Network Backrooms); Stevedore 45.3% (field elite, Harbour Stacks); Rail Bruiser 44.9% (field elite, Rail Sidings); Pipe Brute 38.6% (field elite, Saltmarket Backlots); Night Market Punk 31.9% (field elite, Rail Sidings); Ring Fighter 30.0% (own loot table); Plant Guard 30.0% (own loot table); Port Guard 30.0% (own loot table); Port Guard 27.3% (own loot table, Harbour Stacks); Network Enforcer 25.0% (own loot table); Ring Fighter 22.2% (own loot table, Network Backrooms); Plant Guard 21.6% (own loot table, Plant Outskirts); Stevedore 20.0% (own loot table); Network Enforcer 18.5% (own loot table, Network Backrooms); Stevedore 18.2% (own loot table, Harbour Stacks); Rail Bruiser 18.0% (own loot table, Rail Sidings); Rail Bruiser 18.0% (own loot table); Pipe Brute 15.0% (own loot table, Saltmarket Backlots); Pipe Brute 15.0% (own loot table); Night Market Punk 12.0% (own loot table, Rail Sidings); Night Market Punk 12.0% (own loot table); shop Ama's Kitchen, 22 coins; quest "The Sludge Foreman"; quest "The Pit"
- `glacier_crown` Glacier Crown: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `grip_gloves` Lab Grip Gloves: Hybrid Worker 3.0% (own loot table); Hazmat Sprayer 0.4% (farming ground prize, Facility Annex); Patrol Unit 0.4% (farming ground prize, Facility Annex); Facility Trooper 0.4% (farming ground prize, Facility Annex); Riot Trooper 0.4% (farming ground prize, Facility Annex)
- `harbour_hook` Harbourmaster's Hook: Harbourmaster Chen 6.0% (own loot table)
- `harbourmaster_cap` Harbourmaster's Cap: Harbourmaster Chen 20.0% (own loot table); Dock Thug 3.0% (field elite, Harbour Stacks); Stevedore 3.0% (field elite, Harbour Stacks); Port Guard 3.0% (field elite, Harbour Stacks); Dock Slinger 3.0% (field elite, Harbour Stacks)
- `hard_hat` Hard Hat: Smogling 0.4% (farming ground prize, Saltmarket Backlots); Tar Rat 0.4% (farming ground prize, Saltmarket Backlots); Pipe Brute 0.4% (farming ground prize, Saltmarket Backlots); Smog Warden 0.4% (farming ground prize, Saltmarket Backlots); Bottle Thrower 0.4% (farming ground prize, Saltmarket Backlots); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `hazmat_hood` Hazmat Hood: Plant Guard 6.341% (field elite, Plant Outskirts); Plant Guard 3.0% (own loot table); Plant Guard 2.16% (own loot table, Plant Outskirts); Plant Guard 0.4% (farming ground prize, Plant Outskirts); Hazmat Sprayer 0.4% (farming ground prize, Plant Outskirts); Patrol Unit 0.4% (farming ground prize, Plant Outskirts)
- `heart_epic_body` Protocol Plate: The Wiroj Protocol 15.0% (own loot table); Heart Guard 2.0% (field elite, The Iron Heart); Heart Guard 2.0% (field elite, Heart Core Chamber); Iron Sentry 2.0% (field elite, The Iron Heart); Iron Sentry 2.0% (field elite, Heart Core Chamber); Heart Keeper 2.0% (field elite, The Iron Heart); Heart Keeper 2.0% (field elite, Heart Core Chamber); Rivet Thrower 2.0% (field elite, The Iron Heart); Rivet Thrower 2.0% (field elite, Heart Core Chamber); Heart Keeper 1.789% (field elite, The Iron Heart); Heart Keeper 1.789% (field elite, Heart Core Chamber); Heart Keeper 0.6% (own loot table, The Iron Heart); Heart Keeper 0.6% (own loot table, Heart Core Chamber)
- `heart_epic_charm` Protocol Charm: The Wiroj Protocol 15.0% (own loot table)
- `heart_epic_feet` Protocol Boots: The Wiroj Protocol 15.0% (own loot table)
- `heart_epic_hands` Protocol Gloves: The Wiroj Protocol 15.0% (own loot table)
- `heart_epic_head` Protocol Helm: The Wiroj Protocol 15.0% (own loot table)
- `heart_epic_weapon` Protocol Knuckles: The Wiroj Protocol 15.0% (own loot table); Heart Keeper 1.789% (field elite, The Iron Heart); Heart Keeper 1.789% (field elite, Heart Core Chamber); Heart Keeper 0.6% (own loot table, The Iron Heart); Heart Keeper 0.6% (own loot table, Heart Core Chamber)
- `heart_of_iron_city` Heart of Iron City: quest "The Iron Legacy"
- `heart_rare_body` Heart Sentry Plate: Heart Keeper 7.029% (field elite, The Iron Heart); Heart Keeper 7.029% (field elite, Heart Core Chamber); Heart Guard 3.557% (field elite, The Iron Heart); Heart Guard 3.557% (field elite, Heart Core Chamber); Heart Keeper 2.4% (own loot table, The Iron Heart); Heart Keeper 2.4% (own loot table, Heart Core Chamber); Heart Guard 1.2% (own loot table, The Iron Heart); Heart Guard 1.2% (own loot table, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber)
- `heart_rare_charm` Heart Sentry Charm: Heart Keeper 7.029% (field elite, The Iron Heart); Heart Keeper 7.029% (field elite, Heart Core Chamber); Iron Sentry 3.557% (field elite, The Iron Heart); Iron Sentry 3.557% (field elite, Heart Core Chamber); Heart Keeper 2.4% (own loot table, The Iron Heart); Heart Keeper 2.4% (own loot table, Heart Core Chamber); Iron Sentry 1.2% (own loot table, The Iron Heart); Iron Sentry 1.2% (own loot table, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber)
- `heart_rare_feet` Heart Sentry Boots: Heart Keeper 7.029% (field elite, The Iron Heart); Heart Keeper 7.029% (field elite, Heart Core Chamber); Iron Sentry 3.557% (field elite, The Iron Heart); Iron Sentry 3.557% (field elite, Heart Core Chamber); Heart Keeper 2.4% (own loot table, The Iron Heart); Heart Keeper 2.4% (own loot table, Heart Core Chamber); Iron Sentry 1.2% (own loot table, The Iron Heart); Iron Sentry 1.2% (own loot table, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber)
- `heart_rare_hands` Heart Sentry Gloves: Heart Keeper 7.029% (field elite, The Iron Heart); Heart Keeper 7.029% (field elite, Heart Core Chamber); Rivet Thrower 3.557% (field elite, The Iron Heart); Rivet Thrower 3.557% (field elite, Heart Core Chamber); Heart Keeper 2.4% (own loot table, The Iron Heart); Heart Keeper 2.4% (own loot table, Heart Core Chamber); Rivet Thrower 1.2% (own loot table, The Iron Heart); Rivet Thrower 1.2% (own loot table, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber)
- `heart_rare_head` Heart Sentry Helm: Heart Keeper 7.029% (field elite, The Iron Heart); Heart Keeper 7.029% (field elite, Heart Core Chamber); Rivet Thrower 3.557% (field elite, The Iron Heart); Rivet Thrower 3.557% (field elite, Heart Core Chamber); Heart Keeper 2.4% (own loot table, The Iron Heart); Heart Keeper 2.4% (own loot table, Heart Core Chamber); Rivet Thrower 1.2% (own loot table, The Iron Heart); Rivet Thrower 1.2% (own loot table, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber)
- `heart_rare_weapon` Heart Sentry Knuckles: Heart Keeper 7.029% (field elite, The Iron Heart); Heart Keeper 7.029% (field elite, Heart Core Chamber); Heart Guard 3.557% (field elite, The Iron Heart); Heart Guard 3.557% (field elite, Heart Core Chamber); Heart Keeper 2.4% (own loot table, The Iron Heart); Heart Keeper 2.4% (own loot table, Heart Core Chamber); Heart Guard 1.2% (own loot table, The Iron Heart); Heart Guard 1.2% (own loot table, Heart Core Chamber); Heart Guard 0.05% (farming ground prize, The Iron Heart); Heart Guard 0.05% (farming ground prize, Heart Core Chamber); Iron Sentry 0.05% (farming ground prize, The Iron Heart); Iron Sentry 0.05% (farming ground prize, Heart Core Chamber); Heart Keeper 0.05% (farming ground prize, The Iron Heart); Heart Keeper 0.05% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.05% (farming ground prize, The Iron Heart); Rivet Thrower 0.05% (farming ground prize, Heart Core Chamber)
- `heart_uncommon_body` Heartforged Plate: Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `heart_uncommon_charm` Heartforged Charm: Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `heart_uncommon_feet` Heartforged Boots: Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `heart_uncommon_hands` Heartforged Gloves: Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `heart_uncommon_head` Heartforged Helm: Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `heart_uncommon_weapon` Heartforged Knuckles: Heart Guard 0.17% (farming ground prize, The Iron Heart); Heart Guard 0.17% (farming ground prize, Heart Core Chamber); Iron Sentry 0.17% (farming ground prize, The Iron Heart); Iron Sentry 0.17% (farming ground prize, Heart Core Chamber); Heart Keeper 0.17% (farming ground prize, The Iron Heart); Heart Keeper 0.17% (farming ground prize, Heart Core Chamber); Rivet Thrower 0.17% (farming ground prize, The Iron Heart); Rivet Thrower 0.17% (farming ground prize, Heart Core Chamber)
- `herbal_tonic` Herbal Tonic: The Founder's Engine guaranteed (personal tier, The Founder's Floor); The Tunnel Mother guaranteed (personal tier, The Great Drain); The Tunnel Mother guaranteed (personal tier, The Great Drain); The Iron Colossus guaranteed (personal tier, The Old Scrapyard); Subject Zero guaranteed (personal tier, The Sunken Reservoir); The Crucible King guaranteed (personal tier, The Crucible Pit); The Floodgate Marshal guaranteed (personal tier, Floodgate Barracks); The Iron Sovereign guaranteed (personal tier, Sovereign Vault); The Slag Titan guaranteed (personal tier, Slag Furnace); Subject Zero 80.0% (own loot table); The Iron Colossus 60.0% (own loot table); Reactor Overseer 54.8% (field elite, Reactor Underworks); Reactor Overseer 54.8% (field elite, Tank Hall); Commander Arthit, Reinstated 50.0% (own loot table); Subject Twelve, Relapsed 50.0% (own loot table); Unit K-7, Overdriven 50.0% (own loot table); Spillway Chief 50.0% (own loot table); The Wiroj Protocol 50.0% (own loot table); The Tunnel Mother 50.0% (own loot table); Vault Warden 41.8% (field elite, Coolant Vaults); Vault Warden 41.8% (field elite, Coolant Control Room); Foundry Boss 38.6% (field elite, Foundry Depths); Foundry Boss 38.6% (field elite, The Crucible); Heart Keeper 38.6% (field elite, The Iron Heart); Heart Keeper 38.6% (field elite, Heart Core Chamber); Reactor Overseer 23.2% (own loot table, Reactor Underworks); Reactor Overseer 23.2% (own loot table, Tank Hall); Vault Warden 16.5% (own loot table, Coolant Control Room); Vault Warden 16.5% (own loot table, Coolant Vaults); Foundry Boss 15.0% (own loot table, Foundry Depths); Foundry Boss 15.0% (own loot table, The Crucible); Heart Keeper 15.0% (own loot table, The Iron Heart); Heart Keeper 15.0% (own loot table, Heart Core Chamber); Underworks Brute 13.3% (field elite, Tank Hall); Reactor Tech 13.3% (field elite, Tank Hall); Tank Crawler 13.3% (field elite, Tank Hall); Tank Crawler 13.3% (field elite, Reactor Underworks); Reactor Tech 13.3% (field elite, Reactor Underworks); Underworks Brute 13.3% (field elite, Reactor Underworks); Vault Trooper 9.577% (field elite, Coolant Control Room); Vault Runner 9.577% (field elite, Coolant Vaults); Vault Runner 9.577% (field elite, Coolant Control Room); Coolant Drone 9.577% (field elite, Coolant Vaults); Coolant Drone 9.577% (field elite, Coolant Control Room); Vault Trooper 9.577% (field elite, Coolant Vaults); Slag Slinger 8.733% (field elite, The Crucible); Slag Slinger 8.733% (field elite, Foundry Depths); Heart Guard 8.733% (field elite, The Iron Heart); Foundry Hand 8.733% (field elite, The Crucible); Heart Guard 8.733% (field elite, Heart Core Chamber); Furnace Hauler 8.733% (field elite, Foundry Depths); Iron Sentry 8.733% (field elite, The Iron Heart); Foundry Hand 8.733% (field elite, Foundry Depths); Iron Sentry 8.733% (field elite, Heart Core Chamber); Furnace Hauler 8.733% (field elite, The Crucible); Rivet Thrower 8.733% (field elite, The Iron Heart); Rivet Thrower 8.733% (field elite, Heart Core Chamber); Tank Crawler 4.65% (own loot table, Tank Hall); Tank Crawler 4.65% (own loot table, Reactor Underworks); Underworks Brute 4.65% (own loot table, Reactor Underworks); Underworks Brute 4.65% (own loot table, Tank Hall); Reactor Tech 4.65% (own loot table, Reactor Underworks); Reactor Tech 4.65% (own loot table, Tank Hall); Vault Trooper 3.3% (own loot table, Coolant Vaults); Coolant Drone 3.3% (own loot table, Coolant Control Room); Vault Runner 3.3% (own loot table, Coolant Control Room); Vault Runner 3.3% (own loot table, Coolant Vaults); Vault Trooper 3.3% (own loot table, Coolant Control Room); Coolant Drone 3.3% (own loot table, Coolant Vaults); Heart Guard 3.0% (own loot table, Heart Core Chamber); Heart Guard 3.0% (own loot table, The Iron Heart); Slag Slinger 3.0% (own loot table, The Crucible); Slag Slinger 3.0% (own loot table, Foundry Depths); Furnace Hauler 3.0% (own loot table, Foundry Depths); Foundry Hand 3.0% (own loot table, The Crucible); Furnace Hauler 3.0% (own loot table, The Crucible); Foundry Hand 3.0% (own loot table, Foundry Depths); Rivet Thrower 3.0% (own loot table, The Iron Heart); Iron Sentry 3.0% (own loot table, The Iron Heart); Rivet Thrower 3.0% (own loot table, Heart Core Chamber); Iron Sentry 3.0% (own loot table, Heart Core Chamber); shop Ama's Kitchen, 110 coins; quest "Unit K-7"; quest "The Ring"; quest "Big Sak"; quest "Subject 12"; quest "Commander Arthit"; quest "The Walkway"
- `ice_crown` Ice Crown: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `inspectors_gloves` Inspector's Gloves: quest "The Chief"
- `insulated_gauntlets` Insulated Gauntlets: Hybrid Brute 3.0% (own loot table); Patrol Unit 0.67% (farming ground prize, Core Overflow); Facility Trooper 0.67% (farming ground prize, Core Overflow); Core Sentinel 0.67% (farming ground prize, Core Overflow); Hazmat Sprayer 0.4% (farming ground prize, Core Spillway); Hazmat Sprayer 0.4% (farming ground prize, Spillway Gatehouse); Facility Trooper 0.4% (farming ground prize, Core Spillway); Facility Trooper 0.4% (farming ground prize, Spillway Gatehouse); Core Sentinel 0.4% (farming ground prize, Core Spillway); Core Sentinel 0.4% (farming ground prize, Spillway Gatehouse)
- `insulated_gloves` Insulated Gloves: Hazmat Sprayer 6.341% (field elite, Plant Outskirts); Hazmat Sprayer 5.564% (field elite, Facility Annex); Hazmat Sprayer 5.564% (field elite, Core Spillway); Hazmat Sprayer 5.564% (field elite, Spillway Gatehouse); Hazmat Sprayer 3.0% (own loot table); Hazmat Sprayer 2.16% (own loot table, Plant Outskirts); Hazmat Sprayer 1.89% (own loot table, Facility Annex); Hazmat Sprayer 1.89% (own loot table, Core Spillway); Hazmat Sprayer 1.89% (own loot table, Spillway Gatehouse); Plant Guard 0.4% (farming ground prize, Plant Outskirts); Hazmat Sprayer 0.4% (farming ground prize, Plant Outskirts); Patrol Unit 0.4% (farming ground prize, Plant Outskirts)
- `iron_helm` Iron Helm: Refinery Enforcer 38.6% (field elite, Rail Sidings); Refinery Enforcer 15.0% (own loot table); Refinery Enforcer 15.0% (own loot table, Rail Sidings); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `iron_legacy` The Iron Legacy: Subject Zero 3.0% (kill reward, The Sunken Reservoir); Subject Zero 1.0% (personal tier, The Sunken Reservoir)
- `iron_legacy_relic` Iron Legacy Relic: The Furnace Baron 3.0% (boss's own list); Commander Arthit 3.0% (boss's own list); Director Wiroj 3.0% (boss's own list)
- `iron_wraps` Iron Wraps: Smog Warden 72.5% (field elite, Saltmarket Backlots); Smog Warden 35.0% (own loot table); Smog Warden 35.0% (own loot table, Saltmarket Backlots); Smogling 0.6% (farming ground prize, Saltmarket Backlots); Tar Rat 0.6% (farming ground prize, Saltmarket Backlots); Pipe Brute 0.6% (farming ground prize, Saltmarket Backlots); Smog Warden 0.6% (farming ground prize, Saltmarket Backlots); Dock Thug 0.6% (farming ground prize, Rail Sidings); Rail Bruiser 0.6% (farming ground prize, Rail Sidings); Night Market Punk 0.6% (farming ground prize, Rail Sidings); Refinery Enforcer 0.6% (farming ground prize, Rail Sidings); Bottle Thrower 0.6% (farming ground prize, Saltmarket Backlots)
- `jade_charm` Jade Charm: The Furnace Baron 20.0% (own loot table); Dock Thug 3.0% (field elite, Rail Sidings); Rail Bruiser 3.0% (field elite, Rail Sidings); Night Market Punk 3.0% (field elite, Rail Sidings); Refinery Enforcer 3.0% (field elite, Rail Sidings); quest "The Furnace Baron"
- `jewelled_crown` Jewelled Crown: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `k7_core_plate` K-7 Core Plate: Unit K-7 6.0% (own loot table)
- `k7_plating` K7 Plating: Unit K-7 20.0% (own loot table); Network Runner 3.0% (field elite, Network Backrooms); Network Enforcer 3.0% (field elite, Network Backrooms); Ring Fighter 3.0% (field elite, Network Backrooms)
- `k7_reactor_cell` K-7 Reactor Cell: Unit K-7 25.0% (boss's own list)
- `kenjis_lucky_charm` Kenji's Lucky Charm: quest "The Ring"
- `kevlar_jacket` Kevlar Jacket: Network Enforcer 6.513% (field elite, Network Backrooms); Network Enforcer 3.0% (own loot table); Network Enforcer 2.22% (own loot table, Network Backrooms); Network Runner 0.4% (farming ground prize, Network Backrooms); Network Enforcer 0.4% (farming ground prize, Network Backrooms); Ring Fighter 0.4% (farming ground prize, Network Backrooms)
- `lab_boots` Lab Boots: Patrol Unit 6.341% (field elite, Plant Outskirts); Patrol Unit 5.564% (field elite, Facility Annex); Patrol Unit 5.043% (field elite, Core Overflow); Patrol Unit 3.0% (own loot table); Patrol Unit 2.16% (own loot table, Plant Outskirts); Patrol Unit 1.89% (own loot table, Facility Annex); Patrol Unit 1.71% (own loot table, Core Overflow); Plant Guard 0.4% (farming ground prize, Plant Outskirts); Hazmat Sprayer 0.4% (farming ground prize, Plant Outskirts); Patrol Unit 0.4% (farming ground prize, Plant Outskirts)
- `leks_lab_boots` Lek's Lab Boots: quest "Subject 12"
- `lion_king_crown` Lion King's Crown: The Sludge Foreman 0.02% (catalog drop table); The Furnace Baron 0.02% (catalog drop table); The Pit Champion 0.02% (catalog drop table); Harbourmaster Chen 0.02% (catalog drop table); Security Chief Nattapong 0.02% (catalog drop table); Unit K-7 0.02% (catalog drop table); The Ringmaster 0.02% (catalog drop table); Big Sak 0.02% (catalog drop table); Subject 12 0.02% (catalog drop table); Commander Arthit 0.02% (catalog drop table); Director Wiroj 0.02% (catalog drop table); Commander Arthit, Reinstated 0.02% (catalog drop table); Subject Twelve, Relapsed 0.02% (catalog drop table); Unit K-7, Overdriven 0.02% (catalog drop table); Spillway Chief 0.02% (catalog drop table); The Wiroj Protocol 0.02% (catalog drop table)
- `lucky_coin` Lucky Coin: Tar Rat 14.3% (field elite, Saltmarket Backlots); Tar Rat 5.0% (own loot table); Tar Rat 5.0% (own loot table, Saltmarket Backlots); Smogling 0.4% (farming ground prize, Saltmarket Backlots); Tar Rat 0.4% (farming ground prize, Saltmarket Backlots); Pipe Brute 0.4% (farming ground prize, Saltmarket Backlots); Smog Warden 0.4% (farming ground prize, Saltmarket Backlots); Bottle Thrower 0.4% (farming ground prize, Saltmarket Backlots); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `marshal_greatcoat` Marshal's Greatcoat: The Floodgate Marshal 9.0% (kill reward, Floodgate Barracks); The Floodgate Marshal 3.0% (personal tier, Floodgate Barracks)
- `marshal_sabatons` Marshal's Sabatons: The Floodgate Marshal 9.0% (kill reward, Floodgate Barracks); The Floodgate Marshal 3.0% (personal tier, Floodgate Barracks)
- `marshal_visor` Marshal's Floodlight Visor: The Floodgate Marshal 9.0% (kill reward, Floodgate Barracks); The Floodgate Marshal 3.0% (personal tier, Floodgate Barracks)
- `midnight_wizard_hat` Midnight Wizard Hat: Unit K-7 1.395% (catalog drop table); Security Chief Nattapong 1.395% (catalog drop table); Subject Twelve, Relapsed 1.395% (catalog drop table); Harbourmaster Chen 1.395% (catalog drop table); Commander Arthit, Reinstated 1.395% (catalog drop table); The Ringmaster 1.395% (catalog drop table); Unit K-7, Overdriven 1.395% (catalog drop table); The Pit Champion 1.395% (catalog drop table); Big Sak 1.395% (catalog drop table); The Furnace Baron 1.395% (catalog drop table); Spillway Chief 1.395% (catalog drop table); The Wiroj Protocol 1.395% (catalog drop table); The Sludge Foreman 1.395% (catalog drop table); Subject 12 1.395% (catalog drop table); Commander Arthit 1.395% (catalog drop table); Director Wiroj 1.395% (catalog drop table); Vault Warden 0.011% (catalog drop table); Coolant Drone 0.011% (catalog drop table); Vault Trooper 0.011% (catalog drop table); Underworks Brute 0.011% (catalog drop table); Reactor Tech 0.011% (catalog drop table); Reactor Overseer 0.011% (catalog drop table); Foundry Hand 0.011% (catalog drop table); Slag Slinger 0.011% (catalog drop table); Foundry Boss 0.011% (catalog drop table); Heart Guard 0.011% (catalog drop table); Iron Sentry 0.011% (catalog drop table); Heart Keeper 0.011% (catalog drop table); Vault Runner 0.011% (catalog drop table); Tank Crawler 0.011% (catalog drop table); Furnace Hauler 0.011% (catalog drop table); Rivet Thrower 0.011% (catalog drop table); Smogling 0.011% (catalog drop table); Tar Rat 0.011% (catalog drop table); Pipe Brute 0.011% (catalog drop table); Smog Warden 0.011% (catalog drop table); Dock Thug 0.011% (catalog drop table); Rail Bruiser 0.011% (catalog drop table); Night Market Punk 0.011% (catalog drop table); Refinery Enforcer 0.011% (catalog drop table); Bottle Thrower 0.011% (catalog drop table); Stevedore 0.011% (catalog drop table); Port Guard 0.011% (catalog drop table); Dock Slinger 0.011% (catalog drop table); Plant Guard 0.011% (catalog drop table); Hazmat Sprayer 0.011% (catalog drop table); Patrol Unit 0.011% (catalog drop table); Network Runner 0.011% (catalog drop table); Network Enforcer 0.011% (catalog drop table); Ring Fighter 0.011% (catalog drop table); Facility Trooper 0.011% (catalog drop table); Riot Trooper 0.011% (catalog drop table); Hybrid Worker 0.011% (catalog drop table); Core Sentinel 0.011% (catalog drop table); Hybrid Brute 0.011% (catalog drop table)
- `mineral_azure` Azure Mineral: Harbourmaster Chen 15.0% (boss's own list); The Ringmaster 15.0% (boss's own list); Big Sak 15.0% (boss's own list); Unit K-7 11.6% (catalog drop table); Security Chief Nattapong 11.6% (catalog drop table); Commander Arthit, Reinstated 11.6% (catalog drop table); Subject Twelve, Relapsed 11.6% (catalog drop table); The Ringmaster 11.6% (catalog drop table); Harbourmaster Chen 11.6% (catalog drop table); Big Sak 11.6% (catalog drop table); Unit K-7, Overdriven 11.6% (catalog drop table); The Pit Champion 11.6% (catalog drop table); The Furnace Baron 11.6% (catalog drop table); Spillway Chief 11.6% (catalog drop table); The Wiroj Protocol 11.6% (catalog drop table); The Sludge Foreman 11.6% (catalog drop table); Subject 12 11.6% (catalog drop table); Commander Arthit 11.6% (catalog drop table); Director Wiroj 11.6% (catalog drop table); Vault Warden 0.144% (catalog drop table); Coolant Drone 0.144% (catalog drop table); Vault Trooper 0.144% (catalog drop table); Underworks Brute 0.144% (catalog drop table); Reactor Tech 0.144% (catalog drop table); Reactor Overseer 0.144% (catalog drop table); Foundry Hand 0.144% (catalog drop table); Slag Slinger 0.144% (catalog drop table); Foundry Boss 0.144% (catalog drop table); Heart Guard 0.144% (catalog drop table); Iron Sentry 0.144% (catalog drop table); Heart Keeper 0.144% (catalog drop table); Vault Runner 0.144% (catalog drop table); Tank Crawler 0.144% (catalog drop table); Furnace Hauler 0.144% (catalog drop table); Rivet Thrower 0.144% (catalog drop table); Smogling 0.144% (catalog drop table); Tar Rat 0.144% (catalog drop table); Pipe Brute 0.144% (catalog drop table); Smog Warden 0.144% (catalog drop table); Dock Thug 0.144% (catalog drop table); Rail Bruiser 0.144% (catalog drop table); Night Market Punk 0.144% (catalog drop table); Refinery Enforcer 0.144% (catalog drop table); Bottle Thrower 0.144% (catalog drop table); Stevedore 0.144% (catalog drop table); Port Guard 0.144% (catalog drop table); Dock Slinger 0.144% (catalog drop table); Plant Guard 0.144% (catalog drop table); Hazmat Sprayer 0.144% (catalog drop table); Patrol Unit 0.144% (catalog drop table); Network Runner 0.144% (catalog drop table); Network Enforcer 0.144% (catalog drop table); Ring Fighter 0.144% (catalog drop table); Facility Trooper 0.144% (catalog drop table); Riot Trooper 0.144% (catalog drop table); Hybrid Worker 0.144% (catalog drop table); Core Sentinel 0.144% (catalog drop table); Hybrid Brute 0.144% (catalog drop table)
- `mineral_crimson` Crimson Special Mineral: Subject 12 1.0% (boss's own list); The Wiroj Protocol 0.12% (catalog drop table); Spillway Chief 0.12% (catalog drop table); Unit K-7, Overdriven 0.12% (catalog drop table); Subject Twelve, Relapsed 0.12% (catalog drop table); Commander Arthit, Reinstated 0.12% (catalog drop table); Director Wiroj 0.12% (catalog drop table); Commander Arthit 0.12% (catalog drop table); Subject 12 0.12% (catalog drop table); Big Sak 0.12% (catalog drop table); The Ringmaster 0.12% (catalog drop table); Unit K-7 0.12% (catalog drop table); Security Chief Nattapong 0.12% (catalog drop table); Harbourmaster Chen 0.12% (catalog drop table); The Pit Champion 0.12% (catalog drop table); The Furnace Baron 0.12% (catalog drop table); The Sludge Foreman 0.12% (catalog drop table)
- `mineral_gilded` Gilded Mineral: Commander Arthit 10.0% (boss's own list); Unit K-7 10.0% (boss's own list); Director Wiroj 2.859% (catalog drop table); Commander Arthit 2.859% (catalog drop table); Subject 12 2.859% (catalog drop table); Big Sak 2.859% (catalog drop table); The Ringmaster 2.859% (catalog drop table); Commander Arthit, Reinstated 2.859% (catalog drop table); Unit K-7 2.859% (catalog drop table); Security Chief Nattapong 2.859% (catalog drop table); Subject Twelve, Relapsed 2.859% (catalog drop table); Harbourmaster Chen 2.859% (catalog drop table); Unit K-7, Overdriven 2.859% (catalog drop table); The Pit Champion 2.859% (catalog drop table); The Furnace Baron 2.859% (catalog drop table); The Sludge Foreman 2.859% (catalog drop table); The Wiroj Protocol 2.859% (catalog drop table); Spillway Chief 2.859% (catalog drop table); Rivet Thrower 0.016% (catalog drop table); Furnace Hauler 0.016% (catalog drop table); Tank Crawler 0.016% (catalog drop table); Vault Runner 0.016% (catalog drop table); Vault Trooper 0.016% (catalog drop table); Coolant Drone 0.016% (catalog drop table); Vault Warden 0.016% (catalog drop table); Underworks Brute 0.016% (catalog drop table); Reactor Tech 0.016% (catalog drop table); Heart Keeper 0.016% (catalog drop table); Iron Sentry 0.016% (catalog drop table); Reactor Overseer 0.016% (catalog drop table); Heart Guard 0.016% (catalog drop table); Foundry Hand 0.016% (catalog drop table); Slag Slinger 0.016% (catalog drop table); Foundry Boss 0.016% (catalog drop table); Smogling 0.016% (catalog drop table); Tar Rat 0.016% (catalog drop table); Pipe Brute 0.016% (catalog drop table); Smog Warden 0.016% (catalog drop table); Dock Thug 0.016% (catalog drop table); Rail Bruiser 0.016% (catalog drop table); Night Market Punk 0.016% (catalog drop table); Refinery Enforcer 0.016% (catalog drop table); Bottle Thrower 0.016% (catalog drop table); Stevedore 0.016% (catalog drop table); Port Guard 0.016% (catalog drop table); Dock Slinger 0.016% (catalog drop table); Plant Guard 0.016% (catalog drop table); Hazmat Sprayer 0.016% (catalog drop table); Patrol Unit 0.016% (catalog drop table); Network Runner 0.016% (catalog drop table); Network Enforcer 0.016% (catalog drop table); Ring Fighter 0.016% (catalog drop table); Facility Trooper 0.016% (catalog drop table); Riot Trooper 0.016% (catalog drop table); Hybrid Worker 0.016% (catalog drop table); Core Sentinel 0.016% (catalog drop table); Hybrid Brute 0.016% (catalog drop table)
- `mineral_rare` Rare Mineral: Unit K-7 10.2% (catalog drop table); Security Chief Nattapong 10.2% (catalog drop table); Subject Twelve, Relapsed 10.2% (catalog drop table); Harbourmaster Chen 10.2% (catalog drop table); Commander Arthit, Reinstated 10.2% (catalog drop table); The Ringmaster 10.2% (catalog drop table); Unit K-7, Overdriven 10.2% (catalog drop table); The Pit Champion 10.2% (catalog drop table); Big Sak 10.2% (catalog drop table); The Furnace Baron 10.2% (catalog drop table); Spillway Chief 10.2% (catalog drop table); The Wiroj Protocol 10.2% (catalog drop table); The Sludge Foreman 10.2% (catalog drop table); Subject 12 10.2% (catalog drop table); Commander Arthit 10.2% (catalog drop table); Director Wiroj 10.2% (catalog drop table); Vault Warden 0.32% (catalog drop table); Coolant Drone 0.32% (catalog drop table); Vault Trooper 0.32% (catalog drop table); Underworks Brute 0.32% (catalog drop table); Reactor Tech 0.32% (catalog drop table); Reactor Overseer 0.32% (catalog drop table); Foundry Hand 0.32% (catalog drop table); Slag Slinger 0.32% (catalog drop table); Foundry Boss 0.32% (catalog drop table); Heart Guard 0.32% (catalog drop table); Iron Sentry 0.32% (catalog drop table); Heart Keeper 0.32% (catalog drop table); Vault Runner 0.32% (catalog drop table); Tank Crawler 0.32% (catalog drop table); Furnace Hauler 0.32% (catalog drop table); Rivet Thrower 0.32% (catalog drop table); Smogling 0.32% (catalog drop table); Tar Rat 0.32% (catalog drop table); Pipe Brute 0.32% (catalog drop table); Smog Warden 0.32% (catalog drop table); Dock Thug 0.32% (catalog drop table); Rail Bruiser 0.32% (catalog drop table); Night Market Punk 0.32% (catalog drop table); Refinery Enforcer 0.32% (catalog drop table); Bottle Thrower 0.32% (catalog drop table); Stevedore 0.32% (catalog drop table); Port Guard 0.32% (catalog drop table); Dock Slinger 0.32% (catalog drop table); Plant Guard 0.32% (catalog drop table); Hazmat Sprayer 0.32% (catalog drop table); Patrol Unit 0.32% (catalog drop table); Network Runner 0.32% (catalog drop table); Network Enforcer 0.32% (catalog drop table); Ring Fighter 0.32% (catalog drop table); Facility Trooper 0.32% (catalog drop table); Riot Trooper 0.32% (catalog drop table); Hybrid Worker 0.32% (catalog drop table); Core Sentinel 0.32% (catalog drop table); Hybrid Brute 0.32% (catalog drop table)
- `money_trail` Money Trail: quest "Big Sak"
- `mothers_fang` Mother's Fang: The Tunnel Mother 30.0% (personal tier, The Great Drain); The Tunnel Mother 15.0% (kill reward, The Great Drain); The Tunnel Mother 12.0% (personal tier, The Great Drain); The Tunnel Mother 8.0% (personal tier, The Great Drain)
- `mothers_heart` Mother's Heart: The Tunnel Mother 30.0% (personal tier, The Great Drain); The Tunnel Mother 15.0% (kill reward, The Great Drain); The Tunnel Mother 12.0% (personal tier, The Great Drain); The Tunnel Mother 8.0% (personal tier, The Great Drain)
- `night_market_jacket` Night Market Jacket: quest "The Pit"
- `night_shift_crowbar` Night Shift Crowbar: quest "Commander Arthit"
- `obsidian_crown` Obsidian Crown: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `odos_old_gloves` Odo's Old Gloves: quest "The Sludge Foreman"
- `ore_copper` Copper Ore: Unit K-7 11.6% (catalog drop table); Security Chief Nattapong 11.6% (catalog drop table); Subject Twelve, Relapsed 11.6% (catalog drop table); Harbourmaster Chen 11.6% (catalog drop table); Commander Arthit, Reinstated 11.6% (catalog drop table); The Ringmaster 11.6% (catalog drop table); Unit K-7, Overdriven 11.6% (catalog drop table); The Pit Champion 11.6% (catalog drop table); Big Sak 11.6% (catalog drop table); The Furnace Baron 11.6% (catalog drop table); Spillway Chief 11.6% (catalog drop table); The Wiroj Protocol 11.6% (catalog drop table); The Sludge Foreman 11.6% (catalog drop table); Subject 12 11.6% (catalog drop table); Commander Arthit 11.6% (catalog drop table); Director Wiroj 11.6% (catalog drop table); Vault Warden 1.2% (catalog drop table); Coolant Drone 1.2% (catalog drop table); Vault Trooper 1.2% (catalog drop table); Underworks Brute 1.2% (catalog drop table); Reactor Tech 1.2% (catalog drop table); Reactor Overseer 1.2% (catalog drop table); Foundry Hand 1.2% (catalog drop table); Slag Slinger 1.2% (catalog drop table); Foundry Boss 1.2% (catalog drop table); Heart Guard 1.2% (catalog drop table); Iron Sentry 1.2% (catalog drop table); Heart Keeper 1.2% (catalog drop table); Vault Runner 1.2% (catalog drop table); Tank Crawler 1.2% (catalog drop table); Furnace Hauler 1.2% (catalog drop table); Rivet Thrower 1.2% (catalog drop table); Smogling 1.2% (catalog drop table); Tar Rat 1.2% (catalog drop table); Pipe Brute 1.2% (catalog drop table); Smog Warden 1.2% (catalog drop table); Dock Thug 1.2% (catalog drop table); Rail Bruiser 1.2% (catalog drop table); Night Market Punk 1.2% (catalog drop table); Refinery Enforcer 1.2% (catalog drop table); Bottle Thrower 1.2% (catalog drop table); Stevedore 1.2% (catalog drop table); Port Guard 1.2% (catalog drop table); Dock Slinger 1.2% (catalog drop table); Plant Guard 1.2% (catalog drop table); Hazmat Sprayer 1.2% (catalog drop table); Patrol Unit 1.2% (catalog drop table); Network Runner 1.2% (catalog drop table); Network Enforcer 1.2% (catalog drop table); Ring Fighter 1.2% (catalog drop table); Facility Trooper 1.2% (catalog drop table); Riot Trooper 1.2% (catalog drop table); Hybrid Worker 1.2% (catalog drop table); Core Sentinel 1.2% (catalog drop table); Hybrid Brute 1.2% (catalog drop table)
- `ore_iron` Iron Ore: Unit K-7 11.6% (catalog drop table); Security Chief Nattapong 11.6% (catalog drop table); Subject Twelve, Relapsed 11.6% (catalog drop table); Harbourmaster Chen 11.6% (catalog drop table); Commander Arthit, Reinstated 11.6% (catalog drop table); The Ringmaster 11.6% (catalog drop table); Unit K-7, Overdriven 11.6% (catalog drop table); The Pit Champion 11.6% (catalog drop table); Big Sak 11.6% (catalog drop table); The Furnace Baron 11.6% (catalog drop table); Spillway Chief 11.6% (catalog drop table); The Wiroj Protocol 11.6% (catalog drop table); The Sludge Foreman 11.6% (catalog drop table); Subject 12 11.6% (catalog drop table); Commander Arthit 11.6% (catalog drop table); Director Wiroj 11.6% (catalog drop table); Vault Warden 1.2% (catalog drop table); Coolant Drone 1.2% (catalog drop table); Vault Trooper 1.2% (catalog drop table); Underworks Brute 1.2% (catalog drop table); Reactor Tech 1.2% (catalog drop table); Reactor Overseer 1.2% (catalog drop table); Foundry Hand 1.2% (catalog drop table); Slag Slinger 1.2% (catalog drop table); Foundry Boss 1.2% (catalog drop table); Heart Guard 1.2% (catalog drop table); Iron Sentry 1.2% (catalog drop table); Heart Keeper 1.2% (catalog drop table); Vault Runner 1.2% (catalog drop table); Tank Crawler 1.2% (catalog drop table); Furnace Hauler 1.2% (catalog drop table); Rivet Thrower 1.2% (catalog drop table); Smogling 1.2% (catalog drop table); Tar Rat 1.2% (catalog drop table); Pipe Brute 1.2% (catalog drop table); Smog Warden 1.2% (catalog drop table); Dock Thug 1.2% (catalog drop table); Rail Bruiser 1.2% (catalog drop table); Night Market Punk 1.2% (catalog drop table); Refinery Enforcer 1.2% (catalog drop table); Bottle Thrower 1.2% (catalog drop table); Stevedore 1.2% (catalog drop table); Port Guard 1.2% (catalog drop table); Dock Slinger 1.2% (catalog drop table); Plant Guard 1.2% (catalog drop table); Hazmat Sprayer 1.2% (catalog drop table); Patrol Unit 1.2% (catalog drop table); Network Runner 1.2% (catalog drop table); Network Enforcer 1.2% (catalog drop table); Ring Fighter 1.2% (catalog drop table); Facility Trooper 1.2% (catalog drop table); Riot Trooper 1.2% (catalog drop table); Hybrid Worker 1.2% (catalog drop table); Core Sentinel 1.2% (catalog drop table); Hybrid Brute 1.2% (catalog drop table)
- `ore_refined` Refined Ore: Unit K-7 10.2% (catalog drop table); Security Chief Nattapong 10.2% (catalog drop table); Subject Twelve, Relapsed 10.2% (catalog drop table); Harbourmaster Chen 10.2% (catalog drop table); Commander Arthit, Reinstated 10.2% (catalog drop table); The Ringmaster 10.2% (catalog drop table); Unit K-7, Overdriven 10.2% (catalog drop table); The Pit Champion 10.2% (catalog drop table); Big Sak 10.2% (catalog drop table); The Furnace Baron 10.2% (catalog drop table); Spillway Chief 10.2% (catalog drop table); The Wiroj Protocol 10.2% (catalog drop table); The Sludge Foreman 10.2% (catalog drop table); Subject 12 10.2% (catalog drop table); Commander Arthit 10.2% (catalog drop table); Director Wiroj 10.2% (catalog drop table); Vault Warden 0.32% (catalog drop table); Coolant Drone 0.32% (catalog drop table); Vault Trooper 0.32% (catalog drop table); Underworks Brute 0.32% (catalog drop table); Reactor Tech 0.32% (catalog drop table); Reactor Overseer 0.32% (catalog drop table); Foundry Hand 0.32% (catalog drop table); Slag Slinger 0.32% (catalog drop table); Foundry Boss 0.32% (catalog drop table); Heart Guard 0.32% (catalog drop table); Iron Sentry 0.32% (catalog drop table); Heart Keeper 0.32% (catalog drop table); Vault Runner 0.32% (catalog drop table); Tank Crawler 0.32% (catalog drop table); Furnace Hauler 0.32% (catalog drop table); Rivet Thrower 0.32% (catalog drop table); Smogling 0.32% (catalog drop table); Tar Rat 0.32% (catalog drop table); Pipe Brute 0.32% (catalog drop table); Smog Warden 0.32% (catalog drop table); Dock Thug 0.32% (catalog drop table); Rail Bruiser 0.32% (catalog drop table); Night Market Punk 0.32% (catalog drop table); Refinery Enforcer 0.32% (catalog drop table); Bottle Thrower 0.32% (catalog drop table); Stevedore 0.32% (catalog drop table); Port Guard 0.32% (catalog drop table); Dock Slinger 0.32% (catalog drop table); Plant Guard 0.32% (catalog drop table); Hazmat Sprayer 0.32% (catalog drop table); Patrol Unit 0.32% (catalog drop table); Network Runner 0.32% (catalog drop table); Network Enforcer 0.32% (catalog drop table); Ring Fighter 0.32% (catalog drop table); Facility Trooper 0.32% (catalog drop table); Riot Trooper 0.32% (catalog drop table); Hybrid Worker 0.32% (catalog drop table); Core Sentinel 0.32% (catalog drop table); Hybrid Brute 0.32% (catalog drop table)
- `padded_street_jacket` Padded Street Jacket: Unit K-7 6.878% (catalog drop table); Security Chief Nattapong 6.878% (catalog drop table); Subject Twelve, Relapsed 6.878% (catalog drop table); Harbourmaster Chen 6.878% (catalog drop table); Commander Arthit, Reinstated 6.878% (catalog drop table); The Ringmaster 6.878% (catalog drop table); Unit K-7, Overdriven 6.878% (catalog drop table); The Pit Champion 6.878% (catalog drop table); Big Sak 6.878% (catalog drop table); The Furnace Baron 6.878% (catalog drop table); Spillway Chief 6.878% (catalog drop table); The Wiroj Protocol 6.878% (catalog drop table); The Sludge Foreman 6.878% (catalog drop table); Subject 12 6.878% (catalog drop table); Commander Arthit 6.878% (catalog drop table); Director Wiroj 6.878% (catalog drop table); Vault Warden 0.053% (catalog drop table); Coolant Drone 0.053% (catalog drop table); Vault Trooper 0.053% (catalog drop table); Underworks Brute 0.053% (catalog drop table); Reactor Tech 0.053% (catalog drop table); Reactor Overseer 0.053% (catalog drop table); Foundry Hand 0.053% (catalog drop table); Slag Slinger 0.053% (catalog drop table); Foundry Boss 0.053% (catalog drop table); Heart Guard 0.053% (catalog drop table); Iron Sentry 0.053% (catalog drop table); Heart Keeper 0.053% (catalog drop table); Vault Runner 0.053% (catalog drop table); Tank Crawler 0.053% (catalog drop table); Furnace Hauler 0.053% (catalog drop table); Rivet Thrower 0.053% (catalog drop table); Smogling 0.053% (catalog drop table); Tar Rat 0.053% (catalog drop table); Pipe Brute 0.053% (catalog drop table); Smog Warden 0.053% (catalog drop table); Dock Thug 0.053% (catalog drop table); Rail Bruiser 0.053% (catalog drop table); Night Market Punk 0.053% (catalog drop table); Refinery Enforcer 0.053% (catalog drop table); Bottle Thrower 0.053% (catalog drop table); Stevedore 0.053% (catalog drop table); Port Guard 0.053% (catalog drop table); Dock Slinger 0.053% (catalog drop table); Plant Guard 0.053% (catalog drop table); Hazmat Sprayer 0.053% (catalog drop table); Patrol Unit 0.053% (catalog drop table); Network Runner 0.053% (catalog drop table); Network Enforcer 0.053% (catalog drop table); Ring Fighter 0.053% (catalog drop table); Facility Trooper 0.053% (catalog drop table); Riot Trooper 0.053% (catalog drop table); Hybrid Worker 0.053% (catalog drop table); Core Sentinel 0.053% (catalog drop table); Hybrid Brute 0.053% (catalog drop table)
- `padded_vest` Padded Vest: shop Kenji's Gear Stall, 45 coins
- `patched_street_cap` Patched Street Cap: Unit K-7 2.649% (catalog drop table); Security Chief Nattapong 2.649% (catalog drop table); Subject Twelve, Relapsed 2.649% (catalog drop table); Harbourmaster Chen 2.649% (catalog drop table); Commander Arthit, Reinstated 2.649% (catalog drop table); The Ringmaster 2.649% (catalog drop table); Unit K-7, Overdriven 2.649% (catalog drop table); The Pit Champion 2.649% (catalog drop table); Big Sak 2.649% (catalog drop table); The Furnace Baron 2.649% (catalog drop table); Spillway Chief 2.649% (catalog drop table); The Wiroj Protocol 2.649% (catalog drop table); The Sludge Foreman 2.649% (catalog drop table); Subject 12 2.649% (catalog drop table); Commander Arthit 2.649% (catalog drop table); Director Wiroj 2.649% (catalog drop table); Vault Warden 0.068% (catalog drop table); Coolant Drone 0.068% (catalog drop table); Vault Trooper 0.068% (catalog drop table); Underworks Brute 0.068% (catalog drop table); Reactor Tech 0.068% (catalog drop table); Reactor Overseer 0.068% (catalog drop table); Foundry Hand 0.068% (catalog drop table); Slag Slinger 0.068% (catalog drop table); Foundry Boss 0.068% (catalog drop table); Heart Guard 0.068% (catalog drop table); Iron Sentry 0.068% (catalog drop table); Heart Keeper 0.068% (catalog drop table); Vault Runner 0.068% (catalog drop table); Tank Crawler 0.068% (catalog drop table); Furnace Hauler 0.068% (catalog drop table); Rivet Thrower 0.068% (catalog drop table); Smogling 0.068% (catalog drop table); Tar Rat 0.068% (catalog drop table); Pipe Brute 0.068% (catalog drop table); Smog Warden 0.068% (catalog drop table); Dock Thug 0.068% (catalog drop table); Rail Bruiser 0.068% (catalog drop table); Night Market Punk 0.068% (catalog drop table); Refinery Enforcer 0.068% (catalog drop table); Bottle Thrower 0.068% (catalog drop table); Stevedore 0.068% (catalog drop table); Port Guard 0.068% (catalog drop table); Dock Slinger 0.068% (catalog drop table); Plant Guard 0.068% (catalog drop table); Hazmat Sprayer 0.068% (catalog drop table); Patrol Unit 0.068% (catalog drop table); Network Runner 0.068% (catalog drop table); Network Enforcer 0.068% (catalog drop table); Ring Fighter 0.068% (catalog drop table); Facility Trooper 0.068% (catalog drop table); Riot Trooper 0.068% (catalog drop table); Hybrid Worker 0.068% (catalog drop table); Core Sentinel 0.068% (catalog drop table); Hybrid Brute 0.068% (catalog drop table)
- `phoenix_feather_hat` Phoenix Feather Hat: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `phoenix_tiara` Phoenix Tiara: Unit K-7 0.137% (catalog drop table); Security Chief Nattapong 0.137% (catalog drop table); Subject Twelve, Relapsed 0.137% (catalog drop table); Harbourmaster Chen 0.137% (catalog drop table); Commander Arthit, Reinstated 0.137% (catalog drop table); The Ringmaster 0.137% (catalog drop table); Unit K-7, Overdriven 0.137% (catalog drop table); The Pit Champion 0.137% (catalog drop table); Big Sak 0.137% (catalog drop table); The Furnace Baron 0.137% (catalog drop table); Spillway Chief 0.137% (catalog drop table); The Wiroj Protocol 0.137% (catalog drop table); The Sludge Foreman 0.137% (catalog drop table); Subject 12 0.137% (catalog drop table); Commander Arthit 0.137% (catalog drop table); Director Wiroj 0.137% (catalog drop table); Vault Warden 0.00019% (catalog drop table); Coolant Drone 0.00019% (catalog drop table); Vault Trooper 0.00019% (catalog drop table); Underworks Brute 0.00019% (catalog drop table); Reactor Tech 0.00019% (catalog drop table); Reactor Overseer 0.00019% (catalog drop table); Foundry Hand 0.00019% (catalog drop table); Slag Slinger 0.00019% (catalog drop table); Foundry Boss 0.00019% (catalog drop table); Heart Guard 0.00019% (catalog drop table); Iron Sentry 0.00019% (catalog drop table); Heart Keeper 0.00019% (catalog drop table); Vault Runner 0.00019% (catalog drop table); Tank Crawler 0.00019% (catalog drop table); Furnace Hauler 0.00019% (catalog drop table); Rivet Thrower 0.00019% (catalog drop table); Smogling 0.00019% (catalog drop table); Tar Rat 0.00019% (catalog drop table); Pipe Brute 0.00019% (catalog drop table); Smog Warden 0.00019% (catalog drop table); Dock Thug 0.00019% (catalog drop table); Rail Bruiser 0.00019% (catalog drop table); Night Market Punk 0.00019% (catalog drop table); Refinery Enforcer 0.00019% (catalog drop table); Bottle Thrower 0.00019% (catalog drop table); Stevedore 0.00019% (catalog drop table); Port Guard 0.00019% (catalog drop table); Dock Slinger 0.00019% (catalog drop table); Plant Guard 0.00019% (catalog drop table); Hazmat Sprayer 0.00019% (catalog drop table); Patrol Unit 0.00019% (catalog drop table); Network Runner 0.00019% (catalog drop table); Network Enforcer 0.00019% (catalog drop table); Ring Fighter 0.00019% (catalog drop table); Facility Trooper 0.00019% (catalog drop table); Riot Trooper 0.00019% (catalog drop table); Hybrid Worker 0.00019% (catalog drop table); Core Sentinel 0.00019% (catalog drop table); Hybrid Brute 0.00019% (catalog drop table)
- `pims_field_vest` Pim's Field Vest: quest "Unit K-7"
- `piston_gauntlets` Piston Gauntlets: The Iron Colossus 8.0% (kill reward, The Old Scrapyard); The Iron Colossus 2.0% (personal tier, The Old Scrapyard)
- `plant_vest` Plant Security Vest: Plant Guard 6.341% (field elite, Plant Outskirts); Plant Guard 3.0% (own loot table); Plant Guard 2.16% (own loot table, Plant Outskirts); Plant Guard 0.4% (farming ground prize, Plant Outskirts); Hazmat Sprayer 0.4% (farming ground prize, Plant Outskirts); Patrol Unit 0.4% (farming ground prize, Plant Outskirts)
- `port_jacket` Port Authority Jacket: Port Guard 7.968% (field elite, Harbour Stacks); Port Guard 3.0% (own loot table); Port Guard 2.73% (own loot table, Harbour Stacks); Dock Thug 0.4% (farming ground prize, Harbour Stacks); Stevedore 0.4% (farming ground prize, Harbour Stacks); Port Guard 0.4% (farming ground prize, Harbour Stacks); Dock Slinger 0.4% (farming ground prize, Harbour Stacks)
- `reactor_plate` Reactor Plate: Core Sentinel 5.564% (field elite, Core Spillway); Core Sentinel 5.564% (field elite, Spillway Gatehouse); Core Sentinel 5.043% (field elite, Core Overflow); Core Sentinel 3.0% (own loot table); Core Sentinel 1.89% (own loot table, Core Spillway); Core Sentinel 1.89% (own loot table, Spillway Gatehouse); Core Sentinel 1.71% (own loot table, Core Overflow); Hazmat Sprayer 0.4% (farming ground prize, Core Spillway); Hazmat Sprayer 0.4% (farming ground prize, Spillway Gatehouse); Facility Trooper 0.4% (farming ground prize, Core Spillway); Facility Trooper 0.4% (farming ground prize, Spillway Gatehouse); Core Sentinel 0.4% (farming ground prize, Core Spillway); Core Sentinel 0.4% (farming ground prize, Spillway Gatehouse)
- `rebar_pipe` Rebar Pipe: Pipe Brute 22.1% (field elite, Saltmarket Backlots); Pipe Brute 8.0% (own loot table); Pipe Brute 8.0% (own loot table, Saltmarket Backlots); Smogling 0.4% (farming ground prize, Saltmarket Backlots); Tar Rat 0.4% (farming ground prize, Saltmarket Backlots); Pipe Brute 0.4% (farming ground prize, Saltmarket Backlots); Smog Warden 0.4% (farming ground prize, Saltmarket Backlots); Bottle Thrower 0.4% (farming ground prize, Saltmarket Backlots); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `refined_alloy` Refined Alloy: The Slag Titan guaranteed (personal tier, Slag Furnace); The Slag Titan guaranteed (personal tier, Slag Furnace); The Slag Titan guaranteed (personal tier, Slag Furnace); The Slag Titan guaranteed (personal tier, Slag Furnace); The Slag Titan guaranteed (own loot table); Unit K-7, Overdriven guaranteed (own loot table); Subject Twelve, Relapsed guaranteed (own loot table); Commander Arthit, Reinstated guaranteed (own loot table); Subject Zero guaranteed (kill reward, The Sunken Reservoir); Subject Zero guaranteed (personal tier, The Sunken Reservoir); Subject Zero guaranteed (personal tier, The Sunken Reservoir); Subject Zero guaranteed (personal tier, The Sunken Reservoir); Subject Zero guaranteed (personal tier, The Sunken Reservoir); Subject Zero guaranteed (own loot table); The Iron Colossus guaranteed (kill reward, The Old Scrapyard); The Iron Colossus guaranteed (personal tier, The Old Scrapyard); The Iron Colossus guaranteed (personal tier, The Old Scrapyard); The Iron Colossus guaranteed (personal tier, The Old Scrapyard); The Iron Colossus guaranteed (personal tier, The Old Scrapyard); The Iron Colossus guaranteed (own loot table); The Tunnel Mother guaranteed (kill reward, The Great Drain); The Tunnel Mother guaranteed (personal tier, The Great Drain); The Tunnel Mother guaranteed (personal tier, The Great Drain); The Tunnel Mother guaranteed (personal tier, The Great Drain); The Tunnel Mother guaranteed (personal tier, The Great Drain); The Tunnel Mother guaranteed (own loot table); Director Wiroj guaranteed (own loot table); The Founder's Engine guaranteed (kill reward, The Founder's Floor); The Founder's Engine guaranteed (personal tier, The Founder's Floor); The Founder's Engine guaranteed (personal tier, The Founder's Floor); The Founder's Engine guaranteed (personal tier, The Founder's Floor); The Founder's Engine guaranteed (personal tier, The Founder's Floor); The Founder's Engine guaranteed (own loot table); The Crucible King guaranteed (kill reward, The Crucible Pit); The Crucible King guaranteed (personal tier, The Crucible Pit); The Crucible King guaranteed (personal tier, The Crucible Pit); The Crucible King guaranteed (personal tier, The Crucible Pit); The Crucible King guaranteed (personal tier, The Crucible Pit); The Crucible King guaranteed (own loot table); The Floodgate Marshal guaranteed (kill reward, Floodgate Barracks); The Floodgate Marshal guaranteed (personal tier, Floodgate Barracks); The Floodgate Marshal guaranteed (personal tier, Floodgate Barracks); The Floodgate Marshal guaranteed (personal tier, Floodgate Barracks); The Floodgate Marshal guaranteed (personal tier, Floodgate Barracks); The Floodgate Marshal guaranteed (own loot table); The Wiroj Protocol guaranteed (own loot table); Spillway Chief guaranteed (own loot table); The Iron Sovereign guaranteed (kill reward, Sovereign Vault); The Iron Sovereign guaranteed (personal tier, Sovereign Vault); The Iron Sovereign guaranteed (personal tier, Sovereign Vault); The Iron Sovereign guaranteed (personal tier, Sovereign Vault); The Iron Sovereign guaranteed (personal tier, Sovereign Vault); The Iron Sovereign guaranteed (own loot table); The Slag Titan guaranteed (kill reward, Slag Furnace); The Ringmaster guaranteed (own loot table); Big Sak guaranteed (own loot table); Harbourmaster Chen guaranteed (own loot table); The Pit Champion guaranteed (own loot table); The Sludge Foreman guaranteed (own loot table); Commander Arthit guaranteed (own loot table); Subject 12 guaranteed (own loot table); Unit K-7 guaranteed (own loot table); Security Chief Nattapong guaranteed (own loot table); The Furnace Baron guaranteed (own loot table); Reactor Overseer 91.4% (field elite, Reactor Underworks); Reactor Overseer 91.4% (field elite, Tank Hall); Vault Warden 78.0% (field elite, Coolant Vaults); Vault Warden 78.0% (field elite, Coolant Control Room); Foundry Boss 73.8% (field elite, Foundry Depths); Foundry Boss 73.8% (field elite, The Crucible); Heart Keeper 73.8% (field elite, Heart Core Chamber); Heart Keeper 73.8% (field elite, The Iron Heart); Refinery Enforcer 65.7% (field elite, Rail Sidings); Smog Warden 57.8% (field elite, Saltmarket Backlots); Reactor Overseer 55.8% (own loot table, Tank Hall); Reactor Overseer 55.8% (own loot table, Reactor Underworks); Reactor Tech 54.8% (field elite, Tank Hall); Reactor Tech 54.8% (field elite, Reactor Underworks); Underworks Brute 54.8% (field elite, Tank Hall); Tank Crawler 54.8% (field elite, Reactor Underworks); Underworks Brute 54.8% (field elite, Reactor Underworks); Tank Crawler 54.8% (field elite, Tank Hall); Core Sentinel 46.7% (field elite, Core Spillway); Core Sentinel 46.7% (field elite, Spillway Gatehouse); Rivet Thrower 46.1% (field elite, The Iron Heart); Heart Guard 46.1% (field elite, The Iron Heart); Rivet Thrower 46.1% (field elite, Heart Core Chamber); Heart Guard 46.1% (field elite, Heart Core Chamber); Iron Sentry 46.1% (field elite, The Iron Heart); Iron Sentry 46.1% (field elite, Heart Core Chamber); Core Sentinel 43.0% (field elite, Core Overflow); Slag Slinger 42.4% (field elite, The Crucible); Slag Slinger 42.4% (field elite, Foundry Depths); Foundry Hand 42.4% (field elite, The Crucible); Foundry Hand 42.4% (field elite, Foundry Depths); Furnace Hauler 42.4% (field elite, Foundry Depths); Furnace Hauler 42.4% (field elite, The Crucible); Vault Warden 39.6% (own loot table, Coolant Control Room); Vault Warden 39.6% (own loot table, Coolant Vaults); Vault Runner 37.5% (field elite, Coolant Vaults); Vault Runner 37.5% (field elite, Coolant Control Room); Vault Trooper 37.5% (field elite, Coolant Vaults); Vault Trooper 37.5% (field elite, Coolant Control Room); Coolant Drone 37.5% (field elite, Coolant Vaults); Coolant Drone 37.5% (field elite, Coolant Control Room); Patrol Unit 37.3% (field elite, Plant Outskirts); Heart Keeper 36.0% (own loot table, The Iron Heart); Heart Keeper 36.0% (own loot table, Heart Core Chamber); Foundry Boss 36.0% (own loot table, The Crucible); Foundry Boss 36.0% (own loot table, Foundry Depths); Riot Trooper 33.2% (field elite, Facility Annex); Patrol Unit 33.2% (field elite, Facility Annex); Patrol Unit 30.4% (field elite, Core Overflow); Core Sentinel 30.0% (own loot table); Refinery Enforcer 30.0% (own loot table); Refinery Enforcer 30.0% (own loot table, Rail Sidings); Network Enforcer 29.7% (field elite, Network Backrooms); Ring Fighter 29.7% (field elite, Network Backrooms); Port Guard 29.3% (field elite, Harbour Stacks); Plant Guard 29.0% (field elite, Plant Outskirts); Facility Trooper 25.8% (field elite, Spillway Gatehouse); Facility Trooper 25.8% (field elite, Core Spillway); Facility Trooper 25.8% (field elite, Facility Annex); Smog Warden 25.0% (own loot table, Saltmarket Backlots); Smog Warden 25.0% (own loot table); Facility Trooper 23.5% (field elite, Core Overflow); Underworks Brute 23.2% (own loot table, Reactor Underworks); Tank Crawler 23.2% (own loot table, Tank Hall); Underworks Brute 23.2% (own loot table, Tank Hall); Tank Crawler 23.2% (own loot table, Reactor Underworks); Reactor Tech 23.2% (own loot table, Reactor Underworks); Reactor Tech 23.2% (own loot table, Tank Hall); Hybrid Brute 20.0% (own loot table); Riot Trooper 20.0% (own loot table); Patrol Unit 20.0% (own loot table); Core Sentinel 18.9% (own loot table, Spillway Gatehouse); Core Sentinel 18.9% (own loot table, Core Spillway); Rivet Thrower 18.6% (own loot table, Heart Core Chamber); Rivet Thrower 18.6% (own loot table, The Iron Heart); Iron Sentry 18.6% (own loot table, Heart Core Chamber); Iron Sentry 18.6% (own loot table, The Iron Heart); Heart Guard 18.6% (own loot table, Heart Core Chamber); Heart Guard 18.6% (own loot table, The Iron Heart); Core Sentinel 17.1% (own loot table, Core Overflow); Foundry Hand 16.8% (own loot table, Foundry Depths); Foundry Hand 16.8% (own loot table, The Crucible); Slag Slinger 16.8% (own loot table, Foundry Depths); Slag Slinger 16.8% (own loot table, The Crucible); Furnace Hauler 16.8% (own loot table, Foundry Depths); Furnace Hauler 16.8% (own loot table, The Crucible); Hybrid Worker 15.0% (own loot table); Ring Fighter 15.0% (own loot table); Plant Guard 15.0% (own loot table); Facility Trooper 15.0% (own loot table); Network Enforcer 15.0% (own loot table); Vault Runner 14.5% (own loot table, Coolant Vaults); Vault Runner 14.5% (own loot table, Coolant Control Room); Coolant Drone 14.5% (own loot table, Coolant Control Room); Vault Trooper 14.5% (own loot table, Coolant Vaults); Vault Trooper 14.5% (own loot table, Coolant Control Room); Coolant Drone 14.5% (own loot table, Coolant Vaults); Patrol Unit 14.4% (own loot table, Plant Outskirts); Riot Trooper 12.6% (own loot table, Facility Annex); Patrol Unit 12.6% (own loot table, Facility Annex); Port Guard 12.0% (own loot table); Patrol Unit 11.4% (own loot table, Core Overflow); Ring Fighter 11.1% (own loot table, Network Backrooms); Network Enforcer 11.1% (own loot table, Network Backrooms); Port Guard 10.9% (own loot table, Harbour Stacks); Plant Guard 10.8% (own loot table, Plant Outskirts); Facility Trooper 9.45% (own loot table, Facility Annex); Facility Trooper 9.45% (own loot table, Core Spillway); Facility Trooper 9.45% (own loot table, Spillway Gatehouse); Facility Trooper 8.55% (own loot table, Core Overflow); quest "The Pit"; quest "The Harbourmaster"; quest "The Chief"; quest "The Ring"; quest "Subject 12"; quest "Commander Arthit"; quest "The Walkway"; quest "The Iron Legacy"
- `reinforced_bandana` Reinforced Bandana: Unit K-7 1.395% (catalog drop table); Security Chief Nattapong 1.395% (catalog drop table); Subject Twelve, Relapsed 1.395% (catalog drop table); Harbourmaster Chen 1.395% (catalog drop table); Commander Arthit, Reinstated 1.395% (catalog drop table); The Ringmaster 1.395% (catalog drop table); Unit K-7, Overdriven 1.395% (catalog drop table); The Pit Champion 1.395% (catalog drop table); Big Sak 1.395% (catalog drop table); The Furnace Baron 1.395% (catalog drop table); Spillway Chief 1.395% (catalog drop table); The Wiroj Protocol 1.395% (catalog drop table); The Sludge Foreman 1.395% (catalog drop table); Subject 12 1.395% (catalog drop table); Commander Arthit 1.395% (catalog drop table); Director Wiroj 1.395% (catalog drop table); Vault Warden 0.011% (catalog drop table); Coolant Drone 0.011% (catalog drop table); Vault Trooper 0.011% (catalog drop table); Underworks Brute 0.011% (catalog drop table); Reactor Tech 0.011% (catalog drop table); Reactor Overseer 0.011% (catalog drop table); Foundry Hand 0.011% (catalog drop table); Slag Slinger 0.011% (catalog drop table); Foundry Boss 0.011% (catalog drop table); Heart Guard 0.011% (catalog drop table); Iron Sentry 0.011% (catalog drop table); Heart Keeper 0.011% (catalog drop table); Vault Runner 0.011% (catalog drop table); Tank Crawler 0.011% (catalog drop table); Furnace Hauler 0.011% (catalog drop table); Rivet Thrower 0.011% (catalog drop table); Smogling 0.011% (catalog drop table); Tar Rat 0.011% (catalog drop table); Pipe Brute 0.011% (catalog drop table); Smog Warden 0.011% (catalog drop table); Dock Thug 0.011% (catalog drop table); Rail Bruiser 0.011% (catalog drop table); Night Market Punk 0.011% (catalog drop table); Refinery Enforcer 0.011% (catalog drop table); Bottle Thrower 0.011% (catalog drop table); Stevedore 0.011% (catalog drop table); Port Guard 0.011% (catalog drop table); Dock Slinger 0.011% (catalog drop table); Plant Guard 0.011% (catalog drop table); Hazmat Sprayer 0.011% (catalog drop table); Patrol Unit 0.011% (catalog drop table); Network Runner 0.011% (catalog drop table); Network Enforcer 0.011% (catalog drop table); Ring Fighter 0.011% (catalog drop table); Facility Trooper 0.011% (catalog drop table); Riot Trooper 0.011% (catalog drop table); Hybrid Worker 0.011% (catalog drop table); Core Sentinel 0.011% (catalog drop table); Hybrid Brute 0.011% (catalog drop table)
- `rice_box` Rice Box: The Tunnel Mother guaranteed (personal tier, The Great Drain); Riot Trooper 33.2% (field elite, Facility Annex); Core Sentinel 33.2% (field elite, Spillway Gatehouse); Core Sentinel 33.2% (field elite, Core Spillway); Core Sentinel 30.4% (field elite, Core Overflow); Reactor Tech 29.9% (field elite, Tank Hall); Reactor Tech 29.9% (field elite, Reactor Underworks); Tank Crawler 29.9% (field elite, Tank Hall); Tank Crawler 29.9% (field elite, Reactor Underworks); Underworks Brute 29.9% (field elite, Reactor Underworks); Underworks Brute 29.9% (field elite, Tank Hall); Stevedore 29.3% (field elite, Harbour Stacks); Port Guard 29.3% (field elite, Harbour Stacks); Facility Trooper 25.8% (field elite, Facility Annex); Facility Trooper 25.8% (field elite, Core Spillway); Facility Trooper 25.8% (field elite, Spillway Gatehouse); Network Enforcer 24.3% (field elite, Network Backrooms); Ring Fighter 24.3% (field elite, Network Backrooms); Patrol Unit 23.7% (field elite, Plant Outskirts); Plant Guard 23.7% (field elite, Plant Outskirts); Facility Trooper 23.5% (field elite, Core Overflow); Vault Trooper 21.9% (field elite, Coolant Vaults); Coolant Drone 21.9% (field elite, Coolant Control Room); Vault Trooper 21.9% (field elite, Coolant Control Room); Coolant Drone 21.9% (field elite, Coolant Vaults); Vault Runner 21.9% (field elite, Coolant Control Room); Vault Runner 21.9% (field elite, Coolant Vaults); Patrol Unit 21.0% (field elite, Facility Annex); Rivet Thrower 20.1% (field elite, Heart Core Chamber); Rivet Thrower 20.1% (field elite, The Iron Heart); Furnace Hauler 20.1% (field elite, The Crucible); Furnace Hauler 20.1% (field elite, Foundry Depths); Iron Sentry 20.1% (field elite, Heart Core Chamber); Iron Sentry 20.1% (field elite, The Iron Heart); Heart Guard 20.1% (field elite, Heart Core Chamber); Heart Guard 20.1% (field elite, The Iron Heart); Slag Slinger 20.1% (field elite, The Crucible); Slag Slinger 20.1% (field elite, Foundry Depths); Foundry Hand 20.1% (field elite, The Crucible); Foundry Hand 20.1% (field elite, Foundry Depths); Core Sentinel 20.0% (own loot table); Riot Trooper 20.0% (own loot table); Hybrid Brute 20.0% (own loot table); Patrol Unit 19.1% (field elite, Core Overflow); Hybrid Worker 15.0% (own loot table); Facility Trooper 15.0% (own loot table); Core Sentinel 12.6% (own loot table, Core Spillway); Riot Trooper 12.6% (own loot table, Facility Annex); Core Sentinel 12.6% (own loot table, Spillway Gatehouse); Network Enforcer 12.0% (own loot table); Patrol Unit 12.0% (own loot table); Ring Fighter 12.0% (own loot table); Plant Guard 12.0% (own loot table); Stevedore 12.0% (own loot table); Port Guard 12.0% (own loot table); Core Sentinel 11.4% (own loot table, Core Overflow); Tank Crawler 11.2% (own loot table, Reactor Underworks); Tank Crawler 11.2% (own loot table, Tank Hall); Underworks Brute 11.2% (own loot table, Reactor Underworks); Reactor Tech 11.2% (own loot table, Tank Hall); Reactor Tech 11.2% (own loot table, Reactor Underworks); Underworks Brute 11.2% (own loot table, Tank Hall); Stevedore 10.9% (own loot table, Harbour Stacks); Port Guard 10.9% (own loot table, Harbour Stacks); Facility Trooper 9.45% (own loot table, Core Spillway); Facility Trooper 9.45% (own loot table, Spillway Gatehouse); Facility Trooper 9.45% (own loot table, Facility Annex); Ring Fighter 8.88% (own loot table, Network Backrooms); Network Enforcer 8.88% (own loot table, Network Backrooms); Patrol Unit 8.64% (own loot table, Plant Outskirts); Plant Guard 8.64% (own loot table, Plant Outskirts); Facility Trooper 8.55% (own loot table, Core Overflow); Vault Runner 7.92% (own loot table, Coolant Control Room); Vault Runner 7.92% (own loot table, Coolant Vaults); Coolant Drone 7.92% (own loot table, Coolant Vaults); Coolant Drone 7.92% (own loot table, Coolant Control Room); Vault Trooper 7.92% (own loot table, Coolant Control Room); Vault Trooper 7.92% (own loot table, Coolant Vaults); Patrol Unit 7.56% (own loot table, Facility Annex); Rivet Thrower 7.2% (own loot table, Heart Core Chamber); Rivet Thrower 7.2% (own loot table, The Iron Heart); Furnace Hauler 7.2% (own loot table, The Crucible); Furnace Hauler 7.2% (own loot table, Foundry Depths); Foundry Hand 7.2% (own loot table, Foundry Depths); Foundry Hand 7.2% (own loot table, The Crucible); Slag Slinger 7.2% (own loot table, Foundry Depths); Slag Slinger 7.2% (own loot table, The Crucible); Heart Guard 7.2% (own loot table, The Iron Heart); Heart Guard 7.2% (own loot table, Heart Core Chamber); Iron Sentry 7.2% (own loot table, The Iron Heart); Iron Sentry 7.2% (own loot table, Heart Core Chamber); Patrol Unit 6.84% (own loot table, Core Overflow); shop Ama's Kitchen, 55 coins; quest "The Furnace Baron"; quest "The Harbourmaster"; quest "The Chief"
- `ringmaster_topper` Ringmaster's Topper: The Ringmaster 6.0% (own loot table)
- `ringmaster_wraps` Ringmaster's Wraps: The Ringmaster 20.0% (own loot table); Network Runner 3.0% (field elite, Network Backrooms); Network Enforcer 3.0% (field elite, Network Backrooms); Ring Fighter 3.0% (field elite, Network Backrooms)
- `riot_baton` Riot Baton: Hazmat Sprayer 0.4% (farming ground prize, Facility Annex); Patrol Unit 0.4% (farming ground prize, Facility Annex); Facility Trooper 0.4% (farming ground prize, Facility Annex); Riot Trooper 0.4% (farming ground prize, Facility Annex)
- `rising_sun_headband` Rising Sun Headband: Unit K-7 2.649% (catalog drop table); Security Chief Nattapong 2.649% (catalog drop table); Subject Twelve, Relapsed 2.649% (catalog drop table); Harbourmaster Chen 2.649% (catalog drop table); Commander Arthit, Reinstated 2.649% (catalog drop table); The Ringmaster 2.649% (catalog drop table); Unit K-7, Overdriven 2.649% (catalog drop table); The Pit Champion 2.649% (catalog drop table); Big Sak 2.649% (catalog drop table); The Furnace Baron 2.649% (catalog drop table); Spillway Chief 2.649% (catalog drop table); The Wiroj Protocol 2.649% (catalog drop table); The Sludge Foreman 2.649% (catalog drop table); Subject 12 2.649% (catalog drop table); Commander Arthit 2.649% (catalog drop table); Director Wiroj 2.649% (catalog drop table); Vault Warden 0.068% (catalog drop table); Coolant Drone 0.068% (catalog drop table); Vault Trooper 0.068% (catalog drop table); Underworks Brute 0.068% (catalog drop table); Reactor Tech 0.068% (catalog drop table); Reactor Overseer 0.068% (catalog drop table); Foundry Hand 0.068% (catalog drop table); Slag Slinger 0.068% (catalog drop table); Foundry Boss 0.068% (catalog drop table); Heart Guard 0.068% (catalog drop table); Iron Sentry 0.068% (catalog drop table); Heart Keeper 0.068% (catalog drop table); Vault Runner 0.068% (catalog drop table); Tank Crawler 0.068% (catalog drop table); Furnace Hauler 0.068% (catalog drop table); Rivet Thrower 0.068% (catalog drop table); Smogling 0.068% (catalog drop table); Tar Rat 0.068% (catalog drop table); Pipe Brute 0.068% (catalog drop table); Smog Warden 0.068% (catalog drop table); Dock Thug 0.068% (catalog drop table); Rail Bruiser 0.068% (catalog drop table); Night Market Punk 0.068% (catalog drop table); Refinery Enforcer 0.068% (catalog drop table); Bottle Thrower 0.068% (catalog drop table); Stevedore 0.068% (catalog drop table); Port Guard 0.068% (catalog drop table); Dock Slinger 0.068% (catalog drop table); Plant Guard 0.068% (catalog drop table); Hazmat Sprayer 0.068% (catalog drop table); Patrol Unit 0.068% (catalog drop table); Network Runner 0.068% (catalog drop table); Network Enforcer 0.068% (catalog drop table); Ring Fighter 0.068% (catalog drop table); Facility Trooper 0.068% (catalog drop table); Riot Trooper 0.068% (catalog drop table); Hybrid Worker 0.068% (catalog drop table); Core Sentinel 0.068% (catalog drop table); Hybrid Brute 0.068% (catalog drop table)
- `riveted_dock_coat` Riveted Dock Coat: Unit K-7 3.96% (catalog drop table); Security Chief Nattapong 3.96% (catalog drop table); Subject Twelve, Relapsed 3.96% (catalog drop table); Harbourmaster Chen 3.96% (catalog drop table); Commander Arthit, Reinstated 3.96% (catalog drop table); The Ringmaster 3.96% (catalog drop table); Unit K-7, Overdriven 3.96% (catalog drop table); The Pit Champion 3.96% (catalog drop table); Big Sak 3.96% (catalog drop table); The Furnace Baron 3.96% (catalog drop table); Spillway Chief 3.96% (catalog drop table); The Wiroj Protocol 3.96% (catalog drop table); The Sludge Foreman 3.96% (catalog drop table); Subject 12 3.96% (catalog drop table); Commander Arthit 3.96% (catalog drop table); Director Wiroj 3.96% (catalog drop table); Vault Warden 0.012% (catalog drop table); Coolant Drone 0.012% (catalog drop table); Vault Trooper 0.012% (catalog drop table); Underworks Brute 0.012% (catalog drop table); Reactor Tech 0.012% (catalog drop table); Reactor Overseer 0.012% (catalog drop table); Foundry Hand 0.012% (catalog drop table); Slag Slinger 0.012% (catalog drop table); Foundry Boss 0.012% (catalog drop table); Heart Guard 0.012% (catalog drop table); Iron Sentry 0.012% (catalog drop table); Heart Keeper 0.012% (catalog drop table); Vault Runner 0.012% (catalog drop table); Tank Crawler 0.012% (catalog drop table); Furnace Hauler 0.012% (catalog drop table); Rivet Thrower 0.012% (catalog drop table); Smogling 0.012% (catalog drop table); Tar Rat 0.012% (catalog drop table); Pipe Brute 0.012% (catalog drop table); Smog Warden 0.012% (catalog drop table); Dock Thug 0.012% (catalog drop table); Rail Bruiser 0.012% (catalog drop table); Night Market Punk 0.012% (catalog drop table); Refinery Enforcer 0.012% (catalog drop table); Bottle Thrower 0.012% (catalog drop table); Stevedore 0.012% (catalog drop table); Port Guard 0.012% (catalog drop table); Dock Slinger 0.012% (catalog drop table); Plant Guard 0.012% (catalog drop table); Hazmat Sprayer 0.012% (catalog drop table); Patrol Unit 0.012% (catalog drop table); Network Runner 0.012% (catalog drop table); Network Enforcer 0.012% (catalog drop table); Ring Fighter 0.012% (catalog drop table); Facility Trooper 0.012% (catalog drop table); Riot Trooper 0.012% (catalog drop table); Hybrid Worker 0.012% (catalog drop table); Core Sentinel 0.012% (catalog drop table); Hybrid Brute 0.012% (catalog drop table)
- `riveted_jacket` Riveted Jacket: Refinery Enforcer 31.9% (field elite, Rail Sidings); Refinery Enforcer 12.0% (own loot table); Refinery Enforcer 12.0% (own loot table, Rail Sidings); Rail Bruiser 8.733% (field elite, Rail Sidings); Rail Bruiser 3.0% (own loot table); Rail Bruiser 3.0% (own loot table, Rail Sidings); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `riveted_work_helmet` Riveted Work Helmet: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `runner_sneakers` Runner Sneakers: Network Runner 6.513% (field elite, Network Backrooms); Network Runner 3.0% (own loot table); Network Runner 2.22% (own loot table, Network Backrooms); Network Runner 0.4% (farming ground prize, Network Backrooms); Network Enforcer 0.4% (farming ground prize, Network Backrooms); Ring Fighter 0.4% (farming ground prize, Network Backrooms)
- `runners_cap` Runner's Cap: quest "Big Sak"
- `sak_loafers` Sak's Loafers: Big Sak 20.0% (own loot table); Hazmat Sprayer 3.0% (field elite, Facility Annex); Patrol Unit 3.0% (field elite, Facility Annex); Facility Trooper 3.0% (field elite, Facility Annex); Riot Trooper 3.0% (field elite, Facility Annex)
- `sak_signet` Sak's Signet: Big Sak 6.0% (own loot table)
- `sakura_straw_hat` Sakura Straw Hat: Unit K-7 2.649% (catalog drop table); Security Chief Nattapong 2.649% (catalog drop table); Subject Twelve, Relapsed 2.649% (catalog drop table); Harbourmaster Chen 2.649% (catalog drop table); Commander Arthit, Reinstated 2.649% (catalog drop table); The Ringmaster 2.649% (catalog drop table); Unit K-7, Overdriven 2.649% (catalog drop table); The Pit Champion 2.649% (catalog drop table); Big Sak 2.649% (catalog drop table); The Furnace Baron 2.649% (catalog drop table); Spillway Chief 2.649% (catalog drop table); The Wiroj Protocol 2.649% (catalog drop table); The Sludge Foreman 2.649% (catalog drop table); Subject 12 2.649% (catalog drop table); Commander Arthit 2.649% (catalog drop table); Director Wiroj 2.649% (catalog drop table); Vault Warden 0.068% (catalog drop table); Coolant Drone 0.068% (catalog drop table); Vault Trooper 0.068% (catalog drop table); Underworks Brute 0.068% (catalog drop table); Reactor Tech 0.068% (catalog drop table); Reactor Overseer 0.068% (catalog drop table); Foundry Hand 0.068% (catalog drop table); Slag Slinger 0.068% (catalog drop table); Foundry Boss 0.068% (catalog drop table); Heart Guard 0.068% (catalog drop table); Iron Sentry 0.068% (catalog drop table); Heart Keeper 0.068% (catalog drop table); Vault Runner 0.068% (catalog drop table); Tank Crawler 0.068% (catalog drop table); Furnace Hauler 0.068% (catalog drop table); Rivet Thrower 0.068% (catalog drop table); Smogling 0.068% (catalog drop table); Tar Rat 0.068% (catalog drop table); Pipe Brute 0.068% (catalog drop table); Smog Warden 0.068% (catalog drop table); Dock Thug 0.068% (catalog drop table); Rail Bruiser 0.068% (catalog drop table); Night Market Punk 0.068% (catalog drop table); Refinery Enforcer 0.068% (catalog drop table); Bottle Thrower 0.068% (catalog drop table); Stevedore 0.068% (catalog drop table); Port Guard 0.068% (catalog drop table); Dock Slinger 0.068% (catalog drop table); Plant Guard 0.068% (catalog drop table); Hazmat Sprayer 0.068% (catalog drop table); Patrol Unit 0.068% (catalog drop table); Network Runner 0.068% (catalog drop table); Network Enforcer 0.068% (catalog drop table); Ring Fighter 0.068% (catalog drop table); Facility Trooper 0.068% (catalog drop table); Riot Trooper 0.068% (catalog drop table); Hybrid Worker 0.068% (catalog drop table); Core Sentinel 0.068% (catalog drop table); Hybrid Brute 0.068% (catalog drop table)
- `sakura_wizard_hat` Sakura Wizard Hat: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `scrap_metal` Scrap Metal: The Furnace Baron guaranteed (own loot table); Commander Arthit guaranteed (own loot table); Director Wiroj guaranteed (own loot table); Subject 12 guaranteed (own loot table); Harbourmaster Chen guaranteed (own loot table); The Sludge Foreman guaranteed (own loot table); Big Sak guaranteed (own loot table); The Ringmaster guaranteed (own loot table); The Pit Champion guaranteed (own loot table); Unit K-7 guaranteed (own loot table); Security Chief Nattapong guaranteed (own loot table); Reactor Overseer 100.0% (field elite, Tank Hall); Reactor Overseer 100.0% (field elite, Reactor Underworks); Smog Warden 99.2% (field elite, Saltmarket Backlots); Refinery Enforcer 99.2% (field elite, Rail Sidings); Underworks Brute 98.3% (field elite, Reactor Underworks); Reactor Tech 98.3% (field elite, Reactor Underworks); Tank Crawler 98.3% (field elite, Tank Hall); Tank Crawler 98.3% (field elite, Reactor Underworks); Underworks Brute 98.3% (field elite, Tank Hall); Reactor Tech 98.3% (field elite, Tank Hall); Vault Warden 96.1% (field elite, Coolant Vaults); Vault Warden 96.1% (field elite, Coolant Control Room); Patrol Unit 95.6% (field elite, Plant Outskirts); Foundry Boss 93.6% (field elite, The Crucible); Foundry Boss 93.6% (field elite, Foundry Depths); Heart Keeper 93.6% (field elite, The Iron Heart); Heart Keeper 93.6% (field elite, Heart Core Chamber); Reactor Overseer 93.0% (own loot table, Reactor Underworks); Reactor Overseer 93.0% (own loot table, Tank Hall); Core Sentinel 91.9% (field elite, Spillway Gatehouse); Patrol Unit 91.9% (field elite, Facility Annex); Core Sentinel 91.9% (field elite, Core Spillway); Core Sentinel 90.0% (own loot table); Patrol Unit 90.0% (own loot table); Vault Runner 89.5% (field elite, Coolant Vaults); Coolant Drone 89.5% (field elite, Coolant Control Room); Coolant Drone 89.5% (field elite, Coolant Vaults); Vault Trooper 89.5% (field elite, Coolant Control Room); Vault Trooper 89.5% (field elite, Coolant Vaults); Vault Runner 89.5% (field elite, Coolant Control Room); Patrol Unit 88.4% (field elite, Core Overflow); Core Sentinel 88.4% (field elite, Core Overflow); Heart Guard 85.9% (field elite, Heart Core Chamber); Iron Sentry 85.9% (field elite, The Iron Heart); Iron Sentry 85.9% (field elite, Heart Core Chamber); Rivet Thrower 85.9% (field elite, Heart Core Chamber); Heart Guard 85.9% (field elite, The Iron Heart); Rivet Thrower 85.9% (field elite, The Iron Heart); Slag Slinger 85.9% (field elite, The Crucible); Furnace Hauler 85.9% (field elite, The Crucible); Slag Slinger 85.9% (field elite, Foundry Depths); Foundry Hand 85.9% (field elite, The Crucible); Furnace Hauler 85.9% (field elite, Foundry Depths); Foundry Hand 85.9% (field elite, Foundry Depths); Stevedore 83.8% (field elite, Harbour Stacks); Port Guard 83.8% (field elite, Harbour Stacks); Smog Warden 80.0% (own loot table, Saltmarket Backlots); Smog Warden 80.0% (own loot table); Refinery Enforcer 80.0% (own loot table); Refinery Enforcer 80.0% (own loot table, Rail Sidings); Riot Trooper 75.9% (field elite, Facility Annex); Ring Fighter 75.0% (field elite, Network Backrooms); Network Enforcer 75.0% (field elite, Network Backrooms); Reactor Tech 74.4% (own loot table, Reactor Underworks); Tank Crawler 74.4% (own loot table, Tank Hall); Underworks Brute 74.4% (own loot table, Tank Hall); Underworks Brute 74.4% (own loot table, Reactor Underworks); Reactor Tech 74.4% (own loot table, Tank Hall); Tank Crawler 74.4% (own loot table, Reactor Underworks); Dock Slinger 74.3% (field elite, Harbour Stacks); Plant Guard 73.8% (field elite, Plant Outskirts); Facility Trooper 67.9% (field elite, Spillway Gatehouse); Facility Trooper 67.9% (field elite, Core Spillway); Facility Trooper 67.9% (field elite, Facility Annex); Vault Warden 66.0% (own loot table, Coolant Control Room); Vault Warden 66.0% (own loot table, Coolant Vaults); Rail Bruiser 65.7% (field elite, Rail Sidings); Pipe Brute 65.7% (field elite, Saltmarket Backlots); Patrol Unit 64.8% (own loot table, Plant Outskirts); Hazmat Sprayer 63.9% (field elite, Plant Outskirts); Facility Trooper 63.4% (field elite, Core Overflow); Riot Trooper 60.0% (own loot table); Heart Keeper 60.0% (own loot table, Heart Core Chamber); Foundry Boss 60.0% (own loot table, Foundry Depths); Foundry Boss 60.0% (own loot table, The Crucible); Heart Keeper 60.0% (own loot table, The Iron Heart); Hazmat Sprayer 58.1% (field elite, Facility Annex); Hazmat Sprayer 58.1% (field elite, Core Spillway); Hazmat Sprayer 58.1% (field elite, Spillway Gatehouse); Patrol Unit 56.7% (own loot table, Facility Annex); Core Sentinel 56.7% (own loot table, Core Spillway); Core Sentinel 56.7% (own loot table, Spillway Gatehouse); Network Runner 52.9% (field elite, Network Backrooms); Vault Runner 52.8% (own loot table, Coolant Control Room); Coolant Drone 52.8% (own loot table, Coolant Control Room); Coolant Drone 52.8% (own loot table, Coolant Vaults); Vault Trooper 52.8% (own loot table, Coolant Control Room); Vault Trooper 52.8% (own loot table, Coolant Vaults); Vault Runner 52.8% (own loot table, Coolant Vaults); Patrol Unit 51.3% (own loot table, Core Overflow); Core Sentinel 51.3% (own loot table, Core Overflow); Network Enforcer 50.0% (own loot table); Ring Fighter 50.0% (own loot table); Facility Trooper 50.0% (own loot table); Stevedore 50.0% (own loot table); Port Guard 50.0% (own loot table); Hybrid Brute 50.0% (own loot table); Plant Guard 50.0% (own loot table); Dock Thug 48.8% (field elite, Rail Sidings); Night Market Punk 48.8% (field elite, Rail Sidings); Bottle Thrower 48.8% (field elite, Saltmarket Backlots); Heart Guard 48.0% (own loot table, Heart Core Chamber); Rivet Thrower 48.0% (own loot table, Heart Core Chamber); Heart Guard 48.0% (own loot table, The Iron Heart); Rivet Thrower 48.0% (own loot table, The Iron Heart); Slag Slinger 48.0% (own loot table, The Crucible); Furnace Hauler 48.0% (own loot table, The Crucible); Slag Slinger 48.0% (own loot table, Foundry Depths); Foundry Hand 48.0% (own loot table, The Crucible); Furnace Hauler 48.0% (own loot table, Foundry Depths); Foundry Hand 48.0% (own loot table, Foundry Depths); Iron Sentry 48.0% (own loot table, Heart Core Chamber); Iron Sentry 48.0% (own loot table, The Iron Heart); Stevedore 45.5% (own loot table, Harbour Stacks); Port Guard 45.5% (own loot table, Harbour Stacks); Dock Thug 45.3% (field elite, Harbour Stacks); Hazmat Sprayer 40.0% (own loot table); Dock Slinger 40.0% (own loot table); Hybrid Worker 40.0% (own loot table); Tar Rat 38.6% (field elite, Saltmarket Backlots); Smogling 38.6% (field elite, Saltmarket Backlots); Riot Trooper 37.8% (own loot table, Facility Annex); Ring Fighter 37.0% (own loot table, Network Backrooms); Network Enforcer 37.0% (own loot table, Network Backrooms); Dock Slinger 36.4% (own loot table, Harbour Stacks); Plant Guard 36.0% (own loot table, Plant Outskirts); Facility Trooper 31.5% (own loot table, Spillway Gatehouse); Facility Trooper 31.5% (own loot table, Core Spillway); Facility Trooper 31.5% (own loot table, Facility Annex); Network Runner 30.0% (own loot table); Pipe Brute 30.0% (own loot table); Pipe Brute 30.0% (own loot table, Saltmarket Backlots); Rail Bruiser 30.0% (own loot table, Rail Sidings); Rail Bruiser 30.0% (own loot table); Hazmat Sprayer 28.8% (own loot table, Plant Outskirts); Facility Trooper 28.5% (own loot table, Core Overflow); Hazmat Sprayer 25.2% (own loot table, Spillway Gatehouse); Hazmat Sprayer 25.2% (own loot table, Core Spillway); Hazmat Sprayer 25.2% (own loot table, Facility Annex); Network Runner 22.2% (own loot table, Network Backrooms); Dock Thug 20.0% (own loot table); Dock Thug 20.0% (own loot table, Rail Sidings); Night Market Punk 20.0% (own loot table); Night Market Punk 20.0% (own loot table, Rail Sidings); Bottle Thrower 20.0% (own loot table); Bottle Thrower 20.0% (own loot table, Saltmarket Backlots); Dock Thug 18.2% (own loot table, Harbour Stacks); Tar Rat 15.0% (own loot table, Saltmarket Backlots); Tar Rat 15.0% (own loot table); Smogling 15.0% (own loot table, Saltmarket Backlots); Smogling 15.0% (own loot table)
- `second_wind_tonic` Second Wind Tonic: Unit K-7 0.96% (catalog drop table); Security Chief Nattapong 0.96% (catalog drop table); Subject Twelve, Relapsed 0.96% (catalog drop table); Harbourmaster Chen 0.96% (catalog drop table); Commander Arthit, Reinstated 0.96% (catalog drop table); The Ringmaster 0.96% (catalog drop table); Unit K-7, Overdriven 0.96% (catalog drop table); The Pit Champion 0.96% (catalog drop table); Big Sak 0.96% (catalog drop table); The Furnace Baron 0.96% (catalog drop table); Spillway Chief 0.96% (catalog drop table); The Wiroj Protocol 0.96% (catalog drop table); The Sludge Foreman 0.96% (catalog drop table); Subject 12 0.96% (catalog drop table); Commander Arthit 0.96% (catalog drop table); Director Wiroj 0.96% (catalog drop table); Vault Warden 0.006% (catalog drop table); Coolant Drone 0.006% (catalog drop table); Vault Trooper 0.006% (catalog drop table); Underworks Brute 0.006% (catalog drop table); Reactor Tech 0.006% (catalog drop table); Reactor Overseer 0.006% (catalog drop table); Foundry Hand 0.006% (catalog drop table); Slag Slinger 0.006% (catalog drop table); Foundry Boss 0.006% (catalog drop table); Heart Guard 0.006% (catalog drop table); Iron Sentry 0.006% (catalog drop table); Heart Keeper 0.006% (catalog drop table); Vault Runner 0.006% (catalog drop table); Tank Crawler 0.006% (catalog drop table); Furnace Hauler 0.006% (catalog drop table); Rivet Thrower 0.006% (catalog drop table); Smogling 0.006% (catalog drop table); Tar Rat 0.006% (catalog drop table); Pipe Brute 0.006% (catalog drop table); Smog Warden 0.006% (catalog drop table); Dock Thug 0.006% (catalog drop table); Rail Bruiser 0.006% (catalog drop table); Night Market Punk 0.006% (catalog drop table); Refinery Enforcer 0.006% (catalog drop table); Bottle Thrower 0.006% (catalog drop table); Stevedore 0.006% (catalog drop table); Port Guard 0.006% (catalog drop table); Dock Slinger 0.006% (catalog drop table); Plant Guard 0.006% (catalog drop table); Hazmat Sprayer 0.006% (catalog drop table); Patrol Unit 0.006% (catalog drop table); Network Runner 0.006% (catalog drop table); Network Enforcer 0.006% (catalog drop table); Ring Fighter 0.006% (catalog drop table); Facility Trooper 0.006% (catalog drop table); Riot Trooper 0.006% (catalog drop table); Hybrid Worker 0.006% (catalog drop table); Core Sentinel 0.006% (catalog drop table); Hybrid Brute 0.006% (catalog drop table)
- `sentinel_gauntlets` Sentinel Gauntlets: quest "The Walkway"
- `shock_baton` Shock Baton: Plant Guard 0.4% (farming ground prize, Plant Outskirts); Hazmat Sprayer 0.4% (farming ground prize, Plant Outskirts); Patrol Unit 0.4% (farming ground prize, Plant Outskirts)
- `smelter_apron` Smelter's Apron: The Furnace Baron 20.0% (own loot table); Dock Thug 3.0% (field elite, Rail Sidings); Rail Bruiser 3.0% (field elite, Rail Sidings); Night Market Punk 3.0% (field elite, Rail Sidings); Refinery Enforcer 3.0% (field elite, Rail Sidings)
- `sovereign_crown` Sovereign Crown: The Iron Sovereign 9.0% (kill reward, Sovereign Vault); The Iron Sovereign 3.0% (personal tier, Sovereign Vault)
- `sovereign_fists` Sovereign Fists: The Iron Sovereign 9.0% (kill reward, Sovereign Vault); The Iron Sovereign 3.0% (personal tier, Sovereign Vault)
- `sovereign_grips` Sovereign Grips: The Iron Sovereign 9.0% (kill reward, Sovereign Vault); The Iron Sovereign 3.0% (personal tier, Sovereign Vault)
- `sovereign_mantle` Sovereign Mantle: The Iron Sovereign 9.0% (kill reward, Sovereign Vault); The Iron Sovereign 3.0% (personal tier, Sovereign Vault)
- `sovereign_seal` Sovereign Seal: The Iron Sovereign 9.0% (kill reward, Sovereign Vault); The Iron Sovereign 3.0% (personal tier, Sovereign Vault)
- `sovereign_treads` Sovereign Treads: The Iron Sovereign 9.0% (kill reward, Sovereign Vault); The Iron Sovereign 3.0% (personal tier, Sovereign Vault)
- `spillway_epic_body` Spillway Chief's Coat: Spillway Chief 20.0% (own loot table); Hazmat Sprayer 2.0% (field elite, Core Spillway); Hazmat Sprayer 2.0% (field elite, Spillway Gatehouse); Facility Trooper 2.0% (field elite, Core Spillway); Facility Trooper 2.0% (field elite, Spillway Gatehouse); Core Sentinel 2.0% (field elite, Core Spillway); Core Sentinel 2.0% (field elite, Spillway Gatehouse)
- `spillway_epic_head` Spillway Chief's Visor: Spillway Chief 20.0% (own loot table); Hazmat Sprayer 2.0% (field elite, Core Spillway); Hazmat Sprayer 2.0% (field elite, Spillway Gatehouse); Facility Trooper 2.0% (field elite, Core Spillway); Facility Trooper 2.0% (field elite, Spillway Gatehouse); Core Sentinel 2.0% (field elite, Core Spillway); Core Sentinel 2.0% (field elite, Spillway Gatehouse)
- `starlight_wizard_hat` Starlight Wizard Hat: Unit K-7 0.571% (catalog drop table); Security Chief Nattapong 0.571% (catalog drop table); Subject Twelve, Relapsed 0.571% (catalog drop table); Harbourmaster Chen 0.571% (catalog drop table); Commander Arthit, Reinstated 0.571% (catalog drop table); The Ringmaster 0.571% (catalog drop table); Unit K-7, Overdriven 0.571% (catalog drop table); The Pit Champion 0.571% (catalog drop table); Big Sak 0.571% (catalog drop table); The Furnace Baron 0.571% (catalog drop table); Spillway Chief 0.571% (catalog drop table); The Wiroj Protocol 0.571% (catalog drop table); The Sludge Foreman 0.571% (catalog drop table); Subject 12 0.571% (catalog drop table); Commander Arthit 0.571% (catalog drop table); Director Wiroj 0.571% (catalog drop table); Vault Warden 0.00175% (catalog drop table); Coolant Drone 0.00175% (catalog drop table); Vault Trooper 0.00175% (catalog drop table); Underworks Brute 0.00175% (catalog drop table); Reactor Tech 0.00175% (catalog drop table); Reactor Overseer 0.00175% (catalog drop table); Foundry Hand 0.00175% (catalog drop table); Slag Slinger 0.00175% (catalog drop table); Foundry Boss 0.00175% (catalog drop table); Heart Guard 0.00175% (catalog drop table); Iron Sentry 0.00175% (catalog drop table); Heart Keeper 0.00175% (catalog drop table); Vault Runner 0.00175% (catalog drop table); Tank Crawler 0.00175% (catalog drop table); Furnace Hauler 0.00175% (catalog drop table); Rivet Thrower 0.00175% (catalog drop table); Smogling 0.00175% (catalog drop table); Tar Rat 0.00175% (catalog drop table); Pipe Brute 0.00175% (catalog drop table); Smog Warden 0.00175% (catalog drop table); Dock Thug 0.00175% (catalog drop table); Rail Bruiser 0.00175% (catalog drop table); Night Market Punk 0.00175% (catalog drop table); Refinery Enforcer 0.00175% (catalog drop table); Bottle Thrower 0.00175% (catalog drop table); Stevedore 0.00175% (catalog drop table); Port Guard 0.00175% (catalog drop table); Dock Slinger 0.00175% (catalog drop table); Plant Guard 0.00175% (catalog drop table); Hazmat Sprayer 0.00175% (catalog drop table); Patrol Unit 0.00175% (catalog drop table); Network Runner 0.00175% (catalog drop table); Network Enforcer 0.00175% (catalog drop table); Ring Fighter 0.00175% (catalog drop table); Facility Trooper 0.00175% (catalog drop table); Riot Trooper 0.00175% (catalog drop table); Hybrid Worker 0.00175% (catalog drop table); Core Sentinel 0.00175% (catalog drop table); Hybrid Brute 0.00175% (catalog drop table)
- `steamed_bun` Steamed Bun: Dock Slinger 35.6% (field elite, Harbour Stacks); Smogling 31.9% (field elite, Saltmarket Backlots); Dock Thug 31.9% (field elite, Rail Sidings); Bottle Thrower 31.9% (field elite, Saltmarket Backlots); Network Runner 29.7% (field elite, Network Backrooms); Dock Thug 29.3% (field elite, Harbour Stacks); Hazmat Sprayer 29.0% (field elite, Plant Outskirts); Tar Rat 27.1% (field elite, Saltmarket Backlots); Hazmat Sprayer 25.8% (field elite, Spillway Gatehouse); Hazmat Sprayer 25.8% (field elite, Core Spillway); Hazmat Sprayer 25.8% (field elite, Facility Annex); Network Runner 15.0% (own loot table); Hazmat Sprayer 15.0% (own loot table); Dock Slinger 15.0% (own loot table); Dock Slinger 13.7% (own loot table, Harbour Stacks); Bottle Thrower 12.0% (own loot table, Saltmarket Backlots); Bottle Thrower 12.0% (own loot table); Dock Thug 12.0% (own loot table, Rail Sidings); Dock Thug 12.0% (own loot table); Smogling 12.0% (own loot table, Saltmarket Backlots); Smogling 12.0% (own loot table); Network Runner 11.1% (own loot table, Network Backrooms); Dock Thug 10.9% (own loot table, Harbour Stacks); Hazmat Sprayer 10.8% (own loot table, Plant Outskirts); Tar Rat 10.0% (own loot table, Saltmarket Backlots); Tar Rat 10.0% (own loot table); Hazmat Sprayer 9.45% (own loot table, Facility Annex); Hazmat Sprayer 9.45% (own loot table, Core Spillway); Hazmat Sprayer 9.45% (own loot table, Spillway Gatehouse); shop Ama's Kitchen, 10 coins
- `steel_toe_boots` Steel-toe Boots: Rail Bruiser 11.5% (field elite, Rail Sidings); Rail Bruiser 4.0% (own loot table); Rail Bruiser 4.0% (own loot table, Rail Sidings); Smogling 0.4% (farming ground prize, Saltmarket Backlots); Tar Rat 0.4% (farming ground prize, Saltmarket Backlots); Pipe Brute 0.4% (farming ground prize, Saltmarket Backlots); Smog Warden 0.4% (farming ground prize, Saltmarket Backlots); Bottle Thrower 0.4% (farming ground prize, Saltmarket Backlots); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `street_runners` Street Runners: Night Market Punk 11.5% (field elite, Rail Sidings); Night Market Punk 4.0% (own loot table); Night Market Punk 4.0% (own loot table, Rail Sidings); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `subject_band` Subject 12's Band: Subject 12 20.0% (own loot table); Hazmat Sprayer 3.0% (field elite, Facility Annex); Patrol Unit 3.0% (field elite, Facility Annex); Facility Trooper 3.0% (field elite, Facility Annex); Riot Trooper 3.0% (field elite, Facility Annex)
- `subject_grips` Subject Grips: Subject 12 6.0% (own loot table)
- `taped_knuckles` Taped Knuckles: Pipe Brute 11.5% (field elite, Saltmarket Backlots); Pipe Brute 4.0% (own loot table); Pipe Brute 4.0% (own loot table, Saltmarket Backlots); shop Kenji's Gear Stall, 60 coins
- `tiger_hood` Tiger Hood: Unit K-7 1.395% (catalog drop table); Security Chief Nattapong 1.395% (catalog drop table); Subject Twelve, Relapsed 1.395% (catalog drop table); Harbourmaster Chen 1.395% (catalog drop table); Commander Arthit, Reinstated 1.395% (catalog drop table); The Ringmaster 1.395% (catalog drop table); Unit K-7, Overdriven 1.395% (catalog drop table); The Pit Champion 1.395% (catalog drop table); Big Sak 1.395% (catalog drop table); The Furnace Baron 1.395% (catalog drop table); Spillway Chief 1.395% (catalog drop table); The Wiroj Protocol 1.395% (catalog drop table); The Sludge Foreman 1.395% (catalog drop table); Subject 12 1.395% (catalog drop table); Commander Arthit 1.395% (catalog drop table); Director Wiroj 1.395% (catalog drop table); Vault Warden 0.011% (catalog drop table); Coolant Drone 0.011% (catalog drop table); Vault Trooper 0.011% (catalog drop table); Underworks Brute 0.011% (catalog drop table); Reactor Tech 0.011% (catalog drop table); Reactor Overseer 0.011% (catalog drop table); Foundry Hand 0.011% (catalog drop table); Slag Slinger 0.011% (catalog drop table); Foundry Boss 0.011% (catalog drop table); Heart Guard 0.011% (catalog drop table); Iron Sentry 0.011% (catalog drop table); Heart Keeper 0.011% (catalog drop table); Vault Runner 0.011% (catalog drop table); Tank Crawler 0.011% (catalog drop table); Furnace Hauler 0.011% (catalog drop table); Rivet Thrower 0.011% (catalog drop table); Smogling 0.011% (catalog drop table); Tar Rat 0.011% (catalog drop table); Pipe Brute 0.011% (catalog drop table); Smog Warden 0.011% (catalog drop table); Dock Thug 0.011% (catalog drop table); Rail Bruiser 0.011% (catalog drop table); Night Market Punk 0.011% (catalog drop table); Refinery Enforcer 0.011% (catalog drop table); Bottle Thrower 0.011% (catalog drop table); Stevedore 0.011% (catalog drop table); Port Guard 0.011% (catalog drop table); Dock Slinger 0.011% (catalog drop table); Plant Guard 0.011% (catalog drop table); Hazmat Sprayer 0.011% (catalog drop table); Patrol Unit 0.011% (catalog drop table); Network Runner 0.011% (catalog drop table); Network Enforcer 0.011% (catalog drop table); Ring Fighter 0.011% (catalog drop table); Facility Trooper 0.011% (catalog drop table); Riot Trooper 0.011% (catalog drop table); Hybrid Worker 0.011% (catalog drop table); Core Sentinel 0.011% (catalog drop table); Hybrid Brute 0.011% (catalog drop table)
- `titan_core` Titan's Ember Core: The Slag Titan 15.0% (kill reward, Slag Furnace); The Slag Titan 5.0% (personal tier, Slag Furnace)
- `titan_grip` Titan's Grip: The Slag Titan 15.0% (kill reward, Slag Furnace); The Slag Titan 5.0% (personal tier, Slag Furnace)
- `titan_slagfist` Titan's Slagfist: The Slag Titan 15.0% (kill reward, Slag Furnace); The Slag Titan 5.0% (personal tier, Slag Furnace)
- `torn_label` Torn Shipping Label: quest "The Sludge Foreman"
- `trooper_vest` Trooper Vest: Riot Trooper 5.564% (field elite, Facility Annex); Riot Trooper 3.0% (own loot table); Riot Trooper 1.89% (own loot table, Facility Annex); Hazmat Sprayer 0.4% (farming ground prize, Facility Annex); Patrol Unit 0.4% (farming ground prize, Facility Annex); Facility Trooper 0.4% (farming ground prize, Facility Annex); Riot Trooper 0.4% (farming ground prize, Facility Annex)
- `underworks_epic_body` Relapsed Plate: Subject Twelve, Relapsed 15.0% (own loot table); Reactor Overseer 2.764% (field elite, Reactor Underworks); Reactor Overseer 2.764% (field elite, Tank Hall); Underworks Brute 2.0% (field elite, Reactor Underworks); Underworks Brute 2.0% (field elite, Tank Hall); Reactor Tech 2.0% (field elite, Reactor Underworks); Reactor Tech 2.0% (field elite, Tank Hall); Reactor Overseer 2.0% (field elite, Reactor Underworks); Reactor Overseer 2.0% (field elite, Tank Hall); Tank Crawler 2.0% (field elite, Reactor Underworks); Tank Crawler 2.0% (field elite, Tank Hall); Reactor Overseer 0.93% (own loot table, Reactor Underworks); Reactor Overseer 0.93% (own loot table, Tank Hall)
- `underworks_epic_charm` Relapsed Charm: Subject Twelve, Relapsed 15.0% (own loot table)
- `underworks_epic_feet` Relapsed Boots: Subject Twelve, Relapsed 15.0% (own loot table)
- `underworks_epic_hands` Relapsed Gloves: Subject Twelve, Relapsed 15.0% (own loot table)
- `underworks_epic_head` Relapsed Helm: Subject Twelve, Relapsed 15.0% (own loot table)
- `underworks_epic_weapon` Relapsed Knuckles: Subject Twelve, Relapsed 15.0% (own loot table); Reactor Overseer 2.764% (field elite, Reactor Underworks); Reactor Overseer 2.764% (field elite, Tank Hall); Reactor Overseer 0.93% (own loot table, Reactor Underworks); Reactor Overseer 0.93% (own loot table, Tank Hall)
- `underworks_rare_body` Reactor Crew Plate: Reactor Overseer 10.7% (field elite, Reactor Underworks); Reactor Overseer 10.7% (field elite, Tank Hall); Underworks Brute 5.477% (field elite, Reactor Underworks); Underworks Brute 5.477% (field elite, Tank Hall); Reactor Overseer 3.72% (own loot table, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Tank Hall); Underworks Brute 1.86% (own loot table, Reactor Underworks); Underworks Brute 1.86% (own loot table, Tank Hall); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `underworks_rare_charm` Reactor Crew Charm: Reactor Overseer 10.7% (field elite, Reactor Underworks); Reactor Overseer 10.7% (field elite, Tank Hall); Reactor Tech 5.477% (field elite, Reactor Underworks); Reactor Tech 5.477% (field elite, Tank Hall); Reactor Overseer 3.72% (own loot table, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Tank Hall); Reactor Tech 1.86% (own loot table, Reactor Underworks); Reactor Tech 1.86% (own loot table, Tank Hall); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `underworks_rare_feet` Reactor Crew Boots: Reactor Overseer 10.7% (field elite, Reactor Underworks); Reactor Overseer 10.7% (field elite, Tank Hall); Reactor Tech 5.477% (field elite, Reactor Underworks); Reactor Tech 5.477% (field elite, Tank Hall); Reactor Overseer 3.72% (own loot table, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Tank Hall); Reactor Tech 1.86% (own loot table, Reactor Underworks); Reactor Tech 1.86% (own loot table, Tank Hall); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `underworks_rare_hands` Reactor Crew Gloves: Reactor Overseer 10.7% (field elite, Reactor Underworks); Reactor Overseer 10.7% (field elite, Tank Hall); Tank Crawler 5.477% (field elite, Tank Hall); Tank Crawler 5.477% (field elite, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Tank Hall); Tank Crawler 1.86% (own loot table, Tank Hall); Tank Crawler 1.86% (own loot table, Reactor Underworks); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `underworks_rare_head` Reactor Crew Helm: Reactor Overseer 10.7% (field elite, Reactor Underworks); Reactor Overseer 10.7% (field elite, Tank Hall); Tank Crawler 5.477% (field elite, Tank Hall); Tank Crawler 5.477% (field elite, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Tank Hall); Tank Crawler 1.86% (own loot table, Tank Hall); Tank Crawler 1.86% (own loot table, Reactor Underworks); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `underworks_rare_weapon` Reactor Crew Knuckles: Reactor Overseer 10.7% (field elite, Reactor Underworks); Reactor Overseer 10.7% (field elite, Tank Hall); Underworks Brute 5.477% (field elite, Reactor Underworks); Underworks Brute 5.477% (field elite, Tank Hall); Reactor Overseer 3.72% (own loot table, Reactor Underworks); Reactor Overseer 3.72% (own loot table, Tank Hall); Underworks Brute 1.86% (own loot table, Reactor Underworks); Underworks Brute 1.86% (own loot table, Tank Hall); Furnace Hauler 0.05% (farming ground prize, The Crucible); Furnace Hauler 0.05% (farming ground prize, Foundry Depths); Tank Crawler 0.05% (farming ground prize, Tank Hall); Tank Crawler 0.05% (farming ground prize, Reactor Underworks); Foundry Boss 0.05% (farming ground prize, The Crucible); Foundry Boss 0.05% (farming ground prize, Foundry Depths); Slag Slinger 0.05% (farming ground prize, The Crucible); Slag Slinger 0.05% (farming ground prize, Foundry Depths); Foundry Hand 0.05% (farming ground prize, The Crucible); Foundry Hand 0.05% (farming ground prize, Foundry Depths); Reactor Overseer 0.05% (farming ground prize, Tank Hall); Reactor Overseer 0.05% (farming ground prize, Reactor Underworks); Reactor Tech 0.05% (farming ground prize, Tank Hall); Reactor Tech 0.05% (farming ground prize, Reactor Underworks); Underworks Brute 0.05% (farming ground prize, Tank Hall); Underworks Brute 0.05% (farming ground prize, Reactor Underworks)
- `underworks_uncommon_body` Underworks Plate: Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible)
- `underworks_uncommon_charm` Underworks Charm: Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible)
- `underworks_uncommon_feet` Underworks Boots: Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible)
- `underworks_uncommon_hands` Underworks Gloves: Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible)
- `underworks_uncommon_head` Underworks Helm: Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible)
- `underworks_uncommon_weapon` Underworks Knuckles: Underworks Brute 0.17% (farming ground prize, Reactor Underworks); Underworks Brute 0.17% (farming ground prize, Tank Hall); Reactor Tech 0.17% (farming ground prize, Reactor Underworks); Reactor Tech 0.17% (farming ground prize, Tank Hall); Reactor Overseer 0.17% (farming ground prize, Reactor Underworks); Reactor Overseer 0.17% (farming ground prize, Tank Hall); Foundry Hand 0.17% (farming ground prize, Foundry Depths); Foundry Hand 0.17% (farming ground prize, The Crucible); Slag Slinger 0.17% (farming ground prize, Foundry Depths); Slag Slinger 0.17% (farming ground prize, The Crucible); Foundry Boss 0.17% (farming ground prize, Foundry Depths); Foundry Boss 0.17% (farming ground prize, The Crucible); Tank Crawler 0.17% (farming ground prize, Reactor Underworks); Tank Crawler 0.17% (farming ground prize, Tank Hall); Furnace Hauler 0.17% (farming ground prize, Foundry Depths); Furnace Hauler 0.17% (farming ground prize, The Crucible)
- `used_alloy_knuckles` Used Alloy Knuckles: shop Kenji's Gear Stall, 1660 coins
- `used_brass_knuckles` Used Brass Knuckles: shop Kenji's Gear Stall, 220 coins
- `used_cargo_gloves` Used Cargo Gloves: shop Kenji's Gear Stall, 340 coins
- `used_coolant_uncommon_body` Used Coolant Plate: shop Kenji's Gear Stall, 1360 coins
- `used_coolant_uncommon_charm` Used Coolant Charm: shop Kenji's Gear Stall, 1100 coins
- `used_coolant_uncommon_feet` Used Coolant Boots: shop Kenji's Gear Stall, 820 coins
- `used_coolant_uncommon_hands` Used Coolant Gloves: shop Kenji's Gear Stall, 980 coins
- `used_coolant_uncommon_head` Used Coolant Helm: shop Kenji's Gear Stall, 1080 coins
- `used_coolant_uncommon_weapon` Used Coolant Knuckles: shop Kenji's Gear Stall, 1920 coins
- `used_core_guard_helm` Used Core Guard Helm: shop Kenji's Gear Stall, 1280 coins
- `used_deck_boots` Used Deck Boots: shop Kenji's Gear Stall, 320 coins
- `used_dock_hook` Used Dock Hook: shop Kenji's Gear Stall, 420 coins
- `used_dockers_cap` Used Docker's Cap: shop Kenji's Gear Stall, 320 coins
- `used_facility_boots` Used Facility Boots: shop Kenji's Gear Stall, 880 coins
- `used_facility_helmet` Used Facility Helmet: shop Kenji's Gear Stall, 870 coins
- `used_fight_gloves` Used Taped Fight Gloves: shop Kenji's Gear Stall, 710 coins
- `used_foundry_uncommon_body` Used Foundry Plate: shop Kenji's Gear Stall, 1600 coins
- `used_foundry_uncommon_charm` Used Foundry Charm: shop Kenji's Gear Stall, 1300 coins
- `used_foundry_uncommon_feet` Used Foundry Boots: shop Kenji's Gear Stall, 950 coins
- `used_foundry_uncommon_hands` Used Foundry Gloves: shop Kenji's Gear Stall, 1150 coins
- `used_foundry_uncommon_head` Used Foundry Helm: shop Kenji's Gear Stall, 1270 coins
- `used_foundry_uncommon_weapon` Used Foundry Knuckles: shop Kenji's Gear Stall, 2250 coins
- `used_grip_gloves` Used Lab Grip Gloves: shop Kenji's Gear Stall, 940 coins
- `used_hard_hat` Used Hard Hat: shop Kenji's Gear Stall, 80 coins
- `used_hazmat_hood` Used Hazmat Hood: shop Kenji's Gear Stall, 480 coins
- `used_heart_uncommon_body` Used Heartforged Plate: shop Kenji's Gear Stall, 1710 coins
- `used_heart_uncommon_charm` Used Heartforged Charm: shop Kenji's Gear Stall, 1390 coins
- `used_heart_uncommon_feet` Used Heartforged Boots: shop Kenji's Gear Stall, 1020 coins
- `used_heart_uncommon_hands` Used Heartforged Gloves: shop Kenji's Gear Stall, 1230 coins
- `used_heart_uncommon_head` Used Heartforged Helm: shop Kenji's Gear Stall, 1360 coins
- `used_heart_uncommon_weapon` Used Heartforged Knuckles: shop Kenji's Gear Stall, 2420 coins
- `used_insulated_gauntlets` Used Insulated Gauntlets: shop Kenji's Gear Stall, 1360 coins
- `used_insulated_gloves` Used Insulated Gloves: shop Kenji's Gear Stall, 510 coins
- `used_iron_helm` Used Iron Helm: shop Kenji's Gear Stall, 200 coins
- `used_kevlar_jacket` Used Kevlar Jacket: shop Kenji's Gear Stall, 730 coins
- `used_lab_boots` Used Lab Boots: shop Kenji's Gear Stall, 480 coins
- `used_plant_vest` Used Plant Security Vest: shop Kenji's Gear Stall, 530 coins
- `used_port_jacket` Used Port Authority Jacket: shop Kenji's Gear Stall, 360 coins
- `used_reactor_plate` Used Reactor Plate: shop Kenji's Gear Stall, 1400 coins
- `used_riot_baton` Used Riot Baton: shop Kenji's Gear Stall, 1120 coins
- `used_riveted_jacket` Used Riveted Jacket: shop Kenji's Gear Stall, 190 coins
- `used_runner_sneakers` Used Runner Sneakers: shop Kenji's Gear Stall, 680 coins
- `used_shock_baton` Used Shock Baton: shop Kenji's Gear Stall, 630 coins
- `used_steel_toe_boots` Used Steel-toe Boots: shop Kenji's Gear Stall, 80 coins
- `used_street_runners` Used Street Runners: shop Kenji's Gear Stall, 170 coins
- `used_trooper_vest` Used Trooper Vest: shop Kenji's Gear Stall, 950 coins
- `used_underworks_uncommon_body` Used Underworks Plate: shop Kenji's Gear Stall, 1480 coins
- `used_underworks_uncommon_charm` Used Underworks Charm: shop Kenji's Gear Stall, 1210 coins
- `used_underworks_uncommon_feet` Used Underworks Boots: shop Kenji's Gear Stall, 880 coins
- `used_underworks_uncommon_hands` Used Underworks Gloves: shop Kenji's Gear Stall, 1060 coins
- `used_underworks_uncommon_head` Used Underworks Helm: shop Kenji's Gear Stall, 1170 coins
- `used_underworks_uncommon_weapon` Used Underworks Knuckles: shop Kenji's Gear Stall, 2090 coins
- `used_walkway_boots` Used Walkway Boots: shop Kenji's Gear Stall, 1320 coins
- `used_watch_cap` Used Night Watch Cap: shop Kenji's Gear Stall, 660 coins
- `used_weighted_knuckles` Used Weighted Knuckles: shop Kenji's Gear Stall, 850 coins
- `used_work_jacket` Used Work Jacket: shop Kenji's Gear Stall, 70 coins
- `walkway_boots` Walkway Boots: Hybrid Brute 3.0% (own loot table); Patrol Unit 0.67% (farming ground prize, Core Overflow); Facility Trooper 0.67% (farming ground prize, Core Overflow); Core Sentinel 0.67% (farming ground prize, Core Overflow); Hazmat Sprayer 0.4% (farming ground prize, Core Spillway); Hazmat Sprayer 0.4% (farming ground prize, Spillway Gatehouse); Facility Trooper 0.4% (farming ground prize, Core Spillway); Facility Trooper 0.4% (farming ground prize, Spillway Gatehouse); Core Sentinel 0.4% (farming ground prize, Core Spillway); Core Sentinel 0.4% (farming ground prize, Spillway Gatehouse)
- `waste_sample` Waste Sample: quest "Unit K-7"
- `watch_cap` Night Watch Cap: Ring Fighter 6.513% (field elite, Network Backrooms); Ring Fighter 3.0% (own loot table); Ring Fighter 2.22% (own loot table, Network Backrooms); Network Runner 0.4% (farming ground prize, Network Backrooms); Network Enforcer 0.4% (farming ground prize, Network Backrooms); Ring Fighter 0.4% (farming ground prize, Network Backrooms)
- `watchmans_cap` Watchman's Cap: quest "The Furnace Baron"
- `weighted_knuckles` Weighted Knuckles: Network Runner 0.4% (farming ground prize, Network Backrooms); Network Enforcer 0.4% (farming ground prize, Network Backrooms); Ring Fighter 0.4% (farming ground prize, Network Backrooms)
- `wiroj_protocol_chip` Wiroj Protocol Chip: Director Wiroj 25.0% (boss's own list)
- `work_jacket` Work Jacket: Smog Warden 48.8% (field elite, Saltmarket Backlots); Smog Warden 20.0% (own loot table); Smog Warden 20.0% (own loot table, Saltmarket Backlots); Smogling 0.4% (farming ground prize, Saltmarket Backlots); Tar Rat 0.4% (farming ground prize, Saltmarket Backlots); Pipe Brute 0.4% (farming ground prize, Saltmarket Backlots); Smog Warden 0.4% (farming ground prize, Saltmarket Backlots); Bottle Thrower 0.4% (farming ground prize, Saltmarket Backlots); Dock Thug 0.22% (farming ground prize, Rail Sidings); Rail Bruiser 0.22% (farming ground prize, Rail Sidings); Night Market Punk 0.22% (farming ground prize, Rail Sidings); Refinery Enforcer 0.22% (farming ground prize, Rail Sidings)
- `wrapped_iron_knuckles` Wrapped Iron Knuckles: Unit K-7 7.84% (catalog drop table); Security Chief Nattapong 7.84% (catalog drop table); Subject Twelve, Relapsed 7.84% (catalog drop table); Harbourmaster Chen 7.84% (catalog drop table); Commander Arthit, Reinstated 7.84% (catalog drop table); The Ringmaster 7.84% (catalog drop table); Unit K-7, Overdriven 7.84% (catalog drop table); The Pit Champion 7.84% (catalog drop table); Big Sak 7.84% (catalog drop table); The Furnace Baron 7.84% (catalog drop table); Spillway Chief 7.84% (catalog drop table); The Wiroj Protocol 7.84% (catalog drop table); The Sludge Foreman 7.84% (catalog drop table); Subject 12 7.84% (catalog drop table); Commander Arthit 7.84% (catalog drop table); Director Wiroj 7.84% (catalog drop table); Vault Warden 0.198% (catalog drop table); Coolant Drone 0.198% (catalog drop table); Vault Trooper 0.198% (catalog drop table); Underworks Brute 0.198% (catalog drop table); Reactor Tech 0.198% (catalog drop table); Reactor Overseer 0.198% (catalog drop table); Foundry Hand 0.198% (catalog drop table); Slag Slinger 0.198% (catalog drop table); Foundry Boss 0.198% (catalog drop table); Heart Guard 0.198% (catalog drop table); Iron Sentry 0.198% (catalog drop table); Heart Keeper 0.198% (catalog drop table); Vault Runner 0.198% (catalog drop table); Tank Crawler 0.198% (catalog drop table); Furnace Hauler 0.198% (catalog drop table); Rivet Thrower 0.198% (catalog drop table); Smogling 0.198% (catalog drop table); Tar Rat 0.198% (catalog drop table); Pipe Brute 0.198% (catalog drop table); Smog Warden 0.198% (catalog drop table); Dock Thug 0.198% (catalog drop table); Rail Bruiser 0.198% (catalog drop table); Night Market Punk 0.198% (catalog drop table); Refinery Enforcer 0.198% (catalog drop table); Bottle Thrower 0.198% (catalog drop table); Stevedore 0.198% (catalog drop table); Port Guard 0.198% (catalog drop table); Dock Slinger 0.198% (catalog drop table); Plant Guard 0.198% (catalog drop table); Hazmat Sprayer 0.198% (catalog drop table); Patrol Unit 0.198% (catalog drop table); Network Runner 0.198% (catalog drop table); Network Enforcer 0.198% (catalog drop table); Ring Fighter 0.198% (catalog drop table); Facility Trooper 0.198% (catalog drop table); Riot Trooper 0.198% (catalog drop table); Hybrid Worker 0.198% (catalog drop table); Core Sentinel 0.198% (catalog drop table); Hybrid Brute 0.198% (catalog drop table)
- `zeros_mantle` Zero's Mantle: Subject Zero 5.0% (kill reward, The Sunken Reservoir); Subject Zero 2.0% (personal tier, The Sunken Reservoir)

