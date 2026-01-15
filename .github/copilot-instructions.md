# GlobeSweeper 3D — AI Agent Instructions

This guide helps AI coding agents get productive quickly in this Godot 4.4.1 project. Follow these instructions carefully to avoid breaking existing functionality.

## Table of Contents
- 🎯 Project Overview
- 🚀 Quick Start Commands
- 🏗 Architecture Overview
- 🔍 Where to Look First
- 🎓 Modern Best Practices
- 🧪 Testing & Validation
- 📋 Pre-Commit Checklist
- 🔧 Debugging & Performance
- 📚 Additional Resources


**Last updated:** 2026-01-15

## 🎯 Project Overview

GlobeSweeper 3D is a unique 3D implementation of the classic Minesweeper game featuring spherical gameplay on an icosphere geometry. The project features fully procedural geometry and audio generation, eliminating the need for external assets. It is designed for cross-platform compatibility with touch support.

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

### Project Structure
The project follows a modular architecture with clear separation of concerns:
- `scenes/`: Contains all scene files (main.tscn, ui.tscn, and UI component scenes)
- `scripts/`: Contains all GDScript files organized by system
- `shaders/`: Contains shader files for visual effects
- `ui/`: Contains UI controller scripts

## 🏗 Architecture Overview

### Core System Architecture
This project uses a **decomposed, signal-driven architecture** with clear separation of concerns:

```
Main.gd (Game Orchestrator)
├── GlobeGenerator (Geometry & Mesh Generation)
├── InteractionManager (Input & Raycasting)
├── AudioManager (Procedural Audio Synthesis)
├── SoundVFXManager (Unified Event & Effect Management)
├── VFXSystem (Particle & Visual Effects)
├── PowerupManager (Powerup Inventory & Activation)
├── GameStateManager (State Machine & Flow Control)
├── DifficultyScalingManager (Adaptive Difficulty)
├── ScoringSystem (Game Scoring & Metrics)
└── UIManager (UI State & Visual Feedback)
```

### Data Flow Pattern
1. **Input** → `InteractionManager` → emits `tile_clicked(index, button)`
2. **Main** → handles click → calls `reveal_tile()` or `flag_tile()`
3. **Game State** → validates state transitions → updates UI
4. **Audio** → receives events → generates procedural sound
5. **Difficulty** → monitors performance → adjusts parameters
6. **Scoring** → tracks metrics → updates UI and difficulty scaling

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
- **First-Click Safety**: First click always reveals a safe area, not just a single tile
- **Adaptive Difficulty**: Dynamic difficulty adjustment based on player performance metrics
- **Scoring System**: Comprehensive scoring with efficiency, streaks, and performance metrics

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
| `scripts/sound_vfx_manager.gd` | Event dispatching, audio/VFX coordination | `EventType` enum, `EventPriority` levels |
| `scripts/vfx_system.gd` | Particle effects, visual feedback rendering | VFX types, intensity scaling |
| `scripts/scoring_system.gd` | Game scoring, metrics, and high scores | Scoring algorithms, performance metrics |
| `scripts/ui/ui_manager.gd` | UI state management, visual feedback | Signal connections, HUD updates |
| `shaders/tile.gdshader` | Visual state rendering | `u_state` uniform (0-8) |

### Quick Navigation Guide
- **Game Loop**: `main.gd` → `_ready()` → `generate_globe()` → game state transitions
- **Input Flow**: `interaction_manager.gd` → `_physics_process()` → raycast → signals
- **Audio Flow**: `audio_manager.gd` → event listeners → `AudioStreamGenerator` → `push_frame()`
- **State Flow**: `game_state_manager.gd` → `change_state()` → validation → signals
- **Scoring Flow**: `scoring_system.gd` → tracks metrics → updates UI and difficulty

## 🎯 Project-Specific Conventions

