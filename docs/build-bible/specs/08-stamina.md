# Build Bible Spec 08 — Stamina + Blocks

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #8 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01 (ownership/event conventions), Spec 07 (Player Controller reads this).

---

## Purpose

The stamina bar itself: a fixed, stable budget that strenuous actions draw down, that regenerates normally, and that hauling/Rig Strain/fatigue can partially block — implementing canon §9–§10 and the already-locked G2/G21 rules (§68) exactly, not reinterpreting them.

## Already locked (canon §9–§10, G2, G21 — not new)

- Fixed visual bar; walking and jumping are free; strenuous actions (digging, sprinting, sustained climbing, difficult traversal, hauling, powerful Rig actions) draw it down.
- Normal regeneration whenever not performing strenuous work; walking doesn't block regen.
- Blocks apply in fixed order fatigue → Rig Strain → hauling; overflow becomes Overexertion with a warning, converting into fatigue.
- Overexertion auto-triggers at zero usable stamina while holding a strenuous action, with a strong warning; the first Overexertion each session shows an explicit prompt.

## Design choices

- **Blocks are tracked by named source, not one aggregate number.** Each of hauling / Rig Strain / fatigue holds its own independent block amount, summed for the total blocked portion. This is what lets, e.g., depositing a haul load release exactly the hauling block without touching the others.
- **Overexertion is available uniformly for any strenuous action at zero stamina**, not restricted to a specific allow-list of action types. Simpler, and nothing in canon suggests some strenuous actions should be exempt.

## State it owns

Max stamina, current usable stamina, block amount per source (`{hauling: x, rig_strain: y, fatigue: z}`), regeneration rate.

## API surface

- `request_block(source_id, amount)` / `release_block(source_id)` — called by Hauling, Rig, Fatigue.
- `can_afford(cost) -> bool`
- `spend(cost)` — for an affordable strenuous action.
- `overexert(cost) -> fatigue_added` — for zero-stamina continuation.

## Failure / edge cases

- Total blocks summing to more than max stamina: per G2, this is only reachable *through* an Overexertion event, never a silent state — the invariant `blocked ≤ maximum` always holds outside that one controlled path.

## Debug controls

Set current stamina directly; force a specific block source to a value; force an Overexertion event to inspect its fatigue conversion.

## Acceptance tests

- A hauling block and a Rig Strain block coexist and release independently.
- Overflow past the bar is only reachable via Overexertion, converts to fatigue exactly, and warns first.
- Walking regenerates stamina at the normal rate; sprinting does not.
