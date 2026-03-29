## Mid-Year Review — Shows KPI progress at June (month 6) each year.
## A quick check-in showing how the year is going so far.
extends Control

signal continue_pressed

@onready var title_label: Label = %MidYearTitle
@onready var content_container: VBoxContainer = %MidYearContent
@onready var continue_btn: Button = %MidYearContinueBtn

const KPI_ICONS := {
	"quality": "📚", "equity": "⚖️", "access": "🌐",
	"unity": "🤝", "efficiency": "⚙️"
}

const COMMENTARY_GOOD := [
	"Looking good so far! Keep it up 👍",
	"Halfway there — strong progress! 💪",
	"The reform is on track 📈",
	"Citizens are noticing the improvements 🙂",
	"Minister is pleased with progress 👏",
]
const COMMENTARY_OK := [
	"Halfway through — mixed results 🤔",
	"Some KPIs need more attention ⚠️",
	"Room for improvement in the second half 📋",
	"Not bad, but watch the declining areas 👀",
	"The public is watching closely 📺",
]
const COMMENTARY_BAD := [
	"Warning: Several KPIs are in trouble! 🚨",
	"The second half needs a turnaround 😟",
	"Minister is concerned about the numbers 😬",
	"Public confidence is wavering 📉",
	"Time to make some tough decisions ⚖️",
]


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	add_theme_stylebox_override("panel",
		ThemeConfig.make_panel_stylebox(Color(0.0, 0.0, 0.0, 0.45), 0, 0))
	ThemeConfig.style_button(continue_btn, ThemeConfig.BLUE, ThemeConfig.BLUE_LIGHT)
	continue_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	continue_btn.custom_minimum_size = Vector2(200, 42)
	title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	title_label.add_theme_color_override("font_color", ThemeConfig.CYAN)

	var card: PanelContainer = title_label.get_parent().get_parent()
	card.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.CYAN, 14, 14))


func show_review(year: int, start_kpis: Dictionary, current_kpis: Dictionary,
		active_initiatives: Array) -> void:
	visible = true
	title_label.text = "📊 Mid-Year Review — %d" % year

	for child: Node in content_container.get_children():
		child.queue_free()

	# -- KPI Progress --
	_add_section("KPI PROGRESS — January to June")

	var improving := 0
	var declining := 0

	for kpi_name: String in ["quality", "equity", "access", "unity", "efficiency"]:
		var start_val: float = float(start_kpis.get(kpi_name, {}).get("value", 0))
		var current_val: float = float(current_kpis.get(kpi_name, {}).get("value", 0))
		var delta: float = current_val - start_val

		if delta > 0.5: improving += 1
		elif delta < -0.5: declining += 1

		var icon: String = KPI_ICONS.get(kpi_name, "")
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
		bar.min_value = 0; bar.max_value = 100; bar.value = current_val
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 16
		bar.show_percentage = false
		ThemeConfig.style_progress_bar(bar, ThemeConfig.get_kpi_color(current_val))
		row.add_child(bar)

		var val_lbl := Label.new()
		val_lbl.text = "%.0f" % current_val
		val_lbl.custom_minimum_size.x = 30
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		val_lbl.add_theme_color_override("font_color", ThemeConfig.get_kpi_color(current_val))
		row.add_child(val_lbl)

		var delta_lbl := Label.new()
		if delta > 0.5:
			delta_lbl.text = "+%.0f ▲" % delta
			delta_lbl.add_theme_color_override("font_color", ThemeConfig.GREEN)
		elif delta < -0.5:
			delta_lbl.text = "%.0f ▼" % delta
			delta_lbl.add_theme_color_override("font_color", ThemeConfig.RED)
		else:
			delta_lbl.text = "±0 —"
			delta_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
		delta_lbl.custom_minimum_size.x = 55
		delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		delta_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		row.add_child(delta_lbl)

		content_container.add_child(row)

	# -- Initiative Progress --
	if active_initiatives.size() > 0:
		content_container.add_child(HSeparator.new())
		_add_section("INITIATIVE PROGRESS")

		var on_track := 0
		var at_risk := 0
		for active: Dictionary in active_initiatives:
			var progress: float = float(active.get("progress_percent", 0))
			var duration: int = int(active.get("duration", 12))
			var expected: float = (6.0 / duration) * 100.0
			if progress >= expected * 0.8:
				on_track += 1
			else:
				at_risk += 1

		var status_row := HBoxContainer.new()
		status_row.add_theme_constant_override("separation", 12)
		status_row.alignment = BoxContainer.ALIGNMENT_CENTER

		var track_badge := _make_badge("✅ %d On Track" % on_track, ThemeConfig.GREEN)
		status_row.add_child(track_badge)
		if at_risk > 0:
			var risk_badge := _make_badge("⚠️ %d At Risk" % at_risk, ThemeConfig.ORANGE)
			status_row.add_child(risk_badge)

		content_container.add_child(status_row)

	# -- Commentary --
	content_container.add_child(HSeparator.new())

	var avg := KPISystem.calculate_average(current_kpis)
	var comments: Array
	if improving > declining and avg >= 55:
		comments = COMMENTARY_GOOD
	elif declining > improving or avg < 45:
		comments = COMMENTARY_BAD
	else:
		comments = COMMENTARY_OK

	var comment_lbl := Label.new()
	comment_lbl.text = comments[randi() % comments.size()]
	comment_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comment_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	comment_lbl.add_theme_color_override("font_color", ThemeConfig.BLUE)
	content_container.add_child(comment_lbl)

	# Months remaining
	var remaining := Label.new()
	remaining.text = "6 months remaining in %d" % year
	remaining.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	remaining.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	content_container.add_child(remaining)


func _on_continue() -> void:
	visible = false
	continue_pressed.emit()


func _add_section(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
	lbl.add_theme_color_override("font_color", ThemeConfig.ORANGE)
	content_container.add_child(lbl)


func _make_badge(text: String, color: Color) -> PanelContainer:
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
