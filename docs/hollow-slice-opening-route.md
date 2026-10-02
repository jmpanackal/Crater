# Vertical slice: the opening route (greybox)

The first dressed stretch of the Hollow, built 2026-10-02 on top of the map in
[`hollow-map-spec.md`](hollow-map-spec.md). Canon source: the chunk descriptions in
[`hollow-chunk-map.md`](hollow-chunk-map.md). It is greybox on purpose: flat coloured shapes that read
at player scale. It adds no collision, so it cannot change where anyone can walk.

- Data: [`hollow_dressing.gd`](../hollow_dressing.gd) (buildings, props, lamps, people, stations).
- Drawing: `hollow_dressing_view.gd` (two layers: behind the player, in front of it).
- Building it all: `hollow_dressing_builder.gd` (`Hollow/Dressing` in `main.tscn`). Nothing is placed by hand.
- Judging it: `HollowMapLint` rule `dress`, and `tests/test_hollow_dressing.gd`.
- Look at it: `godot --path . --windowed --script res://tools/check_overview_render.gd -- at=-80,4864`
  (`at=x,y` is the feet position; `mine=x,y` hovers the mouse miner there).

## Look and feel

Target: [`refs/hollow-art-reference-2026-10-02.webp`](refs/hollow-art-reference-2026-10-02.webp) - rooms and courtyards
**carved into** a cavern wall, not boxes hung in a void. The greybox now follows it with generated art
(`rock_textures.gd`, no image files): lumpy navy-brown cobble rock with a little rust and teal moss; warm dressed-stone
brick walls with stone piers and copper plates; arched plank doors and glowing niches; hanging glass lanterns on chains;
thick copper pipes; canvas awnings. Every floor sits on a **rock slab** (the 112 px between levels) with ragged hanging
lumps, moss drips and glow crystals, every civic room has a rock roof, dug galleries have a dim cobble wall behind the
air, and the dig rock, floors, steps and walls all use stone textures. Real art replaces `RockTextures` and the draw
functions later; nothing else depends on them.

### Third pass (2026-10-02): stairs, light, ceilings

- Stair wedges and carved wall mass are the same cave rock as everything else (`HollowTerrain` cuts `RockTextures.cobble`
  into an 8 x 8 atlas indexed by the cell), under stone-step treads, instead of a flat grid.
- The walking areas are always lit (see Light); only rock and your own tunnels are dark.
- Ceilings are not flat: `hollow_fringe_view.gd` hangs jagged rock and stalactites from the Firmament over the cavity, from the
  ceiling of every civic room and dug gallery, and bulges the unfinished gallery ends. It lives under `Terrain`, uses the same
  texture, shader and world-aligned UVs, so it grows out of the tiles with no seam. Not done: the vertical civic walls at x=-2880
  and 9280 are still straight.

### Second pass: stone, not cereal; and speed (2026-10-02)

- **Rock** is now angular fractured stone (`RockTextures.cobble`): irregular flat facets lit from the top-left, dark cracks,
  strata, rust-stained cracks, a few crystal glints, one cool palette. Large-scale variation (light and dark patches, warm
  and cool drift, mossy stretches) is **world-space noise in a shader** (`RockTextures.rock_material`), so the 128 px tile never
  reads as a pattern. Edges are jagged polygons with stalactite spikes filled from the same stone; moss strands, moss
  patches and angular multi-colour crystal clusters (teal, blue, violet, amber) are drawn on top.
- **Speed**: the dressing was one giant canvas item (17,000 draw calls a frame, 14 fps). It is now drawn in chunks (a level band by
  1024 px) so the engine skips what is off screen: 605 draw calls, ~200 fps in the same spot. The minimap redraws 10x a second.
  `tools/measure_frame.gd` (windowed) prints frame time and draw calls.
- **Light** (`vision_layer.gd`, `Vision` in `main.tscn`), Terraria-style: light is a value per 16 px cell that spreads from its
  sources and weakens as it goes, a little per cell of air and a lot per cell of rock. Sources: the Hollow (ambient 0.85, so it is
  easy to see in), **every authored walking area** (dug galleries, stair and shaft air: 0.82, so you can always see where you can
  go), every lamp, and the player (0.9). So in the Hollow you see everything, but in stone you see only a cell or two
  (about 2.5 cells into rock, about 10 along open air), and a dug tunnel shows only what is near you. Tunables are the constants at
  the top of the file (`PLAYER_LIGHT`, `AIR_COST`, `ROCK_COST`, `HOLLOW_AMBIENT`). The upgrade hook is the Rig effect
  `vision_radius_bonus` (pixels of extra reach in air; it also carries further into rock); no Gear grants it yet. **V** toggles
  it for dev, and it hides itself in the dev overview zooms. The grid is re-solved ten times a second, spread over four frames.

## What is in each place

