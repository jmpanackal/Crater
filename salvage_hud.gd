extends Label
## Shows carried Materials. Visible at dig site and Hollow —
## Materials feed District production when turned in at the Hollow.

const UiStyleRef := preload("res://ui_style.gd")

var _wallet: Node


func _ready() -> void:
	UiStyleRef.apply_label(self, &"hud")
	UiStyleRef.tip(
		self,
		"Materials from digging. Turn them in at the Hollow [E] to queue District production."
	)
	modulate.a = 0.9
	_wallet = get_tree().root.get_node_or_null("Resources")
	if _wallet == null:
		text = "Materials: ?"
		return

	_wallet.resource_changed.connect(_on_resource_changed)
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if _wallet == null:
		text = "Materials: ?"
		return
	var parts: PackedStringArray = PackedStringArray()
	var mats: Array[StringName] = [
		_wallet.SPOREMEAL,
		_wallet.LAMPWICK,
		_wallet.BRINECRYSTAL,
		_wallet.VERDIGRIS,
		_wallet.HULLBIT,
	]
	for mat_id in mats:
		var n: int = _wallet.get_amount(mat_id)
		if n > 0:
			parts.append("%s %d" % [_wallet.get_material_display_name(mat_id), n])
	if parts.is_empty():
		text = "Materials: 0"
	else:
		text = "Materials: " + " · ".join(parts)
