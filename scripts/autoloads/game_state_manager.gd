## Game State Manager — Central state machine and game state owner.
## All mutable game state lives here. Other systems request changes via methods.
## See: design/gdd/game-state-manager.md
extends Node

# -- Signals -------------------------------------------------------------------

signal game_initialized
signal phase_changed(new_phase: String)
signal year_started(year: int)
signal month_advanced(year: int, month: int)
signal scenario_triggered(scenario: Dictionary)
signal scenario_resolved(scenario_id: String, choice_id: String)
signal october_checked(has_penalty: bool)
signal year_ended(year: int)
signal kpi_changed(kpi_name: String, old_value: float, new_value: float)
signal budget_changed(old_value: float, new_value: float)
signal pc_changed(old_value: int, new_value: int)
signal initiative_toggled(initiative_id: String, selected: bool)
signal history_updated(entry: String)
signal game_over(won: bool, grade: String)
signal game_restarted

# -- Constants -----------------------------------------------------------------

enum Phase { UNINITIALIZED, PLANNING, RUNNING, SCENARIO, YEAR_END, GAME_OVER, PAUSED }

# -- State ---------------------------------------------------------------------

var state: Dictionary = {}
var current_phase: Phase = Phase.UNINITIALIZED
var _pre_pause_phase: Phase = Phase.RUNNING


# -- Initialization ------------------------------------------------------------

func initialize_game() -> void:
	var config: Dictionary = DataLoader.get_config()
	var initiatives_data: Array = DataLoader.get_initiatives()
	var shifts_data: Array = DataLoader.get_shifts()

	var kpis := KPISystem.create_initial_kpis(config)

	var shifts := {}
	for shift_data: Dictionary in shifts_data:
		var sid: int = int(shift_data.get("id", 0))
		if sid > 0:
			shifts[sid] = shift_data.duplicate(true)

	var minister: Variant = DataLoader.get_minister_by_year(2013)
	if minister == null:
		minister = {}

	var initiatives: Array = []
	for init: Dictionary in initiatives_data:
		var entry := init.duplicate(true)
		entry["selected"] = false
		entry["is_purchased"] = false
		initiatives.append(entry)

	state = {
		"year": 2013,
		"month": 0,
		"current_wave": 1,
		"budget": float(config.get("resources", {}).get("starting_budget", 100)),
		"total_budget": float(config.get("resources", {}).get("starting_budget", 100)),
		"political_capital": int(config.get("resources", {}).get("starting_pc", 50)),
		"kpis": kpis,
		"start_of_year_kpis": kpis.duplicate(true),
		"mid_year_kpis": kpis.duplicate(true),
		"initiatives": initiatives,
		"active_initiatives": [],
		"shifts": shifts,
		"current_minister": minister.duplicate(true) if minister is Dictionary else {},
		"current_scenario": {},
		"scenarios_completed": {},
		"show_mid_year_review": false,
		"has_october_budget_penalty": false,
		"october_unspent_budget": 0.0,
		"history": [],
		"completed_initiative_count": 0,
		"game_over": false,
		"game_won": false,
		"final_grade": "",
	}

	_set_phase(Phase.PLANNING)
	game_initialized.emit()


# -- Phase management ----------------------------------------------------------

func get_phase() -> Phase:
	return current_phase


func get_phase_name() -> String:
	match current_phase:
		Phase.UNINITIALIZED: return "UNINITIALIZED"
		Phase.PLANNING: return "PLANNING"
		Phase.RUNNING: return "RUNNING"
		Phase.SCENARIO: return "SCENARIO"
		Phase.YEAR_END: return "YEAR_END"
		Phase.GAME_OVER: return "GAME_OVER"
		Phase.PAUSED: return "PAUSED"
	return "UNKNOWN"


func _set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	phase_changed.emit(get_phase_name())


# -- State mutation methods ----------------------------------------------------

