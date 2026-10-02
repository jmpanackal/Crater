# Hollow map spec (authoritative)

**This is the one document that says what the Hollow's walkable map is.** If another doc
(`hollow-build-brief.md`, `hollow-macro-blockout.md`, `hollow-chunk-atlas.md`, the old
"blueprint" link) disagrees with this file or with `hollow_map.gd`, **this file and the code
win** — those docs are design intent and history, not coordinates.

Rebuilt 2026-10-01 (second pass). The first pass only re-gridded the east stack; the user's
review found two real problems: the east wall read much smaller than the west (it was built
first as a sandbox and never revisited), and the whole map was flat platforms stacked on
platforms. This pass rebuilds everything from the canon outward — no existing coordinate was
treated as sacred.

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
levels tall and ~4300 px of civic interior wide, plus a ~2900 px dig flank**:

```
x:   -6080 ... -5760 ......... -2880 ........... 1440 | Mouth 3520 | 4960 ........... 9280 ......... 12160 ... 12800
     rock      west dig flank   west civic interior    |   (void)   |  east civic interior   east dig flank   rock
```

Total world 19200 px wide, symmetric about the Mouth's centre (x=3200). Walkable deck length:
west 37.5 k px, east 35.0 k px (ratio 0.93; the lint fails outside 0.8–1.25).

Four structures move you: **stairs, ladders, lifts, and Mid Heart's own stairs and bridges**.
Everything else is a room. Nothing floats.

### Decks are one-way