### Geometry & Mesh Generation
- **Icosphere Algorithm**: Start with icosahedron → subdivide faces → project to sphere → convert to hexagons
- **First 12 vertices are pentagons** (icosahedron vertices), rest are hexagons
- **Subdivision levels**: 2=42 tiles, 3=162 tiles, 4=642 tiles, 5=2562 tiles
- **Tile positioning**: Inward offset (1.0 unit) to hide sphere interior
- **Tile scaling**: Automatically adjusted per difficulty (EASY: 2.2, MEDIUM: 1.8, HARD: 1.2)
- **Mesh caching**: `shared_hex_mesh` and `shared_pent_mesh` prevent redundant generation
- **Hex radius**: Calculated dynamically based on actual vertex spacing to prevent overlap

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

### Sound/VFX Event System
- **Unified architecture**: `SoundVFXManager` coordinates all audio and visual events
- **Event types**: `TILE_REVEAL`, `TILE_FLAG`, `MINE_EXPLOSION`, `GAME_WIN`, `GAME_LOSE`, `CHORD_REVEAL`, etc.
- **Event priority**: `LOW` (background), `MEDIUM` (standard), `HIGH` (critical), `IMMEDIATE` (system)
- **Trigger flow**: Main detects action → `sound_vfx_manager.trigger_event(type, position)` → audio plays + VFX triggers
- **Intensity scaling**: VFX system responds to `vfx_intensity` and `master_volume` parameters
- **Configuration**: Enable/disable via `sound_enabled`, `vfx_enabled` exports

### VFX System Details
**VFX Types & Configurations** (in `vfx_system.gd`):
- `tile_reveal`: 20 particles, 0.5s lifetime, blue, scale 0.3
- `tile_reveal_mine`: 30 particles, 0.8s lifetime, red-orange, scale 0.5
- `flag_placed`: 15 particles, 0.3s lifetime, yellow, scale 0.2
- `flag_removed`: 10 particles, 0.2s lifetime, cyan, scale 0.15
- `mine_explosion`: 100 particles, 1.0s lifetime, red-orange, scale 1.5
- `standard_fireworks`: 200 particles, 1.8s lifetime, white, scale 1.0
- `advanced_fireworks`: 400 particles, 2.5s lifetime, yellow, scale 1.8
- `mega_fireworks`: 800 particles, 3.0s lifetime, multi-color, scale 2.0+

**Particle System Pattern**:
- Called from SoundVFXManager when events occur
- Particles spawn at position with duration based on config
- Intensity multiplier scales particle count and lifetime for different game states

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

### UI Controller Architecture
The UI system uses a **modular controller pattern** with dedicated controllers for each screen:
- **main_menu_controller.gd**: Menu navigation and difficulty selection
- **hud_controller.gd**: In-game HUD (timer, score, mines counter)
- **pause_menu_controller.gd**: Pause state with resume/quit options
- **game_over_controller.gd**: Game over screen with stats and restart
- **settings_menu_controller.gd**: Settings including difficulty scaling toggle
- **powerup_panel_controller.gd**: Powerup UI with availability and cooldowns

**Signal Pattern**: Controllers emit signals (e.g., `start_game_requested`, `pause_requested`) → Main connects and handles → No direct method calls for loose coupling

### Difficulty Scaling
**Scaling Modes:**
- `CONSERVATIVE`: Small, gradual adjustments (±0.1 per game)
- `AGGRESSIVE`: Fast progression for skilled players (±0.2 per game)
- `ADAPTIVE`: Balances challenge and accessibility (±0.15 per game)
- `STATIC`: Traditional fixed difficulty (no scaling)

**Difficulty Range**: 0.5 (easiest) to 2.0 (hardest), default 1.0

**Performance tracking**: Efficiency, speed, error rate, streaks, powerup dependency

**Adjustment Logic**:
- Increases difficulty: 80%+ efficiency and <30% error rate
- Decreases difficulty: <60% efficiency or >40% error rate
- Tracks performance over 10 games (adaptation window)
- Scaling history maintained for rollback capability

**Difficulty-Specific Tile Scaling**:
- **EASY** (subdivision 2): 42 tiles, globe_radius 15.0, tile_scale 2.2
- **MEDIUM** (subdivision 3): 162 tiles, globe_radius 20.0, tile_scale 1.8
- **HARD** (subdivision 4): 642 tiles, globe_radius 25.0, tile_scale 1.2

