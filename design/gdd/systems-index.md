# Systems Index: The Blueprint Story

> **Status**: Approved
> **Created**: 2026-03-29
> **Last Updated**: 2026-03-29
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

The Blueprint Story is a turn-based strategy/management simulation driven by
JSON data files. The game needs systems in three broad areas: (1) a data-driven
engine that loads and processes 7 JSON files into game state, (2) gameplay
systems that implement the KPI economy, initiative management, scenario
decisions, minister agendas, and shift progression, and (3) UI systems that
present information clearly for thoughtful decision-making. Per Pillar 3
(Data-Driven Architecture), no gameplay system should contain hardcoded content
— all content flows from `game-data/` JSON files through the Data Loader.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Data Loader | Core | MVP | Designed | design/gdd/data-loader.md | None |
| 2 | Game State Manager | Core | MVP | Designed | design/gdd/game-state-manager.md | Data Loader |
| 3 | KPI System | Gameplay | MVP | Designed | design/gdd/kpi-system.md | Data Loader |
| 4 | Resource System | Gameplay | MVP | Designed | design/gdd/resource-system.md | Data Loader |
| 5 | Game Timer | Core | MVP | Designed | design/gdd/game-timer.md | Game State Manager |
| 6 | Minister System | Gameplay | MVP | Designed | design/gdd/minister-system.md | Data Loader, Game State Manager |
| 7 | Shift System | Gameplay | MVP | Designed | design/gdd/shift-system.md | Data Loader, KPI System |
| 8 | Initiative System | Gameplay | MVP | Designed | design/gdd/initiative-system.md | Data Loader, KPI System, Resource System, Shift System |
| 9 | Scenario Engine | Gameplay | MVP | Designed | design/gdd/scenario-engine.md | Data Loader, KPI System, Resource System, Game State Manager |
| 10 | Year Cycle Engine | Gameplay | MVP | Designed | design/gdd/year-cycle-engine.md | Game Timer, KPI System, Resource System, Initiative System, Scenario Engine, Minister System, Shift System |
| 11 | HUD / Dashboard | UI | MVP | Designed | design/gdd/hud-dashboard.md | Game State Manager, KPI System, Resource System, Minister System, Game Timer |
| 12 | Initiative Selector UI | UI | MVP | Designed | design/gdd/initiative-selector-ui.md | Initiative System, Resource System |
| 13 | Scenario Modal UI | UI | MVP | Designed | design/gdd/scenario-modal-ui.md | Scenario Engine, Resource System |
| 14 | Event Log | UI | Vertical Slice | Designed | design/gdd/event-log.md | Game State Manager |
| 15 | Grading System | Gameplay | Vertical Slice | Designed | design/gdd/grading-system.md | KPI System |
| 16 | Game Over Screen | UI | Vertical Slice | Designed | design/gdd/game-over-screen.md | Grading System, KPI System |
| 17 | Save/Load System | Persistence | Alpha | Designed | design/gdd/save-load-system.md | Game State Manager |
| 18 | Save/Load UI | UI | Alpha | Designed | design/gdd/save-load-ui.md | Save/Load System |
| 19 | Achievement System | Progression | Alpha | Designed | design/gdd/achievement-system.md | KPI System, Scenario Engine, Initiative System, Shift System |
| 20 | Audio Manager | Audio | Full Vision | Designed | design/gdd/audio-manager.md | Game State Manager |
| 21 | Main Menu | UI | Full Vision | Designed | design/gdd/main-menu.md | Save/Load System |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Core** | Foundation systems everything depends on | Data Loader, Game State Manager, Game Timer |
| **Gameplay** | The systems that make the game fun | KPI System, Resource System, Initiative System, Scenario Engine, Minister System, Shift System, Year Cycle Engine, Grading System |
| **Progression** | How the player grows over time | Achievement System |
| **Persistence** | Save state and continuity | Save/Load System |
| **UI** | Player-facing information displays | HUD/Dashboard, Initiative Selector UI, Scenario Modal UI, Event Log, Game Over Screen, Save/Load UI, Main Menu |
| **Audio** | Sound and music systems | Audio Manager |

---

## Priority Tiers

| Tier | Definition | Systems Count |
|------|------------|---------------|
| **MVP** | Core loop functional: data loading, KPIs, initiatives, scenarios, ministers, timer, and essential UI | 13 |
| **Vertical Slice** | Full campaign playable: grading, event log, game over screen | 3 |
| **Alpha** | All features present: save/load, achievements | 3 |
| **Full Vision** | Polished: audio, main menu, animations | 2 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Data Loader** — All game content flows from JSON; this is the single entry point for all data

