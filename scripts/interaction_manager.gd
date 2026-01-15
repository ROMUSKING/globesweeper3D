class_name InteractionManager
extends Node3D

## Handles all user input and interaction with the 3D globe in GlobeSweeper 3D.
## Processes mouse/touch input for tile selection, camera rotation, and powerup activation.

signal tile_hovered(index: int)
signal tile_clicked(index: int, button_index: int)
signal drag_started
signal drag_ended
signal drag_active(relative: Vector2)
signal zoom_changed(amount: float)

# Powerup activation signals
signal powerup_activation_requested(powerup_type: String)
signal powerup_hover_requested(index: int)

# Configuration
const DRAG_THRESHOLD: float = 4.0

# State
var _pressed_tile_index: int = -1
var _is_dragging: bool = false
var _mouse_down_pos: Vector2 = Vector2.ZERO
var _current_hovered_index: int = -1

# Game State Manager reference
var game_state_manager: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_update_processing_mode(true) # Start with input processing enabled by default

func set_input_processing(enable: bool):
	_update_processing_mode(enable)

func set_game_state_manager_reference(manager: Node):
	"""Sets the Game State Manager reference for state-aware input handling."""
	game_state_manager = manager

func _update_processing_mode(enable: bool):
	# Control whether this node processes input
	if enable:
		process_mode = Node.PROCESS_MODE_PAUSABLE
	else:
		process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(_delta):
	_update_hover()

func _update_hover():
	var mouse_pos = get_viewport().get_mouse_position()
	var result = _perform_raycast(mouse_pos)
	
	var hit_index = -1
	var _hit_collider = null
	
	if result and result.collider:
		if result.collider.has_meta("tile_index"):
			hit_index = result.collider.get_meta("tile_index")
			_hit_collider = result.collider
		# Emit powerup hover signal for relevant powerups
		if hit_index != -1:
			powerup_hover_requested.emit(hit_index)

func _input(event: InputEvent) -> void:
	# Check if we can process input based on game state
	if game_state_manager and not game_state_manager.can_interact():
		_log_input_rejection("Game state prevents interaction", {"current_state": game_state_manager.current_state})
		return
	
	# Handle powerup activation keys
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_powerup_key_input(event)
	
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

func _log_input_rejection(reason: String, context: Dictionary = {}):
	"""Log detailed information about rejected input events"""
	var _log_data = {
		"reason": reason,
		"context": context,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Enhanced logging with stack trace and additional context
	var error_message = "[INPUT REJECTED] %s" % reason
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
	trace = "InteractionManager stack trace"
	return trace

func _log_to_persistent_log(_message: String):
	"""Log message to persistent storage if available"""
	# Placeholder for persistent logging implementation
	# Could be implemented to write to a file or database
	pass

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_changed.emit(-1.0)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_changed.emit(1.0)
			return
		
		var tile_index = _get_tile_index_at(event.position)
		
		# Mouse Down - Only start drag tracking on Left Click
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressed_tile_index = tile_index
			_mouse_down_pos = event.position
			_is_dragging = false
		
		# Right click is instant/independent
		if event.button_index == MOUSE_BUTTON_RIGHT and tile_index != -1:
			tile_clicked.emit(tile_index, MOUSE_BUTTON_RIGHT)
			
	else:
		# Mouse Up - Only handle Left Click release for drag/click logic
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _is_dragging:
				var tile_index = _get_tile_index_at(event.position)
				# If we released on the same tile we pressed, it's a click
				if tile_index != -1 and tile_index == _pressed_tile_index:
					tile_clicked.emit(tile_index, MOUSE_BUTTON_LEFT)
			
			if _is_dragging:
				_is_dragging = false
				drag_ended.emit()
			
			_pressed_tile_index = -1
			_mouse_down_pos = Vector2.ZERO

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	# Hover is now handled in _physics_process
	# Drag logic
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not _is_dragging:
			if (event.position - _mouse_down_pos).length() > DRAG_THRESHOLD:
				_is_dragging = true
				drag_started.emit()
		
		if _is_dragging:
			drag_active.emit(event.relative)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var tile_index = _get_tile_index_at(event.position)
		_pressed_tile_index = tile_index
	else:
		if not _is_dragging and _pressed_tile_index != -1:
			var tile_index = _get_tile_index_at(event.position)
			if tile_index == _pressed_tile_index:
				tile_clicked.emit(tile_index, MOUSE_BUTTON_LEFT)
		
		if _is_dragging:
			_is_dragging = false
			drag_ended.emit()
		_pressed_tile_index = -1

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if not _is_dragging:
		_is_dragging = true
		drag_started.emit()
	
	drag_active.emit(event.relative)

func _handle_powerup_key_input(event: InputEventKey):
	# Map number keys to powerup activations
	match event.keycode:
		KEY_1:
			powerup_activation_requested.emit("reveal_protection")
		KEY_2:
			powerup_activation_requested.emit("reveal_mine")
		KEY_3:
			powerup_activation_requested.emit("reveal_safe_tile")
		KEY_4:
			powerup_activation_requested.emit("hint_system")
		KEY_5:
			powerup_activation_requested.emit("time_freeze")
		KEY_H:
			# Alternative hint activation with H key
			if _current_hovered_index != -1:
				powerup_hover_requested.emit(_current_hovered_index)

func _perform_raycast(screen_pos: Vector2) -> Dictionary:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return {}

	var from = camera.project_ray_origin(screen_pos)
	var globe_radius = get_parent().globe_radius
	var to = from + camera.project_ray_normal(screen_pos) * (globe_radius * 2.0)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# Ensure we collide with the tile layer (layer 1 was set in generator)
	query.collision_mask = 1

	return space_state.intersect_ray(query)

func _get_tile_index_at(screen_pos: Vector2) -> int:
	var result = _perform_raycast(screen_pos)
	if result and result.collider and result.collider.has_meta("tile_index"):
		return result.collider.get_meta("tile_index")
	return -1

# Powerup activation methods
func request_powerup_activation(powerup_type: String, target_index: int = -1):
	"""Public method to request powerup activation (can be called from UI).
	
	Args:
		powerup_type: The type of powerup to activate
		target_index: Optional tile index to target with the powerup
	"""
	if target_index != -1:
		# Set temporary hover for targeted powerups
		_current_hovered_index = target_index
		powerup_hover_requested.emit(target_index)
	
	powerup_activation_requested.emit(powerup_type)

func get_current_hovered_tile() -> int:
	"""Returns the currently hovered tile index."""
	return _current_hovered_index

func is_input_processing_enabled() -> bool:
	"""Returns whether input processing is currently enabled."""
	return process_mode == Node.PROCESS_MODE_PAUSABLE

func set_powerup_mode(enabled: bool):
	"""Enables or disables powerup interaction mode.
	
	Args:
		enabled: True to enable powerup mode, false to disable
	"""
	if enabled:
		# In powerup mode, we might want different behavior
		# For now, just log the mode change
		print("Powerup mode enabled")
	else:
		print("Powerup mode disabled")

# Utility methods for powerup integration
func get_tile_at_position(screen_pos: Vector2) -> int:
	"""Alternative method name for getting tile at screen position."""
	return _get_tile_index_at(screen_pos)

func get_hovered_tile_safe() -> int:
	"""Safely get hovered tile index with bounds checking."""
	if _current_hovered_index >= 0:
		return _current_hovered_index
	return -1
