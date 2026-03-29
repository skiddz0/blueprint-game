# ADR-001: Godot Port Architecture — Autoload Singletons + Signal-Driven UI

> **Status**: Accepted
> **Date**: 2026-03-29
> **Decision Makers**: User + game-designer
> **Supersedes**: N/A

## Context

We are porting a complete React+TypeScript strategy game (The Blueprint Story) to
Godot 4.6. The React prototype uses a hooks-based architecture with a singleton
data loader, centralized game state, and component re-renders for UI updates. We
need a Godot-native architecture that preserves the prototype's proven game logic
while leveraging Godot's strengths.

Key constraints:
- 2D UI-heavy game (no physics, no 3D, no real-time action)
- All game content in 7 JSON files (~200KB total)
- 21 identified systems with clean dependency DAG
- Single-player, no networking
- Must support the exact same JSON data files without modification

## Decision

### 1. Autoload Singletons for Core Systems

The following systems are Godot autoloads (Project Settings → Autoload), loaded
in this order:

| Autoload Name | Script | Purpose |
|---------------|--------|---------|
| `DataLoader` | `data_loader.gd` | JSON loading and caching |
| `GameStateManager` | `game_state_manager.gd` | Central state machine + game state |
| `GameTimer` | `game_timer.gd` | Month/year time progression |
| `YearCycleEngine` | `year_cycle_engine.gd` | Annual orchestration sequence |
| `SaveLoadSystem` | `save_load_system.gd` | File-based save/load |
| `AudioManager` | `audio_manager.gd` | BGM and SFX playback |

**Rationale**: Autoloads are Godot's equivalent of React's context/singletons. They
persist across scene changes, are globally accessible, and initialize in a defined
order. This maps directly to the React prototype's singleton pattern.

### 2. Signal-Driven UI Updates (Replacing React Re-Renders)

All UI updates are driven by Godot signals emitted from `GameStateManager`:

```gdscript
signal kpi_changed(kpi_name, old_value, new_value)
signal budget_changed(old_value, new_value)
signal pc_changed(old_value, int)
signal month_advanced(year, month)
signal scenario_triggered(scenario)
signal phase_changed(new_phase)
# ... 14 signals total
```

UI scenes connect to these signals in `_ready()` and update their Control nodes
in the callback. This replaces React's `useState` → re-render cycle.

**Rationale**: Signals are Godot's native observer pattern. They decouple gameplay
systems from UI, allow headless testing (no UI connected), and make reactive updates
efficient (only changed elements update, not full re-renders).

### 3. Raw JSON Dictionaries (Not Godot Resources)

Game data is loaded as raw Dictionaries from JSON files using `FileAccess` +
`JSON.parse_string()`. We do NOT convert to Godot Resources (`.tres`).

**Rationale**: Pillar 3 (Data-Driven Architecture) requires designers to edit JSON
files directly. Godot Resources require the Godot editor to modify. Raw JSON
preserves the prototype's data pipeline — the same `game-data/` files work in both
the React and Godot versions without conversion.

### 4. Centralized Mutable State in GameStateManager

All mutable game state lives in a single Dictionary inside `GameStateManager`. No
other system owns mutable state. Systems request changes via methods:

```gdscript
GameStateManager.apply_kpi_change("quality", 5)
GameStateManager.apply_budget_change(-15.0)
GameStateManager.toggle_initiative("inf_001")
```

**Rationale**: Mirrors the React prototype's `useGameEngine` hook which held all
state. Centralized state makes save/load trivial (serialize one Dictionary),
prevents state sync bugs, and provides a single source of truth for UI.

### 5. Scene-Per-Screen UI Architecture

Each major UI screen is a separate Godot scene:

| Scene | Root Node | Purpose |
|-------|-----------|---------|
| `HUD.tscn` | Control | Main game dashboard |
| `InitiativeSelector.tscn` | Control | January planning modal |
| `ScenarioModal.tscn` | Control | Scenario choice overlay |
| `GameOverScreen.tscn` | Control | Final grade display |
| `SaveLoadModal.tscn` | Control | Save/load slot grid |
| `MainMenu.tscn` | Control | Entry screen |

Modals overlay the HUD using `CanvasLayer` or visibility toggling. The HUD is
always present during gameplay.

**Rationale**: Scene-per-screen matches React's component-per-screen pattern.
Each scene is independently editable in the Godot editor and connects to the
same autoload signals.

### 6. Gameplay Systems as Static Functions (Not Nodes)

Systems like KPI calculation, resource math, scenario evaluation, and grading are
pure functions — they take data in and return results. They live in script files
loaded by the autoloads, not as scene tree nodes.

```
src/
├── autoloads/          # Autoload singletons (scene tree nodes)
├── systems/            # Pure game logic (no nodes)
│   ├── kpi_system.gd
│   ├── resource_system.gd
│   ├── initiative_system.gd
│   ├── scenario_engine.gd
│   ├── minister_system.gd
│   ├── shift_system.gd
│   └── grading_system.gd
├── ui/                 # UI scenes and scripts
└── data/               # Data classes/utilities
```

**Rationale**: Pure functions are testable without the scene tree. The autoloads
coordinate and call these functions; the functions don't need to be nodes.

## Alternatives Considered

### A. Godot Resources Instead of JSON
- **Pro**: Type safety, editor integration, faster loading
- **Con**: Breaks Pillar 3; requires Godot editor to edit game data; can't share
  data files with the React prototype
- **Rejected**: Data editability without tools is a core design pillar

### B. Node-Based Systems (Each System is a Node)
- **Pro**: Leverages Godot's node lifecycle, visible in scene tree
- **Con**: Overkill for a UI game; adds scene tree complexity for systems that
  don't need spatial presence or rendering
- **Rejected**: Autoloads + pure functions is simpler and more testable

### C. Event Bus (Central Signal Router)
- **Pro**: Single connection point instead of connecting to multiple autoloads
- **Con**: Adds indirection; harder to trace signal flow; Godot's built-in signals
  already work well for this scale (21 systems, ~14 signals)
- **Rejected**: Direct signal connections are clearer for this project size

## Consequences

**Positive:**
- Architecture maps 1:1 to the React prototype — porting is mechanical, not creative
- JSON files work in both React and Godot without modification
- UI is fully decoupled — can test gameplay headless
- Save/load is trivial (serialize one Dictionary)
- All 21 GDDs are written against this architecture

**Negative:**
- Raw Dictionaries lack type safety — runtime errors from typos in key names
- No editor visualization of game state during development
- Autoload initialization order is implicit (must be documented)

**Risks:**
- Dictionary access patterns may become unwieldy as state grows — mitigate by
  considering typed wrapper classes if this becomes painful
- Signal connections can become hard to trace — mitigate with consistent naming
  and the signal list documented in game-state-manager.md

## References

- `design/gdd/data-loader.md` — Data loading architecture
- `design/gdd/game-state-manager.md` — State machine and signal definitions
- `design/gdd/hud-dashboard.md` — UI signal connection patterns
- React prototype: `D:\git\dev\pppm_story_v2\src\services\gameEngine.ts`
