# Antigravity Guidelines for Merge Game

All rules and architectural constraints documented in [AGENTS.md](AGENTS.md) are strictly active for this workspace.

- **Structure**: `entities/`, `modules/`, `assets/`, `gui/` (with active Defold implementations in `main/entities/`, `main/modules/`, `main/gui/`).
- **No Physics**: No Box2D collisionobjects; use circle distance formulas in Lua.
- **Poki SDK**: `poki_sdk.gameplay_start()` on first user input, `poki_sdk.gameplay_stop()` on battle end.
- **Druid & i18n**: UI strictly with Druid, translations via `modules/i18n.lua` (en, pt, ru, tr).
- **Tier Shapes**: Warriors per squad 3, 5, 7, 9, 12 ... 42 (readable formations); each merge = x2.2 HP and damage.
- **Knowledge base**: [docs/KNOWLEDGE_BASE.md](docs/KNOWLEDGE_BASE.md) (balance, sawtooth curve, ads, UI, tools, change log).
- **Tutorial (Level 1)**: Hand FSM: Buy -> Merge -> Fight; no result screens, levels chain automatically.
