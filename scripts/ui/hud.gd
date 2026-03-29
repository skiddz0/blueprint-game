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

@onready var sentiment_panel: PanelContainer = %SentimentPanel
@onready var sentiment_face: Label = %SentimentFace
@onready var sentiment_text: Label = %SentimentText
@onready var sentiment_detail: Label = %SentimentDetail
@onready var sentiment_bar: ProgressBar = %SentimentBar
@onready var minister_portrait: TextureRect = %MinisterPortrait
@onready var minister_name_label: Label = %MinisterNameLabel
@onready var minister_nickname_label: Label = %MinisterNicknameLabel
@onready var minister_agenda_label: Label = %MinisterAgendaLabel

@onready var initiatives_header: Label = %InitiativesHeader
@onready var initiatives_container: VBoxContainer = %InitiativesContainer
@onready var shifts_container: GridContainer = %ShiftsContainer
@onready var events_container: VBoxContainer = %EventsContainer

@onready var select_initiatives_btn: Button = %SelectInitiativesBtn
@onready var pause_btn: Button = %PauseBtn
@onready var speed_btn: Button = %SpeedBtn

@onready var initiative_selector: Control = %InitiativeSelector
@onready var scenario_modal: Control = %ScenarioModal
@onready var game_over_screen: Control = %GameOverScreen
@onready var save_load_modal: Control = %SaveLoadModal
@onready var year_end_summary: Control = %YearEndSummary
@onready var mid_year_review: Control = %MidYearReview
@onready var tutorial: Control = %Tutorial
@onready var menu_btn: MenuButton = %MenuBtn

var _kpi_bars: Dictionary = {}
var _kpi_labels: Dictionary = {}
var _pre_year_end_kpis: Dictionary = {}
var _year_end_initiative_results: Array = []


