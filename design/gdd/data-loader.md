# Data Loader

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 3 — Data-Driven Architecture

## Overview

The Data Loader is the foundation system that reads all 7 JSON data files from
`game-data/` at startup and provides typed, cached access to every other system
in the game. It is invisible to the player — a pure infrastructure system. Without
it, no gameplay system can function because all game content (initiatives, scenarios,
ministers, shifts, config, achievements, timeline) lives in JSON, not code.

In the Godot port, this replaces the React prototype's `DataLoader` singleton class
which used `fetch()` and `Promise.all()`. The Godot version uses synchronous
`FileAccess` reads (JSON files are small, ~200KB total) and exposes data as typed
Godot Resources or Dictionaries.

## Player Fantasy

This is an infrastructure system — the player never interacts with it directly.
Its "fantasy" is developer-facing: any team member can add or rebalance content
by editing JSON files without touching GDScript. Per Pillar 3: "If adding a new
scenario requires modifying GDScript, the architecture is wrong."

## Detailed Design

### Core Rules

1. The Data Loader is an **autoload singleton** (`DataLoader.gd`) available globally
   as `DataLoader`.
2. On `_ready()`, it loads all 7 JSON files synchronously and caches the parsed
   results. Loading order does not matter — files are independent.
3. Each JSON file maps to a strongly-typed accessor method that returns parsed data:
   - `get_config() -> Dictionary` — game constants and formulas
   - `get_initiatives() -> Array[Dictionary]` — 104 initiatives
   - `get_scenarios() -> Array[Dictionary]` — 27 scenarios
   - `get_ministers() -> Array[Dictionary]` — 5 ministers
   - `get_shifts() -> Array[Dictionary]` — 11 shifts
   - `get_achievements() -> Array[Dictionary]` — 20 achievements
   - `get_timeline() -> Array[Dictionary]` — historical events
4. Data is **read-only** after loading. No system may modify the loaded data.
   Systems that need mutable state (e.g., active initiative progress) copy the
   relevant fields into their own state objects.
5. Convenience query methods provide filtered access:
   - `get_initiatives_by_category(category: String) -> Array[Dictionary]`
   - `get_initiatives_by_year(year: int) -> Array[Dictionary]` — unlocked by year
   - `get_scenario_by_year_month(year: int, month: int) -> Dictionary` — or null
   - `get_minister_by_year(year: int) -> Dictionary`
   - `get_shift_by_id(id: int) -> Dictionary`
   - `get_config_value(section: String, key: String) -> Variant` — dot-path access
6. A `data_loaded` signal is emitted after all files are loaded successfully.
7. A `data_load_failed` signal is emitted with an error message if any file fails.

### Loading Process

```
_ready()
  -> for each file in FILE_MANIFEST:
       open file with FileAccess
       read contents as string
       parse with JSON.parse_string()
       validate top-level structure
       store in cache dictionary
  -> emit data_loaded signal
```

### File Manifest

| File | Cache Key | Root Key | Expected Type | Record Count |
|------|-----------|----------|---------------|-------------|
| `game-data/config.json` | `config` | (root is object) | Dictionary | 1 |
| `game-data/initiatives.json` | `initiatives` | `initiatives` | Array | 104 |
| `game-data/scenarios.json` | `scenarios` | `scenarios` | Array | 27 |
| `game-data/ministers.json` | `ministers` | `ministers` | Array | 5 |
| `game-data/shifts.json` | `shifts` | `shifts` | Array | 11 |
| `game-data/achievements.json` | `achievements` | `achievements` | Array | 20 |
| `game-data/timeline.json` | `timeline` | `timeline` | Array | varies |

### Data Schemas

All schemas are ported directly from the React prototype's TypeScript interfaces
(`src/types/index.ts`). Field names are preserved exactly to allow JSON files to
be copied from the prototype without modification.

#### Config Schema (config.json)

