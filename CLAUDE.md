# Crater / Krater — operating rules for Claude

Solo Godot 4.7.2 GDScript 2D side-view game. Act 1 only. Read this file, then
[`docs/DEV-STATE.md`](docs/DEV-STATE.md). Load other docs only when the task needs them.
[`CONTEXT.md`](CONTEXT.md) is the long reference (pitch, pillars, spec history) — search it, don't read it whole.

## Source of truth (hard rules)
- [`docs/mechanics-canon.md`](docs/mechanics-canon.md) is the mechanics authority (~3800 lines — **never read it whole**; use the `canon-keeper` agent or grep by section). Keep its LOCKED / DIRECTION / OPEN / CUT labels. Never invent values for OPEN items.
- Hollow layout authority: [`docs/hollow-map-spec.md`](docs/hollow-map-spec.md) + `hollow_map.gd`. Edit map data only, never hand-place geometry; run the lint (`tests/test_hollow_map_lint.gd`).
- Existing code is **not** canon by default. Retired terms and the code migration backlog: [`docs/terminology-transition.md`](docs/terminology-transition.md). Do not extend retired prototype behavior (Requisition, Shortage Risk, Harvest, Siphon, Witness Risk…).
- Art rules: [`docs/art-direction.md`](docs/art-direction.md), [`docs/art-pipeline.md`](docs/art-pipeline.md), [`docs/ai-workflow.md`](docs/ai-workflow.md). Concept art is not production art. Generate art only from an approved brief.
- Acts 2–3 are out of scope unless asked.

## Canon safety
Implementation convenience never justifies a design change. If a real canon/design decision is needed, STOP and report:

```
CANON DECISION REQUIRED
Current canon: ...
Conflict: ...
Options: A / B / C
Tradeoffs: ...
```
Then wait. After the user decides, update the relevant canon doc (and tag the decision USER), then build. Anything you propose yourself is tagged AI, never quoted as user intent.

## Scale facts (verified in repo)
- Tiles and dig grid: **16 px**, unified across the visible world. Character ≈ **32 px** tall (2 tiles). Walking ~200 px/s, ladders ~140 px/s.
- Hollow levels are **384 px** apart (room height 256); the map has 18 levels per wall (L4-L15 built; L0-L3 and L16-L17 unbuilt rock). The older 1024×576 chunk grid in `hollow-chunk-atlas.md` is design history, not coordinates.
- Values not re-verified (anchor blocks, regional hubs): do not assume; check canon first.

## Working method
1. Before touching a system: find the canon (canon-keeper), read the existing implementation, grep callers/autoloads/signals/tests.
2. Decide whether the code is current canon or retired prototype. Implement against canon.
3. Smallest complete solution. Prefer existing systems and data-driven content; no speculative abstractions, no duplicate systems, no unrequested compatibility shims.
4. Never declare done from reading code. Run validation:
   - `powershell -File tools/check.ps1` — quick: parse-check changed `.gd` files.
   - `powershell -File tools/check.ps1 -Filter hollow` — run matching tests.
   - `powershell -File tools/check.ps1 -Full` — whole suite (slow; run once at completion of a feature, not per edit).
5. Visual changes: use the render checks in `tools/check_*_render.gd` / `hollow_map_report.gd` and look at the image.
6. Report: files changed, behavior changed, tests run, failures/limits, remaining risks.

## Agents and models (use sparingly; the main session does ordinary coding itself)
- `canon-keeper` (Haiku): canon/terminology lookup → compact packet. Use before any gameplay-system work.
- `architect` (Opus): plan only, for multi-system architecture, big refactors, hard debugging strategy. Not for searches or routine code.
- `reviewer` (Sonnet): independent diff review before finishing non-trivial changes.
- Don't spawn agents for trivial work. Parallelize only independent research.

## Workflows
- `/build <task>` — implement something already designed. `/design <topic>` — explore options, change nothing canonical.

## Git
- Check `git status` first; never discard unrelated changes. Commit/push only when asked. Risky features: use a branch (`agent/<name>`), not worktrees by default.

## Context
State lives in the repo, not the chat. Update `docs/DEV-STATE.md` when work meaningfully changes it. The user may `/clear` between features.
