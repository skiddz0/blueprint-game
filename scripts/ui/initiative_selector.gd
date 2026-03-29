## Initiative Selector — January planning modal for selecting initiatives.
## See: design/gdd/initiative-selector-ui.md
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
	"all": "All", "infrastructure": "🏗 Infra", "human_capital": "👩‍🏫 Human",
	"policy": "📜 Policy", "technology": "💻 Tech", "community": "🤝 Community",
	"governance": "🏛 Gov"
}


func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	search_field.text_changed.connect(_on_search_changed)

	# Style the modal background
	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(ThemeConfig.BG_MODAL, 0, 0))

	# Style buttons
	ThemeConfig.style_button(confirm_btn, ThemeConfig.BTN_PRIMARY, ThemeConfig.BTN_PRIMARY_HOVER)
	ThemeConfig.style_button(cancel_btn)

	# Style labels
	summary_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	summary_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	projected_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	projected_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)

	# Build category filter buttons
	for cat: String in CATEGORIES:
		var btn := Button.new()
		btn.text = CATEGORY_LABELS.get(cat, cat)
		btn.toggle_mode = true
		btn.button_pressed = (cat == "all")
		btn.pressed.connect(_on_category_pressed.bind(cat))
		ThemeConfig.style_button(btn)
		category_tabs.add_child(btn)
		_category_buttons[cat] = btn


func open_selector() -> void:
	_current_filter = "all"
	_search_text = ""
	search_field.text = ""
	# Reset category button states
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

	# Calculate committed costs for affordability
	var committed_rm := 0.0
	var committed_pc := 0
	for init: Dictionary in GameStateManager.state["initiatives"]:
		if init["selected"]:
			var d: float = ResourceSystem.get_minister_discount(
				minister.get("cost_modifiers"), init.get("category", ""))
			committed_rm += ResourceSystem.calculate_initiative_cost(
				float(init["cost_rm"]), efficiency, d, config)
			committed_pc += int(init.get("cost_pc", 0))

	var count := 0
	for init: Dictionary in GameStateManager.state["initiatives"]:
		if int(init.get("unlock_year", 9999)) > year:
			continue
		if _current_filter != "all" and init.get("category", "") != _current_filter:
			continue
		if _search_text != "" and _search_text not in str(init.get("name", "")).to_lower():
			continue

		var discount: float = ResourceSystem.get_minister_discount(
			minister.get("cost_modifiers"), init.get("category", ""))
		var adjusted_rm: float = ResourceSystem.calculate_initiative_cost(
			float(init["cost_rm"]), efficiency, discount, config)
		var pc_cost: int = int(init.get("cost_pc", 0))

		# Affordability: can we afford this if not already selected?
		var is_selected: bool = init.get("selected", false)
		var can_afford := true
		if not is_selected:
			can_afford = (committed_rm + adjusted_rm <= budget) and (committed_pc + pc_cost <= pc)

		var card := _build_initiative_card(init, adjusted_rm, pc_cost, is_selected, can_afford)
		initiative_list.add_child(card)
		count += 1

	if count == 0:
		var empty := Label.new()
		empty.text = "No matching initiatives"
		empty.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		initiative_list.add_child(empty)


func _build_initiative_card(init: Dictionary, adjusted_rm: float, pc_cost: int,
		is_selected: bool, can_afford: bool) -> PanelContainer:
	var bg_color := ThemeConfig.BG_CARD if not is_selected else ThemeConfig.ACCENT_BLUE.darkened(0.6)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(bg_color, 4, 6))

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	# Row 1: checkbox + name
	var header := HBoxContainer.new()
	var checkbox := CheckBox.new()
	checkbox.button_pressed = is_selected
	checkbox.disabled = not can_afford and not is_selected
	checkbox.toggled.connect(func(_p: bool): _on_initiative_toggled(init["id"]))
	header.add_child(checkbox)

	var name_label := Label.new()
	name_label.text = str(init.get("name", ""))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	if can_afford or is_selected:
		name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	else:
		name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	header.add_child(name_label)

	# Duration badge
	var dur_label := Label.new()
	dur_label.text = "%d mo" % int(init.get("duration_months", 0))
	dur_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	dur_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	header.add_child(dur_label)

	vbox.add_child(header)

	# Row 2: costs + effects
	var info_row := HBoxContainer.new()

	var cost_label := Label.new()
	cost_label.text = "💰 RM %.1fM" % adjusted_rm
	if pc_cost > 0:
		cost_label.text += "  🏛 PC %d" % pc_cost
	cost_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	if not can_afford and not is_selected:
		cost_label.add_theme_color_override("font_color", ThemeConfig.KPI_RED)
	else:
		cost_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	info_row.add_child(cost_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(spacer)

	# Effects
	var effects: Variant = init.get("effects")
	if effects is Dictionary:
		for kpi: String in effects:
			var val: float = float(effects[kpi])
			var eff_label := Label.new()
			var prefix := "+" if val > 0 else ""
			eff_label.text = "%s %s%d" % [kpi.substr(0, 3).capitalize(), prefix, int(val)]
			eff_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
			eff_label.add_theme_color_override("font_color", ThemeConfig.get_effect_color(val))
			info_row.add_child(eff_label)

			var sep := Label.new()
			sep.text = "  "
			info_row.add_child(sep)

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
			minister.get("cost_modifiers"), init.get("category", ""))
		total_rm += ResourceSystem.calculate_initiative_cost(
			float(init["cost_rm"]), efficiency, discount, config)
		total_pc += int(init.get("cost_pc", 0))
		var effects: Variant = init.get("effects")
		if effects is Dictionary:
			for kpi: String in effects:
				if projected.has(kpi):
					projected[kpi] += int(effects[kpi])

	summary_label.text = "Selected: %d  |  💰 RM %.1f / %.1f  |  🏛 PC %d / %d" % [
		selected.size(), total_rm, GameStateManager.state["budget"],
		total_pc, GameStateManager.state["political_capital"]
	]

	var proj_parts: Array = []
	for kpi: String in projected:
		if projected[kpi] != 0:
			var prefix := "+" if projected[kpi] > 0 else ""
			proj_parts.append("%s %s%d" % [kpi.capitalize(), prefix, projected[kpi]])
	projected_label.text = "Projected KPIs: " + (", ".join(proj_parts) if proj_parts.size() > 0 else "—")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()
