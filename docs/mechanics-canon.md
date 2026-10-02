# Krater Mechanics Canon

> **Source-of-truth rule**
>
> This file is the mechanics source of truth for **Krater**. It supersedes conflicting mechanics details elsewhere in the repository unless a detail is explicitly marked **USER-locked** in its original source and has not been superseded here.
>
> Older AI-authored formulas, exact values, placeholder names, demo tables, prototype behaviors, and implementation details are **non-canon** when they conflict with this file.
>
> The purpose of this document is to stop AI-generated design drift. Future design and implementation work must preserve the distinction between confirmed decisions, agreed directions, intentionally open questions, and rejected approaches.

---

## Reading this document

- **LOCKED** — confirmed design decision. Future implementation and documentation must honor it.
- **DIRECTION** — agreed design intent or preferred shape, but details still need design/prototyping.
- **OPEN** — intentionally unresolved. Do not silently invent a formula, name, number, or mechanic.
- **CUT** — rejected as the default design. Do not reintroduce without a new explicit decision.
- **EXAMPLE** / **EXAMPLES** — illustrative only. Useful for understanding the intended feel, but not itself canon unless separately marked.

Compound labels used below: **LOCKED DIRECTION** and **STRONG DIRECTION** mean the intent is locked but the details are still DIRECTION; **LOCKED / DIRECTION** marks a section mixing both, with each bullet read by its wording; **DIRECTION / REFERENCE** is a design reference scenario, not a script; **NON-CANON** lists legacy details that no longer define the game.

**Repo adoption (2026-09-14, USER):** every other doc in this repository defers to this file. Where older story, pitch, decision, or layout text contradicted it, that text was rewritten to match. Naming follow-ups locked alongside adoption: the daily communal observance is **Ritual** (formerly “Holding”; also replaces “Harvest”), and the **Firmament is thick** — there is no naturally thin shortcut through it.

---

# 1. Core Game Loop

## LOCKED

Krater is a game of **civic life, underground exploration, physical work, progression, mystery, and quiet transgression**.

The recurring loop is:

1. Live in the Hollow and understand what people currently need.
2. Take legitimate civic work, accept a commitment, or choose personal exploration.
3. Travel through the Hollow/frontier.
4. Observe, infer, excavate, extract, explore, and haul meaningful finds.
5. Decide how far to push before returning.
6. Decide what to keep, cache, report, deliver, contribute, order through Approved Gear channels, or secretly divert.
7. Return to a changing Hollow where district condition, work, Trust, Ritual, infrastructure, and NPC reactions respond to what happened.
8. Improve the Rig, Hollow, districts, infrastructure, knowledge, access, and relationships.
9. Reach new places and discoveries that change the next expedition.

Public lateral excavation expands and supports the Hollow. Personal investigation can push toward restricted, ship-related, Firmament, and mystery content.

The game does **not** split into disconnected “work mode” and “adventure mode.” The same traversal, digging, hauling, perception, social, production, and progression systems support both.

Strong upgrades should change:
- what the player can do,
- what they can perceive,
- what routes are possible,
- what risks they can take,
- what resources they can handle,
- or what decisions they face.

Pure numeric improvements may support those changes but are not the primary progression fantasy.

---

# 2. Geology, Digging, and Frontier Structure

## LOCKED

The geology of the Hollow reflects the colony-ship impact.

Closer to the central crash/impact disturbance, rock is more fractured, altered, disrupted, and mixed with ship debris.

Farther sideways, upward, downward, or into less disturbed strata, geology becomes more intact, dense, difficult, or treacherous.

Progression therefore feels like:

> the world becomes harder to work with, so the player needs better knowledge, infrastructure, and equipment.

It should **not** feel like RPG enemies/rocks arbitrarily scaling to the player's level.

Digging serves multiple purposes:

- public civic excavation,
- personal exploration,
- access creation,
- route finding,
- revealing Materials,
- exposing cavities,
- exposing ship structures,
- forbidden excavation,
- environmental storytelling.

Most destructible terrain is simply rock. Breaking rock primarily creates paths, reveals information, and exposes meaningful things.

## LOCKED — Frontier progression

Important areas can evolve through:

**wild frontier → active worksite → established Hollow territory**

The Hollow gradually expands into places the player first encountered as raw frontier.

Frontier transformation should rely mostly on modular stateful additions:
- supports,
- lamps,
- pipes,
- rails,
- crates,
- platforms,
- scaffolds,
- work furniture,
- fungal growth,
- lifts,
- rest equipment,
- utility infrastructure,
- worker presence.

Do not require full bespoke room redraws for every state.

## DIRECTION

Major, story-significant transformations may justify bespoke before/after art.

Frontier progression is partly defined by infrastructure: places that were difficult and exhausting become easier to use as the Hollow establishes support.

---

# 3. Materials, Deposits, and Resource Pockets

## LOCKED

Most broken terrain yields **nothing collectible**.

Bulk **Materials** are recognizable deposits, growths, salvage, or concentrated useful matter embedded naturally in the environment.

Material acquisition usually follows:

**discover → expose/excavate → extract → haul/store/use**

Extraction turns a meaningful deposit into a recoverable physical resource rather than an automatic stream of inventory numbers.

Natural deposits are finite. They do **not** regenerate.

District production renews through civic activity; natural Materials do not.

Materials should remain relatively low-number and meaningful rather than becoming hundreds of generic crafting units.

Players should not feel compelled to strip-mine every useful pocket immediately.

Time, stamina, fatigue, hauling capacity, distance, current needs, and future logistics create natural tradeoffs.

## LOCKED — Resource pockets / micro-environments

Materials are distributed partly through concentrated, environmentally logical resource pockets rather than evenly across terrain.

Examples include:
- damp fungal cavities,
- water/mineral pockets,
- dense impact-altered stone strata,
- buried ship-fracture zones,
- old service cavities,
- partially flooded ship spaces,
- areas with unusual pressure or structural conditions.

Multiple Materials may co-occur when the environment supports it.

A damp cavity might contain biological/fungal resources plus Brinecrystal.

An impact pocket may contain Verdigris traces, Hullbit, Components, or Records.

A dense impact stratum may contain structural stone and occasional ship debris.

Resource pockets can also contain:
- Components,
- Records,
- unusual spaces,
- hidden routes,
- environmental clues,
- small narrative discoveries.

Resource gathering and mystery should naturally overlap.

## LOCKED — Environmental clues

Materials can also provide information about the world.

Examples:
- biological/fungal traces can imply damp conditions or a nearby viable growth pocket;
- Brinecrystal can suggest moisture, water, or pressure conditions;
- Verdigris can suggest buried ship conductors/infrastructure;
- impact-altered structural stone can hint at impact geometry;
- Hullbit and ship debris can imply proximity to larger buried structures.

The player should increasingly learn to read geology rather than merely scan for colored ore.

## DIRECTION — Recording discoveries

Significant resource pockets may be recorded in a rough player map/journal so the player can intentionally return later.

This should feel like the player remembering/marking a place, not modern GPS.

---

# 4. Current Act 1 Material Roster

## LOCKED — Roster philosophy

Act 1 uses a **small, learnable Material roster** of five important bulk Materials.

Materials should generally support more than one meaningful use.

Avoid:

> Material A exists only because District A consumes it.

Materials should connect exploration, districts, civic projects, infrastructure, Approved Gear, and Forbidden Gear.

## LOCKED — Naming approach

Material names should sound like practical Hollow vocabulary: strange enough to feel setting-specific, but compatible with names such as **Glowbeds, Wickwork, Cistern, Firmament, Verdigris, and Hullbit**.

Stronger Indian/Buddhist/Arabic linguistic influence is better reserved for:
- social institutions,
- places,
- ritual language,
- titles,
- doctrine,
- culturally inherited terminology.

Industrial and Material vocabulary may mix degraded English, worker slang, old technical terms, and setting-specific coined words.

Do not force every Material name through one real-world language.

## LOCKED — Sutral

**Sutral** is a naturally occurring and cultivable underground biological/fungal Material with:
- useful fibrous structure,
- cultivation value,
- biological significance,
- recovery/light applications.

Primary associations:
- Glowbeds,
- Wickwork,
- frontier cultivation,
- fibers/bindings,
- biological technology.

The previous **Sporemeal** and **Threadroot** names are rejected.

## LOCKED — Ravelstone

**Ravelstone** is a dense, useful structural geological Material associated with impact-altered or unusually strong stone.

It supports:
- supports,
- platforms,
- reinforcement,
- construction,
- civic expansion,
- heavy structural projects.

Its existence prevents rare ship material from becoming the answer to every construction need.

Earlier names such as Charstone, Deeprock, Lunore, Karn, and Tetzal are non-canon.

## LOCKED — Brinecrystal

**Brinecrystal** is a water/mineral-associated geological Material.

It has believable relationships to:
- moisture,
- water treatment,
- Cistern processes,
- sealing,
- pressure systems,
- environmental clues.

It should not read as generic glowing fantasy crystal.

## LOCKED — Verdigris

**Verdigris** is the Hollow's practical term for recoverable corroded copper-bearing/conductive ship material embedded through impact geology.

The useful material may technically be the conductor beneath the corrosion rather than the corrosion itself; the colloquial name remains Verdigris.

Uses can include:
- Wickwork,
- Cistern machinery,
- electrical systems,
- infrastructure,
- Rig technology,
- Pulse Binder technology,
- advanced/Forbidden technology.

Verdigris also acts as a clue that buried ship infrastructure may be nearby.

## LOCKED — Hullbit

**Hullbit** is useful recoverable colony-ship structural composite embedded in impact debris/strata.

Ordinary useless hull debris may be common scenery; recoverable Hullbit is the valuable intact material.

Uses can include:
- civic reinforcement,
- infrastructure,
- Approved Gear,
- Forbidden Gear,
- major projects,
- advanced ship-related technology,
- later shipbuilding.

Hullbit should create real allocation decisions between community use and personal/secret progression.

## CUT

- Lampwick as a raw mined Material.
- Sporemeal or Threadroot as the final biological Material/name.
- Charstone, Deeprock, Lunore, Karn, or Tetzal as the final structural-stone name.
- One-to-one “colored key” Materials for individual districts.
- Huge generic crafting-resource catalogs.

---

# 5. Materials, Components, and Records

## LOCKED

Krater distinguishes three fundamentally different discovery types.

### Materials

Bulk physical resources.

Used for:
- civic projects,
- district improvements,
- infrastructure,
- equipment fabrication,
- some Forbidden Gear,
- construction.

Usually hauled physically before being stored.

### Components

Smaller manufactured/specialized objects, commonly ship-derived.

Examples conceptually include:
- actuators,
- sensors,
- regulators,
- fittings,
- electronics,
- mechanisms.

Components normally use lightweight personal storage rather than trailing behind the player as bulk haul objects.

### Records / Discoveries

Information and knowledge.

Records should:
- teach how something works,
- reinterpret an existing technology,
- expose contradictions,
- reveal a route or capability,
- unlock a district project,
- unlock an Approved capability,
- unlock or enable a Forbidden Design.

Records are **not** generic “Knowledge +1” currency.

A useful conceptual distinction is:

> **Material = we have the stuff.**  
> **Component = we have the part.**  
> **Record = we know how.**

Not every technology must require all three.

---

# 6. Extraction

## LOCKED

Different Materials can feel modestly different to extract without creating five separate minigames.

Better equipment should make previously difficult/impractical extraction possible rather than mainly giving percentage yield bonuses.

Potential extraction identities:

- biological/fungal Material: relatively easy once reached;
- structural stone: dense and exertive;
- Brinecrystal: tied to moisture/water/pressure conditions;
- Verdigris: may reward careful exposure of embedded ship conductors;
- Hullbit: may require better precision/power to recover intact sections.

Exact implementation remains open.

Extraction leaves persistent visual evidence:
- cut roots,
- harvested growth,
- fractured stone,
- exposed substrate,
- removed ship section,
- empty Hullbit socket,
- extraction scars.

## LOCKED — Pixel-art implementation principle

Depletion should use modular asset states or overlays rather than generating a bespoke full-room redraw.

Typical pattern:

**base terrain + intact deposit overlay → depleted/extracted overlay**

Partial states should only exist where they add meaningful value.

Most deposits can probably use:
- intact
- depleted

This is compatible with PixelLab by generating reusable deposit variants and overlays.

## CUT

- Every broken tile dropping loot.
- Fully bespoke before/after room art for every deposit.
- Separate extraction minigames for every Material.

---

# 7. Hauling and Caching

## LOCKED

Bulk Materials are visibly hauled/tethered behind the player.

The physical behavior should prioritize **game reliability and readability**, not fully accurate rope physics.

