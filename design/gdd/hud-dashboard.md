# HUD / Dashboard

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The HUD is the main game screen — always visible during gameplay. It displays
all critical information: year/month/wave, budget and PC, 5 KPI bars, the current
minister card, active initiatives with progress, the shift grid, timer countdown,
and game controls (pause, speed, mute, save). Every piece of information the player
needs to make decisions is on this one screen.

In Godot, this is a Control-based scene tree with reactive updates driven by signals
from the Game State Manager.

## Player Fantasy

One screen tells you everything. You glance at KPI bars to spot trouble, check
your budget before the next scenario hits, watch initiative progress bars creep
forward. The dashboard IS your command center.

## Detailed Design

### Core Rules

1. The HUD is a single Godot scene (`HUD.tscn`) with a root Control node.
2. All data comes from Game State Manager signals — the HUD never calls gameplay
   methods directly (read-only relationship).
3. Updates are reactive: connect to signals, update UI elements when data changes.
4. Layout zones (from React prototype):

### Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│ HEADER BAR                                              │
│ [Title] [Year: 2013] [Month: Jan] [Wave: 1]           │
│ [Budget: RM 100M] [PC: 50] [Timer: 5:30] [Pause][⚡]  │
├──────────────┬──────────────────────────────────────────┤
│ SIDEBAR      │ MAIN CONTENT                            │
│              │                                          │
│ Minister     │ Active Initiatives                       │
│ ┌──────────┐ │ ┌──────────────────────────────────┐    │
│ │ Portrait │ │ │ Initiative 1     [████░░] 67%    │    │
│ │ Name     │ │ │ Initiative 2     [██░░░░] 33%    │    │
│ │ Nickname │ │ │ Initiative 3     [██████] 100%   │    │
│ │ Priority │ │ └──────────────────────────────────┘    │
│ │ Agenda   │ │                                          │
│ └──────────┘ │ Shifts Grid                             │
│              │ ┌────┬────┬────┬────┐                   │
│ KPI Bars     │ │ S1 │ S2 │ S3 │ S4 │ ...             │
│ Quality  [██████░░] 67 │ │ Lv2│ Lv0│ Lv1│ Lv3│        │
│ Equity   [████░░░░] 52 │ └────┴────┴────┴────┘        │
│ Access   [███░░░░░] 43 │                               │
│ Unity    [█████░░░] 58 │ Recent Events                 │
│ Efficiency[██████░] 72 │ • Scenario resolved: ...      │
│              │ • Initiative completed: ...              │
├──────────────┴──────────────────────────────────────────┤
│ [Select Initiatives] (visible in PLANNING phase only)   │
└─────────────────────────────────────────────────────────┘
```

### UI Elements

| Element | Node Type | Updates On | Data Source |
|---------|-----------|-----------|-------------|
| Year display | Label | `year_started` | GameState.year |
| Month display | Label | `month_advanced` | GameState.month (converted to name) |
| Wave display | Label | `year_started` | GameState.current_wave |
| Budget display | Label | `budget_changed` | GameState.budget |
| PC display | Label | `pc_changed` | GameState.political_capital |
| Timer countdown | Label | `_process` | GameTimer.get_time_remaining_in_year() |
| KPI bars (×5) | ProgressBar + Label | `kpi_changed` | GameState.kpis[name].value |
| KPI bar colors | StyleBox | `kpi_changed` | Red <45, Orange 45-64, Green >=65 |
| Minister portrait | TextureRect | `year_started` | minister.portrait |
| Minister name | Label | `year_started` | minister.name, minister.nickname |
| Minister agenda | Label | `year_started` | minister.agenda.description |
| Active initiatives | VBoxContainer | `year_started`, `month_advanced` | GameState.active_initiatives |
| Initiative progress | ProgressBar | `month_advanced` | active_initiative.progress_percent |
| Shift grid | GridContainer | `year_started` | GameState.shifts |
| Shift level/XP | Label + ProgressBar | `year_started` | shift.level, shift.xp/nextLevelXp |
| Recent events | VBoxContainer | `history_updated` | GameState.history (last 5) |
| Pause button | Button | `timer_paused`/`timer_resumed` | Toggle icon |
| Speed button | Button | `speed_changed` | Display current speed |
| Select Initiatives btn | Button | `phase_changed` | Visible only in PLANNING |

### Signal Connections

```gdscript
func _ready():
    GameStateManager.kpi_changed.connect(_on_kpi_changed)
    GameStateManager.budget_changed.connect(_on_budget_changed)
    GameStateManager.pc_changed.connect(_on_pc_changed)
    GameStateManager.month_advanced.connect(_on_month_advanced)
    GameStateManager.year_started.connect(_on_year_started)
    GameStateManager.phase_changed.connect(_on_phase_changed)
    GameStateManager.history_updated.connect(_on_history_updated)
    GameStateManager.scenario_triggered.connect(_on_scenario_triggered)
    GameTimer.timer_paused.connect(_on_timer_paused)
    GameTimer.timer_resumed.connect(_on_timer_resumed)
