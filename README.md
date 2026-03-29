# The Blueprint Story

**A strategy game about Education Transformation**

Navigate 13 years of education reform (2013-2025). Balance budgets, political capital, and 5 competing KPIs across 27 historical crisis scenarios. Every decision has consequences — and there are no right answers.

Built with **Godot 4.6** | GDScript | JSON-driven data

---

## About The Game

You play as the Director of DAPU — the coordination unit responsible for transforming a nation's education system over 13 years. Five ministers will rotate above you, each with their own agendas. Floods, pandemics, political upheavals, and shrinking budgets will test your resolve.

Your job: keep 5 Key Performance Indicators healthy while spending wisely and surviving 27 crisis scenarios.

### The 5 KPIs

| KPI | What It Measures |
|-----|-----------------|
| **Quality** | Teaching standards, curriculum, international benchmarks |
| **Equity** | Achievement gap between urban and rural, rich and poor |
| **Access** | Enrollment, infrastructure, facilities, connectivity |
| **Unity** | Public satisfaction, stakeholder confidence |
| **Efficiency** | Cost-effectiveness, bureaucracy, budget management |

### How It Works

**Each year follows this cycle:**

1. **January (Planning)** — Select initiatives to fund from 104 available options. Each costs Budget (RM) and Political Capital (PC), takes 2-12 months to complete, and affects different KPIs.

2. **Months tick by** — Watch your initiatives progress. Each month is 30 real seconds (adjustable up to 5x speed).

3. **Scenarios strike** — At specific moments, crisis events interrupt gameplay. You must choose from 3+ options, each with different costs and KPI effects. Some choices affect future scenarios through callback chains.

4. **Year-end** — Initiatives are evaluated (completed, partial, or failed). KPIs decay naturally. Budget recalculates based on performance. Ministers check if you met their agenda.

5. **Repeat** — 13 years, 3 waves, 5 ministers, 27 scenarios. Your final grade (S through F) is based on your average KPI at the end of 2025.

### The Three Waves

| Wave | Years | Budget | Challenge |
|------|-------|--------|-----------|
| **Wave 1: Foundation** | 2013-2015 | RM 100M | Establish infrastructure, prove the reform works |
| **Wave 2: Acceleration** | 2016-2020 | RM 80M | Scale initiatives, navigate political changes, survive a pandemic |
| **Wave 3: Excellence** | 2021-2025 | RM 60M | Tightest budget, highest expectations, legacy at stake |

### Key Mechanics

- **104 initiatives** across 6 categories: Infrastructure, Human Capital, Policy, Technology, Community, Governance
- **27 scenario "boss fights"** triggered at specific historical moments
- **11 strategic shifts** that level up through XP, providing compounding yearly KPI bonuses
- **5 rotating ministers** with unique agendas, bonuses, and cost modifiers
- **Budget system** with performance modifiers, October penalties, and wave-based income
- **Political Capital** that regenerates from public satisfaction (Unity KPI)
- **Public sentiment** with ~130 randomized voice lines reflecting the mood of the nation

---

## Screenshots

*Coming soon*

---

## Getting Started

### Prerequisites

- [Godot 4.6](https://godotengine.org/download/) (standard version, not .NET)

### Running the Game

1. Clone the repository:
   ```bash
   git clone https://github.com/skiddz0/blueprint-game.git
   ```

2. Open the project in Godot 4.6:
   - Launch Godot
   - Click "Import" and select the `project.godot` file

3. Press **F5** to play

### Controls

| Action | Control |
|--------|---------|
| Select initiatives | Click cards in the planning screen |
| Scenario choices | Click choice cards or press **1/2/3** |
| Confirm/Continue | **Enter** or click button |
| Pause/Resume | Click pause button in header |
| Speed control | Click speed button (1x → 1.5x → 2x → 3x → 5x) |
| Save/Load | **☰** hamburger menu in header |
| Close modals | **Escape** |

---

## Architecture

The game uses an **autoload singleton + signal-driven UI** architecture:

### Autoloads (6)

| Autoload | Purpose |
|----------|---------|
| `DataLoader` | Loads 7 JSON data files, provides typed accessors |
| `GameStateManager` | Central state machine with 7 phases and 14 signals |
| `GameTimer` | 30-second months, pause/resume, speed control |
| `YearCycleEngine` | Orchestrates the annual gameplay sequence |
| `SaveLoadSystem` | 3 save slots + auto-save at year-end |
| `AchievementSystem` | 20 achievements, persists across sessions |
| `AudioManager` | 7 BGM tracks with context-aware switching |

### Pure Function Systems (6)

| System | Purpose |
|--------|---------|
| `KPISystem` | Clamp, decay, stagnation, average calculation |
| `ResourceSystem` | Budget math, performance modifiers, PC regeneration |
| `MinisterSystem` | Lookup, agenda checks, cost modifiers |
| `ShiftSystem` | XP awards, leveling, yearly bonuses |
| `ScenarioEngine` | Triggering, affordability, callback chains |
| `GradingSystem` | S-F grade calculation from average KPI |

### Data-Driven Design

All game content lives in 7 JSON files — no hardcoded values:

| File | Contents |
|------|----------|
| `config.json` | Game constants, formulas, wave budgets, thresholds |
| `initiatives.json` | 104 initiatives with costs, effects, durations |
| `scenarios.json` | 27 scenarios with choices and callback chains |
| `ministers.json` | 5 ministers with agendas and bonuses |
| `shifts.json` | 11 strategic shifts with XP progression |
| `achievements.json` | 20 achievement definitions |
| `timeline.json` | Historical timeline data |

Adding or rebalancing content never requires code changes.

---

## Game Features

- **Playful UI** — Colorful Mario-inspired theme, not dark and serious
- **Minister portraits** — Each minister has a visual portrait
- **Public sentiment** — Live indicator with ~130 randomized citizen voice lines in English and Malay
- **School animation** — Animated scene of students going to school and coming home
- **Year-end summary** — Report card showing KPI changes, initiative results, budget forecast
- **Achievement system** — 20 achievements that persist across sessions
- **Save/Load** — 3 manual save slots + auto-save at year-end
- **Context-aware music** — 7 BGM tracks that change based on game state
- **Speed control** — 1x to 5x game speed
- **Grading system** — S through F rank based on final average KPI

---

## Grading

| Grade | Average KPI | Verdict |
|-------|------------|---------|
| **S** | 80+ | Outstanding — a masterclass in education reform |
| **A** | 75+ | Excellent — strong results across the board |
| **B** | 65+ | Victory — the reform plan delivered |
| **C** | 55+ | Adequate — some progress, gaps remain |
| **D** | 45+ | Poor — the reform underperformed |
| **F** | Below 45 | Failed — the education system declined |

Victory requires grade B or above (average KPI >= 65).

---

## Credits

- Game design and data based on education reform concepts
- Built with [Godot Engine 4.6](https://godotengine.org/)
- Development assisted by [Claude Code](https://claude.ai/) (Anthropic)
- Game studio architecture by [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)

## License

MIT License. See [LICENSE](LICENSE) for details.
