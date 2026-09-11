# 🧩 OPEN DECISIONS — options for each, pick as we go

*(Companion doc to the main pitch. Each item has 2-4 concrete options + my recommendation where I have one. Circle/edit as we talk. Numbers are stable references — grouped into categories below, but the numbering doesn't change.)*

**Provenance:** When locking or leaning, prefer clear **USER** intent. Agents must not quietly promote their own suggestions into requirements — see [`ai-workflow.md`](ai-workflow.md) (USER vs AI tags).

---

# 🏷️ NAMING DECISIONS

## 1. Name for the ceiling/taboo
*(the rock overhead + the fear of digging into it)*

**✅ Locked (USER):** **the Firmament** is the formal, sacred name. In ordinary speech, residents say **the Vault** or simply **the roof**.

The Firmament is natural crash-sealed rock, overburden, mineral growth, and alien surface geology. Doctrine says it remains intact through shared work, obedience, and grace; an older “correction” supposedly buried a selfish, questioning generation beneath a collapse. This gives the taboo both religious force and a material-sounding threat, while later allowing the player to discover that the doctrine is manufactured control. Act 1 culminates in a hidden route through the natural strata to the surface—not a discovery that the whole ceiling was artificially built.

---

## 2. Names for Hollow subsections
*(so dialogue doesn't lean on "the Hollow" constantly — and so Act 1 production districts have places to live)*

**✅ Locked concept (see also #28):** Act 1 Hollow subsections are not flavor labels only — a small set of them are **production districts** that passively generate different communal resources and can be upgraded over time. Naming still open; the district *role* is locked.

Need a small handful (3-6) of district/chamber names. Options for a naming *pattern* to pick from, then we fill in actual names later:

- **Function-based:** named after what happens there (the Farms, the Wickwork, the Cistern) — strongest fit for production districts
- **Founder-based:** named after early settlers/families (Toren's Hall, the Marrow District)
- **Descriptive/geological:** named after the physical space (the Low Reach, the Wide Cut, the Narrows)
- **Mixed** — some function, some founder, some geological — most realistic, since real places rarely follow one naming logic

**Leaning:** Mixed — feels the most lived-in and least "designed." Prefer at least some function-based names so production districts read clearly in UI and dialogue.

---

## 19. Working title

**Shortlist (picked):**
- **The Falling Sky** — inverts their own myth (dig up and the sky falls and crushes you) into the literal truth (the sky already fell once — that's your origin)
- **Landfall** — sounds like plain geography, quietly means "the moment the ship hit ground"
- **Borrowed Sky** — the sky above isn't really home; reads as generic myth-flavor until the reveal recontextualizes it
- **Ascendant** — literal (you dig up, you eventually fly home) and figurative (rising above the lie you were raised on), without spelling out either
- **Crater** — sounds like plain geography until you know it's literally an impact site
- **The Hollow** — doubles as the location's name; also means empty/false, so it quietly implies the founding myth is hollow too

**✅ Locked for the pitch doc: "Krater."** All others above stay valid alternates if we want to revisit.

**No pressure to lock this today** — working titles are fine for a long time.

---

# 📖 STORY & LORE DECISIONS

## 3. Surface threats
*(what makes exploration dangerous once you're up there)*

- **A) Wildlife/fauna only** — dangerous creatures, no intelligence behind them. Simplest to build, no diplomacy system needed.
- **B) Environmental hazards only** — weather, terrain, toxic zones, no creatures at all. Also simple, different flavor of danger.
- **C) Both A + B, no intelligent species** — more danger variety, still no diplomacy system.
- **D) A + B + an intelligent native species** — richest option, ties into Act 3's crash reveal and the fight-or-peace choice. Adds real scope (see decision #4).

**Leaning:** D, but scoped tightly per decision #4 below — the intelligent species is central to Act 3's twist, so cutting it loses a lot of narrative payoff. The fauna/hazards can be simple.

---

## 4. How deep does the alien-contact choice go?

- **A) Binary, minimal follow-up** — one choice point (fight or don't), a couple of scripted consequences, no ongoing relationship to manage. Cheapest to build.
- **B) Binary with a small unlockable branch** — same single choice, but peace unlocks a short, finite set of trades/tech (not an ongoing system) while conflict closes it off permanently.
- **C) Full second faction** — reputation system, multiple contact points, ongoing back-and-forth. Most narratively rich, most expensive by far.

