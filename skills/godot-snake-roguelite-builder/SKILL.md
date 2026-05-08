---
name: godot-snake-roguelite-builder
description: Build, extend, test, package, and document Godot 4.x 2D snake auto-battler Roguelite prototypes inspired by SNKRX-style public mechanics while keeping code, assets, names, and tuning original. Use when Codex needs to create or modify a Godot project with snake-like follower movement, auto attacks, shop drafting, duplicate-unit upgrades, class bonds, wave enemies, generated placeholder art, smoke tests, export/PCK validation, project memory, or reusable production documentation.
---

# Godot Snake Roguelite Builder

## Core Workflow

1. Inspect the Godot project before editing: `project.godot`, main scene, autoloads, scripts, resources, generated assets, export presets, and tests.
2. Keep the design original. Borrow only broad genre mechanics such as snake movement, auto battle, shop drafting, and class synergies.
3. Implement systems through Godot-native scenes, scripts, resources, signals, and autoloads.
4. Prefer data-driven resources for units, enemies, classes, costs, attack types, and scaling.
5. Build original placeholder art with code or image generation; never depend on copyrighted source game assets.
6. Add smoke tests for every user-visible bug fix, especially packaging bugs.
7. Validate both source project and exported PCK when packaging behavior matters.
8. Update project memory and usage docs after meaningful changes.

## Architecture Pattern

Use this structure unless the project already has a stronger convention:

- `autoloads/`: event bus, game state, bond system, pools.
- `scripts/data/`: `Resource` classes such as `UnitData` and `EnemyData`.
- `scripts/components/`: reusable behavior such as combat and health.
- `scripts/systems/`: shop, wave manager, snake manager, bullets, visual feedback.
- `scripts/units/`: player-facing unit scenes and scripts.
- `resources/`: `.tres` gameplay data.
- `assets/generated/`: generated placeholder art.
- `tools/`: art generation, smoke tests, export helpers.
- `docs/`: memory, usage guide, design plan.

## Implementation Rules

- Use a fixed resource manifest for critical exported resources such as shop unit pools. Do not rely only on `DirAccess` scanning inside exported packs.
- For snake followers, sample the head path by distance so new units follow the exact path like snake body segments.
- Keep auto attack range adjustable through a single constant or stat pipeline.
- Emit gameplay events for effects instead of coupling combat code directly to visual nodes.
- Use object pooling for frequent bullets or transient combat objects.
- Reset pooled bullets fully: position, direction, damage, trail, pierced targets, lifetime, visibility, and collision state.
- Use `ignore_time_scale=true` for timers that must survive hit stop.
- Keep generated assets replaceable; loading code should handle both imported `Texture2D` and fresh PNG fallback.

## Validation Checklist

Run or create tests that verify:

- Main scene loads and instantiates.
- Autoloads exist.
- Core `UnitData` and `EnemyData` load.
- Shop displays profession cards in source and exported PCK.
- Duplicate purchase upgrades instead of adding length.
- Different unit purchase extends the snake.
- Followers keep reasonable spacing after simulation.
- Wave start spawns enemies or reaches a valid completed state.
- Headless run produces no script errors.

Use the project-local Godot console path when available. For this project, it is:

```powershell
D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe
```

## Packaging Workflow

1. Run source smoke test.
2. Export PCK.
3. Run smoke test with `--main-pack`.
4. Start the packaged console executable if present.
5. Check logs for `ERROR`, `SCRIPT ERROR`, and `WARNING`.
6. Document whether `.exe` regeneration is blocked by missing export templates.

## Documentation Workflow

Maintain:

- `docs/PROJECT_MEMORY.md`: current state, architecture, commands, known issues.
- `docs/USAGE_GUIDE.md`: user-facing run/test/export instructions.
- `docs/GAME_DESIGN_PLAN.md`: game design document.
- `README.md`: short overview and links.

## Reference

For a complete production checklist and common pitfalls, read `references/production-workflow.md`.