Allowed techniques include:
- smoothing,
- anti-snagging,
- compressed chains,
- controlled repositioning,
- reduced collisions,
- other fake/assisted physics.

The goal is physical feel, not simulation purity.

Normal hauling primarily blocks stamina rather than creating a large set of special traversal prohibitions.

Ordinary traversal should remain broadly functional while hauling.

## LOCKED — Caches

A cache is an **optional local frontier stash**.

Use case:

> the player finds more extracted Material than is comfortable to haul home now, so they deliberately leave excess at a known location for later retrieval.

Caching is not mandatory.

A cache is not a magical global inventory.

It represents physical extracted goods left locally.

Potential progression:

**discover pocket → extract some → cache excess → return later → worksite/logistics eventually make transport easier**

## DIRECTION

Cache representation may be a small pile, crate, marked stash, or similar world object.

Later logistics can reduce the need for repetitive long-distance hauling.

## CUT

- Mandatory caching.
- Fully realistic rope-rigidbody simulation as a core requirement.
- Designing every route separately for loaded vs unloaded traversal.

---

# 8. Personal Storage, Ownership, and Material Delivery

## LOCKED

Returning to the Hollow does **not** automatically dump all Materials into communal storage.

The player can maintain personal Material storage at home.

Bulk Materials are physical while being transported, but once placed in established storage they can become abstract stored quantities.

This prevents the player's home from filling with dozens of persistent physics objects.

## LOCKED — Contextual ownership

Ownership is contextual.

### Generally legitimate to keep

Ordinary Materials independently found while exploring an allowed area are generally legitimate personal finds.

### Expected civic delivery

Materials gathered specifically for:
- accepted work,
- assigned duties,
- civic excavation,
- a promised project,

may carry a clear expectation of delivery.

Secretly withholding such Materials can become misconduct/theft.

### District production

District-produced goods stored in district/output areas are communal/district property unless legitimately allocated.

Taking them secretly is theft/diversion.

### Rare Components and Records

Rare ship Components/Records may carry reporting expectations depending on context.

Possessing something from a restricted area may itself create a social problem because it implies where the player has been.

## LOCKED — Material contribution

Materials delivered to districts/projects should have understandable purpose.

The player should usually know:

> what is being built/improved and why the Material matters.

Normal useful Material delivery primarily interacts with **Tallies**.

Trust changes should be reserved for socially meaningful behavior, such as:
- fulfilling an important commitment,
- exceptional assistance,
- returning something especially important,
- helping during a shortage,
- being caught withholding promised civic Material.

Do not award tiny Trust changes for every rock delivered.

---

# 9. Stamina

## LOCKED

Stamina is a core physical budget.

The base stamina bar is visually stable.

Do **not** display something like:

> 85 / 85

when the character is burdened.

Instead, display the full baseline capacity with blocked portions.

Ordinary walking should be free or essentially free.

Normal jumping should be free/negligible unless a specific mechanic later justifies otherwise.

Strenuous actions can consume stamina:
- digging,
- sprinting,
- sustained climbing,
- difficult traversal,
- hauling,
- powerful Rig actions,
- hazards.

## LOCKED — Normal regeneration

Ordinary stamina regenerates when the player is not performing strenuous work.

Walking should not normally prevent regeneration.

---

# 10. Blocked Stamina, Fatigue, and Overexertion

## LOCKED — Stamina blocks

Certain conditions block part of the fixed stamina bar: that portion is visible on the bar, but the player can't spend it until the block is released.

### Hauling block

Hauling Materials blocks part of your stamina.

Removing/depositing/caching the load releases that block.

### Rig Strain block

Equipping Gear beyond safe Rig Capacity creates Rig Strain, which blocks stamina.

The hauling block and the Rig Strain block are separate causes that can stack on the same fixed stamina bar.

### Fatigue block

Fatigue is longer-lasting expedition strain.

Fatigue blocks stamina capacity but does **not** simply disappear through ordinary moment-to-moment stamina regeneration.

## LOCKED — Overexertion

At zero usable stamina, the player does not simply collapse.

When appropriate, the player may **Overexert**: push through an action anyway.

Overexerting converts additional future capacity into fatigue.

Repeated abuse can lead to an exhausted state where strenuous activity is no longer possible until proper recovery.

Do not add random injury systems at this stage.

## LOCKED — Recovery

Proper recovery includes believable support:
- safe rest,
- established worksite rest infrastructure,
- home,
- food/support systems,
- sleep.

Sleep provides full or near-full fatigue recovery.

Field rest can provide partial fatigue recovery at a time cost.

Proper rest points should be relatively rare and associated with believable established Hollow/worksite infrastructure.

Frontier development therefore makes expeditions physically easier.

## DIRECTION

District health may affect rest-station quality.

Glowbeds progression may improve recovery support.

## CUT

- Hunger survival meter.
- Thirst survival meter.
- Random injury systems.
- Fatigue disappearing through ordinary stamina regeneration.

## OPEN

Exact:
- stamina capacity,
- rates,
- fatigue conversion,
- Overexertion rules,
- rest duration,
- exhaustion thresholds,
- UI treatment.

---

# 11. The Pulse

## LOCKED

The **Pulse** is a large surviving component of the crashed colony ship located at Mid Heart.

It functions simultaneously as:
- civic timekeeper,
- cultural centerpiece,
- relic,
- infrastructure,
- social anchor.

It is visibly degraded technology:
- metal,
- housings,
- conduits,
- indicators,
- vents,
- gauges,
- repairs,
- grime,
- fungal growth.

It is **not** an occult fantasy artifact covered in invented magical runes.

Its original ship function remains important but is not yet finalized.

The intended historical progression is:

**ship infrastructure → recurring machine cycle → survival routine → civic schedule → tradition → Ritual**

---

# 12. Civic Cycle and Ritual

## LOCKED

The Hollow uses the Pulse rather than daylight as its dominant civic rhythm.

Current provisional phases:

**Rousing → Working → Gathering → Ritual**

Working is the longest phase.

Final names/timings remain open.

## LOCKED — Time-pressure philosophy

Time exists to create:
- rhythm,
- context,
- social expectation,
- opportunity,
- meaningful prioritization.

It should **not** create constant rushing or stress.

A normal cycle should comfortably allow:
- reasonable civic work,
- travel,
- meaningful optional exploration,
- return.

Conflicting obligations should usually emerge because the player:
- voluntarily commits to too much,
- pursues an unexpected discovery,
- encounters an unusual event,
- or chooses to push farther.

The game should not routinely schedule impossible days.

## LOCKED — World communication

The civic cycle should be communicated primarily through the world:
- Pulse cadence,
- sound,
- lamps,
- worker movement,
- lift activity,
- workstations opening/closing,
- announcements,
- crowds moving toward Mid Heart,
- environmental ambience.

A subtle UI phase indicator may support clarity/accessibility.

## LOCKED — Ritual

Ritual is a communal return anchor.

It provides:
- social accountability,
- story opportunities,
- gathering,
- cultural texture,
- a recurring world-state transition.

Missing Ritual is **contextual**, not an automatic universal stat penalty.

NPCs can react differently depending on:
- whether the player was expected,
- what commitment existed,
- why they were absent,
- whether this is repeated behavior,
- whether evidence contradicts their explanation.

## OPEN

- exact phase durations,
- final phase names,
- exact Ritual practice,
- whether there is a quiet post-Ritual period,
- exact original Pulse function.

---

# 13. Jobs and Civic Work

## LOCKED

Jobs are physical civic situations built from the game's normal systems.

They use:
- digging,
- hauling,
- traversal,
- exploration,
- districts,
- infrastructure,
- Materials,
- social context.

They are **not** traditional quest-state checklists or job-specific minigames.

## LOCKED — Early jobs as invisible tutorials

Early civic jobs are the game's primary invisible tutorial system.

They teach the player the world through believable participation in society.

A typical early flow can naturally introduce:

**Home Court → Dispatch → worksite → excavation → recognize/extract Material → haul/deliver → see where it goes → earn Tallies → Gathering/Ritual**

Later jobs can introduce:
- districts,
- lifts,
- rest infrastructure,
- Records,
- Trust,
- restricted areas,
- unusual Components,
- theft opportunities.

The player learns mechanics because their character has believable work to do.

## LOCKED — Types of work

Work can exist as:

### Available Work

A civic need exists.

The player has not promised to do it.

Ignoring it is not inherently a Trust violation.

### Accepted Work / Commitment

The player voluntarily agrees.

There is now an expectation.

### Assigned Duty

Work expected because of the player's civic role.

Early tutorial work may use this more often.

### Emergency / World Need

Something happens regardless of the player's choice.

Participation can matter, but the game should not pretend the player made a promise they never made.

### Personal NPC Request

A personal/social request.

Consequences are contextual and do not automatically become global Trust changes.

## LOCKED

> **Not helping is not the same as promising and failing.**

Early game can provide less autonomy because the character is a junior worker.

Trust/experience should gradually unlock:
- more autonomy,
- better assignments,
- more access,
- more responsibility,
- more opportunity.

After the introduction, the player may ignore work and explore instead.

The main costs may be:
- missed Tallies,
- missed opportunity,
- contextual relationship consequences,
- broken commitments if they actually committed.

The game continues.

---

# 14. Job Deadlines and Outcomes

## LOCKED

Not every job has a hard countdown.

Different work can use different expectations:
- this cycle,
- during Working,
- before Gathering,
- during Gathering,
- multi-cycle,
- no strict deadline.

Jobs should support partial/graded outcomes internally.

Examples conceptually:
- poor,
- adequate,
- strong,
- exceptional.

These are **not** universal visible star ratings.

Different jobs care about different things.

NPCs react to what actually happened.

## LOCKED

The player-facing presentation should resemble believable:
- commitments,
- notes,
- assignments,
- work records,

not a universal checklist UI.

Exact counts can be shown when the fiction naturally requires exact counts.

---

# 15. Opening Civic-Excavation Reference Scenario

## DIRECTION / REFERENCE

A strong early-work pattern:

- Report to West Dispatch during Rousing/early Working.
- Steward assigns a crew to open a new expansion gallery.
- Workers are already present digging, supporting, hauling, talking, and resting.
- The objective is understandable environmentally: help open the gallery.
- Most rock is worthless obstruction.
- Useful Material can be exposed naturally.
- The player decides whether job-relevant resources go to the collection/worksite.
- An unexpected strange opening/object can appear outside the assignment's scope.
- This creates an early **responsibility vs curiosity** decision.

This is a design reference, not a rigid quest script.

---

# 16. Tallies

## LOCKED

Tallies are the player's transactional compensation for useful civic work/contributions.

Tallies are not Trust.

Tallies represent earned claim/access to legitimate civic production and Approved Gear.

Public progression roughly follows:

**work/contribution → Tallies → Order Approved Gear using Tallies + authorized District Output**

Tallies should remain understandable and relatively simple.

Exact prices are open.

---

# 17. Trust

## LOCKED

Trust represents society's accumulated perception of the player's reliability.

Trust is:
- social,
- contextual,
- earned over time,
- not spendable,
- not an omniscient morality meter.

Ordinary expected job completion primarily earns Tallies.

Trust changes more selectively through:
- repeated reliability,
- meaningful help,
- above-and-beyond behavior,
- serious failures,
- broken accepted commitments,
- betrayal,
- being caught stealing,
- exposed lies,
- major accomplishments.

Higher Trust can provide:
- more autonomy,
- better assignments,
- access,
- responsibility,
- infrastructure access,
- valuable Materials/Components,
- technical knowledge,
- benefit of the doubt.

Higher Trust can also create more opportunity to abuse access.

## LOCKED — Trust explanation

The player should be able to inspect meaningful reasons society currently trusts or distrusts them.

Avoid dozens of tiny permanent modifiers.

Surface:
- recent important events,
- ongoing issues,
- meaningful reliability factors.

## LOCKED — Trust presentation

Trust is presented primarily through a **small number of qualitative standing states** rather than a visible raw numeric score.

Exact internal Trust values may exist for tuning and systemic logic, but the player should normally see understandable social standing rather than `73 / 100`.

A Trust/standing surface should show:
- current qualitative standing,
- major recent reasons society trusts or distrusts the player,
- important ongoing reliability issues,
- meaningful access/status implications where appropriate.

Meaningful Trust changes should be communicated with human-readable reasons rather than `+3 Trust` or `-5 Trust`.

Trust/access requirements may be explained clearly without exposing exact numeric thresholds.

Roughly **4–5 standing states** is the current target; exact names remain tunable.

Local suspicion/investigation remains separate from global Trust.

Hidden suspicion or evidence should not be revealed by the UI before the player has a believable reason to know about it.

