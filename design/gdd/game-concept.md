# Game Concept: The Blueprint Story

*Created: 2026-03-29*
*Status: Approved (ported from proven React+TypeScript prototype)*

---

## Elevator Pitch

> It's a turn-based strategy game where you direct Malaysia's 13-year education
> transformation (PPPM 2013-2025), balancing budgets, political capital, and
> 5 competing KPIs across 27 historical crisis scenarios — every decision has
> real consequences and no right answers.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Turn-based strategy / management simulation |
| **Platform** | PC (Web export possible via Godot) |
| **Target Audience** | Malaysian educators, policy enthusiasts, strategy gamers |
| **Player Count** | Single-player |
| **Session Length** | 30-90 minutes (full 13-year campaign) |
| **Monetization** | Free (educational) |
| **Estimated Scope** | Medium (prototype complete, porting to Godot 4.6) |
| **Comparable Titles** | Democracy 3, Reigns, Long Live The Queen |

---

## Core Fantasy

You are the DAPU/DU Director — the bureaucrat who actually has to make Malaysia's
ambitious education blueprint work. Ministers rotate above you with competing
agendas. Floods, pandemics, political upheavals, and shrinking budgets test your
resolve. Every choice you make ripples across 5 KPIs that represent the real
aspirations of Malaysian education: Quality, Equity, Access, Unity, and Efficiency.

You can't maximize everything. The fantasy is being the person who navigates
impossible trade-offs and still moves the needle — or fails trying.

---

## Unique Hook

Like Democracy 3, AND ALSO every scenario is a real Malaysian historical event
(the 2014 East Coast floods, GE14 government change, COVID-19 pandemic) with
real consequences — it's both a strategy game and an interactive lesson in
education policy. The 13-year timeline means your early decisions compound,
and mistakes from Wave 1 haunt you in Wave 3.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 6 | Clean UI, satisfying KPI bar animations, audio feedback on choices |
| **Fantasy** | 2 | Role as education director navigating real historical events |
| **Narrative** | 1 | 27 authored scenarios tell Malaysia's education story through play |
| **Challenge** | 3 | Budget constraints tighten each wave; KPI decay forces active management |
| **Fellowship** | N/A | Single-player experience |
| **Discovery** | 4 | Alternate scenario outcomes, callback chains, achievement hunting |
| **Expression** | 5 | Multiple viable strategies (efficiency-first vs. equity-first vs. balanced) |
| **Submission** | 7 | Relaxed pacing within each year, no reflex demands |

### Key Dynamics (Emergent player behaviors)

- Players naturally develop a "KPI philosophy" — prioritizing certain metrics and
  accepting trade-offs in others, leading to distinct playstyles
- The October budget penalty creates urgency to spend wisely rather than hoard
- Scenario callback chains (e.g., UPSR Debate -> UPSR Implementation) reward
  players who think ahead about long-term consequences
- Minister agendas create shifting priorities that force adaptation each wave
- Shift leveling rewards specialization but decay punishes neglecting any KPI

### Core Mechanics (Systems we build)

1. **Initiative Selection & Management** — Choose from 104 initiatives each January,
   balancing cost (RM + PC) against KPI effects and duration
2. **Scenario Decision System** — 27 boss-fight events with 3+ choices each,
   including callback chains where past choices modify future scenarios
3. **KPI Economy** — 5 interconnected metrics with natural decay, stagnation
   penalties, shift bonuses, and minister modifiers
4. **Resource Management** — Dual-currency system (Budget RM + Political Capital)
   with wave-based income, performance modifiers, and spend-or-lose pressure
5. **Shift Progression** — 11 strategic shifts with XP leveling that provide
   compounding yearly KPI bonuses

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | 104 initiatives to choose from, 3+ choices per scenario, multiple viable strategies | Core |
| **Competence** | Grading system (S-F rank), KPI improvement feedback, shift leveling progression | Core |
| **Relatedness** | Connection to real Malaysian history and education outcomes; minister relationships | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — S-rank chasing, achievement system (20 achievements), shift mastery
- [x] **Explorers** — Discovering optimal strategies, alternate scenario outcomes, callback chains
- [ ] **Socializers** — N/A (single-player)
- [ ] **Killers/Competitors** — N/A (no PvP, though grade comparison is possible)

### Flow State Design

