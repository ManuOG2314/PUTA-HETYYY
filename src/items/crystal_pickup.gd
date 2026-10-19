extends Area2D

@export var crystal_value: int = 1
@export var magnet_radius: float = 160.0

var _target_player: Node2D = null
var _collected := false
var _velocity := Vector2.ZERO

func _ready() -> void:
	# Modulación brillante tipo gema de plasma
	modulate = Color(0.2, 1.8, 1.6)
	
	# Animación de flotación inicial
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Sprite2D, "position:y", 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _physics_process(delta: float) -> void:
	if _collected:
		return
		
	if not _target_player or not is_instance_valid(_target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			if global_position.distance_to(p.global_position) <= magnet_radius:
				_target_player = p
		else:
			var main_player = get_parent().get_node_or_null("player")
			if main_player and global_position.distance_to(main_player.global_position) <= magnet_radius:
				_target_player = main_player
	
	if _target_player and is_instance_valid(_target_player):
		var dir = global_position.direction_to(_target_player.global_position)
		var dist = global_position.distance_to(_target_player.global_position)
		var speed = clampf(500.0 - dist, 200.0, 800.0)
		
		_velocity = _velocity.lerp(dir * speed, 12.0 * delta)
		global_position += _velocity * delta
		
		if dist < 25.0:
			_collect(_target_player)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _collect(player: Node2D) -> void:
	if _collected:
		return
	_collected = true
	
	if player.has_method("add_crystals"):
		player.add_crystals(crystal_value)
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	
	await tween.finished
	queue_free()
