# Build Bible Spec 04 — World Clock

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #4 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01 (Authoritative State ownership, EventBus), Spec 02 (current phase/cycle count must persist).

---

## Purpose

The sole owner of "what time it is." Advances the civic cycle (Rousing → Working → Gathering → Ritual, per mechanics-canon.md). Nothing else is permitted to move time forward directly — other systems (sleep, forced rescue, failure) *request* an advance; only the Clock actually mutates the phase, per the dependency map's own contract for this exact system ("only the Clock advances time... emits phase-transition events exactly once per transition").

## Decisions (operationalizing G3, G11, §68 — not new design)

- **Cycle length ~30–40 real minutes**, Working occupying about half. A Tuning Registry value, never hardcoded.
- **Time pauses during menus, the workbench, and dialogue.** The Clock exposes `pause(reason)` / `resume(reason)`; it doesn't know *why* it's paused, only that it is. Pause is reference-counted by reason, not a single boolean — a menu open *and* a dialogue open at once must both need to close before time resumes.
- **Sleep is phase-gated.** `request_advance_to_next_rousing()` only succeeds when the current phase is Gathering or after Ritual (G3, locked). Calling it earlier should be prevented by the UI layer, but the Clock itself refuses/asserts as a safety net rather than trusting callers.
- **Travel-time budgets are a design target, not an enforced rule** (G11) — the Clock doesn't need to know about them at all; they're a level-design/playtesting concern.

## State it owns

- Current phase.
- Total cycles elapsed this save.
- Time-within-current-phase (for UI countdown display).
- Pause state as a reason stack (not a boolean).

## Invariants

- **Exactly one `phase_changed` event per actual transition** — no double-firing, no silently skipped phases.
- **Paused time never catches up.** It simply doesn't advance while paused; there's no compensating skip on resume.

## Failure / edge cases

- **Two simultaneous advance requests** (e.g. sleep pressed at the exact moment a forced time-skip also triggers): must be idempotent/queued, resulting in one coherent advance, never a double-advance. Worth a concrete rule once Failure/Rescue (build-order #30) is specced — flagged here as a forward dependency, not resolved yet.

## Tunables

- Cycle length (minutes).
- Phase proportions (Working ≈ half, others split the remainder).
- Whether travel-time budget warnings are shown at all (a UX toggle, not a gameplay rule).

## Debug controls

- Force-advance to next phase.
- Force-advance N cycles.
- Pause / unpause directly (bypassing reason-stack bookkeeping, for testing).
- Jump directly to a named phase.

## Acceptance tests

- A full cycle advances through all four phases in the locked order.
- Pausing during a menu halts time; resuming continues from exactly where it left off, not from a recalculated point.
- `request_advance_to_next_rousing()` succeeds only when phase is Gathering/Ritual, fails otherwise.
- Exactly one `phase_changed` event fires per transition, observable via `EventBus` with no direct reference to the Clock autoload.
