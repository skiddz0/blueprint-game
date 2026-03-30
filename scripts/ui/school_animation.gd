## School Animation — Full day cycle with pixel-art sprites.
## Morning walk → Corridor in → Classroom teach → Classroom study →
## Corridor out → Evening walk home → Night (empty) → repeat
extends Control

# Sprite folders under res://assets/sprites/
const STUDENT_SPRITES := [
	"primary_student", "malay_girl_student", "chinese_boy_student",
	"indian_girl_student",
]
const TEACHER_SPRITES := ["hijab_teacher", "male_teacher"]

# Animation names
const ANIM_IDLE := "idle"
const ANIM_WALK := "walk"
const ANIM_SIT := "sit-study"
const ANIM_TALK := "interact-talk"
const ANIM_TEACH := "teach"

# Backgrounds
const BG_MORNING := "res://assets/sprites/backgrounds/school_morning.png"
const BG_CORRIDOR := "res://assets/sprites/backgrounds/corridor.png"
const BG_CLASSROOM := "res://assets/sprites/backgrounds/classroom.png"
const BG_EVENING := "res://assets/sprites/backgrounds/school_evening.png"
const BG_NIGHT := "res://assets/sprites/backgrounds/school_night.png"

var _bg_textures: Dictionary = {}

# Phases
enum Phase {
	MORNING_WALK,    # 0 — students walk to school (morning bg)
	CORRIDOR_IN,     # 1 — students walk through corridor (corridor bg)
	TEACHING,        # 2 — teacher teaches (classroom bg)
	STUDYING,        # 3 — students study (classroom bg)
	CORRIDOR_OUT,    # 4 — students walk out (corridor bg)
	EVENING_WALK,    # 5 — students walk home (evening bg)
	NIGHT,           # 6 — empty school (night bg)
}

const PHASE_DURATION := [4.5, 3.0, 5.0, 5.0, 3.0, 4.5, 3.0]
const PHASE_BG := [
	BG_MORNING, BG_CORRIDOR, BG_CLASSROOM, BG_CLASSROOM,
	BG_CORRIDOR, BG_EVENING, BG_NIGHT,
]

var _phase: int = Phase.MORNING_WALK
var _phase_timer: float = 0.0

const CHAR_COUNT := 4
const WALK_SPEED := 55.0
const FRAME_RATE := 6.0

# Sprite sizes
const STUDENT_SIZE := 40.0
const STUDENT_SIT_SIZE := 48.0
const TEACHER_SIZE := 46.0

# Floor Y as fraction of panel height per background type
const FLOOR_OUTDOOR := 0.92   # morning/evening — road level
const FLOOR_CORRIDOR := 0.82  # corridor — floor level
const FLOOR_CLASSROOM := 0.82 # classroom — floor level

var _students: Array[Dictionary] = []
var _teacher: Dictionary = {}
var _frame_timer: float = 0.0
var _current_frame: int = 0
var _sprite_cache: Dictionary = {}


func _ready() -> void:
	clip_contents = true
	custom_minimum_size.y = 200
	_load_backgrounds()
	_preload_sprites()
	_spawn_characters()


func _load_backgrounds() -> void:
	for path: String in [BG_MORNING, BG_CORRIDOR, BG_CLASSROOM, BG_EVENING, BG_NIGHT]:
		if ResourceLoader.exists(path):
			_bg_textures[path] = load(path)


func _preload_sprites() -> void:
	var all_chars: Array = STUDENT_SPRITES.duplicate()
	all_chars.append_array(TEACHER_SPRITES)

	for char_name: String in all_chars:
		var anims: Array
		if char_name in TEACHER_SPRITES:
			anims = [ANIM_IDLE, ANIM_WALK, ANIM_TEACH, ANIM_TALK]
		else:
			anims = [ANIM_IDLE, ANIM_WALK, ANIM_SIT, ANIM_TALK]

		for anim: String in anims:
			for dir: String in ["south", "east", "west"]:
				var key := "%s/%s/%s" % [char_name, anim, dir]
				var frames: Array[Texture2D] = []
				for i in range(10):
					var p := "res://assets/sprites/%s/animations/%s/%s/frame_%03d.png" % [char_name, anim, dir, i]
					if ResourceLoader.exists(p):
						frames.append(load(p))
					else:
						break
				if frames.size() > 0:
					_sprite_cache[key] = frames


func _get_frames(char_name: String, anim: String, dir: String) -> Array:
	return _sprite_cache.get("%s/%s/%s" % [char_name, anim, dir], [])


func _get_floor_y() -> float:
	match _phase:
		Phase.MORNING_WALK, Phase.EVENING_WALK, Phase.NIGHT:
			return size.y * FLOOR_OUTDOOR
		Phase.CORRIDOR_IN, Phase.CORRIDOR_OUT:
			return size.y * FLOOR_CORRIDOR
		_:
			return size.y * FLOOR_CLASSROOM


func _set_bottom_y(node: TextureRect, floor_y: float, offset: float = 0.0) -> void:
	node.position.y = floor_y - node.size.y + offset


