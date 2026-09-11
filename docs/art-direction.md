# Art direction — Krater (Act 1)

Living visual bible. Scannable locks from style evals + existing pipeline docs. Update when a decision sticks; don’t invent mood here that fights the pitch (curiosity/wonder, living Hollow, secrecy).

**Companions:** [`art-pipeline.md`](art-pipeline.md) · [`ai-workflow.md`](ai-workflow.md) · [`game-feel-best-practices.md`](game-feel-best-practices.md) · [`godot-best-practices.md`](godot-best-practices.md) · [`game-decisions.md`](game-decisions.md) (#10, #14) · [`../CONTEXT.md`](../CONTEXT.md)

**Primary still:** [`refs/hollow_concept.png`](refs/hollow_concept.png)

---

## North star / locked camera

| Lock | Detail |
| --- | --- |
| **Camera** | **2D side-view only** (decisions #14). Dig Firmament↑ / Pit↓, TileMap carve, Dome Keeper / SteamWorld Dig comps. |
| **Style bar** | Detailed **painterly pixel** — Eastward / Owlboy territory (not 8-bit minimal, not mushy upscale). |
| **Tone** | Communal Hollow life + quiet secrecy. Curiosity over fear. Act 1 must feel like it could be the whole game. |
| **Sea of Stars** | Evaluated → **rejected as camera**. Steal lighting / layered depth craft only. **No** oblique JRPG 2.5D. **No hybrid** (SoS hub + side dig = two pipelines; refuse). |

Side-view weakness (pit-as-space) is solved with **composition + parallax + light**, not a genre swap.

---

## Reference games — steal / don’t steal

| Source | Steal | Don’t steal |
| --- | --- | --- |
| **Eastward / Owlboy** | Painterly pixels, readable silhouettes, controlled palette, warm lived-in hubs | Generic “cute indie” mush; over-busy UI chrome |
| **Sea of Stars** | Warm light pools, layered depth, animated props, “I can go further up” elevation cues | Oblique SNES-JRPG camera; height-authored maps; in-world RPG combat presentation; hybrid camera |
| **INMOST** | Ink-black voids, lantern-led light grammar, fog/depth volumes, quiet UI, vignette, particle restraint | Grief-horror / bleak-everything-as-threat as **default** Act 1 mood |
| **Blasphemous 2** | Screen density, multi-layer parallax, ambient micro-life, animation silhouette hierarchy, architecture-as-culture | Catholic gothic, penance, body-horror / gore, ash–blood–sacred-gold as palette spine |

**Compass one-liner:** INMOST soul (ink + lantern + quiet) + Blasphemous *screen craft* (density / life / motion) on an Eastward–Owlboy pixel bar — teal/copper salvage Hollow, not a cathedral of penance.

---

## Hollow composition (pit-centered vertical)

Primary ref: [`refs/hollow_concept.png`](refs/hollow_concept.png) (cliffside city around a deep central chasm). **Play layout matches that read** (placeholders OK):

- **Center:** bottomless crash-pit — dark ink void, fog layers, emotional anchor (no hallway floor across the shaft; mid **bridge** only).
- **Heart of the Hollow:** a layered civic cluster suspended over the void, not a ground-bound plaza: Upper Heart (ritual/Council), Mid Heart (market/allotments), Lower Heart (freight/dispatch). Retained hull trusses, rock-bolted underbeams, cables, hanging walkways, and selective transfer spans must visibly explain why it is safe enough to use while gaps, open edges, haze, and subtle sway/creaks keep the void emotionally present.
- **Ring / cliffs:** settlement as **terrace levels** left *and* right of the void — bridges, ladders/stair steps, lantern hints.
- **Districts as elevations:** Farms (upper left) / Wickwork (mid) / Cistern (lower right) on **different vertical bands**.
- **Exit:** right mid deck continues to Dig Site past the Hollow (no dig-wall bleed into home).
- **Firmament↑** — quieter, calmer light, less FX drama (secrecy).
- **Pit↓** — darker, heavier fog, stronger danger read (same dig tools, different frontier).

Play frames should read: **foreground clutter → mid play strip → far pit wall/haze**.

---

## Palette & light language

**Base:** earthy rock / dust / damp stone (slate–brown cave).

**Accents (discipline — two main):**

| Accent | Use |
| --- | --- |
| **Teal-green** | Stone/mineral, cool distance, biolum flecks, dig-vein language |
| **Copper-rust** | Salvage metal, warm oxidize, work tools / pipes |

**Light stops (keep to ~3–4):**

1. **Lantern amber** — safe / social / terrace life  
2. **Cool pit void** — depth, danger, Firmament quieter than Pit
3. **Salvage metal sheen** — copper catch-lights, not neon chrome  
4. **Soft haze** — far bridges fade; no flat ambient wash  

No rainbow junk. No cyber/neon. No blood-glow / sacred-gold as Act 1 identity. Reef vivid = Act 2 only.

---

## Density, parallax, ambient life

- **Density:** one readable play strip + layered mid/far props that sell a lived place (Blasphemous craft bar).
- **Parallax:** soft DepthBg + Mist + pit fog layers; far architecture as silhouette, not new camera.
- **Ambient micro-life:** idle NPCs, dust/spores, small looping props (cloth, lamp mote, worker fidget) — world occupied when you’re not talking.
- **Animation hierarchy:** flat readable silhouette first, texture last; player / NPC idle + walk/dig before decorative frame spam.
- **Premium gate:** empty screen → add **life or light**, not more gore/detail noise.

---

## UI restraint

- Hollow should **breathe** — lighting + soft world labels over stacked chrome.
- HUD quiet in the cavern; siphon / status as panels you open, not permanent left-rail clutter.
- Journal / dialogue: soft salvage-craft (Owlboy/Eastward), not relic/altar chrome.
- Matches feel doc: secrecy systems stay social (copy/UI), not arcade fireworks.

---

## Asset strategy & PixelLab

| Priority | Rule |
| --- | --- |
| **Env first** | Terraces, floors, walls, pit void, lanterns, district props before unique hero sheets |
| **Demo NPCs** | **One settler sprite** reused/cloned across decks — enough for “alive” |
| **Approve-before-gen** | Show exact PixelLab ask; wait for user **approve** — trial gens are scarce |
| **Camera in briefs** | Side-view / sidescroller only — never default top-down / iso Wang |
| **Size** | Prefer **32** or **64** px (dig cells = 64); nearest upscale when needed |

Full how-to: [`art-pipeline.md`](art-pipeline.md). Import / filter: [`godot-best-practices.md`](godot-best-practices.md).

---

## Feel / juice

Juice must read **fair and quiet** — dust, weight, Firmament quieter than Pit. Prefer [`game-feel-best-practices.md`](game-feel-best-practices.md). Do not carnival the Hollow.

---

## Checklist — env / art passes

Use before shipping a Hollow or dig visual pass:

1. **Side-view only** — no oblique / hybrid camera drift.
2. **Pit reads as ink void** — terraces hold detail; center stays dark/deep.
3. **Terrace bands readable** — horizontal walk decks against the void before ornament.
4. **Palette lock** — rock/dust + lantern amber + teal stone + copper metal; strip extra hues.
5. **Light assigns space** — warm lamps on life; cool fill in the shaft; Firmament quieter / Pit darker.
6. **Parallax fog** — far architecture silhouettes without new perspective.
7. **Density + micro-life** — mid/far props + 2–3 ambient loops per district before more unique frames.
8. **UI quiet** — cavern breathes; chrome collapses when not needed.
9. **FX budget** — dig/land dust + rare lamp motes; no bloom/sparkle spam.
10. **PixelLab** — env briefs first; one settler reuse; approve-before-gen; Eastward/Owlboy + `hollow_concept` in the brief.
11. **Tone check** — communal + secrecy, not grief-horror or Catholic body-horror.
12. **Feel align** — Firmament quieter than Pit; social systems stay social ([`game-feel-best-practices.md`](game-feel-best-practices.md)).
