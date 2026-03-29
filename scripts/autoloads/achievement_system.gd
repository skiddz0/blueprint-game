## Achievement System — Tracks 20 achievements, persists across sessions.
## See: design/gdd/achievement-system.md
extends Node

signal achievement_unlocked(achievement: Dictionary)

const SAVE_PATH := "user://achievements.json"

var _definitions: Array = []
var _unlocked: Dictionary = {}  # id -> timestamp


func _ready() -> void:
	_load_unlocked()


func initialize(definitions: Array) -> void:
	_definitions = definitions


## Check all achievements against current game state. Call at year-end and game-end.
func check_achievements(game_state: Dictionary, is_game_end: bool = false) -> void:
	for achievement: Dictionary in _definitions:
		var aid: String = str(achievement.get("id", ""))
		if aid == "" or _unlocked.has(aid):
			continue

		if _evaluate(achievement, game_state, is_game_end):
			_unlock(achievement)


## Get list of all achievements with unlocked status.
func get_all_achievements() -> Array:
	var result: Array = []
	for achievement: Dictionary in _definitions:
		var entry := achievement.duplicate()
		var aid: String = str(achievement.get("id", ""))
		entry["unlocked"] = _unlocked.has(aid)
		entry["unlock_time"] = _unlocked.get(aid, 0)
		result.append(entry)
	return result


## Get count of unlocked achievements.
func get_unlocked_count() -> int:
	return _unlocked.size()


## Get total achievement count.
func get_total_count() -> int:
	return _definitions.size()


# -- Evaluation ----------------------------------------------------------------

func _evaluate(achievement: Dictionary, state: Dictionary, is_game_end: bool) -> bool:
	var condition: Variant = achievement.get("condition")
	if not (condition is Dictionary):
		return false

	var ctype: String = str(condition.get("type", ""))

	match ctype:
		"kpi_threshold":
			var kpi: String = str(condition.get("kpi", ""))
			var threshold: float = float(condition.get("threshold", 999))
			if state["kpis"].has(kpi):
				return float(state["kpis"][kpi]["value"]) >= threshold
		"kpi_all_above":
			var threshold: float = float(condition.get("threshold", 999))
			for kpi_name: String in state["kpis"]:
				if float(state["kpis"][kpi_name]["value"]) < threshold:
					return false
			return true
		"grade":
			if not is_game_end:
				return false
			return str(state.get("final_grade", "")) == str(condition.get("grade", ""))
		"grade_min":
			if not is_game_end:
				return false
			var grades := ["F", "D", "C", "B", "A", "S"]
			var required_idx: int = grades.find(str(condition.get("grade", "")))
			var actual_idx: int = grades.find(str(state.get("final_grade", "")))
			return actual_idx >= required_idx and actual_idx >= 0
		"scenario_count":
			var count: int = int(condition.get("count", 999))
			return state.get("scenarios_completed", {}).size() >= count
		"initiative_count":
			var count: int = int(condition.get("count", 999))
			return int(state.get("completed_initiative_count", 0)) >= count
		"shift_mastery":
			for shift_id: int in state.get("shifts", {}):
				if int(state["shifts"][shift_id].get("level", 0)) < 5:
					return false
			return state.get("shifts", {}).size() > 0
		"year_reached":
			var year: int = int(condition.get("year", 9999))
			return int(state.get("year", 0)) >= year
		"game_complete":
			return is_game_end
		"victory":
			return is_game_end and bool(state.get("game_won", false))

	return false


func _unlock(achievement: Dictionary) -> void:
	var aid: String = str(achievement.get("id", ""))
	_unlocked[aid] = int(Time.get_unix_time_from_system())
	_save_unlocked()
	achievement_unlocked.emit(achievement)


# -- Persistence ---------------------------------------------------------------

func _load_unlocked() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_unlocked = {}
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_unlocked = {}
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		_unlocked = json.data
	else:
		_unlocked = {}
	file.close()


func _save_unlocked() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_unlocked, "\t"))
		file.close()
