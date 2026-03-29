# Save/Load UI

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Save/Load UI is a modal with a grid of 3 save slots (plus auto-save display).
Each slot shows metadata: save name, year/month, average KPI, timestamp. The player
can save to a slot (with optional custom name), load from a slot, or delete a save.

## Player Fantasy

Quick access to your saves. See at a glance where each save is in the timeline,
pick one, and jump back in.

## Detailed Design

### Core Rules

1. Opens as modal overlay from HUD save/load button.
2. Two modes: Save Mode and Load Mode (tabs or toggle).
3. Each slot card shows: name, year, month, average KPI, date saved.
4. Empty slots show "Empty Slot" with save button only.
5. Save mode: click slot → enter name → save (overwrites existing).
6. Load mode: click slot → confirm → load.
7. Delete: small delete button per slot with confirmation.

### Layout

```
┌──────────────────────────────────────────────────────────┐
│ SAVE / LOAD GAME               [Save Mode] [Load Mode]  │
│                                                          │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────┐ │
│ │ Auto Save       │ │ Slot 1          │ │ Slot 2      │ │
│ │ Year: 2016      │ │ "Before Flood"  │ │ Empty       │ │
│ │ Month: Jan      │ │ Year: 2014      │ │             │ │
│ │ Avg KPI: 58     │ │ Month: Oct      │ │ [Save]      │ │
│ │ 2 min ago       │ │ Avg KPI: 52     │ │             │ │
│ │                 │ │ Yesterday        │ │             │ │
│ │ [Load]          │ │ [Load] [Delete] │ │             │ │
│ └─────────────────┘ └─────────────────┘ └─────────────┘ │
│                                                          │
│                              [Close]                      │
└──────────────────────────────────────────────────────────┘
```

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Save/Load System | Calls | `save_game()`, `load_game()`, `delete_save()`, `get_save_slots()` |
| HUD / Dashboard | Peer | Overlays HUD; HUD button opens this |
| Game Timer | Calls | Pause on open, resume on close |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Load during gameplay | Confirm dialog: "Unsaved progress will be lost" | Prevent accidental loss |
| Save to occupied slot | Confirm dialog: "Overwrite existing save?" | Prevent accidental overwrite |
| All slots empty (Load mode) | Show "No saves found" | Clear feedback |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Save/Load System | Upstream (hard) | All save/load operations |

## Acceptance Criteria

- [ ] Displays all save slots with correct metadata
- [ ] Save writes to selected slot with optional custom name
- [ ] Load restores game from selected slot
- [ ] Delete removes save with confirmation
- [ ] Auto-save slot is load-only (no manual save to slot 0)
- [ ] Confirmation dialogs for overwrite and load
- [ ] Keyboard: Escape closes modal