## CUT — Trust presentation

- giant reputation bars,
- raw visible Trust scores as the primary presentation,
- dozens of tiny permanent modifiers,
- floating `+X Trust` popups,
- a universal Suspicion meter.

---

# 18. Lying

## LOCKED

There is no generic **Lie** button.

Lying emerges contextually when the player is questioned about something believable.

Possible responses may include:
- truth,
- lie,
- deflection,
- partial truth.

Outcome depends on:
- what claim is made,
- available evidence,
- witnesses,
- circumstances,
- Trust.

Higher Trust gives the player more benefit of the doubt in ambiguous situations.

Trust cannot erase hard evidence.

The game should not normally display:

> 78% chance to lie successfully.

Exposed lies can damage Trust more than simply admitting the truth.

## EXAMPLES

Believable lying contexts include:
- being late to an accepted job,
- being caught near restricted excavation,
- missing Ritual when expected,
- being seen coming from a forbidden direction.

---

# 19. Suspicion, Detection, Evidence, and Audio

## LOCKED

Detection includes:
- sight,
- sound,
- persistent physical evidence.

The world should record meaningful facts/events rather than simulating perfect NPC knowledge.

Examples of useful facts:
- seen entering restricted tunnel,
- seen stealing,
- heard mining in restricted area,
- absent from accepted work,
- missed Ritual,
- returned from forbidden direction,
- damaged seal,
- excavated restricted wall,
- missing production,
- abandoned stolen haul.

Forbidden excavation can leave persistent evidence.

## LOCKED — Trust vs suspicion

**Trust** is the broader social reliability state.

**Suspicion is local/contextual.**

There should be **no universal global Suspicion meter**.

Suspicion can belong to:
- a relevant NPC,
- a district,
- Wardens,
- a location,
- an incident,
- a specific unexplained shortage.

## DIRECTION — Noise system

Actions can emit gameplay noise events.

Audibility can depend on:
- distance,
- obstruction/rooms,
- ambient machinery/noise,
- NPC context/state.

This is not intended to become an acoustics simulation.

The same noise framework could later support:
- stealth,
- distractions,
- NPC investigation,
- machinery masking,
- creatures,
- environmental reactions.

The civic cycle can change stealth conditions:
- Working may be noisy but crowded,
- Gathering may reduce population at some locations,
- post-Ritual may have few witnesses but very little ambient noise.

This creates scenario tradeoffs without a separate stealth timer.

---

# 20. The Pulse, Time, and Commitments

## LOCKED

Conflicting commitments may happen naturally, but Krater should not become a calendar-optimization game.

Broad civic phases are usually enough:
- during Working,
- before Gathering,
- during Gathering,
- after Ritual.

NPCs should react to lateness and broken commitments contextually.

World state and commitment history can create believable truth/lie/deflect conversations.

---

# 21. Production District Identities

## LOCKED

The three current production districts are:

### Glowbeds

Biological cultivation.

Supports:
- food,
- recovery,
- luminous fungi,
- cultivation,
- biological capability,
- potentially biological sensing/medicine.

### Wickwork

Practical flexible fabrication.

Supports:
- tethers,
- harnesses,
- cables,
- bindings,
- Rig gear,
- field equipment,
- repairs,
- lamp housings,
- civic fabrication.

### Cistern

Water, pressure, hydraulics, and mechanical infrastructure.

Supports:
- water systems,
- pumps,
- pressure systems,
- lifts,
- hydraulics,
- drainage,
- powered equipment,
- major infrastructure.

## LOCKED

All three districts must matter to:
- ordinary Hollow life,
- exploration,
- infrastructure,
- player progression.

No district should exist only to feed one upgrade currency.

---

# 22. Cross-District Technology

## DIRECTION

Cross-district projects and technologies are desirable.

Examples:

- powered hauling = Wickwork cable/fabrication + Cistern pressure/mechanics;
- advanced biological light = Glowbeds strain + Wickwork housing;
- frontier rest station = Glowbeds recovery support + Wickwork construction + Cistern utilities.

These are examples, not fixed recipes.

---

# 23. District Development and Player Agency

## LOCKED

The player does **not** directly control districts like a city-builder.

Districts have their own:
- needs,
- ambitions,
- shortages,
- projects,
- priorities.

The player influences development primarily through:
- discoveries,
- Materials,
- Components,
- Records,
- work,
- deciding what to support,
- deciding what to share.

Minor/routine civic improvements can occur without player intervention.

The Hollow should not feel frozen until the protagonist clicks something.

Major advancements commonly require player involvement because the player can provide:
- hard-to-reach Material,
- rare Component,
- Record,
- new space,
- new access,
- cross-district coordination,
- significant production capacity.

## LOCKED — Project choice philosophy

Most district choices determine **development priority/order**, not permanent mutually exclusive branches.

Example:

Glowbeds might pursue better recovery first or luminous cultivation first, but this does not necessarily mean the other path is permanently lost.

Rare mutually exclusive outcomes can exist when justified by real narrative/material constraints.

## LOCKED — Knowledge ownership

Finding a Record does not automatically upload it to society.

The player may sometimes:
- share it,
- keep it,
- give it to a particular person/group,
- withhold it.

Not every Record needs a branching moral choice, but control of information can matter.

## LOCKED — District project structure

District projects can depend on a combination of:

**knowledge + physical resources + production capacity**

Knowledge determines what is possible.

Materials/Components provide requirements.

Production determines whether society can practically execute it.

---

# 24. District Production

## LOCKED — Prototype model

Each production district tracks:

- **District Capacity** — the production rate; how much the district can make per civic cycle. Grows only through lasting investment (equipment, workspace, techniques, Records, infrastructure, Materials/Components, projects, workforce).
- **Civic Demand**
- **District Output** — what's actually produced this cycle. Equal to District Capacity each cycle (see resolution order below); not its own independent lever.
- **District Reserves** — the banked buffer of surplus District Output, carried between cycles.
- **District Reserve Cap**
- **Unmet Demand / resulting district condition**

This is intentionally simple enough to implement and tune without simulating every individual good or resident.

## LOCKED — Civic-cycle resolution

District production resolves **once per full civic cycle**, rather than continuously per second.

The preferred resolution point is around the transition from **Ritual into the next Rousing**, though exact phase-transition implementation may be adjusted if needed.

Cycle resolution follows this order:

1. Produce District Output equal to current District Capacity.
2. District Output serves Civic Demand first.
3. Surplus District Output fills District Reserves up to the District Reserve Cap.
4. If District Output is below Demand, District Reserves cover the deficit.
5. If District Output plus District Reserves cannot meet Demand, the remainder becomes Unmet Demand and creates contextual shortage consequences.

The exact numeric scale is intentionally open.

## LOCKED — Capacity

Capacity increases primarily through lasting improvements such as:
- better equipment,
- improved workspace,
- new techniques,
- useful Records,
- infrastructure,
- important Materials/Components,
- district projects,
- workforce changes where appropriate.

Capacity improvements should visibly change the district/world when practical.

Temporary events may also reduce Capacity until addressed.

## LOCKED — Demand

Demand comes from understandable world conditions, not arbitrary level scaling.

Demand is built from named, explainable contributors such as:
- basic Hollow needs,
- population-level civic needs,
- infrastructure,
- frontier worksites,
- active construction,
- lift operation,
- repairs,
- expansion,
- major projects,
- damage/disruption.

Do not simulate exact per-NPC consumption unless later proven necessary.

Active civic projects may temporarily increase Demand.

Completed infrastructure may create a smaller ongoing maintenance Demand where appropriate.

---

# 25. District Storage, District Reserves, Orders, and Diversion

## LOCKED — District Reserves

District Reserves are a finite civic buffer.

Surplus District Output adds to District Reserves until the District Reserve Cap is reached.

When District Output is insufficient, District Reserves are consumed before a true shortage occurs.

There is no universal fixed “protected reserve” number that must always remain untouched.

Instead, district condition communicates how vulnerable the current balance is.

Stealing during comfortable times may not cause immediate hardship, but it removes the buffer the district may need later.

Therefore:

> surplus means lower immediate harm, not consequence-free theft.

## LOCKED — Full reserves

Full District Reserves do **not** mean additional District Output is worthless.

District Output beyond the abstract storage cap can represent:
- ordinary distribution,
- routine maintenance,
- replacement work,
- quality-of-life benefit,
- low-level civic upkeep.

This prevents the logic that anything above the visible cap is socially free to steal.

## LOCKED — Approved Gear Orders

Approved Gear Orders may require:
- Tallies,
- authorized stored District Output,
- Trust/access,
- district capability,
- other specific requirements where appropriate.

Ordering Approved Gear consumes the legitimate District Output required by the item.

Districts may refuse an otherwise affordable order when available output is needed for essential civic demand or important committed work.

This should be presented as a believable civic constraint rather than an arbitrary shop lock.

## LOCKED — Diversion

Common diversion/theft removes goods directly from a district's District Reserves and transfers them into concealed personal stolen-goods storage.

Stolen/diverted District Output can accumulate across cycles toward a Forbidden Gear build.

Diversion does **not** directly lower the district's underlying District Capacity.

Its civic harm comes from reducing the buffer society has available for later demand, projects, disruptions, or shortages.

## LOCKED — Anti-idle principle

Production should not encourage:
- standing AFK,
- sleeping repeatedly just to farm output,
- checking a meter every few minutes.

The player should normally have meaningful work, exploration, social activity, or preparation while civic production progresses.

---

# 26. District Condition, Shortages, and Projects

## LOCKED — Stability

Districts should normally remain stable without constant babysitting.

Krater is not a Tamagotchi economy.

The player should not have to constantly refill three district meters.

A district may remain healthy for many cycles.

## LOCKED — Shortage philosophy

If District Output plus District Reserves cannot satisfy Civic Demand, the remaining amount becomes Unmet Demand.

Shortages should create:
- contextual problems,
- priorities,
- world consequences,
- new decisions.

They should **not** create:
- generic `Happiness -10`,
- repetitive delivery chores,
- arbitrary maintenance taxes.

Examples:

Wickwork strain may delay:
- lift repair,
- cable replacement,
- expansion.

Glowbeds strain may reduce:
- recovery support,
- frontier comfort,
- replacement of fungal lighting.

Cistern strain may affect:
- lift operation,
- pressure infrastructure,
- drainage,
- powered systems.

## DIRECTION — Condition states

A small qualitative set should communicate district health.

Current examples:
- Comfortable
- Stable
- Strained
- Shortage
- Critical

An additional higher state such as Abundant may be used if it proves useful.

Exact names and thresholds remain tunable.

## LOCKED — Explainability

The player should be able to inspect meaningful causes of district demand/strain.

Example breakdown:
- basic Hollow needs,
- West expansion,
- lower worksite,
- lift maintenance,
- current major project.

World communication should come first; UI explains and confirms.

## LOCKED — Projects

Two useful project categories are:

### Capacity projects

Lasting district improvements that permanently improve production capability.

### Civic projects

World-facing projects such as lifts, frontier stations, utilities, and expansion work.

Civic projects can temporarily increase demand while being built and may create smaller continuing maintenance demand after completion.

Projects can require:

**knowledge + physical resources + production capacity**

The player influences and enables projects rather than directly running a city-builder construction menu.

## DIRECTION — Autonomous healthy-district improvement

Consistently healthy districts may occasionally produce small authored autonomous improvements such as repaired lamps, improved workspaces, additional storage, or routine civic upgrades.

These should be authored/state-driven world changes, not an automatic surplus-spending clicker loop.

---

# 27. District Production as Physical World

## LOCKED

District production/storage should have believable physical representation.

Examples:
- racks,
- prepared goods,
- carts,
- cultures,
- workshops,
- pressure supplies,
- storage chambers.

High stock/capacity should look different from a strained district.

The world communicates first; supporting UI confirms.

District improvements should visibly affect the Hollow where practical.

Examples:
- better workspaces,
- more equipment,
- repaired routes,
- additional lights,
- new lifts,
- new platforms,
- frontier utilities,
- established rest points.

---

# 28. Approved Gear

## LOCKED — Terminology

Use:

**Approved Gear** = category  
**Order** = acquisition action

Do **not** use “Requisition” as the player-facing umbrella term.

Approved Gear is normal society-sanctioned equipment.

The player orders Approved Gear through legitimate Hollow channels.

Typical cost structure:

**Tallies + authorized District Output**

Access/Trust may also matter.

Approved Gear is openly produced by Hollow districts/facilities.

Public progression roughly follows:

**work → Tallies → Order Approved Gear → improve capability**

---

# 29. Forbidden Gear

## LOCKED

Forbidden Gear provides unauthorized capabilities.

