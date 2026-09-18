# Build Bible Spec 27 — Residences + Workspace

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §47, §62, §67, §41 and the resolved G8 — **pending USER review.** Implemented as drafted; anything marked *choice* is the draft's call. Build-order #27 in [`../00-dependency-map.md`](../00-dependency-map.md). Thin slice: Lower home real from the start, Mid Reach and Ashram Heights acquirable by contract (their scenes/interiors are content).

**Depends on:** Spec 19 (Trust), Spec 23 (Wallet), Spec 26 (Concealed Storage), Spec 20 (search_requested).

---

## Purpose

The three-tier residential progression (Lower → the Mid Reach → Ashram Heights) and the private Forbidden workspace that evolves with it, including the qualitative concealment model and the safe-by-default search rules (§47, §62).

## Already locked (canon §47, §62, §67, G8 — not new)

- Every home has a concealed workspace from day one (Lower = crude), holding diverted output and illicit Components/Records; grafting needs Mid Reach or better (§67).
- Concealment is **state-based** with Basic / Improved / Advanced tiers: Basic is vulnerable to a deliberate search; Improved survives a normal deliberate search and falls to a targeted one backed by evidence; Advanced needs very specific knowledge/evidence.
- The workspace is **safe by default**: no random home-search rolls; discovery only through believable evidence, suspicion, access, investigation or story — and most exposures give understandable warning first.
- Discovery is a serious social/story consequence, **not game over**: Trust loss, confiscation of some illicit goods, confrontation, local restrictions. What is actually found determines severity.
- Residence advancement uses Trust, Tallies, status and story clearance (§41/§62). At Ashram Heights the Firmament is the ceiling.

## Draft choices (Fable, pending USER)

- **`Homes` is authoritative for residence tier and workspace concealment tier**; Rig's `get_residence_tier()` lookup (Spec 14) and CapabilityWeb's residence requirement (Spec 25) already read it.
- **Acquisition (`acquire(tier)`)** requires the next tier only, a Trust standing (tuning), a Tallies price (tuning, through `Wallet.spend`), and a story flag (`Story.has_flag`) — a tiny **`Story` autoload** owns flags (the state table's "Story flags" row) and is introduced here because both 27 and 31 gate on it. `grant_residence()` is the authored/story path that bypasses cost.
- **Concealment base follows the tier** (*choice*): Lower = Basic, Mid Reach = Improved, Ashram Heights = Improved, with one `improve_concealment()` step (Tallies) up to Advanced.
- **A residence search resolves in Homes** on `EventBus.search_requested(&"residence")` (Investigation delegates that context instead of resolving a world search): the search's tier (from the request fact, default Basic = a deliberate search) **finds the workspace when its rank ≥ the concealment rank** — the §62 wording, not Evidence's strictly-beats rule for sealed cuts (*choice*; documented difference). What is found: the concealed stockpile (Storage) and stolen units carried on the person (Diversion). Grafts are never found by a home search (Spec 20: examiner-only).
- **Consequences on a find** (*choice*, from §62's list): `found_evidence` facts naming what was found, confiscation (`Storage.clear_concealed`, `Diversion.confiscate_carried`), `District.explain_loss` for each confiscated unit, exactly one Trust event scaled by how much was found, `EventBus.workspace_discovered`. An empty workspace → `found_nothing`, no Trust event.
- **Fair warning**: Investigation emits `EventBus.investigation_warning(context, ratio)` and an `investigation_warning` fact the first time a context reaches a tuned fraction of its threshold — the "someone is asking questions" channel §62 requires before a search.

## State it owns

Residence tier; workspace concealment tier. (Story: flags.)

## API surface

- `Homes.get_residence_tier()`, `can_acquire(tier) -> {ok, reason}`, `acquire(tier) -> {success, reason}`, `grant_residence(tier, reason)`, `get_workspace_concealment()`, `improve_concealment() -> {success, reason}`, `resolve_home_search(search_tier) -> record`.
- `Story.set_flag(id, reason)`, `has_flag(id)`, `clear_flag(id)`.

## Acceptance tests

- Acquiring Mid Reach needs standing + Tallies + story flag, each refusal distinct and atomic; Rig then permits grafting.
- A Basic search of a Basic-concealed workspace holding stolen output finds it: facts, confiscation, one Trust event; an empty workspace is `found_nothing`; an Improved workspace survives a Basic search.
- Repeated district discrepancies warn before a home search is requested.
