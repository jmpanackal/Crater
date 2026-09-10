# Art pipeline — PixelLab MCP (Krater Act 1)

How agents should use [PixelLab Vibe Coding / MCP](https://www.pixellab.ai/docs/ways-to-use-pixellab) for Act 1 assets. Setup: see project `.cursor/mcp.json` (token via `PIXELLAB_API_TOKEN` env var — never commit secrets).

**Visual locks** (camera, palette, steal/don’t-steal, Hollow composition): [`art-direction.md`](art-direction.md). This doc is the *how* of generating and importing; that doc is the *what it should look like*. Agent role-split, player-camera sign-off, and approve-before-gen discipline: [`ai-workflow.md`](ai-workflow.md).

## When to use it

Use PixelLab for **deliberate game assets**, not decorative spam:

| Prefer | Avoid |
| --- | --- |
| Characters / NPC sheets (`create_character` + animate) | Random mood boards |
| Side-view terrain (`create_sidescroller_tileset`) | Top-down / isometric tiles (wrong camera) |
| Props / dig debris / UI icons (`create_1_direction_object`, `create_ui_asset`) | Dozens of unreviewed gens |
| Style-matched variants from a locked reference | “Make it prettier” without constraints |

Krater is **2D side-view**, detailed pixel art, underground earthy Act 1 (Reef vivid = Act 2 only). Tone refs: Eastward / Owlboy — readable silhouettes, controlled palette, no mushy upscale noise.

## Brief checklist (every gen)

1. **Size:** Prefer **32** or **64** px (dig cells are 64px). Say the canvas size explicitly.
2. **Palette:** Earthy Hollow — rock, dust, dim lantern; limited colors. No neon / cyber / glossy UI chrome.
3. **Perspective:** Side-view / sidescroller. Do not default to top-down Wang tilesets.
4. **Reference:** Point at existing style anchors when possible:
   - `docs/refs/hollow_concept.png`
   - `sprites/dig_tiles/` / dig site tile sheets
5. **Background:** Transparent where the game needs it (characters, props).
6. **One job:** One brief → one asset (or one coherent tileset). Review before another pass.

## Import path

1. Download when PixelLab job completes (`get_*` tools / download URL).
2. Save under `sprites/` (or a clear subfolder, e.g. `sprites/npcs/`, `sprites/dig_tiles/`).
3. Let Godot import; project default filter is **Nearest** (`project.godot`). Keep **mipmaps off** and lossless compress, consistent with existing dig tiles. See [`godot-best-practices.md`](godot-best-practices.md).
4. Wire via existing scene/scripts — don’t leave orphan files in the repo root.

## Agent usage pattern

1. Agree the asset need and brief (palette, size, side-view, reference paths). Show the exact ask; **wait for user approve before any `create_*`** — trial gens are scarce. You are the art director; do not ask the model whether the image is “good enough.”
2. Call PixelLab MCP tools (`create_*` → poll `get_*`). Jobs are async (~2–5 min).
3. Review in **play framing** (side-view, real scale) before committing — concept stills and editor zooms can lie. See [`ai-workflow.md`](ai-workflow.md).
4. Prefer **env first**, then **one** reusable settler / tileset over parallel spam (quota + consistency). See [`art-direction.md`](art-direction.md).

Official tools guide: https://api.pixellab.ai/mcp/docs · Token / interactive Cursor snippet: https://www.pixellab.ai/vibe-coding or https://api.pixellab.ai/mcp
