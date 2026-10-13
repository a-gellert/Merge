# Antigravity Guidelines for Merge Game

All rules and architectural constraints documented in [AGENTS.md](AGENTS.md) are strictly active for this workspace.

- **Structure**: `entities/`, `modules/`, `assets/`, `gui/` (with active Defold implementations in `main/entities/`, `main/modules/`, `main/gui/`).
- **No Physics**: No Box2D collisionobjects; use circle distance formulas in Lua.
- **Poki SDK**: `poki_sdk.gameplay_start()` on first user input, `poki_sdk.gameplay_stop()` on battle end.
- **Druid & i18n**: UI strictly with Druid, translations via `modules/i18n.lua` (en, pt, ru, tr).
- **Fibonacci Bunching**: Squad visual unit counts scale by Fibonacci series ($1, 2, 3, 5, 8, 13\dots$).
- **Tutorial (Level 1)**: Hand FSM: Buy -> Merge -> Battle -> Victory.
