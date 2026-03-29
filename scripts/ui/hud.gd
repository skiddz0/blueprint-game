## HUD — Main game dashboard. Playful colorful theme.
extends Control

const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const KPI_ICONS := {
	"quality": "📚", "equity": "⚖️", "access": "🌐",
	"unity": "🤝", "efficiency": "⚙️"
}

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

@onready var minister_portrait: TextureRect = %MinisterPortrait
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
	GameStateManager.game_initialized.connect(_on_game_initialized)
	GameStateManager.phase_changed.connect(_on_phase_changed)
	GameStateManager.year_started.connect(func(_y: int): _refresh_all())
	GameStateManager.month_advanced.connect(_on_month_advanced)
	GameStateManager.kpi_changed.connect(_on_kpi_changed)
	GameStateManager.budget_changed.connect(func(_o: float, n: float): budget_label.text = "💰 RM %.1fM" % n)
	GameStateManager.pc_changed.connect(func(_o: int, n: int): pc_label.text = "🏛 %d" % n)
	GameStateManager.history_updated.connect(func(_e: String): _refresh_events())
	GameStateManager.scenario_triggered.connect(_on_scenario_triggered)
	GameStateManager.scenario_resolved.connect(func(_s: String, _c: String): scenario_modal.visible = false; YearCycleEngine.resume_after_scenario())
	GameStateManager.game_over.connect(func(w: bool, g: String): game_over_screen.show_results(w, g); game_over_screen.visible = true)
	GameTimer.timer_paused.connect(func(): pause_btn.text = "▶ Resume")
	GameTimer.timer_resumed.connect(func(): pause_btn.text = "⏸ Pause")
	GameTimer.speed_changed.connect(func(s: float): speed_btn.text = "⚡%.1fx" % s)

	select_initiatives_btn.pressed.connect(func(): initiative_selector.open_selector(); initiative_selector.visible = true)
	pause_btn.pressed.connect(_on_pause_pressed)
	speed_btn.pressed.connect(_on_speed_pressed)

	_kpi_bars = { "quality": kpi_quality_bar, "equity": kpi_equity_bar,
		"access": kpi_access_bar, "unity": kpi_unity_bar, "efficiency": kpi_efficiency_bar }
	_kpi_labels = { "quality": kpi_quality_value, "equity": kpi_equity_value,
		"access": kpi_access_value, "unity": kpi_unity_value, "efficiency": kpi_efficiency_value }

	_apply_styling()
	initiative_selector.visible = false
	scenario_modal.visible = false
	game_over_screen.visible = false

	if DataLoader.is_loaded():
		GameStateManager.initialize_game()
	else:
		DataLoader.data_loaded.connect(func(): GameStateManager.initialize_game(), CONNECT_ONE_SHOT)


func _process(_delta: float) -> void:
	if GameTimer.is_running():
		var r := GameTimer.get_time_remaining_in_year()
		timer_label.text = "%d:%02d" % [r["minutes"], r["seconds"]]


