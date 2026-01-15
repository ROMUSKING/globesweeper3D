extends Node
class_name GameStateManager

# Comprehensive Game State Machine for GlobeSweeper 3D
# Provides robust state management with validation, history, and integration capabilities

# Constants
const MAX_STATE_HISTORY: int = 20

# Game States Enum
enum GameState {
	MENU, # Main menu state - handles navigation and difficulty selection
	PLAYING, # Active gameplay state - handles all game mechanics
	PAUSED, # Game paused state - freeze gameplay but maintain UI
	GAME_OVER, # Game lost state - shows game over screen and options
	VICTORY, # Game won state - shows victory screen and options
	SETTINGS # Settings menu state - handles configuration changes
}

# State Change Signals
signal state_changed(from_state: GameState, to_state: GameState)
signal state_entered(state: GameState)
signal state_exited(state: GameState)
signal state_transition_attempted(from_state: GameState, to_state: GameState, success: bool, reason: String)

# State-Specific Signals
signal game_paused
signal game_resumed
signal game_started
signal game_ended(victory: bool)
signal game_reset
signal settings_opened
signal settings_closed
signal main_menu_requested
signal back_navigation_requested

# Current state management
var current_state: GameState = GameState.MENU
var previous_state: GameState = GameState.MENU
var state_history: Array[GameState] = []
var state_entry_times: Dictionary = {}

# State configuration
var valid_transitions: Dictionary = {}
var state_persistence_enabled: bool = true
var debug_logging_enabled: bool = true

# State persistence data
var state_data: Dictionary = {}
var paused_game_data: Dictionary = {}

# Audio Manager reference for dependency injection
var _audio_manager: Node = null

func _ready():
	_setup_state_transitions()
	_log_state_change(GameState.MENU, GameState.MENU, "Initial state set to MENU")
	emit_signal("state_entered", GameState.MENU)

func _setup_state_transitions():
	"""Configure valid state transitions"""
	valid_transitions = {
		GameState.MENU: [GameState.PLAYING, GameState.SETTINGS],
		GameState.PLAYING: [GameState.PAUSED, GameState.GAME_OVER, GameState.VICTORY, GameState.MENU],
		GameState.PAUSED: [GameState.PLAYING, GameState.MENU, GameState.SETTINGS],
		GameState.GAME_OVER: [GameState.MENU, GameState.PLAYING, GameState.SETTINGS],
		GameState.VICTORY: [GameState.MENU, GameState.PLAYING, GameState.SETTINGS],
		GameState.SETTINGS: [GameState.MENU, GameState.PAUSED] # Can return to paused state
	}

func change_state(new_state: GameState, reason: String = "") -> bool:
	"""
	Attempt to change game state with validation and history tracking
	
	Args:
		new_state: The target state to transition to
		reason: Optional reason for the state change (for debugging)
	
	Returns:
		bool: True if state change was successful, false otherwise
	"""
	# Emit attempt signal
	emit_signal("state_transition_attempted", current_state, new_state, false, "")
	
	# Validate transition
	if not _is_valid_transition(current_state, new_state):
		var error_msg = "Invalid transition from %s to %s" % [get_state_name(current_state), get_state_name(new_state)]
		var context = {
			"current_state": current_state,
			"target_state": new_state,
			"valid_transitions": valid_transitions.get(current_state, [])
		}
		_log_error(error_msg, "", context)
		emit_signal("state_transition_attempted", current_state, new_state, false, error_msg)
		return false
	
	# Store current state in history
	previous_state = current_state
	state_history.append(current_state)
	
	# Limit history size to prevent memory issues
	if state_history.size() > MAX_STATE_HISTORY:
		state_history.pop_front()
	
	# Exit current state
	_log_state_change(current_state, new_state, reason)
	emit_signal("state_exited", current_state)
	_handle_state_exit(current_state)
	
	# Enter new state
	current_state = new_state
	state_entry_times[current_state] = Time.get_unix_time_from_system()
	emit_signal("state_entered", new_state)
	emit_signal("state_changed", previous_state, new_state)
	_handle_state_enter(new_state)
	
	# Emit success signal
	emit_signal("state_transition_attempted", previous_state, new_state, true, reason)
	
	return true

