# 🎮 GAME PITCH — "Krater"

> **One line:** You're a kid in an underground society built into the walls of the massive Devil’s Mouth — forbidden from digging up, and quietly the only person who's ever wanted to. You break the taboo, reach a surface no one knew existed, and slowly uncover the truth: your people are crash-landed colonists on an alien moon, and the answer to everything was always waiting at the bottom of the Mouth everyone else spent generations staring into.

*(This doc stays high-level. **Mechanics source of truth: [`mechanics-canon.md`](mechanics-canon.md)** — where this pitch and the canon disagree, the canon wins. Open decisions live in the companion **Decisions doc**. Living narrative detail and story idea inbox: [`story.md`](story.md).)*

---

## 🕹️ WHAT KIND OF GAME IS IT

A **persistent-world game of civic life, underground exploration, physical excavation and hauling, build progression, mystery, and quiet transgression** — with a living district economy and a story campaign. Think:

- **Dome Keeper** (2-person team, made ~$1M) — the physical satisfaction of extraction and hauling, inside a persistent world rather than a run-reset mine. Proof our team size can pull off this *kind* of game.
- **Terraria** — local digging freedom inside controlled excavation zones, layered under an authored settlement and story geography.
- **SteamWorld Dig** — dig-and-upgrade with a world that opens up as you progress.
- **Inscryption** — for the mystery pacing, the slow reveal, and "the game is bigger than you first think."

**Why this fits us:** it's systems-heavy and light on hand-drawn art/animation (plays to a coder-driven team + AI-assisted coding). Simple pixel art. Godot engine (free, exactly what Dome Keeper used). Premium game on Steam, ~$10–20, no live-service/monetization treadmill needed. Digging itself is one mechanic pointed in two directions (up and down — more on that below), so we're getting two forbidden frontiers out of one system to build, not two.

**The key insight:** Dome Keeper's most common criticisms are (1) builds collapse into one obvious path, (2) no story, (3) gets repetitive. Our whole concept — real build variety, a mystery campaign, a capability web that doubles as lore — is basically a checklist of the things people *wished Dome Keeper had.*

**Genre honesty check:** this is **not** an idle or roguelite game. Districts produce once per civic cycle, not per second; there is no AFK farming, no permadeath, and no expedition reset. Failure continues the world in a changed state. Progression changes what the player can *do, perceive, and risk* rather than mainly escalating numbers.

---

## 🔁 THE CORE LOOP (how it actually plays)

One loop, reused across the whole game so we're not building four separate games:

**Live in the Hollow → take civic work or explore → travel, dig, extract, and haul → decide how far to push → keep, cache, deliver, order, or secretly divert → return to a Hollow that responds → improve your Rig, districts, knowledge, and access → reach new places.** (Full loop: [`mechanics-canon.md`](mechanics-canon.md) §1.)

- Early game the loop runs across two frontiers: *sideways*, into braced civic galleries that expand the Hollow and yield Materials, and — secretly — *up*, toward the Firmament everyone's mythologized. Same traversal, digging, hauling, and progression systems support both; there is no separate "work mode" and "adventure mode." The Devil’s Mouth remains a feared central crater, not the ordinary mining route.
- Mid/late game it's **running expeditions onto the surface** and hauling stuff back, while Devil’s Mouth descent deepens in parallel as a slower secondary thread.
- The *pressure* comes from stamina, fatigue, hauling, civic time, commitments, evidence, and social consequence — NOT a monster-mash. Skill = deciding what to grab, how far to push, when to turn back.

**⭐ Running underneath all of that: a living civic production economy, transformed rather than discarded across the game:**

- **The Hollow:** Glowbeds, Wickwork, and Cistern each produce civic output **once per civic cycle** from Production Capacity against Civic Demand, with a finite Reserve. Districts stay stable without babysitting; shortages create contextual problems (delayed lift repair, thin recovery support) rather than meter chores. Players raise Capacity through discoveries, Materials, Components, Records, and projects — and the same Reserve that legitimate Approved Gear orders draw on is what secret diversion steals from.
- **The surface settlement:** district traditions evolve into settlement production (agriculture, manufacturing, water/power) (Act 2).
- **The ship:** the same Materials + Components + knowledge + production + infrastructure architecture at the largest scale (Act 3).

**Guardrail:** no idle-style per-second production, AFK farming, or sleep-spam as optimal play, and no separate prestige economy per act. If a tier needs its own disconnected economy, that's scope creep — flag it.

---

## 📖 THE STORY (with how each part = gameplay)

