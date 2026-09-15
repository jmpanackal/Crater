# Build Bible Spec 17 — Perception (Sight + Noise) + Witness

**Status:** DRAFT (AI-proposed, 2026-09-15), pending USER review. Build-order #17 in [`../00-dependency-map.md`](../00-dependency-map.md).

**Depends on:** Spec 01, Spec 16 (loaded NPCs).

---

## Purpose

Turning a witnessable player action into a fact, per canon §19's detection model (sight, sound, persistent evidence) and the dependency map's explicit contract: "perception and witness systems only write facts" (`00-dependency-map.md`, line 178). This spec is the sight/sound half of that contract; Spec 18 is the persistent-evidence half.

## Already locked (canon §19, §68 — not new)

- Detection includes sight, sound, and persistent physical evidence.
- The world should record meaningful facts rather than simulate perfect NPC knowledge — no omniscient NPCs.
- Perception/witnessing only runs for **loaded** NPCs (§68 NPC simulation scope, already built by Spec 16); off-screen scheduled presence is queryable separately but never runs a live perception check.
- Noise is explicitly DIRECTION, not meant to become an acoustics simulation (§19).
- The civic cycle changes stealth conditions contextually (Working noisy/crowded, Gathering fewer people around, post-Ritual quiet) — a tuning-level DIRECTION for later, not a structural requirement this spec has to build now.

## Scope boundary (not a choice — clarifying canon's own example list)

Canon's §19 fact examples mix two different mechanisms. This spec only covers the subset that requires someone present to see or hear it: *seen entering restricted tunnel, seen stealing, heard mining in restricted area, returned from forbidden direction, excavated restricted wall (if witnessed)*. The rest of that list — *absent from accepted work, missed Ritual, missing production* — are logged directly by Jobs (Spec 24) and Civic Cycle (Spec 15) without any NPC needing to witness anything, and are out of scope here.

## Design choices (new, this spec)

- **Witness checks are action-triggered, not continuous.** Perception never scans the world every frame. A system that wants an action checked for witnesses calls `flag_witnessable(...)` at the moment it happens (Terrain's dig event when the dig lands inside a restricted zone, Diversion's theft interaction, Access's restricted-tunnel entry). Perception itself is agnostic to *why* something is witnessable — it only answers "did anyone loaded nearby see or hear this." Deciding whether an action qualifies (e.g. checking a zone's sanctioned/restricted flag) is the calling system's job, not Perception's — keeping the one-directional push pattern already established for Terrain's dig event (Spec 06).
- **Sight check = radius + line-of-sight raycast + facing cone.** An NPC only registers a sight-witness if the player is within range, there's a clear raycast to the terrain/geometry, and the NPC is roughly facing that direction. Pure omniscient-within-radius was rejected — it produces "how did they see me from behind" complaints for no gameplay benefit. A full lighting/vision-cone simulation was also rejected as over-engineering nothing in canon asks for at this stage.
- **Sound check = radius + a coarse enclosed/open flag, no obstruction geometry.** Matches §19's explicit instruction that this "is not intended to become an acoustics simulation" — an interior zone dampens/shrinks the effective radius, an open zone doesn't; no per-wall raycasting.
- **One fact per witnessing NPC, not one aggregate fact per action.** Each fact records which specific NPC witnessed it. This is what lets later systems (Dialogue/Questioning, Spec 21) ask a *specific* NPC what they saw, rather than an anonymous "someone saw this."
- **A per-(NPC, source) cooldown prevents duplicate facts from a sustained action.** Continuous restricted mining witnessed by the same NPC logs one fact, not one per tick; a repeat requires the cooldown to lapse or the NPC to lose and regain sight/hearing of it.

## State it owns

Transient per-(NPC id, witnessable source id) cooldown timestamps only — not saved, not part of the authoritative model; perception state simply re-derives itself as actions occur.

## API surface

- `flag_witnessable(source_id, position, fact_type)` — called by the owning system (Terrain, Diversion, Access) when it has already decided an action is witnessable.
- Internally: for each loaded NPC within sight/hearing range of `position`, run the sight and sound checks; on a hit (and cooldown clear), append a fact (`fact_type`, `witness: npc_id`) to the Fact Log (Spec 01).

## Failure / edge cases

- No loaded NPCs nearby → the check runs, finds nothing, writes nothing. Not an error.
- An NPC facing away can still register a sound-witness (sound isn't blocked by facing) even with no sight-witness.
- `flag_witnessable` called for an action the caller should never have flagged (e.g. inside a sanctioned zone) is a caller bug, not something Perception guards against — Perception trusts its callers by design, per the one-directional contract.

## Acceptance tests

- A restricted-zone dig with one loaded NPC in sight range, clear line-of-sight, and facing the player logs exactly one fact tagged with that NPC's id.
- The same dig with no loaded NPCs nearby logs nothing.
- A sustained restricted action witnessed by the same NPC does not produce duplicate facts within the cooldown window.
- An NPC facing away does not register a sight-witness, but can still register a sound-witness within hearing radius.
