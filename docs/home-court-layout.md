# Home Court traversal blockout — 2026-09-18

Scope: H-4-11 only, following `hollow-chunk-map.md` (Home Court),
`hollow-level-authoring.md`, and the approved Home Court composition reference
`refs/hollow-opening-home-court-approved-2026-09-11.png`. This is a playable
blockout with schematic domestic dressing, not final art or a completed city.
The reference image's void/lift is not copied: the written opening-route contract
requires an enclosed home and no lower-west civic lift.

## Geometry and access

- `main.tscn`: `Hollow/HollowTerrain` paints the floors, stairs, roof and east wall.
  Every solid surface has its own tile collision.
- Home Court's existing west seam stays at x=-64, floor y=864, adjoining
  Lower Switchback without a door, gate or required jump.
- Communal court: x=-64..32, floor y=864; player spawn (-16,832).
- Local back stair: (32,864) to (160,736), with 16px risers.
- Enclosed home/shared landing: x=160..256, floor y=736, 96px wide.
  It is reached by the same stair in both directions. The roof at y=608 leaves
  112px clear beneath its 16px thickness. Walkable elevations are 128px apart.
- The east wall occupies x=256..272, west of the Mouth boundary x=288.
  This extends the previous home blockout east by 112px; it does not move the
  west seam or neighboring districts. Zone bounds now include both elevations.
- Solid support beneath the landing is rock, not an inaccessible room. The
  roof is a structural boundary, not an advertised route. There are no fake
  doors or ladders implying access to unfinished regions.
- Basin/stove/laundry belong to the communal court; sleeping/work/storage
  silhouettes belong to the upper landing. They are background dressing,
  not newly implemented furniture interactions. Coordinates derive from floor spans.
- Camera zoom remains at the original scene scale. The initial forced 640x360
  view was reverted after user review. Camera follow and smoothing use the same
  physics clock as player movement rather than separate render-frame updates.

## Verification

`tests/test_home_court_navigation.gd` drives the actual player in `main.tscn`
using movement input: spawn to upper landing, across the Worker Return overpass
into Mid Heart and Mid-East, back home, then west through the flat Switchback
and Dispatch to Gallery, into the optional Side Chamber, climb back out, return
home and ascend again. It checks arrival, groundedness and reciprocal zone
seams, without test-side position resets or jump input.

The optional chamber's existing ladder needs its real opening x=-1136 and
right-hand landing configured; otherwise it cannot dismount onto Gallery.
This small correction is included because the reachability test exposed it.
The existing Dispatch marker sits on the flat West Dispatch Yard apron.
The Gallery collection marker is grounded at (-960,1056), rather than floating
one player-height above its floor.

## Neighbor greybox (playable expansion — new districts)

From Home Court's upper landing, stairs climb into Mid Heart and Mid-East.
A Heart-height west spur sits above Switchback, reached by a local ladder so the
flat opening corridor stays clear. See `docs/hollow-macro-blockout.md` and
`tests/test_playable_expansion.gd`.

## Still outside this pass

Production districts, furniture mechanics and final art remain unbuilt. Existing
placeholder regions are not certified as finished. Gallery digging and full
atlas framing stay out of scope.
