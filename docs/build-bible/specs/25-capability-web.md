# Build Bible Spec 25 — Capability Web

**Status:** ✅ CONFIRMED (USER, 2026-09-17) — all design choices reviewed in chat and accepted. Build-order #25 in [`../00-dependency-map.md`](../00-dependency-map.md). Proposed as a **thin** slice.

**Depends on:** Spec 11 (Materials/Components/Records), Spec 01.

---

## Purpose

The Known → Understood → Available discovered-capability model from canon §40, and the steerable-not-random build progression from §41 — the system that lets Materials, Records, and conversations gradually reveal what the player can build, rather than a conventional visible tech tree.

## Already locked (canon §40, §41, §42 — not new)

- No fully visible conventional tech tree — a **discovered capability web** instead, with three states: **Known** (a reason to know it exists), **Understood** (enough Record/knowledge/context to understand it), **Available** (also has the access/district capability/Material/Component/Tallies/other conditions to order or build it).
- The player should never see completely unknown technology without an in-world reason — no screen of forty greyed-out mystery upgrades; partial unknown leads appear only after meaningful evidence (a strange Component, a Record fragment, a Pulse Binder mention, an observed old system, a restricted mechanism).
- Build progression must be **steerable**, not random — meaningful leads (district projects, Pulse Binder knowledge, locations, Materials, Components, Records, clues) let the player intentionally pursue a direction.
- Technology belongs to overlapping functional families (Excavation, Survey, Hauling, Mobility, Light, Secrecy, Rig Core) — never forced into mutually exclusive tree branches when it naturally serves multiple roles.
- Home/workbench information surfaces (Gear / Approved Gear / Forbidden Designs / Discoveries) are DIRECTION-level UI guidance, not this spec's contract — the private Forbidden workspace itself is Spec 27's job.
- **Already locked at the state-ownership level**: "Known / Understood / Available per technology | Capability Web | Authoritative (Known/Understood) + Derived (Available) | Submit discovery events" — Known/Understood are stored flags; Available is computed live, never stored, matching the same "derived, never saved as truth" pattern already used for Suspicion, Trust's standing state, and District condition.

## Design choices (✅ Confirmed, USER, 2026-09-17)

- **Known/Understood are set only through explicit, submitted discovery events — Capability Web never decides on its own that something became Known or Understood** (option A). `submit_discovery(tech_id, level, source_context)` is called by whichever system caused the discovery (Materials/Components on pickup, Records on read, Dialogue on a Pulse Binder mention, Perception/Terrain on observing an old system). Same passive-recipient, reason-traceable contract shape already established for Trust and Wallet — and it's what guarantees §40's "never without an in-world reason" requirement structurally, rather than relying on every author to remember to justify it by convention.
- **Available is computed live on every query, never cached or flipped-and-stored** (option A). `is_available(tech_id)` re-checks current access/district capability/Material/Component/Tallies conditions each time it's asked. This is mostly a restatement of the already-locked ownership-table line, but it matters concretely: if the player later spends the Materials a tech needed, Available correctly reads false again on the next check instead of staying stuck true from an earlier pass — the exact class of stale-state bug a stored/cached flag would risk.
- **Functional families are tags on a technology's own Content Definition, not separate registries it lives inside** (option A). A single tech can carry multiple family tags at once, and leads/steering content simply reference those tags to bias what surfaces as a meaningful lead — directly matching §41's explicit "do not force technologies into mutually exclusive tree branches if they naturally serve multiple roles."

## State it owns

Per-technology Known/Understood flags (authoritative). Available is derived, not stored.

## API surface

- `submit_discovery(tech_id, level, source_context)` — called by whichever system caused the discovery.
- `get_state(tech_id) -> {known, understood, available}` — `available` computed live against current conditions.
- `get_families(tech_id) -> [tags]`.

## Failure / edge cases

- Submitting a discovery event for a level the tech has already reached is a harmless no-op — Known → Understood → Available is one-directional; nothing un-discovers.
- A tech that becomes momentarily Available and later isn't (its Material got spent elsewhere) simply reports `available: false` on the next query — no special-case handling needed given the live-computation choice above.

## Acceptance tests

- A tech with no discovery events reports Known/Understood both false, and Available false regardless of whether the player could otherwise afford it.
- Submitting a Known-level discovery event makes `get_state` report `known: true` without affecting Understood/Available.
- A tech at full Known+Understood but currently missing its required Material reports `available: false`; once the Material is acquired, the very next query reports `available: true` with no additional event needed.
- A single technology can carry multiple family tags, all returned by `get_families`.