**Leaning:** B. Gets the "big consequential choice" payoff without building a second faction system from scratch.

---

## 11. Villain's endgame resolution
*(how the final confrontation with him actually plays out — separate from the leave/stay headcount split already locked in)*

- **A) Exposed and left behind** — you win by proving the truth publicly; he has no power once the story falls apart
- **B) Defeated in a direct confrontation** — more active/gameplay-driven climax
- **C) Escapes/flees** — unresolved, could seed a sequel or just be a bittersweet loose end
- **D) Some mix depending on player choices earlier** (Social Standing, how much evidence you gathered, etc.)

**Leaning:** open — this is easiest to decide once we know our ending/final-level gameplay structure, not before.

---

## 12. Runaway settlers — where/how found
*(the second group who split off generations ago and stayed on the surface)*

- **A) A physical settlement you discover** — has its own small area, maybe its own tech branch or NPCs
- **B) A ruin/journal trail only** — cheaper: you find evidence they existed, but don't meet living descendants
- **C) A living settlement, but small — just enough to deliver the "why we split" reveal without a full second society to build**

**Leaning:** C — gets the emotional payoff of B) without needing a whole new area, but earns the reveal being said by an actual character rather than a note left behind. **Locked addition: they're a recruitable source for the settlement, not just a lore beat — see #24.**

---

## 24. Three-source settlement recruitment (Hollow, runaway settlers, aliens)
*(locked in — this is scope/consistency guidance for how it stays cheap)*

**The concept:** the surface settlement can recruit from three narrative sources by end of game — Hollow residents (Social Standing-gated), the runaway settlers (once found, #12), and the native species (only if peace is chosen over conflict, #4). Every major relationship thread in the story pays off into the same settlement headcount, which also feeds the ending split (#11).

**Why it's worth it:** makes the peace-vs-fight alien choice (#4) land harder — peace isn't just a trade-tech unlock anymore, it's a real settlement-growth reward, which makes "you know they're why your people crashed, but you build a future with them anyway" hit much harder. Also gives the Stealth/Social build axis (#7) more to actually do, since it already cares about recruitment ceiling.

**The scope guardrail, not optional:** all three sources share the **same generic worker slot and passive-bonus logic** (per #17's "settlement = headcount + passive bonuses, NOT Rimworld"). Each source gets its own recruitment beat/flavor text/story trigger, but NOT a distinct worker type, unique animation, or separate mechanic. If any source starts needing its own system, that's scope creep — flag it, same as the passive-generation guardrail in the pitch doc.

---

## 22. The Pit — descent scope and reveal placement

- **A) Atmospheric only** — the Pit is constant visual/narrative presence and folklore, but never a playable depth. Cheapest, no new area.
- **B) Partial, gated descent** — mine partway down the Pit's rim early (Act 1) for ambiguous salvage/records, reusing our existing dig mechanic (down instead of up); the true bottom stays inaccessible until much later.
- **C) Full mirrored explorable area** — a real, richly built second space. Most payoff, but real added scope on top of the surface — a second area to build and balance.

**Leaning:** B, with the true bottom (full view of the ship/wreckage) reserved for **Act 3**, gated by the same tech tree that gates everything else. Placement reasoning: too early (Act 1) breaks the "no alien-world confirmation yet" rule; too early in Act 2 makes it redundant with surface evidence we're already gathering. Landing it in Act 3, tied to something mechanically needed (an escape-ship component or a flight recorder confirming the crash cause), gives it real weight instead of being lore for its own sake.

**Locked:** dig tools/tech work in both directions (up toward the ceiling, down into the Pit) — one growing capability, not two separate systems. Encounter dressing (cave-in risk vs. wreckage instability) can differ without the underlying tools differing.

