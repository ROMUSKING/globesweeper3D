# GlobeSweeper 3D - AI Coding Instructions

## Project Overview
GlobeSweeper 3D is a spherical Minesweeper game built in Godot 4.4.1. It uses an icosphere geometry with hexagonal tiles and features procedural audio generation.

## Architecture & Data Flow
- **Central Controller**: [scripts/main.gd](scripts/main.gd) manages game state, input coordination, and delegates to specialized managers.
- **Globe Generation**: [scripts/globe_generator.gd](scripts/globe_generator.gd) handles icosphere geometry, vertex-to-hex conversion, and tile instantiation using `CSGCombiner3D` for baked meshes.
- **Interaction Management**: [scripts/interaction_manager.gd](scripts/interaction_manager.gd) handles raycasting and input events (mouse/touch). It uses `tile_index` metadata on `StaticBody3D` nodes to identify tiles.
- **Audio Management**: [scripts/audio_manager.gd](scripts/audio_manager.gd) generates procedural sound effects using `AudioStreamGenerator`. No external audio files are used; samples are pushed via `push_frame()`.
- **Tile Representation**: Tiles are instances of the `Tile` class defined in [scripts/tile.gd](scripts/tile.gd) (inherits `RefCounted`).
- **UI Management**: [scripts/ui.gd](scripts/ui.gd) handles HUD updates. It communicates with `Main.gd` via **Signals** (e.g., `game_reset_requested`).

## Key Patterns & Conventions
- **First-Click Safety**: Mines are NOT placed at start. `place_mines()` is called in `reveal_tile()` on the first click, excluding the clicked tile and its neighbors.
- **Input Handling**: `InteractionManager.gd` distinguishes between rotation (dragging) and interaction (clicking) using `DRAG_THRESHOLD` (4.0).
- **Visual States**: [shaders/tile.gdshader](shaders/tile.gdshader) uses `u_state` uniform: `0.0` (Hidden), `1.0` (Revealed), `2.0` (Flagged), `3.0` (Mine).
- **Geometry**: Icosphere with `subdivision_level`. Tiles are `StaticBody3D` with baked meshes. The first 12 vertices are always pentagons; others are hexagons.
- **Performance**: F12 toggles a performance overlay. Metrics are in `performance_stats` in `Main.gd`.

## Developer Workflows
- **Running**: Use "Run Godot Project" task or `Godot_v4.4.1-stable_win64_console.exe --path .`.
- **Debugging**: Check `performance_stats` in `Main.gd` for FPS, memory, and generation time.
- **Resetting**: Call `reset_game()` in `Main.gd` to clear tiles and regenerate the globe.

## Common Tasks
- **Modifying Tiles**: Update `create_tile_at_position` or `generate_tile_mesh` in [scripts/globe_generator.gd](scripts/globe_generator.gd).
- **Adjusting Difficulty**: Modify `@export` variables in `Main.gd`: `globe_radius`, `subdivision_level`, and `mine_percentage`.
- **Audio Changes**: Modify `_setup_streams` or `play_*` functions in [scripts/audio_manager.gd](scripts/audio_manager.gd).
- **UI Updates**: Edit [scenes/ui.tscn](scenes/ui.tscn) and [scripts/ui.gd](scripts/ui.gd).
- **Interaction Logic**: Modify `_update_hover` or `_handle_mouse_button` in [scripts/interaction_manager.gd](scripts/interaction_manager.gd).
