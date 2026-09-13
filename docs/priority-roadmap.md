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

## Phase 0 — Close the open core-loop decisions

*Cost: decisions only, no code. Do this first — it's nearly free and
everything downstream depends on the answers.*

From `act1-demo-plan.md`'s "USER answers" section, still marked Open/⏳:

- [ ] Should efficiency ("safe magic") share the Steal shop UI at all, or get its own visible path? (#2)
- [ ] Is Dig Yield forbidden-tier, or ordinary public worker gear? (#3)
- [ ] Steward assignment for the demo: stub dialogue + marker now, or skip until the new-district dig space exists? (#6)
- [ ] Firmament upward dig: available now (prototype), or gated behind a stand-in "Ashram Heights access" flag so fiction matches feel? (#7)
- [ ] Art bar for the demo: greybox OK if the loop reads clearly, or does one PixelLab pass on districts/NPCs need to land first? (#8)

**Exit condition:** every row above has an answer, even a provisional one.

---

## Phase 1 — Harden the core loop to match what's already locked

*Cost: bounded implementation work. No design decisions needed — these are
gaps between locked intent and current code, not open questions.*

- [ ] **Wire Tallies as the real efficiency-spend currency**, replacing the transitional Salvage path (`upgrades.gd:4` marks this explicitly). Scope: `upgrades.gd`'s efficiency spend path, `upgrade_hud.gd`'s cost display, one save-migration note if wallet shape changes.
- [ ] **Rename Cover → Shortage Risk with an inverted polarity** (healthier production → *lower* Shortage Risk, per `materials.md`). Touches `districts.gd` (`cover_changed`, `get_cover_health()`, `get_cover_for_good()` and their formulas), `upgrade_hud.gd` (labels/tooltips/notice text), `main.tscn` (`ShopCover`/`CoverLabel` nodes), and their tests. Do this as its own reviewable batch — it's a values-and-meaning change, not a find/replace.
- [ ] **One true end-to-end integration test**: dig → return to Hollow → turn in Materials → district production updates → save → reload → state persists. Current tests are strong per-system but don't prove this full loop holds together as one path.
- [ ] Re-run the full suite (`tools/run_tests.ps1`) after each of the above — they're independent, land and verify one at a time.

**Exit condition:** the three gaps above are closed; `tools/run_tests.ps1` still 25/25 (or however many exist by then).

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
