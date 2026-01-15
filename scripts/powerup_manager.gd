class_name PowerupManager
extends Node

## Manages powerup inventory, purchasing, activation, and cooldowns for GlobeSweeper 3D.
## Provides consistent game result handling through the GameResult class.

signal powerup_purchased(powerup_type: String, cost: int)
signal powerup_activated(powerup_type: String)
signal powerup_deactivated(powerup_type: String)
signal score_deducted(amount: int, reason: String)

# Powerup definitions with costs and descriptions
const POWERUP_DEFINITIONS = {
	"reveal_protection": {
		"name": "Reveal Protection",
		"cost": 50,
		"description": "Prevents mine explosion for one wrong click",
		"cooldown": 0,
		"duration": 0
	},
	"reveal_mine": {
		"name": "Reveal Mine",
		"cost": 75,
		"description": "Automatically reveals one mine location",
		"cooldown": 0,
		"duration": 0
	},
	"reveal_safe_tile": {
		"name": "Reveal Safe Tile",
		"cost": 25,
		"description": "Automatically reveals a safe tile",
		"cooldown": 0,
		"duration": 0
	},
	"hint_system": {
		"name": "Hint System",
		"cost": 30,
		"description": "Shows safe tiles around a specific area",
		"cooldown": 0,
		"duration": 0
	},
	"time_freeze": {
		"name": "Time Freeze",
		"cost": 100,
		"description": "Pauses timer for 30 seconds",
		"cooldown": 0,
		"duration": 30.0
	}
}

# Powerup inventory (owned vs available counts)
var powerup_inventory: Dictionary = {}
var powerup_cooldowns: Dictionary = {}
var active_powerups: Dictionary = {}

# Reference to main game script
var main_script: Node = null

# Reference to difficulty scaling manager
var difficulty_scaling_manager: Node = null

func _ready():
	initialize_inventory()
	initialize_cooldowns()

func initialize_inventory():
	# Initialize all powerups to 0 owned
	for powerup_type in POWERUP_DEFINITIONS.keys():
		powerup_inventory[powerup_type] = {
			"owned": 0,
			"available": 0
		}

func initialize_cooldowns():
	# Initialize cooldowns for all powerups
	for powerup_type in POWERUP_DEFINITIONS.keys():
		powerup_cooldowns[powerup_type] = 0.0

func can_purchase_powerup(powerup_type: String, available_score: int) -> bool:
	"""Checks if a powerup can be purchased with the given score.
	
	Args:
		powerup_type: The type of powerup to check
		available_score: The player's current score points
	
	Returns: True if the powerup can be purchased
	"""
	if not POWERUP_DEFINITIONS.has(powerup_type):
		return false
	
	var cost = get_adjusted_powerup_cost(powerup_type)
	return available_score >= cost

func purchase_powerup(powerup_type: String, available_score: int) -> Dictionary:
	"""
	Attempts to purchase a powerup.
	
	Args:
		powerup_type: The type of powerup to purchase
		available_score: The player's current score points
	
	Returns:
		Dictionary: Result containing success status, message, and updated inventory
	"""
	if not can_purchase_powerup(powerup_type, available_score):
		var error_context = {
			"powerup_type": powerup_type,
			"available_score": available_score,
			"required_score": get_adjusted_powerup_cost(powerup_type)
		}
		_log_powerup_error("Purchase failed - insufficient score", error_context)
		return {
			"success": false,
			"message": "Insufficient score points",
			"remaining_score": available_score,
			"new_inventory": powerup_inventory.duplicate(true)
		}
	
	var cost = get_adjusted_powerup_cost(powerup_type)
	var remaining_score = available_score - cost
	
	# Update inventory
	powerup_inventory[powerup_type]["owned"] += 1
	powerup_inventory[powerup_type]["available"] += 1
	
	# Emit signals
	powerup_purchased.emit(powerup_type, cost)
	score_deducted.emit(cost, "Powerup Purchase: " + POWERUP_DEFINITIONS[powerup_type]["name"])
	
	# Track powerup purchase for difficulty scaling
	if difficulty_scaling_manager:
		difficulty_scaling_manager.record_player_action("powerup_use", true, {
			"type": powerup_type,
			"action": "purchase",
			"cost": cost,
			"needed": remaining_score < cost * 0.5
		})
	
	return {
		"success": true,
		"message": "Powerup purchased successfully",
		"remaining_score": remaining_score,
		"new_inventory": powerup_inventory.duplicate(true)
	}

func can_activate_powerup(powerup_type: String) -> bool:
	"""Checks if a powerup can be activated.
	
	Checks inventory availability, cooldowns, and active duration.
	
	Args:
		powerup_type: The type of powerup to check
	
	Returns: True if the powerup can be activated
	"""
	if not POWERUP_DEFINITIONS.has(powerup_type):
		return false
	
	if not powerup_inventory[powerup_type].has("available"):
		return false
	
	if powerup_inventory[powerup_type]["available"] <= 0:
		return false
	
	# Check cooldown
	if powerup_cooldowns[powerup_type] > 0.0:
		return false
	
	# Check if already active (for duration-based powerups)
	if active_powerups.has(powerup_type) and active_powerups[powerup_type] > 0.0:
		return false
	
	return true

