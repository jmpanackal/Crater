# Full Hollow Chunk Atlas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, editable, implementation-facing atlas of every Act 1 Hollow chunk and then fill it with user-approved visual references until no atlas location is unaccounted for.

**Architecture:** The atlas uses one canonical JSON data file consumed by a standalone local HTML viewer. It represents fixed-play, interiors, transit, destructible dig envelopes, future locks, and Devil's Mouth visual-depth chunks as one complete mosaic. Approved art is a versioned image reference within a stable slot; draft art is never displayed in the atlas.

**Tech Stack:** JSON, standalone HTML/CSS/JavaScript, project-local PNG references, Python standard-library validator, Godot handoff metadata.

**Spec:** `docs/superpowers/specs/2026-09-11-full-hollow-chunk-atlas-design.md`

## Global Constraints

- Use **Devil's Mouth**, **Firmament**, **Materials**, **District production**, **Trust**, and **Steal**; preserve legacy terminology only in explicit transition documents.
- Treat every place in the cross-section—including void/fog/wreck depth—as a named atlas chunk. No unexplained blank slot or blank settlement mass is allowed.
- Normal gameplay cameras never show the entire Hollow or the Firmament from Mid Heart.
- Public excavation is lateral outward wall work. Devil's Mouth is not a routine downward mine.
- Only user-approved visual references appear inside an atlas slot. Keep earlier approved images as versioned history.
- Atlas coordinates are design topology units, not Godot world pixels. Every implementation seam needs a reciprocal destination.
- Production growth reserves and dynamic area states must claim named space and never interrupt essential routes or the left-lift no-softlock path.

---

## File structure

| File | Responsibility |
| --- | --- |
| `docs/refs/hollow-chunk-atlas.json` | Canonical complete chunk inventory, topology bounds, seams, camera/visual/system contracts, asset history, and future Godot handoff fields. |
| `docs/refs/hollow-chunk-atlas.html` | Local data-driven viewer that renders the complete atlas, status layers, thumbnails, and selected-slot contract. |
| `tools/validate_hollow_chunk_atlas.py` | Standard-library JSON validator for IDs, reciprocal seams, bounds coverage, status/image policy, and required class-specific metadata. |
| `docs/hollow-chunk-atlas.md` | Human-readable operating guide, editing rules, generation queue, and Godot handoff checklist. |
| `docs/hollow-chunk-map.md` | Opening-route source of truth; links to the atlas and records O1–O8 contracts. |
| `docs/hollow-build-brief.md` | Macro layout source of truth; links to complete atlas as the player-scale translation layer. |
| `docs/refs/chunks/approved/` | Versioned, user-approved visual chunk references. |
| `docs/refs/chunks/drafts/` | Non-approved draft references; never rendered by the atlas. |

## Atlas coverage target

The initial complete inventory targets **84 named slots**. This is enough to show the whole Hollow as a fully composed spatial puzzle while leaving no unowned gaps.

| Family | Count | Contents |
| --- | ---: | --- |
| West wall homes, services, production and transit | 23 | Ashram west, High-West, Wickwork, allotments, Lower West, O1–O8, lift landings/interiors. |
| Bottom-West destructible envelope | 7 | threshold, five player-carvable volumes, optional collapsed side chamber / locked boundary. |
| Mid Heart | 16 | four major raft anchors, civic subdecks, loops, docks, catch rails, and interior service rooms. |
| East wall homes, production and transit | 20 | Ashram east, Glowbeds, Mid-East approach, lower-east service, right lift landings, Cistern levels. |
| Mid-East destructible envelope | 8 | checkpoint, six player-carvable pressure/fault volumes, locked deep boundary. |
| High-West destructible envelope | 6 | staging and five constrained late-work volumes. |
| Devil's Mouth visual-depth mosaic | 4 | upper, Heart-band, lower settlement, and deep-wreck/black-descent composites, each internally layered. |

The four void composites are explicit chunks, not empty canvas. They can be subdivided later only if a later Act needs a playable descent.

## Visual reference production order

Do not generate 84 unrelated images. Each batch has a shared palette, edge/seam reference, and user approval gate. A later batch may use approved adjacent images as style/composition references.

