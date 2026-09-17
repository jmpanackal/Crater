extends Node
## Krater core infrastructure — Tuning Registry (autoload: TuningRegistry).
## Build Bible Spec 01 (docs/build-bible/specs/01-core-infrastructure.md).
##
## Every tunable number lives in a Resource (.tres) file under
## res://tuning/, never a hardcoded constant in gameplay code — the
## STRUCTURE of a rule is code, the NUMBER is always data. This is what
## makes every "exact numbers stay OPEN/tunable" note throughout
## mechanics-canon.md and the Build Bible actually mean something in
## practice.
##
## Each tuning domain is its own Resource subclass with typed exported
## fields (e.g. a future StaminaTuning.gd extends Resource) — this registry
## only knows how to find and hold them by filename, not their contents.
## Get the editor inspector + type safety for free instead of a loose
## Dictionary or raw JSON.
##
## Loaded once at startup; reload_all() re-reads every file from disk
## without restarting the game — wire to a debug command once Debug Tools
## (Build Bible Spec 03) exists.
##
## Access via get_tree().root.get_node("TuningRegistry") (no class_name,
## matching the existing project convention — see resources.gd).

const TUNING_DIR := "res://tuning/"

var _domains: Dictionary = {}


func _ready() -> void:
	reload_all()


## Re-scan res://tuning/ and reload every .tres file found, replacing
## whatever was previously loaded for that domain. Safe to call at any time.
## If a specific file fails to load, that domain's previous value is kept
## and a warning is logged — per Spec 01's failure-case rule, gameplay code
## should never need to know a tuning value could be missing.
func reload_all() -> void:
	var dir := DirAccess.open(TUNING_DIR)
	if dir == null:
		push_warning("TuningRegistry: %s does not exist yet (no tuning domains authored)" % TUNING_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var domain_name := file_name.get_basename()
			var path := TUNING_DIR + file_name
			# CACHE_MODE_REPLACE, not plain load(): load() caches by path, so a
			# second load() after the file changed on disk would silently
			# return the stale cached Resource instead of the new values —
			# defeating the entire point of a hot-reloadable registry.
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("TuningRegistry: failed to load %s — keeping previous value" % path)
			else:
				_domains[domain_name] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func get_domain(domain_name: String) -> Resource:
	return _domains.get(domain_name, null)


func has_domain(domain_name: String) -> bool:
	return _domains.has(domain_name)


func get_loaded_domain_names() -> Array[String]:
	var out: Array[String] = []
	for key: Variant in _domains.keys():
		out.append(str(key))
	return out