```
{
  game_version: String,        # "2.0.0"
  data_version: String,        # "2026-01-21"
  time: {
    year_duration_seconds: int, # 360 (12 months × 30 seconds)
    months_per_year: int,       # 12
    mid_year_month: int,        # 6
    october_month: int          # 10
  },
  kpis: {
    starting_values: { quality: int, equity: int, access: int, unity: int, efficiency: int },
    min_value: int,             # 0
    max_value: int,             # 100
    victory_threshold: int,     # 65
    grade_thresholds: { s_rank: int, a_rank: int, b_rank: int, c_rank: int, d_rank: int },
    decay_rates: { access_per_year: int, quality_per_year: int },
    stagnant_penalty: float     # -0.5
  },
  resources: {
    starting_budget: int,       # 100
    starting_pc: int,           # 50
    max_pc: int,                # 100
    october_unspent_threshold: int,  # 10
    october_penalty_percent: int     # 20
  },
  efficiency: {
    penalty_threshold: int,     # 40
    penalty_cost_increase: int, # 50
    bureaucracy_penalty_per_initiative: float,   # -0.5
    bureaucracy_penalty_after_du: float,         # -0.25
    reform_pc_cost: int,        # 10
    reform_efficiency_bonus: int # 10
  },
  initiatives: {
    completion_thresholds: { full: int, partial: int },
    partial_effects_multiplier: float,  # 0.5
    partial_unity_penalty: int,         # -2
    failed_pc_penalty: int,             # -5
    failed_unity_penalty: int           # -3
  },
  shifts: {
    count: int,                 # 11
    max_level: int,             # 5
    xp_per_level: Array[int]    # [3, 3, 4, 4, 5]
  },
  waves: {
    wave_1: { name: String, start_year: int, end_year: int, base_budget: int },
    wave_2: { ... },
    wave_3: { ... }
  },
  performance_modifiers: {
    avg_below_45: float,        # -0.25
    avg_45_to_54: float,        # -0.10
    avg_55_to_64: float,        #  0.00
    avg_65_to_74: float,        #  0.10
    avg_75_plus: float          #  0.25
  }
}
```

#### Initiative Schema (initiatives.json → initiatives[])

```
{
  id: String,                   # "inf_001"
  name: String,                 # "Coordinate 1BestariNet Rollout"
  description: String,
  category: String,             # infrastructure|human_capital|policy|technology|community|governance
  shift: int,                   # 1-11
  cost_rm: int,                 # 5-50 (RM millions)
  cost_pc: int,                 # 0-20 (Political Capital)
  effects: Dictionary,          # { "access": 3, "equity": 2 } — partial, -3 to +3
  shift_xp: int,                # 1-4
  duration_months: int,         # 2-12
  unlock_year: int,             # 2013-2025
  tags: Array[String]           # optional
}
```

#### Scenario Schema (scenarios.json → scenarios[])

```
{
  id: String,                   # "scenario_001"
  name: String,
  year: int,                    # 2013-2025
  month: int,                   # 1-12
  category: String,             # crisis_response|policy_debate|political_event|...
  title: String,                # Display title with emoji
  context: String,              # Narrative text
  choices: Array[{
    id: String,
    label: String,              # "A) QUICK WINS CAMPAIGN"
    description: String,
    costs: { budget: int?, pc: int? },
    effects: Dictionary,        # { "unity": 5, "quality": -2 }
    outcome_text: String,
    headline: String,
    special_effects: Dictionary? # optional: initiatives_delayed_months, unlock_initiatives, etc.
  }],
  cannot_afford_penalty: {
    unity_kpi: int?,
    quality_kpi: int?,
    equity_kpi: int?,
    access_kpi: int?,
    efficiency_kpi: int?,
    outcome_text: String,
    headline: String
  }
}
```

#### Minister Schema (ministers.json → ministers[])

