# Build Bible Spec 32 — Firmament Progression

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §62 (Ashram Heights Firmament access), §63, the dependency map's draft Firmament state machine and the story's Act 1 ending beat — **pending USER review.** Implemented as drafted; anything marked *choice* is the draft's call. Build-order #32 in [`../00-dependency-map.md`](../00-dependency-map.md) (proposed "defer (post-slice)" — built thin here because the user asked for the full mechanic set).

**Depends on:** Spec 27 (Homes), Spec 06 (Terrain), Spec 14 (Rig), Spec 17 (Perception).

---

## Purpose

The Act 1 long game: from foreshadowing that the Firmament is a ceiling, through earning the Ashram Heights residence beneath it, to the sustained multi-session secret excavation that ends Act 1 with a breach — as a tracked stage, never a separate stealth meter.

## Already locked (canon §62, §63, story — not new)

- At Ashram Heights the Firmament is effectively the player's ceiling; it is very thick, exceptionally hard, a sustained multi-session problem, never a one-block barrier.
- Breaching may require specialised Forbidden Gear, repeated sessions, stamina/fatigue management, debris, noise management, concealment, Survey information.
- Upward excavation from Ashram Heights **reuses the existing detection/evidence/noise systems** — no separate Firmament stealth meter.
- Dependency map draft: `Inaccessible → Foreshadowed → Reachable (Ashram residence owned) → Excavation started → Partial breach (multi-session) → Breached`.
- Story: Act 1 ends when the player has begun sustained excavation and gathered enough contradictions; the surface is not yet revealed.

## Draft choices (Fable, pending USER)

- **`Firmament` owns the stage and the excavation progress** (the state table's "Story flags, Firmament stage | Story / Firmament | Authoritative"). Stage is monotonic — nothing un-breaches.
- **Foreshadowed** comes from an authored story flag (`firmament_foreshadowed`) — the moment the world first tells the player the Firmament is above Ashram Heights (*choice*; a Pulse Binder line, a Record).
- **Reachable** = Homes tier is Ashram Heights.
- **Excavation progress = Firmament cells dug** (Terrain's `terrain_dug` with `is_firmament`), counted from the start (curiosity digs before Ashram count toward the tally but cannot advance the stage past Foreshadowed — sustained excavation is a Mid/Ashram capability, §62). Thresholds for Partial breach and Breached are tuning (multi-session by design).
- **Breached** sets the story flag `firmament_breached` (the Act 1 ending beat's hook) — the surface reveal itself is Act 2.
- Nothing here gates digging: hardness, noise, evidence and witnesses are the existing Terrain/Perception/Evidence rules on the `east_firmament` restricted zone.

## State it owns

Firmament stage (highest reached); Firmament cells dug.

## API surface

- `Firmament.get_stage()`, `get_progress() -> {cells_dug, partial_threshold, breach_threshold, ratio}`, `is_reachable()`.

## Acceptance tests

- Stage starts Inaccessible; the foreshadow flag makes it Foreshadowed; digging Firmament cells before Ashram counts progress but leaves the stage at Foreshadowed; the Ashram residence makes it Reachable and the next dig starts excavation; reaching the tuned thresholds gives Partial breach then Breached, which sets `firmament_breached`; the stage never regresses; it persists.
