extends Enemy

signal health_updated(current: int, maximum: int)

@export var boss_tear_scene: PackedScene
@export var fire_rate_boss: float = 2.5
@export var boss_name: String = "NÚCLEO M.A.T.R.I.Z."

var _attack_timer: float = 0.0

func _ready() -> void:
	max_health = 40
	super._ready()

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
			modulate = Color(1.3, 0.3, 1.3)

	if _knockback_velocity.length() > 10.0:
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		velocity = _knockback_velocity
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func _process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
		
	_attack_timer += delta
	if _attack_timer >= fire_rate_boss:
		_attack_timer = 0.0
		_perform_random_attack()

func _perform_random_attack() -> void:
	var choices = [0, 1, 2]
	var choice = choices.pick_random()
	match choice:
		0:
			_attack_aimed_burst()
		1:
			_attack_ring()
		2:
			_attack_spiral()

func _spawn_bullet(dir: Vector2) -> void:
	if not boss_tear_scene:
		return
	var bullet = boss_tear_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir.normalized()
	bullet.scale = Vector2(1.5, 1.5)
	bullet.damage = 1
	get_parent().add_child(bullet)

func _attack_aimed_burst() -> void:
	for i in range(4):
		if not is_instance_valid(self) or not _target or not is_instance_valid(_target):
			return
		var dir = global_position.direction_to(_target.global_position)
		_spawn_bullet(dir)
		await get_tree().create_timer(0.2).timeout

func _attack_ring() -> void:
	var num_bullets = 12
	for i in range(num_bullets):
		var angle = (PI * 2.0 / num_bullets) * i
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_bullet(dir)

func _attack_spiral() -> void:
	var num_bullets = 16
	var start_angle = randf() * PI
	for i in range(num_bullets):
		if not is_instance_valid(self):
			return
		var angle = start_angle + (PI * 2.5 / num_bullets) * i
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_bullet(dir)
		await get_tree().create_timer(0.08).timeout

func take_damage(amount: int, type: int = GameConstants.DamageType.PHYSICAL) -> void:
	super.take_damage(amount, type)
	health_updated.emit(current_health, max_health)

func _die_and_explode() -> void:
	var crystal_scene = preload("res://src/items/crystal_pickup.tscn")
	for i in range(8):
		var crystal = crystal_scene.instantiate()
		var angle = randf() * TAU
		var dist = randf_range(20, 80)
		crystal.global_position = global_position + Vector2(cos(angle), sin(angle)) * dist
		crystal.crystal_value = 2
		get_parent().call_deferred("add_child", crystal)
		
	super._die_and_explode()
