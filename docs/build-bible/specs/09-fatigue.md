# Build Bible Spec 09 — Fatigue / Overexertion / Recovery

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #9 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 04 (Clock — sleep triggers full recovery), Spec 08 (Stamina — fatigue blocks part of it).

---

## Purpose

Longer-lasting expedition strain that doesn't clear through ordinary stamina regeneration, and the recovery paths (sleep, field rest) that do clear it — canon §10's Recovery rules, operationalized.

## Already locked (canon §10 — not new)

- Fatigue blocks part of the stamina bar and does **not** disappear through ordinary regeneration.
- Sleep provides full or near-full recovery. Field rest provides partial recovery at a time cost. Proper rest points are rare, tied to established Hollow/worksite infrastructure.
- No hunger/thirst meters, no random injury systems, no fatigue-via-ordinary-regen loophole.

## Design choices

- **Overexertion adds a fixed fatigue cost per instance**, not scaled to how far past zero the triggering action would have gone. Simpler and more predictable for the player to learn and telegraph against, matching canon §54's emphasis on consequences feeling earned rather than surprising. Scaling can be revisited later if flat costs feel unsatisfying in play.
- **Resting is an explicit interaction, not passive proximity.** Approaching a rest point and interacting (via Spec 10) triggers the recovery, rather than fatigue just draining automatically while standing nearby — keeps rest a deliberate choice/time cost rather than something to idle next to.

## State it owns

Current fatigue amount, the resulting stamina block it creates, exhausted flag (true once fatigue alone fills the bar).

## API surface

- `add_from_overexertion()` — called by Stamina when an Overexertion resolves.
- `recover_full()` — called by sleep (via the Clock's cycle-advance).
- `recover_partial(amount)` — called by field rest, at whatever time cost the specific rest point defines.

## Failure / edge cases

- Reaching Exhausted (fatigue alone fills the bar) must block further strenuous actions entirely, per §10 — no further Overexertion is possible once Exhausted; only recovery clears it.

## Debug controls

Set fatigue directly; force Exhausted; force a full or partial recovery.

## Acceptance tests

- Repeated Overexertion accumulates fatigue and eventually reaches Exhausted, which then blocks further strenuous action.
- Sleep clears fatigue fully; field rest clears it partially and costs time.
- Fatigue never decreases from ordinary stamina regeneration alone.
