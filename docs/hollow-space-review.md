# Hollow space review and structures-pass planning (AI, 2026-10-02)

Not canon. Everything here is **AI**-tagged: an inventory and a list of questions for the user, written during the variety pass. Nothing in it is decided. Answers go into `art-direction.md` (layout character) or `hollow-map-spec.md`, tagged USER.

## 1. Vocabulary the variety pass now has

All of it is map data, lint-checked, and tile-built (no freehand collision):

| Tool | What it makes | Where it lives |
|---|---|---|
| Terrace pieces | a street as flat pieces at small offsets (16-96 px, raised or dipped), joined by flights; a wide gap is a gentle slope | `HollowMap._terraces()` |
| Stair pitch | stairs steeper or shallower than 45 degrees (`pitch`, run per rise) | `HollowMap._stair(..., pitch)` |
| Landings | half-level resting places between two flights | `_landing()` runs |
| Arched roofs | solid rock hung from a ceiling, stepping down to 96 px | `HollowMap._roofs()` |
| Domes | air carved up into the Firmament over an L0 room (a taller roof) | `HollowMap._domes()` |
| Stairwells | carved back wall and ceiling lip behind a flight | `hollow_stairwell_view.gd` |

A round, tall room is a bowl floor (dips, `+16/+32/+48`) under a dome. First one: Ashram West, `A0` x 512..1232 with `D_A0`.

**Limits to know.** A room's ceiling is the street above it, so only L0 rooms can have a dome. A tall room on any lower level needs the street above it to be *absent* (an opening, balconies, a gallery) or raised; that is a layout decision for the structures pass, not a roof decoration. The 12 bands, the shafts and the stair tops are fixed points that terraces and arches work around.

## 2. Large empty spans (no deck at that level)

Found by scanning `HollowMap.runs()` for stretches of 300 px or more inside the civic cavity with no street on that level. They are backdrop-filled rock-looking void today. For each: why is it empty, and what should it be?

| Where | Size | Notes |
|---|---|---|
| **Lower west, L9-L11**, x -2880..1440 (L9 starts at -1984) | 3400-4300 px wide x ~1100 tall | The biggest void. Directly under Home Court (spawn). Bottom-West's decks all sit at its west edge. |
| **East Mouth cliff, L7-L11**, x 4960..6400/7360 | 1400-2400 px wide at each level | The whole lower half of the east wall on the Mouth side. The Cistern starts at x 6400. |
| West Mouth side, L1 and L3, x -160/-800..1440 | 1600 and 2240 px | Right of the Ashram and High-West stairs, toward the Mouth. |
| West Mouth side, L6 and L8, x 640..1440 | 800 px | Beside the Mouth, right of the Worker Stair and Allotments. |
| West outer rim, L0/L5/L7/L8, x -2880..-1280/-1600 | 1280-1600 px | The far west wall of the civic interior. |
| East outer rim, L1/L3/L6, x 8000..9280 | 1280 px | East of the Ashram, Glowbeds Hang and Lower-East streets. |
| East, L5, x 7360..9280 | 1920 px | East of Mid-East Service Court. |
| East, L0 4960..6400 and L2/L0 8800..9280 | 1440 / 480 px | Ashram East edges. |

Only four growth reserves exist (`R_WICKWORK`, `R_GLOWBEDS`, `R_CISTERN`, `R_BW_DEEP`). Everything above is either intended rock, future ground for a district, or simply not designed yet. Questions:

1. Are the **Mouth-side stretches** (x about 1440 west, 4960 east) meant to be cliff faces that look out over the Mouth, or ground the districts should grow toward it?
2. Is **lower west L9-L11** meant to stay solid, to be Bottom-West's growth space (the First Expansion Gallery and the deeper service run already lead that way), or something for the story?
3. Is the **east Mouth cliff, L7-L11** the place for the Cistern's pressure basin or tank space, or for a second east front?
4. Should the **outer rims** hold annexes (a store, a shrine, a service room) behind the main streets, or stay rock?

## 3. Structures pass: how the map relates to story, gameplay and mechanics

Canon facts the layout must keep (from the canon packet; see `mechanics-canon.md` section 27 and sections 43-47 and `hollow-map-spec.md`):

