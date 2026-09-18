extends SceneTree
## QUARANTINED (2026-09-18): this tested the Hollow's FloorVisual tileset —
## painted terrace spans across all the old districts (Farms/Glowbeds, Wick,
## lower-work, Cistern), lift/ladder opening gaps, and collision-to-visual
## alignment for that whole layout. main.tscn's Hollow subtree was deleted for
## a canon-grounded rebuild (docs/hollow-level-authoring.md). This pass only
## rebuilds Home Court + Bottom-West Dig Front; the old multi-district floor
## layout is a later phase. Restore this test's real assertions once that
## floor is rebuilt — tracked in docs/priority-roadmap.md, not forgotten.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SKIPPED (quarantined) — see file header")
	quit(0)