---

## 27. Narrative texture bundle
*(five small, individually cheap additions pulled from Game of Thrones, Hades, and Fallout — the question isn't which one to pick, it's how many to take on)*

**The five pieces, for reference:**
- **Elder disagreement** (Game of Thrones' Maesters) — not everyone around the villain is lying on purpose; some genuinely believe the myth. Costs only dialogue.
- **Evolving recruit dialogue** (Hades) — short, changing lines each time you revisit a recruit, rather than one static beat. Cheap (a handful of lines per character, gated by visit count).
- **Narrated failure recaps** (Hades) — a brief narrated beat instead of a flat "you lost X" screen when an expedition fails or you're caught. Softens the partial-loss model (#13/#16).
- **One signature chase/near-miss set-piece** (Ori) — a single deliberate high-tension sequence (first near-discovery, or fleeing the villain late-game). Cheap specifically because it's a one-off, not a repeatable mechanic.
- **Propaganda murals** (Fallout) — in-world painted warnings about the ceiling/pit taboos. Simple flat illustration assets, not sprites needing animation — reinforces the folklore/comedy layer visually.

- **A) Adopt all five** — maximum texture, and each is individually cheap, but the cumulative writing load (elder disagreement + evolving dialogue + narrated recaps) adds up even if no single piece is expensive alone.
- **B) Adopt the cheapest, highest-impact subset: evolving recruit dialogue + narrated failure recaps** — both touch systems we already have (recruitment, expedition failure) and need zero new assets, just writing layered onto existing triggers.
- **C) Adopt the narrative-only additions: elder disagreement + propaganda murals** — good if writing bandwidth for branching/gated recruit dialogue is a concern; keeps new asset needs minimal (murals are simple, one-off art).
- **D) None for now, revisit after core systems are built** — reasonable if the team wants the base loop solid first, consistent with how we scaled up the Discord setup (start minimal, add texture once there's room).

**Leaning:** B to start, matching the same "start minimal, grow deliberately" pattern we've used elsewhere — both pieces reuse systems we're building anyway, need no new assets, and can absorb A's remaining pieces later if there's spare capacity.

---

# ⚙️ SYSTEMS & MECHANICS DECISIONS

## 5. How punishing are trade-off upgrades?

- **A) No real cost, pure positive scaling** — safest, but this is exactly what let Dome Keeper collapse into "just buy everything." Not recommended given our whole pitch is about avoiding this.
- **B) Optional higher tier costs something; base upgrade is always safe** — lets cautious players opt out of tension, opt-in players get real stakes. Good middle ground.
- **C) Mandatory tradeoffs on all major upgrades** — most Inscryption-like, highest narrative payoff, but risks feeling punishing if not tuned very carefully. Hardest to balance well.

**Leaning:** B to start — easier to tune, can push toward C later if playtesting shows it needs more bite.

---

## 6. Tech tree structure

- **A) Linear** — one fixed order, everyone eventually unlocks everything. This is the Dome Keeper problem. Not recommended.
- **B) Currency + junction choices** — fragments give general tech points AND sometimes a rare unlock-key for one specific branch; at key points you pick ONE of several mutually exclusive options, forcing real specialization.
- **C) Fully separate parallel trees per build type** — most build-distinct, but means designing/balancing 4 trees instead of 1, real scope risk.

**Leaning:** B. Gets real build diversity without needing to design and balance multiple separate trees.

---

