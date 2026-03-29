## Tutorial — Step-by-step onboarding for first-time players.
## Shows contextual tips at key moments during the first year.
extends Control

signal step_completed

@onready var tutorial_panel: PanelContainer = %TutorialPanel
@onready var tutorial_title: Label = %TutorialTitle
@onready var tutorial_text: Label = %TutorialText
@onready var tutorial_icon: Label = %TutorialIcon
@onready var tutorial_btn: Button = %TutorialBtn
@onready var skip_btn: Button = %TutorialSkipBtn
@onready var step_label: Label = %TutorialStepLabel

const SAVE_PATH := "user://tutorial_complete.json"

var _current_step: int = -1
var _is_complete: bool = false
var _waiting_for_action: bool = false

## Tutorial steps — triggered at specific game moments
const STEPS := [
	{
		"id": "welcome",
		"trigger": "game_start",
		"icon": "🎓",
		"title": "Welcome, Director!",
		"text": "You've just been appointed Director of DAPU — the unit coordinating the nation's education reform.\n\nYour mission: guide education transformation over 13 years (2013-2025). Every decision matters!",
		"button": "Let's begin! 🚀",
	},
	{
		"id": "kpis",
		"trigger": "game_start",
		"icon": "📊",
		"title": "Your 5 KPIs",
		"text": "These 5 bars on the left are your Key Performance Indicators:\n\n📚 Quality — Teaching and learning standards\n⚖️ Equity — Fairness between urban and rural\n🌐 Access — School facilities and connectivity\n🤝 Unity — Public satisfaction\n⚙️ Efficiency — Budget management\n\nKeep them all healthy! Average 65+ to win.",
		"button": "Got it! 📊",
	},
	{
		"id": "budget",
		"trigger": "game_start",
		"icon": "💰",
		"title": "Budget & Political Capital",
		"text": "You have two resources:\n\n💰 Budget (RM) — Money to fund initiatives. Resets yearly based on performance.\n🏛 Political Capital (PC) — Your influence. Spent on tough decisions. Regenerates from public Unity.\n\nSpend wisely — if you have too much budget left in October, next year's budget gets cut!",
		"button": "I'll manage carefully 💰",
	},
	{
		"id": "select_initiatives",
		"trigger": "game_start",
		"icon": "🎯",
		"title": "Select Your Initiatives",
		"text": "Click the green '🎯 SELECT INITIATIVES' button to choose what to fund this year.\n\nEach initiative costs Budget and PC, takes time to complete, and affects your KPIs. Pick a good mix!\n\nTip: Filter by category to find what you need.",
		"button": "Time to plan! 🎯",
	},
	{
		"id": "year_running",
		"trigger": "year_started",
		"icon": "⏱️",
		"title": "The Year Begins!",
		"text": "Months are now ticking by — each month is 30 seconds in real time.\n\n⏸ Pause — Stop time to think\n⚡ Speed — Go faster (up to 5x)\n☰ Menu — Save, load, or check achievements\n\nWatch your initiatives progress and keep an eye on the KPIs!",
		"button": "Here we go! ⏱️",
	},
	{
		"id": "scenario",
		"trigger": "scenario",
		"icon": "🚨",
		"title": "A Scenario Has Appeared!",
		"text": "Scenarios are crisis events that demand your attention. Read the context carefully and choose wisely.\n\nEach choice has different costs and KPI effects. Some choices even affect future scenarios!\n\nIf you can't afford any option, a penalty is applied automatically.\n\nTip: Press 1, 2, or 3 to quickly select a choice.",
		"button": "I'll handle this! 🚨",
	},
	{
		"id": "mid_year",
		"trigger": "mid_year",
		"icon": "📋",
		"title": "Mid-Year Check-In",
		"text": "Every June, you get a mid-year review showing how your KPIs have changed since January.\n\nUse this to assess if your strategy is working. Are your initiatives on track?",
		"button": "Good to know! 📋",
	},
	{
		"id": "year_end",
		"trigger": "year_end",
		"icon": "📅",
		"title": "Year-End Summary",
		"text": "Each year ends with a report card:\n\n✅ Completed initiatives give full KPI effects\n⚠️ Partial (50%+) gives half effects + Unity penalty\n❌ Failed (<50%) costs you PC and Unity\n\nKPIs also decay naturally — Access drops 2/year, Quality drops 1/year. You must actively improve them!",
		"button": "Onto the next year! 📅",
	},
	{
		"id": "shifts",
		"trigger": "year_end",
		"icon": "⭐",
		"title": "Strategic Shifts",
		"text": "Notice the Shift cards below your initiatives? Each initiative gives XP to a linked strategic shift.\n\nShifts level up (max level 5) and give a permanent yearly KPI bonus. Level 3 in a shift = +3 to that KPI every year!\n\nThink long-term — early shift investments compound over 13 years.",
		"button": "Strategic! ⭐",
	},
	{
		"id": "minister",
		"trigger": "minister_change",
		"icon": "🏛️",
		"title": "New Minister!",
		"text": "Ministers change every few years, each with:\n\n🎯 An agenda — Meet their KPI target for bonus PC\n💰 Cost modifiers — Discounts on certain initiative categories\n📈 KPI bonuses — Yearly boost to their priority KPI\n\nAdapt your strategy to each minister's priorities!",
		"button": "I'll adapt! 🏛️",
	},
	{
		"id": "complete",
		"trigger": "year_end",
		"icon": "🎉",
		"title": "You're Ready!",
		"text": "That's everything you need to know! From here:\n\n🎮 Play through all 13 years to get your final grade\n🏆 Unlock achievements along the way\n💾 Save anytime from the ☰ menu\n⚡ Speed up with the speed button\n\nGood luck, Director! The nation's education is in your hands.",
		"button": "Let's transform education! 🎉",
	},
]