```
{
  id: String,                   # "minister_001"
  name: String,
  nickname: String,
  start_year: int,
  end_year: int,
  start_month: int,
  end_month: int,
  portrait: String,             # filename for portrait image
  wave: int,                    # 1-3
  legacy: Array[String],
  priority_text: String,
  agenda: {
    description: String,
    kpi: String,                # quality|equity|access|unity|efficiency
    target: int,
    reward_pc: int,
    reward_text: String
  },
  bonuses: Dictionary,          # { "efficiency": 5 }
  cost_modifiers: Dictionary?,  # { "efficiency_initiatives": -10 }
  transition_in: { title: String, message: String },
  transition_out: { title: String, message: String, summary: String }
}
```

#### Shift Schema (shifts.json → shifts[])

```
{
  id: int,                      # 1-11
  title: String,
  shortTitle: String,
  description: String,
  targetKpi: String,            # quality|equity|access|unity|efficiency
  level: int,                   # starting: 0
  xp: int,                     # starting: 0
  nextLevelXp: int             # starting: 3 (from xp_per_level[0])
}
```

#### Achievement Schema (achievements.json → achievements[])

```
{
  id: String,
  name: String,
  description: String,
  category: String,
  condition: Dictionary         # trigger conditions
}
```

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Unloaded | Initial state | `_ready()` called | No data available; accessors return null |
| Loading | `_ready()` begins | All files parsed or error | Reading files sequentially |
| Loaded | All files parsed successfully | Never (persists for app lifetime) | All accessors return cached data |
| Error | Any file fails to load/parse | Never (requires restart) | `data_load_failed` emitted; accessors return null |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Downstream | Reads config for initial KPI values, budget, PC; reads all data to initialize game |
| KPI System | Downstream | Reads `config.kpis` for starting values, decay rates, thresholds |
| Resource System | Downstream | Reads `config.resources` for starting budget/PC, `config.waves` for base budgets |
| Initiative System | Downstream | Reads `initiatives[]` for the full initiative catalog |
| Scenario Engine | Downstream | Reads `scenarios[]` for trigger scheduling and choice data |
| Minister System | Downstream | Reads `ministers[]` for timeline and agendas |
| Shift System | Downstream | Reads `shifts[]` for initial shift state, `config.shifts` for XP thresholds |
| Achievement System | Downstream | Reads `achievements[]` for achievement definitions |
| Year Cycle Engine | Downstream | Reads `config.time` for month/year timing, `config.waves` for wave boundaries |
| Save/Load System | Downstream | May re-read base data to restore non-state fields after load |

All interactions are **one-directional**: Data Loader provides data, never receives it.

## Formulas

No formulas in this system. The Data Loader is pure I/O — it reads, parses, and
caches. All game formulas live in the consuming systems (KPI System, Resource System,
etc.) and reference values loaded from `config.json`.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| JSON file missing from disk | Emit `data_load_failed` with filename; game cannot start | All 7 files are required; no fallback data |
| JSON file has invalid syntax | Emit `data_load_failed` with parse error; game cannot start | Corrupted data is worse than no data |
| JSON file has wrong structure (e.g., missing `initiatives` key) | Emit `data_load_failed` with validation error | Fail fast; don't silently use partial data |
| Initiative has unknown category string | Log warning, include initiative anyway | Forward-compatible with new categories |
| Config missing a key (e.g., no `stagnant_penalty`) | Use hardcoded default, log warning | Graceful degradation for config evolution |
| Empty array in file (0 initiatives) | Load succeeds with empty array | Valid state for testing |
| Accessor called before loading completes | Return null; caller should await `data_loaded` signal | Prevent race conditions |
| `game-data/` path differs in export vs. editor | Use `res://game-data/` path prefix | Godot's `res://` resolves correctly in both contexts |
| Very large JSON file (future-proofing) | No concern — total data is ~200KB | All files load in <100ms even on slow hardware |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| None | Upstream | Data Loader has zero dependencies — it is the root |
| Game State Manager | Downstream (hard) | Cannot initialize without config data |
| KPI System | Downstream (hard) | Cannot set starting values without config |
| Resource System | Downstream (hard) | Cannot set budget/PC without config + waves |
| Initiative System | Downstream (hard) | Cannot display or select initiatives without initiative data |
| Scenario Engine | Downstream (hard) | Cannot trigger scenarios without scenario data |
| Minister System | Downstream (hard) | Cannot display or apply minister effects without minister data |
| Shift System | Downstream (hard) | Cannot track shift progress without shift data |
| Achievement System | Downstream (soft) | Game functions without achievements; they enhance replay |
| Year Cycle Engine | Downstream (hard) | Cannot determine wave boundaries without config |
| Save/Load System | Downstream (soft) | May reference base data; game works without save/load |