- **Onboarding curve**: Wave 1 (2013-2015) has the highest budget (RM 100M) and
  gentlest scenarios, teaching mechanics with forgiving resource margins
- **Difficulty scaling**: Budget decreases each wave (100->80->60), scenarios
  increase in severity, KPI decay accumulates — the game gets harder as you
  progress, matching growing player knowledge
- **Feedback clarity**: KPI bars with color coding (green/orange/red), immediate
  numerical feedback on every choice, mid-year review at month 6, end-of-year
  summary with initiative completion status
- **Recovery from failure**: Partial initiative completion (50% effects) is better
  than total failure; scenario "cannot afford" penalties are harsh but survivable;
  save/load with 3 slots enables experimentation

---

## Core Loop

### Moment-to-Moment (30 seconds)
Read KPI bars, evaluate current resource state, respond to scenario choices by
weighing trade-offs between KPIs. Watch initiative progress bars advance. The
core action is **deciding** — every click is a meaningful choice, not busywork.

### Short-Term (5-15 minutes)
One game year: January planning (select initiatives) -> watch months tick by ->
respond to scenario if triggered -> mid-year review -> October budget check ->
year-end processing. Each year is a complete cycle with a satisfying resolution
(initiative completion, KPI changes, budget recalculation).

### Session-Level (30-90 minutes)
Full 13-year campaign across 3 waves. Natural pacing: Wave 1 is the learning
phase, Wave 2 accelerates with tighter budgets and minister changes, Wave 3 is
the endgame sprint. The campaign ends with a grade (S through F) and full KPI
summary.

### Long-Term Progression
- Chase higher grades on replay (D -> B -> A -> S)
- Try different strategic philosophies (equity-first, efficiency-first, balanced)
- Explore alternate scenario outcomes and callback chain variations
- Complete all 20 achievements
- Master all 11 shifts to level 5

### Retention Hooks
- **Curiosity**: "What happens if I pick the other choice in the UPSR Debate?"
- **Investment**: 13-year campaign creates attachment to your KPI trajectory
- **Mastery**: S-rank requires deep understanding of all systems and trade-offs
- **Social**: N/A for now, but shareable grade screenshots are natural

---

## Game Pillars

### Pillar 1: Historical Authenticity
Every scenario, minister, and initiative maps to real PPPM events and policies.
The game teaches through play, not exposition.

*Design test*: "If we're debating a fictional crisis vs. a real historical one,
we choose the real one — even if the fictional one is more dramatic."

### Pillar 2: Meaningful Trade-offs
No right answers, only trade-offs between KPIs. Every choice that helps one
metric should cost or risk another. The player's strategy IS their story.

*Design test*: "If a choice improves everything with no downside, it's broken
and must be rebalanced."

### Pillar 3: Data-Driven Architecture
All game content (initiatives, scenarios, ministers, shifts, config) lives in
JSON data files, not code. Adding or rebalancing content never requires code
changes.

*Design test*: "If adding a new scenario requires modifying GDScript, the
architecture is wrong."

### Pillar 4: Accessible Complexity
Deep systems with a gentle learning curve. Wave 1 teaches, Wave 2 challenges,
Wave 3 demands mastery. Information is always visible, never hidden.

*Design test*: "If a player can't understand why their KPI changed, we need
better feedback — not simpler mechanics."

### Anti-Pillars (What This Game Is NOT)

- **NOT an action game**: No reflexes, no time pressure beyond the monthly timer.
  Adding real-time pressure would compromise thoughtful decision-making.
- **NOT a sandbox**: Fixed 13-year timeline with authored scenarios. Procedural
  content would undermine historical authenticity.
- **NOT multiplayer**: Single-player narrative strategy. Adding multiplayer would
  compromise pacing and scenario integrity.
- **NOT a visual spectacle**: Clean, functional UI over flashy graphics. Art
  budget goes to clarity, not beauty.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Democracy 3 | Policy-as-mechanics, interconnected KPI web | Fixed timeline with authored events vs. sandbox | Validates that policy management can be engaging gameplay |
| Reigns | Binary choices with cascading consequences | More than 2 choices, deeper resource systems | Validates that simple choice-based governance is compelling |
| Long Live The Queen | Stat management through narrative events | Real historical setting, longer time horizon | Validates that stat-balancing + narrative works for strategy |

