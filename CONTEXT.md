# Krater — Agent Context (Act 1 focus)

Read this before making changes. For the full pitch and open decisions, see:

- [`docs/mechanics-canon.md`](docs/mechanics-canon.md) — **mechanics source of truth.** Supersedes conflicting mechanics anywhere else (including this file). Preserve its LOCKED / DIRECTION / OPEN / CUT distinctions; never invent values for OPEN items.
- [`docs/game-pitch.md`](docs/game-pitch.md) — full game vision (Acts 1–3)
- [`docs/game-decisions.md`](docs/game-decisions.md) — open/locked design choices
- [`docs/story.md`](docs/story.md) — Act 1 fiction canon + story idea inbox (not design locks)
- [`docs/game-feel-best-practices.md`](docs/game-feel-best-practices.md) — living juice / feel notes (Act 1 tone)
- [`docs/art-direction.md`](docs/art-direction.md) — locked visual bible (camera, refs steal/don’t-steal, Hollow composition, palette)
- [`docs/hollow-build-brief.md`](docs/hollow-build-brief.md) — Cursor-ready first Hollow environment pass (layout, assets, acceptance checks)
- [`docs/art-pipeline.md`](docs/art-pipeline.md) — when/how to use PixelLab MCP for Act 1 pixel assets
- [`docs/godot-best-practices.md`](docs/godot-best-practices.md) — Godot 4 / pixel structure checklist for this repo
- [`docs/ai-workflow.md`](docs/ai-workflow.md) — solo AI / agent production habits (role split, player-camera eval, USER vs AI tags)
- [`docs/act1-demo-plan.md`](docs/act1-demo-plan.md) — Act 1 demo priority/fix lists (planning; partly historical)
- [`docs/materials.md`](docs/materials.md) — summary of the canon Materials / Components / Records model
- [`docs/terminology-transition.md`](docs/terminology-transition.md) — retired terms and the code migration backlog

**We are only building Act 1 right now.** Acts 2–3 exist so systems we seed (Trust, diversion, lateral + upward dig, Approved/Forbidden tech) stay compatible — do not implement surface/Reef/settlement/ship features unless asked.