func _process(delta: float) -> void:
	# Frame animation
	_frame_timer += delta
	if _frame_timer >= 1.0 / FRAME_RATE:
		_frame_timer -= 1.0 / FRAME_RATE
		_current_frame += 1

	# Phase progression
	_phase_timer += delta
	if _phase_timer >= PHASE_DURATION[_phase]:
		_phase_timer = 0.0
		_phase = (_phase + 1) % Phase.size()
		if _phase == Phase.MORNING_WALK:
			_spawn_characters()
		_on_phase_changed()

	# Animate current phase
	match _phase:
		Phase.MORNING_WALK: _animate_outdoor_walk(true, delta)
		Phase.CORRIDOR_IN: _animate_corridor_walk(true, delta)
		Phase.TEACHING: _animate_teaching()
		Phase.STUDYING: _animate_studying()
		Phase.CORRIDOR_OUT: _animate_corridor_walk(false, delta)
		Phase.EVENING_WALK: _animate_outdoor_walk(false, delta)
		Phase.NIGHT: _animate_night()

	_update_sprite_frames()
	queue_redraw()


func _on_phase_changed() -> void:
	# Position characters for the new phase
	var floor_y := _get_floor_y()

	match _phase:
		Phase.MORNING_WALK:
			# Students start off-screen left
			for s: Dictionary in _students:
				var node: TextureRect = s["node"]
				if is_instance_valid(node):
					node.visible = true
					node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
					node.position.x = -50.0 - (s["index"] * 36.0)
					_set_bottom_y(node, floor_y)
			_set_teacher_visible(false)

		Phase.CORRIDOR_IN:
			# Students enter corridor from right
			for s: Dictionary in _students:
				var node: TextureRect = s["node"]
				if is_instance_valid(node):
					node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
					node.position.x = size.x + 30.0 + (s["index"] * 36.0)
					_set_bottom_y(node, floor_y)
			_set_teacher_visible(false)

		Phase.TEACHING:
			# Students at seats, teacher appears
			var spacing := size.x * 0.16
			for s: Dictionary in _students:
				var node: TextureRect = s["node"]
				if is_instance_valid(node):
					node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
					node.position.x = size.x * 0.25 + (s["index"] * spacing)
					_set_bottom_y(node, floor_y)
			_set_teacher_visible(true)
			if _teacher.has("node") and is_instance_valid(_teacher["node"]):
				var t: TextureRect = _teacher["node"]
				t.size = Vector2(TEACHER_SIZE, TEACHER_SIZE)
				t.position.x = size.x * 0.05
				_set_bottom_y(t, floor_y)

		Phase.STUDYING:
			pass  # Keep positions from teaching

		Phase.CORRIDOR_OUT:
			# Students start inside corridor, walk right to exit
			for s: Dictionary in _students:
				var node: TextureRect = s["node"]
				if is_instance_valid(node):
					node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
					node.position.x = size.x * 0.1 + (s["index"] * 40.0)
					_set_bottom_y(node, floor_y)
			_set_teacher_visible(false)

		Phase.EVENING_WALK:
			# Students at school side, walk right to go home
			for s: Dictionary in _students:
				var node: TextureRect = s["node"]
				if is_instance_valid(node):
					node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
					node.position.x = size.x * 0.65 + (s["index"] * 30.0)
					_set_bottom_y(node, floor_y)
			_set_teacher_visible(false)

		Phase.NIGHT:
			# Hide everyone
			for s: Dictionary in _students:
				if is_instance_valid(s["node"]):
					s["node"].visible = false
			_set_teacher_visible(false)


func _set_teacher_visible(vis: bool) -> void:
	if _teacher.has("node") and is_instance_valid(_teacher["node"]):
		_teacher["node"].visible = vis


func _spawn_characters() -> void:
	_students.clear()
	_teacher.clear()
	_current_frame = 0

	for child: Node in get_children():
		child.queue_free()

	var shuffled := STUDENT_SPRITES.duplicate()
	shuffled.shuffle()

	var floor_y := size.y * FLOOR_OUTDOOR
	for i in range(CHAR_COUNT):
		var char_name: String = shuffled[i % shuffled.size()]
		var sprite := TextureRect.new()
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
		sprite.position = Vector2(-50.0 - (i * 36.0), floor_y - STUDENT_SIZE)
		sprite.name = "Student_%d" % i
		add_child(sprite)
		_students.append({
			"node": sprite,
			"char_name": char_name,
			"index": i,
		})

	var teacher_name: String = TEACHER_SPRITES[randi() % TEACHER_SPRITES.size()]
	var t_sprite := TextureRect.new()
	t_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t_sprite.size = Vector2(TEACHER_SIZE, TEACHER_SIZE)
	t_sprite.visible = false
	t_sprite.name = "Teacher"
	add_child(t_sprite)
	_teacher = {"node": t_sprite, "char_name": teacher_name}


# ── Phase animations ──