func apply_kpi_change(kpi_name: String, delta: float) -> void:
	if not state["kpis"].has(kpi_name):
		return
	var old_value: float = float(state["kpis"][kpi_name]["value"])
	var new_value: float = KPISystem.clamp_kpi(old_value + delta)
	state["kpis"][kpi_name]["value"] = new_value
	if absf(old_value - new_value) > 0.001:
		kpi_changed.emit(kpi_name, old_value, new_value)


func apply_budget_change(delta: float) -> void:
	var old_value: float = state["budget"]
	state["budget"] = maxf(0.0, old_value + delta)
	if absf(old_value - state["budget"]) > 0.001:
		budget_changed.emit(old_value, state["budget"])


func set_budget(value: float) -> void:
	var old_value: float = state["budget"]
	state["budget"] = maxf(0.0, value)
	if absf(old_value - state["budget"]) > 0.001:
		budget_changed.emit(old_value, state["budget"])


func apply_pc_change(delta: int) -> void:
	var max_pc: int = int(DataLoader.get_config().get("resources", {}).get("max_pc", 100))
	var old_value: int = state["political_capital"]
	# No PC cap in year 1 (2013) — let new players accumulate freely
	if state["year"] <= 2013:
		state["political_capital"] = maxi(0, old_value + delta)
	else:
		state["political_capital"] = clampi(old_value + delta, 0, max_pc)
	if old_value != state["political_capital"]:
		pc_changed.emit(old_value, state["political_capital"])


func add_history_entry(text: String) -> void:
	state["history"].push_front(text)
	if state["history"].size() > 20:
		state["history"].resize(20)
	history_updated.emit(text)


# -- Initiative selection (PLANNING phase) -------------------------------------

func toggle_initiative(initiative_id: String) -> bool:
	if current_phase != Phase.PLANNING:
		return false

	var config: Dictionary = DataLoader.get_config()
	var minister: Dictionary = state["current_minister"]

	for init: Dictionary in state["initiatives"]:
		if init["id"] != initiative_id:
			continue

		if init["selected"]:
			init["selected"] = false
			initiative_toggled.emit(initiative_id, false)
			return true

		if int(init.get("unlock_year", 9999)) > state["year"]:
			return false

		var discount: float = ResourceSystem.get_minister_discount(
			minister.get("cost_modifiers"),
			str(init.get("category", ""))
		)
		var efficiency_kpi: float = float(state["kpis"]["efficiency"]["value"])
		var adjusted_cost: float = ResourceSystem.calculate_initiative_cost(
			float(init["cost_rm"]), efficiency_kpi, discount, config
		)
		var pc_cost: int = int(init.get("cost_pc", 0))

		var committed_rm := 0.0
		var committed_pc := 0
		for other: Dictionary in state["initiatives"]:
			if other["selected"] and other["id"] != initiative_id:
				var other_discount: float = ResourceSystem.get_minister_discount(
					minister.get("cost_modifiers"),
					str(other.get("category", ""))
				)
				committed_rm += ResourceSystem.calculate_initiative_cost(
					float(other["cost_rm"]), efficiency_kpi, other_discount, config
				)
				committed_pc += int(other.get("cost_pc", 0))

		if committed_rm + adjusted_cost > state["budget"]:
			return false
		if committed_pc + pc_cost > state["political_capital"]:
			return false

		init["selected"] = true
		initiative_toggled.emit(initiative_id, true)
		return true

	return false


func get_selected_initiatives() -> Array:
	var selected: Array = []
	for init: Dictionary in state["initiatives"]:
		if init["selected"]:
			selected.append(init)
	return selected


# -- Year lifecycle ------------------------------------------------------------

