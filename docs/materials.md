# Act 1 Materials + Inventory (proposal)

**Status:** Design lock for economy *shape* (USER). Named District production + Materials queue are implemented for the Act 1 slice; efficiency spend still uses transitional Salvage until Tallies UI lands.

Companions: [`story.md`](story.md) · [`game-decisions.md`](game-decisions.md) (#28, #29) · [`act1-demo-plan.md`](act1-demo-plan.md) · [`../CONTEXT.md`](../CONTEXT.md)

---

## Locked shape (USER)

| Lock | Detail |
| --- | --- |
| **Category name** | **Materials** — not “Salvage” (too generic). |
| **Dig haul** | Multi-type Materials + rare **Records** (Records stay a separate track). |
| **District feed** | Some dig finds are **inputs** that feed Glowbeds / Wickwork / Cistern. |
| **Steal** | Diverts **District production** (communal output), not a generic Materials wallet. |
| **Efficiency** | Open “safe magic” that raises a district’s production rate → healthier production → lower **Shortage Risk**. |
| **Inventory** | Required for the demo economy (thin UX OK). |

**Code today** implements named District production + Materials turn-in queue for Harvest. Salvage remains a transitional dig haul id used by open efficiency spend until Tallies UI lands. See Act 1 District production slice tests.

---

## Category vs tracks

| Track | Player-facing | Role |
| --- | --- | --- |
| **Materials** | Inventory category | Dig finds you carry and turn in / craft with |
| **District production** | Communal output | Glowrations / Glowfiber, Wicklamps / Bindcord, and Presswater / Sealbrine; **what Steal diverts** |
| **Records** | Journal / knowledge | Lore + forbidden knowledge gates — **not** Materials |
| **Tallies** | Personal work pay | Open requisition of sanctioned gear (later; may stay thin in demo) |
| **Trust** | Social standing | Residence / access / scrutiny — not a spend currency; no separate Contribution meter |

---

## Diggable Materials (demo set — 5)

Grounded in Mouth rock, damp growth, teal–copper crash metal. Avoid generic “ore.”

| Material | What it is | Where it tends to come from | What you do with it |
| --- | --- | --- | --- |
| **Sporemeal** | Packed fungal nutrient from damp wall mats — smells like wet cellar bread | Mostly lower **side galleries** near the Devil’s Mouth; Firmament only in soft damp pockets | Glowbeds input: releases **Glowrations** + **Glowfiber** at the next Harvest |
| **Lampwick** | Fibrous strands + resin-soaked cordage from fungal mats and old tool bindings | Braced work galleries and old lateral tunnels; Firmament pockets are rare | Wickwork input: releases **Wicklamps** + **Bindcord** at the next Harvest |
| **Brinecrystal** | Mineral salt crusts / pressure-mineral flakes from seep walls | Lower lateral seep galleries; Firmament rare near cool seep | Cistern input: releases **Presswater** + **Sealbrine** at the next Harvest |
| **Verdigris** | Oxidized teal–copper scrap from crash seams, old pipe, bolted plate | **Both**; richer near metal seams / Firmament “quiet” metal veins | Wickwork conductor input, or Mid Heart public turn-in for **Tallies** |
| **Hullbit** | Rare intact seals, glass bits, strange fasteners — “Firstfall” scrap people are supposed to report | Firmament fissures + old lateral service galleries near the Devil’s Mouth (sparse) | **Forbidden** work-rig component, or report it for Trust / public reward |

**Demo tip:** Sporemeal / Lampwick / Brinecrystal teach the three districts. Verdigris is the “general useful scrap.” Hullbit is the rare suspicious find (pairs with Records, not replaced by them).

---

## District production (communal output — theft targets)

Districts turn Materials into the Hollow’s communal output. This is called **District production** everywhere player-facing: it is the useful output a district has made and can still distribute. The named goods are not a second inventory in the player’s bag.

| District (placeholder name) | District production | What it is in fiction |
| --- | --- | --- |
| Farms / Glowbeds | **Glowrations** + **Glowfiber** | Glowrations are food allotments; Glowfiber is fungal textile for filters, wraps, and work clothes. |
| Wickwork | **Wicklamps** + **Bindcord** | Wicklamps are ready lamps and burners; Bindcord is rope, tool binding, and repair cordage. |
| Cistern | **Presswater** + **Sealbrine** | Presswater runs lifts and bore tools; Sealbrine is concentrated mineral sealant for pressure lines, cracked stone, and rig joints. |

Player-facing district name for Farms is **Glowbeds**.

Use two labels consistently:

- **Production rate** — what this district makes each Harvest. Safe-magic upgrades improve this.
- **District production** — the currently available named goods. Theft reduces a specific good, never an abstract district meter.

Healthy production lowers **Shortage Risk**; thin production makes a theft more likely to be noticed later.

## Material allocation contract (demo)

Every Material has a public destination and an immediately legible effect. The three common inputs intentionally have an obvious civic use; **Verdigris** and **Hullbit** supply the real forked choices, while current production needs determine which common input is valuable on a given run. These are the **proposed demo values**: tune the quantities after one playable loop, but preserve the choices.

| Material | Public choice | Concrete effect | What the player gives up / decides |
| --- | --- | --- | --- |
| **Sporemeal** | Give to **Glowbeds** | Queue **2 Glowrations + 1 Glowfiber** for the next Harvest; receive **1 Tally** | It is food production, so feeding Glowbeds improves visible household output and lowers future Glowbeds Shortage Risk; keeping it earns nothing now and consumes bag space. |
| **Lampwick** | Give to **Wickwork** | Queue **1 Wicklamp + 2 Bindcord** for the next Harvest; receive **1 Tally** | Feeding Wickwork supports both light and repairs; carrying it home delays that production and keeps the bag tighter. |
| **Brinecrystal** | Give to **Cistern** | Queue **2 Presswater + 1 Sealbrine** for the next Harvest; receive **1 Tally** | Cistern production supports both working infrastructure and safe excavation, so diverting it when thin should read as a direct civic harm. |
| **Verdigris** | Give to **Wickwork**, or turn in at **Mid Heart** | Wickwork: queue **2 Wicklamps + 1 Bindcord** next Harvest. Mid Heart: receive **3 Tallies** and no production. | The player chooses communal output and lower Shortage Risk, or a faster sanctioned gear purchase. |
| **Hullbit** | **Report** it, or **hide** it | Report: **+1 Trust** and **2 Tallies**. Hide: retain **1 forbidden component** for a secret work-rig recipe. | This is the explicit ethical choice: public trust now, or private capability and future suspicion. |

### Production rules (thin but meaningful)

1. A turn-in queues output for the **next Harvest**, not an instant number pop. The player can see the district’s “Next Harvest” forecast rise.
2. Each named good has a protected civic reserve of **1**. It is a minimum working amount, not free production: inputs create all production above it.
3. At each Harvest, district demand consumes **1 unit above the protected reserve** when available. NPC activity and district props show that use, so production never becomes a permanent bank.
4. Each named good has a visible capacity of **6**. Full production pauses until the Hollow consumes or the player diverts some, so overfeeding a district is not optimal.
5. Safe-magic efficiency adds **+1 output per queued input** in its district. It is public help, not a Siphon purchase.
6. A Steal spends a named unit of District production. It cannot take a good below its protected reserve of **1**; below **3**, the UI warns that Shortage Risk is high.
7. Shortage Risk weights the stolen good at **70%** and its sibling good in the same workplace at **30%**. Food elsewhere cannot make missing pressure capacity plausible. The player sees the baseline before committing, rather than guessing at a hidden percentage.

### Theft risk and consequences (approved)

- **Shortage Risk** is the delayed workplace/accounting risk: how likely the missing good is to stand out after the theft. Healthy output and its workplace sibling lower it; thin output raises it.
- **Witness Risk** is the only live theft meter. It appears only during the short, cancellable in-world theft action and moves through **Quiet → Noticed → Watched → Risky → Exposed**. Residents walking close visibly raise it; a nearby Council Warden raises it sharply. The player receives a subtle alert and can stop before being caught.
- A successful unnoticed theft costs **no Trust immediately**. High Shortage Risk can still produce a later shortage inspection or audit.
- A caught theft costs Trust and creates a temporary, local **Under Watch** theft lockout with visibly increased Warden attention at that workplace. It is not a global ban, instant failure, fall hazard, or softlock.
- Do not use factor tags in the theft UI. The world communicates danger through nearby people, Wardens, inspections, and the production site itself.

### Work-rig modification choices (approved)

The player wears one integrated Mouthworker rig—suit, drill assembly, harness, and utility pack—not a pile of separate tools. It has three physical modification mounts: **Toolhead** for digging/discovery, **Harness** for movement/recovery, and **Utility pack** for secrecy or civic utility. Important discoveries lead to physical repair bays, hidden maintenance stations, sealed hatch rooms, or recovered components. A junction presents two or three strong modules with meaningful downsides; the limited mounts prevent a universal best build. Public modules use Tallies/requisition while forbidden modules use Steal, Records, or concealed wreckage finds. Basic traversal is never permanently missable. Optional build-changing modules are **semi-permanent**: the player may swap only at home or a proper workbench for a meaningful refit cost, preserving experimentation without making every expedition build interchangeable. Theft modules alter approach and risk rather than adding a generic theft-power stat; no equipment passively grants Trust.

This creates three readable decisions: which workplace to feed for the next Harvest, whether Verdigris becomes quick personal pay or communal output, and whether Hullbit becomes public trust or forbidden progress.

Efficiency upgrades raise *production of these goods*, which is why helping districts also lowers Shortage Risk.

### What the Cistern does for the player

The Cistern is the **hard-excavation / recovery workplace**. Its output should make the player feel more capable in unstable side galleries, not merely better hydrated.

| Stolen good | Forbidden work-rig use | Player result |
| --- | --- | --- |
| **Presswater** | **Bore Pulse** charge | Break a reinforced seam or get a short burst of digging power; a direct route into better lateral-gallery hauls. |
| **Presswater + Bindcord** | **Tether Pull** charge | Emergency upward recovery from an unsafe side gallery; the practical first upgrade to the personal tether rig. |
| **Sealbrine + Glowfiber** | **Quiet Sleeve** | Muffles and seals the drill assembly, reducing Firmament-dig notice risk. This is the physical component of Quiet Dig; the Record remains its knowledge gate. |
| **Sealbrine + Hullbit** | **Hullbit restoration** (later) | Makes a recovered component usable in a forbidden recipe instead of inert suspicious scrap. |

**Design rule:** do not steal drinking water as a generic survival meter. The Cistern’s theft should be visibly about taking pressure and maintenance capacity away from lifts, repairs, and safe excavation—the same services the Hollow relies on.

### Work suit: the wearable upgrade lane

**Glowfiber** is the suit’s base material: a woven fungal textile that is warm, durable, and visibly distinct from ordinary Hollow clothes. Do not make a separate “armor wardrobe.” The player has one recognizable **Mouthworker suit** with modular worn upgrades, each visible on the sprite and tied to a real dig problem.

| Worn module | Materials / production | Benefit | Visible change |
| --- | --- | --- | --- |
| **Glowfiber liner** | Glowfiber + **3 Tallies** | Expands the haul bag by one common-Material stack; gives the player a visibly padded undersuit. | Pale teal collar, cuffs, and knee patches. |
| **Tether harness** | Bindcord + **6 Tallies** | Sanctioned base harness. It enables a later Tether Pull, but is not an automatic rescue. | Cross-body rope harness, pressure-canister mount at the hip. |
| **Tether Pull cartridge** *(forbidden)* | Tether harness + **2 Presswater** diverted by Steal | One emergency upward recovery per expedition; protects an unsafe side gallery without removing its danger. | Charged pressure canister at the hip. |
| **Quiet sleeve** | Glowfiber + Sealbrine + Firmament Record | Reduces Firmament-dig notice risk; this is the worn implementation of Quiet Dig. | Dark sealed forearm, wrapped drill hand. |
| **Wicklamp hood** *(later)* | Wicklamp + Glowfiber + **6 Tallies** | A sanctioned work lamp that reveals nearby fragile seams; it does not become a generic fog-of-war system. | Small hood lamp and warm face rim-light. |
| **Hullwork overcoat** *(later)* | Restored Hullbit + Sealbrine + Glowfiber | Unlocks one late forbidden rig junction; do not define its final power until the Act 1 core loop is proven. | Patched reflective mantle over the existing suit. |

**Why this mix works:** Glowbeds make the cloth, Wickwork makes the harness and lamp, and Cistern makes the pressure/seal components. A suit upgrade therefore makes every district personally relevant, while the player still feels the cost of diverting communal production.

**Demo limit:** implement only **Glowfiber liner**, **Tether harness + Tether Pull**, and **Quiet Sleeve**. Wicklamp Hood and Hullwork Overcoat stay visible as later ideas, not demo requirements.

### Tally ladder (demo)

Tallies need visible prices so public work is a meaningful alternative to diversion:

| Cost | Public reward |
| --- | --- |
| **3 Tallies** | Small sanctioned module, such as the Glowfiber liner. |
| **6 Tallies** | Substantial sanctioned module, such as the Tether harness or later Wicklamp Hood. |
| **10 Tallies** | Major public efficiency improvement for a district. |

Verdigris’s **3 Tallies now** is therefore a real shortcut to a small public module, while contributing it to Wickwork improves local production and lowers Shortage Risk instead.

---

## Records (unchanged, separate)

- Findable while digging; unlock Journal entries + knowledge junctions (e.g. Quiet Dig).
- Never stacked as Materials inventory rows.
- Always forbidden-tier when used for knowledge upgrades.

---

## Inventory UX sketch (thin for demo)

**Where**

- **On dig / Firmament / civic side galleries:** compact **haul bag** — counts only (list or 2×3 icon grid). Materials + Record stubs you’ve found this trip.
- **In Hollow:** same bag + turn-in at **Mid Heart** (market / allotments / material turn-in). District props can accept their matching input.

**Carry limits (keep thin)**

- Soft stack caps per Material type (e.g. 20 common / 5 Hullbit) — enough to force a return trip, not a spreadsheet.
- Optional single “bag full” toast; no weight sim, no sorting mini-game.

**Flows**

1. Dig → Materials (and rare Records) enter haul bag.
2. Return before Harvest miss.
3. Turn Sporemeal / Lampwick / Brinecrystal into district inputs → District production rises at next Harvest → Shortage Risk falls.
4. Turn Verdigris for Tallies / open help (when Tallies exist); keep Hullbit for secret craft or risk reporting.
5. At home only: **Steal** diverts named District production for forbidden work-rig pieces. Shortage Risk derives from remaining production and the related good at that workplace; Witness Risk applies during the cancellable theft action.

**UI copy**

- Panel title: **Materials** (not Salvage).
- District panel shows District production by name, current amount, production rate, and next-Harvest forecast.
- Before an expedition, each district can show one short **request** driven by its lowest good (for example, “Cistern needs Presswater”). This makes common-material gathering an informed public choice rather than auto-turn-in.
- Steal lines name the specific good being diverted (“Steal Bindcord”).

---

## Pending code rename (backlog — not this pass)

| Current code / UI | Target fiction |
| --- | --- |
| `resources.gd` / Salvage wallet | Materials inventory (multi-type) |
| HUD “+Salvage” floats | Per-material floats (`+Sporemeal`, etc.) |
| Siphon shop paid in Salvage | Steal paid in District production; open efficiency via Tallies / free-or-quest later (Decision 2) |
| District “Mushrooms / Wickgoods / Water” | Glowrations + Glowfiber / Wicklamps + Bindcord / Presswater + Sealbrine |

Do **not** rewrite the full economy in one pass — docs lock first, then a focused implement after name confirmation + Decision 2 (efficiency UI).

---

## Still needs USER OK

1. **Confirm or edit the five dig Material names** and six District-production names in the tables above.
2. Then **Decision 2** (efficiency / safe-magic UI — separate panel vs shared) — asked after names stick.
