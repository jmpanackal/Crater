---
description: Explore not-yet-locked mechanics/design and present options (never changes canon)
argument-hint: <design question or topic>
---
Topic: $ARGUMENTS

Follow CLAUDE.md. This is exploration only.
1. Run the `canon-keeper` agent for the topic; read the relevant canon sections it points to.
2. Inspect the relevant existing implementation and note constraints (systems, data, scale, Act 1 scope).
3. Lay out 2–4 approaches with concrete tradeoffs (player experience, implementation cost, interaction with other systems, what it forecloses). Mark which parts are canon-LOCKED vs your suggestion. Give a recommendation with reasons.
4. Prototype only if it clearly helps, and keep it isolated (throwaway branch/file) and labeled.
5. Present the decision to the user as `CANON DECISION REQUIRED` options and wait.

Do NOT edit `mechanics-canon.md`, `game-decisions.md` or any canon doc, and do not make an option canonical. Tag anything you propose as AI. After the user decides, they (or you, on their instruction) record it as a USER decision; then `/build` implements it.
