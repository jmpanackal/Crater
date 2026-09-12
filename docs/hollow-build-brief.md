# Hollow build brief — Act 1

Production-ready visual and layout brief for Cursor. This turns the visual bible into one coherent, playable Hollow pass. It is not permission to redesign the economy, add a new camera, or build later acts.

**Approved macro-layout reference:** [`refs/hollow-layout-act1-approved-2026-09-11.png`](refs/hollow-layout-act1-approved-2026-09-11.png). It locks composition and spatial hierarchy, not final in-game art or normal gameplay camera framing. The forthcoming chunk map governs player-scale layout.

**Player-scale chunk map:** [`hollow-chunk-map.md`](hollow-chunk-map.md). The approved opening route (O1–O8) is the implementation-facing baseline for home → Bottom-West → first Mid Heart arrival.

**Full-Hollow chunk atlas:** [`hollow-chunk-atlas.md`](hollow-chunk-atlas.md). It fixes the player-scale chunk topology across both walls, Mid Heart, the lifts, and far-wall dig fronts. Use its seam/camera/system contracts when translating approved chunk art into Godot; an atlas slot is not a final world-pixel coordinate.

**Read first:** [`art-direction.md`](art-direction.md) for the visual locks, [`story.md`](story.md) for fiction, [`materials.md`](materials.md) for the three workplaces, [`terminology-transition.md`](terminology-transition.md) for Trust/Steal copy, and [`../CONTEXT.md`](../CONTEXT.md) for current implementation state.

## Deliverable

Make the Hollow feel like a lived-in vertical settlement built into both walls of the **Devil’s Mouth**. A first playable pass succeeds when a player can immediately read:

1. the Devil’s Mouth is a vast, dangerous vertical void;
2. people live and work around it on many inhabited sub-levels (not three flat platforms);
3. the three workplaces are distinct places with practical outputs;
4. Mid Heart is a large, moored wreckage cluster: the public crossing, material-turn-in center, and daily civic gathering place;
5. civic Presswater lifts are the primary long-distance vertical travel;
6. public excavation is **sideways** braced galleries; Ashram Heights / Firmament digging stays locked at start.

Do not make a town plaza on solid ground. Do not use top-down or oblique perspective. Do not add a surface tease.

## Spatial map (current — supersedes prior stacked-deck and simpler crater rebuilds)

Side-view cross-section. Grid **64 px**. Coordinates are world pixels.

```
Y↑  Ashram Heights (locked) ─── highest band on BOTH walls [gates + residences]
    LEFT: High-West Dig Front ─ directly beneath left Ashram [late, guarded]
    RIGHT: Glowbeds ─────────── directly beneath right Ashram [tidy cultivation]
    RIGHT: Mid-East Dig Front ─ true middle elevation; below Glowbeds
    Mid Heart broad band ────── central, multi-level moored civic cluster
    LEFT: Wickwork ──────────── mid-left workshops; Heart approach
    Lower worker terraces ───── lower-left and lower-right neighborhoods ★ Act 1 spawn
    RIGHT: Cistern ──────────── deep lower-right multi-level utility complex
    Seep / service gallery ──── below/alongside Cistern; threshold, not into Mouth

X→  far west Bottom/High dig fronts … west wall … 288 Mouth void … 736 … east wall … far east Mid dig front
```

