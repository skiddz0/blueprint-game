## Year Cycle Engine — Orchestrates the annual gameplay sequence.
## Connects timer signals to game state operations in the correct order.
## See: design/gdd/year-cycle-engine.md
extends Node


func _ready() -> void:
	GameTimer.month_advanced.connect(_on_month_advanced)
	GameTimer.year_ended.connect(_on_year_ended)

	# Initialize achievements when data is ready
	if DataLoader.is_loaded():
		AchievementSystem.initialize(DataLoader.get_achievements())
	else:
		DataLoader.data_loaded.connect(func():
			AchievementSystem.initialize(DataLoader.get_achievements()), CONNECT_ONE_SHOT)


## Called each time a month boundary is crossed.
func _on_month_advanced(_month: int) -> void:
	GameStateManager.advance_month()

	var year: int = GameStateManager.state["year"]
	var current_month: int = GameStateManager.state["month"]

	# Check for scenario trigger
	var scenario: Variant = ScenarioEngine.check_for_scenario(
		year, current_month,
		DataLoader.get_scenarios(),
		GameStateManager.state["scenarios_completed"]
	)
	if scenario != null:
		GameTimer.pause()
		GameStateManager.trigger_scenario(scenario)
		return

	# Mid-year review
	var config: Dictionary = DataLoader.get_config()
	var mid_year: int = int(config.get("time", {}).get("mid_year_month", 6)) - 1
	if current_month == mid_year:
		GameStateManager.snapshot_mid_year_kpis()

	# October budget check
	var october: int = int(config.get("time", {}).get("october_month", 10)) - 1
	if current_month == october:
		GameStateManager.check_october_budget()


## Called when month 12 is reached (year boundary).
func _on_year_ended() -> void:
	GameTimer.pause()
	GameStateManager.process_year_end()

	# Auto-save at year-end
	SaveLoadSystem.auto_save()

	# Check achievements at year-end
	var is_game_end: bool = GameStateManager.state.get("game_over", false)
	AchievementSystem.check_achievements(GameStateManager.state, is_game_end)


## Called by UI when player confirms initiative selection and is ready to start.
func start_new_year() -> void:
	GameStateManager.start_year()
	GameTimer.reset()
	GameTimer.start()


## Resume timer after a scenario is resolved.
func resume_after_scenario() -> void:
	if GameStateManager.get_phase() == GameStateManager.Phase.RUNNING:
		GameTimer.resume()
