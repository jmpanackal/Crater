# Hollow map spec (authoritative)

**This is the one document that says what the Hollow's walkable map is.** If another doc
(`hollow-build-brief.md`, `hollow-macro-blockout.md`, `hollow-chunk-atlas.md`, the old
"blueprint" link) disagrees with this file or with `hollow_map.gd`, **this file and the code
win** — those docs are design intent and history, not coordinates.

Rebuilt 2026-10-01 (second pass), then tightened the same day (third pass: tighter levels, the
rock shell, Glowbeds open from the start - see section 1). The first pass only re-gridded the east stack; the user's
review found two real problems: the east wall read much smaller than the west (it was built
first as a sandbox and never revisited), and the whole map was flat platforms stacked on
platforms. This pass rebuilds everything from the canon outward — no existing coordinate was
treated as sacred.

> **Placeholder note (USER, 2026-10-02):** this layout fixes size, shape and scale only. Its uniform stairs and levels are not final; see "Layout character" in [`art-direction.md`](art-direction.md) for the direction the traversal layout will move toward.

- Picture: [`refs/hollow-map.png`](refs/hollow-map.png) (decks amber, stairs orange, ladders
  teal, lifts blue, gates red, growth reserves hatched, zone anchors yellow, spawn white).
- Data: [`hollow_map.gd`](../hollow_map.gd) — the map as data. Constants and spawn:
  [`hollow_layout.gd`](../hollow_layout.gd).
- Machine check: [`hollow_map_lint.gd`](../hollow_map_lint.gd), run by
  `tests/test_hollow_map_lint.gd`.
- Report + picture: `godot --headless --path . --script res://tools/hollow_map_report.gd`
  (add `-- scene` for the in-engine checks).
- Zones are generated: `godot --headless --path . --script res://tools/generate_zones.gd`.

## 1. What the map is

A cut-away of rock with carved rooms, one wall on each side of the Devil's Mouth, **each 12
levels tall and ~4300 px of civic interior wide**, wrapped in a **diggable rock shell**:

```
x:  -10560 ............... -5760 ... -2880 ........ 1440 | Mouth 3520 | 4960 ........ 9280 ... 12160 ............... 16960
     west flank rock       galleries   west civic    |  (void, and   |  east civic    galleries   east flank rock
     (7680 px deep)        stop here   interior      |   the pit)    |  interior                  (7680 px deep)

y:   0 ........ 1536 ........... 1792 (L0) ........ 8320 (L17) ... 8336 ........ 9344
     Firmament    first level's air  the eighteen levels (L4-L15 built)  floor slab (open under the Mouth: the pit)
```

**The shell** (`HollowMap.ENV_*`, `ROCK_TOP`, `ROCK_BOTTOM`, `SIDE_DEPTH`): diggable rock on every
side of the Hollow except the pit. 1536 px of **Firmament** across the whole top of the world (the
secret upward frontier; the same placeholder rock for now, a tougher material later), a flank
7680 px deep past each civic wall (the authored dig galleries only reach 2880 px into it, so
there is rock to dig for a long time), and a 1024 px floor slab under both walls. The Mouth is open
all the way down: the pit. `TerrainLayer` fills exactly this (about 520 000 tiles; the scene
builds in ~3 s headless); `HollowMapLint` checks it (`shell`).

Total world 27520 px wide, symmetric about the Mouth's centre (x=3200). Walkable deck length:
west 39.2 k px, east 36.5 k px (ratio 0.93; the lint fails outside 0.8–1.25).

Four structures move you: **stairs, ladders, Presswater elevators, and Mid Heart's own stairs and bridges**. (The old lifts were removed 2026-10-02 and redesigned as elevators the same day, USER.)
Everything else is a room. Nothing floats.

### Decks are one-way