Every deck is a **one-way platform** (HollowTerrain's child layer `Decks`): you stand on it, but
you climb up through it from below. Walls, stair treads and stair wedges are solid. That one rule
is what keeps the map readable:

- a **stair rises through the street above it**, so a street is never cut by a stairwell. Going
  up needs nothing; going down means standing on the street over the flight and pressing
  **Down (S)**, which steps through the deck onto the tread (only when a tread or deck is within
  112 px below — never into the Mouth). Each stair top carries a faint `[S] stairs down` cue.
- a **ladder has no hatch**. Climb up through the deck and land on it; press Down on the deck
  over a ladder to grab it (the ladder's hit box reaches 28 px above the deck).
- a **lift rides up through the decks** with no gap cut in any floor.

(The first version of this rebuild cut a 96/128 px hole in the deck above every stair and
every shaft. The route walk showed it split the street: you could not walk across a stairwell.
One-way decks replaced it.)

### Units

| Thing | Value | Constant |
| --- | --- | --- |
| Tile | 16 px | `HollowLayout.TILE` |
| Player body | 32 × 32 px | |
| Walk / climb / jump | 200 / 140 px/s / ~90 px high | `player.gd` |
| Level spacing | **640 px, everywhere** (≈ one screen) | `HollowMap.LEVEL_GAP` |
| Level grid | `y = 320 + 640·k`, k = 0..11 | `HollowMap.lvl(k)` |
| Half levels | only Mid Heart (Ritual deck 2560, freight tier 3200) | |
| Room height | 480 px of air above a deck | `HollowMap.ROOM_HEIGHT` |
| Stair | 45°, rise = run (640 per level, 320 per half level) | `HollowMap.stairs()` |
| Ladder / lift shaft width | 64 px | `SHAFT_OPENING` |

Deck "Y" is the walkable top surface; standing y = deck Y − 32.

### Seeing the whole map in game (dev)

Press **Z** to cycle the camera: normal -> 0.6x -> 0.35x -> 0.2x -> the whole map fitted to the
window (camera limits lifted; a label shows the mode). The minimap (bottom right, **M** hides it)
is drawn from the same data: rock flanks, the Mouth, decks, stairs, ladders, lifts, gates (red =
shut), warm outlines on places held out at the start, your level row, the camera's view box, and
the name of the place you stand in.

## 2. The model (`hollow_map.gd`)

| Element | Meaning |
| --- | --- |
| **run** | a deck at one level with an end type on each side: `wall` (painted column), `mouth` (open lip), `rock` (dig-flank face), `foot` (low end of a stair — the wedge is the wall), `top` (arrival end of a stair), `join` (continues into the next run) |
| **stair** | foot, direction, rise. A solid wedge below the flight. The foot is the end of the lower run (the wedge is that run's wall); the street above passes over the flight |
| **ladder** | open_x, top and bottom level; a deck must cover the shaft at both ends |
| **lift** | open_x and stops; every stop has a deck; the lift passes no deck it does not serve |
| **gate** | a barrier on a run, with a story-flag requirement. `blocks=false` is a lock with no bar (the Warden lift) |
| **reserve** | an empty, rock-backed footprint a district grows into. Nothing may be built in it |
| **zone** | a named place: rect + anchor on a deck. Zones never overlap |

Add or move something by editing `hollow_map.gd` only. Painting, carving, ladders, lifts, gates,
zone anchors, `content/zones/*.tres`, the minimap and the lint all derive from it.

## 3. The levels

Both walls use the same 12 rows. West = x −2880..1440 civic, west of that is the dig flank.
East = x 4960..9280 civic, east of that is the dig flank.

| Lvl | Y | West wall | East wall |
| --- | --- | --- | --- |
| L0 | 320 | **Ashram Heights W** residences + Mouth overlook (gated) | **Ashram Heights E** residences, Firmament ceiling (gated) |
| L1 | 960 | Ashram W promenade + gateway lobby (lift stop, Warden gate) | Ashram E promenade + lobby (lift stop, Warden gate) |
| L2 | 1600 | **High-West Dig Front** upper: terrace + gallery into the flank (guarded) | **Glowbeds** terrace (Warden lift) |
| L3 | 2240 | High-West lower gallery | **Glowbeds Hang** (fibre racks) |
| L4 | 2880 | **Wickwork** street, bay into the west rock, runs into **Mid Heart** | Mid Heart's east raft, **Mid-East Landing, Approach, Dig Front** (to 12160) |
| L5 | 3520 | Wickwork lower repair bays (Mouth dock) | Mid-East Service Court (clinic, trade) |
| L6 | 4160 | **Mid Allotments** upper — the Mid Reach residence | Lower-East Homes |
| L7 | 4800 | Allotment street | Lower-East Services (rail-cart freight yard; freight stop) |
| L8 | 5440 | **Lower Worker Terraces — Home Court (spawn)**, Switchback, Dispatch Yard, Worker Stair hall | Cistern Freight Landing (basin approach; freight stop) |
| L9 | 6080 | Lower Landing + Bottom-West Approach | **Cistern** core (pressure basin; freight bottom stop) |
| L10 | 6720 | **Bottom-West Dig Front**: threshold + First Expansion Gallery | Cistern Tanks (maintenance) |
| L11 | 7360 | Collapsed Side Chamber + the locked deeper service run | Seep gallery + the sealed Cistern flood gate |

Mid Heart (L4 plus its two half levels) is the only structure over the Mouth — see §5.

## 4. Vertical circulation

### Stairs (19)

West: `S_A1` (Ashram), `S_HW3` (High-West), `S_WK5` (Wickwork), `S_AL6`, `S_AL7` (Allotments),
`S_LW` (**the Worker Stair**: Home Court up to the Allotments), `S_BW1` (Dispatch Yard down to the
Bottom-West Approach), `S_BW2` (Approach down to the dig threshold).
East: `S_EA1`, `S_EG3`, `S_EM5`, `S_LE6`, `S_LS7` (with `S_LE6` it forms the continuous
**Lower-East Stair** diagonal), `S_CF` (with `S_CL10`: the **Cistern Stair**).
Mid Heart: `H_RIT_W`, `H_RIT_E` (over the raised Ritual deck), `H_FRT_W`, `H_FRT_E` (the lower freight tier).

### Ladders (13) — local shortcuts, one level each

`LAD_A`, `LAD_HW`, `LAD_WK4` (cargo hoist), `LAD_WK5`, `LAD_AL2`, `LAD_AL`, `LAD_BW` (to the
Collapsed Side Chamber), `LAD_EA`, `LAD_EG`, `LAD_LE2`, `LAD_EF`, `LAD_CC`, `LAD_SE`. No two
share an x across more than one level, so a ladder chain is never a full-height shaft (canon:
lower-west workers use stairs, not a shaft).

### Lifts (3) — Presswater, physical, never fast travel

| Lift | x | Stops | Role |
| --- | --- | --- | --- |
| `heart` (west civic) | −2560 | L1, L2, L3, L4 | Always runs. Wickwork up to High-West and the Ashram gateway |
| `east_passenger` | 6400 | L1, L2, L3, L4 | Warden-run; parked until `east_ward_clearance`. Recessed Mid-East landing up through Glowbeds |
| `freight` | 8640 | L4, L7, L8, L9 | Heavy; slows and parks with the Cistern's condition. Mid-East down to the Cistern |

### Travel times (200 px/s walking, 140 px/s ladders; rough)

| Trip | By stairs | With ladder shortcuts |
| --- | --- | --- |
| Home Court → Mid Heart west lip | ~70 s | ~45 s |
| Home Court → Bottom-West first gallery | ~35 s | — |
| Mid Heart → Cistern (stairs + freight lift) | ~90 s | ~60 s |
| Wickwork → High-West (lift) | ~12 s | — |

If these feel too long in play, shorten *corridors* (move a stair), do not shrink the levels.

### Future movement upgrades (reserved, not built)

Ziplines and other Wickline-style crossings belong on **Mouth lips**: `HollowMap.runs()` with an
`END_MOUTH` end (A0, HW2, WK5, AL7 on the west; E4/E5 on the east). A zipline must clear every
Mid Heart deck by ≥ 192 px; the lint will need a rule for it when one is added. Diagonal crossings
such as High-West ↔ Mid-East are the design target (see the memory note on the zipline idea).

## 5. Mid Heart (`zone mid_heart`)

One cluster over the Mouth, and nothing else may touch the Mouth:

- **West Exchange raft** (L4, x 1440–2400): Joss's counter, Approved Gear orders. Continuous with Wickwork's street.
- **Ritual Raft** (y 2560, x 2720–3680): the raised hall. The main crossing climbs `H_RIT_W`
  (320 px) over it and descends `H_RIT_E` — a walkable crossing that is never flat.
- **East Service raft** (L4, x 4000–4960): care, notices, civic offices. Continuous with the Mid-East Landing.
- **Lower freight tier** (y 3200, x 1760–4640): carts and cargo. A second route across, reached
  only from the cliffs (Wickwork's lower dock by `H_FRT_W`, the Mid-East Service Court by `H_FRT_E`),
  never from the Ritual deck.

The lint checks the cluster's own decks and stairs connect the west lip to the east lip.

## 6. Access: what is open, what is held

Start-closed gates (all `closed_at_start()`); every requirement is a story flag (names are
**AI-proposed — USER to confirm**; they are plain `StringName`s in `HollowMap.gates()`):

| Gate | Where | Flag | Holds back |
| --- | --- | --- | --- |
| `gate_ashram_west` | L1 x −1920 | `ashram_clearance` | Ashram W promenade + residences |
| `gate_ashram_east` | L1 x 7040 | `ashram_clearance` | Ashram E promenade + residences |
| `gate_high_west`, `_low` | L2/L3 x −3520 | `high_west_cleared` | High-West gallery into the flank |
| `gate_east_lift` | the passenger lift | `east_ward_clearance` | Glowbeds and Glowbeds Hang (they are only reachable by that lift) |
| `gate_mid_east_dig` | L4 x 9280 | `mid_east_survey_cleared` | Mid-East Dig Front |
| `gate_bw_deep` | L11 x −4480 | `bottom_west_service_open` | the deeper Bottom-West run |
| `gate_cistern_deep` | L11 x 8640 | `cistern_flood_gate_open` | the sealed flood-gate side |

The lint proves two things: with every gate open every deck is reachable, and with the start-closed
gates shut every zone in `early_zones()` is still reachable **and** every point in `held_points()`
is not (so a gate cannot be walked around).

**Decision for the USER:** Glowbeds is held back entirely by the Warden lift (the brief says it is
"reached by the guarded east upper passenger lift after clearance"). If Pell and Glowbeds must be
visitable in the opening, either clear `east_ward_clearance` early or add a public stair from the
Mid-East Service Court — one `_stair()` line plus a run, and the lint will tell you what else moves.

## 7. Growth space

| Reserve | District | Size | Meaning |
| --- | --- | --- | --- |
| `R_WICKWORK` | Wickwork | 1760 × 1120 west of the bay | next workshop tier |
| `R_GLOWBEDS` | Glowbeds | 480 × 1120 past the planter court | next cultivation tier |
| `R_CISTERN` | Cistern | 1280 × 1760 east of the flood gate | pressure basin / tank expansion |
| `R_BW_DEEP` | Bottom-West | 320 × 640 | the locked service run continues |

Dig fronts grow by digging into the flank rock; High-West, Bottom-West and Mid-East each end in
rock beyond their last deck. The Firmament is the rock above Ashram (rows above L0; its thick
band is `TerrainLayer.FIRMAMENT_Y_MAX`).

## 8. Lint rules (what makes a test fail)

| Rule | Meaning |
| --- | --- |
| `grid` | every deck on the 640 px grid (Heart's two half levels excepted) |
| `stack` | decks that overlap in x are ≥ 320 px apart; runs never overlap |
| `end` | every run end is a wall, Mouth lip, rock, stair foot/top, or Mouth join — and the stair it names exists |
| `stair` | foot on a run end, top lands on a deck, the wedge touches no other deck, no deck crosses the flight between its two levels |
| `ladder`, `lift` | a deck covers the shaft at each end/stop; a lift never passes a deck it does not stop at |
| `gate` | on a run, clear of ladders and lifts |
| `mouth` | only Mid Heart is over the Mouth, and it crosses it |
| `reserve` | empty, rock-backed, touches its own district |
| `zone` | zones never overlap, anchors on decks, every deck inside a zone |
| `reach` | all decks reachable with gates open; early zones reachable and held points sealed with gates closed |
| `space` | west and east walkable length within 0.8–1.25 |
| scene | structures instanced to match; every deck painted one-way; walls and treads painted; headroom above every deck and tread; rock beyond flank ends |

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

- **Dressing is not redone.** `hollow_ambiance.gd`, `hollow_ledge.gd`, `hollow_bridge.gd` and
  `home_court_dressing.gd` are keyed to the old layout and are not instanced (the first three
  would not compile against the new constants). Dressing a district now means reading its zone
  rect and runs from the map.
- Visuals for walls/wedges are the flat placeholder rock colour.
- Dig-front gameplay beyond the carved galleries (deposits, evidence, Firmament thickness above
  the Ashram residences) was only re-seated, not re-designed: deposits moved with the east dig
  start; the Firmament is still the existing rock band, not a new thick mass above Ashram.
- `hollow_lift.gd` got an `access_gate_id` lock; the Warden lock is evaluated by `Access`.
- The east flank has one dig front (Mid-East) to the west flank's four galleries; the Cistern
  reserve is where a second east front would go.