## 7. Build axes
*(what a "build" actually consists of — pick which of these we want, doesn't have to be all 4)*

- **Gatherer** — yield/speed/carrying capacity, leans on the mining/economy loop
- **Combat/Aggressive** — survive dangerous zones, faster access to guarded areas
- **Stealth/Social** — better at avoiding detection + lying, higher recruitment ceiling (ties into Social Standing)
- **Scholar/Lore** — better/faster at finding and decoding records, earlier lore-gated tech access

Each build should feel different to *play*, not just have different numbers:
- Gatherer = calmer, sustainable, slower story pace
- Combat = faster access to danger + its rewards, higher variance
- Stealth/Social = safer overall, best endings/recruitment, slower raw production
- Scholar = fastest mystery progress, weakest raw production — trades power for story

**Leaning:** Keep all 4 — they map directly onto systems we're already building (economy, combat, Social Standing, lore), so it's not new content, just new framing on existing systems.

---

## 8. Build reset vs. carryover between acts

- **A) Full reset each act** — cleanest "fresh start" feel, but wastes players' earlier choices mattering.
- **B) Full unrestricted carryover** — nothing resets, but risks the tree feeling static/"more of the same" by Act 3.
- **C) Hybrid** — permanent core upgrades (drill, gear, standing perks) carry across all acts; each act adds a new resource type that gates a new branch, so the tree keeps growing without repeating.

**Leaning:** C — matches our "one loop reskinned three times" scope plan, keeps early choices meaningful without staleness.

---

## 16. Save system / permadeath policy
*(directly follows from #13)*

- **A) No permadeath at all** — safest for players, lowest tension
- **B) Partial** — failing/getting caught on an expedition costs you unbanked resources/time and maybe a Social Standing hit, but never resets your whole save
- **C) Full permadeath on failure** — only makes sense if we go with #13 option A (true roguelite)

**Leaning:** B — consistent with #13's hybrid recommendation.

---

## 20. Dialogue system

- **A) No player choices** — NPCs just deliver lines. Cheapest, but doesn't actually match what we've designed — the lie mechanic, recruitment, and alien contact all already require the player to decide something.
- **B) Lightweight contextual choices** — no branching conversation trees, just discrete decision prompts at key moments (e.g. "Lie about where you were?" Yes/No, "Attack or approach?"). Most NPCs just talk; only specific moments get a choice.
- **C) Full branching dialogue trees** (Mass Effect-style conversation wheels, many lines/paths per NPC) — expensive: heavy writing load, dedicated UI, every branch needs testing. Real scope trap for a 3-person team.
- **D) Hybrid** — most NPCs just talk (lore, comedy, world-building, no choices needed); a small, deliberate set of key moments (lie mechanic, recruitment beats, alien contact, villain confrontation) get real discrete choices.

