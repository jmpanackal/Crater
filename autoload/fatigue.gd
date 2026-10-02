extends Node
## Krater Fatigue / Overexertion / Recovery (autoload: Fatigue).
## Build Bible Spec 09 (docs/build-bible/specs/09-fatigue.md).
##
## Longer-lasting expedition strain that does NOT clear through ordinary
## stamina regeneration (canon §10) — only sleep (full recovery) or field
## rest (partial, at a time cost) clear it.
##
## Fatigue does not keep its own shadow copy of the current amount (Spec
## 01: no shadow copies of state readable from its owner) — Stamina (Spec
## 08) already stores the raw "fatigue" block value in its block map;
## Fatigue is the sole system that WRITES to that specific slot (via
## Stamina.request_block()/release_block()), and reads it back the same
## way anything else reading Stamina's state would.
##
## Access via get_tree().root.get_node("Fatigue") (no class_name, matching
## the existing project convention — see resources.gd).

const TUNING_DOMAIN := "fatigue_tuning"


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command(
		"set_fatigue", "set_fatigue <amount> — set current fatigue directly.", _debug_set_fatigue
	)
	console.register_command(
		"force_exhausted", "force_exhausted — set fatigue to exactly max stamina.", _debug_force_exhausted
	)
	console.register_command(
		"recover_fatigue",
		"recover_fatigue [amount] — full recovery with no amount, partial recovery with one.",
		_debug_recover
	)


func get_current() -> float:
	var stamina := _stamina()
	return stamina.get_block(stamina.SOURCE_FATIGUE) if stamina != null else 0.0


## True once fatigue alone has filled the bar (canon §10) — delegates to
## Stamina, which already owns this computation; not duplicated here.
func is_exhausted() -> bool:
	var stamina := _stamina()
	return bool(stamina.is_exhausted()) if stamina != null else false


## Called by Stamina when an Overexertion resolves (Spec 08). Adds a FIXED
## cost per instance (Spec 09, confirmed option A) — not scaled to how far
## past zero the triggering action went. Refuses outright (adds nothing,
## returns 0.0) if already Exhausted — Spec 09's own failure case: no
## further Overexertion is possible once fatigue alone already fills the
## bar; only recovery clears it.
func add_from_overexertion() -> float:
	if is_exhausted():
		return 0.0
	var stamina := _stamina()
	if stamina == null:
		return 0.0
	var amount := get_fixed_overexertion_cost()
	stamina.request_block(stamina.SOURCE_FATIGUE, get_current() + amount)
	return amount


## Build Bible Spec 30: fatigue from a severe fall or a rescue — a fixed,
## explainable amount added to the block (capped at the bar). Returns the
## amount actually added.
func add_fatigue(amount: float) -> float:
	var stamina := _stamina()
	if stamina == null or amount <= 0.0:
		return 0.0
	var before := get_current()
	var next := minf(float(stamina.get_max_stamina()), before + amount)
	stamina.request_block(stamina.SOURCE_FATIGUE, next)
	return next - before


## Build Bible Spec 30: a rescue leaves the player at a known fatigue level
## (partial recovery — rescuers carry you home, they don't rest you).
func set_fatigue(amount: float) -> void:
	var stamina := _stamina()
	if stamina == null:
		return
	stamina.request_block(stamina.SOURCE_FATIGUE, clampf(amount, 0.0, float(stamina.get_max_stamina())))


## Full recovery — called by sleep, via the Clock's cycle-advance.
func recover_full() -> void:
	var stamina := _stamina()
	if stamina != null:
		stamina.release_block(stamina.SOURCE_FATIGUE)


## Partial recovery by a fixed amount — called by field rest, at whatever
## time cost the specific rest point defines (Spec 09, confirmed option A:
## resting is an explicit interaction, not passive proximity — the time
## cost itself belongs to whatever rest-point content calls this, not to
## Fatigue). Clamps at zero, never goes negative.
func recover_partial(amount: float) -> void:
	var stamina := _stamina()
	if stamina == null:
		return
	var next := maxf(0.0, get_current() - amount)
	stamina.request_block(stamina.SOURCE_FATIGUE, next)


func get_fixed_overexertion_cost() -> float:
	var tuning := _tuning()
	return float(tuning.overexertion_fatigue_cost) if tuning != null else 15.0


func _stamina() -> Node:
	return get_tree().root.get_node_or_null("Stamina")


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


func _debug_set_fatigue(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: set_fatigue <amount>"
	var stamina := _stamina()
	if stamina == null:
		return "Stamina autoload not found."
	stamina.request_block(stamina.SOURCE_FATIGUE, float(args[0]))
	return "Fatigue set to %s" % get_current()


func _debug_force_exhausted(_args: Array[String]) -> String:
	var stamina := _stamina()
	if stamina == null:
		return "Stamina autoload not found."
	stamina.request_block(stamina.SOURCE_FATIGUE, stamina.get_max_stamina())
	return "Fatigue forced to max stamina (%s) — Exhausted." % stamina.get_max_stamina()


func _debug_recover(args: Array[String]) -> String:
	if args.is_empty():
		recover_full()
		return "Full recovery — fatigue cleared."
	recover_partial(float(args[0]))
	return "Partial recovery by %s — fatigue now %s" % [args[0], get_current()]