Tile scale is automatically adjusted to maintain visual consistency and prevent overlap across difficulty levels. Larger scales on easier difficulties and smaller scales on harder difficulties ensure tiles remain visually distinct and playable.

## 🎯 Scoring System Architecture

**Metrics Tracked** (in `scoring_system.gd`):
- **Efficiency Score**: correct_moves / total_moves (target: 80%+)
- **Speed Performance**: game_timer / expected_time (faster is better)
- **Error Rate**: mistakes / total_moves (target: <30%)
- **Streak Performance**: Consecutive correct moves bonus
- **Powerup Dependency**: Reliance on powerups (lower is better)

**Scoring Formula Example**:
```
base_score = safe_tiles_revealed * 10
efficiency_bonus = (correct_moves / total_moves) * 50
speed_bonus = (1.0 - game_timer / time_limit) * 30
streak_bonus = current_streak * 5
final_score = base + efficiency + speed + streak
```

**Game Result System** (`game_result.gd`):
RefCounted wrapper capturing game outcome data:
- `victory`: bool
- `game_time`: float
- `tiles_revealed`: int
- `mines_flagged`: int
- `final_score`: int
- `efficiency`: float
- `error_rate`: float
- `streak_length`: int
- `powerups_used`: int

Used by difficulty scaling manager to track performance history and make scaling decisions.

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

### Type Hint Issues
- **Missing class_name declarations**: All manager scripts must have `class_name` declarations for type hints to work
- **Scene file parsing errors**: Missing or incorrect type hints can cause scene files to fail loading
- **Circular dependencies**: Ensure all type hints reference valid classes with proper declarations
- **HUD scene structure**: Complex UI scenes require all referenced nodes to exist in the scene hierarchy

### Common Parser Errors
- **"Could not find type X in current scope"**: Add `class_name X` to the script file
- **"Parse error in scene file"**: Check for missing nodes or incorrect parent paths
- **"Node not found"**: Verify scene hierarchy matches @onready variable paths

### Recent Issues & Solutions
For a complete list of parser errors encountered and their fixes, see `PARSER_ERROR_FIXES.md` in the project root. This includes:
- AudioManager type resolution
- Scene file loading issues
- Missing signal handlers
- Indentation and variable shadowing fixes

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

### Parser Validation
- [ ] All scripts have `class_name` declarations if used as type hints
- [ ] Scene files can load without parse errors
- [ ] No "Could not find type in current scope" errors
- [ ] All @onready paths match actual scene hierarchy
- [ ] No variable shadowing issues
- [ ] All signal handlers are implemented

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

### Example 2: Fixing Parser Errors
```gdscript
# Problem: "Could not find type AudioManager in current scope"
# Solution: Add class_name declaration to audio_manager.gd

# Before:
extends Node

# After:
class_name AudioManager
extends Node

# Then all type hints like this will work:
var audio_manager: AudioManager
```

### Example 3: Scene File Node Paths
```gdscript
# Problem: "Node not found" errors in @onready variables
# Solution: Verify scene hierarchy matches paths

# In settings_menu_controller.gd:
@onready var scaling_toggle = $VBoxContainer/ScalingContainer/ScalingToggle

# Must exist in scenes/ui/SettingsMenu.tscn:
# [node name="VBoxContainer" type="VBoxContainer" parent="."]
#   [node name="ScalingContainer" type="Container" parent="VBoxContainer"]
#     [node name="ScalingToggle" type="CheckButton" parent="VBoxContainer/ScalingContainer"]
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

---

## 🎓 Modern Best Practices for Godot & Game Development

This section documents contemporary best practices based on official Godot 4.4.1 documentation and proven game development patterns. These practices enhance code quality, maintainability, and performance.

### Godot Architecture Principles

#### Loose Coupling & Dependency Injection
**Problem**: Hard-coded node references create cascading failures and reduce reusability.

**Solution**: Use signals for inter-system communication and dependency injection patterns.

\```gdscript
# ❌ Tight coupling - avoid
extends Node
func _ready():
    var audio = get_node("AudioManager")
    audio.play_sound("reveal")  # Direct call creates hard dependency

# ✅ Loose coupling - prefer
extends Node
signal reveal_requested

func _ready():
    reveal_requested.connect(audio_manager.play_reveal_sound)
    emit_signal("reveal_requested")  # Decoupled signal communication
```
**Benefits**: 
- Systems can be tested in isolation
- Easy to swap implementations
- Reusable across projects
- Resilient to refactoring

