# Grading System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 2 — Meaningful Trade-offs

## Overview

The Grading System calculates the player's final grade (S through F) based on
the average KPI at game end (after year 2025 processing). It also determines
whether the player won (average KPI >= victory threshold of 65). The grade
provides replayability incentive — players chase S-rank after achieving B.

## Player Fantasy

The report card. After 13 years of work, you get a single letter grade that
summarizes your entire administration. S-rank is the badge of mastery.

## Detailed Design

### Core Rules

1. Called at game end (after 2025 year-end processing completes).
2. Calculates average KPI: `(quality + equity + access + unity + efficiency) / 5`.
3. Determines grade from thresholds in `config.kpis.grade_thresholds`.
4. Determines win/loss from `config.kpis.victory_threshold` (65).
5. Stores `final_grade` and `game_won` in GameState.

### Grade Thresholds

| Grade | Average KPI | Meaning |
|-------|------------|---------|
| S | >= 80 | Outstanding — near-perfect transformation |
| A | >= 75 | Excellent — strong results across all KPIs |
| B | >= 65 | Good — victory threshold met |
| C | >= 55 | Adequate — some progress but gaps remain |
| D | >= 45 | Poor — minimal progress |
| F | < 45 | Failed — education system declined |

Victory: B or above (average >= 65).

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| KPI System | Upstream | Reads final KPI values |
| Data Loader | Upstream | Reads grade thresholds from config |
| Game State Manager | Upstream | Stores grade and win/loss state |
| Year Cycle Engine | Upstream | Triggered at game end |
| Game Over Screen | Downstream | Provides grade and KPI data for display |

## Formulas

### Grade Calculation

```
func calculate_grade(kpis: Dictionary) -> Dictionary:
    var avg = calculate_average_kpi(kpis)
    var grade: String
    if avg >= config.kpis.grade_thresholds.s_rank: grade = "S"
    elif avg >= config.kpis.grade_thresholds.a_rank: grade = "A"
    elif avg >= config.kpis.grade_thresholds.b_rank: grade = "B"
    elif avg >= config.kpis.grade_thresholds.c_rank: grade = "C"
    elif avg >= config.kpis.grade_thresholds.d_rank: grade = "D"
    else: grade = "F"
    var won = avg >= config.kpis.victory_threshold
    return { "grade": grade, "won": won, "average_kpi": avg }
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Average KPI exactly 65.0 | Grade B, game won | Threshold is >= |
| Average KPI exactly 80.0 | Grade S | Threshold is >= |
| All KPIs at 0 | Grade F, game lost | Average = 0 |
| All KPIs at 100 | Grade S, game won | Average = 100 |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| KPI System | Upstream (hard) | Final KPI values |
| Data Loader | Upstream (hard) | Grade thresholds |
| Game Over Screen | Downstream (hard) | Display data |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `grade_thresholds.s_rank` | 80 | 70-95 | Harder to get S | Easier S-rank |
| `grade_thresholds.b_rank` / `victory_threshold` | 65 | 50-80 | Harder to win | Easier to win |

## Acceptance Criteria

- [ ] Grade calculates correctly for all threshold boundaries
- [ ] Victory determined by average KPI >= 65
- [ ] Grade stored in GameState after calculation
- [ ] All thresholds from config.json — no hardcoded values