func _is_valid_transition(from_state: GameState, to_state: GameState) -> bool:
	"""Check if transition is valid"""
	if not valid_transitions.has(from_state):
		return false
	
	return to_state in valid_transitions[from_state]

func _handle_state_enter(state: GameState):
	"""Handle entering a specific state"""
	match state:
		GameState.MENU:
			_handle_menu_enter()
			_play_state_transition_sound("menu_enter")
		GameState.PLAYING:
			_handle_playing_enter()
			_play_state_transition_sound("game_start")
		GameState.PAUSED:
			_handle_paused_enter()
			_play_state_transition_sound("pause")
		GameState.GAME_OVER:
			_handle_game_over_enter()
			_play_state_transition_sound("game_over")
		GameState.VICTORY:
			_handle_victory_enter()
			_play_state_transition_sound("victory")
		GameState.SETTINGS:
			_handle_settings_enter()
			_play_state_transition_sound("settings")

func _handle_state_exit(state: GameState):
	"""Handle exiting a specific state"""
	match state:
		GameState.MENU:
			_handle_menu_exit()
		GameState.PLAYING:
			_handle_playing_exit()
		GameState.PAUSED:
			_handle_paused_exit()
		GameState.GAME_OVER:
			_handle_game_over_exit()
		GameState.VICTORY:
			_handle_victory_exit()
		GameState.SETTINGS:
			_handle_settings_exit()

# State-specific enter handlers
func _handle_menu_enter():
	emit_signal("main_menu_requested")

func _handle_playing_enter():
	emit_signal("game_started")

func _handle_paused_enter():
	emit_signal("game_paused")

func _handle_game_over_enter():
	emit_signal("game_ended", false)

func _handle_victory_enter():
	emit_signal("game_ended", true)

func _handle_settings_enter():
	emit_signal("settings_opened")

# State-specific exit handlers
func _handle_menu_exit():
	pass

func _handle_playing_exit():
	# Save game state if needed
	if state_persistence_enabled:
		_save_game_state()

func _handle_paused_exit():
	emit_signal("game_resumed")

func _handle_game_over_exit():
	pass

func _handle_victory_exit():
	pass

func _handle_settings_exit():
	emit_signal("settings_closed")

# Convenience methods for common state changes
func start_game() -> bool:
	"""Start a new game"""
	return change_state(GameState.PLAYING, "Start game requested")

func pause_game() -> bool:
	"""Pause the current game"""
	if current_state == GameState.PLAYING:
		return change_state(GameState.PAUSED, "Game paused")
	return false

func resume_game() -> bool:
	"""Resume from paused state"""
	if current_state == GameState.PAUSED:
		return change_state(GameState.PLAYING, "Game resumed")
	return false

func end_game(victory: bool = false) -> bool:
	"""End the current game (win or lose)"""
	var new_state = GameState.VICTORY if victory else GameState.GAME_OVER
	return change_state(new_state, "Game ended: %s" % ("Victory" if victory else "Game Over"))

func return_to_menu() -> bool:
	"""Return to main menu"""
	return change_state(GameState.MENU, "Return to menu")

func open_settings() -> bool:
	"""Open settings menu"""
	return change_state(GameState.SETTINGS, "Open settings")

func close_settings() -> bool:
	"""Close settings menu"""
	if current_state == GameState.SETTINGS:
		# Return to previous state (usually MENU or PAUSED)
		var target_state = GameState.MENU
		if previous_state in [GameState.PAUSED]:
			target_state = previous_state
		return change_state(target_state, "Close settings")
	return false

func go_back() -> bool:
	"""Navigate back using state history"""
	if state_history.size() > 0:
		var _previous_state = state_history.pop_back()
		return change_state(_previous_state, "Navigate back")
	return false

# State validation and query methods
func is_state(state: GameState) -> bool:
	"""Check if currently in specified state"""
	return current_state == state

