# Project Architecture & Guidelines

## Core Principles
1. **Target Platform**: Poki (WebGL/HTML5). Optimized for performance, low memory footprint, and high responsiveness.
2. **Physics**: NO Box2D physical components (`collisionobject`). All collision and distance calculations use pure Lua circle mathematics:
   $$(\Delta x)^2 + (\Delta y)^2 < R^2$$
3. **Communication**: Minimize Defold `msg.post`. All business and simulation logic resides in modules (`main/modules/*.lua` and `modules/*.lua`) with direct Lua function calls.
4. **Poki SDK**:
   - `poki_sdk.gameplay_start()` is called strictly on the player's first input/click.
   - `poki_sdk.gameplay_stop()` is called when a level finishes (victory or defeat).
5. **Camera & Adaptability**: Built with `defold-orthographic` for universal mobile & desktop screen scaling.
6. **UI & Localization**: Built strictly with Druid. All user-facing strings are resolved through `modules/i18n.lua` (supporting English `en`, Portuguese `pt`, Russian `ru`, Turkish `tr`). UI prioritizes clear icons and numbers over long text.

## Directory Structure
- `entities/` (and `main/entities/`): All game objects needed for the game. Each entity has a dedicated subfolder containing the script and gameobject of the exact same name (e.g. `melee/melee.go`, `melee/melee.script`).
  - Units (`archer`, `melee`) are visual containers only (sprites, tier markers) with NO logic in `update()`.
  - `bunch_controller`: Controls squad formation, movement, and combat in a unified array.
  - `battle_manager`: Manages battle flow, squad spawning, level progression.
  - `projectile_manager`: Global projectile object pool (50-100 arrows) using enable/disable without frequent `go.delete()`.
  - `drag_manager`: Controls drag & drop grid merging ($A + A \rightarrow B$).
- `modules/` (and `main/modules/`): Pure Lua modules containing all game logic, economy, level designs, grid data, and tutorial state.
- `assets/` (and `main/assets/`): Sprites, atlases, and visual assets.
- `gui/` (and `main/gui/`): UI built with Druid.

## Game Mechanics
- **Grids**: $4 \times 4$ Player field at the bottom (16 cells) and $4 \times 4$ Enemy field at the top (16 cells).
- **Squad Scaling**: Squad unit counts scale according to the Fibonacci sequence:
  $$F = [1, 2, 3, 5, 8, 13, 21 \dots]$$
- **Economy**: Defeating enemies grants coins. If a level is failed, it restarts and earned coins can be spent on reinforcements.
- **Tutorial (Level 1)**: Strict FSM:
  1. Hand points at "Buy" button -> Spawns identical squad (Melee Tier 1).
  2. Hand moves between the two squads -> Demonstrates drag & merge.
  3. Hand points at "В бой" ("Battle") button -> Player launches battle.
  4. Victory popup appears -> Auto-progresses to Level 2.

## Mandatory Rule for Agents
Before making changes to this codebase, all AI agents MUST first inspect this file (`AGENTS.md`) and keep all modifications strictly aligned with the directory structure, Lua module architecture, Druid GUI standards, and Poki SDK requirements outlined above.
