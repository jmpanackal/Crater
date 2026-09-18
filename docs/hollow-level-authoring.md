# Hollow level authoring

Engine-level methodology for building the Hollow's playable geometry in Godot. This is
the missing piece between the design docs (`hollow-build-brief.md`, `mechanics-canon.md`
§52/§63, `hollow-chunk-atlas.md`) and actual `.tscn`/`.gd` content — it doesn't redesign
the world, it governs how the world gets built so collision and visuals can't drift
apart and rooms don't get invented ad hoc.

**Spatial reference:** [Hollow Cross-Section Blueprint](https://claude.ai/artifact/Dq15YdDjhfe4B6e1hsvv7U)
is the confirmed, to-scale macro layout — read it before laying out any new region.
Update it (and this doc) if a later design decision changes the macro shape; don't let
the in-engine scene and the blueprint silently diverge from each other.

## Why this doc exists

The Hollow's floor used to be built by three independent procedural systems —
`hollow_decks.gd` (hand-computed collision rectangles), `hollow_floor.gd` (a separate
tile layer painting matching-looking pixels), and `hollow_ambiance.gd` (decorative
props positioned by eyeballed offsets) — all reconstructing positions from shared
constants with nothing forcing them to agree. The concrete failure: ramps had real
collision with zero painted tile under them, so a player would stand on invisible
ground. Beyond that specific bug, room widths and spacings were invented per-section
without a stated methodology, which is what made the result feel arbitrary rather than
designed.

## Rule 1 — Single source of truth, enforced by construction

Floor collision and floor visuals live on the *same* `TileMapLayer`, using a Godot
TileSet physics layer (`tile_set.add_physics_layer()` + a collision polygon on each
tile's `TileData`), not a separate `StaticBody2D` reconstructing the same rectangles by
hand. A tile you can see is a tile you can stand on; there is no other kind. See
`hollow_terrain.gd`.

Decorative props (`hollow_ambiance.gd`) are not collision and never need to be, but
their position must be derived from the same tile-span values used to paint the floor
under them — never an independent hand-tuned offset. This is a review convention, not
an enforced abstraction: when adding ambiance for a room, pass in the same x0/x1/y the
terrain call used.

## Rule 2 — Elevation changes are stepped tiles, not floating ramp polygons

No freehand ramp `CollisionPolygon2D`. A height change is a staircase of individual
tile steps (Terraria-style, matching `mechanics-canon.md` §63's own stated reference),
sized to the player's traversal capability. This is simpler to reason about, trivially
tile-paintable, and closes the exact bug class Rule 1 exists to prevent.

## Rule 3 — Room-sizing minimums

- Player body: 32px (existing `hollow_layout.gd` convention).
- Minimum gap between vertically stacked walkable bands: 128px (`MIN_BAND_GAP`,
  already locked) — headroom under an upper deck must clear the player's height.
- Minimum walkable corridor width: 96px (6 tiles at `TILE_SIZE := 16`) so no room
  reads as claustrophobic by accident.

## Rule 4 — Verticality ratio

At least two readable ascents and one safe descent per major band transition — a
height change is never a single mandatory ladder. Applies at every wall-column
boundary, not only at the three named lifts (west civic, east upper passenger, east
Cistern freight).

**Not-a-straight-line rule:** a sequence of named locations (a quest route, a
district's internal layout) is not automatically a physical line. Switchbacks double
back; corridors fold; rooms stack. A "Lower Switchback" changes elevation — it isn't
horizontal distance with a decorative name. Check the blueprint reference above before
laying out any new sequence of rooms; this mistake happened once already while
building this doc's own reference diagram.

## Rule 5 — Growth-reserve convention

A production district (confirmed so far: Wickwork, Glowbeds, Cistern) claims a
currently-empty tile footprint adjacent to its built structure, sized for its next
production tier, per `hollow-build-brief.md`'s "must claim named space" rule.
Visually: a built footprint next to a reserved (undrawn or dashed-marker) footprint —
see the blueprint's convention. When the district's tier upgrades later, the bigger
building occupies the reserved space; nothing needs to be relocated.

Transport infrastructure (a lift shaft) can separately reserve a future stop the same
way — draw the shaft slightly past its currently-active stop. This is a distinct idea
from district growth (transport capacity vs. production capacity); don't conflate the
two in a single "reserved" marker.

## Rule 6 — Section-by-section build-and-verify workflow

1. Re-read the location's design description (`hollow-chunk-map.md` or equivalent).
2. Size and place it against the blueprint's confirmed macro position — not invented.
3. Paint it on the terrain `TileMapLayer` — collision and visual land together.
4. Add its `zone_anchor` + `content/zones/*.tres` with real reciprocal seams
   (`Zones.validate_seams()` must pass).
5. Extend a navigability test for that location.
6. Only then move to the next location. Never batch multiple unverified sections —
   that's exactly how the geometry this doc replaces came to exist.

## Landmark-first identity (carried over from `hollow-chunk-atlas.md`)

Every region gets one noticeable, unique feature so players read location from the
world, not a minimap. Confirmed by outside research as the right call for this genre,
not just an in-house preference — keep it.
