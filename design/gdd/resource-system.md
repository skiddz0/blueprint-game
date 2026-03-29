# Resource System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 2 — Meaningful Trade-offs

## Overview

The Resource System manages two currencies — Budget (RM millions) and Political
Capital (PC) — that constrain every player decision. Budget is spent on initiatives
and scenario choices; it resets yearly based on wave, performance, and penalties.
PC is spent on scenario choices and some initiatives; it regenerates slowly from
the Unity KPI. The tension between these two resources and their renewal rates
creates the core strategic constraint.

## Player Fantasy

You never have enough. Every January you stare at your budget knowing it won't
cover everything you want. Every scenario choice costs PC you can't spare. The
fantasy is being the resourceful administrator who makes the most of limited means.

## Detailed Design

### Core Rules

**Budget (RM):**
1. Budget is a float representing millions of Ringgit.
2. Starting budget: `config.resources.starting_budget` (RM 100M).
3. Budget resets each year based on wave base budget + performance modifier.
4. Spending: initiatives deduct `cost_rm` at year start; scenario choices deduct `costs.budget`.
5. Budget cannot go below 0 (clamped).
6. October penalty: if budget > `october_unspent_threshold` (RM 10M) at month 9,
   next year's budget is reduced by `october_penalty_percent` (20%).
7. Efficiency crisis: if Efficiency KPI < `efficiency.penalty_threshold` (40),
   all initiative costs are multiplied by `1 + efficiency.penalty_cost_increase/100` (×1.5).
8. Minister cost modifiers: some ministers give percentage discounts on matching
   category initiatives (e.g., -10% on efficiency_initiatives).
9. Budget floor: minimum RM 10M regardless of penalties.

**Political Capital (PC):**
1. PC is an integer, range [0, `config.resources.max_pc`] (0-100).
2. Starting PC: `config.resources.starting_pc` (50).
3. PC regeneration at year-end: `+floor(unity_kpi / 5)` per year.
4. Spending: scenario choices deduct `costs.pc`; some initiatives deduct `cost_pc`.
5. Failed initiatives cost `config.initiatives.failed_pc_penalty` (-5 PC).
6. Minister agenda reward: if minister's target KPI >= target at year-end, gain `reward_pc`.
7. PC cannot go below 0 or above max (clamped).

### States and Transitions

No discrete states. Resources are continuous values modified by game events.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `config.resources`, `config.waves`, `config.efficiency`, `config.performance_modifiers` |
| Game State Manager | Upstream | Budget/PC stored in GameState; changes via `apply_budget_change()`/`apply_pc_change()` |
| KPI System | Reads | Average KPI for performance modifier; Efficiency KPI for cost increase; Unity KPI for PC regen |
| Initiative System | Upstream | Initiative `cost_rm` and `cost_pc` deducted at year start |
| Scenario Engine | Upstream | Choice `costs.budget` and `costs.pc` deducted on resolution |
| Minister System | Reads | Minister `cost_modifiers` for initiative discounts; `agenda.reward_pc` for PC bonus |
| Year Cycle Engine | Upstream | Triggers budget recalculation and PC regen at year-end |
| HUD / Dashboard | Downstream | Displays budget and PC values |
| Initiative Selector UI | Downstream | Shows affordability of each initiative |

## Formulas

### Next Year Budget

```
base_budget = config.waves[current_wave].base_budget
performance_modifier = lookup_performance_modifier(average_kpi)
budget = base_budget * (1 + performance_modifier)
if has_october_penalty:
    budget = budget * (1 - october_penalty_percent / 100)
budget = max(10, budget)
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| base_budget | int | 60-100 | config.waves (wave 1: 100, wave 2: 80, wave 3: 60) |
| performance_modifier | float | -0.25 to +0.25 | config.performance_modifiers |
| october_penalty_percent | int | 20 | config.resources |

**Performance modifier lookup:**

| Average KPI | Modifier |
|-------------|----------|
| < 45 | -0.25 |
| 45-54 | -0.10 |
| 55-64 | 0.00 |
| 65-74 | +0.10 |
| 75+ | +0.25 |

**Expected budget range**: RM 10M (floor) to RM 125M (wave 1 + 25% bonus)

### Initiative Cost Adjustment

```
cost = initiative.cost_rm
minister_discount = get_minister_discount(minister.cost_modifiers, initiative.category)
if minister_discount < 0:
    cost = cost * (1 + minister_discount / 100)
