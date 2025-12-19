# GlobeSweeper 3D — AI Agent Instructions

This short guide helps an AI coding agent get productive quickly in this Godot (4.4.1) project.

## Quick start (commands)
- Open the project in Godot Editor (recommended for visual changes).
- Headless checks: use the VS Code task **"Run Godot Project"** (task runs: `Godot_v4.4.1-stable_win64_console.exe --path . --headless --check-only`).
- Run the test suite (headless):
  `Godot_v4.4.1-stable_win64_console.exe --path . --script res://scripts/run_tests.gd --headless`
  Tests print readable reports to stdout; `scripts/comprehensive_test_suite.gd` aggregates results.

## Where to look first (fast path)
- gameplay and orchestration: `scripts/main.gd` (globe generation, exports: `globe_radius`, `subdivision_level`, `mine_percentage`).
- geometry & tiles: `scripts/globe_generator.gd` (hex/pent mesh baking, `hex_radius`, `shared_hex_mesh`/`shared_pent_mesh`).
- input & click logic: `scripts/interaction_manager.gd` (raycasts, `tile_index` meta, signal `tile_clicked(index, button)`, `DRAG_THRESHOLD` = 4.0).
- tile model: `scripts/tile.gd` (RefCounted tile state and node refs).
- audio: `scripts/audio_manager.gd` (procedural AudioStreamGenerator; no external audio files — uses `push_frame()`).
- visuals/shader: `shaders/tile.gdshader` (uniform `u_state`: 0 hidden, 1 revealed, 2 flagged, 3 mine).
- tests: `scripts/run_tests.gd`, `scripts/comprehensive_test_suite.gd`, `scripts/difficulty_scaling_test.gd`.

## Project conventions & gotchas
- First-click safety: mines are placed lazily on first reveal — see `place_mines()` called from `reveal_tile()` in `main.gd`.
- Tile geometry: the first 12 vertices are pentagons; other tiles are hexagons. Changing subdivision level drastically changes tile count and perf.
- Mesh reuse: globe generator uses shared meshes (`shared_hex_mesh`, `shared_pent_mesh`) and `CSGCombiner3D` to optimize draw calls.
- Input semantics: left-click reveal, right-click flag, drag to rotate. Use `DRAG_THRESHOLD` to distinguish drag vs click.
- Audio: all SFX are synthesized in code; be careful when adjusting sample rates or push sizes to avoid audio glitches.
- Visual state is driven by shader `u_state` — updating visuals typically requires both shader and state updates in code.

## Testing & validation
- Tests are script-driven (not a test framework). Add test functions consistent with existing patterns (e.g., `run_all_tests()` style).
- For UI checks, there are test helpers in `scripts/ui/ui_manager.gd` (example: `test_powerup_ui()`).
- Always run `scripts/run_tests.gd` headless after functional changes; CI-like checks can use the `--script` command above.

## Performance & debugging
- Press F12 (in editor or running game) to toggle the performance overlay; metrics collected in `performance_stats` in `scripts/main.gd`.
- For geometry or memory regressions, test multiple `subdivision_level` values and profile generation times.

## Making safe changes
- When changing tile sizing or mesh generation, update `hex_radius` and re-check overlap at different `subdivision_level` values.
- When modifying audio code, add short, deterministic tests that validate `AudioStreamGenerator` output length and that no underflows/overflows occur.
- Keep changes small and run the comprehensive test suite and the difficulty scaling tests before opening a PR.

## Useful references (examples)
- Example: to change tile visuals, update `scripts/globe_generator.gd` (mesh) + `shaders/tile.gdshader` (`u_state`).
- Example: to add an interaction test, append a scenario to `scripts/comprehensive_test_suite.gd` and run `scripts/run_tests.gd`.

If any part is unclear or you want more examples (e.g., a template test or PR checklist), say which area to expand. Thank you!
