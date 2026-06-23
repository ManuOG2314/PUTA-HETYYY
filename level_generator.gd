extends Node2D

const GameConstants = preload("res://game_constants.gd")
const RoomData = preload("res://room_data.gd")

const DIR_UP = Vector2i(0, -1)
const DIR_DOWN = Vector2i(0, 1)
const DIR_LEFT = Vector2i(-1, 0)
const DIR_RIGHT = Vector2i(1, 0)
const DIRECTIONS = [DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT]

@export var room_scene: PackedScene
@export var num_rooms: int = 8

var grid: Dictionary = {}
var spawned_rooms: Dictionary = {}

func generate_level() -> Dictionary:
	for room in spawned_rooms.values():
		if is_instance_valid(room):
			room.queue_free()
	spawned_rooms.clear()
	grid.clear()
	
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	
	var start_room = RoomData.new()
	start_room.grid_position = Vector2i.ZERO
	start_room.room_type = GameConstants.RoomType.START
	grid[Vector2i.ZERO] = start_room
	
	var current_count = 1
	
	while current_count < num_rooms and queue.size() > 0:
		var current_pos = queue.pick_random()
		var neighbors = _get_unoccupied_neighbors(current_pos)
		
		if neighbors.size() == 0:
			queue.erase(current_pos)
			continue
			
		var next_pos = neighbors.pick_random()
		if _count_adjacent_rooms(next_pos) > 1:
			continue
			
		var new_room = RoomData.new()
		new_room.grid_position = next_pos
		new_room.room_type = GameConstants.RoomType.NORMAL
		grid[next_pos] = new_room
		
		queue.append(next_pos)
		current_count += 1
		
	_place_special_rooms()
	_calculate_exits()
	_instantiate_rooms()
	return spawned_rooms

func _get_unoccupied_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var n = pos + dir
		if not grid.has(n):
			list.append(n)
	return list

func _count_adjacent_rooms(pos: Vector2i) -> int:
	var count = 0
	for dir in DIRECTIONS:
		if grid.has(pos + dir):
			count += 1
	return count

func _place_special_rooms() -> void:
	var dead_ends: Array[Vector2i] = []
	for pos in grid:
		var room_data = grid[pos]
		if room_data.room_type == GameConstants.RoomType.START:
			continue
		if _count_adjacent_rooms(pos) == 1:
			dead_ends.append(pos)
			
	if dead_ends.size() > 0:
		var boss_pos = dead_ends[0]
		var max_dist = 0
		for pos in dead_ends:
			var dist = abs(pos.x) + abs(pos.y)
			if dist > max_dist:
				max_dist = dist
				boss_pos = pos
		var boss_room = grid[boss_pos]
		boss_room.room_type = GameConstants.RoomType.BOSS
		dead_ends.erase(boss_pos)
		
	if dead_ends.size() > 0:
		var item_pos = dead_ends.pick_random()
		var item_room = grid[item_pos]
		item_room.room_type = GameConstants.RoomType.TREASURE

func _calculate_exits() -> void:
	for pos in grid:
		var room_data = grid[pos]
		room_data.exits.clear()
		if grid.has(pos + DIR_UP):
			room_data.exits.append(GameConstants.Direction.NORTH)
		if grid.has(pos + DIR_DOWN):
			room_data.exits.append(GameConstants.Direction.SOUTH)
		if grid.has(pos + DIR_RIGHT):
			room_data.exits.append(GameConstants.Direction.EAST)
		if grid.has(pos + DIR_LEFT):
			room_data.exits.append(GameConstants.Direction.WEST)

func _instantiate_rooms() -> void:
	for pos in grid:
		var room_data = grid[pos]
		var room_inst = room_scene.instantiate()
		add_child(room_inst)
		room_inst.global_position = Vector2(pos.x * GameConstants.ROOM_PIXEL_SIZE.x, pos.y * GameConstants.ROOM_PIXEL_SIZE.y)
		room_inst.setup_room(room_data)
		spawned_rooms[pos] = room_inst
