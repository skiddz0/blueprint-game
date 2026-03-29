## Game Over Screen — Playful, colorful results display.
extends Control

@onready var grade_label: Label = %GradeLabel
@onready var result_label: Label = %ResultLabel
@onready var avg_kpi_label: Label = %AvgKpiLabel
@onready var kpi_summary: VBoxContainer = %KpiSummary
@onready var play_again_btn: Button = %PlayAgainBtn

const GRADE_COLORS := {
	"S": Color(0.98, 0.78, 0.15), "A": Color(0.20, 0.72, 0.35),
	"B": Color(0.25, 0.52, 0.95), "C": Color(0.95, 0.55, 0.15),
	"D": Color(0.75, 0.45, 0.15), "F": Color(0.92, 0.28, 0.25),
}
const GRADE_MESSAGES := {
	"S": "Outstanding! A masterclass! 🌟🌟🌟",
	"A": "Excellent work! Malaysia is proud! 🎉",
	"B": "Victory! The Blueprint delivered! ✨",
	"C": "Not bad, but room for improvement 🤔",
	"D": "The Blueprint underperformed... 😓",
	"F": "The education system declined 😢",
}
const KPI_ICONS := { "quality": "📚", "equity": "⚖️", "access": "🌐", "unity": "🤝", "efficiency": "⚙️" }


func _ready() -> void:
	play_again_btn.pressed.connect(func(): visible = false; GameStateManager.restart_game())
	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(
		Color(0.0, 0.0, 0.0, 0.50), 0, 0))
	grade_label.add_theme_font_size_override("font_size", 88)
	result_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SUBTITLE)
	avg_kpi_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	avg_kpi_label.add_theme_color_override("font_color", ThemeConfig.TEXT_BODY)
	ThemeConfig.style_button(play_again_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	play_again_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	play_again_btn.custom_minimum_size = Vector2(220, 50)

	# Title label
	var title_lbl: Label = grade_label.get_parent().get_child(0)
	if title_lbl is Label:
		title_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
		title_lbl.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Card panel background
	var card_panel: PanelContainer = grade_label.get_parent().get_parent()
	card_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.YELLOW, 16, 20))


func show_results(_won: bool, grade: String) -> void:
	var color: Color = GRADE_COLORS.get(grade, ThemeConfig.BLUE)

	grade_label.text = grade
	grade_label.add_theme_color_override("font_color", color)
	result_label.text = GRADE_MESSAGES.get(grade, "")
	result_label.add_theme_color_override("font_color", color)

	var avg: float = KPISystem.calculate_average(GameStateManager.state["kpis"])
	avg_kpi_label.text = "Average KPI: %.1f / 100" % avg

	for child: Node in kpi_summary.get_children():
		child.queue_free()

	var kpi_colors := { "quality": ThemeConfig.BLUE, "equity": ThemeConfig.PURPLE,
		"access": ThemeConfig.CYAN, "unity": ThemeConfig.PINK, "efficiency": ThemeConfig.ORANGE }

	for kpi_name: String in ["quality", "equity", "access", "unity", "efficiency"]:
		var value: float = float(GameStateManager.state["kpis"][kpi_name]["value"])
		var kpi_color := ThemeConfig.get_kpi_color(value)
		var accent: Color = kpi_colors.get(kpi_name, ThemeConfig.BLUE)

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_card(ThemeConfig.BG_WHITE, accent, 10, 10))
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		panel.add_child(hbox)

		var icon_lbl := Label.new()
		icon_lbl.text = KPI_ICONS.get(kpi_name, "")
		icon_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
		hbox.add_child(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text = kpi_name.capitalize()
		name_lbl.custom_minimum_size.x = 80
		name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		hbox.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.min_value = 0; bar.max_value = 100; bar.value = value
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 20
		bar.show_percentage = false
		ThemeConfig.style_progress_bar(bar, kpi_color)
		hbox.add_child(bar)

		var val_lbl := Label.new()
		val_lbl.text = "%d" % int(value)
		val_lbl.custom_minimum_size.x = 40
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
		val_lbl.add_theme_color_override("font_color", kpi_color)
		hbox.add_child(val_lbl)

		kpi_summary.add_child(panel)

	var stats := Label.new()
	var s: Dictionary = GameStateManager.state
	stats.text = "📊 Initiatives: %d  |  🎯 Scenarios: %d/27  |  📅 2013–2025" % [
		int(s.get("completed_initiative_count", 0)), s.get("scenarios_completed", {}).size()]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	stats.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	kpi_summary.add_child(stats)

	visible = true
