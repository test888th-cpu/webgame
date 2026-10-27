# Enemy sprite prompts (IL-4, D6)

Prompts for repainting the four enemies whose look does not fit the story yet
([STORY_BIBLE.md](STORY_BIBLE.md) §6). LPC has no masks or hazmat suits under the licences
the game allows (CC0, OGA-BY, CC-BY), so these are painted by the owner like the street kit
and Riku's sheets, and imported by `tools/assets/custom_import.py`
([ASSETS.md](ASSETS.md) "Art from the project owner").

## What to paint for each enemy

Two images per enemy, each a **sprite sheet: a grid of equal square cells**, one frame per
cell, read left to right, top to bottom.

| File | Grid | Frames |
|---|---|---|
| `walk.png` | 4 columns x 2 rows | 8 frames: a full walk cycle |
| `fight.png` | 4 columns x 3 rows | frames 1-5: quick jab; frames 6-12: heavy blow with a clear wind-up (frames 6-8 pull back and hold, 9-10 strike, 11-12 recover) |

Hurt and knock-down are made by the importer from the first frame, so they need no frames.

## Rules for every sheet (the importer needs these)

1. **Flat bright green backdrop** (#00FF00) behind every cell, no shadow, no floor.
2. **Dark outline** around the figure, like the heroes.
3. **Side view facing right**, whole body in every cell, the same size and the same foot
   line in every frame (the figure fills about 80% of the cell height).
4. **Nothing in the hands**: the game draws any weapon picked up from the street.
5. No text, no logos, no real brands.
6. Up to 2048 px on the long side, PNG.

## Shared style block (start every prompt with this)

```
HD pixel art sprite sheet for a 2D side-scrolling beat 'em up, same style as Streets of
Rage 4 meets modern pixel art, clean dark outline, consistent character size and foot line
in every frame, side view facing right, full body in every cell, flat pure green
(#00FF00) background, no shadow, no text, empty hands, Bangkok street gang setting,
night lighting with warm light from upper left
```

## The four enemies

| Enemy (`art/custom/<id>/`) | Who they are | Prompt (after the shared block) |
|---|---|---|
| Tar Rat (`tar_hound`) | A Rat Nest gang member: fast, lunges in | `wiry Thai teenage gang member wearing a cheap rubber rat mask that covers the whole face, black hoodie with the hood up, ripped jeans, sneakers stained with black tar, crouched and twitchy` |
| Smogling (`smogling`) | A drifter who breathed the Murk too long | `hunched homeless drifter wearing a home-made gas mask made from a cut plastic bottle and duct tape, smeared face paint around the eyes, patched yellow raincoat, bare feet wrapped in rags, slow swaying walk` |
| Smog Warden (`smog_warden`) | Private security guarding the waste pipes | `tall private security guard in a grey hazmat suit printed with a white skeleton hazard pattern, full gas mask with two round filters, thick rubber gloves and boots, stiff military walk` |
| Sludge Foreman (`sludge_foreman`, boss) | Boss of the drainage-pipe gang | `huge heavy-set gang boss wearing a carved wild-boar mask with tusks, black suspenders over a stained work vest, rubber boots, thick forearms, slow heavy stride` |

For `fight.png` add: `frames 1 to 5 a quick jab, frames 6 to 12 a big two-handed overhead
smash with a long clear wind-up`.

## After painting

1. Upload `walk.png` and `fight.png` to `art/custom/<id>/` (GitHub → Add file → Upload
   files), or send them to Claude in a cloud session, a few images per message.
2. Claude writes the `import.json` (with `"key": true` for the green backdrop), retires the
   LPC recipe of that enemy, imports the sheets and checks them in a browser screenshot.
