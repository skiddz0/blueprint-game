## Scenario Modal — Colorful, playful scenario decisions.
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

const CATEGORY_COLORS := {
	"political_event": Color(0.25, 0.52, 0.95),
	"crisis_response": Color(0.92, 0.28, 0.25),
	"policy_debate": Color(0.20, 0.72, 0.35),
	"implementation_challenge": Color(0.95, 0.55, 0.15),
	"pandemic_response": Color(0.58, 0.35, 0.85),
	"performance_review": Color(0.15, 0.75, 0.85),
	"international_benchmark": Color(0.92, 0.45, 0.65),
	"strategic_pivot": Color(0.98, 0.78, 0.15),
	"milestone_review": Color(0.55, 0.38, 0.25),
}


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	cannot_afford_btn.pressed.connect(_on_cannot_afford_continue)

	add_theme_stylebox_override("panel", ThemeConfig.make_panel_stylebox(
		Color(0.0, 0.0, 0.0, 0.50), 0, 0))
	title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	category_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_SECTION)
	ThemeConfig.style_button(continue_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	continue_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	ThemeConfig.style_button(cannot_afford_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)
	context_label.add_theme_color_override("default_color", ThemeConfig.TEXT_BODY)
	context_label.add_theme_font_size_override("normal_font_size", ThemeConfig.FONT_BODY)
	outcome_text.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	outcome_text.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	headline_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	headline_label.add_theme_color_override("font_color", ThemeConfig.BLUE)
	cannot_afford_text.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)

	# Outcome/cannot-afford panel backgrounds
	outcome_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_WHITE, ThemeConfig.GREEN, 10, 12))
	cannot_afford_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_WHITE, ThemeConfig.RED, 10, 12))

	# Card panel background
	var card_panel: PanelContainer = title_label.get_parent().get_parent()
	card_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.ORANGE, 16, 16))


func show_scenario(scenario: Dictionary) -> void:
	_current_scenario = scenario
	_selected_choice = {}

	var cat: String = str(scenario.get("category", ""))
	var cat_color: Color = CATEGORY_COLORS.get(cat, ThemeConfig.BLUE)

	title_label.text = str(scenario.get("title", ""))
	title_label.add_theme_color_override("font_color", cat_color)
	category_label.text = cat.replace("_", " ").to_upper()
	category_label.add_theme_color_override("font_color", cat_color.lerp(ThemeConfig.TEXT_BODY, 0.3))
	context_label.text = str(scenario.get("context", ""))

	outcome_panel.visible = false
	cannot_afford_panel.visible = false
	outcome_text.text = ""
	headline_label.text = ""

	var budget: float = GameStateManager.state["budget"]
	var pc: int = GameStateManager.state["political_capital"]

	if not ScenarioEngine.can_afford_any_choice(scenario, budget, pc):
		_show_cannot_afford(scenario)
		return

	_build_choices(scenario, budget, pc)
	choices_container.visible = true


func _build_choices(scenario: Dictionary, budget: float, pc: int) -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()
	var choices: Array = scenario.get("choices", [])
	var choice_colors := [ThemeConfig.BLUE, ThemeConfig.GREEN, ThemeConfig.PURPLE, ThemeConfig.ORANGE]
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var affordable := ScenarioEngine.can_afford_choice(choice, budget, pc)
		var col: Color = choice_colors[i % choice_colors.size()]
		choices_container.add_child(_build_choice_card(choice, affordable, i + 1, col))


