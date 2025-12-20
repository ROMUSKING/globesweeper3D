# GlobeSweeper 3D - AI Coding Instructions

## Project Overview
GlobeSweeper 3D is a spherical Minesweeper game built in Godot 4.4.1. It uses an icosphere geometry with hexagonal tiles and features procedural audio generation.

## Architecture & Data Flow
- **Central Controller**: [scripts/main.gd](scripts/main.gd) manages game state, input coordination, and delegates to specialized managers. It handles the main game loop, camera rotation/zoom, difficulty settings, and performance monitoring. Key exports: `globe_radius` (default 20.0), `subdivision_level` (default 3), `mine_percentage` (default 0.15).
- **Globe Generation**: [scripts/globe_generator.gd](scripts/globe_generator.gd) handles icosphere geometry, vertex-to-hex conversion, and tile instantiation. Uses `CSGCombiner3D` to bake optimized meshes for hexagonal (and 12 pentagonal) tiles. Computes `hex_radius` to ensure tile edges touch without overlap. Reuses shared meshes (`shared_hex_mesh`, `shared_pent_mesh`) for performance.
- **Interaction Management**: [scripts/interaction_manager.gd](scripts/interaction_manager.gd) handles raycasting and input events (mouse/touch). Uses `tile_index` metadata on `StaticBody3D` nodes to identify tiles and emits signals like `tile_clicked(index, button)`. Distinguishes drag (rotation) from click using `DRAG_THRESHOLD` (4.0).
- **Audio Management**: [scripts/audio_manager.gd](scripts/audio_manager.gd) generates procedural sound effects using `AudioStreamGenerator`. No external audio files; samples pushed via `push_frame()`. Separate streams for reveal, explosion, win/lose sounds.
- **Tile Representation**: Tiles are instances of the `Tile` class ([scripts/tile.gd](scripts/tile.gd), inherits `RefCounted`). Each stores state (mine, revealed, flagged) and a reference to its `StaticBody3D` node.
- **UI Management**: [scripts/ui/ui_manager.gd](scripts/ui/ui_manager.gd) handles UI state switching between Main Menu, HUD, and Game Over screens. Communicates with `Main.gd` via signals (e.g., `start_game_requested`, `restart_game_requested`, `menu_requested`). Manages sub-scenes: [scenes/ui/MainMenu.tscn](scenes/ui/MainMenu.tscn), [scenes/ui/HUD.tscn](scenes/ui/HUD.tscn), [scenes/ui/GameOver.tscn](scenes/ui/GameOver.tscn).

## Key Patterns & Conventions
- **First-Click Safety**: Mines are NOT placed at start. `place_mines()` is called in `reveal_tile()` on the first click, excluding the clicked tile and its neighbors.
- **Input Handling**: `InteractionManager.gd` distinguishes rotation (dragging) from interaction (clicking) using `DRAG_THRESHOLD` (4.0). Left-click reveals, right-click flags, drag rotates globe, wheel zooms.
- **Visual States**: [shaders/tile.gdshader](shaders/tile.gdshader) uses `u_state` uniform: `0.0` (Hidden), `1.0` (Revealed), `2.0` (Flagged), `3.0` (Mine). Colors change based on state; revealed tiles use `NEIGHBOR_COLORS` array for mine count display.
- **Geometry**: Icosphere with `subdivision_level`. First 12 vertices are always pentagons; others hexagons. Tiles positioned at `vertex * globe_radius`. Neighbors calculated post-generation for accurate adjacency.
- **Performance**: F12 toggles performance overlay. Metrics tracked in `performance_stats` in `Main.gd` (FPS, memory, generation time). Shared meshes reused. Tweens used for tile reveal animations (scale down to 0.1, apply visuals, scale back up).
- **Game State**: Enum `GameState {MENU, PLAYING, GAME_OVER}` in `Main.gd`. Statistics tracked in `game_statistics` dict. Scoring based on efficiency (safe tiles revealed / total time).
- **Difficulty Scaling**: Enum `DifficultyLevel {EASY, MEDIUM, HARD}` adjusts `globe_radius`, `subdivision_level`, `mine_percentage` via `apply_difficulty_settings()`.

## Developer Workflows
- **Running**: Use "Run Godot Project" task or `Godot_v4.4.1-stable_win64_console.exe --path .`. For headless check-only, add `--headless --check-only`.
- **Debugging**: Check `performance_stats` in `Main.gd` for FPS, memory, generation time. Print report with F12. Use Godot's debugger for breakpoints.
- **Resetting**: Call `reset_game()` in `Main.gd` to clear tiles and regenerate globe.
- **Building**: No custom build steps; Godot handles compilation. Use Godot editor for scene editing and testing.
- **Testing**: Run in editor to test gameplay. Use `_process()` for real-time monitoring. Validate tile neighbor calculations and mine placement logic.

## Common Tasks
- **Modifying Tiles**: Update `create_tile_at_position` or `generate_tile_mesh` in [scripts/globe_generator.gd](scripts/globe_generator.gd). Adjust `hex_radius` calculation for sizing.
- **Adjusting Difficulty**: Modify `@export` variables in `Main.gd`: `globe_radius`, `subdivision_level`, `mine_percentage`. Higher subdivision exponentially increases tile count.
- **Audio Changes**: Modify `_setup_streams` or `play_*` functions in [scripts/audio_manager.gd](scripts/audio_manager.gd). Sounds use sine waves, noise, envelopes pushed to `AudioStreamGenerator`.
- **UI Updates**: Edit [scenes/ui.tscn](scenes/ui.tscn) and [scripts/ui/ui_manager.gd](scripts/ui/ui_manager.gd). Connect signals like `start_game_requested` for new game button. Modify sub-scenes for specific UI elements.
- **Interaction Logic**: Modify `_update_hover` or `_handle_mouse_button` in [scripts/interaction_manager.gd](scripts/interaction_manager.gd). Raycast against `StaticBody3D` with `tile_index` meta.
- **Shader Modifications**: Update [shaders/tile.gdshader](shaders/tile.gdshader) for visual effects. Use `u_state` to switch between hidden/revealed/flagged/mine appearances.
- **Adding Features**: For new mechanics, extend `Tile` class or add new managers following the delegation pattern from `Main.gd`. Use signals for cross-component communication.
