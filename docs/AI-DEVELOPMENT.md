# Using Claude Code on Crater

State lives in the repo: `CLAUDE.md` (rules, auto-loaded) + [`DEV-STATE.md`](DEV-STATE.md) (where we are). Canon is fetched on demand, never preloaded.

## Commands
- `/build <task>` — implement something already designed. Example: `/build finish the Foreman job-return state in the opening route`.
- `/design <topic>` — explore unlocked mechanics, get options, change nothing canonical. Example: `/design how Firmament mining progression fits Ashram Heights housing`. You decide; then record it as a USER decision and `/build` it.
- `powershell -File tools/check.ps1` (parse changed files) · `-Filter hollow` (matching tests) · `-Full` (everything, slow).

## Who does what
- Main session: all ordinary coding (use Sonnet; `/model` to switch).
- `canon-keeper` (Haiku): fetches only relevant canon. `reviewer` (Sonnet): reviews the diff. `architect` (Opus): plans hard multi-system work only.
- Switch the main session to Opus (`/model`) only for design-heavy `/design` sessions.

## Canon protection
Claude stops with `CANON DECISION REQUIRED` rather than changing design. Answer with a letter/decision; then it updates the doc and builds.

## Art
Use the existing PixelLab/SpriteLab/Gamelab MCP tools, only from an approved brief ([`art-pipeline.md`](art-pipeline.md)). Look at renders (`tools/check_*_render.gd`, `hollow_map_report.gd`) before calling visual work done.

## Git
Claude doesn't commit unless asked. For risky features ask for a branch `agent/<name>`.

## `/clear`
Safe after any finished feature. Next session: `/build continue <thing>` — Claude re-reads `CLAUDE.md` + `DEV-STATE.md`.
