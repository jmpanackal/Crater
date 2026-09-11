# Act 1 Materials + Inventory (proposal)

**Status:** Design lock for economy *shape* (USER). **Names below are proposed — confirm or edit before code rename / inventory implement.**

Companions: [`story.md`](story.md) · [`game-decisions.md`](game-decisions.md) (#28, #29) · [`act1-demo-plan.md`](act1-demo-plan.md) · [`../CONTEXT.md`](../CONTEXT.md)

---

## Locked shape (USER)

| Lock | Detail |
| --- | --- |
| **Category name** | **Materials** — not “Salvage” (too generic). |
| **Dig haul** | Multi-type Materials + rare **Records** (Records stay a separate track). |
| **District feed** | Some dig finds are **inputs** that feed Glowbeds / Wickwork / Cistern. |
| **Siphon** | Diverts **District production** (communal output), not a generic Materials wallet. |
| **Efficiency** | Open “safe magic” that raises a district’s production rate → healthier production → better siphon **Cover**. |
| **Inventory** | Required for the demo economy (thin UX OK). |

**Code today** still says Salvage / single wallet — see backlog rename below. Docs are ahead of code on purpose.

---

## Category vs tracks

| Track | Player-facing | Role |
| --- | --- | --- |
| **Materials** | Inventory category | Dig finds you carry and turn in / craft with |
| **District production** | Communal output | Glowrations / Glowfiber, Wicklamps / Bindcord, and Presswater / Clearwater; **what Siphon diverts** |
| **Records** | Journal / knowledge | Lore + forbidden knowledge gates — **not** Materials |
| **Tallies** | Personal work pay | Open requisition of sanctioned gear (later; may stay thin in demo) |
| **Contribution** | Residence / access rank | Not a spend currency |

---

## Diggable Materials (demo set — 5)

Grounded in Mouth rock, damp growth, teal–copper crash metal. Avoid generic “ore.”

| Material | What it is | Where it tends to come from | What you do with it |
| --- | --- | --- | --- |
| **Sporemeal** | Packed fungal nutrient from damp wall mats — smells like wet cellar bread | Mostly **Pit** (wetter seams); Firmament only in soft damp pockets | Glowbeds input: releases **Glowrations** + **Glowfiber** at the next Harvest |
| **Lampwick** | Fibrous strands + resin-soaked cordage from fungal mats and old tool bindings | **Both** Firmament and Pit; thicker near old work tunnels | Wickwork input: releases **Wicklamps** + **Bindcord** at the next Harvest |
| **Brinecrystal** | Mineral salt crusts / pressure-mineral flakes from seep walls | Mostly **Pit** deeper damp; Firmament rare near cool seep | Cistern input: releases **Presswater** + **Clearwater** at the next Harvest |
| **Verdigris** | Oxidized teal–copper scrap from crash seams, old pipe, bolted plate | **Both**; richer near metal seams / Firmament “quiet” metal veins | Wickwork conductor input, or Mid Heart public turn-in for **Tallies** |
| **Hullbit** | Rare intact seals, glass bits, strange fasteners — “Firstfall” scrap people are supposed to report | Firmament fissures + Pit wreckage hints (sparse) | **Forbidden** work-rig component, or report it for Standing / public reward |

**Demo tip:** Sporemeal / Lampwick / Brinecrystal teach the three districts. Verdigris is the “general useful scrap.” Hullbit is the rare suspicious find (pairs with Records, not replaced by them).

---

## District production (communal output — siphon targets)

Districts turn Materials into the Hollow’s communal output. This is called **District production** everywhere player-facing: it is the useful output a district has made and can still distribute. The named goods are not a second inventory in the player’s bag.

| District (placeholder name) | District production | What it is in fiction |
| --- | --- | --- |
| Farms / Glowbeds | **Glowrations** + **Glowfiber** | Glowrations are food allotments; Glowfiber is fungal textile for filters, wraps, and work clothes. |
| Wickwork | **Wicklamps** + **Bindcord** | Wicklamps are ready lamps and burners; Bindcord is rope, tool binding, and repair cordage. |
| Cistern | **Presswater** + **Clearwater** | Presswater runs lifts and annex work; Clearwater is drinking, washing, and basic filtration supply. |

Use two labels consistently:

- **Production rate** — what this district makes each Harvest. Safe-magic upgrades improve this.
- **District production** — the currently available named goods. Siphon reduces a specific good, never an abstract district meter.

Healthy production makes diversion harder to notice; thin production + a siphon is conspicuous (**Cover**).

## Material allocation contract (demo)

Every Material has a public destination and an immediately legible effect. The three common inputs intentionally have an obvious civic use; **Verdigris** and **Hullbit** supply the real forked choices, while current production needs determine which common input is valuable on a given run. These are the **proposed demo values**: tune the quantities after one playable loop, but preserve the choices.

| Material | Public choice | Concrete effect | What the player gives up / decides |
| --- | --- | --- | --- |
| **Sporemeal** | Give to **Glowbeds** | Queue **2 Glowrations + 1 Glowfiber** for the next Harvest; receive **1 Tally** | It is food production, so feeding Glowbeds improves visible household output and future Siphon Cover; keeping it earns nothing now and consumes bag space. |
| **Lampwick** | Give to **Wickwork** | Queue **1 Wicklamp + 2 Bindcord** for the next Harvest; receive **1 Tally** | Feeding Wickwork supports both light and repairs; carrying it home delays that production and keeps the bag tighter. |
| **Brinecrystal** | Give to **Cistern** | Queue **2 Presswater + 1 Clearwater** for the next Harvest; receive **1 Tally** | Cistern production supports both working infrastructure and daily life, so diverting it when thin should read as a direct civic harm. |
| **Verdigris** | Give to **Wickwork**, or turn in at **Mid Heart** | Wickwork: queue **2 Wicklamps + 1 Bindcord** next Harvest. Mid Heart: receive **3 Tallies** and no production. | The player chooses communal output and stronger Cover, or a faster sanctioned gear purchase. |
| **Hullbit** | **Report** it, or **hide** it | Report: **+1 Standing** and **2 Tallies**. Hide: retain **1 forbidden component** for a secret work-rig recipe. | This is the explicit ethical choice: public trust now, or private capability and future suspicion. |

### Production rules (thin but meaningful)

1. A turn-in queues output for the **next Harvest**, not an instant number pop. The player can see the district’s “Next Harvest” forecast rise.
2. Each district begins a Harvest with a small baseline production of **1 of each** named good. Inputs add the queued output above; an empty district therefore looks strained but never entirely dead.
3. Safe-magic efficiency adds **+1 output per queued input** in its district. It is public help, not a siphon purchase.
4. A Siphon spends a named unit of District production. It cannot take a good below its baseline **1**; below **3**, the UI warns **“Production is thin — diversion will be noticed.”**
5. Cover is calculated from the production left after diversion across all six goods. The player sees the result before confirming, rather than guessing at a hidden percentage.

This creates three readable decisions: which district to feed for the next Harvest, whether Verdigris becomes quick personal pay or communal output, and whether Hullbit becomes public trust or forbidden progress.

Efficiency upgrades raise *production of these goods*, which is why helping districts also covers theft.

---

## Records (unchanged, separate)

- Findable while digging; unlock Journal entries + knowledge junctions (e.g. Quiet Dig).
- Never stacked as Materials inventory rows.
- Always forbidden-tier when used for knowledge upgrades.

---

## Inventory UX sketch (thin for demo)

**Where**

- **On dig / Firmament / Pit:** compact **haul bag** — counts only (list or 2×3 icon grid). Materials + Record stubs you’ve found this trip.
- **In Hollow:** same bag + turn-in at **Mid Heart** (market / allotments / material turn-in). District props can accept their matching input.

**Carry limits (keep thin)**

- Soft stack caps per Material type (e.g. 20 common / 5 Hullbit) — enough to force a return trip, not a spreadsheet.
- Optional single “bag full” toast; no weight sim, no sorting mini-game.

**Flows**

1. Dig → Materials (and rare Records) enter haul bag.
2. Return before Harvest miss.
3. Turn Sporemeal / Lampwick / Brinecrystal into district inputs → District production rises at next Harvest → Cover improves.
4. Turn Verdigris for Tallies / open help (when Tallies exist); keep Hullbit for secret craft or risk reporting.
5. At home only: **Siphon** diverts named District production for forbidden work-rig pieces (Cover from remaining production + production rates).

**UI copy**

- Panel title: **Materials** (not Salvage).
- District panel shows District production by name, current amount, production rate, and next-Harvest forecast.
- Siphon lines name the specific good being diverted (“Divert Bindcord”).

---

## Pending code rename (backlog — not this pass)

| Current code / UI | Target fiction |
| --- | --- |
| `resources.gd` / Salvage wallet | Materials inventory (multi-type) |
| HUD “+Salvage” floats | Per-material floats (`+Sporemeal`, etc.) |
| Siphon shop paid in Salvage | Siphon paid in District production; open efficiency via Tallies / free-or-quest later (Decision 2) |
| District “Mushrooms / Wickgoods / Water” | Glowrations + Glowfiber / Wicklamps + Bindcord / Presswater + Clearwater |

Do **not** rewrite the full economy in one pass — docs lock first, then a focused implement after name confirmation + Decision 2 (efficiency UI).

---

## Still needs USER OK

1. **Confirm or edit the five dig Material names** and six District-production names in the tables above.
2. Then **Decision 2** (efficiency / safe-magic UI — separate panel vs shared) — asked after names stick.
