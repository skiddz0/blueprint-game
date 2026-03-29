## Save/Load Modal — 3 save slots + auto-save display.
## See: design/gdd/save-load-ui.md
extends Control

signal closed

@onready var slots_container: VBoxContainer = %SlotsContainer
@onready var close_btn: Button = %CloseBtn
@onready var title_label: Label = %SaveLoadTitle

var _mode: String = "save"  # "save" or "load"

const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


func _ready() -> void:
	close_btn.pressed.connect(func(): visible = false; closed.emit())
	add_theme_stylebox_override("panel",
		ThemeConfig.make_panel_stylebox(Color(0.0, 0.0, 0.0, 0.45), 0, 0))
	ThemeConfig.style_button(close_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)
	title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_TITLE)
	title_label.add_theme_color_override("font_color", ThemeConfig.BLUE)

	# Card panel background
	var card_panel: PanelContainer = title_label.get_parent().get_parent()
	card_panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_CREAM, ThemeConfig.BLUE, 16, 16))


func open(mode: String = "save") -> void:
	_mode = mode
	title_label.text = "💾 SAVE GAME" if mode == "save" else "📂 LOAD GAME"
	_rebuild_slots()
	visible = true


func _rebuild_slots() -> void:
	for child: Node in slots_container.get_children():
		child.queue_free()

	var slots := SaveLoadSystem.get_save_slots()

	for i in range(slots.size()):
		var slot_data: Variant = slots[i]
		var is_auto: bool = (i == 0)
		var card := _build_slot_card(i, slot_data, is_auto)
		slots_container.add_child(card)


func _build_slot_card(slot_id: int, slot_data: Variant, is_auto: bool) -> PanelContainer:
	var has_save: bool = (slot_data != null)
	var accent := ThemeConfig.YELLOW if is_auto else ThemeConfig.BLUE
	if not has_save:
		accent = ThemeConfig.BORDER_LIGHT

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		ThemeConfig.make_card(ThemeConfig.BG_WHITE, accent, 10, 12))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Slot info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_lbl := Label.new()
	if has_save:
		name_lbl.text = "%s %s" % ["⭐" if is_auto else "💾", str(slot_data["name"])]
	else:
		name_lbl.text = "💾 Empty Slot %d" % slot_id
	name_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_HEADER)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	info_vbox.add_child(name_lbl)

	if has_save:
		var detail_lbl := Label.new()
		var month_name: String = MONTH_NAMES[mini(int(slot_data["month"]), 11)]
		detail_lbl.text = "📅 Year %d, %s  |  📊 Avg KPI: %.0f  |  %s" % [
			int(slot_data["year"]), month_name,
			float(slot_data["avg_kpi"]),
			str(slot_data.get("phase", ""))
		]
		detail_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_SMALL)
		detail_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
		info_vbox.add_child(detail_lbl)

		# Time ago
		var timestamp: int = int(slot_data.get("timestamp", 0))
		if timestamp > 0:
			var ago := _time_ago(timestamp)
			var time_lbl := Label.new()
			time_lbl.text = "🕐 %s" % ago
			time_lbl.add_theme_font_size_override("font_size", ThemeConfig.FONT_TINY)
			time_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			info_vbox.add_child(time_lbl)

	# Buttons
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(btn_vbox)

	if _mode == "save":
		if not is_auto:  # Can't manually save to auto slot
			var save_btn := Button.new()
			save_btn.text = "💾 Save"
			ThemeConfig.style_button(save_btn, ThemeConfig.GREEN, ThemeConfig.GREEN_LIGHT)
			save_btn.pressed.connect(_on_save_pressed.bind(slot_id))
			btn_vbox.add_child(save_btn)
	elif _mode == "load":
		if has_save:
			var load_btn := Button.new()
			load_btn.text = "📂 Load"
			ThemeConfig.style_button(load_btn, ThemeConfig.BLUE, ThemeConfig.BLUE_LIGHT)
			load_btn.pressed.connect(_on_load_pressed.bind(slot_id))
			btn_vbox.add_child(load_btn)

	if has_save and not is_auto:
		var del_btn := Button.new()
		del_btn.text = "🗑️ Delete"
		ThemeConfig.style_button(del_btn, ThemeConfig.RED, ThemeConfig.RED_LIGHT)
		del_btn.pressed.connect(_on_delete_pressed.bind(slot_id))
		btn_vbox.add_child(del_btn)

	return panel


func _on_save_pressed(slot_id: int) -> void:
	SaveLoadSystem.save_game(slot_id)
	_rebuild_slots()


func _on_load_pressed(slot_id: int) -> void:
	SaveLoadSystem.load_game(slot_id)
	visible = false
	closed.emit()


func _on_delete_pressed(slot_id: int) -> void:
	SaveLoadSystem.delete_save(slot_id)
	_rebuild_slots()


func _time_ago(timestamp: int) -> String:
	var now: int = int(Time.get_unix_time_from_system())
	var diff: int = now - timestamp
	if diff < 60: return "just now"
	if diff < 3600: return "%d min ago" % (diff / 60)
	if diff < 86400: return "%d hours ago" % (diff / 3600)
	return "%d days ago" % (diff / 86400)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		closed.emit()
		get_viewport().set_input_as_handled()
