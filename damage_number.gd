extends Node2D

func _ready() -> void:
	var target_pos = position + Vector2(randf_range(-30, 30), randf_range(-50, -80))
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "position", target_pos, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	scale = Vector2(0.3, 0.3)
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.45).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	queue_free()

func set_text(amount: int) -> void:
	$Label.text = str(amount)