**Non-game inspirations**: Malaysia's actual PPPM 2013-2025 policy document,
education reform case studies, the experience of civil servants navigating
political transitions and budget constraints.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-45 |
| **Gaming experience** | Casual to mid-core (strategy-literate) |
| **Time availability** | 30-90 minute sessions |
| **Platform preference** | PC, potentially web browser |
| **Current games they play** | Democracy 3, Civilization, management sims, narrative games |
| **What they're looking for** | A strategy game grounded in real-world policy with educational value |
| **What would turn them away** | Overly complex UI, no clear feedback on choices, historically inaccurate content |

**Secondary audience**: Malaysian educators, policy students, and anyone curious
about education reform — people who might not normally play strategy games but
are drawn by the subject matter.

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Godot 4.6 (configured) |
| **Key Technical Challenges** | Porting React UI patterns to Godot Control nodes; JSON data loading; timer system |
| **Art Style** | 2D UI-focused, clean information design with minister portraits and icons |
| **Art Pipeline Complexity** | Low — UI elements, 5 minister portraits, category icons, KPI visualizations |
| **Audio Needs** | Moderate — BGM tracks, 8 SFX types (select, confirm, alert, success, warning, yearEnd, gameWin, gameOver) |
| **Networking** | None |
| **Content Volume** | 104 initiatives, 27 scenarios, 5 ministers, 11 shifts, 20 achievements, 7 JSON data files |
| **Procedural Systems** | None — fully authored content |

---

## Risks and Open Questions

### Design Risks
- Core loop is proven (prototype is balanced and complete) — minimal design risk
- Risk of losing UI responsiveness in the Godot port (React's immediate re-render
  vs. Godot's signal-based updates)

### Technical Risks
- Godot 4.6 Control/UI system differences from React component model
- JSON data loading patterns in GDScript vs. TypeScript's native JSON support
- Timer accuracy and monthly progression in Godot's `_process` loop
- Save/load system migration from localStorage to Godot's FileAccess/ConfigFile

### Market Risks
- Niche subject matter (Malaysian education policy) limits global audience
- Educational games carry "edutainment" stigma — must lead with strategy, not
  education

### Scope Risks
- 104 initiatives + 27 scenarios = significant data validation after porting
- UI complexity (initiative selector, scenario modal, KPI dashboard) needs careful
  Godot scene architecture

### Open Questions
- Should the Godot version add features beyond the React prototype, or be a
  faithful 1:1 port first?
- What's the target export: desktop only, or web (HTML5) as well?
- Should minister portraits be upgraded from static images to animated portraits?

---

## MVP Definition

**Core hypothesis**: The React prototype's proven gameplay translates to Godot
with equivalent or better player experience.

**Required for MVP (Godot port)**:
1. Game engine + KPI system working with JSON data loaded from `game-data/`
2. Initiative selection UI and year-long progression
3. Scenario triggering and choice resolution with full effect application
4. One complete wave (2013-2015, 3 years) playable end-to-end
5. Minister display with agenda tracking

**Explicitly NOT in MVP** (defer to later):
- Save/load system (play full sessions instead)
- Achievement system
- Audio/SFX
- All 27 scenarios (just Wave 1 scenarios for MVP)
- Polish animations and transitions

### Scope Tiers

| Tier | Content | Features | Estimate |
| ---- | ---- | ---- | ---- |
| **MVP** | Wave 1 (2013-2015), ~8 scenarios, ~35 initiatives | Core loop, KPI, initiatives, scenarios | 2-3 weeks |
| **Vertical Slice** | All 3 waves, all 27 scenarios, all 104 initiatives | Full campaign, ministers, shifts | 4-6 weeks |
| **Alpha** | Full content + save/load + achievements | All features, rough UI | 6-8 weeks |
| **Full Vision** | Polished UI, audio, animations, web export | Complete parity with React prototype | 8-12 weeks |

---

## Next Steps

- [x] Engine configured (Godot 4.6 via `/setup-engine`)
- [x] Game concept formalized (this document)
- [ ] Decompose concept into Godot-native systems (`/map-systems`)
- [ ] Author per-system GDDs adapted for Godot (`/design-system`)
- [ ] Create first architecture decision record (`/architecture-decision`)
- [ ] Plan the first sprint (`/sprint-plan new`)