**Leaning:** D — this is what we've actually already designed everywhere else in this doc, just not named as a dialogue system yet. Keep choice points rare and meaningful rather than building toward full branching trees everywhere, which would be a different, much bigger game than what we've scoped. **Act 1 requirement (locked via #28):** the Hollow needs ordinary NPCs who work/live/play/chat under option D's "most NPCs just talk" lane — presence and texture, not a full dialogue sim.

---

## 21. Combine/repair/escalation system
*(the Inscryption-inspired "push your luck" mechanic — this is actually 3 related pieces, worth keeping distinct)*

**Piece 1 — Repair:** broken salvage/ship parts can be repaired into functional tools. Not really new design — this is our existing salvage → mechanic pipeline, just narrated as restoration instead of an abstract unlock.

**Piece 2 — Fusion/combine:** two different tools/parts can be combined into something stronger (e.g. a multitool), with a real risk that both items break in the attempt. Ties directly into decision #5's "optional higher tier, real cost" model — this is that tradeoff made concrete. One-time transformation per pair, not repeatable.

**Piece 3 — Escalating repeated risk ("push your luck"):** grounded directly in how Inscryption's campfire actually works — first use is safe, then each additional use on the same thing carries escalating failure risk (their real numbers: ~22.5% / 45% / 67.5% chance of loss on the 2nd/3rd/4th attempt), capped at a max of 5 attempts total. Answers a different design question than fusion: fusion is "what do I combine," this is "how far do I push one thing." Keep it **rare** (specific locations/opportunities, not a repeatable menu action) — this is what keeps it a deliberate tense event instead of a compulsive slot-machine loop.

- **Consequence categories** (so failure isn't repetitive): physical/incapacitation (bedridden, lose time), social (Social Standing hit, villain suspicion rises — reuses our existing system directly), material (attempt fails, resource wasted).
- **Open sub-decision:** do all 5 tiers share one downside type, or do later tiers roll from scarier categories than early ones? Changes how "safe" early tries feel vs. late ones — worth deciding once we're actually tuning it, not today.

**Related, locked decision — no Social Standing "fix-it" item.** We considered an ultra-rare item that restores Social Standing and decided against it: any mechanic that can undo consequences undercuts the reason the standing system has tension in the first place. Instead: **a bad standing hit is permanent for that playthrough**, and standing recovers only slowly, through sustained ordinary good behavior — not a lucky find. More honest to the theme (some trust doesn't come back), and keeps replayability about "lie less next time" rather than "hunt for the fix."

---

## 25. "Magicians" — sanctioned vs. forbidden tech
*(locked in as core lore/systems logic — a few sub-questions remain open)*

**The concept:** some Hollow residents operate old salvaged machinery by rote, inherited practice, without understanding it — everyone calls this magic, because that's what it genuinely looks like. This isn't just flavor: it's *why* the villain's power works. A settlement that thinks its tools are magic has no framework for questioning who controls them, so he encourages the framing rather than merely tolerating it, and likely positions himself as the most gifted magician of all — reads as harmless in Act 1, recontextualizes hard once his identity is revealed in Act 3.

**The tech split, mapped onto existing systems (not a new one):**
- **Sanctioned/"safe magic"** (mundane, utilitarian — fire-starting, filtration, structural) → **efficiency upgrades**, openly used, boosts **Hollow production-district** passive rates (and later the surface settlement)
- **Forbidden/"dangerous magic"** (anything that could reveal the truth — navigation, comms, records, legible data) → **knowledge upgrades**, hoarded/restricted, tied directly to the risk/Social Standing system (#3, #16, #21)

**Why it's worth it:** costs nothing new to build — it's a diegetic skin on the existing Materials/Records split (#6, #29) and the existing efficiency/knowledge upgrade categories already implied by the passive-generation and tech-tree systems. Gives the villain a personal stake and presence in Act 1, long before his Act 3 reveal, without spending any extra dev time on a new mechanic. Efficiency upgrades also feed **siphon cover** (#28): healthier district output makes diversion harder to notice.

**Open sub-questions:**
- Exact term for this in-world ("magicians" works fine as a placeholder — worth revisiting once we're naming other Hollow-specific vocabulary)
- How strictly the sanctioned/forbidden line is enforced in-fiction — is it an unspoken norm everyone just follows, or does the villain (or his allies) actively police it? Affects how much of a threat "getting caught with forbidden tech" should feel like in Act 1 versus just a stronger Social Standing risk (#21's social consequence category already covers the mechanical side either way).

---

## 28. Act 1 Hollow society layer — production districts, siphon cover, living NPCs
*(✅ locked — corrects underweighted Act 1 scope; do not treat as Act 2 settlement work)*

**The concept:** Act 1's Hollow is a working underground society, not an empty home hub.

1. **Production districts** — a small set of named areas (#2) that passively generate *different* communal resources. Player efficiency/"safe magic" upgrades raise those rates over time. Harvest remains the communal rhythm/clock; districts are the ongoing economy underneath.
2. **Siphon cover** — diverting materials/effort for personal dig upgrades is safer when district output is healthy, and riskier when production is thin. Helping the society and stealing from it are the same economy viewed two ways.
3. **Living NPCs** — characters who work, live, play, and chat in those spaces. Required for Act 1's "might be the whole game" feel. Dialogue stays lightweight per #20 (most NPCs just talk; rare choice prompts only).

**Scope guardrails:**
- Same passive formula family as later settlement/ship tiers (pitch guardrail) — different flavor numbers and district outputs, not a second prestige economy.
- Districts + NPCs stay simple: rates, presence, light talk — **not** RimWorld, schedule sims, or full branching dialogue trees.
- Do **not** invent Act 2 surface settlement/recruitment features here; this is the underground society only.

**Why lock it now:** passive generation was already in the pitch, but districts-as-upgradable-areas, siphon-safety-from-healthy-output, and a populated Hollow were easy to underweight into "timer + empty siphon booth." Those three are Act 1 canon.

---

## 29. Act 1 Materials, inventory, and siphon spend
*(✅ shape locked USER — names proposed in [`materials.md`](materials.md); confirm names before full code rename)*

**✅ Locked (USER):** Go with what the story already suggests — **not** a Salvage-only upgrade shop.

1. **Category:** dig finds are **Materials** (player-facing category). Drop “Salvage” as the economy label (too generic). Specific material *types* are what you find and hold.
2. **Multi-type dig haul:** expeditions return several Material types that feed districts, craft/forbidden components, and later Tallies turn-in — plus separate **Records**.
3. **Siphon** spends **communal District production** (Glowrations / Glowfiber, Wicklamps / Bindcord, and Presswater / Clearwater — names proposed), not a single dig wallet.
4. **Efficiency / safe magic** raises production rates so healthier available production improves Siphon **Cover** (incentive to help society).
5. **Inventory** is required for the demo economy (thin list/grid + soft carry caps OK).

**Proposed dig Materials (confirm/edit):** Sporemeal, Lampwick, Brinecrystal, Verdigris, Hullbit — full table in [`materials.md`](materials.md).

**Open (next, one at a time):** Efficiency UI placement (separate Requisition vs shared panel) — Decision follow-up after names OK. Dig Yield sanctioned vs forbidden still open (act1-demo-plan Q3).

**Code backlog:** `resources.gd` / Salvage HUD still use old naming — rename path Salvage → Materials system after docs confirm; do not treat current Salvage wallet as canon fiction.

---

## 26. The Journal — unified lore/mystery UI
*(consolidates three inspirations — Outer Wilds' Rumor Board, Obra Dinn's confirm-a-fact mechanic, Subnautica's codex — into one feature rather than three)*

**The concept:** a single Journal screen giving the player a satisfying place to see what they've pieced together, instead of lore only ever appearing as one-off popups that vanish from memory. Directly serves the Scholar build axis (#7) and the whole dual-purpose tech tree (#6) by giving them a payoff screen.

- **A) Full three-view Journal** — a Rumor/Connections view (fragments visually linked as you find them, node-graph style), a Confirmed Facts view (the central mystery, locked in piece by piece as you gather proof), and a Codex view (Reef creatures, alien lore). Richest, most faithful to the inspirations, but the connections graph is real, non-trivial UI/visual design work — closer to a small feature of its own than a display screen.
- **B) Two-view Journal** — merge the rumor and confirmed-facts ideas into one evolving "Mystery" list (no visual node-graph, just a categorized, updating list of what you know and what's still theory), plus a separate Codex view for creatures/lore. Gets most of the value of A at a fraction of the UI cost — no graph-drawing logic needed.
- **C) Single unified log** — one categorized, filterable list covering everything (mystery clues, creatures, lore) with no separate views at all. Cheapest, still functional, loses some of the "watching the picture assemble" satisfaction that made Outer Wilds' and Obra Dinn's versions memorable.
- **D) No dedicated system** — lore stays as it is now, one-off popups only. Not recommended: this is the exact thing the three inspirations prove players want a home for, and it costs comparatively little to build even at option C's level.

**Leaning:** B — real payoff for the mystery/build systems we've already committed to, without taking on graph-UI complexity we haven't budgeted for. Can revisit toward A later if there's spare capacity.

---

## 9. Which system is our ONE "deep" pillar?
*(the thing we polish hardest; everything else stays intentionally simple)*

- **A) Tech tree / build system** — our team's stated strength and interest; directly fixes Dome Keeper's #1 complaint
- **B) Mining/exploration feel** — the core moment-to-moment loop
- **C) Story/mystery delivery** — the dual-purpose lore system, pacing of reveals
- **D) Settlement/passive generation** — the incremental economy layer

**Leaning:** A. It's the thing we're most excited about AND the thing that most directly differentiates us from Dome Keeper. B still needs to feel good but doesn't need to be the deepest system; C and D should support A rather than compete with it for dev time. **Clarification (locked via #28):** "D stays simple" does **not** mean Act 1 ships without Hollow production districts or living NPCs — those are required Act 1 content, just intentionally lighter than the tech tree.

---

## 13. Core structure: roguelite runs vs. persistent campaign
*(⚠️ this is the biggest hidden ambiguity in the doc — we've used "roguelite" as a genre comp since Dome Keeper, but everything we've actually written is a linear 3-act story with one persistent world. These are genuinely different structures. Needs a clear answer.)*

- **A) True roguelite** — expeditions/runs can end in failure, resetting most progress each time; procedurally varied; meta-progression carries between runs. This is Dome Keeper's actual structure.
- **B) Persistent single campaign** — one continuous save, story moves through the 3 acts linearly, checkpoint saves, no permadeath. Closer to SteamWorld Dig/Metroidvania structure.
- **C) Hybrid** — one persistent story/world/save overall (matches everything we've written), but individual expeditions carry real risk — fail or get caught and you lose unbanked resources/time, not your whole game. This is what our design has actually been describing this whole time; we just haven't said it out loud.

**Leaning:** C. Naming it explicitly now avoids confusion later — "roguelite" should be understood as flavor/comp for the expedition tension, not literal permadeath structure.

---

## 14. Camera & perspective

- **A) 2D side-view** — matches Dome Keeper, SteamWorld Dig, and our pixel art choice directly. Best genre precedent.
- **B) Top-down** — different feel, more common for base-builders/twin-stick, less natural for a "digging deeper/climbing up" game.
- **C) Isometric** — visually distinct, but harder to do well in pixel art and adds real complexity to digging/terrain mechanics.