### ACT 1 — Underground (the taboo)

Generations ago a colony ship was shot down (more on that later) and swallowed into the crust of an alien world, tearing open the massive shaft now called the Devil’s Mouth. The survivors built their settlement directly into and around that wound — homes, walkways, and workshops layered over, across, and into a void that plunges out of sight. Over generations the truth of what happened rotted into myth, and the Devil’s Mouth itself became a permanent fixture of daily life: everyone in the Hollow has a theory about how deep it goes and what's down there, because nobody who's gone far enough has ever come back to settle the argument. It's the one thing the whole community can't stop talking about.

At the same time, everyone's raised to believe **this is simply how the world is**, and the one unbreakable rule going the *other* direction is: never dig upward. The myths say the rock overhead will collapse and crush everyone. Nobody needs convincing to be careful around the Devil’s Mouth — it's obviously dangerous, no story required. The Firmament is different: there's no real evidence it's dangerous at all, which is exactly why it needed an actively retold myth to keep working generation after generation. Living side-by-side with a genuinely risky, unmythologized void and a harmless, elaborately mythologized ceiling means players can *feel* the difference between organic caution and manufactured control before the story ever explains it — which is the whole engine behind our villain, later.

You're a kid who never really bought the Firmament story. You don't hate your home, you don't love it — it just *is*. And where everyone else's curiosity points down, into the Devil’s Mouth they'll never stop wondering about, yours quietly points up, somewhere nobody else even thinks to look. That asymmetry is who you are before anything else happens: not a rebel, just someone whose attention is aimed in the one direction nobody shares. Then something — a doubt, a crack, a fragment you find — sets you digging upward in secret, incrementally, a little at a time, in a hidden pocket, stealing hours and Materials from daily life. Public crews meanwhile push sideways into braced galleries to expand the Hollow; those ordinary excavations occasionally expose the first hints that the two mysteries share a root.

