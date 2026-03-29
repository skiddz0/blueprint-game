# KPI System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 2 — Meaningful Trade-offs

## Overview

The KPI System manages 5 key performance indicators — Quality, Equity, Access,
Unity, and Efficiency — that represent Malaysia's education aspirations. Each KPI
is a 0-100 value that rises from initiative effects, scenario choices, shift
bonuses, and minister modifiers, while falling from natural decay and stagnation
penalties. The average KPI at game end determines the player's grade (S-F).

The player interacts with KPIs constantly: they're the scoreboard, the feedback
mechanism, and the primary decision driver. Every choice in the game ultimately
asks: "which KPIs am I willing to sacrifice?"

## Player Fantasy

You are watching the health of an entire education system through 5 vital signs.
When a KPI bar climbs into green, you feel progress. When one slides into red,
you feel urgency. The tension between them — you can't raise all five
simultaneously — IS the strategic challenge.

## Detailed Design

### Core Rules

1. Five KPIs exist: `quality`, `equity`, `access`, `unity`, `efficiency`.
2. Each KPI has a `value` (float, clamped to [0, 100]), a `name`, and a `description`.
3. Starting values are loaded from `config.kpis.starting_values`:
   - Quality: 45, Equity: 50, Access: 45, Unity: 50, Efficiency: 60
4. KPI changes come from these sources (applied via `GameStateManager.apply_kpi_change()`):
   - Initiative completion effects (full or partial)
   - Scenario choice effects
   - Minister yearly bonuses
   - Shift level bonuses (+1 per level per year to target KPI)
   - Natural decay (annual, applied at year-end)
   - Stagnation penalty (annual, applied at year-end)
   - Failed initiative penalties (Unity, PC)
   - Cannot-afford scenario penalties
5. All KPI modifications are clamped: `value = clamp(value + delta, 0, 100)`.
6. KPI snapshots are taken at year start (`start_of_year_kpis`) and mid-year
   (`mid_year_kpis`) for comparison feedback.

### Natural Decay (Annual)

Applied during year-end processing:
- Access: -2 per year (`config.kpis.decay_rates.access_per_year`)
- Quality: -1 per year (`config.kpis.decay_rates.quality_per_year`)
- Equity, Unity, Efficiency: No natural decay

### Stagnation Penalty (Annual, from 2014+)

For each KPI, if `current_value == start_of_year_value` (no change during the year):
- Apply -0.5 (`config.kpis.stagnant_penalty`)
- This punishes passive play — you must actively improve KPIs to avoid decline

### States and Transitions

KPIs don't have discrete states, but they have **color zones** for UI feedback:

| Zone | Condition | Color | Meaning |
|------|-----------|-------|---------|
| Critical | value < 45 | Red | KPI is dangerously low |
| Warning | 45 <= value < 65 | Orange | KPI needs attention |
| Healthy | value >= 65 | Green | KPI meets victory threshold |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `config.kpis` for starting values, thresholds, decay rates |
| Game State Manager | Upstream | KPI values stored in `GameState.kpis`; changes via `apply_kpi_change()` |
| Initiative System | Upstream | Completed initiatives apply `effects` dict to KPIs |
| Scenario Engine | Upstream | Scenario choices apply `effects` dict; cannot-afford applies penalties |
| Minister System | Upstream | Minister `bonuses` dict applied at year start |
| Shift System | Upstream | Each shift level adds +1/year to its `targetKpi` |
| Resource System | Reads | Efficiency KPI < 40 triggers initiative cost increase (+50%) |
| Grading System | Downstream | Reads average KPI for grade calculation |
| Year Cycle Engine | Upstream | Triggers decay and stagnation at year-end |
| HUD / Dashboard | Downstream | Displays 5 KPI bars with color zones and values |

## Formulas

### Average KPI

```
average_kpi = (quality + equity + access + unity + efficiency) / 5
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| quality, equity, access, unity, efficiency | float | 0-100 | GameState.kpis |

**Expected output**: 0-100

### Year-End Decay

```
for each kpi in [access, quality]:
    kpi.value += decay_rates[kpi]    # access: -2, quality: -1
