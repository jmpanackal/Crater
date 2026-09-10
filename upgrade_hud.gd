extends VBoxContainer
## Hollow-only siphon UI. Hidden at the dig site — personal upgrades are not
## a neutral shop; they divert Salvage meant for the communal Harvest.
## Shortcut: "siphon_upgrade" action (U), only while the Hollow station is open.

@onready var _info: Label = $InfoLabel
@onready var _siphon_button: Button = $SiphonButton

var _upgrades: Node
var _wallet: Node


func _ready() -> void:
	_upgrades = get_tree().root.get_node_or_null("Upgrades")
	_wallet = get_tree().root.get_node_or_null("Resources")

	if _siphon_button:
		# Space/ui_accept must not activate this when jumping.
		_siphon_button.focus_mode = Control.FOCUS_NONE
		_siphon_button.pressed.connect(_on_siphon_pressed)

	if _upgrades:
		_upgrades.upgrade_changed.connect(_on_upgrade_changed)
		_upgrades.siphon_station_changed.connect(_on_siphon_station_changed)
	if _wallet:
		_wallet.resource_changed.connect(_on_resource_changed)

	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("siphon_upgrade"):
		_try_siphon_dig_yield()
		get_viewport().set_input_as_handled()


func _on_siphon_pressed() -> void:
	_try_siphon_dig_yield()


func _try_siphon_dig_yield() -> void:
	if _upgrades == null:
		return
	# Hard gate: siphon_for_upgrade refuses unless Hollow station is open.
	_upgrades.siphon_for_upgrade(_upgrades.DIG_YIELD)
	_refresh()


func _on_upgrade_changed(_upgrade_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _on_siphon_station_changed(_is_open: bool) -> void:
	_refresh()


func _refresh() -> void:
	if _upgrades == null:
		visible = false
		return

	# Siphon UI only exists while the player is in the Hollow.
	var in_hollow: bool = _upgrades.is_siphon_station_open()
	visible = in_hollow
	if not in_hollow:
		return

	var id: StringName = _upgrades.DIG_YIELD
	var level: int = _upgrades.get_level(id)
	var cost: int = _upgrades.get_next_cost(id)
	var yield_now: int = _upgrades.get_dig_salvage_yield()
	var upgrade_name: String = _upgrades.get_display_name(id)
	var can_afford: bool = _upgrades.can_siphon(id)

	if _info:
		_info.text = (
			"Siphon %s Lv %d | Next: %d Salvage | Yield: %d/dig"
			% [upgrade_name, level, cost, yield_now]
		)

	if _siphon_button:
		_siphon_button.text = "Siphon %s (%d Salvage) [U]" % [upgrade_name, cost]
		_siphon_button.disabled = not can_afford
