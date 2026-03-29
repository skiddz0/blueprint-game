# Game State Manager

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity (clear state transitions the player can follow)

## Overview

The Game State Manager is the central state machine that owns the master `GameState`
and controls the flow between game phases: main menu, planning, running, scenario,
year-end, and game over. It is the hub that all gameplay and UI systems connect to.
In the React prototype, this was the `useGameEngine` hook in `App.tsx`; in Godot,
it becomes an autoload singleton (`GameStateManager.gd`) that holds game state as
a typed Dictionary/Resource and emits signals on every state transition.

The player experiences this system as the game's rhythm: "pick initiatives in January,
watch the year play out, respond to scenarios, see year-end results, repeat."

## Player Fantasy

The player feels in control of a 13-year plan unfolding in real-time. The state
machine creates the pacing — the tense pause when a scenario appears, the
anticipation of year-end results, the relief or dread of seeing KPI changes.
The state machine IS the game's narrative structure.

## Detailed Design

### Core Rules

1. The Game State Manager is an **autoload singleton** (`GameStateManager.gd`),
   available globally as `GameStateManager`.
2. It depends on `DataLoader` being in the `Loaded` state before initialization.
3. On `initialize_game()`, it:
   a. Reads config, initiatives, ministers, shifts from `DataLoader`
   b. Creates the initial `GameState` for year 2013, month 0
   c. Sets starting KPI values from `config.kpis.starting_values`
   d. Sets starting budget from `config.resources.starting_budget`
   e. Sets starting PC from `config.resources.starting_pc`
   f. Initializes 11 shift records from shifts data
   g. Finds the starting minister (start_year = 2013)
   h. Marks all initiatives as unselected/unpurchased
   i. Transitions to `PLANNING` phase
4. The game state is a single Dictionary (or custom Resource) that contains all
   mutable game data. No other system owns mutable game state — they read from
   this and request changes via methods.
5. State changes happen only through public methods on the manager. No direct
   mutation of the state Dictionary from outside.

### Game State Structure

```
GameState = {
  # Time
  year: int,                    # 2013-2025
  month: int,                   # 0-11 (0=Jan, 11=Dec)
  current_wave: int,            # 1, 2, or 3

  # Resources
  budget: float,                # Current available RM
  total_budget: float,          # Total for year (before spending)
  political_capital: int,       # 0-100

  # KPIs
  kpis: Dictionary,             # { "quality": { "name": "quality", "value": 45, "description": "..." }, ... }
  start_of_year_kpis: Dictionary,  # Snapshot at year start for comparison
  mid_year_kpis: Dictionary,       # Snapshot at month 6

  # Initiatives
  initiatives: Array,           # Full catalog with is_purchased, selected flags
  active_initiatives: Array,    # Currently running initiatives with progress

  # Shifts
  shifts: Dictionary,           # { 1: { id, level, xp, ... }, 2: ..., 11: ... }

  # Minister
  current_minister: Dictionary,

  # Scenarios
  current_scenario: Dictionary, # or null
  scenarios_completed: Dictionary,  # { "scenario_001": "choice_a", ... }

  # Flags
  show_mid_year_review: bool,
  has_october_budget_penalty: bool,
  october_unspent_budget: float,

  # History
  history: Array[String],       # Recent event log entries
  completed_initiative_count: int,

  # Game Over
  game_over: bool,
  game_won: bool,
  final_grade: String           # "S"|"A"|"B"|"C"|"D"|"F" or ""
}
```

### States and Transitions

| State | Entry Condition | Behavior | Exit Conditions |
|-------|----------------|----------|-----------------|
| `UNINITIALIZED` | App start | No game state exists | `initialize_game()` → PLANNING |
| `PLANNING` | Year start (month 0) or `initialize_game()` | Player selects initiatives for the year. Timer paused. | `start_year()` → RUNNING |
| `RUNNING` | `start_year()` called | Timer ticks months. Initiatives progress. Scenarios may trigger. | Month advances → check for scenario; Year ends → YEAR_END |
| `SCENARIO` | Scenario triggers at current year/month | Timer paused. Scenario modal shown. Player must choose. | `resolve_scenario(choice_id)` → RUNNING |
| `YEAR_END` | Month 11 completes | Process initiative completion, apply decay, calculate next budget, check for minister change, advance year. | Not game over → PLANNING; Game over → GAME_OVER |
| `GAME_OVER` | Year > 2025 after YEAR_END | Calculate final grade. Show results. | `restart_game()` → PLANNING (2013) |
| `PAUSED` | Player pauses during RUNNING | Timer paused, all processing halted | Player unpauses → RUNNING |

