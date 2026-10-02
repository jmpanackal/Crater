# Game feel / juice — best practices (Krater)

Living reference for Act 1 polish. Add notes here as you learn more; this is not a feature backlog.

**Tone guardrail:** Act 1 is secrecy, curiosity, and a living Hollow — not an arcade carnival. Juice should make systems *read* and *feel fair*, usually subtle. Prefer dust, weight, and quiet tension over fireworks.

**Code snapshot (as of this doc):** `player.gd` has coyote (~100 ms), jump buffer (~120 ms), light accel/friction, sprite-only squash/stretch on jump/land, and soft void respawn. Dig/land grit via `feel_fx.gd` — Firmament quieter than Devil’s Mouth. Soft land/dig camera shake (Firmament barely notches). Micro dig hitch (~16 ms Firmament / ~40 ms Devil’s Mouth, non-stacking). Subdued world `+N` Salvage floats (transitional → Materials) + clearer Record floats. Procedural dig/land click stubs in `feel_audio.gd` with pitch randomize. Camera look-ahead + drag deadzone (`camera_follow.gd`). Harvest status soft-pulses when ≤10 s; Standing notices tint by tone (Harvest and Standing are transitional → civic cycle / Ritual and Trust, per `mechanics-canon.md`). NPC idle bob + lean toward player. Approach threshold placard. No authored SFX packs yet.

---

## Game feel / juice techniques

### 1. Acceleration + friction (weight / momentum)

**What:** Ramp into max speed and ease to a stop instead of snapping velocity.

**Why:** Movement feels physical; short hops and dig approaches feel intentional.

**Krater:** High priority for the kid in Hollow corridors and Dig Site ledges. Current move is snappy/arcade. Keep dig-aim responsiveness: don’t make accel so soft that aiming Firmament↑ / Devil’s Mouth↓ with WASD + **R** feels mushy. Hollow wandering can be slightly heavier than dig-site urgency if you ever split feel by zone — optional, not required for Act 1.

**Careful:** Don’t fight tile-grid dig spacing (64px cells). Weight should not make “nudge next to a tile and dig” unreliable.

---

### 2. Squash & stretch (sprite scale, not hitbox)

**What:** Briefly squash on land / stretch on jump by scaling the *visual* only (`AnimatedSprite2D`), never the `CharacterBody2D` collision.

**Why:** Jump/land read clearly even with idle-only art.

**Krater:** Good fit once jump/land moments exist. Player currently has 8-dir **idle** frames only — squash on land still works with a single frame. Dig strike could use a tiny forward squash toward aim, but keep Firmament digs *quieter* visually than Devil’s Mouth digs (secrecy vs public danger).

**Careful:** Don’t scale collision or dig origin math; dig uses `global_position + TILE offset`.

---

### 3. Impact: dust + light screen shake

**What:** Small particles and a short, low-amplitude camera shake on meaningful impacts.

**Why:** Confirms contact with the world.

**Krater:**
| Moment | Suggestion |
| --- | --- |
| Land from jump | Soft dust; very light shake |
| Successful dig | Rock grit / dust in dig direction |
| Devil’s Mouth streak warning | Slightly stronger rumble (walls “groan”) |
| Firmament dig (especially noticed) | Prefer *less* camera drama — secrecy; grit + quiet SFX over shake |
| Missed Ritual / Trust change | Prefer UI/world tension over big shake |
| Theft witnessed / evidence found | Same — social consequence, not explosion |
| Fragment / Record find | Soft sparkle or quiet pop, not slot-machine cascade |
| Hollow NPC talk | Usually none; presence already soft (`soft_world_label` fade) |

**Careful:** Shake on every dig will fatigue and clash with “might get caught.” Reserve stronger shake for Devil’s Mouth danger / rare beats.

---

### 4. Freeze frames (brief timescale near 0)

**What:** 1–3 frames of near-paused time on a big hit so the brain registers impact.

**Why:** Makes rare moments feel important.

**Krater:** Micro hitch only on successful digs — Firmament ~1 frame, Devil’s Mouth ~2–3 frames, mid in between; never stack. Prefer this over freezing rare social beats for now. First Record / exposed lie hitch remains optional later.

