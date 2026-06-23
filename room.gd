extends Node2D

const GameConstants = preload("res://game_constants.gd")
const RoomData = preload("res://room_data.gd")

signal door_entered(direction: int)
signal room_cleared

@export var enemy_scene: PackedScene
@export var item_pedestal_scene: PackedScene

const ROOM_LAYOUTS = [
	[
		"............................",
		"............................",
		"....##................##....",
		"....##................##....",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"....##................##....",
		"....##................##....",
		"............................",
		"............................"
	],
	[
		"............................",
		"............................",
		"............................",
		"..........########..........",
		"..........#......#..........",
		"..........#......#..........",
		"..........#......#..........",
		"..........#......#..........",
		"..........#......#..........",
		"..........#......#..........",
		"..........########..........",
		"............................",
		"............................",
		"............................",
		"............................"
	],
	[
		"............................",
		"............................",
		".............##.............",
		".............##.............",
		".............##.............",
		".............##.............",
		"......################......",
		"......################......",
		".............##.............",
		".............##.............",
		".............##.............",
		".............##.............",
		"............................",
		"............................",
		"............................"
	]
]

var grid_position := Vector2i.ZERO
var room_type: int = GameConstants.RoomType.NORMAL
var _data = null
var _active_enemies: Array = []
var _cleared := false
var _doors_closed := false

@onready var door_n: Area2D = $Doors/North
@onready var door_s: Area2D = $Doors/South
@onready var door_e: Area2D = $Doors/East
@onready var door_w: Area2D = $Doors/West
@onready var tile_map: TileMapLayer = $TileMapLayer

func setup_room(data) -> void:
	_data = data
	grid_position = data.grid_position
	room_type = data.room_type
	_cleared = data.cleared
	
	var has_n = GameConstants.Direction.NORTH in data.exits
	var has_s = GameConstants.Direction.SOUTH in data.exits
	var has_e = GameConstants.Direction.EAST in data.exits
	var has_w = GameConstants.Direction.WEST in data.exits
	
	var half_w = GameConstants.ROOM_WIDTH / 2
	var half_h = GameConstants.ROOM_HEIGHT / 2
	var tile_sz = GameConstants.TILE_SIZE
	
	door_n.visible = has_n
	door_n.monitoring = has_n
	door_n.monitorable = has_n
	door_n.position = Vector2(-tile_sz / 2.0, -half_h * tile_sz)
	
	door_s.visible = has_s
	door_s.monitoring = has_s
	door_s.monitorable = has_s
	door_s.position = Vector2(-tile_sz / 2.0, half_h * tile_sz)
	
	door_e.visible = has_e
	door_e.monitoring = has_e
	door_e.monitorable = has_e
	door_e.position = Vector2((half_w - 1) * tile_sz, -tile_sz / 2.0)
	
	door_w.visible = has_w
	door_w.monitoring = has_w
	door_w.monitorable = has_w
	door_w.position = Vector2(-half_w * tile_sz, -tile_sz / 2.0)
	
	_build_room_layout(has_n, has_s, has_e, has_w)

func activate_room(player: Node2D) -> void:
	if _cleared:
		return
	
	if room_type == GameConstants.RoomType.START:
		_cleared = true
		if _data:
			_data.cleared = true
		return
	
	if room_type == GameConstants.RoomType.TREASURE:
		_cleared = true
		if _data:
			_data.cleared = true
		_spawn_pedestal()
		return
	
	if room_type == GameConstants.RoomType.NORMAL or room_type == GameConstants.RoomType.BOSS:
		_close_doors()
		_spawn_enemies(player)

func _spawn_enemies(player: Node2D) -> void:
	if not enemy_scene:
		_on_all_enemies_dead()
		return
	
	var count = _data.enemy_count if _data else 3
	if count <= 0:
		count = randi_range(2, 4)
	
	var half_w = GameConstants.ROOM_WIDTH / 2
	var half_h = GameConstants.ROOM_HEIGHT / 2
	var tile_sz = GameConstants.TILE_SIZE
	
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		
		var spawn_x = randf_range(-(half_w - 4) * tile_sz, (half_w - 4) * tile_sz)
		var spawn_y = randf_range(-(half_h - 3) * tile_sz, (half_h - 3) * tile_sz)
		
		add_child(enemy)
		enemy.position = Vector2(spawn_x, spawn_y)
		enemy.set_target(player)
		enemy.died.connect(_on_enemy_died.bind(enemy))
		_active_enemies.append(enemy)

func _on_enemy_died(enemy: Node2D) -> void:
	_active_enemies.erase(enemy)
	if _active_enemies.size() == 0:
		_on_all_enemies_dead()

func _on_all_enemies_dead() -> void:
	_cleared = true
	if _data:
		_data.cleared = true
	_open_doors()
	room_cleared.emit()