func is_playing() -> bool:
	"""Check if game is in playing state"""
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	"""Check if game is paused"""
	return current_state == GameState.PAUSED

func can_interact() -> bool:
	"""Check if player can interact with game elements"""
	return current_state in [GameState.PLAYING]

func can_show_ui() -> bool:
	"""Check if UI should be shown"""
	return current_state != GameState.PLAYING or current_state == GameState.PAUSED

# State data persistence
func save_state_data(key: String, data: Variant):
	"""Save data associated with current state"""
	if not state_data.has(current_state):
		state_data[current_state] = {}
	state_data[current_state][key] = data

func load_state_data(key: String, default: Variant = null) -> Variant:
	"""Load data associated with current state"""
	if state_data.has(current_state) and state_data[current_state].has(key):
		return state_data[current_state][key]
	return default

func clear_state_data():
	"""Clear all state data"""
	state_data.clear()

# Pause/resume functionality
func toggle_pause() -> bool:
	"""Toggle pause state"""
	if current_state == GameState.PLAYING:
		return pause_game()
	elif current_state == GameState.PAUSED:
		return resume_game()
	return false

# Game state persistence
func _save_game_state():
	"""Save current game state for persistence"""
	if current_state == GameState.PLAYING:
		paused_game_data = {
			"timestamp": Time.get_unix_time_from_system(),
			"state": current_state,
			"game_time": load_state_data("game_time", 0.0),
			"difficulty": load_state_data("difficulty", 1),
			"score": load_state_data("score", 0)
		}

func load_game_state() -> bool:
	"""Load saved game state"""
	if paused_game_data.is_empty():
		return false
	
	var success = change_state(paused_game_data.state, "Load saved game state")
	if success:
		# Restore state data
		for key in paused_game_data.keys():
			if key != "state" and key != "timestamp":
				save_state_data(key, paused_game_data[key])
	
	return success

# Utility methods
func get_state_duration() -> float:
	"""Get duration in current state in seconds"""
	if state_entry_times.has(current_state):
		return Time.get_unix_time_from_system() - state_entry_times[current_state]
	return 0.0

func get_state_history() -> Array[GameState]:
	"""Get state transition history"""
	return state_history.duplicate()

func get_previous_state() -> GameState:
	"""Get the previous state"""
	return previous_state

func get_state_name(state: GameState) -> String:
	"""Convert state enum to string"""
	match state:
		GameState.MENU: return "MENU"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.GAME_OVER: return "GAME_OVER"
		GameState.VICTORY: return "VICTORY"
		GameState.SETTINGS: return "SETTINGS"
		_: return "UNKNOWN"

# Debugging and logging
func enable_debug_logging(enabled: bool = true):
	"""Enable or disable debug logging"""
	debug_logging_enabled = enabled

func get_state_debug_info() -> Dictionary:
	"""Get comprehensive debug information about current state"""
	return {
		"current_state": get_state_name(current_state),
		"previous_state": get_state_name(previous_state),
		"state_duration": get_state_duration(),
		"state_history": state_history.map(func(state): return get_state_name(state)),
		"valid_transitions": valid_transitions.get(current_state, []).map(func(state): return get_state_name(state)),
		"can_interact": can_interact(),
		"can_show_ui": can_show_ui(),
		"auto_pause_enabled": false,
		"state_data": state_data,
		"paused_game_data": paused_game_data,
		"state_entry_times": state_entry_times,
		"debug_logging_enabled": debug_logging_enabled,
		"state_persistence_enabled": state_persistence_enabled
	}

func print_debug_info():
	"""Print debug information to console"""
	var info = get_state_debug_info()
	print("=== Game State Manager Debug Info ===")
	for key in info.keys():
		print("%s: %s" % [key, str(info[key])])
	print("=====================================")

