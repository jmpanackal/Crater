# Krater — Agent Context (Act 1 focus)

Read this before making changes. For the full pitch and open decisions, see:

- [`docs/game-pitch.md`](docs/game-pitch.md) — full game vision (Acts 1–3)
- [`docs/game-decisions.md`](docs/game-decisions.md) — open/locked design choices

**We are only building Act 1 right now.** Acts 2–3 exist so systems we seed (Standing, siphon, dual dig, sanctioned/forbidden tech) stay compatible — do not implement surface/Reef/settlement/ship features unless asked.

**Solo project.** Repo: [jmpanackal/Crater](https://github.com/jmpanackal/Crater) · path `E:\Coding\Projects\Crater` · title **Krater** · Godot **4.7.2** GDScript · 2D side-view · eventual premium Steam.

---

## One-line pitch

A kid in an underground society built into a massive pit is forbidden from digging up. They break the taboo, reach a surface no one knew existed, and uncover that their people are crash-landed colonists — with the answer waiting at the bottom of the pit everyone stared into for generations.

Closest comps: **Dome Keeper** (loop/team size), **SteamWorld Dig** (dig-and-open), **Inscryption** (mystery pacing). Tone: curiosity/wonder over fear.

---

## Act 1 — what we're building toward

### Setting (the Hollow)

- Society lives in/around a massive shaft (**the Pit**) torn by an ancient crash; truth rotted into myth.
- Unbreakable rule the *other* way: **never dig upward** (ceiling myth = manufactured control). The Pit is *genuinely* dangerous without needing a myth — players should feel that asymmetry.
- Working name for the society/world-as-known: **the Hollow**. In dialogue, prefer **named subsections** (districts/chambers) over constantly saying "the Hollow" (see decisions #1–#2).
- Ceiling/taboo name still open (leaning Cap / Roof).
- Folk comedy lightly: belly-of-a-beast theories, nursery rhymes, one guy who says "it's just rock."

### Magicians (load-bearing lore → systems)

Rote use of salvaged machinery is called **magic**. Villain encourages that framing.

| Diegetic | Maps to |
| --- | --- |
| Sanctioned / "safe magic" (mundane tools) | **Efficiency** upgrades — boost Harvest/passive openly |
| Forbidden / "dangerous magic" (nav, logs, legible data) | **Knowledge** upgrades — tied to risk / Social Standing |

Act 1 players only feel "some magic is common, some is rare/suspicious."

### Act 1 gameplay pillars

1. **Harvest** — communal rhythm + clock; miss it (away digging) and you're noticed.
2. **Dual-direction dig** — one toolset: **up** (secret taboo) and **down** into Pit walls (public-ish but dangerous if you go too far).
3. **Fragments** stay ambiguous (myth/history, never clear "alien planet"):
   - **Salvage** → mechanical upgrades (efficiency vs forbidden split above)
   - **Records** → lore / knowledge upgrades (always forbidden-tier)
4. **Social Standing** — caught digging up, lying, or using unsanctioned tech costs standing; lies can dodge but exposed lies hurt worse; gates later recruitment.
5. **Siphon framing** — personal upgrades = diverting effort/materials from communal life; spending happens when back in the Hollow, not at the dig site.

### Act 1 design goal (critical)

**Act 1 should feel like it might be the whole game.** No visible surface tab, no locked branches hinting at "more world." Player braces for punishment when digging up — the breach is a surprise. The Pit stays an unexplained background mystery.

### Structure honesty (locked leanings)

- **Hybrid campaign** (decisions #13/#16): one persistent save; expedition/miss risk costs unbanked resources/time/Standing — **not** full permadeath.
- **Deep pillar:** tech tree / builds (#9). Mining must feel good but stay simpler; settlement/passive stay thin.
- **Camera:** 2D side-view (#14). **Art:** detailed pixel art (#10); underground earthy vs later Reef vivid (Act 2 — not now).
- **Pit descent:** partial/gated (#22 leaning B) — reuse dig-down; true bottom is Act 3.

---

## Core loop — do not simplify away

**Venture out → gather + fragments → return before missed → upgrade → go further.**

This is **not** a neutral dig-shop. Scaffolding in code may look like dig→resource→upgrade; the **meaning** is secrecy, siphoning from Harvest, and Standing risk.

### When in doubt

If a request erases theft / return / consequence / Act 1 "might be the whole game," **flag it** instead of building the generic version.

---

## Current build state (keep honest)

### Implemented

- Zones: **Hollow** (left) vs **Dig Site** (right) in `main.tscn`.
- Player: move/jump/dig (**R**), 8-dir idle `AnimatedSprite2D`, dig aim still 4-cardinal.
- **Salvage** wallet; dig grants Salvage; **siphon_for_upgrade** only in Hollow.
- **Harvest timer** (60s) + **Social Standing** (50/100); Dig Site miss → `on_harvest_missed()` (−5).
- **SaveLoad** (`user://krater_save.json`): Salvage, upgrades, Standing, harvest_timer.
- Hollow UI: Harvest countdown, Social Standing, siphon controls (**U**); Salvage always visible.

### Not built yet (Act 1 still)

- Harvest *economy* / passive generation rates (timer/miss only).
- Lie mechanic; exposed-lie worse penalty.
- Sanctioned vs forbidden as real upgrade categories.
- Records/fragments lore pipeline; Journal.
- Dig Radius / richer tech tree / tradeoff upgrades.
- Named Hollow districts; ceiling name locked in fiction.
- Full tilesets/art beyond player idle + colored blocks.

### Later acts (do not build now)

Surface/Reef, settlement recruitment, ship, alien contact, villain confrontation — see pitch Acts 2–3.

---

## Code map (seeds)

| File | Role |
| --- | --- |
| `resources.gd` | Salvage wallet |
| `upgrades.gd` | Data-driven upgrades; **`siphon_for_upgrade`** |
| `community.gd` | `harvest_timer`, `social_standing`, `on_harvest_missed()` |
| `save_load.gd` | Persist Act 1 progress |
| `hollow_zone.gd` | Opens siphon station in Hollow |
| `terrain.gd` | Diggable TileMapLayer |
| `player.gd` | Move / dig / 8-dir idle visual |
| `upgrade_hud.gd` | Hollow Harvest + Standing + siphon UI |
| `docs/game-pitch.md` | Full narrative/systems pitch |
| `docs/game-decisions.md` | Decision log |

### Controls

| Action | Input |
| --- | --- |
| Move | A/D or arrows |
| Aim dig (4-dir; diagonals for sprite only) | WASD / arrows |
| Dig | **R** |
| Jump | **Space** |
| Siphon (Hollow only) | Click or **U** |

---

## Scope guardrails (from pitch)

- Settlement later = headcount + passives, **not** RimWorld.
- Passive tiers share one formula — flag if a tier needs its own prestige system.
- One dig system, two directions — not two tool trees.
- Pick **tech tree** as the deep pillar; keep other Act 1 systems intentionally simple.
