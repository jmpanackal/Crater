# Krater — Project Context

Read this fully before making changes. Future prompts can say: *see CONTEXT.md for project background*.

**Solo project.** Repo folder / GitHub name is **Crater** ([jmpanackal/Crater](https://github.com/jmpanackal/Crater)); game title is **Krater**. Local path: `E:\Coding\Projects\Crater`. Engine: **Godot 4.7.2** (GDScript), 2D side-view, eventual premium Steam release.

---

## Game overview

Krater is a 2D pixel-art expedition/mining game (closest comp: **Dome Keeper**) with a tech tree, a growing settlement, idle-style passive generation, and a story campaign.

---

## Story premise

A kid in an underground society (**"the Hollow"**) built into the walls of a massive crater is forbidden from digging upward. They break the taboo, discover a surface no one knew existed, and slowly uncover that their people are crash-landed colonists on an alien moon — with the truth waiting at the bottom of the crater everyone else has stared into for generations.

**Tone:** curiosity and wonder over fear/horror. Two mysteries (what's above, what's below) converge into one by the end.

---

## Core mechanical loop — IMPORTANT, DO NOT SIMPLIFY THIS AWAY

This is **NOT** "dig → get resource → spend resource → instantly repeat." That shape exists only as **placeholder scaffolding** in the current build.

The **real** loop:

1. The player secretly digs at a **dig site**, separate from the Hollow itself — upward toward a forbidden ceiling, and into the crater.
2. The Hollow runs on a communal daily **"Harvest"** — public, shared resource gathering that sustains the whole society.
3. The player's personal upgrades are **not** bought neutrally. They represent secretly **siphoning** resources/effort away from the communal Harvest into the player's hidden operation. **Spending only happens back at the Hollow**, not at the dig site.
4. Getting caught digging, caught with diverted resources, or caught in a lie costs **"Social Standing"** — a persistent stat that will later gate how many people can be recruited to the surface settlement. A **lie** mechanic can dodge suspicion, but if the lie is later exposed, the penalty is **worse** than getting caught honestly.
5. Tech has two tiers:
   - **Sanctioned** — mundane, public, openly used (called "magic" by people who don't understand it); boosts communal efficiency.
   - **Forbidden** — anything that could reveal the truth; hoarded, secret, tied to personal risk/knowledge upgrades.
6. Digging is **one system pointed in two directions**:
   - **Up** — secret / forbidden (toward the ceiling).
   - **Down** — into the crater (public but genuinely dangerous). Same tools drive both.

Passive/idle generation (society working when the player isn't actively digging) is intended later and reskins across tiers: Hollow → surface settlement → ship.

### When in doubt

If a request seems to simplify away the **theft / return / consequence** framing above, **flag it back to the user** rather than silently building the generic dig-shop loop. The mechanical shape (dig → resource → upgrade) is intentional scaffolding; the **meaning** (secrecy, risk, community vs. self) is core to the game, not decoration to bolt on later.

---

## Art direction

Detailed painterly pixel art (reference level: **Eastward**, **Owlboy**) — not minimalist 8-bit.

- **Underground:** mineral-tinted rock (teal-green / copper-rust streaks), warm lantern light mixed with bioluminescent fungus glow, carved-not-shack dwellings, crude reused salvaged tech.
- **Surface (not built yet):** dense alien **"Reef"** aesthetic — coral-like bioluminescent growth, drifting particles (denser atmosphere than Earth), awe/wonder tone.

---

## Design constraints

- Skill-based via **decisions**, not twitch-reflex.
- **No full permadeath** — failure costs resources / time / standing, never destroys overall save progress.
- Reuse existing systems/patterns rather than bespoke one-offs per feature.
- Comment code so a GDScript beginner can follow it.

---

## Current build state (keep this section honest as things change)

### Implemented now (in repo)

- **Two zones in `main.tscn`:** left **Hollow** (backdrop + floor + `HollowZone` Area2D) and right **Dig Site** (`TerrainLayer` tiles from x≥10). Walk between them on the shared floor line.
- **Player** (`player.gd`): move / jump / dig in 4 directions (**R**); in group `player` for Hollow detection; camera follow.
- **Resources** autoload: **`salvage`** / UI **"Salvage"** — carried haul from digging; useful only when siphoned at the Hollow.
- **Upgrades** autoload: data-driven Dig Yield; spending is **`siphon_for_upgrade`** and only while **`set_siphon_station_open(true)`** (Hollow). Cost `ceil(base * 1.5^level)`.
- **Community** autoload: **`harvest_timer`** (60s cycle), **`social_standing`** (default 50/100); Dig Site miss calls **`on_harvest_missed()`** (−5 Standing); Hollow attendance does not.
- **SaveLoad** autoload: JSON at `user://krater_save.json` — Salvage, upgrade levels, Standing, harvest_timer (seeded here; was not present before).
- **HollowZone** (`hollow_zone.gd`): opens/closes the siphon station when the player enters/exits.
- **UI:** Salvage + Standing always visible; Hollow panel shows Harvest countdown + Standing + siphon controls (**U**); button `focus_mode = None`.
- Dig payout: `destroy_cell` → `get_dig_salvage_yield()` → `Resources.add(SALVAGE, …)`.
- Headless tests under `tests/` including Hollow siphon gating and Harvest/Standing persistence.

### Explicitly not built yet

- Communal Harvest *economy* (timer/miss is the seed; no shared pool simulation yet).
- **Lie** mechanic / exposed-lie worse penalty.
- Recruitment gated by Standing.
- Sanctioned vs forbidden tech tiers as distinct systems.
- Second upgrade **Dig Radius**.
- Real pixel art, surface Reef, campaign scripting, settlement art beyond the Hollow placeholder.

---

## Seed systems (code map)

| Piece | Role |
| --- | --- |
| `resources.gd` | Autoload wallet (`SALVAGE`); `add` / `get_amount` / `resource_changed`. |
| `upgrades.gd` | Autoload defs/levels; **`siphon_for_upgrade`** / `can_siphon` / Hollow station gate. |
| `community.gd` | **`harvest_timer`**, **`social_standing`**, **`on_harvest_missed()`**, Harvest cycle. |
| `save_load.gd` | Persist Salvage / upgrades / Standing / harvest_timer. |
| `hollow_zone.gd` | Area2D that opens the siphon station while the player is home. |
| `terrain.gd` | Dig site grid; `destroy_cell` / `dig_in_direction`. |
| `player.gd` | Movement + dig request only (no spending). |
| `salvage_hud.gd` / `standing_hud.gd` | Always-on readouts. |
| `upgrade_hud.gd` | Hollow-only Harvest countdown + siphon UI. |
| `tests/` | Headless regressions. |

### Controls (current)

| Action | Input |
| --- | --- |
| Move | A/D or Left/Right |
| Aim dig (incl. up/down) | WASD / arrows |
| Dig | **R** |
| Jump | **Space** |
| Siphon Dig Yield (Hollow only) | Click button or **U** |

### Implementation notes worth keeping

- Autoloads via `get_tree().root.get_node("Resources"|"Upgrades")` from `class_name` scripts (no `class_name` on autoloads).
- TileSet physics polygons after atlas source is on a TileSet that already has a physics layer.
- Dig aim: held keys win; else last aim; vertical overrides horizontal if both held.
- Spending API is intentionally named **siphon** so Standing/Harvest risk attaches later without a rename.

---

## Naming note

Prefer **Krater** in player-facing copy. Repo folder remains **Crater**. Resource id is **`salvage`**.