## Tuning Knobs

The Data Loader itself has no tuning knobs — it is pure infrastructure. However,
it serves as the **delivery mechanism** for all tuning knobs in the game. Every
tunable value in `config.json` is a tuning knob for its consuming system:

| Parameter | File | Consuming System |
|-----------|------|-----------------|
| `kpis.starting_values.*` | config.json | KPI System |
| `kpis.decay_rates.*` | config.json | KPI System |
| `kpis.grade_thresholds.*` | config.json | Grading System |
| `resources.starting_budget` | config.json | Resource System |
| `waves.*.base_budget` | config.json | Resource System |
| `shifts.xp_per_level` | config.json | Shift System |
| `performance_modifiers.*` | config.json | Resource System |
| Initiative `cost_rm`, `effects`, `duration_months` | initiatives.json | Initiative System |
| Scenario `choices[].costs`, `choices[].effects` | scenarios.json | Scenario Engine |

Designers tune the game by editing JSON files, not code. The Data Loader ensures
those edits take effect on next launch.

## Visual/Audio Requirements

None. The Data Loader is invisible infrastructure with no player-facing output.

## UI Requirements

None directly. If the `Error` state is reached, the consuming system (likely
Main Menu or a startup screen) should display an error message to the player.
The Data Loader emits the signal; UI systems decide how to present it.

## Acceptance Criteria

- [ ] All 7 JSON files load successfully from `res://game-data/`
- [ ] `data_loaded` signal fires after all files are cached
- [ ] `data_load_failed` signal fires with descriptive error when a file is missing
- [ ] `data_load_failed` signal fires with parse error when JSON is malformed
- [ ] `get_config()` returns a Dictionary matching the config schema above
- [ ] `get_initiatives()` returns an Array of 104 Dictionaries
- [ ] `get_scenarios()` returns an Array of 27 Dictionaries
- [ ] `get_ministers()` returns an Array of 5 Dictionaries
- [ ] `get_shifts()` returns an Array of 11 Dictionaries
- [ ] `get_initiatives_by_category("infrastructure")` returns only infrastructure initiatives
- [ ] `get_initiatives_by_year(2013)` returns only initiatives with `unlock_year <= 2013`
- [ ] `get_scenario_by_year_month(2013, 6)` returns scenario_001 (Blueprint Skepticism)
- [ ] `get_minister_by_year(2013)` returns minister_001 (Moo-Hidin)
- [ ] Data is immutable after loading — modifying a returned Dictionary does not affect cache
- [ ] Accessor called before `_ready()` completes returns null without crash
- [ ] Performance: All 7 files load in < 500ms on target hardware
- [ ] No hardcoded game values in `data_loader.gd` — only file paths and structural keys
- [ ] JSON files from the React prototype (`D:\git\dev\pppm_story_v2\game-data\`) load without modification

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should we use Godot Resources (`.tres`) instead of raw JSON? | Technical Director | Before implementation | JSON preferred for Pillar 3 (designers edit JSON, not Godot editor). Resources could wrap JSON for type safety. Decision: start with raw JSON, convert to Resources later if needed. |
| Should timeline.json be loaded (it's unused in the React prototype)? | Game Designer | Before implementation | Load it — costs nothing, and it may be used for flavor text or historical context UI later. |
| Return Dictionaries or custom RefCounted classes? | Lead Programmer | Before implementation | Start with Dictionaries for simplicity. If type safety becomes a pain point, wrap in typed classes later. |
