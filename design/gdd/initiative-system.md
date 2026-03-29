# Initiative System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 2 — Meaningful Trade-offs; Pillar 3 — Data-Driven Architecture

## Overview

The Initiative System manages the 104 education initiatives that form the player's
primary action space. Each January, the player selects which initiatives to fund
from those unlocked for the current year, spending Budget (RM) and Political Capital
(PC). Selected initiatives run for their `duration_months`, progressing automatically.
At year-end, initiatives are evaluated: full completion applies full KPI effects,
partial completion applies half effects with a Unity penalty, and failure costs PC
and Unity.

This is the system where the player spends most of their time making decisions.

## Player Fantasy

You're the planner. Every January you spread 104 options before you and build
the best portfolio your budget allows. Some are quick wins (2 months), others are
long-term investments (12 months). You can't fund everything — the joy is in
crafting the optimal combination.

## Detailed Design

### Core Rules

1. 104 initiatives loaded from `initiatives.json` via Data Loader.
2. Each initiative has: `id`, `name`, `description`, `category`, `shift`, `cost_rm`,
   `cost_pc`, `effects`, `shift_xp`, `duration_months`, `unlock_year`, `tags`.
3. **Unlock**: An initiative is available when `current_year >= unlock_year`.
4. **Selection** (PLANNING phase only):
   a. Player toggles initiatives on/off.
   b. Each toggle checks: can afford `cost_rm` and `cost_pc` (after adjustments).
   c. Total selected cost cannot exceed current budget and PC.
5. **Activation** (on `start_year()`):
   a. For each selected initiative, deduct adjusted `cost_rm` from budget and `cost_pc` from PC.
   b. Award `shift_xp` to the initiative's linked shift.
   c. Apply bureaucracy penalty: Efficiency KPI gets `bureaucracy_penalty_per_initiative`
      (or `bureaucracy_penalty_after_du` if year >= 2024) per initiative started.
   d. Create an `ActiveInitiative` record with progress at 0%.
6. **Progress** (monthly):
   a. Each month, each active initiative gains `(100 / duration_months)` percent progress.
   b. If a scenario is active (crisis), add `crisis_delay_months` to effective duration,
      slowing progress.
   c. Progress formula: `progress += 100 / (duration_months + crisis_delay_months)`.
7. **Completion** (year-end processing):
   a. **Full** (progress >= 100%): Apply all `effects` to KPIs.
   b. **Partial** (50% <= progress < 100%): Apply `effects × partial_effects_multiplier` (0.5);
      apply `partial_unity_penalty` (-2).
   c. **Failed** (progress < 50%): Apply `failed_pc_penalty` (-5 PC);
      apply `failed_unity_penalty` (-3 Unity).
   d. Remove from active initiatives.

### Active Initiative Record

```
{
    initiative_id: String,
    name: String,
    start_month: int,          # 0 (always January)
    duration: int,             # months
    progress_percent: float,   # 0-100
    crisis_delay_months: float,# accumulated from scenario special_effects
    is_complete: bool,
    effects: Dictionary        # copied from initiative data
}
```

### Initiative Cost Adjustment

Costs are adjusted before affordability checks and deduction:

```
adjusted_cost_rm = initiative.cost_rm
minister_discount = get_minister_discount(minister.cost_modifiers, initiative.category)
if minister_discount < 0:
    adjusted_cost_rm *= (1 + minister_discount / 100)
if efficiency_kpi < config.efficiency.penalty_threshold:  # < 40
    adjusted_cost_rm *= (1 + config.efficiency.penalty_cost_increase / 100)  # × 1.5
adjusted_cost_rm = max(1, round(adjusted_cost_rm, 1))
```

PC cost (`cost_pc`) is not adjusted — it's always the base value.

### States and Transitions

Per-initiative lifecycle:

| State | Condition | Behavior |
|-------|-----------|----------|
| Locked | `current_year < unlock_year` | Not shown in selector |
| Available | `current_year >= unlock_year` and not selected | Shown in selector |
| Selected | Player toggled on during PLANNING | Marked for activation; cost reserved |
| Active | Year started; initiative running | Progress increments monthly |
| Completed (Full) | Year-end; progress >= 100% | Full effects applied |
| Completed (Partial) | Year-end; 50% <= progress < 100% | Half effects + Unity -2 |
| Failed | Year-end; progress < 50% | PC -5, Unity -3 |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `initiatives[]` catalog, `config.initiatives` for thresholds |
| Game State Manager | Upstream | Stores initiative catalog and active list in GameState |
| Resource System | Upstream | Budget/PC deducted on activation; affordability checks during selection |
| KPI System | Downstream | Initiative effects applied on completion |
| Shift System | Downstream | `shift_xp` awarded on activation |
| Minister System | Reads | Cost modifiers for adjusted pricing |
| Scenario Engine | Reads | Crisis delay from `special_effects.initiatives_delayed_months` |
| Year Cycle Engine | Upstream | Triggers activation at year start, progress monthly, completion at year-end |
| Initiative Selector UI | Downstream | Provides filtered initiative list, selection state, costs |