It is not merely “better gear with purple rarity.”

Forbidden technology often:
- modifies,
- repurposes,
- reinterprets,
- recombines

existing Approved Gear or ship technology.

Forbidden Gear commonly arises from:
- Records,
- unusual Components,
- restricted exploration,
- experimentation,
- reinterpretation of sanctioned technology.

## LOCKED — Cost philosophy

Forbidden Gear requires:

**stolen/diverted District Output + at least one additional non-Tally requirement**

The additional requirement may be:
- a Material,
- a Component,
- knowledge/Record,
- or a combination.

Not every Forbidden Gear design must require all of these simultaneously.

Forbidden Gear is privately built rather than ordered openly through a normal district.

Secret progression roughly follows:

**explore → discover/understand → recover Material/Component → steal/divert District Output → privately build Forbidden Gear**

---

# 30. Diversion and Theft

## LOCKED

The common forbidden-economy mechanic is **systemic diversion** of real District Output.

The player is not waiting for random rare upgrade items to spawn.

Districts continuously create useful civic output.

The player can secretly divert part of that output toward Forbidden Gear.

Mechanically, the game may abstract District Output into manageable units.

Fictionally, it represents:
- real goods,
- fabrication work,
- prepared biological products,
- pressure/mechanical supplies,
- workshop capacity,
- civic production.

## LOCKED — Storage areas

Diversion occurs through believable physical storage/output areas.

Examples:
- Wickwork racks/stores,
- Glowbeds prepared stock/cultures,
- Cistern supply/equipment areas.

Stealing should not be purely a menu button.

Schedules, sight, sound, access, Trust, and local conditions can matter.

## LOCKED — Two independent theft risks

Theft has two distinct consequence axes.

### Civic / economic harm

Can the Hollow afford what you took?

Production relative to demand determines how damaging the loss is.

### Social / detection risk

Did anyone see, hear, discover, or credibly connect the theft to you?

Being caught can damage Trust **regardless of surplus**.

## LOCKED

Undetected theft does not automatically lower Trust simply because the game knows the player did it.

Trust represents what society knows/believes.

Undetected theft can still:
- reduce reserves,
- delay projects,
- create shortage,
- cause visible world problems,
- trigger unexplained-loss investigation.

Repeated unexplained losses can increase:
- storage checks,
- Warden presence,
- local restrictions,
- investigation.

These can be authored/state-driven rather than a full detective simulator.

## DIRECTION — Physical stolen goods

Small diversions may be concealable/carried normally.

Large diversions may sometimes require physical hauling.

Do **not** make every theft a hauling mission.

## CUT

- Random special upgrade objects periodically spawning as the main theft mechanic.
- Treating surplus as morally/economically free.
- Universal abstract “steal production points” with no physical fiction.
- Siphon as the canonical player-facing theft/diversion term.

---

# 31. Personal / Secret Storage

## DIRECTION

The player's home/private area may hold:
- personal Materials,
- withheld Materials,
- diverted District Output,
- forbidden Components,
- Records not shared with society.

The home can therefore function as:
- preparation space,
- storage,
- Rig maintenance area,
- hidden progression space.

Authored situations may occasionally make hidden possession socially relevant.

Avoid random routine home searches as a punishment loop.

---

# 32. Pulse Binders

## LOCKED — Provenance

This section is **USER-locked** (2026-09-14). "Divine Binding" is the practice; "Pulse Binders" are its practitioners, replacing the earlier placeholder term "Magicians"/"magic" everywhere. Divine Binding is not a separate thing from the Hollow's religion — it *is* devotional practice: sacred, ritualized work with inherited colony technology, performed in the belief (sincere for some, performative for others) that it unites the practitioner with the Pulse and the technology's original purpose. There is no separate "folk magic" vocabulary running alongside doctrine; this is the vocabulary.

## LOCKED

Pulse Binders remain a major part of Krater.

They are **not** a fourth production district.

They are custodians/practitioners of inherited colony technology, named for their most sacred devotion — tending the Pulse — though Divine Binding as a practice extends to old salvaged technology broadly (lifts, lamps, pressure systems, Wickwork's machinery), not only the Pulse itself.

Their knowledge consists of real technical procedures preserved through:
- ritual,
- tradition,
- apprenticeship,
- incomplete understanding,
- institutional practice,
- possibly deliberate secrecy.

To ordinary Hollow residents, what they do genuinely reads as sacred, not as a trick — Divine Binding is understood as devotion, not performance, even by residents who privately doubt it.

## LOCKED — Role in technology

Pulse Binders may:
- maintain ancient systems,
- interpret Components,
- teach procedures,
- certify Approved Gear,
- reveal sanctioned uses,
- maintain/understand parts of the Pulse,
- preserve old technical rituals.

Approved technology often means:

> established/sanctioned procedure that society accepts.

Forbidden technology often comes from:

> understanding, modifying, repurposing, or recombining technology beyond accepted doctrine.

A Pulse Binder may know **how** a procedure works operationally without understanding **why**.

A Record may reveal why it works and expose new possibilities.

This directly connects Pulse Binders to the distinction between Approved and Forbidden technology.

The unsanctioned counterpart — practicing the same Divine Binding without Council sanction, including bio-fusion (§67) — is not a separate practice but a corruption of this one: the same devotional work, stolen rather than granted. It is named **Hellbinding** or **Voidbinding** (interchangeable), and its practitioners **Hell Binders** or **Void Binders** (interchangeable). See §67.

## LOCKED — Story potential

The eventual surface/ship revelations should not reduce the Pulse Binders to:

> “haha, your Binding was just technology.”

Different Pulse Binders can react differently.

Some may:
- resist,
- protect institutional authority,
- reinterpret tradition,
- accept the truth,
- become leading engineers/technicians.

Their inherited practical knowledge can remain genuinely valuable even when its historical explanation changes.

---

# 33. Rig

## LOCKED

The player uses one evolving **Rig** throughout the game.

The Rig is the player's work/exploration platform:
- harness,
- digging system,
- light,
- hauling/tether equipment,
- protection,
- specialized attachments,
- later ship-derived technology.

The player should not constantly replace the entire Rig with RPG loot tiers.

Basic:
- movement,
- digging,
- light,
- tether

cannot be accidentally unequipped or permanently missed.

---

# 34. Core Improvements and Gear

## LOCKED

Rig progression separates:

### Core Improvements

Foundational permanent improvements.

These improve dependable baseline capability and generally do not consume a configurable Gear slot.

### Gear

Swappable build-defining equipment.

Gear creates meaningful expedition choices.

## LOCKED

Major Rig changes happen at believable locations:
- home,
- private workbench,
- Wickwork/approved facility,
- other proper stations.

Do not allow complete build reconstruction from the pause menu in the middle of a cave.

---

# 35. Rig Capacity and Rig Strain

## LOCKED — Terminology

Use:

**Rig Capacity** — what the Rig comfortably supports.

**Rig Strain** — the physical consequence of exceeding it.

Do not use **Rig Load** as the canonical term.

## LOCKED — Soft capacity

Rig Capacity is a **soft limit**, not a normal hard equip cap.

The player may intentionally equip Gear beyond capacity.

Going over capacity creates Rig Strain.

Rig Strain blocks part of the player's fixed stamina bar.

Greater overcapacity creates greater strain.

The hauling block and Rig Strain are separate stamina-blocking sources.

Improving the underlying Rig can increase Rig Capacity, allowing previously strenuous builds to operate comfortably.

A generous absolute technical limit may eventually exist, but normal build decisions should happen around the soft capacity threshold.

## OPEN

Exact:
- capacity values,
- strain formula,
- threshold behavior,
- absolute limit.

---

# 36. Rig Gear Structure

## LOCKED — Slots vs Capacity

**Gear slot count and Rig Capacity are separate progression systems.**

Gear slots determine how many configurable Gear pieces can be mounted.

Rig Capacity determines how much combined equipment the Rig can comfortably support before Rig Strain begins.

Capacity growth, rather than endlessly adding more slots, is the main way the Rig becomes able to support stronger combinations comfortably.

## DIRECTION — Slot progression

Current target through Act 1 is approximately:

**3 → 4 → 5 configurable Gear slots**

A later sixth/Flex slot may become appropriate, especially after Act 1 or on the surface.

These numbers are intentionally **slightly tunable through prototyping**. The design is locked; the exact counts are not sacred.

Avoid expanding to a large 8-slot Act 1 loadout unless testing demonstrates a clear need, because too many simultaneous qualitative Gear effects would weaken specialization.

## DIRECTION — Rig Capacity progression

Rig Capacity should grow more aggressively than slot count.

A rough Act 1 shape is approximately:

**3 → 5 → 8 Capacity**

with further growth later.

Exact values remain tuning targets.

Going over Capacity remains legal and creates Rig Strain, which blocks stamina.

## DIRECTION — Functional categories

Functional Gear categories currently lean toward:
- **Tool**
- **Rig**
- **Utility**

Exact hard category restrictions are not yet locked.

A possible later Flex mount may accept multiple categories.

## DIRECTION — Refit quality of life

Potential later quality-of-life:
- saved loadout presets,
- player-created preset names,
- quick refit at proper workbenches.

Some Forbidden Gear may be visibly suspicious.

Smaller modifications may be concealable.

Large obvious forbidden attachments may create social/logistical issues.

Use this sparingly so every expedition does not become a smuggling chore.

---

# 37. Build Philosophy

## LOCKED

Builds should emerge from combinations of Gear and Core Improvements.

There are no permanent character classes.

The player should be able to combine different approaches.

Strong Gear effects should be qualitative.

Good examples:
- reveal cavities,
- reduce the hauling stamina block,
- change light shape,
- suppress excavation noise,
- penetrate a new class of terrain.

Avoid an upgrade ecosystem dominated by:
- +12% digging,
- +8% stealth,
- +15% yield.

---

# 38. Five Playstyle Dimensions

## LOCKED DIRECTION

Krater currently uses five major overlapping playstyle dimensions:

### 1. Excavation

Fantasy:

> I can make difficult geology practical.

Potential capabilities:
- hard-material excavation,
- efficient sustained digging,
- precision extraction,
- restricted/dense-material penetration.

Likely tradeoffs:
- Rig Capacity,
- noise,
- stamina.

### 2. Survey

Fantasy:

> I know where to dig.

Potential capabilities:
- identify deposits,
- read geology,
- detect cavities,
- locate water/pressure clues,
- identify ship structures,
- understand hidden routes.

Survey players may dig less but dig smarter.

### 3. Hauling / Endurance

Fantasy:

> I can stay out longer and bring more back.

Potential capabilities:
- reduced hauling stamina block,
- better tether handling,
- better fatigue management,
- better use of rest/logistics,
- powered hauling later.

Avoid simply giving “+50 stamina.”

### 4. Mobility

Fantasy:

> The terrain does not dictate my route.

Potential capabilities:
- climbing,
- tether traversal,
- controlled descent,
- grappling,
- alternate access,
- powered ascent later.

Mobility can also reduce the friction of returning for civic obligations.

### 5. Secrecy

Fantasy:

> I can do forbidden things with less evidence.

Potential capabilities:
- quieter excavation,
- controlled light,
- less debris/evidence,
- access manipulation,
- observation,
- exploiting routines/noise cover.

Secrecy should never collapse into a generic stealth percentage.

## LOCKED

These are:
- playstyle dimensions,
- not named classes,
- not isolated skill trees.

Players can combine them freely within Gear/Rig Capacity constraints.

Each dimension can include both Approved and Forbidden technology.

Major story/progression obstacles should support multiple approaches so no one dimension becomes mandatory.

Example:

A restricted upper barrier might be addressed through:
- better excavation,
- finding a weakness via Survey,
- alternate access via Mobility,
- safer timing/location via Secrecy,
- sustaining a longer remote route via Hauling/Endurance.

---

# 39. Approved vs Forbidden Across Builds

## LOCKED

Approved does **not** map to one set of playstyles while Forbidden maps to another.

Every dimension can contain legitimate and forbidden technology.

Example:

Survey:
- Approved geological survey equipment,
- Forbidden ship-derived structural sensing.

Excavation:
- Approved civic excavation tool,
- Forbidden pressure override.

Forbidden Gear can modify Approved Gear.

This keeps the equipment roster coherent and makes forbidden progression feel like reinterpretation rather than a parallel purple loot tree.

---

# 40. Discovered Capability Web

## LOCKED

Krater does not use a fully visible conventional tech tree.

It uses a **discovered capability web**.

Technology can progress through:

### Known

The player has a reason to know the technology/capability exists.

### Understood

The player has enough Record/knowledge/context to understand it.

### Available

The player also has the required:
- access,
- district capability,
- Material,
- Component,
- Tallies,
- or other conditions

to order/build it.

## LOCKED

The player should not see completely unknown technology without an in-world reason.

Do not display a screen with forty greyed-out mystery upgrades at the start.

Partial unknown leads appear only after meaningful evidence.

Examples:
- strange Component,
- Record fragment,
- Pulse Binder mention,
- observed old system,
- restricted mechanism.

---

# 41. Steering Build Progression

## LOCKED

Discovery can surprise the player, but build progression must remain **steerable**, not random.

If the player wants more Survey progression, the world should provide meaningful leads:
- district projects,
- Pulse Binder knowledge,
- locations,
- Materials,
- Components,
- Records,
- clues.

The player can intentionally pursue a direction.

Technology belongs to overlapping functional families such as:
- Excavation,
- Survey,
- Hauling,
- Mobility,
- Light,
- Secrecy,
- Rig Core.

Do not force technologies into mutually exclusive tree branches if they naturally serve multiple roles.

---

# 42. Gear / Technology Interface

## DIRECTION

At home/workbench, major information surfaces may be:

- **Gear**
- **Approved Gear**
- **Forbidden Designs**
- **Discoveries**

An entry should explain:
- what it does,
- what is missing,
- whether it is Approved or Forbidden,
- what resource/capability is needed.

Unknown possibilities may appear partially only after evidence exists.

The private Forbidden workspace itself remains to be designed.

---

# 43. Glowbeds — Detailed Identity

## LOCKED

Glowbeds is more than the “food district.”

It represents biological cultivation and underground biological expertise.

Its productive role can include:
- food,
- useful fungal cultures,
- luminous fungi,
- recovery support,
- medicinal/biological applications,
- biological substrates,
- frontier cultivation.

High Glowbeds capacity can visibly support:
- healthier cultivation,
- better lighting,
- better frontier support,
- better recovery infrastructure.

Low Glowbeds capacity should create contextual strain rather than a hunger meter.

## DIRECTION

Potential player-facing capabilities:
- better rest/recovery,
- portable biological support,
- fungal lighting,
- frontier cultivation,
- biological sensing/reactive strains.

Exact upgrade projects remain open.

---

# 44. Wickwork — Detailed Identity

## LOCKED

Wickwork is practical/flexible fabrication.

It is not merely a blacksmith.

It supports:
- cable,
- bindings,
- harnesses,
- seals,
- lamp housings,
- protective layers,
- tether equipment,
- Rig equipment,
- work gear,
- civic repair.

Wickwork should be strongly relevant to:
- Approved Gear,
- Rig customization,
- hauling,
- mobility,
- Hollow infrastructure.

When strained, the world can show:
- patched equipment,
- worn tethers,
- delayed repairs,
- limited expansion.

## DIRECTION

Wickwork may become the first district where systemic diversion/theft is clearly taught because its stored fabricated output is understandable and valuable.

---

# 45. Cistern — Detailed Identity

## LOCKED

Cistern is more than water storage.

It represents:
- water,
- pressure,
- hydraulics,
- pumps,
- fluid systems,
- mechanical power,
- lifts,
- drainage,
- heavy infrastructure.

Its technological tradition grows naturally from generations maintaining ship-derived fluid/pressure systems.

## LOCKED — Water source (USER, 2026-09-14)

Cistern's water is drawn from below, not above: Heavenfall's flood drained downward over generations through fractures and cavities, pooling at the bottom of the Devil's Mouth and submerging part of the wreck there. Cistern's supply is siphoned up from that pool, not a slow surface seep — giving the district's water a direct, discoverable origin in the Hollow's founding disaster rather than an unexplained utility.

## DIRECTION — Endgame Cistern arc

A sufficiently developed Cistern is the plausible mechanism for eventually draining the Devil's Mouth and exposing the wreck at its bottom (§51, game-pitch.md Act 3's "bottom of the Devil's Mouth"). This is not mechanically specified — exact capacity, infrastructure, and timing remain open, Act 3 content — but the throughline is locked: Cistern's Act 1–2 development is not incidental infrastructure, it is the thing that eventually makes the true bottom reachable.

