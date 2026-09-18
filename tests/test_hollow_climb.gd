extends SceneTree
## QUARANTINED (2026-09-18): this tested the local emergency ladder between
## the Lower work deck and the Cistern district (Hollow/LadderCistern) —
## climb-zone detection, grab geometry, and climbing down/up between those two
## decks. main.tscn's Hollow subtree was deleted for a canon-grounded rebuild
## (docs/hollow-level-authoring.md). This pass only rebuilds Home Court +
## Bottom-West Dig Front; the Cistern district and its ladder are a later
## phase. Restore this test's real assertions once the Cistern is rebuilt —
## tracked in docs/priority-roadmap.md, not forgotten.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SKIPPED (quarantined) — see file header")
	quit(0)
