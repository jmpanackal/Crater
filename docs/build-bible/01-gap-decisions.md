# Build Bible 01 — Gap decisions

**Status:** ✅ ALL DECIDED (USER, 2026-09-15). Every gap below is locked — G5 explicitly, all others as the AI recommendation, reviewed and accepted in full. Promoted into [`../mechanics-canon.md`](../mechanics-canon.md) §68 as one consolidated USER-locked section. This doc remains the record of the options considered and the reasoning; §68 is the terse canonical form implementers should read first.

**G7 and G8 were resolved** by bio-fusion (§67) before this pass; everything else was decided in this pass.

These are questions the mechanics canon leaves unanswered that **block a contract** in [`00-dependency-map.md`](00-dependency-map.md). They are structural decisions, not tuning: exact numbers stay in the tuning registry.

Every recommendation below is marked **AI** and is only a starting point.

---

## Quick decision sheet

| ID | Question | Blocks | Tier | Locked |
| --- | --- | --- | --- | --- |
| G2 | What happens when stamina blocks exceed the bar? | Stamina | 1 | ✅ C |
| G21 | How does Overexertion trigger? | Stamina, Fatigue | 1 | ✅ A |
| G3 | When can the player sleep, and how are cycles skipped? | Clock, Districts | 1 | ✅ A |
| G11 | How long is a civic cycle, and does time pause? | Clock, topology | 1 | ✅ B |
| G10 | Save and reload policy | Save / Load | 1 | ✅ C |
| G14 | How much are off-screen NPCs simulated? | NPCs, Perception | 1 | ✅ A |
| G16 | One global Trust, or per-place Trust? | Trust | 1 | ✅ A |
| G12 | Combat in Act 1? | Scope, NPCs | 1 | ✅ A |
| G1 | What makes hauling cost something on flat ground? | Hauling | 2 | ✅ A + C |
| G13 | How many loads, and how are they bundled? | Hauling | 2 | ✅ A |
| G9 | What is the theft interaction? | Diversion | 2 | ✅ A |
| ~~G8~~ | ~~Where does stolen output go before the workspace exists?~~ | — | — | **Resolved by §67** |
| ~~G7~~ | ~~How do Forbidden modifications use the Rig?~~ | — | — | **Resolved by §67** |
| G6 | Where do Core Improvements come from? | Rig | 2 | ✅ B |
| G4 | What makes theft costly when District Reserves refill? | Districts, Investigation | 2 | ✅ A + C |
| G5 | What can the player do during a shortage this cycle? | Districts, Jobs | 2 | ✅ B + C |
| G22 | What happens on an accidental fall or void drop? | Failure | 2 | ✅ A + B |

**Tier 1** blocks foundation contracts (decide first). **Tier 2** blocks vertical-slice systems. **Tier 3** (end of doc) can wait until after the slice.

---

## Tier 1 — foundations

### G2 · Stamina block overflow — ✅ LOCKED: C

**Question:** Hauling, Rig Strain, and fatigue all block part of the fixed stamina bar (canon §10). What happens when their total would exceed it?

**Canon constraints:** fixed visual bar; Rig Capacity is a soft limit; Overexerting converts future capacity into fatigue; exhaustion blocks strenuous actions.

- **A — Hard block:** you can't pick up a load or equip Gear if the total would exceed the bar. Simple, but contradicts the soft-limit spirit.
- **B — Instant exhaustion:** overflow immediately puts the player in Exhausted. Readable, but harsh and easy to trigger by accident.
- **C — Overflow is Overexertion:** blocks apply in a fixed order (fatigue → Rig Strain → hauling). An action that would exceed the bar is allowed only as Overexertion with a warning; the overflow converts into fatigue. If fatigue alone fills the bar, the player is Exhausted.

**✅ Decision: C.** It reuses the Overexertion system instead of inventing a new rule and keeps the invariant *blocked ≤ maximum*.