Cistern improvements can produce large physical world changes such as:
- repaired lifts,
- powered hauling,
- pressure tools,
- drainage access,
- hydraulic traversal,
- frontier utilities.

Cistern should distinguish itself from Wickwork by being more about **infrastructure and mechanical power** than personal fabrication.

---

# 46. Public Progression vs Secret Progression

## LOCKED

The two main progression paths intentionally feel different while using the same underlying world economy.

### Public / Approved

**work → Tallies → Order Approved Gear using Tallies + authorized District Output**

Potentially also requires:
- Trust,
- access,
- district capability,
- specific Materials.

### Secret / Forbidden

**explore → discover/understand → recover Material/Component → steal/divert District Output → privately build Forbidden Gear**

This shared economy is intentional.

Forbidden progression should not use a separate arbitrary “dark currency.”

---

# 47. Private Forbidden Workspace

## LOCKED — Role and unlock

Forbidden Gear is built through a private/hidden workspace rather than a public district counter.

The workspace becomes available when the player obtains or understands their first meaningful **Forbidden Design**, creating a practical need to fabricate something that cannot be built openly.

The workspace is a physical representation of secret progression.

It can:
- support private fabrication,
- store diverted District Output,
- store illicit Components/Records,
- conceal suspicious Gear,
- improve alongside the player's housing.

The player does **not** begin the game with a fully developed forbidden workshop.

## LOCKED — Residential relationship

The forbidden workspace evolves alongside residential progression:

**Lower Hollow home → Mid Reach residence → Ashram Heights residence**

The starting/lower home supports a crude concealed workspace once forbidden progression begins.

The Mid Reach residence provides a meaningful improvement in privacy, storage, legitimate Rig preparation, and secret-workspace capability.

The Ashram Heights residence becomes the strongest late-Act-1 private base and provides sustained access immediately beneath the Firmament.

## LOCKED — Construction timing

Forbidden construction does not use real-time/mobile-style crafting timers.

Small modifications may be effectively immediate at the proper workspace.

Major illegal fabrication may consume meaningful civic time.

Exact build-time rules remain tuning.

## LOCKED — Concealed storage

Diverted District Output can accumulate in concealed storage across cycles until enough exists for a Forbidden build.

Larger or more incriminating stockpiles create stronger evidence if discovered.

Exact storage capacities remain open.

## LOCKED — Discovery philosophy

The hidden workspace is safe by default.

There are no random recurring home-raid/search rolls.

Discovery requires believable:
- evidence,
- suspicion,
- access,
- investigation,
- or authored story circumstances.

Most serious exposure situations should provide understandable warning and an opportunity to respond.

Concealment is qualitative/state-based rather than a percentage modifier.

What investigators actually find determines the severity of consequences.

Workspace discovery creates serious social/story consequences, not an automatic game over.

See Section 62 for the detailed residential, concealment, and Ashram/Firmament rules.

---

# 48. Pulse Binders and the Capability Web

## LOCKED

Pulse Binders are major sources/interpreters of **Known** and **Approved** technology.

They may know:
- operating procedures,
- maintenance rituals,
- approved technical uses,
- old terminology.

Records can reinterpret their knowledge.

Example conceptual pattern:

> Pulse Binder: “This regulator is only for the Pulse.”  
> Record: reveals it is actually a general pressure-control component.  
> Player: realizes it can support another forbidden application.

This is a central story/mechanics connection.

---

# 49. Surface Continuity

## LOCKED

Core Act 1 systems should **transform into** the second half of the game rather than being discarded after the Firmament breach.

The surface should feel like an expansion of systems the player already understands.

### Hollow → Surface continuity

- digging/exploration → surface exploration/salvage
- Materials → new surface Materials
- Components → more advanced colony/ship Components
- Records → more complete technical knowledge
- hauling → cargo/logistics
- district projects → settlement projects
- production capacity → settlement production
- civic demand → settlement/colony demand
- Approved Gear → legitimate settlement technology
- diversion/theft → resource politics and competing priorities
- Trust → leadership/social relationships
- jobs → settlement work, expeditions, major projects
- Rig builds → advanced exploration/salvage builds
- Hollow infrastructure → surface infrastructure
- Pulse Binders → technicians/engineers and/or ideological conflict

## LOCKED — District tradition continuity

Glowbeds can evolve toward:
- agriculture,
- biology,
- ecology,
- food/recovery systems.

Wickwork can evolve toward:
- manufacturing,
- construction,
- fabrication.

Cistern can evolve toward:
- water systems,
- pressure systems,
- mechanical infrastructure,
- broader utility/power integration.

These traditions survive the transition to the surface.

Their Act 1 development can influence what they are capable of later.

---

# 50. Shipbuilding Continuity

## LOCKED

Shipbuilding should use the same broad progression architecture at a larger scale.

Do not introduce a disconnected “shipbuilding minigame economy.”

The player has already learned the logic through:
- Hollow projects,
- Materials,
- Components,
- Records,
- district capability,
- production,
- infrastructure.

Scale progression conceptually:

early Act 1:
> repair a lift

later Act 1:
> expand a district

surface:
> establish agriculture, water, manufacturing, logistics

late game:
> manufacture/restore major ship systems

Shipbuilding can require combinations of:

**Materials + Components + knowledge + production capacity + infrastructure**

Exact later-game steps remain open.

---

# 51. Devil's Mouth

## LOCKED

Devil's Mouth remains:
- a huge central crater,
- a visual/lore anchor,
- a future mystery.

It is **not** the ordinary public mining route.

In Act 1:
- public work is primarily lateral civic excavation,
- secret investigation trends upward toward the Firmament.

True deep descent belongs later.

---

# 52. Opening-Route World Structure

## STRONG DIRECTION

The current opening-route structure is a good foundation and should not be restarted casually.

Current route:

1. Home Court
2. Lower Switchback
3. West Dispatch Yard
4. Bottom-West Approach
5. Bottom-West Threshold
6. First Expansion Gallery
7. optional Collapsed Side Chamber
8. Lower Lift Landing
9. onward toward West Exchange / Mid Heart

The first trip moves west/outward away from Devil's Mouth.

The route should feel lived in and horizontally traversable, not like isolated ladder rooms.

No normal camera frame should reveal the whole Hollow.

The first Mid Heart arrival should be a slice of the Heart, not the entire settlement in one screen.

---

# 53. Living Hollow

## LOCKED

The Hollow must feel like a real society.

Ordinary NPCs should:
- work,
- rest,
- talk,
- move,
- use infrastructure,
- gather,
- react to district state.

NPC relationships should remain **lightweight**.

Krater is not trying to become Stardew Valley.

The important goal is:
- social texture,
- believable familiarity,
- contextual consequences,
- meaningful recurring people.

---

# 54. Failure and Recovery

## LOCKED — Overall philosophy

Krater does **not** use permadeath or full expedition resets as its normal failure model.

Failure should usually continue the world/story in a changed state rather than encourage immediate reloads.

At the same time, major overextension must have meaningful consequences. The player should not be able to repeatedly ignore stamina, fatigue, civic time, social obligations, or safety with no downside.

## LOCKED — Graduated severity

Failure is graduated rather than binary.

A useful conceptual ladder is:

### Strained

The player is under pressure but remains fully capable of choosing a safer response.

They may:
- turn back,
- cache Materials,
- abandon optional goals,
- take a safer route,
- use available rest infrastructure.

### Exhausted

The player has overextended enough that strenuous actions are no longer available until proper recovery.

They can usually still:
- walk,
- interact,
- use basic non-strenuous actions,
- attempt a slow return,
- seek help.

### Stranded / critical situation

Some believable physical situations can remove the quiet-retreat option.

Examples:
- collapse isolates the player,
- flooding blocks the return route,
- necessary traversal can no longer be performed while exhausted,
- critical equipment needed for escape is disabled,
- the player is physically trapped.

In these situations, rescue or another serious contextual outcome may become mandatory.

Exact state names are tunable.

## LOCKED — Quiet return vs rescue

When rescue is optional, avoiding it can preserve secrecy but is **not free**.

A difficult self-return can cost:
- civic time,
- Ritual attendance,
- accepted commitments,
- recovery,
- abandoned haul,
- additional fatigue,
- social reliability.

Missing Ritual or commitments due to voluntary overextension can affect Trust/context when appropriate.

## LOCKED — Forced rescue

Rescue may be mandatory in sufficiently severe believable situations.

Forced rescue is not a random punishment.

Who finds/rescues the player and what they encounter can matter.

Rescue can expose:
- forbidden location,
- suspicious Gear,
- stolen/diverted output,
- illegal excavation,
- other physical evidence.