| Area | Coordinates / band | Build intent |
| --- | --- | --- |
| **Devil’s Mouth void** | x **288–736**, full height | Broad uninterrupted ink void. No walkable floor across the shaft. Fog, far-wall silhouettes, faint wreck ribs only. Not the routine dig route. |
| **Ashram Heights** | Highest inhabited band on both walls | Guarded late-Act-1 residential ward beneath the Firmament. Gate + collision block. Not free at start. |
| **High-West Dig Front** | Directly below left Ashram Heights | Late official guarded lateral gallery; rare Records/Hullbit finds. It never grants the separate hidden upward route. |
| **Glowbeds** | Directly below right Ashram Heights; upper-right wall | Broad, tidy cultivation gallery + terrace; stepped planters, fiber racks; right civic-lift stop. |
| **Wickwork** | y **512**; bay into left rock | Mid-left workshop band with lateral bays; approaches Mid Heart. |
| **Mid Heart** | broad y **352–640** band across the Mouth | Large **moored wreckage Heart cluster**: three or four major lightened rafts, plus several smaller attached decks. The concealed wreck’s stabilizer makes the major rafts hover or carry implausibly little weight; practical anchors, clamps, cables, docks, and emergency catches make it safe enough for daily life. Build 7–10 substantial terraces with distinct civic functions—Holding hall, Joss turn-in, requisition, Glowration, Wickwork repair, freight, notices, and gathering decks. **Not** one long flat bridge or a single island. |
| **Mid allotments** | y **640**; left wall | Residential / allotment sub-level under Wickwork. |
| **Mid-East Dig Front** | True middle elevation on far east wall; below Glowbeds, above Cistern | Mid Act 1; wet, pressurized shock-fault/service layer with ambiguous corroded remnants. Reached through a long inhabited east-wall approach. |
| **Lower working terraces** | Low wall neighborhoods, primarily west but with a real east counterpart | Crowded worker band; **player spawn**; left civic-lift lower stop; no long flat cross-Mouth floor. |
| **Lower-East service band** | Between Mid-East approach and the deep Cistern | Worker housing, freight yards, repair alcoves, dock/clinic functions, and service corridors—prevents the lower-right from becoming a Cistern dead end. |
| **Cistern** | Deep lower-right, well below Mid Heart | Multi-level basin, pipes, pressure gear, freight alcoves, and lower service walkways; right civic-lift lower stop. |
| **Seep gallery** | Below/alongside deep Cistern | Lower crater-wall seep/service threshold (sideways; not into Mouth). |
| **Bottom-West Dig Front** | Far west from Lower working terraces | Early Act 1 civic expansion; rough, crowded braced galleries and the Steward’s first district work. Starter Materials; teaches public lateral mining. |
| **Mid-East Dig Front** | Far east at middle elevation, below Glowbeds and above Cistern | Mid Act 1; wet, pressurized shock-fault/service layer with ambiguous corroded remnants. Stronger Cistern/Wickwork-linked Materials and contextual puzzles. |
| **High-West Dig Front** | Far west, directly below left Ashram Heights | Late Act 1, guarded official lateral gallery near the Firmament. Cleaner, rarer Records/Hullbit-level finds; creates but does not grant the separate secret upward route. |

### Mid Heart route graph (approved)

Mid Heart is a dense, open civic loop built around four major wreckage rafts, not a single ceremonial bridge:

| Raft | Primary role | Principal connection |
| --- | --- | --- |
| **Holding Raft** | Largest, slightly raised two-level hall for daily Holding, announcements, Council appearances, queues, benches, and broad gathering space | Center of the cluster; carries the main public route without becoming a dead end |
| **West Exchange Raft** | Joss Materials turn-in, sanctioned requisitions, Wickwork repair intake, and freight receiving | Wickwork / left civic-lift approach |
| **East Service Raft** | Glowration distribution, medic/care room, notices, small shops, and civic offices | Right civic-lift / Cistern approach |
| **Lower Freight Raft** | Carts, cargo transfer, dock machinery, and maintenance access | Lower service loop beneath the public cluster |

The obvious ceremonial/public route is **West Exchange → Holding → East Service**. A second lower freight-and-service loop uses ramps, short bridges, and smaller attached decks to connect all four rafts. It must create real route choice and later shortcuts while retaining open gaps, visible depth, and a plainly readable civic center.

### Public excavation progression (approved)

Public excavation is a journey to one of three outer-wall destinations, never a diggable wall beside Mid Heart and never a routine descent into Devil’s Mouth:

1. **Bottom-West** — opens early from Lower working terraces; first civic expansion and starter public work.
2. **Mid-East** — opens mid Act 1 at middle east-wall height, below Glowbeds and above the deep Cistern; pressure, seep, shock-fractured service traces, and stronger Materials.
3. **High-West** — opens late directly below left Ashram Heights; official guarded lateral work near the Firmament, with rare Records/Hullbit finds and proximity to the later secret roof route.

Each front needs a long continuous approach through inhabited wall neighborhoods, a dispatch/checkpoint, braced threshold, several playable dig chambers, and a locked deeper continuation. No normal Mid Heart camera frame may show both the Heart and a dig chamber.

