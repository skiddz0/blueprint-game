## Year Cycle Engine — Orchestrates the annual gameplay sequence.
## Connects timer signals to game state operations in the correct order.
## See: design/gdd/year-cycle-engine.md
extends Node

## Emitted before year-end processing with snapshot data for the summary screen.
signal year_end_data_ready(data: Dictionary)
## Emitted at mid-year (June) with KPI comparison data.
signal mid_year_review_ready(data: Dictionary)


func _ready() -> void:
	GameTimer.month_advanced.connect(_on_month_advanced)
	GameTimer.year_ended.connect(_on_year_ended)

	if DataLoader.is_loaded():
		AchievementSystem.initialize(DataLoader.get_achievements())
	else:
		DataLoader.data_loaded.connect(func():
			AchievementSystem.initialize(DataLoader.get_achievements()), CONNECT_ONE_SHOT)


func _on_month_advanced(_month: int) -> void:
	GameStateManager.advance_month()

	var year: int = GameStateManager.state["year"]
	var current_month: int = GameStateManager.state["month"]

	var scenario: Variant = ScenarioEngine.check_for_scenario(
		year, current_month,
		DataLoader.get_scenarios(),
		GameStateManager.state["scenarios_completed"]
	)
	if scenario != null:
		GameTimer.pause()
		GameStateManager.trigger_scenario(scenario)
		return

	var config: Dictionary = DataLoader.get_config()
	var mid_year: int = int(config.get("time", {}).get("mid_year_month", 6)) - 1
	if current_month == mid_year:
		GameStateManager.snapshot_mid_year_kpis()
		GameTimer.pause()
		mid_year_review_ready.emit({
			"year": year,
			"start_kpis": GameStateManager.state["start_of_year_kpis"].duplicate(true),
			"current_kpis": GameStateManager.state["kpis"].duplicate(true),
			"active_initiatives": GameStateManager.state["active_initiatives"].duplicate(true),
		})
		return

	var october: int = int(config.get("time", {}).get("october_month", 10)) - 1
	if current_month == october:
		GameStateManager.check_october_budget()


func _on_year_ended() -> void:
	GameTimer.pause()

	# Snapshot data BEFORE year-end processing
	var completed_year: int = GameStateManager.state["year"]
	var old_kpis: Dictionary = GameStateManager.state["kpis"].duplicate(true)
	var old_minister_id: String = str(GameStateManager.state["current_minister"].get("id", ""))
	var has_october_penalty: bool = GameStateManager.state["has_october_budget_penalty"]

	# Capture initiative results before they're cleared
	var initiative_results: Array = []
	var config: Dictionary = DataLoader.get_config()
	var init_config: Dictionary = config.get("initiatives", {})
	for active: Dictionary in GameStateManager.state["active_initiatives"]:
		var progress: float = float(active["progress_percent"])
		var status: String
		if progress >= float(init_config.get("completion_thresholds", {}).get("full", 100)):
			status = "completed"
		elif progress >= float(init_config.get("completion_thresholds", {}).get("partial", 50)):
			status = "partial"
		else:
			status = "failed"
		initiative_results.append({
			"name": str(active["name"]),
			"progress": progress,
			"status": status,
		})

	# Now process year-end (modifies state)
	GameStateManager.process_year_end()

	# Check if minister changed
	var new_minister_id: String = str(GameStateManager.state["current_minister"].get("id", ""))
	var minister_changed: bool = (new_minister_id != old_minister_id)
	var new_minister_name: String = str(GameStateManager.state["current_minister"].get("name", ""))

	# Check agenda
	var agenda_met := false
	var agenda_reward_pc := 0
	# Check history for agenda reward text
	for entry: String in GameStateManager.state["history"]:
		if "agenda" in entry.to_lower() or "minister" in entry.to_lower():
			if "met" in entry.to_lower() or "reward" in entry.to_lower():
				agenda_met = true
				var minister: Dictionary = GameStateManager.state["current_minister"]
				var agenda: Variant = minister.get("agenda")
				if agenda is Dictionary:
					agenda_reward_pc = int(agenda.get("reward_pc", 0))
				break

	# Emit data for HUD to show summary
	year_end_data_ready.emit({
		"completed_year": completed_year,
		"old_kpis": old_kpis,
		"new_kpis": GameStateManager.state["kpis"].duplicate(true),
		"initiative_results": initiative_results,
		"new_budget": GameStateManager.state["budget"],
		"has_october_penalty": has_october_penalty,
		"minister_changed": minister_changed,
		"new_minister_name": new_minister_name,
		"agenda_met": agenda_met,
		"agenda_reward_pc": agenda_reward_pc,
	})

	# Auto-save
	SaveLoadSystem.auto_save()

	# Check achievements
	var is_game_end: bool = GameStateManager.state.get("game_over", false)
	AchievementSystem.check_achievements(GameStateManager.state, is_game_end)


func start_new_year() -> void:
	GameStateManager.start_year()
	GameTimer.reset()
	GameTimer.start()


func resume_after_scenario() -> void:
	if GameStateManager.get_phase() == GameStateManager.Phase.RUNNING:
		GameTimer.resume()
