extends Enemy

@export var enemy_tear_scene: PackedScene
@export var fire_rate_ranged: float = 1.5

var _can_shoot_ranged := true

func _ready() -> void:
	super._ready()
	max_health = 2
	current_health = 2
	move_speed = 100.0

func _physics_process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta

	if not _is_flashing:
		if _slow_timer > 0.0:
			modulate = Color(0.3, 0.8, 2.0)
		elif _burn_ticks > 0:
			modulate = Color(2.0, 0.6, 0.2)
		elif _poison_ticks > 0:
			modulate = Color(0.3, 2.0, 0.3)
		else:
			modulate = Color(0.4, 1.0, 0.4)

	if _knockback_velocity.length() > 10.0:
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		velocity = _knockback_velocity
	elif _target and is_instance_valid(_target):
		var direction = global_position.direction_to(_target.global_position)
		var dist = global_position.distance_to(_target.global_position)
		
		var current_speed = move_speed
		if _slow_timer > 0.0:
			current_speed = move_speed * 0.5
			
		if dist > 350.0:
			velocity = direction * current_speed
		elif dist < 220.0:
			velocity = -direction * current_speed
		else:
			velocity = Vector2.ZERO
			
		if _can_shoot_ranged:
			_shoot_at_target()
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	_animate_sprite(delta)

func _shoot_at_target() -> void:
	if not _target or not is_instance_valid(_target) or not enemy_tear_scene:
		return
		
	_can_shoot_ranged = false
	
	var projectile = enemy_tear_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = global_position.direction_to(_target.global_position)
	get_parent().add_child(projectile)
	
	await get_tree().create_timer(fire_rate_ranged, false).timeout
	_can_shoot_ranged = true
