extends Node2D

const GameConstants = preload("res://game_constants.gd")

var current_room_coord := Vector2i.ZERO
var spawned_rooms := {}
var transitioning := false

@onready var level_generator = $LevelGenerator
@onready var player = $player
@onready var camera = $Camera2D

func _ready() -> void:
	spawned_rooms = level_generator.generate_level()
	for pos in spawned_rooms:
		var room = spawned_rooms[pos]
		room.door_entered.connect(_on_room_door_entered.bind(pos))
	
	_move_player_to_room_smooth(Vector2i.ZERO, Vector2.ZERO, true)

func _on_room_door_entered(direction: int, from_pos: Vector2i) -> void:
	if transitioning:
		return
		
	var dir_vector = Vector2i.ZERO
	var end_pos = Vector2.ZERO
	
	var half_w = GameConstants.ROOM_WIDTH / 2
	var half_h = GameConstants.ROOM_HEIGHT / 2
	var tile_sz = GameConstants.TILE_SIZE
	
	var next_coord = from_pos
	if direction == GameConstants.Direction.NORTH:
		dir_vector = Vector2i(0, -1)
		next_coord = from_pos + dir_vector
		if spawned_rooms.has(next_coord):
			var next_room_center = Vector2(next_coord.x * GameConstants.ROOM_PIXEL_SIZE.x, next_coord.y * GameConstants.ROOM_PIXEL_SIZE.y)
			end_pos = Vector2(player.global_position.x, next_room_center.y + (half_h - 2) * tile_sz)
	elif direction == GameConstants.Direction.SOUTH:
		dir_vector = Vector2i(0, 1)
		next_coord = from_pos + dir_vector
		if spawned_rooms.has(next_coord):
			var next_room_center = Vector2(next_coord.x * GameConstants.ROOM_PIXEL_SIZE.x, next_coord.y * GameConstants.ROOM_PIXEL_SIZE.y)
			end_pos = Vector2(player.global_position.x, next_room_center.y - (half_h - 2) * tile_sz)
	elif direction == GameConstants.Direction.EAST:
		dir_vector = Vector2i(1, 0)
		next_coord = from_pos + dir_vector
		if spawned_rooms.has(next_coord):
			var next_room_center = Vector2(next_coord.x * GameConstants.ROOM_PIXEL_SIZE.x, next_coord.y * GameConstants.ROOM_PIXEL_SIZE.y)
			end_pos = Vector2(next_room_center.x - (half_w - 2.5) * tile_sz, player.global_position.y)
	elif direction == GameConstants.Direction.WEST:
		dir_vector = Vector2i(-1, 0)
		next_coord = from_pos + dir_vector
		if spawned_rooms.has(next_coord):
			var next_room_center = Vector2(next_coord.x * GameConstants.ROOM_PIXEL_SIZE.x, next_coord.y * GameConstants.ROOM_PIXEL_SIZE.y)
			end_pos = Vector2(next_room_center.x + (half_w - 2.5) * tile_sz, player.global_position.y)
			
	if spawned_rooms.has(next_coord):
		_move_player_to_room_smooth(next_coord, end_pos, false)

func _move_player_to_room_smooth(coord: Vector2i, end_pos: Vector2, is_initial: bool = false) -> void:
	current_room_coord = coord
	var target_room_pos = Vector2(
		coord.x * GameConstants.ROOM_PIXEL_SIZE.x,
		coord.y * GameConstants.ROOM_PIXEL_SIZE.y
	)
	
	if is_initial:
		player.global_position = target_room_pos
		camera.global_position = target_room_pos
		_activate_current_room()
		return
		
	transitioning = true
	
	player.set_physics_process(false)
	player.set_process(false)
	player.velocity = Vector2.ZERO
	
	var old_smoothing = camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "global_position", target_room_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", end_pos, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	camera.position_smoothing_enabled = old_smoothing
	player.set_physics_process(true)
	player.set_process(true)
	transitioning = false
	
	_activate_current_room()

func _activate_current_room() -> void:
	if spawned_rooms.has(current_room_coord):
		var room = spawned_rooms[current_room_coord]
		room.activate_room(player)