1. **West opening route:** O2 through O8 plus immediately adjacent Lower West home/service pieces. This establishes the player’s first continuous route and Bottom-West handoff.
2. **Bottom-West envelope:** threshold, five destructible-volume state references, collapsed side chamber, and locked boundary.
3. **West mid/upper:** Wickwork, allotments, left lift stops, High-West, and Ashram west.
4. **Mid Heart:** one composite contact reference for the four raft relationships, then its 16 local normal-camera chunks.
5. **East service/deep:** lower-east service band, right lift, Cistern, and seep gallery before upper-east work so Presswater infrastructure stays spatially coherent.
6. **Glowbeds and Mid-East:** tidy upper cultivation, growth reserve states, middle-height approach, and pressure-dig envelope.
7. **Ashram east and void mosaic:** upper sacred/guarded residence band and four Devil's Mouth visual-depth composites.
8. **Growth-state variants:** only after base chunks are approved; generate construction/upgraded/operating variants for production/civic chunks in the same stable slots.

## Task 1: Establish the canonical chunk schema and complete inventory

**Files:**
- Create: `docs/refs/hollow-chunk-atlas.json`
- Modify: `docs/hollow-chunk-atlas.md`

**Interfaces:**
- Produces a JSON object with `schema_version`, `atlas`, `chunks`, and `seams` keys.
- Each `chunks[]` item has exactly the fields in the approved spec: `id`, `display_name`, `class`, `status`, `atlas_bounds`, `band`, `parent`, `seams`, `camera_contract`, `visual_contract`, `systems`, `image_history`, `godot_handoff`; production/civic items additionally carry growth fields.

- [ ] **Step 1: Create the JSON top-level contract.**

```json
{
  "schema_version": 1,
  "atlas": { "unit": "design-cell", "width": 180, "height": 108, "void_region_ids": ["VM-01", "VM-02", "VM-03", "VM-04"] },
  "chunks": [],
  "seams": []
}
```

- [ ] **Step 2: Add all 84 IDs with their class, band, parent, and topology bounds.** Use contiguous west-wall, Heart, east-wall, and void footprints; make the four void composites cover the entire central vertical void region.

- [ ] **Step 3: Add reciprocal seam records.** Every walkable/door/lift seam has `from`, `to`, `from_edge`, `to_edge`, `mode`, `gate`, and `camera_handoff`; non-walkable visual-depth adjacency is recorded separately and does not claim collision.

- [ ] **Step 4: Add class-specific contracts.** Give all dig chunks immutable boundaries, safe return seams, and locked deeper continuation; give all production/civic chunks growth reserves and state profiles; give void chunks parallax/occlusion contracts.

- [ ] **Step 5: Add asset-history policy.** Set O1 to approved with `docs/refs/hollow-opening-home-court-approved-2026-09-11.png`; set O2 to `draft` with no image entry; set all other slots to `planned` with empty image history.

- [ ] **Step 6: Update `docs/hollow-chunk-atlas.md`.** Replace the prototype-only status table with the 84-slot inventory summary and explain that JSON is the canonical source.

## Task 2: Implement the validator before the viewer consumes data

**Files:**
- Create: `tools/validate_hollow_chunk_atlas.py`
- Test: command-line checks against `docs/refs/hollow-chunk-atlas.json`

**Interfaces:**
- Consumes `python tools/validate_hollow_chunk_atlas.py docs/refs/hollow-chunk-atlas.json`.
- Produces exit code `0` and `Atlas valid: <count> chunks, <count> seams` on success; exit code `1` plus exact field/ID failures otherwise.

- [ ] **Step 1: Implement required-field validation.** Require all general schema fields and growth fields for `WK-*`, `GL-*`, `CI-*`, and `MH-*` chunks.

- [ ] **Step 2: Implement ID, status, and asset validation.** Reject duplicate IDs; reject any approved/implemented chunk without an existing image path; reject draft chunk image paths; reject unsupported statuses/classes.

- [ ] **Step 3: Implement topology validation.** Reject bounds outside the atlas, an empty void mosaic, missing required families, or non-void chunks whose explicit `coverage_role` is absent.

- [ ] **Step 4: Implement reciprocal seam validation.** For each walkable, door, lift, or dig transition, require exactly one reciprocal seam with compatible traversal mode.

- [ ] **Step 5: Run the validator against the initial JSON.** Expected output: `Atlas valid: 84 chunks, ... seams`.