| Zone | Level | Canon beat | What is there |
| --- | --- | --- | --- |
| Home Court | L8 | a lived-in home before the job | **Unit**: bed (sleeps), lockbox (Storage), workbench (home Rig station), delivery hook, pots, rug. **Court**: shared stove with a flue to the ceiling, wash basin and pipe, hanging laundry, fungal mats, neighbour doors, wicklamps. A cook and a neighbour |
| Lower Switchback | L8 | uneven, inhabited worker quarter | carved support mass, railings, a projecting room overhead, a maker nook (a craftsperson hammering), a family doorway, a rock fracture slit, a courier on a beat |
| West Dispatch Yard | L8 | public work made legible | crew board, tool racks, cart turntable and cart, scales, beam stacks, the foreman's dais (the **Foreman** talks), waiting crew, a sorter, a hauler. The Opening Duty dispatcher is the existing node |
| Worker Stair hall | L8 | the broad way back up | rails, delivery hooks, a rest bench, the lift's gauge and warning bell, a climber on a beat, someone resting |
| Lower Landing / Bottom-West Approach | L9 | distance and direction: edge of town | older worker homes the corridor is threaded through, timber braces, supply racks, a parked cart, a residence extension overhead, work lamps, a resident and a hauler |
| Bottom-West Threshold | L10 | excavation is regulated community labour | the tunnel-mouth arch, shift board, tool check, crates, warning lamps, a shift hut, an observation window, a crew queue, the **Warden** (talks) |
| First Expansion Gallery | L10 | sanctioned digging, first Material | braces running west, sorting table, a cart, ore piles, crew digging at the face and sorting, the warning sign at the unstable end, the existing collection point, and three deposits in the west rock (`content/deposits/west_dig_site.tres`) |
| Collapsed Side Chamber | L11 | optional clue, deeper route locked | rubble, fallen supports, an overturned cart, the sealed hatch on the locked run, and the **corroded fragment**, which unlocks the Journal record `slate_shard` |

## What you can do there

- **Sleep** at the bed (E). Only from Gathering or Ritual (the Clock refuses earlier); it advances to the next Rousing and clears Fatigue.
- **Open storage** at the lockbox (E): the one Storage pool, and a towed bundle is deposited. **Refit** at the workbench (E).
- **Talk** to the Foreman and the Warden (E). Their lines are placeholder, written from the chunk-map text, and need the user's pass.
- **Take the fragment** in the chamber (E): once, and the Record is in the Journal (J).
- **Mine** with the mouse: hover rock, hold the left button (see below).

## Mouse mining (Terraria style)

`mine_controller.gd` (`Player/MineController`). Hover a rock tile and hold the left mouse button; it cracks
(four stages) and breaks after 0.28 s. Rules:

- **Reach**: 96 px (six tiles, three body heights) from your centre. Out of reach shows a red outline and does nothing.
- **Line of sight**: rock, walls and stair wedges between you and the tile block it (one-way decks do not).
- **Progress fades** if you let go or move to another tile; menus (dialogue, journal, requisition) own the mouse.
- It breaks tiles through `TerrainLayer.destroy_cell`, exactly like the R key, so deposits, evidence, Perception, dust and
  saving all behave the same. The R-key dig is unchanged.
- Tunable in one place: `REACH_PX`, `MINE_TIME` at the top of `mine_controller.gd`. Dig stamina cost still comes from the
  player (`DIG_STAMINA_COST`, currently 0).
- Not done (Terraria has them): placing blocks, tool-tier mining speed, a "smart cursor" that picks the tile for you.

## What I judged (and what to check)

- **Gallery height.** The dig galleries are now 160 px of air (five bodies), was 96. Dressed galleries need to brace and
  cart; the lint caps flank dressing at that height.
- **Home Court is tight**: 480 px for a unit and a shared court. It works greybox, but the canon "modest vertical back
  stair to an upper landing" is not there (the map has one deck per level). If you want it, it is a half-level run (like Mid
  Heart's) plus a stair, and Home Court wants to be wider.
- **People are ambient and unnamed.** The four named NPCs (Joss, Pell, Rook, Sila) live in Mid Heart, Glowbeds, Wickwork and the
  Cistern, not on this route, so none are placed here. The Foreman and the Warden are generic roles from the chunk map.
- **The fragment uses the existing `slate_shard` record** ("course correction failed. Hull breach..."). That is more explicit
  than the chunk map's "without saying spaceship". Say if you want a different record for this spot.
- **Not yet**: the First Steward is still the plain Dispatch marker; the job beats (crew acknowledgement, a posted update on
  return) from the chunk map are not built; no sound.

## Adding to the slice

Edit `hollow_dressing.gd` only, then run the lint (`tools/hollow_map_report.gd`). The lint tells you if a thing floats, sits on
a stair, a shaft or a gate, hits the ceiling, or leaves its zone, and fails a slice zone that thins out. Positions are the
centre `x`, the level `k`, and `y_off` for things off the deck.