**Naming: "the Hollow"** — going with this for the overarching name for now. (Ceiling/taboo naming: open — see Decisions doc #1.)

**Realism note on naming:** the Hollow is the *entirety of existence* as far as its people know — nobody living there thinks of themselves as living "in the Hollow" any more than we walk around saying "I'm going back to Earth." "The Hollow" is a name **we (the player/dev team) use**, and possibly an old, semi-formal or ceremonial term within the lore — but in day-to-day dialogue and flavor text, people should reference **named subsections** (districts, tunnels, chambers — see Decisions doc #2) rather than saying "the Hollow" constantly. This keeps the writing believable and avoids the "as you know, Bob, we live on Earth" problem.

**The comedy + folk beliefs (lightly sprinkled):** nobody actually knows what's up there or down there, so people have invented wild explanations for both. Some genuinely believe they live **inside the belly of a giant beast** — the Firmament is its stomach, the Devil’s Mouth is its throat, tremors are it being hungry, and digging either direction will "wake it." Others think the surface is where the dead go, or that the bottom of the Mouth is where they came from. One guy insists it's just rock, in both directions, and everyone's overthinking it (he's right, and nobody listens to him). Kids have creepy nursery rhymes about the ones who dug up, and separate ones about the ones who went down too far. This keeps the tone curious/warm, not grim.

**"Magicians."** A handful of people in the Hollow have learned to operate old machinery pulled from the crater walls — by rote and inherited practice, not understanding — and everyone else calls what they do magic, because that's genuinely what it looks like when nobody knows why it works. This isn't background flavor, it's load-bearing: the villain didn't stumble into power by accident, he erased the *knowledge* of what this tech actually is while letting its *use* continue — because a settlement that thinks its tools are magic has no framework for questioning who controls them. He likely encourages the magic framing rather than merely tolerating it, and may quietly position himself as the most gifted magician of all — a detail that reads as harmless local color in Act 1 and lands very differently once the player knows who he really is.

Not all tech gets the same treatment, though. Anything mundane and utilitarian — fire-starting tools, water filtration, structural reinforcement — is sanctioned, openly used, "safe magic." Anything that could actually reveal the truth — navigation instruments, communication devices, ship logs, legible data of any kind — is hoarded, restricted, or quietly destroyed, because that's the tech that could unravel his story. Players won't know this distinction exists yet in Act 1 — it's just "some magic is common, some is rare and suspicious" — but it maps directly onto real mechanics below.

**GAMEPLAY IN ACT 1:**
- **Production districts in the Hollow** — Glowbeds, Wickwork, and Cistern produce civic output each cycle. The player influences their development through discoveries, Materials, Components, Records, and work — never a city-builder menu.
- **The Pulse and Ritual** — the Pulse, a degraded ship relic at Mid Heart, sets the civic cycle (Rousing → Working → Gathering → Ritual). **Ritual** is the communal return anchor: gathering, accountability, and story. Time creates rhythm and social expectation, not constant rushing; missing Ritual is contextual.
- **Jobs as invisible tutorials** — early civic work (Dispatch → worksite → excavation → haul/deliver → Tallies → Ritual) teaches the game through believable participation. Later, the player may ignore work to explore; not helping is not the same as promising and failing.
- **A living Hollow** — people who work those districts, live in the chambers, play, and talk. Act 1's home base must feel inhabited; an empty upgrade booth fails the "might be the whole game" design goal.
- **Two-frontier digging** — the same tools push sideways into civic side galleries (public work that expands the Hollow) and, secretly, upward. The **Firmament is thick**: breaching it is a sustained multi-session project from a hard-won Ashram Heights residence.
- **Discoveries** stay ambiguous everywhere this early (could be read as myth, religion, or history — never clearly "we're on an alien planet"):
  - **Materials** = Sutral, Ravelstone, Brinecrystal, Verdigris, and Hullbit — finite, physically hauled, multi-use.
  - **Components** = smaller ship-derived parts.
  - **Records** = knowledge that can unlock Approved capabilities, district projects, routes, or Forbidden Designs — and whose sharing is the player's choice.
- **Approved vs Forbidden Gear** — public progression: work → Tallies → Order Approved Gear. Secret progression: explore → understand → recover Material/Component → divert district output → privately build Forbidden Gear. One shared economy, no dark currency.
- **Trust (important, runs the whole game):** qualitative, explainable social standing. Being caught stealing, exposed lies, broken commitments, and forbidden evidence damage it; reliability and meaningful help build it. Detection is sight, sound, and persistent evidence; suspicion is local. There is no lie button — questioning leads to truth, lie, deflection, or partial truth, and exposed lies hurt more than honesty. Trust gates access now and recruitment later. **Act 1's small personal risks become Act 3's payoff.**

**🎯 DESIGN GOAL: Act 1 should feel like it might be the whole game.** No visible "surface" tab, no locked branches hinting at more. The player should brace for punishment when they dig up, NOT anticipate a reveal — the world only turning out to be bigger than shown should land as a genuine surprise, not something the player was quietly expecting. The Devil’s Mouth stays a constant, lived-with mystery throughout — never confirmed, never explained, just always there in the background the way it is for everyone else in the Hollow.

**Bonus continuity:** "Krater" — our locked title — is literally what the Devil’s Mouth is. Not just a name we picked, but the actual crater the ship carved out generations ago.

---

### ACT 2 — The Breach (the reveal + survival + settlement)

You break through. **The world doesn't end.** Instead: a vast, alien, wondrous landscape — strange colors, impossible formations, distant structures. Not a wasteland — *beautiful*, which makes it even harder to square with everything you were taught. (It has **some verticality** — cliffs, layers, things to climb — but isn't a pure vertical world.)

**⭐ Visual identity: "the Reef."** The surface looks like a colorful underwater reef — but isn't underwater. The planet's atmosphere is simply denser than Earth's: things drift instead of fall, dust and spores hang and swirl like silt, plants sway on slow air-currents instead of wind, creatures glide rather than fly. This is a real diegetic fact about the world, not just a visual trick — and it quietly explains why the native species might look/move the way they do (evolved for a denser medium — graceful and drifting, not aggressive-looking). Bonus continuity: bioluminescence already exists in the Hollow (lanterns, glowbugs) — if the Reef's life is *also* bioluminescent, just wilder and more colorful, we get one visual language connecting both halves of the game, escalated rather than reinvented.

**One core identity, not many biomes.** Rather than building several distinct biomes (real added art cost for a small team), we lean on ONE strong aesthetic pillar with depth/density variation — shallower reaches sparse and sunlit, deeper/further reaches denser, darker, stranger, more bioluminescent. Same core assets recombined and recolored, not new asset categories every zone. Distinct biomes are a stretch goal only if we have spare capacity late, not the baseline plan.

**First truth:** the "collapse" was never real. It was a story wrapped around knowledge no one below ever had.

**Surface threats:** the world is gorgeous but has hidden teeth, revealed the deeper you explore. Open — see Decisions doc #3.

