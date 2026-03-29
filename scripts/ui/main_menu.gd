## Main Menu — Entry screen. New Game launches the HUD scene.
## See: design/gdd/main-menu.md
extends Control

@onready var new_game_btn: Button = %NewGameBtn
@onready var quit_btn: Button = %QuitBtn


func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	quit_btn.pressed.connect(_on_quit)

	# Dark background (behind everything, no mouse interaction)
	var bg := ColorRect.new()
	bg.color = ThemeConfig.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	# Style buttons
	ThemeConfig.style_button(new_game_btn, ThemeConfig.BTN_PRIMARY, ThemeConfig.BTN_PRIMARY_HOVER)
	ThemeConfig.style_button(quit_btn)

	# Style title labels
	var title: Label = $VBox/Title
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)

	var subtitle: Label = $VBox/Subtitle
	subtitle.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	subtitle.add_theme_color_override("font_color", ThemeConfig.ACCENT_GOLD)


func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/hud.tscn")


func _on_quit() -> void:
	get_tree().quit()