### Core Layer (depends on foundation)

2. **Game State Manager** — Central state machine; depends on: Data Loader
3. **KPI System** — 5 KPIs with decay/bonuses; depends on: Data Loader
4. **Resource System** — Budget + Political Capital; depends on: Data Loader

### Feature Layer (depends on core)

5. **Game Timer** — 30-second months; depends on: Game State Manager
6. **Minister System** — Rotating ministers with agendas; depends on: Data Loader, Game State Manager
7. **Shift System** — 11 shifts with XP leveling; depends on: Data Loader, KPI System
8. **Initiative System** — 104 initiatives; depends on: Data Loader, KPI System, Resource System, Shift System
9. **Scenario Engine** — 27 scenarios; depends on: Data Loader, KPI System, Resource System, Game State Manager
10. **Year Cycle Engine** — Orchestrates annual cycle; depends on: Game Timer, KPI System, Resource System, Initiative System, Scenario Engine, Minister System, Shift System
11. **Grading System** — S-F rank calculation; depends on: KPI System

### Presentation Layer (depends on features)

12. **HUD / Dashboard** — Main game screen; depends on: Game State Manager, KPI System, Resource System, Minister System, Game Timer
13. **Initiative Selector UI** — January planning modal; depends on: Initiative System, Resource System
14. **Scenario Modal UI** — Scenario choice modal; depends on: Scenario Engine, Resource System
15. **Event Log** — Recent events panel; depends on: Game State Manager
16. **Game Over Screen** — Final grade display; depends on: Grading System, KPI System
17. **Save/Load UI** — Save slot grid; depends on: Save/Load System

### Polish Layer (depends on everything)

18. **Save/Load System** — Full state serialization; depends on: Game State Manager
19. **Achievement System** — 20 achievements; depends on: KPI System, Scenario Engine, Initiative System, Shift System
20. **Audio Manager** — BGM + 8 SFX; depends on: Game State Manager
21. **Main Menu** — Entry screen; depends on: Save/Load System

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | Data Loader | MVP | Foundation | S |
| 2 | Game State Manager | MVP | Core | M |
| 3 | KPI System | MVP | Core | M |
| 4 | Resource System | MVP | Core | S |
| 5 | Game Timer | MVP | Feature | S |
| 6 | Minister System | MVP | Feature | S |
| 7 | Shift System | MVP | Feature | S |
| 8 | Initiative System | MVP | Feature | M |
| 9 | Scenario Engine | MVP | Feature | M |
| 10 | Year Cycle Engine | MVP | Feature | L |
| 11 | HUD / Dashboard | MVP | Presentation | L |
| 12 | Initiative Selector UI | MVP | Presentation | M |
| 13 | Scenario Modal UI | MVP | Presentation | M |
| 14 | Event Log | Vertical Slice | Presentation | S |
| 15 | Grading System | Vertical Slice | Feature | S |
| 16 | Game Over Screen | Vertical Slice | Presentation | S |
| 17 | Save/Load System | Alpha | Polish | M |
| 18 | Save/Load UI | Alpha | Presentation | S |
| 19 | Achievement System | Alpha | Polish | S |
| 20 | Audio Manager | Full Vision | Polish | S |
| 21 | Main Menu | Full Vision | Polish | S |

Effort: S = 1 session, M = 2-3 sessions, L = 4+ sessions.

---

## Circular Dependencies

None found. The dependency graph is a clean DAG (directed acyclic graph).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Year Cycle Engine | Scope | Orchestrates 7 other systems; most complex single system | Design last among gameplay systems so all dependencies are stable |
| HUD / Dashboard | Technical | Porting React's component model to Godot Control nodes; most complex UI | Prototype Godot UI patterns early; reference `docs/engine-reference/godot/modules/ui.md` |
| Scenario Engine | Design | Callback chains between scenarios require careful state tracking | Port callback logic directly from `scenarioEngine.ts`; test with known prototype outcomes |
| Data Loader | Technical | JSON loading in GDScript differs from TypeScript; schema validation | Test with actual `game-data/` files early; validate all 7 files load correctly |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 21 |
| Design docs started | 21 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 13/13 |
| Vertical Slice systems designed | 3/3 |
| Alpha systems designed | 3/3 |
| Full Vision systems designed | 2/2 |

---

## Next Steps

- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Start with Data Loader (Order #1, Foundation layer)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype HUD/Dashboard early to validate Godot UI patterns
