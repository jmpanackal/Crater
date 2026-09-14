# Full Hollow chunk atlas design

## Status and purpose

**Status:** proposed for review. Do not treat the current prototype atlas as the final topology until this design is approved.

The Hollow needs one complete, implementation-facing cross-section: not a list of landmark districts and not a single panoramic camera shot. The **full chunk atlas** will reserve every spatial piece that makes up the Act 1 Hollow, including walkable settlement, interiors, lift shafts, Mid Heart rafts, bounded excavations, and the visual depth of Devil's Mouth.

The atlas has two jobs:

1. allow art, narrative, and level design to judge whether every player-scale image fits its actual place in the whole Hollow; and
2. become the handoff topology for Godot regions/scenes, collision seams, camera bounds, and gameplay systems.

This specification preserves the existing fiction: Devil's Mouth is a vast impact crater from the crashed colony ship; civic excavation proceeds sideways into outer wall galleries; the Firmament is above the high inhabited bands; Mid Heart is a moored wreckage civic cluster; and the Hollow is a large multilevel society rather than a three-platform town.

## Design principles

- **Everything has a place.** The atlas has no unexplained blank territory. Every location belongs to a chunk: playable terrain, destructible terrain, interior/transition, or visual-depth scene. The broadest open area is the deliberately represented Devil's Mouth mosaic, not absence from the map.
- **A chunk is a normal-camera promise.** It defines a local playable/cinematic view, not a uniform puzzle tile or one-screen room. A large carved complex can span multiple chunks; an interior can be its own chunk.
- **Images follow approval.** A slot always has an ID and contract. It shows a visual reference only after approval. Draft art is kept outside the atlas; its on-map slot stays labeled `draft — image withheld`.
- **Seams are first-class.** Every traversable edge names the exact neighboring chunk and mode of movement. Camera cuts, overlaps, ramps, doors, lifts, and destructible boundaries are explicit.
- **The player can improvise inside, not outside, a dig envelope.** Destructible excavations allow many player-cut paths while retaining authored scale, story pacing, collision limits, visual composition, and stable room transitions.
- **Districts visibly grow.** Production upgrades must claim prepared physical space, add or repurpose buildings, and change daily activity. They are not invisible number increases behind an unchanged backdrop.
- **No false global shot.** The atlas is an editorial/map view only. Normal gameplay never displays the entire settlement at once.

## Locked atlas grid

The canonical full-Hollow atlas is an **18-column × 16-row logical grid**: **288 stable composition cells**. This is the definitive spatial canvas for all current and future chunk work.

- Columns **0–2** are the far-west outward frontier and Bottom-West/High-West dig space.
- Columns **3–5** are the inhabited west wall.
- Columns **6–11** are Devil's Mouth and the Mid Heart band. The void occupies these cells except where a Mid Heart raft/deck intentionally claims a cell; all remaining cells have explicit fog/depth/wreck visual ownership.
- Columns **12–14** are the inhabited east wall.
- Columns **15–17** are the far-east approach and Mid-East dig frontier.
- Rows progress from Firmament-adjacent upper settlement through Ashram, upper work/cultivation, mid bands and Mid Heart, lower worker/service districts, deep Cistern, and the visual black descent.

A cell is a stable **composition slot**, not a promise of one camera screen or a final Godot pixel rectangle. A normal camera can span multiple cells; every cell still receives a fixed ID, type, neighbor seams, visual contract, and eventually an approved reference image. A full composition must account for every one of the 288 cells; the only difference is whether a cell is fixed play, interior, transit, destructible dig, future-locked, or visual depth.

### Hierarchical visual-production lock

The full grid is not generated as 288 independent images, and a single macro illustration cannot substitute for final player-scale images. Use this production pyramid instead:

| Level | Unit | Count | Purpose |
| --- | --- | ---: | --- |
| 0 | 18 × 16 logical board | 1 | Canonical non-AI topology: every route, district, lift, dig front, depth cell, and growth socket. |
| 1 | 6 × 4 regional master | 12 | Composition reference for one quarter-band of the Hollow; follows the exact Level 0 cells below it. |
| 2A | 2 × 2 anchor master | 72 | One shared, high-resolution 16:9 composition whose four quadrants map directly to four Level 0 cells. |
| 2B | 2 × 2 bridge master | Per cross-anchor seam | Overlapping composition that repairs one important seam crossing an anchor boundary; contributes only a shared narrow border band. |
| 3 | 16:9 child frame | 288 | Crop from its parent anchor master; carries parent provenance and exact internal neighbor boundaries. |

