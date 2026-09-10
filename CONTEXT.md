# Krater — Project Context

Read this fully before making changes. Future prompts can say: *see CONTEXT.md for project background*.

## Game overview

Krater is a 2D pixel-art expedition/mining roguelite-adjacent game (closest comp: Dome Keeper) with a tech tree, a growing settlement, idle-style passive generation, and a story campaign.

- **Engine:** Godot 4.7.2 (GDScript)
- **Perspective:** 2D side-view
- **Target:** eventual premium release on Steam

## Story premise (context only — not to build yet)

A kid in an underground society ("the Hollow") built into the walls of a massive crater is forbidden from digging upward. They break the taboo, discover a surface no one knew existed, and slowly uncover that their people are crash-landed colonists on an alien moon — with the truth waiting at the bottom of the crater everyone else has stared into for generations.

**Tone:** curiosity and wonder over fear/horror. Two mysteries (what's above, what's below) converge into one by the end.

## Core mechanical loop

Venture out → gather resources/fragments → return before caught → upgrade → go further.

Digging is **one system pointed in two directions:**

- **Up** — toward the ceiling (secret / forbidden)
- **Down** — into the crater (public but genuinely dangerous)

Same tools drive both.

Passive/idle generation runs underneath (society working even when not actively playing), reskinned across three tiers later (Hollow → surface settlement → ship) — not needed yet, just context.

## Art direction

Detailed painterly pixel art (reference level: Eastward, Owlboy) — not minimalist 8-bit.

- **Underground:** mineral-tinted rock (teal-green / copper-rust streaks), warm lantern light mixed with bioluminescent fungus glow, makeshift-but-substantial carved dwellings (not flimsy shacks), primitive salvaged tech reused crudely.
- **Surface:** dense alien "Reef" aesthetic — coral-like bioluminescent growth, drifting particles (denser atmosphere than Earth), awe/wonder tone.

## Current project state

- Godot project at `E:\Coding\Projects\Crater`, GitHub: [jmpanackal/Crater](https://github.com/jmpanackal/Crater)
- `main.tscn`: Player (`CharacterBody2D`) with move/jump, diggable `TileMapLayer` terrain, dig on **R** (aim with WASD/arrows), smooth `Camera2D` follow, Ore HUD + Dig Yield upgrade button (**U**)
- Autoload **`Resources`**: dictionary-backed resource wallet (Ore starts at 0)
- Autoload **`Upgrades`**: data-driven upgrade levels; Dig Yield increases Ore per dig; cost = ceil(base * 1.5^level)
- Repo folder / GitHub name is **Crater**; game title is **Krater**

## Design constraints

- Combat/interaction should be skill-based via decision-making, **not** twitch-reflex-based
- No full permadeath — failure/risk costs resources/time, never destroys overall save progress
- Keep systems reusable/generic; reuse existing nodes/patterns rather than inventing new ones per feature
- Comment code reasonably so a non-expert learning GDScript can follow it

## Seed systems (extend later)

- **Resources (`resources.gd` autoload):** tracks named resource amounts; emit `resource_changed` for UI/tech tree later
- **Upgrades (`upgrades.gd` autoload):** dictionary of upgrade defs + levels; `try_buy` / `get_next_cost` / effect getters — add tech by extending `_defs`
- **Terrain (`terrain.gd`):** owns the diggable grid; call `dig_in_direction` / `destroy_cell` here instead of erasing cells from random scripts
- **Player dig (`player.gd`):** resolves dig direction (up/down/left/right via aim keys or last aim), then asks Terrain to remove the tile — same path will eventually support tools, stamina, and up-vs-down fiction layers
- **Dig controls:** hold WASD/arrows to aim, press **R** to dig that adjacent tile; if no aim key is held, uses last aim direction
- **Upgrade controls:** click the Dig Yield button or press **U** to spend Ore
