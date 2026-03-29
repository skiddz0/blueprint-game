## Main Menu — Colorful entry screen with Continue/Load support.
extends Control

@onready var new_game_btn: Button = %NewGameBtn
@onready var quit_btn: Button = %QuitBtn


func _ready() -> void:
	new_game_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hud.tscn"))
	quit_btn.pressed.connect(func(): get_tree().quit())

	# Play menu music
	AudioManager.play_menu_music()

	# Background
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

	# New Game button
	ThemeConfig.style_button(new_game_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
	new_game_btn.add_theme_font_size_override("font_size", 18)
	new_game_btn.custom_minimum_size = Vector2(260, 50)
	new_game_btn.text = "🎮 New Game"

	# Continue button (auto-save)
	if SaveLoadSystem.has_any_save():
		var continue_btn := Button.new()
		continue_btn.text = "▶ Continue"
		continue_btn.custom_minimum_size = Vector2(260, 50)
		ThemeConfig.style_button(continue_btn, ThemeConfig.BLUE, ThemeConfig.BLUE_LIGHT)
		continue_btn.add_theme_font_size_override("font_size", 18)
		continue_btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/hud.tscn")
			# Load auto-save after scene is ready
			await get_tree().process_frame
			await get_tree().process_frame
			SaveLoadSystem.load_game(SaveLoadSystem.AUTO_SLOT)
		)
		$VBox.add_child(continue_btn)
		$VBox.move_child(continue_btn, $VBox.get_children().find(new_game_btn) + 1)

	# Quit button
	ThemeConfig.style_button(quit_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)
	quit_btn.custom_minimum_size = Vector2(260, 50)
	quit_btn.text = "🚪 Quit"

	# Version
	var ver := Label.new()
	ver.text = "v2.0.0 — Godot 4.6 🎮"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
	ver.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	$VBox.add_child(ver)