if efficiency_kpi < config.efficiency.penalty_threshold:
    cost = cost * (1 + config.efficiency.penalty_cost_increase / 100)
cost = max(1, round(cost, 1))
```

### PC Regeneration (Year-End)

```
pc_gain = floor(unity_kpi / 5)
new_pc = clamp(political_capital + pc_gain, 0, max_pc)
```

**Expected range**: +0 (Unity=0) to +20 (Unity=100)

### October Budget Check

```
if month == 9 and budget > config.resources.october_unspent_threshold:
    has_october_penalty = true
    october_unspent_budget = budget
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Budget exactly RM 10M at October | No penalty (threshold is >) | Threshold is "more than 10", not "10 or more" |
| All penalties stack (october + low KPI) | Both apply: budget × 0.8 × (1 - 0.25) | Penalties compound; floor of RM 10M prevents catastrophe |
| PC at 100, Unity at 100 | PC stays at 100 (clamped to max) | Don't waste regen — it's capped |
| Player spends all budget in January | Budget = 0 for rest of year; scenario costs come from remaining or can't afford | Valid strategy — all-in on initiatives |
| Efficiency at 39, minister gives -10% | Apply minister discount first, then efficiency penalty | Order: base → minister → efficiency → clamp |
| Budget goes negative from scenario cost | Clamp to 0 | Never negative; affordability should be checked first |
| Wave transition mid-year? | Waves change at year boundaries only | Budget recalculates at year-end using next year's wave |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Config values for budgets, waves, modifiers |
| Game State Manager | Upstream (hard) | Owns budget/PC storage |
| KPI System | Peer (hard) | Reads average KPI and efficiency KPI |
| Initiative System | Peer (hard) | Costs deducted when initiatives start |
| Scenario Engine | Peer (soft) | Costs deducted on scenario resolution |
| Minister System | Peer (soft) | Cost modifiers for initiative discounts |
| Year Cycle Engine | Upstream (hard) | Triggers annual budget recalculation |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `waves.wave_1.base_budget` | 100 | 50-200 | More room for initiatives in Wave 1 | Tighter early game |
| `waves.wave_2.base_budget` | 80 | 40-150 | Easier mid-game | Tighter mid-game |
| `waves.wave_3.base_budget` | 60 | 30-120 | Easier late game | Brutal endgame |
| `resources.starting_pc` | 50 | 20-80 | More early scenario flexibility | Fewer early choices |
| `resources.max_pc` | 100 | 50-200 | Higher PC ceiling | Lower PC ceiling |
| `resources.october_unspent_threshold` | 10 | 5-30 | Easier to avoid penalty | Must spend more aggressively |
| `resources.october_penalty_percent` | 20 | 10-50 | Harsher penalty | Milder penalty |
| `efficiency.penalty_threshold` | 40 | 20-60 | More situations trigger cost increase | Fewer triggers |
| `efficiency.penalty_cost_increase` | 50 | 25-100 | Steeper cost increase | Milder increase |
| Performance modifiers | -25% to +25% | -50% to +50% | More budget swing | Less budget swing |

## Acceptance Criteria

- [ ] Budget initializes to RM 100M from config
- [ ] PC initializes to 50 from config
- [ ] Budget recalculates correctly at year-end using wave + performance modifier
- [ ] October penalty flags when budget > RM 10M at month 9
- [ ] October penalty reduces next year budget by 20%
- [ ] Budget floor is RM 10M regardless of penalties
- [ ] Efficiency < 40 increases initiative costs by 50%
- [ ] Minister discount applies to matching category initiatives
- [ ] PC regenerates floor(unity/5) per year
- [ ] PC clamped to [0, 100]
- [ ] Budget clamped to >= 0
- [ ] Initiative affordability check accounts for adjusted cost (minister + efficiency)
- [ ] `budget_changed` and `pc_changed` signals fire on every modification
- [ ] No hardcoded values — all from config.json

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should budget be int or float? | Lead Programmer | Before implementation | Float — minister discounts create fractional values (e.g., 45 × 0.9 = 40.5). Display can round. |
