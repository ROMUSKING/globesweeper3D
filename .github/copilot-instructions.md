# GlobeSweeper 3D — AI Agent Instructions

This guide helps AI coding agents get productive quickly in this Godot 4.4.1 project. Follow these instructions carefully to avoid breaking existing functionality.

## 🚀 Quick Start Commands

### Development Workflow
```bash
# Open in Godot Editor (recommended for visual changes)
Godot_v4.4.1-stable_win64.exe --path .

# Headless validation (VS Code task)
Godot_v4.4.1-stable_win64_console.exe --path . --headless --check-only

# Run comprehensive test suite
Godot_v4.4.1-stable_win64_console.exe --path . --script res://scripts/run_tests.gd --headless

# Run difficulty scaling tests specifically
Godot_v4.4.1-stable_win64_console.exe --path . --script res://scripts/difficulty_scaling_test.gd --headless
```

### Essential VS Code Tasks
- **"Run Godot Project"**: Headless validation with `--check-only`
- **F12**: Toggle performance overlay (in running game)

## 🏗 Architecture Overview

### Core System Architecture
This project uses a **decomposed, signal-driven architecture** with clear separation of concerns:

```
Main.gd (Game Orchestrator)
├── GlobeGenerator (Geometry & Mesh Generation)
├── InteractionManager (Input & Raycasting)
├── AudioManager (Procedural Audio Synthesis)
├── PowerupManager (Powerup Inventory & Activation)
├── GameStateManager (State Machine & Flow Control)
├── DifficultyScalingManager (Adaptive Difficulty)
└── UIManager (UI State & Visual Feedback)
```

### Data Flow Pattern
1. **Input** → `InteractionManager` → emits `tile_clicked(index, button)`
2. **Main** → handles click → calls `reveal_tile()` or `flag_tile()`
3. **Game State** → validates state transitions → updates UI
4. **Audio** → receives events → generates procedural sound
5. **Difficulty** → monitors performance → adjusts parameters

### Critical Design Decisions
- **Lazy Mine Placement**: Mines are placed on first reveal, not at generation time (see `place_mines()` in `main.gd`)
- **Signal Decoupling**: All managers communicate via signals, not direct method calls
- **Procedural Audio**: No external audio files; all sounds synthesized via `AudioStreamGenerator`
- **Mesh Reuse**: Shared hex/pent meshes for performance optimization
- **State-Driven Visuals**: Shader `u_state` uniform controls all tile appearance

## 🔍 Where to Look First (Fast Path)

### Essential Files & Their Roles
| File | Primary Responsibility | Key Exports/Constants |
|------|------------------------|----------------------|
| `scripts/main.gd` | Game orchestration, globe generation, mine placement | `globe_radius`, `subdivision_level`, `mine_percentage` |
| `scripts/globe_generator.gd` | Icosphere generation, hex/pent mesh creation, neighbor calculation | `hex_radius`, `shared_hex_mesh`, `shared_pent_mesh` |
| `scripts/interaction_manager.gd` | Input processing, raycasting, drag detection | `DRAG_THRESHOLD = 4.0`, `tile_index` metadata |
| `scripts/game_state_manager.gd` | State machine, validation, persistence | `GameState` enum, transition validation |
| `scripts/powerup_manager.gd` | Powerup inventory, costs, activation logic | `POWERUP_DEFINITIONS`, cooldown management |
| `scripts/difficulty_scaling_manager.gd` | Adaptive difficulty, performance tracking | `ScalingMode`, performance thresholds |
| `scripts/audio_manager.gd` | Procedural audio synthesis, multi-channel management | `SAMPLE_RATE = 22050`, `AudioStreamGenerator` |
| `scripts/ui/ui_manager.gd` | UI state management, visual feedback | Signal connections, HUD updates |
| `shaders/tile.gdshader` | Visual state rendering | `u_state` uniform (0-6) |

### Quick Navigation Guide
- **Game Loop**: `main.gd` → `_ready()` → `generate_globe()` → game state transitions
- **Input Flow**: `interaction_manager.gd` → `_physics_process()` → raycast → signals
- **Audio Flow**: `audio_manager.gd` → event listeners → `AudioStreamGenerator` → `push_frame()`
- **State Flow**: `game_state_manager.gd` → `change_state()` → validation → signals

