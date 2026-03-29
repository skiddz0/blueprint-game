## Audio Manager — BGM playback with context-aware track switching.
## See: design/gdd/audio-manager.md
extends Node

const BGM_DIR := "res://assets/audio/bgm/"

## Track names mapped to files
const TRACKS := {
	"menu":       "menu_theme.mp3",
	"calm":       "gameplay_calm.mp3",
	"tense":      "gameplay_tense.mp3",
	"dramatic":   "event_dramatic.mp3",
	"intro":      "intro_epic.mp3",
	"victory":    "victory.mp3",
	"defeat":     "defeat.mp3",
}

var _bgm_player: AudioStreamPlayer
var _current_track: String = ""
var _is_muted: bool = false
var _volume_db: float = -6.0  # Slightly below max for headroom
var _fade_tween: Tween

const SETTINGS_PATH := "user://audio_settings.json"


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = _volume_db
	add_child(_bgm_player)
	_bgm_player.finished.connect(_on_track_finished)

	_load_settings()

	# Connect to game signals for context-aware music
	GameStateManager.game_initialized.connect(func(): play_track("calm"))
	GameStateManager.phase_changed.connect(_on_phase_changed)
	GameStateManager.scenario_triggered.connect(func(_s: Dictionary): play_track("dramatic"))
	GameStateManager.scenario_resolved.connect(func(_s: String, _c: String): _resume_gameplay_track())
	GameStateManager.game_over.connect(_on_game_over)
	GameStateManager.game_restarted.connect(func(): play_track("calm"))


func _on_phase_changed(phase: String) -> void:
	match phase:
		"PLANNING":
			play_track("calm")
		"RUNNING":
			_resume_gameplay_track()
		"YEAR_END":
			pass  # Keep current track during summary


func _on_game_over(won: bool, _grade: String) -> void:
	if won:
		play_track("victory")
	else:
		play_track("defeat")


## Play a named track with crossfade.
func play_track(track_name: String) -> void:
	if track_name == _current_track:
		return
	if not TRACKS.has(track_name):
		push_warning("AudioManager: Unknown track '%s'" % track_name)
		return
	if _is_muted:
		_current_track = track_name
		return

	var path: String = BGM_DIR + str(TRACKS[track_name])

	# Load via buffer for MP3 (same approach as portraits)
	var stream: AudioStream = _load_audio(path)
	if stream == null:
		push_warning("AudioManager: Cannot load '%s'" % path)
		return

	# Crossfade
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	if _bgm_player.playing:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_bgm_player, "volume_db", -40.0, 0.5)
		_fade_tween.tween_callback(func():
			_bgm_player.stream = stream
			_bgm_player.volume_db = _volume_db
			_bgm_player.play()
		)
	else:
		_bgm_player.stream = stream
		_bgm_player.volume_db = _volume_db
		_bgm_player.play()

	_current_track = track_name


## Play menu music (called from main menu).
func play_menu_music() -> void:
	play_track("menu")


## Stop all music.
func stop() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_bgm_player.stop()
	_current_track = ""


## Toggle mute. Returns new mute state.
func toggle_mute() -> bool:
	_is_muted = not _is_muted
	if _is_muted:
		_bgm_player.volume_db = -80.0
	else:
		_bgm_player.volume_db = _volume_db
		if not _bgm_player.playing and _current_track != "":
			play_track(_current_track)
	_save_settings()
	return _is_muted


func is_muted() -> bool:
	return _is_muted


## Set volume (0.0 to 1.0).
func set_volume(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	_volume_db = linear_to_db(value) if value > 0.01 else -80.0
	if not _is_muted:
		_bgm_player.volume_db = _volume_db
	_save_settings()


func get_volume() -> float:
	return db_to_linear(_volume_db)


# -- Internal ------------------------------------------------------------------

func _resume_gameplay_track() -> void:
	var avg := KPISystem.calculate_average(GameStateManager.state["kpis"])
	if avg < 45.0:
		play_track("tense")
	else:
		play_track("calm")


func _on_track_finished() -> void:
	# Loop gameplay tracks, don't loop victory/defeat
	if _current_track in ["calm", "tense", "menu"]:
		_bgm_player.play()


func _load_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()

	var stream := AudioStreamMP3.new()
	stream.data = bytes
	return stream


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		_is_muted = bool(json.data.get("muted", false))
		var vol: float = float(json.data.get("volume", 0.5))
		_volume_db = linear_to_db(vol) if vol > 0.01 else -80.0
		if _is_muted:
			_bgm_player.volume_db = -80.0
		else:
			_bgm_player.volume_db = _volume_db
	file.close()


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"muted": _is_muted,
			"volume": get_volume(),
		}, "\t"))
		file.close()
