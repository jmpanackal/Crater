extends SceneTree
## QUARANTINED (2026-09-18): this tested the Presswater lift network — the
## Heart hoist (essential, three stops across Lower/Mid/Glowbeds) and the
## secondary left-service/freight lifts' thin/reserve throttling and no-
## softlock guarantee. main.tscn's Hollow subtree was deleted for a
## canon-grounded rebuild (docs/hollow-level-authoring.md). This pass only
## rebuilds Home Court + Bottom-West Dig Front; the lift network's districts
## and shafts are a later phase. Restore this test's real assertions once the
## lift network is rebuilt — tracked in docs/priority-roadmap.md, not
## forgotten.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SKIPPED (quarantined) — see file header")
	quit(0)
