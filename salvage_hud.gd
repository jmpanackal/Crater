extends Label
## Shows carried Materials from the real canon owner (Storage, Build Bible
## Spec 11) — replaces the retired Salvage wallet.

const UiStyleRef := preload("res://ui_style.gd")

var _storage: Node


func _ready() -> void:
	UiStyleRef.apply_label(self, &"hud")
	UiStyleRef.tip(
		self,
		"Materials from digging. Delivered to districts through Jobs."
	)
	modulate.a = 0.9
	_storage = get_tree().root.get_node_or_null("Storage")
	if _storage == null:
		text = "Materials: ?"
		return

	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.storage_changed.connect(_on_storage_changed)
	_refresh()


func _on_storage_changed(kind: StringName, _id: StringName, _new_count: int) -> void:
	if kind == _storage.KIND_MATERIAL:
		_refresh()


func _refresh() -> void:
	if _storage == null:
		text = "Materials: ?"
		return
	var parts: PackedStringArray = PackedStringArray()
	for material_id: StringName in _storage.get_material_ids():
		var n: int = _storage.get_material_count(material_id)
		if n > 0:
			parts.append("%s %d" % [_storage.get_material_display_name(material_id), n])
	if parts.is_empty():
		text = "Materials: 0"
	else:
		text = "Materials: " + " · ".join(parts)
