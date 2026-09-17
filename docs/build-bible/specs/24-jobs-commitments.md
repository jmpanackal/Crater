# Build Bible Spec 24 — Jobs + Commitments

**Status:** ✅ CONFIRMED (USER, 2026-09-17) — all design choices reviewed in chat and accepted. Build-order #24 in [`../00-dependency-map.md`](../00-dependency-map.md). Proposed as a **thin** slice — the one opening job (§15's reference scenario) is the only fully authored content.

**Depends on:** Spec 15 (Civic Cycle), Spec 11 (Materials), Spec 13 (Hauling), Spec 22 (Districts), Spec 19 (Trust).

---

## Purpose

The five work types and graded outcomes from canon §13–§14, built as real state — and the concrete site where Jobs actually calls into Wallet (Spec 23) and Trust (Spec 19) at settlement.

## Already locked (canon §13, §14, §15, §16 — not new)

- **Five work types**: Available Work (no promise; ignoring it isn't inherently a Trust violation), Accepted Work/Commitment (a voluntary agreement creates a real expectation), Assigned Duty (expected because of civic role, common early), Emergency/World Need (happens regardless of player choice; participation optional, never a broken promise), Personal NPC Request (contextual consequences, never automatic global Trust change).
- **"Not helping is not the same as promising and failing"** (§13, LOCKED) — the central distinction this spec's Trust-consequence logic has to respect.
- Jobs are physical civic situations built from the game's normal systems — digging, hauling, traversal, districts, infrastructure, Materials, social context — never quest-state checklists or job-specific minigames.
- Not every job has a hard countdown; different work uses different deadline shapes: this cycle, during Working, before Gathering, during Gathering, multi-cycle, no strict deadline.
- Graded outcomes (poor/adequate/strong/exceptional, conceptually) are **not** a universal visible star rating — different jobs care about different things, and NPCs react to what actually happened.
- Presentation resembles believable commitments/notes/assignments/work records, not a universal checklist UI.
- Ordinary expected job completion primarily earns Tallies, not Trust (§16/§17) — Trust changes only for the specific categories §17 already names (serious failures, broken commitments, above-and-beyond), never for routine completion.
- The opening-job reference pattern (§15): Home Court → Dispatch → worksite → excavation → recognize/extract Material → haul/deliver → see where it goes → earn Tallies → Gathering/Ritual — a design reference, not a rigid script, and this spec's one authored vertical-slice job.
- Dependency map's already-resolved cycle: "Jobs emit settlement facts; Trust reads facts. Jobs only query Trust" (`00-dependency-map.md`, line 298).
- **Higher Trust already unlocks "better assignments" — this is canon, not new.** §17 lists "better assignments" and "more autonomy" among what higher Trust provides; §13 says Trust/experience "should gradually unlock more autonomy, better assignments, more access, more responsibility, more opportunity." This spec is what makes that concrete.

## Design choices (✅ Confirmed, USER, 2026-09-17)

- **A job can require a minimum Trust standing just to be offered, and higher-tier jobs pay more Tallies** (option A). "Better assignments" aren't flavor text — a job's Content Definition can declare a minimum Trust standing gating `offer()`, the same way every other Trust-gated thing in this Build Bible reads `Trust.get_trust(context)`, and its Tallies reward scales with that tier. This gives Trust a tangible, legitimate payoff beyond access alone, without turning Tallies into something Trust can buy directly — the player still has to actually do the higher-tier work to earn the higher pay; Trust only decides whether that work is on offer at all. Exact tier thresholds and pay scaling stay Tuning Registry territory, same as every other numeric value in this document.
- **Breaking a higher-tier Accepted Work/Assigned Duty commitment costs more Trust than breaking a routine one** (option A). Extends the already-confirmed rule that only these two work types can produce a negative Trust event on failure: the *magnitude* of that event now scales with the job's own tier, since society extended more trust to offer a better assignment in the first place, and breaking it should cost proportionally more. A missed routine duty and a missed high-trust assignment are still mechanically the same kind of event (one `submit_trust_event` call at settlement) — only the delta differs, read from the job's tier the same way the reward is. Exact scaling curve is tuning-registry territory, not fixed here.

- **Settlement is the single resolution point, and Jobs is the explicit caller into Wallet and Trust — never a passive fact the other systems watch for themselves** (option A). Every job instance ends in a `settle()` call that grades the outcome against that job's own criteria, always calls `Wallet.earn(...)` for ordinary completion, and conditionally calls `Trust.submit_trust_event(...)` only for the specific categories §17 already names. This makes concrete what the dependency map's "Jobs emit settlement facts; Trust reads facts" line means in practice: Jobs is the system that decides an outcome is Trust-worthy and explicitly submits it, matching Spec 19's already-confirmed contract that Trust is a passive recipient that never infers anything on its own from the Fact Log. Rejected: Trust listening to the Fact Log directly and self-triggering off Jobs' settlement facts, which would contradict Spec 19's own design choice.
- **Only Accepted Work/Commitment and Assigned Duty can ever produce a *negative* Trust event on failure** (option A). Available Work, Emergency/World Need, and Personal NPC Request never can — this is a direct, concrete restatement of §13's explicit lines ("ignoring [Available Work] is not inherently a Trust violation," Emergency work should never "pretend the player made a promise they never made," Personal NPC Request consequences "do not automatically become global Trust changes"). An *exceptional*, above-and-beyond outcome can produce a positive Trust event regardless of work type, since going beyond isn't about breaking a promise in the first place.
- **Deadlines are one of several named shapes read from a job's own Content Definition** (option A) (`this_cycle`, `during_working`, `before_gathering`, `during_gathering`, `multi_cycle`, `none`) — Jobs asks "has this job's own deadline condition passed" using whichever shape that job was authored with, rather than forcing every job through one generic countdown timer. Directly matches §14's explicit list of different deadline expectations.
- **Only Commitment and Duty types pass through a real "Accepted" stage** (option A). Available Work, Emergency/World Need, and Personal NPC Request skip it entirely — their lifecycle is Offered → In Progress (or resolves in the background without the player at all) → Settled, with no formal acceptance step, because no promise is ever made for these types in the first place. Giving them an "Accepted" stage would misleadingly imply a commitment exists where canon explicitly says none does. Rejected: one uniform Offered → Accepted → In Progress → Settled machine for every work type — simpler code, but it manufactures a promise for types §13 explicitly says never carry one.

## State it owns

Job instances (id, work type, deadline shape, current stage, target/content reference) and their settlement grade once resolved — matches the state-ownership table's "Job instances + state machine | Jobs | Authoritative | Accept / progress / settle."

## API surface

- `offer(job_id)` — makes a job visible/available; fails to offer a job whose Trust-tier requirement isn't currently met.
- `accept(job_id)` — valid only for Commitment/Duty types.
- `progress(job_id, ...)` — updates driven by world actions (digging, hauling, delivering) matched against that job's own definition of progress.
- `settle(job_id)` — grades the outcome, always calls `Wallet.earn(...)` for ordinary completion, conditionally calls `Trust.submit_trust_event(...)` per the work-type rule above.
- `get_active_jobs()`, `get_deadline_status(job_id)`.

## Failure / edge cases

- Abandoning an Accepted job before its deadline settles as a broken commitment — Trust-relevant, not a silent disappearance.
- An Emergency/World Need job that resolves without any player involvement settles with no Trust event and no Tallies, matching "the game should not pretend the player made a promise they never made."
- Only the opening job is real authored content for this spec; everything else here is the contract other jobs will later plug into, matching the build order's "thin (opening job)" note.

## Acceptance tests

- The opening job (Home Court → Dispatch → worksite → excavate → extract → haul/deliver → Tallies → Gathering/Ritual) runs end to end and settles with a grade, earning Tallies.
- Abandoning an Accepted Work job before its deadline settles as a broken commitment and calls exactly one Trust event.
- A higher-tier job pays more Tallies on success than a routine one, and a broken higher-tier commitment produces a larger negative Trust event than a broken routine one.
- A job whose Trust-tier requirement isn't met is never offered in the first place.
- Ignoring an Available Work job produces no settlement and no Trust event if the player never engages with it.
- An Emergency/World Need job resolving without the player produces no Trust event.