func _log_state_change(from_state: GameState, to_state: GameState, reason: String):
	"""Log state changes if debug logging is enabled"""
	if debug_logging_enabled:
		var message = "State change: %s -> %s" % [get_state_name(from_state), get_state_name(to_state)]
		if reason != "":
			message += " (%s)" % reason
		
		# Add timestamp and additional context
		var timestamp = Time.get_unix_time_from_system()
		var _state_context = {
			"from_state": from_state,
			"to_state": to_state,
			"reason": reason,
			"timestamp": timestamp
		}
		
		var full_message = "[%s] %s" % [timestamp, message]
		print(full_message)
		
		# Log to persistent log if available
		if has_method("_log_to_persistent_log"):
			_log_to_persistent_log(full_message)

func _log_error(message: String, stack_trace: String = "", context: Dictionary = {}):
	"""Log error messages with detailed context for debugging"""
	var error_message = "ERROR: GameStateManager - %s" % message
	if stack_trace != "":
		error_message += "\nStack Trace: %s" % stack_trace
	if not context.is_empty():
		error_message += "\nContext: %s" % str(context)
	
	# Add timestamp for better debugging
	var timestamp = Time.get_unix_time_from_system()
	error_message = "[%s] %s" % [timestamp, error_message]
	
	print(error_message)
	
	# Also log to a persistent error log if available
	if has_method("_log_to_persistent_log"):
		_log_to_persistent_log(error_message)

func _log_debug_info(info_type: String, data: Variant):
	"""Log detailed debug information for complex scenarios"""
	if debug_logging_enabled:
		var timestamp = Time.get_unix_time_from_system()
		var log_message = "[DEBUG] [%s] %s: %s" % [timestamp, info_type, str(data)]
		print(log_message)
		
		# Log to persistent debug log if available
		if has_method("_log_to_persistent_log"):
			_log_to_persistent_log(log_message)

func _play_state_transition_sound(sound_type: String):
	"""Play audio feedback for state transitions"""
	# Use injected audio manager reference first
	if _audio_manager and _audio_manager.has_method("play_state_transition_sound"):
		_audio_manager.play_state_transition_sound(sound_type)
	else:
		# Fallback to scene tree search if not injected
		var audio_manager = get_tree().current_scene.find_child("AudioManager", true, false)
		if audio_manager and audio_manager.has_method("play_state_transition_sound"):
			audio_manager.play_state_transition_sound(sound_type)
		else:
			# Fallback to basic click sound if available
			var audio_players = get_tree().current_scene.find_children("*", "AudioStreamPlayer", true, false)
			for player in audio_players:
				if player.name == "Click" or player.name == "UI":
					player.play()
					break

func _exit_tree():
	"""Clean up resources and signals when the node is removed from the scene tree"""
	# Clear references to prevent memory leaks
	_audio_manager = null
	state_data.clear()
	paused_game_data.clear()
	state_history.clear()
	state_entry_times.clear()
	valid_transitions.clear()
	
	_log_debug_info("Cleanup", {"message": "GameStateManager resources cleaned up"})

func _log_to_persistent_log(_message: String):
	"""Log message to persistent storage if available"""
	# Placeholder for persistent logging implementation
	# Could be implemented to write to a file or database
	pass

## Sets the AudioManager reference for dependency injection.
## Call this from main.gd after AudioManager is ready to remove scene tree coupling.
## 
## Args:
## 	audio_manager: Reference to the AudioManager node
func set_audio_manager_ref(audio_manager: Node):
	_audio_manager = audio_manager

# Public API for external integration
func force_state_change(new_state: GameState, reason: String = "") -> bool:
	"""
	Force state change with proper enter/exit handler calls.
	This maintains state machine integrity even during forced transitions.
	
	Args:
		new_state: The target state to transition to
		reason: Optional reason for the state change (for debugging)
	
	Returns:
		bool: True if state change was successful
	"""
	var old_state = current_state
	
	# Exit current state properly
	emit_signal("state_exited", current_state)
	_handle_state_exit(current_state)
	
	# Update state
	current_state = new_state
	state_entry_times[current_state] = Time.get_unix_time_from_system()
	
	# Log and emit signals
	_log_state_change(old_state, new_state, "FORCED: " + reason)
	emit_signal("state_changed", old_state, new_state)
	emit_signal("state_entered", new_state)
	
	# Enter new state properly
	_handle_state_enter(new_state)
	
	return true
