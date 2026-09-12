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
| Lower west | Home Court (O1), Lower Switchback (O2), family interiors, maker alcoves, worker courts, West Dispatch (O3), lower lift landing (O8) | Starting civic neighborhood that gives the player a home and long lateral route. |
| Bottom-West | outward approach (O4), threshold (O5), 5–7 destructible expansion pieces including O6, optional O7 chamber, locked deep boundary | Early sanctioned outward work; the Mouth disappears as the route travels west. |

### Mid Heart

Mid Heart is one large region of many chunks, not a single plaza. It must reserve at least 12 pieces: four major raft anchors and eight or more attached/connector chunks. Open gaps between them belong to Devil's Mouth visual-depth pieces.

| Major raft | Required subchunks |
| --- | --- |
| West Exchange | west dock, Joss Materials counter, requisition/repair intake, attached freight ledge |
| Holding | upper holding hall, lower Holding floor, queue/bench terrace, council/announcement edge |
| East Service | Glowration queue, medic/care room, notices/small shops, right dock |
| Lower Freight | cargo deck, transfer machinery, west and east maintenance loops, emergency catch rail |

The cluster connects to Wickwork/left lift on the west and the lower-east/right-lift approach on the east. It has no direct public excavation face.

### East wall

| Group | Required pieces | Purpose / direction |
| --- | --- | --- |
| Ashram east | high lift landing, guarded threshold, ordered residence courts and interiors | Highest east inhabited band beneath Firmament. |
| Glowbeds | upper terrace, planters/fiber racks, cultivation rooms, drying/packing bay, lift landing | Directly below east Ashram; tidy and protected. |
| Mid-East | wall approach street, freight/service passage, checkpoint, staging, 6–8 destructible dig-envelope pieces, locked deep boundary | True middle height, below Glowbeds and well above Cistern. Wet/pressurized shock-fault work. |
| Lower-east service | residential/service street, clinic, freight dock, repair corridor, lift landing, interior service rooms | A substantial dense band—not a dead-end beside Cistern. |
| Cistern and seep | upper pipe/service level, freight level, pressure basin level, Sealbrine room, deep walkways, seep gallery | Far below Mid Heart, linked by right freight lift and emergency local route. |

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
| Bottom-West | Early; far low west | 5–7 connected chunks, broad and comparatively low | impact-compacted bedrock, brace line, collapse face, locked deep seam | two or three viable horizontal/diagonal routes; O7 optional collapsed side chamber |
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

The upgrade unlock source is intentionally recorded as **`discovery unlock (name pending)`** in the atlas. It may later resolve to recovered Records, a repaired component, a named Knowledge Fragment, or a combination, but the spatial plan must not silently invent a new economy item. The production/system design will decide the final name and exact cost. Atlas slots record the source, the required story state, and the visible construction consequence separately from Materials costs.

### Required district growth reserves

| District | Base footprint | Reserved growth sockets | Visual upgrade outcome | Dynamic states |
| --- | --- | --- | --- | --- |
| **Glowbeds** | tidy upper-right cultivation terrace, planters, fiber racks, packing/drying rooms | fallow cultivation hang, closed humid room, storage/packing yard | additional stepped beds, a tended humid gallery, more drying lines/fiber racks, new grow-light niches, more workers | inoculated/fallow → sprouting → mature harvest → picked/drying → recovering; guarded/tidy throughout |
| **Wickwork** | mid-left repair terrace, binding racks, lamp bench and work bays | shuttered repair bay, spool loft, covered loading sideyard | new binding bench/loom, repair line, lamp service nook, freight intake and visible repair queues | quiet intake → active repair shift → backlog/overflow → upgraded multi-bench operation; shortages visibly thin spools and lamp stock |
| **Cistern** | deep lower-right pipes, basin, pressure gear, freight and Sealbrine rooms | sealed side tank, unused pump alcove, lower pressure chamber/service walk | extra pressure train, new settling tank, larger freight staging, additional controlled water route and service crew | reserve/thin/healthy Presswater; maintenance shutdown; leak repair; upgraded steady operation. States must preserve the left-lift no-softlock rule. |
| **Mid Heart civic support** | existing separate rafts and civic counters | docked utility annex, closed counter, catch-rail service deck | a repaired civic counter, expanded ration/service point, working dock machinery, safer/more active freight flow | daily Holding crowd, quiet interval, delivery arrival, thin-Presswater dimming, harmless catch-rail settle; never a falling/failure catastrophe |

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
id                 stable ID, e.g. O1, BW-D3, MH-H2, VM-C4
display_name       user-facing working name
class              fixed-play / interior / transit / destructible-dig / visual-depth / future-locked
status             planned / draft / approved / revision-needed / implemented
atlas_bounds       x, y, width, height in atlas design units
band               upper / mid / lower / deep / void and wall/Heart side
parent             optional complex or neighborhood owner
seams              destination ID, edge, traversal type, state gate, camera handoff
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
- click a chunk to see its full contract, adjacent seams, approved-image history, and Godot handoff fields;
- toggle visual-depth pieces on/off only for diagram clarity, never delete them;
- display only approved reference images inside slots, with controlled crop and image version/date;
- flag an approved image as `revision-needed` without removing it, so placement history remains clear.

The atlas is a planning tool, not shipped UI and not a source of runtime coordinates. It uses a plain, editable data source so a Godot exporter or a developer can consume the same IDs/seams later.

## Workflow

1. Build the complete fixed mosaic and assign every ID/contract before generating more player-scale art.
2. Generate a chunk image from its contract and neighboring seams.
3. Review it at player scale and in atlas context.
4. On approval, copy the image to `docs/refs/`, add filename/date to the atlas slot, and set status `approved`.
5. Translate approved slots into Godot in logical neighborhood batches. Fill `godot_handoff` as each scene/region is made.
6. After an implementation change, test every changed seam bidirectionally, test camera transitions, and verify relevant system hooks.

## Validation checklist

- [ ] Every part of the full cross-section is represented by a slot, including all Devil's Mouth visual-depth bands.
- [ ] No non-void gaps remain between settlement chunks without an explicit `visual-depth` or `future-locked` reason.
- [ ] O1 has its approved reference image; O2 remains image-withheld until approved.
- [ ] All three dig fronts are bounded destructible envelopes, with no open-ended digging.
- [ ] Every production district and Mid Heart civic-support area has named growth sockets and dynamic-state contracts; no upgrade is a purely invisible numerical change.
- [ ] Bottom-West is visibly lateral/outward and early; Mid-East remains middle-east; High-West remains immediately below Ashram west.
- [ ] Cistern is materially lower than Mid Heart; right wall has density comparable to west.
- [ ] Mid Heart has separate raft/deck chunks and visible void gaps, not one bridge.
- [ ] Every walkable seam has a reciprocal destination and traversal mode.
- [ ] Camera contracts prevent ordinary frames from seeing the entire Hollow or Firmament from Mid Heart.
- [ ] The data includes Godot handoff fields without conflating atlas units with final world pixels.
