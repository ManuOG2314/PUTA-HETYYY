extends CharacterBody2D

@export var speed: float = 500.0
@export var tear_scene: PackedScene
@export var fire_rate: float = 0.4

var _last_x: int = 0
var _last_y: int = 0
var _can_fire: bool = true

func _physics_process(_delta: float) -> void:
	var x := _get_axis("move_left", "move_right", _last_x)
	_last_x = x.last

	var y := _get_axis("move_up", "move_down", _last_y)
	_last_y = y.last

	velocity = Vector2(x.value, y.value).normalized() * speed
	move_and_slide()

func _process(_delta: float) -> void:
	_handle_shooting()

func _handle_shooting() -> void:
	if not _can_fire:
		return
	
	if Input.is_action_pressed("main_fire"):
		var fire_direction := global_position.direction_to(get_global_mouse_position())
		_shoot(fire_direction)

func _shoot(direction: Vector2) -> void:
	_can_fire = false
	
	var new_tear = tear_scene.instantiate()
	new_tear.global_position = global_position
	new_tear.direction = direction
	
	get_parent().add_child(new_tear)
	
	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true


class AxisState:
	var value: int
	var last: int

	func _init(value: int, last: int) -> void:
		self.value = value
		self.last = last

func _get_axis(negative: StringName, positive: StringName, last: int) -> AxisState:
	var neg := Input.is_action_pressed(negative)
	var pos := Input.is_action_pressed(positive)

	if Input.is_action_just_pressed(positive):
		last = 1
	elif Input.is_action_just_pressed(negative):
		last = -1

	var value: int

	if pos == neg:
		value = last if pos else 0
	else:
		value = 1 if pos else -1

	return AxisState.new(value, last)
