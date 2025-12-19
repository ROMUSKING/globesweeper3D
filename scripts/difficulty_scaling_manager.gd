class_name DifficultyScalingManager
extends Node

# Difficulty Scaling Manager for GlobeSweeper 3D
# Provides adaptive difficulty adjustment based on player performance and behavior

# Difficulty Scaling Modes
enum ScalingMode {
	CONSERVATIVE, # Gradual, small adjustments
	AGGRESSIVE, # Faster difficulty progression for skilled players
	ADAPTIVE, # Balances challenge and accessibility
	STATIC # No scaling (traditional minesweeper experience)
}

# Difficulty Scaling Signals
signal scaling_enabled
signal scaling_disabled
signal difficulty_changed(from_level: float, to_level: float, reason: String)
signal performance_metrics_updated(metrics: Dictionary)
signal scaling_history_updated(history: Array)
signal player_skill_assessed(skill_level: float, confidence: float)

# Current scaling configuration
var is_scaling_enabled: bool = true
var current_mode: ScalingMode = ScalingMode.ADAPTIVE
var current_difficulty_level: float = 1.0 # 0.5 to 2.0 range
var min_difficulty: float = 0.5
var max_difficulty: float = 2.0

# Scaling triggers and thresholds
var performance_threshold: float = 0.8 # 80% efficiency triggers difficulty increase
var error_threshold: float = 0.3 # 30% error rate triggers difficulty decrease
var time_threshold: float = 0.7 # Time performance threshold

# Performance tracking data
var performance_history: Array = []
var current_session_metrics: Dictionary = {}
var session_start_time: float = 0.0

# Player performance metrics
var efficiency_score: float = 0.0
var speed_performance: float = 0.0
var error_rate: float = 0.0
var streak_performance: float = 0.0
var powerup_dependency: float = 0.0
var recovery_ability: float = 0.0

# Base difficulty parameters
var base_mine_density: float = 0.15
var base_grid_size: int = 20
var base_time_limit: float = 300.0 # 5 minutes
var base_subdivision_level: int = 3

# Scaling history for rollback capabilities
var scaling_history: Array = []
var max_history_entries: int = 50

# References to other game systems
var game_state_manager: Node = null
var main_script: Node = null
var powerup_manager: Node = null

# Adaptive learning parameters
var learning_rate: float = 0.1
var adaptation_window: int = 10 # Number of games to analyze
var confidence_threshold: float = 0.7

func _ready():
	initialize_scaling_system()
	connect_game_signals()

func initialize_scaling_system():
	"""Initialize the difficulty scaling system"""
	session_start_time = Time.get_unix_time_from_system()
	
	# Initialize current session metrics
	current_session_metrics = {
		"games_played": 0,
		"games_won": 0,
		"total_moves": 0,
		"correct_moves": 0,
		"total_time": 0.0,
		"powerups_used": 0,
		"mistakes_made": 0,
		"correct_flags": 0,
		"total_flags": 0,
		"longest_streak": 0,
		"recovery_attempts": 0,
		"successful_recoveries": 0
	}
	
	# Load scaling preferences if available
	load_scaling_preferences()

func connect_game_signals():
	"""Connect to game state and performance signals"""
	if game_state_manager:
		game_state_manager.state_changed.connect(_on_game_state_changed)
		game_state_manager.game_started.connect(_on_game_started)
		game_state_manager.game_ended.connect(_on_game_ended)

# Performance Tracking Methods

func record_player_action(action_type: String, success: bool = true, data: Dictionary = {}):
	"""
	Record player action for performance analysis
	
	Args:
		action_type: Type of action ("reveal", "flag", "chord", "powerup_use")
		success: Whether the action was successful
		data: Additional action data
	"""
	if not is_scaling_enabled:
		return
	
	match action_type:
		"reveal":
			record_reveal_action(success, data)
		"flag":
			record_flag_action(success, data)
		"chord":
			record_chord_action(success, data)
		"powerup_use":
			record_powerup_action(data)
		"mistake":
			record_mistake_action(data)

func record_reveal_action(success: bool, data: Dictionary):
	"""Record tile reveal action"""
	current_session_metrics.total_moves += 1
	if success:
		current_session_metrics.correct_moves += 1
	else:
		current_session_metrics.mistakes_made += 1

