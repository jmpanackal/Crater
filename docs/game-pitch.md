# 🎮 GAME PITCH — "Krater"

> **One line:** You're a kid in an underground society built into the walls of a massive, unexplored pit — forbidden from digging up, and quietly the only person who's ever wanted to. You break the taboo, reach a surface no one knew existed, and slowly uncover the truth: your people are crash-landed colonists on an alien moon, and the answer to everything was always waiting at the bottom of the pit everyone else spent generations staring into.

*(This doc stays high-level. Every open decision — naming, mechanics, structure, art, production — lives in the companion **Decisions doc**, organized by category there.)*

---

## 🕹️ WHAT KIND OF GAME IS IT

An **expedition-based mining roguelite with a tech tree, a settlement layer, passive/idle-style resource generation, and a story campaign.** Think:

- **Dome Keeper** (2-person team, made ~$1M) — dig for resources, upgrade, defend against threats. This is our closest comp and proof our team size can pull off this *kind* of game.
- **SteamWorld Dig** — dig-and-upgrade with a world that opens up as you progress.
- **Inscryption** — for the mystery pacing, the slow reveal, and "the game is bigger than you first think."
- **AdVenture Capitalist / idle-clicker games, and Palworld's Pals-working-while-you-explore loop** — for the passive generation layer, detailed below. This is how we keep the incremental/idle DNA that started this whole conversation, without making the *whole* game idle.

**Why this fits us:** it's systems-heavy and light on hand-drawn art/animation (plays to a coder-driven team + AI-assisted coding). Simple pixel art. Godot engine (free, exactly what Dome Keeper used). Premium game on Steam, ~$10–20, no live-service/monetization treadmill needed. Digging itself is one mechanic pointed in two directions (up and down — more on that below), so we're getting two forbidden frontiers out of one system to build, not two.

**The key insight:** Dome Keeper's most common criticisms are (1) builds collapse into one obvious path, (2) no story, (3) gets repetitive. Our whole concept — real build variety, a mystery campaign, a tech tree that doubles as lore — is basically a checklist of the things people *wished Dome Keeper had.*

