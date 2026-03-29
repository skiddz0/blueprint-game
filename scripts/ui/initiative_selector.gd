## Initiative Selector — Playful January planning modal.
extends Control

signal selection_confirmed
signal selection_cancelled

@onready var search_field: LineEdit = %SearchField
@onready var category_tabs: HBoxContainer = %CategoryTabs
@onready var initiative_list: VBoxContainer = %InitiativeList
@onready var summary_label: Label = %SummaryLabel
@onready var projected_label: Label = %ProjectedLabel
@onready var confirm_btn: Button = %ConfirmBtn
@onready var cancel_btn: Button = %CancelBtn

var _current_filter: String = "all"
var _search_text: String = ""
var _category_buttons: Dictionary = {}

const CATEGORIES := ["all", "infrastructure", "human_capital", "policy",
	"technology", "community", "governance"]
const CATEGORY_LABELS := {
	"all": "🌟 All", "infrastructure": "🏗️ Infra", "human_capital": "👩‍🏫 Human",
	"policy": "📜 Policy", "technology": "💻 Tech", "community": "🤝 Community",
	"governance": "🏛️ Gov"
}
const CATEGORY_COLORS := {
	"all": Color(0.25, 0.52, 0.95),
	"infrastructure": Color(0.95, 0.55, 0.15),
	"human_capital": Color(0.58, 0.35, 0.85),
	"policy": Color(0.20, 0.72, 0.35),
	"technology": Color(0.15, 0.75, 0.85),
	"community": Color(0.92, 0.45, 0.65),
	"governance": Color(0.50, 0.30, 0.75),
}


func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	search_field.text_changed.connect(_on_search_changed)

	# Modal background — semi-transparent overlay + white card
	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(
		Color(0.0, 0.0, 0.0, 0.45), 0, 0))

	# Style header
	var header_lbl: Node = %SearchField.get_parent().get_child(0)
	if header_lbl is Label:
		header_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
		header_lbl.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Summary labels
	summary_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	summary_label.add_theme_color_override("font_color", ThemeConfig.ORANGE)
	projected_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	projected_label.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Buttons
	ThemeConfig.style_button(confirm_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	confirm_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	ThemeConfig.style_button(cancel_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)

	# Category filter buttons
	for cat: String in CATEGORIES:
		var btn := Button.new()
		btn.text = CATEGORY_LABELS.get(cat, cat)
		btn.toggle_mode = true
		btn.button_pressed = (cat == "all")
		btn.pressed.connect(_on_category_pressed.bind(cat))
		var col: Color = CATEGORY_COLORS.get(cat, ThemeConfig.BLUE)
		ThemeConfig.style_button(btn, col.lerp(ThemeConfig.BG_CREAM, 0.6), col.lerp(ThemeConfig.BG_CREAM, 0.4))
		category_tabs.add_child(btn)
		_category_buttons[cat] = btn

	# Search field styling
	search_field.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	search_field.add_theme_color_override("font_placeholder_color", ThemeConfig.TEXT_MUTED)
	search_field.add_theme_stylebox_override("normal",
		ThemeConfig.make_bordered_panel(ThemeConfig.BG_WHITE, ThemeConfig.BORDER_LIGHT, 1, 8, 8))

	# Card panel background
	var card_panel: PanelContainer = %SearchField.get_parent().get_parent()
	card_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.BLUE, 16, 16))


func open_selector() -> void:
	_current_filter = "all"
	_search_text = ""
	search_field.text = ""
	for cat: String in _category_buttons:
		_category_buttons[cat].button_pressed = (cat == "all")
	_rebuild_list()
	_update_summary()
	visible = true
	search_field.grab_focus()


func _on_confirm() -> void:
	visible = false
	YearCycleEngine.start_new_year()
	selection_confirmed.emit()

func _on_cancel() -> void:
	for init: Dictionary in GameStateManager.state["initiatives"]:
		if init["selected"]:
			GameStateManager.toggle_initiative(init["id"])
	visible = false
	selection_cancelled.emit()

func _on_search_changed(new_text: String) -> void:
	_search_text = new_text.to_lower()
	_rebuild_list()

func _on_category_pressed(category: String) -> void:
	_current_filter = category
	for cat: String in _category_buttons:
		_category_buttons[cat].button_pressed = (cat == category)
	_rebuild_list()

func _on_initiative_toggled(initiative_id: String) -> void:
	GameStateManager.toggle_initiative(initiative_id)
	_rebuild_list()
	_update_summary()


func _rebuild_list() -> void:
	for child: Node in initiative_list.get_children():
		child.queue_free()

	var year: int = GameStateManager.state["year"]
	var config: Dictionary = DataLoader.get_config()
	var minister: Dictionary = GameStateManager.state["current_minister"]
	var efficiency: float = float(GameStateManager.state["kpis"]["efficiency"]["value"])
	var budget: float = GameStateManager.state["budget"]
	var pc: int = GameStateManager.state["political_capital"]

	var committed_rm := 0.0
	var committed_pc := 0
	for init: Dictionary in GameStateManager.state["initiatives"]:
		if init["selected"]:
			var d: float = ResourceSystem.get_minister_discount(
				minister.get("cost_modifiers"), str(init.get("category", "")))
			committed_rm += ResourceSystem.calculate_initiative_cost(
				float(init["cost_rm"]), efficiency, d, config)
			committed_pc += int(init.get("cost_pc", 0))

	var count := 0
	for init: Dictionary in GameStateManager.state["initiatives"]:
		if int(init.get("unlock_year", 9999)) > year: continue
		if _current_filter != "all" and init.get("category", "") != _current_filter: continue
		if _search_text != "" and _search_text not in str(init.get("name", "")).to_lower(): continue

		var discount: float = ResourceSystem.get_minister_discount(
			minister.get("cost_modifiers"), str(init.get("category", "")))
		var adjusted_rm: float = ResourceSystem.calculate_initiative_cost(
			float(init["cost_rm"]), efficiency, discount, config)
		var pc_cost: int = int(init.get("cost_pc", 0))

		var is_selected: bool = init.get("selected", false)
		var can_afford := true
		if not is_selected:
			can_afford = (committed_rm + adjusted_rm <= budget) and (committed_pc + pc_cost <= pc)

		initiative_list.add_child(_build_card(init, adjusted_rm, pc_cost, is_selected, can_afford))
		count += 1

	if count == 0:
		var empty := Label.new()
		empty.text = "No matching initiatives 🔍"
		empty.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		initiative_list.add_child(empty)


