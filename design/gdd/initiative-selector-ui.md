# Initiative Selector UI

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Initiative Selector is a modal overlay shown during the PLANNING phase each
January. It presents all unlocked initiatives in a filterable, searchable list.
The player toggles initiatives on/off, seeing running totals of cost (RM and PC)
and projected KPI effects. A "Confirm" button activates selected initiatives and
starts the year.

This is the most complex UI screen in the game — 30-50+ initiatives visible at
once with real-time affordability feedback.

## Player Fantasy

The planning table. You spread out your options, filter by category, compare costs,
and assemble the best portfolio your budget allows. It's the satisfying puzzle of
optimization under constraints.

## Detailed Design

### Core Rules

1. Opens as a modal overlay on the HUD when player clicks "Select Initiatives"
   (or automatically at year start).
2. Shows only unlocked initiatives (`unlock_year <= current_year`).
3. Already-purchased initiatives from previous years are NOT shown (yearly reset).
4. Each initiative card shows: name, description, category icon, adjusted cost (RM + PC),
   KPI effects, duration, linked shift.
5. Player toggles initiatives on/off by clicking.
6. Running totals panel shows: total RM cost, total PC cost, remaining budget,
   remaining PC, projected KPI changes.
7. Toggle is rejected (with feedback) if selecting would exceed budget or PC.
8. Category filter tabs: All, Infrastructure, Human Capital, Policy, Technology,
   Community, Governance.
9. Search bar filters by initiative name.
10. "Confirm" button is enabled when at least 0 initiatives are selected (0 is valid).
11. On confirm: close modal, call `GameStateManager.start_year()`.

### Layout

```
┌──────────────────────────────────────────────────────────┐
│ INITIATIVE SELECTOR — Year 2013                          │
│ [Search: ________________]                               │
│ [All|Infra|Human|Policy|Tech|Community|Gov]              │
├────────────────────────────────┬─────────────────────────┤
│ INITIATIVE LIST                │ SELECTION SUMMARY       │
│                                │                         │
│ ┌────────────────────────────┐ │ Selected: 3/available   │
│ │ ☐ Initiative Name         │ │ Budget: RM 45M / 100M   │
│ │   Category | Duration: 6mo│ │ PC:     15 / 50         │
│ │   Cost: RM 15M, PC 5      │ │                         │
│ │   Effects: Quality +2     │ │ Projected KPI Changes:  │
│ │   Shift: #4 Transform     │ │ Quality:  +4            │
│ └────────────────────────────┘ │ Equity:   +2            │
│ ┌────────────────────────────┐ │ Access:   +3            │
│ │ ☑ Initiative Name (sel)   │ │ Unity:    -1            │
│ │   ...                     │ │ Efficiency: 0           │
│ └────────────────────────────┘ │                         │
│ ...                            │ [Confirm Selection]     │
│ (scrollable)                   │ [Cancel]                │
└────────────────────────────────┴─────────────────────────┘
```

### Affordability Display

Each initiative card shows:
- **Affordable**: Normal display, clickable
- **Too expensive (RM)**: Greyed out, RM cost in red, tooltip "Insufficient budget"
- **Too expensive (PC)**: Greyed out, PC cost in red, tooltip "Insufficient PC"
- **Already selected**: Highlighted background, checkbox filled

Affordability recalculates after each toggle (remaining = total - already selected).

### States and Transitions

| State | Condition | Behavior |
|-------|-----------|----------|
| Closed | Not PLANNING phase | Modal hidden |
| Open | PLANNING phase, button clicked | Modal visible, interactive |
| Filtering | Search or category active | List filtered, totals recalculated |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Initiative System | Reads | Unlocked initiatives, adjusted costs |
| Resource System | Reads | Current budget and PC for affordability |
| Minister System | Reads | Cost modifiers for adjusted pricing display |
| Game State Manager | Calls | `toggle_initiative()` on click; `start_year()` on confirm |
| KPI System | Reads | Current KPI values for projected change display |
| HUD / Dashboard | Peer | Overlays HUD; HUD button opens this |

## Formulas

### Projected KPI Changes

```
projected = { quality: 0, equity: 0, access: 0, unity: 0, efficiency: 0 }
for each selected initiative:
    for kpi, delta in initiative.effects:
        projected[kpi] += delta
```

### Remaining Resources

```
remaining_budget = current_budget - sum(selected.adjusted_cost_rm)
remaining_pc = current_pc - sum(selected.cost_pc)
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| 0 unlocked initiatives (impossible in practice) | Show empty list with message | Graceful |
| Player deselects an initiative | Costs returned to available pool | Toggle is reversible |
| Search finds 0 results | Show "No matching initiatives" | Clear feedback |
| Budget is 0 (all spent by scenario) | All initiatives greyed out | Nothing affordable |
| Cancel button clicked | Close modal, return to PLANNING with no changes | Non-destructive |
| Player selects 0 initiatives and confirms | Valid — year starts with no active initiatives | Allowed strategy |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Initiative System | Upstream (hard) | Initiative catalog and costs |
| Resource System | Upstream (hard) | Budget/PC for affordability |
| Minister System | Upstream (soft) | Cost modifiers |
| Game State Manager | Downstream (hard) | Toggle and confirm actions |

## Tuning Knobs

No tuning knobs — this is a pure UI system. Display parameters:

| Parameter | Value | Notes |
|-----------|-------|-------|
| Cards per page | Scrollable (no pagination) | Scroll for simplicity |
| Default filter | "All" | Show everything initially |
| Sort order | By category, then by name | Consistent grouping |

## Acceptance Criteria

- [ ] Shows only initiatives with `unlock_year <= current_year`
- [ ] Category filter tabs work correctly
- [ ] Search filters by initiative name
- [ ] Toggle updates running totals (RM, PC, projected KPIs)
- [ ] Unaffordable initiatives are greyed out with reason
- [ ] Costs display adjusted values (minister discount, efficiency penalty)
- [ ] Confirm button calls `start_year()` and closes modal
- [ ] Cancel closes modal without changes
- [ ] Scrolling works for 50+ initiatives
- [ ] Keyboard: Escape closes modal

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should there be a "recommended" badge on high-value initiatives? | Game Designer | Post-MVP | Not in MVP — let players discover value themselves. |
