# Shift System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 2 — Meaningful Trade-offs

## Overview

The Shift System tracks 11 strategic shifts from Malaysia's PPPM, each linked
to a target KPI. Shifts level up (0-5) by earning XP from completed initiatives.
Each level provides a +1 yearly bonus to the shift's target KPI, compounding over
time. This is the game's long-term investment mechanic — early initiative choices
pay dividends for years through shift levels.

## Player Fantasy

You're building institutional capacity. Each shift represents a strategic direction
for education reform. Investing in Shift 7 (Leverage ICT) doesn't just improve
Access today — it builds permanent infrastructure that improves Access every year
going forward. Your shift levels tell the story of your strategic priorities.

## Detailed Design

### Core Rules

1. 11 shifts loaded from `shifts.json` via Data Loader.
2. Each shift has: `id` (1-11), `title`, `shortTitle`, `description`,
   `targetKpi`, `level` (0-5), `xp`, `nextLevelXp`.
3. Starting state: all shifts at level 0, xp 0.
4. XP is gained when initiatives are activated (at year start via `start_year()`):
   each initiative's `shift_xp` (1-4) is added to its linked shift (by `shift` field).
5. XP progression per level: `[3, 3, 4, 4, 5]` from `config.shifts.xp_per_level`.
6. When `xp >= nextLevelXp`: level up, subtract the threshold from xp, set new
   `nextLevelXp` from the progression array. Max level 5.
7. Yearly bonus: at year start, each shift with level > 0 adds +1 per level to
   its `targetKpi` via the KPI System.
8. Shift records are mutable game state — stored in `GameState.shifts`.

### The 11 Shifts

| ID | Short Title | Target KPI |
|----|------------|------------|
| 1 | High-Performing Schools | Quality |
| 2 | Every Child Succeeds | Equity |
| 3 | Universal Access | Access |
| 4 | Transform Teaching | Quality |
| 5 | High-Performing Leaders | Quality |
| 6 | Empower JPNs/PPDs | Efficiency |
| 7 | Leverage ICT | Access |
| 8 | Transform Curriculum | Quality |
| 9 | Maximize Outcomes | Quality |
| 10 | Increase Transparency | Unity |
| 11 | Partner with Community | Unity |

### States and Transitions

Per-shift state:

| Level | XP Needed | Yearly Bonus |
|-------|-----------|-------------|
| 0 | 3 to reach level 1 | +0 |
| 1 | 3 to reach level 2 | +1/year |
| 2 | 4 to reach level 3 | +2/year |
| 3 | 4 to reach level 4 | +3/year |
| 4 | 5 to reach level 5 | +4/year |
| 5 (max) | N/A | +5/year |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `shifts[]` for initial state, `config.shifts` for XP thresholds |
| Game State Manager | Upstream | Shift records stored in `GameState.shifts`; updated on XP gain |
| Initiative System | Upstream | Each initiative's `shift_xp` and `shift` fields determine XP awards |
| KPI System | Downstream | Yearly bonus: +level per shift to its targetKpi |
| Year Cycle Engine | Upstream | Triggers yearly bonus application and XP awards |
| HUD / Dashboard | Downstream | Displays shift grid with levels and XP progress |

## Formulas

### XP Award

```
func award_shift_xp(shift_id: int, xp_amount: int) -> void:
    var shift = game_state.shifts[shift_id]
    if shift.level >= config.shifts.max_level:
        return  # Already max level
    shift.xp += xp_amount
    while shift.xp >= shift.nextLevelXp and shift.level < config.shifts.max_level:
        shift.xp -= shift.nextLevelXp
        shift.level += 1
        if shift.level < config.shifts.max_level:
            shift.nextLevelXp = config.shifts.xp_per_level[shift.level]
```

### Yearly Bonus

```
for each shift in shifts.values():
    if shift.level > 0:
        apply_kpi_change(shift.targetKpi, shift.level)
```

**Example**: Shift 7 (ICT) at level 3 adds +3 Access per year.

### Total Shift Contribution to KPI

```
total_bonus[kpi] = sum(shift.level for shift in shifts if shift.targetKpi == kpi)
```

**Example**: Quality has 4 shifts targeting it (1, 4, 5, 8, 9). If all at level 2,
total Quality bonus = +10/year.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| XP award overflows into multiple levels | Process level-ups in a while loop until xp < nextLevelXp | Large XP awards (4) can skip levels if threshold is 3 |
| Shift at max level receives XP | Ignored — no further progression | XP is wasted; this is fine |
| Initiative has shift: 0 or invalid shift ID | Skip XP award; log warning | Defensive against bad data |
| All shifts at level 5 | +55 total KPI bonus per year (11 × 5) | This is the theoretical max; impossible to achieve in practice due to limited initiatives |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Shift data and XP config |
| Game State Manager | Upstream (hard) | Stores mutable shift state |
| Initiative System | Upstream (hard) | Provides XP from completed initiatives |
| KPI System | Downstream (hard) | Receives yearly bonuses |
| Year Cycle Engine | Upstream (hard) | Triggers bonus application |
| HUD / Dashboard | Downstream (soft) | Displays shift grid |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `shifts.xp_per_level` | [3,3,4,4,5] | [1,1,1,1,1] to [5,5,5,5,5] | Slower leveling | Faster leveling |
| `shifts.max_level` | 5 | 3-10 | Higher ceiling, more XP needed | Lower ceiling, faster cap |
| Initiative `shift_xp` | 1-4 | 1-6 | Faster shift leveling | Slower leveling |
| Number of shifts targeting each KPI | Quality:5, Equity:1, Access:2, Unity:2, Efficiency:1 | N/A | More shifts = higher potential bonus | Fewer shifts = lower ceiling |

## Acceptance Criteria

- [ ] 11 shifts initialize at level 0, xp 0 from JSON data
- [ ] Initiative completion awards correct XP to linked shift
- [ ] Level-up occurs when XP >= threshold, with correct XP carryover
- [ ] XP thresholds follow [3,3,4,4,5] progression
- [ ] Max level 5 — no further XP processing
- [ ] Yearly bonus adds +level to target KPI for each shift
- [ ] Shift grid displays all 11 shifts with level and XP progress
- [ ] Invalid shift IDs in initiative data don't crash
- [ ] All values from config.json and shifts.json — no hardcoded XP or levels

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should shift XP be awarded at initiative start or completion? | Game Designer | Before implementation | At year start (when initiatives activate), matching the React prototype's `startYear()` behavior. |
