# Build Bible Spec 20 — Suspicion + Investigation (Derived)

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #20 in [`../00-dependency-map.md`](../00-dependency-map.md). Proposed as a **stub**: the general contract is real, but only one authored investigation case is built for the vertical slice.

**Depends on:** Spec 17 (Witness), Spec 18 (Evidence), Spec 19 (Trust).

---

## Purpose

Turning the raw facts Witness and Evidence already write into local, contextual Suspicion, and — for the one case the vertical slice actually needs — a real Investigation that can resolve into a Trust consequence. This is the missing link between "something happened" (Specs 17/18) and "something happens about it" (Spec 19).

## Already locked (canon §19, §30, G4 — not new)

- **No universal global Suspicion meter.** Suspicion belongs to an NPC, a district, the Wardens, a location, or an incident (§19) — never one player-wide number.
- **Suspicion and investigation stage are derived, never saved as truth** — the dependency map's state-ownership table lists both under "Their derived systems | Derived | Read only," and the contract line is explicit: "Suspicion and investigation are derived from facts and never saved as truth" (`00-dependency-map.md`, line 178).
- **Repeated unexplained losses can increase storage checks, Warden presence, local restrictions, investigation — "these can be authored/state-driven rather than a full detective simulator"** (§30, LOCKED). This spec takes "state-driven" at face value: a small generic rule reacting to derived Suspicion, not hand-authored content for every possible case.
- **G4 already locks the concrete first suspicion source for Districts**: every diversion always writes an unexplained-loss fact (G4-A), and at cycle resolution the district compares expected vs. actual Reserves — when unexplained loss since the last check crosses a threshold (lower when the district is already strained), it logs a discrepancy fact (G4-C). Spec 22 (Districts) owns producing this fact; this spec is what reads it.
- **The Investigation ↔ Home search ↔ Workspace cycle is already resolved**: "Investigation emits a search-requested event; Homes resolves the search against the concealment tier and emits found-evidence facts" (`00-dependency-map.md`, line 301). Spec 18's `resolve_search` for world evidence already follows this exact shape — this spec is what emits the `search_requested` event both of them listen for.

## Design choices (new, this spec)

- **Suspicion is a pure derived query, never a stored value.** `get_suspicion(context)` recomputes live from a recent window of relevant facts in the Fact Log (Witness facts scoped to that NPC/location, Evidence-adjacent facts, District discrepancy facts scoped to that district) — nothing is cached or persisted. This is a direct consequence of the already-locked "derived, never saved as truth" contract, not a fresh judgment call, but it's worth stating explicitly because it also gives Suspicion a free, natural cooldown: older facts simply age out of the window, so nothing needs an explicit decay timer.
- **Investigation triggers two ways, both real for this slice.** (1) A generic, state-driven rule: whenever a new fact could raise Suspicion for some context, recompute it, and the first time it crosses a tunable threshold for that context, automatically emit a `search_requested` event scoped to it. (2) An authored path: `trigger_investigation(context, reason)`, called directly by story content, bypassing the threshold entirely. The vertical slice only needs one hand-built case using path (2), but path (1) is the same generic rule already implied by G4/§30's "state-driven" language and by Spec 18's own design (which already assumed Suspicion could auto-trigger a search against sealed evidence) — building it now costs little and is what lets Evidence (Spec 18) ever actually get discovered outside of a scripted beat. Rejected: authored-only investigations for this slice, generic triggering deferred — that would leave Spec 18's evidence system with no real way to surface on its own, undercutting the "world reacts to accumulated behavior over time" feeling already assumed when Spec 18 was designed.
- **An Investigation's "stage" is itself derived from its own sequence of facts** (`search_requested` → `found_evidence`/`found_nothing` → optionally `escalated`), not a stored state machine object. Reading "what stage is this investigation at" just means reading the latest relevant fact for that context — consistent with the same "derived, not saved" reasoning as Suspicion itself, and avoids needing a second, parallel save format for investigation state that could drift from what the Fact Log already says happened.

## Where consequences actually land

When a search resolves with real (unconcealed) evidence tying the incident to the player, Investigation is the system that calls `Trust.submit_trust_event(...)` (Spec 19) — closing the loop the dependency map already describes generically. This isn't a separate choice so much as wiring the two already-locked contracts together: Investigation is exactly the "system that determined something Trust-worthy actually happened" that Spec 19's design assumed would exist.

## State it owns

None. Fully derived — reads the Fact Log (Spec 01), Terrain's evidence flags (Spec 18), and District's discrepancy facts (Spec 22) to answer `get_suspicion` and `get_investigation_stage` queries live.

## API surface

- `get_suspicion(context) -> level` — `context` is an NPC id, district id, location/zone id, or incident id, matching §19's scoping.
- `get_investigation_stage(context) -> stage` — derived from the latest relevant fact for that context.
- `trigger_investigation(context, reason)` — authored/story entry point; emits `search_requested` directly.
- Internal: a Fact Log listener recomputes Suspicion for the relevant context on each new fact and emits `search_requested` the first time a context crosses its threshold.
- On a search's resolution fact (from Spec 18 or, later, Spec 27), if it resolves to real evidence tied to the player, calls `Trust.submit_trust_event(...)` with a reason built from the resolved facts.

## Failure / edge cases

- A threshold-triggered search that resolves to `found_nothing` (evidence was never there, or was successfully concealed per Spec 18) still logs that resolution, so the same context doesn't immediately re-trigger on the very next fact — it has to cross the threshold freshly again.
- `trigger_investigation` always fires regardless of current computed Suspicion — authored content isn't blocked by the generic threshold rule.
- Undetected activity that never crosses a threshold and is never authored-triggered simply never becomes an Investigation — matches §30's explicit "undetected theft does not automatically lower Trust simply because the game knows the player did it."

## Acceptance tests

- A single Witness fact for a given NPC does not cross the threshold; enough facts within the recent window do, and crossing it emits exactly one `search_requested` event for that context.
- The vertical slice's one authored investigation can be triggered via `trigger_investigation` regardless of the current computed Suspicion level.
- A resolved search against successfully concealed (sealed) evidence produces `found_nothing`, not `found_evidence`.
- A resolved search that finds real, unconcealed evidence results in exactly one `submit_trust_event` call.
