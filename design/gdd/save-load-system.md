# Save/Load System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Save/Load System serializes and deserializes the complete GameState to/from
disk using Godot's FileAccess. It supports 3 manual save slots plus 1 auto-save
slot. Each slot stores the full game state, a timestamp, and preview metadata
(year, month, average KPI). This replaces the React prototype's localStorage
implementation.

## Player Fantasy

Save before a risky scenario, load if it goes wrong. Experiment with different
strategies without losing progress. The safety net that enables bold play.

## Detailed Design

### Core Rules

1. **4 save slots**: slot 0 (auto-save), slots 1-3 (manual).
2. Save data stored in `user://saves/slot_N.json` (Godot's user data directory).
3. Each save file contains:
   ```json
   {
     "slot_id": 0,
     "name": "Auto Save" | "Custom Name",
     "timestamp": 1711699200,
     "year": 2015,
     "month": 6,
     "avg_kpi": 58.4,
     "game_state": { ... full GameState dictionary ... }
   }
   ```
4. **Save**: Serialize GameState to Dictionary, wrap in save metadata, write JSON.
5. **Load**: Read JSON, parse, extract GameState, restore via `GameStateManager`.
6. **Auto-save**: Triggered at each year-end (not every 30 seconds like prototype —
   year-end is a natural checkpoint and avoids mid-month state complexity).
7. **Delete**: Remove the save file from disk.
8. Save/Load is an autoload singleton (`SaveLoadSystem.gd`).

### Public API

```gdscript
func save_game(slot_id: int, custom_name: String = "") -> bool
func load_game(slot_id: int) -> bool
func delete_save(slot_id: int) -> bool
func get_save_slots() -> Array[Dictionary]  # Returns metadata for all slots
func has_any_save() -> bool
func get_auto_save() -> Dictionary  # or null
```

### Save Format

Uses `JSON.stringify()` for serialization and `JSON.parse_string()` for
deserialization. GameState Dictionary is directly serializable since it contains
only basic types (int, float, String, Array, Dictionary).

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Bidirectional | Reads full GameState for save; restores GameState on load |
| Data Loader | Reads on load | May need base data to validate/supplement loaded state |
| Year Cycle Engine | Upstream | Auto-save triggered at year-end |
| Save/Load UI | Downstream | Provides slot metadata for display |
| Main Menu | Downstream | "Continue" uses auto-save; "Load" opens Save/Load UI |

## Formulas

### Average KPI (for preview)

```
avg_kpi = sum(kpi.value for kpi in game_state.kpis.values()) / 5
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Save file corrupted/invalid JSON | Return false; log error; don't crash | Graceful failure |
| Save slot doesn't exist (load) | Return false | Nothing to load |
| Disk full (save) | Return false; show error to user | Can't write |
| Load during SCENARIO state | Restore full state including current_scenario; transition to SCENARIO | Resume exactly where saved |
| Auto-save overwrites without confirmation | Expected — slot 0 is always auto-save | Matches prototype behavior |
| Game version mismatch on load | Load anyway; log warning | Forward-compatible where possible |
| Save directory doesn't exist | Create `user://saves/` on first save | Auto-create |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game State Manager | Peer (hard) | State serialization and restoration |
| Year Cycle Engine | Upstream (soft) | Auto-save trigger |
| Save/Load UI | Downstream (soft) | Slot display |
| Main Menu | Downstream (soft) | Continue/Load actions |

## Tuning Knobs

| Parameter | Value | Safe Range | Notes |
|-----------|-------|------------|-------|
| Max save slots | 3 (+ 1 auto) | 1-10 | More slots = more disk use (negligible) |
| Auto-save frequency | Every year-end | Every month to never | Year-end is clean state |

## Acceptance Criteria

- [ ] Save writes valid JSON to `user://saves/slot_N.json`
- [ ] Load restores exact GameState (year, month, KPIs, budget, PC, etc.)
- [ ] Auto-save triggers at year-end to slot 0
- [ ] Manual save to slots 1-3 with custom names
- [ ] `get_save_slots()` returns metadata for all existing saves
- [ ] Delete removes save file from disk
- [ ] Corrupted save files don't crash the game
- [ ] Loaded state transitions to correct game phase
- [ ] Save directory auto-created on first save
