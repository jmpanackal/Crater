extends Label
## Shows carried Salvage. Visible at dig site and Hollow —
## but Salvage only becomes useful when siphoned at the Hollow.

var _wallet: Node


func _ready() -> void:
	_wallet = get_tree().root.get_node_or_null("Resources")
	if _wallet == null:
		text = "Salvage: ?"
		return

	_wallet.resource_changed.connect(_on_resource_changed)
	_refresh(_wallet.get_amount(_wallet.SALVAGE))


func _on_resource_changed(resource_id: StringName, new_amount: int) -> void:
	if resource_id == _wallet.SALVAGE:
		_refresh(new_amount)


func _refresh(amount: int) -> void:
	text = "Salvage: %d" % amount
