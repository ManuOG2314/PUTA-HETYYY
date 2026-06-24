extends Area2D

signal item_collected

enum BuffType {
	SPEED,
	DAMAGE,
	FIRE_RATE,
	HEALTH
}

var buff_type: int
var buff_names := {
	BuffType.SPEED: "Botas de Gravedad",
	BuffType.DAMAGE: "Plasma Mejorado",
	BuffType.FIRE_RATE: "Acelerador de Partículas",
	BuffType.HEALTH: "Tanque de Oxígeno"
}
var _collected := false

func _ready() -> void:
	buff_type = randi_range(0, BuffType.size() - 1)
	
	var label = Label.new()
	label.text = buff_names[buff_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-80, 40)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.name != "player":
		return
	
	_collected = true
	_apply_buff(body)
	item_collected.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func _apply_buff(player: Node2D) -> void:
	match buff_type:
		BuffType.SPEED:
			player.add_speed(80.0)
		BuffType.DAMAGE:
			player.add_damage(1)
		BuffType.FIRE_RATE:
			player.reduce_fire_rate(0.08)
		BuffType.HEALTH:
			player.add_max_health(2)
