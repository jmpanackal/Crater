# Build Bible Spec 05 — Authored Topology / Zones

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #5 in [`../00-dependency-map.md`](../00-dependency-map.md). Blocked on a camera/tile-scale lock (production decision, not a design gap) before real chunk art can target real pixel dimensions.

**Depends on:** Spec 01 (Content Definitions / Authoritative State conventions).

---

## Purpose

Represent the Hollow's authored world layout — Home Court, Lower Switchback, West Dispatch Yard, Bottom-West, Mid Heart, and so on — as loadable Godot content, distinct from the destructible terrain that lives *within* some of those zones (Spec 06). `hollow-chunk-map.md` and `hollow-chunk-atlas.md` already describe this world at design/composition level in detail; this spec is about the implementation contract those designs get built into, not a redesign of the layout itself.

## Design choices (✅ Confirmed, USER, 2026-09-15)

- **Zone granularity: named locations, not the atlas's composition grid** (option C). One implementation-level zone per player-recognizable location from the opening route (Home Court, Lower Switchback, West Dispatch Yard, Bottom-West Approach, …), each built internally from whatever finer tilemap/sub-scene structure it needs. The atlas's 2×2 composition-slot grid stays a design/art reference tool for how zones visually compose — it was never meant to be a 1:1 runtime loading boundary.
- **No streaming for the vertical slice** (option A). The opening route (~8 chunks) loads as one scene, no zone-crossing load triggers. Full streaming-by-proximity becomes necessary once the full 288-cell atlas gets built (priority-roadmap.md's explicit Phase 6, "only after Phases 0–5 hold up") — flagged as a known future upgrade, not deferred forever, not built prematurely either.
- **Seams are a validated contract, not manual alignment** (option B). `hollow-chunk-atlas.md` already describes seams qualitatively ("literal shared bands," bridge-banded connections). This spec formalizes that into a real check — two adjacent zones' shared edge must match — validated by a test, not just eyeballed in the editor. Exact validation mechanism (automated test vs. editor tool) is a small enough question to resolve during implementation, not decided here.

## State it owns

Which zone(s) are currently loaded; each zone's world-space origin/transform; the seam-adjacency graph (which zones border which, and where).

## Failure / edge cases

- A player-triggered dig or Rig action near a zone boundary must never behave differently than the same action mid-zone — seams are a loading/authoring concern, invisible to gameplay logic.

## Acceptance tests

- The opening route's ~8 zones load as one coherent scene with no visible gaps or misaligned collision at any seam.
- A new zone can be added by adding content, not by editing an existing zone's script.
