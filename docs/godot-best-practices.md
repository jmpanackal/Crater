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
| **Readable silhouettes / palette** | Earthy Hollow, limited lantern warmth; Firmament quieter visually than Devil’s Mouth. See art-pipeline brief checklist. |
| **Parallax / depth** | Prefer soft DepthBg + Mist + future layers over busy particle fog. Keep Firmament/Devil’s Mouth readable. |

---

## Feel / play (align with game-feel doc)

1. **Fairness first:** coyote + jump buffer before freeze frames / heavy shake.
2. **Weight without mush:** accel/friction, but dig-aim (WASD + **R**) stays snappy on the 64 px grid.
3. **Firmament quieter than Devil’s Mouth** for dust, shake, and SFX.
4. **Social systems stay social:** Ritual / Trust / theft evidence → copy + UI, not arcade juice.
5. **Dome Keeper–ish extraction feel (borrow the physicality, not the run reset or combat):** venture out → extract and haul → return to a persistent Hollow. Krater’s pressure is stamina, fatigue, civic time, and social consequence, not dome defense.

---

## Project structure (sustainable for Act 1)

| Prefer | Avoid |
| --- | --- |
| Autoloads only for persistent Act 1 systems (wallet, upgrades, districts, community, journal, save) | Growing god-objects; every helper as an autoload |
| Feature clusters as the tree grows (`hollow/`, `dig/`, `ui/`, `autoload/`) | Forever-flat `res://` root once NPC/prop scenes multiply |
| Scenes own composition; scripts own one responsibility | Stuffing all Hollow art + UI + wiring into one mega-`main.tscn` |
| `TileMapLayer` + one dig API (`TerrainLayer`) | Parallel dig systems for Firmament work vs lateral civic side galleries |
| Tests as SceneTree scripts under `tests/` for each pillar | Untested Trust / diversion / district-cycle / save regressions |

**Current shape:** flat root scripts + `main.tscn` play scene + `title_screen.tscn` shell is fine for a vertical slice. Split Hollow / Dig Site / UI into packed scenes when `main.tscn` or art iteration starts fighting itself.

**New infrastructure lives under `autoload/`** (`event_bus.gd`, `fact_log.gd`, `tuning_registry.gd` — Build Bible Spec 01). This is the first feature cluster; legacy root-level autoloads (`resources.gd`, `districts.gd`, etc.) stay where they are unless a later pass specifically migrates them — don't fold that into an unrelated change.

---

## Core infrastructure conventions (Build Bible Spec 01)

Two of Spec 01's five pieces are conventions, not new files — easy to miss since there's nothing to `grep` for by filename. Both apply to every autoload from here on, existing or new.

**Authoritative State — one writer per value, no shadow copies.** Every piece of state has exactly one autoload allowed to mutate it (`Districts` owns district goods, `Resources` owns the wallet, and so on). Everyone else requests changes through that owner's public API — a method call, never a direct field write — and may freely *read* another domain's state through its getters. Nothing caches a second copy of a value that can be read from its owner; only derived/computed values get cached, never authoritative ones. This is already the shape `resources.gd` / `districts.gd` / `community.gd` follow — Spec 01 just makes it an explicit, binding rule for every system built from here on, not an emergent convention.

**Content Definitions — Resource files, not code arrays.** Once a system has real authored content (Gear, Materials, Jobs, Districts, …), that content is a Godot `Resource` (`.tres`) file per item, not a `match` statement or a hardcoded `Dictionary` in a script — a designer/agent adds content by adding a file, not editing code. Content resources are read-only at runtime; a domain's *state* about a piece of content (e.g. "this Gear is currently equipped") lives in that domain's own authoritative state as a reference to the definition, never mutated onto the definition itself. Not retrofitted onto the existing prototype's `_defs`/`_good_defs` dictionaries in `districts.gd` — those migrate when their owning system gets rebuilt against its Build Bible spec, not as a drive-by change.

---

## Agent / author checklist

- [ ] New sprites: side-view, 32 or 64, earthy palette, transparent where needed → `sprites/…` → nearest / no mipmaps
- [ ] Dig changes go through `terrain.gd` (one toolset, two frontiers)
- [ ] Major Rig refits, Approved Gear Orders, and Forbidden builds happen only at believable stations (home, workbench, Wickwork); no pause-menu rebuilds mid-cave
- [ ] Mechanics match [`mechanics-canon.md`](mechanics-canon.md); OPEN values are not silently invented
- [ ] Juice: read game-feel doc; don’t celebrate getting caught
- [ ] Don’t tease Act 2 (surface / Reef) in UI or folders players can see
- [ ] Prefer editing placement nodes over leaving `visible = false` ColorRect graveyards
- [ ] Art / layout sign-off from the **play camera**, not only editor overview — see [`ai-workflow.md`](ai-workflow.md)
- [ ] Design locks: tag USER vs AI so hallucinated “requirements” don’t stick in decisions docs

---

## How to extend

When you lock a display choice (integer scale, base resolution, SubViewport), a folder convention, or a camera policy, add one row or checkbox here and link the relevant file. Keep this short.
