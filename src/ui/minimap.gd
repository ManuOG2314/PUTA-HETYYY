extends Control

const GameConstants = preload("res://src/core/game_constants.gd")

var _grid: Dictionary = {}
var _current_coord := Vector2i.ZERO

const CELL_SIZE := Vector2(24, 16)
const CELL_STEP := Vector2(30, 22)

func _ready() -> void:
	custom_minimum_size = Vector2(180, 130)

func _process(_delta: float) -> void:
	# Redibujar para animar el pulso de la sala actual
	queue_redraw()

func setup_minimap(grid: Dictionary) -> void:
	_grid = grid
	queue_redraw()

func set_current_room(coord: Vector2i) -> void:
	_current_coord = coord
	if _grid.has(coord):
		_grid[coord].visited = true
	queue_redraw()

func _draw() -> void:
	if _grid.is_empty():
		return
		
	var center = size / 2.0
	var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.008)
	
	# 1. Dibujar conexiones entre salas exploradas
	for pos in _grid:
		var room = _grid[pos]
		if not _is_visible_on_map(pos):
			continue
			
		var room_center = center + Vector2(pos.x - _current_coord.x, pos.y - _current_coord.y) * CELL_STEP
		
		# Conexión Este
		if GameConstants.Direction.EAST in room.exits and _grid.has(pos + Vector2i(1, 0)):
			if _is_visible_on_map(pos + Vector2i(1, 0)):
				var start_pt = room_center + Vector2(CELL_SIZE.x / 2.0, 0)
				var end_pt = room_center + Vector2(CELL_STEP.x - CELL_SIZE.x / 2.0, 0)
				draw_line(start_pt, end_pt, Color(0.4, 0.6, 0.8, 0.6), 2.0)
				
		# Conexión Sur
		if GameConstants.Direction.SOUTH in room.exits and _grid.has(pos + Vector2i(0, 1)):
			if _is_visible_on_map(pos + Vector2i(0, 1)):
				var start_pt = room_center + Vector2(0, CELL_SIZE.y / 2.0)
				var end_pt = room_center + Vector2(0, CELL_STEP.y - CELL_SIZE.y / 2.0)
				draw_line(start_pt, end_pt, Color(0.4, 0.6, 0.8, 0.6), 2.0)
	
	# 2. Dibujar cajas de salas
	for pos in _grid:
		var room = _grid[pos]
		if not _is_visible_on_map(pos):
			continue
			
		var room_pos = center + Vector2(pos.x - _current_coord.x, pos.y - _current_coord.y) * CELL_STEP - (CELL_SIZE / 2.0)
		var rect = Rect2(room_pos, CELL_SIZE)
		var is_current = (pos == _current_coord)
		var is_visited = room.visited
		
		var fill_color = Color(0.2, 0.25, 0.35, 0.8)
		var border_color = Color(0.4, 0.5, 0.7, 0.8)
		var icon_text = ""
		
		if is_visited:
			match room.room_type:
				GameConstants.RoomType.START:
					fill_color = Color(0.15, 0.45, 0.8, 0.9)
					border_color = Color(0.4, 0.7, 1.0, 1.0)
				GameConstants.RoomType.TREASURE:
					fill_color = Color(0.8, 0.65, 0.1, 0.9)
					border_color = Color(1.0, 0.9, 0.3, 1.0)
					icon_text = "✦"
				GameConstants.RoomType.SHOP:
					fill_color = Color(0.15, 0.7, 0.35, 0.9)
					border_color = Color(0.4, 1.0, 0.6, 1.0)
					icon_text = "💎"
				GameConstants.RoomType.BOSS:
					fill_color = Color(0.75, 0.15, 0.2, 0.9)
					border_color = Color(1.0, 0.3, 0.3, 1.0)
					icon_text = "💀"
				_:
					fill_color = Color(0.22, 0.28, 0.38, 0.85)
		else:
			# Adyacente no visitada (revelada)
			fill_color = Color(0.15, 0.18, 0.25, 0.4)
			border_color = Color(0.3, 0.4, 0.5, 0.5)
			match room.room_type:
				GameConstants.RoomType.TREASURE:
					icon_text = "✦"
				GameConstants.RoomType.SHOP:
					icon_text = "💎"
				GameConstants.RoomType.BOSS:
					icon_text = "💀"
		
		# Dibujar fondo de sala
		draw_rect(rect, fill_color, true)
		
		# Dibujar borde
		if is_current:
			var glow_rect = rect.grow(2.0)
			draw_rect(glow_rect, Color(1.0, 1.0, 1.0, pulse), false, 2.0)
			draw_rect(rect, Color(0.3, 0.9, 1.0, 1.0), false, 1.5)
		else:
			draw_rect(rect, border_color, false, 1.0)
			
		# Dibujar icono si existe
		if icon_text != "":
			var font = ThemeDB.fallback_font
			var font_size = 11
			var text_size = font.get_string_size(icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = room_pos + (CELL_SIZE - text_size) / 2.0 + Vector2(0, 9)
			draw_string(font, text_pos, icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _is_visible_on_map(pos: Vector2i) -> bool:
	if not _grid.has(pos):
		return false
	if _grid[pos].visited:
		return true
		
	# Visible si es adyacente a una sala visitada
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var neighbor = pos + dir
		if _grid.has(neighbor) and _grid[neighbor].visited:
			return true
	return false
