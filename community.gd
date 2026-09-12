extends Node
## Communal Hollow life (autoload: Community).
## harvest_timer counts down each Harvest cycle. Missing a Harvest (being at the
## Dig Site when it completes) calls on_harvest_missed() and lowers Trust.
## Optional lie prompt can dodge the miss; exposed lies hurt worse later.
## Upward digs and thin-cover thefts also risk Trust.

signal harvest_timer_changed(seconds_remaining: float)
signal harvest_completed(player_missed: bool)
signal trust_changed(new_trust: int)
signal harvest_miss_prompt
signal notice_message(text: String)

const HARVEST_INTERVAL_SEC := 60.0
const TRUST_MAX := 100
const TRUST_DEFAULT := 50
const TRUST_MISS_PENALTY := 5
const LIE_EXPOSED_EXTRA_PENALTY := 8
const THEFT_NOTICE_PENALTY := 3
const UPWARD_DIG_PENALTY := 4
const UPWARD_DIG_BASE_CHANCE := 0.1

## Seconds until the next communal Harvest completes.
var harvest_timer: float = HARVEST_INTERVAL_SEC

## Persistent trust in the Hollow (0..TRUST_MAX).
var trust: int = TRUST_DEFAULT

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


func get_trust() -> int:
	return trust


func set_trust(value: int) -> void:
	var next := clampi(value, 0, TRUST_MAX)
	if next == trust:
		return
	trust = next
	trust_changed.emit(trust)


func set_harvest_timer(seconds: float) -> void:
	harvest_timer = maxf(0.0, seconds)
	harvest_timer_changed.emit(harvest_timer)


## True when the player is currently in the Hollow (reuse theft-station presence).
func is_player_in_hollow() -> bool:
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	return upgrades != null and upgrades.is_theft_station_open()


## Player was at the Dig Site (or otherwise away) when Harvest completed.
func on_harvest_missed() -> void:
	set_trust(trust - TRUST_MISS_PENALTY)
	notice_message.emit("Missed Harvest. People noticed you were gone.")


## Answer the Harvest-miss lie prompt. lied=true dodges Trust for now.
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


## Forbidden theft noticed — Trust drop; exposes a pending lie harder.
func on_theft_noticed() -> void:
	var penalty := THEFT_NOTICE_PENALTY
	var exposed := pending_lie
	if exposed:
		penalty += LIE_EXPOSED_EXTRA_PENALTY
		pending_lie = false
	set_trust(trust - penalty)
	if exposed:
		notice_message.emit("The theft was noticed — and your earlier lie came apart. (−%d Trust)" % penalty)
	else:
		notice_message.emit("Someone noticed District production going missing. (−%d Trust)" % penalty)


## Chance of being caught digging toward the Firmament. quiet_level reduces risk.
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
	set_trust(trust - penalty)
	if exposed:
		notice_message.emit("Caught digging the Firmament — and your lie cracked. (−%d Trust)" % penalty)
	else:
		notice_message.emit("Soft rock-fall above — someone asks why you dig that way. (−%d Trust)" % penalty)


func _complete_harvest_cycle() -> void:
	var missed := not is_player_in_hollow()
	if missed:
		if skip_lie_prompt:
			on_harvest_missed()
		else:
			_miss_awaiting_resolve = true
			harvest_miss_prompt.emit()

	var districts := get_tree().root.get_node_or_null("Districts")
	if districts and districts.has_method("apply_harvest"):
		districts.apply_harvest()

	harvest_completed.emit(missed)
	harvest_timer = HARVEST_INTERVAL_SEC
	harvest_timer_changed.emit(harvest_timer)

	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load and save_load.has_method("save_game"):
		save_load.save_game()


## Test helper: freeze the countdown without clearing state.
func set_paused(paused: bool) -> void:
	_paused = paused
