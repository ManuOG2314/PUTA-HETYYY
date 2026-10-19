class_name Enemy
extends CharacterBody2D

signal died

@export var max_health: int = 3
@export var move_speed: float = 150.0
@export var contact_damage: int = 1
@export var knockback_force: float = 300.0

const DAMAGE_NUMBER_SCENE = preload("res://src/combat/damage_number.tscn")
const GameConstants = preload("res://src/core/game_constants.gd")

var current_health: int
var _knockback_velocity := Vector2.ZERO
var _target: Node2D = null
var _anim_time: float = 0.0
var _current_frame_idx: int = 0

var _burn_ticks := 0
var _poison_ticks := 0
var _slow_timer := 0.0
var _is_flashing := false

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	$Hitbox.add_to_group("enemy_hitbox")

func set_target(target: Node2D) -> void:
	_target = target

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
			modulate = Color.WHITE

	if _knockback_velocity.length() > 10.0:
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		velocity = _knockback_velocity
	elif _target and is_instance_valid(_target):
		var direction = global_position.direction_to(_target.global_position)
		var current_speed = move_speed
		if _slow_timer > 0.0:
			current_speed = move_speed * 0.5
		velocity = direction * current_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	_animate_sprite(delta)

func _animate_sprite(delta: float) -> void:
	var is_moving = velocity.length() > 0.0
	var anim_frames = []
	var frame_speed = 0.1
	
	if is_moving:
		anim_frames = [24, 25, 26, 27] # Row 3: Run
		frame_speed = 0.1
		if velocity.x < 0:
			$Sprite2D.flip_h = true
		elif velocity.x > 0:
			$Sprite2D.flip_h = false
	else:
		anim_frames = [0] # Row 0: Idle
		frame_speed = 0.3
		
	_anim_time += delta
	if _anim_time >= frame_speed:
		_anim_time = 0.0
		_current_frame_idx = (_current_frame_idx + 1) % anim_frames.size()
		
	if _current_frame_idx >= anim_frames.size():
		_current_frame_idx = 0
		
	var target_frame = anim_frames[_current_frame_idx]
	if $Sprite2D.frame != target_frame:
		$Sprite2D.frame = target_frame

func take_damage(amount: int, type: int = GameConstants.DamageType.PHYSICAL) -> void:
	current_health -= amount
	
	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	dmg_num.position = position
	get_parent().add_child(dmg_num)
	dmg_num.set_text(amount)
	
	# Colorear números de daño según elemento
	match type:
		GameConstants.DamageType.FIRE:
			dmg_num.get_node("Label").add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		GameConstants.DamageType.ICE:
			dmg_num.get_node("Label").add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))
		GameConstants.DamageType.POISON:
			dmg_num.get_node("Label").add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		GameConstants.DamageType.ELECTRIC:
			dmg_num.get_node("Label").add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
	
	# Aplicar estados
	match type:
		GameConstants.DamageType.FIRE:
			var start_loop = (_burn_ticks == 0)
			_burn_ticks = 4
			if start_loop:
				_apply_burn_loop()
		GameConstants.DamageType.ICE:
			_slow_timer = 2.5
		GameConstants.DamageType.POISON:
			var start_loop = (_poison_ticks == 0)
			_poison_ticks = 5
			if start_loop:
				_apply_poison_loop()
		GameConstants.DamageType.ELECTRIC:
			_apply_electric_chain(amount)
				
	if _target and is_instance_valid(_target):
		var knock_dir = _target.global_position.direction_to(global_position)
		_knockback_velocity = knock_dir * knockback_force
	
	_flash_hit(type)
	Events.shake_requested.emit(4.0, 0.15)
	Events.hit_sfx.emit()
	
	if current_health <= 0:
		_die_and_explode()

func _take_tick_damage(amount: int, type: int) -> void:
	current_health -= amount
	
	var dmg_num = DAMAGE_NUMBER_SCENE.instantiate()
	dmg_num.position = position
	get_parent().add_child(dmg_num)
	dmg_num.set_text(amount)
	
	match type:
		GameConstants.DamageType.FIRE:
			dmg_num.get_node("Label").add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		GameConstants.DamageType.POISON:
			dmg_num.get_node("Label").add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			
	_flash_hit()
	
	if current_health <= 0:
		_die_and_explode()

func _die_and_explode() -> void:
	if is_queued_for_deletion():
		return
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox/CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)

	if randf() < 0.65:
		var crystal_scene = preload("res://src/items/crystal_pickup.tscn")
		var crystal_count = 1 if randf() < 0.8 else 2
		for i in range(crystal_count):
			var crystal = crystal_scene.instantiate()
			crystal.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
			get_parent().call_deferred("add_child", crystal)

	if _target and is_instance_valid(_target) and _target.get("explode_on_kill"):
		var explosion_scene = load("res://src/combat/explosion.tscn")
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_parent().call_deferred("add_child", explosion)
		Events.explosion_sfx.emit()
		
	died.emit()
	Events.enemy_died_sfx.emit()
	queue_free()

func _apply_burn_loop() -> void:
	while _burn_ticks > 0 and is_instance_valid(self):
		await get_tree().create_timer(0.5, false).timeout
		if not is_instance_valid(self):
			return
		_burn_ticks -= 1
		_take_tick_damage(1, GameConstants.DamageType.FIRE)

func _apply_poison_loop() -> void:
	while _poison_ticks > 0 and is_instance_valid(self):
		await get_tree().create_timer(1.0, false).timeout
		if not is_instance_valid(self):
			return
		_poison_ticks -= 1
		_take_tick_damage(1, GameConstants.DamageType.POISON)

func _apply_electric_chain(source_damage: int) -> void:
	var zap_damage = maxi(1, int(source_damage * 0.75))
	var enemies = get_tree().get_nodes_in_group("enemies")
	var zapped_count = 0
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == self:
			continue
		if global_position.distance_to(enemy.global_position) <= 220.0:
			if enemy.has_method("take_damage"):
				# Pasamos daño físico para evitar un bucle infinito de cadenas
				enemy.take_damage(zap_damage, GameConstants.DamageType.PHYSICAL)
				zapped_count += 1
				if zapped_count >= 2:
					break

func get_contact_damage() -> int:
	return contact_damage

func _flash_hit(type: int = GameConstants.DamageType.PHYSICAL) -> void:
	_is_flashing = true
	if type == GameConstants.DamageType.ELECTRIC:
		modulate = Color(5.0, 5.0, 0.5)
	else:
		modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.08, false).timeout
	if is_instance_valid(self):
		_is_flashing = false