### Impact-material distribution (approved)

- **Bottom-West:** loose impact-fill and ordinary lateral wall rock; generous common Materials, almost no legible ship evidence. Its early availability is civic and structural, not a claim that it is nearer the ship.
- **Mid-East:** a middle-east-wall fault affected by the impact and old service runs; pressurized mineral resources plus corroded, still-ambiguous technical remnants.
- **High-West:** near-rim collapse and settlement layers hold the rarer, more intact outward-thrown debris—Hullbits, sealed components, and Records. It remains guarded and late.
- **Devil’s Mouth:** do not place the easy early wreck source here. The dense wreck mass and true explanation stay beneath the open void for Act 3.

### Asymmetry and interlocking mass (approved)

Do not arrange the Hollow as parallel rows. Wall districts must vary in height, depth, and overlap: some are large carved complexes spanning multiple terrace levels, some project over smaller routes, and some recess deeply into the walls. The east wall must carry comparable civic density to the west—Glowbeds beneath its Ashram arm, a middle-height Mid-East approach/trade-service band, broad wall neighborhoods and interiors, a lower-east service band, and a Cistern complex far below Mid Heart that extends vertically through multiple service levels. Mid Heart needs **7–10** meaningful offset terraces/decks across its four major rafts, with open gaps still preserving the Mouth.

### Society bands (not a three-floor town)

| Civic anchor | Sub-levels (examples) | Read |
| --- | --- | --- |
| **Upper** | Ashram Heights on both walls; High-West below the left arm; Glowbeds main + hang below the right arm | Quieter, orderly, still inhabited |
| **Mid** | Wickwork, Mid Heart, allotment street | Markets, dispatch, social circulation |
| **Lower** | Working terraces, lower-east service band, deep Cistern, seep | Crowded, practical, worker-oriented |

Higher bands read as residence / responsibility / keys / neighbors / scrutiny — not arbitrary videogame gates. Advancement uses **Trust** + Tallies / relocation cost — **no** separate Contribution meter.

### Act 1 housing progression (approved)

| Home | Location / access | Player-facing use | Social read |
| --- | --- | --- | --- |
| **Lower-terrace unit** | Starting private unit off a shared worker courtyard | Bed/rest-save, lockbox storage, small work surface, deliveries, visitors | Crowded, practical, communal wash/cook space and audible neighbors |
| **Mid-band apartment** | Mid allotments/Wickwork area; requires Trust, Tallies, and story clearance | More storage, proper workbench, shared balcony, deliveries, visitors | Better-kept two-room home; responsibility and proximity to civic work, not luxury |
| **Ashram Heights residence** | Guarded upper ward; late Act 1, requires Trust, Tallies/relocation cost, and story clearance | Same core home functions plus privacy for story meetings and plausible access to restricted maintenance routes | Quiet, tidy, ordered, and watched; privilege comes with scrutiny |

All homes support storage, deliveries, visitors, and rest/save. Do not turn moves into abstract stat purchases. Any illicit relocation is a named one-off narrative favor, never a generic repeatable bribe system.

### Council Wardens (approved)

Wardens are Council-appointed civic safety workers who uphold Firmament doctrine. They operate Ashram Heights gates, maintenance access, lift/dock safety, Holding crowd management, relic protocols, and shortage inspections. Place them visibly at gate landings, docks, crowd edges, and restricted service routes—not as omnipresent police. Their immediate presence sharply raises Witness Risk for forbidden actions, especially theft when Shortage Risk is already high and unauthorized upper digging. Getting caught costs Trust and can impose repayment, a forced civic shift, or delayed access; it never causes an instant fail state or a softlock. Patrols, checkpoints, posted inspections, and NPC warnings must be readable before the player commits.

### Horizontal-play rule

Each workplace needs a **horizontal public terrace** and at least one **carved side room** on the same plane. Prefer continuous walk colliders; visual steps are non-blocking when needed. Player should usually walk sideways through a district before changing level.

### Building exploration layer (approved)