func _apply_styling() -> void:
	# Cream background on root
	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(ThemeConfig.BG_CREAM, 0, 0))

	# Blue header bar
	var header_panel: PanelContainer = %YearLabel.get_parent().get_parent()
	header_panel.add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(ThemeConfig.BG_HEADER, 0, 10))

	# Header labels — big, colorful, playful
	year_label.add_theme_font_size_override("font_size", 22)
	year_label.add_theme_color_override("font_color", ThemeConfig.TEXT_WHITE)
	month_label.add_theme_font_size_override("font_size", 22)
	month_label.add_theme_color_override("font_color", ThemeConfig.YELLOW)
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", ThemeConfig.CYAN)
	budget_label.add_theme_font_size_override("font_size", 22)
	budget_label.add_theme_color_override("font_color", ThemeConfig.YELLOW_LIGHT)
	pc_label.add_theme_font_size_override("font_size", 22)
	pc_label.add_theme_color_override("font_color", ThemeConfig.PURPLE_LIGHT)
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", ThemeConfig.YELLOW)
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", ThemeConfig.CYAN)

	# Minister
	minister_name_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	minister_name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	minister_nickname_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	minister_nickname_label.add_theme_color_override("font_color", ThemeConfig.PURPLE)
	minister_agenda_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	minister_agenda_label.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Buttons — colorful and playful
	ThemeConfig.style_button(select_initiatives_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	select_initiatives_btn.add_theme_font_size_override("font_size", 18)
	select_initiatives_btn.custom_minimum_size = Vector2(0, 44)
	ThemeConfig.style_button(pause_btn, ThemeConfig.ORANGE, Color(1.0, 0.65, 0.25))
	pause_btn.add_theme_font_size_override("font_size", 16)
	ThemeConfig.style_button(speed_btn, ThemeConfig.CYAN, Color(0.25, 0.82, 0.92))
	speed_btn.add_theme_font_size_override("font_size", 16)

	# KPI bars — chunky
	for kpi_name: String in _kpi_bars:
		var bar: ProgressBar = _kpi_bars[kpi_name]
		bar.custom_minimum_size.y = 20
		ThemeConfig.style_progress_bar(bar, ThemeConfig.KPI_GREEN)

	# Section headers in sidebar
	var sidebar: VBoxContainer = minister_portrait.get_parent()
	for child: Node in sidebar.get_children():
		if child is Label and not child.unique_name_in_owner:
			child.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
			child.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# KPI labels — dark text, explicit size
	for kpi_name: String in _kpi_labels:
		var row: HBoxContainer = _kpi_bars[kpi_name].get_parent()
		for child: Node in row.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
				child.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)

	# Section headers in main
	var main_content: VBoxContainer = initiatives_container.get_parent().get_parent()
	for child: Node in main_content.get_children():
		if child is Label and not child.unique_name_in_owner:
			child.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
			child.add_theme_color_override("font_color", ThemeConfig.ORANGE)


# -- Handlers ------------------------------------------------------------------

func _on_game_initialized() -> void:
	_refresh_all()

func _on_phase_changed(new_phase: String) -> void:
	phase_label.text = new_phase
	select_initiatives_btn.visible = (new_phase == "PLANNING")
	var show_ctrls := (new_phase == "RUNNING" or new_phase == "PAUSED")
	pause_btn.visible = show_ctrls
	speed_btn.visible = show_ctrls

func _on_month_advanced(_year: int, month: int) -> void:
	month_label.text = MONTH_NAMES[mini(month, 11)]
	_refresh_active_initiatives()

func _on_kpi_changed(kpi_name: String, _old: float, new_value: float) -> void:
	_update_kpi_display(kpi_name, new_value)

func _on_scenario_triggered(scenario: Dictionary) -> void:
	scenario_modal.show_scenario(scenario)
	scenario_modal.visible = true

func _on_pause_pressed() -> void:
	var phase := GameStateManager.get_phase()
	if phase == GameStateManager.Phase.RUNNING:
		GameTimer.pause(); GameStateManager.pause_game()
	elif phase == GameStateManager.Phase.PAUSED:
		GameStateManager.resume_game(); GameTimer.resume()

func _on_speed_pressed() -> void:
	var c := GameTimer.get_speed()
	if c < 1.5: GameTimer.set_speed(1.5)
	elif c < 2.0: GameTimer.set_speed(2.0)
	elif c < 3.0: GameTimer.set_speed(3.0)
	elif c < 5.0: GameTimer.set_speed(5.0)
	else: GameTimer.set_speed(1.0)


# -- Refresh -------------------------------------------------------------------

