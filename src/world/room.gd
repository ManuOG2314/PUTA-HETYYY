class_name Room
extends Node2D

const GameConstants = preload("res://src/core/game_constants.gd")
const RoomData = preload("res://src/world/room_data.gd")

signal door_entered(direction: int)
signal room_cleared
signal boss_spawned(boss_node)

@export var enemy_scene: PackedScene
@export var item_pedestal_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var boss_scene: PackedScene

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
@onready var floor_tile_map: TileMapLayer = $FloorTileMapLayer

func setup_room(data) -> void:
	_data = data
	grid_position = data.grid_position
	room_type = data.room_type
	_cleared = data.cleared
	
	var has_n = GameConstants.Direction.NORTH in data.exits
	var has_s = GameConstants.Direction.SOUTH in data.exits
	var has_e = GameConstants.Direction.EAST in data.exits
	var has_w = GameConstants.Direction.WEST in data.exits
	
	var half_w = int(GameConstants.ROOM_WIDTH / 2.0)
	var half_h = int(GameConstants.ROOM_HEIGHT / 2.0)
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
		
	if room_type == GameConstants.RoomType.SHOP:
		_cleared = true
		if _data:
			_data.cleared = true
		_spawn_shop_items()
		return
	
	if room_type == GameConstants.RoomType.NORMAL:
		_close_doors()
		_spawn_enemies(player)
	elif room_type == GameConstants.RoomType.BOSS:
		_close_doors()
		_spawn_boss(player)

func _spawn_enemies(player: Node2D) -> void:
	if not enemy_scene:
		_on_all_enemies_dead()
		return
	
	var count = _data.enemy_count if _data else 3
	if count <= 0:
		count = randi_range(2, 4)
	
	var valid_positions = _get_valid_spawn_positions()
	if valid_positions.size() == 0:
		valid_positions.append(Vector2.ZERO)
	
	for i in range(count):
		var scene_to_spawn = enemy_scene
		if ranged_enemy_scene and randf() < 0.4:
			scene_to_spawn = ranged_enemy_scene
			
		var enemy = scene_to_spawn.instantiate()
		var spawn_pos = valid_positions.pick_random()
		if valid_positions.size() > 1:
			valid_positions.erase(spawn_pos)
		
		add_child(enemy)
		enemy.position = spawn_pos
		enemy.set_target(player)
		enemy.died.connect(_on_enemy_died.bind(enemy))
		_active_enemies.append(enemy)

func _spawn_boss(player: Node2D) -> void:
	if not boss_scene:
		_on_all_enemies_dead()
		return
		
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.position = Vector2.ZERO
	boss.set_target(player)
	boss.died.connect(_on_enemy_died.bind(boss))
	_active_enemies.append(boss)
	boss_spawned.emit(boss)

func _get_valid_spawn_positions() -> Array[Vector2]:
	var list: Array[Vector2] = []
	var half_w = int(GameConstants.ROOM_WIDTH / 2.0)
	var half_h = int(GameConstants.ROOM_HEIGHT / 2.0)
	var tile_sz = GameConstants.TILE_SIZE
	
	for x in range(-(half_w - 2), half_w - 2):
		for y in range(-(half_h - 2), half_h - 2):
			var cell = Vector2i(x, y)
			# Debe tener suelo y NO tener un muro/obstáculo en tile_map
			var has_floor = floor_tile_map.get_cell_source_id(cell) != -1
			var has_wall = tile_map.get_cell_source_id(cell) != -1
			
			if has_floor and not has_wall:
				# Evitar la zona central exacta para no aparecer pegado al jugador al entrar
				if abs(x) > 1 or abs(y) > 1:
					var pos = Vector2(x * tile_sz + tile_sz / 2.0, y * tile_sz + tile_sz / 2.0)
					list.append(pos)
	return list

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
	
	var half_w = int(GameConstants.ROOM_WIDTH / 2.0)
	var half_h = int(GameConstants.ROOM_HEIGHT / 2.0)
	
	if door_n.visible:
		tile_map.set_cell(Vector2i(-1, -half_h), 0, Vector2i(3, 0))
		tile_map.set_cell(Vector2i(0, -half_h), 0, Vector2i(3, 0))
	if door_s.visible:
		tile_map.set_cell(Vector2i(-1, half_h), 0, Vector2i(3, 0))
		tile_map.set_cell(Vector2i(0, half_h), 0, Vector2i(3, 0))
	if door_e.visible:
		tile_map.set_cell(Vector2i(half_w - 1, -1), 0, Vector2i(3, 0))
		tile_map.set_cell(Vector2i(half_w - 1, 0), 0, Vector2i(3, 0))
	if door_w.visible:
		tile_map.set_cell(Vector2i(-half_w, -1), 0, Vector2i(3, 0))
		tile_map.set_cell(Vector2i(-half_w, 0), 0, Vector2i(3, 0))