func activate_powerup(powerup_type: String) -> Dictionary:
	"""
	Activates a powerup if available.
	
	Args:
		powerup_type: The type of powerup to activate
	
	Returns:
		Dictionary: Result containing success status, message, and effect data
	"""
	if not can_activate_powerup(powerup_type):
		var error_context = {
			"powerup_type": powerup_type,
			"inventory": powerup_inventory.get(powerup_type, {}),
			"cooldown": powerup_cooldowns.get(powerup_type, 0.0),
			"active": active_powerups.get(powerup_type, 0.0)
		}
		_log_powerup_error("Activation failed - cannot activate powerup", error_context)
		return {
			"success": false,
			"message": "Powerup cannot be activated",
			"effect_data": {}
		}
	
	# Consume one available powerup
	powerup_inventory[powerup_type]["available"] -= 1
	
	var duration = POWERUP_DEFINITIONS[powerup_type]["duration"]
	
	# Handle duration-based powerups
	if duration > 0.0:
		active_powerups[powerup_type] = duration
	else:
		active_powerups[powerup_type] = 0.0
	
	# Set cooldown
	powerup_cooldowns[powerup_type] = POWERUP_DEFINITIONS[powerup_type]["cooldown"]
	
	# Emit activation signal
	powerup_activated.emit(powerup_type)
	
	# Track powerup activation for difficulty scaling
	if difficulty_scaling_manager:
		difficulty_scaling_manager.record_player_action("powerup_use", true, {
			"type": powerup_type,
			"action": "activate"
		})
	
	# Execute powerup effect
	var effect_data = execute_powerup_effect(powerup_type)
	
	return {
		"success": true,
		"message": "Powerup activated successfully",
		"effect_data": effect_data
	}

func execute_powerup_effect(powerup_type: String) -> Dictionary:
	"""
	Executes the specific effect of a powerup.
	Consolidated dispatcher using method calling and helper for reduced boilerplate.
	
	Args:
		powerup_type: Type of powerup to execute
	
	Returns: Dictionary with effect-specific data
	"""
	var handler_name = "_effect_" + powerup_type
	if has_method(handler_name):
		return call(handler_name)
	
	var error_context = {
		"powerup_type": powerup_type,
		"available_handlers": _get_available_effect_handlers()
	}
	_log_powerup_error("Unknown powerup type", error_context)
	return {"error": "Unknown powerup type: " + powerup_type}

func _get_available_effect_handlers() -> Array:
	"""Get list of available effect handler methods"""
	var handlers = []
	for powerup_type in POWERUP_DEFINITIONS.keys():
		var handler_name = "_effect_" + powerup_type
		if has_method(handler_name):
			handlers.append(handler_name)
	return handlers

# Helper to reduce boilerplate for main script method calls
func _call_main_method(method_name: String, args: Array = []) -> Dictionary:
	"""Helper to call main script methods safely"""
	if not main_script or not main_script.has_method(method_name):
		return {"success": false, "error": "Method not available"}
	
	if args.is_empty():
		return main_script.call(method_name)
	else:
		return main_script.call(method_name, args)

# Powerup effect handlers - private with _effect prefix
func _effect_reveal_protection() -> Dictionary:
	if main_script and main_script.has_method("add_reveal_protection"):
		main_script.add_reveal_protection()
	
	if difficulty_scaling_manager:
		difficulty_scaling_manager.record_player_action("powerup_use", true, {
			"type": "reveal_protection",
			"action": "activate",
			"needed": true
		})
	
	return {"protection_count": 1}

func _effect_reveal_mine() -> Dictionary:
	return _call_main_method("reveal_random_mine")

func _effect_reveal_safe_tile() -> Dictionary:
	return _call_main_method("reveal_random_safe_tile")

func _effect_hint_system() -> Dictionary:
	return _call_main_method("show_hints")

func _effect_time_freeze() -> Dictionary:
	if main_script and main_script.has_method("freeze_timer"):
		main_script.freeze_timer(30.0)
		return {"freeze_duration": 30.0}
	return {"freeze_duration": 0.0}

# Legacy compatibility - can remove after testing
func activate_reveal_protection() -> Dictionary:
	return _effect_reveal_protection()

func activate_reveal_mine() -> Dictionary:
	return _effect_reveal_mine()

func activate_reveal_safe_tile() -> Dictionary:
	return _effect_reveal_safe_tile()

func activate_hint_system() -> Dictionary:
	return _effect_hint_system()

func activate_time_freeze() -> Dictionary:
	return _effect_time_freeze()

