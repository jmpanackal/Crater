# Hollow chunk atlas

The atlas is the implementation-facing, full-Hollow board: [`refs/hollow-chunk-atlas.html`](refs/hollow-chunk-atlas.html).

It is deliberately **not** a panoramic artwork. It keeps each normal-camera chunk in its fixed spatial slot so approved chunk images can be compared as a connected whole without falsely promising a single camera can see the city.

## Operating rules

1. Every planned chunk has a fixed slot before its art is made.
2. A slot shows an image **only** after the user approves that image. Draft images remain outside the atlas; their slot stays labeled `Draft — image withheld`.
3. Do not replace an approved reference destructively. Add a dated sibling image, review it, then update that slot's `image` field and retain the old file as history.
4. Every slot must record its route seams, camera contract, systemic owner, and level band. A beautiful image is not approved for implementation until those contracts agree with the adjacent slots.
5. Atlas `x`, `y`, `w`, and `h` positions are **design topology coordinates**, not final Godot world pixels. The Godot implementation must translate them into scene-local chunk origins, tile/collision extents, and camera bounds while preserving the stated adjacencies.

## Implementation handoff

When constructing a chunk in Godot, copy the slot's ID into the scene/region naming convention and record:

- scene or region path;
- world origin and walkable bounds;
- east/west/north/south seam transforms and destination IDs;
- camera anchor / clamp range;
- relevant district, production, home, lift, Warden, Work Order, Trust, or theft hooks;
- the currently approved image filename and date.

This keeps visual approval, traversal construction, and story/system integration synchronized.

## Current opening-route status

| Chunk | Atlas state | Image policy |
| --- | --- | --- |
| O1 Home Court | Approved | `refs/hollow-opening-home-court-approved-2026-09-11.png` is shown in its west-wall slot. |
| O2 Lower Switchback | Draft | Its generated image is awaiting user approval and is intentionally not embedded. |
| O3–O8 | Planned | Labeled slots only. |

The macro arrangement, broader district placement, excavation progression, and non-negotiable Devil's Mouth constraints remain governed by [`hollow-build-brief.md`](hollow-build-brief.md); the opening route contracts remain governed by [`hollow-chunk-map.md`](hollow-chunk-map.md).
