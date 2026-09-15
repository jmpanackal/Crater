# Build Bible Spec 06 — Destructible Terrain + Persistence

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #6 in [`../00-dependency-map.md`](../00-dependency-map.md). **The core data-representation question is explicitly spike-owned, not decided here** — 00-dependency-map.md already flags "terrain persistence representation (per-tile deltas vs. chunk snapshots)" as a technical spike's job, and this spec respects that rather than picking an answer prematurely.

**Depends on:** Spec 02 (Save/Load), Spec 05 (zones).

---

## Purpose

Player-diggable terrain within authored dig envelopes, persistent across saves, implementing the already-locked hybrid model from mechanics-canon.md §63: authored settlement geography stays fixed; controlled excavation zones are genuinely destructible within their authored boundary.

## Already locked by existing canon (not new choices)

- **Opt-in destructibility.** Nothing is destructible by default — only explicitly authored "dig envelope" regions are, per §63/the atlas's "fixed outer envelope of destructible chunks" language. This is the opposite of an opt-out model and was already decided by the existing design docs, not picked fresh here.
- **Depletion visuals.** Base terrain + intact deposit overlay → depleted overlay (§6, LOCKED). Not a new choice.
- **Major discoveries are authored, not procedural.** Critical Records/Components/hidden rooms and Firmament progression never depend on where the player happens to dig (§63, LOCKED).

## Design choice (new, this spec — ✅ Confirmed, USER, 2026-09-15, option A)

- **Terrain digging is push, not pull.** A successful dig emits an `EventBus` event (per Spec 01's confirmed pattern) rather than other systems polling terrain state each frame. This is what lets Perception (noise), the Fact Log, and Material extraction all react to a dig without Terrain needing to know who's listening.

## Explicitly deferred to the technical spike

- Whether persistence is stored as per-tile deltas from an authored base, or full chunk snapshots, or something else. This spec only requires that *whatever* the spike lands on round-trips correctly through Spec 02's save/load contract — the representation itself isn't this spec's call.

## Contract surface (regardless of spike outcome)

- `can_dig(position) -> bool` (false outside an authored envelope)
- `dig(position)` → mutates terrain, emits the dig event, returns what was exposed/extracted
- `get_deposit_state(position)` → intact / depleted / none

## Failure / edge cases

- A dig attempt outside an authored envelope is a no-op with feedback, never a crash or an unintended tunnel into fixed geography.
- Terrain persistence must survive a save/load round-trip exactly — this is one of Spec 02's own acceptance tests, extended to cover a dug tunnel specifically once this system exists.

## Acceptance tests

- Digging within an authored envelope succeeds and persists after save/load.
- Digging outside an envelope fails cleanly.
- A dig emits exactly one `EventBus` event, observable by an unrelated listener.
- Depletion visually matches the locked overlay principle (intact → depleted, no full-room redraw).