Level 1 is partitioned 3 columns × 4 rows. Each Level 1 region partitions into 3 × 2 Level 2A anchor masters, each covering exactly 2 × 2 final cells. This fits the 18 × 16 board without padding, invented cells, or asymmetric edge exceptions. Because no non-overlapping 2 × 2 partition can contain every neighboring pair, a Level 2B bridge master is required for each important walkable seam crossing an anchor boundary. It provides a narrow shared seam band for both child frames rather than a competing full-cell image.

Generated macro imagery may help judge mood and large silhouette only. It is never allowed to move the player home from the lower-left, move Ashram Heights out of the wall strata, turn excavation downward into Devil's Mouth, or override the fixed row/column placement below.

### Locked capacity and row hierarchy

The west wall and east wall each contain 96 cells. Each reserves **58 active-core cells**, **22 occupied growth/discovery cells**, and **16 transit/visual-support cells**. The center contains 18 Mid Heart cells, 8 future deep/secret cells, and 70 Devil's Mouth visual-depth cells.

Reserved cells are never empty map blanks. Before conversion, they have an explicit believable use: fallow cultivation, storage, a shuttered but occupied work bay, an old tank, a quiet residence, an unused service passage, a delivery yard, a façade with inhabitants, or a sealed/hidden room. Their atlas state describes both the current use and the later conversion. The compositor must expose that current use directly in every cell; a label such as “reserve” by itself is invalid.

| Rows | Locked content |
| --- | --- |
| 0 | Firmament/roof visual cells |
| 1–2 | Ashram Heights on both walls |
| 3–4 | High-West on the left; Glowbeds on the right |
| 5–6 | Wickwork on the left; Mid-East approach begins on the right |
| 6–8 | Mid Heart's separated raft/deck cells through the central Mouth band |
| 7–8 | Mid-East dig front at true middle-east height |
| 9–11 | Lower worker neighborhoods; Home Court at row 11 in lower-left band |
| 12–13 | Bottom-West approach/dig; lower-east service and Cistern upper levels |
| 14–15 | Deep Bottom-West boundary; Cistern basin/Seep; deep void/wreck depth |

## Atlas piece classes

| Class | Player interaction | Atlas treatment | Godot translation |
| --- | --- | --- | --- |
| `fixed-play` | Walk, jump, use doors, local ramps/ladders | Bounded solid chunk | Region/scene with tile and collision bounds |
| `interior` | Enter a room or carved bay from a parent exterior | Dedicated slot nested beside/behind parent | Interior scene with door seam |
| `transit` | Lift, short bridge, stairs, dock, crossover | Narrow but explicit connector | Shared transition/camera seam, platform data |
| `destructible-dig` | Carve routes inside a predefined envelope | Filled solid volume with entrance, exits, and hard boundaries | Destructible tilefield plus immutable perimeter / anchors |
| `visual-depth` | Usually not entered in Act 1 | Explicit void/fog/wreck/mid-distance slot | Parallax/background scene with camera ownership |
| `future-locked` | Recognizable but unreachable until its gate | Reserved, named piece with lock condition | Disabled seam / collision gate plus future scene reference |

## Complete Act 1 spatial mosaic

The atlas uses irregular rectangular or stepped chunk footprints. Shapes may overlap vertically or recess behind each other; they must not resolve into identical grid squares or flat parallel floor rows.

### West wall

| Group | Required pieces | Purpose / direction |
| --- | --- | --- |
| Ashram west | high lift landing, guarded threshold, upper residence court, private residence interiors | Highest west inhabited band, immediately below Firmament; sacred/prestigious and watched. |
| High-West | guarded approach, dispatch/checkpoint, dig staging, 5–7 destructible dig-envelope pieces, locked deep boundary | Official late lateral work directly under Ashram. It never becomes the hidden upward route. |
| Wickwork | public terrace, repair bays, lamp/bindcord production rooms, workbench room, mid lift landing | Mid-left production complex with substantial sideways play. |
| Mid allotments | shared street, mid-home exterior, apartment interior, wash/cook yard, connector passages | Later home band and lived-in mid-level density. |
| Lower west | Home Court (`H-4-11`), Lower Switchback (`H-3-11`), family interiors, maker alcoves, worker courts, West Dispatch Yard (`H-2-11`), lower lift landing (`H-5-11`) | Starting civic neighborhood that gives the player a home and long lateral route. |
| Bottom-West | outward approach, threshold, 5–7 destructible expansion pieces, optional collapsed chamber, locked deep boundary | Early sanctioned outward work; the Mouth disappears as the route travels west. |