The labeled production districts are anchors, not the full city. Build wall neighborhoods with a mix of: bespoke playable interiors; repeatable inhabited rooms; quest/NPC doors; and ambient façades with windows, sound, deliveries, laundry, and silhouettes. Reserve physical depth behind the visible wall face for homes, courtyards, shared kitchens, washhouses, clinics, maker bays, storage, Warden posts, clerks, Holding prep rooms, and gallery corridors.

| Find type | Plausible locations | Reward intent |
| --- | --- | --- |
| **Human** | Homes, shops, courtyards, kitchens | Tallies, Materials, notes, favors, minor shortcuts |
| **Work-rig** | Repair bays, maintenance rooms, hidden tool junctions | A module or new upgrade path |
| **Story Record** | Ledgers, letters, restricted offices, old service routes | Must unlock a route, tool junction, NPC consequence, or doctrine contradiction—not journal text only |
| **Buried wreckage** | Rare sealed hatches, concealed service rooms, intact components | Carefully paced evidence or forbidden capability; never commonplace alien loot |

Use contextual spatial puzzles (Presswater routing, maintenance sequences, quiet-dig seams, delivery discrepancies, disguised old hatches). Avoid generic key doors, glowing chest loops, and abstract percentage buffs; discoveries should create actions, routes, work-rig modules, civic favors, or story leverage.

**Work-rig choices:** the player wears one integrated Mouthworker rig with three physical modification mounts—**Toolhead** (digging/discovery), **Harness** (movement/recovery), and **Utility pack** (secrecy/civic utility)—rather than carrying separate tools. Place important module choices at physical repair bays, maintenance stations, sealed hatch rooms, or recovered components. A choice offers two or three strong modules with a real downside; the limited mounts prevent one universal build. Essential traversal upgrades are never permanently missable. Optional approach-changing modules are semi-permanent and can be swapped only at home or a proper workbench for a meaningful refit cost. Theft modules alter risk and approach; no equipment grants passive Trust.

### Lift network (Presswater → service)

| Lift | Stops | Role |
| --- | --- | --- |
| **Left civic lift** (`Hollow/CivicLift`, id `heart`) | High-West / Wickwork-Mid / Lower work | Fixed public cage tight against the left wall. Guaranteed no-softlock route. |
| **Right civic lift** (`Hollow/FreightLift`) | Glowbeds / Mid-East / lower-east service / deep Cistern | Fixed public/freight cage tight against the right wall. Crews, Materials, and canisters. |

Controls: stand on cage, **W/S** to ride. Physical slow platforms (not fast travel). **Do not** use Tether Pull as public transport.

**Presswater rules (no softlock):**

| Presswater | Right civic lift | Left civic lift |
| --- | --- | --- |
| Healthy (≥3) | Full speed | Full speed |
| Thin (2) | Slow / delayed dock | Full speed |
| At protected reserve (1) | Parked (hint: “Presswater thin — lift parked”) | **Always runs** |

Steal never takes Presswater below reserve (`Districts.divert_good`). At campaign start goods sit at reserve — the left civic lift is the guaranteed route until Cistern production rises. Thin Presswater may also dim nonessential Heart equipment or settle a raft harmlessly onto its catch-rail; it must never cause a fall or softlock.

### Local ladders (secondary only)

| Ladder | Span | Role |
| --- | --- | --- |
| `LadderUpper` | Ashram arm ↔ adjacent High-West or Glowbeds terraces | Short local residence/service climb |
| `LadderMid` | Wick ↔ mid allotment | Maintenance |
| `LadderCistern` | Lower work ↔ Cistern | Emergency when freight is parked |

## Composition and layers

1. **Foreground:** rail posts, hanging rope, nearby pipes — never block the player.
2. **Playable middle strip:** terrace / Heart deck.
3. **Midground:** district props, lift cages, lamps, NPCs, lit windows / laundry / distant figures.
4. **Far layer:** opposite cliff silhouettes, retained hull ribs, cables in fog.
5. **Void:** darkest, emptiest. Never fill with decorative city panels or a floor.

Avoid rectangular BG room boxes, long straight deck rows, and a single ladder shaft as the city spine.

### What the Devil’s Mouth is—and is not

Powerful because of **scale, exposure, and history** (crashed colony ship crater) — not supernatural. Ordinary public mining is **lateral**. The Mouth remains a feared, mostly unworked void until later story beats.

