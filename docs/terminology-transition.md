# Terminology transition

**Source of truth:** [`mechanics-canon.md`](mechanics-canon.md). This table tracks retired words so docs, copy, and code converge on the canon vocabulary.

Current canonical terms:

| Use now | Retired term | Meaning |
| --- | --- | --- |
| **Trust** | Social Standing / Standing | Society's accumulated, qualitative perception of the player's reliability. Shown as 4–5 standing states with human-readable reasons, not a raw number. Not spendable. |
| **Ritual** | Holding; Harvest | The communal return anchor at the end of the Pulse-driven civic cycle. Missing it is contextual, not an automatic stat penalty. The Holding Raft is now the **Ritual Raft**. |
| **Civic cycle** (Rousing → Working → Gathering → Ritual) | Harvest clock / 60-second Harvest timer | The Pulse-driven daily rhythm. Phase names and timings are still OPEN. |
| **the Pulse** | — | Degraded surviving ship component at Mid Heart; civic timekeeper and relic. Original ship function OPEN. |
| **Diversion / theft** (verb: divert, steal) | Siphon / siphoning | Secretly removing district output from a district's Reserve into concealed personal storage toward Forbidden Gear. |
| **District condition** (e.g. Comfortable / Stable / Strained / Shortage / Critical — names tunable) | Cover; Shortage Risk | How vulnerable a district's Capacity/Demand/Reserve balance currently is. There is no theft-success percentage. |
| **Local suspicion / evidence** (sight, sound, persistent evidence) | Witness Risk (five-state meter); siphon notice chance | Detection records believable facts; suspicion belongs to an NPC, district, Wardens, location, or incident. No universal Suspicion meter. |
| **Approved Gear** (category) / **Order** (action) | Requisition; efficiency / “safe magic” upgrades | Society-sanctioned equipment ordered with Tallies + authorized district output (plus Trust/access where relevant). |
| **Forbidden Gear** / **Forbidden Designs** | forbidden work-rig modules; knowledge upgrades | Privately built from stolen/diverted output + at least one non-Tally requirement (Material, Component, Record). |
| **Rig** | work rig; Mouthworker rig / suit | The player's single evolving work/exploration platform. |
| **Gear slots** + **Rig Capacity** / **Rig Strain** | three fixed mounts (Toolhead / Harness / Utility pack); Rig Load | Separate progression systems. Capacity is a soft limit; exceeding it creates Rig Strain, which reserves stamina. |
| **Core Improvements** | — | Permanent baseline Rig improvements that do not use a Gear slot. |
| **Materials** | Salvage (as category) | Bulk physical resources: Sutral, Ravelstone, Brinecrystal, Verdigris, Hullbit. |
| **Sutral** | Sporemeal, Threadroot | Biological/fungal fibrous Material. |
| **Ravelstone** | Charstone, Deeprock, Lunore, Karn, Tetzal | Dense structural stone Material. |
| *(cut)* | Lampwick (as a mined Material) | Not a raw Material. |
| **Components** / **Records** | “fragments” as a single track | Components = manufactured/ship parts; Records = knowledge (can unlock Approved *or* Forbidden capability). |
| **District output** / **Production Capacity**, **Civic Demand**, **Reserve**, **Reserve Cap** | named District-production pairs (Glowrations + Glowfiber, Wicklamps + Bindcord, Presswater + Sealbrine); protected reserve of 1; cap of 6; 70/30 sibling weighting | District production resolves once per civic cycle. Output is abstracted into units; named goods are flavor, not canon currencies. |
| **Capability web** (Known → Understood → Available) | tech tree; junction choices | Technology is discovered, not shown as a full tree. |
| **Firmament** | Vault / roof (everyday speech — still valid in dialogue); **Cap** in old `cap_*` test names | Sacred ceiling; thick, exceptionally hard natural crash-sealed strata. |
| **Devil’s Mouth** | Pit (as a place name) | Central impact crater void. Code may still use `PIT_*` layout constants and decorative `Pit*` node names. |

**Still valid as in-world descriptive words** (not currencies or district-output goods): **Presswater** for the Cistern's pressurized service water that drives lifts, brakes, and docks; **Wicklamp** for the Hollow's lamp family; **Firstfall** for old ship relics.

**Do not reintroduce** a separate **Contribution** meter or currency.

The retired terms are retained only in this reference and legacy save migration notes. New player-facing copy, specs, APIs, tests, and implementation work must use the **Use now** column.

## Code still using retired terms (migration backlog)

Code is not canon by default. As of 2026-09-14 the prototype still encodes the retired model and needs a scoped migration pass driven by the Build Bible, not a blind find/replace:

- **Harvest** 60s timer and Standing miss (`community.gd`, HUD) → civic cycle + Ritual + contextual Trust.
- **Requisition** panel / `RequisitionPanel` (`upgrade_hud.gd`, `main.tscn`) → Approved Gear Orders.
- **Shortage Risk** (`districts.gd` `get_shortage_risk*`, `shortage_risk_changed`, HUD labels) and the theft notice chance → district condition states + local suspicion/evidence.
- **Named District-production goods, protected reserve 1, capacity 6, 70/30 weighting** (`districts.gd`, `Districts.divert_good`, tests `test_district_production.gd`, `test_districts_cover.gd`, `test_siphon_cover_risk.gd`, `test_economy_loop.gd`) → Capacity / Demand / Reserve / Reserve Cap resolved once per civic cycle.
- **Salvage** wallet and `+Salvage` floats (`resources.gd`, `feel_fx.gd`) → Materials (physical haul) / Components / Records.
- **Dig Yield / Quiet Dig** upgrades (`upgrades.gd`) → Gear under Rig Capacity; Quiet Dig's role maps to Secrecy Gear (e.g. Dampening Wrap / Quieting Coupler).
- **`hollow_ambiance.gd` split** (~1859 lines) and **`upgrade_hud.gd` split** (~700 lines) remain structural follow-ups; do them alongside the migration so new canon systems don't land in the god-objects.
