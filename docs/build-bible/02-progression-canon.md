# Build Bible 02 — Progression Canon

**Status:** DRAFT (AI-proposed, 2026-09-15; reworked 2026-09-15 — USER: structure around gameplay gates, not an hours target). This sequences everything already locked (housing ladder, dig fronts, Gear/Capacity growth, bio-fusion gating, the Act 1 story arc) by **what actually unlocks the next beat**, not by a clock. Nothing here overrides mechanics-canon.md — it only orders what's already true.

**This describes the full intended Act 1 experience, not the vertical slice.** The vertical slice (00-dependency-map.md's "thin" systems) is a smaller subset built first to prove the loop — roughly Beats 1–2 below.

## Why gates, not hours

A first pass at this doc anchored everything to a target playtime and fit content to it — backwards, and the kind of thing that makes a game feel padded or rushed depending which way the estimate is off. **Each beat below is instead defined by its content and by the condition that actually ends it** — a story trigger, a Trust/Tallies threshold, a completed district project, a dig front substantially explored. None of those conditions have fixed numbers yet (Trust thresholds, exact project costs, and district timing are all explicitly OPEN elsewhere in the canon), and they shouldn't get invented here just to make a clock work. Real pacing is something playtesting finds, not something this document should predict. A rough scale estimate sits at the very end, clearly marked as sanity-check territory, not a design target.

---

## Beat 1 — The Hollow Holds

**Content:** Home Court → Lower Switchback → West Dispatch Yard. Civic cycle, Ritual, the three districts, Firmament doctrine, baseline NPCs — the "invisible tutorial" jobs (canon §13).

**State while here:** Lower home. No dig front yet. Baseline Rig only (3 Gear slots, Capacity 3, per DIRECTION §36). Trust neutral.

**Gate to Beat 2:** the Steward's assignment is offered and accepted. A pure story trigger, not a threshold — this should be nearly immediate, since it's the game teaching itself.

---

## Beat 2 — The Steward's District

**Content:** **Bottom-West Dig Front** opens and is the entire public-work content here — First Expansion Gallery, the **Collapsed Side Chamber** as the first unauthorized side-dig (canon §68's "secret digging isn't just upward" applies from here on), first ambiguous fragment/Record, first hint something is off about Bottom-West.

**State while here:** Lower home. First Approved Gear orders become affordable as Tallies accumulate. Capacity begins growing toward its next tier as the district project progresses.

**Secret progression available:** diversion can start here — a Lower home's crude workspace can already hold diverted output and illicit Records (§67). Grafting still can't happen yet; that's gated later.

**Gate to Beat 3:** the Steward's district assignment is completed, *and* the player has done enough public work since to be offered advancement — the exact Trust/Tallies threshold is OPEN and belongs in the tuning registry, not fixed here. Completing the assignment should always be necessary; how much extra work beyond it is needed is a tuning question.

---

## Beat 3 — Earned Ascent (the long middle)

This is most of the game — where public and secret progression both do their real work. It has no single internal gate structure; it's where the player spends most of their accumulated time before the next hard transition.

**Content:** **Mid-East Dig Front** opens; district projects and deeper jobs become available; the capability web opens up across multiple Gear (Known → Understood → Available); ambient Heavenfall/doctrine texture accumulates through NPC talk; more contradictions surface.

**State while here:** **Lower → the Mid Reach** transition happens somewhere in this stretch, Trust/Tallies-gated (exact threshold OPEN). Gear slots grow 3→4; Capacity grows through the 5–8 DIRECTION range as projects complete.

**Secret progression — the key unlock:** once the Mid Reach residence is reached, **grafting itself becomes possible for the first time** (§67's Mid Reach gate). This is the actual start of Hellbinding/Voidbinding as a played system, not just diversion, and it's worth treating as its own named milestone rather than folding it quietly into "housing improved."

**Gate to Beat 4:** **Ashram Heights** is reached — explicitly Trust + Tallies + story clearance (already locked, not just leaned). This is a harder, more deliberate gate than the Beat 2→3 one; it should feel like a real achievement, not a natural byproduct of doing Beat 3's content.

---

## Beat 4 — Beneath the Firmament

**Content:** **High-West Dig Front** opens (late, guarded, near Ashram). Repeated Firmament excavation sessions — noise/debris/concealment management, per §67/§68's locked rules. The optional **Heavenfall chamber discovery** is woven into this content, not a separate destination.

**State while here:** Ashram Heights residence. 5th Gear slot; Capacity approaching its top DIRECTION value. A committed secret-path player likely has multiple grafts by now, supported by Ashram Heights' improved workspace tier.

**Gate to Beat 5/6:** sustained Firmament excavation makes real progress — session after session, per the canon's own description of this as a multi-session project, not a single dig. What "enough progress" means (a progress value, an authored sequence of sub-stages, required Gear/knowledge per game-pitch.md's "with the necessary Forbidden Gear, knowledge, and persistence") is OPEN and belongs in the Build Bible spec for Firmament progression specifically, not invented here.

---

## Beat 5 — The Cost of Looking

**Content:** a single authored consequence (a friend covers for the player, or is hurt by a lie), triggered by story state during or after Beat 4. Not a stretch of gameplay — a discrete scripted moment, deliberately not systemic.

---

## Beat 6 — The Breach

**Content:** the Firmament finally breaks open. Surface revealed. Act 1 ends.

---

## Vertical slice cut

If this beat structure is right, the **vertical slice** — the first playable thing worth building — is **Beats 1–2**: Home Court through Bottom-West, one district resolving, one job, the Collapsed Side Chamber as the first optional secret content, and diversion (but not yet grafting) as the introduction to secrecy. That matches what 00-dependency-map.md already scoped as "thin" for most systems. No hour figure attached — it's exactly as long as that content actually takes to make and play, which is a question for the team building it, not this document.

## Rough scale, for production sanity-checking only — not a target

Three residence tiers, three dig fronts, a full capability web, and a Firmament-breach climax is real content — closer to a compact Metroidvania/Dome Keeper-scale game than a short demo. If a rough order of magnitude is useful for early production planning, low-to-mid single digits of hours for critical path and meaningfully more for a player who explores and pursues secret progression is a reasonable expectation to hold loosely. This number should be revisited from actual playtesting once Beats 1–2 exist, not treated as something the design should hit.

## OPEN — needs your call

- Exact Trust/Tallies thresholds for each housing/dig-front gate (Beat 2→3, Beat 3→4) — tuning registry territory.
- What "enough Firmament progress" concretely means for the Beat 4→6 gate — likely its own dedicated Build Bible spec (Firmament excavation as a system), not a number here.
- Whether Beat 3's Mid Reach transition should be able to happen early or late within that beat by design, or whether it should always land at roughly the same relative point regardless of how a given player plays.
