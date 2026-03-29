## HUD — Main game dashboard. Displays all game state reactively via signals.
## See: design/gdd/hud-dashboard.md
extends Control

const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

# -- Node references -----------------------------------------------------------

@onready var year_label: Label = %YearLabel
@onready var month_label: Label = %MonthLabel
@onready var wave_label: Label = %WaveLabel
@onready var budget_label: Label = %BudgetLabel
@onready var pc_label: Label = %PCLabel
@onready var timer_label: Label = %TimerLabel
@onready var phase_label: Label = %PhaseLabel

@onready var kpi_quality_bar: ProgressBar = %QualityBar
@onready var kpi_equity_bar: ProgressBar = %EquityBar
@onready var kpi_access_bar: ProgressBar = %AccessBar
@onready var kpi_unity_bar: ProgressBar = %UnityBar
@onready var kpi_efficiency_bar: ProgressBar = %EfficiencyBar
@onready var kpi_quality_value: Label = %QualityValue
@onready var kpi_equity_value: Label = %EquityValue
@onready var kpi_access_value: Label = %AccessValue
@onready var kpi_unity_value: Label = %UnityValue
@onready var kpi_efficiency_value: Label = %EfficiencyValue

@onready var minister_name_label: Label = %MinisterNameLabel
@onready var minister_nickname_label: Label = %MinisterNicknameLabel
@onready var minister_agenda_label: Label = %MinisterAgendaLabel

@onready var initiatives_container: VBoxContainer = %InitiativesContainer
@onready var shifts_container: GridContainer = %ShiftsContainer
@onready var events_container: VBoxContainer = %EventsContainer

@onready var select_initiatives_btn: Button = %SelectInitiativesBtn
@onready var pause_btn: Button = %PauseBtn
@onready var speed_btn: Button = %SpeedBtn

@onready var initiative_selector: Control = %InitiativeSelector
@onready var scenario_modal: Control = %ScenarioModal
@onready var game_over_screen: Control = %GameOverScreen

var _kpi_bars: Dictionary = {}
var _kpi_labels: Dictionary = {}


func _ready() -> void:
	# Connect signals
	GameStateManager.game_initialized.connect(_on_game_initialized)
	GameStateManager.phase_changed.connect(_on_phase_changed)
	GameStateManager.year_started.connect(_on_year_started)
	GameStateManager.month_advanced.connect(_on_month_advanced)
	GameStateManager.kpi_changed.connect(_on_kpi_changed)
	GameStateManager.budget_changed.connect(_on_budget_changed)
	GameStateManager.pc_changed.connect(_on_pc_changed)
	GameStateManager.history_updated.connect(_on_history_updated)
	GameStateManager.scenario_triggered.connect(_on_scenario_triggered)
	GameStateManager.scenario_resolved.connect(_on_scenario_resolved)
	GameStateManager.game_over.connect(_on_game_over)
	GameTimer.timer_paused.connect(func(): pause_btn.text = "▶ Resume")
	GameTimer.timer_resumed.connect(func(): pause_btn.text = "⏸ Pause")
	GameTimer.speed_changed.connect(func(s: float): speed_btn.text = "⚡%.1fx" % s)

	select_initiatives_btn.pressed.connect(_on_select_initiatives_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	speed_btn.pressed.connect(_on_speed_pressed)

	_kpi_bars = {
		"quality": kpi_quality_bar, "equity": kpi_equity_bar,
		"access": kpi_access_bar, "unity": kpi_unity_bar,
		"efficiency": kpi_efficiency_bar
	}
	_kpi_labels = {
		"quality": kpi_quality_value, "equity": kpi_equity_value,
		"access": kpi_access_value, "unity": kpi_unity_value,
		"efficiency": kpi_efficiency_value
	}

	_apply_styling()

	initiative_selector.visible = false
	scenario_modal.visible = false
	game_over_screen.visible = false

	# Initialize game
	if DataLoader.is_loaded():
		GameStateManager.initialize_game()
	else:
		DataLoader.data_loaded.connect(func(): GameStateManager.initialize_game(), CONNECT_ONE_SHOT)


func _process(_delta: float) -> void:
	if GameTimer.is_running():
		var remaining := GameTimer.get_time_remaining_in_year()
		timer_label.text = "%d:%02d" % [remaining["minutes"], remaining["seconds"]]


# -- Styling -------------------------------------------------------------------

func _apply_styling() -> void:
	# Header
	year_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	year_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	month_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	month_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	wave_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	wave_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_BLUE)
	budget_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	budget_label.add_theme_color_override("font_color", ThemeConfig.BUDGET_COLOR)
	pc_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	pc_label.add_theme_color_override("font_color", ThemeConfig.PC_COLOR)
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	phase_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	phase_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_BLUE)

	# Minister
	minister_name_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	minister_name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	minister_nickname_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	minister_nickname_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	minister_agenda_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	minister_agenda_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)

	# Buttons
	ThemeConfig.style_button(select_initiatives_btn, ThemeConfig.BTN_PRIMARY, ThemeConfig.BTN_PRIMARY_HOVER)
	ThemeConfig.style_button(pause_btn)
	ThemeConfig.style_button(speed_btn)

	# KPI bars
	for kpi_name: String in _kpi_bars:
		var bar: ProgressBar = _kpi_bars[kpi_name]
		bar.custom_minimum_size.y = 18
		ThemeConfig.style_progress_bar(bar, ThemeConfig.KPI_GREEN)


