# Build Bible Spec 14 — Rig + Gear + Capacity / Strain

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #14 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01, Spec 08.

---

## Purpose

The player's evolving Rig — Core Improvements, swappable Gear slots, Rig Capacity as a soft limit — implementing canon §33–§36 and §67's bio-fusion rules exactly.

## Already locked (canon §33–§36, §67 — not new)

- One evolving Rig; Core Improvements use no slot, Gear fills configurable slots.
- Slots ~3→4→5 and Capacity ~3→5→8 through Act 1 (DIRECTION, exact numbers tunable, not this spec's call).
- Exceeding Capacity is legal, creates Rig Strain, which blocks stamina via the `rig_strain` source already defined in Spec 08.
- Baseline move/dig/light/tether are never gated by Gear (Spec 07).
- Forbidden Gear (grafts) uses **no slots at all**, draws only on Capacity (§67).
- Major Rig changes happen only at proper stations (home, workbench, Wickwork); grafting specifically requires the workspace and Mid Reach residence or better (§67).

## Explicitly not decided here (canon says so itself)

- **Hard category restrictions** (which Gear category fits which slot) — §36 states this is "not yet locked." This spec treats slots as generic for the vertical slice; category-based restriction is a future refinement, not invented here.
- **Exact Rig Strain formula** (linear vs. stepped scaling with overcapacity) — §35's own OPEN list. This spec only defines the contract: overcapacity requests a `rig_strain` block from Spec 08, magnitude left to the tuning registry.

## Design choice (✅ Confirmed, USER, 2026-09-15, option A)

- **Station restriction is hard-enforced by the system, not just a UI convention.** The UI should still hide/grey the option normally for a clean player experience — the point is that `equip()`/`graft()` *also* refuse if called any other way (debug console, a future quick-refit feature, anything not yet built), so the rule can't be silently bypassed by a path that forgot to re-check it. The Rig autoload itself refuses equip/unequip/graft calls unless the player is currently within range of a valid station — it doesn't just trust that the UI never offers the option elsewhere. Given how explicit canon is about this ("do not allow complete build reconstruction from the pause menu in the middle of a cave"), enforcing it at the system level means it can't be bypassed by a UI bug or a debug shortcut landing in the wrong state.

## State it owns

Equipped Gear per slot, current slot count, current Capacity, active Core Improvements, current Rig Strain block amount (delegated to Spec 08 under `rig_strain`).

## API surface

- `can_equip_at_current_location() -> bool` — station check.
- `equip(gear_id, slot)` / `unequip(slot)` — fail if not at a valid station.
- `graft(design_id)` — fails if not at the workspace and Mid Reach+.

## Acceptance tests

- Attempting to equip/unequip away from a valid station fails, not just hidden by UI.
- Equipping Gear beyond Capacity succeeds (soft limit) and creates a `rig_strain` stamina block.
- A graft attempt away from the workspace, or before Mid Reach, fails cleanly.
