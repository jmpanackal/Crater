extends SceneTree
## Dumps everything the Hollow map and its dressing declare (every x/y, with the level indices) to JSON,
## so a layout-wide change (adding levels, renumbering) can be diffed: each x unchanged, each y shifted
## by exactly the expected amount, nothing added or lost.
## Run: godot --headless --path . --script res://tools/hollow_map_snapshot.gd -- out=tmp/snap.json


func _init() -> void:
	var out_path := "res://tmp/snap.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("out="):
			out_path = argument.trim_prefix("out=")
	var snap := {
		"runs": _plain(HollowMap.runs()),
		"stairs": _plain(HollowMap.stairs()),
		"ladders": _plain(HollowMap.ladders()),
		"lifts": _plain(HollowMap.lifts()),
		"gates": _plain(HollowMap.gates()),
		"zones": _plain(HollowMap.zones()),
		"reserves": _plain(HollowMap.reserves()),
		"roofs": _plain(HollowMap.roofs()),
		"domes": _plain(HollowMap.domes()),
		"held": _plain(HollowMap.held_points()),
		"buildings": _plain(HollowDressing.buildings()),
		"props": _plain(HollowDressing.props()),
		"lamps": _plain(HollowDressing.lamps()),
		"actors": _plain(HollowDressing.actors()),
		"stations": _plain(HollowDressing.stations()),
		"spawn": _plain([HollowLayout.player_spawn_point()]),
	}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(snap, "  ", true))
	f.close()
	print("wrote ", out_path)
	quit(0)


## Variants and Rect2/Vector2 into plain JSON-able data.
func _plain(v: Variant) -> Variant:
	if v is Array:
		var a := []
		for e in v:
			a.append(_plain(e))
		return a
	if v is Dictionary:
		var d := {}
		for key in v.keys():
			d[str(key)] = _plain(v[key])
		return d
	if v is Rect2:
		return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Vector2:
		return {"x": v.x, "y": v.y}
	if v is StringName:
		return str(v)
	return v