**Valid Transitions:**
```
UNINITIALIZED → PLANNING
PLANNING → RUNNING
RUNNING → SCENARIO (scenario triggers)
RUNNING → PAUSED (player pauses)
RUNNING → YEAR_END (month 11 ends)
SCENARIO → RUNNING (choice made)
PAUSED → RUNNING (unpause)
YEAR_END → PLANNING (next year)
YEAR_END → GAME_OVER (year > 2025)
GAME_OVER → PLANNING (restart)
```

### Key Methods

| Method | From State | Effect |
|--------|-----------|--------|
| `initialize_game()` | UNINITIALIZED | Create initial state, emit `game_initialized` |
| `toggle_initiative(id)` | PLANNING | Toggle initiative selection; emit `initiative_toggled` |
| `start_year()` | PLANNING | Activate selected initiatives, deduct costs, award shift XP; emit `year_started` → RUNNING |
| `advance_month()` | RUNNING | Increment month, update initiative progress, check for scenario trigger; emit `month_advanced` |
| `trigger_scenario(scenario)` | RUNNING | Set current_scenario, pause timer; emit `scenario_triggered` → SCENARIO |
| `resolve_scenario(choice_id)` | SCENARIO | Apply choice effects/costs, record completion, clear scenario; emit `scenario_resolved` → RUNNING |
| `check_october_budget()` | RUNNING (month 9) | Flag penalty if budget > threshold; emit `october_checked` |
| `process_year_end()` | RUNNING (month 11 ends) | Process completions, apply decay, calculate next budget, advance year; emit `year_ended` → YEAR_END or GAME_OVER |
| `apply_kpi_change(kpi, delta)` | Any active state | Clamp and update KPI value; emit `kpi_changed` |
| `apply_budget_change(delta)` | Any active state | Update budget; emit `budget_changed` |
| `apply_pc_change(delta)` | Any active state | Clamp PC to 0-max; emit `pc_changed` |
| `add_history_entry(text)` | Any active state | Append to history array; emit `history_updated` |
| `restart_game()` | GAME_OVER | Re-initialize for 2013; emit `game_restarted` |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Data Loader | Upstream | Reads all game data during `initialize_game()` |
| Game Timer | Bidirectional | Timer calls `advance_month()` on tick; manager pauses/resumes timer on state transitions |
| KPI System | Downstream | KPI System reads `kpis` from state; requests changes via `apply_kpi_change()` |
| Resource System | Downstream | Resource System reads `budget`/`political_capital`; requests changes via `apply_budget_change()`/`apply_pc_change()` |
| Initiative System | Downstream | Reads `initiatives`/`active_initiatives`; requests changes via `toggle_initiative()`/`start_year()` |
| Scenario Engine | Bidirectional | Engine calls `trigger_scenario()`; manager calls `resolve_scenario()` on player choice |
| Minister System | Downstream | Reads `current_minister`; manager handles transitions during `process_year_end()` |
| Shift System | Downstream | Reads `shifts`; updated during `start_year()` (XP) and `process_year_end()` (bonuses) |
| Year Cycle Engine | Bidirectional | Orchestrates the yearly flow by calling manager methods in sequence |
| All UI Systems | Downstream | UI reads state and connects to signals for reactive updates |
| Save/Load System | Bidirectional | Serializes/deserializes the full `GameState` dictionary |

### Signals

```gdscript
signal game_initialized
signal phase_changed(new_phase: String)
signal year_started(year: int)
signal month_advanced(year: int, month: int)
signal scenario_triggered(scenario: Dictionary)
signal scenario_resolved(scenario_id: String, choice_id: String)
signal october_checked(has_penalty: bool)
signal year_ended(year: int, results: Dictionary)
signal kpi_changed(kpi_name: String, old_value: float, new_value: float)
signal budget_changed(old_value: float, new_value: float)
signal pc_changed(old_value: int, new_value: int)
signal initiative_toggled(initiative_id: String, selected: bool)
signal history_updated(entry: String)
signal game_over(won: bool, grade: String)
signal game_restarted
```

UI systems connect to these signals for reactive updates — the Godot equivalent
of React's `useState` re-renders.

## Formulas

No formulas live in the Game State Manager directly. It delegates all calculations:
- KPI changes → KPI System
- Budget calculations → Resource System
- Initiative progress → Initiative System
- Grade calculation → Grading System

