## Year-End Summary — Shows a report card between years.
## Displays KPI changes, initiative results, budget forecast, minister transition.
extends Control

signal continue_pressed

@onready var title_label: Label = %YearEndTitle
@onready var content_container: VBoxContainer = %YearEndContent
@onready var continue_btn: Button = %YearEndContinueBtn

const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const KPI_ICONS := {
	"quality": "📚", "equity": "⚖️", "access": "🌐",
	"unity": "🤝", "efficiency": "⚙️"
}


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	add_theme_stylebox_override("panel",
		ThemeConfig.make_panel_stylebox(Color(0.0, 0.0, 0.0, 0.50), 0, 0))
	ThemeConfig.style_button(continue_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	continue_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	continue_btn.custom_minimum_size = Vector2(250, 46)
	title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	title_label.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Card panel
	var card: PanelContainer = title_label.get_parent().get_parent()
	card.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.BLUE, 16, 16))


func show_summary(completed_year: int, old_kpis: Dictionary, new_kpis: Dictionary,
		initiative_results: Array, new_budget: float, has_october_penalty: bool,
		minister_changed: bool, new_minister_name: String, agenda_met: bool,
		agenda_reward_pc: int) -> void:
	visible = true

	title_label.text = "📋 Year %d — Summary" % completed_year

	# Clear previous
	for child: Node in content_container.get_children():
		child.queue_free()

	# -- KPI Changes Section --
	_add_section_header("📊 KPI CHANGES")

	for kpi_name: String in ["quality", "equity", "access", "unity", "efficiency"]:
		var old_val: float = float(old_kpis.get(kpi_name, {}).get("value", 0))
		var new_val: float = float(new_kpis.get(kpi_name, {}).get("value", 0))
		var delta: float = new_val - old_val

		var icon: String = KPI_ICONS.get(kpi_name, "")
		var delta_text: String
		var delta_color: Color
		if delta > 0.5:
			delta_text = "+%.0f ▲" % delta
			delta_color = ThemeConfig.GREEN
		elif delta < -0.5:
			delta_text = "%.0f ▼" % delta
			delta_color = ThemeConfig.RED
		else:
			delta_text = "±0 —"
			delta_color = ThemeConfig.TEXT_SECONDARY

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon_lbl := Label.new()
		icon_lbl.text = icon
		icon_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
		row.add_child(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text = kpi_name.capitalize()
		name_lbl.custom_minimum_size.x = 80
		name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		row.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.min_value = 0; bar.max_value = 100; bar.value = new_val
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 16
		bar.show_percentage = false
		ThemeConfig.style_progress_bar(bar, ThemeConfig.get_kpi_color(new_val))
		row.add_child(bar)

		var val_lbl := Label.new()
		val_lbl.text = "%.0f" % new_val
		val_lbl.custom_minimum_size.x = 30
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		val_lbl.add_theme_color_override("font_color", ThemeConfig.get_kpi_color(new_val))
		row.add_child(val_lbl)

		var delta_lbl := Label.new()
		delta_lbl.text = delta_text
		delta_lbl.custom_minimum_size.x = 60
		delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		delta_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		delta_lbl.add_theme_color_override("font_color", delta_color)
		row.add_child(delta_lbl)

		content_container.add_child(row)

	# Average KPI
	var avg := KPISystem.calculate_average(new_kpis)
	var avg_lbl := Label.new()
	avg_lbl.text = "📈 Average KPI: %.1f" % avg
	avg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avg_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	avg_lbl.add_theme_color_override("font_color", ThemeConfig.get_kpi_color(avg))
	content_container.add_child(avg_lbl)

	_add_separator()

	# -- Initiative Results Section --
	if initiative_results.size() > 0:
		_add_section_header("🎯 INITIATIVE RESULTS")
		var completed := 0; var partial := 0; var failed := 0
		for result: Dictionary in initiative_results:
			var status: String = str(result.get("status", ""))
			match status:
				"completed": completed += 1
				"partial": partial += 1
				"failed": failed += 1

		var results_row := HBoxContainer.new()
		results_row.add_theme_constant_override("separation", 16)
		results_row.alignment = BoxContainer.ALIGNMENT_CENTER

		if completed > 0:
			results_row.add_child(_make_stat_badge("✅ %d Completed" % completed, ThemeConfig.GREEN))
		if partial > 0:
			results_row.add_child(_make_stat_badge("⚠️ %d Partial" % partial, ThemeConfig.ORANGE))
		if failed > 0:
			results_row.add_child(_make_stat_badge("❌ %d Failed" % failed, ThemeConfig.RED))

		content_container.add_child(results_row)
		_add_separator()

	# -- Budget Section --
	_add_section_header("💰 BUDGET FORECAST")

	var budget_text := "Next year budget: RM %.1fM" % new_budget
	if has_october_penalty:
		budget_text += "  ⚠️ October penalty applied!"

	var budget_lbl := Label.new()
	budget_lbl.text = budget_text
	budget_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	budget_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	budget_lbl.add_theme_color_override("font_color",
		ThemeConfig.RED if has_october_penalty else ThemeConfig.BUDGET_COLOR)
	content_container.add_child(budget_lbl)

	# -- Minister Agenda --
	if agenda_met:
		var agenda_lbl := Label.new()
		agenda_lbl.text = "🎯 Minister's agenda met! +%d PC" % agenda_reward_pc
		agenda_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		agenda_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		agenda_lbl.add_theme_color_override("font_color", ThemeConfig.GREEN)
		content_container.add_child(agenda_lbl)

	_add_separator()

	# -- Minister Transition --
	if minister_changed:
		_add_section_header("🏛️ MINISTER TRANSITION")
		var transition_lbl := Label.new()
		transition_lbl.text = "New Minister: %s" % new_minister_name
		transition_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		transition_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
		transition_lbl.add_theme_color_override("font_color", ThemeConfig.PURPLE)
		content_container.add_child(transition_lbl)
		_add_separator()

	# -- Next Year Preview --
	var next_year: int = completed_year + 1
	if next_year <= 2025:
		var wave: int = ResourceSystem.get_wave(next_year)
		var preview := Label.new()
		preview.text = "📅 Entering Year %d — Wave %d" % [next_year, wave]
		preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
		preview.add_theme_color_override("font_color", ThemeConfig.BLUE)
		content_container.add_child(preview)


func _on_continue() -> void:
	visible = false
	continue_pressed.emit()


func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
	lbl.add_theme_color_override("font_color", ThemeConfig.ORANGE)
	content_container.add_child(lbl)


func _add_separator() -> void:
	var sep := HSeparator.new()
	content_container.add_child(sep)


func _make_stat_badge(text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(color.lerp(Color.WHITE, 0.85), color, 8, 8))
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	lbl.add_theme_color_override("font_color", color)
	panel.add_child(lbl)
	return panel


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_continue()
		get_viewport().set_input_as_handled()
