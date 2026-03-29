# Scenario Engine

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 1 — Historical Authenticity; Pillar 2 — Meaningful Trade-offs

## Overview

The Scenario Engine manages 27 "boss fight" decision events triggered at specific
year/month combinations. Each scenario presents the player with 3+ choices, each
costing Budget and/or PC and affecting KPIs. If the player can't afford any choice,
an automatic penalty is applied. One callback chain exists: the UPSR Debate
(scenario_011) modifies the UPSR Implementation (scenario_017) based on the player's
earlier choice.

Scenarios are the game's narrative backbone — each one tells a real historical
event from Malaysia's education timeline through an interactive decision.

## Player Fantasy

Crisis hits. The timer pauses. You read the context — a real event from Malaysian
history — and weigh three imperfect options. No choice is clearly right. You spend
precious resources and live with the consequences. These are the moments you
remember and replay differently next time.

## Detailed Design

### Core Rules

1. 27 scenarios loaded from `scenarios.json` via Data Loader.
2. Each scenario has: `id`, `name`, `year`, `month` (1-12), `category`, `title`,
   `context`, `choices[]`, `cannot_afford_penalty`.
3. **Triggering**: During each month advance, check if any scenario matches
   `(current_year, current_month + 1)`. Note: game months are 0-11 internally,
   scenario months are 1-12 in data.
4. Only trigger scenarios not already in `scenarios_completed`.
5. When triggered: pause timer, set game state to SCENARIO, emit `scenario_triggered`.
6. **Callback chains**: Before presenting a scenario, check if it should be modified
   based on prior choices (see Callback Chains below).
7. **Choice resolution**:
   a. Player selects a choice.
   b. Check affordability: `budget >= choice.costs.budget` AND `pc >= choice.costs.pc`.
   c. Deduct costs from budget and PC.
   d. Apply `choice.effects` to KPIs.
   e. Apply `choice.special_effects` if present.
   f. Record `scenario.id → choice.id` in `scenarios_completed`.
   g. Add outcome to history.
   h. Clear current scenario, resume timer, return to RUNNING.
8. **Cannot afford**: If the player cannot afford ANY choice:
   a. Apply `cannot_afford_penalty` effects to KPIs.
   b. Record `scenario.id → "cannot_afford"` in `scenarios_completed`.
   c. Add penalty outcome to history.
   d. Clear scenario, resume timer.

### Callback Chains

Currently one chain exists:

**UPSR Debate → UPSR Implementation**

| Prior Choice (Debate) | Effect on Implementation |
|----------------------|------------------------|
| `upsr_a` (full abolishment) | Easier: +2 Unity to all choices, -5 PC cost |
| `upsr_b` (format changes) | Default: no modification |
| `upsr_c` (maintain UPSR) | Harder: -2 Unity to all choices, +5 PC cost |
| `cannot_afford` or not reached | Hard: -1 Unity to all choices, +3 PC cost |

The chain works by deep-cloning the scenario and modifying `choices[].effects`
and `choices[].costs` before presenting to the player.

### Special Effects

Some scenario choices have `special_effects`:

| Effect | Behavior |
|--------|----------|
| `initiatives_delayed_months: N` | Add N to `crisis_delay_months` on all active initiatives |
| `unlock_initiatives: [ids]` | Mark specific initiatives as available regardless of unlock_year |
| `bureaucracy_penalty_reduced: true` | Flag for future bureaucracy calculation |

### Scenario Categories

| Category | Count | Description |
|----------|-------|-------------|
| `political_event` | ~5 | Government changes, elections |
| `crisis_response` | ~5 | Natural disasters, emergencies |
| `policy_debate` | ~4 | Assessment reform, curriculum changes |
| `implementation_challenge` | ~4 | Rollout problems |
| `pandemic_response` | ~3 | COVID-19 and aftermath |
| `performance_review` | ~3 | International benchmarks, audits |
| `international_benchmark` | ~1 | PISA/TIMSS results |
| `strategic_pivot` | ~1 | Major direction changes |
| `milestone_review` | ~1 | PPPM milestone evaluation |

### States and Transitions

The scenario engine itself is stateless — it provides functions. The game's
SCENARIO state is managed by Game State Manager.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads `scenarios[]` array |
| Game State Manager | Upstream | Reads year/month for trigger check; `scenarios_completed` for filtering; writes scenario resolution |
| KPI System | Downstream | Choice effects applied to KPIs |
| Resource System | Downstream | Choice costs deducted from budget/PC |
| Initiative System | Downstream | Special effects: crisis delay, initiative unlocks |
| Game Timer | Downstream | Timer paused on trigger, resumed on resolution |
| Scenario Modal UI | Downstream | Provides scenario data for display |