```

### States and Transitions

The HUD doesn't have states — it's always visible. Certain elements show/hide
based on game phase:

| Phase | Visible Elements | Hidden Elements |
|-------|-----------------|-----------------|
| PLANNING | "Select Initiatives" button, full dashboard | Timer countdown (paused) |
| RUNNING | Full dashboard, timer countdown | "Select Initiatives" button |
| SCENARIO | Dashboard dimmed behind Scenario Modal | Interactive elements disabled |
| GAME_OVER | Hidden behind Game Over Screen | Everything |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Upstream (signals) | All game state changes |
| Game Timer | Upstream (signals + polling) | Timer state; countdown via `_process` |
| Initiative Selector UI | Triggers | "Select Initiatives" button opens the selector modal |
| Scenario Modal UI | Peer | Scenario modal overlays the HUD |
| Save/Load UI | Triggers | Save/Load button opens the modal |

## Formulas

### Month Name Conversion

```
const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
display_month = MONTH_NAMES[month]  # month is 0-11
```

### KPI Bar Color

```
if value < 45: return Color.RED
elif value < 65: return Color.ORANGE
else: return Color.GREEN
```

### Timer Display

```
var remaining = GameTimer.get_time_remaining_in_year()
timer_label.text = "%d:%02d" % [remaining.minutes, remaining.seconds]
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| KPI changes rapidly (multiple in one frame) | Each signal updates independently; no batching needed | Godot processes signals synchronously |
| Window resized | UI scales via anchors/containers | Godot Control node layout system |
| 0 active initiatives | Show empty list with "No active initiatives" text | Visual feedback |
| History has 0 entries | Show empty events panel | Clean initial state |
| Very long initiative names | Truncate with ellipsis in the list | Fixed-width layout |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game State Manager | Upstream (hard) | All displayed data |
| Game Timer | Upstream (hard) | Countdown display |
| Initiative Selector UI | Peer (soft) | Opens modal |
| Scenario Modal UI | Peer (soft) | Overlay relationship |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Notes |
|-----------|--------------|------------|-------|
| KPI red threshold | 45 | 30-60 | Match `config.kpis` thresholds |
| KPI green threshold | 65 | 50-80 | Match victory threshold |
| Events history count | 5 | 3-10 | More events = more scrolling |
| Timer update frequency | Every frame | Every frame | Smooth countdown |

## Acceptance Criteria

- [ ] All 5 KPI bars display correct values with color coding
- [ ] KPI bars update reactively on `kpi_changed` signal
- [ ] Budget and PC displays update on change signals
- [ ] Timer countdown updates smoothly every frame
- [ ] Minister card shows correct portrait, name, agenda
- [ ] Active initiatives show with progress bars
- [ ] Shift grid displays all 11 shifts with level indicators
- [ ] Recent events panel shows last 5 entries
- [ ] "Select Initiatives" button visible only in PLANNING phase
- [ ] Pause/resume button toggles timer
- [ ] Speed button cycles through 1x/1.5x/2x
- [ ] Month display converts 0-11 to Jan-Dec names
- [ ] Layout doesn't break at common window sizes

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Fixed resolution or responsive? | UX Designer | Before implementation | Start with fixed 1280×720 viewport. Add scaling later if needed. |
| Dark or light theme? | Art Director | Before implementation | Match the React prototype's style initially. |
