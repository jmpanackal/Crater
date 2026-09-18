# Priority roadmap

Dependency-ordered production plan for Act 1. Each phase should be *closed*
(or explicitly descoped) before spending real effort on the next one — this
is what stops rework: art built against an undecided rule, or a chunk map
built against an economy that's about to change shape, gets thrown away.

**Companions:** [`act1-demo-plan.md`](act1-demo-plan.md) (detailed fix list +
USER answer log — this doc summarizes and sequences it, doesn't replace it),
[`game-decisions.md`](game-decisions.md) (#28/#29 locks), [`materials.md`](materials.md),
[`terminology-transition.md`](terminology-transition.md).

**Status snapshot (2026-09-14):** [`mechanics-canon.md`](mechanics-canon.md)
adopted as the mechanics source of truth. Phase 0–1 below were completed
against the **pre-canon** model; their Requisition, Shortage Risk, Harvest,
and named-goods implementations are now transitional (see the code
migration backlog in `terminology-transition.md`). Phase 1.5 is new.

---

## Phase 0 — Close the open core-loop decisions ✅ done (2026-09-13)

*Cost: decisions only, no code.*

Full detail and rationale in `act1-demo-plan.md`'s "USER answers" section
(#2, #3, #6, #7, #8). Summary:

- [x] **Efficiency UI (#2):** split into two panels — public **Requisition** (efficiency/safe) + **Steal** (forbidden only). Both currently share one `steal_for_upgrade()` panel; that's the Phase 1 fix.
- [x] **Dig Yield tier (#3):** not a locked question — treat current prototype content as disposable, docs are canon. Dig Yield lands in Requisition by default once the split above exists, no hard rule needed.
- [x] **Steward assignment (#6):** stub dialogue + marker now — it's the opening route's core teaching beat per `hollow-chunk-map.md`.
- [x] **Firmament upward dig (#7):** gate behind a stand-in "Ashram Heights access" flag (soft lean — revisit if implementation cost is nontrivial).
- [x] **Demo art bar (#8):** greybox is fine. Real art comes after the loop is proven (Phase 2/3 below), not before.

**General rule established alongside these:** nothing in the current
code/prototype is canon by default — the docs are the source of truth. Don't
treat an existing implementation choice as a constraint unless a doc locks
it.

**Still genuinely open (not one of the five, tracked separately):** Decision
4, the exact player-facing Cover sentence — linked to the Cover → Shortage
Risk rename below, lock both together.

---

## Phase 1 — Harden the core loop to match what's already locked ✅ done (2026-09-13)

*Cost: bounded implementation work. No design decisions needed — these were
gaps between locked intent and current code, not open questions.*

- [x] **Split the shop UI into Requisition (public) + Steal (forbidden)** per Phase 0 Decision #2. `upgrades.gd`'s shared gate/spend renamed `can_acquire`/`acquire_upgrade` (was `can_steal`/`steal_for_upgrade` — that name was itself wrong for a sanctioned purchase); `theft_result` now only fires for the forbidden path, fixing a real bug where every efficiency buy showed "Theft complete." Two real panels in `main.tscn` (`RequisitionPanel` + `TheftShopPanel`), two hotkeys (`Q` / `U`), District production browsing moved to Requisition only.
- [x] **Wire Tallies as the real efficiency-spend currency** — `acquire_upgrade`'s efficiency branch spends `wallet.TALLIES`, not `wallet.SALVAGE`.
- [x] **Rename Cover → Shortage Risk with an inverted polarity** — `districts.gd`'s `get_cover_health`/`get_cover_for_good` → `get_shortage_risk`/`get_shortage_risk_for_good` (1.0 - the old value), `cover_changed` → `shortage_risk_changed`, `get_theft_notice_chance` rewritten directly proportional to risk. HUD labels/tooltips and `main.tscn` node names (`CoverLabel`→`ShortageRiskLabel`, `ShopCover`→`ShopShortageRisk`) updated to match.
- [x] **One true end-to-end integration test** — new `tests/test_economy_loop.gd`: dig → turn in → Harvest → Requisition (Tallies) → Steal (divert) → save → mutate everything → load → confirm the whole loop survives together, not per-system.
- [x] Verified with `tools/run_tests.ps1` after each step — **26/26 passing** at the end (one pre-existing flaky test unrelated to this phase, confirmed by rerun: `test_feel_feedback.gd`'s Record-drop RNG isn't seeded/disabled, occasionally fails at whichever assertion runs first — not a regression, not touched by this phase, worth a follow-up fix later).

**Exit condition:** the four gaps above are closed; `tools/run_tests.ps1` still 25/25 (or however many exist by then).

---

## Phase 1.5 — Build Bible + canon migration

*Cost: design contract first, then scoped implementation. Opened 2026-09-14 when
the mechanics canon superseded the Phase 0–1 economy model.*

- [ ] Write the **Build Bible** (canon §66): implementation-level contracts for services/autoloads, stamina/fatigue/reservation, Materials/Components/Records, hauling/caching, district Capacity/Demand/Reserve, jobs/commitments, Trust/suspicion/evidence, Rig/Gear/Capacity/Strain, capability web, workspace/residences, destructible terrain persistence, save/load, and opening-route acceptance tests. Include an explicit **vertical-slice scope cut** (which systems ship thin, which defer).
- [ ] Migrate code off retired mechanics per `terminology-transition.md` (Harvest → civic cycle/Ritual, Requisition → Approved Gear Orders, Shortage Risk → district condition + local suspicion, named goods/reserve 1/cap 6 → Capacity/Demand/Reserve, Salvage → Materials).

**Sequencing note:** Phase 2's opening-route layout (canon §52) is unchanged by the canon, so layout work may continue in parallel; only rename labels (Holding → Ritual) as chunks are touched.

---

## Phase 2 — Lock the opening-route spatial layout

*Cost: design + a modest amount of generation. This is the map/chunk work
from earlier in this session — now correctly sequenced after the economy
shape is settled, so rooms aren't designed around rules that are about to
change.*

Already scoped in [`docs/superpowers/plans/2026-09-12-full-hollow-chunk-atlas.md`](superpowers/plans/2026-09-12-full-hollow-chunk-atlas.md)
Task 4 — don't re-plan it, execute it:

- [x] Approve a seam-locked `H-3-11` ↔ `H-4-11` master — done (see `hollow-chunk-atlas.md`'s opening-route status table; this was stale here).
- [x] Generate `H-2-11` West Dispatch with its seam contracts — approved.
- [x] Generate Bottom-West Approach + Threshold as one outward strip — approved.
- [x] Generate First Expansion Gallery, Collapsed Side Chamber — approved (Lower Lift Landing superseded by the locked stairs/switchback topology; see `hollow-chunk-atlas.md`'s "Locked transport topology").
- [x] **Build the opening route as real, walkable Godot geometry** — rebuilt 2026-09-18 after the first attempt got the macro shape wrong (see below). `content/zones/*.tres` + `main.tscn`'s `Hollow/Zones` author all 8 opening-route zones (Home Court → Lower Switchback → West Dispatch Yard → Bottom-West Approach → Lower Lift Landing → Bottom-West Threshold → First Expansion Gallery → Collapsed Side Chamber) with real seams, and `hollow_terrain.gd` (one `TileMapLayer`, collision + visuals on the same tile — see `docs/hollow-level-authoring.md`) builds matching geometry. Greybox, per Phase 0's #8 decision. Covered by `tests/test_opening_route.gd`.
- [x] **First pass corrected, not just patched:** the original build (`hollow_decks.gd`/`hollow_floor.gd`, since deleted) put Bottom-West Dig Front beside Home Court as a flat westward strip — checked against a to-scale blueprint with the user and found wrong twice (a quest-order sequence isn't a physical distance; Bottom-West sits *below* Home Court, mirroring Cistern below Glowbeds). Confirmed macro reference: https://claude.ai/artifact/Dq15YdDjhfe4B6e1hsvv7U.
- [ ] Stop there — do **not** scale to the full 288-cell atlas yet, and don't wire actual digging into First Expansion Gallery yet (`terrain.gd` only supports one hardcoded envelope today — a real follow-up, not done here).

**Exit condition:** the Home Court + Bottom-West Dig Front cluster is walkable in-engine — **done**. Wickwork, Glowbeds, Mid Heart, Cistern, and Ashram Heights are a later rebuild phase, same methodology (`docs/hollow-level-authoring.md`); their prior prototype geometry was deleted, not carried forward, since it had real canon mismatches (Glowbeds on the wrong wall, a non-canonical `LeftServiceLift`).

---

## Phase 3 — Real art pass onto the locked layout

*Cost: generation + review cycles. Blocked on Phase 2's layout being stable.*

- [ ] Build side-view tilesets (PixelLab `create_sidescroller_tileset`, or Retro Diffusion) matching `hollow_concept.png`'s palette, for the materials the opening route actually needs (rock, timber decking, civic metal).
- [ ] Compose each Phase 2 chunk as a Godot TileMap from those tiles — not another painted panorama.
- [ ] Keep ChatGPT panoramas as mood/structure reference only, per this session's earlier finding.

---

## Phase 4 — Narrative / dialogue pass

*Cost: mostly writing. Can run in parallel with Phase 2–3 — text isn't
blocked by layout or art, only by Phase 0/1's economy rules being settled
(dialogue about Steal/Trust/Tallies needs to match what the mechanic
actually does).*

- [ ] First Steward assignment dialogue (depends on Phase 0's #6 answer).
- [ ] Write theft/evidence and Trust-reason copy against the canon (human-readable reasons, no `+X Trust` popups, no percentages) once Phase 1.5 lands.
- [ ] Expand the three Journal record stubs if the demo needs more than the Firmament-note gate.

---

## Phase 5 — Feel / polish (ongoing)

Already seeded (`feel_fx.gd`, `feel_audio.gd`, camera work) — keep extending
opportunistically rather than as a blocking phase. Re-run the demo eval
checklist in `ai-workflow.md` before calling any pass "done."

---

## Phase 6 — Scale beyond the opening-route slice

Only after Phases 0–5 hold up in actual play. This is where the full
288-cell atlas, remaining districts, and Act 1's back half get built —
deliberately last, so the pattern proven in Phases 1–5 is what scales,
not a guess.

---

## How to use this doc

- Work top to bottom. Don't start a phase while the one above it has open
  checkboxes, unless you're explicitly descoping something (write that down
  here, don't just skip silently).
- When a phase closes, update its checkboxes and move on — this doc should
  stay a short, current map of "what's next," not a historical log (that's
  what `act1-demo-plan.md` and `game-decisions.md` are for).
