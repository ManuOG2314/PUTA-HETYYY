extends Area2D

signal item_collected

const GameConstants = preload("res://src/core/game_constants.gd")

enum BuffType {
	SPEED,
	DAMAGE,
	FIRE_RATE,
	HEALTH,
	CHIP_FIRE,
	CHIP_ICE,
	CHIP_POISON,
	CHIP_ELECTRIC,
	CHIP_PIERCE,
	CHIP_SPLIT,
	CHIP_EXPLODE
}

var buff_type: int
var buff_names := {
	BuffType.SPEED: "Botas de Gravedad (+Vel)",
	BuffType.DAMAGE: "Plasma Mejorado (+Daño)",
	BuffType.FIRE_RATE: "Acelerador de Partículas (+Cadencia)",
	BuffType.HEALTH: "Tanque de Oxígeno (+Vida)",
	BuffType.CHIP_FIRE: "Núcleo Ígneo (Fuego)",
	BuffType.CHIP_ICE: "Núcleo Criogénico (Hielo)",
	BuffType.CHIP_POISON: "Núcleo de Ácido (Veneno)",
	BuffType.CHIP_ELECTRIC: "Núcleo Voltaico (Rayo)",
	BuffType.CHIP_PIERCE: "Chip Perforador (+Pierce)",
	BuffType.CHIP_SPLIT: "Chip Divisor (Disparo Split)",
	BuffType.CHIP_EXPLODE: "Chip Detonador (Explosión al matar)"
}

var buff_colors := {
	BuffType.SPEED: Color(0.2, 0.6, 1.0),
	BuffType.DAMAGE: Color(1.0, 0.2, 0.2),
	BuffType.FIRE_RATE: Color(1.0, 0.9, 0.2),
	BuffType.HEALTH: Color(0.2, 1.0, 0.4),
	BuffType.CHIP_FIRE: Color(1.0, 0.4, 0.1),
	BuffType.CHIP_ICE: Color(0.3, 0.9, 1.0),
	BuffType.CHIP_POISON: Color(0.3, 1.0, 0.3),
	BuffType.CHIP_ELECTRIC: Color(1.0, 1.0, 0.2),
	BuffType.CHIP_PIERCE: Color(0.8, 0.3, 1.0),
	BuffType.CHIP_SPLIT: Color(1.0, 0.3, 0.8),
	BuffType.CHIP_EXPLODE: Color(1.0, 0.6, 0.1)
}

var cost: int = 0
var _label: Label = null
var _cost_label: Label = null
var _collected := false
var _warning_active := false

func _ready() -> void:
	if not _label:
		setup_pedestal(randi_range(0, BuffType.size() - 1), cost)

func setup_pedestal(type: int, item_cost: int = 0) -> void:
	buff_type = type
	cost = item_cost
	
	if has_node("Sprite2D"):
		var spr = $Sprite2D
		spr.texture = load("res://assets/orb/ball.png")
		spr.scale = Vector2(0.12, 0.12)
		spr.modulate = buff_colors.get(buff_type, Color.WHITE)
		
		# Animación de levitación del orbe
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(spr, "position:y", -10.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(spr, "position:y", 10.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if not _label:
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.position = Vector2(-100, 36)
		_label.size = Vector2(200, 30)
		_label.add_theme_font_size_override("font_size", 14)
		_label.add_theme_color_override("font_color", buff_colors.get(buff_type, Color.WHITE))
		_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_label.add_theme_constant_override("outline_size", 4)
		add_child(_label)
		
	_label.text = buff_names[buff_type]
	
	if cost > 0:
		if not _cost_label:
			_cost_label = Label.new()
			_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_cost_label.position = Vector2(-80, -38)
			_cost_label.size = Vector2(160, 24)
			_cost_label.add_theme_font_size_override("font_size", 15)
			_cost_label.add_theme_color_override("font_color", Color(0.2, 1.8, 1.6))
			_cost_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_cost_label.add_theme_constant_override("outline_size", 4)
			add_child(_cost_label)
		_cost_label.text = "💎 %d Cristales" % cost

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return
		
	if cost > 0:
		if body.has_method("spend_crystals"):
			if not body.spend_crystals(cost):
				_show_insufficient_warning()
				return
		else:
			return
	
	_collected = true
	_apply_buff(body)
	item_collected.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func _show_insufficient_warning() -> void:
	if _warning_active or not _cost_label:
		return
	_warning_active = true
	
	var orig_text = _cost_label.text
	var orig_pos = _cost_label.position
	_cost_label.text = "¡Faltan Cristales! 💎"
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	
	var shake_tween = create_tween()
	shake_tween.tween_property(_cost_label, "position:x", orig_pos.x - 6.0, 0.05)
	shake_tween.tween_property(_cost_label, "position:x", orig_pos.x + 6.0, 0.05)
	shake_tween.tween_property(_cost_label, "position:x", orig_pos.x, 0.05)
	
	await get_tree().create_timer(1.2, false).timeout
	if is_instance_valid(self) and is_instance_valid(_cost_label):
		_cost_label.text = orig_text
		_cost_label.position = orig_pos
		_cost_label.add_theme_color_override("font_color", Color(0.2, 1.8, 1.6))
		_warning_active = false

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
		BuffType.CHIP_FIRE:
			player.set_damage_type(GameConstants.DamageType.FIRE)
		BuffType.CHIP_ICE:
			player.set_damage_type(GameConstants.DamageType.ICE)
		BuffType.CHIP_POISON:
			player.set_damage_type(GameConstants.DamageType.POISON)
		BuffType.CHIP_ELECTRIC:
			player.set_damage_type(GameConstants.DamageType.ELECTRIC)
		BuffType.CHIP_PIERCE:
			player.add_pierce(2)
		BuffType.CHIP_SPLIT:
			player.enable_split()
		BuffType.CHIP_EXPLODE:
			player.enable_explode_on_kill()
