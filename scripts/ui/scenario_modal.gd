## Scenario Modal — Full-screen overlay for scenario decision events.
## See: design/gdd/scenario-modal-ui.md
extends Control

@onready var title_label: Label = %ScenarioTitleLabel
@onready var category_label: Label = %ScenarioCategoryLabel
@onready var context_label: RichTextLabel = %ContextLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var outcome_panel: PanelContainer = %OutcomePanel
@onready var outcome_text: Label = %OutcomeText
@onready var headline_label: Label = %HeadlineLabel
@onready var continue_btn: Button = %ContinueBtn
@onready var cannot_afford_panel: PanelContainer = %CannotAffordPanel
@onready var cannot_afford_text: Label = %CannotAffordText
@onready var cannot_afford_btn: Button = %CannotAffordBtn

var _current_scenario: Dictionary = {}
var _selected_choice: Dictionary = {}


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	cannot_afford_btn.pressed.connect(_on_cannot_afford_continue)

	# Styling
	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(ThemeConfig.BG_MODAL, 0, 0))
	title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	title_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	category_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	category_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	ThemeConfig.style_button(continue_btn, ThemeConfig.BTN_PRIMARY, ThemeConfig.BTN_PRIMARY_HOVER)
	ThemeConfig.style_button(cannot_afford_btn, ThemeConfig.BTN_DANGER)

	outcome_text.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	headline_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	headline_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)


func show_scenario(scenario: Dictionary) -> void:
	_current_scenario = scenario
	_selected_choice = {}

	title_label.text = str(scenario.get("title", ""))
	category_label.text = str(scenario.get("category", "")).replace("_", " ").to_upper()
	context_label.text = str(scenario.get("context", ""))

	outcome_panel.visible = false
	cannot_afford_panel.visible = false

	var budget: float = GameStateManager.state["budget"]
	var pc: int = GameStateManager.state["political_capital"]
	var can_afford: bool = ScenarioEngine.can_afford_any_choice(scenario, budget, pc)

	if not can_afford:
		_show_cannot_afford(scenario)
		return

	_build_choices(scenario, budget, pc)
	choices_container.visible = true


func _build_choices(scenario: Dictionary, budget: float, pc: int) -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()

	for choice: Dictionary in scenario.get("choices", []):
		var affordable: bool = ScenarioEngine.can_afford_choice(choice, budget, pc)
		var card := _build_choice_card(choice, affordable)
		choices_container.add_child(card)


func _build_choice_card(choice: Dictionary, affordable: bool) -> PanelContainer:
	var bg := ThemeConfig.BG_CARD if affordable else ThemeConfig.BG_CARD.darkened(0.3)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(bg, 6, 10))

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	# Choice label (A, B, C)
	var label_text := Label.new()
	label_text.text = str(choice.get("label", ""))
	label_text.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	if affordable:
		label_text.add_theme_color_override("font_color", ThemeConfig.ACCENT_BLUE)
	else:
		label_text.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	vbox.add_child(label_text)

	# Description
	var desc := Label.new()
	desc.text = str(choice.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	if affordable:
		desc.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	else:
		desc.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	vbox.add_child(desc)

	# Cost + Effects row
	var info_row := HBoxContainer.new()

	var costs: Dictionary = choice.get("costs", {})
	var costs_parts: Array = []
	if costs.get("budget", 0) > 0:
		costs_parts.append("💰 RM %dM" % int(costs["budget"]))
	if costs.get("pc", 0) > 0:
		costs_parts.append("🏛 PC %d" % int(costs["pc"]))

	var cost_label := Label.new()
	cost_label.text = ", ".join(costs_parts) if costs_parts.size() > 0 else "Free"
	cost_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
	if not affordable:
		cost_label.add_theme_color_override("font_color", ThemeConfig.KPI_RED)
	else:
		cost_label.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)
	info_row.add_child(cost_label)

	var sep := Label.new()
	sep.text = "    "
	info_row.add_child(sep)

	var effects: Variant = choice.get("effects")
	if effects is Dictionary:
		for kpi: String in effects:
			var val: float = float(effects[kpi])
			var prefix := "+" if val > 0 else ""
			var eff_label := Label.new()
			eff_label.text = "%s %s%d  " % [kpi.capitalize(), prefix, int(val)]
			eff_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
			eff_label.add_theme_color_override("font_color", ThemeConfig.get_effect_color(val))
			info_row.add_child(eff_label)

	vbox.add_child(info_row)

	# Select button
	var select_btn := Button.new()
	if affordable:
		select_btn.text = "Choose This"
		ThemeConfig.style_button(select_btn, ThemeConfig.BTN_PRIMARY, ThemeConfig.BTN_PRIMARY_HOVER)
	else:
		select_btn.text = "Can't Afford"
		select_btn.disabled = true
		ThemeConfig.style_button(select_btn, ThemeConfig.BG_CARD)
	select_btn.pressed.connect(_on_choice_selected.bind(choice))
	vbox.add_child(select_btn)

	return panel


func _on_choice_selected(choice: Dictionary) -> void:
	_selected_choice = choice
	choices_container.visible = false

	outcome_text.text = str(choice.get("outcome_text", ""))
	headline_label.text = "📰 " + str(choice.get("headline", ""))
	outcome_panel.visible = true


func _on_continue() -> void:
	outcome_panel.visible = false
	GameStateManager.resolve_scenario(_selected_choice.get("id", ""))
	visible = false


func _show_cannot_afford(scenario: Dictionary) -> void:
	choices_container.visible = false
	var penalty: Dictionary = scenario.get("cannot_afford_penalty", {})
	cannot_afford_text.text = str(penalty.get("outcome_text", "You cannot afford any option."))
	headline_label.text = "📰 " + str(penalty.get("headline", ""))
	cannot_afford_panel.visible = true


func _on_cannot_afford_continue() -> void:
	cannot_afford_panel.visible = false
	GameStateManager.apply_cannot_afford_penalty(_current_scenario)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		var choices: Array = _current_scenario.get("choices", [])
		var budget: float = GameStateManager.state["budget"]
		var pc: int = GameStateManager.state["political_capital"]
		if event.keycode == KEY_1 and choices.size() >= 1:
			if ScenarioEngine.can_afford_choice(choices[0], budget, pc):
				_on_choice_selected(choices[0])
		elif event.keycode == KEY_2 and choices.size() >= 2:
			if ScenarioEngine.can_afford_choice(choices[1], budget, pc):
				_on_choice_selected(choices[1])
		elif event.keycode == KEY_3 and choices.size() >= 3:
			if ScenarioEngine.can_afford_choice(choices[2], budget, pc):
				_on_choice_selected(choices[2])
		elif event.keycode == KEY_ENTER and outcome_panel.visible:
			_on_continue()
