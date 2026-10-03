# Art direction — Krater (Act 1)

Living visual bible. Scannable locks from style evals + existing pipeline docs. Update when a decision sticks; don’t invent mood here that fights the pitch (curiosity/wonder, living Hollow, secrecy).

**Companions:** [`hollow-build-brief.md`](hollow-build-brief.md) · [`art-pipeline.md`](art-pipeline.md) · [`ai-workflow.md`](ai-workflow.md) · [`game-feel-best-practices.md`](game-feel-best-practices.md) · [`godot-best-practices.md`](godot-best-practices.md) · [`game-decisions.md`](game-decisions.md) (#10, #14) · [`../CONTEXT.md`](../CONTEXT.md)

**Primary still:** [`refs/hollow_concept.png`](refs/hollow_concept.png)

---

## North star / locked camera

| Lock | Detail |
| --- | --- |
| **Camera** | **2D side-view only** (decisions #14). Secret Firmament↑ digging + public lateral civic excavation; the Devil’s Mouth is the central void, not the routine dig route. |
| **Style bar** | Low-detail, material-rich pixel art: chunky readable silhouettes, irregular strata, dust, seepage, rust, and fungi. Noita-like material clarity without its gore, chaos, or simulation density. |
| **Tone** | Communal Hollow life + quiet secrecy. Curiosity over fear. Act 1 must feel like it could be the whole game. |
| **Sea of Stars** | Evaluated → **rejected as camera**. Steal lighting / layered depth craft only. **No** oblique JRPG 2.5D. **No hybrid** (SoS hub + side dig = two pipelines; refuse). |

Side-view weakness (Devil’s Mouth-as-space) is solved with **composition + parallax + light**, not a genre swap.

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

## Bio-fusion Gear — tone guardrail (locked)

Forbidden Gear is bodily fusion ([`mechanics-canon.md`](mechanics-canon.md) §67). This sits directly next to the Blasphemous body-horror line already rejected above — the guardrail applies with extra weight here:

- Most grafts render as small, quiet, almost-missable changes: a fine vein pattern, a faint luminous patch, a color shift in one eye. Not new limbs, not visible growths, not wounds.
- A rare few late/powerful grafts may be larger and genuinely visible, but still read as **uncanny and controlled**, never grotesque or wound-like. No exposed tissue, no gore palette.
- Use the existing modular-overlay sprite principle (small patches/tints on the current sprite), not a new base body per graft.
- The feeling to aim for is closer to INMOST's quiet unease than Blasphemous's penance/gore — something private and a little wrong, not a horror reveal.

## Hollow composition (Devil’s Mouth-centered vertical)

Primary ref: [`refs/hollow_concept.png`](refs/hollow_concept.png) (cliffside city around a deep central chasm). **Play layout matches that read** (placeholders OK):

- **Center:** bottomless Devil’s Mouth — dark ink void, fog layers, emotional anchor (no hallway floor across the shaft; mid **bridge** only).
- **Heart of the Hollow:** a layered civic cluster suspended over the void, not a ground-bound plaza: Upper Heart (ritual/Council), Mid Heart (market/allotments), Lower Heart (freight/dispatch). These are three civic anchors, each made of several inhabited sub-levels—short streets, carved rooms, homes, balconies, work bays, landings, and hanging walkways—not three flat platforms.
- **Mid Heart’s unique silhouette:** it is a moored constellation of three or four major wreckage rafts and several smaller attached decks, not one bridge and not a set of freely flying islands. Its hidden ship stabilizer makes the major rafts unnaturally light; practical wall anchors, docking bridges, tension cables, catch-rails, hydraulic clamps, and braces still visibly keep it safe. The wreckage is disguised by patchwork civic construction: shaved hull plates, sealed ribs, old hatches reused as walls, oxidized seams, worn decking, dust, and sparse fungi. Do not give every district this language: Glowbeds stay cultivated and fungal, Wickwork stays warm repair-craft, and Cistern stays pressurized utility. Mid Heart alone blends civic amber with weathered, half-buried wreckage geometry, the degraded ship machinery of **the Pulse** (metal housings, conduits, indicators, vents, gauges, repairs, grime, fungal growth — never occult runes), and the ordered remnants of the daily Ritual.
- **Mid Heart flow:** the largest, slightly raised Ritual Raft is visibly the civic center—a broad stepped hall that can hold the daily crowd. West Exchange (Wickwork/left-lift side) reads as queues, Material delivery, Approved Gear orders, repair intake, and freight; East Service (right-lift/Cistern side) reads as rations, care, notices, small shops, and offices; Lower Freight reads as cargo and rougher dock machinery. Keep the main public crossing visually clear from West Exchange through the Ritual Raft to East Service, but show a lower loop of ramps, short bridges, and attached decks so the cluster has several usable paths rather than a single street.
- The Heart must leave gaps, open edges, haze, and subtle sway/creaks around its decks so the void remains emotionally present. Long-distance vertical travel is an **asymmetric three-lift system**: the west civic cage is mid-to-high only; the heavy east Cistern freight cage is Low-to-Mid; and a smaller guarded east passenger cage is Mid-to-High, recessed in the wall away from the Mouth. Lower-west travel is visibly stair/switchback-led. Ladders stay short and local. Hydraulic launch pads may be optional local shortcuts between Heart decks, never the only public route.
- **Ring / cliffs:** settlement as **terrace levels** left *and* right of the void — balconies, transfer decks, cables, walkways over the void.
- **Homes show social ascent:** Lower-terrace homes are compact private units set around noisy shared worker courtyards and communal service spaces. Mid-band apartments are better kept two-room homes near civic work, with shared balconies and more orderly delivery/work surfaces. Ashram Heights homes are quiet, tidy, guarded residences beneath the Firmament—more privacy and better light, but formal entrances, regulated neighbors, and visible scrutiny. Do not make any band luxurious or technologically pristine.
- **Council Wardens:** recognizable civic safety workers, not soldiers in fantasy armor—well-kept work coats, seal tags, practical lamps, inspection ledgers, lift keys, and restrained Firmament markings. Show them at Ashram Heights gate landings, lift docks, Ritual crowd edges, storage checks after unexplained losses, and restricted service routes. Their presence should be easy to read before any forbidden action.
- **Districts as elevations:** High-West directly beneath left Ashram Heights; **Glowbeds directly beneath right Ashram Heights**; Wickwork (mid-left); Mid-East Dig Front at true mid-right height; and Cistern deep lower-right—all on **different vertical bands**, each with generous horizontal play.
- **Progressive outer dig fronts:** Bottom-West (rough early impact-fill civic expansion), Mid-East (wet/pressurized **middle-east** shock-fault and service infrastructure, below Glowbeds and above the deep Cistern), and High-West (cleaner, guarded high-wall work directly below left Ashram Heights, with rarer buried outward-thrown wreck fragments) are far beyond the inhabited edges. Each has a long lived-in approach, dispatch/checkpoint, braced lateral threshold, and several side-gallery chambers. They are distinct destination silhouettes, not decorative work walls visible from Mid Heart.
- **Interlocking settlement mass:** avoid stacked platform rows. Let large districts consume different vertical volumes: long stepped rooms carved behind foreground paths, terraces that overhang smaller routes, multi-storey service towers, recessed courts, and uneven rock shelves. Balance both crater walls; the right wall needs dense neighborhoods and a vertically extended Cistern/service complex, not an empty counterpart to the left.
- **Carved-landscape rule:** the Hollow is a continuous inhabited cliffscape, not a tower of floor strips. Every camera-scale region needs a varied mix of open terraces, recessed caves, overhangs, tall carved bays, and void-facing ledges. Routes must rise and turn: use short steep stair flights, longer switchbacks, shallow ramps, hanging crossings, and occasional local hydraulic service lifts. Do not reset movement to a flat floor at each chunk edge.
- **Multi-cell landmarks:** each 2 × 2 atlas anchor must be organized around at least one feature that visibly crosses cell boundaries—such as a switchback stair, lift tower, tall workshop bay, suspended freight gantry, carved court, or overhanging public terrace. The landmark owns the silhouette; individual rooms and props fill around it. Exact seam bands must preserve this landmark geometry rather than flatten it.
- **Open terraces:** make some terraces substantial public spaces, not decorative balconies: they need room for circulation and a district function such as a market, wash lines, repair queue, grow racks, freight staging, public benches, or Ritual overflow. Give them railings, cables, supports, and a view into Devil’s Mouth or a large internal shaft. Balance these with tighter, shadowed carved interiors.
- **Outer wall limits:** as a route approaches an outer map boundary, ordinary habitation gives way to thicker irregular rock, collapsed shoulders, sealed lateral galleries, bracing, inspection gates, and maintained turnbacks. The limit must read as a real physical and civic boundary, never as another interchangeable room or an endless mine.
- **Exit:** right mid deck continues to Dig Site past the Hollow (no dig-wall bleed into home). Ashram Heights / Firmament↑ stay locked until late Act 1.
- **Firmament↑** — quieter, calmer light, less FX drama (secrecy).
- **Devil’s Mouth** — darker, heavier fog, and stronger exposure/danger read; it is a powerful crater vista, not a routine downward mining frontier.

Play frames should read: **foreground clutter → mid play strip → far Devil’s Mouth wall/haze**.

---

## Layout character — improvised, varied, not formal (USER direction, 2026-10-02)

Recorded from the user's review of the stairs and reference shots (Blasphemous-style stacked ruins; Terraria stair/room builds). Direction, not yet implemented; the current map is a **placeholder for size, shape and scale**, not the final traversal layout.

- **Origin story drives the shape.** The Hollow is a society that moved into the walls of a cavern a crashed ship hollowed out. Layout should read as *adapted and improvised* around the rock, not formally planned: curved terraces, uneven ledges, walkways that follow the rock face, structures wedged into the wall.
- **No long monotone stretches.** Avoid long runs of one kind of space (a single long flight of stairs, a flat street with buildings along it). Break routes up with landings, doorways, alcoves, changes of direction, and changes of room height, while still flowing together.
- **Every area feels unique.** Nearly every district/area gets its own layout identity. Deliberately plain areas are fine as *contrast* against more intricate ones, but the default is variety, not a flat plane with buildings stacked on it.
- **Stairs belong to rooms.** A stairwell is a carved space with a ceiling and back wall (rock), not a bare wedge in void. Prefer shorter flights with landings over a single 45-degree run.
- **More curvature.** Prefer curved or irregular platform and terrace edges and stepped-tile approximations of slopes over dead-straight platforms and uniform stairs. (Terrain stays tile-built: see `hollow-level-authoring.md` Rule 2, no freehand collision ramps.)
- Because the current layout is placeholder, changes to stairs, level heights and district footprints for this purpose are expected, via the `hollow-map-spec.md` protocol and lint, not by hand.

### Decisions on the variety pass (USER, 2026-10-02)

1. **Level variation: keep the 12 bands.** Allow only small per-run deck offsets (about +/-16-96 px) and half-level landings. No free deck heights, no mezzanines anywhere yet.
2. **Stairwells: visual only.** The street still passes over a flight (one-way decks); stairwells get a carved ceiling and back wall but do not enclose or interrupt the street.
3. **Opening-route slice: limited change.** Only stairwell visuals and landings on its 3 stairs. Its dressing, routes and tests otherwise stay; revisit last.
4. **Variety enforcement: a lint warning**, not a hard error: flat runs longer than a set length with no landing, step or stair get flagged. Which districts stay deliberately plain, and any new place names, are still the user's call.

### Direction from the space review (USER, 2026-10-02)

Answers to [`hollow-space-review.md`](hollow-space-review.md). Direction, not yet built; items 5-6 need a canon decision before any layout change (see the report in the session notes / DEV-STATE).

1. **Mouth side varies by purpose.** The stretches facing the Mouth should differ in how close they come: some areas put out longer terraces that reach a little over it, others are tucked back and closed off from it. It depends on what the area is for, and it should be varied, not uniform.
2. **Lower west gets more area.** Bottom-West should hold more than it does now.
3. **Too wide, not tall enough.** The map feels horizontally stretched. A main story thread is buying housing further and further up the Hollow, so the vertical climb needs to be tall enough that low and high housing contrast strongly.
4. **More vertical separation by rock.** Areas should be separated vertically by rock, with doors or other things to get through, not one continuous stack of open streets.
5. **One Mid-East dig front only.** No second east front.
6. **Annexes are welcome, but nearly everything should have a gameplay purpose.** Small annexes are fine if they do something (no decorative-only rooms).
8. **Decision (USER, 2026-10-02): add levels and separate districts by rock.** The Hollow gets taller by *adding levels* (about 16-18, same 384 px spacing, extra levels at the top and bottom to lengthen the housing climb) and each district becomes a rock-separated pocket joined by doors, gates, shafts or lifts, not a continuous street. Civic width may shrink somewhat. This lifts decision 1's "keep the 12 bands".
9. **Decision (USER, 2026-10-02): a short cantilevered ledge over the Mouth is acceptable** at a cliff edge. It is not a bridge or a structure: Mid Heart stays the only thing that spans the Mouth.
10. **Decision (USER, 2026-10-02): 18 levels, +4 at the top and +2 at the bottom** (the Hollow grows from 12 to 18 levels at the same 384 px spacing). Home Court (spawn) moves down four levels with everything else; the new top levels lengthen the housing climb and the new bottom levels feed Bottom-West and the Cistern.
11. **Decision (USER, 2026-10-02): the rock between districts is solid and not diggable** (painted rock with collision, like the wall columns). Digging stays in the flanks, the Firmament and the floor slab, so doors and gates cannot be bypassed.
12. **Decision (USER, 2026-10-02): a Mouth ledge reaches at most 128 px over the Mouth.**
13. **Direction (USER, 2026-10-02): there are three housing tiers: lower, mid, and high (Ashram).** The climb is lower to mid to Ashram.
14. **Direction (USER, 2026-10-02): doors come in varieties** (plain doors, gates, archways); what each door is for can be decided later.
15. **Direction (USER, 2026-10-02): the new bottom levels, Bottom-West's extra area and every space's purpose are to be worked out from the docs** (AI proposals, user reviews).
16. **Feedback (USER, 2026-10-02) on the 18-level render: too simple.** Too few terraces over the pit and the variety pass is not finished: the map still reads as long straight strips. Wants many more Mouth ledges (varied reach) and more variation in district shapes.
17. **Decision (USER, 2026-10-02): add stepped halls and sloped streets.** Streets may climb a whole level on a long shallow slope (stepped tiles, pitch 2 or more), and a stepped hall is a tall open space joining several levels with a cascade of landings and flights. This lifts decision 1's "no free deck heights, no mezzanines anywhere yet" for these two forms. Wickwork, the Cistern and Glowbeds are to take the shape the docs describe (Wickwork: a broad stepped repair terrace with a diagonal descent; Glowbeds: a stepped planter court with a switchback; Cistern: a tall pressure-basin chamber with galleries and a freight lift).
18. **Direction (USER, 2026-10-02): a dev movement-speed toggle** for crossing the map fast (built: X cycles 1/3/6/12, console `speed <n>`).
19. **Decision (USER, 2026-10-02): stair openings are real openings.** The street deck is absent over the stretch of a flight just before its top, so you climb out of an open stairwell and drop into it from either side; there is no one-way covering and no "[S] stairs down" cue. (Terrace steps under 96 px have no street over them.)
20. **Decision (USER, 2026-10-02): all lifts are removed from the map** (they no longer worked with the 18 levels and the rock between districts). Their connections are now ladders (`LAD_A5`, `LAD_HW2`, `LAD_E1`) and the existing stairs and ladders. The Cistern basin chamber has no freight pier now.
21. **Decision (USER, 2026-10-02): W or S in a ladder's zone climbs at once** (pressed or held, on the floor or in the air), with no jump needed.
7. **Reference (concept art, not production art):** an AI-generated Hollow atlas the user made (stacked inhabited storeys, round and domed rooms, pipes and tanks in the Cistern, bridges over the Mouth, dark void between). Useful for scale, detail and variation only; it is not connected and not a layout.

Implementation plan (architect, 2026-10-02): phases are stairwell visuals, then variable pitch + landings on one non-slice district, then a zero-change `deck_y_at(x, k)` refactor, then stepped terraces, then district-by-district rework. Tracked in [`DEV-STATE.md`](DEV-STATE.md).

## Cultural material and architectural language (approved)

The Hollow is a mature human civilization grown over generations, not a camp made only from wreckage. Its visual vocabulary comes from **four interwoven sources**: crater geology; cultivated underground life and minerals; reclaimed Firstfall remnants; and generations of local human craft, ritual, and household taste. A prop does not need an overt fungal or ship explanation to belong here, but it must feel plausible in a closed, resource-conscious crater society.

- **Local craft and domestic variety:** fired clay, carved and plastered stone, pigments, woven Sutral fibre, patched textiles, shaped metalwork, small furniture, instruments, toys, food presses, wall paintings, household ornaments, and personal shrine objects are all valid. Wood is scarce, repaired, and purposeful—braces, handles, carts, and select household pieces—not the default wall material.
- **Architecture:** draw from the *formal qualities* of Buddhist and Aztec architecture without copying real-world temples, deities, symbols, or sacred objects. Use stepped terraces, deep shadowed thresholds, inset courts, deliberate processional stairways, rhythmic posts and lintels, geometric reliefs, plastered niches, elevated gathering spaces, and heavy carved mass. Adapt all of this to irregular crater walls, patched construction, and side-view play; it should never become a pristine temple complex or a direct cultural pastiche.
- **Social expression:** lower homes use compact, improvised versions of these forms—stoops, painted door marks, tiny niches, shared cook courts, and stepped service terraces. Mid Heart is more formal, civic, and wreckage-integrated. Ashram Heights is the most ordered, ceremonial, and guarded expression, but still inhabited and maintained rather than luxurious.
- **Inherited technology:** people know how to operate lifts, pressure lines, clamps, gauges, lamps, and repair systems through apprenticeship and ritualized procedure. Devices are tactile, patched, and legible—valves, float indicators, lever banks, pressure marks, reused housings—not pristine science-fiction panels or arbitrary steampunk machinery. Rare exact alloys, serial traces, impossible curves, and sealed mechanisms carry the buried Firstfall mystery.
- **Ritual in daily life:** Firmament doctrine appears through ordered lamp placement, inspection seals, Ritual knots, threshold markings, cleaning rituals, and Warden tags. It should read as maintenance culture made sacred, not as banners and cult symbols covering every surface.
- **Living light:** use a family of **Wicklamps** rather than generic medieval lanterns: shallow ceramic/copper vessels, caged capillary wicks, mineral-glass or Brinecrystal lenses, wall niches, hand lamps, and civic reflector assemblies. Amber Wicklamp light is the main safe/social light; dim teal, blue, and violet fungal/mineral light stays local and biological. Keep a varied lighting ecology—glow bowls, reflective niches, guarded pressure lights, and glow mats—without cyber-neon or endless identical sconces.
- **Material storytelling:** Sutral appears as damp fibrous fungal growth, cultivation beds, and spun/bound fibre; Ravelstone as dense impact-altered stone used in supports and platforms; Brinecrystal as salt crust, jars, and pressure-line residue (never generic glowing crystal); Verdigris as oxidized conductor strips embedded in rock and reused fittings. Hullbits and unusually precise Firstfall pieces remain rare, suspicious, and often hidden—never ordinary set dressing.
- **Deposits and state art:** most rock is plain; deposits are recognizable pockets drawn as reusable overlays with **intact** and **depleted** states (cut roots, fractured stone, empty Hullbit socket). Frontier progression (wild frontier → active worksite → established territory) uses modular additions—supports, lamps, pipes, rails, scaffolds, rest equipment, workers—not full room redraws (canon §2, §6, §56).
- **District condition:** high-capacity districts look stocked and busy; strained districts show empty racks, patched equipment, delayed repairs. The world communicates first; UI confirms.

---

## Palette & light language

**Base:** earthy rock / dust / damp stone (slate–brown cave).

**Accents (discipline — two main):**

| Accent | Use |
| --- | --- |
| **Teal-green** | Stone/mineral, cool distance, biolum flecks, dig-vein language |
| **Copper-rust** | Salvage metal, warm oxidize, work tools / pipes |

**Light stops (keep to ~3–4):**

1. **Wicklamp amber** — safe / social / terrace life; varied local vessels rather than stock lanterns  
2. **Cool Devil’s Mouth void** — depth, danger, Firmament quieter than Devil’s Mouth
3. **Salvage metal sheen** — copper catch-lights, not neon chrome  
4. **Soft haze** — far bridges fade; no flat ambient wash  

No rainbow junk. No cyber/neon. No blood-glow / sacred-gold as Act 1 identity. Reef vivid = Act 2 only.

---

## Density, parallax, ambient life

- **Density:** one readable play strip + layered mid/far props that sell a lived place (Blasphemous craft bar).
- **Parallax:** soft DepthBg + Mist + Devil’s Mouth fog layers; far architecture as silhouette, not new camera.
- **Ambient micro-life:** idle NPCs, dust/spores, small looping props (cloth, lamp mote, worker fidget) — world occupied when you’re not talking.
- **Animation hierarchy:** flat readable silhouette first, texture last; player / NPC idle + walk/dig before decorative frame spam.
- **Premium gate:** empty screen → add **life or light**, not more gore/detail noise.

---

## UI restraint

- Hollow should **breathe** — lighting + soft world labels over stacked chrome.
- HUD quiet in the cavern; the stamina bar keeps a stable full width with reserved/blocked segments (never a shrinking “85 / 85”); Trust, district, and Gear surfaces are panels you open, not permanent left-rail clutter.
- Journal / dialogue: soft salvage-craft (Owlboy/Eastward), not relic/altar chrome.
- Matches feel doc: secrecy systems stay social (copy/UI), not arcade fireworks.

---

## Asset strategy & PixelLab

| Priority | Rule |
| --- | --- |
| **Env first** | Terraces, floors, walls, Devil’s Mouth void, lanterns, district props before unique hero sheets |
| **Demo NPCs** | **One settler sprite** reused/cloned across decks — enough for “alive” |
| **Approve-before-gen** | Show exact PixelLab ask; wait for user **approve** — trial gens are scarce |
| **Camera in briefs** | Side-view / sidescroller only — never default top-down / iso Wang |
| **Size** | Prefer **32** or **64** px (dig cells = 64); nearest upscale when needed |

Full how-to: [`art-pipeline.md`](art-pipeline.md). Import / filter: [`godot-best-practices.md`](godot-best-practices.md).

---

## Feel / juice

Juice must read **fair and quiet** — dust, weight, Firmament quieter than Devil’s Mouth. Prefer [`game-feel-best-practices.md`](game-feel-best-practices.md). Do not carnival the Hollow.

---

## Checklist — env / art passes

Use before shipping a Hollow or dig visual pass:

1. **Side-view only** — no oblique / hybrid camera drift.
2. **Devil’s Mouth reads as ink void** — terraces hold detail; center stays dark/deep.
3. **Terrace bands readable** — horizontal walk decks against the void before ornament.
4. **Palette lock** — rock/dust + lantern amber + teal stone + copper metal; strip extra hues.
5. **Light assigns space** — warm lamps on life; cool fill in the shaft; Firmament quieter / Devil’s Mouth darker.
6. **Parallax fog** — far architecture silhouettes without new perspective.
7. **Density + micro-life** — mid/far props + 2–3 ambient loops per district before more unique frames.
8. **UI quiet** — cavern breathes; chrome collapses when not needed.
9. **FX budget** — dig/land dust + rare lamp motes; no bloom/sparkle spam.
10. **PixelLab** — env briefs first; one settler reuse; approve-before-gen; Eastward/Owlboy + `hollow_concept` in the brief.
11. **Tone check** — communal + secrecy, not grief-horror or Catholic body-horror.
12. **Feel align** — Firmament quieter than Devil’s Mouth; social systems stay social ([`game-feel-best-practices.md`](game-feel-best-practices.md)).
