# Difficulty Scaling Logic System - Implementation Documentation

## Overview

The Difficulty Scaling Logic System for GlobeSweeper 3D provides adaptive gameplay that dynamically adjusts difficulty based on player performance and behavior. This system ensures optimal challenge and engagement by analyzing player metrics and making intelligent difficulty adjustments.

## System Architecture

### Core Components

1. **DifficultyScalingManager** (`scripts/difficulty_scaling_manager.gd`)
   - Central orchestrator for all scaling logic
   - Performance tracking and analysis
   - Difficulty adjustment algorithms
   - Scaling history and rollback capabilities

2. **Integration Points**
   - **Main Game Script** (`scripts/main.gd`) - Game flow and player action tracking
   - **Powerup Manager** (`scripts/powerup_manager.gd`) - Difficulty-based cost adjustments
   - **UI Manager** (`scripts/ui_manager.gd`) - Scaling status display and controls
   - **Game State Manager** (`scripts/game_state_manager.gd`) - State transition handling

3. **Test Suite** (`scripts/difficulty_scaling_test.gd`)
   - Comprehensive testing of scaling scenarios
   - Performance validation
   - Bounds and persistence testing

## Key Features

### 1. Player Performance Metrics

The system tracks six key performance indicators:

- **Efficiency Score**: Ratio of correct moves to total moves (0.0 to 1.0)
- **Speed Performance**: Time taken vs expected time for difficulty level (0.0 to 2.0)
- **Error Rate**: Frequency of mistakes and corrections (0.0 to 1.0)
- **Streak Performance**: Consecutive correct moves and success patterns (0.0 to 1.0)
- **Powerup Dependency**: Reliance on powerups for progression (0.0 to 1.0)
- **Recovery Ability**: Performance after mistakes or setbacks (0.0 to 1.0)

### 2. Adaptive Difficulty Parameters

The system adjusts these game parameters based on performance:

- **Mine Density**: 0.10 to 0.25 (base 0.15)
- **Grid Complexity**: 15x15 to 30x30 (base 20x20)
- **Subdivision Level**: 1 to 6 (base 3)
- **Time Pressure**: 150s to 600s (base 300s)

### 3. Scaling Algorithms

#### Performance Assessment

```gdscript
func calculate_player_skill_level(trend_analysis: Dictionary) -> float:
    var efficiency_trend = trend_analysis.get("efficiency_trend", 0.0)
    var speed_trend = trend_analysis.get("speed_trend", 0.0)
    var victory_rate = trend_analysis.get("victory_rate", 0.0)
    var consistency = trend_analysis.get("consistency", 0.5)
    
    var skill_level = 1.0  # Baseline
    skill_level += efficiency_trend * 0.4  # 40% weight
    skill_level += speed_trend * 0.25      # 25% weight
    skill_level += victory_rate * 0.25     # 25% weight
    skill_level += consistency * 0.1       # 10% weight
    
    return clamp(skill_level, 0.0, 2.0)
```

#### Difficulty Calculation

```gdscript
func calculate_recommended_difficulty(skill_level: float, trend_analysis: Dictionary) -> float:
    var base_difficulty = skill_level
    
    match current_mode:
        ScalingMode.CONSERVATIVE:
            return clamp(lerp(current_difficulty_level, base_difficulty, 0.3), min_difficulty, max_difficulty)
        ScalingMode.AGGRESSIVE:
            return clamp(lerp(current_difficulty_level, base_difficulty, 0.8), min_difficulty, max_difficulty)
        ScalingMode.ADAPTIVE:
            return clamp(lerp(current_difficulty_level, base_difficulty, 0.5), min_difficulty, max_difficulty)
```

### 4. Difficulty Scaling Modes

#### Conservative Scaling

- Gradual difficulty adjustments (30% interpolation)
- Small changes to prevent jarring experience
- Best for casual players

#### Aggressive Scaling

- Faster difficulty progression (80% interpolation)
- Quick adaptation for skilled players
- Best for experienced players seeking challenge

#### Adaptive Scaling

- Balanced approach (50% interpolation)
- Optimal challenge/maintainability balance
- Default mode for most players

#### Static Mode

- No difficulty scaling
- Traditional minesweeper experience
- Best for competitive play

### 5. Scaling Triggers

The system triggers difficulty adjustments based on:

- **Performance Thresholds**: 80% efficiency triggers increase, 30% error rate triggers decrease
- **Time-based Analysis**: Speed performance vs expected completion time
- **Success Streaks**: Consecutive wins increase difficulty
- **Error Patterns**: High error rates decrease difficulty
- **Powerup Dependency**: Heavy powerup usage affects scaling calculations

## Integration Guide

### 1. Main Game Script Integration