- Districts change by **authored state-driven physical changes** (repaired lamps, racks, workspaces, storage), not by an auto-clicker. Healthy districts look repaired and equipped; strained ones show empty racks and patched gear.
- **Cistern** (hydraulics, pumps, pressure, lifts, drainage, frontier utilities): open from the start; only the deep L11 service run is gated (`gate_cistern_deep`). In the map it is a chain: Freight Landing L8, Cistern core L9, Tanks L10, Seep L11, from x 5440 to 9280, with the freight lift at x 8640. Long-term direction: drain the Mouth and expose the wreck in Act 3. Exact capacity and timing are OPEN.
- **Glowbeds** (cultivation, food, recovery), **Wickwork** (fabrication, Approved Gear, hauling), **Mid Heart** (exchange, ritual, services, freight; the only structure over the Mouth), **Ashram Heights** (late-Act-1 aspiration, gated), **High-West** (guarded gallery, dig front), **Lower-East and Mid Allotments** (homes, services, freight).
- Dig fronts grow by digging the flanks; 1600 px of rock remains past each gallery.

Planning questions that will move layout (none decided):

**Cistern.** How big is it as a place: the current 3840 x 1536 px footprint, or bigger? Should the player *see* the whole pressure basin as one tall chamber (which means opening the L9 street over it, since a roof cannot rise through a street), or only reach it room by room? Which parts are walkable, which are only viewed from a gallery, and which are gated? What does "developed" look like physically (more pumps, higher water, working lifts), and is that new rooms or changed contents?

**Growth.** When a district upgrades, does the map **gain rooms** (new runs unlocked by a flag, like the gates, using the reserves) or only change what the existing rooms contain? If it gains rooms, the reserves need to be larger and in the right places before the structures pass fixes the streets.

**Story.** Which spaces carry story beats (Ashram Heights, the Forbidden workspace under the Firmament, the flood gate, the wreck under the Mouth), and should they get the unusual shapes (domes, bowls, tall halls)? Ashram West's round court is a first placeholder for that.

**Mechanics.** What will each district's jobs need on the map (queues, loading areas, a work floor, storage), and does that need more horizontal run, more height, or side rooms? Wickwork and Cistern look like they need the most.

**Space budget.** The empty spans above are about 40 percent of the civic cavity. Deciding which become rooms, which stay rock, and which are reserved for growth is the main structures-pass input.

## 4. What the variety pass has not touched

Still flagged by the `flat` lint: `HW2`, `HW3` (High-West galleries), `LW8` (opening route, goes last), `BW10`, `BW11` (Bottom-West), `E0`, `E4` (Mid-East dig front), `E9`, `E10`, `E11` (Cistern core, tanks, Seep). The Cistern streets are held back on purpose until its size and shape are decided.

## 5. Layout fill, stage 1 (AI, 2026-10-02; working names for the user to confirm)

Built after the user's answers (three housing tiers: lower, mid, high/Ashram; doors varied; Bottom-West and purposes "from the docs"). Everything below is **AI-proposed** from canon (`mechanics-canon.md` sections 21, 26, 47 and the hollow-build-brief); the names are placeholders and the purposes are for review.