func _open_doors() -> void:
	if not _doors_closed:
		return
	_doors_closed = false
	
	var half_w = int(GameConstants.ROOM_WIDTH / 2.0)
	var half_h = int(GameConstants.ROOM_HEIGHT / 2.0)
	
	if door_n.visible:
		tile_map.erase_cell(Vector2i(-1, -half_h))
		tile_map.erase_cell(Vector2i(0, -half_h))
		floor_tile_map.set_cell(Vector2i(-1, -half_h), 0, Vector2i(33, 1))
		floor_tile_map.set_cell(Vector2i(0, -half_h), 0, Vector2i(33, 1))
	if door_s.visible:
		tile_map.erase_cell(Vector2i(-1, half_h))
		tile_map.erase_cell(Vector2i(0, half_h))
		floor_tile_map.set_cell(Vector2i(-1, half_h), 0, Vector2i(33, 1))
		floor_tile_map.set_cell(Vector2i(0, half_h), 0, Vector2i(33, 1))
	if door_e.visible:
		tile_map.erase_cell(Vector2i(half_w - 1, -1))
		tile_map.erase_cell(Vector2i(half_w - 1, 0))
		floor_tile_map.set_cell(Vector2i(half_w - 1, -1), 0, Vector2i(33, 1))
		floor_tile_map.set_cell(Vector2i(half_w - 1, 0), 0, Vector2i(33, 1))
	if door_w.visible:
		tile_map.erase_cell(Vector2i(-half_w, -1))
		tile_map.erase_cell(Vector2i(-half_w, 0))
		floor_tile_map.set_cell(Vector2i(-half_w, -1), 0, Vector2i(33, 1))
		floor_tile_map.set_cell(Vector2i(-half_w, 0), 0, Vector2i(33, 1))

func _spawn_pedestal() -> void:
	if not item_pedestal_scene:
		return
	var pedestal = item_pedestal_scene.instantiate()
	add_child(pedestal)
	pedestal.position = Vector2.ZERO

func _spawn_shop_items() -> void:
	if not item_pedestal_scene:
		return
	
	# Item 1: Salud (+Vida por 3 cristales)
	var p1 = item_pedestal_scene.instantiate()
	add_child(p1)
	p1.position = Vector2(-220, 0)
	p1.setup_pedestal(3, 3) # BuffType.HEALTH = 3, cost = 3
	
	# Item 2: Buff de stats (Velocidad, Daño o Cadencia por 6 cristales)
	var p2 = item_pedestal_scene.instantiate()
	add_child(p2)
	p2.position = Vector2(0, 0)
	var stat_type = [0, 1, 2].pick_random() # SPEED, DAMAGE, FIRE_RATE
	p2.setup_pedestal(stat_type, 6) # cost = 6
	
	# Item 3: Chip o Núcleo elemental por 10 cristales
	var p3 = item_pedestal_scene.instantiate()
	add_child(p3)
	p3.position = Vector2(220, 0)
	var chip_type = randi_range(4, 10) # Fuego, Hielo, Veneno, Rayo, Pierce, Split, Explode
	p3.setup_pedestal(chip_type, 10) # cost = 10

func _build_room_layout(has_n: bool, has_s: bool, has_e: bool, has_w: bool) -> void:
	tile_map.clear()
	floor_tile_map.clear()
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
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
			else:
				floor_tile_map.set_cell(Vector2i(x, y), 0, Vector2i(33, 1))
				
	_apply_random_layout()

func _apply_random_layout() -> void:
	if room_type == GameConstants.RoomType.START or room_type == GameConstants.RoomType.TREASURE or room_type == GameConstants.RoomType.SHOP:
		return
		
	var layout = ROOM_LAYOUTS.pick_random()
	var half_w = int(GameConstants.ROOM_WIDTH / 2.0)
	var half_h = int(GameConstants.ROOM_HEIGHT / 2.0)
	var inner_w = GameConstants.ROOM_WIDTH - 2
	var inner_h = GameConstants.ROOM_HEIGHT - 2
	
	for r in range(inner_h):
		var row_string = layout[r]
		var y = -(half_h - 1) + r
		for c in range(inner_w):
			var character = row_string[c]
			var x = -(half_w - 1) + c
			if character == "#":
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))

func _on_north_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _doors_closed:
		door_entered.emit(GameConstants.Direction.NORTH)

func _on_south_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _doors_closed:
		door_entered.emit(GameConstants.Direction.SOUTH)

func _on_east_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _doors_closed:
		door_entered.emit(GameConstants.Direction.EAST)

func _on_west_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _doors_closed:
		door_entered.emit(GameConstants.Direction.WEST)