func _ready() -> void:
	GameStateManager.game_initialized.connect(_on_game_initialized)
	GameStateManager.phase_changed.connect(_on_phase_changed)
	GameStateManager.year_started.connect(func(_y: int): _refresh_all(); tutorial.trigger("year_started"))
	GameStateManager.month_advanced.connect(_on_month_advanced)
	GameStateManager.kpi_changed.connect(_on_kpi_changed)
	GameStateManager.budget_changed.connect(func(_o: float, n: float): budget_label.text = "💰 RM %.1fM" % n)
	GameStateManager.pc_changed.connect(func(_o: int, n: int): pc_label.text = "🏛 %d" % n)
	GameStateManager.history_updated.connect(func(_e: String): _refresh_events())
	GameStateManager.scenario_triggered.connect(_on_scenario_triggered)
	GameStateManager.scenario_resolved.connect(func(_s: String, _c: String): scenario_modal.visible = false; YearCycleEngine.resume_after_scenario())
	GameStateManager.year_ended.connect(_on_year_ended)
	GameStateManager.game_over.connect(func(w: bool, g: String): game_over_screen.show_results(w, g); game_over_screen.visible = true)
	GameTimer.timer_paused.connect(func(): pause_btn.text = "▶ Resume")
	GameTimer.timer_resumed.connect(func(): pause_btn.text = "⏸ Pause")
	GameTimer.speed_changed.connect(func(s: float): speed_btn.text = "⚡%.1fx" % s)

	select_initiatives_btn.pressed.connect(func(): initiative_selector.open_selector(); initiative_selector.visible = true)
	pause_btn.pressed.connect(_on_pause_pressed)
	speed_btn.pressed.connect(_on_speed_pressed)
	# Hamburger menu
	var popup := menu_btn.get_popup()
	popup.add_item("💾  Save Game", 0)
	popup.add_item("📂  Load Game", 1)
	popup.add_separator()
	popup.add_item("🏆  Achievements", 2)
	popup.add_separator()
	popup.add_item("🔊  Toggle Music", 4)
	popup.add_item("📖  Replay Tutorial", 5)
	popup.add_separator()
	popup.add_item("🚪  Main Menu", 3)
	popup.id_pressed.connect(_on_menu_item)

	_kpi_bars = { "quality": kpi_quality_bar, "equity": kpi_equity_bar,
		"access": kpi_access_bar, "unity": kpi_unity_bar, "efficiency": kpi_efficiency_bar }
	_kpi_labels = { "quality": kpi_quality_value, "equity": kpi_equity_value,
		"access": kpi_access_value, "unity": kpi_unity_value, "efficiency": kpi_efficiency_value }

	_apply_styling()
	initiative_selector.visible = false
	scenario_modal.visible = false
	game_over_screen.visible = false
	save_load_modal.visible = false
	year_end_summary.visible = false
	year_end_summary.continue_pressed.connect(_on_year_end_continue)
	mid_year_review.visible = false
	mid_year_review.continue_pressed.connect(_on_mid_year_continue)
	YearCycleEngine.year_end_data_ready.connect(_on_year_end_data_ready)
	YearCycleEngine.mid_year_review_ready.connect(_on_mid_year_review_ready)

	# Achievement toast
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)

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
	minister_name_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	minister_name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	minister_nickname_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	minister_nickname_label.add_theme_color_override("font_color", ThemeConfig.PURPLE)
	minister_agenda_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	minister_agenda_label.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Buttons — colorful and playful
	ThemeConfig.style_button(select_initiatives_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	select_initiatives_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
	ThemeConfig.style_button(pause_btn, ThemeConfig.ORANGE, Color(1.0, 0.65, 0.25))
	pause_btn.add_theme_font_size_override("font_size", 16)
	ThemeConfig.style_button(speed_btn, ThemeConfig.CYAN, Color(0.25, 0.82, 0.92))
	speed_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.add_theme_font_size_override("font_size", 22)
	menu_btn.add_theme_color_override("font_color", ThemeConfig.TEXT_WHITE)

	# KPI bars — chunky
	for kpi_name: String in _kpi_bars:
		var bar: ProgressBar = _kpi_bars[kpi_name]
		bar.custom_minimum_size.y = 20
		ThemeConfig.style_progress_bar(bar, ThemeConfig.KPI_GREEN)

	# Section headers in sidebar (including nested in HBoxContainers)
	var sidebar: VBoxContainer = minister_portrait.get_parent()
	for child: Node in sidebar.get_children():
		if child is Label and not child.unique_name_in_owner:
			child.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
			child.add_theme_color_override("font_color", ThemeConfig.BLUE)
		elif child is HBoxContainer:
			for sub: Node in child.get_children():
				if sub is Label and not sub.unique_name_in_owner:
					sub.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
					sub.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# KPI labels — dark text, explicit size
	for kpi_name: String in _kpi_labels:
		var row: HBoxContainer = _kpi_bars[kpi_name].get_parent()
		for child: Node in row.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
				child.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)

	# Section headers in main — style all Labels (not KPI/minister ones)
	var main_content: VBoxContainer = initiatives_container.get_parent().get_parent().get_parent()
	for child: Node in main_content.get_children():
		if child is Label and child != initiatives_header:
			child.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
			child.add_theme_color_override("font_color", ThemeConfig.ORANGE)
		elif child is HBoxContainer:
			for sub: Node in child.get_children():
				if sub is Label:
					sub.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
					sub.add_theme_color_override("font_color", ThemeConfig.ORANGE)

	# Explicitly style initiatives header
	initiatives_header.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
	initiatives_header.add_theme_color_override("font_color", ThemeConfig.ORANGE)


# -- Handlers ------------------------------------------------------------------

func _on_game_initialized() -> void:
	_refresh_all()
	tutorial.trigger("game_start")

