# Build Bible Spec 30 — Failure / Rescue

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §54 and the locked G22 (A+B) — **pending USER review.** Implemented as drafted; anything marked *choice* is the draft's call. Build-order #30 in [`../00-dependency-map.md`](../00-dependency-map.md). Thin slice.

**Depends on:** Spec 09 (Fatigue), Spec 13 (Hauling), Spec 04 (Clock), Spec 17 (Perception / facts).

---

## Purpose

Canon §54's graduated failure model as state: no permadeath, no expedition resets; overextension continues the world in a changed state — lost time, abandoned haul, added fatigue, and rescue that can expose what the player was doing.

## Already locked (canon §54, G22 — not new)

- Failure is graduated: Strained (fully capable of a safer choice) → Exhausted (no strenuous actions until proper recovery; can still walk, interact, seek help) → Stranded/critical (quiet retreat impossible; rescue or another serious outcome may be mandatory).
- **G22 (A+B)**: authored barriers prevent lethal drops (A); if a severe fall happens anyway, the player wakes at the nearest safe point with added fatigue, lost time, and any haul left behind, recoverable (B).
- Forced rescue is not a random punishment; who finds the player and what they encounter matters — it can expose forbidden location, suspicious Gear, stolen output, illegal excavation, evidence. Rescue from civic work is mostly embarrassing; from restricted excavation, disastrous.
- Severe failure/rescue may advance substantial civic time (missed Ritual, deadlines, commitments — lost time is itself the consequence).
- Stored and cached resources are safe; hauled bulk may need to be abandoned/cached/recovered; ordinary failure never deletes Components/Records. No durability system; no random injury tables.
- The Clock is the sole mover of time; Failure/Rescue *requests* an advance and never marks Ritual missed directly (dependency map).

## Draft choices (Fable, pending USER)

- **Severe fall = G22-B literally**: the player's existing void-fall soft respawn reports to `Rescue.report_severe_fall()`, which adds a fixed fatigue cost (through Fatigue, the fatigue slot's one writer), leaves the towed bundle as a cache at the last safe ground (a forced cache — the frontier-only rule for player-chosen caches doesn't apply to a load dropped in a fall), requests a tuned number of phases of lost time from the Clock, and logs a `severe_fall` fact.
- **Stranded is derived** (*choice*): Exhausted (Fatigue) while outside the Hollow (`Community.is_player_in_hollow()` legacy presence, until zones carry the Hollow's footprint). Staying stranded for a tuned grace period forces a rescue; a voluntary `request_rescue()` is available any time while Exhausted.
- **Rescue** (*choice*, from §54's list): logs a `rescued` fact carrying the zone and whether it is restricted; **from a restricted zone** it additionally logs `rescued_from_restricted_area` (a scored suspicion fact — Investigation treats it like found evidence for that location and the residence); **stolen units carried on the person are found** by rescuers (`Diversion.confiscate_carried`, `found_evidence` fact, one Trust event); the towed bundle is cached where the player fell; the player wakes at home with fatigue partially recovered and the Clock advanced to the next Rousing (Ritual and deadlines fall out of that naturally). Rescue from ordinary civic work (a sanctioned zone, nothing carried) costs only time, haul and fatigue — no Trust event.
- **Telegraphing**: `EventBus.strain_state_changed(state)` reports strained / exhausted / stranded transitions for the world/UI (breathing audio, warnings) — the data, not the presentation.

## State it owns

None persistent — the stranded grace timer is transient.

## API surface

- `Rescue.get_failure_state() -> strained|exhausted|stranded|none`, `is_stranded()`, `report_severe_fall(fall_pos, safe_pos)`, `request_rescue(forced) -> record`.

## Acceptance tests

- A severe fall adds fatigue, caches the haul at the last safe ground, advances the Clock by the tuned phases, logs one fact, and never deletes stored Components/Records.
- Rescue from a restricted zone while carrying stolen output logs the exposure facts, confiscates the contraband, and submits exactly one Trust event; rescue from a sanctioned zone with nothing carried submits none — both advance time to the next Rousing.
- Exhausted outside the Hollow reads stranded; the grace period expiring forces the rescue.
