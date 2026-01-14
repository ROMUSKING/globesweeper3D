class_name ScoringSystem
extends Node

# Comprehensive Scoring System for GlobeSweeper 3D
# Provides detailed scoring with performance metrics, accuracy calculations, and difficulty modifiers

# Scoring Signals
signal score_updated(new_score: int, delta: int, reason: String)
signal high_score_updated(new_high_score: int, difficulty_level: float)
signal accuracy_updated(new_accuracy: float)
signal performance_metrics_updated(metrics: Dictionary)
signal multiplier_changed(new_multiplier: float, reason: String)

# Scoring Configuration
var base_score_per_tile: int = 10
var base_score_per_flag: int = 15
var base_score_per_chord: int = 25
var base_time_bonus: int = 50
var base_completion_bonus: int = 500
var base_accuracy_bonus: int = 100
var base_streak_bonus: int = 20

# Current Game State
var current_score: int = 0
var current_multiplier: float = 1.0
var current_accuracy: float = 1.0
var current_streak: int = 0
var max_streak: int = 0
var tiles_revealed: int = 0
var flags_placed: int = 0
var correct_flags: int = 0
var total_tiles: int = 0
var game_start_time: float = 0.0

# Performance Metrics
var efficiency_score: float = 0.0
var speed_performance: float = 0.0
var error_rate: float = 0.0
var streak_performance: float = 0.0
var powerup_dependency: float = 0.0
var recovery_ability: float = 0.5

# References to other game systems
var game_state_manager: Node = null
var difficulty_scaling_manager: Node = null

# High Scores
var high_scores: Dictionary = {}

func _ready():
    initialize_scoring_system()
    connect_game_signals()

func initialize_scoring_system():
    """Initialize the scoring system"""
    reset_score()
    load_high_scores()

func connect_game_signals():
    """Connect to game state signals"""
    if game_state_manager:
        game_state_manager.state_changed.connect(_on_game_state_changed)
        game_state_manager.game_started.connect(_on_game_started)
        game_state_manager.game_ended.connect(_on_game_ended)

func reset_score():
    """Reset all scoring variables for a new game"""
    current_score = 0
    current_multiplier = 1.0
    current_accuracy = 1.0
    current_streak = 0
    max_streak = 0
    tiles_revealed = 0
    flags_placed = 0
    correct_flags = 0
    total_tiles = 0
    game_start_time = 0.0
    
    # Reset performance metrics
    efficiency_score = 0.0
    speed_performance = 0.0
    error_rate = 0.0
    streak_performance = 0.0
    powerup_dependency = 0.0
    recovery_ability = 0.5

# Scoring Methods

func add_score(points: int, reason: String = "general") -> int:
    """
    Add points to the current score with multiplier
    
    Args:
        points: Base points to add
        reason: Reason for score addition (for tracking)
        
    Returns:
        int: Total points added (including multiplier)
    """
    var points_with_multiplier = int(points * current_multiplier)
    current_score += points_with_multiplier
    
    score_updated.emit(current_score, points_with_multiplier, reason)
    
    return points_with_multiplier

func set_multiplier(new_multiplier: float, reason: String = "general"):
    """
    Set the current score multiplier
    
    Args:
        new_multiplier: New multiplier value
        reason: Reason for multiplier change
    """
    current_multiplier = clamp(new_multiplier, 0.5, 3.0)
    multiplier_changed.emit(current_multiplier, reason)

func adjust_multiplier(adjustment: float, reason: String = "general"):
    """
    Adjust the current score multiplier
    
    Args:
        adjustment: Amount to adjust multiplier by
        reason: Reason for multiplier adjustment
    """
    set_multiplier(current_multiplier + adjustment, reason)

func record_tile_reveal(success: bool = true):
    """Record a tile reveal action"""
    tiles_revealed += 1
    
    if success:
        current_streak += 1
        max_streak = max(max_streak, current_streak)
        add_score(base_score_per_tile, "tile_reveal")
    else:
        current_streak = 0
        add_score(-base_score_per_tile, "tile_reveal_failure")

