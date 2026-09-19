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
The existing east-side digging sandbox is retained, not silently relocated or
declared to be the finished east-wall layout; its terrain will need a later
authored pass against these reservations.

The former opening-only rectangles are replaced by a background from
(-1280,-320) to (2304,1472): 3584 x 1792 world pixels. Both walls, all current
inhabited bands, the upper Firmament reserve, the Mouth and lateral dig-front
reservations now fit within the same background. The 32px player and 256px
scale bar make its size explicit. No terrain, seams or playable routes move.

## Authority and provisional decisions

- `hollow_layout.gd` supplies existing locked band heights, 16px tiles,
  32px player scale and Mouth edges x=288..736. The later implementation
  heights supersede the old 64px-grid heights in `hollow-build-brief.md`.
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
