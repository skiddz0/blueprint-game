## Game Over Screen — Displays final grade and KPI summary.
## See: design/gdd/game-over-screen.md
extends Control

@onready var grade_label: Label = %GradeLabel
@onready var result_label: Label = %ResultLabel
@onready var avg_kpi_label: Label = %AvgKpiLabel
@onready var kpi_summary: VBoxContainer = %KpiSummary
@onready var play_again_btn: Button = %PlayAgainBtn


func _ready() -> void:
	play_again_btn.pressed.connect(_on_play_again)
	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(ThemeConfig.BG_MODAL, 0, 0))
	grade_label.add_theme_font_size_override("font_size", 72)
	result_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	avg_kpi_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	avg_kpi_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	ThemeConfig.style_button(play_again_btn, ThemeConfig.BTN_PRIMARY, ThemeConfig.BTN_PRIMARY_HOVER)


func show_results(won: bool, grade: String) -> void:
	grade_label.text = grade
	var grade_colors := {
		"S": ThemeConfig.ACCENT_GOLD,
		"A": ThemeConfig.KPI_GREEN,
		"B": ThemeConfig.ACCENT_BLUE,
		"C": ThemeConfig.KPI_ORANGE,
		"D": ThemeConfig.KPI_ORANGE.darkened(0.2),
		"F": ThemeConfig.KPI_RED,
	}
	grade_label.add_theme_color_override("font_color", grade_colors.get(grade, ThemeConfig.TEXT_PRIMARY))

	if won:
		result_label.text = "Victory!"
		result_label.add_theme_color_override("font_color", ThemeConfig.KPI_GREEN)
	else:
		result_label.text = "The Blueprint fell short."
		result_label.add_theme_color_override("font_color", ThemeConfig.KPI_RED)

	var avg: float = KPISystem.calculate_average(GameStateManager.state["kpis"])
	avg_kpi_label.text = "Average KPI: %.1f" % avg

	for child: Node in kpi_summary.get_children():
		child.queue_free()

	for kpi_name: String in ["quality", "equity", "access", "unity", "efficiency"]:
		var value: float = float(GameStateManager.state["kpis"][kpi_name]["value"])
		var color := ThemeConfig.get_kpi_color(value)

		var hbox := HBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.text = kpi_name.capitalize()
		name_lbl.custom_minimum_size.x = 100
		name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
		hbox.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = value
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 20
		bar.show_percentage = false
		ThemeConfig.style_progress_bar(bar, color)
		hbox.add_child(bar)

		var val_lbl := Label.new()
		val_lbl.text = "%d" % int(value)
		val_lbl.custom_minimum_size.x = 40
		val_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		val_lbl.add_theme_color_override("font_color", color)
		hbox.add_child(val_lbl)

		kpi_summary.add_child(hbox)

	visible = true


func _on_play_again() -> void:
	visible = false
	GameStateManager.restart_game()