# -- Signal handlers -----------------------------------------------------------

func _on_game_initialized() -> void:
	_refresh_all()


func _on_phase_changed(new_phase: String) -> void:
	phase_label.text = new_phase
	select_initiatives_btn.visible = (new_phase == "PLANNING")
	var show_controls := (new_phase == "RUNNING" or new_phase == "PAUSED")
	pause_btn.visible = show_controls
	speed_btn.visible = show_controls


func _on_year_started(_year: int) -> void:
	_refresh_all()


func _on_month_advanced(_year: int, month: int) -> void:
	month_label.text = MONTH_NAMES[mini(month, 11)]
	_refresh_active_initiatives()


func _on_kpi_changed(kpi_name: String, _old_value: float, new_value: float) -> void:
	_update_kpi_display(kpi_name, new_value)


func _on_budget_changed(_old_value: float, new_value: float) -> void:
	budget_label.text = "RM %.1fM" % new_value


func _on_pc_changed(_old_value: int, new_value: int) -> void:
	pc_label.text = "PC: %d" % new_value


func _on_history_updated(_entry: String) -> void:
	_refresh_events()


func _on_scenario_triggered(scenario: Dictionary) -> void:
	scenario_modal.show_scenario(scenario)
	scenario_modal.visible = true


func _on_scenario_resolved(_scenario_id: String, _choice_id: String) -> void:
	scenario_modal.visible = false
	YearCycleEngine.resume_after_scenario()


func _on_game_over(won: bool, grade: String) -> void:
	game_over_screen.show_results(won, grade)
	game_over_screen.visible = true


# -- Button handlers -----------------------------------------------------------

func _on_select_initiatives_pressed() -> void:
	initiative_selector.open_selector()
	initiative_selector.visible = true


func _on_pause_pressed() -> void:
	var phase := GameStateManager.get_phase()
	if phase == GameStateManager.Phase.RUNNING:
		GameTimer.pause()
		GameStateManager.pause_game()
	elif phase == GameStateManager.Phase.PAUSED:
		GameStateManager.resume_game()
		GameTimer.resume()


func _on_speed_pressed() -> void:
	var current: float = GameTimer.get_speed()
	if current < 1.5:
		GameTimer.set_speed(1.5)
	elif current < 2.0:
		GameTimer.set_speed(2.0)
	else:
		GameTimer.set_speed(1.0)


# -- Refresh helpers -----------------------------------------------------------

func _refresh_all() -> void:
	var s: Dictionary = GameStateManager.state
	year_label.text = "Year: %d" % s["year"]
	month_label.text = MONTH_NAMES[mini(int(s["month"]), 11)]
	wave_label.text = "Wave %d" % s["current_wave"]
	budget_label.text = "RM %.1fM" % s["budget"]
	pc_label.text = "PC: %d" % s["political_capital"]
	phase_label.text = GameStateManager.get_phase_name()

	for kpi_name: String in s["kpis"]:
		_update_kpi_display(kpi_name, float(s["kpis"][kpi_name]["value"]))

	var minister: Dictionary = s.get("current_minister", {})
	minister_name_label.text = str(minister.get("name", "No Minister"))
	minister_nickname_label.text = "\"%s\"" % str(minister.get("nickname", ""))
	var agenda: Variant = minister.get("agenda")
	if agenda is Dictionary:
		var target: String = str(agenda.get("kpi", "")).capitalize()
		var threshold: int = int(agenda.get("target", 0))
		minister_agenda_label.text = "Goal: %s >= %d" % [target, threshold]
	else:
		minister_agenda_label.text = ""

	_refresh_active_initiatives()
	_refresh_shifts()
	_refresh_events()

	select_initiatives_btn.visible = (GameStateManager.get_phase() == GameStateManager.Phase.PLANNING)
	var show_controls := (GameStateManager.get_phase() == GameStateManager.Phase.RUNNING
		or GameStateManager.get_phase() == GameStateManager.Phase.PAUSED)
	pause_btn.visible = show_controls
	speed_btn.visible = show_controls