### Mid Heart

Mid Heart is one large region of many chunks, not a single plaza. It must reserve at least 12 pieces: four major raft anchors and eight or more attached/connector chunks. Open gaps between them belong to Devil's Mouth visual-depth pieces.

| Major raft | Required subchunks |
| --- | --- |
| West Exchange | west dock, Joss Materials counter, Approved Gear order/repair intake, attached freight ledge |
| Ritual Raft *(formerly Holding)* | upper Ritual hall, lower Ritual floor, the Pulse, queue/bench terrace, council/announcement edge |
| East Service | Glowbeds ration queue, medic/care room, notices/small shops, right dock |
| Lower Freight | cargo deck, transfer machinery, west and east maintenance loops, emergency catch rail |

The cluster connects to Wickwork/left lift on the west and the lower-east/right-lift approach on the east. It has no direct public excavation face.

### East wall

| Group | Required pieces | Purpose / direction |
| --- | --- | --- |
| Ashram east | high lift landing, guarded threshold, ordered residence courts and interiors | Highest east inhabited band beneath Firmament. |
| Glowbeds | upper terrace, planters/fiber racks, cultivation rooms, drying/packing bay, lift landing | Directly below east Ashram; tidy and protected. |
| Mid-East | wall approach street, freight/service passage, checkpoint, staging, 6–8 destructible dig-envelope pieces, locked deep boundary | True middle height, below Glowbeds and well above Cistern. Wet/pressurized shock-fault work. |
| Lower-east service | residential/service street, clinic, freight dock, repair corridor, lift landing, interior service rooms | A substantial dense band—not a dead-end beside Cistern. |
| Cistern and seep | upper pipe/service level, freight level, pressure basin level, sealant room, deep walkways, seep gallery | Far below Mid Heart, linked by right freight lift and emergency local route. |

### Devil's Mouth visual mosaic

Devil's Mouth is not a blank backdrop. It is a vertical matrix of explicit `visual-depth` chunks, generally arranged in three columns—west near-wall, central fog/depth, east near-wall—and at least five vertical bands:

1. **Upper Mouth:** high-wall fog, cables, distant minor dwellings, no routine access; Firmament is not exposed from ordinary Mid Heart views.
2. **Heart band:** nearby void gaps, catch rails/cables, haze, occasional distant wreck ribs; supports Mid Heart’s scale.
3. **Lower settlement band:** deep-light silhouettes, retention debris, far maintenance rails, largely non-walkable.
4. **Deep wreck haze:** ambiguous ship scars and submerged shapes, no legible reveal.
5. **Black descent:** near-opaque lower void, reserved for future Act 3 descent topology.

These pieces have parallax, lighting, and occlusion contracts rather than ordinary collision. Select future pieces may later become playable descent chunks; no current atlas coordinate needs to be discarded to make that possible.

## Destructible excavation envelopes

Each dig front has a **fixed outer envelope** of destructible chunks. A player may carve a chosen route through destructible cells inside the envelope, but the level boundary is authored and visible in fiction.

| Front | Act / geography | Envelope | Boundaries | Expected player choice |
| --- | --- | --- | --- | --- |
| Bottom-West | Early; far low west | 5–7 connected chunks, broad and comparatively low | impact-compacted bedrock, brace line, collapse face, locked deep seam | two or three viable horizontal/diagonal routes; optional collapsed side chamber |
| Mid-East | Mid Act 1; far middle east | 6–8 connected chunks, taller/branchier than Bottom-West | pressurized seams, flooding pockets, old sealed service wall, civic brace limit | routes balance pressure routing, safer material veins, and ambiguous service traces |
| High-West | Late Act 1; directly below Ashram west | 5–7 constrained chunks with controlled staging | guarded permit boundary, near-rim collapse rock, sealed component strata, locked roof-side limit | deliberate routes through rarer material; never a shortcut into the forbidden upward dig |

### Size and collision contract