```

### Stagnation Check (2014+)

```
for each kpi in all_kpis:
    if kpi.value == start_of_year_kpis[kpi.name].value:
        kpi.value += stagnant_penalty   # -0.5
```

### Initiative Effect Application

```
# Full completion (progress >= 100%)
for each kpi_name, delta in initiative.effects:
    apply_kpi_change(kpi_name, delta)

# Partial completion (50% <= progress < 100%)
for each kpi_name, delta in initiative.effects:
    apply_kpi_change(kpi_name, delta * partial_effects_multiplier)  # × 0.5
apply_kpi_change("unity", partial_unity_penalty)                    # -2

# Failed (progress < 50%)
apply_kpi_change("unity", failed_unity_penalty)                     # -3
```

### Shift Bonus (Annual)

```
for each shift in shifts:
    if shift.level > 0:
        apply_kpi_change(shift.targetKpi, shift.level)  # +1 per level
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| KPI at 100 receives positive effect | Stays at 100 (clamped) | Max is 100 per config |
| KPI at 0 receives decay | Stays at 0 (clamped) | Min is 0 per config |
| All 5 KPIs at exactly 65.0 | Victory (average = 65 >= threshold) | Threshold is >= not > |
| Stagnation check in year 2013 | Skipped — only applies from 2014+ | First year has no baseline |
| Float precision: KPI at 49.5 | Display rounds for UI, keeps float internally | Avoid integer truncation artifacts |
| Multiple effects on same KPI in one tick | Apply sequentially, clamp after each | Prevents intermediate negative values from blocking positive effects |
| Efficiency at 39 (below 40 threshold) | Initiative costs × 1.5 (Resource System handles) | KPI System just stores the value; Resource System reads it |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Config values for starting KPIs, decay, thresholds |
| Game State Manager | Upstream (hard) | Owns KPI storage; all mutations go through it |
| Initiative System | Upstream (soft) | Provides KPI deltas on completion |
| Scenario Engine | Upstream (soft) | Provides KPI deltas on choice resolution |
| Minister System | Upstream (soft) | Provides yearly KPI bonuses |
| Shift System | Upstream (soft) | Provides level-based yearly bonuses |
| Grading System | Downstream (hard) | Reads average KPI |
| Resource System | Downstream (soft) | Reads efficiency KPI for cost modifier |
| HUD / Dashboard | Downstream (soft) | Displays KPI values |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `kpis.starting_values.*` | 45-60 | 20-80 | Easier early game | Harder early game |
| `kpis.decay_rates.access_per_year` | -2 | -5 to 0 | Access harder to maintain | Access easier |
| `kpis.decay_rates.quality_per_year` | -1 | -3 to 0 | Quality harder to maintain | Quality easier |
| `kpis.stagnant_penalty` | -0.5 | -2 to 0 | Punishes passive play more | Less penalty for stagnation |
| `kpis.victory_threshold` | 65 | 50-80 | Harder to win | Easier to win |
| `kpis.min_value` | 0 | 0 | N/A (keep at 0) | N/A |
| `kpis.max_value` | 100 | 100 | N/A (keep at 100) | N/A |
| Initiative `effects` values | -3 to +3 | -5 to +5 | More volatile KPIs | Slower KPI changes |

## Acceptance Criteria

- [ ] 5 KPIs initialize with correct starting values from config
- [ ] All KPI values remain clamped to [0, 100] after any modification
- [ ] `kpi_changed` signal fires with old/new values on every change
- [ ] Natural decay applies correctly at year-end (Access -2, Quality -1)
- [ ] Stagnation penalty (-0.5) applies when KPI unchanged from year start
- [ ] Stagnation check skipped in 2013 (first year)
- [ ] Initiative full completion applies 100% of effects
- [ ] Initiative partial completion applies 50% of effects + Unity -2
- [ ] Initiative failure applies Unity -3
- [ ] Shift bonuses (+1 per level) apply at year start
- [ ] Minister bonuses apply at year start
- [ ] Average KPI calculation returns correct value
- [ ] Color zones: red < 45, orange 45-64, green >= 65
- [ ] No hardcoded KPI values — all from config.json

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should KPI values be int or float internally? | Lead Programmer | Before implementation | Float — stagnation penalty is -0.5, and partial effects use 0.5 multiplier. Display can round. |