func start_year() -> void:
	if current_phase != Phase.PLANNING:
		return

	var config: Dictionary = DataLoader.get_config()
	var minister: Dictionary = state["current_minister"]
	var efficiency_kpi: float = float(state["kpis"]["efficiency"]["value"])
	var bureaucracy_penalty: float = ResourceSystem.get_bureaucracy_penalty(state["year"], config)

	var initiatives_started := 0

	for init: Dictionary in state["initiatives"]:
		if not init["selected"]:
			continue

		var discount: float = ResourceSystem.get_minister_discount(
			minister.get("cost_modifiers"),
			str(init.get("category", ""))
		)
		var adjusted_cost: float = ResourceSystem.calculate_initiative_cost(
			float(init["cost_rm"]), efficiency_kpi, discount, config
		)

		apply_budget_change(-adjusted_cost)
		apply_pc_change(-int(init.get("cost_pc", 0)))

		var shift_id: int = int(init.get("shift", 0))
		var shift_xp: int = int(init.get("shift_xp", 0))
		if shift_id > 0 and state["shifts"].has(shift_id):
			_award_shift_xp(shift_id, shift_xp)

		var active := {
			"initiative_id": str(init["id"]),
			"name": str(init["name"]),
			"start_month": 0,
			"duration": int(init["duration_months"]),
			"progress_percent": 0.0,
			"crisis_delay_months": 0.0,
			"is_complete": false,
			"effects": init.get("effects", {}).duplicate(true),
		}
		state["active_initiatives"].append(active)

		init["is_purchased"] = true
		init["selected"] = false
		initiatives_started += 1

	if initiatives_started > 0:
		var total_penalty: float = initiatives_started * bureaucracy_penalty
		apply_kpi_change("efficiency", total_penalty)

	# Apply minister bonuses
	var bonuses: Variant = minister.get("bonuses")
	if bonuses is Dictionary:
		for kpi_name: String in bonuses:
			apply_kpi_change(kpi_name, float(bonuses[kpi_name]))

	# Apply shift level bonuses
	for shift_id: int in state["shifts"]:
		var shift: Dictionary = state["shifts"][shift_id]
		var level: int = int(shift.get("level", 0))
		if level > 0:
			var target_kpi: String = str(shift.get("targetKpi", ""))
			if target_kpi != "" and state["kpis"].has(target_kpi):
				apply_kpi_change(target_kpi, float(level))

	state["start_of_year_kpis"] = state["kpis"].duplicate(true)
	state["has_october_budget_penalty"] = false

	_set_phase(Phase.RUNNING)
	year_started.emit(state["year"])


func advance_month() -> void:
	if current_phase != Phase.RUNNING:
		return

	state["month"] += 1

	for active: Dictionary in state["active_initiatives"]:
		if active["is_complete"]:
			continue
		var effective_duration: float = float(active["duration"]) + float(active["crisis_delay_months"])
		if effective_duration <= 0.0:
			effective_duration = 1.0
		var increment: float = 100.0 / effective_duration
		active["progress_percent"] = minf(100.0, float(active["progress_percent"]) + increment)
		if active["progress_percent"] >= 100.0:
			active["is_complete"] = true

	month_advanced.emit(state["year"], state["month"])


func trigger_scenario(scenario: Dictionary) -> void:
	state["current_scenario"] = scenario.duplicate(true)
	_set_phase(Phase.SCENARIO)
	scenario_triggered.emit(scenario)


func resolve_scenario(choice_id: String) -> void:
	if current_phase != Phase.SCENARIO:
		return

	var scenario: Dictionary = state["current_scenario"]
	if scenario.is_empty():
		return

	var scenario_id: String = str(scenario.get("id", ""))

	var chosen: Dictionary = {}
	for choice: Dictionary in scenario.get("choices", []):
		if str(choice.get("id", "")) == choice_id:
			chosen = choice
			break

	if chosen.is_empty():
		return

	var costs: Dictionary = chosen.get("costs", {})
	var budget_cost: float = float(costs.get("budget", 0))
	var pc_cost: int = int(costs.get("pc", 0))
	if budget_cost > 0.0:
		apply_budget_change(-budget_cost)
	if pc_cost > 0:
		apply_pc_change(-pc_cost)

	var effects: Variant = chosen.get("effects")
	if effects is Dictionary:
		for kpi_name: String in effects:
			apply_kpi_change(kpi_name, float(effects[kpi_name]))

	var special: Variant = chosen.get("special_effects")
	if special is Dictionary:
		if special.has("initiatives_delayed_months"):
			var delay: float = float(special["initiatives_delayed_months"])
			for active: Dictionary in state["active_initiatives"]:
				active["crisis_delay_months"] = float(active["crisis_delay_months"]) + delay

	state["scenarios_completed"][scenario_id] = choice_id
	add_history_entry(str(scenario.get("name", "")) + ": " + str(chosen.get("outcome_text", "")))

	state["current_scenario"] = {}
	_set_phase(Phase.RUNNING)
	scenario_resolved.emit(scenario_id, choice_id)


