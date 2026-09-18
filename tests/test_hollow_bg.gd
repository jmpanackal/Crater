extends SceneTree
## QUARANTINED (2026-09-18): this tested the Hollow's background readability —
## cliff silhouettes, district building stubs (Glowbeds/Wickwork/Cistern),
## carved rooms, Mid Heart/Vaultward structure, lift network, and habitation
## dressing (rope crossing, lamp posts, terrace lookouts, signage). main.tscn's
## Hollow subtree was deleted for a canon-grounded rebuild
## (docs/hollow-level-authoring.md). This pass only rebuilds Home Court +
## Bottom-West Dig Front; Glowbeds/Wickwork/Mid Heart/Cistern/Vaultward are a
## later phase. Restore this test's real assertions once those districts are
## rebuilt — tracked in docs/priority-roadmap.md, not forgotten.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SKIPPED (quarantined) — see file header")
	quit(0)