Being rescued from ordinary civic work may be mostly embarrassing or inconvenient.

Being rescued from restricted Firmament excavation may be socially disastrous.

## LOCKED — Lost time

Severe failure or rescue may advance a substantial amount of civic time.

This can cause:
- missed Ritual,
- missed deadlines,
- failed commitments,
- changed world state,
- NPC concern/questions.

Lost time is itself a meaningful consequence.

## LOCKED — Resource risk

Stored and properly cached resources are generally safe.

Bulk Materials currently being hauled may need to be abandoned, cached, or recovered later after failure.

Ordinary failure should not routinely delete important Components or Records.

## LOCKED — Gear

Krater does not use a general-purpose durability maintenance system.

Specific severe events may temporarily disable or damage a Gear item until repaired.

This should be contextual and occasional rather than constant wear-and-tear bookkeeping.

## LOCKED — Telegraphing

The game should clearly communicate when the player is approaching a severe overextension/stranding risk.

Potential signals include:
- heavily blocked stamina,
- exhausted animation,
- breathing/exertion audio,
- poor recovery,
- warnings when attempting to Overexert again.

Major consequences should generally feel earned rather than surprising.

## CUT

- permadeath as the default failure loop,
- automatic full-expedition resets,
- consequence-free repeated Overexertion,
- instant arbitrary rescue teleports with no contextual meaning,
- random injury tables,
- routine deletion of important Records/Components.

---

# 55. UI / Invisible Interface Principle

## LOCKED

The world should communicate mechanics first.

HUD/UI should support understanding rather than replace environmental communication.

Examples:

District strain:
- empty racks,
- patched equipment,
- delayed repairs,
- NPC dialogue,
then UI confirms the reason.

Civic phase:
- Pulse,
- sound,
- movement,
- lights,
then UI confirms the phase.

Resource clues:
- moisture,
- staining,
- fungal traces,
then Survey capability clarifies.

Trust:
- NPC behavior and access,
then Trust view explains the important reasons.

---

# 56. PixelLab / Art-State Principle

## LOCKED

Stateful environment systems should be designed for modular art production.

Prefer:
- reusable base tiles,
- overlays,
- intact/depleted deposits,
- support modules,
- infrastructure modules,
- worksite modules,
- fungal modules,
- storage-state variants.

Avoid requiring AI art generation for every possible full-room state.

This applies to:
- deposit depletion,
- district improvement,
- frontier establishment,
- infrastructure repair,
- worksite development.

---

# 57. Explicitly Non-Canon Legacy Details

The following older/prototype details do **not** define the game unless explicitly reconfirmed later.

## NON-CANON

- exact production formulas;
- exact demand formulas;
- exact reserve formulas;
- exact storage capacities;
- exact Material yields;
- exact stamina numbers;
- exact Tally prices;
- exact risk percentages;
- exact theft formulas;
- exact witness-risk ladders;
- exact Shortage Risk formulas;
- fixed `reserve = 1`;
- fixed `capacity = 6`;
- exact 70/30 shortage behavior;
- exact five-stage witness-risk states;
- exact 60-second Harvest timer;
- exact named district-output pairs;
- exact old Material roster as immutable canon;
- Salvage as the canonical player economy;
- Siphon as the canonical theft/diversion action;
- current prototype shops as design canon;
- conventional fully visible tech tree;
- linear gear tier progression;
- permanent named classes;
- generic stealth-success percentages;
- generic lie-success percentages;
- fixed three-mount Rig;
- hard Rig Capacity equip bans;
- Rig Load as canonical terminology;
- Contribution as a required social currency.

Older implementation names may remain temporarily in code only when clearly treated as transitional.

---

# 58. CUT / Avoid

## CUT

- Every rock dropping collectible resources.
- Huge crafting-resource bloat.
- One Material per district.
- Hunger/thirst survival simulation.
- Constant district babysitting.
- Idle-game per-second production as the visible core.
- AFK farming.
- Sleep-spam as optimal production farming.
- Universal global Suspicion meter.
- Stealth as a percentage stat.
- Lying as a percentage roll.
- Random rare theft-item spawning as the main Forbidden Gear economy.
- Surplus theft being consequence-free.
- Fully realistic rope simulation as a requirement.
- Designing every level path separately for loaded/unloaded states.
- Permanent character classes.
- One mandatory “story build.”
- Full city-builder control over district decisions.
- Permanent mutually exclusive district branches as the normal model.
- Random injury complexity.
- Generic morality meter.
- Pulse Binders being discarded once technology is revealed.

---

# 59. Remaining OPEN Questions After Mechanics Freeze

The vertical-slice mechanics are now sufficiently defined to move into the **Build Bible**.

Remaining OPEN items are primarily tuning, implementation, presentation detail, or later-game design. Future AI work must not silently promote these into canon.

## Rig tuning
- exact slot counts after playtesting,
- exact Capacity values,
- Rig Strain formula,
- exact Tool/Rig/Utility category restrictions,
- whether/when a sixth or Flex slot appears.

## Materials and extraction tuning
- exact yields,
- extraction costs,
- deposit frequency,
- pocket-generation parameters.

## District economy tuning
- exact numeric scale,
- qualitative condition-state thresholds/names,
- District Reserves Caps,
- exact project/order costs,
- exact maintenance values.

## Trust
- final names for standing states,
- exact internal thresholds,
- final visual layout.

## Pulse / Ritual
- original ship function,
- exact phase names,
- timings,
- exact Ritual practices,
- possible quiet post-Ritual period.

## Workspace / housing tuning
- exact concealed-storage capacities,
- final concealment tier names,
- exact fabrication time costs,
- exact housing acquisition requirements.

## Mining implementation
- exact Godot TileMap/chunk/destructible-terrain architecture,
- procedural seed rules,
- authored-vs-variable pocket ratios,
- persistence/save representation.

## Failure tuning
- exact exhaustion thresholds,
- rescue time costs,
- contextual Gear damage rules,
- exact world/social consequences for specific hazards.

## Later game
- exact surface settlement structure,
- shipbuilding milestones,
- later Materials,
- final role of Devil's Mouth.

---

# 60. Design Test for Future Mechanics

Before adding a new mechanic, ask:

1. Does it connect to the existing world rather than create a parallel minigame?
2. Does it create a meaningful decision rather than another meter?
3. Can the player understand it through the world?
4. Does it interact with more than one existing system?
5. Does it preserve player freedom rather than force one build?
6. Does it avoid unnecessary repetitive maintenance?
7. Can the Hollow visibly respond to it?
8. Can it plausibly evolve into surface/settlement/shipbuilding gameplay?
9. Is it genuinely USER-decided, or did AI invent it to fill a gap?
10. If it is not decided, is it clearly marked OPEN instead of silently promoted to canon?

---

# 61. Current Canon Summary

Krater is a systemically connected game in which:

- the Hollow is a real society rather than a hub menu;
- jobs teach the game through believable civic participation;
- the civic cycle and Ritual create social rhythm without turning play into constant schedule anxiety;
- the society's cult-like/religious undertone shapes Ritual, doctrine, legitimacy, access, Pulse Binders, taboo, and social expectations without becoming a separate Faith meter;
- digging creates persistent player-made routes and reveals meaningful pockets rather than showering generic loot;
- the world uses authored settlement/story geography with Terraria-like local digging freedom inside controlled excavation zones;
- extraction/hauling borrows some of Dome Keeper's physical satisfaction while remaining part of a persistent world rather than a run-reset mine;
- Sutral, Ravelstone, Brinecrystal, Verdigris, and Hullbit form the locked Act 1 bulk Material roster;
- Materials, Components, and Records have distinct roles;
- hauling, Rig Strain, stamina, fatigue, Overexertion, rescue, and civic time create real expedition consequences;
- failure usually continues the world rather than resetting it, but severe overextension can force rescue and social/time consequences;
- districts produce useful civic output once per civic cycle through Capacity, Demand, finite District Reserves, and contextual shortages;
- district development is influenced rather than directly commanded;
- Tallies support legitimate progression;
- Trust is qualitative social standing with explainable causes rather than a visible numeric morality bar;
- suspicion/investigation remains local and evidence-driven;
- theft/diversion has both economic and social consequences;
- Approved Gear is ordered openly using Tallies and legitimate District Output;
- Forbidden Gear is privately built from stolen output plus discoveries/resources;
- the Rig uses separate Gear-slot and Rig-Capacity progression, with roughly 3→4→5 slots and stronger Capacity growth through Act 1 as tunable targets;
- Gear changes capabilities, information, routes, logistics, or risk rather than mainly adding percentages;
- the five overlapping build dimensions are Excavation, Survey, Hauling/Endurance, Mobility, and Secrecy;
- technology is discovered through a Known → Understood → Available capability web rather than fully exposed from the start;
- Pulse Binders preserve inherited real technology through ritualized/incomplete understanding, practicing what the Hollow calls Divine Binding;
- the Pulse anchors time, culture, and infrastructure;
- the hidden Forbidden workspace develops through residential progression;
- Mid Reach housing is a meaningful intermediate status/mechanical milestone;
- Ashram Heights is a major late-Act-1 aspiration because it combines legitimate status with private sustained access beneath the Firmament;
- the Firmament is thick, difficult, and requires sustained secret excavation rather than a single breakable barrier;
- legitimate social advancement enabling deeper forbidden activity is an intentional thematic contradiction;
- Act 1 systems are intended to evolve naturally into surface settlement and eventual shipbuilding.

Future AI work must treat this document as canon and must not silently restore older prototype mechanics or invent exact values for OPEN systems.

---

# 62. Residential Progression, Hidden Workspace Security, and Ashram Heights Firmament Access

## LOCKED — Residential progression

The player's residential progression includes a meaningful **Mid Reach home before Ashram Heights**.

The Mid Reach residence is an intermediate social and mechanical milestone. It should expand:
- privacy,
- personal storage,
- legitimate Rig preparation capability,
- secret storage/workspace capability,
- the player's sense of civic advancement.

Ashram Heights comes later, at the very top of the Hollow beneath the Firmament.

## LOCKED DIRECTION — Ashram Heights as a long-term goal

Owning a residence in **Ashram Heights** is a major late-Act-1 aspiration with both legitimate and secret value.

The game can foreshadow well in advance that living there would place the player directly beneath the Firmament and therefore create a unique opportunity for sustained private upward excavation.

The Ashram Heights house should be able to function as a primary or secondary long-term goal throughout Act 1, not merely as a surprise convenience discovered at the end.

Legitimate progression such as:
- Trust,
- Tallies,
- status,
- access,
- story progression

can help the player qualify for or obtain the residence.

This creates an important design contradiction:

> **legitimate social advancement creates the privacy and access needed for deeper forbidden activity.**

## LOCKED — The Firmament at Ashram Heights

At Ashram Heights, the Firmament is effectively the player's ceiling / immediately above the residence.

This does **not** mean the player can mine through it quickly.

The Firmament is:
- very thick,
- exceptionally hard,
- difficult to excavate,
- a sustained multi-session problem rather than a one-block barrier.

Breaching it may require:
- specialized Forbidden Gear,
- repeated excavation sessions,
- careful stamina/fatigue management,
- debris handling,
- noise management,
- concealment,
- Survey information about where/how to dig.

The house provides **access and cover**, not automatic safety.

## LOCKED — Firmament excavation risk

Upward excavation from Ashram Heights reuses the existing detection/evidence/noise systems.

Risk can come from:
- excavation noise,
- repeated sound through walls/ceilings,
- visible dust/debris,
- structural evidence,
- suspicious Rig modifications,
- suspicious movement/behavior,
- witnesses,
- local investigation.

Do **not** create a separate Firmament stealth meter.

## DIRECTION — Ashram Heights house upgrades

House improvements should be functional rather than decorative-only.

Potential secrecy/workshop improvements include:
- sound dampening,
- concealed storage,
- debris concealment/handling,
- stronger private workbench capability,
- hidden ceiling access,
- reinforced mounting/support,
- better workshop ventilation/power,
- concealment for suspicious Gear.

Exact upgrade list remains open.

## LOCKED — Hidden workspace security philosophy

The hidden workspace is **safe by default**.

It is not subject to random recurring home-search rolls.

Workspace discovery should only become possible when believable world state, evidence, suspicion, access, or story circumstances create a reason for someone to investigate or enter the residence.

Examples of triggers can include:
- the player being seen carrying stolen output home,
- someone following the player,
- repeated unexplained district losses,
- obvious Forbidden Gear being seen,
- evidence connecting the player to a restricted area,
- a story event that legitimately brings someone into the home,
- Wardens having a specific reason to search.

## LOCKED — Fair warning and response

Most situations that could expose the hidden workspace should provide understandable warning first.