func apply_cannot_afford_penalty(scenario: Dictionary) -> void:
	var scenario_id: String = str(scenario.get("id", ""))
	var penalty: Dictionary = scenario.get("cannot_afford_penalty", {})

	var kpi_map := {
		"unity_kpi": "unity", "quality_kpi": "quality", "equity_kpi": "equity",
		"access_kpi": "access", "efficiency_kpi": "efficiency",
	}
	for penalty_key: String in kpi_map:
		if penalty.has(penalty_key):
			apply_kpi_change(kpi_map[penalty_key], float(penalty[penalty_key]))

	state["scenarios_completed"][scenario_id] = "cannot_afford"
	add_history_entry(str(scenario.get("name", "")) + ": " + str(penalty.get("outcome_text", "")))

	state["current_scenario"] = {}
	_set_phase(Phase.RUNNING)
	scenario_resolved.emit(scenario_id, "cannot_afford")


func snapshot_mid_year_kpis() -> void:
	state["mid_year_kpis"] = state["kpis"].duplicate(true)
	state["show_mid_year_review"] = true


func check_october_budget() -> void:
	var config: Dictionary = DataLoader.get_config()
	var threshold: float = float(config.get("resources", {}).get("october_unspent_threshold", 10))
	if state["budget"] > threshold:
		state["has_october_budget_penalty"] = true
		state["october_unspent_budget"] = state["budget"]
		add_history_entry("October: RM %.1fM unspent — next year budget will be penalized!" % state["budget"])
	october_checked.emit(state["has_october_budget_penalty"])


