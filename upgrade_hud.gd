extends VBoxContainer
## Hollow-only status + siphon UI.
## Shows Harvest countdown and Social Standing while home; Dig Yield siphon below.

@onready var _harvest_label: Label = $HarvestLabel
@onready var _standing_label: Label = $StandingLabel
@onready var _info: Label = $InfoLabel
@onready var _siphon_button: Button = $SiphonButton

var _upgrades: Node
var _wallet: Node
var _community: Node


func _ready() -> void:
	_upgrades = get_tree().root.get_node_or_null("Upgrades")
	_wallet = get_tree().root.get_node_or_null("Resources")
	_community = get_tree().root.get_node_or_null("Community")

	if _siphon_button:
		_siphon_button.focus_mode = Control.FOCUS_NONE
		_siphon_button.pressed.connect(_on_siphon_pressed)

	if _upgrades:
		_upgrades.upgrade_changed.connect(_on_upgrade_changed)
		_upgrades.siphon_station_changed.connect(_on_siphon_station_changed)
	if _wallet:
		_wallet.resource_changed.connect(_on_resource_changed)
	if _community:
		_community.harvest_timer_changed.connect(_on_harvest_timer_changed)
		_community.social_standing_changed.connect(_on_standing_changed)
		_community.harvest_completed.connect(_on_harvest_completed)

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
	_upgrades.siphon_for_upgrade(_upgrades.DIG_YIELD)
	_refresh()


func _on_upgrade_changed(_upgrade_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _on_siphon_station_changed(_is_open: bool) -> void:
	_refresh()


func _on_harvest_timer_changed(_seconds: float) -> void:
	_refresh_hollow_status()


func _on_standing_changed(_value: int) -> void:
	_refresh_hollow_status()


func _on_harvest_completed(_missed: bool) -> void:
	_refresh()


func _refresh() -> void:
	if _upgrades == null:
		visible = false
		return

	var in_hollow: bool = _upgrades.is_siphon_station_open()
	visible = in_hollow
	if not in_hollow:
		return

	_refresh_hollow_status()

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


func _refresh_hollow_status() -> void:
	if _community == null:
		if _harvest_label:
			_harvest_label.text = "Next Harvest: ?"
		if _standing_label:
			_standing_label.text = "Social Standing: ?"
		return

	var seconds: float = _community.get_harvest_seconds_remaining()
	if _harvest_label:
		_harvest_label.text = "Next Harvest: %ds" % int(ceil(seconds))

	if _standing_label:
		_standing_label.text = "Social Standing: %d/%d" % [
			_community.get_social_standing(),
			_community.SOCIAL_STANDING_MAX,
		]