Possible warning channels include:
- NPC dialogue,
- Warden activity,
- notices/checks in the district,
- signs that someone has entered or inspected the area,
- investigation-related Trust/suspicion information,
- a known upcoming visit or maintenance event.

The player should have an opportunity to respond by:
- moving incriminating goods,
- concealing them better,
- consuming stolen output in a build,
- relocating goods to a frontier cache,
- cleaning physical evidence,
- hiding suspicious Gear,
- preparing a lie/deflection if questioned,
- accepting the risk.

This should be an occasional meaningful problem, not a repetitive housekeeping chore.

## LOCKED — Concealment is state-based, not percentage-based

Concealment changes **what kind of access/search is sufficient to expose the workspace**.

Avoid designs such as:

> Hidden Compartment: -35% discovery chance

A better model is qualitative:

### Basic concealment
- safe from ordinary visitors,
- safe from casual maintenance,
- vulnerable to a deliberate search.

### Improved concealment
- survives a normal deliberate search,
- vulnerable to a targeted search backed by evidence.

### Advanced concealment
- requires very specific knowledge/evidence to expose.

Exact tiers/names remain open.

## DIRECTION — Secrecy progression at home

Secrecy progression may improve:
- concealed storage,
- hidden Rig mounts,
- quiet private fabrication,
- false compartments,
- transport concealment,
- separation of incriminating goods.

These should be qualitative capabilities rather than stealth percentages.

## LOCKED — Discovery consequences

Finding the hidden workspace is a serious social/story consequence, **not an automatic game over**.

Possible consequences may include:
- Trust loss,
- local restrictions,
- confiscation of some illicit goods,
- Pulse Binder/Warden confrontation,
- forced explanation/lie/deflection,
- loss of access,
- a story branch,
- relocation or rebuilding of secret work.

What investigators actually find matters.

An empty concealed bench is suspicious.

A concealed bench containing stolen Cistern goods, a forbidden Component, and an illegal pressure-bore modification is much stronger evidence.

Finding the workspace does not automatically prove every crime the player has ever committed.

## LOCKED / DIRECTION — Accumulating stolen output

Stolen/diverted District Output can be accumulated over time in preparation for a future Forbidden Gear build.

This is desirable because it creates anticipation and makes repeated theft part of a larger secret project.

At the same time, larger private stockpiles create more incriminating material that may need to be protected if an investigation becomes credible.

Exact private storage capacity remains open.

---

# 63. Hybrid World Structure and Digging Model

## LOCKED

Krater uses a **hybrid authored + destructible world structure**.

Major settlement geography, districts, homes, lifts, civic routes, Mid Heart, Ashram Heights, story spaces, and critical progression anchors are intentionally authored.

Between and around those authored anchors are controlled excavation/frontier regions where the player has genuine freedom to carve persistent routes through destructible terrain.

The design target is:

> **Terraria-like local digging freedom + Dome Keeper-like physical extraction/hauling + Krater's authored persistent civic world layered on top.**

## LOCKED — Persistence

Player excavation persists.

The world can remember:
- dug tunnels,
- depleted deposits,
- exposed cavities,
- forbidden holes,
- major worksite changes.

Established structures should not be universally destructible.

Terrain can conceptually include:
- established/fixed civic structure,
- workable excavation terrain,
- reinforced/restricted structure,
- ship structure,
- Firmament.

Different categories may require different capabilities and rules.

## LOCKED — Authored narrative anchors

Major narrative discoveries, critical Records/Components, important hidden rooms, Firmament progression, and progression-critical ship spaces should not depend on random generation.

Procedural variation supports exploration; it does not determine whether the player can find required story content.

## DIRECTION — Controlled variation

Within authored excavation volumes, controlled procedural/seeded variation may determine:
- pocket shape,
- minor cavity placement,
- some Material distribution,
- weak seams,
- local geology.

Authored environmental logic still constrains what can appear.

Geology should strongly influence practical route choice even when multiple digging paths exist.

## LOCKED — Job compatibility

Civic excavation jobs may specify the worksite/goal without dictating the exact tunnel.

Different builds should be able to solve the same excavation assignment differently through:
- direct excavation,
- Survey,
- alternate cavities,
- Mobility,
- endurance/logistics,
- quieter approaches where relevant.

---

# 64. Religious / Cult-Like Social Undertone

## LOCKED DIRECTION

The Hollow's religious/cult-like culture is expressed primarily through **existing systems** rather than through a separate religion mechanic.

Religion/cultural doctrine can shape:
- Ritual,
- Pulse Binders,
- Approved vs Forbidden technology,
- civic duty,
- Trust,
- access,
- housing/status,
- taboo,
- Firmament excavation,
- interpretation of inherited ship technology.

Religious expectations can influence how NPCs interpret behavior, but **Trust remains broader than religious conformity**.

An action may be simultaneously:
- illegal,
- socially disloyal,
- technologically taboo,
- culturally/spiritually transgressive,

depending on context.

Approved technology often carries the weight of sanctioned/orthodox use.

Forbidden technology may violate not only civic rules but inherited doctrine about what old technology is for and who may manipulate it.

Ashram Heights should especially embody respected social status, ritualized culture, and proximity to institutional authority, making secret Firmament excavation from there more transgressive.

## LOCKED — Naming/cultural integration

Indian/Buddhist/Arabic inspiration can appear more strongly in:
- societal terms,
- institutional names,
- places,
- titles,
- ritual language,
- doctrine.

This influence should be blended with degraded colony vocabulary rather than copied mechanically from one real-world religion or language.

## CUT

Do not add by default:
- a Faith meter,
- Sin points,
- prayer buffs,
- a doctrine skill tree,
- a separate religious reputation currency.

Religion should change the meaning and social interpretation of existing actions rather than create a detached progression system.

---

# 65. Prototype Approved and Forbidden Gear Roster

## LOCKED — Purpose

The following is the first concrete prototype Gear roster.

Names and tuning may be refined, but the mechanical roles define the intended capability web.

Gear should primarily change:
- capabilities,
- information,
- routes,
- logistics,
- risk,
- tradeoffs,

rather than provide small generic percentage bonuses.

## DIRECTION — Excavation

### Approved — Pressure Bore

Heavy Cistern-assisted excavation equipment.

Role:
- makes dense Ravelstone and difficult geology practical,
- supports direct excavation,
- costs substantial Rig Capacity,
- is loud and stamina-intensive.

### Approved — Fracture Pick

A more efficient precision excavation approach.

Role:
- weaker than brute-force pressure equipment,
- cheaper to sustain,
- especially effective when Survey reveals cracks/weak seams.

### Forbidden — Resonance Driver

Illegal modification/repurposing of heavy excavation technology.

Role:
- transmits force deeper through rock,
- can defeat some reinforced or ship-adjacent barriers that Approved tools should not,
- produces distinctive noise/evidence,
- carries higher physical/Rig risk.

## DIRECTION — Survey

### Approved — Strata Lens

Reads nearby density/geological transitions.

Role:
- reveals weak seams,
- improves interpretation of nearby Material pockets,
- short/medium-range geological information.

### Approved — Echo Probe

Active sensing into surrounding geology.

Role:
- detects cavities,
- buried chambers,
- large structural anomalies,
- gains range at the cost of noticeable noise.

### Forbidden — Ghost Mapper

Repurposed ship-derived sensing.

Role:
- detects concealed conduits,
- sealed cavities,
- artificial structures,
- buried ship infrastructure,
- may reveal things society intentionally leaves sealed.

## DIRECTION — Hauling / Endurance

### Approved — Load Harness

Improves how hauled Material is supported.

Role:
- reduces the severity of the hauling stamina block,
- improves practical expedition range,
- does not simply raise maximum stamina.

### Approved — Counterweight Frame

Heavy hauling Rig attachment.

Role:
- specializes in supporting large loads,
- consumes significant Rig Capacity,
- trades flexibility for hauling strength.

### Forbidden — Deadweight Bypass

Unsafe Rig override.

Role:
- permits extreme hauling by bypassing normal safety assumptions,
- shifts pressure into Rig Strain/fatigue risk,
- lets the player knowingly overextend rather than receiving a pure capacity bonus.

## DIRECTION — Mobility

### Approved — Wickline

Compact Wickwork tether/grapple system.

Role:
- anchors to valid surfaces,
- crosses gaps,
- supports controlled descent,
- shortens return routes.

### Approved — Climber Spurs

Sustained vertical traversal equipment.

Role:
- reduces the practical cost of prolonged climbing,
- improves control on rough surfaces,
- favors deliberate vertical exploration.

### Forbidden — Snapline

Unsafe high-tension Wickline modification.

Role:
- faster/more aggressive deployment,
- can use some surfaces or situations rejected by sanctioned safety rules,
- increases noise and physical/Rig risk.

## DIRECTION — Secrecy

### Approved — Dampening Wrap

Legitimate Wickwork vibration-control equipment.

Role:
- reduces tool vibration/noise,
- useful for worker safety and structural stability,
- also naturally useful for illicit excavation.

### Approved — Hooded Lamp

Directional personal light.

Role:
- reduces light spill,
- useful in occupied/delicate spaces,
- trades peripheral visibility for discretion.

### Forbidden — Quieting Coupler

Illegal powered-tool modification.

Role:
- strongly suppresses the sound signature of selected excavation equipment,
- creates heat/strain/sustained-use tradeoffs,
- is difficult to explain if discovered.

## DIRECTION — Cross-category light/survey

### Approved — Glowglass Lamp

Glowbeds + Wickwork light technology.

Role:
- broad usable illumination,
- can reveal biological/environmental responses,
- overlaps Light and Survey.

### Possible Forbidden evolution — Pulse Lamp

A repurposed/reactive prospecting version.

Role:
- provokes/reads environmental responses useful for prospecting,
- may be visually distinctive or socially suspicious.

This specific Forbidden evolution remains a **DIRECTION**, not a required Act 1 item.

---

# 66. Mechanics Freeze for Build Bible

## LOCKED

The mechanics canon is now sufficiently complete to begin the **Build Bible / implementation-contract phase** for the vertical slice.

The Build Bible should convert this canon into implementation-level definitions for:
- Godot architecture and ownership,
- services/autoloads,
- signals and dependencies,
- player-controller contract,
- stamina/fatigue/stamina blocks,
- Materials/Components/Records,
- hauling/caching,
- district production/demand/reserves,
- jobs/commitments,
- Trust/suspicion/evidence,
- Rig/Gear/Capacity/Strain,
- capability web,
- Approved and Forbidden Gear,
- private workspace/residential progression,
- destructible terrain/chunks,
- world-state persistence,
- save/load,
- opening-route acceptance tests,
- PixelLab asset/state contracts.

The Build Bible must preserve every **LOCKED**, **DIRECTION**, **OPEN**, and **CUT** distinction in this canon.

Do not reopen a locked mechanic merely because an implementation agent prefers a different architecture.

Small numeric/tuning changes explicitly marked as tunable do not constitute redesign.

---

# 67. Forbidden Gear as Bio-Fusion

## LOCKED — Provenance

This section is **USER-locked** (2026-09-14), reached through explicit design discussion and checked against every other section of this document for contradictions before being added. It refines Sections 29, 33–36, 47, 54, and 62 without contradicting anything else marked LOCKED elsewhere in this document. Where this section and an earlier one could be read two ways for Forbidden Gear specifically, this section's wording governs.

## LOCKED — Naming (USER, 2026-09-14)

