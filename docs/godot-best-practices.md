# Godot / pixel art best practices (Krater)

Living checklist for Act 1 structure, look, and feel. Not a feature backlog.

**Companions:** [`art-direction.md`](art-direction.md) · [`game-feel-best-practices.md`](game-feel-best-practices.md) · [`art-pipeline.md`](art-pipeline.md) · [`ai-workflow.md`](ai-workflow.md) · [`CONTEXT.md`](../CONTEXT.md)

**Sources distilled for this project:** [GDQuest pixel-art setup (Godot 4)](https://www.gdquest.com/library/pixel_art_setup_godot4/), [Godot image import docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html), Godot style / project-organization guidance, platformer feel primers (coyote ~80–140 ms, jump buffer ~80–150 ms).

---

## Pixel look (must-have)

| Practice | Krater note |
| --- | --- |
| **Nearest filter project-wide** | `project.godot`: `textures/canvas_textures/default_texture_filter=0` (Nearest). Terrain also forces nearest on the TileMapLayer. |
| **No mipmaps on 2D pixel assets** | Imports already `mipmaps/generate=false`; keep it that way. |
| **Lossless compress for tiles/sprites** | Imports use `compress/mode=0` (Lossless) — correct for pixel art. |
| **Consistent tile / dig grid** | Dig cells = **64 px**. SpriteFusion sources often 32 px → nearest upscale into `dig_site_tiles.png`. Don’t mix 32/64 world scales casually. |
| **Snap 2D transforms to pixel** | Enabled project-wide to reduce sub-pixel shimmer with smoothed cameras. |
| **Stretch mode** | Current: `canvas_items` + `aspect=expand` @ 1152×648 — good for Eastward/Owlboy-ish detail + smooth camera (Hyper Light Drifter style). `viewport` + integer scale is the sharper “retro framebuffer” option if you later want chunkier UI pixels. |
| **Readable silhouettes / palette** | Earthy Hollow, limited lantern warmth; Firmament quieter visually than Pit. See art-pipeline brief checklist. |
| **Parallax / depth** | Prefer soft DepthBg + Mist + future layers over busy particle fog. Keep Firmament/Pit readable. |

---

## Feel / play (align with game-feel doc)

1. **Fairness first:** coyote + jump buffer before freeze frames / heavy shake.
2. **Weight without mush:** accel/friction, but dig-aim (WASD + **R**) stays snappy on the 64 px grid.
3. **Firmament quieter than Pit** for dust, shake, and SFX.
4. **Social systems stay social:** Harvest / Standing / siphon notice → copy + UI, not arcade juice.
5. **Dome Keeper–ish loop pattern (borrow the structure, not the combat):** hub return → spend → venture out under a clock. Krater’s “wave” is Harvest + Standing, not dome defense.

---

## Project structure (sustainable for Act 1)

| Prefer | Avoid |
| --- | --- |
| Autoloads only for persistent Act 1 systems (wallet, upgrades, districts, community, journal, save) | Growing god-objects; every helper as an autoload |
| Feature clusters as the tree grows (`hollow/`, `dig/`, `ui/`, `autoload/`) | Forever-flat `res://` root once NPC/prop scenes multiply |
| Scenes own composition; scripts own one responsibility | Stuffing all Hollow art + UI + wiring into one mega-`main.tscn` |
| `TileMapLayer` + one dig API (`TerrainLayer`) | Parallel dig systems for Firmament vs Pit |
| Tests as SceneTree scripts under `tests/` for each pillar | Untested Standing / siphon / save regressions |

**Current shape:** flat root scripts + `main.tscn` play scene + `title_screen.tscn` shell is fine for a vertical slice. Split Hollow / Dig Site / UI into packed scenes when `main.tscn` or art iteration starts fighting itself.

---

## Agent / author checklist

- [ ] New sprites: side-view, 32 or 64, earthy palette, transparent where needed → `sprites/…` → nearest / no mipmaps
- [ ] Dig changes go through `terrain.gd` (one toolset, two frontiers)
- [ ] Siphon / upgrades only meaningful in Hollow; dig site stays the venture
- [ ] Juice: read game-feel doc; don’t celebrate getting caught
- [ ] Don’t tease Act 2 (surface / Reef) in UI or folders players can see
- [ ] Prefer editing placement nodes over leaving `visible = false` ColorRect graveyards
- [ ] Art / layout sign-off from the **play camera**, not only editor overview — see [`ai-workflow.md`](ai-workflow.md)
- [ ] Design locks: tag USER vs AI so hallucinated “requirements” don’t stick in decisions docs

---

## How to extend

When you lock a display choice (integer scale, base resolution, SubViewport), a folder convention, or a camera policy, add one row or checkbox here and link the relevant file. Keep this short.
