# Krater — Story (living narrative doc)

**Canonical place for Act 1 fiction detail, open narrative questions, and future story ideas.**

| Doc | Owns |
| --- | --- |
| [`mechanics-canon.md`](mechanics-canon.md) | **Mechanics source of truth.** Story text that contradicts it is updated to match. |
| [`game-pitch.md`](game-pitch.md) | High-level vision + how story maps to systems (Acts 1–3) |
| [`game-decisions.md`](game-decisions.md) | Numbered design locks / leanings (mechanics, naming options, scope) |
| **This file (`story.md`)** | Narrative detail, tone for writing, **idea inbox** |

**Rule for agents and future notes:**

- Pitch + decisions **lock design systems** (Trust, theft, dig directions, Divine Binding split, Act 1 “might be the whole game,” etc.).
- **Canon** below = locked fiction we write and implement against. Do not contradict it without an explicit user lock.
- **Inbox / ideas** = brainstorms only. Agents must **not** treat inbox items as canon or ship them as fact until the user moves them into Canon (and optionally notes a decision # in `game-decisions.md`).
- When locking an idea: copy/edit it into **Canon**, delete or mark it done in Inbox, and link a decision number if one exists.

Do **not** invent major new plot here. Prefer concise pulls from pitch / CONTEXT / decisions.

---

## Canon — Act 1 fiction

### World as people know it

- Society lives in and around a massive crash shaft formally called **the Devil’s Mouth**: cliffside terraces and bridges ring its deep central void (see `docs/refs/hollow_concept.png`). Most people shorten it to **the Mouth**; other common names are the Deep, the Void, and—among the more fearful—Hell. Truth of the crash has rotted into myth; everyone has a theory about how deep it goes; nobody who’s gone far enough has come back to settle it.
- Working name for the whole world-as-known: **the Hollow**. Day-to-day speech should prefer **named subsections** (districts, tunnels, chambers), not constant “the Hollow” (see decisions #1–#2, #28).
- The sacred ceiling is **the Firmament** in formal speech; most people call it the Vault or simply the roof. It is natural crash-sealed strata: impact-fused rock, collapsed overburden, mineral growth, and alien surface geology that closed over the ancient impact cavity. The Firmament is believed to hold only through shared work, obedience, and grace.
- The Hollow's foundational myth is **the Great Collapse**: generations ago, an early expedition dug upward and broke into a waterlogged layer above the Firmament. The breach brought both collapse and flood, and people died — a real disaster, not an invention. Doctrine has since reframed it as judgment: an earlier generation grew selfish and questioning, and the Firmament fell on them while the faithful were spared. The taboo against upward digging carries genuine, earned weight because something genuinely terrible really happened once — what's manufactured is the moral framing layered on top of it since, not the disaster itself. (This is why the Firmament genuinely being thick and exceptionally hard, not a thin shortcut, matters: whatever's above was dangerous enough to kill people the first time.)
- Unbreakable rule the *other* way: **never dig upward**. The ceiling myth is manufactured control. The Devil’s Mouth is *genuinely* dangerous without needing a myth — that asymmetry is load-bearing tone. The player should discover that the Firmament doctrine is false or deliberately distorted, not that the Mouth is harmless.
- Title **Krater** is also diegetic: the Devil’s Mouth *is* the crater the ship carved (players don’t get that confirmation in Act 1).

### Protagonist

- A kid who never fully bought the Firmament story. Not a rebel — curiosity just points **up**, while everyone else’s wonder points **down**.
- They begin in the working, lower terraces. By helping the Hollow thrive, they earn higher residence, responsibility, and eventually access to Ashram Heights: the guarded, prestigious sacred upper ward immediately beneath the Firmament. Advancement brings privilege and a better home, but also scrutiny, duties, and more to lose.
- Personal investigation can push toward restricted, ship-related, and Firmament mysteries throughout Act 1, but **sustained** secret upward excavation becomes practical only once the player lives in Ashram Heights. Ordinary public digging is lateral civic excavation into side galleries and new districts; the Devil’s Mouth itself is a feared, mostly unworked void until later story beats.

### Life underground

- **Production districts** — Glowbeds (biological cultivation: food, luminous fungi, recovery, biological capability), Wickwork (practical flexible fabrication: cable, bindings, harnesses, lamp housings, Rig gear, repairs), and Cistern (water, pressure, hydraulics, lifts, drainage, heavy infrastructure). Each produces civic output once per civic cycle from its Capacity against Civic Demand, with a finite District Reserves. Districts are influenced, not commanded (see [`mechanics-canon.md`](mechanics-canon.md) §21–§27).
- **The Pulse and Ritual** — the Pulse, a large degraded ship component at Mid Heart, sets the civic cycle (provisionally Rousing → Working → Gathering → Ritual). **Ritual** is the communal return anchor: gathering, accountability, and story. Missing it is contextual — who expected you, why you were gone, and whether evidence contradicts your explanation.
- **Living Hollow** — people work, live, play, and talk. Home base must feel inhabited (#28).
- **Building exploration** — production districts are anchors, not the whole settlement. Wall neighborhoods contain actual homes, courtyards, shared kitchens, washhouses, clinics, maker bays, storage rooms, Warden posts, clerks, Ritual prep rooms, and deep carved galleries. Use a mix of bespoke interiors, repeatable inhabited rooms, quest/NPC doors, and ambient façades; not every lit window needs a unique explorable house. Discoveries belong to their location: human finds (Tallies, Materials, favors, notes), Rig finds (repair bays, workbenches, Gear leads), story finds (Records that unlock a route, capability, district project, or NPC consequence), and rare buried-wreckage finds (sealed hatches, Components, partial systems). Puzzles are physical and contextual—Presswater routing, maintenance sequences, quiet-dig seams, delivery discrepancies—not generic key doors or treasure chests. Prefer new actions, routes, Gear, civic favors, or story leverage over abstract percentage buffs.
- The Hollow is warm and mutually dependent, but carries the undertones of a practical theocracy. People vary: some genuinely believe the Firmament doctrine, some comply for safety or status, and some quietly joke about it. Light folk comedy remains: belly-of-a-beast theories, nursery rhymes, one person who says it is all just rock. The Devil's Mouth in particular is a constant, massive presence in daily life, so it comes up constantly in ordinary conversation — many different residents casually apply their own theories, half-remembered religious framing, and folk wisdom to it in passing talk, not concentrated in any one character. Most are wrong. A few, scattered across different unrelated conversations, land closer to the truth than doctrine would like without anyone realizing it — ambient texture and optional Journal color, not a dedicated NPC or quest thread.

### Hollow shape and the two frontiers

- The game remains a 2D side-view world built around a broad, central Devil’s Mouth. The Mouth is an ink-dark vertical void with terraces and bridges on both sides; it must read as the Hollow's emotional and geographic center, not as a flat floor with a hole in it.
- **The Heart of the Hollow** is one connected, vertically layered civic complex suspended across the Mouth. Upper Heart (Ritual, Council appearances, upper routes), Mid Heart (market, allotments, material turn-in, public work), and Lower Heart (freight, excavation dispatch, Deep recovery) are its three civic anchors—not its only three platforms. Each is a dense band of smaller terraces, carved chambers, homes, work bays, transfer landings, and suspended walkways.
- **Mid Heart is the Heart cluster:** a vast colony-ship wreck fragment caught across the Mouth in the impact, then buried under generations of decking, patchwork cladding, dust, rust, fungus, shops, and homes. A damaged stabilization system in the concealed wreck reduces its weight across a limited radius. It is therefore a **moored floating civic district**: three or four major lightened structural rafts, with several smaller conventional decks hung from or bolted to them. It must never read as a single island or as a fleet of freely flying platforms.
- **Pulse Binders are based at Mid Heart**, physically tending the Pulse and the stabilizer-linked systems that keep the cluster aloft — the inherited pressure checks, material repairs, lamps, and maintenance rites already described below as part of daily Ritual practice are their work. A small Binder's hall or tending-station near the Pulse is their home base; their certifying/teaching role still radiates out to the districts (Wickwork, Glowbeds, Cistern) where Approved Gear is actually built.
- Residents believe the daily Ritual—prayer, procession, and civic observance at the close of the Pulse’s cycle—keeps the Heart aloft. The practice grew around inherited pressure checks, material repairs, lamps, and maintenance rites; it genuinely coincides with what keeps the system stable, though no living resident understands the original technology. This is a sincere civic faith with a false explanation, not literal supernatural intervention.
- Rock-bolted underbeams, tension cables, docking bridges, catch-rails, hydraulic clamps, and emergency seating braces connect the cluster to both cliff faces. Presswater drives the visible brakes, docking gear, ballast pumps, freight machinery, and lifts. Hanging walkways, stairs, freight lines, and transfer spans connect the major rafts, smaller decks, and both walls. It is the Hollow’s main cross-Mouth circulation system as well as its civic center.
- **Vertical transport is deliberately asymmetric.** The west civic cage begins at the Wickwork/Mid band and rises to the High-West and west Ashram gateway; lower west workers reach that landing by broad stairs, ramps, and switchbacks, never by a full-height shaft. On the east, a heavy Cistern freight cage runs only between the deep Cistern/lower-east service band and Mid-East, carrying crews, Materials, brine canisters, and repair loads. A separate, smaller east passenger cage begins inside the recessed Mid-East wall and rises to Glowbeds and the east Ashram gateway; Wardens control it before clearance. All are slow on-screen platforms. Ladders remain short local maintenance alternatives, and the personal tether remains separate recovery gear.
- **Mid Heart route graph:** four major rafts make a dense, open civic loop rather than a procession across one bridge. The central, slightly raised **Ritual Raft** is the largest gathering place: a broad two-level civic hall for daily Ritual, announcements, Council appearances, queues, benches, and public standing room. The **West Exchange Raft** meets Wickwork and the left-lift approach, housing Joss’s Materials delivery counter, Approved Gear orders, repair intake, and freight receiving. The **East Service Raft** faces the right-lift/Cistern side, with Glowbeds ration distribution, a medic/care room, notices, small shops, and civic offices. The rougher **Lower Freight Raft** carries carts, cargo transfer, docking machinery, and maintenance access. The obvious ceremonial/public route is West Exchange → Ritual → East Service; a second lower freight-and-service loop connects all four with ramps, short bridges, and smaller attached decks. The Ritual Raft remains the clear center without becoming a dead-end plaza.
- The Heart is secure enough for daily life but must never feel like a normal building on solid ground: open edge views, gaps between platforms, visible support cables, distant depth haze, restrained sway, and occasional metal creaks keep the Devil’s Mouth present beneath every shop, market table, and crowd. Cistern strain or shortage causes controlled civic degradation—dimmed equipment, delayed docks or lifts, and a visible settling onto emergency catches—not a random fall or a player softlock.
- Keep the platform cluster legible: several distinct silhouettes and activities, with only enough bridges to create route choices and later shortcuts. Do not fill the center so densely that the Mouth stops reading as an immense void.
- The lower terraces are crowded, practical, and closest to Mouth work. Middle terraces contain the main production districts and public civic life. Upper terraces are quieter, more ordered, and increasingly restricted; **Ashram Heights crowns both crater walls directly beneath the Firmament.** The left upper approach passes through the High-West work front; the right upper approach contains the tidy Glowbeds before descending toward Mid-East. This is social geography: public work earns **Tallies**, and reliable conduct over time builds **Trust**; Trust, Tallies, status, and story progression unlock better residences and higher bands. There is **no** separate Contribution meter.
- **Homes and ascent:** the player always has a home in the Hollow. Act 1 uses three fixed residences rather than an abstract property menu. They begin in a small private Lower-terrace unit off a shared workers’ courtyard: bed, lockbox/storage, work surface, deliveries at the door, and communal wash/cook space nearby. A Trust- and Tally-gated **Mid Hollow residence** provides a better-kept two-room apartment near Mid allotments/Wickwork, with more privacy and storage, a proper workbench, a shared balcony, and more opportunities for visitors. The late-Act-1 **Ashram Heights residence** is quiet, tidy, and private directly beneath the Firmament; it is a long-term aspiration foreshadowed well in advance, and it provides access and cover for sustained private upward excavation while increasing observation and responsibility. Legitimate social advancement creating the privacy for deeper forbidden work is an intentional contradiction. Every home supports storage, deliveries, visitors, and rest/save. Once the player understands their first Forbidden Design, each home also hosts a concealed private workspace that improves with each residence (crude → improved → strongest); it is safe by default and only exposed through believable evidence, suspicion, or story circumstances, with warning first (canon §47, §62). Relocation requires Trust, Tallies, and story clearance; any illicit route is a named one-off favor, never a generic repeatable bribe system.
- The player starts with useful, public **lateral** work: digging braced side galleries for Materials, district supplies, and ambiguous Records. The Devil’s Mouth remains a powerful, mostly unworked crater at the Hollow’s center; its true wreckage stays reserved for Act 3.
- **Three progressive public dig fronts:** all sanctioned excavation goes sideways away from Devil’s Mouth, reached by a real trip through the city. **Bottom-West Dig Front** opens early from the Lower working terraces: a crowded, rough civic expansion through loose impact-fill and ordinary crater-wall rock. It yields abundant common Materials but little recognizable wreckage; it is first because it is structurally manageable and socially permitted, not because it is closest to the crash. **Mid-East Dig Front** opens in mid Act 1 at a true middle elevation on the east wall—below the upper-right Glowbeds and well above the deep Cistern complex. It is a wetter, pressurized fault-and-service layer where shock-fractured stone contains corroded, ambiguous technical remnants. It yields stronger Cistern/Wickwork-linked Materials and contextual puzzles without making the ship’s origin obvious. **High-West Dig Front** opens late directly below left-side Ashram Heights, through an official guarded high-wall gallery near the Firmament. Collapse and settlement layers have buried outward-thrown surface debris there, so it offers rarer, more intact Hullbits, sealed components, and Records. It remains lateral civic work: its roof proximity creates opportunity for the separate, forbidden upward route but does not itself grant it. The true dense wreck mass remains far below in Devil’s Mouth for Act 3.
- The player’s first official excavation, the Steward's new district, is Bottom-West lateral expansion from an existing working terrace. It teaches digging as civic labor and can expose old metal, strange infrastructure, or a contradiction without granting premature Firmament access.
- Upward digging is the late-Act-1 secret frontier, sustained from the Ashram Heights residence, where the Firmament is effectively the player’s ceiling. **The Firmament is thick and exceptionally hard**: there is no naturally thin shortcut. Breaching it is a multi-session project that may require specialized Forbidden Gear, repeated excavation sessions, stamina/fatigue management, debris handling, noise management, concealment, and Survey information about where and how to dig. The house provides access and cover, not safety: noise through walls, dust, structural evidence, suspicious Rig modifications, witnesses, and local investigation all use the ordinary detection/evidence systems (no separate Firmament stealth meter). Firmament progression is authored, not procedurally generated. Breaking through reveals the surface world above, which is Act 1’s climax. Any ship material found in these layers is incidental crash texture, not the primary reveal.
- **The Great Collapse's remains sit within this same excavation, as an authored optional branch, not a separate mapped location.** As the player carves their own route, their tunnel can break through into the sealed remnant of the original attempt — rotted supports, corroded fittings, and a still-waterlogged chamber behind a barrier, never touched since because the taboo it created kept anyone from going back to clear it. Nobody currently living knows exactly where it is; finding it is a genuine first, for the player and for the Hollow. It is not on the required path to breach the Firmament — the player's own route goes elsewhere — but a curious player can dig toward it and enter. The standing water there can source an ordinary stranding hazard (flooding blocking a return route, per the failure system) rather than needing a new mechanic.

### The Lost of the Mouth

- **Void Jumpers** are people who have disappeared into the Devil’s Mouth, usually during grief, despair, obsession, or a desperate longing for truth. They are never treated as a spectacle or player option.
- Official doctrine may call them “taken” or imply the Mouth answered them; families and compassionate residents call them the Lost. This exposes the harm in the Hollow’s religious language without romanticizing the loss.

### The First Steward

- The Hollow is governed by a small **Council of Stewards**: respected senior residents who decide major public works, food allocation, discipline, Firmament restrictions, and responses to danger collectively. They are not department heads; clerks, foremen, and crews run ordinary district work. Most Council members are sincere people trying to preserve the only world they know.
- **Albus Socul**, the future antagonist, is the Council’s **First Steward** and longest-serving, most trusted voice. He chairs the Council but is not publicly a king. His real power is informational: he frames evidence, controls relic protocol, and holds special inherited authority over Firmament doctrine and restricted artifacts. The Council believes it governs collectively; Albus governs what it is allowed to know.
- Albus is useful, calm, and genuinely capable of improving life in the Hollow. The player first meets him through an official assignment: excavate a whole **new district**. This teaches public digging, communal production, and the social value of contributing before secrecy enters the loop.
- The new district is a real civic project: a pressure-storage and expansion annex with space for families, supplies, and safer support around an aging terrace. Multiple crews work it from both sides of the Hollow; the player receives local tasks rather than a complete map.
- Its chosen location also lies over an old colony-ship **service spine** leading toward sealed medical/life-support infrastructure. The Steward needs the route for their own longevity, but the exact nature and location of the hidden room remain open until it serves the final Act 1/Act 3 plan.
- The Steward can plausibly contain discoveries because Hollow protocol already requires unusual metal, intact components, and “Firstfall relics” to be reported for safe handling. A sealed structure can be declared unstable, contaminated, or sacred, then handed to a small trusted maintenance team. The lie is not that old technology exists; it is that only the Steward can judge what is safe, useful, or holy.
- Albus does not read as openly villainous in Act 1. His later reveal is that he preserved control by turning emergency knowledge and old-world restrictions into doctrine.
- **Albus and the Great Collapse (Act 3 reveal, seed only in Act 1):** Albus was there — young, and by some accounts responsible for leading the original expedition that caused it. People he was answerable for died. Building the Firmament taboo, with himself as its sole interpreter, began as a real attempt to make sure it never happened again, not naked ambition. Decades of being the only person who remembers the truth, combined with generations of sustained use of the same restricted bio-fusion-adjacent technology (§67) that keeps him alive, have gradually reshaped him — the exact mechanism stays open, but the throughline is that protector curdled into controller without a single deliberate choice to become one. By the present day he likely still believes he is protecting the Hollow; his actions no longer are.

### Divine Binding (lore → systems)

- **Divine Binding** is the Hollow's sacred practice of ritually operating inherited colony technology — devotional labor, not folklore beside religion. Its practitioners are **Pulse Binders**. The future villain encourages that reverent framing and likely poses as the most gifted Pulse Binder alive (#25).
- Pulse Binders are custodians/practitioners of inherited colony technology, not a fourth production district. They maintain ancient systems, interpret Components, teach procedures, certify **Approved Gear**, and tend parts of the Pulse. A Pulse Binder may know *how* a procedure works without knowing *why*; a Record can reveal why and expose new possibilities.
- **Approved** technology = established, sanctioned Divine Binding society accepts. **Forbidden** technology = the same Divine Binding, practiced without sanction — understanding, modifying, repurposing, or recombining technology beyond accepted doctrine. Every playstyle dimension contains both.
- Later revelations must not reduce Pulse Binders to “your Binding was just technology”: some resist, some reinterpret, some become leading engineers.
- Act 1 players only feel “some Binding is common and sanctioned, some is rare and suspicious.”

### Fragments (stay ambiguous)

- Seeded up and down; readable as myth, religion, or history — **never** clear “we’re on an alien planet” in Act 1.
- **Materials** — bulk physical resources hauled home: **Sutral**, **Ravelstone**, **Brinecrystal**, **Verdigris**, **Hullbit** (locked roster). Each serves several uses across districts, civic projects, infrastructure, Approved Gear, and Forbidden Gear; Hullbit in particular forces community-vs-secret allocation choices. Full table: [`materials.md`](materials.md).
- **Components** — smaller manufactured, usually ship-derived parts. Rare ones may carry reporting expectations, and possessing something from a restricted area implies where the player has been.
- **District Output** — abstract goods (prepared biological products, fabricated goods, pressure/mechanical supplies) produced once per civic cycle from District Capacity. Surplus banks into District Reserves; Approved Gear Orders and diversion both draw on District Reserves, not the momentary Output itself.
- **Records** → knowledge. **Not Materials.** A Record must do more than add a Journal entry: it teaches how something works, reinterprets a technology, exposes a contradiction, reveals a route, or unlocks a district project, an Approved capability, or a Forbidden Design. Finding one does not auto-share it with society; the player may share, keep, give, or withhold it.

### Secrecy systems (story meaning)

- **Jobs and civic work** — jobs are physical civic situations built from ordinary digging, hauling, traversal, and social context, not quest checklists. Early jobs are the invisible tutorial. Work can be Available, Accepted (a commitment), Assigned Duty, an Emergency, or a Personal Request. **Not helping is not the same as promising and failing.**
- **Public progression** — work → **Tallies** → Order **Approved Gear** using Tallies + authorized District Output (Trust/access may also matter). Districts may refuse an affordable order when the output is needed for essential civic demand. Normal Material delivery earns Tallies; Trust moves only for socially meaningful behavior. There is no Contribution currency.
- **District production** — resolved once per civic cycle from District Capacity against Civic Demand, with finite District Reserves. Districts normally stay stable without babysitting; shortages create contextual world problems (delayed lift repair, reduced recovery support, pressure infrastructure trouble), not generic happiness penalties. A thriving district visibly improves Hollow life.
- **Diversion (theft)** — secret progression steals real District Output from physical storage areas (Wickwork racks, Glowbeds prepared stock, Cistern supply rooms) into concealed personal storage, accumulating toward a **Forbidden Gear** build that also needs a Material, Component, or Record. Theft has two independent consequences: **civic harm** (can the Hollow afford it — surplus means lower immediate harm, not consequence-free theft) and **social/detection risk** (did anyone see, hear, discover, or credibly connect it to you). Undetected theft does not lower Trust, but repeated unexplained losses raise storage checks, Warden presence, local restrictions, and investigation.
- **Hauling** — bulk Materials are visibly tethered behind the player and reserve stamina; excess can be cached at a known frontier location. Returning home does not auto-dump Materials into communal storage.
- **The Rig** — the player improves one evolving **Rig** (harness, digging system, light, tether equipment, protection, attachments), never a pile of loot tiers. **Core Improvements** raise baseline capability permanently without using a slot; swappable **Gear** fills configurable slots (roughly 3 → 4 → 5 through Act 1, tunable). **Rig Capacity** is a separate soft limit that grows faster than slots; exceeding it is legal but creates **Rig Strain**, which reserves stamina. Basic movement, digging, light, and tether can never be unequipped or missed. Major refits happen only at home, a private workbench, Wickwork, or another proper station. Gear changes capabilities, information, routes, logistics, or risk rather than adding percentages. Some Forbidden Gear is visibly suspicious. No equipment grants Trust.
- **Trust** — society's qualitative perception of the player's reliability, shown as a few standing states with human-readable reasons. It changes through repeated reliability, meaningful help, broken accepted commitments, being caught stealing, exposed lies, and major accomplishments. Higher Trust gives autonomy, better assignments, access, and benefit of the doubt — and more opportunity to abuse access. It gates later recruitment (seed for Acts 2–3).
- **Lying** — there is no generic Lie button. When questioned about something believable, the player may tell the truth, lie, deflect, or give a partial truth; the outcome depends on the claim, evidence, witnesses, circumstances, and Trust. Trust cannot erase hard evidence, and exposed lies hurt more than admitting the truth. No success percentages.
- **Council Wardens** — a small civic safety corps appointed by the Council and charged with upholding Firmament doctrine. They manage Ashram Heights gates, Firmament maintenance access, lift/dock safety, Ritual crowds, relic protocols, and unexplained shortages. They are familiar civic workers rather than a militarized occupying force: checking seals, giving directions, escorting crews, and helping at accidents. Their authority makes hierarchy real. A nearby Warden is a strong witness; restricted digging in their presence is especially dangerous. A caught player loses Trust and may face repayment, a forced civic shift, confiscation, or delayed access — never an instant fail state or softlock. Their patrols, checkpoints, notices, and local warnings must make risk legible before the player acts.
- **Detection** — sight, sound, and persistent physical evidence. The world records meaningful facts (seen entering a restricted tunnel, heard mining, missed Ritual, damaged seal, missing production) rather than simulating perfect NPC knowledge. **Suspicion is local** to an NPC, district, Wardens, location, or incident; there is no universal Suspicion meter. The civic cycle changes conditions: Working is noisy but crowded; Gathering thins some locations.
- **Failure** — no permadeath or expedition resets. Overextension moves through strained → exhausted → stranded. Quiet self-return preserves secrecy but costs time, commitments, and haul; forced rescue can expose forbidden locations, Gear, or stolen goods. Severe failure can advance substantial civic time.

### Work-rig progression

- The player improves their **Rig**, not their body with abstract stats — though the Rig itself is not purely mechanical (see Bio-fusion below). Approved Gear is normal sanctioned worker equipment, worn and mounted in Gear slots.
- **Forbidden Gear is bodily fusion, not a device.** It is grafted into the player, not attached to a harness, and does not use Gear slots — it draws only on the same Rig Capacity that Approved Gear already shares. Full mechanics: [`mechanics-canon.md`](mechanics-canon.md) §67.
- Builds combine five overlapping playstyle dimensions — **Excavation**, **Survey**, **Hauling/Endurance**, **Mobility**, **Secrecy** — with no classes or isolated skill trees. Major obstacles support multiple approaches so no dimension is mandatory.
- Technology is a **discovered capability web** (Known → Understood → Available), steerable through district projects, Pulse Binder knowledge, locations, Materials, Components, Records, and clues. No screen of greyed-out mystery upgrades.
- The basic tether is part of the Rig’s unmissable baseline. Mobility Gear such as the Approved **Wickline** (compact Wickwork tether/grapple) extends it; the Hollow’s fixed, Cistern-powered lifts remain public infrastructure.
- The core upgrade tension is deliberate: some upgrades make the player more useful to the Hollow, while others make them better at uncovering its truth — and for the Forbidden path, literally change what they are.

### Bio-fusion (Forbidden Gear)

- Grafts are built from a recovered **pioneer/expedition-corps** bio-Component + a compatibility Material matched to the graft's function + a Record teaching the procedure, on top of the usual diverted-district-output cost. The colony ship's expedition equipment was never meant for ordinary colonists — only a small corps preparing for the hazardous unknown of a new world — which is why bio-fusion is rare among Hollow residents rather than universal, and why the knowledge of it was hoarded alongside navigation and ship logs as "truth-revealing" technology.
- Grafting happens only at the player's concealed workspace, and only once they hold the **Mid Hollow residence** or better — not from the crude Lower-home setup.
- No legitimate Pulse Binder performs grafting; it was restricted even before the crash. The First Steward's own long life plausibly draws on the same restricted technology category, from a deeper, more complete cache than anything the player can reach in Act 1 — the two are never the same find.
- Most grafts read as small and easy to miss — a vein pattern, a faint luminous patch — with a rare few late, powerful grafts large enough to be genuinely visible. Concealment uses the same Basic/Improved/Advanced tiers as the hidden workspace, tracked separately for the player's body.
- The unsanctioned practice is **Hellbinding** or **Voidbinding** (interchangeable, both drawn from the Mouth's existing folk names); its practitioners are **Hell Binders** or **Void Binders**. Same devotional work as Divine Binding, stolen rather than granted — Binding always means joining tech to something; this just joins it to a body instead of another tool. Folk warning: it "traps your soul in the void" — likely superstition, possibly not entirely (open, Act 3 territory, echoes the Great Collapse's real-kernel-under-doctrine pattern).

### Act 1 arc — The Firmament

1. **The Hollow Holds:** The player learns ordinary work, the Pulse’s civic cycle and Ritual, the three production districts, public lateral civic excavation, and Firmament doctrine — through early jobs that act as invisible tutorials.
2. **The Steward’s District:** The First Steward assigns the player to help excavate a new district. This provides the first public reason to dig, introduces the Steward as helpful authority, and exposes a contradiction or strange find outside the assignment’s scope — an early responsibility-versus-curiosity choice.
3. **Earned Ascent:** Public work, Trust, Tallies, status, and story clearance advance the player from the Lower home through the Mid Hollow residence toward Ashram Heights, while secret progression quietly grows in each home’s concealed workspace.
4. **Beneath the Firmament:** From the Ashram Heights residence, the player begins sustained secret excavation into the thick Firmament — session after session of Survey, noise and debris management, fatigue, and concealment — and gathers enough contradictions to know the doctrine is false. The surface is not yet revealed.
5. **The Cost of Looking:** One authored social consequence makes secrecy personal: a friend covers for the player at cost, is hurt by a lie, or asks them to choose duty over progress. Contextual Trust and evidence consequences support this beat but do not replace it.
6. **The Breach:** With the necessary Forbidden Gear, knowledge, and persistence, the player breaks through the Firmament. The player controls the quiet, enormous reveal of the surface.

### Act 1 design goal (narrative)

**Act 1 should feel like it might be the whole game.** No surface tease, no “more world” UI. Player braces for punishment when digging up. The Devil’s Mouth stays an unexplained lived-with mystery. The breach is Act 1’s final reveal; there is no surface gameplay or surface-facing UI before it.

---

## Canon — later acts (outline only; do not build)

Full beats live in [`game-pitch.md`](game-pitch.md). Do not expand here unless locking writing for a specific beat.

- **Act 2:** breach → Reef surface; settlement; Trust and relationships still pull you home; Act 1 systems transform rather than reset (canon §49); Devil’s Mouth descent deepens in parallel; hints of runaway surface survivors.
- **Act 3:** crash = first-contact tragedy; villain = long-lived myth-builder / “greatest magician”; homeworld visible as the “guiding light”; Devil’s Mouth bottom pays off both mysteries; shipbuilding uses the same Materials + Components + knowledge + production + infrastructure architecture at larger scale; Trust + three recruitment sources shape the ending.

---

## Open questions / placeholders

Pull these from decisions; resolve there, then promote wording into Canon.

| Topic | Status | Decision |
| --- | --- | --- |
| Firmament / taboo name | Locked: Firmament formal; Vault/roof everyday | #1 |
| Hollow subsection / district permanent names | Open (function-based leaning; Farms/Wickwork/Cistern are build placeholders) | #2 |
| Exact in-world term for “magicians” | Placeholder OK | #25 |
| How strictly sanctioned vs forbidden is policed in fiction | Open | #25 |
| Surface threats / alien scope | Later acts | #3, #4 |
| Devil’s Mouth true-bottom reveal placement | Leaning Act 3, partial descent earlier | #22 |
| Journal Mystery vs Codex framing | See decisions | #26 |
| Narrative texture (murals, elder disagreement, etc.) | Leaning start minimal | #27 |
| Exact hidden medical/life-support room and discovery beat | Open: the service-spine motive is locked; do not prematurely expose its full purpose | New Act 1 story lock |
| Individual Council names and personalities | Open: Albus Socul is the working First Steward name; the Council has no fixed departmental portfolios | New Act 1 story lock |
| Companion creature / living-tool concept | Deferred: evaluate only after core dig/return/Rig loop is proven | Deferred scope candidate |
| Material names | Locked: Sutral / Ravelstone / Brinecrystal / Verdigris / Hullbit. District output has no canon named goods. | [`mechanics-canon.md`](mechanics-canon.md) §4 |
| Pulse original ship function; exact Ritual practice; civic phase names/timings | Open | [`mechanics-canon.md`](mechanics-canon.md) §12 |
| How the Pulse relates to Mid Heart’s concealed stabilizer | Open — do not merge them without a decision | — |

---

## Inbox / ideas

**Brainstorm only.** Paste notes here freely — changes, improvements, additions, dialogue scraps, NPC beats, myth variants.

Agents: **do not implement or treat as locked canon** until an item is moved into **Canon** (and optionally given a decision #).

### How to add an idea

1. Add a bullet (or short paragraph) under **Unsorted** below — date optional.
2. Tag if useful: `[tone]`, `[NPC]`, `[myth]`, `[Act2+]`, `[maybe-cut]`.
3. When you lock it: move the text into the right **Canon** section, strike or delete the inbox bullet, note decision # if applicable.

### Unsorted

*(empty — drop ideas here)*

---

## Quick links

- Pitch (full story + gameplay mapping): [`game-pitch.md`](game-pitch.md)
- Decisions (numbered locks): [`game-decisions.md`](game-decisions.md)
- Materials + inventory proposal: [`materials.md`](materials.md)
- Agent Act 1 summary: [`../CONTEXT.md`](../CONTEXT.md)
- Visual bible (if present): [`art-direction.md`](art-direction.md)