Use **one to two normal camera widths** per destructible chunk, with roughly one camera height of meaningful dig volume. The outer envelope at each front therefore spans about 6–10 normal camera widths in total; it is large enough for route discovery and later revisions, but small enough for authored atmosphere and implementation performance.

The exact world-tile dimensions are set only after the game camera’s final width and tile scale are locked. The atlas records the shape and seams in camera-relative units now. Every envelope needs:

- immutable boundary rock or a diegetic barrier on all non-exit edges;
- enough thickness around each intended route to make player-cut horizontal, shallow diagonal, and local vertical options meaningful;
- anchored supports/fixtures that are never destroyed;
- at least one clear return route, no accidental path into Devil's Mouth, and no required destructible action that can softlock;
- a deeper continuation marked locked until the appropriate work order/story state.

The player may create messy personal tunnels, but those tunnels are confined to this envelope and never create unplanned links to residential chunks, lifts, Ashram roof routes, or the Mouth.

## District growth, upgrades, and dynamic states

Production districts need enough area to read as living workplaces before an upgrade and to become visibly larger, busier, and more capable afterward. The atlas therefore reserves **growth sockets** beside every production anchor: at least two adjacent interior/exterior subchunks plus one flexible service/yard seam. These are not blank space. Before use, they have a named low-intensity role—storage, a quiet yard, old equipment, a closed work bay, a fallow bed, or a service passage. After an upgrade, they become active construction, work, cultivation, storage, or distribution space.

The upgrade unlock source is recorded as **`discovery unlock`** in the atlas. Per [`mechanics-canon.md`](../../mechanics-canon.md) §23 and §26, district projects combine **knowledge (Records) + physical resources (Materials/Components) + production capacity**; the spatial plan must not invent a new economy item. Exact project costs remain OPEN. Atlas slots record the source, the required story state, and the visible construction consequence separately from Materials costs.

### Required district growth reserves

| District | Base footprint | Reserved growth sockets | Visual upgrade outcome | Dynamic states |
| --- | --- | --- | --- | --- |
| **Glowbeds** | tidy upper-right cultivation terrace, planters, fiber racks, packing/drying rooms | fallow cultivation hang, closed humid room, storage/packing yard | additional stepped beds, a tended humid gallery, more drying lines/fiber racks, new grow-light niches, more workers | inoculated/fallow → sprouting → mature harvest → picked/drying → recovering; guarded/tidy throughout |
| **Wickwork** | mid-left repair terrace, binding racks, lamp bench and work bays | shuttered repair bay, spool loft, covered loading sideyard | new binding bench/loom, repair line, lamp service nook, freight intake and visible repair queues | quiet intake → active repair shift → backlog/overflow → upgraded multi-bench operation; shortages visibly thin spools and lamp stock |
| **Cistern** | deep lower-right pipes, basin, pressure gear, freight and sealant rooms | sealed side tank, unused pump alcove, lower pressure chamber/service walk | extra pressure train, new settling tank, larger freight staging, additional controlled water route and service crew | Cistern condition (comfortable/stable/strained/shortage — names tunable); maintenance shutdown; leak repair; upgraded steady operation. States must preserve the left-lift no-softlock rule. |
| **Mid Heart civic support** | existing separate rafts and civic counters | docked utility annex, closed counter, catch-rail service deck | a repaired civic counter, expanded ration/service point, working dock machinery, safer/more active freight flow | civic-cycle phases (Rousing / Working / Gathering / Ritual crowd), delivery arrival, Cistern-strain dimming, harmless catch-rail settle; never a falling/failure catastrophe |

### Dynamic-area rules

- A state change must affect **layout activity, props, NPC placement, light, sound, or accessible micro-routes**, not only a sign or particle effect.
- The fixed traversal spine stays readable in every state. A growing bed may narrow a side path or open a maintenance shortcut, but must not erase the player’s essential route.
- Dynamic state is bounded. Crops and machinery change inside named slots; they do not expand through homes, lift shafts, Ashram gates, or unexplained map space.
- Work Orders, delivery activity, production shortages, repair demands, and story events may select a state. A visible state must have a documented player-facing consequence or story implication.
- Any upgrade construction state needs a temporary scaffold/closed-bay presentation and a safe detour. It must never make a district inaccessible.

### Production chunk state contract

Every production or civic-support slot adds:

```text
growth_role         base-work / reserve / construction / upgraded-work / distribution
upgrade_source      discovery unlock (name pending), Materials, story state, or a combination
state_profiles      named visual/activity states and their triggers
state_changes       props, NPCs, lighting, route/access and production consequences
reserve_conversion  the named pre-upgrade use and exact upgraded function
```

