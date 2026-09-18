extends Node
## Krater Save / Load (autoload: SaveLoad).
## Build Bible Spec 02 (docs/build-bible/specs/02-save-load.md).
##
## Single rolling save slot (G10) — one file, no save-slot picker. Autosave
## triggers (sleep, civic phase transitions, quit) are wired by whatever
## system owns that moment calling save_game() (Community's Harvest
## completion today; the real Clock's phase_changed once Build Bible Spec 04
## exists) — this autoload only orchestrates WHEN a save/load happens and
## HOW it's written to disk, never a domain's internal state directly.
##
## Ownership stays distributed (Spec 02, confirmed option B): every domain
## autoload implements its own save_state() -> Dictionary /
## load_state(Dictionary) -> void pair for its own slice of state. SaveLoad
## calls that uniform contract on a known list of domain autoloads — it
## never reaches into a domain's internals, and a domain's own save_state
## shape can change freely without SaveLoad itself ever needing an edit.
##
## Access via get_tree().root.get_node("SaveLoad") (no class_name, matching
## the existing project convention — see resources.gd).

const SAVE_PATH := "user://krater_save.json"
const SAVE_TEMP_PATH := "user://krater_save.json.tmp"

## Spec 02: schema version stored in every save file; a mismatch is rejected
## loudly, never silently loaded as-is. This restarts the counter under the
## new nested {schema_version, domains} shape — the old flat-keys prototype
## format (top-level "salvage"/"trust"/... keys, an unenforced "version" int)
## predates this contract and is intentionally not migrated; see Spec 02's
## note that the exact migration mechanism is a separate, spike-owned
## question. An old save simply fails to load rather than being misread.
const SCHEMA_VERSION := 1

## Every autoload name SaveLoad persists, in save order. A domain missing
## save_state()/load_state() is skipped with a warning rather than failing
## the whole save/load — lets systems land ahead of their own Build Bible
## spec's save wiring without breaking everything else.
const DOMAIN_AUTOLOAD_NAMES: Array[String] = [
	"FactLog",
	"Clock",
	"Zones",
	"Stamina",
	"Storage",
	"Hauling",
	"Rig",
	"Resources",
	"Upgrades",
	"Community",
	"Districts",
	"Journal",
	"WorkOrders",
]

## Scene-tree nodes (not autoloads) that want to participate in save/load
## register themselves here instead of being found by a root-relative name
## — Terrain (a TileMapLayer that has to live inside the play scene's
## hierarchy to render/collide correctly, not as a top-level autoload) is
## the first user of this, but it's generic for whatever scene-owned system
## needs it next (Player, NPCs, ...). Registered under the SAME "domains"
## key namespace as autoload names in the save file — SaveLoad doesn't
## distinguish the two once a node is resolved.
var _scene_domains: Dictionary = {}


func _ready() -> void:
	# Load after sibling autoloads exist. Title screen may clear/reload explicitly.
	call_deferred("load_game")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func register_scene_domain(domain_name: String, node: Node) -> void:
	_scene_domains[domain_name] = node


func unregister_scene_domain(domain_name: String) -> void:
	_scene_domains.erase(domain_name)


## All currently-resolvable domain nodes, autoload and scene-registered
## alike, keyed by domain name — the single list every save/load/reset pass
## below iterates, so there's exactly one place that combines the two.
func _all_domain_nodes() -> Dictionary:
	var out := {}
	for domain_name: String in DOMAIN_AUTOLOAD_NAMES:
		var node := get_tree().root.get_node_or_null(domain_name)
		if node != null:
			out[domain_name] = node
	for domain_name: Variant in _scene_domains.keys():
		var node: Node = _scene_domains[domain_name]
		if is_instance_valid(node):
			out[str(domain_name)] = node
	return out


## Writes every registered domain's save_state() to disk via an atomic write
## (temp file + rename) so a crash mid-save can never corrupt the existing
## save file (Spec 02 invariant: never a partial write).
func save_game() -> bool:
	var domains := {}
	var nodes := _all_domain_nodes()
	for domain_name: Variant in nodes.keys():
		var node: Node = nodes[domain_name]
		if not node.has_method("save_state"):
			push_warning("SaveLoad: %s has no save_state() yet — skipped" % domain_name)
			continue
		domains[str(domain_name)] = node.save_state()

	var data := {
		"schema_version": SCHEMA_VERSION,
		"domains": domains,
	}

	var file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveLoad: could not write %s" % SAVE_TEMP_PATH)
		return false
	file.store_string(JSON.stringify(data))
	file.close()

	var err := DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	if err != OK:
		push_warning("SaveLoad: atomic rename failed (error %d) — save file left at %s" % [err, SAVE_TEMP_PATH])
		return false

	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.save_completed.emit()
	return true


## Restores every registered domain from disk. Loading is inert (Spec 02
## invariant) — it only calls each domain's own load_state(), which applies
## state through that domain's normal setters; nothing here re-fires
## one-time events or "welcome back" side effects.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveLoad: could not open %s" % SAVE_PATH)
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		# Spec 02 failure case: corrupted/unreadable save fails loudly.
		# Never silently start a new game without saying what happened.
		push_error("SaveLoad: %s is corrupted or unreadable — refusing to load" % SAVE_PATH)
		return false
	var data: Dictionary = parsed

	var version := int(data.get("schema_version", -1))
	if version != SCHEMA_VERSION:
		push_error(
			"SaveLoad: save schema version %d does not match expected %d — refusing to load (no migration path exists yet)"
			% [version, SCHEMA_VERSION]
		)
		return false

	var domains: Variant = data.get("domains", null)
	if typeof(domains) != TYPE_DICTIONARY:
		push_error("SaveLoad: save file missing domains data — refusing to load")
		return false

	var nodes := _all_domain_nodes()
	for domain_name: Variant in nodes.keys():
		if not (domains as Dictionary).has(str(domain_name)):
			continue
		var node: Node = nodes[domain_name]
		if not node.has_method("load_state"):
			continue
		node.load_state((domains as Dictionary)[str(domain_name)])

	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.load_completed.emit()
	return true


## Reset every registered domain for a New Game (also clears the save file).
func new_game() -> void:
	clear_save()
	var nodes := _all_domain_nodes()
	for domain_name: Variant in nodes.keys():
		var node: Node = nodes[domain_name]
		if node.has_method("reset_all"):
			node.reset_all()
	# theft_station_open is live physical-position state (set by HollowZone
	# from where the player actually is), not part of any domain's saved
	# progress — reset explicitly since no reset_all() covers it.
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	if upgrades != null and upgrades.has_method("set_theft_station_open"):
		upgrades.set_theft_station_open(false)


## Test helper: wipe the save file (and any leftover temp file from a
## previously interrupted atomic write).
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(SAVE_TEMP_PATH):
		DirAccess.remove_absolute(SAVE_TEMP_PATH)