**Leaning:** A — matches everything else we've already locked in (art style, comps, digging mechanic).

**✅ Locked (2026-09):** Stay **A**. Sea of Stars–style oblique JRPG camera evaluated and rejected for Act 1 (fights Firmament↑/Pit↓ dig; wrong cost). Steal SoS lighting/layering craft only — **no camera hybrid**. Full visual bible: [`art-direction.md`](art-direction.md).

---

## 15. Combat system type
*(ties back to our own "skill-based but not twitch" goal from early on)*

- **A) Real-time action** — closest to typical arcade combat, but leans twitchy/reflex-based, which cuts against what we said we wanted.
- **B) Real-time but tactical/positional** — Dome Keeper's wave-defense model: you're making positioning/timing decisions in real time, but it's not reflex-fast. Good middle ground with direct precedent.
- **C) Turn-based tactics** — Into the Breach style: zero reflex requirement, pure decision-making. Furthest from Dome Keeper's precedent, more of a build/production risk since it's a different combat paradigm than our closest comp.

**Leaning:** B — matches our comp, and matches the "active but not twitchy" goal without introducing a whole new combat paradigm to design and build.

---

# 🎨 ART & PRESENTATION DECISIONS

## 10. Art style
*(this is a bigger constraint than most decisions here — we have no dedicated artist, so this choice should be picked partly FOR its low skill floor, not just its look)*

