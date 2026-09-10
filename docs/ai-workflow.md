# AI / solo-agent workflow (Krater)

Durable lessons for Act 1 production with Cursor agents, Godot MCP, and PixelLab — not a tool tutorial.

**Companions:** [`art-pipeline.md`](art-pipeline.md) · [`art-direction.md`](art-direction.md) · [`game-decisions.md`](game-decisions.md) · [`godot-best-practices.md`](godot-best-practices.md) · [`../CONTEXT.md`](../CONTEXT.md)

**Source (steal process, not fishing content):** [Week 3 of making my fishing game entirely with AI](https://www.reddit.com/r/aigamedev/comments/1vrj2cl/week_3_of_making_my_fishing_game_entirely_with_ai/) (u/RUSuper, Aug 2026; also discussed on r/ClaudeAI). Self-reported Godot 4.7.x + multi-session MCP workflow.

---

## What maps to Krater

| Lesson | Krater practice |
| --- | --- |
| **You are the art director** | Human eye locks look. Agents propose; you approve. Without taste in the loop, assets won’t cohere. |
| **Approve before gen** | PixelLab `create_*` only after an agreed brief — see [`art-pipeline.md`](art-pipeline.md). Scarce trial gens. |
| **Split roles across sessions** | Don’t mix “invent a system,” “generate art,” and “wire `main.tscn`” in one unbounded pass. Art director / asset gen / Godot integrate stay separate jobs. |
| **Player camera is the referee** | Sign-off from the **play camera** (side-view, real HUD, real scale). Editor overhead, zoomed debug, or concept stills alone can lie (OP’s “pancake islands”). |
| **Rubric before a polish pass** | Write scored criteria *before* a graphics/art pass; blind A/B when possible; only ship if it clears the bar (OP used 8+/10). Churn ≠ upgrade. |
| **USER vs AI decision tags** | Log design choices with provenance so agents don’t quote their own suggestions as your intent. Prefer updating [`game-decisions.md`](game-decisions.md) / story inbox with clear USER locks. |
| **Editable sources over opaque blobs** | Prefer locked refs + PixelLab briefs + sprites you can re-gen/edit over one-shot meshes you can’t fix. Env-first, one reusable settler/tileset. |
| **Polish out “AI-ness” up close** | Hollow must *live*: doors that go somewhere, NPCs that stand on floors, districts that read as planned — not trailer-distance only. |
| **UI late** | Mechanics and readable copy first; fancy HUD chrome after the loop is real. |

---

## Role split (practical)

Three concerns — can be three chats or one chat with hard boundaries:

1. **Look (art director)** — Refs, palette, silhouette. Output: approved stills / briefs only. Never invents dig systems or Standing rules.
2. **Assets (PixelLab / sprites)** — Implements the approved brief. No scene wiring, no “while I’m here” feature creep.
3. **Integrate (Godot)** — Placement, collision, TileMap, import settings, tests. May *propose* design changes tagged **AI**; must not silently promote them to requirements.

A dispatcher / general session may hold the decision log and critic rubric. It quotes other work; it does **not** overwrite USER locks.

---

## Eval checklist (before calling art “done”)

- [ ] Seen in **side-view play framing** at normal dig/Hollow scale (not only a concept PNG)
- [ ] Matches [`art-direction.md`](art-direction.md) locks (camera, palette, tone)
- [ ] Nearest / no mipmaps / correct size (32 or 64) — [`godot-best-practices.md`](godot-best-practices.md)
- [ ] Diegetic sense pass: can a settler *use* this space? (paths, floors, readable props)
- [ ] If it was a “polish pass”: criteria written first; newer set actually scored better

---

## Decision provenance (short schema)

When an agent or you lock something that will be re-quoted later:

`YYYY-MM-DD | USER|AI | topic | decision | still in build?`

The **still in build?** column stops discarded AI suggestions from reincarnating as requirements three sessions later. OP’s failure mode: an upgrade nobody proposed sat in docs and got quoted back as the user’s idea.

---

## Skip / caveats (not Krater)

- Fishing boat / 3D Rodin / Blender mesh pipeline — Krater is **2D pixel** + PixelLab.
- Subscription spend claims — ignore as forecasting.
- “Looks like Dredge” risk — for us, keep comps as **structure** (Dome Keeper loop, SteamWorld dig), not visual clones; see art-direction steal/don’t-steal.

---

## How to extend

When a workflow habit sticks (shot list for Godot MCP screenshots, a standing critic rubric for Hollow passes, a decision-log file), add one short bullet here and link it. Keep this scannable.