func record_flag_action(success: bool, data: Dictionary):
	"""Record flag placement action"""
	current_session_metrics.total_flags += 1
	if success:
		current_session_metrics.correct_flags += 1

func record_chord_action(success: bool, data: Dictionary):
	"""Record chord reveal action"""
	if success:
		current_session_metrics.correct_moves += 1
		# Chord reveals are considered high-skill actions
		streak_performance += 0.1

func record_powerup_action(data: Dictionary):
	"""Record powerup usage"""
	current_session_metrics.powerups_used += 1
	
	# Powerup dependency calculation
	var powerup_type = data.get("type", "")
	var needed = data.get("needed", true)
	
	if needed:
		powerup_dependency += 0.1
	else:
		powerup_dependency -= 0.05

func record_mistake_action(data: Dictionary):
	"""Record player mistake"""
	current_session_metrics.mistakes_made += 1
	
	# Recovery ability tracking
	var recovered = data.get("recovered", false)
	if recovered:
		current_session_metrics.successful_recoveries += 1
	else:
		current_session_metrics.recovery_attempts += 1

func record_game_end(victory: bool, game_time: float, final_score: int):
	"""Record game completion for analysis"""
	current_session_metrics.games_played += 1
	current_session_metrics.total_time += game_time
	
	if victory:
		current_session_metrics.games_won += 1
	
	# Calculate performance metrics for this game
	calculate_current_metrics()
	
	# Store in performance history
	var game_record = {
		"timestamp": Time.get_unix_time_from_system(),
		"victory": victory,
		"game_time": game_time,
		"final_score": final_score,
		"efficiency": efficiency_score,
		"speed": speed_performance,
		"error_rate": error_rate,
		"powerup_dependency": powerup_dependency,
		"streak_performance": streak_performance,
		"difficulty_level": current_difficulty_level
	}
	
	performance_history.append(game_record)
	
	# Limit history size
	if performance_history.size() > max_history_entries:
		performance_history.pop_front()
	
	# Analyze performance and potentially adjust difficulty
	analyze_and_adjust_difficulty()
	
	# Reset session metrics for next game
	reset_session_metrics()

# Performance Analysis Methods

func calculate_current_metrics():
	"""Calculate current performance metrics"""
	if current_session_metrics.total_moves > 0:
		efficiency_score = float(current_session_metrics.correct_moves) / float(current_session_metrics.total_moves)
	
	if current_session_metrics.total_flags > 0:
		var flag_accuracy = float(current_session_metrics.correct_flags) / float(current_session_metrics.total_flags)
		error_rate = 1.0 - flag_accuracy
	else:
		error_rate = 0.0
	
	# Speed performance based on expected time for current difficulty
	var expected_time = base_time_limit / current_difficulty_level
	var game_time = current_session_metrics.total_time
	if game_time > 0:
		speed_performance = clamp(expected_time / game_time, 0.0, 2.0)
	
	# Streak performance (simplified calculation)
	if current_session_metrics.games_played > 0:
		streak_performance = float(current_session_metrics.longest_streak) / float(current_session_metrics.games_played)
	
	# Powerup dependency (0.0 to 1.0, higher = more dependent)
	powerup_dependency = clamp(powerup_dependency, 0.0, 1.0)
	
	# Recovery ability
	if current_session_metrics.recovery_attempts > 0:
		recovery_ability = float(current_session_metrics.successful_recoveries) / float(current_session_metrics.recovery_attempts)
	else:
		recovery_ability = 0.5 # Neutral if no recovery attempts

func analyze_performance_trends() -> Dictionary:
	"""Analyze performance trends over recent games"""
	if performance_history.size() < 3:
		return {"trend": "insufficient_data", "confidence": 0.0}
	
	var recent_games = performance_history.slice(max(0, performance_history.size() - adaptation_window))
	
	# Extract efficiency values for trend calculation
	var efficiency_values = []
	var speed_values = []
	for game in recent_games:
		efficiency_values.append(game.efficiency)
		speed_values.append(game.speed)
	
	# Count victories
	var victory_count = 0
	for game in recent_games:
		if game.victory:
			victory_count += 1
	
	var trend_analysis = {
		"efficiency_trend": calculate_trend(efficiency_values),
		"speed_trend": calculate_trend(speed_values),
		"victory_rate": float(victory_count) / float(recent_games.size()),
		"consistency": calculate_consistency(efficiency_values),
		"confidence": calculate_confidence(recent_games.size())
	}
	
	return trend_analysis

