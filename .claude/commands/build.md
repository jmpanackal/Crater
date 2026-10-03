---
description: Implement something whose design is already established (canon-aware, tested, reviewed)
argument-hint: <what to build or fix>
---
Task: $ARGUMENTS

Follow CLAUDE.md. Workflow:
1. Read `docs/DEV-STATE.md`. Check `git status` and preserve unrelated changes.
2. Run the `canon-keeper` agent for the task (skip for trivial/non-gameplay work). If the canon packet shows the design is OPEN or contradictory, stop with a `CANON DECISION REQUIRED` report.
3. Inspect existing implementation and grep callers, autoloads, signals, tests.
4. Size it. Trivial: just do it. Moderate: plan briefly and implement yourself. Architecture-heavy (multi-system, refactor, migration, hard bug): run the `architect` agent first and follow its plan.
5. Implement the smallest complete solution against current canon, not retired prototype behavior. Add/adjust tests for new behavior.
6. Validate: `powershell -File tools/check.ps1` (quick), then relevant `-Filter` tests; `-Full` once at the end for substantial changes. Look at renders for visual work. Never claim done without running them.
7. For non-trivial changes run the `reviewer` agent; fix real findings; re-test.
8. Update `docs/DEV-STATE.md` if state meaningfully changed.
9. Summarize: files changed, behavior changed, tests run, failures/limits, remaining risks.

Don't ask for approval on ordinary implementation details. Stop and ask only for genuine game-design/canon decisions. Don't commit unless asked.
