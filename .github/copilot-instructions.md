# GlobeSweeper 3D - AI Coding Instructions

## Project Overview
GlobeSweeper 3D is a spherical Minesweeper game built in Godot 4.4.1. It uses an icosphere geometry with hexagonal tiles and features procedural audio generation.

## Architecture & Data Flow
- **Central Controller**: [scripts/main.gd](scripts/main.gd) is a "God Object" managing game state, globe generation, input, and audio. [scripts/main_old.gd](scripts/main_old.gd) is DEPRECATED.
- **Tile Representation**: Tiles are **Dictionaries** in `Main.gd`. [scripts/tile.gd](scripts/tile.gd) is UNUSED.
    - Keys: `index`, `position`, `world_position`, `has_mine`, `is_revealed`, `is_flagged`, `neighbor_mines`, `neighbors`, `node`, `mesh`.
- **Procedural Audio**: Generated in [scripts/main.gd](scripts/main.gd) using `AudioStreamGenerator`. Sounds are played by pushing frames to `AudioStreamGeneratorPlayback` in `play_*` functions. [scripts/audio_generator.gd](scripts/audio_generator.gd) is DEPRECATED.
- **UI Management**: [scripts/ui.gd](scripts/ui.gd) handles HUD updates and calls `reset_game()` on the parent node. Plan to refactor to use Signals.

## Key Patterns & Conventions
- **Mine Placement**: `place_mines()` is called during `_ready()` or `reset_game()`. First-click safety is NOT implemented.
- **Input Handling**: `_input(event)` in `Main.gd` handles rotation (dragging) and interaction (clicking). `DRAG_THRESHOLD` (4.0) distinguishes them.
- **Geometry**: Icosphere with `subdivision_level` (default 3). Tiles are `StaticBody3D` with baked CSG meshes for rounded hexagonal shapes.
- **Performance**: F12 toggles a performance overlay. Metrics are in `performance_stats`.

## Developer Workflows
- **Running**: Use "Run Godot Project" task or `Godot_v4.4.1-stable_win64_console.exe --path .`.
- **Debugging**: Check `performance_stats` in `Main.gd` for FPS, memory, and generation time.
- **Resetting**: Call `reset_game()` in `Main.gd` to clear tiles and regenerate the globe.

## Common Tasks
- **Modifying Tiles**: Update `create_tile_at_position` in [scripts/main.gd](scripts/main.gd).
- **Adjusting Difficulty**: Modify `@export` variables in `Main.gd`: `globe_radius`, `subdivision_level`, and `mine_percentage`.
- **Audio Changes**: Modify `play_*` functions in `Main.gd` to adjust procedural waveforms.
- **UI Updates**: Edit [scenes/ui.tscn](scenes/ui.tscn) and [scripts/ui.gd](scripts/ui.gd).