func calculate_trend(values: Array) -> float:
	"""Calculate trend direction (-1 to 1)"""
	if values.size() < 2:
		return 0.0
	
	var trend = 0.0
	for i in range(1, values.size()):
		if values[i] > values[i - 1]:
			trend += 1.0
		elif values[i] < values[i - 1]:
			trend -= 1.0
	
	return trend / float(values.size() - 1)

func calculate_consistency(values: Array) -> float:
	"""Calculate performance consistency (0 to 1, higher = more consistent)"""
	if values.size() < 2:
		return 0.5
	
	var mean = 0.0
	for value in values:
		mean += value
	mean /= values.size()
	
	var variance = 0.0
	for value in values:
		variance += pow(value - mean, 2)
	variance /= values.size()
	
	return 1.0 / (1.0 + variance)

func calculate_confidence(sample_size: int) -> float:
	"""Calculate confidence in analysis based on sample size"""
	return clamp(float(sample_size) / float(adaptation_window), 0.0, 1.0)

# Difficulty Adjustment Methods

func analyze_and_adjust_difficulty():
	"""Main difficulty analysis and adjustment logic"""
	if not is_scaling_enabled or current_mode == ScalingMode.STATIC:
		return
	
	var trend_analysis = analyze_performance_trends()
	
	if trend_analysis.confidence < confidence_threshold:
		print("Difficulty Scaling: Insufficient data for confident adjustment")
		return
	
	var skill_level = calculate_player_skill_level(trend_analysis)
	var recommended_difficulty = calculate_recommended_difficulty(skill_level, trend_analysis)
	
	# Apply smoothing to avoid abrupt changes
	var adjusted_difficulty = apply_smoothing(recommended_difficulty)
	
	# Check if adjustment is significant enough
	if abs(adjusted_difficulty - current_difficulty_level) > 0.1:
		apply_difficulty_adjustment(adjusted_difficulty, "Performance analysis")

func calculate_player_skill_level(trend_analysis: Dictionary) -> float:
	"""Calculate overall player skill level (0 to 2)"""
	var skill_components = []
	
	# Efficiency component (40% weight)
	var efficiency_trend = trend_analysis.get("efficiency_trend", 0.0)
	skill_components.append(efficiency_trend * 0.4)
	
	# Speed component (25% weight)
	var speed_trend = trend_analysis.get("speed_trend", 0.0)
	skill_components.append(speed_trend * 0.25)
	
	# Victory rate component (25% weight)
	var victory_rate = trend_analysis.get("victory_rate", 0.0)
	var victory_component = (victory_rate - 0.5) * 2.0 # Normalize to -1 to 1
	skill_components.append(victory_component * 0.25)
	
	# Consistency component (10% weight)
	var consistency = trend_analysis.get("consistency", 0.5)
	var consistency_component = (consistency - 0.5) * 2.0 # Normalize to -1 to 1
	skill_components.append(consistency_component * 0.1)
	
	var skill_level = 1.0 # Start at baseline
	for component in skill_components:
		skill_level += component
	
	skill_level = clamp(skill_level, 0.0, 2.0)
	
	# Emit signal with skill assessment
	var confidence = trend_analysis.get("confidence", 0.0)
	player_skill_assessed.emit(skill_level, confidence)
	
	return skill_level

func calculate_recommended_difficulty(skill_level: float, trend_analysis: Dictionary) -> float:
	"""Calculate recommended difficulty based on skill level and mode"""
	var base_difficulty = skill_level
	
	match current_mode:
		ScalingMode.CONSERVATIVE:
			return clamp(lerp(current_difficulty_level, base_difficulty, 0.3), min_difficulty, max_difficulty)
		
		ScalingMode.AGGRESSIVE:
			return clamp(lerp(current_difficulty_level, base_difficulty, 0.8), min_difficulty, max_difficulty)
		
		ScalingMode.ADAPTIVE:
			return clamp(lerp(current_difficulty_level, base_difficulty, 0.5), min_difficulty, max_difficulty)
		
		ScalingMode.STATIC:
			return current_difficulty_level
	
	return current_difficulty_level

