## School Animation — Looping scene of students and teachers.
## Students walk to school → teacher teaches → students walk home → repeat
extends Control

const STUDENT_EMOJIS := ["👧", "👦", "👧🏽", "👦🏽", "👧🏻", "👦🏻"]
const TEACHER_EMOJI := "👩‍🏫"
const SCHOOL_EMOJI := "🏫"
const BOOK_EMOJIS := ["📚", "📖", "✏️", "🎒"]
const HOME_EMOJI := "🏠"
const TREE_EMOJI := "🌳"
const SUN_EMOJI := "☀️"

var _characters: Array = []
var _phase: int = 0  # 0=walking to school, 1=teaching, 2=walking home
var _phase_timer: float = 0.0
var _bg_color := Color(0.55, 0.82, 0.95)  # Sky blue

const PHASE_DURATION := [6.0, 4.0, 6.0]  # seconds per phase
const CHAR_COUNT := 5
const WALK_SPEED := 60.0  # pixels per second


func _ready() -> void:
	clip_contents = true
	custom_minimum_size.y = 80
	_spawn_characters()


func _process(delta: float) -> void:
	_phase_timer += delta
	if _phase_timer >= PHASE_DURATION[_phase]:
		_phase_timer = 0.0
		_phase = (_phase + 1) % 3
		if _phase == 0:
			_spawn_characters()

	# Animate based on phase
	match _phase:
		0: _animate_walking_to_school(delta)
		1: _animate_teaching(delta)
		2: _animate_walking_home(delta)

	queue_redraw()


func _draw() -> void:
	# Sky background
	draw_rect(Rect2(Vector2.ZERO, size), _bg_color)

	# Ground
	var ground_y := size.y - 16
	draw_rect(Rect2(0, ground_y, size.x, 16), Color(0.45, 0.72, 0.32))

	# Road
	draw_rect(Rect2(0, ground_y - 4, size.x, 4), Color(0.60, 0.58, 0.52))


func _spawn_characters() -> void:
	# Remove old character labels
	for child: Node in get_children():
		child.queue_free()
	_characters.clear()

	# Scenery — static elements
	_add_label(SUN_EMOJI, Vector2(size.x - 50, 5), 20)
	_add_label(TREE_EMOJI, Vector2(30, size.y - 42), 18)
	_add_label(TREE_EMOJI, Vector2(size.x - 60, size.y - 42), 18)

	# School in the middle
	var school := _add_label(SCHOOL_EMOJI, Vector2(size.x / 2 - 15, size.y - 48), 24)
	school.name = "School"

	# Home on the left
	_add_label(HOME_EMOJI, Vector2(10, size.y - 44), 20)

	# Students start from left, walking right
	for i in range(CHAR_COUNT):
		var emoji: String = STUDENT_EMOJIS[i % STUDENT_EMOJIS.size()]
		var start_x: float = -30.0 - (i * 35.0)
		var y: float = size.y - 44 + randf_range(-4, 4)
		var lbl := _add_label(emoji, Vector2(start_x, y), 16)
		lbl.name = "Student_%d" % i
		_characters.append({
			"node": lbl,
			"target_x": (size.x / 2) - 60 + (i * 20),
			"home_x": 50.0 + (i * 25),
			"start_x": start_x,
			"y": y,
		})

	# Teacher at school (hidden initially)
	var teacher := _add_label(TEACHER_EMOJI, Vector2(size.x / 2 + 10, size.y - 46), 18)
	teacher.name = "Teacher"
	teacher.visible = false


func _add_label(text: String, pos: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	add_child(lbl)
	return lbl


func _animate_walking_to_school(delta: float) -> void:
	for char_data: Dictionary in _characters:
		var node: Label = char_data["node"]
		if not is_instance_valid(node):
			continue
		var target: float = char_data["target_x"]
		if node.position.x < target:
			node.position.x += WALK_SPEED * delta
			# Bob up and down while walking
			node.position.y = char_data["y"] + sin(node.position.x * 0.1) * 3.0
		else:
			node.position.x = target

	# Hide teacher during walk
	var teacher := get_node_or_null("Teacher")
	if teacher:
		teacher.visible = false


func _animate_teaching(_delta: float) -> void:
	# Show teacher
	var teacher := get_node_or_null("Teacher")
	if teacher:
		teacher.visible = true
		# Teacher bobs slightly
		teacher.position.y = (size.y - 46) + sin(_phase_timer * 3.0) * 2.0

	# Students bob in place (listening)
	for char_data: Dictionary in _characters:
		var node: Label = char_data["node"]
		if not is_instance_valid(node):
			continue
		node.position.y = char_data["y"] + sin(_phase_timer * 2.0 + node.position.x * 0.05) * 2.0


func _animate_walking_home(delta: float) -> void:
	# Hide teacher
	var teacher := get_node_or_null("Teacher")
	if teacher:
		teacher.visible = false

	for char_data: Dictionary in _characters:
		var node: Label = char_data["node"]
		if not is_instance_valid(node):
			continue
		var target: float = char_data["home_x"]
		if node.position.x > target:
			node.position.x -= WALK_SPEED * delta
			node.position.y = char_data["y"] + sin(node.position.x * 0.1) * 3.0
		else:
			node.position.x = target
