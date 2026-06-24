extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal stats_changed
signal died

@export var speed: float = 500.0
@export var tear_scene: PackedScene
@export var fire_rate: float = 0.4
@export var max_health: int = 6
@export var damage: int = 1
@export var invincibility_time: float = 1.0

var current_health: int
var _last_x: int = 0
var _last_y: int = 0
var _can_fire: bool = true
var _invincible: bool = false

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

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
	new_tear.tear_damage = damage
	
	get_parent().add_child(new_tear)
	
	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true

func take_damage(amount: int) -> void:
	if _invincible:
		return
	
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()
		return
	
	_invincible = true
	_start_invincibility_blink()
	await get_tree().create_timer(invincibility_time).timeout
	_invincible = false
	modulate.a = 1.0
	
	for area in $Hurtbox.get_overlapping_areas():
		if area.is_in_group("enemy_hitbox"):
			_on_hurtbox_area_entered(area)
			break

func _start_invincibility_blink() -> void:
	while _invincible:
		modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		if not _invincible:
			break
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func heal(amount: int) -> void:
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func add_speed(amount: float) -> void:
	speed += amount
	stats_changed.emit()

func add_damage(amount: int) -> void:
	damage += amount
	stats_changed.emit()

func reduce_fire_rate(amount: float) -> void:
	fire_rate = maxf(fire_rate - amount, 0.1)
	stats_changed.emit()

func add_max_health(amount: int) -> void:
	max_health += amount
	current_health += amount
	health_changed.emit(current_health, max_health)
	stats_changed.emit()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		var contact_damage = 1
		if enemy.has_method("get_contact_damage"):
			contact_damage = enemy.get_contact_damage()
		take_damage(contact_damage)


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
