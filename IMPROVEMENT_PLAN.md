# Improvement Plan

## Phase 4: Reliability & Refactoring (Current Priority)

Focus on stability, bug fixes, and paying down technical debt identified in the 2025 Audit.

### 4.1 Critical Fixes

- [ ] **Implement First-Click Safety**: Refactor mine placement to happen after the first interaction to guarantee the start is safe.
- [ ] **Remove Dead Code**: Delete `scripts/audio_generator.gd` and any other unused assets.

### 4.2 Architecture Refactoring

- [ ] **Decompose `main.gd`**:
  - Extract Mesh Generation logic into a `GlobeGenerator` class/node.
  - Extract Audio logic into a dedicated `AudioManager`.
- [ ] **Decouple UI**: Refactor `ui.gd` to use Signals for communication instead of direct node paths.

## Phase 5: Polish & Features (Future)

- [ ] **Save/Load System**: Persist game state between sessions.
- [ ] **Visual Polish**: Shader-based water effects, particle effects for clearing mines.
- [ ] **Leaderboards**: Online high scores.