### G21 · Overexertion trigger — ✅ LOCKED: A

**Question:** At zero usable stamina, how does the player Overexert?

- **A — Continue the action:** holding a strenuous action at zero usable stamina Overexerts automatically, with strong audio/visual warning; the first Overexertion each session shows an explicit prompt.
- **B — Explicit modifier:** a dedicated Overexert input must be held.
- **C — Confirmation every time:** a prompt before each Overexertion.

**✅ Decision: A.** Keeps flow; the warnings satisfy the canon's telegraphing rule (§54).

### G3 · Sleep and cycle skipping — ✅ LOCKED: A

**Question:** When can the player sleep, what does it advance, and what stops sleep-spam from farming District Output (canon §25, §58)?

- **A — Sleep closes the cycle:** sleep is available only from Gathering onward (or after Ritual) and advances to the next Rousing, triggering exactly one district resolution. Earlier in the cycle, only field or home *rest* is available: partial fatigue recovery at a time cost, never crossing a cycle boundary. Skipping cycles means playing through to Gathering each time.
- **B — Sleep anytime:** sleep jumps to the next Rousing from any phase; sleeping through Working counts as absence from commitments and Ritual.
- **C — Sleep anytime, capped:** like B, but at most one sleep per cycle and no district resolution if the player slept more than once without activity.

**✅ Decision: A.** The simplest rule that makes spam structurally impossible and gives Gathering/Ritual their "return home" meaning. Needs G11's real-time length to be tolerable.

### G11 · Civic cycle length and time flow — ✅ LOCKED: B

**Question:** How long is a cycle in real time, and does time pass during menus and dialogue? (Exact minutes are tunable; the structure is not.)

- **A — Short (~20 min):** brisk rhythm; risks the "constant rushing" the canon forbids (§12).
- **B — Medium (~30–40 min, Working about half):** room for a job, travel, and optional exploration, per canon.
- **C — Long (~60 min):** relaxed, but Ritual and district changes become rare events.

Also decide: **time pauses in menus, the workbench, and dialogue** (AI rec: yes), and set **travel-time budgets** as design targets (e.g. home → Bottom-West front under 3 minutes).

**✅ Decision: B**, with time paused in menus, the workbench, and dialogue.

### G10 · Save and reload policy — ✅ LOCKED: C

**Question:** When does the game save, and can the player reload to undo being caught? (The failure model in canon §54 assumes consequences stick.)

- **A — Beds only:** saves only when sleeping. Strong consequences, but losing progress to a crash or quit is painful.
- **B — Save anywhere:** manual saves plus autosave. Save-scumming undoes theft and lie consequences.
- **C — Single rolling slot:** one campaign slot that autosaves at beds, civic phase transitions, and on quit (quit-save resumes exactly where you left). No manual save list.

**✅ Decision: C.** Protects consequences without punishing crashes. A separate optional "backup" slot could be offered for accessibility later.

### G14 · NPC simulation scope — ✅ LOCKED: A

**Question:** Do NPCs exist when their chunk isn't loaded? Witnessing, schedules, Ritual crowds, and investigations all depend on the answer.

- **A — Abstract off-screen schedules:** each NPC has a schedule table (location per phase); off-screen they "are" at their scheduled location without physics; they are instantiated when the chunk loads. Perception runs only for loaded NPCs; off-screen presence can still be queried ("was anyone scheduled in Wickwork storage?").
- **B — Loaded only:** NPCs exist only in loaded chunks. Cheap, but theft in an unloaded area has no witnesses and Ritual crowds are fake.
- **C — Full simulation:** every NPC runs everywhere. Expensive and unnecessary.

**✅ Decision: A.**

### G16 · Trust granularity — ✅ LOCKED: A

