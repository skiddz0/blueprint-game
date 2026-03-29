## Data Loader — Autoload singleton that loads and caches all JSON game data.
## All game content flows from game_data/ JSON files through this system.
## See: design/gdd/data-loader.md
extends Node

## Emitted after all 7 JSON files are loaded and cached successfully.
signal data_loaded
## Emitted if any file fails to load or parse, with error description.
signal data_load_failed(error_message: String)

const DATA_DIR := "res://game_data/"

## File manifest: cache_key -> { filename, root_key (or "" for root-level dict) }
const FILE_MANIFEST := {
	"config":       { "filename": "config.json",       "root_key": "" },
	"initiatives":  { "filename": "initiatives.json",  "root_key": "initiatives" },
	"scenarios":    { "filename": "scenarios.json",     "root_key": "scenarios" },
	"ministers":    { "filename": "ministers.json",      "root_key": "ministers" },
	"shifts":       { "filename": "shifts.json",        "root_key": "shifts" },
	"achievements": { "filename": "achievements.json",  "root_key": "achievements" },
	"timeline":     { "filename": "timeline.json",      "root_key": "" },
}

var _cache: Dictionary = {}
var _is_loaded: bool = false


func _ready() -> void:
	_load_all_files()


## Returns true if all data files have been loaded successfully.
func is_loaded() -> bool:
	return _is_loaded


# -- Primary accessors ----------------------------------------------------------

## Returns the game config dictionary (config.json root object).
func get_config() -> Dictionary:
	return _cache.get("config", {})


## Returns array of all initiative dictionaries.
func get_initiatives() -> Array:
	return _cache.get("initiatives", [])


## Returns array of all scenario dictionaries.
func get_scenarios() -> Array:
	return _cache.get("scenarios", [])


## Returns array of all minister dictionaries.
func get_ministers() -> Array:
	return _cache.get("ministers", [])


## Returns array of all shift dictionaries.
func get_shifts() -> Array:
	return _cache.get("shifts", [])


## Returns array of all achievement dictionaries.
func get_achievements() -> Array:
	return _cache.get("achievements", [])


## Returns array of all timeline event dictionaries.
func get_timeline() -> Array:
	return _cache.get("timeline", [])


# -- Convenience queries --------------------------------------------------------

## Returns initiatives filtered by category string.
func get_initiatives_by_category(category: String) -> Array:
	var result: Array = []
	for init: Dictionary in get_initiatives():
		if init.get("category", "") == category:
			result.append(init)
	return result


## Returns initiatives unlocked at or before the given year.
func get_initiatives_by_year(year: int) -> Array:
	var result: Array = []
	for init: Dictionary in get_initiatives():
		if init.get("unlock_year", 9999) <= year:
			result.append(init)
	return result


## Returns the scenario scheduled for the given year and month (1-12), or null.
func get_scenario_by_year_month(year: int, month: int) -> Variant:
	for scenario: Dictionary in get_scenarios():
		if scenario.get("year", 0) == year and scenario.get("month", 0) == month:
			return scenario
	return null


## Returns the minister active during the given year, or null.
func get_minister_by_year(year: int) -> Variant:
	for minister: Dictionary in get_ministers():
		if minister.get("start_year", 0) <= year and year <= minister.get("end_year", 0):
			return minister
	return null


## Returns the shift dictionary for the given shift id (1-11), or null.
func get_shift_by_id(id: int) -> Variant:
	for shift: Dictionary in get_shifts():
		if shift.get("id", -1) == id:
			return shift
	return null


## Dot-path access into the config: get_config_value("kpis", "victory_threshold").
func get_config_value(section: String, key: String) -> Variant:
	var cfg := get_config()
	var sec: Variant = cfg.get(section, null)
	if sec is Dictionary:
		return sec.get(key, null)
	return null


# -- Internal loading -----------------------------------------------------------

func _load_all_files() -> void:
	for cache_key: String in FILE_MANIFEST:
		var manifest: Dictionary = FILE_MANIFEST[cache_key]
		var path: String = DATA_DIR + manifest["filename"]
		var root_key: String = manifest["root_key"]

		var result: Variant = _load_json_file(path, root_key)
		if result == null:
			_is_loaded = false
			data_load_failed.emit("Failed to load: " + path)
			return

		_cache[cache_key] = result

	_is_loaded = true
	data_loaded.emit()


func _load_json_file(path: String, root_key: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: File not found: " + path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: Cannot open: " + path + " error: " + str(FileAccess.get_open_error()))
		return null

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(content)
	if parse_error != OK:
		push_error("DataLoader: JSON parse error in " + path + ": " + json.get_error_message())
		return null

	var data: Variant = json.data

	# If root_key is specified, extract that key from the parsed object
	if root_key != "":
		if data is Dictionary and data.has(root_key):
			return data[root_key]
		else:
			push_error("DataLoader: Missing root key '" + root_key + "' in " + path)
			return null

	return data
