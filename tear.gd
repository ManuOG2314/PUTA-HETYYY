extends Area2D

@export var speed: float = 700.0
var direction := Vector2.ZERO
var tear_damage: int = 1

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(tear_damage)
	
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