#### Single Responsibility Principle (SRP)
**Definition**: Each script should have one reason to change.

\```gdscript
# ❌ Violates SRP - handles too many responsibilities
class_name GameManager
extends Node

func _process(delta):
    update_score()  # Scoring logic
    update_physics()  # Physics logic
    update_audio()  # Audio logic
    update_ui()  # UI logic

# ✅ Follows SRP - each system has one job
class_name ScoringSystem
extends Node
signal score_changed(new_score: int)

func add_points(amount: int):
    score += amount
    score_changed.emit(score)
```
**Benefits**:
- Easier to understand and maintain
- Simpler to test and debug
- Reduced side effects
- Better code reuse

#### Encapsulation & Data Hiding
**Principle**: Hide internal implementation details; expose only necessary interfaces.

\```gdscript
# ❌ Exposes internal state - allow external modification
class_name Player
extends Node3D

var health: int = 100  # Anyone can modify this directly

# ✅ Protects internal state with accessors
class_name Player
extends Node3D

var health: int = 100
signal health_changed(new_health: int)

func take_damage(amount: int):
    health = max(0, health - amount)
    health_changed.emit(health)

func heal(amount: int):
    health = min(100, health + amount)
    health_changed.emit(health)
```
**Benefits**:
- Prevents invalid state
- Allows validation before state changes
- Simplifies refactoring internal implementation
- Clear API contract

#### SOLID Principles in Godot

**Single Responsibility**: Each manager handles one domain (audio, UI, state, etc.)

**Open/Closed**: Design systems to be extended via inheritance or composition, not modification.

\```gdscript
# Base powerup class - open for extension
class_name Powerup
extends RefCounted

var name: String
var cost: int
signal activated(powerup: Powerup)

func activate():
    activated.emit(self)
```
**Liskov Substitution**: Subclasses must be usable wherever their parent is expected.

\```gdscript
# All powerups can be used the same way
class_name MineRevealPowerup
extends Powerup

func _init():
    name = "Mine Reveal"
    cost = 75
```
**Interface Segregation**: Create focused, minimal interfaces.

\```gdscript
# Don't make one manager interface that does everything
# ❌ Too broad
class_name Manager
func start(), stop(), pause(), resume(), reset()

# ✅ Focused interfaces
class_name AudioManager
extends Node
signal audio_ready

func play_sound(event: String):
    pass
```
**Dependency Inversion**: Depend on abstractions, not concrete implementations.

\```gdscript
# ✅ Depend on signal interface, not specific AudioManager
signal reveal_tile
signal flag_tile
# Connect to any system that wants to handle these
```
### GDScript Code Quality Standards

#### Type Hints for Safety & Performance
Type hints enable IDE autocompletion and compile-time error detection.

\```gdscript
# ❌ No type information - harder to understand
extends Node

func process_tiles(tiles):
    for tile in tiles:
        reveal_tile(tile)

# ✅ Clear type information
extends Node

func process_tiles(tiles: Array[Tile]) -> void:
    for tile in tiles:
        reveal_tile(tile)

# Complex return types
func get_tile_stats() -> Dictionary[String, int]:
    return {"flagged": flag_count, "revealed": reveal_count}

# Callable types for signals/callbacks
var on_complete: Callable = func(): pass
```
**Type Hints Checklist**:
- ✅ All function parameters
- ✅ Return types
- ✅ Class variables (especially public ones)
- ✅ Signal parameter types
- ✅ Dictionary and Array element types

#### Naming Conventions
Follow consistent naming for clarity and IDE completion.

