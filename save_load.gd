extends Node
## Minimal JSON save/load (autoload: SaveLoad).
## Persists Act 1: Materials, upgrades, Trust, harvest, District production, journal, lies, Work Orders.

const SAVE_PATH := "user://krater_save.json"
const SAVE_VERSION := 4


func _ready() -> void:
	# Load after sibling autoloads exist. Title screen may clear/reload explicitly.
	call_deferred("load_game")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var wallet := get_tree().root.get_node_or_null("Resources")
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	var community := get_tree().root.get_node_or_null("Community")
	var districts := get_tree().root.get_node_or_null("Districts")
	var journal := get_tree().root.get_node_or_null("Journal")
	var work_orders := get_tree().root.get_node_or_null("WorkOrders")
	if wallet == null or upgrades == null or community == null:
		push_warning("SaveLoad: missing autoload; skip save")
		return false

	var data := {
		"version": SAVE_VERSION,
		"salvage": wallet.get_amount(wallet.SALVAGE),
		"materials": wallet.get_materials_snapshot() if wallet.has_method("get_materials_snapshot") else {},
		"upgrade_levels": upgrades.get_levels_snapshot(),
		"trust": community.get_trust(),
		"harvest_timer": community.get_harvest_seconds_remaining(),
		"pending_lie": community.has_pending_lie(),
	}
	if districts and districts.has_method("get_production_snapshot"):
		data["district_production"] = districts.get_production_snapshot()
	# Keep legacy key for older tooling / partial readers.
	if districts and districts.has_method("get_stocks_snapshot"):
		data["district_stocks"] = districts.get_stocks_snapshot()
	if journal and journal.has_method("get_snapshot"):
		data["journal_records"] = journal.get_snapshot()
	if work_orders and work_orders.has_method("get_snapshot"):
		data["work_orders"] = work_orders.get_snapshot()

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
	var districts := get_tree().root.get_node_or_null("Districts")
	var journal := get_tree().root.get_node_or_null("Journal")
	var work_orders := get_tree().root.get_node_or_null("WorkOrders")
	if wallet == null or upgrades == null or community == null:
		return false

	if data.has("materials") and typeof(data["materials"]) == TYPE_DICTIONARY and wallet.has_method("apply_materials_snapshot"):
		wallet.apply_materials_snapshot(data["materials"])
	elif data.has("salvage"):
		wallet.set_amount(wallet.SALVAGE, int(data["salvage"]))

	if data.has("upgrade_levels") and typeof(data["upgrade_levels"]) == TYPE_DICTIONARY:
		upgrades.apply_levels_snapshot(data["upgrade_levels"])
	if data.has("trust"):
		community.set_trust(int(data["trust"]))
	elif data.has("social_standing"): # Legacy save key: Social Standing → Trust.
		community.set_trust(int(data["social_standing"]))
	if data.has("harvest_timer"):
		community.set_harvest_timer(float(data["harvest_timer"]))
	if data.has("pending_lie") and community.has_method("set_pending_lie"):
		community.set_pending_lie(bool(data["pending_lie"]))

	if data.has("district_production") and districts and districts.has_method("apply_production_snapshot"):
		if typeof(data["district_production"]) == TYPE_DICTIONARY:
			districts.apply_production_snapshot(data["district_production"])
	elif data.has("district_stocks") and districts and districts.has_method("apply_stocks_snapshot"):
		if typeof(data["district_stocks"]) == TYPE_DICTIONARY:
			districts.apply_stocks_snapshot(data["district_stocks"])

	if data.has("journal_records") and journal and journal.has_method("apply_snapshot"):
		if typeof(data["journal_records"]) == TYPE_ARRAY:
			journal.apply_snapshot(data["journal_records"])

	if work_orders and work_orders.has_method("apply_snapshot"):
		if data.has("work_orders") and typeof(data["work_orders"]) == TYPE_DICTIONARY:
			work_orders.apply_snapshot(data["work_orders"])
		elif work_orders.has_method("reset_all"):
			# Older saves: start the Act 1 Work Order slate fresh.
			work_orders.reset_all()
	return true


## Reset runtime state for a New Game (also clears the save file).
func new_game() -> void:
	clear_save()
	var wallet := get_tree().root.get_node_or_null("Resources")
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	var community := get_tree().root.get_node_or_null("Community")
	var districts := get_tree().root.get_node_or_null("Districts")
	var journal := get_tree().root.get_node_or_null("Journal")
	var work_orders := get_tree().root.get_node_or_null("WorkOrders")

	if wallet:
		if wallet.has_method("reset_all"):
			wallet.reset_all()
		else:
			wallet.set_amount(wallet.SALVAGE, 0)
	if upgrades:
		for id in upgrades.get_upgrade_ids():
			upgrades.set_level(id, 0)
		upgrades.set_theft_station_open(false)
	if community:
		community.set_trust(community.TRUST_DEFAULT)
		community.set_harvest_timer(community.HARVEST_INTERVAL_SEC)
		community.set_pending_lie(false)
		community.skip_lie_prompt = false
	if districts:
		if districts.has_method("reset_production"):
			districts.reset_production()
		else:
			for id in districts.get_district_ids():
				districts.set_stock(id, 0.0)
	if journal:
		journal.clear_all()
	if work_orders and work_orders.has_method("reset_all"):
		work_orders.reset_all()


## Test helper: wipe the save file.
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
