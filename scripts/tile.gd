class_name Tile
extends RefCounted

var index: int
var position: Vector3 # Normalized position
var world_position: Vector3
var has_mine: bool = false
var neighbor_mines: int = 0
var is_revealed: bool = false
var is_flagged: bool = false
var neighbors: Array = [] # Array of indices
var node: Node3D
var mesh: MeshInstance3D

# Powerup-related properties
var is_powerup_revealed: bool = false # For reveal_mine powerup
var is_hint_highlighted: bool = false # For hint_system powerup
var protection_active: bool = false # For reveal_protection powerup

func _init(_index: int = 0, _position: Vector3 = Vector3.ZERO, _world_position: Vector3 = Vector3.ZERO):
	index = _index
	position = _position
	world_position = _world_position

# Powerup utility methods
func is_safe() -> bool:
	"""Returns true if this tile is safe (no mine)"""
	return not has_mine

func is_revealable() -> bool:
	"""Returns true if this tile can be revealed (not flagged and not already revealed)"""
	return not is_flagged and not is_revealed

func is_hint_candidate() -> bool:
	"""Returns true if this tile could be shown as a hint (safe and unrevealed)"""
	return is_safe() and is_revealable()

func get_safety_level() -> int:
	"""Returns safety level: 0 = mine, 1 = safe with neighbors, 2 = safe empty"""
	if has_mine:
		return 0
	elif neighbor_mines > 0:
		return 1
	else:
		return 2

func can_be_powerup_target() -> bool:
	"""Returns true if this tile can be targeted by powerups"""
	return not is_revealed and not is_flagged

func mark_as_powerup_revealed():
	"""Marks this tile as revealed by a powerup"""
	is_powerup_revealed = true

func mark_as_hint_highlighted():
	"""Marks this tile as highlighted by hint system"""
	is_hint_highlighted = true

func clear_hint_highlight():
	"""Removes hint highlighting from this tile"""
	is_hint_highlighted = false

func activate_protection():
	"""Activates protection on this tile"""
	protection_active = true

func consume_protection() -> bool:
	"""Consumes protection if active, returns true if protection was consumed"""
	if protection_active:
		protection_active = false
		return true
	return false

func get_distance_to_tile(other_tile) -> float:
	"""Calculates distance to another tile in 3D space"""
	return position.distance_to(other_tile.position)

func is_in_radius_of_tile(other_tile, radius: float) -> bool:
	"""Returns true if this tile is within radius of another tile"""
	return get_distance_to_tile(other_tile) <= radius

func get_safe_neighbor_count() -> int:
	"""Returns count of safe neighbors (useful for hint system)"""
	var safe_count = 0
	for neighbor_idx in neighbors:
		# This would need to be populated by the game manager
		# Placeholder implementation
		safe_count += 1
	return safe_count

func get_information_value() -> float:
	"""Returns a value representing how much information this tile provides"""
	if has_mine:
		return 1.0 # High value for mine information
	elif neighbor_mines > 0:
		return 0.8 # Good information about surrounding mines
	else:
		return 0.6 # Basic information, clears area

func should_prioritize_for_powerup() -> bool:
	"""Returns true if this tile should be prioritized for powerup targeting"""
	# Prioritize tiles that provide the most information
	return get_information_value() > 0.7

func clone() -> Tile:
	"""Creates a copy of this tile (useful for powerup calculations)"""
	var new_tile = Tile.new(index, position, world_position)
	new_tile.has_mine = has_mine
	new_tile.neighbor_mines = neighbor_mines
	new_tile.is_revealed = is_revealed
	new_tile.is_flagged = is_flagged
	new_tile.neighbors = neighbors.duplicate()
	# Note: node and mesh are not copied as they are scene-specific
	return new_tile