func apply_smoothing(target_difficulty: float) -> float:
	"""Apply smoothing to difficulty changes to avoid abrupt transitions"""
	var max_change_per_session = 0.2 # Maximum 20% change per analysis
	
	var diff = target_difficulty - current_difficulty_level
	if abs(diff) > max_change_per_session:
		return current_difficulty_level + (diff * max_change_per_session / abs(diff))
	
	return target_difficulty

func apply_difficulty_adjustment(new_difficulty: float, reason: String):
	"""Apply difficulty adjustment and record in history"""
	var old_difficulty = current_difficulty_level
	current_difficulty_level = clamp(new_difficulty, min_difficulty, max_difficulty)
	
	# Record in scaling history
	var adjustment_record = {
		"timestamp": Time.get_unix_time_from_system(),
		"from_difficulty": old_difficulty,
		"to_difficulty": current_difficulty_level,
		"reason": reason,
		"mode": current_mode
	}
	
	scaling_history.append(adjustment_record)
	
	# Limit history size
	if scaling_history.size() > max_history_entries:
		scaling_history.pop_front()
	
	# Emit signals
	difficulty_changed.emit(old_difficulty, current_difficulty_level, reason)
	scaling_history_updated.emit(scaling_history)
	
	print("Difficulty adjusted from %.2f to %.2f: %s" % [old_difficulty, current_difficulty_level, reason])

# Difficulty Parameter Calculation

func get_scaled_parameters() -> Dictionary:
	"""Get current difficulty-scaled game parameters"""
	var difficulty_factor = current_difficulty_level
	
	return {
		"mine_density": base_mine_density * difficulty_factor,
		"grid_size": int(base_grid_size * sqrt(difficulty_factor)),
		"subdivision_level": clamp(int(base_subdivision_level + (difficulty_factor - 1.0)), 1, 6),
		"time_limit": base_time_limit / difficulty_factor,
		"difficulty_level": current_difficulty_level
	}

func get_powerup_cost_multiplier() -> float:
	"""Get powerup cost multiplier based on difficulty and performance"""
	var base_multiplier = 1.0 / current_difficulty_level
	
	# Adjust based on powerup dependency
	var dependency_adjustment = 1.0 + (powerup_dependency * 0.5)
	
	return clamp(base_multiplier * dependency_adjustment, 0.5, 2.0)

func get_scoring_multiplier() -> float:
	"""Get scoring multiplier based on current difficulty"""
	return 1.0 * current_difficulty_level

# Game Event Handlers

func _on_game_state_changed(from_state, to_state):
	"""Handle game state changes"""
	if to_state == game_state_manager.GameState.PLAYING:
		# Game started
		pass
	elif to_state in [game_state_manager.GameState.GAME_OVER, game_state_manager.GameState.VICTORY]:
		# Game ended - will be handled by _on_game_ended
		pass

func _on_game_started():
	"""Handle game start event"""
	session_start_time = Time.get_unix_time_from_system()

func _on_game_ended(victory: bool):
	"""Handle game end event"""
	var game_time = Time.get_unix_time_from_system() - session_start_time
	var final_score = 0 # Will be updated by main script
	
	record_game_end(victory, game_time, final_score)

# Configuration and Control Methods

func set_scaling_enabled(enabled: bool):
	"""Enable or disable difficulty scaling"""
	is_scaling_enabled = enabled
	if enabled:
		scaling_enabled.emit()
	else:
		scaling_disabled.emit()

func set_scaling_mode(mode: ScalingMode):
	"""Set the difficulty scaling mode"""
	current_mode = mode
	print("Difficulty scaling mode set to: ", ScalingMode.keys()[mode])

func set_difficulty_bounds(min_level: float, max_level: float):
	"""Set minimum and maximum difficulty bounds"""
	min_difficulty = clamp(min_level, 0.1, 5.0)
	max_difficulty = clamp(max_level, min_difficulty, 10.0)
	current_difficulty_level = clamp(current_difficulty_level, min_difficulty, max_difficulty)