func _refresh_all() -> void:
	var s: Dictionary = GameStateManager.state
	year_label.text = "📅 %d" % s["year"]
	month_label.text = MONTH_NAMES[mini(int(s["month"]), 11)]
	wave_label.text = "Wave %d" % s["current_wave"]
	budget_label.text = "💰 RM %.1fM" % s["budget"]
	pc_label.text = "🏛 %d" % s["political_capital"]
	phase_label.text = GameStateManager.get_phase_name()

	for kpi_name: String in s["kpis"]:
		_update_kpi_display(kpi_name, float(s["kpis"][kpi_name]["value"]))

	var minister: Dictionary = s.get("current_minister", {})
	minister_name_label.text = str(minister.get("name", ""))
	minister_nickname_label.text = "\"%s\"" % str(minister.get("nickname", ""))
	var agenda: Variant = minister.get("agenda")
	if agenda is Dictionary:
		minister_agenda_label.text = "🎯 %s ≥ %d → +%d PC" % [
			str(agenda.get("kpi", "")).capitalize(),
			int(agenda.get("target", 0)), int(agenda.get("reward_pc", 0))]
	else:
		minister_agenda_label.text = ""

	# Load portrait
	var portrait_file: String = str(minister.get("portrait", ""))
	if portrait_file != "":
		var res_path := "res://assets/ministers/" + portrait_file
		if FileAccess.file_exists(res_path):
			var file := FileAccess.open(res_path, FileAccess.READ)
			var bytes := file.get_buffer(file.get_length())
			file.close()
			var img := Image.new()
			var ok := false
			if bytes.size() >= 4 and bytes[0] == 0x89 and bytes[1] == 0x50:
				ok = (img.load_png_from_buffer(bytes) == OK)
			if not ok:
				img = Image.new()
				ok = (img.load_jpg_from_buffer(bytes) == OK)
			if ok:
				minister_portrait.texture = ImageTexture.create_from_image(img)
			else:
				minister_portrait.texture = null
		else:
			minister_portrait.texture = null

	_refresh_active_initiatives()
	_refresh_shifts()
	_refresh_events()

	select_initiatives_btn.visible = (GameStateManager.get_phase() == GameStateManager.Phase.PLANNING)
	var show_ctrls := (GameStateManager.get_phase() == GameStateManager.Phase.RUNNING \
		or GameStateManager.get_phase() == GameStateManager.Phase.PAUSED)
	pause_btn.visible = show_ctrls; speed_btn.visible = show_ctrls


func _update_kpi_display(kpi_name: String, value: float) -> void:
	if not _kpi_bars.has(kpi_name): return
	var bar: ProgressBar = _kpi_bars[kpi_name]
	var label: Label = _kpi_labels[kpi_name]
	bar.value = value
	label.text = "%d" % int(value)
	var color := ThemeConfig.get_kpi_color(value)
	ThemeConfig.style_progress_bar(bar, color)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)


func _refresh_active_initiatives() -> void:
	for child: Node in initiatives_container.get_children():
		child.queue_free()

	var actives: Array = GameStateManager.state.get("active_initiatives", [])
	if actives.is_empty():
		var empty := Label.new()
		empty.text = "No active initiatives — pick some above! 🎯"
		empty.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		empty.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		initiatives_container.add_child(empty)
		return

	for active: Dictionary in actives:
		var progress: float = float(active.get("progress_percent", 0))
		var prog_color: Color
		if progress >= 100.0: prog_color = ThemeConfig.GREEN
		elif progress >= 50.0: prog_color = ThemeConfig.BLUE
		else: prog_color = ThemeConfig.ORANGE

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_left_accent_panel(ThemeConfig.BG_WHITE, prog_color, 4, 8, 8))
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		panel.add_child(hbox)

		var name_lbl := Label.new()
		name_lbl.text = str(active.get("name", ""))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = true
		name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		hbox.add_child(name_lbl)

		var prog_bar := ProgressBar.new()
		prog_bar.min_value = 0; prog_bar.max_value = 100; prog_bar.value = progress
		prog_bar.custom_minimum_size = Vector2(100, 16)
		prog_bar.show_percentage = false
		ThemeConfig.style_progress_bar(prog_bar, prog_color)
		hbox.add_child(prog_bar)

		var pct := Label.new()
		pct.text = "%d%%" % int(progress)
		pct.custom_minimum_size.x = 38
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		pct.add_theme_color_override("font_color", prog_color)
		hbox.add_child(pct)

		initiatives_container.add_child(panel)


