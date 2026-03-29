# Minister System

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 1 — Historical Authenticity

## Overview

The Minister System manages the rotation of 5 Education Ministers across the
13-year timeline, each with unique agendas, KPI bonuses, and cost modifiers.
Ministers change at year boundaries according to their `start_year`/`end_year`
ranges. Each minister creates a distinct strategic pressure — their agenda KPI
target rewards you with PC if met, and their bonuses shift which KPIs are easier
to improve during their tenure.

## Player Fantasy

Your boss changes every few years. Each new minister arrives with priorities that
may clash with your long-term strategy. You must adapt without abandoning your
plan. The transitions feel historically grounded — real political shifts with
real consequences.

## Detailed Design

### Core Rules

1. 5 ministers loaded from `ministers.json` via Data Loader.
2. The current minister is determined by year: the minister whose
   `[start_year, end_year]` range contains the current year.
3. Minister transitions occur during year-end processing when the next year
   falls outside the current minister's range.
4. On transition: show `transition_out` message for departing minister, then
   `transition_in` message for arriving minister.
5. **Minister Bonuses**: At year start, apply the minister's `bonuses` dict to KPIs
   (e.g., `{ "efficiency": 5 }` adds +5 Efficiency).
6. **Cost Modifiers**: Minister's `cost_modifiers` dict gives percentage discounts
   on matching initiative categories (e.g., `{ "efficiency_initiatives": -10 }`
   means 10% cheaper).
7. **Agenda**: Each minister has a target KPI and threshold. If that KPI >= target
   at year-end, player receives `agenda.reward_pc` Political Capital.
8. Minister data is read-only — the system never modifies minister records.

### Minister Timeline

| # | Name | Years | Wave | Priority KPI | Agenda Target | Bonus |
|---|------|-------|------|-------------|---------------|-------|
| 1 | Tan Sri Moo-Hidin | 2013-2015 | 1 | Efficiency | Efficiency >= 70 | Efficiency +5 |
| 2 | Dato' Seri Mad-Zir | 2016-2018 | 2 | Equity | Equity >= 60 | Equity +5 |
| 3 | Dr. Maz-Lee | 2018-2020 | 2 | Quality | Quality >= 65 | Quality +3 |
| 4 | Dr. Rad-Zee | 2020-2022 | 3 | Access | Access >= 55 | Access +5 |
| 5 | Ms. Fadz-Lina | 2023-2025 | 3 | Unity | Unity >= 60 | Unity +5 |

### States and Transitions

No internal states — the minister is determined by year lookup. Transitions are
events, not state changes.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `ministers[]` array |
| Game State Manager | Upstream | `current_minister` stored in GameState; updated at year-end |
| KPI System | Downstream | Minister `bonuses` applied as KPI changes at year start |
| Resource System | Downstream | `cost_modifiers` read by Resource System for initiative cost calculation |
| Resource System | Downstream | `agenda.reward_pc` granted if agenda met at year-end |
| Year Cycle Engine | Upstream | Triggers minister check and transition at year boundaries |
| HUD / Dashboard | Downstream | Displays minister portrait, name, nickname, agenda, priority text |

## Formulas

### Minister Lookup

```
func get_minister_for_year(year: int) -> Dictionary:
    for minister in ministers:
        if minister.start_year <= year and year <= minister.end_year:
            return minister
    return current_minister  # fallback: keep current
```

### Agenda Check (Year-End)

```
if kpis[minister.agenda.kpi].value >= minister.agenda.target:
    apply_pc_change(minister.agenda.reward_pc)
    add_history_entry(minister.agenda.reward_text)
```

### Cost Modifier Lookup

```
func get_minister_discount(category: String) -> float:
    var key = category + "_initiatives"
    return minister.cost_modifiers.get(key, 0)  # e.g., -10 means 10% discount
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Two ministers cover overlapping years (data error) | First match wins (array order) | Defensive; should not happen with valid data |
| No minister found for a year | Keep previous minister; log warning | Fail gracefully |
| Minister transition and scenario in same year-end | Process minister transition first, then scenario check | Minister bonuses should apply before scenario |
| Agenda target exactly met (KPI == target) | Reward granted (>= check) | Threshold is inclusive |
| Minister has no cost_modifiers field | Return 0 discount for all categories | Optional field in schema |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Minister data |
| Game State Manager | Upstream (hard) | Stores current minister |
| KPI System | Downstream (soft) | Receives bonus KPI changes |
| Resource System | Downstream (soft) | Reads cost modifiers; receives PC reward |
| Year Cycle Engine | Upstream (hard) | Triggers transitions |
| HUD / Dashboard | Downstream (soft) | Displays minister info |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `minister.bonuses.*` | +3 to +5 | 0 to +10 | Stronger KPI boost per minister | Weaker minister impact |
| `minister.cost_modifiers.*` | -10 to -15% | -30% to 0% | Bigger discounts on matching initiatives | Less minister benefit |
| `minister.agenda.target` | 55-70 | 40-90 | Harder to earn agenda reward | Easier agenda completion |
| `minister.agenda.reward_pc` | 20-30 | 10-50 | More PC incentive to follow agenda | Less incentive |

## Acceptance Criteria

- [ ] Correct minister active for each year (2013-2025)
- [ ] Minister transition fires at year boundary with transition messages
- [ ] Minister bonuses apply to KPIs at year start
- [ ] Cost modifiers reduce matching category initiative costs
- [ ] Agenda reward grants PC when target KPI met at year-end
- [ ] Minister portrait and info display correctly in HUD
- [ ] No crash if minister data is missing for a year (graceful fallback)
- [ ] All minister data comes from JSON — no hardcoded names or values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should minister portraits be emotion-based (happy/neutral/angry) like the React prototype? | Art Director | Before UI implementation | Nice-to-have for Full Vision tier. Start with static portrait. |
