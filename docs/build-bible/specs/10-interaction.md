# Build Bible Spec 10 — Interaction

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #10 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 07 (Player Controller).

---

## Purpose

How the player interacts with world objects — NPCs, rest points, storage, deposits, doors — as one generic system rather than each object type inventing its own input handling.

## Design choices

- **Area2D-based targeting**, not raycast/aim or a bare proximity check. Matches the existing prototype's NPC-talk pattern (already proximity-triggered) and fits a 2D side-view game with no mouse-aim input.
- **One unified Interact input** (already **E** in the existing control scheme) for every interactable type — talk, rest, turn-in, open. The specific behavior is decided by what's being interacted with, not by which key was pressed.
- **Closest interactable wins** when more than one is in range simultaneously. No selection UI for the vertical slice; revisit only if overlapping interactables turn out to be a real problem in playtesting.

## State it owns

Nothing persistent — this system only tracks which interactables are currently in range and which one is currently the closest/active target for UI prompt purposes.

## API surface

- Interactable objects implement a small interface: `get_interact_prompt() -> String`, `on_interact(player)`.
- `Interaction` (on the player) tracks nearby interactables via Area2D overlap and exposes the current closest one for a UI prompt.

## Failure / edge cases

- An interactable that becomes invalid while in range (e.g. an NPC that walks away mid-interaction) should cleanly cancel rather than leave the player in a stuck state.

## Debug controls

List all currently-registered interactables in the scene; force-trigger a specific one regardless of range.

## Acceptance tests

- Standing near exactly one interactable shows its prompt and triggers it on Interact.
- Standing near two shows/triggers the closer one.
- Walking out of range clears the prompt.
