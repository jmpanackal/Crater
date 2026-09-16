# Build Bible Spec 22 — Districts: Capacity / Demand / District Reserves

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #22 in [`../00-dependency-map.md`](../00-dependency-map.md). Proposed as a **thin** slice — Wickwork gets full real content; Glowbeds/Cistern get the same machinery seeded with placeholder contributors.

**Depends on:** Spec 15 (Civic Cycle), Spec 01.

---

## Purpose

The core district economy loop — Capacity, Demand, Output, District Reserves, District Reserve Cap, Unmet Demand — implementing canon §24–§26 exactly, plus the concrete G4 accounting-discrepancy mechanism that feeds Suspicion (Spec 20).

## Already locked (canon §24–§26, G4, G5 — not new)

- **Six tracked values per district**: District Capacity (production rate, grows only through lasting investment), Civic Demand, District Output (equal to Capacity each cycle — not its own independent lever), District Reserves (banked surplus), District Reserve Cap, and the derived Unmet Demand / condition label.
- **Resolution runs once per civic cycle**, at the Ritual→Rousing transition (already implemented by Spec 15's `phase_changed` hook — this spec adds the actual economic logic there, not a new timer).
- **Canon's exact 5-step resolution order**: (1) produce Output = Capacity, (2) Output serves Demand first, (3) surplus fills Reserves up to the Cap, (4) if Output is short, Reserves cover the deficit, (5) if Output + Reserves still can't meet Demand, the remainder becomes Unmet Demand.
- **Demand must be explainable** — built from named, explainable contributors (basic Hollow needs, active projects, infrastructure, etc.), never arbitrary level-scaling or simulated per-NPC consumption.
- **District condition is a derived qualitative label** (Comfortable/Stable/Strained/Shortage/Critical, DIRECTION on exact names/thresholds) — the state-ownership table already marks it "Derived | Read only; never saved as truth."
- **Diversion draws from Reserves, never lowers Capacity directly**; its harm is removing the buffer the district may need later, not an immediate production cut (§25).
- **Full Reserves doesn't mean extra Output is free to steal** — Output beyond the Cap still represents ordinary distribution/upkeep, not a socially-free surplus (§25).
- **Anti-idle principle** — production isn't something the player babysits, farms, or checks like a meter (§25).
- **G4 (A+C, already locked)**: every diversion always writes an unexplained-loss fact regardless of current Reserves (owned by Diversion, Spec 26, not this spec); at cycle resolution, the district compares expected vs. actual Reserves, and when unexplained loss since the last check crosses a threshold — lower when the district is already strained — it logs a discrepancy fact and "storage checks increase."
- **G5 (B+C, already locked)**: a shortage can spawn temporary-Capacity-granting Emergency jobs (owned by Jobs, Spec 24) and the player can return diverted Output or donate personal stores directly to Reserves, openly or anonymously (owned by this spec's `deposit` entry point).
- **Cycle resolution already has a one-directional contract with withdrawal-based systems**: "District owns District Reserves and serves withdrawal requests; neither system knows about the other" (`00-dependency-map.md`, line 299) — Orders (Spec 23) and Diversion (Spec 26) both call the same generic withdrawal entry point; District doesn't distinguish them.

## Design choices (new, this spec)

- **Demand is a sum of named contributor entries, not one opaque tunable number.** Any system with an active demand source (a civic project under construction, ongoing infrastructure maintenance, a frontier worksite) registers/unregisters its own contributor (name + amount) with the district; total Demand is just the live sum. This makes §24's "explainability" requirement automatic — the breakdown the player sees *is* the underlying data, not a separately-authored explanation that could drift out of sync with the real number.
- **District condition is computed live from current Capacity/Demand-contributors/Reserves, never cached.** Its inputs only actually change at defined moments (cycle resolution, a withdrawal/deposit, a contributor registering or unregistering), so live computation is cheap — and it keeps the condition label honestly derived rather than a stored value that could go stale, consistent with the state-ownership table's "never saved as truth" line.
- **G4's accounting-discrepancy check runs as an explicit step 6, appended after canon's 5 locked resolution steps.** It compares cumulative unexplained loss since the last check against a per-district threshold that scales down as condition worsens (Strained/Shortage districts notice smaller losses sooner), logging a `district_discrepancy` fact when crossed — this is the fact Suspicion (Spec 20) reads to compute district-scoped suspicion. "Storage checks increase" is implemented abstractly this way (a more sensitive threshold), not as a literal new Warden-patrol simulation — building real dynamic NPC patrol behavior reacting to district state would be a much larger addition (new Spec 16 scheduling logic) that nothing currently requires.

## State it owns

Per district: current Capacity (+ its list of lasting-improvement contributors), the live Demand-contributor list, current Reserves, Reserve Cap, and the last-checked Reserves value used for G4's discrepancy comparison.

## API surface

- `get_capacity(district_id)`, `get_demand_breakdown(district_id) -> [contributors]`, `get_reserves(district_id)`, `get_condition(district_id) -> label` (derived, live).
- `request_withdrawal(district_id, amount, requester_context) -> granted_amount` — generic; used identically by Orders (Spec 23) and Diversion (Spec 26). Grants only what's actually available; the requester decides what to do with a partial grant or refusal.
- `deposit(district_id, amount, source_context)` — the G5-C return/donate lever.
- `register_capacity_contributor` / `unregister_capacity_contributor`, `register_demand_contributor` / `unregister_demand_contributor` — used by Projects (Spec 29), Jobs' emergency-Capacity grants (G5-B), and temporary civic-project Demand.
- Internal: a cycle-resolution handler subscribed to Spec 15's Ritual→Rousing event runs the 5 canon-locked steps, then the G4 discrepancy check.

## Failure / edge cases

- A withdrawal request exceeding current Reserves only ever grants what's actually there — District never goes negative; how the requester handles a short grant (Diversion still "succeeding" with a bigger loss fact, an Order simply being refused) is entirely the caller's concern.
- Multiple withdrawal/deposit requests in the same cycle apply serially against the same Reserves value, matching the serial-processing pattern already established for every other autoload (Trust, etc.) — no race condition to design around.

## Acceptance tests

- A full cycle resolution for Wickwork with real contributor content matches canon's exact 5-step order: Output = Capacity, Demand served first, surplus fills Reserves up to Cap, deficit drawn from Reserves, remainder becomes Unmet Demand.
- The same cumulative unexplained loss crosses the G4 discrepancy threshold sooner in a Strained district than in a Comfortable one.
- A G5-C deposit is reflected immediately in `get_condition`'s next query, without waiting for the next cycle resolution.
- `get_condition` never returns a value inconsistent with the district's current authoritative Capacity/Demand/Reserves — there is no cached label to go stale.
