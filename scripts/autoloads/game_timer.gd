## Game Timer — Autoload that drives month/year time progression.
## 30 real seconds per in-game month at 1x speed.
## See: design/gdd/game-timer.md
extends Node

signal month_advanced(month: int)
signal year_ended
signal timer_paused
signal timer_resumed
signal speed_changed(new_speed: float)

enum State { PAUSED, RUNNING, STOPPED }

var _state: State = State.PAUSED
var _current_month: int = 0
var _elapsed_in_month: float = 0.0
var _speed_multiplier: float = 1.0
var _seconds_per_month: float = 30.0


func _ready() -> void:
	_recalculate_seconds_per_month()


func _process(delta: float) -> void:
	if _state != State.RUNNING:
		return

	# Cap delta to prevent skipping months on lag spikes
	var capped_delta: float = minf(delta, _seconds_per_month)
	_elapsed_in_month += capped_delta

	if _elapsed_in_month >= _seconds_per_month:
		_elapsed_in_month -= _seconds_per_month
		_current_month += 1

		if _current_month >= 12:
			_current_month = 0
			year_ended.emit()
		else:
			month_advanced.emit(_current_month)


# -- Control -------------------------------------------------------------------

func start() -> void:
	if _state != State.STOPPED:
		_state = State.RUNNING
		timer_resumed.emit()


func pause() -> void:
	if _state == State.RUNNING:
		_state = State.PAUSED
		timer_paused.emit()


func resume() -> void:
	if _state == State.PAUSED:
		_state = State.RUNNING
		timer_resumed.emit()


func toggle_pause() -> void:
	if _state == State.RUNNING:
		pause()
	elif _state == State.PAUSED:
		resume()


func stop() -> void:
	_state = State.STOPPED


func reset() -> void:
	_current_month = 0
	_elapsed_in_month = 0.0
	_state = State.PAUSED


# -- Speed ---------------------------------------------------------------------

func set_speed(multiplier: float) -> void:
	_speed_multiplier = maxf(0.5, multiplier)
	_recalculate_seconds_per_month()
	speed_changed.emit(_speed_multiplier)


func get_speed() -> float:
	return _speed_multiplier


# -- Query ---------------------------------------------------------------------

func get_current_month() -> int:
	return _current_month


func get_elapsed_in_month() -> float:
	return _elapsed_in_month


func is_running() -> bool:
	return _state == State.RUNNING


func is_paused() -> bool:
	return _state == State.PAUSED


func get_time_remaining_in_year() -> Dictionary:
	var months_left: int = maxi(0, 11 - _current_month)
	var seconds_left: float = (months_left * _seconds_per_month) + (_seconds_per_month - _elapsed_in_month)
	seconds_left = maxf(0.0, seconds_left)
	var total_int: int = int(seconds_left)
	@warning_ignore("integer_division")
	var minutes: int = total_int / 60
	var seconds: int = total_int % 60
	return { "minutes": minutes, "seconds": seconds, "total_seconds": seconds_left }


# -- Internal ------------------------------------------------------------------

func _recalculate_seconds_per_month() -> void:
	if not DataLoader.is_loaded():
		_seconds_per_month = 30.0
		return
	var config: Dictionary = DataLoader.get_config()
	var year_seconds: float = float(config.get("time", {}).get("year_duration_seconds", 360))
	var months: float = float(config.get("time", {}).get("months_per_year", 12))
	_seconds_per_month = (year_seconds / months) / _speed_multiplier
