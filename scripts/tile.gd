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

func _init(_index: int = 0, _position: Vector3 = Vector3.ZERO, _world_position: Vector3 = Vector3.ZERO):
	index = _index
	position = _position
	world_position = _world_position