```gdscript
# Initialize difficulty scaling manager
difficulty_scaling_manager = DifficultyScalingManagerScript.new()
add_child(difficulty_scaling_manager)
difficulty_scaling_manager.set_main_script_reference(self)
difficulty_scaling_manager.set_powerup_manager_reference(powerup_manager)
difficulty_scaling_manager.set_game_state_manager_reference(game_state_manager)

# Track player actions
func track_player_action(action_type: String, success: bool = true, data: Dictionary = {}):
    if difficulty_scaling_manager:
        difficulty_scaling_manager.record_player_action(action_type, success, data)

# Apply difficulty parameters
func apply_difficulty_scaling_parameters():
    var scaled_params = difficulty_scaling_manager.get_scaled_parameters()
    mine_percentage = scaled_params.mine_density
    subdivision_level = scaled_params.subdivision_level
```

### 2. Powerup System Integration

```gdscript
# Adjust powerup costs based on difficulty
func get_adjusted_powerup_cost(powerup_type: String) -> int:
    var base_cost = POWERUP_DEFINITIONS[powerup_type]["cost"]
    var cost_multiplier = difficulty_scaling_manager.get_powerup_cost_multiplier()
    return int(base_cost * cost_multiplier)

# Track powerup usage for scaling analysis
func record_powerup_action(data: Dictionary):
    var powerup_type = data.get("type", "")
    var needed = data.get("needed", true)
    if needed:
        powerup_dependency += 0.1
    else:
        powerup_dependency -= 0.05
```

### 3. UI Integration

```gdscript
# Display difficulty scaling information
func update_difficulty_display(difficulty_level: float):
    difficulty_label.text = "Difficulty: %.2fx" % difficulty_level

# Handle scaling control signals
func _on_scaling_toggle_toggled(enabled: bool):
    difficulty_scaling_manager.set_scaling_enabled(enabled)

func _on_scaling_mode_selected(mode_index: int):
    var mode_name = ["CONSERVATIVE", "AGGRESSIVE", "ADAPTIVE", "STATIC"][mode_index]
    difficulty_scaling_manager.set_scaling_mode(mode_name)
```

## Configuration Options

### Basic Configuration

```gdscript
# Set scaling enabled/disabled
difficulty_scaling_manager.set_scaling_enabled(true)

# Set scaling mode
difficulty_scaling_manager.set_scaling_mode(DifficultyScalingManager.ScalingMode.ADAPTIVE)

# Set difficulty bounds
difficulty_scaling_manager.set_difficulty_bounds(0.5, 2.0)
```

### Advanced Configuration

```gdscript
# Customize thresholds
difficulty_scaling_manager.performance_threshold = 0.8    # 80% efficiency
difficulty_scaling_manager.error_threshold = 0.3         # 30% error rate
difficulty_scaling_manager.time_threshold = 0.7          # Time performance

# Customize learning parameters
difficulty_scaling_manager.learning_rate = 0.1
difficulty_scaling_manager.adaptation_window = 10
difficulty_scaling_manager.confidence_threshold = 0.7
```

## Usage Examples

### 1. Basic Usage

```gdscript
# Start with default settings
func start_game():
    difficulty_scaling_manager = DifficultyScalingManagerScript.new()
    add_child(difficulty_scaling_manager)
    
    # The system will automatically track performance and adjust difficulty
    reset_game()

# Track player actions during gameplay
func on_tile_revealed(success: bool):
    track_player_action("reveal", success, {"tile_index": current_tile})
```

### 2. Advanced Usage with Custom Logic

```gdscript
# Custom difficulty adjustment
func custom_difficulty_adjustment():
    var current_metrics = difficulty_scaling_manager.get_current_metrics()
    
    if current_metrics.efficiency_score > 0.9:
        # Player is excelling, increase difficulty more aggressively
        difficulty_scaling_manager.set_scaling_mode(DifficultyScalingManager.ScalingMode.AGGRESSIVE)
    elif current_metrics.error_rate > 0.5:
        # Player is struggling, decrease difficulty
        difficulty_scaling_manager.rollback_difficulty(2)
```

### 3. UI Control Integration

```gdscript
# Settings menu integration
func create_difficulty_settings_panel():
    var panel = PanelContainer.new()
    
    # Scaling toggle
    var toggle = CheckBox.new()
    toggle.text = "Enable Difficulty Scaling"
    toggle.button_pressed = difficulty_scaling_manager.is_scaling_enabled
    toggle.toggled.connect(_on_scaling_toggle_toggled)
    panel.add_child(toggle)
    
    # Mode selector
    var selector = OptionButton.new()
    selector.add_item("Conservative")
    selector.add_item("Aggressive")
    selector.add_item("Adaptive")
    selector.add_item("Static")
    selector.selected = current_mode_index
    selector.item_selected.connect(_on_scaling_mode_selected)
    panel.add_child(selector)
    
    return panel
```

## Performance Monitoring

### Getting Current Status

```gdscript
func get_difficulty_scaling_status() -> Dictionary:
    return difficulty_scaling_manager.get_scaling_status()
```

Returns:

