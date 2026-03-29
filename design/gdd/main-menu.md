# Main Menu

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Main Menu is the entry screen when the game launches. It provides: New Game,
Continue (auto-save), Load Game, Settings, and Quit. Simple and functional — the
player should be in-game within 2 clicks.

## Player Fantasy

Clean entry point. No clutter, no ads, no friction. Click "New Game" and you're
planning Malaysia's education future.

## Detailed Design

### Core Rules

1. First scene loaded on game start (after DataLoader `_ready()`).
2. Background: subtle, thematic (education/Malaysia visual).
3. Title: "The Blueprint Story" with subtitle "PPPM 2013-2025".
4. Menu buttons:
   - **New Game**: Call `GameStateManager.initialize_game()` → switch to HUD scene
   - **Continue**: Load auto-save (slot 0) if exists; greyed out if no auto-save
   - **Load Game**: Open Save/Load UI in load mode
   - **Settings**: Volume, speed defaults (minimal)
   - **Quit**: Exit application

### Layout

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│              🎓 THE BLUEPRINT STORY                      │
│                 PPPM 2013-2025                            │
│                                                          │
│                  [New Game]                               │
│                  [Continue]                               │
│                  [Load Game]                              │
│                  [Settings]                               │
│                  [Quit]                                   │
│                                                          │
│                              v2.0.0                       │
└──────────────────────────────────────────────────────────┘
```

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Calls | `initialize_game()` for New Game |
| Save/Load System | Reads | Auto-save existence for Continue; opens Load UI |
| Audio Manager | Calls | Play BGM on menu; stop on game start |
| Data Loader | Upstream | Must be loaded before menu is interactive |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| No auto-save exists | "Continue" button greyed out | Nothing to continue |
| DataLoader fails | Show error message on menu | Can't play without data |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Must be loaded before menu works |
| Save/Load System | Upstream (soft) | Auto-save check |
| Game State Manager | Downstream (hard) | New game initialization |

## Acceptance Criteria

- [ ] Menu appears on game launch
- [ ] "New Game" starts a fresh 2013 game
- [ ] "Continue" loads auto-save when available; disabled when not
- [ ] "Load Game" opens save/load modal
- [ ] "Quit" exits the application
- [ ] Keyboard navigation works (arrow keys + Enter)
