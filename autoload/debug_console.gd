extends CanvasLayer
## Krater Debug Tools (autoload: DebugConsole).
## Build Bible Spec 03 (docs/build-bible/specs/03-debug-tools.md).
##
## Registry pattern: systems register their own commands and state
## inspectors here as they're built — this framework never needs to know
## about every system upfront. That's why it ships this early (build-order
## #3) and grows incrementally as every later spec adds to it, rather than
## being written once at the end.
##
## Gated behind OS.is_debug_build() — never present in a shipped/exported
## release build, regardless of what key is pressed (Spec 03 invariant:
## "never a runtime toggle a player could stumble into"). The overlay is
## never even constructed in a release build.
##
## Access via get_tree().root.get_node("DebugConsole") (no class_name,
## matching the existing project convention — see resources.gd).

const TOGGLE_ACTION := "toggle_debug_console"

## One registered console command.
class DebugCommand:
	var name: String
	var description: String
	var callable: Callable

	func _init(p_name: String, p_description: String, p_callable: Callable) -> void:
		name = p_name
		description = p_description
		callable = p_callable

var _commands: Dictionary = {}
## Optional per-domain override for get_domain_state(); most domains don't
## need one since save_state() (Spec 02) already covers "dump my state" —
## this exists for a domain that wants its debug dump to show more than
## what gets persisted (derived values, for instance).
var _inspectors: Dictionary = {}
var _log_lines: PackedStringArray = []

var _panel: Control
var _output: RichTextLabel
var _input_field: LineEdit


func _ready() -> void:
	if not OS.is_debug_build():
		return
	_register_builtin_commands()
	_build_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if InputMap.has_action(TOGGLE_ACTION) and event.is_action_pressed(TOGGLE_ACTION):
		toggle_overlay()
		get_viewport().set_input_as_handled()


func toggle_overlay() -> void:
	if not OS.is_debug_build() or _panel == null:
		return
	_panel.visible = not _panel.visible
	if _panel.visible:
		_input_field.grab_focus()


func is_overlay_visible() -> bool:
	return _panel != null and _panel.visible


## Registers a command. Matched case-insensitively against the first
## whitespace-separated token of console input; the remaining tokens are
## passed to callable as a single Array[String].
##
## callable's return value is converted with str() and shown as the
## result — return "" for a silent success, or a message either way.
## Spec 03's failure-case rule ("never crashes the session") is only fully
## guaranteed for unknown-command / not-yet-registered input; a poorly
## written registered callable is still that system's own responsibility,
## same as this spec's own note that the framework can't generically
## enforce every rule a registered command should follow.
func register_command(name: String, description: String, callable: Callable) -> void:
	_commands[name.to_lower()] = DebugCommand.new(name, description, callable)


func unregister_command(name: String) -> void:
	_commands.erase(name.to_lower())


func get_registered_commands() -> Array:
	var out: Array = []
	for key: Variant in _commands.keys():
		out.append(_commands[key])
	return out


## Registers a custom state inspector for a domain name, overriding the
## automatic save_state() fallback in get_domain_state().
func register_inspector(domain_name: String, callable: Callable) -> void:
	_inspectors[domain_name] = callable


func unregister_inspector(domain_name: String) -> void:
	_inspectors.erase(domain_name)


## Dumps a domain's current state for the "dump" command / a future state
## inspector panel. Prefers a registered custom inspector; falls back to
## calling save_state() (Spec 02's uniform contract) on the matching
## autoload — most domains don't need to register anything extra here.
func get_domain_state(domain_name: String) -> Dictionary:
	if _inspectors.has(domain_name):
		var out: Variant = _inspectors[domain_name].call()
		return out if typeof(out) == TYPE_DICTIONARY else {}
	var node := get_tree().root.get_node_or_null(domain_name)
	if node != null and node.has_method("save_state"):
		return node.save_state()
	return {}


## Executes one line of console input, returns the result text (also
## appended to the on-screen log). An unknown command or an invalidated
## callable returns an error string rather than crashing (Spec 03 failure
## case), but this framework can't protect against an internal error
## inside a well-formed, registered callable's own logic.
func execute(input: String) -> String:
	var trimmed := input.strip_edges()
	if trimmed.is_empty():
		return ""
	var parts := trimmed.split(" ", false)
	var cmd_name: String = str(parts[0]).to_lower()
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(str(parts[i]))

	var result: String
	if not _commands.has(cmd_name):
		result = "Unknown command: %s (try 'help')" % cmd_name
	else:
		var command: DebugCommand = _commands[cmd_name]
		if not command.callable.is_valid():
			result = "Command '%s' is no longer valid (its target may have been freed)" % cmd_name
		else:
			var raw: Variant = command.callable.call(args)
			result = str(raw) if raw != null and str(raw) != "" else "OK"

	_log_lines.append("> " + trimmed)
	_log_lines.append(result)
	_refresh_output()
	return result


