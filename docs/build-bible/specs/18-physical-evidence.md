# Build Bible Spec 18 — Physical Evidence

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #18 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 06 (Terrain), Spec 01.

---

## Purpose

The "cold case" counterpart to Spec 17's Witness: a persistent world trace of forbidden/restricted activity that stays discoverable after the fact, independent of whether anyone was present to see it happen — per canon §19's "forbidden excavation can leave persistent evidence" and its listing of persistent physical evidence as its own detection category alongside sight and sound.

## Already locked (canon §19 — not new)

- Detection includes persistent physical evidence as a category distinct from sight/sound.
- Forbidden excavation can leave persistent evidence.
- The same underlying event (e.g. digging a restricted wall) can produce **both** a Witness fact (Spec 17, if someone saw it) **and** leave behind evidence discoverable later — the two are not mutually exclusive outcomes of one action.

## Scope boundary (not a choice — clarifying against nearby systems)

Concealed workspace/personal-storage discovery (searching a residence for a hidden bench or stockpile) is Spec 27's job, built on its own qualitative concealment-tier model (§62: Basic/Improved/Advanced). This spec covers evidence anchored to **world locations** — terrain, seals, restricted structure — not personal storage or the body (Spec 14's graft concealment).

## Design choices (new, this spec)

- **Evidence is a flag on the terrain delta itself, not a second registry.** When Terrain (Spec 06) records a dig whose target zone is restricted (the calling system's own check, same as Spec 17's pattern — Terrain reads the zone's authored sanctioned/restricted flag, not something Evidence tracks separately), it tags that specific delta `evidence: true`. Anything that later reads terrain state there (an authored investigation, an NPC patrol check) can find it. Rejected: a standalone Evidence system independently tracking discoverable world coordinates — that would duplicate the position data Terrain already owns and persists (Spec 06/02's existing save contract already covers it for free).
- **Discovery is investigation-triggered, not proximity/ambient.** Evidence sitting in the world does not alert anyone by merely existing — it's found only when something actively checks that location: an authored investigation event (Spec 20) or a scripted NPC search. This generalizes §62's "safe by default" philosophy beyond the hidden workspace, and reuses the dependency map's already-resolved shape for this exact kind of cycle: "Investigation emits a search-requested event; [the owning system] resolves the search... and emits found-evidence facts" (`00-dependency-map.md`, line 301). Rejected: ambient detection where a passing NPC's patrol automatically notices evidence — that would turn every patrol route into a suspicion generator, contradicting "safe by default."
- **Evidence doesn't expire or self-repair for the vertical slice.** Once a restricted wall is excavated, it stays excavated and stays flagged as evidence until some explicit action changes it — canon describes no decay or auto-repair mechanic. (§62 does mention "cleaning physical evidence," but that's part of Spec 27's workspace-concealment mechanic, not a general world-evidence repair system this spec needs to invent.)

## State it owns

None new — an `evidence` tag added to Terrain's already-owned per-delta state (Spec 06). No second source of truth for where digging happened.

## API surface

- Terrain (Spec 06) tags a delta `evidence: true` at dig time when the target zone is restricted — an extension of its existing `dig()` contract, not a new entry point.
- `resolve_search(zone_id_or_position) -> [evidence_found]` — called by Investigation (Spec 20) in response to a search-requested event; reads flagged deltas in range and returns what's found, which Investigation then logs as `found_evidence` facts via Spec 01.

## Failure / edge cases

- A search of a zone with no flagged evidence returns an empty result, not an error.
- Evidence flags persist across save/load exactly like any other terrain delta — already covered by Spec 06/02's existing round-trip contract, no new persistence work required.

## Acceptance tests

- Digging inside a restricted zone flags that delta as evidence; digging inside a sanctioned zone does not.
- A search-requested event against a zone containing flagged evidence returns it via `resolve_search`; a search of a clean zone returns nothing.
- Evidence flags survive a save/load cycle.
