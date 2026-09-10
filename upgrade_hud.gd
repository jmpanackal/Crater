extends VBoxContainer
## Placeholder upgrade shop UI: shows dig-yield level/cost and a buy button.
## Also listens for the "buy_upgrade" input action (U) as a keyboard shortcut.

@onready var _info: Label = $InfoLabel
@onready var _buy_button: Button = $BuyButton

var _upgrades: Node
var _wallet: Node


func _ready() -> void:
	_upgrades = get_tree().root.get_node_or_null("Upgrades")
	_wallet = get_tree().root.get_node_or_null("Resources")

	if _buy_button:
		# Space/ui_accept must not activate this button when jumping.
		_buy_button.focus_mode = Control.FOCUS_NONE
		_buy_button.pressed.connect(_on_buy_pressed)

	if _upgrades:
		_upgrades.upgrade_changed.connect(_on_upgrade_changed)
	if _wallet:
		_wallet.resource_changed.connect(_on_resource_changed)

	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("buy_upgrade"):
		_try_buy_dig_yield()
		get_viewport().set_input_as_handled()


func _on_buy_pressed() -> void:
	_try_buy_dig_yield()


func _try_buy_dig_yield() -> void:
	if _upgrades == null:
		return
	_upgrades.try_buy(_upgrades.DIG_YIELD)
	_refresh()


func _on_upgrade_changed(_upgrade_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if _upgrades == null:
		if _info:
			_info.text = "Upgrades unavailable"
		return

	var id: StringName = _upgrades.DIG_YIELD
	var level: int = _upgrades.get_level(id)
	var cost: int = _upgrades.get_next_cost(id)
	var yield_now: int = _upgrades.get_dig_ore_yield()
	var name: String = _upgrades.get_display_name(id)
	var can_afford: bool = _upgrades.can_buy(id)

	if _info:
		_info.text = "%s Lv %d | Next: %d Ore | Yield: %d/dig" % [name, level, cost, yield_now]

	if _buy_button:
		_buy_button.text = "Buy %s (%d Ore) [U]" % [name, cost]
		_buy_button.disabled = not can_afford