func _register_builtin_commands() -> void:
	register_command("help", "List all registered commands.", func(_args: Array[String]) -> String:
		var lines: PackedStringArray = []
		var names: Array = _commands.keys()
		names.sort()
		for key: Variant in names:
			var command: DebugCommand = _commands[key]
			lines.append("%s — %s" % [command.name, command.description])
		return "\n".join(lines)
	)

	register_command("dump", "dump <domain> — show a registered domain's current state.", func(args: Array[String]) -> String:
		if args.is_empty():
			return "Usage: dump <domain_autoload_name>"
		var state := get_domain_state(args[0])
		if state.is_empty():
			return "No state found for '%s' (not an autoload, or it has no save_state()/inspector)" % args[0]
		return JSON.stringify(state, "  ")
	)

	register_command("facts", "facts [type=<t>] [subject=<s>] [cycle_from=<n>] [cycle_to=<n>] — browse the Fact Log.", func(args: Array[String]) -> String:
		var fact_log := get_tree().root.get_node_or_null("FactLog")
		if fact_log == null:
			return "FactLog autoload not found."
		var filters := {}
		for arg in args:
			var eq := arg.find("=")
			if eq > 0:
				filters[arg.substr(0, eq)] = arg.substr(eq + 1)
		var results: Array = fact_log.get_all()
		if filters.has("type"):
			results = results.filter(func(f: Dictionary) -> bool: return str(f["type"]) == filters["type"])
		if filters.has("subject"):
			results = results.filter(func(f: Dictionary) -> bool: return str(f["subject"]) == filters["subject"])
		if filters.has("cycle_from"):
			var from_c := int(filters["cycle_from"])
			results = results.filter(func(f: Dictionary) -> bool: return int(f["cycle"]) >= from_c)
		if filters.has("cycle_to"):
			var to_c := int(filters["cycle_to"])
			results = results.filter(func(f: Dictionary) -> bool: return int(f["cycle"]) <= to_c)
		if results.is_empty():
			return "No matching facts (%d total in log)." % fact_log.count()
		var lines: PackedStringArray = []
		for fact: Dictionary in results:
			lines.append(JSON.stringify(fact))
		return "\n".join(lines)
	)

	# Wired to the current pre-canon prototype's Trust/Materials stand-ins
	# (Community.trust, Resources) — real per Spec 03's own acceptance-test
	# note that these commands "exist and work once the systems they target
	# are built", and Trust/Materials already exist in some form today.
	register_command("set_trust", "set_trust <value> — set Community.trust directly (0-100).", func(args: Array[String]) -> String:
		if args.is_empty():
			return "Usage: set_trust <0-100>"
		var community := get_tree().root.get_node_or_null("Community")
		if community == null:
			return "Community autoload not found."
		community.set_trust(int(args[0]))
		return "Trust set to %d" % community.get_trust()
	)

	# Targets Storage (Build Bible Spec 11), the canon Materials owner — not
	# the retired Salvage wallet (resources.gd), which still exists only for
	# the retired mechanics awaiting their own specs' migration. Storage
	# rejects retired ids (sporemeal, lampwick, ...), so this command also
	# teaches the locked vocabulary instead of silently minting old names.
	register_command("spawn_material", "spawn_material <id> <amount> — add Materials to personal storage directly, bypassing hauling.", func(args: Array[String]) -> String:
		if args.size() < 2:
			return "Usage: spawn_material <id> <amount>"
		var storage := get_tree().root.get_node_or_null("Storage")
		if storage == null:
			return "Storage autoload not found."
		var material_id := StringName(args[0])
		var amount := int(args[1])
		var before: int = int(storage.get_material_count(material_id))
		if not bool(storage.deposit_material(material_id, amount)):
			var known: Array[StringName] = storage.get_material_ids()
			return "Refused: '%s' is not a known Material (or amount <= 0). Known: %s" % [args[0], ", ".join(PackedStringArray(known))]
		return "%s: %d (was %d)" % [material_id, storage.get_material_count(material_id), before]
	)


func _build_overlay() -> void:
	layer = 100

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -260
	_panel.offset_bottom = 0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	_output = RichTextLabel.new()
	_output.custom_minimum_size = Vector2(0, 220)
	_output.scroll_following = true
	_output.bbcode_enabled = false
	vbox.add_child(_output)

	_input_field = LineEdit.new()
	_input_field.placeholder_text = "type a command, Enter to run — 'help' to list"
	_input_field.text_submitted.connect(_on_input_submitted)
	vbox.add_child(_input_field)

	_refresh_output()


func _on_input_submitted(text: String) -> void:
	execute(text)
	_input_field.text = ""


func _refresh_output() -> void:
	if _output == null:
		return
	_output.text = "\n".join(_log_lines)
