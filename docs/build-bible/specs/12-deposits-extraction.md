# Build Bible Spec 12 — Deposits + Extraction

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #12 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 06 (Terrain), Spec 11 (Materials).

---

## Purpose

Turning a dug-open pocket into a recoverable Material, per canon §3/§6's discover → expose → extract → haul flow.

## Already locked (canon §3, §6 — not new)

- Most rock yields nothing; deposits sit in environmentally-logical resource pockets.
- Deposits are finite, never regenerate.
- Extraction feels modestly different per Material without becoming five separate minigames — **exact implementation intentionally left open by canon itself**, not something this spec should over-specify.
- Depletion uses base terrain + intact overlay → depleted overlay; most deposits need only those two states.
- Better equipment makes previously-impractical extraction possible, rather than mainly granting yield bonuses.

## Design choices (✅ Confirmed, USER, 2026-09-15)

- **Exposing and extracting are two distinct steps** (option A), matching canon's explicit four-step flow rather than collapsing extraction into the act of digging itself. Digging (Spec 06) exposes a deposit — it becomes visible and interactable, but not yet in the player's possession. A separate extraction interaction (Spec 10) pulls the Material out.
- **Extraction is a cancellable hold-to-interact** (option A), the same interaction shape already confirmed for theft (choice 9 in the earlier gap-decisions batch: "a hold-to-take interaction... cancellable"). Reusing this pattern keeps the game's interaction language consistent instead of inventing a second timing mechanic.

## What stays open (canon's own call, not deferred by this spec)

Exact per-Material extraction differentiation (timing, effort, any Material-specific flavor) is canon-OPEN and belongs in the tuning registry once playtested — this spec defines the *shape* (hold-to-extract, cancellable, two-state depletion), not the numbers.

## API surface

- `Terrain.expose_deposit(position)` → deposit becomes an interactable, still "intact."
- Deposit implements the `Interaction` interface (Spec 10): `on_interact` begins the hold-to-extract sequence; completing it calls `Materials.add(type, amount)` and flips the deposit to "depleted."

## Failure / edge cases

- Canceling an extraction mid-hold leaves the deposit intact and untouched — no partial extraction state.

## Acceptance tests

- Digging exposes a deposit without granting the Material.
- Completing the hold-to-extract interaction grants the Material and flips the visual to depleted.
- Canceling mid-extraction leaves the deposit exactly as it was.
