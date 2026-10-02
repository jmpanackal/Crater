# Build Bible Spec 15 — Civic Cycle / Pulse / Ritual

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #15 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 04 (Clock).

---

## Purpose

The Pulse-driven civic rhythm (Rousing → Working → Gathering → Ritual) as it actually touches gameplay — district resolution timing and Ritual attendance — built on top of Spec 04's phase mechanics rather than duplicating them.

## Already locked / already implemented by Spec 04 (not new)

- Phase names/order (provisional per canon, not finalized, but already what Spec 04 uses).
- District resolution fires "around the transition from Ritual into the next Rousing" (§24) — implemented as: resolution runs as part of the Clock's `phase_changed` event, specifically on the Ritual→Rousing transition. Not a separate timer.

## Design choice (✅ Confirmed, USER, 2026-09-15, option A)

- **Ritual attendance is detected automatically, not scripted per-quest.** At the Ritual phase transition, the system checks the player's current location/state and, if absent, logs a `ritual_missed` fact through Spec 01's Fact Log — a general-purpose check, not something each story beat has to remember to implement. Matches how canon already treats "missed Ritual" as a recurring, general detection example (§19), not a one-off scripted event.

## Scoping note (not a real alternative — just stating the boundary)

The Pulse doesn't get its own autoload at this build stage. Mechanically it's fully represented by Spec 04's Clock; physically it's a static world object at Mid Heart. If the Pulse ever needs its own mechanical state (a condition/health stat, say), that's new scope for a later spec, not something this one invents preemptively.

## Failure / edge cases

- A player mid-rescue or mid-forced-time-skip (Spec 30, not yet built) during a Ritual transition shouldn't double-log a `ritual_missed` fact if their absence is already accounted for by that system — flagged as a forward dependency to resolve once Spec 30 exists, same pattern as Spec 04's simultaneous-advance-request edge case.

## Acceptance tests

- District resolution fires exactly once per cycle, at the Ritual→Rousing transition, observable via the existing `EventBus`.
- A player away from Ritual at the transition gets exactly one `ritual_missed` fact logged; a present player gets none.
