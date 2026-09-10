extends Node
## Minimal JSON save/load (autoload: SaveLoad).
## Persists Salvage, upgrade levels, social_standing, and harvest_timer.
## There was no save system in the repo yet — this is the seed for Act 1 persistence.

const SAVE_PATH := "user://krater_save.json"


func _ready() -> void:
	# Load after sibling autoloads exist.
	call_deferred("load_game")


func save_game() -> bool:
	var wallet := get_tree().root.get_node_or_null("Resources")
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	var community := get_tree().root.get_node_or_null("Community")
	if wallet == null or upgrades == null or community == null:
		push_warning("SaveLoad: missing autoload; skip save")
		return false

	var data := {
		"version": 1,
		"salvage": wallet.get_amount(wallet.SALVAGE),
		"upgrade_levels": upgrades.get_levels_snapshot(),
		"social_standing": community.get_social_standing(),
		"harvest_timer": community.get_harvest_seconds_remaining(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveLoad: could not write %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed

	var wallet := get_tree().root.get_node_or_null("Resources")
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	var community := get_tree().root.get_node_or_null("Community")
	if wallet == null or upgrades == null or community == null:
		return false

	if data.has("salvage"):
		wallet.set_amount(wallet.SALVAGE, int(data["salvage"]))
	if data.has("upgrade_levels") and typeof(data["upgrade_levels"]) == TYPE_DICTIONARY:
		upgrades.apply_levels_snapshot(data["upgrade_levels"])
	if data.has("social_standing"):
		community.set_social_standing(int(data["social_standing"]))
	if data.has("harvest_timer"):
		community.set_harvest_timer(float(data["harvest_timer"]))
	return true


## Test helper: wipe the save file.
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