func _update_kpi_display(kpi_name: String, value: float) -> void:
	if not _kpi_bars.has(kpi_name):
		return
	var bar: ProgressBar = _kpi_bars[kpi_name]
	var label: Label = _kpi_labels[kpi_name]
	bar.value = value
	label.text = "%d" % int(value)
	var color := ThemeConfig.get_kpi_color(value)
	ThemeConfig.style_progress_bar(bar, color)
	label.add_theme_color_override("font_color", color)


func _refresh_active_initiatives() -> void:
	for child: Node in initiatives_container.get_children():
		child.queue_free()

	var actives: Array = GameStateManager.state.get("active_initiatives", [])
	if actives.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active initiatives — select some above!"
		empty_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		empty_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		initiatives_container.add_child(empty_label)
		return

	for active: Dictionary in actives:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(ThemeConfig.BG_CARD, 3, 4))
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		panel.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(active.get("name", ""))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
		hbox.add_child(name_label)

		var progress: float = float(active.get("progress_percent", 0))
		var prog_bar := ProgressBar.new()
		prog_bar.min_value = 0
		prog_bar.max_value = 100
		prog_bar.value = progress
		prog_bar.custom_minimum_size = Vector2(100, 14)
		prog_bar.show_percentage = false
		var prog_color: Color
		if progress >= 100.0:
			prog_color = ThemeConfig.KPI_GREEN
		elif progress >= 50.0:
			prog_color = ThemeConfig.ACCENT_BLUE
		else:
			prog_color = ThemeConfig.KPI_ORANGE
		ThemeConfig.style_progress_bar(prog_bar, prog_color)
		hbox.add_child(prog_bar)

		var pct_label := Label.new()
		pct_label.text = "%d%%" % int(progress)
		pct_label.custom_minimum_size.x = 36
		pct_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		pct_label.add_theme_color_override("font_color", prog_color)
		hbox.add_child(pct_label)

		initiatives_container.add_child(panel)


func _refresh_shifts() -> void:
	for child: Node in shifts_container.get_children():
		child.queue_free()

	var shifts: Dictionary = GameStateManager.state.get("shifts", {})
	for shift_id: int in shifts:
		var shift: Dictionary = shifts[shift_id]
		var level: int = int(shift.get("level", 0))
		var xp: int = int(shift.get("xp", 0))
		var next_xp: int = int(shift.get("nextLevelXp", 3))
		var target_kpi: String = str(shift.get("targetKpi", ""))
		var max_level := 5

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 70)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bg_color := ThemeConfig.BG_CARD
		if level >= max_level:
			bg_color = ThemeConfig.ACCENT_GOLD.darkened(0.75)
		elif level > 0:
			bg_color = ThemeConfig.ACCENT_BLUE.darkened(0.7)
		panel.add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(bg_color, 4, 6))

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)

		# Title
		var title_label := Label.new()
		title_label.text = str(shift.get("shortTitle", "Shift %d" % shift_id))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		title_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
		title_label.clip_text = true
		vbox.add_child(title_label)

		# Level + target KPI
		var info_label := Label.new()
		if level >= max_level:
			info_label.text = "MAX (%s)" % target_kpi.substr(0, 3).capitalize()
		else:
			info_label.text = "Lv %d  →  %s" % [level, target_kpi.substr(0, 3).capitalize()]
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		if level >= max_level:
			info_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
		elif level > 0:
			info_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_BLUE)
		else:
			info_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		vbox.add_child(info_label)

		# XP bar (if not max level)
		if level < max_level:
			var xp_bar := ProgressBar.new()
			xp_bar.min_value = 0
			xp_bar.max_value = next_xp
			xp_bar.value = xp
			xp_bar.custom_minimum_size.y = 8
			xp_bar.show_percentage = false
			ThemeConfig.style_progress_bar(xp_bar, ThemeConfig.ACCENT_BLUE.lightened(0.2))
			vbox.add_child(xp_bar)

			var xp_label := Label.new()
			xp_label.text = "XP: %d/%d" % [xp, next_xp]
			xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			xp_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
			xp_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			vbox.add_child(xp_label)
		else:
			var max_label := Label.new()
			max_label.text = "+%d/year" % level
			max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			max_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
			max_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
			vbox.add_child(max_label)

		shifts_container.add_child(panel)


func _refresh_events() -> void:
	for child: Node in events_container.get_children():
		child.queue_free()

	var history: Array = GameStateManager.state.get("history", [])
	var count := mini(5, history.size())

	if count == 0:
		var empty := Label.new()
		empty.text = "No events yet"
		empty.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		empty.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		events_container.add_child(empty)
		return

	for i in range(count):
		var entry_label := Label.new()
		entry_label.text = "• " + str(history[i])
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		entry_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
		events_container.add_child(entry_label)
