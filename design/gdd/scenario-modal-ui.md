# Scenario Modal UI

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 1 — Historical Authenticity; Pillar 4 — Accessible Complexity

## Overview

The Scenario Modal is a full-screen overlay that appears when a scenario triggers.
It pauses all gameplay and presents the historical context, 3+ choice cards with
costs and effects, and outcome feedback after the player decides. If no choice is
affordable, it shows the cannot-afford penalty automatically.

This is the game's dramatic moment — the "boss fight" that interrupts the routine
and forces a meaningful decision.

## Player Fantasy

Everything stops. A crisis has hit. You read the context — real history — and
study three imperfect options. The costs are real, the effects permanent. You
choose, see the outcome, and the world moves on changed.

## Detailed Design

### Core Rules

1. Triggered by `scenario_triggered` signal from Game State Manager.
2. Displays as a full-screen overlay above the HUD.
3. Timer is already paused (Game State Manager handles this).
4. Content from the scenario Dictionary:
   - Title (with emoji), category badge, context narrative
   - 3+ choice cards, each showing: label, description, costs (RM/PC badges),
     effects (KPI changes), outcome text preview
5. Choices are interactive — player clicks one to select.
6. **Affordability**: Each choice shows enabled/disabled based on player's current
   budget and PC. Unaffordable choices are greyed with costs in red.
7. **Cannot afford any**: If all choices are unaffordable, show a penalty notice
   with the `cannot_afford_penalty` effects and a "Continue" button.
8. **Resolution flow**:
   a. Player clicks a choice → show confirmation with outcome text and headline
   b. Player confirms → call `GameStateManager.resolve_scenario(choice_id)`
   c. Modal closes, timer resumes, game returns to RUNNING

### Layout

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  📋 BLUEPRINT SKEPTICISM - FIRST TEST                   │
│  [Political Event]                                       │
│                                                          │
│  Six months into the Blueprint, critics call it another  │
│  "empty promise"...                                      │
│                                                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌────────────┐ │
│  │ A) QUICK WINS   │ │ B) DATA DRIVE   │ │ C) STAY    │ │
│  │                 │ │                 │ │ COURSE     │ │
│  │ Redirect        │ │ Commission an   │ │ Maintain   │ │
│  │ resources to    │ │ independent     │ │ current    │ │
│  │ visible...      │ │ audit...        │ │ plans...   │ │
│  │                 │ │                 │ │            │ │
│  │ RM 15M  PC 12  │ │ RM 10M  PC 8   │ │ PC 5       │ │
│  │ Unity +5       │ │ Quality +3      │ │ Eff +2     │ │
│  │ Quality -2     │ │ Unity -1        │ │ Unity -3   │ │
│  │                 │ │                 │ │            │ │
│  │ [Select]        │ │ [Select]        │ │ [Select]   │ │
│  └─────────────────┘ └─────────────────┘ └────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Post-Choice Outcome Screen

After selecting a choice, show:
```
┌──────────────────────────────────────────────────────────┐
│  OUTCOME                                                 │
│                                                          │
│  "Quick wins generate positive media coverage..."        │
│                                                          │
│  📰 Headline: "MOE shows early Blueprint results"       │
│                                                          │
│  Effects Applied:                                        │
│  Unity: +5  Quality: -2  Budget: -RM 15M  PC: -12       │
│                                                          │
│                              [Continue]                   │
└──────────────────────────────────────────────────────────┘
```

### Cannot-Afford Screen

```
┌──────────────────────────────────────────────────────────┐
│  ⚠️ CANNOT AFFORD ANY OPTION                            │
│                                                          │
│  You lack the resources to respond effectively.          │
│  The situation resolves itself — poorly.                 │
│                                                          │
│  "Without resources to act, the criticism snowballs..."  │
│                                                          │
│  📰 "MOE silent as Blueprint criticism mounts"          │
│                                                          │
│  Penalties: Unity -5, Quality -2                         │
│                                                          │
│                              [Continue]                   │
└──────────────────────────────────────────────────────────┘
```

### States and Transitions

| State | Condition | Behavior |
|-------|-----------|----------|
| Hidden | No active scenario | Modal not rendered |
| Choosing | Scenario triggered, choices shown | Player selects a choice |
| Cannot Afford | All choices unaffordable | Show penalty; "Continue" to resolve |
| Outcome | Choice made, showing result | Display outcome; "Continue" to close |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Upstream (signal) | `scenario_triggered` opens modal |
| Game State Manager | Calls | `resolve_scenario(choice_id)` on confirm |
| Scenario Engine | Reads | Scenario data (already modified by callback chains) |
| Resource System | Reads | Current budget/PC for affordability display |
| HUD / Dashboard | Peer | Overlays and dims the HUD |

## Formulas

### Affordability Per Choice

```
can_afford = (budget >= choice.costs.get("budget", 0)) and
             (pc >= choice.costs.get("pc", 0))
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Scenario has only 1 choice | Show single choice card (valid but unlikely) | Data-driven |
| Choice has 0 costs | Always affordable; show "Free" badge | No cost = always available |
| Choice effects are empty | Show "No KPI effects" | Transparent |
| Player tries to close modal without choosing | Blocked — must choose or accept penalty | Scenarios are mandatory |
| Very long context text | Scrollable context area | Some scenarios have detailed narratives |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game State Manager | Upstream (hard) | Trigger signal and resolution |
| Scenario Engine | Upstream (hard) | Scenario data |
| Resource System | Upstream (hard) | Affordability check |

## Tuning Knobs

No tuning knobs — pure UI. Content comes from `scenarios.json`.

## Acceptance Criteria

- [ ] Modal appears on `scenario_triggered` signal
- [ ] Title, category, and context text display correctly
- [ ] All choices render with costs, effects, and descriptions
- [ ] Unaffordable choices are greyed out with costs in red
- [ ] Cannot-afford screen shows when all choices are too expensive
- [ ] Selected choice shows outcome text and headline
- [ ] "Continue" calls `resolve_scenario()` and closes modal
- [ ] Modal cannot be dismissed without making a choice
- [ ] Keyboard: number keys (1/2/3) select choices; Enter confirms
- [ ] Callback-modified scenarios (UPSR chain) display modified values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should there be a "thinking time" delay before choices appear? | UX Designer | Post-MVP | No — let the player read at their own pace. Context is already engaging. |