func _build_card(init: Dictionary, adjusted_rm: float, pc_cost: int,
		is_selected: bool, can_afford: bool) -> PanelContainer:
	var cat: String = str(init.get("category", ""))
	var cat_color: Color = CATEGORY_COLORS.get(cat, ThemeConfig.BLUE)

	# Vibrant category-colored cards
	var card_bg: Color
	var accent: Color
	if is_selected:
		card_bg = cat_color.lerp(Color.WHITE, 0.75)
		accent = cat_color
	elif can_afford:
		card_bg = cat_color.lerp(Color.WHITE, 0.88)
		accent = cat_color.lerp(Color.WHITE, 0.3)
	else:
		card_bg = Color(0.92, 0.90, 0.88)
		accent = ThemeConfig.KPI_RED.lerp(Color.WHITE, 0.5)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_left_accent_panel(card_bg, accent, 5, 8, 10))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	# Row 1: checkbox + name + duration
	var header := HBoxContainer.new()
	# Toggle button instead of checkbox — white bg, colored when selected
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.button_pressed = is_selected
	toggle.disabled = not can_afford and not is_selected
	toggle.text = "✅" if is_selected else "⬜"
	toggle.custom_minimum_size = Vector2(36, 36)
	if can_afford or is_selected:
		var bg_col := Color.WHITE if not is_selected else cat_color.lerp(Color.WHITE, 0.6)
		ThemeConfig.style_button(toggle, bg_col, cat_color.lerp(Color.WHITE, 0.7))
		toggle.add_theme_color_override("font_color", cat_color)
	else:
		ThemeConfig.style_button(toggle, Color(0.90, 0.88, 0.86), Color(0.90, 0.88, 0.86))
		toggle.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	toggle.toggled.connect(func(_p: bool): _on_initiative_toggled(init["id"]))
	header.add_child(toggle)

	var name_lbl := Label.new()
	name_lbl.text = str(init.get("name", ""))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK if (can_afford or is_selected) else ThemeConfig.TEXT_MUTED)
	header.add_child(name_lbl)

	var dur_lbl := Label.new()
	dur_lbl.text = "⏱ %d mo" % int(init.get("duration_months", 0))
	dur_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	dur_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	header.add_child(dur_lbl)
	vbox.add_child(header)

	# Row 2: costs + effects
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)

	var cost_lbl := Label.new()
	cost_lbl.text = "💰 RM %.1fM" % adjusted_rm
	if pc_cost > 0:
		cost_lbl.text += "  🏛 PC %d" % pc_cost
	cost_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	if not can_afford and not is_selected:
		cost_lbl.add_theme_color_override("font_color", ThemeConfig.KPI_RED)
	else:
		cost_lbl.add_theme_color_override("font_color", ThemeConfig.ORANGE)
	info_row.add_child(cost_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(spacer)

	var effects: Variant = init.get("effects")
	if effects is Dictionary:
		for kpi: String in effects:
			var val: float = float(effects[kpi])
			var prefix := "+" if val > 0 else ""
			var eff := Label.new()
			eff.text = "%s %s%d" % [kpi.substr(0, 3).capitalize(), prefix, int(val)]
			eff.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
			eff.add_theme_color_override("font_color", ThemeConfig.get_effect_color(val))
			info_row.add_child(eff)
	vbox.add_child(info_row)

	return panel


func _update_summary() -> void:
	var selected := GameStateManager.get_selected_initiatives()
	var config: Dictionary = DataLoader.get_config()
	var minister: Dictionary = GameStateManager.state["current_minister"]
	var efficiency: float = float(GameStateManager.state["kpis"]["efficiency"]["value"])

	var total_rm := 0.0
	var total_pc := 0
	var projected := { "quality": 0, "equity": 0, "access": 0, "unity": 0, "efficiency": 0 }

	for init: Dictionary in selected:
		var discount: float = ResourceSystem.get_minister_discount(
			minister.get("cost_modifiers"), str(init.get("category", "")))
		total_rm += ResourceSystem.calculate_initiative_cost(
			float(init["cost_rm"]), efficiency, discount, config)
		total_pc += int(init.get("cost_pc", 0))
		var effects: Variant = init.get("effects")
		if effects is Dictionary:
			for kpi: String in effects:
				if projected.has(kpi):
					projected[kpi] += int(effects[kpi])

	summary_label.text = "🎯 Selected: %d  |  💰 RM %.1f / %.1f  |  🏛 PC %d / %d" % [
		selected.size(), total_rm, GameStateManager.state["budget"],
		total_pc, GameStateManager.state["political_capital"]]

	var proj_parts: Array = []
	for kpi: String in projected:
		if projected[kpi] != 0:
			var prefix := "+" if projected[kpi] > 0 else ""
			proj_parts.append("%s %s%d" % [kpi.capitalize(), prefix, projected[kpi]])
	projected_label.text = "📊 Projected: " + (", ".join(proj_parts) if proj_parts.size() > 0 else "—")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()