- **A) Pixel art** — lowest skill floor of any style, huge tool/tutorial/asset-pack support, and it's the exact style Dome Keeper and SteamWorld Dig both used at our team size. Aseprite is the standard tool. A non-artist can get functional at simple pixel art faster than almost any other style.
- **B) 1-bit / very limited palette (Obra Dinn-style)** — even cheaper to produce than full pixel art (fewer colors/shading decisions per asset), strong moody/mysterious read, but risks undercutting the "surface should look wondrous and vibrant" goal — this style leans stark, not colorful.
- **C) Flat vector / paper-cutout style** — clean, scales well, decently approachable for a non-artist using tools like Aseprite/Figma/Illustrator, but has less genre precedent in this exact space and can look flat without careful shading.
- **D) Low-poly 3D** — can look great, but 3D adds real scope we haven't budgeted for (rigging, lighting, camera work, more complex tooling) — not recommended for a 3-person team on this timeline.
- **E) Hand-drawn/painterly** — highest visual ceiling, but needs real illustration skill we don't have on the team. Not recommended.

**Leaning:** A. It's the only option with direct precedent at our exact team size AND team skill level, and it gives us a concrete design tool for free: **use a deliberate palette shift for the reveal** — dark, warm, earthy tones underground vs. vivid, strange colors on the surface. The art style itself can help sell the "the world doesn't end, it explodes into color" moment, which is a cheap, high-impact way to reinforce the twist.

