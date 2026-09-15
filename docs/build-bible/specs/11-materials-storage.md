# Build Bible Spec 11 — Materials / Components / Records + Storage

**Status:** ✅ CONFIRMED (USER, 2026-09-15) — all design choices reviewed in chat and accepted. Build-order #11 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01, Spec 02, Spec 10.

---

## Purpose

The three discovery types (canon §3–§8) as actual data: bulk Materials, lightweight Components, and knowledge Records, plus where they live once carried home.

## Already locked (canon §3–§8, materials.md — not new)

- Three types: Materials (bulk, physically hauled while in transit), Components (lightweight personal storage), Records (knowledge, never stacked as Materials).
- Materials become **abstract stored quantities** once placed in established storage.
- Locked Act 1 roster: Sutral, Ravelstone, Brinecrystal, Verdigris, Hullbit.
- Ownership is contextual (personal find vs. expected civic delivery vs. district property vs. reportable rarities) — a narrative/social framing, not previously specified as a data structure.

## Design choices (✅ Confirmed, USER, 2026-09-15)

- **Stored Materials are a simple integer count per type** (option A), not per-batch records with quality/origin metadata — directly matches "abstract stored quantities."
- **One unified personal storage pool**, reachable from any owned residence, not separate pools per home (option A). Considered and rejected splitting storage per-residence to make transportation upgrades matter more (that idea's real value goes to the hauling/delivery trips that already exist constantly, per Spec 13, rather than to storage itself — splitting storage would reopen exactly the "dozens of things to track across multiple homes" problem canon's abstraction was meant to avoid). The thing that *does* vary by residence tier is the concealed Forbidden workspace (a different system — Spec 27), not ordinary Material storage.
- **Components use the same unified-pool model** as Materials (option A, confirmed after discussion) — "lightweight personal storage" implies the same simplicity, not a separate scoping rule.
- **No per-unit ownership tag** (option A). Legitimacy (was this Material "supposed" to go to a district?) is resolved by whatever job/commitment expects it, checking current totals against its own requirement — not a flag carried by individual Material units. Keeps the abstraction real instead of secretly re-introducing per-item tracking.

## State it owns

Per-Material integer counts (storage), per-Component owned-instance list (Components may carry more identity than a bare count, e.g. which specific recovered part), Records as an unlocked-entries set (owned by the Journal/Capability Web systems, not duplicated here).

## Failure / edge cases

- A job expecting delivery of a Material resolves against current totals at the moment of delivery/check, not a reserved allocation — avoids needing to "lock" units against other uses.

## Acceptance tests

- Picking up a Material in the field, then storing it at home, converts a physical haul object into an abstract count with no data loss.
- Storage is identical whether accessed from the Lower home or a later residence.
- A job that expects "5 Ravelstone" resolves correctly regardless of which trips the Materials came from.