## 🎯 Project-Specific Conventions

### Geometry & Mesh Generation
- **Icosphere Algorithm**: Start with icosahedron → subdivide faces → project to sphere → convert to hexagons
- **First 12 vertices are pentagons** (icosahedron vertices), rest are hexagons
- **Subdivision levels**: 2=42 tiles, 3=162 tiles, 4=642 tiles, 5=2562 tiles
- **Tile positioning**: Inward offset (3.0 units) to hide sphere interior
- **Mesh caching**: `shared_hex_mesh` and `shared_pent_mesh` prevent redundant generation

### Input & Interaction
- **Left-click**: Reveal tile (if hidden)
- **Right-click**: Flag/unflag tile
- **Drag**: Rotate globe (threshold: 4.0 pixels)
- **Double-click**: Chord reveal (on revealed numbered tiles)
- **Metadata usage**: `StaticBody3D` nodes have `tile_index` meta for raycast identification

### Audio System
- **Procedural only**: No external audio assets
- **Multi-channel**: Separate players for background, reveal, explosion, win, lose, click, chord
- **Sample rate**: 22050 Hz (optimized for performance)
- **Buffer management**: Careful with `push_frame()` to avoid underflows/overflows
- **Audio glitch prevention**: Always call `play()` before `get_stream_playback()`

### Visual State Management
**Shader `u_state` values:**
- `0.0`: Hidden (base color)
- `1.0`: Revealed (light gray)
- `2.0`: Flagged (red)
- `3.0`: Mine revealed (dark red)
- `4.0`: Powerup revealed mine (purple)
- `5.0`: Hint highlighted (bright green)
- `6.0`: Protected mine (blue)

**Visual updates require:**
1. Shader uniform update: `material.set_shader_parameter("u_state", state_value)`
2. Tile state update in `tile.gd`
3. Optional: Visual feedback via UI manager

### First-Click Safety
- **Lazy mine placement**: `place_mines()` called from `reveal_tile()` on first reveal
- **Safety guarantee**: First click is always safe (no mine)
- **Neighbor calculation**: Happens after mine placement for accurate counts

### State Machine Patterns
**Valid State Transitions:**
```
MENU → PLAYING (start game)
PLAYING → PAUSED (pause)
PAUSED → PLAYING (resume)
PLAYING → GAME_OVER (mine hit)
PLAYING → VICTORY (all safe tiles revealed)
GAME_OVER → MENU (return to menu)
VICTORY → MENU (return to menu)
```

**State validation**: `GameStateManager` prevents invalid transitions and emits signals

### Powerup System
**Available Powerups:**
- `reveal_protection`: Prevents one mine explosion (cost: 50)
- `reveal_mine`: Auto-reveals one mine (cost: 75)
- `reveal_safe_tile`: Auto-reveals safe tile (cost: 25)
- `hint_system`: Shows safe tiles around area (cost: 30)
- `time_freeze`: Pauses timer for 30s (cost: 100)

**Activation flow**: Purchase → deduct score → activate → immediate effect or timed duration

### Difficulty Scaling
**Scaling Modes:**
- `CONSERVATIVE`: Small, gradual adjustments
- `AGGRESSIVE`: Fast progression for skilled players
- `ADAPTIVE`: Balances challenge and accessibility
- `STATIC`: Traditional fixed difficulty

**Performance tracking**: Efficiency, speed, error rate, streaks, powerup dependency
**Adjustment triggers**: Based on 80% efficiency threshold or 30% error rate

## 🧪 Testing & Validation

### Test Structure
- **Script-driven**: No external test framework
- **Pattern**: `run_all_tests()` → categorize → execute → report
- **Integration tests**: `comprehensive_test_suite.gd` tests all systems together
- **Unit tests**: Individual system tests (e.g., `difficulty_scaling_test.gd`)

### Running Tests
```bash
# Full test suite
Godot_v4.4.1-stable_win64_console.exe --path . --script res://scripts/run_tests.gd --headless

# Specific test categories
# (Run from within Godot Editor or via script)
```