This means the atlas will show both the **current Act 1 footprint** and the later claimed space. A future chunk image can be versioned per state while staying in the same stable map slot.

## Per-piece contract

Every slot in the atlas data must carry the following fields:

```text
id                 stable coordinate ID, e.g. H-4-11 or VM-8-4
display_name       user-facing working name
class              fixed-play / interior / transit / destructible-dig / visual-depth / future-locked
status             planned / draft / approved / revision-needed / implemented
atlas_bounds       x, y, width, height in atlas design units
band               upper / mid / lower / deep / void and wall/Heart side
parent             optional complex or neighborhood owner
seams              destination ID, reciprocal edge, traversal type, boundary height/grade, state gate, camera handoff
camera_contract    local framing, prohibited global reveal, parallax/void ownership
visual_contract    required materials, lighting, silhouette and prohibited reads
systems            district production, home, lift, Warden, Trust/theft, Work Order, rig, etc.
image              approved reference filename plus date; absent until approval
growth_role         optional base/reserve/construction/upgraded/distribution role
upgrade_source      optional discovery/Materials/story prerequisite; final item name may be pending
state_profiles      optional named visual and gameplay states
godot_handoff      scene path, origin, collision extent, implementation status; blank until constructed
```

## Atlas interface behavior

The durable local atlas will show the whole mosaic with zoom and pan. It must allow a user to:

- see all chunk footprints at once;
- filter by class, status, progression, wall, and system owner;
- click a chunk to see its full contract, adjacent seams, composition-master history, and Godot handoff fields; a draft master remains visibly placed across its shared bounds and is clearly marked non-canonical;
- toggle visual-depth pieces on/off only for diagram clarity, never delete them;
- render composition masters once at their actual shared atlas bounds, with transparent selectable coordinate slots above them; normal-camera crops are implementation references and must not appear as disconnected thumbnail cards in the atlas;
- flag an approved image as `revision-needed` without removing it, so placement history remains clear.

The atlas is a planning tool, not shipped UI and not a source of runtime coordinates. It uses a plain, editable data source so a Godot exporter or a developer can consume the same IDs/seams later.

## Workflow

1. Build the complete fixed mosaic and assign every ID/contract before generating more player-scale art.
2. Generate a neighboring pair (or wider local strip) from their shared seam contract. Approve the strip before cropping it into coordinate-keyed reference images.
3. Review it at player scale and in atlas context.
4. On approval, copy the image to `docs/refs/`, add filename/date to the atlas slot, and set status `approved`.
5. Translate approved slots into Godot in logical neighborhood batches. Fill `godot_handoff` as each scene/region is made.
6. After an implementation change, test every changed seam bidirectionally, test camera transitions, and verify relevant system hooks.

## Validation checklist

- [ ] Every part of the full cross-section is represented by a slot, including all Devil's Mouth visual-depth bands.
- [ ] No non-void gaps remain between settlement chunks without an explicit `visual-depth` or `future-locked` reason.
- [x] `H-4-11` retains its approved original visual reference; `H-2-10`, `H-3-10`, `H-2-11`, and `H-3-11` are derived from the approved `h2-h3-r10-r11` anchor; the approved `h3-h4-r10-r11` bridge supplies the shared `H-3-11` ↔ `H-4-11` band without overwriting either original interior.
- [ ] All three dig fronts are bounded destructible envelopes, with no open-ended digging.
- [ ] Every production district and Mid Heart civic-support area has named growth sockets and dynamic-state contracts; no upgrade is a purely invisible numerical change.
- [ ] Bottom-West is visibly lateral/outward and early; Mid-East remains middle-east; High-West remains immediately below Ashram west.
- [ ] Cistern is materially lower than Mid Heart; right wall has density comparable to west.
- [ ] Mid Heart has separate raft/deck chunks and visible void gaps, not one bridge.
- [ ] Every walkable seam has a reciprocal destination and traversal mode.
- [ ] Every image-bearing walkable seam has matching boundary height/grade, rail/structure continuation, camera overlap, and a shared-master provenance record.
- [ ] Camera contracts prevent ordinary frames from seeing the entire Hollow or Firmament from Mid Heart.
- [ ] The data includes Godot handoff fields without conflating atlas units with final world pixels.