\```gdscript
class_name TileManager  # PascalCase for classes

const MAX_TILES = 100  # UPPER_SNAKE_CASE for constants
const TILE_OFFSET = Vector3(1.0, 0.0, 0.0)

var is_playing: bool  # snake_case for variables
var current_score: int

func reveal_tile(tile_index: int) -> void:  # snake_case for methods
    pass

func _on_tile_clicked(index: int) -> void:  # _on_ prefix for signal handlers
    reveal_tile(index)

var _internal_cache: Dictionary  # _prefix for private variables
```
**Signal Naming**:
\```gdscript
signal tile_revealed  # Past tense for events that happened
signal state_changed
signal game_started
signal score_updated(new_score: int)

# Handler method names
func _on_tile_revealed(index: int):
    pass
```
#### Documentation Standards
Clear documentation helps future maintainers (including your future self).

\```gdscript
## Reveals a tile on the globe.
## 
## This method handles the complete reveal flow including:
## - Validation that tile is hidden
## - Mine check and cascade reveal
## - Audio and visual feedback
## - Difficulty scaling adjustments
##
## [param tile_index]: The index of the tile to reveal (0-based)
## [return]: true if reveal was successful, false if invalid state
func reveal_tile(tile_index: int) -> bool:
    pass

## Signal emitted when a tile is successfully revealed.
## Provides the tile index and whether it contained a mine.
signal tile_revealed(index: int, has_mine: bool)

## Configuration for difficulty scaling behavior.
## Determines how aggressively the game adjusts difficulty.
enum ScalingMode {
    CONSERVATIVE,  # Small adjustments
    AGGRESSIVE,    # Fast progression  
    ADAPTIVE,      # Balanced approach
    STATIC         # No scaling
}
```
### Performance Best Practices

#### Caching & Lookups
Cache computed values instead of recalculating every frame.

\```gdscript
# ❌ Inefficient - recalculates every frame
extends Node

var tiles: Array[Tile]

func _process(_delta):
    var hex_tiles = tiles.filter(func(t): return t.is_hex)
    # ... do something with hex_tiles

# ✅ Efficient - cache the filtered result
extends Node

var tiles: Array[Tile]
var _hex_tiles_cache: Array[Tile] = []
var _cache_dirty: bool = true

func _ready():
    for tile in tiles:
        tile.state_changed.connect(_on_tile_state_changed)

func _on_tile_state_changed():
    _cache_dirty = true

func _process(_delta):
    if _cache_dirty:
        _hex_tiles_cache = tiles.filter(func(t): return t.is_hex)
        _cache_dirty = false
    
    # Use cached result
    for tile in _hex_tiles_cache:
        process_tile(tile)
```
#### Efficient Loops & Filtering
Write loops that terminate early and avoid unnecessary iterations.

\```gdscript
# ❌ Inefficient - iterates entire array even after finding target
func find_tile(target_index: int) -> Tile:
    for tile in tiles:
        if tile.index == target_index:
            return tile
    return null

# ✅ Efficient - uses direct lookup with validation
func find_tile(target_index: int) -> Tile:
    if target_index < 0 or target_index >= tiles.size():
        return null
    return tiles[target_index]

# Better for large collections: use Dictionary
var tiles_by_index: Dictionary[int, Tile] = {}

func find_tile(target_index: int) -> Tile:
    return tiles_by_index.get(target_index)
```
#### Memory Management with RefCounted
Use RefCounted for automatic memory cleanup.

\```gdscript
# ❌ Manual cleanup required
class_name GameSession
extends Node

func _exit_tree():
    # Must manually disconnect signals
    tile_revealed.disconnect(on_tile_reveal)

# ✅ Automatic cleanup with RefCounted
class_name GameResult
extends RefCounted

var victory: bool
var score: int
signal processed

# Automatically freed when no references exist
# No manual cleanup needed
```
### Signal-Driven Architecture

#### Proper Signal Usage
Signals enable decoupling and event-driven design.