Every deck is a **one-way platform** (HollowTerrain's child layer `Decks`): you stand on it, but
you climb up through it from below. Walls, stair treads and stair wedges are solid. That one rule
is what keeps the map readable:

- a **stair opens through the street above it** (USER 2026-10-02): the deck is simply absent over the stretch of the flight just before its top (`HollowMap.stair_holes()`, 64 px of depth per unit of pitch plus two tiles). You climb out of an open stairwell and drop into it from either side; there is no covering and no key to press, and no "stairs down" cue. Terrace steps under 96 px have no street over them and no opening. The rest of the street still passes over the lower flight.
- a **ladder has no hatch**. Climb up through the deck and land on it. **W or S in a ladder's zone climbs at once** (pressed or held, on the floor or in the air; no jump), and the ladder's hit box reaches 28 px above the deck so S on the deck over a ladder goes down.
- an **elevator** is a cab on a carved shaft: stand on it and press W (up) or S (down) to ride to the next stop; press Interact at a landing to call it. Slow, physical, never fast travel.

(The first version of this rebuild cut a 96/128 px hole in the deck above every stair and every shaft, which split streets; one-way decks replaced it; the stair opening is now back, but only over the last stretch of a flight, so the street still continues on both sides of it.)

### Units

| Thing | Value | Constant |
| --- | --- | --- |
| Tile | 16 px | `HollowLayout.TILE` |
| Player body | 32 × 32 px | |
| Walk / climb / jump | 200 / 140 px/s / ~90 px high | `player.gd` |
| Level spacing | **384 px, everywhere** (12 body heights; 18 levels since 2026-10-02) | `HollowMap.LEVEL_GAP` |
| Level grid | `y = 1792 + 384·k`, k = 0..17 (`LEVEL_ORIGIN = ROCK_TOP + ROOM_HEIGHT`, `HollowMap.LEVELS`) | `HollowMap.lvl(k)` |
| Half levels | only Mid Heart (Ritual deck 3136, freight tier 3520) | |
| Room height | 256 px of air above a deck (8 body heights), then 128 px of floor slab and ceiling | `HollowMap.ROOM_HEIGHT` |
| Terrace | A run may be several flat pieces at small offsets from its band line (`dy`, whole tiles, 16-96 px; negative = raised, positive = a dip; lint rule `grid`), joined by short flights: rise = the dy difference, run = the gap, so a wide gap is a gentle slope of stepped tiles (under 96 px rise: no stairwell or cue). Written once in `HollowMap._terraces()` (`pieces`: [x0, x1, dy]; pieces `id`, `id_1`...; flights `S_id_1`...). Keep shafts, anchors, gates and stair tops on dy-0 pieces and no dip over a flight. In use: Ashram West, Wickwork, Mid Allotments, Allotment Terrace (`AL7`) and the East civic streets | `HollowMap.runs()` |
| Arched roof | Solid rock hung from a room's ceiling over a band-line deck, stepping down to `depth` (16-96 px) in the middle: `HollowMap._roofs()`, painted as HollowTerrain rock; lint rule `roof` keeps it off shafts and flights and leaves 160 px of air. In use: `R_A1`, `R_WK4`, `R_AL6` | `HollowMap.roofs()` |
| Door | A rock partition across a room from the ceiling down to 96 px above the deck (`HollowMap._doors()`, 32 px thick), so the opening is a doorway; the deck stays continuous. On a dy-0 piece, clear of flights, shafts and gates (lint rule `door`). First use: `DR_MID_EAST` on `E4` at x 7040 (Mid-East Landing / Approach) | `HollowMap.doors()` |
| Mouth ledge | A run may end in `END_LEDGE`: a deck reaching at most `LEDGE_MAX` = 128 px out over the Mouth from a lip (USER 2026-10-02). No stairs, shafts or doors on it; Mid Heart stays the only thing that spans the Mouth (lint rule `mouth`). First use: `A0` (Ashram overlook, 96 px). A run can also be tucked back and closed with a wall: `AL7` ends at x 1280 with `END_WALL` | `HollowMap.runs()` |
| Stepped hall | Open air joining two or more levels over an x-range (`HollowMap._halls()`: x0, x1, k_top, k_bottom): from the top level's ceiling down to the bottom level's deck. The steps inside are ordinary runs, half-level landings and flights; streets that cross it are bridges (hanging crossings). Needs solid rock directly above (lint rule `hall`). A run end that just stops inside a hall is `END_OPEN` (no wall, you can drop). In use: `H_WK` (Wickwork repair hall, levels 8-9, with the hanging shelf `WS`), `H_GB` (Glowbeds planter court, levels 5-7, with the terrace `GL1`), `H_CI` (Cistern basin chamber, levels 11-14, with the pier `PF13` for the freight lift) | `HollowMap.halls()` |
| Sloped street | A flight of pitch 2 or more with `air` 160 (stairs default to 112): a street that climbs a whole level on stepped tiles. In use: `S_HW3` (pitch 4), `S_WK5` (3), `S_EM5` (2.5), `S_EA1` (2), `S_CF` (2). Keep the top clear of step flights and shafts | `HollowMap.stairs()` |
| Stair | 45° by default (`RISE` = 384 per level, 192 per half level); an optional `pitch` (run per rise, whole tiles) makes a flight shallower. A flight may end on a half-level **landing** run (`landing: true`, allowed off the level grid, zone rect must cover it). First use: Lower-East Stair `S_LE6a` (45°) + landing `E5L` + `S_LE6b` (1.5 pitch) | `HollowMap.stairs()` |
| Ladder / lift shaft width | 64 px | `SHAFT_OPENING` |

Deck "Y" is the walkable top surface; standing y = deck Y − 32.

### Seeing the whole map in game (dev)

Press **Z** to cycle the camera: normal -> 0.6x -> 0.35x -> 0.2x -> the whole map fitted to the
window (camera limits lifted; a label shows the mode). The minimap (bottom right, **M** hides it)
is drawn from the same data: the rock shell (Firmament, flanks, floor slab), the Mouth and the pit,
decks, stairs, ladders, lifts, gates (red = shut), warm outlines on places held out at the start,
your level row, your position as a dot, and the name of the place you stand in. Labels are small
(7 px) and faint so they do not hide the map.

**Why 384, not 640 (decided 2026-10-01, from playing it):** with 640 px between decks and 480 px of
air, every room was 15 body heights tall and the empty map looked like it had room for another
floor between each pair. 384 / 256 is eight body heights of air, enough for a two-storey building
with 128 px floors, or for a mezzanine half-level (192 px, the Mid Heart pattern) later. Both are
single constants (`LEVEL_GAP`, `ROOM_HEIGHT`, with `RISE` following); stair tops follow `RISE`, so
a change moves the flights, and the lint says which runs have to follow.

## 2. The model (`hollow_map.gd`)

| Element | Meaning |
| --- | --- |
| **run** | a deck at one level with an end type on each side: `wall` (painted column), `mouth` (open lip), `rock` (dig-flank face), `foot` (low end of a stair — the wedge is the wall), `top` (arrival end of a stair), `join` (continues into the next run) |
| **stair** | foot, direction, rise. A solid wedge below the flight. The foot is the end of the lower run (the wedge is that run's wall); the street above passes over the flight |
| **ladder** | open_x, top and bottom level; a deck must cover the shaft at both ends |
| **lift** | open_x and stops; every stop has a deck; the lift passes no deck it does not serve |
| **gate** | a barrier on a run, with a story-flag requirement (a flag is just a named yes/no in the story, e.g. `ashram_clearance`; the gate opens when the story sets it). `blocks=false` is a lock with no bar across the deck (no gate uses it now) |
| **reserve** | an empty, rock-backed footprint a district grows into. Nothing may be built in it |
| **zone** | a named place: rect + anchor on a deck. Zones never overlap |

Add or move something by editing `hollow_map.gd` only. Painting, carving, ladders, lifts, gates,
zone anchors, `content/zones/*.tres`, the minimap and the lint all derive from it.

## 3. The levels

> **Civic rock (USER decision 2026-10-02):** the civic cavity is solid, non-diggable rock except the rooms, flights, ladder and lift shafts, domes and the Mouth (`HollowMap.air_rects()` / `civic_rock_rows()`, painted by `HollowTerrain`). Districts are rock-separated pockets; the unbuilt levels are rock. Digging stays in the flanks, the Firmament and the floor slab.

Both walls use the same 18 rows (L0-L3 and L16-L17 are unbuilt rock; added 2026-10-02, USER). West = x −2880..1440 civic, west of that is the dig flank.
East = x 4960..9280 civic, east of that is the dig flank.

| Lvl | Y | West wall | East wall |
| --- | --- | --- | --- |
| L0-L3 | 1792-2944 | *Unbuilt (2026-10-02): four levels of solid rock above the Ashram, for the housing climb. To be designed in the district rework.* | *Unbuilt: same.* |
| L4 | 3328 | **Ashram Heights W** residences + Mouth overlook (gated) | **Ashram Heights E** residences, Firmament ceiling (gated) |
| L5 | 3712 | Ashram W promenade + gateway lobby (lift stop, Warden gate) | Ashram E promenade + lobby (lift stop, Warden gate) |
| L6 | 4096 | **High-West Dig Front** upper: terrace + gallery into the flank (guarded) | **Glowbeds** terrace (open: passenger lift or stairs) |
| L7 | 4480 | High-West lower gallery | **Glowbeds Hang** (fibre racks) |
| L8 | 4864 | **Wickwork** street, bay into the west rock, runs into **Mid Heart** | Mid Heart's east raft, **Mid-East Landing, Approach, Dig Front** (to 12160) |
| L9 | 5248 | Wickwork lower repair bays (Mouth dock) | Mid-East Service Court (clinic, trade) |
| L10 | 5632 | **Mid Allotments** upper — the Mid Reach residence | Lower-East Homes |
| L11 | 6016 | Allotment street | Lower-East Services (rail-cart freight yard; freight stop) |
| L12 | 6400 | **Lower Worker Terraces — Home Court (spawn)**, Switchback, Dispatch Yard, Worker Stair hall | Cistern Freight Landing (basin approach; freight stop) |
| L13 | 6784 | Lower Landing + Bottom-West Approach | **Cistern** core (pressure basin; freight bottom stop) |
| L14 | 7168 | **Bottom-West Dig Front**: threshold + First Expansion Gallery | Cistern Tanks (maintenance) |
| L15 | 7552 | Collapsed Side Chamber + the locked deeper service run | Seep gallery + the sealed Cistern flood gate |
| L16-L17 | 7936-8320 | *Unbuilt: two levels of solid rock below the old bottom, for Bottom-West and Cistern growth.* | *Unbuilt: same.* |

Mid Heart (L8 plus its two half levels) is the only structure over the Mouth — see §5.

## 4. Vertical circulation

### Stairs (19)

West: `S_A1` (Ashram), `S_HW3` (High-West), `S_WK5` (Wickwork), `S_AL6`, `S_AL7` (Allotments),
`S_LW` (**the Worker Stair**: Home Court up to the Allotments), `S_BW1` (Dispatch Yard down to the
Bottom-West Approach), `S_BW2` (Approach down to the dig threshold).
East: `S_EA1`, `S_EG3`, `S_EM5`, `S_LE6`, `S_LS7` (with `S_LE6` it forms the continuous
**Lower-East Stair** diagonal), `S_CF` (with `S_CL10`: the **Cistern Stair**).
Mid Heart: `H_RIT_W`, `H_RIT_E` (over the raised Ritual deck), `H_FRT_W`, `H_FRT_E` (the lower freight tier), `H_WG`, `H_WG2`, `H_EG`, `H_EG2` (the two galleries).

### Ladders (14) — local shortcuts, one level each

`LAD_A`, `LAD_HW`, `LAD_WK4` (cargo hoist), `LAD_WK5`, `LAD_AL2`, `LAD_AL`, `LAD_BW` (to the
Collapsed Side Chamber), `LAD_EA`, `LAD_EG`, `LAD_EG4` (Mid-East Landing up to Glowbeds Hang, so Glowbeds can be reached without the lift), `LAD_LE2`, `LAD_EF`, `LAD_CC`, `LAD_SE`. No two
share an x across more than one level, so a ladder chain is never a full-height shaft (canon:
lower-west workers use stairs, not a shaft).

### Elevators (4): Presswater, physical, never fast travel (USER 2026-10-02)

Power (LOCKED canon, `story.md` and `mechanics-canon.md` section 21/26): **Presswater, the Cistern's pressurized water, drives the lifts**, and Cistern strain slows or parks them. The Pulse (the surviving ship component at Mid Heart) is the civic timekeeper and is not a power source in canon (its original function is OPEN), so no elevator draws on it. Two classes, in `HollowMap.lifts()` (cab `width`, `kind`, `stops`, `essential`, optional Access `gate`):

| Elevator | x | Cab | Stops | Role |
| --- | --- | --- | --- | --- |
| `freight_west` | 1200 | freight, 160 px, slow (140 px/s) | L8, L9, L10, L11, L12, L13, L15 | Wickwork down through the Allotments, the Mouth balcony, the Lower Mouth Rows (skips L14): the west backbone through five districts |
| `freight_east` | 8704 | freight, 160 px | L8, L11, L12, L13, L14 | Mid-East down through Lower-East services into the Cistern basin chamber (pier `PF13` at L13) and the tanks; stops short of the flood gate |
| `ashram_west` | -2560 | premium, 96 px, quick (220 px/s), essential | L8, L7, L6, L5 | Wickwork up through High-West to the Ashram lobby (west of `gate_ashram_west`) |
| `ashram_east` | 6416 | premium, 96 px, essential | L8, L7, L6, L5 | Mid-East Landing up through Glowbeds to the Ashram lobby (west of `gate_ashram_east`) |

- **Lift-only areas:** Ashram Heights (all tiers, both sides) can be reached only by the premium elevators (lint rule `lift_only`: with every lift ignored, none of those decks is reachable). The L5 Warden gates still stand beyond the lobbies.
- **Cistern condition:** healthy runs at full speed; strained or short slows to 35 percent; critical parks a non-essential lift (a trip in progress finishes at a crawl). Essential lifts never park. An Access `gate` locks a lift ("Warden-run: not cleared yet"); none is set yet.
- **Space:** a shaft is carved cab width + 16 px each side and passes only decks it stops at, with no ladder or flight in it. Freight cabs are 160 px so a cart or a bundle can ride; premium cabs are 96 px.
- **Decided (USER, 2026-10-03, taking the AI recommendations):** (1) the Pulse powers nothing; elevators run on Presswater only, and a Pulse-cycle schedule for the Ashram lifts is a possible later add-on, not built. (2) The Ashram elevators are open to the lobby; the L5 `ashram_clearance` gates do the gating (a Warden boarding check at the lobby is a possible later upgrade once witness rules reach the Ashram). (3) Freight is free to ride with hauled goods, slow, and parks when the Cistern is critical; making freight a progression unlock ("powered hauling") is a later project, not built.
- **Still open:** Pulse Binders versus Wardens as the people who tend or run the lifts; zone names and purposes are AI placeholders until confirmed.

### Travel times (200 px/s walking, 140 px/s ladders; rough, before the 384 px levels)

| Trip | By stairs | With ladder shortcuts |
| --- | --- | --- |
| Home Court → Mid Heart west lip | ~70 s | ~45 s |
| Home Court → Bottom-West first gallery | ~35 s | — |
| Mid Heart → Cistern (stairs + freight lift) | ~90 s | ~60 s |
| Wickwork → High-West → Ashram lobby (premium elevator `ashram_west`) | — | ~10 s |

The 384 px levels shorten every flight and shaft by 40 % (a stair is `RISE` long; a ladder climbs
384 px, not 640), so these are upper bounds now. If the trip still feels long in play, shorten
*corridors* (move a stair); do not shrink the levels again without playing it first.

### Future movement upgrades (reserved, not built)

Ziplines and other Wickline-style crossings belong on **Mouth lips**: `HollowMap.runs()` with an
`END_MOUTH` end (A0, HW2, WK5, AL7 on the west; E4/E5 on the east). A zipline must clear every
Mid Heart deck by ≥ 192 px; the lint will need a rule for it when one is added. Diagonal crossings
such as High-West ↔ Mid-East are the design target (see the memory note on the zipline idea).

## 5. Mid Heart (`zone mid_heart`)

One cluster over the Mouth, and nothing else may touch the Mouth:

- **West Exchange** (L8 lip landing x 1440–1632, the **Exchange gallery** at half level 7.5 x 1824–2144, a landing x 2336–2528): Joss's counter, Approved Gear orders. Continuous with Wickwork's street; the crossing steps up over the gallery and down again (`H_WG`, `H_WG2`).
- **Ritual Raft** (y 3136, x 2720–3680): the raised hall. The main crossing climbs `H_RIT_W`
  (192 px) over it and descends `H_RIT_E` — a walkable crossing that is never flat.
- **East Service** (L8 landing x 3872–4064, the **Stewards' gallery** at 7.5 x 4256–4576, a landing x 4768–4960): care, notices, civic offices. Continuous with the Mid-East Landing (`H_EG`, `H_EG2`).
- **Lower freight tier** (y 3520, x 1632–4768): carts and cargo. A second route across, reached
  only from the cliffs (Wickwork's lower dock by `H_FRT_W`, the Mid-East Service Court by `H_FRT_E`),
  never from the Ritual deck.

The lint checks the cluster's own decks and stairs connect the west lip to the east lip.

## 6. Access: what is open, what is held

Start-closed gates (all `closed_at_start()`); every requirement is a story flag (a named
yes/no the story sets; names are **AI-proposed — USER to confirm**; they are plain `StringName`s
in `HollowMap.gates()`).

**Every main district is open from the start**: Wickwork, the Allotments, Mid Heart, **Glowbeds**
(the passenger lift now always runs), Lower-East, and the **Cistern**. What stays gated is the
Warden's Ashram Heights, the two guarded dig fronts, and the sealed deep runs:

| Gate | Where | Flag | Holds back |
| --- | --- | --- | --- |
| `gate_ashram_west` | L5 x −1920 | `ashram_clearance` | Ashram W promenade + residences |
| `gate_ashram_east` | L5 x 7040 | `ashram_clearance` | Ashram E promenade + residences |
| `gate_high_west`, `_low` | L6/L7 x −3520 | `high_west_cleared` | High-West gallery into the flank |
| `gate_mid_east_dig` | L8 x 9280 | `mid_east_survey_cleared` | Mid-East Dig Front |
| `gate_bw_deep` | L15 x −4480 | `bottom_west_service_open` | the deeper Bottom-West run |
| `gate_cistern_deep` | L15 x 8640 | `cistern_flood_gate_open` | the sealed flood-gate side |
| `gate_wickwork_growth` | L8 x -3600 | `wickwork_expansion` | Wickwork Expansion Bay (growth room) |
| `gate_glowbeds_growth` | L6 x 8720 | `glowbeds_expansion` | Glowbeds Expansion Court (growth room) |
| `gate_cistern_growth` | L14 x 9280 | `cistern_expansion` | Cistern Tank Annex (growth room) |

The lint proves two things: with every gate open every deck is reachable, and with the start-closed
gates shut every zone in `early_zones()` is still reachable **and** every point in `held_points()`
is not (so a gate cannot be walked around).

History: the first rebuild held Glowbeds back behind a Warden-run lift (`gate_east_lift`, flag
`east_ward_clearance`, from the build brief). The user wants every main district visitable from
the start, so that gate is gone and `glowbeds` / `glowbeds_hang` are in `early_zones()`. If the
story later wants the lift Warden-run again, add the gate back and put those zones out of
`early_zones()`; the lint will tell you what else moves.

## 7. Growth space

**Growth rooms (USER 2026-10-03: a district gains rooms at its milestones; AI-built).** Three of the four reserves are now real rooms behind start-closed bulkhead gates, so the map gains rooms the same way it opens everything else: a story flag. The flag names are AI-proposed. What earns each flag (the district upgrade rules) is OPEN and not designed, so today they stay shut until story sets them (`/flag`-style debug, or the console).

| Growth room | District | Where | Gate (flag) |
| --- | --- | --- | --- |
| Wickwork Expansion Bay (`wickwork_annex`) | Wickwork | street `WK4` runs 1760 px further west, level 8, x -5440..-3680 | `gate_wickwork_growth` (`wickwork_expansion`) |
| Glowbeds Expansion Court (`glowbeds_annex`) | Glowbeds | street `E2` runs on past the planter court to x 9248, level 6 | `gate_glowbeds_growth` (`glowbeds_expansion`) |
| Cistern Tank Annex (`cistern_annex`) | Cistern | tank street `E10` runs out through the east wall into the flank, level 14, x 9280..10592 | `gate_cistern_growth` (`cistern_expansion`) |

Each is held back until its gate opens (lint `reach`, `held_points`), is dressed with a few props, and replaces the old reserve (`R_WICKWORK`, `R_GLOWBEDS`, `R_CISTERN` are gone). One reserve is left:

| Reserve | District | Size | Meaning |
| --- | --- | --- | --- |
| `R_BW_DEEP` | Bottom-West | 320 × 352 | the locked service run continues |

Dig fronts grow by digging into the flank rock; High-West, Bottom-West and Mid-East each end in
rock beyond their last deck, with at least 1600 px of it left (`MIN_FLANK_BEYOND`). The Firmament
is the 1536 px of rock above the whole map (`TerrainLayer.FIRMAMENT_Y_MAX`; zone `firmament`,
restricted). The two flank volumes (`west_dig_site`, `east_dig_site`) are sanctioned digging; where
a gallery zone overlaps one, the smaller rect wins (`Zones.get_zone_at`).

## 8. Lint rules (what makes a test fail)

| Rule | Meaning |
| --- | --- |
| `grid` | every deck on the 384 px grid (Heart's two half levels excepted) |
| `stack` | decks that overlap in x are ≥ 192 px apart; runs never overlap |
| `end` | every run end is a wall, Mouth lip, rock, stair foot/top, or Mouth join — and the stair it names exists |
| `stair` | foot on a run end, top lands on a deck, the wedge touches no other deck, no deck crosses the flight between its two levels |
| `ladder`, `lift` | a deck covers the shaft at each end/stop; a lift never passes a deck it does not stop at |
| `gate` | on a run, clear of ladders and lifts |
| `mouth` | only Mid Heart is over the Mouth, and it crosses it |
| `reserve` | empty, rock-backed, touches its own district |
| `zone` | zones never overlap, anchors on decks, every deck inside a zone |
| `reach` | all decks reachable with gates open; early zones reachable and held points sealed with gates closed |
| `space` | west and east walkable length within 0.8–1.25 |
| `shell` | Firmament ≥ 1024, floor slab ≥ 512, flanks ≥ 3200 deep; every room sits inside the civic cavity (or a flank); ≥ 1600 px of rock beyond every gallery end; the pit is open to the bottom |
| scene | structures instanced to match; every deck painted one-way; walls and treads painted; headroom above every deck and tread; rock beyond flank ends; the shell is really painted (Firmament, slab, edges), the cavity and the pit really empty |

## 8b. Dressing (the opening-route slice)

What lives in the rooms is data too: `hollow_dressing.gd`, judged by the lint rule `dress` (things stand on a deck in their
own zone, clear of stairs, shafts and gates, under the ceiling; a slice zone may not thin out). The slice, what is in it and
how mouse mining works: [`hollow-slice-opening-route.md`](hollow-slice-opening-route.md). Dig galleries are
`HollowMap.FLANK_CLEAR` = 160 px tall.

## 9. Protocol for anyone (human or AI) changing the map

1. **Read this file and `hollow_map.gd`.** Do not read the old briefs for coordinates.
2. **Run the report first**; know what is already red.
3. **State the intent of every element in one sentence**: which district, what for, how you get in
   and out, who is held out and why. If you cannot, do not add it.
4. **Edit `hollow_map.gd` only.** Never hand-place a deck, ladder, lift, gate or zone in
   `main.tscn`. Then run `tools/generate_zones.gd`.
5. **New Ys come from `HollowMap.lvl(k)`.** Never type a literal Y.
6. **A stair's wedge is a wall in the band it sits in.** It blocks the lower street at its foot,
   so put the foot at a corridor end or at a wall; the lint's `stair` and `reach` rules catch the rest.
7. **One section per pass.** Edit → `tests/test_hollow_map_lint.gd` → look at
   `refs/hollow-map.png` → play it. Do not batch.
8. **If you change a number, change the table here in the same commit.**
9. **Don't invent districts or canon.** New named places need the user's go-ahead; flags and gate
   conditions are AI proposals until the user confirms them.

## 10. Known follow-ups

- **There is no dressing.** The old dressing scripts (`hollow_ambiance`, `hollow_ledge`,
  `hollow_bridge`, `home_court_dressing`, `dig_site_dressing`, `dig_approach`) were deleted
  2026-10-01: they were keyed to the old layout and nothing instanced them. Dressing a district now
  means reading its zone rect and runs from the map and building on top.
- Visuals for walls/wedges are the flat placeholder rock colour.
- The Firmament is a plain 1536 px band of the placeholder rock; a tougher material and its dig
  rules come later. Deposits are still the old east pockets (`content/deposits/east_dig_site.tres`)
  - the west flank has none yet.
- `hollow_lift.gd` got an `access_gate_id` lock; the Warden lock is evaluated by `Access`.
- The east flank has one dig front (Mid-East) to the west flank's four galleries; the Cistern
  reserve is gone: the Cistern Tank Annex now uses that space.

**Mid Heart gets a vertical dimension (USER 2026-10-03: "needs another level at least, it doesn't feel how it sounds in the lore"; AI-built from `story.md` and `hollow-build-brief.md`).** The lore: a moored floating civic district of three or four rafts plus smaller attached decks, 7-10 offset terraces, with Upper Heart (Ritual, Council), Mid Heart (market, delivery) and Lower Heart (freight, dispatch) as three vertical anchors, the Ritual Raft a two-level hall, and never one island or one bridge. Now:

- **Upper Heart: the Council Terrace** (`HM_UC`, zone `mid_heart_upper`, level 6, x 2736-3664) above the Ritual Raft, so the Ritual hall is two levels with the Pulse standing between. Its ends are riveted bulkheads (wall columns clad in hull plating).
- **Two masts** (freight elevators `heart_mast_west` x 2752 and `heart_mast_east` x 3488, stops Council Terrace 6, Ritual Raft 7.5, lowered dock 9) carry you up and down the Ritual hall. They are Presswater elevators like the others.
- **Lower Heart: a lowered freight dock** (`HM_LH`, level 9, x 2736-3664) in the middle of the freight tier: the tier now dips down to it by `H_LH1` and `H_LH2` (`HM_F`, `HM_F2` are the two tier wings), with a gantry crane, a dispatch booth and cargo.
- **Moorings:** catch-cables run from the terrace and the galleries to anchor plates on both cliffs.
- 11 decks across the cluster (the brief asks for 7-10); the crossing is still West Exchange, galleries, Ritual, East Service, plus the freight loop.

**Terraces reach further near Mid Heart (USER 2026-10-04, AI steps).** A Mouth ledge may reach `HollowMap.ledge_max(k)` over the Mouth: 320 px on levels 7 and 9, 256 on 6 and 10, 192 on 5 and 11, 128 beyond. Extended: east `E3` (L7, 320), `E2` (L6, 256), `ME10` (L10, 256), `E1` (L5, 192), `EP11` (L11, 192); west `HW2` rail ledge (L6, 256), `MB10` (L10, 256). The Mid Heart zone rect now starts at level 8's room top so the level-7 terraces do not overlap it. The Upper Heart Council Terrace is 1504 px wide (x 2448-3952) with a lit council hall. A west level-7 terrace was tried and dropped: its band is the High-West gallery zone.

**Mid Heart structure (AI, 2026-10-03).** `hollow_midheart_view.gd` draws girders and trusses under every deck, rails, and a character for each part: Exchange counter, stalls and rate board; Ritual pillars, pennants and braziers either side of the Pulse; Service notice boards and office doors; canopies on the galleries; a gantry crane and cargo on the lower freight tier. Visual only, drawn from the Mid Heart runs.

## Ragged cliff faces (USER 2026-10-04, AI-built)

The Mouth's cliff faces are no longer a ruled vertical line. `HollowMap.cliff_bulges()` bulges the rock out into the void (up to 192 px, whole tiles, seeded and deterministic) on every solid rock mass between rooms at a lip; any row a room, ledge, flight or shaft touches, and Mid Heart's band (L5 to L9.5), keep the straight lip. `civic_rock_rows()` paints it; lint rule `cliff` keeps bulges out of every deck and flight. Slabs between levels are only about 128 px tall, so the biggest bulges are at the top and bottom of the map; more organic faces need taller rooms or terraces that step back, not just bulges (see the layout plan in `DEV-STATE.md`).

**Room coves (USER 2026-10-04: "many other vertical looking edges").** `HollowMap.cove_rows()` cuts a sloped rock cove, 6 to 10 tiles wide at the ceiling, into the upper corner of every room that ends in a wall, so rooms read as caves and not boxes. Only the top 160 px of the 256 px room is ever filled; the 96 px of headroom over every deck is untouched. The cliff profile no longer jitters per tile.

## Wickwork and Glowbeds resized (USER 2026-10-04, AI-built)

**Wickwork** (was two levels, about 6,000 px): the growth gate `gate_wickwork_growth` now guards a three-level foundry stack in the west flank: the Expansion Bay (L8, `wickwork_annex`), a **slag gallery** (L9, run `WK9F`, zone `wickwork_slag`, ladder `LAD_WS1`) and a **casting floor** (L10, run `WC10`, zone `wickwork_casting`, ladder `LAD_WS2`), about 6,000 px more, all gated. On the public side a small **gantry level** (`WK7`, zone `wickwork_upper`, L7 x 1232-1760, a 320 px ledge toward Mid Heart, ladder `LAD_WK7`) sits above the street. The slope `S_HW3` and the eastern-hall dome `D_WK4` fence in the rest of L7, so the gantry is small; a larger public Wickwork would mean moving the Allotments. The High-West lower gallery became its own zone (`high_west_lower`) so the L7 band east of it can belong to Wickwork.
**Glowbeds** (was two public levels): a public **lower-gardens level** (`GL7`, zone `glowbeds_lower`, L7 x 6656-8000) east of the lift, reached by ladders `LAD_GL` (from the hang) and `LAD_GM` (down to the Mid-East Approach), replacing the old two-level ladder `LAD_EG4`. With the gated recovery wing and the flank annex, Glowbeds is about 7,000 px public and 3,000 px gated.
New greybox props: `furnace`, `anvil`, `forge_wheel` (turns), `smokestack` (steams), animated by `hollow_motion_view.gd`.

## Glowbeds and the east Ashram, raised (USER 2026-10-04, AI-built)

The east Ashram's residences and gate promenade are one level now: run `E1` (L4) carries the public promenade and Mouth overlook, the Warden gate at x 7040 (`gate_ashram_east`) and the residences beyond it; the old `E0`, stair `S_EA1` and ladder `LAD_EA` are gone. Glowbeds moved up one level: main street `E2` at L5, the hang `E3`/`E3B` at L6, the planter court hall `H_GB` at L4-L6. The Ashram elevator `ashram_east` now stops L4, L5, L6 and L8. Level 7 under the hang holds the **Glowbeds recovery and cultures wing** (`GW7`, zone `glowbeds_wing`, behind `gate_glowbeds_wing`, flag `glowbeds_recovery_wing`, AI-proposed, what earns it OPEN; ladder `LAD_GW` from the hang). `LAD_EG4` is now a two-level ladder from the hang to the Mid-East Landing. The Glowbeds expansion court (`E2_6` onward, gate `gate_glowbeds_growth`) runs through the east wall into the flank to x 10400 with a raised section: the frontier cultivation tier. Ledge reach follows `ledge_max(k)` at the new levels (E1 128, E2 192, E3 256). New greybox props: `planter`, `glow_fungi`, `fiber_rack`, `harvest_basket`, `culture_shelf`.

## Placeholder dressing across the whole map (USER 2026-10-04, AI-built)

The user wants an even smattering of placeholder structures across the map, not one big set piece in the Cistern and bare rock elsewhere. `tools/generate_dressing_fill.gd` writes `hollow_dressing_fill.gd` (generated data, never hand-edited): props, lamps and buildings spread along every flat deck, themed by district (residence: Ashram; homes: lower, east and Mouth rows; allotment; works: Wickwork; market: Mid-East; garden: Glowbeds; freight; dig front: High-West, Bottom-West, Mid-East front). `HollowDressing.props()/lamps()/buildings()` return the hand-authored lists plus the fill (`authored_*` returns only the hand-authored ones). Every item is checked against the same conflicts as the `dress` lint (stairs, ladders, gates, lift shafts, doors, zone, ceiling), and zones that already hold their share (the opening slice, the Cistern) get proportionally less. Result: about 2 to 5 props per 1000 px of deck in every district. All placeholder greybox: replaced by real art later. Regenerate with `godot --headless --path . --script res://tools/generate_dressing_fill.gd` after any map change.
