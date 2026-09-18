# Build Bible Spec 31 — Access / Gates

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §17, §19, §41, §62 and the Vaultward/Ashram direction in the Hollow build brief — **pending USER review.** Implemented as drafted; anything marked *choice* is the draft's call. Build-order #31 in [`../00-dependency-map.md`](../00-dependency-map.md). Thin slice: the Vaultward gate.

**Depends on:** Spec 19 (Trust), Spec 27 (Story flags, residence), Spec 17 (Perception).

---

## Purpose

Higher bands and restricted routes read as "responsibility / keys / neighbours / scrutiny — not arbitrary videogame gates" (build brief). Access is what higher Trust, status and story clearance *buy* (§17: "more autonomy, better assignments, access"), and a gate is a believable physical threshold, explained in the world without exposing numbers (§17).

## Already locked (canon §17, §19, §41, §62 — not new)

- Higher Trust provides access; access requirements may be explained clearly without exposing exact numeric thresholds.
- Ashram Heights / the Vaultward route beneath the Firmament is not free at the start; advancement uses Trust, Tallies, status and story clearance.
- "Seen entering restricted tunnel" and "returned from forbidden direction" are canon's own witness-fact examples (§19).
- The witnessable decision belongs to the calling system (Spec 17): Access decides an entry was restricted; Perception decides whether anyone saw.

## Draft choices (Fable, pending USER)

- **A gate is a scene node** (`access_gate.gd`, a StaticBody2D) carrying its own requirements — Trust standing id, story flag, residence tier — and an explanation line; it registers with `Access`, which re-evaluates every gate on `trust_changed`, `story_flag_set`, `residence_changed` and toggles the gate's collision. No per-frame polling.
- **A closed gate is solid and explains itself** through a Spec 10 interactable prompt (*choice*: "The Wardens don't pass anyone below Relied-on standing", never "Trust 70/100").
- **Bypassing a closed gate** (digging around it, dropping in) is detected by the gate's "beyond" area: entering it while the gate is closed logs a `restricted_entry` fact and calls `Perception.flag_witnessable("restricted_entry:<gate>", …, "seen_entering_restricted_area")` — witnessed only if someone was there.
- **The Vaultward block becomes a real gate** requiring the Ashram Heights residence (*choice*, the build brief's "Gate + collision block. Not free at start").

## State it owns

None persistent — gate open/closed is derived from Trust/Story/Homes each re-evaluation.

## API surface

- `Access.can_pass(gate_id) -> {ok, reason, explanation}`, `is_open(gate_id)`, `get_gate_ids()`, `refresh()`.
- `AccessGate` exports: `gate_id`, `required_trust`, `required_flag`, `required_residence`, `explanation`, `beyond_offset`/`beyond_size`.

## Acceptance tests

- A gate with a standing/flag/residence requirement is solid until each is met, then opens on the very event that met it; its prompt explains the requirement without numbers.
- Entering the area beyond a closed gate logs a restricted entry and is witnessable; entering beyond an open gate logs nothing.
- `main.tscn`'s Vaultward gate is closed at start and opens with Ashram Heights.