func _close_doors() -> void:
	if _doors_closed:
		return
	_doors_closed = true
	
	if door_n.visible:
		tile_map.set_cell(Vector2i(-1, -int(GameConstants.ROOM_HEIGHT / 2.0)), 0, Vector2i(0, 0))
		tile_map.set_cell(Vector2i(0, -int(GameConstants.ROOM_HEIGHT / 2.0)), 0, Vector2i(0, 0))
	if door_s.visible:
		tile_map.set_cell(Vector2i(-1, int(GameConstants.ROOM_HEIGHT / 2.0)), 0, Vector2i(0, 0))
		tile_map.set_cell(Vector2i(0, int(GameConstants.ROOM_HEIGHT / 2.0)), 0, Vector2i(0, 0))
	if door_e.visible:
		tile_map.set_cell(Vector2i(int(GameConstants.ROOM_WIDTH / 2.0) - 1, -1), 0, Vector2i(0, 0))
		tile_map.set_cell(Vector2i(int(GameConstants.ROOM_WIDTH / 2.0) - 1, 0), 0, Vector2i(0, 0))
	if door_w.visible:
		tile_map.set_cell(Vector2i(-int(GameConstants.ROOM_WIDTH / 2.0), -1), 0, Vector2i(0, 0))
		tile_map.set_cell(Vector2i(-int(GameConstants.ROOM_WIDTH / 2.0), 0), 0, Vector2i(0, 0))

func _open_doors() -> void:
	if not _doors_closed:
		return
	_doors_closed = false
	
	if door_n.visible:
		tile_map.erase_cell(Vector2i(-1, -int(GameConstants.ROOM_HEIGHT / 2.0)))
		tile_map.erase_cell(Vector2i(0, -int(GameConstants.ROOM_HEIGHT / 2.0)))
	if door_s.visible:
		tile_map.erase_cell(Vector2i(-1, int(GameConstants.ROOM_HEIGHT / 2.0)))
		tile_map.erase_cell(Vector2i(0, int(GameConstants.ROOM_HEIGHT / 2.0)))
	if door_e.visible:
		tile_map.erase_cell(Vector2i(int(GameConstants.ROOM_WIDTH / 2.0) - 1, -1))
		tile_map.erase_cell(Vector2i(int(GameConstants.ROOM_WIDTH / 2.0) - 1, 0))
	if door_w.visible:
		tile_map.erase_cell(Vector2i(-int(GameConstants.ROOM_WIDTH / 2.0), -1))
		tile_map.erase_cell(Vector2i(-int(GameConstants.ROOM_WIDTH / 2.0), 0))

func _spawn_pedestal() -> void:
	if not item_pedestal_scene:
		return
	var pedestal = item_pedestal_scene.instantiate()
	add_child(pedestal)
	pedestal.position = Vector2.ZERO

func _build_room_layout(has_n: bool, has_s: bool, has_e: bool, has_w: bool) -> void:
	tile_map.clear()
	var half_w = int(GameConstants.ROOM_WIDTH / 2.0)
	var half_h = int(GameConstants.ROOM_HEIGHT / 2.0)
	
	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h + 1):
			var is_wall = false
			
			if y == -half_h:
				if not has_n or (x != -1 and x != 0):
					is_wall = true
			elif y == half_h:
				if not has_s or (x != -1 and x != 0):
					is_wall = true
			elif x == -half_w:
				if not has_w or (y != -1 and y != 0):
					is_wall = true
			elif x == half_w - 1:
				if not has_e or (y != -1 and y != 0):
					is_wall = true
					
			if is_wall:
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				
	_apply_random_layout()

func _apply_random_layout() -> void:
	if room_type == GameConstants.RoomType.START:
		return
	if room_type == GameConstants.RoomType.TREASURE:
		return
		
	var layout = ROOM_LAYOUTS.pick_random()
	var half_w = GameConstants.ROOM_WIDTH / 2.0
	var half_h = GameConstants.ROOM_HEIGHT / 2.0
	var inner_w = GameConstants.ROOM_WIDTH - 2
	var inner_h = GameConstants.ROOM_HEIGHT - 2
	
	for r in range(inner_h):
		var row_string = layout[r]
		var y = -(half_h - 1) + r
		for c in range(inner_w):
			var character = row_string[c]
			var x = -(half_w - 1) + c
			if character == "#":
				tile_map.set_cell(Vector2i(int(x), int(y)), 0, Vector2i(0, 0))

func _on_north_body_entered(body: Node2D) -> void:
	if body.name == "player" and not _doors_closed:
		door_entered.emit(GameConstants.Direction.NORTH)

func _on_south_body_entered(body: Node2D) -> void:
	if body.name == "player" and not _doors_closed:
		door_entered.emit(GameConstants.Direction.SOUTH)

func _on_east_body_entered(body: Node2D) -> void:
	if body.name == "player" and not _doors_closed:
		door_entered.emit(GameConstants.Direction.EAST)

func _on_west_body_entered(body: Node2D) -> void:
	if body.name == "player" and not _doors_closed:
		door_entered.emit(GameConstants.Direction.WEST)