### Test Categories
1. **System Integration**: All managers communicate correctly
2. **Functionality**: Core game mechanics work
3. **UI/UX**: Interface responsiveness and feedback
4. **Edge Cases**: Boundary conditions, error handling
5. **Performance**: Generation times, memory usage
6. **Game Flow**: Complete game sessions
7. **Error Handling**: Graceful failure recovery

### Adding New Tests
```gdscript
# In comprehensive_test_suite.gd
func run_new_feature_tests():
    print("\n--- NEW FEATURE TESTS ---")
    var test_result = {"status": "PASS", "details": []}
    
    # Test logic here
    if some_condition:
        test_result.details.append("✓ Feature works")
    else:
        test_result.status = "FAIL"
        test_result.details.append("✗ Feature broken")
    
    test_results["new_feature"] = test_result
    print("Result: " + test_result.status)
```

### Validation Checklist
- [ ] Run comprehensive test suite after any functional change
- [ ] Test multiple subdivision levels (2, 3, 4, 5)
- [ ] Verify audio doesn't glitch or underflow
- [ ] Check state transitions are valid
- [ ] Ensure performance metrics are accurate
- [ ] Validate UI feedback on all actions

## 🎮 Critical Workflows

### Adding a New Powerup
1. **Define in `POWERUP_DEFINITIONS`** (powerup_manager.gd)
2. **Add activation logic** in `activate_powerup()`
3. **Create UI button** in UI scene
4. **Connect signal** from UI to powerup manager
5. **Add visual feedback** (shader state or UI)
6. **Test purchase/activation flow**
7. **Update test suite** with powerup scenarios

### Modifying Globe Geometry
1. **Update `hex_radius` calculation** in globe_generator.gd
2. **Test overlap** at different subdivision levels
3. **Verify neighbor calculation** accuracy
4. **Check performance impact** (generation time, draw calls)
5. **Update visual tests** for new geometry

### Changing Audio System
1. **Modify `AudioStreamGenerator` parameters** carefully
2. **Test buffer sizes** to prevent underflows
3. **Add deterministic tests** for audio output length
4. **Verify multi-channel mixing** doesn't cause clipping
5. **Test on different hardware** (sample rate variations)

### Updating State Machine
1. **Add new state** to `GameState` enum
2. **Define valid transitions** in `valid_transitions`
3. **Update transition validation** logic
4. **Add state-specific signals** if needed
5. **Test all transition paths**
6. **Update UI state handling**

## ⚠️ Common Pitfalls & Gotchas

### Performance Issues
- **High subdivision levels**: Can cause frame drops (test on low-end hardware)
- **Memory leaks**: Always clean up nodes when regenerating globe
- **Audio glitches**: Buffer underflows from incorrect `push_frame()` usage
- **Raycast overhead**: Use physics layers to optimize collision detection

### State Management
- **Invalid transitions**: `GameStateManager` will reject and emit failure signal
- **Lost state data**: Ensure `state_persistence_enabled` is true for needed data
- **Signal loops**: Avoid circular signal connections

### Geometry & Mesh
- **Mesh regeneration**: Always reuse shared meshes when possible
- **Vertex ordering**: First 12 vertices must be pentagons
- **Neighbor calculation**: Must happen after subdivision for accuracy
- **Overlap detection**: Test `hex_radius` at multiple subdivision levels

### Audio Synthesis
- **Sample rate mismatch**: Keep at 22050 Hz for consistency
- **Buffer overflow**: Don't push too many frames at once
- **Player initialization**: Must call `play()` before `get_stream_playback()`
- **Memory usage**: Large buffers can cause memory spikes

### UI Integration
- **Signal connections**: UI must connect to manager signals, not call methods directly
- **State synchronization**: UI state must match game state manager
- **Visual feedback**: Use shader state for immediate visual response
- **Powerup UI**: Update availability based on score and cooldowns

## 🔧 Debugging & Performance

### Debug Tools
- **F12 Performance Overlay**: Real-time FPS, frame time, memory, draw calls
- **Console Output**: Debug prints for initialization and state changes
- **Error Logging**: Comprehensive error reporting in all managers
- **Test Reports**: Detailed test output with metrics

