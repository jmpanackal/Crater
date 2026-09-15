# Build Bible Spec 03 — Debug Tools Framework

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #3 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01 (reads Authoritative State, Fact Log, and Tuning Registry through their own owning systems' APIs).

---

## Purpose

One framework every later system hangs its own debug hooks off, instead of each system inventing its own ad-hoc debug UI. This is the single biggest lever for fast AI-assisted development flagged during planning: nobody, human or agent, should have to play 20 minutes to reach a scenario worth checking.

## Decisions

- **One console/overlay**, toggled by a key, debug-builds only.
- **Registry pattern.** Systems register their own commands and inspector panels into the framework; the framework doesn't need to know about every system upfront. This is why it ships early (build-order #3) and grows incrementally as every later spec adds to it, rather than being written once at the end.
- **Minimum viable command set, growing as dependent systems land:**
  - a typed command console (`set_trust high`, `spawn_material sutral 5`, `teleport bottom_west`, …)
  - a state inspector (dump any registered domain's current Authoritative State)
  - a Fact Log browser (filter by type, cycle range, subject)
  - teleport-to-chunk
  - force civic phase / force-advance cycles (hooks into Spec 04's Clock)

Most of these commands can't do anything meaningful until the system they target exists — this spec defines the plumbing; each later spec is expected to register into it rather than build a separate debug surface.

## Invariants

- **Never present in a shipped build.** Gated behind a debug/dev build flag, not a runtime toggle a player could stumble into.
- **Debug actions should be inert with respect to legitimate-progression tracking where that matters** — e.g. debug-spawning a Material shouldn't silently satisfy a "found this via real digging" Record trigger. This is a design responsibility each system's own debug hook needs to honor; this framework can't enforce it generically, only flag it as a rule to follow when registering a command.

## Failure / edge cases

- A malformed or invalid debug command fails with an error message printed to the console itself — it never crashes the running session.

## Tunables

None.

## Debug controls (this system's own)

- `help` / list all currently registered commands.
- Toggle the overlay.

## Acceptance tests

- Console toggles in a debug build; has no effect at all in a release build.
- A new system can register a command or inspector panel without modifying this framework's own code.
- The core set (set phase, set Trust, spawn a Material, teleport to a chunk, dump a domain's state) exists and works once the systems they target are built — verified incrementally as each dependent spec lands, not all at once here.