**GAMEPLAY IN ACT 2 — this is where the game opens up:**
- **Surface expeditions:** the core loop, reskinned. Venture out, gather alien resources + salvage the *real* ship wreckage (bigger finds than the scraps below), race back.
- **Return pressure / Trust:** you still have to go back down to keep relationships and commitments alive. Absence is contextual, as in Act 1 — one social system, whole game.
- **The Devil’s Mouth keeps deepening alongside everything else** — better drills and survival gear pulled from surface Materials let you push further down than Act 1 ever allowed, in parallel with your surface progress. Still no confirmation of what's at the bottom — just further, and stranger.
- **⭐ BUILD A SURFACE SETTLEMENT:** you establish a camp up top. As you recruit people — from below, and eventually from every relationship thread the story opens up — they populate it and **auto-work** (gathering, crafting) — this is our incremental/auto-farming engine. Crucially, **because you've got salvaged tech, the surface settlement is MORE efficient than the underground society** — that contrast is the point: the life everyone was taught to fear is better than the one they were told to accept.
- **Recruitment has three sources by the end of the game, all sharing the same underlying system** (same generic worker slot, gated the same way — just a different recruitment beat and flavor per source, not a separate mechanic each): Hollow recruits, gated by your Trust (from the caught/lie system); the runaway settlers, once you find them (below); and, if you make peace, the native species themselves. More people from any source = bigger, faster settlement = closer to building the ship.
- **Hints of the other survivors:** you find signs that a *second* group survived the crash and stayed on the surface generations ago, splitting from your ancestors over a dispute nobody remembers — and unlike the Hollow, whose people you're persuading to leave everything they know, these are people who already chose the surface once. Finding them and winning them over is a second, distinct route into your settlement's growth, not just a lore beat.

---

### ACT 3 — The Truth (origin, villain, and the ship home)

Using **records from below + salvage from above**, you finally have enough to reconstruct what actually happened — and it converges from every direction at once.

**The crash was a misunderstanding.** The world's **native intelligent species** shot the colony ship down — not out of malice, but fear. They saw something huge descending and reacted like anyone would. A tragedy of first contact, never undone. The wreck didn't vanish; it tore open the Devil’s Mouth the Hollow has been staring into for generations, and it's still down there.

**The villain is still alive.** The founding myth wasn't just superstition — it was *built*, deliberately, by one of the original survivors: a scientist who's kept himself alive for generations using medical stock recovered, long ago, from deep in the Devil’s Mouth itself — meaning he's the only other person who ever went as far down as you're about to. He's now one of the society's elders, quietly known as the most gifted of the Hollow's "magicians" — a reputation that read as harmless local color for two acts and now recontextualizes completely: he didn't just tolerate the magic framing everyone lives under, he built his entire authority on being its supposed master, while personally hoarding the one category of tech — records, navigation, anything that could reveal the truth — that "magic" was never allowed to touch. He's spent his long life controlling what everyone believes and staying one step ahead of the truth, and he has real personal reasons to have discouraged anyone else from finishing what he started. If he learns you're digging and recruiting, he becomes an active threat — and his weapon is what it's always been: **the story itself.** He'll try to rewrite your discoveries into new myth before you can spread the truth.

**The thing in the sky.** There's a shape the society has always had a name for — a guiding light, a myth. It's **the real homeworld**, in view the entire game, mistaken for a star/moon because no one below ever thought to wonder if it was real. This world is its **moon**. So "home" is right there — the ship just has to cross local space.

**The bottom of the Devil’s Mouth.** This is where it all lands. Access has been opening gradually all game, tech-gated the same way everything else is — but the true bottom, a full view of the ship or a real chunk of it, is reserved for right here, tied to something you actually need: a component for the escape ship, or a flight recorder that nails the crash cause in the founders' own words. Not lore for its own sake — mechanical weight too. And the payoff line writes itself: **everyone in the Hollow spent generations staring at the answer to everything, and never once thought to look up instead.** Your whole arc, in reverse, is the mirror of theirs — you're the one person who looked in the direction nobody else did, and it turns out the two mysteries — what's above, what's below — were always the same one.

**GAMEPLAY IN ACT 3:**
- The **ship = the largest-scale project of the same capability web and production architecture**, not a new genre. Everything you've built — upward and downward — funnels into it.
- **The alien-contact choice:** you can find the native species' settlement and choose to **fight or make peace** — and it's a genuinely hard call, because *by now you know they're why your people crashed.* Choosing peace can unlock a third tech branch (trade/shared knowledge) and opens the native species as your settlement's third recruitment source — the biggest possible reward for the hardest choice in the game, since you'd be building a shared future with the people who ended your old one. Fighting closes both off, but opens others.
- **The ending is driven by your Trust + recruitment across all three sources:**
  - Expose the villain and leave him behind
  - Defeat him in a final confrontation
  - He stays and convinces others NOT to go with you — and **the number of people who leave vs. stay depends on how many you convinced over the whole game, from the Hollow, the runaway settlers, and — if you chose peace — the aliens themselves.** Your choices across all three threads literally shape your ending headcount.

