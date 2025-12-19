class_name PowerupManager
extends Node

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
	if not POWERUP_DEFINITIONS.has(powerup_type):
		return false
		
	var cost = get_adjusted_powerup_cost(powerup_type)
	return available_score >= cost

func purchase_powerup(powerup_type: String, available_score: int) -> Dictionary:
	"""
	Attempts to purchase a powerup
	Returns: {
		"success": bool,
		"message": String,
		"remaining_score": int,
		"new_inventory": Dictionary
	}
	"""
	
	if not can_purchase_powerup(powerup_type, available_score):
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
			"needed": remaining_score < cost * 0.5 # Consider "needed" if barely had enough score
		})
	
	return {
		"success": true,
		"message": "Powerup purchased successfully",
		"remaining_score": remaining_score,
		"new_inventory": powerup_inventory.duplicate(true)
	}

func can_activate_powerup(powerup_type: String) -> bool:
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
	Activates a powerup if available
	Returns: {
		"success": bool,
		"message": String,
		"effect_data": Dictionary
	}
	"""
	
	if not can_activate_powerup(powerup_type):
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
	Executes the specific effect of a powerup
	Returns effect-specific data
	"""
	match powerup_type:
		"reveal_protection":
			return activate_reveal_protection()
		"reveal_mine":
			return activate_reveal_mine()
		"reveal_safe_tile":
			return activate_reveal_safe_tile()
		"hint_system":
			return activate_hint_system()
		"time_freeze":
			return activate_time_freeze()
		_:
			return {"error": "Unknown powerup type"}

func activate_reveal_protection() -> Dictionary:
	# Add protection state to main script
	if main_script and main_script.has_method("add_reveal_protection"):
		main_script.add_reveal_protection()
	
	# Track powerup use for difficulty scaling
	if difficulty_scaling_manager:
		difficulty_scaling_manager.record_player_action("powerup_use", true, {
			"type": "reveal_protection",
			"action": "activate",
			"needed": true # Protection is always "needed" when used
		})
	
	return {"protection_count": 1}

func activate_reveal_mine() -> Dictionary:
	# Automatically reveal a mine location
	if main_script and main_script.has_method("reveal_random_mine"):
		var mine_data = main_script.reveal_random_mine()
		return mine_data
	return {"revealed": false}

func activate_reveal_safe_tile() -> Dictionary:
	# Automatically reveal a safe tile
	if main_script and main_script.has_method("reveal_random_safe_tile"):
		var tile_data = main_script.reveal_random_safe_tile()
		return tile_data
	return {"revealed": false}

func activate_hint_system() -> Dictionary:
	# Show safe tiles around a specific area
	if main_script and main_script.has_method("show_hints"):
		var hint_data = main_script.show_hints()
		return hint_data
	return {"hints_shown": 0}

func activate_time_freeze() -> Dictionary:
	# Pause timer for 30 seconds
	if main_script and main_script.has_method("freeze_timer"):
		main_script.freeze_timer(30.0)
		return {"freeze_duration": 30.0}
	return {"freeze_duration": 0.0}

func update_cooldowns(delta: float):
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