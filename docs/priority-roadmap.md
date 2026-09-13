# Priority roadmap

Dependency-ordered production plan for Act 1. Each phase should be *closed*
(or explicitly descoped) before spending real effort on the next one — this
is what stops rework: art built against an undecided rule, or a chunk map
built against an economy that's about to change shape, gets thrown away.

**Companions:** [`act1-demo-plan.md`](act1-demo-plan.md) (detailed fix list +
USER answer log — this doc summarizes and sequences it, doesn't replace it),
[`game-decisions.md`](game-decisions.md) (#28/#29 locks), [`materials.md`](materials.md),
[`terminology-transition.md`](terminology-transition.md).

**Status snapshot (2026-09-13):** 25/25 headless tests passing. Terminology
migration complete except the two items in Phase 1 below. See "Known
follow-ups" in `terminology-transition.md` for the full detail on each.

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

## Phase 2 — Lock the opening-route spatial layout

*Cost: design + a modest amount of generation. This is the map/chunk work
from earlier in this session — now correctly sequenced after the economy
shape is settled, so rooms aren't designed around rules that are about to
change.*

Already scoped in [`docs/superpowers/plans/2026-09-12-full-hollow-chunk-atlas.md`](superpowers/plans/2026-09-12-full-hollow-chunk-atlas.md)
Task 4 — don't re-plan it, execute it:

- [ ] Approve a seam-locked `H-3-11` ↔ `H-4-11` master (draft exists, unapproved).
- [ ] Generate `H-2-11` West Dispatch with its seam contracts.
- [ ] Generate Bottom-West Approach + Threshold as one outward strip.
- [ ] Generate First Expansion Gallery, Collapsed Side Chamber, Lower Lift Landing.
- [ ] Stop there — do **not** scale to the full 288-cell atlas yet. Prove the opening route (~8 chunks) end-to-end in Godot first.

**Exit condition:** the opening route (Home Court → Lower Lift Landing) is walkable in-engine with seam-correct art, not just approved reference images.

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
- [ ] Tighten Cover/Shortage Risk-adjacent notice copy once Phase 1's rename lands.
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
