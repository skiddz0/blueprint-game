## Theme Config — Central color and style constants for the game UI.
class_name ThemeConfig

# -- Colors --------------------------------------------------------------------
const BG_DARK := Color(0.12, 0.13, 0.15)
const BG_PANEL := Color(0.16, 0.18, 0.20)
const BG_CARD := Color(0.20, 0.22, 0.25)
const BG_HEADER := Color(0.10, 0.11, 0.13)
const BG_MODAL := Color(0.08, 0.09, 0.10, 0.95)

const TEXT_PRIMARY := Color(0.93, 0.93, 0.93)
const TEXT_SECONDARY := Color(0.65, 0.65, 0.70)
const TEXT_MUTED := Color(0.45, 0.45, 0.50)

const ACCENT_BLUE := Color(0.25, 0.55, 0.85)
const ACCENT_GOLD := Color(0.85, 0.70, 0.25)

const KPI_RED := Color(0.85, 0.25, 0.25)
const KPI_ORANGE := Color(0.90, 0.60, 0.15)
const KPI_GREEN := Color(0.25, 0.75, 0.35)

const BUDGET_COLOR := Color(0.30, 0.75, 0.45)
const PC_COLOR := Color(0.70, 0.50, 0.85)

const BTN_PRIMARY := Color(0.22, 0.50, 0.78)
const BTN_PRIMARY_HOVER := Color(0.28, 0.58, 0.88)
const BTN_DANGER := Color(0.75, 0.25, 0.25)
const BTN_DEFAULT := Color(0.25, 0.27, 0.30)
const BTN_DEFAULT_HOVER := Color(0.30, 0.33, 0.37)

const POSITIVE := Color(0.30, 0.80, 0.40)
const NEGATIVE := Color(0.85, 0.30, 0.30)

# -- Font sizes ----------------------------------------------------------------
const FONT_TITLE := 24
const FONT_HEADER := 18
const FONT_BODY := 14
const FONT_SMALL := 12
const FONT_TINY := 11

# -- Helpers -------------------------------------------------------------------

static func get_kpi_color(value: float) -> Color:
	if value < 45.0:
		return KPI_RED
	elif value < 65.0:
		return KPI_ORANGE
	return KPI_GREEN


static func get_effect_color(value: float) -> Color:
	if value > 0:
		return POSITIVE
	elif value < 0:
		return NEGATIVE
	return TEXT_SECONDARY


static func make_panel_stylebox(color: Color, corner_radius: int = 6, padding: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func make_button_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func style_button(btn: Button, color: Color = BTN_DEFAULT, hover: Color = BTN_DEFAULT_HOVER) -> void:
	btn.add_theme_stylebox_override("normal", make_button_stylebox(color))
	btn.add_theme_stylebox_override("hover", make_button_stylebox(hover))
	btn.add_theme_stylebox_override("pressed", make_button_stylebox(color.darkened(0.2)))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", TEXT_PRIMARY)


static func style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.18)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
