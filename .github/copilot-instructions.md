# GlobeSweeper 3D - AI Coding Instructions

## Project Overview
GlobeSweeper 3D is a spherical Minesweeper game built in Godot 4.4.1. It uses an icosphere geometry with hexagonal tiles and features procedural audio generation.

## Architecture & Data Flow
- **Central Controller**: [scripts/main.gd](scripts/main.gd) manages game state, input coordination, and delegates to specialized managers. It handles the main game loop, camera rotation, and zoom. Key exports: `globe_radius` (default 20.0), `subdivision_level` (default 3), `mine_percentage` (default 0.15).
- **Globe Generation**: [scripts/globe_generator.gd](scripts/globe_generator.gd) handles icosphere geometry, vertex-to-hex conversion, and tile instantiation. It uses `CSGCombiner3D` to bake optimized meshes for hexagonal (and 12 pentagonal) tiles. Computes `hex_radius` to ensure tile edges touch without overlap.
- **Interaction Management**: [scripts/interaction_manager.gd](scripts/interaction_manager.gd) handles raycasting and input events (mouse/touch). It uses `tile_index` metadata on `StaticBody3D` nodes to identify tiles and emits signals like `tile_clicked(index, button)`. Distinguishes drag (rotation) from click using `DRAG_THRESHOLD` (4.0).
- **Audio Management**: [scripts/audio_manager.gd](scripts/audio_manager.gd) generates procedural sound effects using `AudioStreamGenerator`. No external audio files are used; samples are pushed via `push_frame()`. Separate streams for reveal, explosion, win/lose sounds.
- **Tile Representation**: Tiles are instances of the `Tile` class ([scripts/tile.gd](scripts/tile.gd), inherits `RefCounted`). Each `Tile` object stores its state (mine, revealed, flagged) and a reference to its `StaticBody3D` node.
- **UI Management**: [scripts/ui.gd](scripts/ui.gd) handles HUD updates. It communicates with `Main.gd` via **Signals** (e.g., `game_reset_requested`). Updates mine counter, timer, and game status.

## Key Patterns & Conventions
- **First-Click Safety**: Mines are NOT placed at start. `place_mines()` is called in `reveal_tile()` on the first click, excluding the clicked tile and its neighbors.
- **Input Handling**: `InteractionManager.gd` distinguishes between rotation (dragging) and interaction (clicking) using `DRAG_THRESHOLD` (4.0). Left-click reveals, right-click flags, drag rotates globe.
- **Visual States**: [shaders/tile.gdshader](shaders/tile.gdshader) uses `u_state` uniform: `0.0` (Hidden), `1.0` (Revealed), `2.0` (Flagged), `3.0` (Mine). Colors and materials change based on state.
- **Geometry**: Icosphere with `subdivision_level`. The first 12 vertices are always pentagons; others are hexagons. Tiles are positioned at `vertex * globe_radius`.
- **Performance**: F12 toggles a performance overlay. Metrics are tracked in `performance_stats` in `Main.gd`. Shared meshes (`shared_hex_mesh`, `shared_pent_mesh`) are reused for efficiency.
- **Animation**: Tweens are used for tile reveal/flip animations (scale down to 0.1, apply visuals, scale back up).

## Developer Workflows
- **Running**: Use "Run Godot Project" task or `Godot_v4.4.1-stable_win64_console.exe --path .`. For headless check-only, use the task with `--headless --check-only`.
- **Debugging**: Check `performance_stats` in `Main.gd` for FPS, memory, and generation time. Print performance report with F12 key.
- **Resetting**: Call `reset_game()` in `Main.gd` to clear tiles and regenerate the globe.
- **Building**: No custom build steps; Godot handles compilation. Use Godot editor for scene editing.

## Common Tasks
- **Modifying Tiles**: Update `create_tile_at_position` or `generate_tile_mesh` in [scripts/globe_generator.gd](scripts/globe_generator.gd). Adjust `hex_radius` calculation for tile sizing.
- **Adjusting Difficulty**: Modify `@export` variables in `Main.gd`: `globe_radius`, `subdivision_level`, and `mine_percentage`. Higher subdivision increases tile count exponentially.
- **Audio Changes**: Modify `_setup_streams` or `play_*` functions in [scripts/audio_manager.gd](scripts/audio_manager.gd). Sounds use sine waves, noise, and envelopes pushed to `AudioStreamGenerator`.
- **UI Updates**: Edit [scenes/ui.tscn](scenes/ui.tscn) and [scripts/ui.gd](scripts/ui.gd). Connect signals like `game_reset_requested` for new game button.
- **Interaction Logic**: Modify `_update_hover` or `_handle_mouse_button` in [scripts/interaction_manager.gd](scripts/interaction_manager.gd). Raycast against `StaticBody3D` with `tile_index` meta.
- **Shader Modifications**: Update [shaders/tile.gdshader](shaders/tile.gdshader) for visual effects. Use `u_state` to switch between hidden/revealed/flagged/mine appearances.

## Key Patterns & Conventions
- **First-Click Safety**: Mines are NOT placed at start. `place_mines()` is called in `reveal_tile()` on the first click, excluding the clicked tile and its neighbors.
- **Input Handling**: `InteractionManager.gd` distinguishes between rotation (dragging) and interaction (clicking) using `DRAG_THRESHOLD` (4.0).
- **Visual States**: [shaders/tile.gdshader](shaders/tile.gdshader) uses `u_state` uniform: `0.0` (Hidden), `1.0` (Revealed), `2.0` (Flagged), `3.0` (Mine).
- **Geometry**: Icosphere with `subdivision_level`. The first 12 vertices are always pentagons; others are hexagons. Tiles are positioned at `vertex * globe_radius`.
- **Performance**: F12 toggles a performance overlay. Metrics are tracked in `performance_stats` in `Main.gd`.

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
