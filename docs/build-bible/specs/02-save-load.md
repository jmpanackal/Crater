# Build Bible Spec 02 — Save / Load + Versioning

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #2 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01 (Core Infrastructure — Authoritative State ownership convention, Fact Log).

---

## Purpose

Persist and restore Authoritative State and the Fact Log across sessions, implementing the already-locked G10 policy: one rolling save slot, autosaving at beds, civic phase transitions, and on quit — no manual save list, no save-scumming path around consequences.

## Already locked (G10 — your decision, not new)

- **Single rolling slot.** One save file per campaign. No save-slot picker UI.
- **Autosave triggers:** sleeping (G3's phase-gated sleep), every civic phase transition (Rousing/Working/Gathering/Ritual), and on quit. Quit-save resumes exactly where the player left off, including mid-cycle.

## ✅ Confirmed (USER, 2026-09-15)

- **Ownership stays distributed** (option B). Save/Load doesn't serialize domain state itself — it orchestrates *when* saving happens and calls a `save_state() -> Dictionary` / `load_state(Dictionary)` contract each domain autoload (Stamina, Trust, Districts, the Clock, …) implements for its own slice, matching Spec 01's (also unreviewed) one-writer-per-value rule. Save/Load never reaches into another domain's internals directly.
- **Fact Log persists in full** for Act 1 vertical-slice scope. Pruning/archival for very long saves is explicitly deferred (flagged, not a non-issue forever — see Spec 01).
- **Atomic write** (option B): write to a temp file, then atomic rename.
- **Schema version stored in every save file** (option B). A loader that finds an older version migrates or fails loudly — it never silently loads mismatched data. The exact migration mechanism is a spike-owned question (00-dependency-map.md's "Save format and migration strategy"), not decided here; this spec only confirms that a version number exists and gets checked.

## Invariants

- **Never a partial write** — a crash mid-save must never corrupt the existing save.
- **Loading is inert.** Restoring state never re-fires one-time events, quests, or "welcome back" side effects. If something needs to react to a fresh load, it reacts to the *state*, not to a "just loaded" signal treated as a trigger.
- **No manual save list**, per G10 — exactly one slot, always.

## Failure / edge cases

- **Corrupted or unreadable save file:** fail loudly with a clear message. Never silently start a new game without telling the player what happened.
- **Crash between autosave points:** accepted loss back to the last autosave — this is the explicit tradeoff G10 chose (protects consequences without a manual-save-scumming path), not a bug to design around further.

## Tunables

None directly — autosave *trigger points* are structural (locked by G3/G11/G10), not tunable numbers.

## Debug controls

- Force-save now.
- Force-load a specific save file (for testing across builds).
- Inspect the current save file's raw contents.
- Simulate a corrupted save to verify the failure path.

## Acceptance tests

- Save → mutate every domain's state → load → full state matches the pre-mutation snapshot. (This already exists in spirit as `tests/test_economy_loop.gd`; extend it to the current canon-driven state shape rather than the retired economy model.)
- Autosave actually fires at: sleep, each phase transition, and quit.
- Quit-save resume lands the player exactly where they left off, including mid-cycle state and current phase countdown.
- A save file with a mismatched schema version is rejected/migrated, never silently loaded as-is.