**Genre honesty check:** this is *incremental* (numbers escalate, upgrades increase generation rates) but not a pure *idle* game (you can't just close the app and win — it needs active exploration too). If what drew us to the clicker idea was mainly "low art burden, systems-driven, buildable by a small team," this keeps all of that. If it was specifically the close-the-app-and-come-back mechanic, see the passive layer below — that's where it lives.

---

## 🔁 THE CORE LOOP (how it actually plays)

One loop, reused across the whole game so we're not building four separate games:

**Venture out → gather resources + discover fragments → return before you're missed → upgrade your tech tree → go further next time.**

- Early game that loop is **digging in secret** — and it runs in two directions from day one: *up*, toward the ceiling everyone's mythologized, and *down*, into the pit everyone stares at but nobody dares finish exploring. Same tools, same upgrades, same risk system — one growing capability the player can point at either forbidden frontier.
- Mid/late game it's **running expeditions onto the surface** and hauling stuff back, while the pit keeps deepening in parallel as a slower secondary thread.
- The *pressure* that makes it tense = a time/risk system (detailed below), NOT a monster-mash. Skill = deciding what to grab, how far to push, when to turn back — not twitch reflexes.

**⭐ Running underneath all of that: passive/idle generation, the same system reskinned three times, same as the core loop:**

- **The Hollow:** the society is constantly working — farming, crafting, whatever sustains it — generating resources whether you're actively playing or not. The tech/upgrades you steal and find increase their generation rate. This is what funds and speeds up your secret digging, in both directions.
- **The surface settlement:** recruited people auto-work here too, at a **higher rate** than the Hollow (because of the tech you've brought up) — direct, visible payoff for progress and recruitment.
- **The ship:** same system, final skin — passive construction ticking upward while you're out on expeditions, until it's ready.

This is deliberately one of the *cheapest* systems to build (a rate-per-tick number, modified by upgrades and headcount, no animation/combat-feel needed) — it's the same math idle-clicker games run on, and it's a well-worn enough pattern that AI-assisted coding handles it easily. It keeps the actual incremental/idle satisfaction (numbers climbing, checking in on growth) without making the *whole* game passive. Comparable to how Palworld's Pals work on tasks while you go explore.

**Guardrail:** keep all three tiers sharing the same underlying formula/scaling logic with different flavor numbers. If any tier starts needing its own prestige system or its own independent balancing pass, that's scope creep — flag it.

---

## 📖 THE STORY (with how each part = gameplay)

### ACT 1 — Underground (the taboo)

Generations ago a colony ship was shot down (more on that later) and swallowed into the crust of an alien world, tearing open a massive shaft in the process. The survivors built their settlement directly into and around that wound — homes, walkways, and workshops layered over, across, and into a pit that plunges out of sight. Over generations the truth of what happened rotted into myth, and the pit itself became a permanent fixture of daily life: everyone in the Hollow has a theory about how deep it goes and what's down there, because nobody who's gone far enough has ever come back to settle the argument. It's the one thing the whole community can't stop talking about.

At the same time, everyone's raised to believe **this is simply how the world is**, and the one unbreakable rule going the *other* direction is: never dig upward. The myths say the rock overhead will collapse and crush everyone. Nobody needs convincing to be careful around the pit — it's obviously dangerous, no story required. The ceiling is different: there's no real evidence it's dangerous at all, which is exactly why it needed an actively retold myth to keep working generation after generation. Living side-by-side with a genuinely risky, unmythologized hole and a harmless, elaborately mythologized ceiling means players can *feel* the difference between organic caution and manufactured control before the story ever explains it — which is the whole engine behind our villain, later.

You're a kid who never really bought the ceiling story. You don't hate your home, you don't love it — it just *is*. And where everyone else's curiosity points down, into the pit they'll never stop wondering about, yours quietly points up, somewhere nobody else even thinks to look. That asymmetry is who you are before anything else happens: not a rebel, just someone whose attention is aimed in the one direction nobody shares. Then something — a doubt, a crack, a fragment you find — sets you digging upward in secret, incrementally, a little at a time, in a hidden pocket, stealing hours and materials from daily life. Since the tools that dig are the same tools regardless of direction, the same stolen hours quietly let you push into the pit's upper walls too, whenever there's something worth checking — not the main thread yet, but the first hint that your curiosity and everyone else's obsession are pointed at the same underlying mystery.

**Naming: "the Hollow"** — going with this for the overarching name for now. (Ceiling/taboo naming: open — see Decisions doc #1.)

**Realism note on naming:** the Hollow is the *entirety of existence* as far as its people know — nobody living there thinks of themselves as living "in the Hollow" any more than we walk around saying "I'm going back to Earth." "The Hollow" is a name **we (the player/dev team) use**, and possibly an old, semi-formal or ceremonial term within the lore — but in day-to-day dialogue and flavor text, people should reference **named subsections** (districts, tunnels, chambers — see Decisions doc #2) rather than saying "the Hollow" constantly. This keeps the writing believable and avoids the "as you know, Bob, we live on Earth" problem.

**The comedy + folk beliefs (lightly sprinkled):** nobody actually knows what's up there or down there, so people have invented wild explanations for both. Some genuinely believe they live **inside the belly of a giant beast** — the ceiling is its stomach, the pit is its throat, tremors are it being hungry, and digging either direction will "wake it." Others think the surface is where the dead go, or that the bottom of the pit is where they came from. One guy insists it's just rock, in both directions, and everyone's overthinking it (he's right, and nobody listens to him). Kids have creepy nursery rhymes about the ones who dug up, and separate ones about the ones who went down too far. This keeps the tone curious/warm, not grim.

**"Magicians."** A handful of people in the Hollow have learned to operate old machinery pulled from the crater walls — by rote and inherited practice, not understanding — and everyone else calls what they do magic, because that's genuinely what it looks like when nobody knows why it works. This isn't background flavor, it's load-bearing: the villain didn't stumble into power by accident, he erased the *knowledge* of what this tech actually is while letting its *use* continue — because a settlement that thinks its tools are magic has no framework for questioning who controls them. He likely encourages the magic framing rather than merely tolerating it, and may quietly position himself as the most gifted magician of all — a detail that reads as harmless local color in Act 1 and lands very differently once the player knows who he really is.

Not all tech gets the same treatment, though. Anything mundane and utilitarian — fire-starting tools, water filtration, structural reinforcement — is sanctioned, openly used, "safe magic." Anything that could actually reveal the truth — navigation instruments, communication devices, ship logs, legible data of any kind — is hoarded, restricted, or quietly destroyed, because that's the tech that could unravel his story. Players won't know this distinction exists yet in Act 1 — it's just "some magic is common, some is rare and suspicious" — but it maps directly onto real mechanics below.

**GAMEPLAY IN ACT 1:**
- The **daily Harvest** — communal crop/resource gathering that keeps the society fed. It's the rhythm of life AND your clock: you dig during stolen time, but you have to show up or you're noticed.
- **Dual-direction digging** — the same tools push both upward (the secret, forbidden project) and into the pit's upper walls (public, permitted, everyone does it a little — though going too far is genuinely dangerous rather than taboo). Cheap for us to build: one system, two frontiers.
- **Fragments** are seeded in both directions but stay ambiguous everywhere this early (could be read as myth, religion, or history — never clearly "we're on an alien planet"). Two kinds, and each now has a diegetic reason for how it's used and by whom:
  - **Salvage** = metal, machinery, hull → mechanical upgrades. Sanctioned/"safe magic" salvage becomes **efficiency upgrades** — it boosts the Harvest's passive generation rate openly, no secrecy required. Forbidden/"dangerous magic" salvage is what you're actually risking everything to dig for.
  - **Records** = data-slates, audio logs, survivor journals → lore. Always forbidden-tier — this is the tech that could unravel the myth, so finding and using it becomes a **knowledge upgrade**, tied directly to the risk below rather than open daily life.
- **Social Standing system (important, runs the whole game):** getting caught digging upward, caught in a lie about where you've been, or caught tinkering with tech beyond what's sanctioned, costs you standing. A lie mechanic lets you dodge suspicion — but if a lie is *later* exposed, the penalty is worse than getting caught honestly. Standing gates how many people you can recruit later. **Act 1's small personal risks become Act 3's payoff.**

**🎯 DESIGN GOAL: Act 1 should feel like it might be the whole game.** No visible "surface" tab, no locked branches hinting at more. The player should brace for punishment when they dig up, NOT anticipate a reveal — the world only turning out to be bigger than shown should land as a genuine surprise, not something the player was quietly expecting. The pit stays a constant, lived-with mystery throughout — never confirmed, never explained, just always there in the background the way it is for everyone else in the Hollow.

**Bonus continuity:** "Krater" — our locked title — is literally what this pit is. Not just a name we picked, but the actual crater the ship carved out generations ago.

---

### ACT 2 — The Breach (the reveal + survival + settlement)

You break through. **The world doesn't end.** Instead: a vast, alien, wondrous landscape — strange colors, impossible formations, distant structures. Not a wasteland — *beautiful*, which makes it even harder to square with everything you were taught. (It has **some verticality** — cliffs, layers, things to climb — but isn't a pure vertical world.)

**⭐ Visual identity: "the Reef."** The surface looks like a colorful underwater reef — but isn't underwater. The planet's atmosphere is simply denser than Earth's: things drift instead of fall, dust and spores hang and swirl like silt, plants sway on slow air-currents instead of wind, creatures glide rather than fly. This is a real diegetic fact about the world, not just a visual trick — and it quietly explains why the native species might look/move the way they do (evolved for a denser medium — graceful and drifting, not aggressive-looking). Bonus continuity: bioluminescence already exists in the Hollow (lanterns, glowbugs) — if the Reef's life is *also* bioluminescent, just wilder and more colorful, we get one visual language connecting both halves of the game, escalated rather than reinvented.

**One core identity, not many biomes.** Rather than building several distinct biomes (real added art cost for a small team), we lean on ONE strong aesthetic pillar with depth/density variation — shallower reaches sparse and sunlit, deeper/further reaches denser, darker, stranger, more bioluminescent. Same core assets recombined and recolored, not new asset categories every zone. Distinct biomes are a stretch goal only if we have spare capacity late, not the baseline plan.

**First truth:** the "collapse" was never real. It was a story wrapped around knowledge no one below ever had.

**Surface threats:** the world is gorgeous but has hidden teeth, revealed the deeper you explore. Open — see Decisions doc #3.

**GAMEPLAY IN ACT 2 — this is where the game opens up:**
- **Surface expeditions:** the core loop, reskinned. Venture out, gather alien resources + salvage the *real* ship wreckage (bigger finds than the scraps below), race back.
- **The return timer / Social Standing:** you still have to go back down for food and to keep relationships alive. Stay out too long = standing drops. Same system as Act 1 — one mechanic, whole game.
- **The pit keeps deepening alongside everything else** — better drills and survival gear pulled from surface salvage let you push further down than Act 1 ever allowed, in parallel with your surface progress. Still no confirmation of what's at the bottom — just further, and stranger.
- **⭐ BUILD A SURFACE SETTLEMENT:** you establish a camp up top. As you recruit people — from below, and eventually from every relationship thread the story opens up — they populate it and **auto-work** (gathering, crafting) — this is our incremental/auto-farming engine. Crucially, **because you've got salvaged tech, the surface settlement is MORE efficient than the underground society** — that contrast is the point: the life everyone was taught to fear is better than the one they were told to accept.
- **Recruitment has three sources by the end of the game, all sharing the same underlying system** (same generic worker slot, gated the same way — just a different recruitment beat and flavor per source, not a separate mechanic each): Hollow recruits, gated by your Social Standing (from the caught/lie system); the runaway settlers, once you find them (below); and, if you make peace, the native species themselves. More people from any source = bigger, faster settlement = closer to building the ship.
- **Hints of the other survivors:** you find signs that a *second* group survived the crash and stayed on the surface generations ago, splitting from your ancestors over a dispute nobody remembers — and unlike the Hollow, whose people you're persuading to leave everything they know, these are people who already chose the surface once. Finding them and winning them over is a second, distinct route into your settlement's growth, not just a lore beat.

---

### ACT 3 — The Truth (origin, villain, and the ship home)

Using **records from below + salvage from above**, you finally have enough to reconstruct what actually happened — and it converges from every direction at once.

**The crash was a misunderstanding.** The world's **native intelligent species** shot the colony ship down — not out of malice, but fear. They saw something huge descending and reacted like anyone would. A tragedy of first contact, never undone. The wreck didn't vanish; it tore open the pit the Hollow has been staring into for generations, and it's still down there.

**The villain is still alive.** The founding myth wasn't just superstition — it was *built*, deliberately, by one of the original survivors: a scientist who's kept himself alive for generations using medical stock recovered, long ago, from deep in the pit itself — meaning he's the only other person who ever went as far down as you're about to. He's now one of the society's elders, quietly known as the most gifted of the Hollow's "magicians" — a reputation that read as harmless local color for two acts and now recontextualizes completely: he didn't just tolerate the magic framing everyone lives under, he built his entire authority on being its supposed master, while personally hoarding the one category of tech — records, navigation, anything that could reveal the truth — that "magic" was never allowed to touch. He's spent his long life controlling what everyone believes and staying one step ahead of the truth, and he has real personal reasons to have discouraged anyone else from finishing what he started. If he learns you're digging and recruiting, he becomes an active threat — and his weapon is what it's always been: **the story itself.** He'll try to rewrite your discoveries into new myth before you can spread the truth.

**The thing in the sky.** There's a shape the society has always had a name for — a guiding light, a myth. It's **the real homeworld**, in view the entire game, mistaken for a star/moon because no one below ever thought to wonder if it was real. This world is its **moon**. So "home" is right there — the ship just has to cross local space.

**The bottom of the pit.** This is where it all lands. Access has been opening gradually all game, tech-gated the same way everything else is — but the true bottom, a full view of the ship or a real chunk of it, is reserved for right here, tied to something you actually need: a component for the escape ship, or a flight recorder that nails the crash cause in the founders' own words. Not lore for its own sake — mechanical weight too. And the payoff line writes itself: **everyone in the Hollow spent generations staring at the answer to everything, and never once thought to look up instead.** Your whole arc, in reverse, is the mirror of theirs — you're the one person who looked in the direction nobody else did, and it turns out the two mysteries — what's above, what's below — were always the same one.

**GAMEPLAY IN ACT 3:**
- The **ship = the final tier of the tech tree**, not a new genre. Everything you've built — upward and downward — funnels into it.
- **The alien-contact choice:** you can find the native species' settlement and choose to **fight or make peace** — and it's a genuinely hard call, because *by now you know they're why your people crashed.* Choosing peace can unlock a third tech branch (trade/shared knowledge) and opens the native species as your settlement's third recruitment source — the biggest possible reward for the hardest choice in the game, since you'd be building a shared future with the people who ended your old one. Fighting closes both off, but opens others.
- **The ending is driven by your Social Standing + recruitment across all three sources:**
  - Expose the villain and leave him behind
  - Defeat him in a final confrontation
  - He stays and convinces others NOT to go with you — and **the number of people who leave vs. stay depends on how many you convinced over the whole game, from the Hollow, the runaway settlers, and — if you chose peace — the aliens themselves.** Your choices across all three threads literally shape your ending headcount.

---

## 🧩 THE SYSTEMS THAT MAKE IT UNIQUE (vs. Dome Keeper)

1. **Dual-purpose tech tree** — every unlock is a mechanic AND a lore fragment. Salvaged ship tech literally upgrades you and explains your origin. Solves Dome Keeper's "no story" + "thin content" at once.
2. **Trade-off upgrades** — higher tiers cost something. Kills the "one obvious build order" problem. (How punishing: see Decisions doc #5.)
3. **Social Standing** — one persistent stat driven by getting caught/lying/time-away, that gates recruitment and shapes the ending. Gives the game *memory* and makes choices matter.
4. **Passive/idle generation, reskinned across three tiers (Hollow → settlement → ship)** — the incremental engine that keeps our idle-clicker DNA alive, and a thematic statement (surface life > the life you were told to fear, made visible in the numbers).
5. **One dig mechanic, two forbidden directions (up and down)** — the same growing toolset drives both the ceiling-breach story and the pit's slow-burn mystery, converging in Act 3. Two mysteries for the cost of one system.
6. **One recruitment system, three narrative sources (Hollow, runaway settlers, aliens)** — same generic worker slot and standing-gated logic every time, but each source is a different relationship thread paying off into the same settlement number. Every major story choice ends up visible in your headcount.
7. **"Magicians" — sanctioned vs. forbidden tech, as a diegetic skin on the tech tree.** Public "safe magic" tech maps to efficiency upgrades (openly boosts passive generation); hoarded "dangerous magic" — anything that could reveal the truth — maps to knowledge upgrades, tied to the risk/Social Standing system. Gives the villain a personal stake in Act 1 long before his reveal (he's the "greatest magician"), and turns an existing mechanical split into a piece of characterization for free.

---

## 🛠️ CAN WE ACTUALLY BUILD THIS? (scope reality check)

**Yes, IF we're disciplined.** The trick: it's **one core loop reskinned three times, pointed in two directions**, not several separate games. Same underlying "venture / gather / return / upgrade" code runs underground, into the pit, on the surface, and into the endgame — what changes is the skin, the threats, and what the tech tree unlocks.

Keep these LIGHT so we don't drown:
- Settlement = headcount + passive bonuses, NOT Rimworld
- Recruitment/persuasion = triggered story beats + a standing check, NOT a full dialogue sim
- Three recruitment sources = same generic worker + different flavor text/recruitment beat each, NOT three distinct worker types or mechanics
- Alien contact = a meaningful choice with a few consequences, NOT a branching faction system
- Story = fragments + key scripted beats, NOT hours of cutscenes
- The pit = a slow-burn secondary thread using existing tools, NOT a full second area to design and balance

**Tech:** Godot + GDScript (free, proven at our team size). Pixel art (Aseprite). Contract out music. Target: premium on Steam.

**Timeline:** 1–2 years is plausible at Dome-Keeper scope. It is NOT plausible if we try to make mining, combat, settlement, AND diplomacy all deep. **Pick ONE system as our "deep" pillar** (I vote the tech tree / build system — it's our strength and interest) and keep the rest intentionally simple.

---

## ✅ WHAT WE NEED TO DECIDE TODAY

Every open option — naming, mechanics, structure, art, production — is in the companion **Decisions doc**, organized by category. Its "fastest path" section at the bottom flags what actually blocks starting work vs. what can wait.

One thing worth deciding here, out loud, that isn't a pick-an-option item: **are we all in on the scope discipline above?** This is the thing most likely to sink us — not any single design choice.
