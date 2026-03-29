# Game Timer

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Game Timer drives the passage of in-game time: 30 real seconds per month,
12 months per year, 13 years (2013-2025). It is an autoload singleton that ticks
independently and emits signals when months and years advance. The Game State
Manager listens to these signals and orchestrates gameplay responses. The timer
pauses during planning phase, scenarios, and when the player manually pauses.

The player experiences this as a gentle time pressure — not frantic, but steady
enough that you can't deliberate forever.

## Player Fantasy

Time is always moving. You watch the months tick by, initiatives progressing,
knowing that a scenario might trigger any month. The timer creates tension without
panic — you have time to think, but not to waste.

## Detailed Design

### Core Rules

1. The Game Timer is an **autoload singleton** (`GameTimer.gd`).
2. Each in-game month = 30 real seconds (`config.time.year_duration_seconds / config.time.months_per_year` = 360/12 = 30).
3. The timer uses Godot's `_process(delta)` to accumulate elapsed time.
4. When `elapsed_seconds >= seconds_per_month` (30), emit `month_advanced` and reset.
5. When month reaches 12, emit `year_ended` and reset month to 0.
6. Timer can be paused/resumed via `pause()` / `resume()` / `toggle_pause()`.
7. Timer starts paused — the Game State Manager calls `resume()` when transitioning to RUNNING.
8. Speed multiplier support: 1x (default), 1.5x, 2x — divides the seconds_per_month.

### States and Transitions

| State | Entry Condition | Behavior | Exit Condition |
|-------|----------------|----------|----------------|
| PAUSED | Initial; or `pause()` called | No time accumulation | `resume()` called |
| RUNNING | `resume()` called | `_process` accumulates delta | `pause()` called; month/year boundary |
| STOPPED | `stop()` called (game over) | No time accumulation; cannot resume | `reset()` called |

### Public API

```gdscript
# Control
func start() -> void          # Begin from paused state
func pause() -> void           # Pause accumulation
func resume() -> void          # Resume accumulation
func toggle_pause() -> void    # Toggle pause/resume
func stop() -> void            # Game over — no resume
func reset() -> void           # Reset to month 0, 0 elapsed

# Speed
func set_speed(multiplier: float) -> void  # 1.0, 1.5, 2.0
func get_speed() -> float

# Query
func get_current_month() -> int            # 0-11
func get_elapsed_in_month() -> float       # 0-30 seconds
func get_time_remaining_in_year() -> Dictionary  # { minutes, seconds, total_seconds }
func is_running() -> bool
func is_paused() -> bool
```

### Signals

```gdscript
signal month_advanced(month: int)     # 0-11, fires when month boundary crossed
signal year_ended                      # fires when month 12 reached
signal timer_paused
signal timer_resumed
signal speed_changed(new_speed: float)
```

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `config.time` for seconds per year and months per year |
| Game State Manager | Downstream | Listens to `month_advanced` → calls `advance_month()`; listens to `year_ended` → calls `process_year_end()` |
| Game State Manager | Upstream | Manager calls `pause()`/`resume()` on state transitions (scenario, planning, game over) |
| HUD / Dashboard | Downstream | Reads `get_time_remaining_in_year()` for countdown display |

## Formulas

### Seconds Per Month

```
seconds_per_month = config.time.year_duration_seconds / config.time.months_per_year / speed_multiplier
```

| Variable | Value | Source |
|----------|-------|--------|
| year_duration_seconds | 360 | config.json |
| months_per_year | 12 | config.json |
| speed_multiplier | 1.0 / 1.5 / 2.0 | Player setting |

**Default**: 360 / 12 / 1.0 = 30 seconds per month

### Time Remaining in Year

```
months_remaining = 12 - current_month - 1
seconds_remaining = (months_remaining * seconds_per_month) + (seconds_per_month - elapsed_in_month)
minutes = floor(seconds_remaining / 60)
seconds = seconds_remaining % 60
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| `_process` delta spike (lag/minimize) | Cap delta at `seconds_per_month` per frame; never skip months | Prevent multiple months advancing in one frame |
| Speed changed mid-month | Recalculate remaining time at new speed; don't reset month progress | Smooth transition |
| `resume()` called when already running | No-op | Idempotent |
| `pause()` called when already paused | No-op | Idempotent |
| Year ends exactly on frame boundary | Emit `month_advanced(11)` then `year_ended` in same frame | Both signals fire; order matters |
| Timer at month 11, 29.99s elapsed | Next tick crosses 30s → emit month_advanced(11), then detect month==12 → emit year_ended | Two events in rapid succession is fine |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Config for timing values |
| Game State Manager | Peer (hard) | Bidirectional: timer emits signals, manager controls pause/resume |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `time.year_duration_seconds` | 360 | 120-720 | Slower pace, more time to think | Faster pace, more urgency |
| Speed multiplier options | 1x, 1.5x, 2x | 0.5x-4x | Fast-forward for experienced players | Slow-motion for new players |

## Acceptance Criteria

- [ ] Timer starts in PAUSED state
- [ ] `month_advanced` signal fires every 30 seconds at 1x speed
- [ ] `year_ended` signal fires after 12 months (360 seconds at 1x)
- [ ] `pause()` and `resume()` correctly halt/resume time accumulation
- [ ] Speed 1.5x produces months every 20 seconds
- [ ] Speed 2x produces months every 15 seconds
- [ ] Large delta spikes don't skip months
- [ ] `get_time_remaining_in_year()` returns accurate countdown
- [ ] Timer ignores `_process` when paused or stopped
- [ ] `reset()` returns timer to month 0, 0 elapsed, PAUSED
- [ ] No hardcoded timing values — all from config.json

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should speed be player-accessible or dev-only? | Game Designer | Before UI design | Player-accessible — add speed buttons to HUD for experienced players who want faster replays. |
