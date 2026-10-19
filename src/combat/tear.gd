extends Area2D

const GameConstants = preload("res://src/core/game_constants.gd")

@export var speed: float = 700.0
var direction := Vector2.ZERO
var tear_damage: int = 1
var damage_type: int = GameConstants.DamageType.PHYSICAL

var pierce_count: int = 0
var split_on_hit: bool = false
var _hit_enemies: Array = []

func _ready() -> void:
	rotation = direction.angle()
	match damage_type:
		GameConstants.DamageType.FIRE:
			modulate = Color(1.8, 0.5, 0.1)
		GameConstants.DamageType.ICE:
			modulate = Color(0.2, 0.8, 1.8)
		GameConstants.DamageType.POISON:
			modulate = Color(0.2, 1.8, 0.2)
		GameConstants.DamageType.ELECTRIC:
			modulate = Color(1.9, 1.8, 0.2)
		_:
			modulate = Color(0.922, 0.922, 0.922, 1.0)

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body in _hit_enemies:
			return # Evitar golpear múltiples veces al mismo enemigo al atravesarlo
		_hit_enemies.append(body)
		
		if body.has_method("take_damage"):
			body.take_damage(tear_damage, damage_type)
			
		if split_on_hit:
			_split_tear()
			split_on_hit = false # Asegurar que solo se divida una vez
			
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
	else:
		# Si choca contra una pared u otra cosa sólida
		queue_free()

func _split_tear() -> void:
	var tear_scene = load("res://src/combat/tear.tscn")
	for angle in [45.0, -45.0]:
		var new_tear = tear_scene.instantiate()
		new_tear.global_position = global_position
		new_tear.direction = direction.rotated(deg_to_rad(angle))
		new_tear.tear_damage = maxi(1, int(tear_damage / 2.0))
		new_tear.damage_type = damage_type
		new_tear.scale = scale * 0.7
		new_tear.pierce_count = 0
		new_tear.split_on_hit = false
		get_parent().call_deferred("add_child", new_tear)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
