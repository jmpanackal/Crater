# Build Bible Spec 13 — Hauling + Tether + Caches

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #13 in [`../00-dependency-map.md`](../00-dependency-map.md). **Tether physics itself is spike-owned** — 00-dependency-map.md already flags "tether physics approach and snag handling" as a technical spike's job; this spec defines the contract around it, not the physics.

**Depends on:** Spec 08 (Stamina), Spec 11 (Materials).

---

## Purpose

Bulk Materials as something physically carried, per canon §7, plus the already-locked G1/G13 rules for what hauling actually costs and how it's bundled.

## Already locked (canon §7, G1, G13 — not new)

- Hauling makes climbing, ladders, ramps, and jumps strenuous, and unlocks a slower loaded-movement speed scaled by load; sprinting is unavailable while hauling.
- One bundle, holding up to a capacity of a single Material type, towed at a time; more simultaneous capacity comes from Hauling-dimension Gear.
- Hauling blocks stamina (Spec 08); depositing, delivering, or caching the load releases that block — already explicit in canon §10.
- Caches are optional, local, player-created stashes — never mandatory, never a global inventory.

## Design choice

- **Caches are created by the player at any valid location**, not restricted to a small set of pre-authored cache points. Canon's own description ("leave excess at a known location for later retrieval") implies player choice and memory, not a fixed list — a cache is created via an interaction ("drop bundle here"), and represented by a world marker (per canon's own DIRECTION: "a small pile, crate, marked stash"). "Valid location" means non-blocking and within an authorized/reachable area, not a special pre-placed slot.

## Explicitly deferred to the technical spike

- How the bundle physically trails the player (rope/chain simulation approach, snag handling, smoothing/anti-snag techniques). This spec only requires that whatever the spike lands on: (a) reads as a physical tether, per canon's "physical feel, not simulation purity" rule, and (b) can be picked up, dropped, and cached through the API below regardless of its internal physics representation.

## API surface

- `Hauling.attach(material_type, amount)` — requests a stamina block from Spec 08, begins towing.
- `Hauling.deposit_at_storage()` / `Hauling.cache_at(position)` — both release the block; the former adds to personal storage (Spec 11), the latter creates a world cache object.
- `Hauling.is_loaded() -> bool` — read by the Player Controller (Spec 07) to apply the locked movement-cost rules.

## Failure / edge cases

- Attempting to cache at an invalid location (blocking geometry, outside an authorized area) fails cleanly with feedback, same as an invalid dig attempt.

## Acceptance tests

- Picking up a bundle blocks the correct stamina amount; depositing, delivering, or caching releases it.
- Climbing/ladders/jumps become strenuous exactly while a bundle is attached, not before or after.
- A cache can be created at a player-chosen valid location and later retrieved from the same spot after the session ends and resumes (ties to Spec 02's persistence).