func record_flag_placement(success: bool = true):
    """Record a flag placement action"""
    flags_placed += 1
    
    if success:
        correct_flags += 1
        add_score(base_score_per_flag, "flag_placement")
    else:
        add_score(-base_score_per_flag, "flag_misplacement")
    
    update_accuracy()

func record_chord_reveal(success: bool = true):
    """Record a chord reveal action"""
    if success:
        add_score(base_score_per_chord, "chord_reveal")
        current_streak += 1
        max_streak = max(max_streak, current_streak)
    else:
        current_streak = 0
        add_score(-base_score_per_chord, "chord_reveal_failure")

func record_powerup_use(powerup_type: String, needed: bool = true):
    """Record powerup usage"""
    # Powerup usage affects dependency metric
    if needed:
        powerup_dependency += 0.1
    else:
        powerup_dependency -= 0.05
        
    powerup_dependency = clamp(powerup_dependency, 0.0, 1.0)

func record_mistake(recovered: bool = false):
    """Record a player mistake"""
    current_streak = 0
    
    if recovered:
        recovery_ability += 0.1
    else:
        recovery_ability -= 0.1
        
    recovery_ability = clamp(recovery_ability, 0.0, 1.0)

func update_accuracy():
    """Update accuracy calculation"""
    if flags_placed > 0:
        current_accuracy = float(correct_flags) / float(flags_placed)
    else:
        current_accuracy = 1.0
        
    accuracy_updated.emit(current_accuracy)

func calculate_final_score(game_time: float, victory: bool) -> int:
    """
    Calculate final score with bonuses
    
    Args:
        game_time: Total game time in seconds
        victory: Whether the player won
        
    Returns:
        int: Final calculated score
    """
    # Time bonus (faster completion = higher bonus)
    var time_bonus = 0
    if game_time > 0:
        var expected_time = 300.0 # 5 minutes baseline
        var time_factor = clamp(expected_time / game_time, 0.5, 2.0)
        time_bonus = int(base_time_bonus * time_factor)
    
    # Accuracy bonus
    var accuracy_bonus = int(base_accuracy_bonus * current_accuracy)
    
    # Streak bonus
    var streak_bonus = int(base_streak_bonus * max_streak)
    
    # Completion bonus (only for victories)
    var completion_bonus = 0
    if victory:
        completion_bonus = base_completion_bonus
    
    # Calculate total bonuses
    var total_bonuses = time_bonus + accuracy_bonus + streak_bonus + completion_bonus
    
    # Add bonuses to current score
    current_score += total_bonuses
    
    # Apply difficulty multiplier if available
    if difficulty_scaling_manager:
        var difficulty_multiplier = difficulty_scaling_manager.get_scoring_multiplier()
        current_score = int(current_score * difficulty_multiplier)
    
    return current_score

# Performance Metrics

func calculate_performance_metrics(game_time: float) -> Dictionary:
    """
    Calculate comprehensive performance metrics
    
    Args:
        game_time: Total game time in seconds
        
    Returns:
        Dictionary: Performance metrics
    """
    # Efficiency score (correct moves / total moves)
    var total_moves = tiles_revealed + flags_placed
    if total_moves > 0:
        efficiency_score = float(tiles_revealed + correct_flags) / float(total_moves)
    
    # Speed performance (based on expected time)
    if game_time > 0:
        var expected_time = 300.0 # 5 minutes baseline
        speed_performance = clamp(expected_time / game_time, 0.0, 2.0)
    
    # Error rate (incorrect flags / total flags)
    if flags_placed > 0:
        error_rate = 1.0 - current_accuracy
    
    # Streak performance
    if total_moves > 0:
        streak_performance = float(max_streak) / float(total_moves)
    
    # Powerup dependency (0.0 to 1.0, higher = more dependent)
    powerup_dependency = clamp(powerup_dependency, 0.0, 1.0)
    
    var metrics = {
        "efficiency_score": efficiency_score,
        "speed_performance": speed_performance,
        "error_rate": error_rate,
        "streak_performance": streak_performance,
        "powerup_dependency": powerup_dependency,
        "recovery_ability": recovery_ability,
        "current_accuracy": current_accuracy,
        "max_streak": max_streak,
        "tiles_revealed": tiles_revealed,
        "flags_placed": flags_placed,
        "correct_flags": correct_flags
    }
    
    performance_metrics_updated.emit(metrics)
    
    return metrics