\```gdscript
# ✅ Good signal patterns in GlobeSweeper
class_name AudioManager
extends Node

# Clear, specific signals for different events
signal reveal_sound_requested(position: Vector3)
signal explosion_requested(intensity: float)
signal background_music_changed(track: String)

func trigger_event(event_type: String, position: Vector3):
    match event_type:
        "tile_reveal":
            reveal_sound_requested.emit(position)
        "mine_explosion":
            explosion_requested.emit(1.0)
```
#### Signal Connection Best Practices
\```gdscript
# ❌ Avoid lambda in connections - harder to disconnect
signal_name.connect(func(): do_something())

# ✅ Named method - can be disconnected if needed
signal_name.connect(_on_signal_received)

func _on_signal_received():
    do_something()

# For cleanup when scene exits
func _exit_tree():
    signal_name.disconnect(_on_signal_received)
```
### Game Development Best Practices

#### Defensive Programming
Validate input and state before processing.

\```gdscript
# ❌ Assumes valid state
func reveal_tile(index: int):
    tiles[index].reveal()

# ✅ Validates before processing
func reveal_tile(index: int) -> bool:
    if not _is_valid_tile_index(index):
        push_error("Invalid tile index: " + str(index))
        return false
    
    if tiles[index].is_revealed:
        push_warning("Tile already revealed: " + str(index))
        return false
    
    tiles[index].reveal()
    return true

func _is_valid_tile_index(index: int) -> bool:
    return index >= 0 and index < tiles.size()
```
#### Testing & Validation
Built-in test patterns for validation.

\```gdscript
# ✅ Test suite pattern from GlobeSweeper
func run_tests() -> Dictionary:
    var results = {}
    
    # Geometry tests
    results["geometry"] = test_geometry_generation()
    
    # State machine tests
    results["state_machine"] = test_state_transitions()
    
    # Scoring tests
    results["scoring"] = test_scoring_calculations()
    
    return results

func test_geometry_generation() -> Dictionary:
    var test = {"status": "PASS", "details": []}
    
    var generator = GlobeGenerator.new()
    var globe = generator.generate(42)
    
    if globe.tiles.size() != 42:
        test.status = "FAIL"
        test.details.append("Tile count mismatch")
    
    return test
```
#### Cross-Platform Input Handling
Support multiple input methods for broad accessibility.

\```gdscript
# ✅ Handle touch, mouse, and keyboard
func _input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            _on_mouse_pressed(event.position, event.button_index)
    
    elif event is InputEventScreenTouch:
        if event.pressed:
            _on_touch_pressed(event.position)
    
    elif event is InputEventKey:
        if event.pressed and event.keycode == KEY_SPACE:
            _on_space_pressed()

func _on_mouse_pressed(position: Vector2, button: int):
    if button == MOUSE_BUTTON_LEFT:
        reveal_at_position(position)
    elif button == MOUSE_BUTTON_RIGHT:
        flag_at_position(position)

func _on_touch_pressed(position: Vector2):
    reveal_at_position(position)
```
### Code Organization Best Practices

#### Directory Structure by Feature
Organize code by feature/subsystem, not by type.
```
scripts/
├── main.gd                          # Game orchestrator
├── managers/
│   ├── game_state_manager.gd       # State machine
│   ├── scoring_system.gd           # Score tracking
│   ├── difficulty_scaling_manager.gd # Adaptive difficulty
│   ├── audio_manager.gd            # Audio synthesis
│   └── interaction_manager.gd      # Input handling
├── generation/
│   ├── globe_generator.gd          # Mesh generation
│   └── mine_placement.gd           # Mine algorithm
├── effects/
│   ├── vfx_system.gd              # Particle effects
│   └── sound_vfx_manager.gd       # Event coordination
└── ui/
    ├── ui_manager.gd              # UI orchestration
    ├── hud_controller.gd          # In-game HUD
    ├── main_menu_controller.gd    # Menu logic
    └── settings_menu_controller.gd # Settings UI
```
**Benefits**:
- Easy to find related code
- Clear dependencies between subsystems
- Easier to isolate and test features
- Self-documenting structure

#### Git Practices
Write meaningful commit messages and keep commits focused.
```bash
# ❌ Poor commit messages
git commit -m "fix stuff"
git commit -m "wip"

# ✅ Clear, descriptive messages
git commit -m "fix: prevent mine placement near first click

- Add safe_zone calculation in place_mines()
- Validate no mines within 2-tile radius
- Add test for first-click safety"

git commit -m "refactor: extract audio synthesis to separate method

- Move AudioStreamGenerator setup to _setup_audio_stream()
- Reduces _ready() complexity
- Improves testability"

git commit -m "feat: add difficulty scaling performance tracking

- Track efficiency, speed, error rate metrics
- Adjust difficulty based on 10-game window
- Add scaling history for rollback capability"
```
### Common Pitfalls & Prevention

