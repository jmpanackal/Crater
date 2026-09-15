# Build Bible Spec 01 — Core Infrastructure

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #1 in [`../00-dependency-map.md`](../00-dependency-map.md) — the foundation every other system depends on. This is the only spec that bundles multiple systems together; every spec after this one is scoped to a single numbered system.

**Covers:** Event Bus, Authoritative State (ownership convention), Fact Log, Tuning Registry, Content Definitions.

---

## Purpose

Four conventions and one shared service that every later system builds on, so that by the time Spec 02 onward gets written, "where does this state live," "how do systems talk without coupling," "how do we remember what happened," and "where do numbers/content live" are already answered once, not re-decided per system.

## The three state layers (recap, canon-level)

Per the planning discussion in 00-dependency-map.md §1: **authoritative state** (what's true right now), **fact log** (what happened, append-only), **derived state** (computed from the first two, never itself saved as truth — e.g. Suspicion, Investigation stage, district condition labels). This spec defines the first two as real infrastructure; derived state is each consuming system's own responsibility to compute on read.

---

## 1. Authoritative State — an ownership convention, not a singleton

**Decision:** no single "GameState" god-object. Each domain (Stamina, Trust, a District, the Clock, Homes, the Capability Web, …) owns its own state in its own autoload, matching the existing project convention already in place (`resources.gd`, `districts.gd`, `community.gd` — see `godot-best-practices.md`'s explicit warning against "growing god-objects"). This spec's job is the *rule*, not a new object:

- **One writer per piece of state.** Every value has exactly one autoload that's allowed to mutate it. Everyone else requests changes through that owner's public API (a method call, not a direct field write) — this is what 00-dependency-map.md's "state ownership table" already assumes for every later system.
- **Reads are open; writes are not.** Any system may read another domain's state through its public getters. Only the owner writes.
- **No shadow copies.** If a value can be read from its owner, nothing else caches a second copy that can drift out of sync. Cache derived/computed values, never authoritative ones.

## 2. Event Bus

**Decision:** two tiers, not one universal bus.

- **Direct Godot signals** for tightly-coupled, local relationships (a UI panel listening to the district it's displaying, a player node listening to its own Rig). Default choice — cheapest, most idiomatic Godot.
- **A single `EventBus` autoload**, signals only, for events genuinely cross-cutting enough that many unrelated systems need to observe them without hard references to each other: civic phase transitions, Trust changes, a diversion/witness event, a job state change, a save/load lifecycle event. This is the layer the Fact Log, debug tools, and UI toasts hook into generically.

**API shape:** `EventBus` exposes typed signals (`phase_changed(old, new)`, `trust_changed(reason)`, `fact_recorded(fact)`, …) rather than one generic `emit(name, payload)` — Godot's own signal system already gives type safety and autocomplete; a generic string-keyed bus throws that away for no real benefit here.

**Invariant:** the bus never holds state itself. It's a pass-through. If something needs to ask "what's the current phase," it asks the Clock, not the bus.

## 3. Fact Log

**Decision:** one shared, append-only service (`FactLog` autoload) that every domain writes to through one call shape, and multiple domains read from (Trust, Suspicion/Investigation, Dialogue's contradiction-checking, debug tools).

**A fact record holds, at minimum:**
- `type` (e.g. `seen_in_restricted_area`, `ritual_missed`, `theft_witnessed`, `claim_made`)
- `cycle` (which civic cycle it happened in — ties to the Clock)
- `subject` (usually the player; occasionally an NPC or district)
- `location` (chunk/zone id)
- `witnesses` (NPC ids present, if any — empty is valid and meaningful)
- `severity` or `context` payload specific to the fact type (kept loose — a `Dictionary`, not a rigid schema per type, so new fact types don't require a log-format migration)

**Invariants:**
- **Append-only.** Never mutated or deleted once written. A fact that turns out to be wrong or superseded gets a *new* fact recorded (e.g. `claim_exposed_as_lie` referencing the original `claim_made`), not an edit.
- **Self-contained.** A fact must carry enough detail to be understood on its own, later, without re-querying other systems' *current* state — because by the time something asks "was anyone in Wickwork storage that cycle," Wickwork's current state may no longer reflect that moment.
- **Facts are data, derived state is not facts.** Suspicion/Investigation compute *from* the log; they never write themselves into it as if they were things that happened.

## 4. Tuning Registry

**Decision:** every tunable number lives in a data file, never a hardcoded constant in gameplay code. Organized by system (`tuning/stamina.tres`, `tuning/districts.tres`, `tuning/trust.tres`, …), loaded at startup, with a debug command to reload without restarting the game. This is what makes every "exact numbers stay OPEN/tunable" note throughout mechanics-canon.md and Spec 02 actually mean something in practice — the *structure* of a rule is code; the *number* is always data.

**Godot shape:** custom `Resource` subclasses per tuning domain (e.g. `StaminaTuning.gd` extends `Resource`, with typed exported fields), not raw JSON — gets the editor inspector for free, and type safety over a loose dictionary.

## 5. Content Definitions

**Decision:** Gear, Materials, Jobs, Districts, and similar authored content are Godot `Resource` files, not code-defined arrays or match statements. A designer/agent adds a new Gear item by adding a `.tres` file matching the schema, not by editing a script.

**Invariant:** content resources are never mutated at runtime by gameplay code. They're read-only authored data, referenced by id/path. Runtime *state* about a piece of content (e.g. "this Gear is currently equipped") lives in the owning domain's authoritative state, as a reference to the definition, not inside the definition itself.

---

## Failure / edge cases

- **Two systems try to write the same Authoritative State value in one frame:** shouldn't be possible by construction (one writer per value) — if it happens, it's a design bug in that domain's ownership, not something this layer papers over with a resolution rule.
- **Fact Log growth over a long save:** a non-issue at Act 1 vertical-slice scale (bounded playtime); flagged here so it isn't forgotten if the game later needs archival/pruning.
- **Tuning file fails to load / missing field:** fall back to a hardcoded safe default *in the tuning Resource's own script*, not scattered through gameplay code, and log a loud debug warning — gameplay code should never need to know a tuning value could be missing.

## Debug controls (belongs to the Debug Tools system, build-order #3, but drives its earliest requirements)

- Dump current Authoritative State for any given domain autoload.
- Browse/filter the Fact Log (by type, cycle range, subject).
- Hot-reload Tuning Registry files without restarting.
- List loaded Content Definitions and inspect one.

## Acceptance tests

- A domain autoload can write its own state and reject/ignore an external write attempt (verifying the one-writer rule is enforced, not just conventional).
- `EventBus` signal fires and is received by an unrelated listener with no direct reference between emitter and receiver.
- A fact can be appended and later queried back by type and by cycle range.
- Changing a value in a Tuning Registry file changes runtime behavior after a debug reload, with no code change.
- A new Gear Content Definition `.tres` file is picked up and readable by the Rig system without a script edit.
- Authoritative State + Fact Log both round-trip through save/load (canon §68's G10 single-rolling-slot policy) with no loss.