**Solo project.** Repo: [jmpanackal/Crater](https://github.com/jmpanackal/Crater) · path `E:\Coding\Projects\Crater` · title **Krater** · Godot **4.7.2** GDScript · 2D side-view · eventual premium Steam.

---

## One-line pitch

A kid in an underground society built into the walls of the massive Devil’s Mouth is forbidden from digging up. They break the taboo, reach a surface no one knew existed, and uncover that their people are crash-landed colonists — with the answer waiting at the bottom of the Mouth everyone stared into for generations.

Closest comps: **Dome Keeper** (loop/team size), **SteamWorld Dig** (dig-and-open), **Inscryption** (mystery pacing). Tone: curiosity/wonder over fear.

---

## Act 1 — what we're building toward

### Setting (the Hollow)

- Society lives in/around a massive crash shaft called **the Devil’s Mouth** (usually the Mouth; also the Deep, Void, or Hell); truth rotted into myth.
- Unbreakable rule the *other* way: **never dig upward** into the sacred **Firmament** (ceiling myth = manufactured control). The Firmament is natural crash-sealed strata, believed to collapse as judgment on selfish or disobedient people; the Devil’s Mouth is *genuinely* dangerous without needing a myth. Players should feel that asymmetry.
- Working name for the society/world-as-known: **the Hollow**. In dialogue, prefer **named subsections** (districts/chambers) over constantly saying "the Hollow" (see decisions #1–#2). Several of those subsections are **production districts** with distinct passive outputs (#28).
- Firmament is formal speech; people also say Vault or roof. A small collective Council of Stewards makes major decisions; its members are not departmental bosses. **Albus Socul**, the First Steward, is its longest-serving chair and controls relic protocol, Firmament doctrine, and what evidence reaches the Council. He must not read as an obvious villain in Act 1.
- Folk comedy lightly: belly-of-a-beast theories, nursery rhymes, one guy who says "it's just rock."

### Divine Binding (load-bearing lore → systems)

Rote, devotional operation of inherited colony technology is the Hollow's own religion, called **Divine Binding**; its practitioners are **Pulse Binders** — custodians of real technical procedures, not a fourth district. The villain encourages the reverent framing.

| Diegetic | Maps to |
| --- | --- |
| Sanctioned, Council-approved Divine Binding | **Approved Gear** — ordered openly with Tallies + authorized District Output |
| The same Divine Binding, practiced without sanction | **Forbidden Gear** — privately built from diverted output + Material/Component/Record |

Every playstyle dimension contains both. Act 1 players only feel "some Binding is common and sanctioned, some is rare and suspicious."

### Act 1 gameplay pillars

Full detail and status labels: [`docs/mechanics-canon.md`](docs/mechanics-canon.md). Summary:

1. **Hollow production districts** — Glowbeds / Wickwork / Cistern each track Capacity, Civic Demand, District Reserves, District Reserve Cap, and Unmet Demand, resolved **once per civic cycle**. Stable without babysitting; shortages create contextual world problems. Development is influenced (Materials, Components, Records, work), not commanded.
2. **The Pulse, civic cycle, and Ritual** — the Pulse at Mid Heart drives Rousing → Working → Gathering → **Ritual** (names/timings OPEN). Time creates rhythm and social expectation, not constant rushing. Missing Ritual is contextual.
3. **Lateral public dig + upward secret dig** — one toolset in a hybrid authored + destructible, persistent world. Public work is **sideways** civic excavation; secret investigation trends **up**. The **Firmament is thick** — a sustained, multi-session project from the Ashram Heights residence, not a thin fissure. The Devil’s Mouth is a feared, mostly unworked central void.
4. **Discoveries** stay ambiguous (myth/history, never clear "alien planet"):
   - **Materials** — Sutral, Ravelstone, Brinecrystal, Verdigris, Hullbit. Finite deposits in resource pockets; most rock yields nothing; bulk Materials are hauled/tethered physically and can be cached.
   - **Components** — smaller ship-derived parts in light personal storage.
   - **Records** — knowledge that unlocks routes, district projects, Approved capabilities, or Forbidden Designs (not always forbidden).
5. **Stamina, fatigue, Push** — a fixed stamina bar with reserved portions (hauling, Rig Strain, fatigue). Push converts future capacity into fatigue; proper rest recovers it. No hunger/thirst/injury systems.
6. **Jobs, Tallies, Trust** — jobs are physical civic situations and the invisible tutorial; not helping ≠ promising and failing. Work earns **Tallies** → Order **Approved Gear**. **Trust** is qualitative, explainable standing that is not spendable. No Contribution meter.
7. **Diversion (theft) and detection** — steal real District Output from physical storage into concealed storage toward **Forbidden Gear**. Two independent consequences: civic harm and detection (sight, sound, persistent evidence). Suspicion is local; no global Suspicion meter; no lie button or success percentages.
8. **Rig** — one evolving Rig: Core Improvements + swappable Gear slots (~3 → 4 → 5) + soft **Rig Capacity** (exceeding it = **Rig Strain**). Builds span Excavation / Survey / Hauling-Endurance / Mobility / Secrecy. Technology is a discovered capability web (Known → Understood → Available).
9. **Living Hollow** — NPCs who work, rest, talk, use infrastructure, gather, and react to district state. Relationships stay lightweight.
10. **Vertical advancement** — Lower home → Mid Reach residence → Ashram Heights residence via Trust, Tallies, status, and story. Each home hosts an improving concealed Forbidden workspace, safe by default and exposed only through believable evidence with warning.

### Act 1 design goal (critical)

**Act 1 should feel like it might be the whole game.** No visible surface tab, no locked branches hinting at "more world." Player braces for punishment when digging up — the breach is a surprise. The Devil’s Mouth stays an unexplained background mystery.

### Structure honesty (locked leanings)

- **Persistent campaign, graduated failure** (canon §54): one persistent world; failure continues the world in a changed state (lost time, abandoned haul, rescue exposure, contextual Trust) — **no** permadeath or expedition resets.
- **Deep pillar:** builds / capability web (#9). **Hollow production districts + living NPCs are Act 1 requirements** — keep them lighter than the build system, not absent. Surface settlement/ship production are Act 2–3 only.
- **Camera:** 2D side-view (#14) — Sea of Stars oblique evaluated and rejected; no hybrid. **Art:** detailed pixel art (#10); see [`docs/art-direction.md`](docs/art-direction.md). Underground earthy vs later Reef vivid (Act 2 — not now).
- **Devil’s Mouth:** Act 1’s powerful, mostly unworked crater vista; public Materials work is lateral civic excavation. Any true descent stays later and gated (#22).

---

## Core loop — do not simplify away

**Live in the Hollow → take civic work or explore → travel, dig, extract, haul → decide how far to push → keep / cache / deliver / order / divert → return to a Hollow that responds → improve Rig, districts, knowledge, access → reach new places.** (canon §1)

This is **not** a neutral dig-shop. Scaffolding in code may look like dig→resource→upgrade; the **meaning** is civic participation, quiet transgression against a living communal economy, contextual Trust, and evidence-driven consequences. The Act 1 inciting public work is the First Steward’s assignment to excavate a new district: a real pressure-storage/expansion annex, worked from both sides of the Hollow, whose location conceals a ship service spine tied to the Steward’s longevity. The exact hidden room/discovery beat remains unresolved.

### When in doubt

If a request erases theft / return / consequence / Act 1 "might be the whole game," **flag it** instead of building the generic version.

---

## Current build state (keep honest)

> **Prototype ≠ canon.** The implemented slice below predates [`docs/mechanics-canon.md`](docs/mechanics-canon.md) and still uses retired mechanics (Harvest timer, Standing, Salvage wallet, Requisition panel, Shortage Risk/Cover, named district goods with reserve 1 / cap 6, siphon notice RNG, Dig Yield / Quiet Dig). Treat it as transitional; migration backlog lives in [`docs/terminology-transition.md`](docs/terminology-transition.md).

### Build Bible migration (started 2026-09-17)

The confirmed [`docs/build-bible/`](docs/build-bible/) specs (32 systems, build order in `00-dependency-map.md`) are now being implemented directly as GDScript, in build order, each system fully complete with passing tests before the next one starts — see each spec's own file for exactly what's confirmed vs. still OPEN.

- **Spec 01 (Core Infrastructure) — done.** `autoload/event_bus.gd`, `autoload/fact_log.gd`, `autoload/tuning_registry.gd`, registered in `project.godot`. Authoritative State and Content Definitions are conventions, not files — documented in [`docs/godot-best-practices.md`](docs/godot-best-practices.md)'s "Core infrastructure conventions" section. Tests: `tests/test_core_infrastructure.gd`.
- **Spec 02 (Save / Load + Versioning) — done.** `save_load.gd` rewritten around the uniform `save_state() -> Dictionary` / `load_state(Dictionary) -> void` / `reset_all()` contract now added to every domain autoload (thin wrappers around each domain's own existing snapshot methods — zero behavior change to any of them). Atomic write (temp file + rename), `schema_version` stored and strictly checked (a mismatch is rejected loudly, never silently migrated — the old prototype's unenforced `SAVE_VERSION` int and flat-keys format are intentionally not migrated; real migration is still the open spike question 00-dependency-map.md already flags). Tests: `tests/test_save_load.gd`.
- **Known pre-existing flaky test (not caused by Spec 01/02):** `tests/test_feel_feedback.gd`'s "dig salvage float" check doesn't seed/force off `journal.gd`'s random Record-discovery roll (`try_find_on_dig`), so it can occasionally fail if that roll happens to fire during the dig it expects to only produce a Materials float. Confirmed present before touching either spec; not fixed here since it's an unrelated Journal/RNG-determinism issue, not a save/load or core-infrastructure one.
- **Next up:** Spec 03 (Debug Tools).
- The legacy flat-root systems below (Resources/Districts/Upgrades/Community/etc.) are **not yet migrated to canon shape** — they keep working via the existing autoloads (now also implementing the Spec 02 save contract) until their own Build Bible spec's turn comes up in build order.

### Implemented (Act 1 vertical slice — transitional)

- Campaign shell: **title → New Dig / Continue → play**; Esc saves and returns to title. No Act 2 tease.
- Zones: **Hollow** as Mouth-centered vertical terraces with **lateral carved rooms** (`HOLLOW_LEFT=-512`): Glowbeds grow gallery + public terrace, Wickwork bay + street, Mid Heart bridge band, Cistern + service alcove hint. Upper/Lower Heart suggested by distant suspended decks/cables. Soft labels: **The Glowbeds**, **The Wickwork**, **Mid Heart**, **The Cistern**. Firmament↑ / Devil’s Mouth↓. Dig exit reads as braced civic excavation.
- Player: move/jump/dig (**R**), climb ladders (**W/S**), 8-dir idle sprites; coyote/buffer; accel/friction; sprite squash/stretch; dig/land dust (Firmament quieter than Devil’s Mouth); soft land/dig shake (Firmament quieter than Devil’s Mouth); micro dig hitch (Firmament shorter than Devil’s Mouth); subdued +Salvage / Record floats (**pending rename → Materials**); procedural dig/land click stubs; camera look-ahead + deadzone; starts on Glowbeds terrace.
- Dig Site Firmament / civic side-gallery soft dressing (haze/gloom overlays) + Hollow fog drift / FarHaze / deep-Mouth veil polish + Approach threshold (braced tunnel / “Work walls ahead”).
- **Production districts** (`Districts`): Farms / Wickwork / Cistern passive production + rates; efficiency upgrades raise rates; **Siphon Cover** will use the target good and its sibling output. District prop kits are ColorRect craft (planters, wick bench, cistern basin/freight) — still not painted PixelLab props.
- Hollow ladders: woodier ColorRect shafts with climb hints.
- **Upgrade split**: Efficiency (Farm Tending, Wickcraft, Cistern Flow — open) vs Forbidden (Dig Yield open; Quiet Dig gated by Firmament note Record — cover-based notice risk). Siphon only in Hollow (**U** / buttons). Future Rig progression follows docs/mechanics-canon.md (Gear slots, Rig Capacity / Strain, capability web).
- **Harvest** 60s + Standing miss; optional **lie** prompt when away (Y/N + dimmer stakes copy); exposed lies worsen later notices; Harvest clock soft-pulses when ≤10s; Standing toasts tint by gain/loss.
- **Upward dig risk** (Quiet Dig reduces); lateral civic excavation remains public work. A constrained personal tether rig is planned for unsafe side galleries and upper-Firmament work; fixed Cistern-powered freight lifts remain public infrastructure.
- **Records / Journal** stub (`Journal`, **J**): a few ambiguous fragments, findable while digging; count + “new” highlight on unlock.
- **Living NPCs** (Pell, Rook, Sila, Joss): wander, idle bob, face toward player, talk (**E** / Space advance, Y/N choices), rare Yes/No (Pell farm help → +1 Standing). Placed across Glowbeds / Wickwork / Mid Heart / Cistern.
- **SaveLoad** v2: Salvage, upgrades, Standing, harvest, pending_lie, District production, journal.
- Art ref: `docs/refs/hollow_concept.png` (primary Hollow composition — Devil’s Mouth + terraces).
- Campaign shell title: quieter ink/lantern atmosphere (INMOST-leaning), no Act 2 tease.

### Still placeholder / thin

- District / Heart / void craft is **ColorRect + existing ledge/bridge tiles** — not yet painted prop kits or a full settler sprite. See [`docs/hollow-build-brief.md`](docs/hollow-build-brief.md) implemented table.
- NPC bodies still ColorRect stubs; lanterns are warm posts + PointLight2D, not authored lamp art.
- District economy still uses the retired per-good reserve/cap model, not canon Capacity/Demand/District Reserves per civic cycle. No physical hauling, caching, stamina reservation, fatigue, Components, Rig Capacity, or capability web yet.
- Records are three stubs; Firmament note unlocks Quiet Dig (first knowledge gate). Journal is still a flat list (not Mystery/Codex views).
- Heart Upper/Lower are silhouette hints only; Trust/Tallies-gated residences, hidden workspace, thick-Firmament excavation, and the Steward's new district are not implemented yet.
- Audio is procedural dig/land click stubs only (no authored SFX packs yet); ceiling name is locked in fiction.

### Later acts (do not build now)

Surface/Reef, settlement recruitment, ship, alien contact, villain confrontation — see pitch Acts 2–3.

---

## Code map (seeds)

| File | Role |
| --- | --- |
| `autoload/event_bus.gd` | Cross-cutting signals only (Build Bible Spec 01); no state |
| `autoload/fact_log.gd` | Append-only Fact Log (Build Bible Spec 01) |
| `autoload/tuning_registry.gd` | Loads/hot-reloads `.tres` tuning domains (Build Bible Spec 01) |
| `title_screen.tscn` | Campaign shell (main scene) |
| `main.tscn` / `main.gd` | Play scene; NPC + notice wiring |
| `resources.gd` | Salvage wallet (**pending rename → Materials inventory**) |
| `upgrades.gd` | Efficiency + forbidden upgrades; `siphon_for_upgrade` |
| `districts.gd` | Passive production rates, civic reserve/demand (pending), local Siphon Cover |
| `community.gd` | Harvest, Standing, lie, upward/siphon notice |
| `journal.gd` | Records unlock + snapshot |
| `save_load.gd` | Persist Act 1 progress |
| `hollow_layout.gd` | Devil’s Mouth / terrace world metrics |
| `hollow_zone.gd` | Opens siphon station in Hollow |
| `hollow_npc.gd` | District NPC presence + talk |
| `hollow_floor.gd` | Terrace floor TileMap visuals |
| `terrain.gd` | Diggable TileMapLayer; Firmament/Devil’s Mouth frontiers |
| `feel_fx.gd` | Dig/land grit, soft shake, micro dig hitch, restrained +Salvage/Record floats (**→ Materials**) |
| `feel_audio.gd` | Procedural dig/land click stubs with pitch randomize |
| `camera_follow.gd` | Look-ahead, drag deadzone, shake on Camera2D |
| `dig_site_dressing.gd` | Firmament haze / Devil’s Mouth gloom overlays at dig columns |
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

- Hollow districts/NPCs stay simple (Capacity/Demand/District Reserves per cycle + presence + light talk), **not** RimWorld, city-builder control, per-NPC consumption, or a full dialogue sim.
- No idle/per-second production, AFK farming, or sleep-spam production loops (canon §25, §58).
- Surface settlement later **transforms** Act 1 systems (canon §49) — no separate prestige economy.
- One dig system, two directions — not two tool trees.
- Builds / capability web are the deep pillar; do not cut production districts, diversion, or living NPCs from Act 1.
- Use the canon's §60 design test before adding any mechanic; mark undecided details OPEN.
