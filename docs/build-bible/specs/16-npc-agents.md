# Build Bible Spec 16 — NPC Agents + Schedules + Navigation

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #16 in [`../00-dependency-map.md`](../00-dependency-map.md). **NPC navigation through player-changed terrain is spike-owned** — 00-dependency-map.md already flags "NPC navigation through changed terrain (dynamic repath vs. authored corridors vs. per-chunk regeneration)" as a technical spike's job.

**Depends on:** Spec 05 (zones), Spec 06 (terrain), Spec 15 (civic cycle).

---

## Purpose

NPCs that live somewhere specific depending on the civic phase, whether or not the player is nearby to see it — implementing the already-confirmed G14 decision (abstract off-screen schedules) as an actual system.

## Already locked (G14, confirmed earlier this session — not new)

- Each NPC has a schedule: one location per civic phase (4 slots).
- Off-screen, an NPC "is" at its scheduled location without physics simulation; it instantiates when its chunk loads.
- Perception (Spec 17) only runs for loaded NPCs; off-screen scheduled presence can still be queried for world-fact purposes.

## Design choice (✅ Confirmed, USER, 2026-09-15, option A)

- **Schedules reference named zones, not fixed world coordinates.** An NPC's schedule entry is "at Glowbeds during Working," not a hardcoded position — the specific spot within that zone comes from a small set of marked idle/spawn points inside it. This is easier to author (a designer/agent writes a zone name, not coordinates), and means adding or reshaping a zone later doesn't silently break every NPC scheduled to be near it.

## Reused, not reinvented

Idle behavior (wander, idle bob, facing the player) already exists and works in the current prototype — this spec keeps it, per the same "reuse prototype" approach as Spec 07, rather than redesigning NPC behavior from scratch.

## Explicitly deferred to the technical spike

Whether NPCs dynamically repath around player-dug tunnels, stick to pre-authored corridors regardless of digging, or regenerate per-chunk navigation data. This spec only requires that whatever the spike lands on works with the named-zone schedule model above.

## Out of scope for now (flagged, not decided)

What happens if an NPC's chunk unloads mid-interaction is a non-issue under Spec 05's confirmed "no streaming for the vertical slice" choice — nothing unloads while the player is near an NPC yet. Revisit once streaming is actually built.

## Acceptance tests

- An NPC's location correctly matches its schedule for the current civic phase after a phase transition.
- Querying "was anyone scheduled at \[zone\] during \[phase\]" returns a correct answer even for a zone that was never loaded that phase.
