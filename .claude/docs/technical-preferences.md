# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Compatibility (Forward+) — 2D UI-heavy game
- **Physics**: Not required (strategy/management game)

## Naming Conventions

- **Classes**: PascalCase (e.g., `GameEngine`)
- **Variables/Functions**: snake_case (e.g., `move_speed`)
- **Signals**: snake_case past tense (e.g., `kpi_changed`)
- **Files**: snake_case matching class (e.g., `game_engine.gd`)
- **Scenes**: PascalCase matching root node (e.g., `GameEngine.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_KPI_VALUE`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: [TO BE CONFIGURED — low for 2D UI game]
- **Memory Ceiling**: [TO BE CONFIGURED]

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, KPI calculations

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [ADR-001](../../docs/architecture/ADR-001-godot-port-architecture.md) — Autoload singletons + signal-driven UI + raw JSON data
