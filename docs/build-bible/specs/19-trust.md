# Build Bible Spec 19 — Trust (+ Reasons View)

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #19 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01.

---

## Purpose

The single global Trust value and its human-readable reasons list, implementing canon §17 and the already-locked G16 granularity decision.

## Already locked (canon §17, G16/§68 — not new)

- One global Trust value for Act 1 (G16), with local suspicion tracked separately per NPC/district/Wardens/location/incident (Spec 20's job, not this one).
- Trust is presented to the player as ~4–5 qualitative standing states, never a raw number; exact internal values may exist for tuning.
- Trust changes selectively — repeated reliability, meaningful help, above-and-beyond behavior, serious failures, broken commitments, betrayal, caught stealing, exposed lies, major accomplishments — **not** from ordinary job completion, which earns Tallies instead.
- Meaningful Trust changes are communicated with human-readable reasons, never floating `+X Trust` popups or silent tiny modifiers (explicitly CUT).
- Trust cannot erase hard evidence — Trust and evidence/suspicion are independent, never one suppressing the other.
- Dependency map contract: Trust is authoritative but changes only through named, reasoned change events read from facts (`00-dependency-map.md`, line 178); "Jobs emit settlement facts; Trust reads facts. Jobs only query Trust" (line 298); "Dialogue writes a `claim_made` fact; contradiction checks are derived; exposure emits a fact that Trust reads" (line 303).
- G16 already requires Trust to expose a context-aware query (`get_trust(context)`) from the start, so group-specific modifiers (Wardens reading Trust differently than ordinary residents) can be added later without breaking the contract — even though only the global context is used in Act 1.

## Design choices (✅ Confirmed, USER, 2026-09-15)

- **Trust changes only through a submitted, reasoned event — never a direct write from another system** (option A). Any system that wants Trust to move calls `submit_trust_event(type, delta, reason_text)`; Trust applies the delta and appends the reason to its own list. This keeps "why did Trust change" always answerable from Trust's own state and matches the state-ownership table's existing line: "Trust value + reason list | Trust | Authoritative | Submit reasoned change events." A `reason_text` is required, not optional — enforcing the CUT list's ban on unexplained modifiers at the contract level, not just by convention.
- **The internal value is a plain scalar** (option A), not a multi-dimensional model — nothing in canon asks for more, and it matches how every other tunable number in the Build Bible so far (Rig Strain, District Reserve Caps) has stayed a simple value pending playtest tuning.
- **Standing-state thresholds live in the Tuning Registry (Spec 01), not hardcoded in Trust** (option A). Consistent with how every other threshold decided so far in this Build Bible has been deferred to tuning rather than fixed in a system's own script.
- **The reasons list is a capped, recent-window display log, not a permanent unbounded history** (option A). §17 explicitly asks to "surface recent important events" while avoiding "dozens of tiny permanent modifiers" — the full permanent record already exists in the Fact Log (Spec 01, append-only); Trust's own reasons list only needs to serve the UI's "why does society (dis)trust me right now" view.

## Flagged for Spec 21 (Dialogue + Questioning) — not decided here, captured so it isn't lost

This batch's discussion surfaced two dialogue-lie ideas that touch Trust's `exposed_lie` category but don't change anything in *this* spec's contract — `submit_trust_event` stays generic either way. Both are OPEN, for Spec 21 to actually design:

- **Two-tier claim tagging.** Dialogue's already-sketched `claim_made` fact (`00-dependency-map.md`, line 303) could carry a `trust_relevant: true/false` tag set per dialogue node. A comforting white lie ("it'll be fine" to a worried NPC) still writes a `claim_made` fact — so the world remembers it happened and writers can reference it in later authored dialogue — but is tagged `false`, so even if later contradicted it never calls `submit_trust_event`. A self-serving cover-up lie is tagged `true` and *does* call it when exposed. Consequence for a caught white lie, under this shape: narrative-only (an authored follow-up line), not a new mechanical stat — introducing a per-NPC "rapport" value separate from Trust was considered and set aside as real new scope nothing else in the game currently has, not a quick addition.
- **Behavior/economy-linked predictive claims** (USER idea): a claim like answering "will there be another shortage?" isn't checked against a past fact, it's checked against *future* derived state (District output trends, Spec 22; the player's own theft pattern, Spec 26) — meaning dialogue could commit the player to a prediction that the world later proves right or wrong. This is a genuinely good cross-system connection (ties chit-chat into the district economy rather than leaving it as isolated flavor, matching §60's Design Test), but it's structurally bigger than the two-tier tag above — it needs a claim that resolves later against emergent state rather than an immediate fact check. Worth a real design pass when Spec 21 comes up, not decided now.

## State it owns

Current Trust value (scalar); a capped recent-reasons list (each entry: reason text, event type, timestamp/cycle).

## API surface

- `get_trust(context?) -> standing_state` — context-aware query; only the global context is meaningfully used in Act 1, shaped for future group modifiers per G16.
- `get_trust_reasons() -> [recent reasons]`
- `submit_trust_event(type, delta, reason_text)` — applies the delta, appends the reason, emits a `trust_changed` event for the UI.

## Failure / edge cases

- Multiple systems submitting trust events in the same frame apply serially, same as every other autoload under the established Event Bus pattern — no race condition to design around.
- A `submit_trust_event` call missing `reason_text` should fail loudly in debug builds rather than silently accepting an unexplained modifier.

## Acceptance tests

- Submitting a trust event changes the value and appends a matching, retrievable reason.
- `get_trust()` returns one of the qualitative standing states for UI-facing calls, never a raw number.
- Ordinary job completion (a Tallies-earning event) does not by itself submit a trust event, confirming Trust and Tallies stay separate per §17.
