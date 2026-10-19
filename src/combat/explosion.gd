extends Area2D

@export var damage: int = 2

func _ready() -> void:
	# Esperar un frame físico para asegurar la detección de colisiones
	await get_tree().physics_frame
	
	# Dañar a los enemigos dentro del rango
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
			
	# Animación de explosión rápida
	scale = Vector2(0.1, 0.1)
	modulate = Color(2.0, 0.8, 0.2, 1.0)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	queue_free()