func _on_phase_changed(new_phase: String) -> void:
	phase_label.text = new_phase
	var is_planning := (new_phase == "PLANNING")
	select_initiatives_btn.visible = is_planning
	initiatives_header.visible = not is_planning
	if is_planning:
		select_initiatives_btn.text = "🎯 Select Initiatives"
		select_initiatives_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
	var show_ctrls := (new_phase == "RUNNING" or new_phase == "PAUSED")
	pause_btn.visible = show_ctrls
	speed_btn.visible = show_ctrls

func _on_month_advanced(_year: int, month: int) -> void:
	month_label.text = MONTH_NAMES[mini(month, 11)]
	_refresh_active_initiatives()
	_update_sentiment()

func _on_kpi_changed(kpi_name: String, _old: float, new_value: float) -> void:
	_update_kpi_display(kpi_name, new_value)

func _on_scenario_triggered(scenario: Dictionary) -> void:
	tutorial.trigger("scenario")
	scenario_modal.show_scenario(scenario)
	scenario_modal.visible = true

func _on_year_ended(completed_year: int) -> void:
	_refresh_all()

func _on_year_end_data_ready(data: Dictionary) -> void:
	tutorial.trigger("year_end")
	if bool(data.get("minister_changed", false)):
		tutorial.trigger("minister_change")
	# Don't show summary if game is over — game over screen handles that
	if GameStateManager.state.get("game_over", false):
		return
	year_end_summary.show_summary(
		int(data["completed_year"]),
		data["old_kpis"],
		data["new_kpis"],
		data["initiative_results"],
		float(data["new_budget"]),
		bool(data["has_october_penalty"]),
		bool(data["minister_changed"]),
		str(data["new_minister_name"]),
		bool(data["agenda_met"]),
		int(data["agenda_reward_pc"]),
	)

func _on_year_end_continue() -> void:
	_refresh_all()

func _on_mid_year_review_ready(data: Dictionary) -> void:
	tutorial.trigger("mid_year")
	mid_year_review.show_review(
		int(data["year"]),
		data["start_kpis"],
		data["current_kpis"],
		data["active_initiatives"],
	)

func _on_mid_year_continue() -> void:
	GameTimer.resume()

func _on_pause_pressed() -> void:
	var phase := GameStateManager.get_phase()
	if phase == GameStateManager.Phase.RUNNING:
		GameTimer.pause(); GameStateManager.pause_game()
	elif phase == GameStateManager.Phase.PAUSED:
		GameStateManager.resume_game(); GameTimer.resume()

func _on_menu_item(id: int) -> void:
	match id:
		0: save_load_modal.open("save")
		1: save_load_modal.open("load")
		2: _show_achievements()
		3:
			AudioManager.play_menu_music()
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		4:
			var muted := AudioManager.toggle_mute()
		5:
			tutorial._is_complete = false
			tutorial._current_step = -1
			tutorial._save_state()
			tutorial.trigger("game_start")
			# Update menu label
			var popup := menu_btn.get_popup()
			for i in range(popup.item_count):
				if popup.get_item_id(i) == 4:
					popup.set_item_text(i, "🔇  Music Off" if muted else "🔊  Toggle Music")


