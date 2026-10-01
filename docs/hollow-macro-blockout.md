> **Superseded for coordinates (2026-10-01):** see [`hollow-map-spec.md`](hollow-map-spec.md). The east stack was re-gridded to consecutive 640px levels and the west dig flank carve was fixed; numbers below are history.

# Hollow macro planning pass — 2026-09-18

User direction: establish the whole map's scale, district positions and basic
levels before connecting and refining individual rooms. Preserve the current
opening route and original camera zoom. Planning guides are not walkable floors.

## Inspecting the plan

Open `main.tscn`, select `Hollow/MacroBackground`, and frame the selection in
the 2D editor. The `@tool` script draws the background and planning overlay
without running the game. Toggle **Show Planning Guides** in its Inspector.
**Show Guides In Game** optionally displays the same overlay during play;
it is off by default. There is no new gameplay camera or hotkey.
The guide overlay renders above existing tiles so it stays legible in-game.

### Play minimap (orientation overlay)

In play, `UI/HollowMinimap` is a quiet bottom-right overview of
`MacroBackground.WORLD_BOUNDS` (district footprints, Mouth band, sparse labels,
player dot). It defaults **on**; press **M** (`toggle_minimap`) to hide/show.
Drawn 2D only — no second camera. Useful while greyboxing; landmark identity
in the world remains the primary player guide.
The existing east-side digging sandbox is retained, not silently relocated or
declared to be the finished east-wall layout; its terrain will need a later
authored pass against these reservations.

The former opening-only rectangles are replaced by a background from
(-1280,-320) to (2720,1472): 4000 x 1792 world pixels. Both walls, all current
inhabited bands, the upper Firmament reserve, the Mouth and lateral dig-front
reservations now fit within the same background. The 32px player and 256px
scale bar make its size explicit.