func process_year_end() -> void:
	var config: Dictionary = DataLoader.get_config()
	var init_config: Dictionary = config.get("initiatives", {})

	_set_phase(Phase.YEAR_END)

	# -- Process initiative completion --
	var completed_this_year := 0
	for active: Dictionary in state["active_initiatives"]:
		var progress: float = float(active["progress_percent"])
		var full_threshold: float = float(init_config.get("completion_thresholds", {}).get("full", 100))
		var partial_threshold: float = float(init_config.get("completion_thresholds", {}).get("partial", 50))

		if progress >= full_threshold:
			var effects: Variant = active.get("effects")
			if effects is Dictionary:
				for kpi_name: String in effects:
					apply_kpi_change(kpi_name, float(effects[kpi_name]))
			completed_this_year += 1
			add_history_entry("Completed: " + str(active["name"]))
		elif progress >= partial_threshold:
			var multiplier: float = float(init_config.get("partial_effects_multiplier", 0.5))
			var effects: Variant = active.get("effects")
			if effects is Dictionary:
				for kpi_name: String in effects:
					apply_kpi_change(kpi_name, float(effects[kpi_name]) * multiplier)
			apply_kpi_change("unity", float(init_config.get("partial_unity_penalty", -2)))
			add_history_entry("Partial: " + str(active["name"]))
		else:
			apply_pc_change(int(init_config.get("failed_pc_penalty", -5)))
			apply_kpi_change("unity", float(init_config.get("failed_unity_penalty", -3)))
			add_history_entry("Failed: " + str(active["name"]))

	state["completed_initiative_count"] += completed_this_year
	state["active_initiatives"].clear()

	# -- KPI decay --
	var decay_deltas := KPISystem.get_decay_deltas(config)
	for kpi_name: String in decay_deltas:
		apply_kpi_change(kpi_name, decay_deltas[kpi_name])

	# -- Stagnation penalty --
	var stagnation := KPISystem.get_stagnation_deltas(
		state["kpis"], state["start_of_year_kpis"], config, state["year"]
	)
	for kpi_name: String in stagnation:
		apply_kpi_change(kpi_name, stagnation[kpi_name])

	# -- PC regeneration --
	var unity_val: float = float(state["kpis"]["unity"]["value"])
	var pc_regen: int = ResourceSystem.calculate_pc_regen(unity_val)
	if pc_regen > 0:
		apply_pc_change(pc_regen)

	# -- Minister agenda check --
	var minister: Dictionary = state["current_minister"]
	var agenda: Variant = minister.get("agenda")
	if agenda is Dictionary:
		var target_kpi_name: Variant = agenda.get("kpi")
		if target_kpi_name != null:
			var target_kpi: String = str(target_kpi_name)
			var target_val: float = float(agenda.get("target", 999))
			if state["kpis"].has(target_kpi) and float(state["kpis"][target_kpi]["value"]) >= target_val:
				apply_pc_change(int(agenda.get("reward_pc", 0)))
				add_history_entry(str(agenda.get("reward_text", "Minister agenda met!")))

	# -- Advance year --
	var old_year: int = state["year"]
	state["year"] += 1
	state["month"] = 0

	state["current_wave"] = ResourceSystem.get_wave(state["year"])
	var avg_kpi: float = KPISystem.calculate_average(state["kpis"])
	var new_budget: float = ResourceSystem.calculate_next_year_budget(
		state["current_wave"], avg_kpi, state["has_october_budget_penalty"], config
	)
	set_budget(new_budget)
	state["total_budget"] = new_budget

	# -- Minister transition check --
	var new_minister: Variant = DataLoader.get_minister_by_year(state["year"])
	if new_minister != null and new_minister is Dictionary:
		var new_id: String = str(new_minister.get("id", ""))
		var old_id: String = str(minister.get("id", ""))
		if new_id != old_id:
			add_history_entry("New Minister: " + str(new_minister.get("name", "")))
			state["current_minister"] = new_minister.duplicate(true)

	# -- Reset initiatives for new year --
	for init: Dictionary in state["initiatives"]:
		init["selected"] = false
		init["is_purchased"] = false

	add_history_entry("--- Year %d Complete ---" % old_year)
	year_ended.emit(old_year)

	# -- Check game over --
	if state["year"] > 2025:
		state["game_over"] = true
		var final_avg: float = KPISystem.calculate_average(state["kpis"])
		state["final_grade"] = GradingSystem.calculate_grade(final_avg, config)
		state["game_won"] = final_avg >= float(config.get("kpis", {}).get("victory_threshold", 65))
		_set_phase(Phase.GAME_OVER)
		game_over.emit(state["game_won"], state["final_grade"])
	else:
		_set_phase(Phase.PLANNING)


func restart_game() -> void:
	initialize_game()
	game_restarted.emit()


# -- Pause/resume --------------------------------------------------------------

func pause_game() -> void:
	if current_phase == Phase.RUNNING:
		_pre_pause_phase = Phase.RUNNING
		_set_phase(Phase.PAUSED)


func resume_game() -> void:
	if current_phase == Phase.PAUSED:
		_set_phase(_pre_pause_phase)


# -- Internal ------------------------------------------------------------------

func _award_shift_xp(shift_id: int, xp_amount: int) -> void:
	if not state["shifts"].has(shift_id):
		return
	var shift: Dictionary = state["shifts"][shift_id]
	var config: Dictionary = DataLoader.get_config()
	var max_level: int = int(config.get("shifts", {}).get("max_level", 5))
	var xp_per_level: Array = config.get("shifts", {}).get("xp_per_level", [3, 3, 4, 4, 5])

	var level: int = int(shift.get("level", 0))
	if level >= max_level:
		return

	shift["xp"] = int(shift.get("xp", 0)) + xp_amount

	while int(shift["xp"]) >= int(shift.get("nextLevelXp", 3)) and int(shift["level"]) < max_level:
		shift["xp"] = int(shift["xp"]) - int(shift["nextLevelXp"])
		shift["level"] = int(shift["level"]) + 1
		if int(shift["level"]) < max_level and int(shift["level"]) < xp_per_level.size():
			shift["nextLevelXp"] = xp_per_level[int(shift["level"])]