Bodily fusion is named **Hellbinding** or **Voidbinding** (interchangeable — both derive from existing folk names for the Devil's Mouth, "Hell" and "the Void"), and its practitioners **Hell Binders** or **Void Binders** (interchangeable). This is deliberately the same root as Divine Binding / Pulse Binders, not an unrelated word: Binding always means joining technology to something through sacred procedure. Pulse Binders join tech to tech. Hell/Void Binders join tech to a body. The transgression is exactly and only that the target shifted from an object to a self — doctrine permits binding tools together, not binding a tool to yourself.

**DIRECTION, not mechanically specified:** folk warning holds that Hellbinding/Voidbinding "traps your soul in the void" — mostly superstition, but consistent with this game's pattern (Heavenfall) of doctrine's exaggerated warnings sitting on top of a real, smaller kernel of truth. Whether that kernel is literal (some genuine connection to whatever's actually at the bottom of the Mouth) remains open, Act 3 territory.

## LOCKED — What Forbidden Gear physically is

**Forbidden Gear is bodily fusion, not a worn device.**

Approved Gear remains ordinary sanctioned worn equipment — harnesses, tools, lamps — built and issued by the sanctioned districts, mounted in Gear slots as already defined (§35–§36).

Forbidden Gear is different in kind, not just in legality: it is grafted into the player's body. There is no separate mechanical Forbidden Gear category running alongside it — every Forbidden item is a graft.

This does not change how Forbidden Gear is acquired. The existing cost rule (§29) still applies in full: **diverted/stolen District Output remains the base cost for every Forbidden item**, with a Material, Component, and/or Record as the required additional layer, detailed below.

## LOCKED — Recipe

A graft requires all three of:

- a **Component** recovered from ship wreckage, specifically tied to old bio-interface/medical-grade equipment (not general ship hardware — see Origin below);
- a **Material** whose properties match the graft's function, acting as the living, tissue-compatible substrate the Component needs to bond safely. Different grafts call for different Materials — Sutral for recovery/endurance-flavored grafts, Ravelstone for hardening/structural grafts, Brinecrystal for pressure/sensory grafts, Verdigris for signal/conductive grafts, Hullbit for the rarest, most intact grafts. No single Material is required by every graft;
- a **Record** teaching the procedure. Without it, the Component and Material exist but the knowledge to use them safely does not.

This is the same Material/Component/Record framework already locked in Sections 3–8, applied to one specific use. It does not create a sixth Material or a new discovery type.

## LOCKED — Origin

The recovered Components are not general-purpose ship debris. They belonged to equipment built for the **Firstwalkers** (USER-named, 2026-09-15) — a small pre-crash pioneer/expedition corps: colonists meant to do the hazardous frontier work an unfamiliar world required (deep excavation, survey, first contact, whatever lay beyond what ordinary domestic technology could handle) — not life support or environmental adaptation for the general colonist population. The name echoes "Firstfall," the existing term for crash-era ship relics — the Firstwalkers were meant to be the first to walk this world; the crash meant they never got the chance. Ordinary colonists relied on conventional equipment, consistent with Approved technology already being described as mundane and domestic (fire-starting, filtration, structural).

This equipment was restricted and specialist even before the crash. After it, knowledge of what it actually is falls under the same "could reveal the truth" category already locked for navigation, communications, and legible ship data (§32, §48) — hoarded and suppressed, not openly destroyed.

This means most colonists never had access to it, and their descendants have no baseline need for it. Bio-fusion is not universal among the Hollow's population, and finding a working fragment of it is rare by design, not by accident.

The First Steward's own long life, drawn from "medical stock" recovered from deep within the Devil's Mouth (story canon), comes from the same restricted category of technology — a more complete source than anything reachable in Act 1. **The player's Act 1 finds are lesser, partial caches from the wider crash debris field, not the same source the Steward reached.** This distinction must be preserved wherever the Steward's backstory and the player's Forbidden progression are both discussed, so the two are never implied to be the same find.

## LOCKED — Slots and Capacity

Grafts do not use Gear slots. Slot count (§36) governs only configurable, worn Approved Gear.

Grafts draw only from **Rig Capacity**, the same soft-limit pool Approved Gear already draws from (§35). Exceeding it still creates Rig Strain, following the existing rule exactly — nothing new is added to how Capacity or Strain work.

This gives the two acquisition paths a genuinely different shape rather than a reskinned one: an Approved-heavy build is limited by slot count first; a Forbidden-heavy build is not slot-limited at all, but pays for it in cumulative Capacity/Strain cost.

"The Rig" remains the umbrella term for the player's whole loadout, worn and grafted alike — the term does not narrow to mean only mechanical equipment.

## LOCKED — Where grafting happens

Grafting occurs only at the player's private Forbidden workspace (§47), following its existing rules for fabrication time and residence-tier improvement.

Grafting specifically requires the **Mid Reach residence tier or better** — the Lower home's crude workspace is not sufficient for it. Earlier Forbidden progression, before Mid Reach, can still exist through smaller diverted-output spends the crude workspace already supports; sustained bio-fusion is a Mid Reach-and-later capability.

## LOCKED — Removal and refitting

Grafts follow the existing semi-permanent refit rule (§34, §36): swapping which graft is active is possible only at the workspace, for a real cost — consumed Materials/Components and a short recovery window during which strenuous action is harder — rather than an instant menu swap.

Full removal back to an unmodified body is rarer and harder than a routine swap, and may require its own Record. It is not designed as a common action, and does not need further definition before the vertical slice.

## LOCKED — Concealment

A graft's concealment uses the same qualitative tiers already locked for the hidden workspace (§62: Basic / Improved / Advanced), but tracks **independently** — a player's body and a player's workspace each have their own concealment state; improving one does not improve the other.

Consistent with §62, concealment is state-based, not a percentage: a Basic-concealed graft is safe from a casual glance but not a deliberate search or medical exam; better concealment raises what it takes to expose it. What is actually found still determines the severity of the consequence, per §47's discovery philosophy.

## LOCKED — Damage and complications

Severe, specific, contextual events may disable or complicate a graft, following the exact rule already locked for ordinary Gear damage (§54): occasional and story/event-driven, never routine wear-and-tear bookkeeping, and never a random injury system. This section does not introduce a new injury mechanic — it applies the existing one.

## DIRECTION — Size and visibility

Most grafts should be small and easy to miss at a glance — a vein pattern, a faint luminous patch, a color change in one eye — consistent with the existing line that "smaller modifications may be concealable" (§36). A handful of the most powerful late grafts may be visibly larger, consistent with the same section's "large obvious forbidden attachments may create social/logistical issues." Exact sizes and which specific items are large remain tuning, not locked here.

## DIRECTION — Existing prototype roster

The Forbidden items already listed in Section 65 (Resonance Driver, Ghost Mapper, Deadweight Bypass, Snapline, Quieting Coupler, the possible Pulse Lamp evolution) keep their existing mechanical roles unchanged. Their fiction needs to be rewritten as grafts rather than devices — this is follow-up work for the Build Bible / roster pass, not a re-design, and Section 65's own permission already covers it: "Names and tuning may be refined, but the mechanical roles define the intended capability web."

## CUT

- A separate mechanical Forbidden Gear category running alongside bio-fusion.
- A dedicated Gear slot type for grafts.
- A random injury/complication system distinct from the existing occasional Gear-damage rule.
- A sixth Material or a fourth discovery type created specifically for grafting.
- Any implication that the player's Act 1 finds are the same source as the First Steward's medical stock.

## OPEN

- exact Capacity cost per graft, and whether a graft has a minimum Capacity floor regardless of size;
- exact procedure time/fatigue cost at the moment of grafting, separate from the ongoing Capacity cost;
- exact concealment tier names and search rules for on-body grafts (may reuse §62's names outright or diverge slightly once tested);
- whether full removal requires a distinct Record from the one that taught the graft;
- **flagged idea (USER, 2026-09-16), not decided — secretly recharging Forbidden Gear at the Pulse itself.** Once the player has pieced together what the Pulse actually is (not a relic but a real, still-active piece of ship technology), could some grafts require periodic recharging only the Pulse can provide — meaning the player secretly draws power from the exact object Pulse Binders devotionally serve, in the one location that's rarely unstaffed? Thematically sharp (a direct, personal mirror of the Approved/Forbidden split: legitimate practitioners serve the Pulse, the player secretly exploits it), but real unbuilt scope — it needs its own concealment/witness rules for a location that's almost never empty, distinct from the general hidden-workspace model. Not required for the vertical slice; revisit if/when Forbidden Builds (Build Bible Spec 28) or the Pulse itself gets fleshed out further.

---

# 68. Vertical-Slice Structural Locks

## LOCKED — Provenance

This section is **USER-locked** (2026-09-15), resolving every Tier 1/Tier 2 structural gap identified for the vertical slice. Full rationale and rejected alternatives live in `docs/build-bible/01-gap-decisions.md` (G1–G22); this section is the terse canonical form. These are structural decisions, not tuning — exact numbers (durations, thresholds, quantities) remain OPEN/tunable unless stated otherwise.

## LOCKED — Stamina block overflow

Stamina blocks apply in a fixed order: fatigue first, then Rig Strain, then hauling. An action that would push total blocks past the stamina bar is allowed only as Overexertion, with a warning; the overflow converts into fatigue. If fatigue alone fills the bar, the player is Exhausted. Invariant: blocked stamina never exceeds the maximum.

## LOCKED — Overexertion trigger

Holding a strenuous action at zero usable stamina triggers Overexertion automatically, with a strong audio/visual warning. The first Overexertion in a play session shows an explicit prompt before it happens.

## LOCKED — Sleep and cycle skipping

Sleep is available only from Gathering onward (or after Ritual), and always advances to the next Rousing, triggering exactly one district cycle resolution. Earlier in the cycle, only field/home rest is available: partial fatigue recovery at a time cost, never crossing a cycle boundary. This makes farming repeated district resolutions by sleep-spam structurally impossible.

## LOCKED — Civic cycle length and time flow

A civic cycle runs roughly 30–40 real minutes, with Working occupying about half. Time pauses during menus, the workbench, and dialogue. Travel-time budgets are a design target, not a hard rule (e.g. home to the Bottom-West front under 3 minutes). Exact minutes stay tunable; the structure (paused during UI, Working as the long phase) does not.

## LOCKED — Save and reload policy

One rolling save slot autosaves at beds, civic phase transitions, and on quit; quitting resumes exactly where the player left off. No manual save list, and no save-scumming path around theft or lie consequences. A separate optional backup slot for accessibility may be offered later without breaking this.

## LOCKED — NPC simulation scope

NPCs follow an abstract schedule table (location per civic phase) whether or not their chunk is loaded. Off-screen NPCs "are" at their scheduled location without physics simulation, and instantiate when their chunk loads. Perception (witnessing, noise) runs only for loaded NPCs, but off-screen scheduled presence can still be queried for world-fact purposes (e.g. "was anyone scheduled in Wickwork storage at that time").

## LOCKED — Trust granularity

Trust is one global value for Act 1, with local suspicion tracked separately per NPC, district, Wardens, location, or incident, per §17/§19. The Trust system exposes a context-aware query from the start, so group-specific modifiers (e.g. Wardens reading Trust differently than ordinary residents) can be added later without breaking the contract.

## LOCKED — Combat in Act 1

Act 1 has no combat. Danger comes from hazards (collapse, flooding, falls, pressure), stamina, civic time, and social consequence. Non-combat creatures that react to the noise system (avoiding, distracting, hiding — never fighting) remain a possible later DIRECTION, not required for Act 1.

## LOCKED — Hauling cost on flat routes

Hauling makes climbing, ladders, steep ramps, and jumps strenuous — they spend stamina and can't draw on the blocked portion — and sprinting is unavailable while hauling. Loaded movement is also slower, scaled by load, so distance costs civic time even on flat ground.

## LOCKED — Load bundling

The player tows one bundle holding up to a capacity of a single Material type at a time. Additional simultaneous bundle capacity comes from Hauling-dimension Gear, not from carrying multiple bundles by default.

## LOCKED — Theft interaction

Diversion is a hold-to-take interaction at a physical storage object (rack, culture shelf, supply crate): cancellable, takes real time, emits noise, one unit per take. Small amounts stay concealed on the player; amounts above a threshold become a physical haul load. Witness danger is shown diegetically (NPC facing, footsteps, light) — never a meter or percentage.

## LOCKED — Core Improvement sources

Core Improvements come from a small, mixed set of sources: some ordered from Wickwork at Trust/story-gated milestones (Approved), some restored from recovered ship Components or discovered at repair bays, and some Forbidden. Kept deliberately small so Core Improvements never become an RPG stat track.

## LOCKED — Theft cost when District Reserves refill

Every diversion writes an unexplained-loss fact regardless of current District Reserves; local investigation pressure derives from those facts and decays slowly across cycles. Additionally, at cycle resolution each district compares expected vs. actual District Reserves — when the unexplained loss since the last check crosses a threshold (lower while the district is strained), a discrepancy fact is logged and storage checks increase. Both effects are deterministic, not hidden random rolls.

## LOCKED — Player lever during a shortage

When a district is short this cycle, the player has two immediate levers even though District Capacity itself only grows via lasting projects: a shortage can spawn Emergency/World Need jobs (repair a line, haul supplies, clear a blockage) granting temporary District Capacity for a few cycles; and the player can return diverted District Output or donate personal stores directly to District Reserves, openly or anonymously as its own risky act.

## LOCKED — Accidental falls and void drops

Authored barriers keep normal routes from dropping into the Devil's Mouth or off lethal falls. If a severe fall happens anyway, the player wakes at the nearest safe point with added fatigue, lost time, and any haul left behind but recoverable. Rescue as a forced event is reserved for authored stranded situations (§54), not ordinary accidental falls.
- which specific Materials pair with which playstyle dimensions beyond the examples given above.

