## Save/Load System — File-based save with 3 manual slots + 1 auto-save.
## See: design/gdd/save-load-system.md
extends Node

signal save_completed(slot_id: int)
signal load_completed(slot_id: int)
signal save_failed(error: String)

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3  # slots 1-3 manual, slot 0 = auto-save
const AUTO_SLOT := 0


func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## Save the current game state to a slot (0=auto, 1-3=manual).
func save_game(slot_id: int, custom_name: String = "") -> bool:
	if slot_id < 0 or slot_id > MAX_SLOTS:
		save_failed.emit("Invalid slot: %d" % slot_id)
		return false

	var state: Dictionary = GameStateManager.state
	var avg_kpi: float = KPISystem.calculate_average(state["kpis"])

	var save_data := {
		"slot_id": slot_id,
		"name": custom_name if custom_name != "" else ("Auto Save" if slot_id == 0 else "Save %d" % slot_id),
		"timestamp": int(Time.get_unix_time_from_system()),
		"year": state["year"],
		"month": state["month"],
		"avg_kpi": avg_kpi,
		"phase": GameStateManager.get_phase_name(),
		"game_state": state.duplicate(true),
	}

	var path := _slot_path(slot_id)
	var json_str := JSON.stringify(save_data, "\t")

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err := "Cannot write: %s (error %d)" % [path, FileAccess.get_open_error()]
		push_error("SaveLoad: " + err)
		save_failed.emit(err)
		return false

	file.store_string(json_str)
	file.close()
	save_completed.emit(slot_id)
	return true


## Load game state from a slot. Returns true on success.
func load_game(slot_id: int) -> bool:
	var save_data := _read_slot(slot_id)
	if save_data.is_empty():
		return false

	var game_state: Variant = save_data.get("game_state")
	if not (game_state is Dictionary):
		push_error("SaveLoad: Invalid game_state in slot %d" % slot_id)
		return false

	# Restore state
	GameStateManager.state = game_state.duplicate(true)

	# Determine phase to restore
	var phase_name: String = str(save_data.get("phase", "PLANNING"))
	match phase_name:
		"PLANNING":
			GameStateManager.current_phase = GameStateManager.Phase.PLANNING
		"RUNNING":
			GameStateManager.current_phase = GameStateManager.Phase.RUNNING
		"SCENARIO":
			GameStateManager.current_phase = GameStateManager.Phase.SCENARIO
		"PAUSED":
			GameStateManager.current_phase = GameStateManager.Phase.PAUSED
		_:
			GameStateManager.current_phase = GameStateManager.Phase.PLANNING

	GameStateManager.phase_changed.emit(GameStateManager.get_phase_name())
	GameStateManager.game_initialized.emit()

	GameTimer.reset()
	if GameStateManager.current_phase == GameStateManager.Phase.RUNNING:
		GameTimer.start()

	load_completed.emit(slot_id)
	return true


## Auto-save (called at year-end by YearCycleEngine).
func auto_save() -> void:
	save_game(AUTO_SLOT, "Auto Save")


## Delete a save slot.
func delete_save(slot_id: int) -> bool:
	var path := _slot_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return true
	return false


## Get metadata for all save slots. Returns Array of Dictionary (or null per slot).
func get_save_slots() -> Array:
	var slots: Array = []
	for i in range(MAX_SLOTS + 1):  # 0, 1, 2, 3
		var data := _read_slot(i)
		if data.is_empty():
			slots.append(null)
		else:
			slots.append({
				"slot_id": data.get("slot_id", i),
				"name": data.get("name", ""),
				"timestamp": data.get("timestamp", 0),
				"year": data.get("year", 0),
				"month": data.get("month", 0),
				"avg_kpi": data.get("avg_kpi", 0.0),
				"phase": data.get("phase", ""),
			})
	return slots


## Check if any save exists.
func has_any_save() -> bool:
	for i in range(MAX_SLOTS + 1):
		if FileAccess.file_exists(_slot_path(i)):
			return true
	return false


## Get auto-save metadata (or null).
func get_auto_save() -> Variant:
	var slots := get_save_slots()
	return slots[AUTO_SLOT]


# -- Internal ------------------------------------------------------------------

func _slot_path(slot_id: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot_id


func _read_slot(slot_id: int) -> Dictionary:
	var path := _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("SaveLoad: Parse error in %s: %s" % [path, json.get_error_message()])
		return {}

	if json.data is Dictionary:
		return json.data
	return {}
