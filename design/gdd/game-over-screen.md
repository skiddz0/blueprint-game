# Game Over Screen

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Game Over Screen replaces the HUD when the game ends after 2025. It displays
the final grade (S-F), win/loss status, all 5 KPI final values, average KPI,
and a "Play Again" button. This is the payoff screen — the culmination of 13 years
of decisions.

## Player Fantasy

The final report. Your grade flashes on screen. You scan each KPI to see where
you excelled and where you fell short. Then you hit "Play Again" to try a different
strategy.

## Detailed Design

### Core Rules

1. Triggered by `game_over` signal from Game State Manager.
2. Full-screen overlay replacing the HUD.
3. Displays: grade (large, centered), win/loss message, 5 KPI final values with
   bars, average KPI, scenarios completed count, initiatives completed count.
4. "Play Again" button calls `GameStateManager.restart_game()`.
5. Optional: "Return to Menu" button (when Main Menu exists).

### Layout

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│                    THE BLUEPRINT STORY                    │
│                      2013 — 2025                         │
│                                                          │
│                        Grade: A                          │
│                   "Excellent Work!"                       │
│                                                          │
│           Average KPI: 76.4 — Victory!                   │
│                                                          │
│  Quality:    [████████░░] 78                             │
│  Equity:     [███████░░░] 72                             │
│  Access:     [████████░░] 81                             │
│  Unity:      [██████░░░░] 68                             │
│  Efficiency: [████████░░] 83                             │
│                                                          │
│  Scenarios: 27/27 | Initiatives: 42 completed            │
│                                                          │
│            [Play Again]    [Main Menu]                    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Upstream | `game_over` signal; reads final state |
| Grading System | Upstream | Grade and win/loss data |
| KPI System | Upstream | Final KPI values |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Grade F (loss) | Show "The Blueprint fell short" message | Different tone for loss |
| Grade S (perfect) | Show special congratulations | Reward excellence |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game State Manager | Upstream (hard) | Game over trigger and state |
| Grading System | Upstream (hard) | Grade data |

## Acceptance Criteria

- [ ] Shows on `game_over` signal
- [ ] Displays correct grade and win/loss status
- [ ] All 5 KPI final values with color-coded bars
- [ ] Average KPI displayed
- [ ] "Play Again" restarts the game
- [ ] Keyboard: Enter triggers "Play Again"
