extends "res://ui_modal.gd"
## The Standing view (canon section 17 and the Trust spec): Trust is shown as a small number of qualitative standing
## states, never a score, with the recent reasons society trusts or distrusts you in plain words. A row of lamps
## walks the standing ladder (the current state lit); under it, the recent reasons, newest first, each marked with
## a small up or down arrow, never "+3". Opens with [T]. Reads the Trust autoload. Display only.


func _init() -> void:
	title_text = "Standing"
	title_glyph = &"seal"
	toggle_action = "standing_view"
	plate_width = 440.0
	ensure_key("standing_view", KEY_T)


func _signature() -> String:
	var trust := get_node_or_null("/root/Trust")
	if trust == null:
		return "none"
	return "%s|%d" % [str(trust.get_standing_label()), trust.get_trust_reasons().size()]


func _refresh() -> void:
	clear_body()
	var trust := get_node_or_null("/root/Trust")
	if trust == null:
		var none := Label.new()
		none.text = "Standing is not available."
		UiStyleRef.apply_label(none, &"muted")
		body.add_child(none)
		return
	var current := str(trust.get_standing_label())
	var big := Label.new()
	big.text = current
	big.add_theme_font_size_override("font_size", 24)
	big.add_theme_color_override("font_color", UiStyleRef.TEXT_AMBER)
	body.add_child(big)
	var ladder: Array = trust.get_standing_ladder()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for step in ladder:
		var cell := VBoxContainer.new()
		var lamp := ColorRect.new()
		lamp.custom_minimum_size = Vector2(14.0, 8.0)
		lamp.color = UiStyleRef.LAMP_AMBER if str(step["label"]) == current else Color(0.14, 0.13, 0.11)
		cell.add_child(lamp)
		var n := Label.new()
		n.text = str(step["label"])
		UiStyleRef.apply_label(n, &"muted")
		cell.add_child(n)
		row.add_child(cell)
	body.add_child(row)
	var why := Label.new()
	why.text = "Why society sees you this way"
	UiStyleRef.apply_label(why, &"accent")
	body.add_child(why)
	var reasons: Array = trust.get_trust_reasons()
	if reasons.is_empty():
		var empty := Label.new()
		empty.text = "Nothing yet. People are still watching how you work."
		UiStyleRef.apply_label(empty, &"muted")
		body.add_child(empty)
	else:
		for i in range(reasons.size() - 1, -1, -1):
			var r: Dictionary = reasons[i]
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 8)
			var arrow := Label.new()
			arrow.text = "▲" if float(r["delta"]) >= 0.0 else "▼"
			arrow.add_theme_color_override("font_color", UiStyleRef.TEXT_TEAL if float(r["delta"]) >= 0.0 else UiStyleRef.ALERT_RED)
			line.add_child(arrow)
			var txt := Label.new()
			txt.text = str(r["reason"])
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			txt.custom_minimum_size = Vector2(plate_width - 80.0, 0.0)
			UiStyleRef.apply_label(txt, &"body")
			line.add_child(txt)
			body.add_child(line)
