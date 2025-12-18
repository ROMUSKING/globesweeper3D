class_name InteractionManager
extends Node3D

signal tile_hovered(index: int)
signal tile_clicked(index: int, button_index: int)
signal drag_started
signal drag_ended
signal drag_active(relative: Vector2)
signal zoom_changed(amount: float)

# Configuration
const DRAG_THRESHOLD: float = 4.0

# State
var _pressed_tile_index: int = -1
var _is_dragging: bool = false
var _mouse_down_pos: Vector2 = Vector2.ZERO
var _current_hovered_index: int = -1

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(_delta):
	_update_hover()

func _update_hover():
	var mouse_pos = get_viewport().get_mouse_position()
	var result = _perform_raycast(mouse_pos)
	
	var hit_index = -1
	var hit_collider = null
	
	if result and result.collider:
		if result.collider.has_meta("tile_index"):
			hit_index = result.collider.get_meta("tile_index")
			hit_collider = result.collider
	
	if hit_index != _current_hovered_index:
		_current_hovered_index = hit_index
		tile_hovered.emit(hit_index)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

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

func _perform_raycast(screen_pos: Vector2) -> Dictionary:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return {}
		
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000.0
	
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