func _show_achievements() -> void:
	var all := AchievementSystem.get_all_achievements()
	var unlocked := AchievementSystem.get_unlocked_count()
	var total := AchievementSystem.get_total_count()

	# Simple achievement display as a panel overlay
	var overlay := PanelContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel",
		ThemeConfig.make_panel_stylebox(Color(0.0, 0.0, 0.0, 0.45), 0, 0))
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	overlay.add_child(margin)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.YELLOW, 16, 16))
	margin.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "🏆 Achievements (%d/%d)" % [unlocked, total]
	title.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	title.add_theme_color_override("font_color", ThemeConfig.YELLOW)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for ach: Dictionary in all:
		var is_unlocked: bool = ach.get("unlocked", false)
		var ach_panel := PanelContainer.new()
		var accent := ThemeConfig.YELLOW if is_unlocked else ThemeConfig.BORDER_LIGHT
		ach_panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_left_accent_panel(
				ThemeConfig.BG_WHITE if is_unlocked else ThemeConfig.BG_LIGHT,
				accent, 4, 8, 8))

		var ach_hbox := HBoxContainer.new()
		ach_hbox.add_theme_constant_override("separation", 10)
		ach_panel.add_child(ach_hbox)

		var icon := Label.new()
		icon.text = "🏆" if is_unlocked else "🔒"
		icon.add_theme_font_size_override("font_size", 18)
		ach_hbox.add_child(icon)

		var ach_info := VBoxContainer.new()
		ach_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ach_hbox.add_child(ach_info)

		var ach_name := Label.new()
		ach_name.text = str(ach.get("name", ""))
		ach_name.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		ach_name.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK if is_unlocked else ThemeConfig.TEXT_MUTED)
		ach_info.add_child(ach_name)

		var ach_desc := Label.new()
		ach_desc.text = str(ach.get("description", ""))
		ach_desc.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		ach_desc.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY if is_unlocked else ThemeConfig.TEXT_MUTED)
		ach_info.add_child(ach_desc)

		list.add_child(ach_panel)

	var close_btn := Button.new()
	close_btn.text = "Close"
	ThemeConfig.style_button(close_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

	add_child(overlay)


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

	_update_sentiment()
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


## Public voice lines by sentiment tier — randomised each update
const PUBLIC_VOICES_HIGH := [
	"\"Anak saya semakin pandai! Terima kasih cikgu!\" 👩‍👧",
	"\"My kids love going to school now!\" 🏫❤️",
	"\"Internet in rural schools — about time!\" 📡",
	"\"Teacher quality has really improved\" 👩‍🏫✨",
	"\"Proud of Malaysia's education progress\" 🇲🇾",
	"\"Results are showing — well done!\" 📊",
	"\"My daughter wants to be a scientist now!\" 🔬👧",
	"\"School canteen food also improved haha\" 🍛😄",
	"\"Jiran saya pun puji sekolah anak dia\" 🏘️👍",
	"\"Finally, kampung schools getting attention\" 🌾🏫",
	"\"Cikgu sekarang sangat dedicated\" 👩‍🏫💪",
	"\"My son got into university — first in our family!\" 🎓🎉",
	"\"Education is the best investment\" 📚💎",
	"\"I can see the difference in my child's thinking\" 🧠✨",
	"\"Sekolah dah macam fun, anak tak sabar nak pergi\" 🏃‍♂️",
	"\"Thank you for investing in our children's future\" 🙏",
]
const PUBLIC_VOICES_GOOD := [
	"\"Things are getting better, step by step\" 🙂",
	"\"Hope the new policies continue\" 🤞",
	"\"My child's school got new computers\" 💻",
	"\"New curriculum is more interesting\" 📚",
	"\"More teachers joining — good sign\" 👩‍🏫",
	"\"Exam reformed! Now assess real skills\" 📋✅",
	"\"Less memorization, more understanding\" 🧠",
	"\"I was an exam kid and I support reform\" 🤝",
	"\"Anak saya seronok belajar coding\" 💻😊",
	"\"At least they're listening to parents now\" 👂",
	"\"School library got new books — anak suka!\" 📖😊",
	"\"Teacher training is making a difference\" 👩‍🏫📈",
	"\"Rural schools slowly catching up\" 🏘️📶",
	"\"My neighbour's kid got a scholarship!\" 🎓",
	"\"Sports facilities improved, anak aktif sihat\" ⚽😊",
	"\"Preschool program bagus — anak ready for Year 1\" 👶📚",
	"\"Love the new after-school activities\" 🎨🏀",
	"\"School counselor helped my child a lot\" 💚",
]
const PUBLIC_VOICES_NEUTRAL := [
	"\"Where is our education heading?\" 🤔",
	"\"Too many uniforms to wash la...\" 👕",
	"\"Are national exams still relevant?\" 📝",
	"\"My kid's homework is the same as mine dulu\" 📖",
	"\"Can we focus on quality, not quantity?\" ⚖️",
	"\"Abolish exams! Students just hafal jawapan je\" 🙅",
	"\"Don't abolish exams la — I turned out fine\" 💪",
	"\"Exam or no exam, tuition centre still full\" 🏫",
	"\"My child study for exam or study for life?\" 🤷",
	"\"Cikgu pun penat mark kertas\" 😮‍💨",
	"\"Let kids be kids la, too much homework\" 🧒",
	"\"Sekolah kebangsaan or sekolah jenis — which better?\" 🤔",
	"\"My anak wants tablet, I want them to read books\" 📱📚",
	"\"Co-curriculum important or waste of time?\" 🏸",
	"\"Every year new policy, consistency please\" 📋",
	"\"BM or English for Science? Debat tak habis\" 🗣️",
	"\"Tuition business booming — what does that tell you\" 📝💰",
	"\"Buku teks berat sangat, kesian budak-budak\" 🎒😅",
	"\"Teacher friend says too much paperwork\" 📋😑",
	"\"My child happy at school, that's enough for me\" 😊",
	"\"Nak jadi cikgu ke engineer? Both also good\" 👩‍🏫👷",
	"\"Canteen food needs upgrade la\" 🍜",
	"\"School bus always late...\" 🚌⏰",
]
const PUBLIC_VOICES_WORRIED := [
	"\"Our children deserve better than this\" 😟",
	"\"Schools are getting too crowded\" 🏫😰",
	"\"Teachers are burning out\" 😩",
	"\"Global rankings are not looking good\" 📉",
	"\"Rich area schools vs kampung schools — unfair\" 💔",
	"\"Digital gap is getting worse\" 📵",
	"\"Students hafal jawapan tapi tak faham\" 📖😟",
	"\"Exam stress affecting our kids\" 😰",
	"\"Budak sekarang susah nak fokus\" 🤦",
	"\"Need more counselors in schools\" 💚😟",
	"\"Class size too big, teacher cannot cope\" 👨‍👩‍👧‍👦",
	"\"Special needs students not getting enough support\" ♿😟",
	"\"Some schools still no proper internet\" 📵",
	"\"Parents have to spend so much on tuition\" 💸",
	"\"Kualiti pendidikan merosot — risau\" 😟📉",
]
const PUBLIC_VOICES_ANGRY := [
	"\"We need answers! Where's the progress?\" 😡",
	"\"My child can't read properly at Year 3!\" 😡📖",
	"\"So much budget, so little change!\" 💸",
	"\"Our kids are falling behind!\" 🌏😠",
	"\"Teachers underpaid but workload gila\" 😢",
	"\"The system needs a complete overhaul\" 🔧",
	"\"We want accountability from the ministry!\" ✊",
	"\"Stop experimenting on our children!\" 🧪😤",
	"\"Janji manis je, action mana?\" 😤",
	"\"Every minister reset everything, penat!\" 🔄😡",
]

## KPI-specific public concerns — shown when a specific KPI is the lowest
const KPI_VOICES := {
	"quality": [
		"\"Kualiti pengajaran perlu ditingkatkan\" 📉",
		"\"Students need to think, not just memorize\" 🧠",
		"\"Teaching quality needs more investment\" 👩‍🏫",
		"\"International test scores need improvement\" 📊",
		"\"Creativity should be in the curriculum\" 🎨",
		"\"STEM education still not strong enough\" 🔬",
		"\"Our graduates not work-ready\" 🎓😟",
		"\"Need better teacher training programs\" 👩‍🏫📚",
	],
	"equity": [
		"\"Rural schools need more attention\" 🏘️",
		"\"Every child deserves equal opportunity\" 💛",
		"\"The achievement gap needs to shrink\" 📊",
		"\"Orang Asli communities want better schools\" 🤝",
		"\"Sabah and Sarawak schools need love too\" 🏝️",
		"\"B40 families struggling with school costs\" 💸",
		"\"Special needs kids deserve better facilities\" ♿💛",
		"\"Urban vs rural — the gap is real\" 🏙️🏘️",
	],
	"access": [
		"\"Not enough schools in new areas\" 🏗️",
		"\"Internet in kampung schools — when?\" 📵",
		"\"OKU students need better access\" ♿",
		"\"Preschool enrollment still too low\" 👶",
		"\"We need more science labs\" 🔬",
		"\"Sekolah penuh sesak, kelas 40 orang\" 👨‍👩‍👧‍👦",
		"\"Library hours too short, nak baca bila?\" 📚⏰",
		"\"Transport to school is a problem\" 🚌",
	],
	"unity": [
		"\"Parents want more say in school decisions\" 🗣️",
		"\"Keep politics out of education please\" 🏛️",
		"\"We need consistency in policies\" 📋",
		"\"PTAs should have real power\" 👨‍👩‍👧",
		"\"Community wants to help but how?\" 🤝",
		"\"Communication from ministry very poor\" 📢",
		"\"Parents and teachers should work together\" 🤝👩‍🏫",
		"\"Dengar suara rakyat dulu before decide\" 👂",
	],
	"efficiency": [
		"\"Where does the education budget go?\" 💸",
		"\"Too much bureaucracy in schools\" 📋",
		"\"Teachers drowning in paperwork\" 📝😩",
		"\"Spend more on classrooms, less on admin\" ⚖️",
		"\"School maintenance always delayed\" 🔧⏳",
		"\"Procurement process too slow\" 📦😑",
		"\"Cikgu nak mengajar, bukan isi borang\" 📋👩‍🏫",
		"\"Budget ada, execution lambat\" 💰🐌",
	],
}

var _last_voice: String = ""

func _update_sentiment() -> void:
	var kpis: Dictionary = GameStateManager.state["kpis"]
	var avg := KPISystem.calculate_average(kpis)
	var unity: float = float(kpis["unity"]["value"])

	# Sentiment weighted: 60% avg KPI + 40% Unity
	var score: float = avg * 0.6 + unity * 0.4

	var emoji: String
	var mood: String
	var color: Color
	var voices: Array
	if score >= 80:
		emoji = "🤩"; mood = "Ecstatic"; color = ThemeConfig.GREEN; voices = PUBLIC_VOICES_HIGH
	elif score >= 70:
		emoji = "😄"; mood = "Thrilled"; color = ThemeConfig.GREEN; voices = PUBLIC_VOICES_HIGH
	elif score >= 60:
		emoji = "😊"; mood = "Pleased"; color = ThemeConfig.GREEN; voices = PUBLIC_VOICES_GOOD
	elif score >= 50:
		emoji = "🙂"; mood = "Hopeful"; color = ThemeConfig.BLUE; voices = PUBLIC_VOICES_GOOD
	elif score >= 45:
		emoji = "😐"; mood = "Neutral"; color = ThemeConfig.ORANGE; voices = PUBLIC_VOICES_NEUTRAL
	elif score >= 35:
		emoji = "😟"; mood = "Concerned"; color = ThemeConfig.ORANGE; voices = PUBLIC_VOICES_WORRIED
	elif score >= 25:
		emoji = "😠"; mood = "Frustrated"; color = ThemeConfig.RED; voices = PUBLIC_VOICES_ANGRY
	else:
		emoji = "🤬"; mood = "Outraged"; color = ThemeConfig.RED; voices = PUBLIC_VOICES_ANGRY

	# 40% chance to show a KPI-specific concern about the lowest KPI
	var use_kpi_voice := (randf() < 0.4 and score < 70)
	if use_kpi_voice:
		var lowest_kpi := ""
		var lowest_val := 999.0
		for kpi_name: String in kpis:
			var val: float = float(kpis[kpi_name]["value"])
			if val < lowest_val:
				lowest_val = val
				lowest_kpi = kpi_name
		if KPI_VOICES.has(lowest_kpi):
			voices = KPI_VOICES[lowest_kpi]

	# Pick random voice (avoid repeating)
	var voice: String = voices[randi() % voices.size()]
	if voices.size() > 1:
		while voice == _last_voice:
			voice = voices[randi() % voices.size()]
	_last_voice = voice

	sentiment_face.text = emoji
	sentiment_face.add_theme_font_size_override("font_size", 28)

	# Public voice quote above the mood
	sentiment_detail.text = voice
	sentiment_detail.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	sentiment_detail.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	sentiment_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	sentiment_text.text = "%s — Approval: %.0f%%" % [mood, score]
	sentiment_text.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	sentiment_text.add_theme_color_override("font_color", color)

	sentiment_bar.value = score
	ThemeConfig.style_progress_bar(sentiment_bar, color)
	sentiment_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_WHITE, color, 8, 8))


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
		vbox.add_theme_constant_override("separation", 3)
		panel.add_child(vbox)

		# Title — wraps to 2 lines
		var title_lbl := Label.new()
		title_lbl.text = str(shift.get("shortTitle", "Shift %d" % shift_id))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		title_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(title_lbl)

		# Icon row: big icon + level/XP info
		var icon: String = KPI_ICONS.get(target_kpi, "")
		var icon_row := HBoxContainer.new()
		icon_row.add_theme_constant_override("separation", 6)
		icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(icon_row)

		var icon_lbl := Label.new()
		icon_lbl.text = icon
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_row.add_child(icon_lbl)

		var level_lbl := Label.new()
		if level >= 5:
			level_lbl.text = "⭐ MAX  +%d/yr" % level
			level_lbl.add_theme_color_override("font_color", ThemeConfig.YELLOW)
		elif level > 0:
			level_lbl.text = "Lv %d  XP %d/%d" % [level, xp, next_xp]
			level_lbl.add_theme_color_override("font_color", card_color)
		else:
			level_lbl.text = "Lv 0  XP %d/%d" % [xp, next_xp]
			level_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		level_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		icon_row.add_child(level_lbl)

		# XP bar (below icon row)
		if level < 5:
			var xp_bar := ProgressBar.new()
			xp_bar.min_value = 0; xp_bar.max_value = next_xp; xp_bar.value = xp
			xp_bar.custom_minimum_size.y = 6
			xp_bar.show_percentage = false
			ThemeConfig.style_progress_bar(xp_bar, card_color)
			vbox.add_child(xp_bar)

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


func _on_achievement_unlocked(achievement: Dictionary) -> void:
	# Show a toast notification at the top of the screen
	var toast := PanelContainer.new()
	toast.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_WHITE, ThemeConfig.YELLOW, 12, 12))
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position.y = 60
	toast.custom_minimum_size = Vector2(400, 0)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	toast.add_child(hbox)

	var trophy := Label.new()
	trophy.text = "🏆"
	trophy.add_theme_font_size_override("font_size", 28)
	hbox.add_child(trophy)

	var info := VBoxContainer.new()
	hbox.add_child(info)

	var title := Label.new()
	title.text = "Achievement Unlocked!"
	title.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	title.add_theme_color_override("font_color", ThemeConfig.YELLOW)
	info.add_child(title)

	var name_lbl := Label.new()
	name_lbl.text = str(achievement.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(achievement.get("description", ""))
	desc_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	desc_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	info.add_child(desc_lbl)

	add_child(toast)

	# Fade out after 3 seconds
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(toast, "modulate:a", 0.0, 1.0)
	tween.tween_callback(toast.queue_free)
