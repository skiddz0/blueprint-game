# Event Log

> **Status**: In Design
> **Author**: user + game-designer
> **Last Updated**: 2026-03-29
> **Implements Pillar**: Pillar 4 — Accessible Complexity

## Overview

The Event Log is a simple UI panel on the HUD that displays the last 5 game events
in reverse chronological order. Events include scenario outcomes, initiative
completions, minister transitions, and year-end summaries. It gives the player
a running narrative of what's happened.

## Player Fantasy

A ticker tape of your decisions and their consequences. Glance at it to remember
what just happened and why your KPIs changed.

## Detailed Design

### Core Rules

1. Displays as a panel in the main HUD content area.
2. Shows the last 5 entries from `GameState.history` array.
3. New entries appear at the top, old entries scroll down and out.
4. Updates on `history_updated` signal from Game State Manager.
5. History entries are plain strings — formatting is handled by the source system.
6. Maximum history stored: 20 entries (in GameState); only 5 displayed.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Game State Manager | Upstream | `history_updated` signal; reads `GameState.history` |
| HUD / Dashboard | Parent | Embedded as a child panel |

## Formulas

None.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| 0 history entries | Show empty panel or "No events yet" | Clean initial state |
| Entry text very long | Truncate with ellipsis or wrap | Fixed panel width |
| Multiple entries added in one frame | All appear; most recent at top | Batch updates are fine |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Game State Manager | Upstream (hard) | History data and signal |
| HUD / Dashboard | Parent (hard) | Layout container |

## Tuning Knobs

| Parameter | Value | Safe Range | Notes |
|-----------|-------|------------|-------|
| Displayed entries | 5 | 3-10 | More = more space needed |
| Max stored entries | 20 | 10-50 | Memory is not a concern |

## Acceptance Criteria

- [ ] Displays last 5 entries from history
- [ ] Updates reactively on `history_updated` signal
- [ ] Most recent entry at top
- [ ] Handles empty state gracefully
- [ ] Long entries don't break layout
