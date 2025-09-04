class_name Tile
extends RefCounted

var label = null
var has_mine = false
var neighbor_mines = 0
var is_revealed = false
var is_flagged = false
var neighbors = {}
var position = Vector3()
var index = 0
var node = null

func _init(_index, _position):
	index = _index
	position = _position
