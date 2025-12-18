# Improvement Plan

## Phase 4: Reliability & Refactoring ✅ COMPLETE

Focus on stability, bug fixes, and paying down technical debt identified in the 2025 Audit.

### 4.1 Critical Fixes

- [x] **Implement First-Click Safety**: Mine placement now happens after the first interaction to guarantee a safe start.
- [x] **Remove Dead Code**: Deleted `scripts/audio_generator.gd` and unused assets.

### 4.2 Architecture Refactoring

- [x] **Decompose `main.gd`**:
  - Extracted Mesh Generation logic into `GlobeGenerator`.
  - Extracted Audio logic into `AudioManager`.
- [x] **Decouple UI**: Refactored `ui.gd` to use Signals for communication.

## Phase 5: Visual Polish & Mechanics ✅ COMPLETE

Major overhaul of the interaction system and visual fidelity.

- [x] **Geometry Optimization**: Implemented shared meshes for Hexagons/Pentagons to improve performance.
- [x] **Interaction Manager**: Created a dedicated raycast-based input system for precise tile selection.
- [x] **Visual Polish**:
  - Implemented `tile.gdshader` for performant, state-based visual updates.
  - Added Fresnel rim lighting and dynamic color transitions.
  - Added a 3D Cursor for better hover feedback.
- [x] **Game Feel**:
  - Added camera momentum and smoothing.
  - Implemented Tween-based animations for tile reveals and flag toggling.

## Phase 6: Advanced Gameplay Features (Next Priority)

Adding depth and replayability to the core mechanics.

- [ ] **Difficulty Settings**:
  - Implement configurable Map Size (Radius/Subdivisions).
  - Implement configurable Mine Density.
- [ ] **Scoring System**:
  - Implement a High Score system (local persistence).
  - Add specific metrics (Efficiency, Streak).
- [ ] **Advanced Mechanics**:
  - **Chord Reveal**: Middle-click on a revealed number to auto-clear valid neighbors if flags match.
  - **Safe-Start Guarantee**: Ensure the initial reveal opens a playable area (not just a single tile).

## Phase 7: UI Overhaul (Future)

Replacing the developer UI with a polished, game-ready interface.

- [ ] **Theming**:
  - Design a cohesive "Holographic/Tech" theme to match the new shaders.
  - Create custom `Theme` resource for Godot controls.
- [ ] **Screens**:
  - **Main Menu**: Title, Play, Options, Credits.
  - **Pause Menu**: Resume, Restart, Options, Quit.
  - **Game Over Screen**: Animated results, stats summary, quick restart.
- [ ] **HUD**:
  - Stylish Mine Counter and Timer.
  - Interaction hints (LMB/RMB).

## Phase 8: Long Term Goals

- [ ] **Online Features**: Global Leaderboards.
- [ ] **Save/Load System**: Persist mid-game state.
- [ ] **Controller Support**: Gamepad navigation for the spherical grid.
