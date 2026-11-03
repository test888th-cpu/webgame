# Licence register

Every licence the shipped assets carry, as recorded in the repository on
2026-11-03 (counts from [ASSET_CREDITS.csv](ASSET_CREDITS.csv), one row per
credited file or asset group). This is a working summary for the project, not
legal advice: **the licence text at the link governs**. Where a summary below
is uncertain, the licence text decides.

| Licence | Version | Rows | Official text | Used for |
|---|---|---|---|---|
| OGA-BY | 3.0 | 341 | <https://static.opengameart.org/OGA-BY-3.0.txt> | LPC character parts |
| OGA-BY | 3.0+ ("3.0 or later") | 15 | <https://static.opengameart.org/OGA-BY-3.0.txt> | LPC character parts |
| CC0 | 1.0 | 7 | <https://creativecommons.org/publicdomain/zero/1.0/legalcode> | 3 LPC parts (heroes and NPCs), 4 recorded sounds |
| CC BY | 3.0 | 5 | <https://creativecommons.org/licenses/by/3.0/legalcode> | 5 recorded sounds |
| CC BY | 4.0 | 5 | <https://creativecommons.org/licenses/by/4.0/legalcode> | the LPC spiked hair (4 enemies), 1 recorded sound |
| MIT | — | 5 | [LICENSE](../../LICENSE) | the project's own generators: environment, effects, UI icons, synthesised sounds, training dummy |
| MIT (third party) | — | 14 | [pixelfx LICENSE](../../client/assets/fx/pixelfx/LICENSE.txt), <https://github.com/patch-gg/pixelfx/blob/a84159688af3ca37a4be05a0d422b94451b2e24e/LICENSE> | combat effects from pixelfx by Patch (with work adapted from Hugo Duprez and rehan-remade, see its NOTICE) |
| SIL OFL | 1.1 | 1 | [NotoSansThai-OFL.txt](../../client/assets/fonts/NotoSansThai-OFL.txt), <https://openfontlicense.org> | Noto Sans Thai font |
| Proprietary (project owner) | — | 5 | none (the owner's own work) | the street kit and four painted enemies |

## Obligations, per licence

**CC0 1.0.** A waiver, not a licence with conditions: no attribution is legally
required. The project still records creator and source for provenance (the
in-game Credits list them), and does not claim the work as its own.

**OGA-BY 3.0.** OpenGameArt's attribution licence, written from CC BY 3.0 with
the clause against technical protection measures removed, so it can be used on
platforms that apply DRM. Attribution is required: credit the creator(s), name
the work, link the source and the licence, and say when the work was changed (an
LPC character sheet is a composite and recolour of the source files: a
modification). Keep any notice the creator asks to be kept. "3.0+" means the
creator also allows later versions; the project uses it under 3.0.

**CC BY 3.0 and CC BY 4.0.** Attribution as above (4.0 also asks for the
copyright notice, licence notice and disclaimer notice if supplied, and a link
to the licence), and changes indicated. Both forbid adding restrictions that stop
recipients exercising the licensed rights, including technological measures
(3.0 §4(a), 4.0 §2(a)(5)(B)). OGA-BY exists to remove exactly that clause; the
CC BY items are the ones to look at before shipping on a platform that applies
DRM. `tools/assets/validate.py` already flags every recorded sound (CC BY and
CC0 alike) "REPLACE BEFORE PAID FEATURES".

**MIT (pixelfx).** The same obligation for third-party code and art: the
notice (Copyright (c) 2026 Patch, Copyright (c) 2026 Hugo Duprez) ships as
`client/assets/fx/pixelfx/LICENSE.txt` beside the sheets, is stored in the
manifest (`fx_pixelfx.notice`) and is printed in the game's Credits, with
pixelfx's NOTICE (the parts it adapts from Sprite Fusion and Hollow Crown).
Its gallery font is not MIT and is not used. Verified at the source: the
licence was read in the repository's own LICENSE at the pinned commit.

**MIT.** Keep the copyright and permission notice ([LICENSE](../../LICENSE)) with
copies of the software and substantial portions of it.

**SIL OFL 1.1.** The font may be bundled with the game; it may not be sold on its
own; a modified version may not use the Reserved Font Name; the copyright and
licence travel with the font (the OFL file ships beside it).

**Proprietary (project owner).** The owner's own work (painted with the owner's
AI tools, per the credit notes); no third-party licence. Any terms of the AI
tools used are the owner's to confirm; nothing in the repository records them.

## Selection for monster art

For monster art the owner selected **CC0 and OGA-BY 3.0** (3.0+ included). CC BY,
CC BY-SA, GPL, OGA-SA and anything else is outside it; the current LPC policy in
`art/lpc/characters.json` still allows CC-BY, so the four CC BY 4.0 hair rows are
reported as outside the selection by `tools/assets/credit_register.py check`
([LICENSE_AUDIT_REPORT.md](../monster_art/LICENSE_AUDIT_REPORT.md)).