#### Pitfall 1: Circular Signal Connections
**Problem**: System A listens to System B, which listens to System A = infinite loops.

\```gdscript
# ❌ Circular connection
signal health_changed(value: int)

func _ready():
    health_changed.connect(_on_health_changed)

func _on_health_changed(value: int):
    health_changed.emit(value - 1)  # Emits again = infinite loop
```
**Solution**: Carefully track signal dependencies; prefer unidirectional flows.

\```gdscript
# ✅ Unidirectional flow
signal health_decreased(value: int)

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        death_requested.emit()
    else:
        health_decreased.emit(health)
```
#### Pitfall 2: Missing Type Hints
**Problem**: No autocompletion, hard to debug type mismatches.

\```gdscript
# ❌ Missing types
func process_tiles(tiles):
    for tile in tiles:
        # No autocompletion for tile methods

# ✅ Clear types
func process_tiles(tiles: Array[Tile]) -> void:
    for tile in tiles:
        # Autocompletion available for Tile methods
```
#### Pitfall 3: Not Cleaning Up Signals
**Problem**: Memory leaks and stale signal handlers.

```gdscript
# ❌ Signal leaks memory (GlobeSweeper Anti-Pattern)
class_name GlobeTile
extends StaticBody3D  # Matches actual project base class

func _ready():
    GameStateManager.state_changed.connect(_on_state_changed)

# ✅ Proper cleanup (GlobeSweeper Best Practice)
func _exit_tree():
    if GameStateManager.state_changed.is_connected(_on_state_changed):
        GameStateManager.state_changed.disconnect(_on_state_changed)
```

#### Pitfall 4: Hardcoded Values
**Problem**: Magic numbers reduce maintainability (especially in difficulty scaling).

**GlobeSweeper Example**:
```gdscript
# ❌ Anti-pattern from early versions
func adjust_difficulty():
    if efficiency > 0.8:  # What's 0.8?
        mine_percentage += 0.1

# ✅ Current best practice (from DifficultyScalingManager.gd)
const HIGH_EFFICIENCY_THRESHOLD = 0.8
const MINE_SCALING_STEP = 0.1

func adjust_difficulty():
    if efficiency > HIGH_EFFICIENCY_THRESHOLD:
        mine_percentage += MINE_SCALING_STEP
```

#### Pitfall 5: Blocking the Main Thread
**Problem**: Long operations freeze the game.

\```gdscript
# ❌ Blocks rendering
func generate_large_mesh():
    for i in range(100000):
        # Heavy computation without yielding

# ✅ Yields periodically
func generate_large_mesh():
    for i in range(100000):
        if i % 100 == 0:
            await get_tree().process_frame
        # Continue heavy computation
```
### Further Reading

**Official Godot Documentation**:
- [Best Practices Guide](https://docs.godotengine.org/en/stable/tutorials/best_practices/)
- [Scene Organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html)
- [Performance Best Practices](https://docs.godotengine.org/en/stable/tutorials/performance/index.html)
- [Signals and Connections](https://docs.godotengine.org/en/stable/tutorials/best_practices/signals.html)

**GlobeSweeper 3D Implementation Examples**:
- Signal-driven architecture: [main.gd](scripts/main.gd), [audio_manager.gd](scripts/audio_manager.gd)
- State management: [game_state_manager.gd](scripts/game_state_manager.gd)
- Encapsulation: [powerup_manager.gd](scripts/powerup_manager.gd)
- Testing patterns: [comprehensive_test_suite.gd](scripts/comprehensive_test_suite.gd)
- Performance optimization: [globe_generator.gd](scripts/globe_generator.gd)

---

**Final Reminder**: These best practices compound over time. Small improvements in code organization, type safety, and signal discipline prevent major issues later. Invest in clarity now to save debugging time tomorrow.