func _animate_outdoor_walk(going_to_school: bool, delta: float) -> void:
	var floor_y := _get_floor_y()
	for s: Dictionary in _students:
		var node: TextureRect = s["node"]
		if not is_instance_valid(node):
			continue
		node.visible = true
		node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
		if going_to_school:
			# Walk east (left to right) toward school on the right
			var target: float = size.x * 0.55 + (float(s["index"]) * 30.0)
			if node.position.x < target:
				node.position.x += WALK_SPEED * delta
		else:
			# Walk right off screen (going home)
			node.position.x += WALK_SPEED * delta
		var bob := sin(node.position.x * 0.12) * 1.5
		_set_bottom_y(node, floor_y, bob)


func _animate_corridor_walk(entering: bool, delta: float) -> void:
	var floor_y := _get_floor_y()
	for s: Dictionary in _students:
		var node: TextureRect = s["node"]
		if not is_instance_valid(node):
			continue
		node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
		if entering:
			# Walk left (into school, from right)
			var target: float = size.x * 0.15 + (float(s["index"]) * 42.0)
			if node.position.x > target:
				node.position.x -= WALK_SPEED * delta
		else:
			# Walk right (out of school)
			node.position.x += WALK_SPEED * delta
		var bob := sin(node.position.x * 0.1) * 1.5
		_set_bottom_y(node, floor_y, bob)


func _animate_teaching() -> void:
	var floor_y := _get_floor_y()

	if _teacher.has("node") and is_instance_valid(_teacher["node"]):
		var t_node: TextureRect = _teacher["node"]
		t_node.visible = true
		t_node.size = Vector2(TEACHER_SIZE, TEACHER_SIZE)
		t_node.position.x = size.x * 0.05
		var bob := sin(_phase_timer * 2.5) * 1.5
		_set_bottom_y(t_node, floor_y, bob)

	var spacing := size.x * 0.16
	for s: Dictionary in _students:
		var node: TextureRect = s["node"]
		if not is_instance_valid(node):
			continue
		node.size = Vector2(STUDENT_SIZE, STUDENT_SIZE)
		node.position.x = size.x * 0.25 + (s["index"] * spacing)
		var bob := sin(_phase_timer * 1.8 + float(s["index"]) * 1.2) * 1.0
		_set_bottom_y(node, floor_y, bob)


func _animate_studying() -> void:
	var floor_y := _get_floor_y()

	if _teacher.has("node") and is_instance_valid(_teacher["node"]):
		var t_node: TextureRect = _teacher["node"]
		t_node.visible = true
		t_node.size = Vector2(TEACHER_SIZE, TEACHER_SIZE)
		# Teacher paces slowly
		t_node.position.x = size.x * 0.05 + sin(_phase_timer * 0.7) * 15.0
		var bob := sin(_phase_timer * 2.0) * 1.0
		_set_bottom_y(t_node, floor_y, bob)

	var spacing := size.x * 0.16
	for s: Dictionary in _students:
		var node: TextureRect = s["node"]
		if not is_instance_valid(node):
			continue
		node.size = Vector2(STUDENT_SIT_SIZE, STUDENT_SIT_SIZE)
		node.position.x = size.x * 0.22 + (s["index"] * spacing)
		var bob := sin(_phase_timer * 1.2 + float(s["index"]) * 0.8) * 0.8
		_set_bottom_y(node, floor_y, bob)


func _animate_night() -> void:
	# Everything hidden — peaceful empty school
	pass


# ── Sprite frame updates ──

func _update_sprite_frames() -> void:
	for s: Dictionary in _students:
		var node: TextureRect = s["node"]
		if not is_instance_valid(node) or not node.visible:
			continue
		var char_name: String = s["char_name"]
		var anim: String
		var dir: String

		match _phase:
			Phase.MORNING_WALK:
				anim = ANIM_WALK; dir = "east"
			Phase.CORRIDOR_IN:
				anim = ANIM_WALK; dir = "west"
			Phase.TEACHING:
				anim = ANIM_IDLE; dir = "west"
			Phase.STUDYING:
				anim = ANIM_SIT; dir = "south"
			Phase.CORRIDOR_OUT:
				anim = ANIM_WALK; dir = "east"
			Phase.EVENING_WALK:
				anim = ANIM_WALK; dir = "east"
			_:
				anim = ANIM_IDLE; dir = "south"

		var frames: Array = _get_frames(char_name, anim, dir)
		if frames.size() > 0:
			node.texture = frames[_current_frame % frames.size()]

	if _teacher.has("node") and is_instance_valid(_teacher["node"]) and _teacher["node"].visible:
		var t_node: TextureRect = _teacher["node"]
		var t_name: String = _teacher["char_name"]
		var t_anim: String
		var t_dir: String

		match _phase:
			Phase.TEACHING:
				t_anim = ANIM_TEACH; t_dir = "east"
			Phase.STUDYING:
				t_anim = ANIM_TALK; t_dir = "east"
			_:
				t_anim = ANIM_IDLE; t_dir = "south"

		var frames: Array = _get_frames(t_name, t_anim, t_dir)
		if frames.size() > 0:
			t_node.texture = frames[_current_frame % frames.size()]


# ── Drawing ──

func _draw() -> void:
	# Draw current phase background
	var bg_path: String = PHASE_BG[_phase]
	var tex: Texture2D = _bg_textures.get(bg_path)
	if tex:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.82, 0.95))
