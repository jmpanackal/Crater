extends SceneTree
## The Hollow map must pass HollowMapLint: level grid, stacking, run ends, stairs, ladders,
## lifts, gates, a single Mouth cluster, growth reserves, zones, reachability with gates open
## and shut, east/west balance, and (in the real scene) built structures, painted walls and
## treads, headroom above every deck, rock beyond flank ends. See docs/hollow-map-spec.md.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var report := HollowMapLint.run()
	var scene_report := HollowMapLint.lint_scene(scene)
	var errors: Array = report["errors"] + scene_report["errors"]
	for line in report["warnings"] + scene_report["warnings"]:
		print("WARN ", line)
	if not errors.is_empty():
		for line in errors:
			push_error("FAIL map lint: %s" % line)
		quit(1)
		return
	print("PASS Hollow map lint: %d deck pieces, data and scene rules clean" % report["pieces"].size())
	quit(0)
