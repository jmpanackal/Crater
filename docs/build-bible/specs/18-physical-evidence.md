# Build Bible Spec 18 — Physical Evidence

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #18 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 06 (Terrain), Spec 01.

---

## Purpose

The "cold case" counterpart to Spec 17's Witness: a persistent world trace of forbidden/restricted activity that stays discoverable after the fact, independent of whether anyone was present to see it happen — per canon §19's "forbidden excavation can leave persistent evidence" and its listing of persistent physical evidence as its own detection category alongside sight and sound.

## Already locked (canon §19, §61, §62, §67 — not new)

- Detection includes persistent physical evidence as a category distinct from sight/sound.
- Forbidden excavation can leave persistent evidence.
- The same underlying event (e.g. digging a restricted wall) can produce **both** a Witness fact (Spec 17, if someone saw it) **and** leave behind evidence discoverable later — the two are not mutually exclusive outcomes of one action.
- **Secrecy is one of the five already-named build dimensions** (§61: Excavation, Survey, Hauling/Endurance, Mobility, Secrecy) — this spec gives that dimension its first concrete expression.
- **Concealment is already locked as qualitative/state-based, not percentage-based**, using a shared Basic / Improved / Advanced tier model — established for the hidden workspace (§62) and reused independently for on-body grafts (§67, "the same qualitative tiers already locked for the hidden workspace... but tracks independently"). This spec reuses that same tier model again for world evidence, rather than inventing a fourth concealment mechanic.

## Scope boundary (not a choice — clarifying against nearby systems)

Concealed workspace/personal-storage discovery (searching a residence for a hidden bench or stockpile) is Spec 27's job, built on its own qualitative concealment-tier model (§62: Basic/Improved/Advanced). This spec covers evidence anchored to **world locations** — terrain, seals, restricted structure — not personal storage or the body (Spec 14's graft concealment).

## Design choices (✅ Confirmed, USER, 2026-09-15)

- **Evidence is a flag on the terrain delta itself, not a second registry** (option A). When Terrain (Spec 06) records a dig whose target zone is restricted (the calling system's own check, same as Spec 17's pattern — Terrain reads the zone's authored sanctioned/restricted flag, not something Evidence tracks separately), it tags that specific delta `evidence: true`. Anything that later reads terrain state there (an authored investigation, an NPC patrol check) can find it. Rejected: a standalone Evidence system independently tracking discoverable world coordinates — that would duplicate the position data Terrain already owns and persists (Spec 06/02's existing save contract already covers it for free).
- **Discovery is investigation-triggered, not proximity/ambient** (option A). Evidence sitting in the world does not alert anyone by merely existing — it's found only when something actively checks that location: an authored investigation event (Spec 20) or a scripted NPC search. This generalizes §62's "safe by default" philosophy beyond the hidden workspace, and reuses the dependency map's already-resolved shape for this exact kind of cycle: "Investigation emits a search-requested event; [the owning system] resolves the search... and emits found-evidence facts" (`00-dependency-map.md`, line 301). Rejected: ambient detection where a passing NPC's patrol automatically notices evidence — that would turn every patrol route into a suspicion generator, contradicting "safe by default," and would require exposing patrol routes/timing as a real learnable stealth-game system nothing in canon currently asks for.
- **Evidence is concealable, but only with the right Material and a real action — not free, and not permanent-by-default** (revised choice, option B). A "seal kit" Material/Component (Spec 11) plus a hold-to-interact "seal" action (reusing Spec 10's interaction shape, same pattern as extraction and theft) removes a delta's `evidence: true` flag at the cost of consuming the kit. What tier of concealment the seal achieves reuses the already-locked Basic / Improved / Advanced qualitative model (§62/§67) rather than a binary sealed/unsealed state — a Basic seal is safe from a casual pass-through but not a targeted search; better tiers require better kits or Secrecy-build Gear (Spec 14) to achieve, giving the already-named Secrecy build dimension (§61) its first concrete payoff. A search (`resolve_search`) must beat the achieved tier to find sealed evidence, the same resolution shape already used for workspace search. Left open for tuning: exact kit recipe(s), which specific Secrecy Gear improves which tier, and exact search-vs-tier resolution numbers — this spec only locks the shape (material-gated, tiered, reuses the existing concealment model), not the values.

## State it owns

An `evidence` tag (plus, when sealed, a concealment tier) added to Terrain's already-owned per-delta state (Spec 06). No second source of truth for where digging happened.

## API surface

- Terrain (Spec 06) tags a delta `evidence: true` at dig time when the target zone is restricted — an extension of its existing `dig()` contract, not a new entry point.
- `seal(position, kit_id)` — consumes the seal-kit Material/Component (Spec 11) via a hold-to-interact action (Spec 10); on completion, sets the delta's concealment tier per the kit/Gear used and clears its exposed `evidence: true` state until a search beats that tier.
- `resolve_search(zone_id_or_position) -> [evidence_found]` — called by Investigation (Spec 20) in response to a search-requested event; reads flagged deltas in range, resolves any sealed ones against their concealment tier, and returns what's actually found, which Investigation then logs as `found_evidence` facts via Spec 01.

## Failure / edge cases

- A search of a zone with no flagged (or with only successfully-concealed) evidence returns an empty result, not an error.
- Canceling a seal mid-hold leaves the evidence exactly as it was — no partial concealment, matching the already-established cancellable hold-to-interact pattern.
- Evidence and concealment-tier state persist across save/load exactly like any other terrain delta — already covered by Spec 06/02's existing round-trip contract, no new persistence work required.

## Acceptance tests

- Digging inside a restricted zone flags that delta as evidence; digging inside a sanctioned zone does not.
- Sealing a flagged delta with a seal kit clears its exposed evidence state and records a concealment tier; a subsequent search must beat that tier to find it.
- Canceling a seal mid-hold leaves the delta exactly as it was before.
- A search-requested event against a zone containing unconcealed flagged evidence returns it via `resolve_search`; a search of a clean or successfully-concealed zone returns nothing.
- Evidence and concealment state survive a save/load cycle.