func _refresh_shifts() -> void:
	for child: Node in shifts_container.get_children():
		child.queue_free()

	var shifts: Dictionary = GameStateManager.state.get("shifts", {})
	# Colors per KPI for shift cards
	var kpi_colors := {
		"quality": ThemeConfig.BLUE, "equity": ThemeConfig.PURPLE,
		"access": ThemeConfig.CYAN, "unity": ThemeConfig.PINK,
		"efficiency": ThemeConfig.ORANGE
	}

	for shift_id: int in shifts:
		var shift: Dictionary = shifts[shift_id]
		var level: int = int(shift.get("level", 0))
		var xp: int = int(shift.get("xp", 0))
		var next_xp: int = int(shift.get("nextLevelXp", 3))
		var target_kpi: String = str(shift.get("targetKpi", ""))
		var card_color: Color = kpi_colors.get(target_kpi, ThemeConfig.BLUE)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var border_color: Color
		if level >= 5: border_color = ThemeConfig.YELLOW
		elif level > 0: border_color = card_color
		else: border_color = ThemeConfig.BORDER_LIGHT
		panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_card(ThemeConfig.BG_WHITE, border_color, 10, 8))

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)

		# Title
		var title_lbl := Label.new()
		title_lbl.text = str(shift.get("shortTitle", "Shift %d" % shift_id))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		title_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		title_lbl.clip_text = true
		vbox.add_child(title_lbl)

		# Level + KPI
		var icon: String = KPI_ICONS.get(target_kpi, "")
		var info_lbl := Label.new()
		if level >= 5:
			info_lbl.text = "⭐ MAX %s" % icon
			info_lbl.add_theme_color_override("font_color", ThemeConfig.YELLOW)
		elif level > 0:
			info_lbl.text = "Lv %d %s" % [level, icon]
			info_lbl.add_theme_color_override("font_color", card_color)
		else:
			info_lbl.text = "Lv 0 %s" % icon
			info_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		vbox.add_child(info_lbl)

		# XP bar or max bonus
		if level < 5:
			var xp_bar := ProgressBar.new()
			xp_bar.min_value = 0; xp_bar.max_value = next_xp; xp_bar.value = xp
			xp_bar.custom_minimum_size.y = 8
			xp_bar.show_percentage = false
			ThemeConfig.style_progress_bar(xp_bar, card_color)
			vbox.add_child(xp_bar)
			var xp_lbl := Label.new()
			xp_lbl.text = "XP %d/%d" % [xp, next_xp]
			xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			xp_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
			xp_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
			vbox.add_child(xp_lbl)
		else:
			var bonus := Label.new()
			bonus.text = "+%d/year 🌟" % level
			bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bonus.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
			bonus.add_theme_color_override("font_color", ThemeConfig.YELLOW)
			vbox.add_child(bonus)

		shifts_container.add_child(panel)