```gdscript
{
    "enabled": true,
    "mode": "ADAPTIVE",
    "current_difficulty": 1.25,
    "min_difficulty": 0.5,
    "max_difficulty": 2.0,
    "metrics": {
        "efficiency_score": 0.85,
        "speed_performance": 1.2,
        "error_rate": 0.15,
        "powerup_dependency": 0.3,
        "current_difficulty": 1.25
    },
    "trend_analysis": {
        "efficiency_trend": 0.3,
        "speed_trend": 0.2,
        "victory_rate": 0.8,
        "consistency": 0.7,
        "confidence": 0.9
    }
}
```

### Real-time Monitoring

```gdscript
# Connect to scaling signals for real-time updates
difficulty_scaling_manager.difficulty_changed.connect(func(from_level, to_level, reason):
    print("Difficulty adjusted: %.2f -> %.2f (%s)" % [from_level, to_level, reason])
    update_ui_difficulty_display(to_level)
)

difficulty_scaling_manager.player_skill_assessed.connect(func(skill_level, confidence):
    print("Player skill: %.2f (confidence: %.2f)" % [skill_level, confidence])
)
```

## Testing and Validation

### Running Tests

```gdscript
# Add test node to scene
var test_suite = preload("res://scripts/difficulty_scaling_test.gd").new()
add_child(test_suite)

# Run specific test
test_suite.run_specific_test("High Performance Test")

# Run all tests
test_suite.run_all_tests()

# Get test results
var results = test_suite.get_test_results()
```

### Test Scenarios

1. **Basic Scaling Test**: Validates core difficulty adjustment functionality
2. **High Performance Test**: Tests difficulty increase for skilled players
3. **Struggling Player Test**: Tests difficulty decrease for players having trouble
4. **Powerup Dependency Test**: Validates powerup usage impact on scaling
5. **Scaling Mode Test**: Tests all four scaling modes

### Validation Checklist

- [ ] Difficulty adjustments trigger at appropriate thresholds
- [ ] Scaling respects minimum/maximum bounds
- [ ] Different modes produce appropriate adjustment rates
- [ ] Powerup costs adjust correctly with difficulty
- [ ] UI displays current scaling status accurately
- [ ] Scaling preferences persist between sessions
- [ ] Performance metrics track accurately
- [ ] Rollback functionality works correctly

## Troubleshooting

### Common Issues

1. **No Difficulty Changes Detected**
   - Check if scaling is enabled: `difficulty_scaling_manager.is_scaling_enabled`
   - Verify sufficient game data for analysis (minimum 3 games)
   - Check confidence threshold settings

2. **Difficulty Changes Too Abrupt**
   - Switch to Conservative mode
   - Reduce learning rate
   - Increase adaptation window

3. **Powerup Costs Seem Wrong**
   - Verify difficulty scaling manager reference in powerup manager
   - Check cost multiplier calculation
   - Ensure powerup dependency tracking is working

4. **UI Not Updating**
   - Verify UI manager has difficulty scaling manager reference
   - Check signal connections
   - Ensure update methods are being called

### Debug Methods

```gdscript
# Enable debug logging
difficulty_scaling_manager.enable_debug_logging(true)

# Get detailed status
var status = difficulty_scaling_manager.get_scaling_status()
print(JSON.stringify(status, "  "))

# Check performance history
var history = difficulty_scaling_manager.performance_history
for game in history:
    print("Game: ", game)
```

## Performance Considerations

### Optimization Tips

1. **Data Retention**: Limit history sizes to prevent memory issues
   - Performance history: 50 entries max
   - Scaling history: 50 entries max

2. **Calculation Frequency**: Analysis runs only after game completion
   - No per-frame calculations
   - Efficient trend analysis using recent data window

3. **UI Updates**: Throttle UI updates to prevent excessive redraws
   - Update scaling status only when changes occur
   - Cache metric calculations when possible

### Memory Management

```gdscript
# Clear old data periodically
func cleanup_old_data():
    if performance_history.size() > max_history_entries:
        performance_history = performance_history.slice(-max_history_entries)
    
    if scaling_history.size() > max_history_entries:
        scaling_history = scaling_history.slice(-max_history_entries)
```

## Future Enhancements

### Planned Features

1. **Machine Learning Integration**: More sophisticated pattern recognition
2. **Multiplayer Scaling**: Difficulty adjustment for competitive scenarios
3. **Advanced Analytics**: Detailed performance dashboards
4. **Custom Scaling Rules**: Player-defined scaling parameters
5. **A/B Testing Framework**: Compare different scaling strategies

### Extension Points

1. **Custom Metrics**: Add new performance tracking metrics
2. **Alternative Algorithms**: Implement different scaling approaches
3. **Platform-Specific Adjustments**: Tailor scaling for different devices
4. **Accessibility Features**: Enhanced scaling for players with disabilities

## Conclusion

The Difficulty Scaling Logic System provides a comprehensive, adaptive gameplay experience that responds intelligently to player performance. By tracking multiple metrics and using sophisticated algorithms, the system maintains optimal challenge levels while respecting player preferences and constraints.

The modular architecture allows for easy integration with existing systems and provides extensive customization options for different gameplay scenarios. The comprehensive testing suite ensures reliability and performance across various usage patterns.

For questions or contributions, please refer to the source code documentation and test suite for implementation details and usage examples.
