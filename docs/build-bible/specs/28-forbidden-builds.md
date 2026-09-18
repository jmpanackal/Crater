# Build Bible Spec 28 — Forbidden Builds

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §29, §47, §62, §67 and the resolved G7/G8 — **pending USER review.** Implemented as drafted; anything marked *choice* is the draft's call. Build-order #28 in [`../00-dependency-map.md`](../00-dependency-map.md). Thin slice: one design (the Quieting Coupler).

**Depends on:** Spec 25 (Capability Web), Spec 26 (Concealed Storage), Spec 27 (Workspace), Spec 14 (Rig grafts).

---

## Purpose

Turning a Known + Understood + Available Forbidden design into a graft at the private workspace — the secret-progression payoff canon §29/§67 describe: `explore → discover/understand → recover Material/Component → steal/divert District Output → privately build`.

## Already locked (canon §29, §47, §62, §67 — not new)

- Every Forbidden item is a graft (§67); it uses no Gear slot and draws on Rig Capacity; grafting needs the private workspace **and** the Mid Reach residence or better.
- Cost: **stolen/diverted District Output as the base**, plus a Material whose properties match the graft, a ship Component tied to bio-interface equipment, and a Record teaching the procedure (§29, §67) — "not every design must require all simultaneously" for the Material/Component/Record layer; the diverted output is always required.
- Construction uses no real-time timers; small modifications are immediate, major fabrication may consume civic time (§47) — exact rules are tuning.
- Graft concealment reuses the qualitative Basic / Improved / Advanced tiers and tracks independently of the workspace (§67).
- Ordinary NPCs cannot recognise a graft; discovery is examiner-restricted (Council / First Steward), investigation-shaped, resolved against the graft's concealment tier (Spec 20).
- Removal/refit of a graft happens only at the workspace, for a real cost (§67) — Rig already gates `remove_graft` on the workspace.

## Draft choices (Fable, pending USER)

- **Requirements live on the technology's definition** (Spec 25): `requires_materials`, `requires_components`, `requires_residence`, and new `requires_diverted_output` (district → units drawn from the concealed stockpile). CapabilityWeb's `Available` therefore already answers "can this be built right now", including the stolen-output part.
- **`build(design_id)` is atomic**: refuses (distinct reasons) unless at a workspace with Mid Reach+ (Rig's gate), Available, and the diverted output is stashed; on success consumes everything and calls `Rig.graft()`; logs a `forbidden_build` fact (what was consumed — the evidence a search could later name).
- **Fabrication time is immediate for the slice** (*choice*; a `fabrication_cycles` tuning value exists for when major builds should consume civic time).
- **Graft concealment starts Basic** and can be improved one step at a time at the workspace for Tallies (*choice*, stand-in for §62's "concealment for suspicious Gear" house upgrades).
- **`examine(design_id, examiner_is_authority, examination_tier)`**: only an authority (Council / Steward / specialist) can recognise a graft; the examination finds it when its tier rank ≥ the graft's concealment rank → `graft_exposed` fact + one Trust event (*choice* magnitude in tuning). A non-authority examination never finds anything.

## State it owns

Per-graft concealment tier. (Ownership of the graft itself is Rig's.)

## API surface

- `ForbiddenBuilds.can_build(design_id) -> {ok, reason}`, `build(design_id) -> {success, reason, consumed}`.
- `get_graft_concealment(design_id)`, `improve_graft_concealment(design_id) -> {success, reason}`.
- `examine(design_id, examiner_is_authority, examination_tier) -> {found, outcome}`.

## Acceptance tests

- Building away from a Mid Reach workspace fails; without stashed diverted output fails; with everything, one build consumes exactly the recipe and installs the graft using no slot.
- An ordinary (non-authority) examination of an exposed graft finds nothing; an authority's Basic examination exposes a Basic-concealed graft with exactly one Trust event; an Improved-concealed graft survives it.