**World-scale pass (2026-09-19):** the player reported the built-out Hollow
read as jumbled and undersized — walking Mid Heart's Mouth crossing took
~3.5s at `SPEED=200`, against a target of 15-20s — and didn't match the
confirmed [Hollow Cross-Section Blueprint](https://claude.ai/artifact/Dq15YdDjhfe4B6e1hsvv7U).
Every world position, span, and district footprint in `hollow_layout.gd` /
`hollow_macro_background.gd` / `content/zones/*.tres` is now **5x** its prior
value (Mid Heart crossing: ~17.6s). Background now runs (-6400,-1600) to
(13600,7360): 20000 x 8960 world pixels. Sizes tied to the player's fixed
32px body — tile size, floor/bridge thickness, lift/ladder cage openings —
are unchanged; only world distances grew. Numbers below this note in the
rest of the doc are historical (as authored 2026-09-18/19, pre-rescale)
unless restated.

## Authority and provisional decisions

- `hollow_layout.gd` supplies existing locked band heights, 16px tiles,
  32px player scale and Mouth edges x=1440..4960 (3520 px / ~1/5 of world
  width; x5 of the original 288..992 / 704px, per the 2026-09-19 world-scale
  pass above). The earlier 2026-09-19 scale-plan correction had widened
  Devil's Mouth from the old 288..736 (448 px) so the central void matches
  the HOLLOW SCALE PLAN image.
  Implementation heights supersede the old 64px-grid heights in
  `hollow-build-brief.md`.
- `hollow-build-brief.md` and `hollow-chunk-atlas.md` supply district ordering:
  Ashram on both walls, High-West below west Ashram, Glowbeds upper east,
  Wickwork mid-west, Heart suspended centrally, Cistern deep east, and
  Bottom-West / Mid-East lateral excavation fronts.
- West civic transport is Mid-to-High only; east upper passenger transport
  is separately recessed; Cistern freight is Low-to-Mid only. Dashed worker
  switchbacks reserve the lower-west return route, not a lower civic lift.
- Exact unbuilt district widths, three adjacent growth footprints, lift X
  positions and the dashed switchback path are **AI-proposed blockout
  reservations**, not newly approved canon or implemented paths. They are
  labeled as planning guides and have no collision. Their geometry is
  centralized in `hollow_macro_background.gd` for subsequent review.
- The 18x16 atlas is topology, explicitly not a world-pixel conversion.
  This pass does not multiply it into 18 screen-widths or claim those final
  dimensions are approved. It exposes the existing engine scale for review.
- The external Claude cross-section link was inaccessible in this session;
  the older referenced `hollow-layout-act1-approved-2026-09-11.png` is absent.
  Therefore this pass reserves space against local written specs and current
  metrics, without claiming exact blueprint fidelity or building new regions.

## Movement rendering

The earlier camera-clock change prevented transform-direction reversals but
did not test rasterized pixels between physics ticks. This pass removes
independent transform snapping and enables interpolation on the Player branch
only (main root opts out). Nearest texture filtering and zoom remain unchanged.
Spawn, void recovery and rescue reset interpolation to avoid streaking.

Godot references: [physics interpolation setup](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html)
and [jitter troubleshooting](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html).

Headless tests cover map coverage, correct transport bands, non-colliding
guides, interpolation configuration and physical traversal. A rendered
motion check is also required: headless transform checks alone do not prove
that movement looks smooth on the user's display.

`tools/check_player_rendering.gd` is a manual GPU-rendered diagnostic (not a
headless test). Run Godot with `--path . --windowed --max-fps 144 --script
res://tools/check_player_rendering.gd -- fixed`; use `baseline` instead of
`fixed` to reproduce the old no-interpolation + pixel-snap settings. Optional
`output=<directory>` and `size=3840x2160` arguments control reports and size.
It detects the actual rendered character pixels, records both movement
directions after two seconds of camera settling, and writes JSON plus frames.
Missing detections are errors, not evidence of smooth movement. The initial
144 FPS comparison had 32/11 raster reversals with old settings and 0/0 with
the new settings, with no missing detections. This is evidence on this machine,
not a guarantee for every monitor configuration.

Follow-up fixed-mode checks at 1280x720 / 60 FPS and 3840x2160 / 144 FPS
also recorded 0/0 reversals with no missing frames. The full headless runner
reported 55/55 successful exits (50 active files, 5 existing quarantined skips).
Zoom and gameplay movement/collision tuning are unchanged.

## Playable expansion landed (2026-09-18 correction)

Greybox collision now grows the map footprint with **new places**, not denser
detailing of the Home → Switchback → Dispatch corridor:

- **Opening corridor (simplified):** Lower Switchback and West Dispatch are flat
  lower-work floors again (pre-expansion silhouette). The rejected support-mass
  dip/tunnel, foreman podium, and cart bay are gone.
- **Landing → Mid Heart:** `LadderHomeToHeart` from Home Court's upper landing
  (x≈220) up through a cut roof onto Heart-height approach pads, then east onto
  Mid Heart's Mouth crossing (west lip x=288 → east lip x=992).
- **Worker Return west spur:** Heart-height floors at y=576 (x=-336..-64) above
  the flat corridor, reached by `LadderWorkerReturn` from Switchback (x≈-208).
  Mid Allotments (y=720) share that shaft through a matching floor gap — no
  second Mid ladder beside it.
- **Wickwork terrace:** flat Mid/Wick floor west of Worker Return (x=-528..-336).
- **Mid Allotments:** street at y=720 under the west spur (x=-336..-64), reached
  from the shared Worker Return shaft.
- **Mid Heart deck:** one continuous walk spanning Mouth west lip (x=288) →
  east lip (x=992) at y=576 — the sole primary east–west crossing over the void.
  Multi-deck rafts / Lower Span Mouth crossings were removed (2026-09-19).
- **Mid-East Landing:** flat walkable floor from the Mouth's east edge (x=992)
  out past FreightLift toward the east passenger shaft.
- **Mid-East Approach:** continues the civic east walk to x=1664;
  camera keeps civic framing through the approach tip before Dig Front unlock.
- **Mid-East Dig Front:** excavation terrace from the civic tip (x=1664) out to
  x=2368 at Mid Heart height; brown diggable rock outside Mouth (not teal fill).
- **High-West Dig Front:** diggable Firmament + mid-band rock at x=-1136..-576,
  west of the Hollow civic void (conceptual Dig(west) flank).
- **Ashram Heights (east):** walkable terrace at y=80 above Glowbeds on the shared
  east passenger shaft (`LadderEastStack`).
- **Glowbeds hang:** fiber-rack deck at y=368 on the same shaft (between Glowbeds
  main gallery y=224 and Mid-East).
- **Cistern chamber:** walkable floor past the approach lip with a
  Low↔Mid↔Cistern `FreightLift` shaft (cage-width floor gaps on Mid /
  Lower / Cistern; lift parks at Mid so the civic walk stays bridged).
- **Dig carve (2026-09-19):** East dig envelope starts at EXIT_RIGHT (x=1280).
  Civic decks + `LadderEastStack` are carved open after fill so dig rock does
  not seal the approach; Dig Front keeps a thin diggable face + Firmament band
  (non-aqua `DIG_ROCK_COLOR`). Mouth stays open void; Mid Heart is the sole
  continuous crossing.

Covered by `tests/test_playable_expansion.gd` and the Home Court navigation
walk. Gallery digging and final art remain out of scope.
