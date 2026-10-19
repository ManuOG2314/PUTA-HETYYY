extends Area2D

@export var speed: float = 400.0
var direction := Vector2.ZERO
var damage: int = 1

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Solo dañamos al player: los proyectiles enemigos NUNCA deben dañar
	# a otros enemigos (friendly-fire involuntario, ref. AUDITORIA 3.7).
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.has_method("take_damage"):
		# Muro / cuerpo sólido sin lógica de daño en el mask (layers 1+2)
		queue_free()

func _on_screen_exited() -> void:
	queue_free()
