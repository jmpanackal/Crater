# Build Bible Spec 07 — Player Controller

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #7 in [`../00-dependency-map.md`](../00-dependency-map.md). Slice: **full, reuse prototype** — CONTEXT.md already documents a working `player.gd` (move/jump/dig, coyote time, jump buffer, squash/stretch, dust). This spec formalizes its contract against the current canon rather than proposing a rebuild.

**Depends on:** Spec 06 (Destructible Terrain).

---

## Purpose

Movement, digging, and physical feel, as the one place canon's stamina/hauling/Rig rules actually reach the player's body. Existing prototype code is the starting point, not something to replace.

## Design choices

- **Player Controller calls other systems' public APIs directly** for blocking-relevant actions (a dig requests its stamina cost from Stamina, a sprint attempt checks Stamina's current block state) — no intermediary "Action" layer between input and consequence. This matches Spec 01's confirmed "reads are open, writes are not" ownership rule directly: Player Controller reads/requests, the owning system (Stamina, Hauling) is the only one that actually mutates its own state.
- **Player Controller owns its own movement parameters and adjusts them by reading Hauling's state**, rather than Hauling reaching in and modifying Player Controller's exported values from outside. Same ownership rule, applied the other direction — keeps "who can change my speed" answerable by one glance at this system's own code.
- **Baseline capabilities (move, dig, light, tether) are hardcoded default behavior, not modeled as removable Gear at all.** Canon §33 requires these can never be "accidentally unequipped or permanently missed" — the simplest way to guarantee that is for them to not be part of the equipment system in the first place, rather than being "unremovable Gear" that needs special-case protection. Actual Gear (Approved items, grafts) only ever *adds to* this baseline; it never gates it.

## State it owns

Position, velocity, facing/aim direction, current movement state (grounded/climbing/hauling-adjusted), coyote/buffer timers.

## Dependencies (read-only)

- **Stamina** (Spec 08, not yet built) — for whether a strenuous action is currently affordable, and to report Overexertion.
- **Hauling** (Spec 13, not yet built) — for whether the player is currently loaded, which per the locked G1 decision makes climbing/ladders/ramps/jumps strenuous and unlocks a slower loaded-movement speed.
- **Terrain** (Spec 06) — for what's diggable at the current aim position.

## Failure / edge cases

- Stamina/Hauling systems don't exist yet in build order — until they do, this spec's hooks into them are contract-only (method signatures agreed, bodies stubbed), not fully wired. Flagged so nobody expects hauling-affected movement to work before Spec 13 lands.

## Acceptance tests

- Existing prototype movement/dig/coyote/buffer/squash behavior is preserved (regression, not reinvention).
- Baseline move/dig/light/tether remain available with zero Gear equipped.
- A stubbed Stamina/Hauling dependency doesn't break normal movement — the hooks fail safe (unblocked) until those systems land for real.
