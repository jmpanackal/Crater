extends Node
## Communal Hollow life (autoload: Community).
## harvest_timer counts down each Harvest cycle. Missing a Harvest (being at the
## Dig Site when it completes) calls on_harvest_missed() and lowers social_standing.
## Lie mechanic / recruitment consequences will hook these same entry points later.

signal harvest_timer_changed(seconds_remaining: float)
signal harvest_completed(player_missed: bool)
signal social_standing_changed(new_standing: int)

const HARVEST_INTERVAL_SEC := 60.0
const SOCIAL_STANDING_MAX := 100
const SOCIAL_STANDING_DEFAULT := 50
const SOCIAL_STANDING_MISS_PENALTY := 5

## Seconds until the next communal Harvest completes.
var harvest_timer: float = HARVEST_INTERVAL_SEC

## Persistent reputation in the Hollow (0..SOCIAL_STANDING_MAX).
var social_standing: int = SOCIAL_STANDING_DEFAULT

var _paused := false


func _process(delta: float) -> void:
	if _paused:
		return
	var previous := harvest_timer
	harvest_timer = maxf(0.0, harvest_timer - delta)
	if not is_equal_approx(previous, harvest_timer):
		harvest_timer_changed.emit(harvest_timer)
	if harvest_timer <= 0.0:
		_complete_harvest_cycle()


## Force a Harvest resolution now (also used by tests).
func trigger_harvest_now() -> void:
	_complete_harvest_cycle()


func get_harvest_seconds_remaining() -> float:
	return harvest_timer


func get_social_standing() -> int:
	return social_standing


func set_social_standing(value: int) -> void:
	var next := clampi(value, 0, SOCIAL_STANDING_MAX)
	if next == social_standing:
		return
	social_standing = next
	social_standing_changed.emit(social_standing)


func set_harvest_timer(seconds: float) -> void:
	harvest_timer = maxf(0.0, seconds)
	harvest_timer_changed.emit(harvest_timer)


## True when the player is currently in the Hollow (reuse siphon-station presence).
func is_player_in_hollow() -> bool:
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	return upgrades != null and upgrades.is_siphon_station_open()


## Player was at the Dig Site (or otherwise away) when Harvest completed.
## Hook for later: lie to cover the absence, worse penalty if exposed.
func on_harvest_missed() -> void:
	set_social_standing(social_standing - SOCIAL_STANDING_MISS_PENALTY)


func _complete_harvest_cycle() -> void:
	var missed := not is_player_in_hollow()
	if missed:
		on_harvest_missed()
	harvest_completed.emit(missed)
	harvest_timer = HARVEST_INTERVAL_SEC
	harvest_timer_changed.emit(harvest_timer)

	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load and save_load.has_method("save_game"):
		save_load.save_game()


## Test helper: freeze the countdown without clearing state.
func set_paused(paused: bool) -> void:
	_paused = paused