**Does not apply / careful:** No freeze on theft interactions or NPC dialogue open. Keep dig hitch under ~50 ms so mining rhythm stays intact. Never stack freezes in a way that desyncs the civic-cycle clock (hitstop ignores time_scale on its restore timer).

---

### 5. Coyote time & jump buffering

**What:** Coyote = short grace after leaving a ledge still allows jump. Buffer = pressing jump slightly early still jumps on landing.

**Why:** Fairness; reduces “I swear I jumped” frustration on platformer edges.

**Krater:** Strong fit — Dig Site has ledgey tile geometry; Hollow has platforms/districts. **Implemented** (coyote ~100 ms, buffer ~120 ms). High polish priority that landed; keep dig on **R** separate from jump on Space.

**Careful:** Dig is on **R**, jump on Space — keep buffers from stealing dig inputs. No need for complex air control juice until basic coyote/buffer exist.

---

### 6. Audio: randomize SFX pitch

**What:** Play dig/land/UI sounds with slight random pitch (and optionally volume) variation.

**Why:** Avoids mechanical machine-gun repetition.

**Krater:** No audio yet (CONTEXT: placeholder). When SFX land:
- Dig hits: pitch vary; Firmament dig quieter / muffled vs Devil’s Mouth dig fuller / riskier
- Material extraction / tether attach: weighty and soft; Record find distinct and rare
- Pulse cadence and Ritual gathering: world audio that communicates the civic phase
- Missed Ritual / Trust change: human/social cue, not a game-over sting
- Diversion: muted “divert” feel; being seen or heard: sharper social ping
- NPC talk: light affirm, not collectible chime spam

**Careful:** Don’t make forbidden actions sound *rewarding* like a power-up.

---

### 7. Collect pops / floating score labels

**What:** Brief scale-pop animation and floating “+N” text on pickup.

**Why:** Confirms reward; satisfying in arcade economies.

**Krater — apply lightly:**
- Material extraction: the deposit visibly changes to its depleted overlay and the haul attaches to the tether — that *is* the feedback; most broken rock yields nothing and should not pop.
- Record / Journal unlock: clearer pop — rare, story-bearing.
- Trust changes: human-readable reasons in a notice, **never** floating `+X Trust` / `−X Trust` popups (canon §17 CUT).
- Diversion / Forbidden builds: confirmation in the private workspace UI, not world-space score popcorn.

**Does not apply well:** Treating civic-cycle phases or district output as floating score spam.

---

## Priorities / when to apply

1. **Systems first.** Trust, the civic cycle and Ritual, diversion/evidence, stamina reservation, dual dig frontiers, and districts must stay correct. Juice never masks broken rules.
2. **Fairness before spectacle.** Coyote/buffer and readable dig feedback before freeze frames and heavy shake.
3. **Movement weight next.** Accel/friction + land squash once jump exists in daily play.
4. **Dig feel as the loop’s “hit.”** Dust + pitched SFX + optional micro-squash; Firmament quieter than Devil’s Mouth.
5. **Social consequences stay social.** Missed Ritual, lies, Trust, being witnessed → copy, UI, sparse audio — not arcade juicing.
6. **NPC / Hollow life stays soft.** Match existing soft placards and talk prompts; don’t turn districts into particle festivals.
7. **Act 1 tone.** Curiosity/wonder over fear; secrecy over celebration when digging up.

---

## Does not apply / careful (checklist)

| Technique | Risk in Krater |
| --- | --- |
| Heavy freeze every dig | Mining feels laggy; breaks loop tempo |
| Big shake on Firmament digs | Undermines sneaking / taboo tension |
| Arcade collect cascades | Fights “most rock yields nothing” and the secrecy framing of Materials |
| Juice before systems | Pretty wrong Trust/civic-cycle rules are worse |
| Hitbox squash | Breaks dig origin / tile collision |
| Rewarding SFX for getting caught | Teaches the wrong emotion |
| Constant timescale tricks | Desyncs civic-cycle / dig rhythm perception |

---

## How to extend this file

When you learn a new feel trick (hit-stop curves, controller rumble, animation cancel, UI punch, etc.), add a short subsection: **What / Why / Krater / Careful**. Keep examples tied to real verbs: move, dig, extract, haul, divert, Ritual, Trust, Records, Hollow NPCs.
