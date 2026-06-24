extends CharacterBody2D

signal died

@export var max_health: int = 3
@export var move_speed: float = 150.0
@export var contact_damage: int = 1
@export var knockback_force: float = 300.0

const DAMAGE_NUMBER_SCENE = preload("res://damage_number.tscn")

var current_health: int
var _knockback_velocity := Vector2.ZERO
var _target: Node2D = null

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	$Hitbox.add_to_group("enemy_hitbox")

func set_target(target: Node2D) -> void:
	_target = target

func _physics_process(delta: float) -> void:
	if _knockback_velocity.length() > 10.0:
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		velocity = _knockback_velocity
	elif _target and is_instance_valid(_target):
		var direction = global_position.direction_to(_target.global_position)
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func take_damage(amount: int) -> void:
	current_health -= amount
	
	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	dmg_num.position = position
	get_parent().add_child(dmg_num)
	dmg_num.set_text(amount)
	
	if _target and is_instance_valid(_target):
		var knock_dir = _target.global_position.direction_to(global_position)
		_knockback_velocity = knock_dir * knockback_force
	
	_flash_hit()
	
	if current_health <= 0:
		died.emit()
		queue_free()

func get_contact_damage() -> int:
	return contact_damage

func _flash_hit() -> void:
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self):
		modulate = Color.WHITE