| Where | What it is | Purpose, from canon |
|---|---|---|
| **Ashram upper wards** (west and east), 4 tiers each, L3 down to the summit at L0 | A zigzag of streets joined by processional stairs (45 and 1.5 pitch), arches on two tiers, a domed summit directly under the Firmament (`D_AW0`, `D_AE0`) | The high housing tier. Canon: Ashram homes sit directly under the Firmament, which is the cover for sustained secret upward excavation (section 47). The summits are where private homes and the hidden ceiling access go. Gated by `ashram_clearance` like the rest of the Ashram. |
| **Lower Mouth Rows** (west, L12-L17) | Six stepped pockets hugging the Mouth cliff: ladders and stairs between rows, ledges of 96, 64 and 128 px, one tucked row, an arched roof | The lower housing tier's overflow (crowded compact units, shared wash and cook courts) and Bottom-West annexes: storage and output areas, a repair bay, rest points near worksite infrastructure (canon section 9). |
| **Lower-East and Cistern Mouth Rows** (east, L11-L17) | The mirror on the east cliff: a first row of homes, then Cistern-side rows down to a lowest row | Lower-East homes overflow, then pump, valve and gauge rooms (the Cistern is the hydraulic district; its water comes from the pit pool). |
| **Cistern Intake Ledge** (L13) and **Mouth balconies** (`MB10`, `ME10`) | Small pockets at the lips with ledges up to 128 px | Intake and observation points over the pit pool (siphon intake, a lookout), and a wash and drying terrace. |
| **Bottom-West deeper and lowest galleries** (L16, L17) | Two new dig galleries beyond the service-run gate | More lateral mining, as canon says Bottom-West is where public lateral mining is taught. Behind `gate_bw_deep`. |
| **Mid-East street** (`E4`) | Terraced with a door, a bump and a dip, so the 7200 px gallery is no longer one strip | The Landing, the Approach and the dig-front gallery. |

Still open: the Cistern's final size and growth, what a "rest point" hosts in each row, the housing costs and Ashram upgrade list (all OPEN in canon), the names above, and the High-West galleries and remaining long runs (`HW2`, `HW3`, `BW10-BW13`, `E9-E11`, the opening route's `LW8`).

## 6. Structures pass: decisions and first build (2026-10-03)

User decisions (also `art-direction.md` 24): growth is both new rooms (from the reserves) and changed contents; the Cistern is one tall pressure basin seen whole from galleries; lower west L9-L11 stays solid rock as Bottom-West's growth reserve; the east Mouth cliff L7-L11 becomes Cistern basin and tank space; unusual shapes go to the Ashram Heights summits, the Cistern basin and flood gate, and Mid Heart / the Pulse hall.

Built (AI): the basin chamber `H_CI` (x 8096..9248, levels 11-14) now holds three full-height pressure tanks with sight glasses, headers and risers (`hollow_cistern_view.gd`, back layer, no collision). The fill follows the Cistern's condition through `EventBus.district_changed` (comfortable 0.9, stable 0.75, strained 0.5, shortage 0.3, critical 0.12: display values, not simulation). Test: `tests/test_hollow_cistern_view.gd`.

Also built (AI): the Pulse on the Ritual Raft (`hollow_pulse_view.gd`, x 2720..3680 at the Ritual deck): a tall degraded drum of housings, conduits, vents, two gauges, mismatched repair plates, grime and fungal growth, no runes. Eight indicator lamps follow the civic phase from `Clock` (rousing 2 lit, working 6, gathering 8, ritual 8 bright); it is a timekeeper only and implies nothing about its OPEN original function. Back layer, no collision. Test: `tests/test_hollow_pulse_view.gd`.

Cistern dressing (AI, 2026-10-03): a pump house facade on the Cistern core street (`pump_house`, x 6704..6960, level 13) with two pumps, valve wheels, a gauge and a pipe run, more valves and notices on the balcony east of it, a freight landing with carts, crates, a rack and a notice (`cistern_freight`), a pump and gauge on the tanks street, and a warning sign and rubble at the Seep. New prop kinds `pump` and `valve_wheel` in `hollow_dressing.gd` / `hollow_dressing_view.gd`; 23 props, 8 lamps, 1 building, all under the lint `dress` rule. Pure data: no map geometry changed. The existing basin galleries are the four streets that already cross the chamber (levels 11-13 plus the floor at 14).

Growth rooms built (AI, 2026-10-03, USER decision 24a): the Wickwork Expansion Bay, Glowbeds Expansion Court and Cistern Tank Annex, each a street extension behind a start-closed bulkhead gate with an AI-proposed flag (`wickwork_expansion`, `glowbeds_expansion`, `cistern_expansion`). What earns the flags is OPEN. Reserves `R_WICKWORK`, `R_GLOWBEDS`, `R_CISTERN` are consumed; `R_BW_DEEP` remains. See `hollow-map-spec.md` section 7.

Not built yet: widening the basin west into the east cliff, galleries and pump rooms around it, reserve growth rooms, a roofed or tall hall shape around the Pulse, and annexes for the other empty spans.
