# Build Bible Spec 21 — Dialogue + Questioning

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #21 in [`../00-dependency-map.md`](../00-dependency-map.md). Proposed as a **thin** slice — the claim/contradiction/exposure contract is real, authored dialogue content is minimal.

**Depends on:** Spec 19 (Trust), Spec 01.

---

## Purpose

Implementing canon §18's contextual lying model — no generic Lie button; truth, lies, deflection, and partial truth all emerge from specific believable questioning moments, with outcomes that depend on evidence, witnesses, and Trust rather than a hidden success roll.

## Already locked (canon §18 — not new)

- No generic **Lie** button. Lying emerges contextually when the player is questioned about something believable.
- Possible responses: truth, lie, deflection, partial truth.
- Outcome depends on the claim made, available evidence, witnesses, circumstances, and Trust.
- Higher Trust gives more benefit of the doubt in ambiguous situations; Trust cannot erase hard evidence.
- No displayed success percentages (e.g. never "78% chance to lie successfully").
- Exposed lies can damage Trust more than simply admitting the truth.
- Example believable contexts: late to an accepted job, caught near restricted excavation, missing Ritual, seen from a forbidden direction.
- Dependency map contract: "Dialogue writes a `claim_made` fact; contradiction checks are derived; exposure emits a fact that Trust reads" (`00-dependency-map.md`, line 303) — this spec implements that contract.

## Design choices (✅ Confirmed, USER, 2026-09-15)

- **Every claim is authored with a `trust_relevant: true/false` tag** (option A) (this is choice 47's follow-up, flagged in Spec 19 and locked here now that this is that spec). A `claim_made` fact is written either way — the Fact Log remembers everything that was said, so a writer can always reference it later — but only a `trust_relevant: true` claim can ever feed a Trust consequence. A reassuring but inaccurate answer to someone anxious about the Ritual is tagged `false`: it's remembered, it can be referenced narratively later (an authored follow-up line, nothing mechanical), but it can never call `submit_trust_event` even if later contradicted. A self-serving claim ("I wasn't near Wickwork last night") is tagged `true`. Rejected: one undifferentiated lie category for everything, which would either force every kind fib to risk Trust or require hand-exempting cases one at a time instead of a single authored tag.
- **Predictive claims (checked against future derived state, not a past fact) are out of scope for this slice** (option B). The idea raised earlier — a claim like "will there be another shortage?" resolving later against District trend data (Spec 22) or the player's own diversion pattern (Spec 26) — is a genuinely good connection between dialogue and the district economy, but it needs a claim that gets "remembered" and re-checked at a future resolution point, which is real new complexity this thin slice doesn't need before the core claim/contradiction/exposure loop is even proven out. This spec's claims only ever check against the Fact Log's existing record. Predictive claims are captured as a DIRECTION for a later pass, not built now.
- **Deflection and partial truth are authoring shapes, not separate mechanical categories** (option A). A partial truth is just a claim like any other (tagged, checkable, exposable) — the "partial" is in what the claim actually asserts, decided by the dialogue author, not a distinct system. Pure deflection writes no `claim_made` fact at all — nothing was committed to, so there's nothing to later contradict or expose. No third mechanical branch is needed beyond "a checkable claim was made" or "it wasn't."
- **Exposure requires an in-fiction moment, not silent automatic detection** (option A). A contradiction becoming technically derivable (the Fact Log now disagrees with a stored claim) does not, by itself, do anything. Exposure only happens when something surfaces it — Investigation (Spec 20) resolving a search that conflicts with an earlier claim, or an authored confrontation dialogue node that specifically calls it out. This matches §19's "the world should record meaningful facts rather than simulate perfect NPC knowledge" and §30's "Trust represents what society knows/believes" — not what the Fact Log technically contains. Rejected: automatically firing an `exposed_lie` event the instant a contradiction becomes derivable, which would make the world quietly omniscient in exactly the way canon warns against.

## State it owns

None new — claims live as `claim_made` facts in the Fact Log (Spec 01); dialogue content itself is authored Content Definitions (Spec 01), not runtime state this system owns.

## API surface

- `make_claim(claim_id, trust_relevant: bool, context)` — logs a `claim_made` fact.
- `is_contradicted(claim_id) -> bool` — a derived check comparing the claim against the Fact Log's actual record (e.g. a Witness fact placing the player elsewhere).
- `expose_claim(claim_id)` — called by Investigation (Spec 20) on a conflicting resolution, or by an authored confrontation node; if the claim is `trust_relevant` and `is_contradicted`, calls `Trust.submit_trust_event("exposed_lie", ...)`.

## Failure / edge cases

- A `trust_relevant` claim that's contradicted but never exposed never triggers anything — matches §30's "undetected theft does not automatically lower Trust" applied the same way to lying.
- A `trust_relevant: false` claim can never trigger a Trust event even if `expose_claim` is called on it — the tag is a hard gate, not a modifier.
- Deflection produces no `claim_made` fact, so `is_contradicted`/`expose_claim` have nothing to operate on.

## Acceptance tests

- A `trust_relevant` claim later contradicted by a Witness fact, when exposed via Investigation, produces exactly one `exposed_lie` Trust event.
- The same scenario with `trust_relevant: false` produces zero Trust events.
- Deflecting a question produces no `claim_made` fact and cannot later be exposed.