**✅ Where we're leaning as a team: detailed pixel art** (mid-to-high resolution, more expressive than 8-bit — Eastward/Owlboy / Dead Cells territory, not minimalist). AI-assisted for concept art and static single-frame sprites; human hand-finishing for tileset seams and animation frames, since those are AI's current weak points.

**Craft refs (steal craft, not tone):** INMOST (ink voids, lantern light, quiet UI) + Blasphemous 2 (screen density, parallax, ambient micro-life) — not grief-horror or Catholic body-horror. See [`art-direction.md`](art-direction.md).

---

## 23. Surface visual identity: "the Reef" + biomes vs. one identity

**The concept:** the surface looks like a colorful underwater reef but isn't underwater — the planet's atmosphere is simply denser than Earth's, so things drift instead of fall, dust/spores hang like silt, plants sway on slow air-currents, creatures glide. A real diegetic fact, not just a visual trick — also explains native-species design (graceful/drifting, not aggressive-looking, which supports the misunderstanding-not-malice tone). Bonus: if the Reef's life is bioluminescent like the Hollow's lanterns/glowbugs, we get one visual language connecting both halves of the game.

- **A) One core identity ("the Reef"), varied by depth/density** — shallower = sparse/sunlit, deeper/further = denser/darker/stranger/more bioluminescent. Same core assets recombined, not new asset categories per zone.
- **B) Multiple distinct biomes** (desert, ice, jungle-style variety) — richer visual variety, but separate tile sets/creature designs/palettes per biome. Real added art cost.

**Leaning:** A. Matches the art-scope discipline we've applied everywhere else (#9, #10) — same "one thing, reskinned" economy applied to art instead of gameplay. Distinct biomes are a stretch goal only with spare late-dev capacity, not baseline plan.

---

# 💼 PRODUCTION & BUSINESS DECISIONS

## 17. Team roles & workflow tools
*(not really "pick an option" — more "decide this explicitly today so nobody assumes")*

Things to actually assign out loud:
- Who owns programming, who owns art/pixel work, who owns writing/lore, who owns production/project management (could be split, could overlap)
- Project tracking tool: Notion, Trello, a plain Discord channel, or something else
- Version control: GitHub (or similar) from day one, even for a small team — avoids painful merge problems later
- Communication cadence: regular check-ins vs. ad hoc

**No leaning here** — this is genuinely a "decide together" item, not something to pre-recommend.

---

## 18. Monetization & release plan

- **A) Straight 1.0 premium launch** — build the whole thing, launch once, priced $10-20. What Dome Keeper and AGADAH both did.
- **B) Early Access premium launch, then iterate** — get real player feedback and revenue earlier, common for small teams, but means shipping a rougher version publicly and managing live feedback while still building.
- **C) Free demo + premium full release** — lower-risk way to test if the hook lands before asking for money, common on Steam now, but is its own extra scope (a demo needs its own polish pass).

**Leaning:** open — worth deciding once you have a sense of how long full development will realistically take; A is simplest, B is a reasonable de-risking move if the team wants earlier feedback/income.

---

## ✅ Fastest path through this doc if we're short on time

Priority decisions (need answers to actually start building): **#3, #4, #6, #9, #10, #13, #14, #15, #20, #21, #22, #23, #24, #25, #26, #28, #29**
Can defer safely to later: **#1, #2 (names only — district *role* locked in #28), #11, #12, #16, #18, #19, #27**
Decide explicitly regardless of time: **#17** (team roles/workflow — can't skip this one)