### Performance Monitoring
```gdscript
# In main.gd, performance_stats tracks:
# - FPS
# - Frame time
# - Memory usage
# - Draw calls
# - Generation time
# - Tile count
```

### Optimization Strategies
- **Mesh reuse**: Shared hex/pent meshes
- **Physics layers**: Optimize raycast targets
- **Signal efficiency**: Direct connections, no polling
- **Memory management**: Proper cleanup of generated nodes
- **Audio streaming**: Efficient buffer management

### Common Error Patterns
- **"AudioStreamGenerator not playing"**: Call `play()` before `get_stream_playback()`
- **"Invalid state transition"**: Check `valid_transitions` dictionary
- **"Tile overlap"**: Recalculate `hex_radius` for current subdivision
- **"Missing signal"**: Ensure signal is emitted in manager, connected in main

## 📋 Pre-Commit Checklist

Before making changes or creating PRs:

### Code Quality
- [ ] Run comprehensive test suite (all tests pass)
- [ ] Test at multiple subdivision levels (2, 3, 4, 5)
- [ ] Verify no audio glitches or memory leaks
- [ ] Check state transitions are valid
- [ ] Validate UI feedback on all actions

### Documentation
- [ ] Update function comments for new parameters
- [ ] Add signal documentation if new signals added
- [ ] Update test suite with new scenarios
- [ ] Document any breaking changes

### Performance
- [ ] Profile generation time impact
- [ ] Check memory usage patterns
- [ ] Verify draw call counts haven't increased
- [ ] Test on low-end hardware if possible

### Integration
- [ ] All managers communicate via signals
- [ ] UI updates correctly on state changes
- [ ] Audio triggers at appropriate times
- [ ] Difficulty scaling adjusts properly

## 🎯 Quick Reference Examples

### Example 1: Adding a New Tile State
```gdscript
# In tile.gd
const STATE_NEW = 7.0

# In shader (tile.gdshader)
# Add new color uniform and state check

# In main.gd or manager
tile.set_state(STATE_NEW)
material.set_shader_parameter("u_state", STATE_NEW)
```

### Example 2: New Powerup Implementation
```gdscript
# In powerup_manager.gd
const POWERUP_DEFINITIONS = {
    "new_powerup": {
        "name": "New Powerup",
        "cost": 100,
        "description": "Does something cool",
        "cooldown": 10,
        "duration": 5.0
    }
}

func activate_new_powerup():
    # Implementation logic
    emit_signal("powerup_activated", "new_powerup")
```

### Example 3: Performance Test
```gdscript
# In comprehensive_test_suite.gd
func test_performance():
    var start_time = Time.get_unix_time_from_system()
    # Run generation
    var end_time = Time.get_unix_time_from_system()
    var duration = end_time - start_time
    
    if duration < 2.0:
        test_result.details.append("✓ Performance acceptable")
    else:
        test_result.details.append("✗ Performance issue")
```

## 📚 Additional Resources

### Key Files for Deep Understanding
- `CODE_DOCUMENTATION.md`: Comprehensive code documentation
- `TECHNICAL_DOCS.md`: Algorithm details and technical specifications
- `README.md`: User-facing documentation and features
- `COMPREHENSIVE_TEST_REPORT.md`: Test results and validation
- `PHASE7_IMPLEMENTATION_PLAN.md`: Future development roadmap

### Architecture Patterns
- **Decomposition**: Large main.gd split into specialized managers
- **Signal-driven**: Decoupled communication between components
- **State machine**: Robust game flow control
- **Procedural generation**: No external assets required

### Development Philosophy
- **Safety first**: First-click safety, state validation, error handling
- **Performance conscious**: Mesh reuse, efficient algorithms, monitoring
- **User experience**: Smooth gameplay, clear feedback, intuitive controls
- **Maintainability**: Clear separation, documented interfaces, test coverage

---

**Remember**: When in doubt, run the test suite. It's your safety net for all changes.

**Need more specific guidance?** Ask about:
- Specific system implementation details
- Test case examples for new features
- Performance optimization strategies
- Architecture decision rationales
- Integration patterns for new components