## Task 3: Rebuild the local atlas viewer around canonical data

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.html`
- Modify: `docs/hollow-chunk-atlas.md`

**Interfaces:**
- Consumes the embedded or local canonical atlas data without duplicating it manually.
- Produces a full-map canvas with status-filterable chunk slots and a selected-slot detail inspector.

- [ ] **Step 1: Render every JSON chunk at `atlas_bounds`.** Render all four void composites as visible visual-depth cards/layers, not an unowned blank center.

- [ ] **Step 2: Render approved thumbnails only.** Use the latest approved `image_history` asset, show draft/planned/revision statuses as labeled non-image cards, and never render a draft file.

- [ ] **Step 3: Render seams and state overlays.** Differentiate walk, door, lift, dig transition, visual adjacency, locked gate, and growth-reserve seams with labeled legend styles.

- [ ] **Step 4: Implement inspector details.** Clicking a slot shows its purpose, adjacent IDs, camera/visual contract, systems, growth state, image history, and Godot handoff fields.

- [ ] **Step 5: Validate the viewer manually.** Confirm O1 appears in lower west, O2 remains text-only beside it, void chunks cover the central shaft, Cistern sits far below Mid Heart, and no system uses deprecated terminology.

## Task 4: Make the opening route complete before generating new regions

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.json`
- Create: `docs/refs/chunks/drafts/` image files one at a time
- Modify: `docs/hollow-chunk-map.md`

**Interfaces:**
- O1 is the immutable approved edge/palette reference.
- O2–O8 consume west/east adjacency contracts from the canonical JSON.

- [ ] **Step 1: Review and approve or revise O2.** Do not add its current draft to the atlas until the user approves it.
- [ ] **Step 2: Generate O3 West Dispatch with O2/O4 seam contracts.** Include First Steward assignment, crew staging, tool/carts, and a wide layered civic terrace; no generic market or Mouth descent.
- [ ] **Step 3: Generate O4 Bottom-West Approach with O3/O5 contracts.** Make the outward route more enclosed as the Mouth disappears.
- [ ] **Step 4: Generate O5 threshold, O6 expansion gallery, O7 collapsed chamber, and O8 lower lift landing in that dependency order.** Each image gets a user review before its slot status changes.
- [ ] **Step 5: Save only approved images in `docs/refs/chunks/approved/` and update their image history.** Preserve rejected/draft references in `docs/refs/chunks/drafts/`.
- [ ] **Step 6: Re-run validator and review O1–O8 as a contiguous west-opening strip in the atlas.**

## Task 5: Produce the three bounded dig envelopes

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.json`
- Create: approved/draft chunk references under `docs/refs/chunks/`
- Modify: `docs/hollow-build-brief.md`

**Interfaces:**
- Bottom-West, Mid-East, and High-West envelope chunks use `class: destructible-dig` and share no direct seam with Devil's Mouth.

- [ ] **Step 1: Generate Bottom-West in a shared contact pass, then review individual dig-volume pieces.** Enforce low/wide impact-fill, lateral outward direction, two-to-three route alternatives, optional O7, and locked deep boundary.
- [ ] **Step 2: Generate Mid-East in a shared contact pass, then individual pieces.** Enforce true middle-east position, wet pressure/fault state changes, and no proximity to the deep Cistern in the same camera.
- [ ] **Step 3: Generate High-West in a shared contact pass, then individual pieces.** Enforce direct-below-Ashram placement, Warden control, rare Records/Hullbit traces, and no secret roof shortcut.
- [ ] **Step 4: Update dig state profiles.** Record base, active dig, cleared-route, construction/brace, and locked-deeper visuals for each envelope.
- [ ] **Step 5: Run validator and inspect every dig chunk's return and lock seams.**

## Task 6: Produce West mid/upper residential and Wickwork pieces

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.json`
- Create: approved/draft references under `docs/refs/chunks/`
- Modify: `docs/hollow-chunk-map.md`

**Interfaces:**
- Wickwork production slots have `growth_role`, `upgrade_source`, and state profiles.
- Ashram west slots are future-locked at start and include Warden/Trust systems.

- [ ] **Step 1: Generate the Wickwork terrace, bays, interior repair room, and shuttered expansion-bay images as one adjacency cluster.**
- [ ] **Step 2: Generate Mid Allotments and mid-home pieces with a distinct modest two-room home progression.**
- [ ] **Step 3: Generate left-lift landings/shaft frames that connect lower, Wickwork-mid, and High-West without becoming generic ladder spine imagery.**
- [ ] **Step 4: Generate Ashram west approach/residence chunks with guarded, tidy, sacred/prestigious structural language—not literal real-world religious symbols.**
- [ ] **Step 5: Review state-growth variants only after each base chunk is approved.**

