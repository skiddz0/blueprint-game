## Theme Config — Playful, colorful UI inspired by Mario + strategy games.
## Serious topic, not-serious presentation.
class_name ThemeConfig

# -- Colors: Warm, vibrant, approachable ------------------------------------
const BG_CREAM := Color(0.96, 0.94, 0.88)        # Warm cream background
const BG_LIGHT := Color(0.98, 0.96, 0.92)         # Card backgrounds
const BG_WHITE := Color(1.0, 0.98, 0.95)          # Bright card
const BG_HEADER := Color(0.22, 0.38, 0.65)        # Deep blue header
const BG_SIDEBAR := Color(0.95, 0.92, 0.86)       # Warm sidebar
const BG_MODAL := Color(0.0, 0.0, 0.0, 0.5)       # Semi-transparent overlay
const BG_CARD := Color(1.0, 0.99, 0.96)           # White-ish card
const BG_CARD_SELECTED := Color(0.88, 0.94, 1.0)  # Light blue selected

const TEXT_DARK := Color(0.18, 0.16, 0.22)        # Near-black text
const TEXT_BODY := Color(0.30, 0.28, 0.35)        # Body text
const TEXT_SECONDARY := Color(0.38, 0.36, 0.43)   # Muted text (WCAG AA compliant)
const TEXT_MUTED := Color(0.50, 0.48, 0.55)       # Disabled/very muted (still readable)
const TEXT_HEADER := Color(0.40, 0.38, 0.50)      # Section headers
const TEXT_WHITE := Color(1.0, 1.0, 1.0)          # White text on dark bg
const TEXT_PRIMARY := TEXT_DARK                     # Alias

# Vibrant palette
const BLUE := Color(0.25, 0.52, 0.95)             # Mario blue
const BLUE_LIGHT := Color(0.55, 0.75, 1.0)
const RED := Color(0.92, 0.28, 0.25)              # Mario red
const RED_LIGHT := Color(1.0, 0.60, 0.55)
const GREEN := Color(0.20, 0.72, 0.35)            # Luigi green
const GREEN_LIGHT := Color(0.55, 0.88, 0.60)
const YELLOW := Color(0.98, 0.78, 0.15)           # Star yellow
const YELLOW_LIGHT := Color(1.0, 0.90, 0.50)
const ORANGE := Color(0.95, 0.55, 0.15)           # Warm orange
const PURPLE := Color(0.58, 0.35, 0.85)           # Royal purple
const PURPLE_LIGHT := Color(0.75, 0.60, 0.95)
const CYAN := Color(0.15, 0.75, 0.85)             # Bright cyan
const PINK := Color(0.92, 0.45, 0.65)             # Playful pink
const BROWN := Color(0.55, 0.38, 0.25)            # Warm brown

# KPI colors — vibrant
const KPI_RED := Color(0.92, 0.25, 0.22)
const KPI_ORANGE := Color(0.95, 0.58, 0.12)
const KPI_GREEN := Color(0.18, 0.75, 0.32)

# Resource colors
const BUDGET_COLOR := Color(0.20, 0.65, 0.38)
const PC_COLOR := Color(0.58, 0.35, 0.85)

# Accent aliases
const ACCENT_BLUE := BLUE
const ACCENT_GOLD := YELLOW
const ACCENT_CYAN := CYAN

# Button colors
const BTN_PRIMARY := BLUE
const BTN_PRIMARY_HOVER := Color(0.32, 0.58, 1.0)
const BTN_DANGER := RED
const BTN_DANGER_HOVER := Color(1.0, 0.38, 0.35)
const BTN_SUCCESS := GREEN
const BTN_SUCCESS_HOVER := Color(0.28, 0.80, 0.42)
const BTN_DEFAULT := Color(0.82, 0.80, 0.76)
const BTN_DEFAULT_HOVER := Color(0.88, 0.86, 0.82)
const BTN_YELLOW := YELLOW
const BTN_YELLOW_HOVER := Color(1.0, 0.85, 0.25)

const POSITIVE := Color(0.15, 0.70, 0.30)
const NEGATIVE := Color(0.90, 0.25, 0.22)
const NEUTRAL := Color(0.55, 0.52, 0.58)

const BORDER_LIGHT := Color(0.82, 0.78, 0.72)
const BORDER_ACCENT := BLUE
const BORDER_SUBTLE := Color(0.88, 0.85, 0.80)

# -- Font sizes ----------------------------------------------------------------
const FONT_TITLE := 28
const FONT_SUBTITLE := 20
const FONT_HEADER := 16
const FONT_BODY := 14
const FONT_SMALL := 14
const FONT_TINY := 13
const FONT_SECTION := 15

# -- Helpers -------------------------------------------------------------------

static func get_kpi_color(value: float) -> Color:
	if value < 45.0: return KPI_RED
	elif value < 65.0: return KPI_ORANGE
	return KPI_GREEN


static func get_effect_color(value: float) -> Color:
	if value > 0: return POSITIVE
	elif value < 0: return NEGATIVE
	return NEUTRAL


static func make_panel_stylebox(color: Color, corner_radius: int = 12, padding: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func make_card(color: Color = BG_CARD, border_color: Color = BORDER_LIGHT,
		corner_radius: int = 12, padding: int = 10) -> StyleBoxFlat:
	var style := make_panel_stylebox(color, corner_radius, padding)
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	# Subtle shadow
	style.shadow_color = Color(0, 0, 0, 0.08)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


static func make_bordered_panel(color: Color, border_color: Color, border_width: int = 2,
		corner_radius: int = 12, padding: int = 10) -> StyleBoxFlat:
	var style := make_panel_stylebox(color, corner_radius, padding)
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	return style


static func make_left_accent_panel(color: Color, accent_color: Color, accent_width: int = 4,
		corner_radius: int = 10, padding: int = 10) -> StyleBoxFlat:
	var style := make_panel_stylebox(color, corner_radius, padding)
	style.border_color = accent_color
	style.border_width_left = accent_width
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style


static func style_button(btn: Button, color: Color = BTN_DEFAULT, hover: Color = BTN_DEFAULT_HOVER) -> void:
	var is_dark_bg := color.v < 0.6
	var text_color := TEXT_WHITE if is_dark_bg else TEXT_DARK

	var normal := make_panel_stylebox(color, 10, 12)
	normal.shadow_color = Color(0, 0, 0, 0.12)
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", normal)

	var hov := make_panel_stylebox(hover, 10, 12)
	hov.shadow_color = Color(0, 0, 0, 0.15)
	hov.shadow_size = 4
	hov.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("hover", hov)

	var pressed := make_panel_stylebox(color.darkened(0.1), 10, 12)
	pressed.shadow_size = 1
	pressed.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := make_panel_stylebox(color.lerp(BG_CREAM, 0.5), 10, 12)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", FONT_BODY)


static func style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.88, 0.86, 0.82)
	bg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)


static func make_section_header(text: String, color: Color = TEXT_HEADER) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SECTION)
	label.add_theme_color_override("font_color", color)
	return label