func reset_difficulty():
	"""Reset difficulty to baseline"""
	var old_difficulty = current_difficulty_level
	current_difficulty_level = 1.0
	
	var adjustment_record = {
		"timestamp": Time.get_unix_time_from_system(),
		"from_difficulty": old_difficulty,
		"to_difficulty": current_difficulty_level,
		"reason": "Manual reset",
		"mode": current_mode
	}
	
	scaling_history.append(adjustment_record)
	difficulty_changed.emit(old_difficulty, current_difficulty_level, "Manual reset")

func rollback_difficulty(steps: int = 1):
	"""Rollback difficulty changes"""
	if scaling_history.size() >= steps:
		var old_difficulty = current_difficulty_level
		
		# Find the adjustment to rollback to
		var target_difficulty = 1.0 # Default fallback
		var history_index = scaling_history.size() - steps - 1
		if history_index >= 0:
			target_difficulty = scaling_history[history_index].from_difficulty
		
		current_difficulty_level = target_difficulty
		
		var adjustment_record = {
			"timestamp": Time.get_unix_time_from_system(),
			"from_difficulty": old_difficulty,
			"to_difficulty": current_difficulty_level,
			"reason": "Rollback %d steps" % steps,
			"mode": current_mode
		}
		
		scaling_history.append(adjustment_record)
		difficulty_changed.emit(old_difficulty, current_difficulty_level, "Rollback %d steps" % steps)

# Utility Methods

func get_current_metrics() -> Dictionary:
	"""Get current performance metrics"""
	return {
		"efficiency_score": efficiency_score,
		"speed_performance": speed_performance,
		"error_rate": error_rate,
		"streak_performance": streak_performance,
		"powerup_dependency": powerup_dependency,
		"recovery_ability": recovery_ability,
		"current_difficulty": current_difficulty_level,
		"mode": ScalingMode.keys()[current_mode],
		"scaling_enabled": is_scaling_enabled
	}

func get_scaling_status() -> Dictionary:
	"""Get comprehensive scaling status"""
	var trend_analysis = analyze_performance_trends()
	
	return {
		"enabled": is_scaling_enabled,
		"mode": ScalingMode.keys()[current_mode],
		"current_difficulty": current_difficulty_level,
		"min_difficulty": min_difficulty,
		"max_difficulty": max_difficulty,
		"metrics": get_current_metrics(),
		"trend_analysis": trend_analysis,
		"history_size": scaling_history.size(),
		"performance_history_size": performance_history.size()
	}

func reset_session_metrics():
	"""Reset metrics for new session"""
	current_session_metrics = {
		"games_played": 0,
		"games_won": 0,
		"total_moves": 0,
		"correct_moves": 0,
		"total_time": 0.0,
		"powerups_used": 0,
		"mistakes_made": 0,
		"correct_flags": 0,
		"total_flags": 0,
		"longest_streak": 0,
		"recovery_attempts": 0,
		"successful_recoveries": 0
	}

# Persistence Methods

func save_scaling_preferences():
	"""Save scaling preferences to file"""
	var save_data = {
		"scaling_enabled": is_scaling_enabled,
		"current_mode": current_mode,
		"current_difficulty_level": current_difficulty_level,
		"min_difficulty": min_difficulty,
		"max_difficulty": max_difficulty,
		"performance_history": performance_history,
		"scaling_history": scaling_history
	}
	
	var file = FileAccess.open("user://difficulty_scaling.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_scaling_preferences():
	"""Load scaling preferences from file"""
	if not FileAccess.file_exists("user://difficulty_scaling.save"):
		return
	
	var file = FileAccess.open("user://difficulty_scaling.save", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		is_scaling_enabled = save_data.get("scaling_enabled", true)
		current_mode = save_data.get("current_mode", ScalingMode.ADAPTIVE)
		current_difficulty_level = save_data.get("current_difficulty_level", 1.0)
		min_difficulty = save_data.get("min_difficulty", 0.5)
		max_difficulty = save_data.get("max_difficulty", 2.0)
		performance_history = save_data.get("performance_history", [])
		scaling_history = save_data.get("scaling_history", [])

# Integration Methods

func set_main_script_reference(script: Node):
	"""Set reference to main game script"""
	main_script = script

func set_powerup_manager_reference(manager: Node):
	"""Set reference to powerup manager"""
	powerup_manager = manager

func set_game_state_manager_reference(manager: Node):
	"""Set reference to game state manager"""
	game_state_manager = manager
	connect_game_signals()
