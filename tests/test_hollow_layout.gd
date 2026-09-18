extends SceneTree
## QUARANTINED (2026-09-18): this tested the old multi-band Devil's Mouth
## Hollow layout — the PitVoid, district elevations and horizontal spans
## (Farms/Glowbeds, Wickwork, Cistern), sub-level bands, the three-lift
## Presswater network, Vaultward's locked gate, NPC placement across decks,
## and camera bounds sized to that layout. main.tscn's Hollow subtree was
## deleted for a canon-grounded rebuild (docs/hollow-level-authoring.md).
## This pass only rebuilds Home Court + Bottom-West Dig Front; that whole
## district layout is a later phase. Restore this test's real assertions once
## it is rebuilt — tracked in docs/priority-roadmap.md, not forgotten.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SKIPPED (quarantined) — see file header")
	quit(0)
