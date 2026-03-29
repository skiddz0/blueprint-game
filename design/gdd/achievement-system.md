# Achievement System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Achievement System tracks 20 achievements that reward specific milestones,
KPI thresholds, and gameplay challenges. Achievements persist across sessions
(saved separately from game state) and provide replayability incentive. They
are checked at natural evaluation points (year-end, game-end, scenario resolution).

## Player Fantasy

Badges of mastery. Complete your first year, manage 10 crises, get all KPIs above
90. Each achievement validates a different dimension of skill and encourages
diverse strategies across replays.

## Detailed Design

### Core Rules

1. 20 achievements loaded from `achievements.json` via Data Loader.
2. Each achievement has: `id`, `name`, `description`, `category`, `condition`.
3. Achievement progress is checked at:
   - Year-end (KPI thresholds, initiative counts)
   - Game end (grade-based, completion-based)
   - Scenario resolution (scenario count milestones)
4. Unlocked achievements are stored in `user://achievements.json` — persists
   across game sessions (separate from save slots).
5. On unlock: emit `achievement_unlocked` signal; show notification toast.
6. Already-unlocked achievements are not re-triggered.

### Achievement Categories

| Category | Examples | Check Timing |
|----------|---------|-------------|
| Milestones | First Steps (complete year 1), Blueprint Complete (finish game) | Year-end, game-end |
| Grades | Excellence (A rank), Perfect Score (S rank) | Game end |
| KPI | Equity Champion (equity >= 90), Quality Leader (quality >= 90) | Year-end |
| Challenges | Crisis Manager (10 scenarios), Initiative Champion (20 initiatives) | Scenario resolution, year-end |
| Mastery | Shift Master (all shifts maxed) | Year-end |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Achievement definitions |
| KPI System | Reads | KPI values for threshold checks |
| Scenario Engine | Reads | Scenarios completed count |
| Initiative System | Reads | Initiatives completed count |
| Shift System | Reads | Shift levels for mastery check |
| Grading System | Reads | Final grade |
| Year Cycle Engine | Upstream | Trigger checks at year-end and game-end |

## Formulas

### Condition Evaluation

```
func check_achievement(achievement: Dictionary, game_state: Dictionary) -> bool:
    match achievement.condition.type:
        "kpi_threshold":
            return game_state.kpis[condition.kpi].value >= condition.threshold
        "grade":
            return game_state.final_grade == condition.grade
        "scenario_count":
            return game_state.scenarios_completed.size() >= condition.count
        "initiative_count":
            return game_state.completed_initiative_count >= condition.count
        "shift_mastery":
            return all shifts at max level
        "year_reached":
            return game_state.year >= condition.year
    return false
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Achievement unlocked then game loaded to before that point | Achievement stays unlocked (persists separately) | Achievements are meta-progression |
| Achievement file corrupted | Reset to empty; log warning | Don't crash; player loses achievement history |
| Same achievement conditions met multiple times | Only triggers once | `unlocked_achievements` set prevents re-trigger |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Achievement definitions |
| KPI System | Upstream (soft) | Threshold checks |
| Scenario Engine | Upstream (soft) | Count checks |
| Initiative System | Upstream (soft) | Count checks |
| Shift System | Upstream (soft) | Mastery check |
| Grading System | Upstream (soft) | Grade check |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Notes |
|-----------|--------------|------------|-------|
| KPI threshold for champion achievements | 90 | 80-100 | Lower = more achievable |
| Scenario count for Crisis Manager | 10 | 5-27 | All 27 would require perfect run |
| Initiative count for Champion | 20 | 10-50 | Per game session |

## Acceptance Criteria

- [ ] 20 achievements load from JSON
- [ ] Achievements check at correct timing (year-end, game-end, scenario)
- [ ] Unlocked achievements persist in `user://achievements.json`
- [ ] `achievement_unlocked` signal fires with achievement data
- [ ] Already-unlocked achievements don't re-trigger
- [ ] Achievement file corruption doesn't crash the game
