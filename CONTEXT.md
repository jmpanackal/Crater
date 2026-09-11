# Krater — Agent Context (Act 1 focus)

Read this before making changes. For the full pitch and open decisions, see:

- [`docs/game-pitch.md`](docs/game-pitch.md) — full game vision (Acts 1–3)
- [`docs/game-decisions.md`](docs/game-decisions.md) — open/locked design choices
- [`docs/story.md`](docs/story.md) — Act 1 fiction canon + story idea inbox (not design locks)
- [`docs/game-feel-best-practices.md`](docs/game-feel-best-practices.md) — living juice / feel notes (Act 1 tone)
- [`docs/art-direction.md`](docs/art-direction.md) — locked visual bible (camera, refs steal/don’t-steal, Hollow composition, palette)
- [`docs/art-pipeline.md`](docs/art-pipeline.md) — when/how to use PixelLab MCP for Act 1 pixel assets
- [`docs/godot-best-practices.md`](docs/godot-best-practices.md) — Godot 4 / pixel structure checklist for this repo
- [`docs/ai-workflow.md`](docs/ai-workflow.md) — solo AI / agent production habits (role split, player-camera eval, USER vs AI tags)
- [`docs/act1-demo-plan.md`](docs/act1-demo-plan.md) — Act 1 demo priority/fix lists + siphon questions (planning)
- [`docs/materials.md`](docs/materials.md) — Act 1 Materials types, District production, inventory sketch (#29)

**We are only building Act 1 right now.** Acts 2–3 exist so systems we seed (Standing, siphon, dual dig, sanctioned/forbidden tech) stay compatible — do not implement surface/Reef/settlement/ship features unless asked.

**Solo project.** Repo: [jmpanackal/Crater](https://github.com/jmpanackal/Crater) · path `E:\Coding\Projects\Crater` · title **Krater** · Godot **4.7.2** GDScript · 2D side-view · eventual premium Steam.

---

## One-line pitch

A kid in an underground society built into a massive pit is forbidden from digging up. They break the taboo, reach a surface no one knew existed, and uncover that their people are crash-landed colonists — with the answer waiting at the bottom of the pit everyone stared into for generations.

Closest comps: **Dome Keeper** (loop/team size), **SteamWorld Dig** (dig-and-open), **Inscryption** (mystery pacing). Tone: curiosity/wonder over fear.

---

## Act 1 — what we're building toward

### Setting (the Hollow)

- Society lives in/around a massive crash shaft called **the Devil’s Mouth** (usually the Mouth; also the Deep, Void, or Hell); truth rotted into myth.
- Unbreakable rule the *other* way: **never dig upward** into the sacred **Firmament** (ceiling myth = manufactured control). The Firmament is natural crash-sealed strata, believed to collapse as judgment on selfish or disobedient people; the Devil’s Mouth is *genuinely* dangerous without needing a myth. Players should feel that asymmetry.
- Working name for the society/world-as-known: **the Hollow**. In dialogue, prefer **named subsections** (districts/chambers) over constantly saying "the Hollow" (see decisions #1–#2). Several of those subsections are **production districts** with distinct passive outputs (#28).
- Firmament is formal speech; people also say Vault or roof. A small collective Council of Stewards makes major decisions; its members are not departmental bosses. **Albus Socul**, the First Steward, is its longest-serving chair and controls relic protocol, Firmament doctrine, and what evidence reaches the Council. He must not read as an obvious villain in Act 1.
- Folk comedy lightly: belly-of-a-beast theories, nursery rhymes, one guy who says "it's just rock."

### Magicians (load-bearing lore → systems)

Rote use of salvaged machinery is called **magic**. Villain encourages that framing.

| Diegetic | Maps to |
| --- | --- |
| Sanctioned / "safe magic" (mundane tools) | **Efficiency** upgrades — boost Hollow district passives openly |
| Forbidden / "dangerous magic" (nav, logs, legible data) | **Knowledge** upgrades — tied to risk / Social Standing |

Act 1 players only feel "some magic is common, some is rare/suspicious."

### Act 1 gameplay pillars

1. **Hollow production districts** — named areas that produce different communal resources; efficiency/"safe magic" upgrades speed those passives over time (society gets healthier, not just a timer UI).
2. **Harvest** — communal rhythm + clock on top of that economy; miss it (away digging) and you're noticed.
3. **Dual-direction dig** — one toolset: **up** (secret taboo, from a late authored Firmament fissure) and **down** into Devil’s Mouth walls (public-ish but dangerous if you go too far).
4. **Fragments** stay ambiguous (myth/history, never clear "alien planet"):
   - **Materials** (category; #29) — multi-type dig haul → district inputs, Tallies turn-in, rare Hullbit for forbidden craft. Names proposed in [`docs/materials.md`](docs/materials.md); code may still say Salvage until rename.
   - **District production** — Glowrations / Glowfiber, Wicklamps / Bindcord, and Presswater / Clearwater: communal output produced by districts; **Siphon diverts specific goods**
   - **Records** → lore / knowledge upgrades (always forbidden-tier; not Materials)
5. **Social Standing** — caught digging up, lying, or using unsanctioned tech costs standing; lies can dodge but exposed lies hurt worse; gates later recruitment.
6. **Public work + siphon framing** — assigned Materials returned to districts earn Tallies (personal work pay), durable Contribution (residence/access rank), and district inputs. Personal forbidden upgrades divert District production rather than spending Tallies normally. **Stronger communal output makes siphoning safer** — healthier production covers diversion; thin output makes people notice. Demo needs thin **inventory**.
7. **Living Hollow** — NPCs who work, live, play, and chat in those districts. Act 1's home base is a populated society, not an empty upgrade booth.
8. **Vertical advancement** — public contribution earns higher residence and access through the Hollow, culminating in Vaultward access directly beneath the Firmament. Higher status also brings duties and scrutiny.

### Act 1 design goal (critical)

**Act 1 should feel like it might be the whole game.** No visible surface tab, no locked branches hinting at "more world." Player braces for punishment when digging up — the breach is a surprise. The Devil’s Mouth stays an unexplained background mystery.

### Structure honesty (locked leanings)

- **Hybrid campaign** (decisions #13/#16): one persistent save; expedition/miss risk costs unbanked resources/time/Standing — **not** full permadeath.
- **Deep pillar:** tech tree / builds (#9). Mining must feel good but stay simpler. **Hollow production districts + living NPCs are Act 1 requirements** (decision #28) — keep them intentionally lighter than the tech tree, not absent. Surface settlement/ship passives are Act 2–3 only.
- **Camera:** 2D side-view (#14) — Sea of Stars oblique evaluated and rejected; no hybrid. **Art:** detailed pixel art (#10); see [`docs/art-direction.md`](docs/art-direction.md). Underground earthy vs later Reef vivid (Act 2 — not now).
- **Pit descent:** partial/gated (#22 leaning B) — reuse dig-down; true bottom is Act 3.

---

## Core loop — do not simplify away

**Venture out → gather → return before missed → improve the Hollow or your work rig → go further.**

This is **not** a neutral dig-shop. Scaffolding in code may look like dig→resource→upgrade; the **meaning** is secrecy, siphoning from a living communal economy, Standing risk, and covering that diversion by keeping district output healthy. The Act 1 inciting public work is the First Steward’s assignment to excavate a new district: a real pressure-storage/expansion annex, worked from both sides of the Hollow, whose location conceals a ship service spine tied to the Steward’s longevity. The exact hidden room/discovery beat remains unresolved.

### When in doubt

If a request erases theft / return / consequence / Act 1 "might be the whole game," **flag it** instead of building the generic version.

---

## Current build state (keep honest)

### Implemented (Act 1 vertical slice)

- Campaign shell: **title → New Dig / Continue → play**; Esc saves and returns to title. No Act 2 tease.
- Zones: **Hollow** as Mouth-centered vertical terraces, with the Heart of the Hollow suspended civic complex at the middle band: Upper Heart (Holding/Council), Mid Heart (market/allotments), and Lower Heart (freight/excavation dispatch). Hanging walkways and transfer spans connect its levels and both sides of the Hollow. Firmament↑ / Devil’s Mouth↓. The present scene is a spatial prototype, not yet the final social hierarchy.
- Player: move/jump/dig (**R**), climb ladders (**W/S**), 8-dir idle sprites; coyote/buffer; accel/friction; sprite squash/stretch; dig/land dust (Firmament quieter than Pit); soft land/dig shake (Firmament quieter than Pit); micro dig hitch (Firmament shorter than Pit); subdued +Salvage / Record floats (**pending rename → Materials**); procedural dig/land click stubs; camera look-ahead + deadzone; starts in the Hollow.
- Dig Site Firmament↑ / Pit↓ soft dressing (haze/gloom overlays) + Hollow fog drift / FarHaze / PitShaftVeil depth polish + Approach threshold (plank / chasm / “Work walls ahead”).
- **Production districts** (`Districts`): Farms / Wickwork / Cistern passive stocks + rates; efficiency upgrades raise rates; **siphon cover** from total output. District prop stubs use building-like silhouettes (still placeholders).
- Hollow ladders: woodier ColorRect shafts with climb hints.
- **Upgrade split**: Efficiency (Farm Tending, Wickcraft, Cistern Flow — open) vs Forbidden (Dig Yield open; Quiet Dig gated by Firmament note Record — cover-based notice risk). Siphon only in Hollow (**U** / buttons). Future work-rig progression must use meaningful choice junctions: digging, movement/recovery, secrecy, knowledge, and community utility.
- **Harvest** 60s + Standing miss; optional **lie** prompt when away (Y/N + dimmer stakes copy); exposed lies worsen later notices; Harvest clock soft-pulses when ≤10s; Standing toasts tint by gain/loss.
- **Upward dig risk** (Quiet Dig reduces); Mouth digs warn after depth streaks; same dig tools. A constrained lift rig is planned so deep Mouth exploration and upper-Firmament work have safe, interesting vertical recovery.
- **Records / Journal** stub (`Journal`, **J**): a few ambiguous fragments, findable while digging; count + “new” highlight on unlock.
- **Living NPCs** (Pell, Rook, Sila, Joss): wander, idle bob, face toward player, talk (**E** / Space advance, Y/N choices), rare Yes/No (Pell farm help → +1 Standing).
- **SaveLoad** v2: Salvage, upgrades, Standing, harvest, pending_lie, District production, journal.
- Art ref: `docs/refs/hollow_concept.png` (primary Hollow composition — pit + terraces).
- Campaign shell title: quieter ink/lantern atmosphere (INMOST-leaning), no Act 2 tease.

### Still placeholder / thin

- Hollow structure is blocked (pit/terraces/bridge/stairs); props use building-like ColorRect silhouettes — no painted bridge, waterwheel, or farm rows yet.
- NPC bodies still ColorRect stubs (hidden); lanterns are warm rect hints, not PointLights.
- District production is currently flavor-only (not yet a full spend sink beyond Cover). **Pending:** Materials inventory + District-production siphon drain (#29 / [`docs/materials.md`](docs/materials.md)); code still uses single Salvage wallet.
- Records are three stubs; Firmament note unlocks Quiet Dig (first knowledge gate). Journal is still a flat list (not Mystery/Codex views).
- Firmament/Devil’s Mouth dressing now has soft Firmament haze / Mouth gloom overlays (still not distinct painted tilesets); the Heart, upper-Vaultward, an authored hidden Firmament fissure, contribution-ranked residences, and the Steward's new district are not implemented yet.
- Audio is procedural dig/land click stubs only (no authored SFX packs yet); ceiling name is locked in fiction.

### Later acts (do not build now)

Surface/Reef, settlement recruitment, ship, alien contact, villain confrontation — see pitch Acts 2–3.

---

## Code map (seeds)

| File | Role |
| --- | --- |
| `title_screen.tscn` | Campaign shell (main scene) |
| `main.tscn` / `main.gd` | Play scene; NPC + notice wiring |
| `resources.gd` | Salvage wallet (**pending rename → Materials inventory**) |
| `upgrades.gd` | Efficiency + forbidden upgrades; `siphon_for_upgrade` |
| `districts.gd` | Passive rates, stocks, siphon cover |
| `community.gd` | Harvest, Standing, lie, upward/siphon notice |
| `journal.gd` | Records unlock + snapshot |
| `save_load.gd` | Persist Act 1 progress |
| `hollow_layout.gd` | Pit/terrace world metrics |
| `hollow_zone.gd` | Opens siphon station in Hollow |
| `hollow_npc.gd` | District NPC presence + talk |
| `hollow_floor.gd` | Terrace floor TileMap visuals |
| `terrain.gd` | Diggable TileMapLayer; Firmament/Pit frontiers |
| `feel_fx.gd` | Dig/land grit, soft shake, micro dig hitch, restrained +Salvage/Record floats (**→ Materials**) |
| `feel_audio.gd` | Procedural dig/land click stubs with pitch randomize |
| `camera_follow.gd` | Look-ahead, drag deadzone, shake on Camera2D |
| `dig_site_dressing.gd` | Firmament haze / Pit gloom overlays at dig columns |
| `dig_approach.gd` | Hollow→Dig Site threshold plank / chasm / placard |
| `player.gd` | Move / dig / feel (coyote, squash, dust) |
| `upgrade_hud.gd` | Hollow status + multi-siphon UI; harvest pulse; notice tones |
| `journal_hud.gd` / `dialogue_panel.gd` | Journal + talk UI |
| `title_screen.tscn` | Quiet campaign shell |
| `docs/refs/hollow_concept.png` | Hollow art direction ref |
| `docs/art-direction.md` | Visual bible (camera, palette, refs) |
| `docs/game-pitch.md` | Full narrative/systems pitch |
| `docs/game-decisions.md` | Decision log |
| `docs/story.md` | Living story canon + idea inbox |
| `docs/materials.md` | Act 1 Materials / District production / inventory (#29) |
| `docs/act1-demo-plan.md` | Demo priority + economy fix list |
| `docs/game-feel-best-practices.md` | Living game-feel / juice reference |
| `docs/godot-best-practices.md` | Godot 4 / pixel structure checklist |

### Controls

| Action | Input |
| --- | --- |
| Move / climb | A/D or arrows · **W/S** on ladders |
| Aim dig (4-dir; diagonals for sprite only) | WASD / arrows |
| Dig | **R** |
| Jump | **Space** |
| Siphon Dig Yield (Hollow) | Click or **U** |
| Talk (near NPC) | **E** |
| Journal | **J** |
| Title (saves) | **Esc** |

---

## Scope guardrails (from pitch)

- Hollow districts/NPCs stay simple (rates + presence + light talk), **not** RimWorld / full dialogue sim.
- Surface settlement later = headcount + passives, **not** RimWorld (same formula family as Hollow passives).
- Passive tiers share one formula — flag if a tier needs its own prestige system.
- One dig system, two directions — not two tool trees.
- Pick **tech tree** as the deep pillar; keep other Act 1 systems intentionally simple — but do not cut production districts, siphon cover, or living NPCs from Act 1.