## District kits

| District | Must show | Light | Do not show |
| --- | --- | --- | --- |
| **Glowbeds** | Stepped planters, fiber rack, harvest basket | Amber + muted teal growth | Pristine greenhouse / neon fungi |
| **Wickwork** | Spools, rope, lamp bench, binding racks, lateral repair bays | Warm repair amber | Shop-counter UI look / wreckage as its core identity |
| **Mid Heart** | Shaved hull plates, sealed ribs, reused hatches, hydraulic clamps, docking collars, catch-rails, ordered Holding fixtures, Joss counter, freight | Civic amber + oxidized wreck-metal shadows | Generic fungal-wood market / pristine spaceship / a single bridge |
| **Cistern** | Basin, gauges, copper pipe, freight platform | Cool blue-white + one amber safety | Sci-fi lab / bright aquarium |

**NPC baseline:** Pell (Glowbeds), Rook (Wickwork), Sila (Cistern), Joss (Mid Heart).

## Palette and light

| Role | Anchor |
| --- | --- |
| Rock / decks | `#3B403C`, `#62564A` |
| Salvage structure | `#A56848`, patina `#4E837C` |
| Safe social light | `#E3A65B` |
| Growth / distance | `#5C9B82` |
| Devil’s Mouth | `#091419` |
| Cistern utility | `#8BB5C4` |

## Implementation map (code)

| Concern | Primary files |
| --- | --- |
| Metrics | `hollow_layout.gd` |
| Collision decks / ramps | `hollow_decks.gd` on `Hollow/Floor` |
| Floor / bridge paint | `hollow_floor.gd`, `hollow_ledge.gd`, `hollow_bridge.gd` |
| Lift network | `hollow_lift.gd` → current `CivicLift` (left civic) + `FreightLift` (right civic); retire `LeftServiceLift` as a main-route role |
| Local ladders | `hollow_climb.gd` → `LadderCistern`, `LadderMid`, `LadderUpper` |
| Ambiance / Ashram Heights / life | `hollow_ambiance.gd` |
| Dig threshold | `dig_approach.gd` |
| Camera dig blend | `camera_follow.gd` |
| Scene tree | `main.tscn` Hollow subtree |

## Cursor acceptance checklist

- [x] Devil’s Mouth reads as a broad central void (x 288–736).
- [x] Multi-band society with inhabited sub-levels (not three platforms).
- [ ] Mid Heart reads as a large moored wreckage Heart cluster with 7–10 substantial terraces and distinct civic functions.
- [ ] Two wall-mounted Presswater civic lifts; ladders local only.
- [x] Presswater thin/reserve cannot softlock (essential left civic lift).
- [x] Spawn on lower working terraces; Ashram Heights locked.
- [x] Right exit reads as braced lateral civic excavation.
- [x] Materials / District production / Work Orders / Trust / Steal preserved.
- [x] Layout + lift tests updated.

## Playtest path

1. Spawn on **lower working terraces** (left of Mouth) → walk to the **left civic lift** → **W/S** up to Mid.
2. Cross **Mid Heart** decks → talk to **Joss** → continue right to civic excavation threshold → dig past x 1024.
3. Ride the left civic lift up to **Glowbeds**; explore the gallery left.
4. From Mid or Lower, reach **Cistern** via the right civic lift (healthy Presswater) or lower span + emergency ladder.
5. Confirm **Ashram Heights** gate is visible and blocked; no Firmament dig from start.
6. Drain Presswater to reserve (via Steal tests / debug): the right civic lift parks; the left civic lift still rides its public stops.

## Suggested Cursor task prompt

> Rebuild or polish the Hollow using `docs/hollow-build-brief.md` as the source of truth. Keep the Devil’s Mouth as a broad central void, multi-band sub-levels, Mid Heart as a large moored wreckage Heart cluster, and two wall-mounted Presswater civic lifts (left lift essential). Preserve Materials / District production / Work Orders / Trust. Match `docs/art-direction.md`. Verify camera frames at Glowbeds, Mid Heart, Wickwork, Cistern, every lift stop, residence bands, and excavation thresholds before reporting completion.