The manager is a **coordinator**, not a calculator. It calls methods on other
systems and applies their results to the central state.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| `initialize_game()` called when DataLoader not loaded | Wait for `data_loaded` signal, then initialize | Prevent null reference on data access |
| Two scenarios scheduled for same year/month | Trigger first by array order; second triggers next month | Avoid stacking scenario modals |
| Player selects initiatives exceeding budget | `toggle_initiative()` rejects; emit signal with reason | Budget check happens per-toggle, not batch |
| Player selects initiatives exceeding PC | `toggle_initiative()` rejects; emit signal with reason | Same as budget |
| `advance_month()` called in PLANNING state | Ignored — only valid in RUNNING state | State machine guards prevent invalid transitions |
| Year advances past 2025 | Transition to GAME_OVER after year-end processing | 2025 is the final year; process it, then end |
| KPI change would set value below 0 or above 100 | Clamp to [0, 100] in `apply_kpi_change()` | Config defines min/max; never violate |
| PC change would exceed max (100) | Clamp to `config.resources.max_pc` | Defined in config |
| `restart_game()` called during RUNNING | Allowed — reinitializes everything | Player may want to restart mid-game |
| Minister transition mid-year | Handled during `process_year_end()`; never mid-year | Ministers change at year boundaries per prototype |
| No minister found for a year | Use previous minister; log warning | Should never happen with valid data, but fail gracefully |
| Save/Load restores state to SCENARIO phase | Restore current_scenario and transition to SCENARIO | Player was mid-scenario when they saved |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Data Loader | Upstream (hard) | Cannot initialize without loaded game data |
| Game Timer | Peer (hard) | Timer drives month advancement; manager controls timer pause/resume |
| KPI System | Downstream (hard) | Reads KPI state; all KPI mutations go through manager |
| Resource System | Downstream (hard) | Reads budget/PC; all resource mutations go through manager |
| Initiative System | Downstream (hard) | Reads initiative catalog and active list from state |
| Scenario Engine | Downstream (hard) | Reads scenario data; triggers flow through manager |
| Minister System | Downstream (hard) | Reads current minister from state |
| Shift System | Downstream (hard) | Reads shift records from state |
| Year Cycle Engine | Downstream (hard) | Orchestrates by calling manager methods |
| All UI Systems | Downstream (soft) | UI observes state via signals; game works headless without UI |
| Save/Load System | Downstream (soft) | Serializes state; game works without persistence |

## Tuning Knobs

The Game State Manager has no tuning knobs of its own — it is structural. All
tunable values flow through it from `config.json` via the Data Loader and are
applied by the specialized systems (KPI, Resource, Initiative, etc.).

| Structural Parameter | Value | Rationale |
|---------------------|-------|-----------|
| Start year | 2013 | Fixed by historical setting |
| End year | 2025 | Fixed by PPPM timeline |
| Months per year | 12 | Fixed |
| Planning month | 0 (January) | Fixed by game design |

## Visual/Audio Requirements

None directly. The Game State Manager is backend infrastructure. UI systems observe
its signals and render accordingly. Audio Manager may connect to signals like
`year_started`, `scenario_triggered`, `game_over` to trigger sound cues.

## UI Requirements

None directly. All UI systems read from `GameState` and connect to the signals
listed above. The manager does not know about UI — it only emits signals.

## Acceptance Criteria

- [ ] `initialize_game()` creates valid state for 2013 with correct starting KPIs, budget, PC
- [ ] State machine only allows valid transitions (PLANNING→RUNNING, not PLANNING→YEAR_END)
- [ ] `toggle_initiative()` rejects selection when budget or PC insufficient
- [ ] `advance_month()` increments month from 0-11 correctly
- [ ] `trigger_scenario()` pauses timer and sets SCENARIO state
- [ ] `resolve_scenario()` applies effects and returns to RUNNING state
- [ ] `process_year_end()` transitions to GAME_OVER when year > 2025
- [ ] `process_year_end()` transitions to PLANNING for years 2013-2025
- [ ] All signals emit with correct parameters
- [ ] `kpi_changed` signal fires for every KPI modification
- [ ] KPI values never exceed [0, 100] range
- [ ] PC never exceeds `config.resources.max_pc`
- [ ] `restart_game()` produces identical state to first `initialize_game()`
- [ ] State is serializable to Dictionary for save/load (no non-serializable types)
- [ ] No hardcoded game values — all constants from config.json via Data Loader
- [ ] Game runs correctly headless (no UI connected) — signals emit, state updates

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should GameState be a custom Resource class or a plain Dictionary? | Lead Programmer | Before implementation | Dictionary is simpler and serializable; custom Resource adds type safety. Start with Dictionary, refactor if needed. |
| Should Year Cycle Engine be merged into Game State Manager? | Game Designer | Before implementation | Keep separate — Year Cycle orchestrates the sequence of calls across systems; Game State Manager owns the data. Merging would violate single-responsibility. |
| Should the manager own the timer or just interact with it? | Lead Programmer | Before implementation | Separate — Game Timer is its own autoload. Manager calls `GameTimer.pause()` / `GameTimer.resume()`. This allows the timer to be tested independently. |