## Formulas

### Trigger Check

```
func check_for_scenario(year: int, month_0indexed: int) -> Dictionary:
    var display_month = month_0indexed + 1  # Convert 0-11 to 1-12
    for scenario in scenarios:
        if scenario.id in scenarios_completed:
            continue
        if scenario.year == year and scenario.month == display_month:
            return apply_callback_chains(scenario, scenarios_completed)
    return null
```

### Affordability Check

```
func can_afford_any_choice(scenario: Dictionary, budget: float, pc: int) -> bool:
    for choice in scenario.choices:
        var budget_cost = choice.costs.get("budget", 0)
        var pc_cost = choice.costs.get("pc", 0)
        if budget >= budget_cost and pc >= pc_cost:
            return true
    return false
```

### UPSR Callback Modification

```
func apply_upsr_chain(scenario: Dictionary, completed: Dictionary) -> Dictionary:
    var modified = deep_clone(scenario)
    var debate_choice = find_upsr_debate_choice(completed)

    match debate_choice:
        "upsr_a":
            for choice in modified.choices:
                choice.effects["unity"] = choice.effects.get("unity", 0) + 2
                if "pc" in choice.costs:
                    choice.costs.pc = max(0, choice.costs.pc - 5)
        "upsr_c":
            for choice in modified.choices:
                choice.effects["unity"] = choice.effects.get("unity", 0) - 2
                if "pc" in choice.costs:
                    choice.costs.pc += 5
        "cannot_afford", null:
            for choice in modified.choices:
                choice.effects["unity"] = choice.effects.get("unity", 0) - 1
                if "pc" in choice.costs:
                    choice.costs.pc += 3
        # "upsr_b" = no modification (default)

    return modified
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Two scenarios at same year/month | First match triggers; second shifts to next unchecked month | Should not happen with valid data; defensive |
| Scenario triggers while another is active | Should not happen — timer is paused during SCENARIO state | State machine prevents this |
| All choices unaffordable | Apply `cannot_afford_penalty` automatically | Player is told they can't afford any option |
| Choice costs exactly match remaining budget/PC | Affordable — deduct to 0 | Exact match is valid |
| Callback chain: debate scenario was never reached | Treat as `null` — apply "no groundwork" modifier | Cold start penalty |
| Special effect `unlock_initiatives` references non-existent ID | Skip that ID; log warning | Forward-compatible |
| Scenario data has empty choices array | Apply cannot_afford_penalty | Invalid but handled gracefully |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Scenario data |
| Game State Manager | Upstream (hard) | Year/month for triggers, scenarios_completed, state transitions |
| KPI System | Downstream (hard) | Effects applied to KPIs |
| Resource System | Downstream (hard) | Costs deducted from budget/PC |
| Initiative System | Downstream (soft) | Crisis delay via special_effects |
| Game Timer | Downstream (soft) | Paused on trigger, resumed on resolution |
| Scenario Modal UI | Downstream (soft) | Provides display data |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| Scenario `choices[].costs.budget` | 0-30 | 0-50 | More expensive choices | Cheaper choices |
| Scenario `choices[].costs.pc` | 0-20 | 0-30 | Higher PC cost | Lower PC cost |
| Scenario `choices[].effects.*` | -5 to +5 | -10 to +10 | Bigger KPI swings | Subtler effects |
| `cannot_afford_penalty.*_kpi` | -2 to -5 | -10 to -1 | Harsher penalty for poverty | Milder |
| UPSR chain modifiers | ±2 Unity, ±5 PC | ±1-5 | Stronger callback impact | Weaker chain effect |
| `special_effects.initiatives_delayed_months` | 1-2 | 0-6 | More crisis disruption | Less disruption |

## Acceptance Criteria

- [ ] 27 scenarios load from JSON
- [ ] Scenarios trigger at correct year/month combinations
- [ ] Already-completed scenarios don't re-trigger
- [ ] Choice resolution deducts costs and applies effects correctly
- [ ] Cannot-afford penalty applies when all choices are too expensive
- [ ] UPSR callback chain modifies implementation scenario based on debate choice
- [ ] `special_effects.initiatives_delayed_months` adds to active initiative delays
- [ ] Timer pauses on trigger, resumes on resolution
- [ ] `scenario_triggered` and `scenario_resolved` signals fire correctly
- [ ] Deep clone prevents callback modifications from affecting base data
- [ ] Scenario month conversion (1-12 data → 0-11 internal) is correct
- [ ] No hardcoded scenarios — all from scenarios.json

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should more callback chains be added beyond UPSR? | Game Designer | Post-MVP | Start with just UPSR chain per prototype. Add more if replay testing shows opportunities. |