func _refresh_events() -> void:
	for child: Node in events_container.get_children():
		child.queue_free()

	var history: Array = GameStateManager.state.get("history", [])
	var count := mini(6, history.size())

	if count == 0:
		var empty := Label.new()
		empty.text = "No events yet 📝"
		empty.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		empty.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		events_container.add_child(empty)
		return

	# Stakeholder sentiment based on average KPI
	var avg_kpi: float = KPISystem.calculate_average(GameStateManager.state["kpis"])
	var sentiment_emoji: String
	var sentiment_text: String
	var sentiment_color: Color
	if avg_kpi >= 75:
		sentiment_emoji = "😄"; sentiment_text = "Thrilled"; sentiment_color = ThemeConfig.GREEN
	elif avg_kpi >= 65:
		sentiment_emoji = "😊"; sentiment_text = "Pleased"; sentiment_color = ThemeConfig.GREEN
	elif avg_kpi >= 55:
		sentiment_emoji = "😐"; sentiment_text = "Neutral"; sentiment_color = ThemeConfig.ORANGE
	elif avg_kpi >= 45:
		sentiment_emoji = "😟"; sentiment_text = "Concerned"; sentiment_color = ThemeConfig.ORANGE
	else:
		sentiment_emoji = "😠"; sentiment_text = "Angry"; sentiment_color = ThemeConfig.RED

	var sentiment_panel := PanelContainer.new()
	sentiment_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_WHITE, sentiment_color, 8, 6))
	var sentiment_hbox := HBoxContainer.new()
	sentiment_hbox.add_theme_constant_override("separation", 8)
	sentiment_panel.add_child(sentiment_hbox)

	var face_lbl := Label.new()
	face_lbl.text = sentiment_emoji
	face_lbl.add_theme_font_size_override("font_size", 20)
	sentiment_hbox.add_child(face_lbl)

	var sent_vbox := VBoxContainer.new()
	sent_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sentiment_hbox.add_child(sent_vbox)

	var sent_title := Label.new()
	sent_title.text = "Stakeholders: %s" % sentiment_text
	sent_title.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	sent_title.add_theme_color_override("font_color", sentiment_color)
	sent_vbox.add_child(sent_title)

	var sent_detail := Label.new()
	sent_detail.text = "Avg KPI: %.0f" % avg_kpi
	sent_detail.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
	sent_detail.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	sent_vbox.add_child(sent_detail)

	events_container.add_child(sentiment_panel)

	# Event entries with contextual emojis
	for i in range(count):
		var text: String = str(history[i])
		var emoji := _get_event_emoji(text)

		var event_panel := PanelContainer.new()
		event_panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_left_accent_panel(
				ThemeConfig.BG_WHITE if i == 0 else ThemeConfig.BG_LIGHT,
				_get_event_color(text), 3, 6, 6))

		var event_hbox := HBoxContainer.new()
		event_hbox.add_theme_constant_override("separation", 6)
		event_panel.add_child(event_hbox)

		var emoji_lbl := Label.new()
		emoji_lbl.text = emoji
		emoji_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		event_hbox.add_child(emoji_lbl)

		var text_lbl := Label.new()
		text_lbl.text = text
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		if i == 0:
			text_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		else:
			text_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
		event_hbox.add_child(text_lbl)

		events_container.add_child(event_panel)


func _get_event_emoji(text: String) -> String:
	var t := text.to_lower()
	if "completed" in t: return "✅"
	if "partial" in t: return "⚠️"
	if "failed" in t: return "❌"
	if "minister" in t or "transition" in t: return "🏛️"
	if "october" in t or "budget" in t or "penalty" in t: return "💸"
	if "year" in t or "complete" in t: return "📅"
	if "flood" in t or "disaster" in t or "crisis" in t: return "🌊"
	if "pandemic" in t or "covid" in t: return "🦠"
	if "reform" in t or "policy" in t: return "📜"
	if "skeptic" in t or "criticism" in t: return "🤔"
	if "election" in t or "political" in t or "government" in t: return "🗳️"
	if "school" in t or "education" in t: return "🏫"
	if "teacher" in t: return "👩‍🏫"
	if "technology" in t or "digital" in t or "ict" in t: return "💻"
	if "agenda" in t or "reward" in t: return "🎯"
	return "📌"


func _get_event_color(text: String) -> Color:
	var t := text.to_lower()
	if "completed" in t or "reward" in t or "agenda" in t: return ThemeConfig.GREEN
	if "partial" in t or "october" in t: return ThemeConfig.ORANGE
	if "failed" in t or "penalty" in t: return ThemeConfig.RED
	if "minister" in t or "year" in t: return ThemeConfig.BLUE
	return ThemeConfig.BORDER_LIGHT