func update_cooldowns(delta: float):
	"""Updates all powerup cooldowns and active powerup durations.
	
	Args:
		delta: Time elapsed since last update in seconds
	"""
	# Update all powerup cooldowns
	for powerup_type in powerup_cooldowns.keys():
		if powerup_cooldowns[powerup_type] > 0.0:
			powerup_cooldowns[powerup_type] = max(0.0, powerup_cooldowns[powerup_type] - delta)
	
	# Update active powerup durations
	var powerups_to_remove: Array[String] = []
	for powerup_type in active_powerups.keys():
		if active_powerups[powerup_type] > 0.0:
			active_powerups[powerup_type] = max(0.0, active_powerups[powerup_type] - delta)
			if active_powerups[powerup_type] <= 0.0:
				powerups_to_remove.append(powerup_type)
				powerup_deactivated.emit(powerup_type)
	
	# Remove expired powerups
	for powerup_type in powerups_to_remove:
		active_powerups.erase(powerup_type)

func get_powerup_status(powerup_type: String) -> Dictionary:
	"""
	Returns comprehensive status for a powerup
	"""
	if not POWERUP_DEFINITIONS.has(powerup_type):
		return {}
		
	var definition = POWERUP_DEFINITIONS[powerup_type]
	var inventory = powerup_inventory.get(powerup_type, {"owned": 0, "available": 0})
	var cooldown = powerup_cooldowns.get(powerup_type, 0.0)
	var active_duration = active_powerups.get(powerup_type, 0.0)
	
	return {
		"name": definition["name"],
		"cost": get_adjusted_powerup_cost(powerup_type),
		"base_cost": definition["cost"],
		"description": definition["description"],
		"owned": inventory["owned"],
		"available": inventory["available"],
		"cooldown": cooldown,
		"active_duration": active_duration,
		"can_purchase": can_purchase_powerup(powerup_type, get_available_score()),
		"can_activate": can_activate_powerup(powerup_type)
	}

func get_all_powerup_status() -> Dictionary:
	"""
	Returns status for all powerups
	"""
	var all_status = {}
	for powerup_type in POWERUP_DEFINITIONS.keys():
		all_status[powerup_type] = get_powerup_status(powerup_type)
	return all_status

func get_available_score() -> int:
	"""
	Gets the current available score from main script
	"""
	if main_script and main_script.has_method("get_current_score"):
		return main_script.get_current_score()
	return 0

func reset_inventory():
	"""
	Resets powerup inventory (called on new game)
	"""
	initialize_inventory()
	initialize_cooldowns()
	active_powerups.clear()

func get_powerup_inventory() -> Dictionary:
	"""
	Returns current inventory state
	"""
	return powerup_inventory.duplicate(true)

func set_main_script_reference(script: Node):
	"""
	Sets reference to main game script for powerup effects
	"""
	main_script = script

func set_difficulty_scaling_manager_reference(manager: Node):
	"""
	Sets reference to difficulty scaling manager
	"""
	difficulty_scaling_manager = manager

func get_adjusted_powerup_cost(powerup_type: String) -> int:
	"""
	Get powerup cost adjusted for difficulty scaling
	"""
	if not POWERUP_DEFINITIONS.has(powerup_type):
		return 0
	
	var base_cost = POWERUP_DEFINITIONS[powerup_type]["cost"]
	
	# Get difficulty-based cost multiplier
	var cost_multiplier = 1.0
	if difficulty_scaling_manager and difficulty_scaling_manager.has_method("get_powerup_cost_multiplier"):
		cost_multiplier = difficulty_scaling_manager.get_powerup_cost_multiplier()
	
	return int(base_cost * cost_multiplier)

# Utility functions for powerup integration
func is_protection_active() -> bool:
	return active_powerups.has("reveal_protection") and active_powerups["reveal_protection"] > 0.0

func is_time_frozen() -> bool:
	return active_powerups.has("time_freeze") and active_powerups["time_freeze"] > 0.0

func get_time_freeze_remaining() -> float:
	if is_time_frozen():
		return active_powerups["time_freeze"]
	return 0.0

# Enhanced error logging methods
func _log_powerup_error(message: String, context: Dictionary = {}):
	"""Log powerup-related errors with detailed context"""
	var error_message = "[POWERUP ERROR] %s" % message
	
	if not context.is_empty():
		error_message += "\nContext: %s" % str(context)
	
	# Add stack trace if available
	var stack_trace = ""
	if has_method("_get_stack_trace"):
		stack_trace = _get_stack_trace()
	
	if stack_trace != "":
		error_message += "\nStack Trace: %s" % stack_trace
	
	print(error_message)
	
	# Log to persistent log if available
	if has_method("_log_to_persistent_log"):
		_log_to_persistent_log(error_message)

func _get_stack_trace() -> String:
	"""Get current stack trace for error logging"""
	var trace = ""
	# This is a simplified stack trace - in a real implementation you'd want more details
	trace = "PowerupManager stack trace"
	return trace

func _log_to_persistent_log(_message: String):
	"""Log message to persistent storage if available"""
	# Placeholder for persistent logging implementation
	# Could be implemented to write to a file or database
	pass
