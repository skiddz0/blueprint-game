# Sprint 1 — MVP Foundation

> **Sprint Goal**: Get the core game loop running in Godot: load JSON data,
> initialize game state, select initiatives, tick months, trigger scenarios,
> process year-end — one complete year (2013) playable end-to-end.
>
> **Milestone**: MVP (Wave 1 playable)
> **Created**: 2026-03-29
> **Status**: Not Started

---

## Scope

Systems 1-14 from the systems index (Foundation through Presentation layers),
targeting the MVP priority tier. Source reference: React prototype at
`D:\git\dev\pppm_story_v2`.

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Description | Dependencies | Acceptance Criteria |
|----|------|-------------|-------------|-------------------|
| S1-01 | Copy game-data/ | Copy all 7 JSON files from prototype to `res://game-data/` | None | Files present at `res://game-data/`, valid JSON, identical to prototype |
| S1-02 | Data Loader | Autoload `DataLoader.gd`: load & cache 7 JSON files via FileAccess, typed accessors (`get_config()`, `get_initiatives()`, etc.), convenience queries (`get_initiatives_by_category()`, `get_scenario_by_year_month()`, etc.), `data_loaded`/`data_load_failed` signals | S1-01 | All 7 files load; `data_loaded` signal fires; query methods return correct data; error signal on missing file |
| S1-03 | Game State Manager | Autoload `GameStateManager.gd`: state machine (UNINITIALIZED→PLANNING→RUNNING→SCENARIO→YEAR_END→GAME_OVER→PAUSED), central GameState dictionary, `initialize_game()`, 14 signals, public methods for state mutation (`apply_kpi_change`, `apply_budget_change`, `apply_pc_change`, `toggle_initiative`, etc.) | S1-02 | `initialize_game()` creates valid 2013 state with correct starting KPIs/budget/PC; only valid phase transitions allowed; all signals emit |
| S1-04 | KPI System | Pure functions in `kpi_system.gd`: validate/clamp KPI values (0-100), calculate average KPI, apply decay (Access -2, Quality -1), apply stagnation penalty (-0.5 if unchanged from 2014+), color zone thresholds | S1-02 | Starting values match config; clamp enforced; decay correct at year-end; stagnation skipped in 2013 |
| S1-05 | Resource System | Pure functions in `resource_system.gd`: calculate next year budget (wave base + performance modifier ± October penalty, floor RM 10M), calculate initiative cost adjustment (minister discount + efficiency penalty), PC regeneration (floor(unity/5)), performance modifier lookup | S1-02, S1-04 | Budget recalculation matches prototype formulas; October penalty flags at month 9 when budget > RM 10M; PC regen correct |
| S1-06 | Game Timer | Autoload `GameTimer.gd`: `_process(delta)` accumulation, 30s months, 12 months/year, pause/resume/stop/reset, speed multiplier (1x/1.5x/2x), `month_advanced`/`year_ended`/`timer_paused`/`timer_resumed` signals, delta spike protection | S1-03 | Months tick at 30s (1x); pause/resume halts/continues; `month_advanced` fires with correct month; `year_ended` fires after month 11; large delta doesn't skip months |
| S1-07 | Minister System | Pure functions in `minister_system.gd`: lookup minister by year, get minister discount for initiative category, check agenda (KPI >= target → reward PC) | S1-02, S1-03 | Correct minister for each year 2013-2025; bonuses apply; cost modifiers reduce matching category costs; agenda rewards PC when met |
| S1-08 | Shift System | Pure functions in `shift_system.gd`: award XP to shift, process level-up with [3,3,4,4,5] progression and XP carryover, calculate yearly KPI bonus (+level per shift) | S1-02, S1-04 | XP awards trigger level-ups correctly; max level 5 caps; yearly bonus adds +level to target KPI; overflow XP carries over |
| S1-09 | Initiative System | Pure functions in `initiative_system.gd`: filter unlocked by year, calculate adjusted cost (minister + efficiency), activate selected initiatives, advance monthly progress (100/duration per month + crisis delay), evaluate completion (full/partial/failed), apply bureaucracy penalty (-0.5 or -0.25 from 2024+) | S1-02, S1-04, S1-05, S1-08 | Toggle selection respects budget/PC; costs deducted on activation; progress advances monthly; completion effects apply correctly for all 3 tiers; bureaucracy penalty applied |
| S1-10 | Scenario Engine | Pure functions in `scenario_engine.gd`: check trigger by (year, month), check affordability per choice, apply choice effects (KPI + costs + special_effects), apply cannot-afford penalty, UPSR callback chain (modify implementation scenario based on debate choice) | S1-02, S1-04, S1-05, S1-03 | Scenarios trigger at correct year/month; effects apply; cannot-afford penalty works; UPSR chain modifies choices correctly for all 4 debate outcomes |
| S1-11 | Year Cycle Engine | Autoload `YearCycleEngine.gd`: orchestrate full annual sequence — connect to timer signals, coordinate planning→activation→monthly ticks→scenario checks→mid-year snapshot→October check→year-end processing (initiatives→decay→stagnation→PC regen→minister agenda→budget recalc→minister transition→game over check) | S1-06 thru S1-10 | Full year 2013 plays through with correct processing order; year-end advances to 2014 PLANNING; game over triggers after 2025 |
| S1-12 | Minimal HUD | Scene `HUD.tscn`: header (year/month/wave, budget/PC, timer countdown), sidebar (minister card with name/agenda, 5 KPI bars with color coding and values), main content (active initiatives with progress bars, shift grid with levels), "Select Initiatives" button (PLANNING phase only) | S1-03, S1-04, S1-05, S1-06, S1-07 | All values display correctly; KPI bars update reactively on signals; timer countdown updates every frame; month names (Jan-Dec) display correctly; minister info updates on year change |
| S1-13 | Initiative Selector UI | Scene `InitiativeSelector.tscn`: modal overlay, category filter tabs (All/Infra/Human/Policy/Tech/Community/Gov), scrollable initiative list with cards (name, cost, effects, duration), selection toggle with affordability enforcement, running totals (RM/PC spent/remaining, projected KPI changes), Confirm/Cancel buttons | S1-09, S1-05 | Shows only unlocked initiatives; category filter works; toggle updates totals; unaffordable greyed out; confirm calls start_year() and closes; cancel closes without changes |
| S1-14 | Scenario Modal UI | Scene `ScenarioModal.tscn`: full-screen overlay, scenario title/category/context, 3+ choice cards (label, description, costs, effects), affordability display (greyed if can't afford), cannot-afford screen with penalty, outcome screen with headline, Continue button | S1-10, S1-05 | Appears on scenario_triggered; choices display correctly; unaffordable greyed; selection applies effects; cannot-afford shows penalty; Continue closes and resumes |

### Should Have

| ID | Task | Description | Dependencies | Acceptance Criteria |
|----|------|-------------|-------------|-------------------|
| S1-15 | Grading System | Pure function in `grading_system.gd`: calculate grade (S/A/B/C/D/F) from average KPI using config thresholds, determine win/loss | S1-04 | Correct grade at all threshold boundaries; victory at avg >= 65 |
| S1-16 | Game Over Screen | Scene `GameOverScreen.tscn`: grade display, win/loss message, 5 KPI final values with bars, average KPI, Play Again button (calls restart_game()) | S1-15, S1-03 | Shows on game_over signal; correct grade; KPI bars match final values; Play Again restarts to 2013 |
| S1-17 | Event Log | Panel in HUD: last 5 entries from GameState.history, updates on history_updated signal, reverse chronological | S1-03 | Updates reactively; most recent at top; handles empty state |

### Nice to Have

| ID | Task | Description | Dependencies | Acceptance Criteria |
|----|------|-------------|-------------|-------------------|
| S1-18 | Speed Controls | Speed buttons on HUD (1x/1.5x/2x), calls GameTimer.set_speed() | S1-06 | Speed changes reflected in timer; display shows current speed |
| S1-19 | Pause Button | Toggle button on HUD, calls GameTimer.toggle_pause() | S1-06 | Pause halts timer; resume continues; icon toggles |

---

## Implementation Order

Recommended coding sequence (respects dependencies):

```
Phase A — Data Foundation
  S1-01  Copy game-data/
  S1-02  Data Loader autoload

Phase B — Core Systems (can parallel after Data Loader)
  S1-03  Game State Manager autoload
  S1-04  KPI System functions
  S1-05  Resource System functions

Phase C — Feature Systems (can parallel after Core)
  S1-06  Game Timer autoload
  S1-07  Minister System functions
  S1-08  Shift System functions

Phase D — Complex Systems (depends on C)
  S1-09  Initiative System functions
  S1-10  Scenario Engine functions

Phase E — Orchestration
  S1-11  Year Cycle Engine autoload

Phase F — UI (can start after Phase B, complete after Phase E)
  S1-12  Minimal HUD
  S1-13  Initiative Selector UI
  S1-14  Scenario Modal UI

Phase G — Should Have (after Phase E)
  S1-15  Grading System
  S1-16  Game Over Screen
  S1-17  Event Log
```

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Godot 4.6 JSON/FileAccess API differs from expectations | Medium | Medium | Reference `docs/engine-reference/godot/` before implementing; test with actual files early (S1-02) |
| Godot Control node UI layout complexity | Medium | High | Start with minimal HUD (S1-12); iterate; reference `docs/engine-reference/godot/modules/ui.md` |
| Year Cycle orchestration bugs (wrong processing order) | Low | High | Test with 2013 only first; compare KPI values against prototype results |
| Signal connection complexity | Low | Medium | Follow ADR-001 patterns; all connections in `_ready()` |
| Initiative cost adjustment edge cases | Low | Medium | Port formulas directly from `gameCalculations.ts`; test with known values |

---

## Dependencies on External Factors

- Godot 4.6 editor must be installed and project file configured
- JSON files from `D:\git\dev\pppm_story_v2\game-data\` accessible for copy
- Godot MCP connection active for scene creation (optional — can create scenes manually)

---

## Definition of Done

- [ ] All Must Have tasks (S1-01 through S1-14) completed
- [ ] Wave 1 (2013-2015) playable end-to-end: 3 full years with planning, monthly ticks, scenarios, year-end processing
- [ ] Minister Moo-Hidin active 2013-2015 with correct bonuses and agenda
- [ ] Year-end minister transition visible (Moo-Hidin → Mad-Zir at 2015→2016 boundary if extended to 2016)
- [ ] KPI decay, stagnation, and shift bonuses compound correctly across years
- [ ] Budget recalculates each year with performance modifier and October penalty
- [ ] JSON files from React prototype load without modification
- [ ] KPI values match expected behavior from prototype formulas
- [ ] Budget/PC calculations match prototype (test with known inputs)
- [ ] No crashes during a 3-year playthrough
- [ ] Code follows naming conventions from technical-preferences.md
- [ ] Each autoload has doc comments on public API
- [ ] File structure matches ADR-001 (`src/autoloads/`, `src/systems/`, `src/ui/`)
