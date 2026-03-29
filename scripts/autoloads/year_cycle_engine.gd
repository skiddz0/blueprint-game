## Year Cycle Engine — Orchestrates the annual gameplay sequence.
## Connects timer signals to game state operations in the correct order.
## See: design/gdd/year-cycle-engine.md
extends Node


func _ready() -> void:
	GameTimer.month_advanced.connect(_on_month_advanced)
	GameTimer.year_ended.connect(_on_year_ended)


## Called each time a month boundary is crossed.
func _on_month_advanced(_month: int) -> void:
	# Advance game state month (updates initiative progress)
	GameStateManager.advance_month()

	var year: int = GameStateManager.state["year"]
	var current_month: int = GameStateManager.state["month"]

	# Check for scenario trigger
	var scenario: Variant = ScenarioEngine.check_for_scenario(
		year,
		current_month,
		DataLoader.get_scenarios(),
		GameStateManager.state["scenarios_completed"]
	)
	if scenario != null:
		GameTimer.pause()
		GameStateManager.trigger_scenario(scenario)
		return

	# Mid-year review (month 5 = June, config: mid_year_month = 6, but 0-indexed = 5)
	var config: Dictionary = DataLoader.get_config()
	var mid_year: int = int(config.get("time", {}).get("mid_year_month", 6)) - 1
	if current_month == mid_year:
		GameStateManager.snapshot_mid_year_kpis()

	# October budget check (month 9 = October, config: october_month = 10, 0-indexed = 9)
	var october: int = int(config.get("time", {}).get("october_month", 10)) - 1
	if current_month == october:
		GameStateManager.check_october_budget()


## Called when month 12 is reached (year boundary).
func _on_year_ended() -> void:
	GameTimer.pause()
	GameStateManager.process_year_end()

	# If game is not over, timer stays paused for PLANNING phase.
	# UI will call start_new_year() when player confirms initiative selection.


## Called by UI when player confirms initiative selection and is ready to start.
func start_new_year() -> void:
	GameStateManager.start_year()
	GameTimer.reset()
	GameTimer.start()


## Resume timer after a scenario is resolved.
func resume_after_scenario() -> void:
	if GameStateManager.get_phase() == GameStateManager.Phase.RUNNING:
		GameTimer.resume()
