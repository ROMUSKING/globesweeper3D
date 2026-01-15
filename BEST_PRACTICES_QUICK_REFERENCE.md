# Quick Reference: Modern Best Practices for GlobeSweeper 3D

## 🎯 Key Principles

### Loose Coupling

✅ Use signals for communication between managers  
❌ Avoid hard-coded `get_node()` calls to other managers

**Example**:

```gdscript
# ✅ Good: Decoupled via signals
signal tile_revealed
reveal_requested.connect(audio_manager.play_sound)

# ❌ Bad: Tightly coupled
var audio = get_node("AudioManager")
audio.play_sound()
```

### Single Responsibility

✅ Each manager handles one domain (audio, UI, state, etc.)  
❌ Don't let one class do multiple jobs

**GlobeSweeper Managers**:

- `AudioManager` → Audio only
- `GameStateManager` → State transitions only
- `ScoringSystem` → Scoring only
- `DifficultyScalingManager` → Difficulty adjustment only

### Type Hints

✅ Always specify parameter and return types  
❌ Avoid untyped parameters and variables

**Example**:

```gdscript
# ✅ Good: Clear types
func reveal_tile(tile_index: int) -> bool:
    return tiles[tile_index].reveal()

# ❌ Bad: No type info
func reveal_tile(index):
    return tiles[index].reveal()
```

### Naming Conventions

| Category | Pattern | Example |
|----------|---------|---------|
| Classes | PascalCase | `class_name AudioManager` |
| Functions | snake_case | `func play_sound()` |
| Variables | snake_case | `var current_score: int` |
| Constants | UPPER_SNAKE_CASE | `const MAX_TILES = 100` |
| Private | _prefix | `var _internal_cache` |
| Signals | past_tense | `signal tile_revealed` |
| Handlers | _on_prefix | `func _on_tile_clicked()` |

## 🚀 Best Practices Summary

### Architecture

1. **Decompose**: Break large systems into focused managers
2. **Signal Decouple**: Use signals instead of direct method calls
3. **State Machines**: Use explicit state transitions (via GameStateManager)
4. **Encapsulate**: Hide internal state; expose via methods

### Code Quality

1. **Type Hints**: Every function parameter and return type
2. **Documentation**: Use `##` comments for public APIs
3. **Naming**: Follow conventions for classes, functions, variables
4. **Testing**: Build validation into manager classes

### Performance

1. **Cache**: Don't recalculate values every frame
2. **Validate**: Check bounds and state before access
3. **Memory**: Use RefCounted for automatic cleanup
4. **Async**: Yield periodically for long operations

### Signals

1. **Clear Names**: Use past-tense for events (`tile_revealed`)
2. **Typed Params**: Always specify signal parameter types
3. **Named Methods**: Connect to methods, not lambdas
4. **Cleanup**: Disconnect signals in `_exit_tree()`

## ⚠️ Common Pitfalls

### Pitfall 1: Circular Signals

**Problem**: Signal loops cause infinite recursion

```gdscript
# ❌ Bad: Infinite loop
signal state_changed
signal state_changed.connect(_on_state_changed)
func _on_state_changed():
    state_changed.emit()  # Emits again!
```

### Pitfall 2: Missing Type Hints

**Problem**: No IDE autocompletion, hard to debug

```gdscript
# ❌ Bad: No types
func process_tiles(tiles):
    for tile in tiles:
        pass

# ✅ Good: Clear types
func process_tiles(tiles: Array[Tile]) -> void:
    for tile in tiles:
        pass
```

### Pitfall 3: Signal Leaks

**Problem**: Memory leaks from undisconnected signals

```gdscript
# ✅ Always cleanup
func _exit_tree():
    if state_changed.is_connected(_on_state_changed):
        state_changed.disconnect(_on_state_changed)
```

### Pitfall 4: Blocking Main Thread

**Problem**: Long operations freeze the game

```gdscript
# ✅ Yield periodically
func generate_mesh():
    for i in range(1000):
        if i % 100 == 0:
            await get_tree().process_frame
        process_vertex(i)
```

### Pitfall 5: Hardcoded Values

**Problem**: Magic numbers scattered through code

```gdscript
# ❌ Bad: Magic number
if tile_damage > 50:
    instant_kill()

# ✅ Good: Named constant
const INSTANT_KILL_DAMAGE = 50
if tile_damage > INSTANT_KILL_DAMAGE:
    instant_kill()
```

## 📋 Checklist for New Features

- [ ] Uses signal-based communication
- [ ] Single responsibility (one job per manager)
- [ ] All functions have type hints
- [ ] Follows naming conventions
- [ ] Properly documented with `##` comments
- [ ] No circular signal dependencies
- [ ] Cleans up signals in `_exit_tree()`
- [ ] No blocking operations (uses `await` for long tasks)
- [ ] Uses constants instead of magic numbers
- [ ] Encapsulates internal state

## 🔗 Related Documentation

- [Modern Best Practices Section in copilot-instructions.md](.github/copilot-instructions.md)
- [GlobeSweeper 3D Architecture Overview](.github/copilot-instructions.md#-architecture-overview)
- [Official Godot Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/)
- [Official Godot Performance Guide](https://docs.godotengine.org/en/stable/tutorials/performance/index.html)

## 💡 Examples by Manager

### AudioManager Pattern

```gdscript
class_name AudioManager
extends Node

signal reveal_sound_requested(position: Vector3)

func trigger_event(event_type: String, position: Vector3) -> void:
    match event_type:
        "tile_reveal":
            reveal_sound_requested.emit(position)
```

### GameStateManager Pattern

```gdscript
class_name GameStateManager
extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }
signal state_changed(new_state: GameState)

func change_state(new_state: GameState) -> bool:
    if not _is_valid_transition(current_state, new_state):
        return false
    current_state = new_state
    state_changed.emit(new_state)
    return true
```

### ScoringSystem Pattern

```gdscript
class_name ScoringSystem
extends Node

var score: int = 0
signal score_updated(new_score: int)

func add_points(amount: int) -> void:
    score += amount
    score_updated.emit(score)
```

## 🎓 Further Learning

1. **Type Safety**: Advanced type hints with generics (`Array[Tile]`, `Dictionary[String, int]`)
2. **Performance**: Profiling with Debug menu (F12 performance overlay)
3. **Testing**: Build comprehensive test suites like `comprehensive_test_suite.gd`
4. **Architecture**: Study the 11-manager decomposition in `main.gd`
5. **Signals**: Advanced patterns with signal priorities and event systems

---

**Last Updated**: 2026-01-15  
**Godot Version**: 4.4.1  
**Project**: GlobeSweeper 3D
