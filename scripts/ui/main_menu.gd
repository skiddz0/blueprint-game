## Main Menu — Colorful, playful entry screen.
extends Control

@onready var new_game_btn: Button = %NewGameBtn
@onready var quit_btn: Button = %QuitBtn


func _ready() -> void:
	new_game_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hud.tscn"))
	quit_btn.pressed.connect(func(): get_tree().quit())

	# Cream background
	var bg := ColorRect.new()
	bg.color = ThemeConfig.BG_CREAM
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	# Title
	var title: Label = $VBox/Title
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Subtitle
	var subtitle: Label = $VBox/Subtitle
	subtitle.add_theme_font_size_override("font_size", ThemeConfig.FONT_SUBTITLE)
	subtitle.add_theme_color_override("font_color", ThemeConfig.ORANGE)

	# Tagline
	var tagline := Label.new()
	tagline.text = "A strategy game about Malaysia's Education Blueprint 🎓"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	tagline.add_theme_color_override("font_color", ThemeConfig.TEXT_BODY)
	$VBox.add_child(tagline)
	$VBox.move_child(tagline, 2)

	# Buttons
	ThemeConfig.style_button(new_game_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	new_game_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	new_game_btn.custom_minimum_size = Vector2(240, 50)

	ThemeConfig.style_button(quit_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)
	quit_btn.custom_minimum_size = Vector2(240, 50)

	# Version
	var ver := Label.new()
	ver.text = "v2.0.0 — Godot 4.6 🎮"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
	ver.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	$VBox.add_child(ver)