---

## 🧩 THE SYSTEMS THAT MAKE IT UNIQUE (vs. Dome Keeper)

1. **Discovered capability web** — technology moves from Known → Understood → Available through Records, Components, Magician knowledge, and exploration. Recovered ship knowledge literally upgrades you and explains your origin. Solves Dome Keeper's "no story" + "thin content" at once.
2. **Qualitative builds** — Gear changes what you can do, perceive, reach, and risk, across five overlapping dimensions (Excavation, Survey, Hauling/Endurance, Mobility, Secrecy) under soft Rig Capacity. Kills the "one obvious build order" problem.
3. **Trust** — qualitative, explainable social standing driven by what society actually knows: commitments, exposed lies, caught theft, meaningful help. Gates access and recruitment and shapes the ending. Gives the game *memory* and makes choices matter.
4. **A civic production economy that transforms across the game (Hollow districts → settlement → ship)** — Act 1 districts produce each civic cycle; legitimate orders and secret diversion draw on the same Reserve. Later acts expand the same architecture (surface life > the life you were told to fear, made visible once Act 2 exists).
5. **One dig mechanic, two story frontiers** — the same growing toolset serves both Firmament breach work and public lateral civic excavation, while the Devil’s Mouth remains the slow-burn mystery converging in Act 3. Two mysteries for the cost of one system.
6. **One recruitment system, three narrative sources (Hollow, runaway settlers, aliens)** — same generic worker slot and standing-gated logic every time, but each source is a different relationship thread paying off into the same settlement number. Every major story choice ends up visible in your headcount.
7. **"Magicians" — Approved vs. Forbidden tech, as a diegetic skin on the capability web.** Magicians preserve real technical procedures they can operate without fully understanding; sanctioned use becomes **Approved Gear**, while understanding or repurposing technology beyond doctrine — including anything that could reveal the truth — becomes **Forbidden Gear**, tied to the evidence/Trust system. Gives the villain a personal stake in Act 1 long before his reveal (he's the "greatest magician"), and turns an existing mechanical split into a piece of characterization for free.

---

## 🛠️ CAN WE ACTUALLY BUILD THIS? (scope reality check)

**Yes, IF we're disciplined.** The trick: it's **one core loop reskinned three times, pointed in two directions**, not several separate games. Same underlying "venture / gather / return / upgrade" code runs underground, into the Devil’s Mouth, on the surface, and into the endgame — what changes is the skin, the threats, and what the capability web unlocks.

Keep these LIGHT so we don't drown:
- Hollow Act 1 = production districts (Capacity/Demand/Reserve per cycle) + living NPCs with light talk, NOT Rimworld / city-builder / full dialogue sim
- Settlement (Act 2+) = headcount + passive bonuses, NOT Rimworld
- Recruitment/persuasion = triggered story beats + a Trust check, NOT a full dialogue sim
- Three recruitment sources = same generic worker + different flavor text/recruitment beat each, NOT three distinct worker types or mechanics
- Alien contact = a meaningful choice with a few consequences, NOT a branching faction system
- Story = fragments + key scripted beats, NOT hours of cutscenes
- The Devil’s Mouth = a slow-burn secondary thread using existing tools, NOT a full second area to design and balance

**Tech:** Godot + GDScript (free, proven at our team size). Pixel art (Aseprite). Contract out music. Target: premium on Steam.

**Timeline:** 1–2 years is plausible at Dome-Keeper scope. It is NOT plausible if we try to make mining, combat, settlement, AND diplomacy all deep. **Pick ONE system as our "deep" pillar** (the build system / capability web) and keep the rest intentionally simple. The mechanics canon defines many connected systems; the Build Bible must still choose a thin vertical-slice form for each.

---

## ✅ WHAT WE NEED TO DECIDE TODAY

Every open option — naming, mechanics, structure, art, production — is in the companion **Decisions doc**, organized by category. Its "fastest path" section at the bottom flags what actually blocks starting work vs. what can wait.

One thing worth deciding here, out loud, that isn't a pick-an-option item: **are we all in on the scope discipline above?** This is the thing most likely to sink us — not any single design choice.
