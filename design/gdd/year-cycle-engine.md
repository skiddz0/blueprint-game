# Year Cycle Engine

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Year Cycle Engine is the orchestrator that sequences all gameplay events within
a year. It does not own data or perform calculations — it calls methods on other
systems in the correct order at the correct time. It listens to the Game Timer's
signals and coordinates planning, monthly updates, mid-year reviews, October checks,
year-end processing, wave transitions, and minister changes.

In the React prototype, this logic was spread across `useGameEngine` and `App.tsx`.
In Godot, it becomes a dedicated autoload singleton that keeps the orchestration
logic clean and testable.

## Player Fantasy

The player experiences the Year Cycle as the game's rhythm: plan in January,
watch months pass, react to scenarios, see year-end results. The engine makes
this feel smooth and inevitable — like seasons changing.

## Detailed Design

### Core Rules

1. The Year Cycle Engine is an **autoload singleton** (`YearCycleEngine.gd`).
2. It connects to Game Timer signals (`month_advanced`, `year_ended`) and
   orchestrates responses by calling methods on other systems.
3. It does NOT own any game state — it reads from Game State Manager and
   calls methods on other systems.

### Annual Sequence

```
PLANNING PHASE (Month 0 / January)
├── Timer paused
├── Player selects initiatives via Initiative Selector UI
├── Player clicks "Start Year"
└── start_year() triggers:
    ├── Deduct initiative costs (Resource System)
    ├── Create active initiative records (Initiative System)
    ├── Award shift XP (Shift System)
    ├── Apply bureaucracy penalty to Efficiency (KPI System)
    ├── Apply minister bonuses to KPIs (Minister System → KPI System)
    ├── Apply shift level bonuses to KPIs (Shift System → KPI System)
    ├── Snapshot start-of-year KPIs
    ├── Resume timer
    └── Transition to RUNNING

MONTHLY TICKS (Months 1-11)
├── Each month:
│   ├── Advance initiative progress (Initiative System)
│   ├── Check for scenario trigger at (year, month) (Scenario Engine)
│   │   └── If triggered: pause timer → SCENARIO state
│   ├── Month 5 (June): Mid-year review
│   │   └── Snapshot mid-year KPIs for comparison display
│   └── Month 9 (October): Budget check
│       └── Flag penalty if budget > RM 10M unspent

YEAR-END PROCESSING (After month 11)
├── Timer paused
├── Process initiative completion:
│   ├── Full (100%): Apply full effects (KPI System)
│   ├── Partial (50-99%): Apply half effects + Unity penalty
│   └── Failed (<50%): Apply PC and Unity penalties
├── Apply KPI decay (KPI System):
│   ├── Access: -2
│   └── Quality: -1
├── Apply stagnation penalty (KPI System):
│   └── Each unchanged KPI: -0.5 (from 2014+)
├── PC regeneration: +floor(Unity/5) (Resource System)
├── Check minister agenda → award PC if met
├── Advance year
├── Calculate wave for new year
├── Calculate next year's budget (Resource System)
├── Apply October penalty if flagged
├── Check for minister transition
│   └── If new minister: show transition messages
├── Check for game over (year > 2025)
│   ├── If over: calculate grade → GAME_OVER
│   └── If not: → PLANNING (next year)
```

### States and Transitions

The Year Cycle Engine doesn't have its own states — it reacts to Game State
Manager's phase transitions and timer signals.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game Timer | Upstream | Listens to `month_advanced` and `year_ended` signals |
| Game State Manager | Bidirectional | Reads current state; calls state transition methods |
| KPI System | Calls | `apply_kpi_change()` for decay, stagnation, bonuses, initiative effects |
| Resource System | Calls | Budget deduction, recalculation, PC regen, October check |
| Initiative System | Calls | Progress update, completion evaluation, activation |
| Scenario Engine | Calls | Trigger check each month |
| Minister System | Calls | Bonus application, agenda check, transition detection |
| Shift System | Calls | XP awards, yearly bonus application |
| Grading System | Calls | Grade calculation at game end |

## Formulas

No formulas — the Year Cycle Engine is pure orchestration. All calculations
are delegated to the systems listed above.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Scenario triggers on month 5 (mid-year review month) | Process scenario first, then mid-year review | Scenario takes priority |
| Scenario triggers on month 9 (October check month) | Process scenario first, then October check | Scenario takes priority |
| Year 2025 year-end | Process normally, then transition to GAME_OVER | Final year gets full processing |
| Year 2013 stagnation check | Skip — no start_of_year_kpis baseline yet | First year exception |
| Minister transition + game over in same year-end | Process minister transition for completeness, then game over | Clean narrative closure |
| No initiatives selected for a year | start_year() proceeds with empty active list | Valid (risky) strategy |
| Multiple scenarios in same year | Each triggers on its scheduled month; only one at a time | Timer paused during each |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game Timer | Upstream (hard) | Provides month/year signals |
| Game State Manager | Peer (hard) | State transitions and data access |
| KPI System | Downstream (hard) | Called for decay, stagnation, effects |
| Resource System | Downstream (hard) | Called for budget/PC changes |
| Initiative System | Downstream (hard) | Called for progress, completion |
| Scenario Engine | Downstream (hard) | Called for trigger checks |
| Minister System | Downstream (hard) | Called for bonuses, transitions |
| Shift System | Downstream (hard) | Called for XP, bonuses |
| Grading System | Downstream (soft) | Called only at game end |

## Tuning Knobs

None — the Year Cycle Engine is pure sequence logic. All tunable values
live in the systems it calls.

| Structural Parameter | Value | Rationale |
|---------------------|-------|-----------|
| Mid-year review month | 5 (June) | From `config.time.mid_year_month` |
| October check month | 9 (October) | From `config.time.october_month` |
| Year-end processing order | Initiatives → Decay → Stagnation → PC regen → Minister → Budget | Matches prototype; order matters for correct calculations |

## Acceptance Criteria

- [ ] Planning phase pauses timer and enables initiative selection
- [ ] `start_year()` executes all activation steps in correct order
- [ ] Monthly ticks advance initiative progress
- [ ] Scenarios trigger at correct year/month during monthly processing
- [ ] Mid-year KPI snapshot taken at month 5
- [ ] October budget check runs at month 9
- [ ] Year-end processing executes in correct order (initiatives → decay → stagnation → PC → minister → budget)
- [ ] Year advances correctly from 2013 to 2025
- [ ] Wave transitions at correct year boundaries (2016, 2021)
- [ ] Minister transitions fire at correct year boundaries
- [ ] Game over triggers after 2025 year-end processing
- [ ] Full game loop: 13 years × 12 months = 156 monthly ticks complete without errors

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should year-end be animated/stepped or instant? | UX Designer | Before UI implementation | Show a year-end summary screen with key changes. Player clicks through results before next planning phase. |
