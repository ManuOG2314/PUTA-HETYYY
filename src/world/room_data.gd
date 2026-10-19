class_name RoomData
const GameConstants = preload("res://src/core/game_constants.gd")

var grid_position: Vector2i
var room_type: int
var exits: Array = []
var layout_id: int = 0
var visited := false
var enemy_count: int = 0
var cleared := false