**Question:** Is Trust one global value, or tracked per place or group? (The canon says Trust is society's broad perception and suspicion is local; planning notes have used examples like `trust.mid_heart`.)

- **A — One global Trust** + local suspicion per NPC, district, Wardens, location, or incident (matches canon §17, §19).
- **B — Global Trust + group modifiers** (e.g. Wardens, Pulse Binders, a district) that shift how that group reads the global value.
- **C — Per-district Trust.**

**✅ Decision: A** for Act 1; B can be added later without breaking the contract because Trust exposes a `get_trust(context)` query from the start.

### G12 · Combat in Act 1 — ✅ LOCKED: A

**Question:** The canon never mentions combat; decision #15 leaned toward tactical real-time combat.

- **A — No combat in Act 1.** Danger comes from hazards (collapse, flooding, falls, pressure), stamina, time, and social consequence.
- **B — Non-combat creatures** that react to the noise system (avoid, distract, hide), with no fighting.
- **C — Light combat.**

**✅ Decision: A**, with B kept as a later DIRECTION since the noise system supports it.

---

## Tier 2 — vertical-slice systems

### G1 · Hauling cost on flat routes — ✅ LOCKED: A + C

**Question:** Walking is free and stamina regenerates while walking, so a load blocking stamina costs nothing on level ground. What makes distance matter (canon §3, §7)?

- **A — Strenuous traversal while hauling:** climbing, ladders, steep ramps, and jumps become strenuous while hauling (they spend stamina and can't happen in the blocked portion); sprinting is unavailable.
- **B — Fatigue over distance:** hauling slowly adds fatigue per distance travelled.
- **C — Speed by load:** loaded movement is slower, scaled by load weight, so distance costs civic time.

**✅ Decision: A + C.** Time and vertical routes give distance weight without making flat walking feel punishing. Revisit B after playtesting if long hauls still feel free.

### G13 · Load bundling — ✅ LOCKED: A

**Question:** How are bulk Materials physically carried?

- **A — One bundle, one type:** the player tows one bundle holding up to N units of a single Material; more capacity comes from Hauling Gear.
- **B — Chain of bundles:** several tethered bundles in a train.
- **C — Sled with mixed contents.**

**✅ Decision: A** for the slice (most readable, least physics risk); B becomes a Hauling-dimension Gear capability later.

### G9 · Theft interaction — ✅ LOCKED: A

**Question:** What does stealing District Output actually look like? (Canon: not purely a menu button; sight, sound, access, schedules matter; no success percentages.)

- **A — Timed take at storage:** a hold-to-take interaction at a physical storage object (rack, culture shelf, supply crate). Each take removes one unit, takes time, and emits noise; it's cancellable. Small amounts are concealed on the player; amounts above a threshold become a physical haul load. Witness danger is shown diegetically (NPC facing, footsteps, light), not as a meter.
- **B — Choose amount, then timed action:** a small panel picks the amount, then one longer action runs.
- **C — Individual physical goods:** each good is a pickup object.

**✅ Decision: A.**

### ~~G8~~ · Stolen output before the workspace — RESOLVED

**Resolved by §67 (2026-09-14), no decision needed:** every home has a basic concealed workspace from the start (Lower home = crude tier); it exists specifically to hold diverted output and illicit Components/Records before sustained Forbidden progress is possible. Grafting itself — the thing that actually *consumes* Materials/Components/Records into a Forbidden item — additionally requires the Mid Reach residence tier or better. So: diversion can start from day one into the crude workspace; turning that into an actual graft can't happen until Mid Reach. This is Option B from the original draft, just already locked rather than picked.

### ~~G7~~ · Forbidden modifications on the Rig — RESOLVED

**Resolved by §67 (2026-09-14), no decision needed:** Forbidden Gear never uses Gear slots — all of it is bio-fusion, drawing only on Rig Capacity. The original three-way question (attach vs. own slot vs. both) is moot: there is no separate mechanical Forbidden Gear category left to have a slot in the first place. The existing prototype roster (Resonance Driver, Ghost Mapper, Snapline, etc.) all become grafts with the same mechanical roles, per §67's DIRECTION on reflavoring — none of them get a slot.

### G6 · Core Improvement sources — ✅ LOCKED: B

**Question:** Core Improvements raise baseline capability and Rig Capacity (canon §34–§36) but have no stated source.

- **A — Approved only:** ordered from Wickwork at milestones gated by Trust or story.
- **B — Mixed:** a small set of capability-web entries — some Approved (orders), some restored from ship Components or discovered at repair bays, some Forbidden.
- **C — Authored milestone rewards only** (story beats, residence moves).

**✅ Decision: B**, kept to a small number so they don't become an RPG stat track.

### G4 · Theft cost when District Reserves refill — ✅ LOCKED: A + C

**Question:** In a comfortable district, surplus refills District Reserves next cycle, so stolen units cost the Hollow nothing. What makes theft meaningful anyway (canon §25, §30)?

- **A — Loss facts always:** every diversion writes an unexplained-loss fact regardless of current District Reserves; local investigation pressure is derived from those facts and decays slowly across cycles.
- **B — Slow refill:** District Reserves refill only partially each cycle, so theft lingers economically.
- **C — Accounting discrepancy:** at cycle resolution the district compares expected vs. actual District Reserves; when the unexplained loss since the last check crosses a threshold (lower when the district is strained), a discrepancy fact is logged and storage checks increase.

**✅ Decision: A + C**, using deterministic rules rather than hidden random rolls, so outcomes are explainable.

### G5 · Player lever during a shortage — ✅ LOCKED: B + C

**Question:** District Output comes only from District Capacity, which changes only through lasting projects. What can the player do *this cycle* when a district is short (canon §8 rewards "helping during a shortage")?

- **A — Emergency delivery:** delivering relevant Materials grants a one-time District Output bonus at the next resolution.
- **B — Emergency jobs:** a shortage spawns Emergency / World Need jobs (repair a line, haul supplies, clear a blockage) that grant temporary District Capacity for a few cycles.
- **C — Return output:** the player can return diverted District Output or donate personal stores to District Reserves (openly, or anonymously as its own risky act).

**✅ Decision: B + C.** A shortage spawns real jobs that grant temporary District Capacity for a few cycles (B), and the player can also return diverted District Output or donate personal stores directly to District Reserves, openly or anonymously (C). B gives the player an active, job-shaped way to help right now; C gives thieves a concrete way to make amends by giving back rather than just stopping.

### G22 · Accidental falls and void drops — ✅ LOCKED: A + B

**Question:** The prototype respawns the player after a void fall. What's the canon-consistent rule?

- **A — Prevent:** authored barriers keep normal routes from dropping into Devil's Mouth or lethal falls.
- **B — Soft recovery:** if a severe fall happens anyway, the player wakes at the nearest safe point with added fatigue, lost time, and any haul left behind (recoverable).
- **C — Rescue event:** every severe fall becomes a rescue with exposure risk.

**✅ Decision: A + B**, reserving C for authored stranded situations (canon §54).

---

## Tier 3 — can wait until after the vertical slice

- **Progression Canon:** when the player reaches each dig front, residence, Gear, and story beat, with rough target hours. *(Needed before sizing Act 1 content — its own doc, not a single decision.)*
- How a Record is shared (delivered to a Pulse Binder? a district clerk? a notice board?).
- Concealment tier names and exact search rules per tier.
- Residence acquisition requirements.
- Ritual practice, the Pulse's original function, and final phase names.
- Whether Trust group modifiers (G16-B) are needed.
- Job presentation format (notes, assignments, work records).

## Spike-owned questions (answered by technical spikes, not by decision)

- Terrain persistence representation (per-tile deltas vs chunk snapshots).
- NPC navigation through changed terrain (dynamic repath vs authored corridors vs per-chunk regeneration).
- Tether physics approach and snag handling.
- Perception and noise query cost at target NPC counts.
- Save format and migration strategy.