## Task 7: Produce Mid Heart as a connected but separated raft cluster

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.json`
- Create: approved/draft references under `docs/refs/chunks/`
- Modify: `docs/hollow-build-brief.md`

**Interfaces:**
- Mid Heart has at least 16 slots spanning West Exchange, Holding, East Service, Lower Freight, docks, and connective terraces.

- [ ] **Step 1: Generate a non-final cluster contact reference to lock four-raft scale, relative gaps, and wall/lift approaches.**
- [ ] **Step 2: Generate West Exchange pieces: Joss counter, requisition/repair intake, freight dock, and approach.**
- [ ] **Step 3: Generate Holding pieces: large upper/lower hall, queue/bench decks, Council edge, and adjacent terraces that together imply several hundred daily residents.**
- [ ] **Step 4: Generate East Service and Lower Freight pieces with civic care, notices, small shops, service/dock functions, and maintenance loop.**
- [ ] **Step 5: Generate only visual-depth void pieces required through Heart gaps, preserving the open shaft.**
- [ ] **Step 6: Validate every Heart seam and confirm no frame turns it into one long bridge or shows the Firmament.**

## Task 8: Produce East wall, Cistern, and growth-state pieces

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.json`
- Create: approved/draft references under `docs/refs/chunks/`
- Modify: `docs/hollow-build-brief.md`

**Interfaces:**
- Glowbeds, Cistern, and Mid Heart support slots use named reserve/construction/upgraded state profiles.
- Right lift behavior reflects Presswater healthy/thin/reserve but preserves essential left-lift accessibility.

- [ ] **Step 1: Generate lower-east service pieces before Cistern, ensuring the right side has homes, clinic/dock, repair, freight, and circulation rather than a dead end.**
- [ ] **Step 2: Generate the Cistern's upper service, freight, basin, Sealbrine, and seep pieces as vertically related but normal-camera-local images.**
- [ ] **Step 3: Generate Glowbeds base and reserve pieces: tidy cultivation, fallow/growing/harvest/drying states, and later conversion to active expansion space.**
- [ ] **Step 4: Generate Mid-East approach and its dig-envelope pieces after Glowbeds/Cistern placement is visually stable.**
- [ ] **Step 5: Generate Ashram east and right-lift upper landing last, retaining the guarded access and no early Firmament reveal.**

## Task 9: Complete Devil's Mouth visual-depth mosaic and handoff

**Files:**
- Modify: `docs/refs/hollow-chunk-atlas.json`
- Create: approved references under `docs/refs/chunks/approved/`
- Modify: `docs/hollow-chunk-atlas.md`
- Modify: `docs/hollow-build-brief.md`

**Interfaces:**
- VM-01 through VM-04 are visual-depth chunks with parallax/occlusion contracts, no routine collision seams, and a future-Act-3 flag for deep pieces.

- [ ] **Step 1: Generate upper/Heart/lower/deep void composites so the complete puzzle has no unrepresented central region.**
- [ ] **Step 2: Use only non-obvious wreck scars, fog, distant rails, sparse lights, and scale; never make the crater supernatural, ravine-like, or a visible spaceship hangar.**
- [ ] **Step 3: Add `godot_handoff` skeletons for every approved chunk: scene/region ID, world origin placeholder, collision class, camera owner, and implementation status.**
- [ ] **Step 4: Run final validator.** Expected output: every 84 slot represented, reciprocal walkable seams valid, approved-image policy valid, and no non-void coverage gap.
- [ ] **Step 5: Conduct final atlas review at three scales: whole-Hollow topology, adjacent chunk seams, and normal player camera.**

## Plan self-review

- **Spec coverage:** Tasks 1–3 implement complete topology, data, viewer, and validation; Tasks 4–9 cover every chunk family, all dig envelopes, production growth states, visual-depth pieces, and Godot handoff.
- **No placeholders:** No task relies on undefined systems; discovery unlocks remain explicitly name-pending by approved design rather than silently creating an economy item.
- **Consistency:** `status`, `class`, `image_history`, `seams`, and `godot_handoff` use identical names across data, validator, viewer, and production tasks.