## Formulas

### Monthly Progress

```
effective_duration = duration_months + crisis_delay_months
monthly_increment = 100.0 / effective_duration
progress_percent = min(100, progress_percent + monthly_increment)
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| duration_months | int | 2-12 | initiative data |
| crisis_delay_months | float | 0+ | accumulated from scenario special_effects |

### Bureaucracy Penalty

```
penalty_per_initiative = config.efficiency.bureaucracy_penalty_per_initiative  # -0.5
if year >= 2024:  # DU restructuring
    penalty_per_initiative = config.efficiency.bureaucracy_penalty_after_du  # -0.25
total_penalty = num_initiatives_started * penalty_per_initiative
apply_kpi_change("efficiency", total_penalty)
```

### Completion Evaluation

```
if progress >= config.initiatives.completion_thresholds.full:  # 100
    for kpi, delta in effects:
        apply_kpi_change(kpi, delta)
elif progress >= config.initiatives.completion_thresholds.partial:  # 50
    for kpi, delta in effects:
        apply_kpi_change(kpi, delta * config.initiatives.partial_effects_multiplier)
    apply_kpi_change("unity", config.initiatives.partial_unity_penalty)
else:
    apply_pc_change(config.initiatives.failed_pc_penalty)
    apply_kpi_change("unity", config.initiatives.failed_unity_penalty)
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Initiative with duration 12 started in January | Completes at exactly 100% at year-end (12 months × 100/12 = 100%) | Longest initiatives barely finish in one year |
| Initiative with duration 2 and no crisis delay | Reaches 100% by month 2; stays at 100% for rest of year | Progress caps at 100; no over-completion |
| Crisis delay added mid-year | Recalculates progress rate from next month; doesn't retroactively slow | Delay affects remaining months |
| Player selects 0 initiatives | Valid — start_year proceeds with no activations | Risky strategy but allowed |
| Player selects initiatives totaling exactly budget | Allowed — budget becomes 0 | Exact spend is fine |
| Initiative cost_rm rounds to 0 after discounts | Floor to 1 | Every initiative costs at least RM 1M |
| Same initiative selected in multiple years | Only if not already purchased that year; resets yearly | Catalog refreshes each year |
| Initiative with shift: 0 (no linked shift) | Skip XP award | Valid for generic initiatives |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Initiative catalog and config |
| Game State Manager | Upstream (hard) | Stores initiative state |
| Resource System | Upstream (hard) | Budget/PC for costs |
| KPI System | Downstream (hard) | Completion effects |
| Shift System | Downstream (hard) | XP awards |
| Minister System | Reads (soft) | Cost modifiers |
| Scenario Engine | Reads (soft) | Crisis delay |
| Year Cycle Engine | Upstream (hard) | Triggers all lifecycle events |
| Initiative Selector UI | Downstream (soft) | Provides data for selection screen |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| Initiative `cost_rm` | 5-50 | 1-100 | More expensive; fewer per year | Cheaper; more per year |
| Initiative `cost_pc` | 0-20 | 0-30 | Higher PC cost limits selection | Lower barrier |
| Initiative `effects` | -3 to +3 | -5 to +5 | Bigger KPI swings | Subtler changes |
| Initiative `duration_months` | 2-12 | 1-12 | Longer to complete; more partial risk | Quick wins |
| `initiatives.partial_effects_multiplier` | 0.5 | 0.25-0.75 | More partial value | Less partial value |
| `initiatives.partial_unity_penalty` | -2 | -5 to 0 | Harsher partial penalty | Milder |
| `initiatives.failed_pc_penalty` | -5 | -10 to -1 | More PC lost on failure | Less risk |
| `initiatives.failed_unity_penalty` | -3 | -5 to -1 | Harsher failure | Milder |
| `efficiency.bureaucracy_penalty_per_initiative` | -0.5 | -2 to 0 | Discourages many initiatives | Less penalty |

## Acceptance Criteria

- [ ] 104 initiatives load from JSON
- [ ] Initiatives filter by `unlock_year <= current_year`
- [ ] Selection respects adjusted budget and PC constraints
- [ ] `start_year()` deducts costs, awards shift XP, applies bureaucracy penalty
- [ ] Monthly progress increments correctly based on duration
- [ ] Crisis delay slows progress correctly
- [ ] Full completion (100%) applies full effects
- [ ] Partial completion (50-99%) applies 50% effects + Unity -2
- [ ] Failed (<50%) applies PC -5, Unity -3
- [ ] Minister cost modifiers reduce matching category costs
- [ ] Efficiency < 40 increases costs by 50%
- [ ] Minimum cost is RM 1M after adjustments
- [ ] Bureaucracy penalty uses -0.5 before 2024, -0.25 from 2024+
- [ ] No hardcoded values — all from config.json and initiatives.json

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Can initiatives carry over between years? | Game Designer | Before implementation | No — per prototype, all initiatives resolve at year-end. Unfinished ones are partial/failed. New year, fresh selection. |