# High Score Management

func check_high_score(difficulty_level: float) -> bool:
    """
    Check if current score is a new high score for the difficulty level
    
    Args:
        difficulty_level: Current difficulty level
        
    Returns:
        bool: True if new high score
    """
    var difficulty_key = "%.1f" % difficulty_level
    var current_high_score = high_scores.get(difficulty_key, 0)
    
    if current_score > current_high_score:
        high_scores[difficulty_key] = current_score
        save_high_scores()
        high_score_updated.emit(current_score, difficulty_level)
        return true
    
    return false

func get_high_score(difficulty_level: float) -> int:
    """
    Get high score for a specific difficulty level
    
    Args:
        difficulty_level: Difficulty level to check
        
    Returns:
        int: High score for the difficulty level
    """
    var difficulty_key = "%.1f" % difficulty_level
    return high_scores.get(difficulty_key, 0)

func load_high_scores():
    """Load high scores from file"""
    if FileAccess.file_exists("user://high_scores.save"):
        var file = FileAccess.open("user://high_scores.save", FileAccess.READ)
        if file:
            high_scores = file.get_var()
            file.close()

func save_high_scores():
    """Save high scores to file"""
    var file = FileAccess.open("user://high_scores.save", FileAccess.WRITE)
    if file:
        file.store_var(high_scores)
        file.close()

# Game Event Handlers

func _on_game_state_changed(from_state, to_state):
    """Handle game state changes"""
    pass

func _on_game_started():
    """Handle game start event"""
    reset_score()
    game_start_time = Time.get_unix_time_from_system()

func _on_game_ended(victory: bool):
    """Handle game end event"""
    var game_time = Time.get_unix_time_from_system() - game_start_time
    
    # Calculate final score with bonuses
    calculate_final_score(game_time, victory)
    
    # Calculate performance metrics
    calculate_performance_metrics(game_time)
    
    # Check for high score
    if difficulty_scaling_manager:
        var difficulty_level = difficulty_scaling_manager.current_difficulty_level
        check_high_score(difficulty_level)

# Integration Methods

func set_game_state_manager_reference(manager: Node):
    """Set reference to game state manager"""
    game_state_manager = manager
    connect_game_signals()

func set_difficulty_scaling_manager_reference(manager: Node):
    """Set reference to difficulty scaling manager"""
    difficulty_scaling_manager = manager

# Utility Methods

func get_current_score() -> int:
    """Get current score"""
    return current_score

func get_current_multiplier() -> float:
    """Get current multiplier"""
    return current_multiplier

func get_current_accuracy() -> float:
    """Get current accuracy"""
    return current_accuracy

func get_performance_metrics() -> Dictionary:
    """Get current performance metrics"""
    return {
        "efficiency_score": efficiency_score,
        "speed_performance": speed_performance,
        "error_rate": error_rate,
        "streak_performance": streak_performance,
        "powerup_dependency": powerup_dependency,
        "recovery_ability": recovery_ability,
        "current_accuracy": current_accuracy,
        "max_streak": max_streak,
        "tiles_revealed": tiles_revealed,
        "flags_placed": flags_placed,
        "correct_flags": correct_flags
    }

func get_scoring_status() -> Dictionary:
    """Get comprehensive scoring status"""
    return {
        "current_score": current_score,
        "current_multiplier": current_multiplier,
        "current_accuracy": current_accuracy,
        "current_streak": current_streak,
        "max_streak": max_streak,
        "tiles_revealed": tiles_revealed,
        "flags_placed": flags_placed,
        "correct_flags": correct_flags,
        "game_start_time": game_start_time,
        "metrics": get_performance_metrics()
    }