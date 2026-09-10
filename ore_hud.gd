extends Label
## Simple HUD readout for Ore. Listens to Resources so it stays live without polling.

var _wallet: Node


func _ready() -> void:
	_wallet = get_tree().root.get_node_or_null("Resources")
	if _wallet == null:
		text = "Ore: ?"
		return

	_wallet.resource_changed.connect(_on_resource_changed)
	_refresh(_wallet.get_amount(_wallet.ORE))


func _on_resource_changed(resource_id: StringName, new_amount: int) -> void:
	if resource_id == _wallet.ORE:
		_refresh(new_amount)


func _refresh(amount: int) -> void:
	text = "Ore: %d" % amount