func _build_choice_card(choice: Dictionary, affordable: bool, index: int, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	if affordable:
		panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_card(ThemeConfig.BG_WHITE, accent, 12, 12))
	else:
		panel.add_theme_stylebox_override("panel",
			ThemeConfig.make_card(Color(0.94, 0.93, 0.91), ThemeConfig.BORDER_LIGHT, 12, 12))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	var key_hint := Label.new()
	key_hint.text = "[%d]" % index
	key_hint.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	key_hint.add_theme_color_override("font_color", accent if affordable else ThemeConfig.TEXT_MUTED)
	header.add_child(key_hint)
	var label_text := Label.new()
	label_text.text = "  " + str(choice.get("label", ""))
	label_text.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	label_text.add_theme_color_override("font_color", accent if affordable else ThemeConfig.TEXT_MUTED)
	header.add_child(label_text)
	vbox.add_child(header)

	# Description
	var desc := Label.new()
	desc.text = str(choice.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	desc.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK if affordable else ThemeConfig.TEXT_MUTED)
	vbox.add_child(desc)

	# Cost + Effects
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	var costs: Dictionary = choice.get("costs", {})
	var cost_parts: Array = []
	if costs.get("budget", 0) > 0: cost_parts.append("💰 RM %dM" % int(costs["budget"]))
	if costs.get("pc", 0) > 0: cost_parts.append("🏛 PC %d" % int(costs["pc"]))
	var cost_lbl := Label.new()
	cost_lbl.text = ", ".join(cost_parts) if cost_parts.size() > 0 else "Free! 🎉"
	cost_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	cost_lbl.add_theme_color_override("font_color", ThemeConfig.KPI_RED if not affordable else ThemeConfig.ORANGE)
	info_row.add_child(cost_lbl)

	var effects: Variant = choice.get("effects")
	if effects is Dictionary:
		for kpi: String in effects:
			var val: float = float(effects[kpi])
			var prefix := "+" if val > 0 else ""
			var eff := Label.new()
			eff.text = "%s %s%d" % [kpi.capitalize(), prefix, int(val)]
			eff.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
			eff.add_theme_color_override("font_color", ThemeConfig.get_effect_color(val))
			info_row.add_child(eff)
	vbox.add_child(info_row)

	if affordable:
		var btn := Button.new()
		btn.text = "Choose This! ✨"
		ThemeConfig.style_button(btn, accent, accent.lightened(0.2))
		btn.pressed.connect(_on_choice_selected.bind(choice))
		vbox.add_child(btn)

	return panel


func _on_choice_selected(choice: Dictionary) -> void:
	_selected_choice = choice
	choices_container.visible = false
	outcome_text.text = str(choice.get("outcome_text", ""))
	outcome_text.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	headline_label.text = "📰 " + str(choice.get("headline", ""))
	headline_label.add_theme_color_override("font_color", ThemeConfig.BLUE)
	outcome_panel.visible = true

func _on_continue() -> void:
	outcome_panel.visible = false
	GameStateManager.resolve_scenario(str(_selected_choice.get("id", "")))
	visible = false

func _show_cannot_afford(scenario: Dictionary) -> void:
	choices_container.visible = false
	var penalty: Dictionary = scenario.get("cannot_afford_penalty", {})
	cannot_afford_text.text = str(penalty.get("outcome_text", "You cannot afford any option! 😰"))
	cannot_afford_text.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	headline_label.text = "📰 " + str(penalty.get("headline", ""))
	headline_label.add_theme_color_override("font_color", ThemeConfig.RED)
	cannot_afford_panel.visible = true

func _on_cannot_afford_continue() -> void:
	cannot_afford_panel.visible = false
	GameStateManager.apply_cannot_afford_penalty(_current_scenario)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if not (event is InputEventKey) or not event.pressed: return
	if outcome_panel.visible and event.keycode == KEY_ENTER:
		_on_continue(); return
	var choices: Array = _current_scenario.get("choices", [])
	var budget: float = GameStateManager.state["budget"]
	var pc: int = GameStateManager.state["political_capital"]
	var key_map := { KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3 }
	if key_map.has(event.keycode):
		var idx: int = key_map[event.keycode]
		if idx < choices.size() and ScenarioEngine.can_afford_choice(choices[idx], budget, pc):
			_on_choice_selected(choices[idx])
