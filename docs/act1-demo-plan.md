# Act 1 demo plan (planning lock)

Living checklist for a **playable, coherent, demoable** Act 1 vertical slice. Not a full implementation brief — ordered work + known gaps.

Related canon: [`CONTEXT.md`](../CONTEXT.md), [`story.md`](story.md), [`game-decisions.md`](game-decisions.md) (#28, #29), [`materials.md`](materials.md), [`game-pitch.md`](game-pitch.md).

---

## Siphon diagnosis (why it feels nonsensical)

**Design intent (canon — USER locked #29):**

- Public work returns assigned **Materials** → **Tallies** (personal pay for sanctioned gear) + **Contribution** (residence/access) + district inputs.
- Districts passively turn inputs into **District production**; healthy output = **Siphon Cover**.
- **Siphon** = diverting District production / rare Hullbit for *personal forbidden* work-rig upgrades (not normal Tallies spend).
- Efficiency / “safe magic” is *open* help to districts; forbidden / knowledge is the secret, cover-gated path.
- Dig haul is **multi-type Materials** + rare **Records** (Records stay separate).
- Siphon only happens when you are home in the Hollow.
- Demo needs a thin **inventory**.

**What the build does today:**

| Intent | Current code |
| --- | --- |
| Two currencies / channels (Tallies vs siphon) | One wallet: **Salvage** pays for *everything* in the “Siphon shop” |
| Forbidden divert vs open requisition | Both Safe and Secret rows call `siphon_for_upgrade`; Safe only skips notice RNG |
| Divert *communal District production* | Costs Salvage; District production never decreases (flavor counters only) |
| Cover from healthy districts | Implemented as `total_rate / 4.5` → notice chance — correct *shape*, weak *fiction* (rates, not “missing goods”) |
| Hollow-only spend | Correct (`HollowZone` → `set_siphon_station_open`) |
| District supplies from digs | Digs only grant Salvage (+ rare Records); no district-input haul |
| Materials inventory | No multi-type bag — single Salvage int |

**Verdict:** The mechanical seed (Hollow-only shop + cover RNG on forbidden) is right, but the **fiction wiring is wrong**: siphon reads as a generic upgrade shop labeled “siphon,” efficiency is falsely “siphoned,” and Cover floats unattached to anything the player can see going missing. Docs now lock the target; code rename/inventory is backlog after name confirm + Decision 2.

---

## Pending rename (Salvage → Materials)

Do **not** treat code “Salvage” as canon. After USER confirms names in [`materials.md`](materials.md):

- [ ] `resources.gd` / SaveLoad: Salvage wallet → Materials inventory (multi-type)
- [ ] Feel floats / HUD copy: `+Salvage` → per-material labels
- [ ] District production labels: Mushrooms/Water → Glowrations + Glowfiber / Presswater + Clearwater; Wickwork → Wicklamps + Bindcord
- [ ] Siphon UI: cost District production; stop paying forbidden upgrades from dig wallet
- [ ] CONTEXT / comments that still say Salvage as the economy currency

---

## Priority implementation list (Act 1 demo)

Ordered for “demo tomorrow” coherence — cut deep story beats before cutting clarity.

1. **Clarify siphon fiction in UI + economy (after Decision 2 + name confirm)**  
   Split open requisition vs secret divert; stop calling efficiency a siphon; make Cover mean something visible (production drain and/or missing-goods toast). Tiny copy-only mitigations only if full split waits.

2. **Teach the core loop in the first 3 minutes**  
   Short diegetic onboarding: Harvest clock → return to Hollow → districts exist → dig Mouth for Materials → turn in / spend at home. One Steward assignment stub (“help excavate / gather for districts”) even if the new district map is a single authored room.

3. **Public dig + return loop that matters**  
   Mouth dig remains the public reason to leave; Materials (and district inputs) only useful after return. Harvest miss + lie stays the accountability pulse. Thin inventory bag.

4. **Make districts feel like places, not HUD stats**  
   Walkable Farms / Wickwork / Cistern props with NPC presence; world labels; District production that players notice rising when they “help.”

5. **Standing / secrecy readable without a spreadsheet**  
   Cover %, notice toasts, pending-lie tag, upward-dig risk — already seeded; tighten copy and one authored “friend notices” beat later.

6. **Minimal Journal payoff**  
   Keep flat list for demo if needed; ensure Firmament note → Quiet Dig gate is findable and explained once.

7. **Spatial Hollow prototype polish for screenshots**  
   Heart platforms + Mouth void read; approach thresholds; Firmament haze / Pit gloom — enough that it doesn’t look like a greybox shop.

8. **Demo-critical feel**  
   Dig/land juice already present; one pass on HUD chrome so “Siphon shop” doesn’t dominate first impression.

9. **Steward’s new district (thin)**  
   Lateral dig zone + one contradiction fragment — enough to show civic digging, not full spine reveal.

10. **Defer for post-demo**  
    Full Tallies/Contribution ranks, lift rig, Vaultward ascent, authored Firmament fissure, Mystery/Codex Journal, painted tilesets, authored SFX packs, Act 2 tease (never).

---

## Fix list (what exists now)

### Siphon / economy clarity

- [ ] Efficiency upgrades sold through the same “Siphon shop” / `siphon_for_upgrade` path — contradicts “open safe magic.”
- [ ] Button labels “Safe / Secret … Salvage” never say what is being diverted from communal life.
- [ ] District production ticks forever with no spend sink; Cover ignores available production, only rates.
- [ ] No Tallies / Contribution / public requisition channel.
- [ ] No district-supply Materials from digs (story canon has them) — still Salvage-only haul.
- [ ] No Materials inventory (multi-type).
- [ ] Dig Yield is “forbidden” but also the obvious first power buy — may teach “siphon = shop” before “siphon = theft.”

### UX / teaching

- [ ] Siphon panel collapses behind `[U]`; Cover is visible but jargon-heavy (`Cover % · notice ~%`).
- [ ] District details collapsed by default — easy to miss that districts *are* the economy.
- [ ] World district labels exist as soft text; building silhouettes are ColorRect placeholders.
- [ ] No first-run Steward / work assignment to frame why you dig.

### Systems gaps (seeded, incomplete)

- [ ] Harvest 60s + Standing + lie — works; consequences don’t yet change shifts/access (Standing is a number).
- [ ] Quiet Dig gated by Firmament note — works; only three Journal stubs; no Mystery/Codex.
- [ ] Upward dig risk — works; no Vaultward / authored fissure, so Firmament dig may feel available too early vs story.
- [ ] Living NPCs — wander/talk; bodies hidden ColorRects; rare Pell farm help only.
- [ ] SaveLoad v2 — present; no Tallies/Contribution / Materials inventory fields yet.

### Art / presentation

- [ ] Hollow blocked layout (terraces/bridge/stairs) — prototype, not final social hierarchy.
- [ ] District props / NPC bodies / lanterns still placeholders.
- [ ] Firmament/Pit soft overlays only — not distinct tilesets.
- [ ] Audio = procedural click stubs.

### Coherence risks for a demo

- [ ] Player can treat the game as dig → Salvage → buy upgrades with Cover as noise.
- [ ] “Might be the whole game” fails if Hollow reads as an empty upgrade booth between digs.

---

## USER answers (siphon + demo scope)

### Siphon fiction

1. **What does a siphon actually spend?**  
   **✅ Locked (USER):** Story-aligned — Siphon diverts **communal District production**; dig haul is **multi-type Materials** that feed districts + Records + other; efficiency raises production for Cover. See #29 / [`materials.md`](materials.md). (Not Salvage-only shop; not copy-only patch as the end state.)

2. **Should efficiency / safe magic share the siphon UI at all?**  
   **⏳ Next Decision** — ask after Material names confirmed.

3. **Is Dig Yield forbidden-tier or public worker gear?**  
   Open (A/B/C still valid).

4. **What should Cover communicate in one player-facing sentence?**  
   Draft still good: “When the districts thrive, missing materials are harder to notice.” Lock with Decision 2 / UI pass.

5. **Demo economy depth:**  
   **✅ Locked (USER):** Need **inventory** + multi-type Materials toward Tallies + production-drain Siphon — not Salvage-only forever. Implement in focused passes after names + Decision 2.

### Demo scope (non-blocking but useful)

6. Steward assignment for demo: **stub dialogue + marker**, or skip until new-district dig space exists? — Open
7. Firmament upward dig in demo: **available now** (prototype), or **gated** until a fake “Vaultward access” flag so story matches feel? — Open
8. Art bar for demo: greybox OK if loop/fiction clear, or need one PixelLab pass on districts/NPCs first? — Open

---

## Superpowers install note

Manual install for Cursor agents (marketplace `/add-plugin superpowers` still preferred when available):

- Skills: `C:\Users\jacob\.cursor\skills\<skill>\SKILL.md`
- Pack mirror + local plugin: `C:\Users\jacob\.cursor\skills\superpowers\` and `C:\Users\jacob\.cursor\plugins\local\superpowers\`