func _ready() -> void:
	tutorial_btn.pressed.connect(_on_next)
	skip_btn.pressed.connect(_on_skip)
	visible = false
	_load_state()

	ThemeConfig.style_button(tutorial_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	tutorial_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	ThemeConfig.style_button(skip_btn, ThemeConfig.BTN_DEFAULT, ThemeConfig.BTN_DEFAULT_HOVER)
	skip_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)

	tutorial_title.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	tutorial_text.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	tutorial_text.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	step_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
	step_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	tutorial_icon.add_theme_font_size_override("font_size", 48)

	add_theme_stylebox_override("panel",
		ThemeConfig.make_panel_stylebox(Color(0.0, 0.0, 0.0, 0.50), 0, 0))

	var card: PanelContainer = tutorial_title.get_parent().get_parent()
	card.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.YELLOW, 16, 20))


## Check if tutorial is complete.
func is_complete() -> bool:
	return _is_complete


## Trigger a tutorial step by event name. Shows the next matching step.
func trigger(event: String) -> void:
	if _is_complete:
		return

	# Find next step matching this trigger
	for i in range(_current_step + 1, STEPS.size()):
		if STEPS[i]["trigger"] == event:
			_show_step(i)
			return


func _show_step(index: int) -> void:
	_current_step = index
	var step: Dictionary = STEPS[index]

	tutorial_icon.text = str(step["icon"])
	tutorial_title.text = str(step["title"])
	tutorial_title.add_theme_color_override("font_color", ThemeConfig.BLUE)
	tutorial_text.text = str(step["text"])
	tutorial_btn.text = str(step["button"])
	step_label.text = "Step %d of %d" % [index + 1, STEPS.size()]
	skip_btn.text = "Skip Tutorial" if index < STEPS.size() - 1 else ""
	skip_btn.visible = (index < STEPS.size() - 1)

	visible = true


func _on_next() -> void:
	visible = false

	if _current_step >= STEPS.size() - 1:
		_complete_tutorial()
	else:
		step_completed.emit()


func _on_skip() -> void:
	visible = false
	_complete_tutorial()


func _complete_tutorial() -> void:
	_is_complete = true
	_save_state()


func _load_state() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				_is_complete = bool(json.data.get("complete", false))
				_current_step = int(json.data.get("step", -1))
			file.close()


func _save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"complete": _is_complete,
			"step": _current_step,
		}, "\t"))
		file.close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_next()
		get_viewport().set_input_as_handled()
