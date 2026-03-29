# Audio Manager

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Audio Manager handles background music and 8 sound effect types. It connects
to Game State Manager signals to play context-appropriate sounds (alert on scenario,
success on initiative completion, etc.). Supports mute toggle and volume control
with settings persisted to disk.

## Player Fantasy

Subtle audio reinforcement. A satisfying click when you select an initiative, an
alert chime when a scenario arrives, triumphant music when you win. Audio makes
the game feel alive without demanding attention.

## Detailed Design

### Core Rules

1. Autoload singleton (`AudioManager.gd`).
2. Uses Godot's `AudioStreamPlayer` nodes for BGM and SFX.
3. **8 SFX types**: select, confirm, alert, success, warning, year_end, game_win, game_over.
4. **BGM**: Single background track (looping).
5. **Mute toggle**: Persisted to `user://audio_settings.json`.
6. **Volume**: Master volume 0.0-1.0, persisted.
7. Preloads all audio files on `_ready()`.

### Signal Connections

```gdscript
GameStateManager.initiative_toggled → play("select")
GameStateManager.year_started → play("confirm")
GameStateManager.scenario_triggered → play("alert")
GameStateManager.scenario_resolved → play("success")
GameStateManager.kpi_changed → (only if critical: play("warning"))
GameStateManager.year_ended → play("year_end")
GameStateManager.game_over → play("game_win") or play("game_over")
```

### Public API

```gdscript
func play(sound_key: String) -> void
func toggle_mute() -> bool
func set_volume(value: float) -> void
func get_volume() -> float
func is_muted() -> bool
```

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Upstream (signals) | Triggers SFX on game events |
| HUD / Dashboard | Upstream | Mute button calls `toggle_mute()` |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Sound file missing | Log warning, skip playback | Don't crash for missing audio |
| Rapid-fire same sound | Reset playback position | `audio.stream_paused = false; audio.play()` |
| Muted state | All `play()` calls return immediately | Check mute first |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game State Manager | Upstream (soft) | Signal connections for event-driven audio |

## Acceptance Criteria

- [ ] All 8 SFX types play on correct game events
- [ ] BGM loops continuously during gameplay
- [ ] Mute toggle works and persists across sessions
- [ ] Volume control works and persists
- [ ] Missing audio files don't crash the game
- [ ] Audio respects Godot's audio bus system
