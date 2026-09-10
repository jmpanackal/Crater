extends Node
## Communal Hollow life (autoload: Community).
## harvest_timer counts down each Harvest cycle. Missing a Harvest (being at the
## Dig Site when it completes) calls on_harvest_missed() and lowers social_standing.
## Optional lie prompt can dodge the miss; exposed lies hurt worse later.
## Upward digs and thin-cover siphons also risk Standing.

signal harvest_timer_changed(seconds_remaining: float)
signal harvest_completed(player_missed: bool)
signal social_standing_changed(new_standing: int)
signal harvest_miss_prompt
signal notice_message(text: String)

const HARVEST_INTERVAL_SEC := 60.0
const SOCIAL_STANDING_MAX := 100
const SOCIAL_STANDING_DEFAULT := 50
const SOCIAL_STANDING_MISS_PENALTY := 5
const LIE_EXPOSED_EXTRA_PENALTY := 8
const SIPHON_NOTICE_PENALTY := 3
const UPWARD_DIG_PENALTY := 4
const UPWARD_DIG_BASE_CHANCE := 0.1

## Seconds until the next communal Harvest completes.
var harvest_timer: float = HARVEST_INTERVAL_SEC

## Persistent reputation in the Hollow (0..SOCIAL_STANDING_MAX).
var social_standing: int = SOCIAL_STANDING_DEFAULT

## True after a successful Harvest-miss lie until exposed.
var pending_lie: bool = false

## When false, a missed Harvest emits harvest_miss_prompt instead of auto-penalizing.
var skip_lie_prompt: bool = true

var _paused := false
var _miss_awaiting_resolve := false


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
func on_harvest_missed() -> void:
	set_social_standing(social_standing - SOCIAL_STANDING_MISS_PENALTY)
	notice_message.emit("Missed Harvest. People noticed you were gone.")


## Answer the Harvest-miss lie prompt. lied=true dodges Standing for now.
func resolve_harvest_miss(lied: bool) -> void:
	if not _miss_awaiting_resolve:
		return
	_miss_awaiting_resolve = false
	if lied:
		pending_lie = true
		notice_message.emit("You lied about where you were. For now, it holds.")
	else:
		on_harvest_missed()


func has_pending_lie() -> bool:
	return pending_lie


func set_pending_lie(value: bool) -> void:
	pending_lie = value


## Forbidden siphon noticed — Standing drop; exposes a pending lie harder.
func on_siphon_noticed() -> void:
	var penalty := SIPHON_NOTICE_PENALTY
	var exposed := pending_lie
	if exposed:
		penalty += LIE_EXPOSED_EXTRA_PENALTY
		pending_lie = false
	set_social_standing(social_standing - penalty)
	if exposed:
		notice_message.emit("Siphon noticed — and your earlier lie came apart. (−%d Standing)" % penalty)
	else:
		notice_message.emit("Someone noticed materials going missing. (−%d Standing)" % penalty)


## Chance of being caught digging toward the Cap. quiet_level reduces risk.
func roll_upward_dig_risk(quiet_level: int = 0) -> bool:
	var chance := UPWARD_DIG_BASE_CHANCE * pow(0.65, float(maxi(0, quiet_level)))
	if randf() >= chance:
		return false
	on_caught_upward_dig()
	return true


func on_caught_upward_dig() -> void:
	var penalty := UPWARD_DIG_PENALTY
	var exposed := pending_lie
	if exposed:
		penalty += LIE_EXPOSED_EXTRA_PENALTY
		pending_lie = false
	set_social_standing(social_standing - penalty)
	if exposed:
		notice_message.emit("Caught digging the Cap — and your lie cracked. (−%d Standing)" % penalty)
	else:
		notice_message.emit("Soft rock-fall above — someone asks why you dig that way. (−%d Standing)" % penalty)


func _complete_harvest_cycle() -> void:
	var missed := not is_player_in_hollow()
	if missed:
		if skip_lie_prompt:
			on_harvest_missed()
		else:
			_miss_awaiting_resolve = true
			harvest_miss_prompt.emit()
	harvest_completed.emit(missed)
	harvest_timer = HARVEST_INTERVAL_SEC
	harvest_timer_changed.emit(harvest_timer)

	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load and save_load.has_method("save_game"):
		save_load.save_game()


## Test helper: freeze the countdown without clearing state.
func set_paused(paused: bool) -> void:
	_paused = paused
